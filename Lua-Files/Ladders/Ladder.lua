-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach 
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2014-06-01
-- *****************************************************************

Ladder = {
	
	Properties = {
		soclasses_SmartObjectClass = "Ladder",
		fileModel = "objects/Prototype/Measurement/ladder.cgf",
		fUseDistance = 2,
		sDirectionAxis = "x",
    },
  	
  	PhysParams = { 
  		mass = 0,
  		density = 0,
  	},
  	
  	bottom_pos = {x=0,y=0,z=0},
  	top_pos = {x=0,y=0,z=0},
  	  	
    Server = {},
	Client = {},

	OnLoad = function(self, table)
	end,

	OnSave = function(self, table)
	end,

	OnPropertyChange = function(self)
		self:Reset();
	end,

	OnReset = function(self)
		self:Reset();
	end,

	OnSpawn = function(self)	
		System.LogAlways("OnSpawn: "..self:GetName());
		self:Reset(1);
	end,

	OnDestroy = function(self)
	end,

	DoPhysicalize = function(self)
		if (self.currModel ~= self.Properties.fileModel) then
			self:LoadObject( 0,self.Properties.fileModel );
			self:Physicalize(0,PE_RIGID,self.PhysParams);
			local bbmin,bbmax = self:GetLocalBBox();
			bbmax.z = bbmax.z + 1.5;
			self:SetLocalBBox(bbmin,bbmax);
		end
		self.currModel = self.Properties.fileModel;
	end,

	Reset = function(self, onSpawn)
		--self:Activate(1);
		self:DoPhysicalize();		
		self:AwakePhysics(1);
	end,

};









