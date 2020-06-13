Script.ReloadScript( "Server/Lua-Files/Physics/BasicEntity.lua" );

-- Basic entity
RigidBodyEx = {
	Properties = {
		object_Model = "",
		Physics = {
			bRigidBodyActive = 1,
			bActivateOnDamage = 0,
			bResting = 1, -- If rigid body is originally in resting state.
			bCanBreakOthers = 0,
			Simulation =
			{
				max_time_step = 0.02,
				sleep_speed = 0.04,
				damping = 0,
				bFixedDamping = 0,
				bUseSimpleSolver = 0,
			},
			Buoyancy=
			{
				water_density = 1000,
				water_damping = 0,
				water_resistance = 1000,	
			},
		},
	},

	--MakeDerivedEntity( RigidBodyEx,BasicEntity ) --dont enable :D


	Client = {
	    OnPhysicsBreak = function() end,
	},
	Server = {
		
		OnInit = function(self)
			self:PhysicalizeThis();
		end,
	
	},
		
	---------------------------
	--		OnLoad
	---------------------------	
	OnLoad = function(self, table)  
	  self.bRigidBodyActive = table.bRigidBodyActive;
	end,
	---------------------------
	--		OnSave
	---------------------------	
	OnSave = function(self, table)  
		table.bRigidBodyActive = self.bRigidBodyActive;
	end,
	---------------------------
	--		OnSpawn
	---------------------------	
	OnSpawn = function(self)
		if (self.Properties.Physics.bRigidBodyActive == 1) then
			self.bRigidBodyActive = 1;
		end
		self:SetFromProperties();	
	end,
	---------------------------
	--		SetFromProperties
	---------------------------	
	SetFromProperties = function(self)
		local Properties = self.Properties;
		if (Properties.object_Model == "") then
			return;
		end
		self:LoadObject(0,Properties.object_Model);
		--self:CharacterUpdateOnRender(0,1); -- If it is a character force it to update on render.
		if (Properties.object_ModelFrozen ~= "") then
			--self.frozenModelSlot = self:LoadObject(-1, Properties.object_ModelFrozen);
			--self:DrawSlot(self.frozenModelSlot, 0);
		else
			self.frozenModelSlot = nil;
	    end
		--self:DrawSlot(0,1);
		if (Properties.Physics.bPhysicalize == 1) then
			--self:PhysicalizeThis();
		end	
	end,
	---------------------------
	--		PhysicalizeThis
	---------------------------	
	PhysicalizeThis = function(self)
		local physics = self.Properties.Physics;
		if (CryAction.IsImmersivenessEnabled() == 0) then
			local Physics_DX9MP_Simple = {
				bRigidBodyActive = 0,
				bActivateOnDamage = 0,
				bResting = 1, -- If rigid body is originally in resting state.
				Simulation =
				{
					max_time_step = 0.02,
					sleep_speed = 0.04,
					damping = 0,
					bFixedDamping = 0,
					bUseSimpleSolver = 0,
				},
				Buoyancy=
				{
					water_density = 1000,
					water_damping = 0,
					water_resistance = 1000,	
				},
			}
			physics = Physics_DX9MP_Simple;
		end
		EntityCommon.PhysicalizeRigid( self,0,physics,self.bRigidBodyActive );
	end,
	---------------------------
	--		OnPropertyChange
	---------------------------	
	OnPropertyChange = function(self)
		self:SetFromProperties();
	end,
	---------------------------
	--		OnReset
	---------------------------	
	OnReset = function(self)
		--self:ResetOnUsed()
		local PhysProps = self.Properties.Physics;
		if (PhysProps.bPhysicalize == 1) then
			if (self.bRigidBodyActive ~= PhysProps.bRigidBodyActive) then
				self.bRigidBodyActive = PhysProps.bRigidBodyActive;
				--self:PhysicalizeThis();
			end
			if (PhysProps.bRigidBody == 1) then
				--self:AwakePhysics(1-PhysProps.bResting);
				self.bRigidBodyActive = PhysProps.bRigidBodyActive;
			end		
		end
	end,
	---------------------------
	--		GetFrozenSlot
	---------------------------	
	GetFrozenSlot = function(self)
		if (self.frozenModelSlot) then
			return self.frozenModelSlot;
		end
		return -1;
	end,
	---------------------------
	--		Event_Remove
	---------------------------	
	Event_Remove = function(self)
		self:DrawSlot(0,0);
		self:DestroyPhysics();
		self:ActivateOutput( "Remove", true );
	end,
	---------------------------
	--		Event_Hide
	---------------------------	
	Event_Hide = function(self)
		self:Hide(1);
		self:ActivateOutput( "Hide", true );
	end,
	---------------------------
	--		Event_UnHide
	---------------------------	
	Event_UnHide = function(self)
		self:Hide(0);
		self:ActivateOutput( "UnHide", true );
	end,
	---------------------------
	--		Event_RagDollize
	---------------------------	
	Event_RagDollize = function(self)  
		self:RagDollize(0);
		self:ActivateOutput( "RagDollized", true );
	end,
	---------------------------
	--		OnDamage
	---------------------------	
	OnDamage = function(self, hit)
		if (self:IsARigidBody() == 1) then		
			if (self.Properties.Physics.bActivateOnDamage == 1) then
				if (hit.explosion and self:GetState()~="Activated") then
					BroadcastEvent(self, "Activate");
					self:GotoState("Activated");
				end
			end
		end
		if (hit.ipart and hit.ipart>=0 ) then
			self:AddImpulse( hit.ipart, hit.pos, hit.dir, hit.impact_force_mul );
		end
	end,
	---------------------------
	--		Event_Activate
	---------------------------	
	Event_Activate = function(self, sender)	
	    self:GotoState("Activated");
	end,
	---------------------------
	--		CommonSwitchToMaterial
	---------------------------	
	CommonSwitchToMaterial = function(self, numStr )
		if (not self.sOriginalMaterial) then
			self.sOriginalMaterial = self:GetMaterial();
		end
		if (self.sOriginalMaterial) then
			self:SetMaterial( self.sOriginalMaterial..numStr );
		end
	end,
	---------------------------
	--		Event_SwitchToMaterialOriginal
	---------------------------	
	Event_SwitchToMaterialOriginal = function(self, sender)
		self:CommonSwitchToMaterial( "" );
	end,
	---------------------------
	--		Event_SwitchToMaterial1
	---------------------------	
	Event_SwitchToMaterial1 = function(self, sender)
		self:CommonSwitchToMaterial( "1" );
	end,
	---------------------------
	--		Event_SwitchToMaterial2
	---------------------------	
	Event_SwitchToMaterial2 = function(self, sender)
		self:CommonSwitchToMaterial( "2" );
	end,

};

RigidBodyEx.Default = {
	OnBeginState = function(self)
		if (self:IsARigidBody()==1) then
			if (self.bRigidBodyActive~=self.Properties.Physics.bRigidBodyActive) then
				self:SetPhysicsProperties( 0,self.Properties.Physics.bRigidBodyActive );
			else
				System.LogAlways("Awake Physics...");
				self:AwakePhysics(1-self.Properties.Physics.bResting);
			end  
		end
	end,
	OnDamage = RigidBodyEx.OnDamage,
	OnCollision = RigidBodyEx.OnCollision,
	OnPhysicsBreak = RigidBodyEx.OnPhysicsBreak,
};

RigidBodyEx.Activated = {
	OnBeginState = function(self)
		if (self:IsARigidBody()==1 and self.bRigidBodyActive==0) then
			self:SetPhysicsProperties( 0,1 );
			self:AwakePhysics(1);
		end
	end,
	OnDamage = RigidBodyEx.OnDamage,
	OnCollision = RigidBodyEx.OnCollision,
	OnPhysicsBreak = RigidBodyEx.OnPhysicsBreak,
};

RigidBodyEx.FlowEvents = {
	Inputs = {
		Used = { RigidBodyEx.Event_Used, "bool" },
		EnableUsable = { RigidBodyEx.Event_EnableUsable, "bool" },
		DisableUsable = { RigidBodyEx.Event_DisableUsable, "bool" },
		Activate = { RigidBodyEx.Event_Activate, "bool" },
		Hide = { RigidBodyEx.Event_Hide, "bool" },
		UnHide = { RigidBodyEx.Event_UnHide, "bool" },
		Remove = { RigidBodyEx.Event_Remove, "bool" },
		RagDollize = { RigidBodyEx.Event_RagDollize, "bool" },		
		SwitchToMaterial1 = { RigidBodyEx.Event_SwitchToMaterial1, "bool" },
		SwitchToMaterial2 = { RigidBodyEx.Event_SwitchToMaterial2, "bool" },
		SwitchToMaterialOriginal = { RigidBodyEx.Event_SwitchToMaterialOriginal, "bool" },
	},
	Outputs = {
		Used = "bool",
		EnableUsable = "bool",
		DisableUsable = "bool",
		Activate = "bool",
		Hide = "bool",
		UnHide = "bool",
		Remove = "bool",
		RagDollized = "bool",		
		Break = "int",
	},
};

