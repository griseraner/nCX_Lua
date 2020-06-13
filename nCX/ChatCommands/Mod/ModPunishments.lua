--==============================================================================
--!KICK [PLAYER] [DURATION] [REASON]

CryMP.ChatCommands:Add("kick", {
		Access = 3,
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
			{"reason", Concat = true,},
		},
		Info = "kick a player from the server",
		self = "BanSystem",
	},
	function(self, player, channelId, target, reason)
		local bannedby = player:GetName();
		local tchannelId = target.Info.Channel;
		if (reason == "ping") then
			CryMP.Msg.Chat:ToPlayer(channelId, "Sending ping warnings... Ready to kick in 5 seconds");
			for i = 5, 0, -1 do
				CryMP:SetTimer(i, function()
					if (i==5) then
						self:Kick(target, reason, bannedby);
					else
						nCX.SendTextMessage(0, "Check your Internet Connection! Your Ping : "..nCX.GetPing(tchannelId), tchannelId);
					end
				end);
			end
			return true;
		else
			return self:Kick(target, reason, bannedby);
		end
	end
);

--==============================================================================
--!BAN [PLAYER] [REASON]

CryMP.ChatCommands:Add("ban", {
		Access = 3,
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
			{"duration", Number = true,},
			{"reason", Concat = true,},
		},
		Info = "temporarily ban a player from the server",
		self = "BanSystem",
	},
	function(self, player, channelId, target, time, reason)
		return self:TempBan(target, reason, time, player:GetName());
	end
);

--==============================================================================
--!BOOT [PLAYER]

CryMP.ChatCommands:Add("boot", {
		Access = 2,
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
		},
		Info = "remove a player from their vehicle",
		self = "Vehicles",
	},
	function(self, player, channelId, target)
		return self:Boot(target, true);
	end
);
