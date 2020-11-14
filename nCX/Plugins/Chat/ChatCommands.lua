ChatCommands = {

	---------------------------
	--		Config
	---------------------------
	Required 		 = true,
	Tick 			 = 10,
	Tag				 = 1,
	Output_space 	 = 9, -- minimum space for output strings
	
	Commands 		 = {},
	Sorted			 = {},
	Data 		     = {},
	LastPos 		 = {},
	Tagged			 = {}, -- players tagged through !tag
	PM				 = {},
	Taxis		 	 = {},
	
	Usage 			 = {
		Created		 = os.date("%x").." | "..os.date("%X");
	}, -- command usage log
		
	ArgumentInfo = {
		["player"]   = "The name of the player. Accepts partial values",
		["reason"]   = "A brief explanation for your action",
		["duration"] = "The duration (in minutes)",
	},

	Server =  {
		
		OnDisconnect = function(self, channelId, player)
			self.Data[channelId] = nil;
			self.PM[channelId] = nil;
			self.Taxis[channelId] = nil;
			self.LastPos[player.id] = nil;
			self.Tagged[player.id] = nil;
		end,
				
		SvBuy = function(self, player, msg)
			local msg = msg:gsub("_", " ");
			local command = msg:find(" ");
			local command = command and msg:sub(0, (command-1)) or msg;
			local msg = msg:gsub(command, ""):sub(2);
			return not self.Server.OnChatMessage(self, -1, player, command, msg);
		end,
					
		OnChatMessage = function(self, v, player, input, msg)
			local channelId = player.Info.Channel;
			if (input and #input > 0) then
				local ok = false;
				local console = (v == -1);
				local command, data, info = self:GetCommand(player, input, console);
				if (command) then
					ok, data, info = self:ProcessInput(player, command, msg);
					self:AddUsageInfo(command, player, ok);
				end
				if (ok) then
					local sound = data or "confirm";
					if (sound ~= true) then
						CryMP.Ent:PlaySound(player.id, sound);
					end
					if (ok ~= -2) then
						local con = (ok == -1);
						self:LogCmd(player, msg, "$5success", command, con);
						--if (con) then
						--	CryMP.RSE:ToTarget(channelId, CryMP.RSE.OpenConsole);
						--end
					end
				else
					CryMP.Ent:PlaySound(player.id, "error");
					if (command) then
						local feedback;
						if (data) then
							feedback = "$4failed: "..data;
							if (data ~= "LUA error") then
								--nCX.SendTextMessage(2, "Chat Command failed ( "..command:upper().." : "..data.." )", channelId);
								local s = command:upper().." : "..data;
								local sent;
								if (player.actor:IsClientInstalled()) then
									local msg = [[EX:HUD.BattleLogEvent(eBLE_Warning,"]]..s..[[");]];
									g_gameRules.onClient:ClWorkComplete(channelId, player.id, msg);
									sent = true;
								end
								if (player.actor:GetSpectatorMode() ~= 0 or player:IsDead() or info or not sent) then
									info = info or command:upper().." ::: "..data;
									nCX.MsgFromChatEntity(channelId, info, self.Tag);
								end
							end
						end
						self:LogCmd(player, msg, feedback or "$8no feedback", command);
					elseif (data) then
						local acx = tonumber(data);
						if (console) then				
							self:SendOutput(channelId, "Command invalid (buy $7"..input.."$9)", 0, console);
						else
							local curr = player:GetAccess();
							if (acx and curr+1 == acx and CryMP.Users.Access[acx]) then
								local group = acx == 1 and "Premium Members" or CryMP.Users.Access[acx].." Group";
								nCX.MsgFromChatEntity(channelId, "[ "..input:upper().." ] command reserved for "..group, self.Tag);
							else
								nCX.MsgFromChatEntity(channelId, "[ "..input.." ] command invalid", self.Tag);
							end
						end
					end
				end
			else
				local tbl = self.PM[channelId];
				if (tbl) then
					local targetChannel = tbl[1];
					local target = nCX.GetPlayerByChannelId(targetChannel);
					if (target) then
						if (#msg == 61 and not tbl[2]) then
							tbl[2] = msg;
							nCX.MsgFromChatEntity(channelId, "(1/2) Your Message will be sent on next msg. Delete with !pm", self.Tag);
						else
							self:SendPM(player, target, msg, tbl[2]);
							if (tbl[2]) then
								tbl[2] = nil;
							end
						end
					else
						nCX.MsgFromChatEntity(channelId, "PM:SYSTEM disabled... (target disconnected)", self.Tag);
						self.PM[channelId] = nil;
					end					
					return true;
				end
			end
		end,
		
		OnKill = function(self, hit, shooter, target)
			self.LastPos[target.id] = self.LastPos[target.id] or target:GetPos();
			if (self.Tagged[target.id]) then
				nCX.AddMinimapEntity(target.id, 2, 0);
			end
		end,
				
		OnRevive = function(self, channelId, player, vehicle, first)
			if (self.Tagged[player.id]) then
				nCX.AddMinimapEntity(player.id, 2, 0);
			end
		end,
	
	},
	
	OnInit = function(self, Config)
		self:Load();
	end,
	
	OnTick = function(self, tick)
	--[[
		self.TickRep = (self.TickRep or 0) + 1;
		if (self.TickRep > 150) then
			local tbl = self.Sorted[0];
			if (tbl) then
				local chosen = tbl[math.random(1, #tbl)];
				while (not chosen.Info) do
					chosen = tbl[math.random(1, #tbl)];
				end
				local players = CryMP.Users:GetUsers(0, true, true);
				if (players) then
					for channelId, profileId in pairs(players) do
						nCX.MsgFromChatEntity(channelId, "Have you tried !"..chosen.Name.."?", self.Tag);
						nCX.MsgFromChatEntity(channelId, "Use it to "..chosen.Info.."!", self.Tag);
					end
				end
			end
			self.TickRep = 0;
		end]]
		if (self.PM) then
			for channelId, tbl in pairs(self.PM) do
				local target = nCX.GetPlayerByChannelId(tbl[1]);
				if (target) then
					CryMP.Msg.Info:ToPlayer(channelId, "PM-SYS [ ACTIVE ] > > > "..target:GetName());
				else
					nCX.MsgFromChatEntity(channelId, "PM-SYSTEM [ DISABLED ] > > > (user disconnected)", self.Tag);
					self.PM[channelId] = nil;
				end
			end
		end
	end,

	Load = function(self)
		self.Commands = {};
		self.Sorted = {};

		self:Add("reload", {
				Access = 3,
				Info = "reload CryMP files",
				Args = {
					{"mode", Optional = true, Info = "The plugin you want to reload"},
					{"save", Optional = true, Info = "Tables will be restored"},
				}
			}, 
			function (self, player, channelId, msg, save)
				if (not msg) then
					nCX.MsgFromChatEntity(channelId, "Reloading CryMP...");
					nCX:Bootstrap(true);
					return true;
				end
				local input = msg:lower();
				if (#input < 3) then
					return false, "invalid input", "Minimum 3 chars!"
				end
				if (("commands"):sub(1, #input) == input) then
					self:Load();
					return true;
				elseif (("utils"):sub(1, #input) == input) then
					local loaded, utility = CryMP:Setup(true);
					if (loaded) then
						return true;
					end
					return false, "failed to load utility", "Failed to load '"..utility.."'!";
				elseif (("config"):sub(1, #input) == input) then
					local OLD_CONFIG = CryMP.Config;
					CryMP.Config = nil;
					require("Config_"..g_gameRules.class, "configuration file");
					if (not CryMP.Config) then
						CryMP.Config = OLD_CONFIG;
						return false, "config reload failed";
					end
					for module, data in pairs(CryMP.Config) do
						local plugin = CryMP[module];
						if (plugin) then
							plugin.Config = data;
						end
					end
					CryMP.ErrorHandler:Inform();
					return true;
				else
					for module, data in pairs(CryMP.Config) do
						if (module:sub(1, #input):lower() == input) then
							if (CryMP.Plugins:IsDynamic(module)) then
								return CryMP.Plugins:ShutDown(module, false, save);
							end
							return CryMP.Plugins:Reload(module, save);
						end
					end
				end
				return false, "plugin not found", "Plugin '"..msg.."' not found!"
			end
		);
		
		self:Add("disable", {
				Access = 5,
				Info = "disable plugins",
				Args = {
					{"plugin", Info = "The plugin you want to disable"},
					{"save", Optional = true, Info = "Tables will be restored"},
				},
			},
			function (self, player, channelId, input, save)
				if (#input < 3) then
					return false, "invalid input", "Minimum 3 chars!"
				end
				local inputlwr = input:lower();
				for module, data in pairs(CryMP.Config) do
					if (module:sub(1, #input):lower() == inputlwr) then
						local tbl = CryMP[module];
						if (not tbl) then
							return false, "plugin not found", "Plugin '"..input.."' doesn't exist!";
						elseif (tbl.Required) then
							return false, "plugin required", "Plugin '"..tbl.id.."' is required and cannot be disabled!";
						end
						return CryMP.Plugins:ShutDown(module, false, save);
					end
				end
			end
		);	

		self:Add("synch", {
				Info = "",
				Hidden = true,
				Args = {
				},
			},
			function(self, player, channelId, id, token, extra)
				local CL_VERSION = "3.0";
				RPC:CallOne(player, "Execute", {
					code = [[if nCX then nCX:TS(9)return end;nCX=nCX or{}g_LAC=g_localActor.actor:GetChannel()local a,b=g_gameRules,System;function nCX:TS(c)a.server:RequestSpectatorTarget(g_localActorId,c)end;function nCX:GP(d)return a.game:GetPlayerByChannelId(d)end;function nCX:PSE(e,f)local g=bor(bor(SOUND_EVENT,SOUND_VOICE),SOUND_DEFAULT_3D)local h=SOUND_SEMANTIC_PLAYER_FOLEY;return e:PlaySoundEvent(f,g_Vectors.v000,g_Vectors.v010,g,h)end;function nCX:Handle(i)if i=="GetVersion"then nCX:TS(9)return true end;local j=i:sub(1,3)if j=="EX:"then local k=i:sub(4)if k then local l=loadstring;local m,h=pcall(l(k))if not m then nCX:TS(13)if h then a.game:SendChatMessage(2,g_localActorId,g_localActorId,"LUA: "..tostring(h))end end end;return true end end;function a.Client.ClWorkComplete(self,n,i)if nCX:Handle(i)then return end;local g;if i=="repair"then g="sounds/weapons:repairkit:repairkit_successful"elseif i=="lockpick"then g="sounds/weapons:lockpick:lockpick_successful"end;if g then local o=b.GetEntity(n)if o then local e=o:GetWorldPos(g_Vectors.temp_v1)e.z=e.z+1;return Sound.Play(g,e,49152,1024)end end end;nCX.CL_BACKUP=a.Client.ClWorkComplete;b.LogAlways("$9[$4nCX$9] $9Patching client success! Version $3]]..CL_VERSION..[[")nCX:TS(8)]]
				});
			end
		);	
		
		self:Add("validate", {
				Info = "",
				self = "BanSystem",
				Hidden = true,
				Args = {
					{"id", },
					{"token", },
					{"extra", Optional = true,},
				},
			},
			function(self, player, channelId, id, token, extra)
				local num_id = tonumber(id)
				nCX.SendProfileValidationRequest(channelId, num_id, token);
			end
		);		
		local ok, err = 0, 0;
		local TEST_SERVER = System.GetCVar("sv_port") == 49999;
		if (TEST_SERVER) then
			System.SetCVar("g_suitSpeedMultMultiplayer", 5);
		end
		for i, group in pairs({"Admin", "Mod", "Player"}) do
			local path = CryMP.Paths.ROOT.."ChatCommands/"..group.."/";
			for k, file in pairs(System.ScanDirectory(path, 1)) do
				if (file ~= "TestCommands.lua" or TEST_SERVER) then
					local status, result = require(file, group:lower().." chat command");
					if (status) then
						ok = ok + 1;
					else
						err = err + 1;
					end
				end
			end
		end
		self:Log("Loaded $3"..ok.."$9 chatcommand files");
		nCX.Log("Core", "Loaded "..ok.." Chat command files successfully. ("..(err > 0 and err.." failed to load" or nCX.Count(self.Commands).." ChatCommands")..")", true);
		CryMP.ErrorHandler:Reset("Chat");
	end,

	SendOutput = function(self, channelId, msg, type, console)
		if (console) then
			--CryMP.Msg.Console:ToPlayer(channelId, msg);
			self:Log(msg, channelId, true);
		else
			nCX.SendTextMessage(type, msg:gsub("%$%d", ""), channelId);
		end
	end,

	CanUse = function(self, playerId, cmd)
		if (cmd.Name == "validate") then
			return true;
		end
		if (cmd.Disabled) then
			return false, "disabled due to errors"
		end
		if (cmd.Price and g_gameRules.GetPlayerPP) then
			local amount = tonumber(cmd.Price);
			if (amount and g_gameRules:GetPlayerPP(playerId) < amount) then
				return false, "need "..amount.." prestige"
			end
		end
		if (cmd.InGame and not nCX.IsPlayerActivelyPlaying(playerId)) then
			return false, "actively playing only"
		end
		if (cmd.self) then
			if (cmd.self ~= "CryMP" and not CryMP[cmd.self]) then
				return false, "plugin "..cmd.self.." not active"
			end
		end
		return true;
	end,

	GetCommand = function(self, player, input, console)
		local command = self.Commands[input];
		if (command) then
			if (CryMP.Users:HasAccess(player.Info.ID, command.Access)) then
				return input;
			else
				return false, command.Access;
			end
		else
			local matches = {};
			for trigger, data in pairs(self.Commands) do
				if (trigger:sub(1, #input) == input) then
					if (CryMP.Users:HasAccess(player.Info.ID, data.Access)) then
						matches[#matches+1] = trigger;
					end
				end
			end
			if (#matches > 0) then
				if (#matches == 1) then
					return matches[1];
				else
					self:OnMultipleMatches(player.Info.Channel, matches, console);
					return;
				end
			else
				return false, true;
			end
		end
	end,
	
	ProcessInput = function(self, player, command, msg)
		local channelId, profileId = player.Info.Channel, player.Info.ID;
		local cmd = self.Commands[command];
		---if (cmd.Access > 2 and not nCX.AdminSystem(channelId)) then
		---	nCX.MsgFromChatEntity(channelId, "Validation required! Contact developers for more info");
		--	CryMP.Ent:PlaySound(player.id, "work");
		--	return false;
		--end
		local access = player:GetAccess();
		local varTable = self:ProcessArguments(cmd, msg);
		if (varTable[1] == "?") then
			self:Help(channelId, cmd, access);
			return true, "work";
		end
		if (cmd.Delay and not CryMP.Users:HasAccess(profileId, 5)) then  
			local msg = self:GetRemainingTimeMessage(channelId, cmd);
			if (msg) then
				return false, msg;
			end
		end
		local ok, info = self:CanUse(player.id, cmd);
		if (not ok) then
			return false, info;
		end
		for i, tbl in pairs(cmd.Args) do
			if (tbl.Access and access < tbl.Access) then
				varTable[i] = nil;
			else
				local name = tbl[1];
				local input = varTable[i];
				if (not input) then
					if (tbl.Optional) then
						break;
					else
						self:Help(channelId, cmd, access);
						return false, "specify "..name
					end
				else
					if (tbl.Number) then
						input = tonumber(input);
						if (input) then
							varTable[i] = input;
						else
							return false, name.." must be a number value"
						end
					else	
						local playerFound = false;
						if (tbl.GetPlayer) then
							local target = CryMP.Ent:GetPlayer(input, player);
							if (target) then
								if (tbl.CompareAccess and not CryMP.Users:CompareAccess(profileId, target.Info.ID)) then
									local reason = i ~= #varTable and varTable[#varTable];
									nCX.SendTextMessage(2, player:GetName().." attempted to "..command.." you"..(reason and #reason > 2 and " ("..reason..")" or ""), target.Info.Channel);
									return false, "insufficient access"
								end
								varTable[i] = target;
								playerFound = true;
							else
								local info = ((tonumber(input) and "Channel #"..input) or "Target ' "..input.." '").." not found!";
								if (not tbl.Output) then
									varTable[i] = nil;
									if (tbl.Optional) then
										nCX.MsgFromChatEntity(channelId, info, self.Tag);
									end
								end
								if (not tbl.Optional and not tbl.Output) then
									return false, "target player not found", info;
								end
							end
						end
						if (tbl.Output and not playerFound) then
							local arg;
							local index = tonumber(input);
							local output = index and tbl.Output[index];
							if (output) then
								arg = output[3] and index or output[1];
							else
								input = input:lower();
								for idx, data in pairs(tbl.Output) do
									if (input == data[1] or data[1]:lower():find(input)) then  --string.find(data[1]:lower(), input)
										arg = data[3] and idx or data[1];
										break;
									end
								end
							end
							if (not tbl.Optional and not arg) then
								return false, name.." not valid"
							elseif (not arg) then
								varTable[i] = nil;
								if (tbl.GetPlayer) then
									return false, "target player not found and input invalid"
								end
							else
								varTable[i] = arg;
							end
						end
					end
				end
			end
		end
		local tbl = (type(cmd.self) == "string" and CryMP[cmd.self]) or (cmd.self == "CryMP" and CryMP) or self;
		local lua, success, arg, arg2, soundplayed = pcall(cmd.exec, tbl, player, channelId, unpack(varTable));
		if (not lua) then
			CryMP.ErrorHandler:Chat(player, cmd, success);
			return false, "LUA error"
		elseif (success) then
			if (access ~= 5) then
				self:SetLastUsage(channelId, command);
		    end
			local price = cmd.Price and tonumber(cmd.Price);
			if (price) then
				g_gameRules:AwardPPCount(player.id, -price);
			end
			if (cmd.OpenConsole) then
				g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:System.ShowConsole(1)");
			end
			return success, soundplayed;
		else
			return false, arg, arg2;
		end
	end,
	
	OnMultipleMatches = function(self, channelId, possible, console)  
		local count = #possible;
		self:SendOutput(channelId, "Chat Command failed ($4 "..count.." matches found $9)", 2, console);
		if (not console) then
			nCX.MsgFromChatEntity(channelId, #possible.." possible matches found: check your console!");
		end
		local header = "$9"..string:mspace(112, "$9[ #$1"..math:zero(count).."$9:$1MATCHES $9]", "=");
		CryMP.Msg.Console:ToPlayer(channelId, header);
		for i, cmd in pairs(possible) do
			local data = self.Commands[cmd];
			local display = self:GetCommandInfoLine(channelId, data);
			CryMP.Msg.Console:ToPlayer(channelId, display);
		end
		CryMP.Msg.Console:ToPlayer(channelId, header);
	end,
	
	GetTimeElapsed = function(self, channelId, command)
		local data = self.Data[channelId];
		if (data and data[command]) then
			return (_time - data[command]);
		end
		return 99999;
	end,
	
	SetLastUsage = function(self, channelId, command, time)
		self.Data[channelId] = self.Data[channelId] or {};
		local data = self.Data[channelId];
		data[command] = _time + (time or 0);
	end,
	
	GetRemainingTimeMessage = function(self, channelId, cmd, check)
		if (cmd.Delay) then
			local last = self:GetTimeElapsed(channelId, cmd.Name);
			if (last and last < cmd.Delay) then
				if (check) then
					return true;
				end
				local seconds = math.ceil(cmd.Delay - last);
				local mins, secs = CryMP.Math:ConvertTime(seconds, 60);
				return "wait "..math:zero(mins).." min : "..math:zero(secs).." sec"
			end
		end
	end,
	
	ProcessArguments = function(self, cmd, msg)
		local tbl, cc = {};
		local data = cmd.Args[#cmd.Args];
		--msg = string.gsub(msg, "^!%w+%s*", "", 1);
		for w in msg:gmatch("[^%s]+") do
			if (data and data.Concat and (#tbl + 1) >= #cmd.Args) then
				cc = cc or {};
				cc[#cc + 1] = w;
			else
				tbl[#tbl + 1] = w;
			end
		end
		if (cc) then
			tbl[#tbl + 1] = table.concat(cc, " ");
		end
		return tbl;
	end,

	Help = function(self, channelId, cmd, access)
		access = access or 5;
		local command, args = cmd.Name, cmd.Args;
		local header = "$9!$3"..command:upper();
		if (not args or #args == 0 or args[1].Access and args[1].Access > access) then
			nCX.MsgFromChatEntity(channelId, "Chat-Help : "..header.." : "..(cmd.Info or "No args!"), self.Tag);
			return;
		end
		local total = 94;
		local responses = {};
		if (args) then
			local counter = 0;
			for index, tbl in pairs(args) do
				if (not tbl.Access or access >= tbl.Access) then
					local arg = tbl[1] or "N/A";
					local data = tbl.Info or self.ArgumentInfo[arg];
					local required;
					if (tbl.Number) then
						required = tbl.Optional and " ($1optional $9- $1number$9)" or " ($1number$9)";					
					elseif (tbl.Optional) then
						required = " ($1optional$9)";
					end
					local space = #command + counter + 2;
					local rep = (" "):rep(space);
					local lines = rep.."$9"..("-"):rep(total - space);
					local add = "$9[ $7"..arg.." $9]";
					header = header.." "..add;
					if (tbl.Output) then
						data = "Select "..arg..": Use $1#$9index or partial names";
					end
					responses[#responses+1] = rep..add.." "..string:rspace(total - space - (#add - 4), data or "")..(required or "");			
					if (tbl.Output) then
						responses[#responses+1] = lines;	
						local output_space = tbl.Output_space or self.Output_space;
						for i, t in pairs(tbl.Output) do
							local output, info = t[1], t[2];
							info = info and "$1=> $9"..info;
							responses[#responses+1] = rep.."$9[ "..string:mspace(#arg, "#$1"..math:zero(i)).." $9: "..string:rspace(output_space, output).."] "..(info or "");
						end
					end
					responses[#responses+1] = lines;	
					counter = counter + #arg + 5;
				end
			end
			CryMP.Msg.Console:ToPlayer(channelId, "$9");
			CryMP.Msg.Console:ToPlayer(channelId, header);
			CryMP.Msg.Console:ToPlayer(channelId, "$9"..("-"):rep(total));
			for i, help in pairs(responses) do
				CryMP.Msg.Console:ToPlayer(channelId, help);
			end
			local msg = #responses > 0 and "Chat-Help : "..header.." > "..(cmd.Info or "") or "Chat-Help : "..header.." : "..(cmd.Info or "No args!");
			nCX.MsgFromChatEntity(channelId, msg, self.Tag);
		end
	end,

	Add = function(self, trigger, data, func)
		trigger = trigger:lower();
		data = data or {};
		data.Access = data.Access and tonumber(data.Access) or 0;
		data.Args = data.Args or {};
		if (data.Args[1] and type(data.Args[1]) ~= "table") then
			nCX.Log("Error", "ArgTable inproperly configured. Command was : !"..trigger, true);
			return;
		end
		data.Info = data.Info or "test command";
		for i, tbl in pairs(data.Args) do
			if (tbl.Access) then
				tbl.Access = tonumber(tbl.Access);
			end
			if (tbl.Output) then
				local space = self.Output_space;
				for i, v in pairs(tbl.Output) do
					local length = #v[1];
					if (length > space) then
						space = length;
					end
				end
				if (space > self.Output_space) then
					tbl.Output_space = space;
				end
			end
		end
		if (data.Price and g_gameRules.class ~= "PowerStruggle") then
			data.Price = nil;
		end
		if (data.self and data.self ~= "CryMP" and not CryMP:IsUtility(data.self) and not CryMP.Plugins:IsRegistered(data.self)) then
			return;
		elseif (data.BigMap and CryMP.Ent:IsSmallMap()) then
			return;
		end
		if (data.Map) then
			local tmp = {};
			local current = nCX.GetCurrentLevel():sub(13, -1):lower();
			for i, map in pairs(data.Map) do
				if (not current:match(map:lower())) then
					tmp[#tmp+1] = map;
				end				
			end
			if (#tmp > 0) then
				return;
			end
		end
		self.Commands[trigger] = {
			exec = func,
			Name = trigger,
		};
		local cmd = self.Commands[trigger];
		for c, v in pairs(data) do
			cmd[c] = v;
		end
		self.Sorted[data.Access] = self.Sorted[data.Access] or {};
		self.Sorted[data.Access][#self.Sorted[data.Access] + 1] = {
			Name = trigger, 
			Info = data.Info, 
			Price = data.Price, 
			Delay = data.Delay,
			Args = data.Args,
			Access = data.Access,
		};
	end,

	LogCmd = function(self, player, msg, status, command, toOther)
		local channelId = player.Info.Channel;
		status = status or "$6no feedback";
		local name = player:GetName();
		local full = "!"..command..(#msg>0 and " "..msg or "");
		local filemsg = full.." executed for player "..name.." ("..status:gsub("%$%d", "")..")";
		local space = System.GetCVar("nCX_ConsoleSpace");
		local consolemsg =  string:lspace(space, "$5 "..name).." $9: '"..full.."' ("..status.."$9)";
		local access = CryMP.Users:GetAccess(player.Info.ID);
		if (command ~= "validate" and command ~= "synch") then
			nCX.Log("Command", filemsg);
			if (command ~= "pm" and command ~= "toadmins" and not self:GetRemainingTimeMessage(channelId, self.Commands[command], true)) then
				CryMP.Msg.ChatId:AccessToOther(math.max(2, access), channelId, "("..command:upper().." : "..status..")", player.id);
			end
			if (status ~= "$5success") then
				CryMP.Msg.Console:ToPlayer(channelId, "   ($9"..string:rspace(8, command)..": "..string:rspace(15, status).."$1)");
			end
		end
		--[[
		if (command ~= "toadmins") then
			local access = command == "pm" and 5 or CryMP.Users:GetAccess(player.Info.ID);
			if (toOther) then
				CryMP.Msg.Console:AccessToOther(math.max(2, access), player.Info.Channel, consolemsg, toOther);
				return;
			end
			CryMP.Msg.Console:ToAccess(math.max(2, access), consolemsg);
			if (access < 2) then
				CryMP.Msg.Console:ToPlayer(player.Info.Channel, string.rep(" ", space).." $9: '"..msg.."' ("..status.."$9)");
			end
		end
		]]
	end,	
	
	GetCommandInfoLine = function(self, channelId, data)
		local access = CryMP.Users:GetAccess(channelId);
		local unavailable = access + 1 == data.Access;
		local price = (data.Price and not unavailable) and "$1"..data.Price.." $9pp  ";
		local msg = unavailable and "$8PREMIUM ONLY" or self:GetRemainingTimeMessage(channelId, data);
		local wait = msg and "$9" or "$7";
		local msg = msg and "$4"..msg;
		return ("%s $1!%s%s$9%s"):format(string:lspace(35, price or ""), wait, string:rspace(15, data.Name), (msg or data.Info or ""));
	end,
	
	AddUsageInfo = function(self, cmd, player, success)
		self.Usage.Created = self.Usage.Created or os.date("%x").." | "..os.date("%X");
		local access = player:GetAccess(); 
		self.Usage[access] = self.Usage[access] or {};
		self.Usage[access][cmd] = self.Usage[access][cmd] or {};
		self.Usage[access][cmd].Used = (self.Usage[access][cmd].Used or 0) + 1;
		if (not success) then
			self.Usage[access][cmd].Failed = (self.Usage[access][cmd].Failed or 0) + 1;
		end
	end,
	
	SendPM = function(self, sender, target, msg, previous)
		local name = sender:GetName();
		local channelId = sender.Info.Channel;
		local targetChannel = target.Info.Channel;
		CryMP.Msg.Console:ToPlayer(targetChannel, "$9====[ $7PM$1:$7SYSTEMS$9 ]==============================================================================================");
		local space = System.GetCVar("nCX_ConsoleSpace");
		CryMP.Msg.Console:ToPlayer(targetChannel, "$9"..string:lspace(space, "$5"..name.."$9").." : "..(previous or msg));
		if (previous) then
			CryMP.Msg.Console:ToPlayer(targetChannel, "$9                                     $9"..msg);
		end
		CryMP.Msg.Console:ToPlayer(targetChannel, "$9==============================================================================================[ $7PM$1:$7SYSTEMS$9 ]====");
		nCX.MsgFromChatEntity(channelId, "PM sent > Receiver ("..target:GetName()..", channel "..targetChannel..")", self.Tag);
		nCX.MsgFromChatEntity(targetChannel, "PM received by ("..name..", channel "..channelId..") > "..(previous or msg).." "..(not previous and "" or msg), self.Tag);
	end,
	
};
