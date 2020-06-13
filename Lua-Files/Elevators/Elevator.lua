-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2018-11-07
-- *****************************************************************

Elevator = {
	
	Properties = 
	{
		soclasses_SmartObjectClass = "Elevator",

		objModel = "",
		
		Sounds = 
		{
			soundSoundOnStart = "",
			soundSoundOnMove 	= "sounds/doors/wooddooropen.wav",
			soundSoundOnStop 	= "",
		},
		
		bAutomatic				= 0,
		nFloorCount				= 2,
		fFloorHeight			= 5,
		nInitialFloor			= 0,
		nDestinationFloor = 1,
		
		Slide = 
		{
			fSpeed 				= 1.0,
			fAcceleration = 1.0,
			sAxis 				= "z",
			fStopTime 		= 0.75
		},
	},
	Client = {
		ClSlide 		= function() end,
		ClInitMoving 	= function() end,		
	},
	Server = {
		---------------------------
		--		OnUpdate
		---------------------------	
		OnUpdate = function(self, frameTime)
			self:UpdateSlide(frameTime);
		end,
		---------------------------
		--		OnTimer
		---------------------------	
		OnTimer = function(self, timerId, msec)
			if (timerId==1) then
				if (self.automatic and (not self.resting)) then
					self:Slide(self.Properties.nInitialFloor);
				elseif (self.nextFloor and self.nextFloor~=self.currFloor) then
					self:Slide(self.nextFloor);
					self.nextFloor=nil;
				end
			else
				if (self.automatic) then
					self:Slide(self.Properties.nDestinationFloor);
				end
			end
		end,
		---------------------------
		--		OnEnterArea
		---------------------------	
		OnEnterArea = function(self, entity, areaId)
			if (entity and entity.actor) then
				self:SetTimer(0, 2000);
			end
		end,
		---------------------------
		--		OnInitClient
		---------------------------		
		OnInitClient = function(self, channelId)
			if (self.currFloor==self.goalFloor) then
				self.onClient:ClSlide(channelId, self.goalFloor, true);
			else
				self.onClient:ClInitMoving(channelId, self.currFloor, self.goalFloor, self.scp:GetSpeed(), self.scp:GetAcceleration());
			end
		end,
		---------------------------
		--		SvRequestSlide
		---------------------------	
		SvRequestSlide = function(self, userId, floor)
			self:Slide(user, floor);
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
		self.originalpos=self:GetWorldPos();
		self:Reset();
	end,
	---------------------------
	--		DoPhysicalize
	---------------------------	
	DoPhysicalize = function(self)
		if (self.currModel ~= self.Properties.objModel) then
			CryAction.ActivateExtensionForGameObject(self.id, "ScriptControlledPhysics", false);
			self:LoadObject( 0,self.Properties.objModel );
			self:Physicalize(0,PE_RIGID,{mass=0});
			CryAction.ActivateExtensionForGameObject(self.id, "ScriptControlledPhysics", true);
		end
		self.currModel = self.Properties.objModel;
	end,
	---------------------------
	--		Reset
	---------------------------	
	Reset = function(self)
		self:Activate(0);
		self:DoPhysicalize();
		
		local initial=self.Properties.nInitialFloor;

		self.floorpos={};
		self.floorpos[initial]=self.originalpos;
		
		if (self.Properties.nFloorCount>0) then
			
			for i=0,self.Properties.nFloorCount-1 do
				local pos=vecNew(self.originalpos);
				local axis=self.Properties.Slide.sAxis;
				local height=self.Properties.fFloorHeight;
				local range=(i*height-initial*height);
				local dir=g_Vectors.temp_v1;
				
				if (axis=="X" or axis=="x") then
					dir=self:GetDirectionVector(0, dir);
				elseif (axis=="Y" or axis=="y") then
					dir=self:GetDirectionVector(1, dir);
				else
					dir=self:GetDirectionVector(2, dir);
				end
				
				pos.x=pos.x+dir.x*range;
				pos.y=pos.y+dir.y*range;
				pos.z=pos.z+dir.z*range;
				self.floorpos[i]=pos;
			end
		end
		
		self.currFloor=initial;
		self.goalFloor=initial;
		self.nextFloor=nil;

		self.automatic=self.Properties.bAutomatic~=0;
		if (self.automatic) then
			local min,max=self:GetLocalBBox();
			self:SetTriggerBBox(min, max);
		end

		self:UpdateSlide(0);
		self:AwakePhysics(1);
	end,
	---------------------------
	--		UpdateSlide
	---------------------------	
	UpdateSlide = function(self, frameTime)
		if (self.currFloor==self.goalFloor) then
			return;
		end
		
		local currPos=self:GetWorldPos(g_Vectors.temp_v1);
		local goalPos=self.floorpos[self.goalFloor];

		if (vecLenSq(vecSub(goalPos, currPos))<0.001) then
			self.currFloor=self.goalFloor;
			if (self.automatic) then
				if (self.currFloor==self.Properties.nInitialFloor) then
					self.resting=true;
				end
			end
			self:SetTimer(1, 3000);
			self:Activate(0);
		else
			self.resting=false;
		end
	end,
	---------------------------
	--		OnPostStep
	---------------------------	
	OnPostStep = function(self)
	end,
	---------------------------
	--		Slide
	---------------------------	
	Slide = function(self, floor)
		if (floor>=self.Properties.nFloorCount) then
			floor=self.Properties.nFloorCount-1;
		elseif (floor<0) then
			floor=0;
		end
		
		local speed=self.scp:GetSpeed();
		if (self.currFloor==floor and speed==0) then
			return;
		elseif (self.goalFloor==floor) then
			return;
		end
		
		if (speed<=0) then
			self.goalFloor=floor;
			self.currFloor=-1;
			self:Activate(1);	
			self.allClients:ClSlide(floor, false);
			self.scp:MoveTo(self.floorpos[self.goalFloor], self:GetSpeed(), self.Properties.Slide.fSpeed, self.Properties.Slide.fAcceleration, self.Properties.Slide.fStopTime);
		else
			self.nextFloor=floor;
		end
	end,
	---------------------------
	--		Up
	---------------------------	
	Up = function(self, callFloor)
		if (self.currFloor==callFloor) then
			self:Slide(self.goalFloor+1);
		else
			self:Slide(callFloor);
		end
	end,
	---------------------------
	--		Down
	---------------------------	
	Down = function(self, callFloor)
		if (self.currFloor==callFloor) then
			self:Slide(self.goalFloor-1);
		else
			self:Slide(callFloor);
		end
	end,
};

Net.Expose {
	Class = Elevator,
	ClientMethods = {
		ClSlide = { RELIABLE_UNORDERED, NO_ATTACH, INT8, BOOL },
		ClInitMoving = { RELIABLE_UNORDERED, NO_ATTACH, VEC3, INT8, INT8, FLOAT, FLOAT },
	},
	ServerMethods = {
	},
	ServerProperties = {
	},
};