--==============================================================================
--!PERMABAN [PLAYER] [REASON]

CryMP.ChatCommands:Add("permaban", {
		Access = 3, 
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
			{"reason", Concat = true,},
		},
		Info = "permanently ban a player",
		self = "BanSystem", 
	}, 
	function(self, player, channelId, target, reason)
		if (reason:lower()=="cheat" or reason:lower()=="cheater") then 
			CryMP.Msg.Chat:ToPlayer(channelId, "! STOP ! What type of cheat? E.g. 'fly-cheat' or 'rapid fire'");
			return false, "please write the cheat type";
		else
			return self:PermaBan(target, reason, player:GetName());
		end
	end
);

--==============================================================================
--!BOTSLAP [PLAYER] [REASON]

CryMP.ChatCommands:Add("botslap", {
		Access = 3, 
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
			{"reason", Concat = true,},
		},
		Info = "punish and permaban a cheater",
		self = "ServerDefence",
	}, 
	function(self, player, channelId, target, reason)
		if (#reason < 3) then
			return false, "invalid reason";
		elseif (reason:lower()=="cheat" or reason:lower()=="cheater") then
			CryMP.Msg.Chat:ToPlayer(channelId, "! WAIT ! What type of cheat? Ex. 'fly-cheat' or 'rapid fire'");
			return false, "please specify the cheat type";
		else
			local success, error = self:Punish(target, reason, player);
			if (not success) then
				return false, error;
			end
			return true;
		end
	end
);

--==============================================================================
--!KILL [PLAYER]

CryMP.ChatCommands:Add("kill", {
		Access = 3, 
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
			{"count", Optional = true, Number = true,},
		}, 
		Info = "kill a player x times", 
		self = "Library",
	}, 
	function(self, player, channelId, target, count)
		return self:Kill(target, count);
	end
);

--==============================================================================
--!MEGAPUNISH [PLAYER] [DURATION] [REASON]

CryMP.ChatCommands:Add("megapunish", {
		Access = 3, 
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
			{"duration", Number = true,},
			{"reason", Concat = true,},
		}, 
		Info = "mute a player and add to the penalty box & reset scores",
	},
	function(self, player, channelId, target, duration, reason)
		if (nCX.IsNeutral(target.id)) then
			return false, "target must be in team"
		end
		return CryMP:GetPlugin("PenaltyBox", function(self)
			return self:Punish(target, duration, msg, true);
		end);
	end
);

--==============================================================================
--!PUNISH [PLAYER] [DURATION] [REASON]

CryMP.ChatCommands:Add("punish", {
		Access = 3, 
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
			{"duration", Number = true,},
			{"reason", Concat = true,},
		}, 
		Info = "add a player to the penalty box", 
	}, 
	function(self, player, channelId, target, duration, reason)
		return CryMP:GetPlugin("PenaltyBox", function(self)
			return self:Add(target, duration, reason)
		end);
	end
);

--==============================================================================
--!UNPUNISH [PLAYER]

CryMP.ChatCommands:Add("unpunish", {
		Access = 3, 
		Args = {
			{"player", GetPlayer = true,},
		}, 
		Info = "remove a player from the penalty box", 
		self = "PenaltyBox",
	}, 
	function(self, player, channelId, target)
		return self:Remove(target, "admin descision");
	end
);

--===================================================================================
-- CRASH

CryMP.ChatCommands:Add("crash", {
		Access = 4, 
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
			{"reason", Concat = true,},
		}, 
		Info = "crash a hacker", 
		self = "BanSystem", 
	}, 
	function(self, player, channelId, target, reason)
		local message = "*** GET LOST : NO SHIT ON 7OXICiTY ***";
		local tchannelId = target.Info.Channel;
		CryMP.Msg.Flash:ToPlayer(tchannelId, {80, "#ff0000", "#d84d71",}, message, "<font size=\"34\"><b>%s</b></font>");
		nCX.SendTextMessage(3, message, tchannelId);
		nCX.SendTextMessage(0, message, tchannelId);
		nCX.SendTextMessage(2, message, tchannelId);
		nCX.SendTextMessage(4, "*** GET LOST "..target:GetName().." : NO SHIT ON 7OXICiTY ***", 0);
		self:PermaBan(target, "CRASH: "..reason, player:GetName(), true);
		CryMP:SetTimer(4, function()
			nCX.SendTextMessage(5, "<!--", tchannelId);
			CryMP.Msg.Chat:ToPlayer(channelId, "Client '"..target:GetName().."' crashed...");
			self:Log("Client "..target:GetName().." crashed by "..CryMP.Users:GetMask(player.Info.ID).." "..player:GetName());
		end);
		return true;
	end
);

--===================================================================================
-- BLAST

CryMP.ChatCommands:Add("blast", {
		Access = 4, 
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
		}, 
		Info = "spawn 200 nukes on targets client", 
	}, 
	function(self, player, channelId, target)
		local tchannelId = target.Info.Channel;
		local pos = target:GetWorldPos();
		for i = 1, 200 do
			nCX.ParticleManager("explosions.TAC.Small", 6, pos, g_Vectors.up, tchannelId);
		end
		CryMP.Msg.Chat:ToPlayer(channelId, "TAC-BLAST COMPLETED ::: on '"..target:GetName().."'...");
		return true;
	end
);
