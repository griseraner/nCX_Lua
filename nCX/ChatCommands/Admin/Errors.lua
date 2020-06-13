--==============================================================================
--!ERRORS

CryMP.ChatCommands:Add("errors", {
		Access = 4, 
		Args = {
			{"mode", Access = 5, Optional = true, Output = {{"clear", "Clear the errors",},},},
		}, 
		Info = "list mod errors",
		self = "ErrorHandler",
	}, 
	function(self, player, channelId, mode)
		if (mode == "clear") then
			self:Reset();
			return true;
		end
		if (self.Errors and self:GetStatus() > 0) then
			local function display(tbl)
				local count = tbl.Total or tbl.Count;
				if (count < 10) then
					count="0"..count;
				end
				CryMP.Msg.Console:ToPlayer(channelId, "$5[$4%s$5] [$4%s$5] [$4%s$5:$7%s$5]  $4%s",
					count,
					string:mspace(12,tbl.Type),
					string:lspace(22,tbl.File),
					string:lspace(4,tbl.Line),
					tbl.Error	
				);
			end
			for type, data in pairs(self.Errors) do
				for name, tbl in pairs(data) do
					if (type == "Plugin") then
						for event, tbl in pairs(tbl) do
							display(tbl)
						end
					else
						display(tbl)
					end
				end
			end
			return true;
		end
		return false, "no errors found"
	end
);
