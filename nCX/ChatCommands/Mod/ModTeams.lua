--==============================================================================
--!TEAM [PLAYER] [TEAM]

CryMP.ChatCommands:Add("team", {
		Access = 2, 
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
			{"team", Optional = true, Output = {{"nk", "NK Team", true},{"us", "US Team", true},{"spec", "Spectator", true},},},
		}, 
		Info = "switch the team of a player", 
		self = "Library",
	}, 
	function(self, player, channelId, target, team)
		if (target:IsDuelPlayer()) then
			return false, "target is duelplayer"
		end
		return self:Team(target, team);
	end
);

--==============================================================================
--!INGAME [PLAYER]

CryMP.ChatCommands:Add("ingame", {
		Access = 2, 
		Args = {
			{"player", Optional = true, GetPlayer = true, CompareAccess = true,},
		}, 
		Info = "force spectators to team",
	},
	function(self, player, channelId, target)
		if (not target) then
			local count = 0;
			for i, spectator in pairs(nCX.GetTeamPlayers(0) or {}) do
				local spectatorId = spectator.id;
				if (not CryMP.Users:CompareAccess(player.Info.ID, spectator.Info.ID)) then
					CryMP.Msg.Chat:ToPlayer(channelId, "Ingame forcing of "..spectator:GetName().." denied - insufficient access!");
				else
					g_gameRules:AutoAssignTeam(spectatorId);
					if (g_gameRules.class == "PowerStruggle") then
						g_gameRules:QueueRevive(spectator);
					else
						g_gameRules:RevivePlayer(spectator);
					end
					CryMP.Msg.Chat:ToPlayer(spectator.Info.Channel, "Welcome InGame.. :)");
					count = count + 1;
				end
			end
			if (count > 0) then
				nCX.SendTextMessage(2, "[ IN:GAME ] Forced "..count.." spectator(s) to game (Admin Decision)", 0);
				return true;
			end
			nCX.SendTextMessage(2, "[ IN:GAME ] No spectators were moved to game", channelId);
			return false, "no spectators";
		end
		if (target.actor:GetSpectatorMode()==0) then
			return false, "target is not a spectator"
		end
		local targetId = target.id;
		local name = target:GetName();
		g_gameRules:AutoAssignTeam(targetId);
		if (g_gameRules.class == "PowerStruggle") then
			g_gameRules:QueueRevive(targetId);
		else
			g_gameRules:RevivePlayer(target);
		end
		CryMP.Msg.Chat:ToPlayer(target.Info.Channel, "Welcome InGame.. :)");
		nCX.SendTextMessage(2, "Forced spectator '"..name.."' to game (Admin Decision)", 0);
		CryMP.Msg.Chat:ToPlayer(channelId, "Forced spectator "..name.." into game!");
		return true;
	end
);
