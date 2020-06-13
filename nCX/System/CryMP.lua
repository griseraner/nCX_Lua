CryMP = {
		
	---------------------------
	--		Config
	---------------------------
	id 					= "nCX",
	Config 				= {},
	Version 			= {
		Major 			= 6,
		Minor 			= 3,
		Revision		= 0,
		String 			= "%s %s",
		Number		    = 0,
	},
	Packages = {
		{"Math", "Msg", "Ent",},
		{"Plugins", "Library", "ErrorHandler", "Users",},
	},
	Priority = {
		["OnConnect"] = {
			"ScoreRestore",
			"Reports",
			"PerformanceMonitor",
			"PermaScore",
			"Attach",
			"JoinMessages",
		},
		["OnDisconnect"] = {
			"ScoreRestore",
			"PermaScore",
		},
	},
	
	Server = {
		---------------------------
		--		OnConnect		
		---------------------------
		OnConnect = function(self, channelId, actor, profileId, restart)
			nCX.ClientParticles[channelId] = {};
		end,
		---------------------------
		--		OnDisconnect		
		---------------------------
		OnDisconnect = function(self, channelId, actor, profileId)
			nCX.ClientParticles[channelId] = nil;
			self.Buffer[4][channelId] = nil;
		end,
		---------------------------
		--		OnReset		
		---------------------------	
		OnReset = function(self, restart)
			if (self.Plugins and self.Utilities) then
				local s = 0;
				for hook, v in pairs(self.Plugins.List or {}) do
					--if (self.Plugins:IsDynamic(hook)) then
						local ok = self.Plugins:ShutDown(hook, 2, false, restart);
						if (ok) then
							s = s + 1;
						end
					--else
					--	self.Plugins:HandleOnShutdown(self[hook], restart);
					--end
				end
				if (s > 0) then
					nCX.Log("Core", "Unloading plugins ("..s..")...", true);
				end
				for hook, v in pairs(self.Utilities or {}) do
					self.Plugins:HandleOnShutdown(self[hook], restart);
				end
			end
		end,
	},
	---------------------------
	--		Initialize		
	---------------------------	
	Initialize = function(self, reload)
		nCX.SavedTables = nCX.SavedTables or {};
		nCX.ClientParticles = nCX.ClientParticles or {};
		local v = self.Version;
		v.Number = ("%d.%d.%d"):format(v.Major, v.Minor, v.Revision);
		v.String = v.String:format(self.id, v.Number);
		local main = nCX.ROOT.."Game/Server/nCX/";
		
		local old = nCX.ROOT:reverse();
		local n = old:find("\\", 2);
		local new = old:sub(n);
		local new = new:reverse().."GlobalData/";--lol
		
		nCX.SetGlobalPath(new);
		
		self.Paths = {
			ROOT = main,
			ServerData = main.."ServerData/",
			GlobalData = new,
			Packages = {};
		};
		self.EventCache = {};
		self.Utilities = {};
		self.Buffer = {
			{},{},{},{}, --Tick, Delta, Spawns, User Requests
		};
		self:ScanDirectory(self.Paths.ROOT);
		self:PreparePackages();
		self:SetupEvents(self.id, true);
		local utils = self:Setup(reload);
		if (utils) then
			nCX.Log("Core", "Loaded "..math:zero(utils).." Utilities successfully.", true);				
		else
			self:AbortStartup();
			return;
		end
		if (not nCX.MapList) then
			self:GetAvailableMaps();
		end
		self:OnStartupSucceeded(nCX.GetCurrentLevel(), reload);
		if (not reload) then
			local triggers = System.GetEntitiesByClass("ActionTrigger");
			if (triggers and #triggers > 0) then
				local count, rotated = 0, 0;
				for i, trigger in pairs(triggers) do
					if (trigger:GetWorldAngles().z ~= 0) then
						rotated = rotated + 1;
					end
					count = count + 1;
				end
				nCX.Log("Core", "Trigger Count: "..math:zero(count).." ("..math:zero(rotated).." rotated)", true);
			end
		end	
	end,
	---------------------------
	--		OnTimer		
	---------------------------
	OnTimer = function(self, players)
		if (players) then
			if (self.Plugins and self.Plugins.OnTick) then
				self.Plugins.OnTick(self, players);
			end
		end
		self:QueueFunction(1);
		if (self.UpdateDelay) then
			self.UpdateDelay = self.UpdateDelay - 1;
			if (self.UpdateDelay <= 0) then
				self.UpdateDelay = nil;
			end
		else
			self:QueueSpawn(); 
		end
	end,
	---------------------------
	--		OnUpdate		
	---------------------------	
	OnUpdate = function(self, frameTime)
		if (self.Plugins and self.Plugins.OnUpdate) then
			self.Plugins.OnUpdate(self, frameTime);
		end
		self:QueueFunction(2);
		--self:QueueSpawn(); 
	end,
	---------------------------
	--		QueueFunction		
	---------------------------	
	QueueFunction = function(self, typ)
		local buffer = self.Buffer;
		if (buffer[typ] and nCX.Count(buffer[typ]) > 0) then
			for exec, tbl in pairs(buffer[typ]) do
				tbl[1] = tbl[1] - 1;
				if (tbl[1] < 0) then
					local success, quit = pcall(exec);
					buffer[typ][exec] = nil;
					if (not success) then
						buffer[typ] = {};
						self.ErrorHandler:Timer(typ == 2 and "QueueUpdate" or "QueueTimer", quit);					
						break;
					end
				end
			end
		end
	end,
	---------------------------
	--		QueueSpawn		
	---------------------------	
	QueueSpawn = function(self, players)
		if (nCX.Count(self.Buffer[3]) > 0) then
			local counter = 0;
			for exec, params in pairs(self.Buffer[3]) do
				local name = params.name;
				local current = params.vehicleId and System.GetEntity(params.vehicleId);
				if (not current or (current and not current.vehicle)) then
					current = System.GetEntityByName(name);
				end
				local entity = not current and System.SpawnEntity(params);
				if (current) then
					System.LogAlways("Aborted spawning of entity "..name.." ($4entity already present$9)");
				end
				self.Buffer[3][exec] = nil;
				if (exec) then
					local success, quit = pcall(exec, entity, current);
					if (not success) then
						self.ErrorHandler:Timer("QueueSpawn", quit);
					end
				end
				if (entity) then
					entity:AwakePhysics(1);
					if (entity.vehicle) then
						local mod = entity.Properties.Modification:lower();
						if (mod == "repair") then
							if (self.Repair) then
								self.Repair:CreateZone(entity.id);
							end
						elseif (mod == "spawngroup") then
							if (not entity.Properties.Buyzone and not entity.Properties.Spawngroup) then
								g_gameRules:MakeBuyZone(entity, 13, 13);
								nCX.AddSpawnGroup(entity.id);
							end
						end
					end
					counter = counter + 1;
					if (counter > 4) then
						break;
					end
					--System.LogAlways("QueueSpawn: spawning "..entity:GetName().." (mod: "..entity.Properties.Modification..", idx "..counter..", "..(players~=nil and #players.." players" or "$4WARNING$9: no players")..")");
				end
			end
		end
	end,
	---------------------------
	--		SetTimer		
	---------------------------		
	SetTimer = function(self, timer, exec, skip)
		if (timer and exec) then
			timer = tonumber(timer);
			if (timer) then
				self.Buffer[1][exec] = {timer, skip};
			end
		end
	end,
	---------------------------
	--		DeltaTimer		
	---------------------------		
	DeltaTimer = function(self, timer, exec, skip)
		if (timer and exec) then
			timer = tonumber(timer);
			if (timer) then
				self.Buffer[2][exec] = {timer, skip};
			end
		end
	end,
	---------------------------
	--		Spawn		
	---------------------------	
	Spawn = function(self, params, exec)
		if (params and exec) then
			self.Buffer[3][exec] = params;
		end
	end,
	---------------------------
	--		GiveItem		
	---------------------------	
	GiveItem = function(self, player, class, infoClient)
		if (player and player.Info and class) then
			--infoClient = infoClient or nCX.IsPlayerActivelyPlaying(player.id);
			local count = player.inventory:GetCountOfClass(class);
			local item = nCX.GiveItem(class, player.Info.Channel, true, infoClient or false);
			if (item and item.weapon) then
				self:HandleEvent("OnGiveItem", {player, item});
				return item;
			end
		end
	end,
	---------------------------
	--		GetPlugin		
	---------------------------	
	GetPlugin = function(self, pluginId, func)
		local tbl = self[pluginId];
		if (not tbl) then
			local error;
			if (self.ErrorHandler:GetPluginCount(pluginId) > 0) then
				return false, "plugin was disabled due to errors"
			end
			tbl, error = self.Plugins:Activate(pluginId, false, true);
			if (not tbl) then
				return false, error
			end
		end
		if (func and type(func)=="function") then
			local lua, arg, msg = pcall(func, tbl)
			if (lua) then
				return arg, msg
			end
			self.ErrorHandler:Plugin(tbl, "GetPlugin", arg, true);
			return false, "LUA ERROR";
		end
		return true;
	end,
	---------------------------
	--		SetConfig		
	---------------------------	
	SetConfig = function(self, config)
		self.Config = config;
		self.Plugins:OnConfigLoad(config)
	end,
	---------------------------
	--		OnStartupSucceeded		
	---------------------------
	OnStartupSucceeded = function(self, map, reload)
		require("Config_"..g_gameRules.class, "configuration file");
		self:HandleEvent("OnNewMap", {map, not nCX.Rebooted, reload});
		nCX.Rebooted = true;
	end,
	---------------------------
	--		Setup		
	---------------------------
	Setup = function(self, reload)
		local loaded = 0;
		local long = {["Ent"] = "Entity", ["Msg"] = "Message",};
		for v, tbl in pairs(self.Packages) do
			for i, name in pairs(tbl) do
				local util = (long[name] or name)..(v == 1 and "Utils" or "");
				local a = require(util, "required script", true);
				if (not a) then
					return false, util;
				end
				local script = self[name];
				script.id = name;
				if (type(script.OnInit) == "function") then
					script:OnInit(reload);
				end
				if (reload) then
					self:SetupEvents(self.id, false);
				end
				self:SetupEvents(name, true);
				self.Utilities[name] = true;
				script.Log = function(script, msg, access, toChannel)
					local space = System.GetCVar("nCX_ConsoleSpace");
					msg = string:lspace(space, "$5System ($9"..script.id.."$5)").." $9: "..msg;
					if (access) then
						local target = tonumber(access);
						if (toChannel) then
							if (target) then
								self.Msg.Console:ToPlayer(target, msg);
							end
						else
							self.Msg.Console:ToAccess(target or 2, msg);
						end
					else
						self.Msg.Console:ToAll(msg);
					end
				end
			end
			loaded = loaded + #tbl;
		end
		return loaded;
	end,
	---------------------------
	--		ScanDirectory		
	---------------------------
	ScanDirectory = function(self, path, tbl)
		local tbl = tbl or System.ScanDirectory(path, 2, 1);
		for i, dir in pairs(tbl) do
			dir = path..dir.."/";
			self.Paths.Packages[#self.Paths.Packages+1] = dir;
			self:ScanDirectory(dir, System.ScanDirectory(dir, 2, 1));
		end
	end,
	---------------------------
	--		AbortStartup		
	---------------------------
	AbortStartup = function(self)
		self.Paths = {};
		package.path = "";
		System.LogAlways("[$4nCX Error$9] Startup failed!");
	end,
	---------------------------
	--		PreparePackages		
	---------------------------
	PreparePackages = function(self)
		package.path = "./Game/Server/nCX/?.lua;";
		for i, path in pairs(self.Paths.Packages) do
			-- Deal with any weird chars.
			path = path:gsub(nCX.ROOT:gsub("[%[%]%^%$%(%)%%%.%*%+%-%?]", "%%%1"), "./");
			package.path = package.path..path.."?.lua;";
		end
		package.path = package.path..self.Paths.GlobalData.."?.lua;";
		self.Paths.Packages = nil;
	end,
	---------------------------
	--		HandleEvent		
	---------------------------	
	HandleEvent = function(self, event, args)
		if (event) then
			args = args or {};
			if (not self.EventCache[event]) then
				args[#args+1] = true;
				return false, unpack(args);
			end
			local cache = self.EventCache[event];
			if (#cache == 1) then
				local quit, args = self:ProcessEvent(event, cache[1], args);
				return quit, unpack(args);
			end
			local quit;
			for i, hook in pairs(cache) do
				quit, args = self:ProcessEvent(event, hook, args);
				if (quit) then
					return quit, unpack(args);
				end
			end
			return false, unpack(args);
		end
	end,
	---------------------------
	--		ProcessEvent		
	---------------------------	
	ProcessEvent = function(self, event, module, args)
		local plugin = self[module] or self;
		local server = plugin and plugin.Server;
		if (server and server[event]) then
			local lua, quit, replace = pcall(server[event], plugin, unpack(args));
			if (not lua) then
				self.ErrorHandler:Plugin(plugin, event, quit, hook);
				quit = false;
			end
			if (replace and args) then
				for i, v in pairs(replace) do 
					args[i] = v;											
				end
			end				
			if (quit) then
				return quit, args;
			end
		end
		return false, args;
	end, 
	---------------------------
	--		SetupEvents		
	---------------------------	
	SetupEvents = function(self, module, add)
		local tbl = self[module];
		if (module == self.id) then
			tbl = self;
		end
		tbl = tbl and tbl.Server;
		if (tbl) then
			local cache = self.EventCache;		
			for name, code in pairs(tbl) do
				if (type(code) == "function") then
					if (add == true) then
						cache[name] = cache[name] or {};
						cache[name][#cache[name] + 1] = module;
						self:Sort(name);
					elseif (cache[name]) then
						for i, plugin in pairs(cache[name]) do	
							if (plugin == module) then
								if (#cache[name] == 0) then
									cache[name] = nil;
								else
									table.remove(cache[name], i);
								end
							end
						end
					end
				end
			end
		end
	end,
	---------------------------
	--		Sort		
	---------------------------	
	Sort = function(self, event)
		local tbl = self.EventCache[event];
		if (tbl) then
			table.sort(tbl, function(h1, h2)
				return self:GetPriority(h1, event) < self:GetPriority(h2, event)
			end);
		end
	end,
	---------------------------
	--		GetPriority		
	---------------------------	
	GetPriority = function(self, hook, event)
		if (hook == "nCX") then
			return -1;
		elseif (self:IsUtility(hook)) then
			return 0;
		elseif (self.Plugins.List[hook] and self.Plugins.List[hook].Required) then	
			return 0.5;
		else
			local tbl = self.Priority[event];
			if (tbl) then
				for idx, h in pairs(tbl) do
					if (h == hook) then
						return idx;
					end
				end
			end 
			return 1;
		end
	end,
	---------------------------
	--		IsServerVehicle		
	---------------------------	
	IsServerVehicle = function(self, vehicleId)
		return (self.AFKManager and self.AFKManager:IsTruck(vehicleId)) or (self.AntiCheat and self.AntiCheat:IsTruck(vehicleId)) 
	end,
	---------------------------
	--		GetBoxingMsg		
	---------------------------	
	GetBoxingMsg = function(self)
		if (not self.Boxing) then
			return "Boxing - Arena  (off)";
		end
		return "Boxing - Arena  ( "..nCX.Count(self.Boxing.Boxers).." ) fighter(s)";
	end,
	---------------------------
	--		SetRequire		
	---------------------------
	SetRequire = function(self)
		require = function(file, ftype, skip)--IMPORTANT => only .lua files which are in nCX directory can be loaded now!
			if (type(file)~="string") then
				return;
			end
			local ftype = ftype or "";
			local file = file:gsub("%.lua", "");
			-- Reload the file if it's already been loaded.
			package.loaded[file] = nil;
			local s, e = pcall(oldReq, file);
			if (s and file~="nCX" and not ftype:find("chat command")) then
				self:HandleEvent("OnFileLoad", {file, ftype, skip});
			elseif (type(e)=="string") then
				e = e:gsub(nCX.ROOT:gsub("[%[%]%^%$%(%)%%%.%*%+%-%?]", "%%%1"), "./");
				local ok = self.ErrorHandler and self.ErrorHandler:File(e, file);
				if (not ok) then
					local file = ftype~="" and ftype.." "..file or file;
					System.LogAlways("[nCX Error] Failed to load "..file..".lua: "..e);
				end
			end
			return s;
		end
	end,
	---------------------------
	--		IsUtility		
	---------------------------	
	IsUtility = function(self, script)
		return self.Utilities[script];
	end,
	---------------------------
	--		GetAvailableMaps		
	---------------------------	
	GetAvailableMaps = function(self)
		nCX.MapList = {};
		local path = nCX.ROOT.."Game/Levels/Multiplayer/";
		local gamerules = {
			["ps"] = "PowerStruggle",
			["ia"] = "TeamInstantAction",
		};
		for i, rule in pairs(System.ScanDirectory(path, 2)) do
			for j, map in pairs(System.ScanDirectory(path..rule, 2)) do
				if (map) then
					local rules = gamerules[rule:lower()];
					if (rules) then
						nCX.MapList[map:lower()] = rules;
					end
				end
			end
		end
		nCX.Log("Core", nCX.Count(nCX.MapList).." maps found and added to the database.");
	end,

};

--mergef(CryMP,nCX_LUA_System,1); 

if (not oldReq) then
	table.remove(package.loaders, 4);
	package.loaders[3] = package.loaders[1];
	table.remove(package.loaders, 1);
	oldReq = require;
end

CryMP:SetRequire()



