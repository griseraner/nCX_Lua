-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Surprise Nigga
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2013-02-01
-- *****************************************************************

GravityBox = {
	Properties = {
		bActive = 1,
		Radius = 10,
		bUniform = 1,
		Gravity = { x=0,y=0,z=0 },
		Falloff = { x=0,y=0,z=0 },
		Damping = 0,
	},
	_PhysTable = { Area={}, },
	
	OnInit = function(self)
		self:PhysicalizeThis() -- enables for items and vehicles	
		CryAction.CreateGameObjectForEntity(self.id);
		CryAction.BindGameObjectToNetwork(self.id);  -- enables for players
	end,		
	
	PhysicalizeThis = function(self, radius)
		local props = self.Properties;
		local Area = self._PhysTable.Area;
		Area.type = AREA_SPHERE;
		Area.radius = radius or props.Radius;
		Area.uniform = props.bUniform;
		Area.falloff = props.Falloff;
		Area.gravity = props.Gravity;
		Area.damping = props.Damping;
		self:Physicalize( 0,PE_AREA,self._PhysTable );
		self:SetPhysicParams(PHYSICPARAM_FOREIGNDATA,{foreignData = ZEROG_AREA_ID});  -- enables for items and vehicles
	end,
	
	SetRadius = function(self, radius)
		radius = math.max(1, tonumber(radius));
		local scale = radius / self.Properties.Radius;
		self:PhysicalizeThis(radius);
		self:SetScale(scale);
	end,

};



