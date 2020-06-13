-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-09-30
-- *****************************************************************
Fan = {
	Client = {},
	Server = {
		---------------------------
		--		OnInit
		---------------------------
		OnInit = function(self)
			if (not self.bInitialized) then
				self:OnReset();
				self.bInitialized = 1;
			end;
		end,
	},
	Properties = {
		fileModel 			= "objects/library/furniture/misc/hillside_cafe_ventilator.cgf",
		ModelSubObject		= "main",
		fileModelDestroyed	= "",
		DestroyedSubObject	= "remain",
		MaxSpeed 			= 0.1,
		fHealth 			= 100,
		bTurnedOn 			= 1,
		Physics = {
			bRigidBody 				= 0,
			bRigidBodyActive 		= 0,
			bRigidBodyAfterDeath 	= 1,
			bResting 				= 1,
			Density 				= -1,
			Mass 					= 150,
		},
		Breakage = {
			fLifeTime 			= 10,
			fExplodeImpulse 	= 0,
			bSurfaceEffects 	= 1,
		},
		Destruction = {
			bExplode 		= 1,
			Effect 			= "",
			EffectScale 	= 0.2,
			Radius 			= 1,
			Pressure 		= 12,
			Damage 			= 0,
			Decal 			= "",
			Direction 		= {x=0, y=0.0, z=-1},
		},
	},
	States 			= { "TurnedOn", "TurnedOff", "Accelerating", "Decelerating", "Destroyed" },
	fCurrentSpeed 	= 0,
	fDesiredSpeed 	= 0,
	shooterId 		= 0,
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		local props = self.Properties;
		self.health = props.fHealth;
		if (props.fileModel ~= "") then
			self:LoadSubObject(0, props.fileModel, props.ModelSubObject);
		end;
		if (props.fileModelDestroyed ~= "") then
			self:LoadSubObject(1, props.fileModelDestroyed, props.DestroyedSubObject);
		elseif (props.DestroyedSubObject ~= "")then
			self:LoadSubObject(1, props.fileModel, props.DestroyedSubObject);
		end;
		self:SetCurrentSlot(0);
		self:PhysicalizeThis(0);
		if(props.bTurnedOn == 1)then
			self.fCurrentSpeed = self.Properties.MaxSpeed;
			self:GotoState("TurnedOn");
		else
			self.fCurrentSpeed = 0;
			self:GotoState("TurnedOff");
		end;
		self.fDesiredSpeed = self.Properties.MaxSpeed;
	end,
	---------------------------
	--		PhysicalizeThis
	---------------------------
	PhysicalizeThis = function(self, slot)
		local physics = self.Properties.Physics;
		EntityCommon.PhysicalizeRigid(self, slot, physics, 1);
	end,
	---------------------------
	--		SetCurrentSlot
	---------------------------
	SetCurrentSlot = function(self, slot)
		if (slot == 0) then
			self:DrawSlot(0, 1);
			self:DrawSlot(1, 0);
		else
			self:DrawSlot(0, 0);
			self:DrawSlot(1, 1);
		end
		self.currentSlot = slot;
	end,
};
--[[
function Fan:Event_Destroyed()
	BroadcastEvent(self, "Destroyed");
end;

function Fan:Event_TurnOn()
	if(self:GetState() ~= "Destroyed")then
		self:GotoState("Accelerating");
	end;
end;

function Fan:Event_TurnOff()
	if(self:GetState() ~= "Destroyed")then
		self:GotoState("Decelerating");
	end;
end;

function Fan:Event_Switch()
	if(self:GetState() ~= "Destroyed")then
		if(self:GetState() == "Accelerating" or self:GetState() == "TurnedOn")then
			self:GotoState("Decelerating");
		elseif(self:GetState() == "Decelerating" or self:GetState() == "TurnedOff")then
			self:GotoState("Accelerating");
		end;
	end;
end;

function Fan:Event_Hit(sender)
	BroadcastEvent(self, "Hit");
end;--]]

Fan.Server.TurnedOn = {
	OnBeginState = function(self)
		BroadcastEvent(self, "TurnOn")
		self:SetTimer(0,25);
	end,
	OnTimer = function(self,timerId,msec)
		System.LogAlways("TurnedOn:OnTimer");
		self:GetAngles(g_Vectors.temp_v1);
		g_Vectors.temp_v1.z=g_Vectors.temp_v1.z+self.fCurrentSpeed;
		self:SetAngles(g_Vectors.temp_v1);
		self:SetTimer(0,25);
	end,
	OnEndState = function(self)
	end,
};

Fan.Server.TurnedOff = {
	OnBeginState = function(self)
		BroadcastEvent(self, "TurnOff")
	end,
	OnEndState = function(self)
	end,
};

Fan.Server.Accelerating = {
	OnBeginState = function( self )
		self:SetTimer(0,25);
	end,
	OnTimer = function(self, timerId, msec)
		System.LogAlways("Accelerating:OnTimer");
		self:GetAngles(g_Vectors.temp_v1);
		g_Vectors.temp_v1.z=g_Vectors.temp_v1.z+self.fCurrentSpeed;
		self:SetAngles(g_Vectors.temp_v1);
		if(self.fCurrentSpeed<=self.fDesiredSpeed)then
			self.fCurrentSpeed=self.fCurrentSpeed+(self.fDesiredSpeed/100);
			self:SetTimer(0,25);
		else
			self:GotoState("TurnedOn");
		end;
	end,
	OnEndState = function(self)
	end,
};

Fan.Server.Decelerating = {
	OnBeginState = function( self )
		self:SetTimer(0,25);
	end,
	OnTimer = function(self,timerId,msec)
		System.LogAlways("Decelerating:OnTimer");
		self:GetAngles(g_Vectors.temp_v1);
		g_Vectors.temp_v1.z=g_Vectors.temp_v1.z+self.fCurrentSpeed;
		self:SetAngles(g_Vectors.temp_v1);
		if(self.fCurrentSpeed>0.01)then
			self.fCurrentSpeed=self.fCurrentSpeed-(self.fDesiredSpeed/100);
			self:SetTimer(0,25);
		else
			self:GotoState("TurnedOff");
		end;
	end,
	OnEndState = function( self )
	end,
};

Fan.Server.Destroyed = {
	OnBeginState = function( self )
		BroadcastEvent(self, "Destroyed")
		self:SetTimer(0,25);
	end,
	OnTimer = function(self,timerId,msec)
		System.LogAlways("Destroyed:OnTimer");
		self:GetAngles(g_Vectors.temp_v1);
		g_Vectors.temp_v1.z=g_Vectors.temp_v1.z+self.fCurrentSpeed;
		self:SetAngles(g_Vectors.temp_v1);
		if(self.fCurrentSpeed>0.01)then
			self.fCurrentSpeed=self.fCurrentSpeed-((self.fDesiredSpeed/100)*2);
			self:SetTimer(0,25);
		end;
	end,
	OnEndState = function( self )
	end,
};
--[[
Fan.FlowEvents = {
	Inputs = {
		Switch = { Fan.Event_Switch, "bool" },
		TurnOn = { Fan.Event_TurnOn, "bool" },
		TurnOff = { Fan.Event_TurnOff, "bool" },
		Hit = { Fan.Event_hit, "bool" },
		Destroyed = { Fan.Event_Destroyed, "bool" },
	},
	Outputs = {
		TurnOn = "bool",
		TurnOff = "bool",
		Hit = "bool",
		Destroyed = "bool",
	},
};--]]