-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Authors:  Arcziy & ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-11-22
-- *****************************************************************
--UNRAGDOLL_TIMER = 16;
BasicActor = {
	AnimationGraph = "PlayerFullBody.xml",
	UpperBodyGraph = "PlayerUpperBody.xml",
	Properties = {
		soclasses_SmartObjectClass = "Actor",
		ragdollPersistence = 0,
		physicMassMult = 1.0,
		Damage = {
			health = 100,
		},
	},
	tempSetStats = {},
	
	Client = {},
	
	grabParams = {
		collisionFlags = 0,
		holdPos = {x=0.0,y=0.4,z=1.25},
		grabDelay = 0,
		followSpeed = 5.5,
		limbs = {
			"rightArm",
			"leftArm",
		},
		useIKRotation = 0,
	},
	IKLimbs = {
		{0,"rightArm","Bip01 R UpperArm","Bip01 R Forearm","Bip01 R Hand", IKLIMB_RIGHTHAND},
		{0,"leftArm","Bip01 L UpperArm","Bip01 L Forearm","Bip01 L Hand", IKLIMB_LEFTHAND},
	},
	waterStats = {
		lastSplash = 0,
	},
	actorStats = {},
	
	---------------------------
	--		RegisterAI
	---------------------------
	RegisterAI = function(self)
		if ( self.AIType == nil ) then
			AI.RegisterWithAI(self.id, AIOBJECT_PUPPET, self.Properties, self.PropertiesInstance, self.AIMovementAbility,self.melee);
		else
			AI.RegisterWithAI(self.id, self.AIType, self.Properties, self.PropertiesInstance, self.AIMovementAbility,self.melee);
		end
		AI.ChangeParameter(self.id,AIPARAM_COMBATCLASS,AICombatClasses.Infantry);
		AI.ChangeParameter(self.id,AIPARAM_FORGETTIME_TARGET,self.forgetTimeTarget);
		AI.ChangeParameter(self.id,AIPARAM_FORGETTIME_SEEK,self.forgetTimeSeek);
		AI.ChangeParameter(self.id,AIPARAM_FORGETTIME_MEMORY,self.forgetTimeMemory);
	
		-- If the entity is hidden during 
		if (self:IsHidden()) then
			AI.LogEvent(self:GetName()..": The entity is hidden during init -> disable AI.");
			self:TriggerEvent(AIEVENT_DISABLE);
		end
	end,
	--[[
	Server = {
		---------------------------
		--		OnUpdate
		---------------------------
		OnUpdate = function(self, frameTime)
			if (self:IsDead()) then
				local flags = { 
					flags=
					geom_colltype_explosion + 
					geom_colltype_ray + 
					geom_colltype_foliage_proxy + 
					geom_colltype_player
				};
				self:SetPhysicParams(PHYSICPARAM_PART_FLAGS, flags); --CTAO enable ragdoll physics
			end
		end,
	},]]
	OnDeathHit = function(self, partId, pos, hitDir)
		--Log("BasicActor.Server:OnDeadHit()");
		System.LogAlways("OnDeathHit start");
		local frameID = System.GetFrameID();
		
		--if ((frameID - self.lastDeathImpulse) > 10) then
			--marcok: talk to me before touching this
			local dir = g_Vectors.temp_v2;
			CopyVector(dir, hitDir);
			dir.z = dir.z + 1;
			--dir.x = random(-0.1, 0.1); dir.y = random(-0.1, 0.1); dir.z = 1;

			local angAxis = g_Vectors.temp_v3;
			angAxis.x = math.random() * 2 - 1;
			angAxis.y = math.random() * 2 - 1;
			angAxis.z = math.random() * 2 - 1;
			
			local imp1 = 1000; --math.random() * 20 + 10;
			local imp2 = math.random() * 20 + 10;
			--System.Log("DeadHit linear: "..string.format(" %.03f,%.03f,%.03f",dir.x,dir.y,dir.z).." -> "..tostring(imp1));
			--System.Log("DeadHit angular: "..string.format(" %.03f,%.03f,%.03f",angAxis.x,angAxis.y,angAxis.z).." -> "..tostring(imp2));
			
			self:AddImpulse( partId, pos, dir, imp1, 1, angAxis, imp2, 35);
			self.lastDeathImpulse = frameID;
		--end 
		System.LogAlways("OnDeathHit success");
	end,
	---------------------------
	--		CreateActor
	---------------------------
	CreateActor = function(self, child)
		mergef(child,BasicActorParams,1);
		mergef(child,self,1);
	end,
	---------------------------
	--		RemoveActor
	---------------------------
	RemoveActor = function(self)
		self.actor:SetHealth(0);
		self:DestroyPhysics();
		System.RemoveEntity(self.id);
	end,
	---------------------------
	--		ResetCommon
	---------------------------
	ResetCommon = function(self)
		self.actor:Revive();
		local health = System.GetCVar("g_playerHealthValue");
		self.actor:SetMaxHealth(health);
		self:RemoveDecals();
		self:EnableDecals(0, true);
		self.bodyUnseen = 0;
	end,
	---------------------------
	--			Reset
	---------------------------
	Reset = function(self)
		self:ResetCommon();
		self.actor:SetMovementTarget(g_Vectors.v000,g_Vectors.v000,g_Vectors.v000,1);
		self:ActorLink();
	end,
	---------------------------
	--		InitIKLimbs
	---------------------------
	InitIKLimbs = function(self)
		if (self.IKLimbs) then
			for i,limb in pairs(self.IKLimbs) do
				self.actor:CreateIKLimb(limb[1],limb[2],limb[3],limb[4],limb[5],limb[6] or 0);
			end
		end
	end,
	---------------------------
	--	SetAnimKeyEvent
	---------------------------
	SetAnimKeyEvent = function(self, animation, frame, func)
		if (animation and animation ~="") then
			if (not self.onAnimationKey) then
				self.onAnimationKey = {};
			end
			self.onAnimationKey[animation..frame] = func;
			self:SetAnimationKeyEvent(0, animation,frame,animation..frame);
		end
	end,
		---------------------------
	--	GrabObject
	---------------------------
	GrabObject = function(self, object, query)
		--FIXME:
		--if (query and self.actor:IsPlayer()) then
		--	return 0;
		--end
		
		self.grabParams.entityId = object.id;
		local grabParams = new(self.grabParams);
		grabParams.event = "grabObject";
		
		if (self.actor:CreateCodeEvent(grabParams)) then
			return 1;
		end
		
		return 0;
	end,
	---------------------------
	--	GetGrabbedObject
	---------------------------
	GetGrabbedObject = function(self)
		return (self.grabParams.entityId or 0);
	end,
	---------------------------
	--	DropObject
	---------------------------
	DropObject = function(self, throw,throwVec,throwDelay)

		local dropTable =
		{
			event = "dropObject",
			throwVec = {x=0,y=0,z=0},
			throwDelay = throwDelay or 0,
		};
			
		if (throwVec) then
			math:CopyVector(dropTable.throwVec,throwVec);
		end
			
		self.actor:CreateCodeEvent(dropTable);
	end,
	---------------------------
	--		ShutDown
	---------------------------
	ShutDown = function(self)
		self:ResetAttachment(0, "right_item_attachment");
		self:ResetAttachment(0, "left_item_attachment");
		self:ResetAttachment(0, "laser_attachment");
	end,
	---------------------------
	--			OnHit
	---------------------------
	OnHit = function(self, hit)
		if (hit.shattered) then
			g_gameRules:ProcessDeath(hit, self);
			return;
		end
		if (nCX.LogPlayerOnHit) then
			System.LogAlways("============================");
			for s, v in pairs(hit) do
				System.LogAlways(tostring(s).." - "..tostring(v));
			end
		end
		local shooter, target = hit.shooter or self, self;
		hit.self = (shooter.id == self.id);
		local health = self.actor:GetHealth();
		if (hit.damage >= 1 and not hit.self) then
			if (not hit.shooter or hit.damage > 3.0) then
				nCX.SendDamageIndicator(hit.target.id, (hit.shooter and hit.shooter.id or NULL_ENTITY), hit.weaponId or NULL_ENTITY);	
			end
			if (hit.shooter and hit.shooter.actor and not hit.self) then
				nCX.SendHitIndicator(hit.shooter.id, hit.explosion or false);
			end
		end
		if (health and health >= 2) then
			--local vehicle = self.actor:GetLinkedVehicle();
			local fire = hit.type == 7;
			local s_vehicle = hit.shooter and hit.shooter.actor and hit.shooter.actor:GetLinkedVehicle();
			local prev = hit.damage;
			local quit;
			if (not fire) then
				quit, hit = CryMP:HandleEvent("PreHit", {hit, shooter, self, s_vehicle});
			end
			if (not quit) then
				--[[
				local absorption, energy = 0, self.actor:GetNanoSuitEnergy();
				local mode = self.actor:GetNanoSuitMode();
				if (mode == 3) then
					local dmg = (hit.damage * 4.2);
					energy = energy - dmg;
					if (energy < 0.0) then
						absorption, energy = (1 + energy / dmg), 0;
					else
						absorption = 1;
					end
					absorption = math.max(0, absorption);
				end		
				]]
				local deadly = false;
				if (self.actor.class ~= "Shark") then
					deadly = self.actor:NanoSuitHit(hit.damage);
				end
				--[[
				local absorption = 0;
				local mode = self.actor:GetNanoSuitMode();
				if(mode == 3) then -- armor mode
					local currentSuitEnergy = self.actor:GetNanoSuitEnergy();
					-- Reduce energy based on damage. The left over will be reduced from the health.
					local suitEnergyLeft = currentSuitEnergy - (hit.damage*1.5); -- armor energy is 25% weaker than health
					if (suitEnergyLeft < 0.0) then
						self.actor:SetNanoSuitEnergy(0);
						absorption = 1 + suitEnergyLeft/(hit.damage*1.5);
					else
						self.actor:SetNanoSuitEnergy(suitEnergyLeft);
						absorption = 1;
					end
				
					absorption = math.max(0, absorption);
				end
						
				local new = math.floor(health - hit.damage * (1 - absorption));
				self.actor:SetHealth(new);
				]]
				if (not fire) then
					CryMP:HandleEvent("OnHit", {hit, shooter, self, s_vehicle});
				end
				if (deadly) then
					if (hit.self and hit.damage ~= 32760 and hit.typeId ~= 29) then -- target suicides (but not with suicide button or rpg)
						local data = self.lastHit;
						if (data and _time - data[2] < (data[3] or 4)) then 
							local newShooter = nCX.GetPlayer(data[1]);
							if (newShooter) then
								hit.shooter = newShooter;  
								hit.shooterId = newShooter.id;
								hit.self = false;
								if (not data[3]) then
									hit.weaponId = newShooter.id;  -- skull hit type
								end
							else
								self.lastHit = nil;
							end				
						end
					end
					local pos, dir;
					local bloodScale = hit.headshot and 1.4 or 0.9;
					if (hit.explosion or hit.self) then
						pos = target:GetWorldPos();
						pos.z = pos.z + 1.0;
						bloodScale = 1.5;
					end
					--nCX.ParticleManager("misc.blood_fx.ground", bloodScale, pos or hit.pos, g_Vectors.up, 0); --misc.blood_fx.dripping
					g_gameRules:ProcessDeath(hit, self);
				elseif (shooter.actor and not hit.self and not nCX.IsSameTeam(shooter.id, target.id)) then
					self.lastHit = {shooter.id, _time};
					self.hitAssist = self.hitAssist or {};  -- assist
					self.hitAssist[shooter.id] = _time;
				end
				--LogHitToFile(hit, true);
			end
		end
	end,
	---------------------------
	--		IsDead
	---------------------------
	IsDead = function(self)
		return ((self.actor:GetHealth() or 0) <= 0)
	end,
	---------------------------
	--		IsOnVehicle
	---------------------------
	IsOnVehicle = function(self)
		return self.actor:GetLinkedVehicleId();
	end,
	---------------------------
	--		TurnRagdoll
	---------------------------
	TurnRagdoll = function(self, param)
		if (param) then
			self.actor:SetPhysicalizationProfile("ragdoll");
		end
	end,
	---------------------------
	--			Kill
	---------------------------
	Kill = function(self, ragdoll, shooterId, weaponId, freeze)
		self.actor:Kill();
		if (self.actor:GetHealth() > 0) then
			self.actor:SetHealth(0);
		end
		if (not self.actor:GetLinkedVehicleId()) then
			if (ragdoll) then
				self:TurnRagdoll(1);
			end
		end
		return true;
	end,
	---------------------------
	--		GetFrozenAmount
	---------------------------
	GetFrozenAmount = function(self)
		return self.actor:GetFrozenAmount();
	end,
	---------------------------
	--		SetActorModel
	---------------------------
	SetActorModel = function(self)
		CryMP.RSE:SAM(self);
		--[[
		local PropInstance = self.PropertiesInstance;
		local model = self.Properties.fileModel;
	   local nModelVariations = self.Properties.nModelVariations;
	   if (nModelVariations and nModelVariations > 0 and PropInstance and PropInstance.nVariation) then
		  local nModelIndex = PropInstance.nVariation;
		  if (nModelIndex < 1) then
			 nModelIndex = 1;
		  end
		  if (nModelIndex > nModelVariations) then
			 nModelIndex = nModelVariations;
		  end
		  local sVariation = ('%.2d'):format(znModelIndex);
		  model = (model):gsub("_%d%d", "_"..sVariation);
		end
		if (self.currModel ~= model) then
			self.currModel = model;
			self:LoadCharacter(0, model);
			self:InitIKLimbs();
			self:ForceCharacterUpdate(0, false);
			if (self.Properties.objFrozenModel and self.Properties.objFrozenModel~="") then
				self:LoadObject(1, self.Properties.objFrozenModel);
				self:DrawSlot(1, 0);
			end
			self:CreateBoneAttachment(0, "weapon_bone", "right_item_attachment");
			self:CreateBoneAttachment(0, "alt_weapon_bone01", "left_item_attachment");
			self:CreateBoneAttachment(0, "alt_weapon_bone01", "left_hand_grenade_attachment");
			self:CreateBoneAttachment(0, "weapon_bone", "laser_attachment");
			if (self.CreateAttachments) then
				self:CreateAttachments();
			end
		end
		if (self.currItemModel ~= self.Properties.fpItemHandsModel) then
			self:LoadCharacter(3, self.Properties.fpItemHandsModel);
			self:DrawSlot(3, 0);
			self:LoadCharacter(4, self.Properties.fpItemHandsModel);
			self:DrawSlot(4, 0);
			self.currItemModel = self.Properties.fpItemHandsModel;
		end]]
	end,
	---------------------------
	--		OnResetLoad
	---------------------------
	OnResetLoad = function(self)
		self.actor:SetPhysicalizationProfile("alive");
	end,
	---------------------------
	--		OnSpawn
	---------------------------
	OnSpawn = function(self)
		self.grabParams = new(self.grabParams);
		self.waterStats = new(self.waterStats);
		self.actorStats = new(self.actorStats);
	end,
	---------------------------
	--		Resurrect
	---------------------------
	Resurrect = function(self)
		self:OnResetLoad();
		self.ResetLoad(self);
	end,
	---------------------------
	--		ScriptEvent
	---------------------------
	ScriptEvent = function(self, event, value, str)
		if (event == "animationevent") then
			if (self.AnimationEvent) then
				self:AnimationEvent(str,value);
			end
		elseif (event == "resurrect") then
			self:Resurrect();
		elseif (event == "holster") then
			self.actor:HolsterItem(value);
		elseif (event == "kill") then
			self:Kill(true, NULL_ENTITY, NULL_ENTITY);
		elseif (event == "detachLadder") then
			if (self.ladderId == self.OnUseEntityId) then
				self:UseEntity( self.OnUseEntityId, self.OnUseSlot, true);
			end
		end
	end,
	---------------------------
	--		ActorLink
	---------------------------
	ActorLink = function(self, entName)
		if (not entName) then
			self.actor:LinkToEntity();
		else
			local ent = System.GetEntityByName(entName);
			self.actor:LinkToEntity(ent.id);
		end
	end,
	---------------------------
	--		SetCloakType
	---------------------------
	SetCloakType = function(self, cloakType)
		local params = {
			nanoSuit = {
				cloakType = 2,
				cloakEnergyCost = 10.0,
				cloakHealthCost = 0.0,
				cloakVisualDamp = 0.5,
				cloakSoundDamp = 0.1,
				cloakHeatDamp = 1.0,
				cloakHudMessage = "normal_cloak",
			},
		};
		local nanoSuit = params.nanoSuit;
		self.actor:SetParams(params);
	end,
			
	IsDuelPlayer = function(self)
		return CryMP.Duel and CryMP.Duel:IsDuelPlayer(self.id);
	end,
	IsAfk = function(self)
		return CryMP.AFKManager and CryMP.AFKManager:IsAfk(self);
	end,
	IsBoxing = function(self)
		return CryMP.Boxing and CryMP.Boxing:IsBoxing(self.Info.Channel);
	end,
	IsRacing = function(self)
		return CryMP.Race and CryMP.Race:IsRacing(self.Info.Channel);
	end,
	GetLevel = function(self)
		return (CryMP.PermaScore and CryMP.PermaScore:GetLevel(self.Info.ID)) or 0;
	end,
	GetPlayTime = function(self, round)
		return (CryMP.PermaScore and CryMP.PermaScore:GetPlayTime(self.Info.ID, round, true)) or 0,0;
	end,
	GetRank = function(self)
		return (CryMP.PermaScore and CryMP.PermaScore:GetRank(self.Info.ID)) or 0;
	end,
	GetAccess = function(self)
		return (CryMP.Users and CryMP.Users:GetAccess(self.Info.ID));
	end,
	IsMostWanted = function(self)
		return (CryMP.KillStreaks and CryMP.KillStreaks:IsMostWanted(self.Info.Channel));
	end,
	IsNomad = function(self)
		return self:GetName():find(tostring(self.Info.Channel))
	end,
	GetAttachments = function(self, class)
		if (CryMP.Attach) then
			local data = CryMP.Attach:GetData(self.Info.ID);
			return data and data[class] or CryMP.Attach.Default[class];
		end
	end,
};

