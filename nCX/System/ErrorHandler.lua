CryMP.ErrorHandler = {
		
	---------------------------
	--		Config
	---------------------------
	Threshold 		= 5,
	Tag 			= 14,
	Errors = {
		Timer 		= {},
		File 		= {},
		ChatCommand = {},		
		Plugin 		= {},
	},
	
	Server = {
		
		OnFileLoad = function(self, file, type)
			if (type == "plugin") then 
				self:Reset("Plugin", file);
			end
		end,
		
	},
	
	OnShutdown = function(self, restart)
		if (not restart) then
			self:Reset();
		end
	end,
	
	Reset = function(self, type, name)
		if (type) then
			if (type ~= "Plugin") then
				self.Errors[type] = {};
			elseif (name) then
				self.Errors.Plugin[name] = nil;
			end
			return;
		end
		self.Errors = {
			Timer = {},
			File = {},
			ChatCommand = {},		
			Plugin = {},
		},
		nCX.Log("Error", "Erasing error logs...");
	end,

	Add = function(self, type, name, file, line, error, event)
		local errors = self.Errors[type];
		errors[name] = errors[name] or {};
		local tbl = errors[name];
		if (event) then
			tbl[event] = tbl[event] or {};
			tbl = tbl[event];
		end
		tbl.Type = type;
		tbl.Name = name;
		tbl.File = file;
		tbl.Line = line or "N/A";
		tbl.Error = error;
		tbl.Count = (tbl.Count or 0) + 1;
		tbl.Event = event;
		if (event) then -- if Plugin
			tbl.Total = self:GetPluginCount(name);
		end
		return tbl, tbl.Count;
	end,
	
	Chat = function(self, player, cmd, msg)
		local channelId = player.Info.Channel;
		local file, line, error = self:Convert(msg);
		local command = "!"..cmd.Name;
		local tbl, count = self:Add("ChatCommand", command, file, line, error);
		if (count == self.Threshold) then
			CryMP.Msg.Chat:ToPlayer(channelId, "Sorry "..player:GetName()..", this command seems to be broken!", self.Tag);
			CryMP.Msg.Chat:ToPlayer(channelId, "One of our coders will take a look as soon as possible!", self.Tag);
			tbl.Action = "command disabled";
			cmd.Disabled = true;
		else
			CryMP.Msg.Chat:ToPlayer(channelId, "Sorry "..player:GetName()..", there seems to be an error!", self.Tag);
		end
		self:LogError(tbl, nil, player);
	end,

	File = function(self, msg, filename)
		local report = (debug.traceback(msg or "nil",2) or "FAILED TRACEBACK");
		local file, line, error;
		--disabled for testing! id actually like to know whats wrong..
		--if (#report > 1000) then
		--	file = filename;
		--	line = "N/A";
		--	report = "module "..filename..".lua not found";
		--else
			file, line, error = string.match(msg, ".*%/(.+)%.lua%:(.+)%:%s(.*)");
		--end
		error = error or "module not found";
		file = file or filename;
		local tbl = self:Add("File", file, file..".lua", line, error);
		self:LogError(tbl, report);
		return true;
	end,

	Plugin = function(self, plugin, event, msg, check)
		local pluginId = plugin.id;
		local file, line, error = self:Convert(msg);
		local tbl, count = self:Add("Plugin", pluginId, pluginId..".lua", line, error, event);
		local trace;
		--if (check) then
			trace = (debug.traceback(msg or "nil",2) or "FAILED TRACEBACK");
		--end
		if (pluginId ~= "CryMP" and not CryMP.Utilities[pluginId]) then
			if (event == "OnTick") then
				plugin:SetTick(false);
			elseif (event == "OnUpdate") then
				plugin:SetUpdate(false);
			elseif (not plugin.Required) then
				plugin:ControlEvents(event, false);
			end
			if (self:GetPluginCount(pluginId) >= self.Threshold or CryMP.Config[pluginId] == false) then
				if (not plugin.Required) then
					plugin.error = true;
					plugin:ShutDown(true);
					tbl.Action = "plugin disabled";
				end
			end	
			if (not plugin.Required) then
				tbl.Action = tbl.Action or "event disabled";
			end
		end
		self:LogError(tbl, trace); 
	end,
	
	Timer = function(self, name, msg)
		local file, line, error = self:Convert(msg);
		local tbl, count = self:Add("Timer", name, file..".lua", line, error);
		self:LogError(tbl);
	end,

	LogError = function(self, tbl, trace, player)
		local playerInfo = (player and "["..player:GetName().." ("..player.Info.ID..")]") or "";
		local name = tbl.Name;
		local action = tbl.Action or "$5logged$9";
		action = tbl.Event and tbl.Event..", "..action or action;
		local date = os.date("%H:%M:%S", time);
		local error = tbl.Error;
		error = trace and tbl.Error.." "..trace or error;
		local line = "["..tbl.Type.."] ["..tbl.File..":"..tbl.Line.."] ["..name.."] "..playerInfo.." ["..tbl.Count.." time(s)] "..error.." ("..action..")";
		
		nCX.Log("Error", line:gsub("%$%d", ""), true);
		local msg = self:GetMessage(tbl.Type);
		msg = msg:format(tbl.Total or tbl.Count, name, action);
		if (tbl.Type ~= "ChatCommand") then
			CryMP.Msg.Chat:ToAccess(2, msg, self.Tag);
		end
		if (tbl.Type ~= "File") then
			self:Log(msg, 5);
		end
		local space = System.GetCVar("nCX_ConsoleSpace");
		CryMP.Msg.Console:ToAccess(5, "$4"..string:lspace(space, tbl.File).."$9 : %s (Line $7%s$9)", tbl.Error, tbl.Line);
		CryMP.Msg.Info:ToAccess(5, "[ "..tbl.File.." : "..tbl.Line.." ] "..tbl.Error);
	end,

	Inform = function(self, tbl, channelId)
		if (tbl) then
			self:SendError(tbl, channelId);
		else
			for type, data in pairs(self.Errors) do
				for name, tbl in pairs(data) do
					if (type == "Plugin") then
						for event, tbl in pairs(tbl) do
							self:SendError(tbl, channelId);
						end
					else
						self:SendError(tbl, channelId);
					end
				end
			end
		end
	end,

	SendError = function(self, tbl, channelId)
		local msg = self:GetMessage(tbl.Type);
		msg = msg:format(tbl.Count, tbl.Name, "$4"..(tbl.Action or "$6logged"));
		if (channelId) then
			if (channelId == 0) then
				System.LogAlways("[$4CryMP Error$9] "..msg);
				return;
			end
			local space = System.GetCVar("nCX_ConsoleSpace");
			CryMP.Msg.Console:ToPlayer(channelId, "$4"..string:lspace(space, msg));
		else
			self:Log(msg,5);
		end
	end,
	
	GetMessage = function(self, typ)
		if (typ == "File") then
			return "$5[$4%d$5]$9 failures to load File %s.lua (%s$9)";
		end
		return "$5[$4%d$5]$9 error(s) from "..typ.." %s (%s$9)"; 
	end,
	
	Convert = function(self, msg)
		if (msg:sub(1, 7) == "[string") then
			local line, error = msg:match("%:(%d+)%:%s(.*)$");
			return "N/A", line, error;
		end
		return msg:match(".*%/(.+)%.lua%:(.+)%:%s(.*)"); 
	end,
	
	GetPluginCount = function(self, hook)
		local count = 0;
		if (hook and hook~="") then
			local data = self.Errors.Plugin[hook];
			for event, tbl in pairs(data or {}) do
				count = count + tbl.Count;
			end
		else
			for hook, data in pairs(self.Errors.Plugin) do
				for event, tbl in pairs(data) do
					count = count + tbl.Count;
				end
			end	
		end
		return count
	end,
	
	GetEventCount = function(self, hook, event)
		local count = 0;
		local data = self.Errors.Plugin[hook or ""];
		if (data and data[event]) then
			return data[event].Count;
		end
		return count;
	end,
	
	GetStatus = function(self)
		local count = 0;
		for type, errors in pairs(self.Errors) do
			if (type == "Plugin") then
				count = count + self:GetPluginCount();
			else
				for name, tbl in pairs(errors) do
					count = count + 1;
				end
			end
		end
		return count;
	end,

};

System.AddCCommand("err", "CryMP.ErrorHandler:Inform(false, 0)", "show errors");