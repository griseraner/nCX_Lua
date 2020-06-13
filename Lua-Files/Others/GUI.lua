-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2013-04-17
-- *****************************************************************

GUI = {
	Properties = {
		objModel 					= "objects/library/storage/barrels/rusty_metal_barrel_d.cgf",
		bRigidBody					= 1,
		bResting 					= 1,
		bUsable						= nil,
		bPhysicalized				= 1,
		fMass 						= 10,
		GUIMaterial					= "test_hard",
		GUIUsageDistance			= 1.5,
		GUIUsageTolerance			= 0.75,
		GUIWidth					= 512,
		GUIHeight					= 512,
		GUIDefaultScreen			= "test_hard",
		GUIMouseCursor				= "test_hard",
		GUIPreUpdate				= 1,
		GUIMouseCursorSize			= 18,
		GUIHasFocus					= 0,
		color_GUIBackgroundColor 	= {0,0,0},
		fileGUIScript				= "test_hard",
	},
	Client = {},
	Server = {},
		
	---------------------------
	--		OnSpawn
	---------------------------
	OnSpawn = function(self) 
		self:OnReset()
	end,
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		self.Properties.bUsable = nil;
		self:SetUpdatePolicy(ENTITY_UPDATE_VISIBLE);
		local model=self.Properties.objModel;
		local t=self:GetName():sub(-4);
		if(t==".cga" or t==".cgf")then 
			model=self:GetName();
		end 
		self:LoadObject(0, model);
		self:DrawSlot(0, 1);
		if (tonumber(self.Properties.bPhysicalized) ~= 0) then
			local physParam = {
				mass = self.Properties.fMass; -- * 400,
			};
			self:Physicalize(0, PE_RIGID, physParam);
			if (tonumber(self.Properties.bResting) ~= 0) then
				self:AwakePhysics(0);
			else
				self:AwakePhysics(1);
			end
		end
		CryAction.CreateGameObjectForEntity(self.id);
		CryAction.BindGameObjectToNetwork(self.id);
	end,
	
	IsUsable = function(self, user)	  
		System.LogAlways("GUI--> isUsable");
		return 2;
	end,

};

MakePickable(GUI);







