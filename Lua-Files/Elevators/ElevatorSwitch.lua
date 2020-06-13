-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2018-11-07
-- *****************************************************************

ElevatorSwitch = {
	Properties = {
		soclasses_SmartObjectClass = "ElevatorSwitch",

		objModel 			= "Objects/library/furnishings/doors/toiletstall_door_local.cgf",
		nFloor	 			= 0,
		fDelay	 			= 3,
		szUseMessage	="@pick_object",

		Sounds = {
			soundSoundOnPress = "sounds/doors/wooddooropen.wav",
		},
	},
	Client = {
		ClUsed 	= function() end,
	},
	Server = {
		---------------------------
		--		SvRequestUse
		---------------------------	
		SvRequestUse = function(self, userId)
			--System.LogAlways(self:GetName()..":SvRequestUse()");
			if (self.Properties.fDelay>0) then
				self:SetTimer(0, 1000*self.Properties.fDelay);
			else
				self:Used();
			end
		end,
		---------------------------
		--		OnTimer
		---------------------------	
		OnTimer = function(self, timerId, msec)
			self:Used();
		end,
	},
	---------------------------
	--		OnPropertyChange
	---------------------------	
	OnPropertyChange = function(self)
		self:Reset();
	end,
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		self:Reset();
	end,
	---------------------------
	--		OnSpawn
	---------------------------
	OnSpawn = function(self)
		--System.LogAlways("OnSpawn -> $4"..self:GetName());
		CryAction.CreateGameObjectForEntity(self.id);
		CryAction.BindGameObjectToNetwork(self.id);
		CryAction.ForceGameObjectUpdate(self.id, true);

		self.user = 0;
		self.tmp = {x=0,y=0,z=0};
		self.tmp_2 = {x=0,y=0,z=0};
		self.tmp_3 = {x=0,y=0,z=0};
		self.initialdir=self:GetDirectionVector(1);

		self:Reset(1);
	end,
	---------------------------
	--		DoPhysicalize
	---------------------------
	DoPhysicalize = function(self)
		if (self.currModel ~= self.Properties.objModel) then
			self:LoadObject( 0,self.Properties.objModel );
			self:Physicalize(0,PE_RIGID, {mass=0});
		end
		self.currModel = self.Properties.objModel;
	end,
	---------------------------
	--		Reset
	---------------------------
	Reset = function(self, onSpawn)
		self:Activate(0);
		self:DoPhysicalize();
		self.enabled = tonumber(self.Properties.bEnabled) ~= 0
	end,
	---------------------------
	--		IsUsable
	---------------------------
	IsUsable = function(self, user)
		self:GetPos(self.tmp_2)
		user:GetPos(self.tmp_3)
		math:SubVectors(self.tmp,self.tmp_2,self.tmp_3);
		local dist=math:LengthVector(self.tmp);
		if ((not user) or (not self.enabled) or (dist>self.Properties.fUseDistance)) then
			return 0;
		end
		return 1;
	end,
	---------------------------
	--		OnUsed
	---------------------------
	OnUsed = function(self, user)
		--System.LogAlways(self:GetName()..":OnUsed()");
		self.server:SvRequestUse(user.id);
	end,
	---------------------------
	--		GetUsableMessage
	---------------------------
	GetUsableMessage = function(self)
		return self.Properties.UseMessage;
	end,
	---------------------------
	--		Used
	---------------------------
	-- In Sandbox, name the entity link "up" if you want the switch to send the elevator up or name the link "down" if you want to send the elevator down.
	Used = function(self)
		--System.LogAlways(self:GetName()..":Used()");
		local i=0;
		local link=self:GetLinkTarget("up", i);
		if (link) then
			--System.LogAlways("Link found: "..link:GetName());
		else
			--System.LogAlways("No link found for: "..self:GetName());
		end
		while (link) do
			link:Up(self.Properties.nFloor);
			i=i+1;
			link=self:GetLinkTarget("up", i);
		end

		i=0;
		link=self:GetLinkTarget("down", i);
		if (link) then
			--System.LogAlways("2 Link found: "..link:GetName());
		else
			--System.LogAlways("2 No link found for: "..self:GetName());
		end
		while (link) do
			link:Down(self.Properties.nFloor);
			i=i+1;
			link=self:GetLinkTarget("down", i);
		end

		self:ActivateOutput("Used", true);

		self.allClients:ClUsed();
	end,
	---------------------------
	--		Event_Enable
	---------------------------
	Event_Enable = function(self)
		self.enabled = true;
		self:ActivateOutput("Enabled", true);
	end,
	---------------------------
	--		Event_Disable
	---------------------------
	Event_Disable = function(self)
		self.enabled = false;
		self:ActivateOutput("Disabled", true);
	end,
	---------------------------
	--		Event_Use
	---------------------------
	Event_Use = function(self)
		self:Used()
	end,
};

ElevatorSwitch.FlowEvents = {
	Inputs =
	{
		Enable = { ElevatorSwitch.Event_Enable, "any" },
		Disable = { ElevatorSwitch.Event_Disable, "any" },
		Use = { ElevatorSwitch.Event_Use, "any" },
	},

	Outputs = {
		Enabled = "bool",
		Disabled = "bool",
		Used = "bool",
	},
};

Net.Expose {
	Class = ElevatorSwitch,
	ClientMethods = {
		ClUsed = { RELIABLE_UNORDERED, NO_ATTACH, },
	},
	ServerMethods = {
		SvRequestUse = { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, },
	},
	ServerProperties = {
	},
};