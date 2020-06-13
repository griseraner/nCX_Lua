-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2013-03-19
-- *****************************************************************
Script.ReloadScript("Server/Lua-Files/Physics/BasicEntity.lua");

AnimObject = {
	Properties = {
		Animation = {
			Animation = "Default",
			Speed=1,
			bLoop=0,
			bPlaying=0,
			bAlwaysUpdate=0,
			playerAnimationState="",
			bPhysicalizeAfterAnimation=0,
		},
		Physics = {
			bArticulated = 0,
		},
		ActivatePhysicsThreshold = 0,
		ActivatePhysicsDist = 50,
		bNoFriendlyFire = 0,
	},
	PHYSICALIZEAFTER_TIMER = 1,
	POSTQL_TIMER = 2,
	
	Client = {},
};

MakeDerivedEntity( AnimObject,BasicEntity )



