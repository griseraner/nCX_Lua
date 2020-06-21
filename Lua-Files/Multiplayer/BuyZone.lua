-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy & ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-09-27
-- *****************************************************************
BuyZone = {
	Client = {},
	type = "BuyZone",
	Properties = {
		bEnabled = 1,
		teamName = "",
	},
	Server = {
		---------------------------
		--		OnInit
		---------------------------
		OnInit = function(self)
			self:OnReset();
		end,
	},
	---------------------------
	--		OnPropertyChange
	---------------------------	
	OnPropertyChange = function(self)
		self:OnReset();
	end,
	---------------------------
	--		OnReset
	---------------------------	
	OnReset = function(self)
		self:Enable(tonumber(self.Properties.bEnabled) ~= 0);
		local teamId = nCX.GetTeamId(self.Properties.teamName);
		if (teamId and teamId ~= 0) then
			self:SetTeamId(teamId);
		else
			self:SetTeamId(0);
		end
	end,
	---------------------------
	--		GetTeamId
	---------------------------	
	GetTeamId = function(self)
		return nCX.GetTeam(self.id) or 0;
	end,
	---------------------------
	--		SetTeamId
	---------------------------	
	SetTeamId = function(self, teamId)
		nCX.SetTeam(teamId, self.id);
	end,
	---------------------------
	--		Enable
	---------------------------	
	Enable = function(self, enable)
		self.enabled = enable;
	end,
};
g_gameRules:MakeBuyZone(BuyZone, 13); 