-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-05-10
-- *****************************************************************
ParticleEffect = {
	Properties = {
		soclasses_SmartObjectClass = "",
		ParticleEffect = "",
		bActive = 1,
		bPrime = 1,
		Scale = 1,
		SpeedScale = 1,
		CountScale = 1,
		bCountPerUnit = 0,
		AttachType = "",
		AttachForm = "Surface",
		PulsePeriod = 0,
	},
	States = { "Active","Idle" },
};

function ParticleEffect:OnLoad(table)
	if (not table.nParticleSlot) then
		self:Disable();
	elseif (not self.nParticleSlot or self.nParticleSlot ~= table.nParticleSlot) then
		self:Disable();
		if (table.nParticleSlot >= 0) then
			self.nParticleSlot = self:LoadParticleEffect( table.nParticleSlot, self.Properties.ParticleEffect, self.Properties );
		end
	end
end

function ParticleEffect:OnSave(table)
  table.nParticleSlot = self.nParticleSlot;
end

function ParticleEffect:OnInit()
	self.nParticleSlot=-1;
	self.spawnTimer = 0;
	self:SetRegisterInSectors(1);
	self:SetUpdatePolicy(ENTITY_UPDATE_POT_VISIBLE);
	self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0);
	self:OnReset();
	self:PreLoadParticleEffect( self.Properties.ParticleEffect );
end

function ParticleEffect:OnPropertyChange()
	self:GotoState("");
	self:OnReset();
end

function ParticleEffect:OnReset()
	if (self.Properties.bActive ~= 0) then
		self:GotoState( "Active" );
	else
		self:GotoState( "Idle" );
	end
end

function ParticleEffect:Enable()
	if (not self.nParticleSlot or self.nParticleSlot < 0) then
		self.nParticleSlot = self:LoadParticleEffect( -1, self.Properties.ParticleEffect, self.Properties );
	end
end

function ParticleEffect:Disable()
	if (self.nParticleSlot and self.nParticleSlot >= 0) then
		self:FreeSlot(self.nParticleSlot);
		self.nParticleSlot = -1;
	end
end

ParticleEffect.Active = {
	OnBeginState = function( self )
		self:Enable();
	end,
	OnEndState = function( self )
		self:Disable();
	end,
	OnLeaveArea = function( self,entity,areaId )
		self:GotoState( "Idle" );
	end,
};

ParticleEffect.Idle = {
	OnBeginState = function( self )
		self:Disable();
	end,
	OnEnterArea = function( self,entity,areaId )
		self:GotoState( "Active" );
	end,
};