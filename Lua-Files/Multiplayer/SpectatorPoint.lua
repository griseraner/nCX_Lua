-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  3.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-09-27
-- *****************************************************************
SpectatorPoint = {
	Client = {},
	Server = {
		---------------------------
		--		OnInit
		---------------------------
		OnInit = function(self)
			self:Enable(tonumber(self.Properties.bEnabled) ~= 0);	
		end,
		---------------------------
		--		OnShutDown
		---------------------------
		OnShutDown = function(self)
			nCX.RemoveSpectatorLocation(self.id);
		end,
	},	
	Properties = {
		bEnabled = 1,
	},
	---------------------------
	--		Enable
	---------------------------
	Enable = function(self, enable)
		if (enable) then
			nCX.AddSpectatorLocation(self.id);
		else
			nCX.RemoveSpectatorLocation(self.id);
		end
		self.enabled=enable;
	end,
	---------------------------
	--		IsEnabled
	---------------------------
	IsEnabled = function(self)
		return self.enabled;
	end,
};