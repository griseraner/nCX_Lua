--==============================================================================
--!MUTE [PLAYER]

CryMP.ChatCommands:Add("mute", {
		Access = 3, 
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
			{"duration", Number = true,},
		}, 
		Info = "mute a player from the chat",
	}, 
	function(self, player, channelId, target, duration)
		return CryMP:GetPlugin("Mute", function(self)
			return self:Add(target, duration);
		end);
	end
);

--==============================================================================
--!UNMUTE [PLAYER]

CryMP.ChatCommands:Add("unmute", {
		Access = 3, 
		Args = {
			{"player", GetPlayer = true,},
		}, 
		Info = "unmute a player from the chat", 
		self = "Mute", 
	}, 
	function(self, player, channelId, target)
		return self:Remove(target, "admin descision");
	end
);