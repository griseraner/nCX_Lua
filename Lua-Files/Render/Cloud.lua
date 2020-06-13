-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-05-10
-- *****************************************************************
Cloud = {
	type = "Cloud",
	ENTITY_DETAIL_ID = 1,
	Properties = {
		file_CloudFile = "Libs/Clouds/Default.xml",
		fScale = 1,
		Movement = {
			bAutoMove = 0,
			vector_Speed = {x=0,y=0,z=0},
			vector_SpaceLoopBox = {x=2000,y=2000,z=2000},
			fFadeDistance = 0,
		};
	},
	---------------------------
	--		OnSpawn
	---------------------------
	OnSpawn = function(self)
		self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0);
	end,
	---------------------------
	--		OnInit
	---------------------------
	OnInit = function(self)
		self:NetPresent(0);
		self:CreateCloud();
	end,
	---------------------------
	--	SetMovementProperties
	---------------------------
	SetMovementProperties = function(self)
		local moveparams = self.Properties.Movement;
		self:SetCloudMovementProperties(0, moveparams);
	end,
	---------------------------
	--		CreateCloud
	---------------------------
	CreateCloud = function(self)
		local props = self.Properties;	
		self:LoadCloud(0, props.file_CloudFile);
		self:SetMovementProperties();
	end,
	---------------------------
	--		DeleteCloud
	---------------------------
	DeleteCloud = function(self)
		self:FreeSlot(0);
	end,
	---------------------------
	--		OnPropertyChange
	---------------------------
	OnPropertyChange = function(self)
		local props = self.Properties;
		if (props.file_CloudFile ~= self._CloudFile) then
			self._CloudFile = props.file_CloudFile;
			self:CreateCloud();
		else
			self:SetMovementProperties();
		end
	end,
	---------------------------
	--		DeleteCloud
	---------------------------
	DeleteCloud = function(self)
		self:FreeSlot( 0 );
	end,
	---------------------------
	--		OnSave
	---------------------------
	OnSave = function(self, tbl)
	end,
	---------------------------
	--		OnLoad
	---------------------------
	OnLoad = function(self, tbl)
		local bCurrentlyHasCloud = self:IsSlotValid(0);
		local bWantCloud = tbl.bHasCloud;
		if (bWantCloud and not bCurrentlyHasCloud) then
			self:CreateCloud();
		elseif (not bWantCloud and bCurrentlyHasCloud) then
			self:DeleteCloud();	
		end
	end,
};