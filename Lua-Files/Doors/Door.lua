-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach und Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-10-07
-- *****************************************************************
Door = {
	Properties = {
		soclasses_SmartObjectClass  = "Door",
		fileModel 					= "",	
		Rotation = {
			fSpeed 					= 200.0,
			fAcceleration 			= 500.0,
			fStopTime 				= 0.125,
			fRange 					= 90,
			sAxis 					= "z",
			bRelativeToUser 		= 1,
			sFrontAxis				= "y",
		},
		Slide = {
			fSpeed	 				= 2.0,
			fAcceleration 			= 3.0,
			fStopTime				= 0.5,
			fRange	 				= 0,
			sAxis		 			= "x",
		},
		fUseDistance				= 2.5,
		bLocked 					= 0,
		bSquashPlayers 				= 0,
		bActivatePortal 			= 0,
    },
	PhysParams = { 
		mass 						= 0,
		density						= 0,
	},
	Client = {
		ClRotate 					= function() end,
		ClSlide   					= function() end,
	},
	Server = {
		---------------------------
		--		OnInitClient		
		---------------------------
		OnInitClient = function(self, channelId)
			local open = (self.action == 1); 
			if (open) then -- epic optimization
				if (self.Properties.Rotation.fRange ~= 0) then					
					self.onClient:ClRotate(channelId, open, self.fwd or false);
				end
				if (self.Properties.Slide.fRange ~= 0) then			
					self.onClient:ClSlide(channelId, open);
				end
			end
		end,
		---------------------------
		--		SvRequestOpen		
		---------------------------
		SvRequestOpen = function(self, userId, open)
			local distance = self:GetDistance(userId);
			if (distance > 10) then --> Hax/error check
				return;
			end
			local mode = 2;
			if (open) then
				mode = 1;
			end
			self:Open(userId, mode);
		end,
		---------------------------
		--		OnEnterArea
		---------------------------	
		OnEnterArea = function(self, entity, areaId)
			--System.LogAlways(entity:GetName().." [ENTER] "..self:GetName());
			if (entity.vehicle) then
				if (self.action == 1) then
					self:Open(entity.id, 2);
					local child = self.NeighbourId and System.GetEntity(self.NeighbourId);
					if (child and child.action == 1) then
						child:Open(entity.id, 2);
						self.CloseOnLeave = true;
					end
				end	
			end
		end,
		---------------------------
		--		OnLeaveArea
		---------------------------	
		OnLeaveArea = function(self, entity, areaId)
			--System.LogAlways(entity:GetName().." [LEAVING] "..self:GetName());
			if (self.CloseOnLeave and self.action == 2) then
				self:Open(entity.id, 1);
				local child = self.NeighbourId and System.GetEntity(self.NeighbourId);
				if (child and child.action == 2) then
					child:Open(entity.id, 1);
				end
				self.CloseOnLeave = nil;
			end
		end,
		---------------------------
		--  OnStartGame		
		---------------------------
		OnStartGame = function(self)
			if (self.Properties.Rotation.fRange == 0) then
				if (not self.NeighbourId and not nCX.ProMode) then
					local pos = self:GetWorldPos();
					local doors = System.GetEntitiesInSphereByClass(pos, 20, "Door");
					if (doors) then
						local spawn;
						for i, door in pairs(doors) do
							if (door.id ~= self.id and door.Properties.Rotation.fRange == 0) then
								if (not door.NeighbourId) then
									spawn = door;
									break;
								end
							end
						end
						if (spawn) then
							local pos2 = spawn:GetWorldPos();
							local x, y, z = (pos.x + pos2.x) / 2, (pos.y + pos2.y) / 2, (pos.z + pos2.z) / 2;
							local props = {
								class="ServerTrigger",
								position={x=x, y=y, z=z},
								orientation={x=1, y=0, z=0},
								name=self:GetName().."_auto_open_trigger",
								properties={
									DimX=20,
									DimY=20,
									DimZ=10,
								},
							};
							local trigger=System.SpawnEntity(props);
							if (trigger) then
								--nCX.ParticleManager("smoke_and_fire.black_smoke.truck", 1, trigger:GetWorldPos(), g_Vectors.up, channelId);
								self.NeighbourId = spawn.id;
								trigger.GateId = self.id;
								trigger:ForwardTriggerEventsTo(self.id);
							end
						end
					end
				end
				-- Close Gates
				if (not nCX.ProMode) then
					--self:Open(nil, 1);	
				end
			end
		end,
	},
	---------------------------
	--		OnLoad		
	---------------------------
	OnLoad = function(self, table)
		self.goalAngle = table.goalAngle 
		self.currAngle = table.currAngle 
		self.modelAngle = table.modelAngle 	
		self.goalPos = table.goalPos 
		self.currPos = table.currPos 
		self.modelPos = table.modelPos 
		self.locked = table.locked 
	end,
	---------------------------
	--		OnSave		
	---------------------------
	OnSave = function(self, table)
		table.goalAngle = self.goalAngle 
		table.currAngle = self.currAngle 
		table.modelAngle = self.modelAngle 	
		table.goalPos = self.goalPos 
		table.currPos = self.currPos 
		table.modelPos = self.modelPos 
		table.locked = self.locked 
	end,
	---------------------------
	--		OnPropertyChange		
	---------------------------
	OnPropertyChange = function(self)
		self.bNeedReload = 1;
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
		local slideDoor = self.Properties.Rotation.fRange == 0;
		if (not slideDoor and not nCX.ProMode) then
			---------------------------
			--		OnHit		
			---------------------------			
			self.OnHit = function(self, hit)
				--ht_Rocket 29 : 3m  --claymore avmine 0  --ht_C4Explosive 32 -- melee 9 -- ht_GaussBullet 5 -- VehicleGaussMounted 41
				--System.LogAlways("Door Hit: Type "..hit.typeId);
				if (self.action ~= 1) then
					if (hit.shooter and hit.shooter.actor and hit.typeId == 9 and not hit.shooter.actor:GetLinkedVehicleId()) then --(hit.explosion or hit.typeId == 9 or hit.typeId == 5 or hit.typeId == 41)
						if (hit.typeId == 32) then 
							local C4 = System.GetEntity(hit.weaponId);
							if (C4 and C4:GetParent() ~= self) then  -- only C4s attached to door itself can blast it open
								return;
							end
						elseif (hit.explosion) then
							local pos = self:GetWorldPos();
							pos.z = pos.z + 1.15;
							if (math:GetWorldDistance(pos, hit.pos) > 3.0) then
								return;
							end	
						end
						local done = self:Open(hit.shooter.id, 1);
						if (done ~= 0) then
							nCX.ParticleManager("explosions.monitor.computer", 0.5, hit.pos, hit.dir, 0);
						end
					end
				end
			end
		end
		CryAction.CreateGameObjectForEntity(self.id);
		CryAction.BindGameObjectToNetwork(self.id);
		self:Reset(1);
		--[[
		if (slideDoor) then	
			if (self.action ~= 1) then
				self:Slide(false);
				self.action = 1;
			end
		end
		]]
	end,
	---------------------------
	--		DoPhysicalize		
	---------------------------
	DoPhysicalize = function(self)
		if (self.currModel ~= self.Properties.fileModel) then
			CryAction.ActivateExtensionForGameObject(self.id, "ScriptControlledPhysics", false);
			self:LoadObject( 0,self.Properties.fileModel );
			self:Physicalize(0,PE_RIGID,self.PhysParams);
			CryAction.ActivateExtensionForGameObject(self.id, "ScriptControlledPhysics", true);	
		end
		if (tonumber(self.Properties.bSquashPlayers)==0) then  
			self:SetPhysicParams(PHYSICPARAM_FLAGS, {flags_mask=pef_cannot_squash_players, flags=pef_cannot_squash_players});
		end
		self.currModel = self.Properties.fileModel;
	end,
	---------------------------
	--		ResetAction		
	---------------------------
	ResetAction = function(self)
		self.action = 2;
	end,
	---------------------------
	--		Reset		
	---------------------------
	Reset = function(self, onSpawn)
		if (self.bNeedReload and self.bNeedReload == 0) then
			return;
		end
		self.bNeedReload = 0;
		local DoorVars = {
			goalAngle   = {x=0,y=0,z=0},
			currAngle   = {x=0,y=0,z=0},
			modelAngle  = {x=0,y=0,z=0},
			goalPos     = {x=0,y=0,z=0},
			currPos     = {x=0,y=0,z=0},
			modelPos    = {x=0,y=0,z=0},
			locked      = false,
		};
	    mergef(self, DoorVars, 1);
		if (onSpawn) then
			self:ResetAction();
		end
		self:DoPhysicalize();
		if (self.action == 2) then
			self:GetWorldAngles(self.modelAngle);
			self:GetWorldPos(self.modelPos);
		end
		self:ResetAction();
		math:CopyVector(self.currAngle,self.modelAngle);  
		math:CopyVector(self.goalAngle,self.modelAngle);
		math:CopyVector(self.currPos,self.modelPos);
		math:CopyVector(self.goalPos,self.modelPos);
		self:AwakePhysics(1);
		local axis = self.Properties.Rotation.sFrontAxis:lower();
		local neg = (axis=="-x") or (axis=="-y") or (axis=="-z");
		if (axis:find("x")) then
			self.frontAxis = self:GetDirectionVector(0);
		elseif (axis:find("y")) then
			self.frontAxis = self:GetDirectionVector(1);
		else
			self.frontAxis = self:GetDirectionVector(2);
		end
		local isFactoryDoor = System.GetNearestEntityByClass(self:GetWorldPos(), 30, "Factory");
		if (isFactoryDoor) then
			local neg = (axis~="x");
			if (neg) then
				--Fix some Factory doors opening the wrong way
				self.frontAxis = self:GetDirectionVector(0);
			end
		end
	end,
	---------------------------
	--		Slide		
	---------------------------
	Slide = function(self, open)
		local slide = self.Properties.Slide;
		if (open) then
			local axis = slide.sAxis;
			local range = slide.fRange;
			local type = 2;
			if (axis == "x") then
				type = 0;
			elseif (axis == "y") then
				type = 1;
			end
			local dir = self:GetDirectionVector(type);
			self.goalPos.x=self.modelPos.x+dir.x*range;
			self.goalPos.y=self.modelPos.y+dir.y*range;
			self.goalPos.z=self.modelPos.z+dir.z*range;		
		else
			math:CopyVector(self.goalPos, self.modelPos);
		end
		self.scp:MoveTo(self.goalPos, self:GetSpeed(), slide.fSpeed, slide.fAcceleration, slide.fStopTime);
		self.bNeedReload = 1;
	end,
	---------------------------
	--		Rotate		
	---------------------------
	Rotate = function(self, open, fwd, fast)
		local rotation = self.Properties.Rotation;
		if (open) then
			local range = math.rad(rotation.fRange);		
			if (not fwd) then
				range = -range;
			end
			local axis = rotation.sAxis;
			if (axis == "X" or axis == "x") then
				self.goalAngle.x = self.modelAngle.x + range;
			elseif (axis == "Y" or axis == "y") then
				self.goalAngle.y = self.modelAngle.y + range;
			else
				self.goalAngle.z = self.modelAngle.z + range;
			end
		else
			math:CopyVector(self.goalAngle, self.modelAngle); 
		end
		self.scp:RotateToAngles(self.goalAngle, self.scp:GetAngularSpeed(), rotation.fSpeed, rotation.fAcceleration, rotation.fStopTime);
		--System.LogAlways("Rotating to "..self.goalAngle.x.." | "..self.goalAngle.y.." | "..self.goalAngle.z.." ");
		self.bNeedReload = 1;
	end,
	---------------------------
	--		Open		
	---------------------------
	Open = function(self, userId, mode)
		if (mode == 0) then
			self.action = self.action == 1 and 2 or 1
		else
			if (self.action == mode) then
				return 0;
			end
			self.action = mode;
		end
		local open = (self.action == 1);
		if (self.Properties.Rotation.fRange ~= 0) then					
			local fwd = false;
			if (open) then			
				if (userId and (tonumber(self.Properties.Rotation.bRelativeToUser) ~= 0)) then
					local user = nCX.GetPlayer(userId);
					if (user) then
						local userForward=g_Vectors.temp_v2;
						local myPos=self:GetWorldPos();
						local userPos=user:GetWorldPos();
						math:SubVectors(userForward,myPos,userPos);
						math:NormalizeVector(userForward);
						local dot = math:dotproduct3d(self.frontAxis, userForward);	
						fwd = (dot > 0);
					end
				end	
			end
			self.fwd = fwd;
			self:Rotate(open, fwd);
			self.allClients:ClRotate(open, fwd);
			
		elseif (self.Properties.Slide.fRange ~= 0) then
			self:Slide(open);
			self.allClients:ClSlide(open);
		end
		return 1;
	end,

};

Net.Expose {
	Class = Door,
	ClientMethods = {
		ClSlide = { RELIABLE_UNORDERED, NO_ATTACH, BOOL }, --POST_ATTACH
		ClRotate = { RELIABLE_UNORDERED, NO_ATTACH, BOOL, BOOL },
	},
	ServerMethods = {
		SvRequestOpen = { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, BOOL },
	},
	ServerProperties = {
	},
};

