--==============================================================================
--!PLUGINS

CryMP.ChatCommands:Add("plugins", {
		Access = 4, 
		Args = {
			{"plugin", Optional = true, Info = "The Plugin name or index"},
		}, 
		Info = "control loaded plugins",
		self = "Plugins",
	}, 
	function(self, player, channelId, plugin, mode)
	--self.Ticks[1][name]
		local space = 40;
		local extra = space + 20;
		local config = CryMP.Config;
		local i = 0;
		local header = "$9"..string.rep("=", 112);
		local function display(name, dynamic, disabled)
			i = i + 1;
			local vname;
			if (dynamic) then
				if (self.List[name]) then
					vname = "$6"..name;
				else
					vname = "$9"..name.." "..string:lspace(extra - #name, "($1inactive$9)");
				end
			elseif (disabled) then
				vname = name.." $9"..string:lspace(extra - #name, "($4disabled$9)");
			end
			CryMP.Msg.Console:ToPlayer(channelId, "$9[#$1"..math:zero(i).."$9]   $7"..(vname or name));
			for event, tbl in pairs(CryMP.EventCache or {}) do
				for i, v in pairs(tbl) do
					if (v == name) then
						local c = CryMP.ErrorHandler:GetEventCount(name, event);
						CryMP.Msg.Console:ToPlayer(channelId, string.rep(" ", space).."$9"..string:rspace(20, event)..(c > 0 and "$4"..c.." error(s)" or ""));
					end
				end
			end
			CryMP.Msg.Console:ToPlayer(channelId, "$9"..header);
		end
		if (not plugin or #plugin < 3) then
			CryMP.Msg.Console:ToPlayer(channelId, header);
			for name, data in pairs(self.List) do
				if (not self:IsDynamic(name)) then
					display(name, false, false)
				end
			end
			for name, data in pairs(config) do
				if (data ~= false and not self.List[name]) then
					display(name, false, true)
				end
			end
			for name, data in pairs(config) do
				if (data == false) then
					display(name, true, false)
				end
			end
			return true;
		end
		local data = config[plugin];
		if (not data) then
			return false, "plugin not found";
		end
		display(plugin, false, false)
		return true;
	end
);
