-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2013-03-25
-- *****************************************************************

InteractiveEntity = {
	Client = {},
	Server = {},
	Properties = {
		fileModel 			= "objects/library/props/gasstation/vending_machine_drinks.cgf",
		ModelSubObject		= "main",
		fileModelDestroyed	= "",
		DestroyedSubObject	= "remain",
		bTurnedOn			= 0,
		bUsable				= 1,
		bTwoState			= 0,
		UseMessage			= "",
		OnUse = {
			fUseDelay 		= 0,
			fCoolDownTime 	= 1,
			bEffectOnUse	= 0,
			bSoundOnUse		= 0,
			bSpawnOnUse		= 0,
			bChangeMatOnUse = 0,
		},
		Effect = {
			ParticleEffect="explosions.gauss.hit",
			bPrime=0,
			Scale=1,
			CountScale=1,
			bCountPerUnit=0,
			AttachType="",
			AttachForm="Surface",
			PulsePeriod=0,
			SpawnPeriod=0,
			vOffset = {x=0, y=0, z=0},
			vRotation = {x=0, y=0, z=0},
		},
		fHealth = 75,
		Physics = {
			bRigidBody=1,
			bRigidBodyActive = 1,
			bResting = 1,
			Density = -1,
			Mass = 300,
        Buoyancy = {
				water_density = 1000,
				water_damping = 0,
				water_resistance = 1000,	
			},
		},
		Breakage = {
			fLifeTime = 10,
			fExplodeImpulse = 0,
			bSurfaceEffects = 1,
		},
		Destruction = {
			bExplode		= 1,
			Effect			= "explosions.monitor.a",
			EffectScale		= 1,
			Radius			= 0,
			Pressure		= 0,
			Damage			= 0,
			Decal			= "",
			Direction		= {x=0, y=0.2, z=1},
			vOffset 		= {x=0, y=0, z=0},
		},
		Vulnerability	= {
			fDamageTreshold = 0,
			bExplosion = 1,
			bCollision = 1,
			bMelee		 = 1,
			bBullet		 = 1,
			bOther	   = 1,
		},
		SpawnEntity = {
			iSpawnLimit = 1,
			Archetype = "Props.gas_station.can_a",
			vOffset = {x=0, y=0, z=0},
			vRotation = {x=0, y=0, z=0},
			fImpulse = 1,
			vImpulseDir= {x=0, y=0, z=1},
		},
		ChangeMaterial = {
			fileMaterial = "",
			Duration = 0,
		},
		ScreenFunctions = {
			bHasScreenFunction = 0,
			FlashMatId = -1,
			Type = {
				bProgressBar = 0,
			},
		},
	},
};
