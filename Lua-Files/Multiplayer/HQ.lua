-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy & ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-11-21
-- *****************************************************************
HQ = {
	Client = {
		ClDestroy			= function() end,
	},
	Properties = {
		objModel 				= "objects/default.cgf",
		objDestroyedModel		= "",
		teamName				= "",
		nHitPoints				= 500,
		perimeterAreaId			= 0,
		hqType					= "bunker",
		Explosion = {
		Effect					= "",
			EffectScale 		= 1,
			EffectDirection = {x=0,y=0,z=1},
		},		
	},
	
	Server = {
		
		---------------------------
		--		OnInit
		---------------------------	
		OnInit = function(self)
			self:OnReset();	
		end,
		---------------------------
		--		OnShutDown
		---------------------------	
		OnShutDown = function(self)
			nCX.RemoveMinimapEntity(self.id);
		end,
		---------------------------
		--		OnInitClient
		---------------------------	
		OnInitClient = function(self, channelId)
			if (self.destroyed) then
				self.onClient:ClDestroy(channelId);
			end
		end,
		---------------------------
		--		OnEnterArea
		---------------------------	
		OnEnterArea = function(self, entity, areaId)
			if (g_gameRules.Server.OnPerimeterBreached and entity.Info and entity.Info.Channel > 0) then
				g_gameRules.Server.OnPerimeterBreached(g_gameRules, self, entity, areaId, true);
			end
		end,
		---------------------------
		--		OnLeaveArea
		---------------------------	
		OnLeaveArea = function(self, entity, areaId)
			if (g_gameRules.Server.OnPerimeterBreached and entity.Info and entity.Info.Channel > 0) then
				g_gameRules.Server.OnPerimeterBreached(g_gameRules, self, entity, areaId, false);
			end
		end,
	},
	---------------------------
	--		Destroy
	---------------------------
	Destroy = function(self)
		self.destroyed = true;
		self:EnableSlot(0, false);
		self:EnableSlot(1, true);
	end,
	---------------------------
	--		LoadGeometry
	---------------------------
	LoadGeometry = function(self, slot, model)
		if (#model > 0) then
			local ext = model:sub(-4):lower();
			if ((ext == ".chr") or (ext == ".cdf") or (ext == ".cga")) then
				self:LoadCharacter(slot, model);
			else
				self:LoadObject(slot, model);
			end
		end
	end,
	---------------------------
	--		OnSpawn
	---------------------------
	OnSpawn = function(self)
		CryAction.CreateGameObjectForEntity(self.id);
		CryAction.BindGameObjectToNetwork(self.id);
		CryAction.ForceGameObjectUpdate(self.id, true);
		self:LoadGeometry(0, self.Properties.objModel);
		self:LoadGeometry(1, self.Properties.objDestroyedModel);
	end,
	---------------------------
	--		EnableSlot
	---------------------------
	EnableSlot = function(self, slot, enable)
		if (enable) then
			self:Physicalize(slot, PE_RIGID, {});	 --PE_STATIC default
			self:DrawSlot(slot, 1);
		else
			self:DestroyPhysics();
			self:DrawSlot(slot, 0);
		end
	end,
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		self:EnableSlot(1, false);
		self:EnableSlot(0, true);
		if (self.Properties.teamName ~= "") then
			nCX.SetTeam(nCX.GetTeamId(self.Properties.teamName), self.id);
		else
			nCX.SetTeam(0, self.id);
		end
		self.destroyed = false;
		--self.Properties.nHitPoints = 5999;
		self:SetHealth(self.Properties.nHitPoints);
	end,
	---------------------------
	--		OnPropertyChange
	---------------------------
	OnPropertyChange = function(self)
		self:OnReset();
	end,
	---------------------------
	--		IsDead
	---------------------------
	IsDead = function(self)
		return self.destroyed;
	end,
	---------------------------
	--		SetHealth
	---------------------------
	SetHealth = function(self, health)
		self.synched.health=health;
	end,
	---------------------------
	--		GetHealth
	---------------------------
	GetHealth = function(self)
		return self.synched.health;
	end,

};

Net.Expose {
	Class = HQ,
	ClientMethods =	{
		ClDestroy = { RELIABLE_UNORDERED, NO_ATTACH },
	},
	ServerMethods = {},
	ServerProperties = {
		health = FLOAT,
	};
};