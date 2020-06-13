-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2014-04-19
-- *****************************************************************

local CHECK_TIMER = 0;
local FX_TIMER = 1;

Hazard = {

	type = "Trigger",
	Properties = {
		bEnabled = 1,
		Damage = {
			fDamage = 50.0,
			eiHazardType = 0,
			bOnlyPlayer = 1,
			SuitMultipliers = {
				fArmorMode = 1,
				fStrengthMode = 1,
				fSpeedMode = 1,
				fCloakMode = 1,
			},
		},
	},
	States = {"Activated","Deactivated","Turning"},
	Client = {
		AddScreenEffect      	 = function() end,
		RemoveScreenEffect   	 = function() end,
		DoFX				 	 = function() end,
		InitFX 		  		     = function() end,
	},
	Server = {

		Activated = {
			---------------------------
			--		OnBeginState
			---------------------------
			OnBeginState = function(self)
				if (table.getn(self.ents) > 0) then
					self:SetTimer(CHECK_TIMER,1000);
					for i,v in pairs(self.ents) do
						if (v.actor)then
							self.onClient:AddScreenEffect(v.Info.Channel,v.id);
						end
					end
				end
			end,
			---------------------------
			--		OnEnterArea
			---------------------------
			OnEnterArea = function(self,entity,areaId)
				self:ActivateOutput("Enter",true);
				self.ents[#self.ents + 1] = entity;
				self:SetTimer(CHECK_TIMER,1000);
				-- give initial damage
				self:HandleEntity(entity);
				if (entity.actor) then
					self.onClient:AddScreenEffect(entity.Info.Channel, entity.id);
				end
			end,
			---------------------------
			--		OnLeaveArea
			---------------------------
			OnLeaveArea = function(self,entity,areaId)
				for i,v in pairs(self.ents) do
					if (v==entity)then
						self:ActivateOutput("Leave",true);
						table.remove(self.ents,i);
						if (v.actor)then
							self.onClient:RemoveScreenEffect(v.Info.Channel, v.id);
						end
						break;
					end
				end
			end,
			---------------------------
			--		OnTimer
			---------------------------
			OnTimer = function(self,timerId,msec)
				if (timerId==CHECK_TIMER) then
					if(self.ents and #self.ents > 0 )then
						self:HandleEntities();
						self:SetTimer(CHECK_TIMER,1000);
					end
				end
			end,
		},

		Deactivated = {
			---------------------------
			--		OnBeginState
			---------------------------
			OnBeginState = function(self)
				for i, v in pairs(self.ents) do
					if (v.actor) then
						self.onClient:RemoveScreenEffect(v.Info.Channel, v.id);
					end;
				end;
			end,
			---------------------------
			--		OnEnterArea
			---------------------------
			OnEnterArea = function(self,entity,areaId)
				self.ents[#self.ents + 1] = entity;
			end,
			---------------------------
			--		OnLeaveArea
			---------------------------
			OnLeaveArea = function(self,entity,areaId)
				for i,v in pairs(self.ents) do
					if (v == entity) then
						table.remove(self.ents,i);
						self:RemoveScreenEffect(v);
						break;
					end
				end
			end,
		},
		---------------------------
		--		OnInit
		---------------------------
		OnInit = function(self)
			self.ents={};
			self:OnReset();
		end,
	},
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		local props=self.Properties;
		self:InitFX();
		if (props.bEnabled==1)then
			self:GotoState("Activated");
		else
			self:GotoState("Deactivated");
		end
	end,
	---------------------------
	--		OnSave
	---------------------------
	OnSave = function(self, tbl)
		tbl.ents=self.ents;
		tbl.fx=self.fx;
	end,
	---------------------------
	--		OnLoad
	---------------------------
	OnLoad = function(self, tbl)
		self.ents=tbl.ents;
		self.fx=tbl.fx;
	end,
	---------------------------
	--		OnPropertyChange
	---------------------------
	OnPropertyChange = function(self)
		self:OnReset();
	end,
	---------------------------
	--		InitFX
	---------------------------
	InitFX = function(self)
		self.fx={
			none,
			fire={
				active=0,
				desired=0,
				current=0,
			},
			frost={
				active=0,
				desired=0,
				current=0,
			},
			electricity={
				active=0,
				desired=0,
				current=0,
			},
		};
		local tmp=self.Properties.Damage.eiHazardType;
		self.dmg="";
		if (tmp==0) then
			self.dmg="none";
		elseif (tmp==1) then
			self.dmg="fire";
		elseif (tmp==2) then
			self.dmg="frost";
		elseif (tmp==3) then
			self.dmg="electricity";
		else
			return;
		end
	end,
	---------------------------
	--		HandleEntity
	---------------------------
	HandleEntity = function(self, ent)
		local props = self.Properties.Damage;
		local tmp = {x=0,y=0,z=0};
		local dist;
		if (ent and ent.actor)then
			local dmg=self.Properties.Damage.fDamage;
			local nanoSuitMode=ent.actor:GetNanoSuitMode();
			if (nanoSuitMode==0) then --Speed
				dmg=dmg*props.SuitMultipliers.fSpeedMode;
			elseif (nanoSuitMode==1) then --Strength
				dmg=dmg*props.SuitMultipliers.fStrengthMode;
			elseif (nanoSuitMode==2) then --Cloak
				dmg=dmg*props.SuitMultipliers.fCloakMode;
			elseif (nanoSuitMode==3) then
				dmg=dmg*props.SuitMultipliers.fArmorMode;
			end
			if (dmg > 0)then
				nCX.ServerHit(ent.id,ent.id,dmg,"fire");
			end
		end
	end,
	---------------------------
	--		HandleEntities
	---------------------------
	HandleEntities = function(self)
		for i,v in pairs(self.ents) do
			self:HandleEntity(v);
		end
	end,
	---------------------------
	--		AddScreenEffect
	---------------------------
	AddScreenEffect = function(self, ent)
		local dmg=self.Properties.Damage.eiHazardType;
		if (dmg==1) then
			if(self.fx.fire.active~=1)then
				self.fx.fire.active=1;
				self.fx.fire.desired=1;
				self.fx.fire.current=0;
				--System.SetScreenFx("FilterBlurring_Type", 0);
				--System.SetScreenFx("FilterBlurring_Amount", 0);
				self:SetTimer(FX_TIMER,25);
			end
		elseif (dmg==2) then
			if(self.fx.frost.active~=1)then
				self.fx.frost.active=1;
				self.fx.frost.desired=1;
				self.fx.frost.current=0;
				--System.SetScreenFx("ScreenFrost_Active", 1);
				--System.SetScreenFx("ScreenFrost_CenterAmount", 1);
				--System.SetScreenFx("ScreenFrost_Amount", 0);
				self:SetTimer(FX_TIMER,25);
			end
		elseif (dmg==3) then
			if(self.fx.electricity.active~=1)then
				self.fx.electricity.active=1;
				self.fx.electricity.desired=2;
				self.fx.electricity.current=0;
				--System.SetScreenFx("AlienInterference_Active", 1);
				--System.SetScreenFx("AlienInterference_Amount", 1);
				self:SetTimer(FX_TIMER,25);
			end
		end
	end,
	---------------------------
	--		RemoveScreenEffect
	---------------------------
	RemoveScreenEffect = function(self, ent)
		local dmg=self.dmg;
		if (self.fx[dmg])then
			if (self.fx[dmg].active==1)then
				self.fx[dmg].active=0;
				self.fx[dmg].desired=0;
				self:SetTimer(FX_TIMER,25);
			end
		end
	end,
	---------------------------
	--		DoFX
	---------------------------
	DoFX = function(self)
		local dmg=self.dmg;
		if (dmg~="none") then
			if(self.fx[dmg].current<0.01 and self.fx[dmg].desired==0)then
				self.fx[dmg].current=0;
				--[[
				if(dmg=="frost")then
					System.SetScreenFx("ScreenFrost_Amount",self.fx[dmg].current);
					System.SetScreenFx("ScreenFrost_Active", 0);
				elseif(dmg=="fire")then
					System.SetScreenFx("FilterBlurring_Amount",0);
				elseif(dmg=="fire")then
					System.SetScreenFx("AlienInterference_Amount",0);
					System.SetScreenFx("AlienInterference_Active",0);
				end;
				]]
			elseif (self.fx[dmg].current<self.fx[dmg].desired)then
				if(dmg=="frost")then
					self.fx[dmg].current=self.fx[dmg].current+0.01;
					--System.SetScreenFx("ScreenFrost_Amount",self.fx[dmg].current);
				elseif(dmg=="fire")then
					self.fx[dmg].current=self.fx[dmg].current+0.01;
					--System.SetScreenFx("FilterBlurring_Amount",self.fx[dmg].current);
				elseif(dmg=="electricity")then
					self.fx[dmg].current=self.fx[dmg].current+0.1;
					--System.SetScreenFx("AlienInterference_Amount",self.fx[dmg].current);
				end;
				--self:SetTimer(FX_TIMER,25);
			elseif(self.fx[dmg].current>self.fx[dmg].desired)then
				if(dmg=="frost")then
					self.fx[dmg].current=self.fx[dmg].current-0.01;
					--System.SetScreenFx("ScreenFrost_Amount",self.fx[dmg].current);
				elseif(dmg=="fire")then
					self.fx[dmg].current=self.fx[dmg].current-0.03;
					--System.SetScreenFx("FilterBlurring_Amount",self.fx[dmg].current);
				elseif(dmg=="electricity")then
					self.fx[dmg].current=self.fx[dmg].current-0.1;
					--System.SetScreenFx("AlienInterference_Amount",self.fx[dmg].current);
				end;
				self:SetTimer(FX_TIMER,25);
			end
		end
	end,
	---------------------------
	--		Event_Activated
	---------------------------
	Event_Activated = function(self)
		self:GotoState("Activated");
		self:ActivateOutput("Activated",true);
	end,
	---------------------------
	--		Event_Deactivated
	---------------------------
	Event_Deactivated = function(self)
		self:GotoState("Deactivated");
		self:ActivateOutput("Deactivated",true);
	end,

};

Hazard.FlowEvents = {
	Inputs = {
		Activated = { Hazard.Event_Activated, "bool" },
		Deactivated = { Hazard.Event_Deactivated, "bool" },
	},
	Outputs = {
		Activated = "bool",
		Deactivated = "bool",
		Enter = "bool",
		Leave = "bool",
	},
};

Net.Expose {
	Class = Hazard,
	ClientMethods = {
		AddScreenEffect 	= {RELIABLE_UNORDERED, NO_ATTACH, ENTITYID },
		RemoveScreenEffect	= {RELIABLE_UNORDERED, NO_ATTACH, ENTITYID },
		DoFX				= {RELIABLE_UNORDERED, NO_ATTACH, },
		InitFX 				= {RELIABLE_UNORDERED, NO_ATTACH, },
	},

	ServerMethods = {
	},
	ServerProperties = {
	}
};


