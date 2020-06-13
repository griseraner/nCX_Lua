--==============================================================================
--!SETENERGY

CryMP.ChatCommands:Add("setenergy", {
		Access = 2,
		Args = {
			{"team", Output = {{"nk", "NK Team", true},{"us", "US Team", true},},},
			{"level", Number = true,},
		}, 
		Info = "set the energy of a team",
		Map = {"ps/(.*)"},
	},
	function(self, player, channelId, team, energy)
		g_gameRules:SetTeamPower(team, math.floor(energy));
		return true;
	end
);
