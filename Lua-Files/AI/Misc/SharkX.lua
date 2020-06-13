--------------------------------------------------------------------------
--	Crytek Source File.
-- 	Copyright (C), Crytek Studios, 2001-2006.
--------------------------------------------------------------------------
--	$Id$
--	$DateTime$
--	Description: Shark class to be used for kill events
--  
--------------------------------------------------------------------------
--  History:
--  - 6/2006     : Created by Sascha Gundlach
--
--------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
function CreateActor(child)
	BasicActorParams =
	{	
		physicsParams =
		{
			flags = 0,
			mass = 80,
			stiffness_scale = 73,
						
			Living = 
			{
				gravity = 9.81,--15,--REMINDER: if there is a ZeroG sphere in the map, gravity is set to 9.81.
							 --It will be fixed, but for now just do all the tweaks without any zeroG sphere in the map.
				mass = 80,
				air_resistance = 0.5, --used in zeroG
				
				k_air_control = 0.9,
				
				max_vel_ground = 16,
				
				min_slide_angle = 45.0,
				max_climb_angle = 50.0,
				min_fall_angle = 50.0,
				
				timeImpulseRecover = 1.0,
				
				colliderMat = "mat_player_collider",
			},
		},
		
		gameParams =
		{
			stance =
			{
				{
					stanceId = STANCE_STAND,
					normalSpeed = 1.0,
					maxSpeed = 5.0,
					heightCollider = 1.2,
					heightPivot = 0.0,
					size = {x=0.4,y=0.4,z=0.2},
					modelOffset = {x=0,y=-0.0,z=0},
					viewOffset = {x=0,y=0.10,z=1.625},
					weaponOffset = {x=0.2,y=0.0,z=1.35},
					leanLeftViewOffset = {x=-0.5,y=0.10,z=1.525},
					leanRightViewOffset = {x=0.5,y=0.10,z=1.525},
					leanLeftWeaponOffset = {x=-0.45,y=0.0,z=1.30},
					leanRightWeaponOffset = {x=0.65,y=0.0,z=1.30},
					name = "combat",
					useCapsule = 1,
				},
				{
					stanceId = STANCE_STEALTH,
					normalSpeed = 0.6,
					maxSpeed = 3.0,
					heightCollider = 1.0,
					heightPivot = 0.0,
					size = {x=0.4,y=0.4,z=0.1},
					modelOffset = {x=0.0,y=-0.0,z=0},
					viewOffset = {x=0,y=0.3,z=1.35},
					weaponOffset = {x=0.2,y=0.0,z=1.1},
					name = "stealth",
					useCapsule = 1,
				},
				{
					stanceId = STANCE_CROUCH,
					normalSpeed = 0.5,
					maxSpeed = 3.0,
					heightCollider = 0.8,
					heightPivot = 0.0,
					size = {x=0.4,y=0.4,z=0.1},
					modelOffset = {x=0.0,y=0.0,z=0},
					viewOffset = {x=0,y=0.0,z=1.1},
					weaponOffset = {x=0.2,y=0.0,z=0.85},
					leanLeftViewOffset = {x=-0.55,y=0.0,z=0.95},
					leanRightViewOffset = {x=0.55,y=0.0,z=0.95},
					leanLeftWeaponOffset = {x=-0.5,y=0.0,z=0.65},
					leanRightWeaponOffset = {x=0.5,y=0.0,z=0.65},
					name = "crouch",
					useCapsule = 1,
				},
				{
					stanceId = STANCE_PRONE,
					normalSpeed = 0.5,
					maxSpeed = 1.0,
					heightCollider = 0.5,
					heightPivot = 0.0,
					size = {x=0.4,y=0.4,z=0.01},
					modelOffset = {x=0,y=0.0,z=0},
					viewOffset = {x=0,y=0.5,z=0.35},
					weaponOffset = {x=0.1,y=0.0,z=0.25},
					name = "prone",
					useCapsule = 1,
				},
				{
					stanceId = STANCE_SWIM,
					normalSpeed = 1.0, -- this is not even used?
					maxSpeed = 2.5, -- this is ignored, overridden by pl_swim* cvars.
					heightCollider = 0.9,
					heightPivot = 0.5,
					size = {x=0.4,y=0.4,z=0.1},
					modelOffset = {x=0,y=0,z=0.0},
					viewOffset = {x=0,y=0.1,z=0.5},
					weaponOffset = {x=0.2,y=0.0,z=0.3},
					name = "swim",
					useCapsule = 1,
				},
				{
					stanceId = STANCE_ZEROG,
					normalSpeed = 1.75,
					maxSpeed = 3.5,
					heightCollider = 1.2,
					heightPivot = 1.0,
					size = {x=0.4,y=0.4,z=0.6},
					modelOffset = {x=0,y=0,z=-1},
					viewOffset = {x=0,y=0.15,z=0.625},
					weaponOffset = {x=0.2,y=0.0,z=1.3},
					name = "combat",
					useCapsule = 1,
				},
				--AI states
				{
					stanceId = STANCE_RELAXED,
					normalSpeed = 1.0,
					maxSpeed = 1.9,
					heightCollider = 1.2,
					heightPivot = 0.0,
					size = {x=0.4,y=0.4,z=0.2},
					modelOffset = {x=0,y=0,z=0},
					viewOffset = {x=0,y=0.10,z=1.625},
					weaponOffset = {x=0.2,y=0.0,z=1.3},
					name = "relaxed",
					useCapsule = 1,
				},
			},
						
			sprintMultiplier = 1.5,--speed is multiplied by this ammount if sprint key is pressed -- 1.2 for a more counter-striky feel
			strafeMultiplier = 1.0,--speed is multiplied by this ammount when strafing
			backwardMultiplier = 0.7,--speed is multiplied by this ammount when going backward
			grabMultiplier = 0.5,--speed is multiplied by this ammount when the player is carry the maximun ammount carriable
					
			inertia = 10.0,--7.0,--the more, the faster the speed change: 1 is very slow, 10 is very fast already 
			inertiaAccel = 11.0,--same as inertia, but used when the player accel
				
			jumpHeight = 1.0,--meters
			
			slopeSlowdown = 3.0,
			
			leanShift = 0.35,--how much the view shift on the side when leaning
			leanAngle = 15,--how much the view rotate when leaning
			
			--ZeroG stuff:
			thrusterImpulse = 14.0,--thruster power, for the moment very related to air_resistance.
			thrusterStabilizeImpulse = 0.01,--used from the jetpack to make the player stop slowly.
			gravityBootsMultipler = 0.8,--speed is multiplied by this ammount when gravity boots are on
			afterburnerMultiplier = 2.0,--how much the afterburner
			
			--grabbing
			maxGrabMass = 70,
			maxGrabVolume = 2.0,--its the square volume of an 1x1x2 meters object
		},
	}

	mergef(child,BasicActorParams,1);
	mergef(child,BasicActor,1);
	return child;
end
CreateActor(Shark_x);
Shark = CreateAI(Shark_x);
Shark:Expose();

----------------------------------------------------------------------------------------------------
function Shark:Event_Spawn()
	-- to do: get target entity from parameter (no g_localActor)
	-- spawn the shark behind the player
	local targetActor = g_localActor;
	self:Event_Enable();
	--self.AI.target = targetActor;
	self.actor:SetParams({selectTarget = targetActor.id, spawned = self.AI.spawned});
	
	self:Hide(0);
	self:Activate(1);
	

	BroadcastEvent(self, "SpawnShark");
	--AI.ModifySmartObjectStates(self.id,"-Escaping");
end;

function Shark:Event_Remove()
	--self.goAwayTime = 4.0;
	self.actor:SetParams({goAway = 1});
	--AI.ModifySmartObjectStates(self.id,"Escaping-StickToPlayer");
end

----------------------------------------------------------------------------------------------------
function Shark:Chase(target)
	self.actor:SetParams({targetId = target.id});
	--self.AI.target = target;
end

-------------------------------------------------------
function Shark:GetDamageAbsorption()
	return 1;
end

-------------------------------------------------------
function Shark:Event_Disable()
	self:TriggerEvent(AIEVENT_DISABLE);
	self.bNowEnabled = 0;
	--self:Hide(1);
	BroadcastEvent(self, "Disable");
end

-------------------------------------------------------
function Shark:Event_Enable()
	self:TriggerEvent(AIEVENT_ENABLE);
	self.bNowEnabled = 1;
	--self:Hide(0);
	BroadcastEvent(self, "Enable");
end

function Shark:GetDamageAbsorption()
	return 1;
end

Shark.FlowEvents =
{
	Inputs =
	{
		SpawnShark = { Shark.Event_Spawn, "bool" },
		RemoveShark = { Shark.Event_Remove, "bool" },
		DisableShark = { Shark.Event_Disable, "bool" },
		EnableShark = { Shark.Event_Enable, "bool" },
	},
	Outputs =
	{
		Spawn = "bool",
		Remove = "bool",
		Disable = "bool",
		Enable = "bool",
	},
}

--Shark:Expose();