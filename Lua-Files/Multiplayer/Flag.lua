-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy und ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-09-30
-- *****************************************************************
Flag = {	
	Properties = {
		objModel 			= "objects/library/props/flags/mp_flags.cga",
		teamName			= "";
		animationTemplate	= "flags_%s_%s";
	},
	---------------------------
	--      LoadGeometry
	---------------------------
	LoadGeometry = function(self, slot, model)
		if (#model > 0) then
			local ext = model:sub(-4):lower();
			if ((ext == ".chr") or (ext == ".cdf") or (ext == ".cga")) then
				self:LoadCharacter(slot, model);
			else
				self:LoadObject(slot, model);
			end
		end
	end,
	---------------------------
	--        OnSpawn
	---------------------------
	OnSpawn = function(self)
		CryAction.CreateGameObjectForEntity(self.id);
		CryAction.BindGameObjectToNetwork(self.id);
		self:LoadGeometry(0, self.Properties.objModel);
		self:Physicalize(0, PE_RIGID, { mass = 0 });
		--self:RedirectAnimationToLayer0(0, true);
	end,
	---------------------------
	--        OnReset
	---------------------------
	OnReset = function(self)
		CryAction.DontSyncPhysics(self.id);
	end,
	---------------------------
	--        OnInit
	---------------------------
	OnInit = function(self)
		self:OnReset()
	end,
	---------------------------
	--    OnPropertyChange
	---------------------------
	OnPropertyChange = function(self)
		self:OnReset();
	end
};