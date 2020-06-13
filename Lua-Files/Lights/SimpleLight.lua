-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach
--        ##    ## ## ##   ##  ## ##     
--        ##     ####  #####  ##   ##  
-- *****************************************************************
SimpleLight = {
	Properties =
	{
		bActive = 1,
		Radius = 10,
		Style =
		{
			fCoronaScale = 1,
			fCoronaDistSizeFactor = 1,
			fCoronaDistIntensityFactor = 1,
			nLightStyle = 0,
		},
		Projector =
		{
			texture_Texture = "",
			bProjectInAllDirs = 0,
			fProjectorFov = 90,
		},
		Color = {
			clrColor = { x=1,y=1,z=1 },
			fColorMultiplier = 1,
			fSpecularPercentage = 100,
			fHDRDynamic = 0,		-- -1=darker..0=normal..1=brighter
		},
		Options = {
			bCastShadow = 0,
			bAffectsThisAreaOnly = 1,
		},
	},

	TempPos = {x=0.0,y=0.0,z=0.0},
	_LightTable = {},
	---------------------------
	--        OnInit
	---------------------------
	OnInit = function(self)
		self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0);
		self:OnReset();
	end,
	---------------------------
	--       OnShutDown
	---------------------------
	OnShutDown = function(self)
		self:FreeSlot(1);
	end,
	---------------------------
	--        OnLoad
	---------------------------
	OnLoad = function(self, props)
		self:OnReset()
		self:ActivateLight(props.bActive)
	end,
	---------------------------
	--        OnSave
	---------------------------
	OnSave = function(self, props)
		props.bActive = self.bActive
	end,
	---------------------------
	--    OnPropertyChange
	---------------------------
	OnPropertyChange = function(self)
		self:OnReset();
		self:ActivateLight(self.bActive);
	end,
	---------------------------
	--        OnReset
	---------------------------
	OnReset = function(self)
		if (self.Properties.Options.object_RenderGeometry ~= "") then
			--self:LoadGeometry( 0,self.Properties.Options.object_RenderGeometry );
			--self:DrawSlot( 0,1 );
		end
		if (self.bActive ~= self.Properties.bActive) then
			--self:ActivateLight( self.Properties.bActive );
		end
	end,
	---------------------------
	--      ActivateLight
	---------------------------
	ActivateLight = function(self, enable)
		if (enable and enable ~= 0) then
			self.bActive = 1;
			self:ActivateOutput( "Active",true );
		else
			self.bActive = 0;
			self:ActivateOutput( "Active",false );
		end
	end,
	---------------------------
	--     LoadLightToSlot
	---------------------------
	LoadLightToSlot = function(self, nSlot)
	end,
	---------------------------
	--      Event_Enable
	---------------------------
	Event_Enable = function(self)
		if (self.bActive == 0) then
			self:ActivateLight( 1 );
		end
	end,
	---------------------------
	--      Event_Disable
	---------------------------
	Event_Disable = function(self)
		if (self.bActive == 1) then
			self:ActivateLight( 0 );
		end
	end,
	---------------------------
	--      Event_Active
	---------------------------
	Event_Active = function(self, bActive)
		if (self.bActive == 0 and bActive == true) then
			self:ActivateLight( 1 );
		else 
			if (self.bActive == 1 and bActive == false) then
				self:ActivateLight( 0 );
			end
		end
	end,
};

Light.FlowEvents = {
	Inputs = {
		Active = { Light.Event_Active,"bool" },
		Enable = { Light.Event_Enable,"bool" },
		Disable = { Light.Event_Disable,"bool" },
	},
	Outputs = {
		Active = "bool",
	},
};