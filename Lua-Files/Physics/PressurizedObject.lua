-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2013-03-19
-- *****************************************************************

PressurizedObject = {
	Properties = {
		bAutoGenAIHidePts = 0,
		objModel 					= "objects/library/props/fire extinguisher/fire_extinguisher.cgf",
		Vulnerability = {
			bExplosion = 1,
			bCollision = 1,
			bMelee		 = 1,
			bBullet		 = 1,
			bOther	   = 1,
		},
		DamageMultipliers = {
		  fCollision = 1.0,
		  fBullet    = 1.0,		  
		},
		fDamageTreshold		= 0,
		Leak = {
			Effect = {
				Effect					= "bullet.hit_metal.a",
				SpawnPeriod			= 0.1,
				Scale						= 1,
				CountScale			= 1,
				bCountPerUnit		= 0,
				bSizePerUnit		= 0,
				AttachType			= "none",
				AttachForm			= "none",
				bPrime					= 1,
			},
			Damage					= 100,
			DamageRange			= 3,
			DamageHitType		= "fire",
			Pressure				= 1000,
			PressureDecay		= 10,
			PressureImpulse	= 100,
			MaxLeaks				= 10,
			ImpulseScale		= 1,
			Volume					= 10;
			VolumeDecay			= 1;
		},

		bPlayerOnly					= 1,
		fDensity 						= 1000,
		fMass 							= 10,
		bResting 						= 1, -- If rigid body is originally in resting state.
		bRigidBody 					= 0,
		bCanBreakOthers     = 0,
		bPushableByPlayers  = 0,

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
	},

	Client = {},
	
	Server = {
		---------------------------
		--		OnInit
		---------------------------	
		OnInit = function(self)
			if (not self.bInitialized) then
				self:OnReset();
				self.bInitialized = 1;
			end
			self.leaks = 0;
			self.maxLeaks = self.Properties.Leak.MaxLeaks;
			self.pressure = self.Properties.Leak.Pressure;
			self.totalPressure=self.pressure;
			self.pressureDecay = self.Properties.Leak.PressureDecay;
			self.pressureImpulse = self.Properties.Leak.PressureImpulse;
			self.maxLeaks = self.Properties.Leak.MaxLeaks;
			self.volume=self.Properties.Leak.Volume;
			self.leakInfo = {};
		end,
		---------------------------
		--		OnUpdate
		---------------------------	
		OnUpdate = function(self, frameTime)
			local decay = self.pressureDecay*self.leaks*frameTime;
			self.pressure = self.pressure-decay;
			self.volume=self.volume-self.Properties.Leak.VolumeDecay*frameTime;
			if (self.pressure>0) then
				local impulse = ((self.pressureImpulse*self.pressure)/self.leaks)*frameTime*self.Properties.Leak.ImpulseScale;
				
				if (impulse>0) then
					for i,leak in pairs(self.leakInfo) do
						CryMP.RSE:DoPOC(self, leak, impulse);
						--System.LogAlways("AddImpulse");
					end
				end
			elseif (self.pressure<=0) then
				if (self.volume<=0) then
					self:ClearLeaks();
					CryAction.ForceGameObjectUpdate(self.id, false);
				end
			end
		end,
	},
	---------------------------
	--		OnSpawn
	---------------------------	
	OnSpawn = function(self)
		local model = self.Properties.objModel;
		if (string.len(model) > 0) then
			local ext = string.lower(string.sub(model, -4));
			if ((ext == ".chr") or (ext == ".cdf") or (ext == ".cga")) then
				self:LoadCharacter(0, model);
			else
				self:LoadObject(0, model);
			end
		end
	end,
	---------------------------
	--		OnHit
	---------------------------	
	OnHit = function(self, hit)
		--System.LogAlways("ONHit");
		if (hit.explosion) then
			return;
		end
		
		local playerOnly = NumberToBool(self.Properties.bPlayerOnly);

		local damage = hit.damage;	
		local vul = self.Properties.Vulnerability;
		local mult = self.Properties.DamageMultipliers;
		
		local pass = true;
		if (hit.explosion) then pass = NumberToBool(vul.bExplosion);
		elseif (hit.type=="collision") then pass = NumberToBool(vul.bCollision); damage = damage * mult.fCollision;
		elseif (hit.type=="bullet") then pass = NumberToBool(vul.bBullet); hit.damage = damage * mult.fBullet;
		elseif (hit.type=="melee") then pass = NumberToBool(vul.bMelee); 
		else pass = NumberToBool(vul.bOther); end	
		
		pass = pass and damage >= self.Properties.fDamageTreshold;
		
		---if(not pass)then return;end;
	
		if (#self.leakInfo < self.maxLeaks and CryAction.IsImmersivenessEnabled() ~= 0) then
			local slot=CryMP.RSE:GetPOC(hit, self);
			--System.LogAlways("AddLeak");
			local leak = {};
			leak.pos = hit.pos;
			leak.dir = hit.normal;
			leak.slot = slot;
			self.leaks = self.leaks + 1;
			--[[
			local slot = self:LoadParticleEffect(self.leaks, self.Properties.Leak.Effect.Effect, self.Properties.Leak.Effect,{Scale = 0.1});
			if (slot) then
				System.LogAlways("Slot found! "..slot);
				self:SetSlotWorldTM(slot, pos, dir);
			else
				System.LogAlways("No slot found!");
				for i = 1, 50,1  do
					local s = self:LoadObject(i, "dummy"); -- dummy particle effect
					if (slot) then
						System.LogAlways("New Slot found! "..slot);
						self:SetSlotWorldTM(slot, pos, dir);
						leak.slot = slot;
						break;
					end
				end
			end]]
			self:Activate(1);
			--System.LogAlways("Add Leak slot "..self.leaks.." | "..self.maxLeaks);
			self.leakInfo[#self.leakInfo+1] = leak;
		---else
			--self:Activate(0);
		end
	end,
	---------------------------
	--		ClearLeaks
	---------------------------	
	ClearLeaks = function(self)
		if (self.leakInfo) then
			for i,v in ipairs(self.leakInfo) do
				--self:StopLeaking(v);
				if (v.slot) then
					--self:FreeSlot(v.slot);
				end
			end
		end
		--self:Activate(0);
		self.empty = true;
		--self.leaks = 0;
		--self.leakInfo = {};
		--CryAction.ForceGameObjectUpdate(self.id, false);
	end,
	---------------------------
	--		OnReset
	---------------------------	
	OnReset = function(self)
		local params = {
			mass = self.Properties.fMass,
			density	= self.Properties.fDensity,
		};
		local bRigidBody = (tonumber(self.Properties.bRigidBody) ~= 0);
		if (CryAction.IsImmersivenessEnabled() == 0) then
			bRigidBody = nil;
		end
		if (bRigidBody) then
			self:Physicalize(0, PE_RIGID, params);

			if (tonumber(self.Properties.bResting) ~= 0) then
				self:AwakePhysics(0);
			else
				self:AwakePhysics(1);
			end
			
			self:SetPhysicParams(PHYSICPARAM_BUOYANCY, self.Properties.PhysicsBuoyancy);
			self:SetPhysicParams(PHYSICPARAM_SIMULATION, self.Properties.PhysicsSimulation);
		else
			self:Physicalize(0, PE_STATIC, params);
		end
		local PhysFlags = {};
		PhysFlags.flags =  0;
		if (self.Properties.bPushableByPlayers == 1) then
		  PhysFlags.flags = pef_pushable_by_players;
		end
		if (self.Properties.bCanBreakOthers==nil or self.Properties.bCanBreakOthers==0) then
			PhysFlags.flags = PhysFlags.flags+pef_never_break;
		end
		PhysFlags.flags_mask = pef_pushable_by_players + pef_never_break;
		self:SetPhysicParams( PHYSICPARAM_FLAGS,PhysFlags );
	end,
	---------------------------
	--		OnPropertyChange
	---------------------------	
	OnPropertyChange = function(self)
		self:OnReset();
	end,
	---------------------------
	--		OnDestroy
	---------------------------	
	OnDestroy = function(self)
	end,
	
};
