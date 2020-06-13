-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach and Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2013-03-19
-- *****************************************************************
Script.ReloadScript("Server/Lua-Files/Utils/EntityUtils.lua");

BasicEntity = {
	Properties = {
		soclasses_SmartObjectClass = "",
		bAutoGenAIHidePts = 0,
		object_Model = "",
		object_ModelFrozen = "",
		bPickable = 1; --test
		Physics = {
			bPhysicalize = 1,
			bRigidBody = 1,
			bPushableByPlayers = 1,
			Density = -1,
			Mass = -1,
		},
		bFreezable = 1,
		bCanShatter = 1,
	},
	Client = {
	    OnPhysicsBreak = function() end,
	},
	Server = {},
	_Flags = {},
	---------------------------
	--		OnSpawn
	---------------------------	
	OnSpawn = function(self)
		local Properties = self.Properties;
		self:LoadObject(0,Properties.object_Model); -- needed
		local Physics = self.Properties.Physics;
		if (CryAction.IsImmersivenessEnabled() == 0) then  -- DX9 mode
			Physics = {  -- must be present or disco :S 
				bPhysicalize = 1, 
				bPushableByPlayers = 1, 
				Density = 0,
				Mass = 100,
			};
		end
		local PhysFlags = EntityCommon.TempPhysicsFlags;
		PhysFlags.flags =  0;
		if (Properties.bPushableByPlayers == 1) then
		  PhysFlags.flags = pef_pushable_by_players;
		end
		if (Simulation and Simulation.bFixedDamping and Simulation.bFixedDamping==1) then
			PhysFlags.flags = PhysFlags.flags+pef_fixed_damping;
		end
		if (Simulation and Simulation.bUseSimpleSolver and Simulation.bUseSimpleSolver==1) then
			PhysFlags.flags = PhysFlags.flags+ref_use_simple_solver;
		end
		if (Properties.bCanBreakOthers==nil or Properties.bCanBreakOthers==0) then
			PhysFlags.flags = PhysFlags.flags+pef_never_break;
		end
		PhysFlags.flags_mask = pef_fixed_damping + ref_use_simple_solver + pef_pushable_by_players + pef_never_break;
		self:SetPhysicParams( PHYSICPARAM_FLAGS,PhysFlags );
	end,
	
--[[---------------------------
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
	end,]]
};

BasicEntity.FlowEvents = {
	Inputs = {
		Used = { BasicEntity.Event_Used, "bool" },
		EnableUsable = { BasicEntity.Event_EnableUsable, "bool" },
		DisableUsable = { BasicEntity.Event_DisableUsable, "bool" },
		Hide = { BasicEntity.Event_Hide, "bool" },
		UnHide = { BasicEntity.Event_UnHide, "bool" },
		Remove = { BasicEntity.Event_Remove, "bool" },
		RagDollize = { BasicEntity.Event_RagDollize, "bool" },
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

--[[
	Client = {
	    OnPhysicsBreak = function() end,
	},
	Server = {},
	_Flags = {},
	---------------------------
	--		OnSpawn
	---------------------------	
	OnSpawn = function(self)
		self.bRigidBodyActive = 1;
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
		self.freezable=tonumber(Properties.bFreezable)~=0;
		self:LoadObject(0,Properties.object_Model); --needed
		if (Properties.object_ModelFrozen ~= "") then
			self.frozenModelSlot = self:LoadObject(-1, Properties.object_ModelFrozen);
			--self:DrawSlot(self.frozenModelSlot, 0);
		else
			self.frozenModelSlot = nil;
		end
		if (Properties.Physics.bPhysicalize == 1) then
			self:PhysicalizeThis();
		end	
		--System.LogAlways(dump(self));
		
	end,
	
	---------------------------
	--		SetFromProperties
	---------------------------	
	OnHit = function(self)
		System.LogAlways(self:GetName().." | OnHit");
		
	end,
	---------------------------
	--		IsRigidBody
	---------------------------	
	IsRigidBody = function(self)
		local Properties = self.Properties;
		local Mass = Properties.Mass; 
		local Density = Properties.Density;
		if (Mass == 0 or Density == 0 or Properties.bPhysicalize ~= 1) then 
			return false;
		end
		return true;
	end,
	---------------------------
	--		PhysicalizeThis
	---------------------------	
	PhysicalizeThis = function(self)
		local Physics = self.Properties.Physics;
		if (CryAction.IsImmersivenessEnabled() == 0) then  -- DX9 mode
			Physics = {  -- must be present or disco :S 
				bPhysicalize = 1, 
				bPushableByPlayers = 1, 
				Density = 0,
				Mass = 100,
			};
		end
		EntityCommon.PhysicalizeRigid( self,0,Physics,self.bRigidBodyActive );
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
		self:ResetOnUsed()
		local PhysProps = self.Properties.Physics;
		if (PhysProps.bPhysicalize == 1) then
			self:PhysicalizeThis();
			self:AwakePhysics(0);
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

};


--MakeUsable(BasicEntity);
--MakePickable(BasicEntity);

BasicEntity.FlowEvents = {
	Inputs = {
		Used = { BasicEntity.Event_Used, "bool" },
		EnableUsable = { BasicEntity.Event_EnableUsable, "bool" },
		DisableUsable = { BasicEntity.Event_DisableUsable, "bool" },
		Hide = { BasicEntity.Event_Hide, "bool" },
		UnHide = { BasicEntity.Event_UnHide, "bool" },
		Remove = { BasicEntity.Event_Remove, "bool" },
		RagDollize = { BasicEntity.Event_RagDollize, "bool" },
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
};]]