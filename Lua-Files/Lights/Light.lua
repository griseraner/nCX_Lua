-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-05-10
-- *****************************************************************
Light = {
	Properties = {
		bActive = 1,
		Radius = 10,
		Style = {
			fCoronaScale = 1,
			fCoronaDistSizeFactor = 1,
			fCoronaDistIntensityFactor = 1,
			nLightStyle = 0,
		},
		Projector = {
			texture_Texture = "",
			bProjectInAllDirs = 0,
			fProjectorFov = 90,
			fProjectorNearPlane = 0,
		},
		Color = {
			clrDiffuse = { x=1,y=1,z=1 },
			fDiffuseMultiplier = 1,
			fSpecularMultiplier = 1,
			fHDRDynamic = 0,
		},
		Options = {
			bCastShadow = 0,
			bAffectsThisAreaOnly = 1,
			bUsedInRealTime=1,
			bFakeLight=0,
			object_RenderGeometry="",
		},
		Test = {
			bFillLight=0,
			bNegativeLight=0,
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
			self:LoadGeometry( 0,self.Properties.Options.object_RenderGeometry );
			self:DrawSlot( 0,1 );
		end
		if (self.bActive ~= self.Properties.bActive) then
			self:ActivateLight( self.Properties.bActive );
		end
	end,
	---------------------------
	--      ActivateLight
	---------------------------
	ActivateLight = function(self, enable)
		if (enable and enable ~= 0) then
			self.bActive = 1;
			self:LoadLightToSlot(1);
			self:ActivateOutput( "Active",true );
		else
			self.bActive = 0;
			self:FreeSlot(1);
			self:ActivateOutput( "Active",false );
		end
	end,
	---------------------------
	--     LoadLightToSlot
	---------------------------
	LoadLightToSlot = function(self, nSlot)
		local props = self.Properties;
		local Style = props.Style;
		local Projector = props.Projector;
		local Color = props.Color;
		local Options = props.Options;
		local diffuse_mul = Color.fDiffuseMultiplier;
		local specular_mul = Color.fSpecularMultiplier;
		local lt = self._LightTable;
		lt.style = Style.nLightStyle;
		lt.corona_scale = Style.fCoronaScale;
		lt.corona_dist_size_factor = Style.fCoronaDistSizeFactor;
		lt.corona_dist_intensity_factor = Style.fCoronaDistIntensityFactor;
		lt.radius = props.Radius;
		lt.diffuse_color = { x=Color.clrDiffuse.x*diffuse_mul, y=Color.clrDiffuse.y*diffuse_mul, z=Color.clrDiffuse.z*diffuse_mul };
		if (diffuse_mul ~= 0) then
			lt.specular_multiplier = specular_mul / diffuse_mul;
		else
			lt.specular_multiplier = 1;
		end
		lt.hdrdyn = Color.fHDRDynamic;
		lt.projector_texture = Projector.texture_Texture;
		lt.proj_fov = Projector.fProjectorFov;
		lt.proj_nearplane = Projector.fProjectorNearPlane;
		lt.cubemap = Projector.bProjectInAllDirs;
		lt.this_area_only = Options.bAffectsThisAreaOnly;
		lt.realtime = Options.bUsedInRealTime;
		lt.heatsource = 0;
		lt.fake = Options.bFakeLight;
		lt.fill_light = props.Test.bFillLight;
		lt.negative_light = props.Test.bNegativeLight;
		lt.indoor_only = 0;
		lt.has_cbuffer = 0;
		lt.cast_shadow = Options.bCastShadow;
		lt.lightmap_linear_attenuation = 1;
		lt.is_rectangle_light = 0;
		lt.is_sphere_light = 0;
		lt.area_sample_number = 1;
		lt.RAE_AmbientColor = { x = 0, y = 0, z = 0 };
		lt.RAE_MaxShadow = 1;
		lt.RAE_DistMul = 1;
		lt.RAE_DivShadow = 1;
		lt.RAE_ShadowHeight = 1;
		lt.RAE_FallOff = 2;
		lt.RAE_VisareaNumber = 0;
		self:LoadLight( nSlot,lt );
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