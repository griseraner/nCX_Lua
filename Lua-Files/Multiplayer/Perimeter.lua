-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-09-27
-- *****************************************************************
Perimeter = {
	Server = {
		---------------------------
		--		OnInit
		---------------------------
		OnInit = function(self)
			self:OnReset();
		end,
	},
	Client = {},
	type = "Perimeter",
	Properties = {
		teamName = "",
	},
	---------------------------
	--	OnPropertyChange
	---------------------------
	OnPropertyChange = function(self)
		self:OnReset();
	end,
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		local teamId = nCX.GetTeamId(self.Properties.teamName);
		if (teamId and teamId ~= 0) then
			self:SetTeamId(teamId);
		else
			self:SetTeamId(0);
		end
		self:Activate(0);
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
	--		OnEnterArea
	---------------------------
	OnEnterArea = function(self, entity, areaId)
		if (entity.actor) then
			if (g_gameRules.Server.OnPerimeterBreached) then
				local teamId = self:GetTeamId();
				local playerTeamId = nCX.GetTeam(entity.id);
				if (teamId == 0 or teamId ~= playerTeamId) then
					g_gameRules.Server.OnPerimeterBreached(g_gameRules, self, entity);
				end
			end
		end
	end,
};