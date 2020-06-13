-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis 
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2019-05-23
-- *****************************************************************
ChatEntity = {
	Client = {},
	Properties = {
		bEnabled = 1,
		teamName = "",
	},
	Server = {
		---------------------------
		--		OnInit
		---------------------------
		OnInit = function(self)
			System.LogAlways("OnInit"..self:GetName());
			self:OnReset();
		end,
	},
			---------------------------
		--		OnInit
		---------------------------
		OnInit = function(self)
			System.LogAlways("OnInit2 "..self:GetName());
			self:OnReset();
		end,
	---------------------------
	--		OnPropertyChange
	---------------------------	
	OnPropertyChange = function(self)
		self:OnReset();
	end,
	---------------------------
	--		OnReset
	---------------------------	
	OnReset = function(self)
		nCX.SetTeam(1, self.id);
	end,
};
