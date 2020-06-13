-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach und NiggaZerstörer
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2013-02-06
-- *****************************************************************
Factory = {
	Client = {
		ClInit 				= function() end,
		ClStartCapture 		= function() end,
		ClCancelCapture 	= function() end,
		ClStepCapture 		= function() end,
		ClCapture 			= function() end,
		ClStartUncapture 	= function() end,
		ClCancelUncapture 	= function() end,
		ClStepUncapture 	= function() end,
		ClUncapture 		= function() end,
		ClContested 		= function() end,
		ClOpenSlot 			= function() end,
		ClVehicleBuildStart = function() end,
		ClVehicleQueued 	= function() end,
		ClVehicleCancel 	= function() end,
		ClVehicleBuilt 		= function() end,
		ClSetBuyFlags 		= function() end,
	},
	Properties = {
		objModel 			= "objects/default.cgf",
		teamName 			= "",
		captureAreaId		= 0,
		nQueueSize			= 5,
		Vehicles			= "us4wd,nk4wd,nktruck,ustank,ustactank,usgausstank,usapc,nktank,nktactank,nkgausstank,nkboat",
		RestrictedWeapons	= "",
		bGeneratePower		= 0,
		nPowerIndex			= 1,
		nCaptureIndex		= 3,
		basePowerLevel		= 0,
		serviceAreaId		= 0,
		szName				= "",
		bPowerStorage		= 0,
		captureTime			= 30,
		captureRequirement	= 2,
	},
	Server = {
		---------------------------
		--		OnUpdate
		---------------------------	
		OnUpdate = function(self)
		end,
		---------------------------
		--		OnInit
		---------------------------		
		OnInit = function(self)
			self.inside = {
				[1] = {},
				[2] = {},
			};
			local teamId = nCX.GetTeamId(self.Properties.teamName);
			if (teamId and teamId ~= 0) then
				nCX.SetTeam(teamId, self.id);
				self.captured = true;
			else
				nCX.SetTeam(0, self.id);
				self.captured = false;
			end
			self:OnReset();	
			self.default = (#self.Properties.teamName > 0);
		end,
		---------------------------
		--	OnPostInitClient
		---------------------------
		OnPostInitClient = function(self, channelId)
			for i = 1, self.slotCount do	
				local slot = self.slots[i];
				if (slot and not slot.open) then
					self.onClient:ClOpenSlot(channelId, slot.id, slot.open, true);
				end
			end
			if (self.captured) then
				self.onClient:ClInit(channelId, self.captured, nCX.GetTeam(self.id));
			end
		end,
		---------------------------
		--		OnEnterArea
		---------------------------
		OnEnterArea = function(self, entity, areaId)
			if (areaId == self.Properties.serviceAreaId) then
				if (g_gameRules.OnEnterServiceZone) then
					g_gameRules.OnEnterServiceZone(g_gameRules, self, entity);
				end
			end
			local active = nCX.IsPlayerActivelyPlaying(entity.id);
			if (active) then
				local id = areaId and tonumber(areaId);
				if (id) then
					self:GatePunish(entity.id, id, true);
				end
			end
			local force = (areaId == false);
			if (not self.default and entity.Info) then
				if (force or (active and areaId == self.Properties.captureAreaId and self:CanEnter(entity.id))) then
					local entityId = entity.id;
					local teamId = nCX.GetTeam(entityId);
					local inside = self.inside[teamId];
					if (inside) then
						local channelId = entity.Info.Channel;
						local otherId = teamId == 1 and 2 or 1;
						inside[channelId] = (nCX.Count(inside) > 0) and 0 or 1;
						if (channelId > 0) then
							g_gameRules.onClient:ClEnterCaptureArea(channelId, self.id, true);
						end
						self:CheckChannels(self.inside[otherId]);	
						if (nCX.Count(self.inside[otherId]) > 0) then
							if (not self.contested) then
								self.allClients:ClContested(true);
								self.contested = teamId;
							end
							inside[channelId] = 2; -- no buymenu if capture contested
						elseif (not nCX.IsSameTeam(entityId, self.id) and not self.data) then
							self.data = {self.Properties.captureTime, teamId};
							if (self.captured) then
								self.allClients:ClStartUncapture(teamId);
							else
								self.allClients:ClStartCapture(teamId);
							end	
						end
					end
				end
			end	
		end,
		---------------------------
		--		OnLeaveArea
		---------------------------
		OnLeaveArea = function(self, entity, areaId)
			local id = areaId and tonumber(areaId);
			if (id) then
				self:GatePunish(entity.id, id, false);
			end
			if (areaId == self.Properties.serviceAreaId) then
				if (g_gameRules.OnLeaveServiceZone) then
					g_gameRules.OnLeaveServiceZone(g_gameRules, self, entity);
				end
			end
			local force = (areaId == false);
			if (not self.default and entity.Info) then
				if (force or (areaId == self.Properties.captureAreaId and self:CanEnter(entity.id))) then
					local entityId = entity.id;
					local teamId = nCX.GetTeam(entityId);
					local channelId = entity.Info.Channel;			
					local inside = self.inside[teamId];
					if (teamId == 0) then 	 -- handle leaving spectators
						if (self.inside[2][channelId]) then
							inside = self.inside[2];
						end
						inside = inside or self.inside[1];
					end
					if (inside and inside[channelId]) then
						inside[channelId] = nil;
						local otherId = teamId == 1 and 2 or 1;			
						if (channelId > 0) then
							g_gameRules.onClient:ClEnterCaptureArea(channelId, self.id, false);
						end
						if (nCX.Count(inside) == 0) then  
							if (self.contested) then
								self.allClients:ClContested(false);
								self.contested = nil;
								if (self.captured ~= otherId) then 
									self.data = self.data or {self.Properties.captureTime, otherId};
									if (self.data[2] ~= otherId) then
										self.data = {self.Properties.captureTime, otherId};
									end						
									if (self.captured) then
										self.allClients:ClStartUncapture(otherId);
									else
										self.allClients:ClStartCapture(otherId);
									end	
									if (self.captured) then
										self.allClients:ClStartUncapture(otherId);
										self.allClients:ClStepUncapture(otherId, self.data[1]);	 -- update hud immediately, next ontick call might be up to 1 sec later
									else
										self.allClients:ClStartCapture(otherId);
										self.allClients:ClStepCapture(otherId, self.data[1]);
									end	
								else
									if (self.data) then 
										self.allClients:ClCancelUncapture();
										self.data = nil;	
									end
									--[[
									local tbl = {};
									for channelId, v in pairs(self.inside[otherId]) do
										if (v == 2) then
											tbl[channelId] = true;
										end
									end
									if (nCX.Count(tbl) > 0) then
										CryMP:HandleEvent("OnCapture", {self, otherId, tbl}); -- enemy cleared, send buy menu to players who entered while contested
									end]]
								end
							elseif (nCX.Count(self.inside[otherId]) == 0) then
								if (self.captured) then
									self.allClients:ClCancelUncapture();
								else
									self.allClients:ClCancelCapture();
								end
								self.data = nil;
							end
						end
					end
				end
			end	
		end,
		---------------------------
		--  OnStartGame		-- added 2013-03-11
		---------------------------
		OnStartGame = function(self)
			nCX.UpdateObjectTimer(self.id, true);
		end,
	},
	---------------------------
	--		CanEnter
	---------------------------
	CanEnter = function(self, entityId)
		local distance = self:GetDistance(entityId);
		return not (self.Properties.buyOptions and self.Properties.buyOptions.bPrototypes == 1 and distance < 7.0 and distance > 5.0)
	end,
	---------------------------
	--		GatePunish
	---------------------------	
	GatePunish = function(self, entityId, areaId, enter)
		local slot = self.slots[areaId - 10];
		if (slot and areaId == slot.vehicleAreaId) then
			if (enter) then	
				local build = slot.build;
				if (build and not nCX.IsSameTeam(self.id, entityId)) then
					local gate = slot.gate;
					if (gate and gate[1] > 0 and not gate[2]) then
						slot.players[entityId] = true;
						nCX.ForbiddenAreaWarning(true, gate[1], entityId);
					else
						nCX.ProcessEMPEffect(entityId, 0.3);
						nCX.ServerHit(entityId,build.ownerId,1000,"punish");
					end
				else
					slot.players[entityId] = true;
				end
			elseif (slot.players[entityId]) then
				nCX.ForbiddenAreaWarning(false, 0, entityId);
				slot.players[entityId] = nil;
			end
		end
	end,
	---------------------------
	--		SetBusy
	---------------------------
	SetBusy = function(self, busy)
		self.synched.busy = busy;
	end,
	---------------------------
	--		OnSpawn
	---------------------------
	OnSpawn = function(self)
		self:Activate(1);
		local model = self.Properties.objModel;
		if (#model > 0) then
			local ext = model:sub(-4):lower();
			if ((ext == ".chr") or (ext == ".cdf") or (ext == ".cga")) then
				self:LoadCharacter(0, model);
			else
				self:LoadObject(0, model);
			end
			if (ext == ".chr") then
				self:Physicalize(0, PE_STATIC, {mass=0});
			else
				self:Physicalize(0, PE_ARTICULATED, {mass=0});
			end
			self:AwakePhysics(0);
		end
		self.queueCount = tonumber(self.Properties.nQueueSize);	
		local mn = {x=0,y=0,z=0};
		local mx = {x=0,y=0,z=0};
		self:GetLocalBBox(mn, mx);
		local _abs, _min, _max = math.abs, math.min, math.max;
		local maxx=_max(_abs(mn.x), _abs(mx.x));
		local maxy=_max(_abs(mn.y), _abs(mx.y));
		local maxz=_max(_abs(mn.z), _abs(mx.z));
		self.radius = 2*_max(maxz, _max(maxx, maxy));
		CryAction.CreateGameObjectForEntity(self.id);
		CryAction.BindGameObjectToNetwork(self.id);
		local tmp = {};
		for i = 1, 6, 1 do
			local slot = self.Properties["Slot"..i];
			if (slot) then
				tmp[slot.VehicleAreaId] = true;
			end
		end	
		self.slotCount = nCX.Count(tmp);
		if (tmp[21]) then
			self.slotCount = self.slotCount - 1;
		end
		self.queueUpdateTimer = 2.5;
		self.airFactory = self.Properties.szName == "air";
	end,
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		CryAction.ForceGameObjectUpdate(self.id, true);
		CryAction.DontSyncPhysics(self.id);  
		self:ResetAnimation(0, 0);
		for i = 1,self.slotCount do
			self:ResetAnimation(0, i);
		end
		self:RedirectAnimationToLayer0(0, true);
		self.slots = {};
		for i = 1, self.slotCount do
			local slotProperties = self.Properties["Slot"..i];
			local slot = {};
			slot.id = i;
			self:ResetSlot(slot);
			slot.props = slotProperties;
			self.slots[i] = slot;
			self:OpenSlot(slot, true, true);
		end
		self.vehicles = {};
		for def in self.Properties.Vehicles:gfind("([%w_%-]+:*%d*)") do
			local _,_,v=def:find("([%w_%-]+):*(%d*)");
			if (v) then
				self.vehicles[v]=true;
			end
		end
		self.restricted={};
		for def in self.Properties.RestrictedWeapons:gfind("([%w_%-]+:*%d*)") do
			local _,_,v=def:find("([%w_%-]+):*(%d*)");
			if (v) then
				self.restricted[v]=true;
			end
		end
		self.queue = {};
		self.queueTimer = self.queueUpdateTimer;
		self.building = 0;
		self:SetBusy(false);
	end,
	---------------------------
	--		ResetSlot
	---------------------------
	ResetSlot = function(self, slot)
		slot.enabled = false;
		slot.areaId = -1;
		slot.vehicleAreaId = -1;
		slot.build = nil;
		slot.open = false;
		slot.gate = nil;
		slot.players = {};
		local props = self.Properties["Slot"..slot.id];
		if (tonumber(props.bEnabled) ~= 0) then
			slot.enabled = true;
			slot.areaId = props.AreaId;
			slot.vehicleAreaId = props.VehicleAreaId;
		end
	end,
	---------------------------
	--	OnPropertyChange
	---------------------------
	OnPropertyChange = function(self)
		self:OnReset();
	end,
	---------------------------
	--		CanBuild
	---------------------------
	CanBuild = function(self, vehicle)
		return self.vehicles[vehicle] or false;
	end,
	---------------------------
	--		OpenSlot
	---------------------------
	OpenSlot = function(self, slot, open, instant)
		local speed = (instant and 100.0) or 1.25;
		local animation = open and slot.props.OpenAnimation or slot.props.CloseAnimation;
		if (animation and #animation > 0) then
			if (open and (not slot.open or instant)) or (not open and (slot.open or instant)) then
				self:StartAnimation(0, animation, slot.id, 0, speed, false, false, true); --skip this and the vehicle wont be lifted
				self:ForceCharacterUpdate(0, true); --skip this and the vehicle will spawn at the position it would've been brought by the airpad
			end
		end
		slot.open = open;
	end,
	---------------------------
	--		StartBuilding
	---------------------------
	StartBuilding = function(self, slot, time, class, ownerId, teamId)
		self.allClients:ClVehicleBuildStart(self:GetVehicleName(class), ownerId, teamId, slot.id, time);
		slot.build = {
			timer = time,
			class = class,
			ownerId = ownerId,
			teamId = teamId,
		};
		self.building = self.building + 1;
		if (self.building == 1) then
			self:SetBusy(true);
		end
		slot.gate = {2.0, false,};
		for entityId, v in pairs(slot.players or {}) do
			if (not nCX.IsSameTeam(self.id, entityId)) then
				nCX.ForbiddenAreaWarning(true, slot.gate[1], entityId);
			end
		end
	end,
	---------------------------
	--		StopBuilding
	---------------------------
	StopBuilding = function(self, slot)
		if (slot.gate) then
			for entityId, v in pairs(slot.players or {}) do
				if (not nCX.IsSameTeam(self.id, entityId)) then
					nCX.ForbiddenAreaWarning(false, 0, entityId);
				end
			end
		end
		slot.build = nil;
		self:UpdateQueue();
		self.building = self.building - 1;
		if (self.building == 0) then
			self:SetBusy(false);
		end
	end,
	---------------------------
	--	CancelJobForPlayer
	---------------------------
	CancelJobForPlayer = function(self, playerId)
		for i = 1, self.slotCount do
			local slot = self.slots[i];
			if (slot and slot.build and slot.build.ownerId == playerId) then
				self:OnPurchaseCancelled(slot, true);
			end
		end
		if (#self.queue > 0) then
			for i, build in pairs(self.queue) do
				if (build.ownerId == playerId) then
					table.remove(self.queue, i);
					self:OnPurchaseCancelled(build, false); 
					return;
				end
			end
		end
	end,
	---------------------------
	--	OnPurchaseCancelled
	---------------------------
	OnPurchaseCancelled = function(self, slot, openGate) 
		local build = slot.build or slot;
		g_gameRules:OnPurchaseCancelled(build.ownerId, build.teamId, build.class);
		local channelId = nCX.GetChannelId(build.ownerId);
		if (channelId > 0) then
			self.onClient:ClVehicleCancel(channelId, self:GetVehicleName(build.class));
		end
		if (slot.build) then 
			self:StopBuilding(slot);
			if (openGate) then
				if (not slot.open) then -- open immediately if closed or closing
					self:OpenSlot(slot, true, false);
					self.allClients:ClOpenSlot(slot.id, true, false);
					--System.LogAlways("OnPurchaseCancelled "..slot.id);
				end
			end
		end
	end,
	---------------------------
	--		UpdateSlot
	---------------------------
	UpdateSlot = function(self, slot)
		if (not slot.enabled) then
			return;
		end
		local build = slot.build;
		local ownerId = build and build.ownerId;
		if (build) then
			build.timer = build.timer - 1;
			if (build.timer <= 0) then
				local vehicle = g_gameRules.Server.RequestVehicleBuild and g_gameRules.Server.RequestVehicleBuild(g_gameRules, self, slot, build.class, ownerId, build.teamId);
				if (vehicle) then
					self.allClients:ClVehicleBuilt(self:GetVehicleName(build.class), vehicle.id, ownerId, build.teamId, slot.id);
				end
				self:StopBuilding(slot);
				slot.gate = {2.0, true,};
			end
		end
		if (slot.gate) then
			local open = (slot.gate[2] == true);
			if (slot.gate[1] > 0) then
				if (not open) then
					for entityId, v in pairs(slot.players or {}) do
						if (not nCX.IsSameTeam(self.id, entityId)) then
							nCX.ForbiddenAreaWarning(true, slot.gate[1], entityId);
						end
					end
				end
				slot.gate[1] = slot.gate[1] - 1;
			else
				self:OpenSlot(slot, open, false);
				self.allClients:ClOpenSlot(slot.id, open, false);
				if (not open) then
					for entityId, v in pairs(slot.players or {}) do
						if (not nCX.IsSameTeam(self.id, entityId)) then
							nCX.ForbiddenAreaWarning(false, 0, entityId);
							nCX.ProcessEMPEffect(entityId, 0.3);
							nCX.ServerHit(entityId,ownerId,1000,"punish");
						end
					end
				end
				slot.gate = nil;
			end
		end
	end,
	---------------------------
	--	GetParkingLocation
	---------------------------
	GetParkingLocation = function(self, slot)
		local vec = {x=0,y=0,z=0};
		local pos=self:GetHelperPos(slot.props.SpawnHelperName, 0, vec);
		local dir=self:GetHelperDir(slot.props.SpawnHelperName, 0, vec);
		return pos, dir;
	end,
	---------------------------
	--	AdjustVehicleLocation
	---------------------------
	AdjustVehicleLocation = function(self, vehicle)
		local min, max = vehicle:GetLocalBBox();
		local pos = vehicle:GetWorldPos();
		local np={x=0,y=0,z=0};	
		np.x=(min.x+max.x)*0.5;
		np.y=(min.y+max.y)*0.5;
		np.z=min.z;
		local new = vehicle:ToGlobal(-1, np, {x=0,y=0,z=0});
		new.x=pos.x+(pos.x-new.x);
		new.y=pos.y+(pos.y-new.y);
		new.z=pos.z+(pos.z-new.z);
		vehicle:SetWorldPos(new);
	end,
	---------------------------
	--		GetBuildTime
	---------------------------
	GetBuildTime = function(self, class)
		local def = g_gameRules:GetItemDef(class);
		if (def and def.buildtime) then
			return def.buildtime;
		end
		return 30;
	end,
	---------------------------
	--		Queue
	---------------------------
	Queue = function(self, class, ownerId)
		local slot, same = self:GetFreeSlot(ownerId);
		if (slot) then
			if (same) then
				if (slot.build.class == class) then
					self:OnPurchaseCancelled(slot, true);
					slot.build = nil;
					slot.gate = nil;
					return false;
				else
					self:OnPurchaseCancelled(slot, false);
				end
			end				
			self:StartBuilding(slot, self:GetBuildTime(class), class, ownerId, nCX.GetTeam(ownerId));
			return true;
		end
		if (self:AddToQueue(class, ownerId)) then
			return true;
		end
		return false;
	end,
	---------------------------
	--		AddToQueue
	---------------------------
	AddToQueue = function(self, class, ownerId)
		local replace;
		for i, queue in pairs(self.queue) do
			if (queue.ownerId == ownerId) then
				self:OnPurchaseCancelled(queue, false);
				self.queue[i] = nil;					 -- make an empty slot to replace with new (don't use table.remove here)
				if (queue.class == class) then
					return false; 						 -- same class as previous, don't create new vehicle	
				end
				replace = i;
				break;
			end
		end
		if (replace or #self.queue < self.queueCount) then		
			local channelId = nCX.GetChannelId(ownerId);
			if (channelId > 0) then
				self.onClient:ClVehicleQueued(channelId, self:GetVehicleName(class));
			end
			local teamId = nCX.GetTeam(ownerId);
			self.queue[replace or (#self.queue + 1)] = {
				["class"]=class, 
				["ownerId"]=ownerId, 
				["teamId"]=teamId,
			};
			return true;
		end
		return false;
	end,
	---------------------------
	--		UpdateQueue
	---------------------------
	UpdateQueue = function(self)
		if (#self.queue > 0) then
			local slot = self:GetFreeSlot();
			if (slot) then
				local queued = self.queue[1];
				self:StartBuilding(slot, self:GetBuildTime(queued.buildVehicle), queued.class, queued.ownerId, queued.teamId);
				table.remove(self.queue, 1);
			end
		end
	end,
	---------------------------
	--		GetSlotETA
	---------------------------
	GetSlotETA = function(self, n)
		local slot=self.slots[n];
		if (slot.build and slot.enabled) then
			return self.slots[n].buildTimer;
		else
			return 0;
		end
	end,
	---------------------------
	--		GetFreeSlot
	---------------------------
	GetFreeSlot = function(self, ownerId)
		for i, slot in pairs(self.slots) do	
			local same = (slot.build and slot.build.ownerId == ownerId);
			local free = same or self:IsSlotReady(slot);
			if (free) then
				return slot, same;
			end
		end
	end,
	---------------------------
	--		IsSlotReady
	---------------------------
	IsSlotReady = function(self, slot)
		if ((not slot.gate or slot.gate[2] ~= true) and not slot.build and slot.enabled) then
			local entities = System.GetPhysicalEntitiesInBox(self:GetWorldPos(), self.radius);
			if (entities) then
				for i, e in pairs(entities) do
					if (e.vehicle) then
						local areaId = slot.vehicleAreaId;
						if (self:IsEntityInsideArea(areaId, e.id)) then
							return false;
						end
					end
				end
			end
			return true;
		end
		return false;
	end,
	---------------------------
	--		Capture
	---------------------------
	Capture = function(self, teamId)
		self.captured = teamId;
		if (self.contested) then  -- just incase
			self.contested = nil;
			self.allClients:ClContested(false);
		end
		self.data = nil;
		nCX.SetTeam(teamId, self.id);	
		self.allClients:ClCapture(teamId);
		if (g_gameRules.Server.OnCapture) then
			g_gameRules.Server.OnCapture(g_gameRules, self, teamId, self.inside[teamId]);
		end
	end,
	---------------------------
	--		Uncapture
	---------------------------
	Uncapture = function(self, teamId, skip, reset)
		local oldTeamId = nCX.GetTeam(self.id) or 0;
		self.allClients:ClUncapture(teamId, oldTeamId);
		if (not skip) then
			nCX.SetTeam(0, self.id);
			self.captured = nil;
			if (not reset) then
				self.data = {self.Properties.captureTime, teamId,};
				self.allClients:ClStartCapture(self.data[2]);	
			end
		end
		if (self.captured) then
			for i=1, self.slotCount do
				local slot=self.slots[i];
				local build = slot.build;
				if (slot.enabled and build) then
					g_gameRules:OnPurchaseCancelled(build.ownerId, build.class);
					local channelId = nCX.GetChannelId(build.ownerId);
					if (channelId > 0) then
						self.onClient:ClVehicleCancel(channelId, self:GetVehicleName(build.class));
					end
				end
				self:ResetSlot(slot);
				if (slot.enabled) then
					self:OpenSlot(slot, true, false);
					self.allClients:ClOpenSlot(slot.id, true, false);
				end
			end
		end
		if (g_gameRules.Server.OnUncapture) then
			g_gameRules.Server.OnUncapture(g_gameRules, self, teamId, oldTeamId);
		end	
	end,
	---------------------------
	--		OnTimer
	---------------------------
	OnTimer = function(self)
		local data = self.data;
		if (not self.contested and data) then
			--data[1] = data[1] - (0.8 + math.min(1.0, math.max(3, nCX.Count(self.inside[data[2]])) * 0.2));
			local count = 1 + math.min(3, nCX.Count(self.inside[data[2]]) - tonumber(self.Properties.captureRequirement)) * 0.33;
			data[1] = data[1] - count;
			--System.LogAlways("Factory "..data[1].." | "..count);
			if (data[1] <= 0) then
				if (self.captured) then
					self:Uncapture(data[2]);
				else
					self:Capture(data[2]);
				end
				return;
			end
			if (self.captured) then
				self.allClients:ClStepUncapture(data[2], data[1]);		
			else
				self.allClients:ClStepCapture(data[2], data[1]);
			end
		end
		if (self.captured) then
			for i, slot in pairs(self.slots) do
				self:UpdateSlot(slot);
			end
			if (self.queueTimer > 0) then
				self.queueTimer = self.queueTimer - 1;
				if (self.queueTimer <= 0) then
					self:UpdateQueue();
					self.queueTimer = self.queueTimer + self.queueUpdateTimer;
				end
			end
		end			
	end,
	---------------------------
	--			Buy
	---------------------------
	Buy = function(self, playerId, class)
		if (self:CanBuild(class)) then
			return self:Queue(class, playerId);
		else
			nCX.SendTextMessage(2, "@mp_CannotBuild!", nCX.GetChannelId(playerId));
		end
		return false;
	end,
	---------------------------
	--			GetVehicleName
	---------------------------
	GetVehicleName = function(self, class)
		return g_gameRules.GetVehicleName and g_gameRules:GetVehicleName(class) or class;
	end,
	---------------------------
	--		IsInside
	---------------------------
	IsInside = function(self, entity)
		local teamId = nCX.GetTeam(entity.id);
		local inside = self.inside[teamId];
		return inside and entity.Info and inside[entity.Info.Channel];
	end,
	---------------------------
	--		CheckChannels
	---------------------------
	CheckChannels = function(self, tbl)
		for chan, v in pairs(tbl or {}) do 
			if (not nCX.GetPlayerByChannelId(chan)) then
				tbl[chan] = nil;
				System.LogAlways("[$4Warning$9] Channel $4"..chan.." not in game! Deleting entry from "..self:GetName());
			end
		end
	end,
	---------------------------
	--		CanBuy
	---------------------------
	CanBuy = function(self, class)
		if (self.restricted[class] and self.restricted[class]==true) then
			return false;
		end
		return true;
	end,
};

for i = 1, 6 do
	Factory.Properties["Slot"..i] = { bEnabled=1, SpawnHelperName="", OpenAnimation="", CloseAnimation="", AreaId=11, VehicleAreaId=11 };
end

local NetSetup = {
	Class = Factory,
	ClientMethods =	{
		ClOpenSlot 			= { RELIABLE_UNORDERED, NO_ATTACH, INT8, BOOL, BOOL, },
		ClVehicleBuildStart	= { RELIABLE_ORDERED, NO_ATTACH, STRING, ENTITYID, INT8, INT8, FLOAT },
		ClVehicleBuilt		= { RELIABLE_ORDERED, NO_ATTACH, STRING, DEPENTITYID, ENTITYID, INT8, INT8 },
		ClVehicleQueued		= { RELIABLE_ORDERED, NO_ATTACH, STRING, },
		ClVehicleCancel		= { RELIABLE_ORDERED, NO_ATTACH, STRING, },
		ClSetBuyFlags		= { RELIABLE_ORDERED, NO_ATTACH, DEPENTITYID, INT16 };
	},
	ServerMethods = {},
	ServerProperties = {
		busy = BOOL,
	}
};

--> Weird fix
local NT = NetSetup.ClientMethods;
NT.ClStartCapture		= { RELIABLE_ORDERED, NO_ATTACH, INT8 };
NT.ClCancelCapture		= { RELIABLE_ORDERED, NO_ATTACH, };
NT.ClStepCapture		= { RELIABLE_ORDERED, NO_ATTACH, INT8,  FLOAT };
NT.ClCapture			= { RELIABLE_ORDERED, NO_ATTACH, INT8 };
NT.ClStartUncapture		= { RELIABLE_ORDERED, NO_ATTACH, INT8 };
NT.ClCancelUncapture	= { RELIABLE_ORDERED, NO_ATTACH, };
NT.ClStepUncapture		= { RELIABLE_ORDERED, NO_ATTACH, INT8,  FLOAT };
NT.ClUncapture			= { RELIABLE_ORDERED, NO_ATTACH, INT8, INT8 };
NT.ClContested			= { RELIABLE_ORDERED, NO_ATTACH, BOOL };
NT.ClInit				= { RELIABLE_ORDERED, NO_ATTACH, BOOL, INT8 };

g_gameRules:MakeBuyZone(Factory, bor(2,8));  
Net.Expose(NetSetup);

--[[
local NetSetup = {
	Class = Factory,
	ClientMethods =	{
		ClOpenSlot 			= { RELIABLE_UNORDERED, POST_ATTACH, INT8, BOOL, BOOL, },
		ClVehicleBuildStart	= { RELIABLE_ORDERED, POST_ATTACH, STRING, ENTITYID, INT8, INT8, FLOAT },
		ClVehicleBuilt		= { RELIABLE_ORDERED, NO_ATTACH, STRING, DEPENTITYID, ENTITYID, INT8, INT8 },
		ClVehicleQueued		= { RELIABLE_ORDERED, POST_ATTACH, STRING, },
		ClVehicleCancel		= { RELIABLE_ORDERED, POST_ATTACH, STRING, },
		ClSetBuyFlags		= { RELIABLE_ORDERED, NO_ATTACH, DEPENTITYID, INT16 };
	},
	ServerMethods = {},
	ServerProperties = {
		busy = BOOL,
	}
};

--> Weird fix
local NT = NetSetup.ClientMethods;
NT.ClStartCapture		= { RELIABLE_ORDERED, POST_ATTACH, INT8 };
NT.ClCancelCapture		= { RELIABLE_ORDERED, POST_ATTACH, };
NT.ClStepCapture		= { RELIABLE_ORDERED, POST_ATTACH, INT8,  FLOAT };
NT.ClCapture			= { RELIABLE_ORDERED, POST_ATTACH, INT8 };
NT.ClStartUncapture		= { RELIABLE_ORDERED, POST_ATTACH, INT8 };
NT.ClCancelUncapture	= { RELIABLE_ORDERED, POST_ATTACH, };
NT.ClStepUncapture		= { RELIABLE_ORDERED, POST_ATTACH, INT8,  FLOAT };
NT.ClUncapture			= { RELIABLE_ORDERED, POST_ATTACH, INT8, INT8 };
NT.ClContested			= { RELIABLE_ORDERED, POST_ATTACH, BOOL };
NT.ClInit				= { RELIABLE_ORDERED, POST_ATTACH, BOOL, INT8 };

g_gameRules:MakeBuyZone(Factory, bor(2,8));  
Net.Expose(NetSetup);]]