AreaTrigger = {
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