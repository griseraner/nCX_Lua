-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-06-15
-- *****************************************************************
Item = {
	Properties = {
		nCX_OnItemPickEvent = 0; --> set to 1 and nCX_OnItemPickedUp will be called
		bPickable = 0,
		bPhysics = 0,
		bMounted = 0,
		bUsable = 0,
		HitPoints = 0,
		Health = 2000,
		soclasses_SmartObjectClass = "",
		initialSetup = "",--this nigga fapped attachment in tia/ia!
	},
	Client = {},
	Server = {},
	---------------------------
	--   AccessoriesChanged
	---------------------------
	AccessoriesChanged = function(self, attachments)
		local owner = self.item:GetOwner();
		if (owner) then
			CryMP:HandleEvent("OnAccessoriesChanged", {owner, self, attachments});
		end
	end,
	---------------------------
	--   OnPropertyChange
	---------------------------
	OnPropertyChange = function(self)
		self.item:Reset();
		if (self.OnReset) then
			self:OnReset();
		end
	end,
	---------------------------
	--   IsUsable
	---------------------------
	IsUsable = function(self, user)
		return 1;
	end,
	---------------------------
	--   OnUsed
	---------------------------
	OnUsed = function(self, user)
		return self.item:OnUsed(user.id);
	end,
	---------------------------
	--   Event_Hide
	---------------------------
	Event_Hide = function(self)
		self:Hide(1);
		self:ActivateOutput( "Hide", true );
	end,
	---------------------------
	--   Event_UnHide
	---------------------------
	Event_UnHide = function(self)
		self:Hide(0);
		self:ActivateOutput( "UnHide", true );
	end,
};

Item.FlowEvents = {
	Inputs = {
		Hide = { 
			Item.Event_Hide, 
			"bool" 
		},
		UnHide = { 
			Item.Event_UnHide, 
			"bool" 
		},
	},
	Outputs = {
		Hide = "bool",
		UnHide = "bool",
	},
};

function MakeRespawnable(entity)
	if (entity.Properties) then
		entity.Properties.Respawn = {
			nTimer = 30,
			bUnique = 0,
			bRespawn = 0,
		};
	end
end

function CreateItemTable(name)
	if (not _G[name]) then
		_G[name] = new(Item);
	end
	MakeRespawnable(_G[name]);
end

CreateItemTable("CustomAmmoPickup");
CustomAmmoPickup.Properties.objModel="";
CustomAmmoPickup.Properties.bMounted=nil;
CustomAmmoPickup.Properties.HitPoints=nil;
CustomAmmoPickup.Properties.AmmoName="bullet";
CustomAmmoPickup.Properties.Count=30;

CreateItemTable("ShiTen");

ShiTen.Properties.bMounted=1;
ShiTen.Properties.bUsable=1;
ShiTen.Properties.MountedLimits = { pitchMin = -22, pitchMax = 60, yaw = 70, };

function ShiTen:OnReset()
	self.item:SetMountedAngleLimits(self.Properties.MountedLimits.pitchMin,self.Properties.MountedLimits.pitchMax, self.Properties.MountedLimits.yaw);
end

function ShiTen:OnSpawn()
	self:OnReset();
end

function ShiTen:OnUsed(user)
	Item.OnUsed(self, user);
end

function CreateTurret(name)
	CreateItemTable(name);	
	local Turret = _G[name];
	Turret.Properties.species = 0;	
	Turret.Properties.teamName = "";
	Turret.Properties.GunTurret = {
		bSurveillance = 1,
		bVehiclesOnly = 0,
		bAirVehiclesOnly = 0,
		bEnabled = 1,
		bSearching = 0,
		bSearchOnly = 0,
		MGRange = 50,
		RocketRange = 50,
		TACDetectRange = 300,
		TurnSpeed = 1.5,
		SearchSpeed = 0.5,
		UpdateTargetTime = 2.0,
		AbandonTargetTime = 0.5,
		TACCheckTime = 0.2,
		YawRange = 360,
		MinPitch = -45,
		MaxPitch = 45,
		AimTolerance = 20,
		Prediction = 1,
		BurstTime = 0.0,
		BurstPause = 0.0,
		SweepTime = 0.0,
		LightFOV = 0.0,
		bFindCloaked = 1,
		bExplosionOnly = 0,
	};

	Turret.Server.OnInit = function(self)
		self:OnReset();
	end;
	
	Turret.OnReset = function(self)
		local teamId = nCX.GetTeamId(self.Properties.teamName) or 0;
		nCX.SetTeam(teamId, self.id);
	end;

	Turret.Properties.objModel="";
	Turret.Properties.objBarrel="";
	Turret.Properties.objBase="";
	Turret.Properties.objDestroyed="";
	Turret.Properties.bUsable=nil;
	Turret.Properties.bPickable=nil;
	Turret.Event_EnableTurret = function(self)
		self.Properties.GunTurret.bEnabled=1; 
	end;  
	Turret.Event_DisableTurret = function(self)
		self.Properties.GunTurret.bEnabled=0; 
	end;
	Turret.FlowEvents.Inputs.EnableTurret = { Turret.Event_EnableTurret, "bool" };
	Turret.FlowEvents.Inputs.DisableTurret = { Turret.Event_DisableTurret, "bool" };  
	Turret.FlowEvents.Outputs.Destroyed =  "bool";
	return Turret;
end

CreateTurret("AutoTurret").Properties.bExplosionOnly = 1;
CreateTurret("AutoTurretAA").Properties.bExplosionOnly = 1;

CreateTurret("AlienTurret");
CreateTurret("WarriorMOARTurret");

----------------------------------------------------------------------------------------------------
AlienTurret.Properties.DamageMultipliers = {
	Bullet = 1.0,
	Explosion = 1.0,
	Collision = 1.0,
	Melee = 1.0,
};

AlienTurret.Properties.GunTurret.bVulnerable=1;

function AlienTurret.Server:OnHit(hit)
	if(self.Properties.GunTurret.bVulnerable==0)then
		return;
	end;
	
	local dmg=hit.damage;
	local mul=self.Properties.DamageMultipliers;
	if(hit.type=="bullet")then dmg=dmg*mul.Bullet;end;
	if(hit.type=="collision")then dmg=dmg*mul.Collision;end;
	if(hit.type=="melee")then dmg=dmg*mul.Melee;end;
	if(hit.explosion)then
		dmg=dmg*mul.Explosion;
	end;
	
	hit.damage=dmg;
	
	local explosionOnly=tonumber(self.Properties.bExplosionOnly or 0)~=0;
  local hitpoints = self.Properties.HitPoints;
  
	if (hitpoints and (hitpoints > 0)) then
		local destroyed=self.item:IsDestroyed()
		if (hit.type=="repair") then
			self.item:OnHit(hit);
		elseif ((not explosionOnly) or (hit.explosion)) then
			if ((not g_gameRules:IsMultiplayer()) or g_gameRules.game:GetTeam(hit.shooterId)~=g_gameRules.game:GetTeam(self.id)) then
				self.item:OnHit(hit);
				if (not destroyed) then
					if (hit.damage>0) then
						if (g_gameRules.Server.OnTurretHit) then
							g_gameRules.Server.OnTurretHit(g_gameRules, self, hit);
						end
					end
				
					if (self.item:IsDestroyed()) then
						if(self.FlowEvents and self.FlowEvents.Outputs.Destroyed)then
							self:ActivateOutput("Destroyed",1);
						end
					end
				end
			end
		end
	end
end
