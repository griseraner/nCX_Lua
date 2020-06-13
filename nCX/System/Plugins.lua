local CryMP = CryMP;

CryMP.Plugins = {

	---------------------------
	--		Config
	---------------------------
	id 			 = "Plugins",
	List	 	 = {},
	Ticks = {
		[1]  	 = {},     -- OnTick
		[2]		 = {},	   -- OnUpdate
	},
	---------------------------
	--		Add		
	---------------------------	
	Add = function(self, name)
		local original = _G[name];
		if (original) then
			CryMP[name] = original;
			_G[name] = nil;
		else
			return false, "plugin incorrectly configured";
		end
		local plugin = CryMP[name];
		self.List[name] = {Name = name, Required = plugin.Required};
	end,
	---------------------------
	--		OnTick		
	---------------------------		
	OnTick = function(self, players)
		for hook, v in pairs(self.Plugins.Ticks[1]) do
			if (not v.Tick or v.Tick <= 0) then
				v.Tick = v.Timer;
				local tbl = self[hook];
				if (tbl and tbl.OnTick) then
					local a, b = pcall(tbl.OnTick, tbl, players);
					if (not a) then
						self.ErrorHandler:Plugin(tbl, "OnTick", b);
					end
				end				
			end
			v.Tick = (v.Tick or 0) - 1;
		end
	end,
	---------------------------
	--		OnUpdate		
	---------------------------	
	OnUpdate = function(self, frameTime) 
		for hook, v in pairs(self.Plugins.Ticks[2]) do
			local tbl = self[hook];
			if (tbl and tbl.OnUpdate) then
				local a, b = pcall(tbl.OnUpdate, tbl, frameTime);
				if (not a) then
					self.ErrorHandler:Plugin(tbl, "OnUpdate", b);
				end
			end
		end
	end,
	---------------------------
	--		OnConfigLoad		
	---------------------------		
	OnConfigLoad = function(self, config)
		for name, data in pairs(self.List) do
			if (not data.Required) then
				self:ShutDown(name);
			end
		end
		local loaded, failed = 0, 0;
		for module, data in pairs(config) do
			if (data ~= false) then
				local a, b = self:Activate(module, true, true);
				if (a) then
					loaded = loaded + 1;
				else
					nCX.Log("Error", "Aborted loading of plugin "..module..": "..b, true);
					failed = failed + 1;
				end
			end
		end
		nCX.Log("Core", "Loaded "..math:zero(loaded).." Plugins successfully. "..(failed > 0 and "($4"..failed.." $9failed to load)" or ""), true);
	end,
	---------------------------
	--		SetTick		
	---------------------------	
	SetTick = function(self, name, value)
		if (value == false) then
			self.Ticks[1][name] = nil;
			return;
		end
		value = tonumber(value or "")
		if (value) then
			value = {Timer = value, Tick = value,};
		end
		self.Ticks[1][name] = value;
	end,
	---------------------------
	--		SetUpdate		
	---------------------------		
	SetUpdate = function(self, name, add)
		self.Ticks[2][name] = (add == true) or nil;
	end,
	---------------------------
	--		Activate		
	---------------------------	
	Activate = function(self, name, force, skip)
		if (not self:IsRegistered(name)) then
			return false, "plugin "..name.." not registered in config"
		end
		name = name:gsub("CryMP%.", "");
		if (self.List[name] and force and not self.List[name].Required) then
			self:ShutDown(name);
		end
		local a = require(name, "plugin", skip);
		if (not a) then
			return false, "plugin "..name.." not found";
		else
			self:Add(name);
		end
		local data = self.List[name];
		if (not data) then
			return false, "plugin incorrectly configured";
		end
		local tbl = CryMP[name];
		tbl.id = name;
		CryMP:SetupEvents(name, true);
		if (tbl.Tick and tbl.OnTick) then
			self:SetTick(name, tbl.Tick);
		end
		if (tbl.OnUpdate) then
			self:SetUpdate(name, true);
		end
		self:SetupFunctions(tbl);
		local ok;
		local restore = nCX.SavedTables and nCX.SavedTables[name];
		if (restore) then
			for name, data in pairs(restore) do
				tbl[name] = data;
				ok = ok or "($1tables restored$9)";
			end
			nCX.SavedTables[name] = nil;
		end
		if (not skip) then
			self:Log("Activated plugin $3"..name.." $9"..(ok or ""), 5);
		end
		if (type(tbl.OnInit) == "function") then
			pcall(tbl.OnInit, tbl);
		end
		local config = CryMP.Config[name];
		if (type(config) == "table") then
			tbl.Config = config;
		end
		return tbl;
	end,
	---------------------------
	--		ShutDown		
	---------------------------	
	ShutDown = function(self, name, skip, save, restart)
		if not (self.List[name]) then
			return false, "plugin not found";
		end
		local count = 0;
		local tbl = CryMP[name];
		if (tbl) then
			if (tbl.OnTick) then
				self:SetTick(name);
			end
			if (tbl.OnUpdate) then
				self:SetUpdate(name);
			end
			if (save) then
				count = self:PreserveTables(tbl);
			end
			if (type(tbl.OnShutdown) == "function") then
				local ok, data = pcall(tbl.OnShutdown, tbl, restart);
				if (not ok) then
					nCX.Log("Error", "OnShutdown failed! "..data, true);
				elseif (not tbl.error and type(data) == "table") then
					for i, name in pairs(data) do
						local c = self:PreserveTables(tbl, name);
						count = count + c;
					end
				end
			end
			CryMP:SetupEvents(name);
		end
		self.List[name] = nil;
		CryMP[name] = nil;
		if (skip ~= 2) then 
			nCX.Log("Core", "Disabled plugin "..name, true);
		end
		if (not skip) then
			self:Log("Disabled plugin $3"..name, 5);
		end
		return true, count;
	end,
	---------------------------
	--		Reload		
	---------------------------		
	Reload = function(self, name, save)
		local success, count = self:ShutDown(name, true, save); 
		if (success and count > 0) then
			count = "($1"..count.." $9tables restored)";
		end
		local loaded, msg = self:Activate(name, true, true);
		if (loaded) then
			local msg = count;
			if (not success or count == 0) then
				msg = "";
			end
			self:Log("Reloaded plugin $3"..name.." $9"..(msg or ""), 5);
			nCX.Log("Core", "Reloaded plugin "..name, true);
		end
		return loaded, msg
	end,
	---------------------------
	--		PreserveTables		
	---------------------------		
	PreserveTables = function(self, tbl, name)
		nCX.SavedTables[tbl.id] = {};
		if (name) then
			if (type(tbl[name]) == "table") then
				nCX.SavedTables[tbl.id][name] = tbl[name];
			end
		else
			for name, data in pairs(tbl) do
				if (type(data) == "table" and name ~= "Server" and name ~= "Config") then
					nCX.SavedTables[tbl.id][name] = data;
				end
			end
		end
		local count = nCX.Count(nCX.SavedTables[tbl.id]);
		if (count == 0) then
			nCX.SavedTables[tbl.id] = nil;
		end
		return count;
	end,
	---------------------------
	--		SetupFunctions		
	---------------------------		
	SetupFunctions = function(self, tbl)
		local name = tbl.id;
		if (tbl.ParticleManager) then
			tbl.ParticleManager = function(tbl, effect, scale, pos, dir, channelId)     
				local particles = nCX.ClientParticles[channelId];
				if (particles) then
					particles[name] = particles[name] or {};
					local spawned = particles[name];
					spawned[effect] = spawned[effect] or {};
					local count = #spawned[effect];
					if (count > 0) then
						for i, v in pairs(spawned[effect]) do
							if (math:GetWorldDistance(v, pos) == 0) then
								--CryMP.Msg.Console:ToAccess(5, "$9[$4Warning$9] Effect "..effect.." already spawned on client channel $1"..channelId);  
								return;
							end
						end
					end
					spawned[effect][count + 1] = pos;
					nCX.ParticleManager(effect, scale, pos, dir, channelId);
					--CryMP.Msg.Console:ToAccess(5, "$9Spawning effect "..effect.." on client channel $1"..channelId);  
				end
			end
		end	
		tbl.ControlEvents = function(tbl, event, add)     
			local cache = CryMP.EventCache;
			if (event) then
				local tbl = cache[event];
				if (tbl) then	
					for i, plugin in pairs(tbl) do
						if (plugin == name) then
							if (add) then
								tbl[#tbl + 1] = name;
							else
								table.remove(tbl, i);
							end
							break;
						end
					end
				end
			else		
				for func, tbl in pairs(cache) do
					for i, plugin in pairs(tbl) do
						if (plugin == name) then
							table.remove(tbl, i);
							break;
						end
					end
				end
				if (add) then				
					tbl = tbl.Server;
					if (tbl) then
						for func, code in pairs(tbl) do
							if (cache[func]) then
								cache[func][#cache[func] + 1] = name;
							end
						end
					end
				end
			end
		end
		local funcs = {"Reload", "SetTick", "SetUpdate", "ShutDown"};
		for i, v in pairs(funcs) do
			tbl[v] = function(tbl, ...)
				self[v](self, name, ...);
			end
		end
		tbl.Log = function(tbl, msg, access, toChannel)   
			local priority = tbl.Required and tbl.id ~= "ChatCommands" and "$4" or "";
			local space = System.GetCVar("nCX_ConsoleSpace");
			msg = string:lspace(space, "$5Plugin ($9"..priority..tbl.id.."$5)").." $9: "..msg;
			if (access) then
				local target = tonumber(access);
				if (toChannel) then
					if (target) then
						CryMP.Msg.Console:ToPlayer(target, msg);
					end
				else
					CryMP.Msg.Console:ToAccess(target or 2, msg);
				end
			else
				CryMP.Msg.Console:ToAll(msg);
			end
		end
		tbl.CanRequest = function(tbl, playerId)     
			if (playerId) then
				local event = "OnStatusRequest";
				local cache = CryMP.EventCache[event];
				local lua, quit;
				for i, hook in pairs(cache or {}) do
					if (hook ~= name) then
						if (CryMP:ProcessEvent(event, hook, {})) then
							return false;
						end
					end
				end
				return true;
			end
		end
	end,
	---------------------------
	--		IsDynamic		
	---------------------------		
	IsDynamic = function(self, name)
		return CryMP.Config[name] == false
	end,
	---------------------------
	--		IsRegistered		
	---------------------------		
	IsRegistered = function(self, name)
		return CryMP.Config[name] ~= nil
	end,
	---------------------------
	--		Log		
	---------------------------		
	Log = function(self, msg)   
		CryMP.Msg.Console:ToAccess(2, string:lspace(41, "$5Core ($4"..self.id.."$5)").." $9: "..msg);
	end
	
};



