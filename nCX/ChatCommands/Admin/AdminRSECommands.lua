--==============================================================================
--!INSTALL

CryMP.ChatCommands:Add("install", {
		Access = 3, 
		Args = {
			{"player", Optional = false, GetPlayer = true, Output = {{"all", "All players"},},},
		}, 
		Info = "patch client",
		self = "RSE",
	}, 
	function(self, player, channelId, target)
		local msg;
		if (type(target) == "table") then
			player = target;
			msg = target:GetName();
		elseif (target == "all") then
			CryMP.Msg.Chat:ToPlayer(channelId, "REINSTALLING ALL ::"); 
			msg = "ADMINS";
			for i, p in pairs(nCX.GetPlayers() or {}) do
				self:GetMods(p, true);
			end
			return true;
		else
			msg = "YOU";
		end
		self:GetMods(player, true);
		return true;
	end
);