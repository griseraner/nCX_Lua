-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-09-27
-- *****************************************************************
Objective = {
	Client = {},
	Server = {
		---------------------------
		--		OnInit
		---------------------------
		OnInit = function(self)	
			self:OnReset();
		end,
		---------------------------
		--		OnStartGame
		---------------------------
		OnStartGame = function(self)
			self.active = tonumber(self.Properties.bActive) ~= 0;
			self.completed = false;
			self.dependent = false;
			self:UpdateLinks();
			self:InitCondition();
			self:CheckCondition();
			self:UpdateStatus();
		end,
	},	
	Properties = {
		teamName 		= "",
		bActive			= 0,
		bSecondary 		= 0,
		objectiveName 	= "",
		Condition = {
			szCaptureBuilding 	= "",
			szDestroyBuilding 	= "",
			bProduceTAC 		= 0,
		},
	},
	---------------------------
	--		OnSpawn
	---------------------------
	OnSpawn = function(self)
		CryAction.CreateGameObjectForEntity(self.id);
		CryAction.BindGameObjectToNetwork(self.id);
	end,
	---------------------------
	--		OnCapture
	---------------------------
	OnCapture = function(self, building, teamId)
		self:CheckCondition();
	end,
	---------------------------
	--		OnUncapture
	---------------------------
	OnUncapture = function(self, building, teamId)
		self:CheckCondition();
	end,
	---------------------------
	--		OnHQDestroyed
	---------------------------
	OnHQDestroyed = function(self, hq, shooterId, teamId)
		self:CheckCondition();
	end,
	---------------------------
	--		OnNuclearWarfare
	---------------------------
	OnNuclearWarfare = function(self, teamId)
		if (teamId == self.teamId) then
			self.tacproduced = true;
			self:CheckCondition();
		end
	end,
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		self.deps = {};
		self.links = {};
		self.active = tonumber(self.Properties.bActive) ~= 0;
		self.completed = false;
		self.dependent = false;
		self:Activate(0);
		if (self.Properties.objectiveName ~= "") then
			self.missionId = self.Properties.objectiveName;
		else
			self.missionId = self:GetName();
		end
		self.trackId = self.id;
		self.teamId = nCX.GetTeamId(self.Properties.teamName) or 0;
		nCX.SetTeam(self.teamId, self.id);
		nCX.AddObjective(self.teamId, self.missionId, self:GetStatus(), self.trackId);
		self:UpdateLinks();
		self:InitCondition();
		self:UpdateStatus();
	end,
	---------------------------
	--		UpdateStatus
	---------------------------
	UpdateStatus = function(self)
		nCX.SetObjectiveStatus(self.teamId, self.missionId, self:GetStatus());
	end,
	---------------------------
	--		GetStatus
	---------------------------
	GetStatus = function(self)
		if (self.completed) then
			return MO_COMPLETED;
		elseif (self.active) then
			return MO_ACTIVATED;
		elseif (self.failed) then
			return MO_FAILED;
		else
			return MO_DEACTIVATED;
		end
	end,
	---------------------------
	--		UpdateLinks
	---------------------------
	UpdateLinks = function(self)
		local linkName = "next";
		local i = 0;
		local link = self:GetLinkTarget(linkName, i);
		while (link) do
			if (link) then
				link:AddDep(self.id);
				self:AddLink(link.id);
			end
			i = i + 1;
			link = self:GetLinkTarget(linkName, i);
		end
		linkName = "next_notdep";
		i = 0;
		local link = self:GetLinkTarget(linkName, i);
		while (link) do
			if (link) then
				self:AddLink(link.id);
			end
			i = i + 1;
			link = self:GetLinkTarget(linkName, i);
		end
	end,
	---------------------------
	--		AddLink
	---------------------------
	AddLink = function(self, linkId)
		for i,id in pairs(self.links) do
			if (id == linkId) then
				return;
			end
		end
		self.links[#self.links+1] = linkId;
	end,
	---------------------------
	--		AddDep
	---------------------------
	AddDep = function(self, depId)
		for i, id in pairs(self.deps) do
			if (id == depId) then
				return;
			end
		end
		self.deps[#self.deps] = depId;	
	end,
	---------------------------
	--		AddCondition
	---------------------------
	AddCondition = function(self, cond)
		self.conditions[#self.conditions+1] = cond;
	end,
	---------------------------
	--		InitCondition
	---------------------------
	InitCondition = function(self)
		self.conditions = {};
		self.tacproduced = false;
		local condition = self.Properties.Condition;
		if (condition.szCaptureBuilding and condition.szCaptureBuilding ~= "") then
			local buildingClass = condition.szCaptureBuilding;
			local building = System.GetNearestEntityByClass(self:GetWorldPos(), 50, buildingClass, self.id);
			if (building) then
				local buildingId = building.id;
				self:AddCondition(function(self)
					if (self.teamId == nCX.GetTeam(buildingId)) then
						return true;
					end
					return false;
				end);
			end
		end
		if (condition.szDestroyBuilding and condition.szDestroyBuilding ~= "") then
			local buildingClass = condition.szDestroyBuilding;
			local building = System.GetNearestEntityByClass(self:GetWorldPos(), 100, buildingClass, self.id);
			if (building) then
				local buildingId = building.id;	
				self:AddCondition(function(self)
					local building = System.GetEntity(buildingId);
					local destroyed = building.IsDestroyed and building:IsDestroyed();
					destroyed = destroyed or (building.GetHealth and ((building:GetHealth() or 100)<=0));
					return destroyed;
				end);
			end
		end
		if (condition.bProduceTAC and condition.bProduceTAC ~= 0) then
			local vehicleClass = condition.szProduceVehicle;
			self:AddCondition(function(self)
				return self.tacproduced;
			end);
		end
	end,
	---------------------------
	--		CheckCondition
	---------------------------
	CheckCondition = function(self)
		local complete = true;
		for i, b in pairs(self.conditions) do
			complete = complete and b(self);
		end
		if (complete ~= self.completed) then
			self:SetComplete(complete);
		end
	end,
	---------------------------
	--		SetTrackId
	---------------------------
	SetTrackId = function(self, trackId)
		self.trackId = trackId;
		nCX.SetObjectiveEntity(self.teamId, self.missionId, trackId);
	end,
	---------------------------
	--		SetComplete
	---------------------------
	SetComplete = function(self, complete)
		if(self.completed ~= complete) then
			self.completed = complete;
			self:UpdateStatus();
		end
		for i, id in pairs(self.links) do
			local obj = System.GetEntity(id);
			if (obj) then
				obj:DepCompleted(complete, self.id);
			end
		end
	end,
	---------------------------
	--		Completed
	---------------------------
	Completed = function(self)
		return self.completed;
	end,
	---------------------------
	--		Dependent
	---------------------------
	Dependent = function(self)
		return self.dependent;
	end,
	---------------------------
	--		DepCompleted
	---------------------------
	DepCompleted = function(self, complete, depId)
		if (not complete) then
			self.dependent = true;
		else
			self.dependent = false;
			if (table.getn(self.deps) > 0) then
				for i,id in pairs(self.deps) do
					local obj = System.GetEntity(id);
					if (obj) then
						if (not obj:Completed()) then
							self.dependent = true;
							break;
						end
					end
				end
			end
		end
		if (self.dependent ~= (not self.active)) then
			self.active = not self.dependent;
			self:UpdateStatus();
		end	
	end,
};