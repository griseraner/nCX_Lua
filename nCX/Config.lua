-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Authors:  ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2018-07-12
-- *****************************************************************

nCX.Config = {
	--Crysis 1 
	DamageTable = {
		helmet		= 1.25,
		kevlar		= 1.15,
		head 		= 2.25,
		torso 		= 1.15,
		arm_left	= 0.85,
		arm_right	= 0.85,
		leg_left	= 0.85,
		leg_right	= 0.85,
		foot_left	= 0.70,
		foot_right	= 0.70,
		hand_left	= 0.70,
		hand_right	= 0.70,
		assist_min	= 0.80,
	},

	VoteSystem = {
		--[mode] =  "question",
		--["Map"]	 = "Proceed to the next Level?",
		["Kick"] = "Kick %s?",
		["Mute"] = "Mute %s?",
		["Vtol"] = "Toggle VTOLs?",
	},
	
	ChatEntities = {		
		--"[ 7OXiCITY : 5.0.0 ]", -- 0
		"~ nCX ~", -- 0
		"[ iNFO ]",         		-- 1
		"~ TO ADMINS ~",  		    -- 2 
		"[ VOTE ]",               	-- 3  
		"[ WARNING ]",				-- 4
		"[ DUEL ]",					-- 5
		"[ RACE ]",					-- 6
		"[ BOXING ]",				-- 7
		"[ SERVER - DEFENCE ]",			-- 8
		"[ PENALTY : BOX ]",			-- 9
		"[ MUTE ]",					-- 10
		"[ AFK : MANAGER ]",			-- 11
		"[ TEAM : BALANCE ]",			-- 12
		"[ BAN : SYSTEM ]",			-- 13
		"[ ERROR ]",				-- 14
		"[ EQUIP ]",				-- 15
		"[ EVENT ]",	-- 16	--NANOSUIT 1.1.1.6729
		"[ VEHICLE ]",	-- 17
		"[ TEAM : NK ]",	-- 18
		"[ TEAM : US ]",	-- 19
		"[ SQUAD : LEADER ]",	-- 20
	},
	GUIDs = {
		"7PK3599Z2NXMY5YGMTEQ",--ctao
		"HGFXRAHXLWCT7FFQYAVQ",--is it raphs?
		"2KBKSU2ZBK52J5Z7M86R",--krawall
		"7DXP3VLQLSFAZBJGRR86",--chris
	},
	CVars = {
		["cl_crymp"]							   = "1",
		
		["con_restricted"]							= "0",
		["sv_port"]									= "50001",
		["sv_servername"]							= "Server starting up...", -- "7OXiCITY ::: TEST", --
		["sv_password"]								= "1234",
		["sv_dedicatedmaxrate"]						= "60",
		["sv_cheatprotection"]						= "0",
		--["sv_maxplayers"]							= "16",
		["sv_gamerules"]							= "PowerStruggle",
		["sv_lanonly"]								= "0",
		["fg_abortonloaderror"]						= "-1",
		["log_verbosity"]							= "2",
		--["sys_lowspecpak"]							= "0",
		["log_fileverbosity"]						= "4",
		["g_minteamlimit"]							= "0",
		["g_roundRestartTime"]						= "0",
		["g_revivetime"]							= "12",
		["g_timelimit"]								= "27360",
		["g_minplayerlimit"]						= "2",
		["g_friendlyfireratio"] 					= "0",
		["g_pp_scale_price"]						= "1",
		
		["g_c4_limit"]								= "1000",
		["g_claymore_limit"]	  				    = "4",
		["g_avmine_limit"]		   				    = "4",
		
		["nCX_PerformanceValue"]					= "106",
		["nCX_RecoilTreshold"]						= "0.0002",
		["nCX_VehicleCollisionRatio"]   		   	= "0.00015",
		["nCX_ExplosionMult"]   		   			= "0.25",
		["nCX_EnableAmmoBoost"]   		   			= "0",
		["nCX_Movement"]							= "0",
		["nCX_VehicleMovement"]						= "0",
		["nCX_PerformanceMode"]						= "1",
		["nCX_SrGameMode"]							= "Test Mode",
		
		["g_energy_scale_income"]   				= "0.4",
		["v_lights_disable_time"]  					= "-1",
		["g_suitspeedmultmultiplayer"]				= "0.42",
		["g_suitspeedenergyconsumptionmultiplayer"]	= "35",
		["g_suitcloakenergydrainadjuster"] 			= "0.5",
		
		["hud_onScreenFarSize"] 				= "0.5",
		["hud_onScreenNearSize"] 					= "1.1",
		
		--["r_texturesStreamPoolSize"]				= "250",
		--["r_texturesStreaming"]						= "0",
		--["net_inactivitytimeout"] = "1000",
		
		--test
		["cl_screeneffects"] 						= "0",
		["sys_flash_warning_level"] 				= "0",
		["p_net_smoothtime"]						= "1",
		["r_CustomVisions"] 						= "0",
		["sv_packetRate"] 							= "30",
		["cl_packetRate"] 							= "30",
		["cl_bandwidth"] 							= "100000",
		["sv_bandwidth"] 							= "100000", --1000000 wtf?
		["hud_showBigVehicleReload"]				= "1",
	    ["pl_zeroGBaseSpeed"] 						= "4",
		["pl_zeroGAimResponsiveness"] 				= "100",
		["pl_zeroGSpeedModeEnergyConsumption"] 		= "0",
		["v_altitudelimit"] 						= "500",
		--["v_enable_lumberjacks"] 					= "1",
		["hud_nightVisionConsumption"] 				= "0",
		["hud_nightVisionRecharge"]					= "1",
		["g_enableMPStealthOMeter"] 				= "1",
		["g_enableIdleCheck"] 						= "0", 
		
		["g_radialblur"] 							= "0",
		--["e_shadows_max_texture_size"] 				= "128",
		--["ca_gamecontrolledstrafing"] 				= "0",
	--	["p_fixed_timestep"] 						= "-0.033333333",
		["pl_zeroGParticleTrail"]  					= "1",
		["pl_zeroGEnableGBoots"]  					= "1",
		--["es_ImpulseScale"]							= "100",
		--["es_UpdateAI"]								= "0",
		
		--ghost fix?
		--["es_UsePhysVisibilityChecks"] 				= "1",
		--["sys_flash_edgeaa"] 						= "0",
		--["i_restrictItems"] = "flashbang claymore gauss c4 usgausstank ustank nktank nkapc usapc nkaaa",
		--["i_restrictitems"] = "flashbang Claymore claymore SCAR gauss explosivegrenade fgl40 ",
		--["v_newBrakingFriction"] = "1",
		--["v_newBoost"] = "1",
		--["v_enable_lumberjacks"] = "1",
		--["v_slipFrictionModFront"] = "1",
		--["v_slipFrictionModRear"] = "1",
		--["v_slipSlopeFront"] = "1",
		--["v_slipSlopeRear"] = "1",
	},
	KeepSynching = {
		["time_scale"] 		= true,
		["i_debuggun_1"] 	= true,
		["i_debuggun_2"] 	= true,	
	},
	-- These will be set on Server only, synching disabled!
	CVars_Server = {
--[[
		["ca_EnableAssetStrafing"] 					= "0",
		["ca_EnableAssetTurning"] 					= "0",
		["ca_UseAimIK"] 							= "0",	
		["ca_UseLookIK"] 							= "0",
		["ca_UseFacialAnimation"] 					= "0",		
		["ca_UseMorph"] 							= "0",	
		["ca_UsePhysics"] 							= "0",
		["ca_LoadDatabase"] 							= "0",
		["ca_ForceNullAnimation"] 							= "0",
		["es_OnDemandPhysics"] 						= "0",	
		["r_NoLoadTextures"] 						= "1",		
		["r_NoPreprocess"] 							= "1",	
		["e_materials"] 							= "0",			
		--["g_ec_enable"] 							= "0",	
		["g_enableAutoSave"] 						= "0",	
		["g_enableloadingscreen"] 					= "0",	
		["g_enableTracers"] 						= "0",	
		["h_useIK"] 								= "0",	
		["g_useProfile"] 							= "0",	
		["mfx_Enable"] 								= "0",	
		["mfx_EnableFGEffects"] 					= "0",	
		["net_enable_tfrc"] 						= "0",	
		["r_ShadersAlwaysUseColors"]				= "0",	
		["r_ShadersUserFolder"]						= "0",	
		["r_UseAlphaBlend"] 						= "0",	
		["r_UseHWSkinning"] 						= "0",	
		["r_UseMaterialLayers"]						= "0",	
		["r_UseParticlesGlow"] 						= "0",	
		["r_UseParticlesRefraction"] 				= "0",	
		["r_UseZPass"] 								= "0",
		["r_WaterReflectionsUseMinOffset"] 			= "0",
		--]]
	},
	Censor = {
		--[[
			MODIFIED by KM
			Changed to regular expressions (the most powerful tool available for string replacements)
			Formatting rules: Each character of the forbidden word needs to be encapsulated within
			[Ff]+ (both upper- and lower case, here: F is forbidden)
			followed by [^a-z^A-Z]* (which removes any blanks, special characters, numbers etc) from the word.
			This also recognizes 
			'f Uc &/k the fuCKi###ng GAY fUC  .......K897453/(&(/%$&ers ArSE'
		]]
		"gay", "cock",
		"fuck", "asshole",
		"fick", "arse",
		"nigger", "noob", "dick",
		"pussy", "anal", "fag", "shit", 
		"retard", "cyka", "blyat",
	},
	LevelRotation = {
		["mesa x"] = "PowerStruggle";
		["outpost x"] = "InstantAction";
		["mesa x"] = "PowerStruggle";
		["beach x"] = "PowerStruggle";
		["plantation x"] = "PowerStruggle";
		["savanna"] = "TeamInstantAction";
	},
};