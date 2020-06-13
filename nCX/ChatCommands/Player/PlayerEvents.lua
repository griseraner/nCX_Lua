--==============================================================================
--!BOXING

CryMP.ChatCommands:Add("boxing", {
		Info = "enter the boxing arena",
		self = "Boxing",
	},
	function(self, player, channelId)
		if (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		elseif (player:IsRacing()) then
			return false, "not while racing"
		elseif (player:IsAfk()) then
			return false, "not while afk"
		end
		return self:Teleport(player, false);
	end
);

--==============================================================================
--!DUEL

CryMP.ChatCommands:Add("duel", {
		Info = "challenge a player to a duel", 
		Args = {
			{"player", GetPlayer = true,},
			{"weapon", Optional = true, 
				Output = {
					{"random", "A random weapon will be selected for you", true},
					{"c4", "Unlimited C4 during fight", true},
					{"fists",nil,true},{"minigun",nil,true},{"dsg1",nil,true},{"moac",nil,true},{"shotgun",nil,true},{"gauss",nil,true},{"pistol",nil,true},{"scar",nil,true},{"fy71",nil,true},{"smg",nil,true},{"superscar","Super high damage SCAR",true},
				},
			},
			{"mode", Optional = true,
				Output = {
					{"hardcore", "Damages decreased by 40 percent", true},
					{"frag", "Frag delivery mode", true}, 
					{"gfrag", "Frag delivery mode and Zero Gravity", true}, 
					{"gravity", "Zero Gravity", true},
				},
			},
		},
		Map = {"ps/mesa"},
		InGame = true,
		self = "CryMP",
	}, 
	function(self, player, channelId, target, weapon, mode)
		if (self.Duel) then
			return false, self.Duel:GetStatus();
		end
		if (player:IsRacing()) then
			return false, "cannot use while racing"
		elseif (nCX.IsSameTeam(target.id, player.id)) then
			return false, "can only duel enemies"
		elseif (target.actor:GetSpectatorMode()~=0) then
			return false, "target is spectating"
		elseif (target:IsRacing()) then
			return false, "target is racing"
		elseif (target:IsBoxing()) then
			return false, "target is boxing"
		end
		return self:GetPlugin("Duel", function(self)
			return self:Process(player, target, weapon, mode);
		end);
	end
);

--==============================================================================
--!VOTE

CryMP.ChatCommands:Add("vote", {
		Info = "call a vote",
		Args = {
			{"mode", Output= {{"Vtol", "disable/enable vtols"}, {"Kick", "kick a specific player"}, {"Mute", "mute a specific player"}, --[[{"Nextmap", "proceed to the next level in rotation"}]]}},
			{"player", Optional = true, GetPlayer = true, CompareAccess = true},
		},
		Delay = 2000,
	},
	function(self, player, channelId, mode, target)
		if (mode == "Vtol" and g_gameRules.class ~= "PowerStruggle") then
			return false, "map not supported";
		end
		local staff = CryMP.Users:GetUsers(2, false, true);
		if (staff and not staff[channelId]) then
			return false, "admin is online", "Ask admin via !toadmins";
		end
		local tchannel = (target and target.Info.Channel) or (mode ~= "Vtol" and mode ~= "Nextmap" and 0) or -1;
		local info = nCX.StartVote(channelId, mode, nCX.Config.VoteSystem[mode], tchannel);
		local started = info and #info == 0;
		if (started) then
			for i, player in pairs(nCX.GetPlayers()) do
				self:SetLastUsage(player.Info.Channel, "vote");
			end
		end
		return started, info;
	end
);

--==============================================================================
--!REPORT

CryMP.ChatCommands:Add("report", {
		Args = {
			{"player", GetPlayer = true,},
			{"reason", Concat = true,},
		},
		Info = "report a player to the admins",
		self = "Reports",
	}, 
	function(self, player, channelId, suspect, reason)
		return self:OnReport(suspect, reason, player);
	end
);

--[[
CryMP.ChatCommands:Add("hack", {Args={"player"}, Access=1, Info ="hack a player", Price = 300, InGame = true,}, function(self, player, channelId, target)		
    if (not CryMP.SuitHack or CryMP.SuitHack.Disabled) then
        local success, error = CryMP.Plugins:Activate("SuitHack", nil, nil, true);
		if(not success) then
			return false, error;
		end
	end
	return CryMP.SuitHack:Hack(player, CryMP.Ent:GetPlayer(target));
end);


CryMP.ChatCommands:Add("firewall", {Args={"code"},InGame = true, Info ="prevent a hack"}, function(self, player, channelId, code)
	if (not CryMP.SuitHack or CryMP.SuitHack.Disabled) then
        return false, "no need to enable your firewall";
	end
	return CryMP.SuitHack:Firewall(player, code);
end);

CryMP.ChatCommands:Add("parcours", {Info ="enter the parcours arena"}, function(self, player)
    if (not CryMP.Parcours) then
        return false, "parcours is disabled"
	end
	return CryMP.Parcours:Teleport(player, false);
end);
]]