Repair = {

	---------------------------
	--		Config
	---------------------------
	Tick		 = 1,
	Tag		     = 17,
	
	Works 		 = {},  -- entities repaired by repair vehicle -- passengers must be present 
	Queue 		 = {},  -- queue for entities waiting to be repaired 
	Zones 		 = {},  -- vehicle repair trigger zones
	Requests 	 = {},  -- requests initiated by chat command (!repair)
	Vehicles 	 = {},  -- repairs initiated by radio command confirm 
	Request_Msg  = "[  %s  ] :: Repair %s? :: [ %s DMG ] :: Press [ F5 + 1 ] for YES : [ F5 + 2 ] for NO",
		
	Server = {
			
		OnDisconnect = function(self, channelId, player)
			self.Requests[player.id] = nil;
		end,
		
		OnChangeSpectatorMode = function(self, player)
			self.Requests[player.id] = nil;
		end,
	
		OnEnterArea = function(self, zone, entity)
			local vehicle = self.Zones[zone.id];
			if (vehicle and not self.Vehicles[entity.id]) then -- dont repair vehicle which are repaired through !repair
				local vehicleId = vehicle.id;
				local driverId = vehicle:GetDriverId();
				local channelId = driverId and nCX.GetChannelId(driverId);
				channelId = channelId and channelId > 0 and channelId;
				if (nCX.IsSameTeam(vehicleId, entity.id)) then
					local speed = vehicle:GetSpeed();
					if (vehicle.vehicle:GetMovementType() == "air") then
						local speed = vehicle:GetSpeed();
						if (speed > 15 and channelId) then
							nCX.SendTextMessage(0, "You're approaching too fast... ("..speed.." mph)", channelId);
							return;
						end
					elseif (vehicle.vehicle:IsDestroyed() or vehicle.vehicle:IsSubmerged()) then
						nCX.SendTextMessage(0, CryMP.Ent:GetVehicleName(entity.class).." destroyed...", channelId);
						return;
					end
					if (entity.vehicle:GetRepairableDamage() > 0) then
						if (self.Works[vehicleId]--[[ or not vehicle:IsAnyPassenger()]]) then  	-- repair vehicle is busy, put entity to queue
							self:AddToQueue(vehicleId, entity);
							return;
						end
						self:Start(entity, vehicle);
					elseif (channelId) then
						nCX.SendTextMessage(0, "This "..CryMP.Ent:GetVehicleName(entity.class).." requires no repair...", channelId);
					end
				elseif (nCX.IsNeutral(entity.id)) then
					if (channelId) then
						nCX.SendTextMessage(0, "Neutral "..CryMP.Ent:GetVehicleName(entity.class).."s cannot be repaired...", channelId);
					end
				else
					local passengers = vehicle:GetPassengers();
					for i, playerId in pairs(passengers or {}) do
						nCX.ProcessEMPEffect(playerId, 0.1);
					end
				end
			end	
		end,
		
		OnLeaveArea = function(self, zone, entity)
			local vehicle = self.Zones[zone.id];
			if (vehicle) then
				local driverId = vehicle:GetDriverId();
				local channelId = driverId and nCX.GetChannelId(driverId);
				if (channelId and channelId > 0) then
					nCX.SendTextMessage(0, "", channelId);
				end
				local queue = self.Queue[vehicle.id];
				if (queue and #queue > 1) then
					for i, ent in pairs(queue) do
						if (ent == entity) then
							table.remove(queue, i);   	-- leaving entity was in queue and left zone
							return;
						end
					end
				end
				local work = self.Works[vehicle.id];   -- leaving entity was in repair service and left zone
				if (work) then
					self:Stop(work);
				end
			end	
		end,
		
		OnEnterVehicleSeat = function(self, vehicle, seat, player, entering)
			if (entering) then
				local work = self.Works[vehicle.id];
				if (work) then
					work.passengers[player.id] = 0;
					g_gameRules.onClient:ClStartWorking(player.Info.Channel, work.target.id, "repair");
				else
					self:ProceedQueue(vehicle); 	-- if vehicle is repair vehicle proceed queue 
				end
			end
		end,
		
		OnLeaveVehicleSeat = function(self, vehicle, seat, player, exiting)
			if (exiting) then
				local work = self.Works[vehicle.id];
				if (work) then		
					local amount = work.passengers[player.id];
					if (amount) then		
						work.passengers[player.id] = nil;
						g_gameRules.onClient:ClStopWorking(player.Info.Channel, work.target.id, work.complete or false);
						g_gameRules:AwardPPCount(player.id, math.floor(amount));
					end
					if (nCX.Count(work.passengers) == 0) then
						self:Stop(work);
						self:AddToQueue(work.vehicle.id, vehicle);
					end				
				end
			end
		end,
		
		OnVehicleDestroyed = function(self, vehicleId, vehicle, msg)
			local work = self.Works[vehicleId] or self.Vehicles[vehicleId];
			if (work) then
				self:Stop(work);
			end
			self.Queue[vehicleId] = nil;
			if (nCX.Count(self.Zones) > 0) then
				for zoneId, vehicle in pairs(self.Zones) do
					if (vehicle.id == vehicleId) then
						self.Zones[zoneId] = nil;
					end
				end
			end
			if (nCX.Count(self.Requests) > 0) then
				for playerId, data in pairs(self.Requests) do
					if (data[2].id == vehicleId) then
						self.Requests[playerId] = nil;
						nCX.SendTextMessage(0, (msg or "Vehicle Destroyed..."), nCX.GetChannelId(playerId));
					end
				end
			end
		end,
		
		OnVehicleLockpicked = function(self, player, vehicle)  
			self.Server.OnVehicleDestroyed(self, vehicle.id, vehicle, "Vehicle Lockpicked...");
		end,
			
		OnVehicleBuilt = function(self, building, vehicleName, vehicleId, ownerId, teamId, gateId, def)
			if (def.repair) then
				self:CreateZone(vehicleId);
			end
		end,
		
		OnRadioMessage = function(self, player, msg)
			local queue = self.Requests[player.id];
			if (queue) then
				if (msg == 1 or msg == 2) then
					nCX.SendTextMessage(0, "", player.Info.Channel);
					self.Requests[player.id] = nil;
					if (msg == 1) then
						local vehicle = queue[2];
						self:Start(vehicle, player);
						if (CryMP.ChatCommands) then
							CryMP.ChatCommands:SetLastUsage(player.Info.Channel, "repair");
						end
					end
					return true;
				end
			end
		end,
		
		OnKill = function(self, hit, shooter, target)
			if (nCX.Count(self.Vehicles) > 0) then
				for targetId, work in pairs(self.Vehicles) do
					if (work.owner.id == target.id) then
						self:Stop(work);
						break;
					end
				end
			end
			self.Requests[target.id] = nil;
		end,
	
		PreVehicleHit = function(self, hit, vehicle, svehicle)
			if (svehicle and nCX.IsSameTeam(svehicle.id, vehicle.id) and not hit.self) then
				if (self:IsRepairVehicle(svehicle.id)) then -- repair vehicle wont be able to damage other friendly vehicles
					return true;
				end
			end
		end,
		
		OnStatusRequest = function(self, actorId)
			if (self.Requests[actorId]) then
				return true;
			end
		end,
	
	},
	
	OnInit = function(self)
		self:SetUpdate(false);
	end,
	
	OnShutdown = function(self, restart)
		if (not restart) then
			for vehicleId, work in pairs(self.Works) do
				self:Stop(work);
			end
			for vehicleId, work in pairs(self.Vehicles) do
				self:Stop(work);
			end
			return {"Zones"};
		end	
	end,
	
	OnTick = function(self)
		if (self.Interval == 0) then
			if (nCX.Count(self.Zones) > 0) then
				for zoneId, vehicle in pairs(self.Zones) do
					if (vehicle:GetSpeed() == 0) then
						local pos = vehicle:GetPos();
						nCX.ParticleManager("expansion_misc.Lights.Towersignallight", 0.4, {pos.x, pos.y, pos.z + 4}, g_Vectors.up, 0);
					end
					--local zone = System.GetEntity(zoneId);
					--if (zone) then
					--	zone:SpawnLights()
					--end
				end
				self.Interval = 5;
			end
		end
		self.Interval = (self.Interval or 5) - 1;		
		if (nCX.Count(self.Requests) > 0) then
			for playerId, data in pairs(self.Requests) do
				local vehicle = data[2];
				if (data[1] == 0 or vehicle.vehicle:GetRepairableDamage()<=0) then	
					nCX.SendTextMessage(0, "", nCX.GetChannelId(playerId));
					self.Requests[playerId] = nil;
				else
					local rate = vehicle.vehicle:GetRepairableDamage();
					local damage = math.ceil(rate * 100);
					nCX.SendTextMessage(0, self.Request_Msg:format(math:zero(data[1]), CryMP.Ent:GetVehicleName(vehicle.class), damage), nCX.GetChannelId(playerId));
					data[1] = data[1] - 1;
				end
			end
		end
		if (nCX.Count(self.Works) > 0) then
			for vehicleId, work in pairs(self.Works) do
				self:SpawnParticles(work.vehicle, work.target);
			end
		end
	end,
	
	OnUpdate = function(self, frameTime)
		if (nCX.Count(self.Works) > 0) then
			for vehicleId, work in pairs(self.Works) do
				local stop = self:Process(work, frameTime);
				if (stop) then
					self:Stop(work);
				end
			end
		end
		if (nCX.Count(self.Vehicles) > 0) then
			for vehicleId, work in pairs(self.Vehicles) do
				local stop, pp = self:Process(work, frameTime);
				if (stop) then
					self:Stop(work, pp);
				end
			end
		end	
	end,
		
	Process = function(self, work, frameTime)
		local target, passengers, owner = work.target, work.passengers, work.owner;
		local amount = (60 * frameTime);
		if (passengers) then
			amount = math.max(1, nCX.Count(passengers)) * amount;
		end			
		local pos = target:GetWorldPos();
		local driverId = (owner and owner.id) or (work.driverId) or target.id;
		local progress = math.ceil((1.0-target.vehicle:GetRepairableDamage()) * 100);
		target.vehicle:OnHit(target.id, driverId, (progress == 100 and 100 or amount), pos, 0, "repair", false);
		work.complete = target.vehicle:GetRepairableDamage()<=0;
		if (passengers) then
			for id, v in pairs(passengers) do
				g_gameRules.onClient:ClStepWorking(nCX.GetChannelId(id), progress);
				work.passengers[id] = work.passengers[id] + amount;
			end
		elseif (owner) then
			g_gameRules.onClient:ClStepWorking(owner.Info.Channel, progress);
			work.amount = work.amount + amount;
			if (progress ~= 100) then 
				work.pp = work.pp - amount;
			end
			if (work.pp < 0) then
				return true, true
			end
		end
		return work.complete;
	end,
	
	Start = function(self, target, entity)	-- entity = repairvehicle or actor
		--if (entity.actor) then
		--	entity.actor:RepairTarget(target.id, true);
		--	return;
		--end
		if (nCX.Count(self.Works) + nCX.Count(self.Vehicles) == 0) then
			self:SetUpdate(true);
		end
		if (entity.vehicle) then
			local passengers = entity:GetPassengers() or {};
			local tbl = {};
			for i, id in pairs(passengers) do
				tbl[id] = 0;
				g_gameRules.onClient:ClStartWorking(nCX.GetChannelId(id), target.id, "repair");
			end
			self.Works[entity.id] = {
				target = target,
				vehicle = entity,
				passengers = tbl,
				driverId = passengers[1],
			};
			self:SpawnParticles(entity, target);
		elseif (entity.actor) then
			g_gameRules.onClient:ClStartWorking(entity.Info.Channel, target.id, "repair");
			self.Vehicles[target.id] = {
				target = target,
				owner = entity,
				amount = 0, 
				pp = g_gameRules:GetPlayerPP(entity.id),
				dmg = target.vehicle:GetRepairableDamage(),
			};
		end
	end,
		
	Stop = function(self, work, pp)				
		local entity = work.vehicle or work.owner;
		local vehicle = work.target;
		local vehicleId = vehicle.id;
		if (entity.vehicle) then	
			for id, amount in pairs(work.passengers) do
				g_gameRules.onClient:ClStopWorking(nCX.GetChannelId(id), vehicleId, work.complete or false);
				if (work.complete) then
					g_gameRules:AwardPPCount(id, math.floor(amount));
				end
			end
			self.Works[entity.id] = nil;
		elseif (entity.actor) then
			local channelId = entity.Info.Channel;
			g_gameRules.onClient:ClStopWorking(channelId, vehicleId, work.complete or false);
			g_gameRules:AwardPPCount(entity.id, -math.floor(work.amount), true);
			if (pp) then
				--local damage = vehicle.vehicle:GetRepairableDamage();
				--local repaired = math.ceil(damage * 100)
				CryMP.Msg.Flash:ToPlayer(channelId, {60, "#d77676", "#ec2020", true}, "NO PRESTIGE LEFT", "<font size=\"32\"><b><font color=\"#b9b9b9\">*** </font> <font color=\"#843b3b\">REPAIR [<font color=\"#d77676\">  %s  </font><font color=\"#843b3b\">] CANCELED</font> <font color=\"#b9b9b9\"> ***</font></b></font>");
			else
				local damage = math:zero(math.ceil(work.dmg * 100));
				local name = entity:GetName();
				local class = CryMP.Ent:GetVehicleName(vehicle.class);
				CryMP.Msg.Chat:ToOther(channelId, "Player "..name.." repaired "..class.." ("..damage.." DMG)", self.Tag);		
				self:Log("Player "..name.." repaired "..class.." ($4"..damage.." $9dmg)");
			end
			self.Vehicles[vehicleId] = nil;
		end
		if (work.complete) then
			g_gameRules.allClients:ClWorkComplete(vehicleId, "repair");
		end
		if (work.passengers and nCX.Count(work.passengers) == 0) then
			if (not work.complete) then
				self:AddToQueue(vehicleId, entity);
			end
		elseif (entity.vehicle) then
			self:ProceedQueue(entity);
		end
		if (nCX.Count(self.Works) + nCX.Count(self.Vehicles) == 0) then
			self:SetUpdate(false);
		end
	end,
	
	AddToQueue = function(self, vehicleId, entity)
		local queue = self.Queue[vehicleId];
		if (queue) then
			for i, ent in pairs(queue) do
				if (ent == entity) then
					return false;
				end
			end
		else
			self.Queue[vehicleId] = {};
		end
		self.Queue[vehicleId][#self.Queue[vehicleId] + 1] = entity;
		return true;
	end,
	
	ProceedQueue = function(self, vehicle)
		local queue = self.Queue[vehicle.id];
		if (queue and #queue > 0) then
			for i, entity in pairs(queue) do
				if (entity:IsAnyPassenger()) then
					if (entity.vehicle:GetRepairableDamage()>0) then    -- check if entity in queue is repairable and there is a passenger
						self:Start(entity, vehicle);
						break;
					end
					table.remove(queue, i);
				end
			end
		end
	end,
	
	CreateZone = function(self, vehicleId)
		local vehicle = System.GetEntity(vehicleId);
		if (vehicle) then
			local dim = {x = 25, y = 25, z = 15,};
			if (vehicle.class == "US_vtol") then
				dim = {x = 30, y = 30, z = 35,};
			end
			local params = {
				dim = dim,
				name = "Repair_"..vehicle:GetName();
			};
			local trigger, current = CryMP.Ent:SpawnTrigger(params, vehicle)
			trigger = trigger or current;
			if (trigger) then
				self.Zones[trigger.id] = vehicle;
				trigger.CanEnter = function(trigger, entity)
					return entity.vehicle;
				end
			end
			vehicle.Properties.Modification = "Repair";
		end
	end,
		
	IsRepairVehicle = function(self, vehicleId)
		if (nCX.Count(self.Zones) > 0) then
			for zoneId, vehicle in pairs(self.Zones) do
				if (vehicleId == vehicle.id) then
					return true;
				end
			end
		end
		return false;
	end,
		
	Fix = function(self, player)	
		if (not self:CanRequest(player.id)) then
			return false, "do current request first";
		end
		local vehicle = player.actor:GetLinkedVehicle();
		local isOnVehicle = vehicle ~= nil;
		if (not vehicle) then
			local vehicleId, time = player.actor:GetLastVehicle();
			vehicle = vehicleId and System.GetEntity(vehicleId);
			if (not vehicle) then
				return false, "no vehicle found"
			end
		end
		if (player.actor:RepairTarget(vehicle.id, true)) then	
			return true;
		end
		
		local work = self.Vehicles[vehicle.id];	
		if (work) then
			self:Stop(work)
			return true;
		end
		if (not nCX.IsSameTeam(vehicle.id, player.id) and not nCX.IsNeutral(vehicle.id) and not nCX.IsNeutral(player.id)) then
			return false, "cannot repair this vehicle"
		elseif (vehicle.vehicle:IsDestroyed() or vehicle.vehicle:IsSubmerged()) then
			return false, "vehicle is destroyed"
		elseif (self:IsRepairVehicle(vehicle.id)) then
			return false, "cannot use on a repair vehicle"
		elseif (vehicle.vehicle:GetRepairableDamage() <= 0) then
			return false, "no repairable damage"
		end
		for playerId, data in pairs(self.Requests) do
			if (data[2] == vehicle) then
				if (playerId == player.id) then
					nCX.SendTextMessage(0, "", player.Info.Channel); 	
					self.Requests[playerId] = nil;
					return true;
				end
				return false, "repair already requested";
			end
		end
		if (isOnVehicle) then
			self:Start(vehicle, player);
			if (CryMP.ChatCommands) then
				CryMP.ChatCommands:SetLastUsage(player.Info.Channel, "repair");
			end
		else
			self.Requests[player.id] = {15, vehicle};
			local damage = math.ceil(vehicle.vehicle:GetRepairableDamage() * 100);
			nCX.SendTextMessage(0, self.Request_Msg:format("--", CryMP.Ent:GetVehicleName(vehicle.class), damage), player.Info.Channel);
		end
		return true;
	end,
	
	GetRepairCost = function(self, vehicle)
		local damage = vehicle.vehicle:GetRepairableDamage();
		local name = vehicle.builtas;
		if (name) then
			return (damage * 100 * 4);
		end
		return damage;
	end,
		
	SpawnParticles = function(self, entity, target)
		local repairPos = entity:GetCenterOfMassPos();
		repairPos.z = repairPos.z + 2;
		local pos = target:GetCenterOfMassPos();
		local vec = math:DifferenceVectors(pos, repairPos );
		local scale = 0.01;
		if (entity:IsHeavy()) then
			scale = 0.2;
		end
		nCX.ParticleManager("Alien_Weapons.singularity.Tank_Singularity_Spinup", scale, repairPos, vec, 0);--Alien_Weapons.singularity.Tank_Singularity_Spinup --smoke_and_fire.Tank_round.rifle_gauss
		nCX.ParticleManager("alien_special.Trooper.death_chargeup", 1, pos, g_Vectors.up, 0); --explosions.hunter.footstep  --alien_special.Trooper.death_chargeup
	end,
		
};

--[[

Alien_Weapons.Moac.Scout_Moac_Impact


smoke_and_fire.fuel_tank.large


smoke_and_fire.Tank_round.rifle_gauss
	--g_gameRules:CreateExplosion(nil,nil,0,pos,g_Vectors.up,1,1,1,1,"expansion_fx.electric3",0.2, 7, 7, 7);
alien_special.Trooper.death_chargeup
		g_gameRules:CreateExplosion(nil,nil,1,{pos.x,pos.y,pos.z+4,},g_Vectors.up,1,1,1,1,"expansion_fx.weapons.emp_grenade",0.2, 0, 0, 0);

]]

