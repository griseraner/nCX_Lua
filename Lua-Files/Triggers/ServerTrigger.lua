-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy & ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-11-04
-- *****************************************************************
ServerTrigger = {
	type = "Trigger",
	Properties = {
		DimX = 5,
		DimY = 5,
		DimZ = 5,
	},
	
	trigger = true,
	---------------------------
	--    OnPropertyChange
	---------------------------	
	OnPropertyChange = function(self)
		self:OnReset();
	end,
	---------------------------
	--       OnInit
	---------------------------	
	OnInit = function(self)
		self:OnReset();
	end,
	---------------------------
	--      OnReset
	---------------------------	
	OnReset = function(self)
		local Min = { x=-self.Properties.DimX/2, y=-self.Properties.DimY/2, z=-self.Properties.DimZ/2 };
		local Max = { x=self.Properties.DimX/2, y=self.Properties.DimY/2, z=self.Properties.DimZ/2 };
		self:SetTriggerBBox(Min, Max);
	end,
	---------------------------
	--      OnEnterArea
	---------------------------	
	OnEnterArea = function(self, entity, areaId)
	end,
	---------------------------
	--      OnLeaveArea
	---------------------------	
	OnLeaveArea = function(self, entity, areaId)
	end,
};

