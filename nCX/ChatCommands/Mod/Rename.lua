--==============================================================================
--!NAME [PLAYERNAME] [NEWNAME]

CryMP.ChatCommands:Add("rename", {
		Access = 2,
		Args = {
			{"player", GetPlayer = true, CompareAccess = true},
			{"name", Concat = true,},
		}, 
		Info = "rename a player",
		self = "Ent",
	}, 
	function(self, player, channelId, target, newname)
		local name = target:GetName();
		local ok, err, info = self:Rename(target, newname, "admin descision");
		if (ok) then
			nCX.SendTextMessage(0, "Player "..name.." renamed to "..newname, channelId);
			return true;
		else
			return false, err, info;
		end
	end
);
