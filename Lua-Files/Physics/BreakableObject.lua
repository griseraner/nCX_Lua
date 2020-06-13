-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach and Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2013-03-19
-- *****************************************************************
Script.ReloadScript("Server/Lua-Files/Utils/EntityUtils.lua")

BreakableObject = {
	Properties = {
		bCXP_special = 0,
		objModel = "objects/brushes/prototype/breakable/bridge.cgf",
		fDensity = 5000,
		fMass = -1,
		bResting = 0, -- If rigid body is originally in resting state.
		bRigidBody = 0,
		bPickable = 0,
		bUsable = 0,
		nBreakableType = 0,
		PhysicsBuoyancy = {
			water_density = 1,
			water_damping = 1.5,
			water_resistance = 0,	
		},
		PhysicsSimulation = {
			max_time_step = 0.01,
			sleep_speed = 0.04,
			damping = 0,
		},
		PhysicsBreakable = {
			max_push_force = 0.01,
			max_pull_force = 0.01,
			max_shift_force = 0.01,
			max_twist_torque = 0.01,
			max_bend_torque = 0.01,
			crack_weaken = 0.5,
			GroundPlanes = {
				positiveX = 0,
				negativeX = 0,
				positiveY = 0,
				negativeY = 0,
				positiveZ = 0.05,
				negativeZ = 0,
			},
		},
	},
	---------------------------
	--		OnSave
	---------------------------	
	OnSave = function(self, table)
		table.first_break = self.first_break
	end,
	---------------------------
	--		OnLoad
	---------------------------	
	OnLoad = function(self, table)
		self.first_break = table.first_break;
	end,
	---------------------------
	--		OnInit
	---------------------------	
	OnInit = function(self)
		self:OnReset();
	end,
	---------------------------
	--		OnReset
	---------------------------	
	OnReset = function(self)
		self:ResetOnUsed()
		self:LoadObject(0, self.Properties.objModel);
		self:DrawSlot(0, 1);
		local physType;
		if (tonumber(self.Properties.bRigidBody) ~= 0) then
			physType = PE_RIGID;
		else
			physType = PE_STATIC;
		end
		local props = self.Properties;
		self:Physicalize(0, physType, { mass = props.fMass, density = props.fDensity,});
		self:LoadObjectLattice(0);
		self:SetPhysicParams(PHYSICPARAM_SUPPORT_LATTICE, props.PhysicsBreakable);
		self:SetPhysicParams(PHYSICPARAM_SIMULATION, props.PhysicsSimulation);
		self:SetPhysicParams(PHYSICPARAM_BUOYANCY, props.PhysicsBuoyancy);
		self:SetPhysicParams(PHYSICPARAM_PART_FLAGS, {partId = 0, mat_breakable = props.nBreakableType});
		local planes = props.PhysicsBreakable.GroundPlanes;
		local plane = 0;
		if (planes.positiveX ~= 0) then
			self:SetGroundPlane(plane, 1, {x=1, y=0, z=0}, planes.positiveX);
			plane = plane+1;
		end
		if (planes.negativeX ~= 0) then
			self:SetGroundPlane(plane, 1, {x=-1, y=0, z=0}, planes.negativeX);
			plane = plane+1;
		end
		if (planes.positiveY ~= 0) then
			self:SetGroundPlane(plane, 2, {x=0, y=1, z=0}, planes.positiveY);
			plane = plane+1;
		end
		if (planes.negativeY ~= 0) then
			self:SetGroundPlane(plane, 2, {x=0, y=-1, z=0}, planes.negativeY);
			plane = plane+1;
		end
		if (planes.positiveZ ~= 0) then
			self:SetGroundPlane(plane, 3, {x=0, y=0, z=1}, planes.positiveZ);
			plane = plane+1;
		end
		if (planes.negativeZ ~= 0) then
			self:SetGroundPlane(plane, 3, {x=0, y=0, z=-1}, planes.negativeZ);
			plane = plane+1;
		end
		if (tonumber(self.Properties.bResting) ~= 0) then
			self:AwakePhysics(0);
		else
			self:AwakePhysics(1);
		end
		self.first_break = true;
	end,
	---------------------------
	--		SetGroundPlane
	---------------------------	
	SetGroundPlane = function(self, index, axis, n, distance)
		local wmin, wmax = self:GetLocalBBox();
		local size = { x=wmax.x-wmin.x, y=wmax.y-wmin.y, z=wmax.z-wmin.z };
		local c = { x=(wmax.x+wmin.x)*0.5, y=(wmax.y+wmin.y)*0.5, z=(wmax.z+wmin.z)*0.5 };
		local org = { x=c.x+n.x*size.x*(distance-0.5), y=c.y+n.y*size.y*(distance-0.5), z=c.z+n.z*size.z*(distance-0.5) };
		self:SetPhysicParams(PHYSICPARAM_GROUND_PLANE, { origin = org, normal = n, plane_index = index});
	end,
	---------------------------
	--		OnPropertyChange
	---------------------------	
	OnPropertyChange = function(self)
		self:OnReset();
	end,
	---------------------------
	--		OnShutDown
	---------------------------	
	OnShutDown = function(self)
	end,
	---------------------------
	--		OnPhysicsBreak
	---------------------------	
	OnPhysicsBreak = function(self)
		self:Event_OnBreak();
	end,
	---------------------------
	--		OnPhysicsBreak
	---------------------------	
	OnPhysicsBreak = function(self)
		self:Event_OnBreak();
		if (self.first_break) then
			self:Event_OnFirstBreak();
			self.first_break = false;
		end
	end,
	---------------------------
	--		Event_OnBreak
	---------------------------	
	Event_OnBreak = function(self)
		BroadcastEvent( self,"OnBreak" );
	end,
	---------------------------
	--		Event_OnFirstBreak
	---------------------------	
	Event_OnFirstBreak = function(self)
		BroadcastEvent( self,"OnFirstBreak" );
	end,
	
};

MakeUsable(BreakableObject)

BreakableObject.FlowEvents = {
	Inputs = {
		OnBreak = { BreakableObject.Event_OnBreak, "bool" },
		OnFirstBreak = { BreakableObject.Event_OnFirstBreak, "bool" },
	},
	Outputs = {
		OnBreak = "bool",
		OnFirstBreak = "bool",
	},
};