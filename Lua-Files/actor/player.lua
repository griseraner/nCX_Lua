-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-09-05
-- *****************************************************************
Player = {
	AnimationGraph = "PlayerFullBody.xml",
	UpperBodyGraph = "PlayerUpperBody.xml",
	type = "Player",
	Properties = {
    soclasses_SmartObjectClass = "Player",
    groupid = 0,
		species = 0,
		commrange = 40;
		voiceType = "player",
		aicharacter_character = "Player",
		Perception = {
			camoScale = 1,
			velBase = 1,
			velScale = .03,
			sightrange = 50,
		}	,
		fileModel = "objects/characters/human/us/nanosuit/nanosuit_us_multiplayer.cdf",
		clientFileModel = "objects/characters/human/us/nanosuit/nanosuit_us_fp3p.cdf",
		fpItemHandsModel = "objects/weapons/arms_global/arms_nanosuit_us.chr",
		objFrozenModel= "objects/characters/human/asian/nk_soldier/nk_soldier_frozen_scatter.cgf",
	},
	gameParams = {
		stance = {
			{
				stanceId = STANCE_STAND,
				normalSpeed = 1.75,
				maxSpeed = 4.5,
				heightCollider = 1.2,
				heightPivot = 0.0,
				size = {x=0.4,y=0.4,z=0.3},
				viewOffset = {x=0,y=0.15,z=1.625},
				modelOffset = {x=0,y=0,z=0.0},
				name = "combat",
				useCapsule = 1,
			},
			{
				stanceId = -2,
			},
			{
				stanceId = STANCE_CROUCH,
				normalSpeed = 1.0,
				maxSpeed = 1.5,
				heightCollider = 0.9,
				heightPivot = 0,
				size = {x=0.4,y=0.4,z=0.1},
				viewOffset = {x=0,y=0.1,z=1.0},
				modelOffset = {x=0,y=0,z=0},
				name = "crouch",
				useCapsule = 1,
			},
			{
				stanceId = STANCE_PRONE,
				normalSpeed = 0.375,
				maxSpeed = 0.75,
				heightCollider = 0.4,
				heightPivot = 0,
				size = {x=0.35,y=0.35,z=0.001},
				viewOffset = {x=0,y=0.0,z=0.5},
				modelOffset = {x=0,y=0,z=0},
				weaponOffset = {x=0.0,y=0.0,z=0.0},
				name = "prone",
				useCapsule = 1,
			},
			{
				stanceId = STANCE_SWIM,
				normalSpeed = 1.0,
				maxSpeed = 2.5,
				heightCollider = 1.0,
				heightPivot = 0,
				size = {x=0.4,y=0.4,z=0.35},
				viewOffset = {x=0,y=0.1,z=1.5},
				modelOffset = {x=0,y=0,z=0.0},
				weaponOffset = {x=0.3,y=0.0,z=0},
				name = "swim",
				useCapsule = 1,
			},
			{
				stanceId = STANCE_ZEROG,
				normalSpeed = 1.75,
				maxSpeed = 3.5,
				heightCollider = 0.0,
				heightPivot = 0,
				size = {x=0.6,y=0.6,z=0.001},
				viewOffset = {x=0,y=0.0,z=0.35},
				modelOffset = {x=0,y=0,z=0.0},
				weaponOffset = {x=0.3,y=0.0,z=0},
				name = "zerog",
				useCapsule = 1,
			},
			{
				stanceId = -2,
			},
		},
		nanoSuitActive = 1,
	},
	modelSetup = {
		deadAttachments = {"head","helmet"},
	},
	--SignalData = {},
	OnUseEntityId = NULL_ENTITY,
	OnUseSlot = 0,
	Client = {
		Revive			= function() end,
		MoveTo			= function() end,
		AlignTo			= function() end,
		ClearInventory	= function() end,
		
		SetCustomModel	= function() end,
	},
	Server = {
		---------------------------
		--        OnInit
		---------------------------
		OnInit = function(self)
			self:OnReset(true);
		end,
	},
	---------------------------
	--        SetModel
	---------------------------
	SetModel = function(self, model, arms, frozen, fp3p)
		if (model) then
			if (fp3p) then
				self.Properties.clientFileModel = fp3p;
			end
			self.Properties.fileModel = model;
			if (arms) then
				self.Properties.fpItemHandsModel = arms;
			end
			if (frozen) then
				self.Properties.objFrozenModel = frozen;
			end
		end
	end,
	---------------------------
	--        OnReset
	---------------------------
	OnReset = function(self)
		BasicActor.Reset(self);
		self.actor:ActivateNanoSuit(1);
		self:SetCloakType(1);
	end,
	---------------------------
	--      SetOnUseData
	---------------------------
	SetOnUseData = function(self, entityId, slot) --> Not sure if needed but it's used in ScriptEvent BasicActor
		self.OnUseEntityId = entityId
		self.OnUseSlot = slot
	end,
	---------------------------
	--      ScriptEvent
	---------------------------
	ScriptEvent = function(self, event,value,str)
		BasicActor.ScriptEvent(self, event, value, str);
	end,
};

local BasicActorParams = {
	physicsParams = {
		flags = 0,
		mass = 80,
		stiffness_scale = 73,
		Living = {
			gravity = 9.81,
			mass = 80,
			air_resistance = 0.5,
			k_air_control = 0.9,
			max_vel_ground = 16,
			min_slide_angle = 45.0,
			max_climb_angle = 50.0,
			min_fall_angle = 50.0,
			timeImpulseRecover = 1.0,
			colliderMat = "mat_player_collider",
		},
	},
	gameParams = {
		stance = {
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
				normalSpeed = 1.0,
				maxSpeed = 2.5,
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
		sprintMultiplier = 1.5,
		strafeMultiplier = 1.0,
		strafeMultiplierMP = 0.75,
		backwardMultiplier = 0.7,
		grabMultiplier = 0.5,
		inertia = 10.0,
		inertiaAccel = 11.0,
		jumpHeight = 1.0,
		slopeSlowdown = 3.0,
		leanShift = 0.35,
		leanAngle = 15,
		thrusterImpulse = 14.0,
		thrusterStabilizeImpulse = 0.01,
		gravityBootsMultipler = 0.8,
		afterburnerMultiplier = 2.0,
		maxGrabMass = 70,
		maxGrabVolume = 2.0,
	},
};

mergef(Player, BasicActorParams, true);
mergef(Player, BasicActor, true);

local CryMP_Enhanced = false; --tonumber(System.GetCVar("cl_crymp")) == 2;

local NetSetup = {
	Class = Player,
	ClientMethods = {
		Revive				= { RELIABLE_ORDERED, NO_ATTACH },
		MoveTo				= { RELIABLE_ORDERED, NO_ATTACH, VEC3 },
		AlignTo				= { RELIABLE_ORDERED, NO_ATTACH, VEC3 },
		ClearInventory		= { RELIABLE_ORDERED, NO_ATTACH },
	},
	ServerMethods = {},
	ServerProperties = {}
};

if (CryMP_Enhanced) then
	NetSetup.ClientMethods.SetCustomModel = { RELIABLE_ORDERED, NO_ATTACH, STRING, VEC3, BOOL };
	System.LogAlways("$4[CryMP_Enhanced] $9Loading custom player.lua RMIs");
else
	NetSetup.ClientMethods.SetCustomModel = nil;
	System.LogAlways("$4[CryMP_Enhanced] $9Loading default player.lua RMIs");
end

Net.Expose(NetSetup);

		

