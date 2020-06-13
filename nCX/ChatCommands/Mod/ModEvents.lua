--==============================================================================
--!TOGGLEBOXING [TYPE]

CryMP.ChatCommands:Add("toggleboxing", {
		Access = 1,
		Args = {
			{"type", Optional = true, Output = {{"underground","enables underground boxing"},{"sky","enables sky boxing"},},},
		},
		Info = "toggle boxing",
		Map = {"ps/(.*)"},
		self = "CryMP",
	},
	function(self, player, channelId, position)
		if (self.Boxing) then
			self.Boxing:ShutDown(true);
			return true;
		else
			return self:GetPlugin("Boxing", function(self)
				return self:Activate(position);
			end);
		end
	end
);

--==============================================================================
--!BOXMODE

CryMP.ChatCommands:Add("boxmode", {
		Access = 3,
		Args = {
			{"mode", Output = {{"lights", "spawn some partylights"},{"smoke","got distracted?"},{"gravity","enable zero-gravity mode"},{"cage","spawn boxing-cage"}}},
		},
		Info = "enable different boxing modes",
		self = "Boxing",
	},
	function(self, player, channelId, boxinmode)
		return self:Boxmode(channelId, boxinmode);
	end
);

--==============================================================================
--!RACE [TYPE] [CAR]

CryMP.ChatCommands:Add("race", {
		Access = 1,
		Args = {
			{"track", Optional = true, Output = {{"sprint", "Tunnel at US base to D4"},{"medium", "Tunnel at NK base, C7, D4, E3 (used if left empty)"},{"long", "Tunnel at US base, D4, checkpoint at NK base, C7, D4, E3 (known as hockenheim)"},},},
			{"car", Optional = true, Output = {{"jeep", "Unarmed (used if left empty)"},{"taxi", "Unarmed"},{"truck", "Unarmed"},{"apc", "DeathMode Race"},{"tank", "DeathMode Race"},{"hover", "DeathMode Race (random modifications : HovercraftGun, Gauss, AH, AV, MOAC)"},{"ltv", "DeathMode Race (Asian Jeep known from singleplayer)"},},},
		},
		Info = "start a race",
		Map = {"ps/mesa"},
		self = "CryMP",
	},
	function(self, player, channelId, racename, car)
		if (player:GetAccess() < 2 and self.Race) then
			return false, "there's a race going on"
		end
		if (self.Race) then
			self.Race:ShutDown(true);
			return true;
		else
			return self:GetPlugin("Race", function(self)
				return self:Activate(racename, car);
			end);
		end
	end
);

--==============================================================================
--!ENDVOTE

CryMP.ChatCommands:Add("endvote", {
		Access = 2,
		Info = "end a vote",
	}, 
	function(self, player)
		if (not nCX.EndVote()) then
			return false, "no vote in progress";
		end
		return true;
	end
);

CryMP.ChatCommands:Add("time", {
		Access = 2,
		Info = "set the round time",
		Args = {
			{"time", Number = true},
		},
	},
	function(self, player, channelId, time)
		--local org = System.GetCVar("g_timelimit");
		System.SetCVar("g_timelimit", time);
		nCX.ResetGameTime();
		--System.SetCVar("g_timelimit", org);
		return true;
	end
);

--[[
CryMP.ChatCommands:Add("openparcours", {Access = 2, Args = {"course"}, ArgumentInfo={["course"] = "\"easy\", \"hard\" or leave empty for \"easy\""}, Info="toggle the parcours"}, function(self, player, channelId, course)
	if (not CryMP.Parcours) then
		local success, error = CryMP.Plugins:Activate("Parcours", nil, nil, true);
		if (not success) then
			return success, error;
		end
	end
	return CryMP.Parcours:Toggle(course);
end);
]]