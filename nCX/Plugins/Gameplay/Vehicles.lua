Vehicles = {
	
	---------------------------
	--		Config
	---------------------------
	ScanRadius 				 = 200,
	Tag 					 = 17, 
	Locked 			 		 = {},
	Built 			 		 = {},
	
	Info = {
		["Civ_car1"]		 = {2.8,0.4},
		["US_vtol"]			 = {4.0,0.6},
		["US_tank"] 		 = {3.5,0.6},
		["US_ltv"] 			 = {2.8,0.4},
		["US_asv"] 			 = {3.2,0.4},
		["US_hovercraft"] 	 = {3.4,0.4},
		["US_apc"] 			 = {3.5,0.6},
		["US_smallboat"]	 = {2.6,0.4},
		["US_trolley"] 		 = {0.6,0.2},
		["Asian_patrolboat"] = {6.6,0.8},
		["Asian_aaa"]		 = {4.5,0.4},
		["Asian_tank"]		 = {3.5,0.6},
		["Asian_truck"] 	 = {4.0,0.4},
		["Asian_apc"] 		 = {3.5,0.6},
		["Asian_helicopter"] = {4.4,0.6},
		["Asian_ltv"] 		 = {2.8,0.4},
	},
	
	Server = {
									
		OnDisconnect = function(self, channelId, player)
			for vehicleId, ownerId in pairs(self.Locked) do
				if (ownerId == player.id) then
					self.Locked[vehicleId] = nil;
				end
			end
			self.Built[player.id] = nil;
		end,
		
		OnChangeTeam = function(self, player, teamId)
			local tbl = self.Built[player.id];
			if (tbl) then
				for i, vehicleId in pairs(tbl) do
					local vehicle = System.GetEntity(vehicleId);
					if (vehicle) then
						vehicle.vehicle:SetOwnerId(NULL_ENTITY);
					else
						table.remove(tbl, i);
					end
				end
				self.Built[player.id] = nil;
			end
		end,
		
		OnRevive = function(self, channelId, player, vehicle, first)
			if (vehicle and vehicle.vehicle) then
				local ownerId = vehicle.vehicle:GetOwnerId();
				if (ownerId and ownerId ~= player.id and ownerId ~= NULL_ENTITY) then	
					local HUD = vehicle:GetDistance(ownerId) < 50 or -1;
					g_gameRules:AwardPPCount(ownerId, 10, HUD);	
				end
			end		
		end,
		
		OnVehicleDestroyed = function(self, vehicleId)
			self.Locked[vehicleId] = nil;
			for ownerId, tbl in pairs(self.Built) do	
				for i, vId in pairs(tbl) do
					if (vId == vehicleId) then
						table.remove(tbl, i);
						if (#tbl == 0) then
							self.Built[ownerId] = nil;
						end
						break;
					end
				end
			end
		end,

		OnVehicleBuilt = function(self, building, vehicleName, vehicleId, ownerId, teamId, gateId, def)
			self.Built[ownerId] = self.Built[ownerId] or {};
			self.Built[ownerId][#self.Built[ownerId] + 1] = vehicleId;
		end,
		
		OnVehicleLockpicked = function(self, owner, vehicle)
			local previousId = self.Locked[vehicle.id];
			if (previousId) then
				CryMP.Ent:PlaySound(previousId, "demote");	
				self.Locked[vehicle.id] = nil;
				local owner = nCX.GetPlayer(previousId);
				if (owner) then
					nCX.SendTextMessage(3, "ENEMY - [ "..vehicle:GetName().." ] - LOCKPICKED", owner.Info.Channel);
				end
			end
		end,
		
		CanEnterVehicle = function(self, vehicle, player)
			local playerId, channelId = player.id, player.Info.Channel;
			local ownerId = self:IsLocked(vehicle.id);
			if (ownerId and ownerId ~= playerId) then
				local owner = nCX.GetPlayer(ownerId);
				if (owner) then
					if (nCX.GodMode(channelId)) then
						CryMP.Ent:PlaySound(playerId, "lockpick");
						nCX.SendTextMessage(3, "Lock bypassed successfully...", channelId);
						return true, {true};
					end
					nCX.SendTextMessage(2, "OWNER - [ "..owner:GetName().." ] - LOCKED", channelId);
					CryMP.Ent:PlaySound(playerId, "error");
					return true, {false};
				end
			end
		end,

		OnLeaveVehicleSeat = function(self, vehicle, seat, player, exiting, server)
			local playerId, channelId = player.id, player.Info.Channel;
			if (not nCX.GodMode(channelId)) then
				if (not exiting and not server) then
					local ownerId = self:IsLocked(vehicle.id);
					if (ownerId and ownerId ~= playerId) then
						local owner = nCX.GetPlayer(ownerId);
						if (owner) then
							CryMP.Ent:PlaySound(playerId, "error");
							nCX.SendTextMessage(2, "OWNER - [ "..owner:GetName().." ] - LOCKED", channelId);
							return true;
						end
					end
				end
			end
		end,
			
		OnFirstVehicleEntrance = function(self, vehicle, seat, player)
			local props = vehicle.Properties;
			if (props.Buyzone) then
				g_gameRules:MakeBuyZone(vehicle, 13, 13);
				if (props.Spawngroup) then
					nCX.AddSpawnGroup(vehicle.id);
				else
					nCX.AddMinimapEntity(vehicle.id, 1, 0);
				end
				CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "[+] >> BUY:ZONE "..(props.Spawngroup and "+ SPAWN " or "").."enabled on this "..CryMP.Ent:GetVehicleName(vehicle.class).."!", 17);
				nCX.ParticleManager("expansion_fx.weapons.emp_grenade", 0.6, vehicle:GetPos(), g_Vectors.up, 0);
				CryMP.Ent:PlaySound(player.id, "lockpick");
				nCX.AbortEntityRemoval(vehicle.id);
			end
		end,
	
	},
	
	OnShutdown = function(self, restart)
		if (not restart) then
			return {"Locked", "Built",};
		end
	end,
	
	IsLocked = function(self, vehicleId)
		return self.Locked[vehicleId];
	end,
	
	GetOwnersClosestVehicle = function(self, owner)
		local vehicles = {};
		local ents = System.GetEntitiesInSphere(owner:GetPos(), self.ScanRadius);
		for i, ent in pairs(ents or {}) do
			if (ent.vehicle and ent.vehicle:GetOwnerId() == owner.id) then
				vehicles[#vehicles + 1] = ent;
			end
		end
		if (#vehicles > 1) then
			local function sort_by_distance(v1, v2)
				return (owner:GetDistance(v1.id) < owner:GetDistance(v2.id));
			end
			table.sort(vehicles, sort_by_distance);
		end
		return vehicles[1];
	end,
	
	CanLock = function(self, player)
		local vehicle = player.actor:GetLinkedVehicle();
		if (vehicle and not CryMP:IsServerVehicle(vehicle.id)) then
			local ownerId = vehicle.vehicle:GetOwnerId();
			if ((not ownerId and vehicle:GetDriverId() == player.id) or ownerId == NULL_ENTITY or ownerId == player.id) then
				return vehicle;
			end
		else
			local vehicleId, time = player.actor:GetLastVehicle();
			vehicle = vehicleId and System.GetEntity(vehicleId);
			if (vehicle and not CryMP:IsServerVehicle(vehicle.id)) then
				local ownerId = vehicle.vehicle:GetOwnerId();
				if (not ownerId or ownerId == NULL_ENTITY or ownerId == player.id) then
					return vehicle, true;
				end
			end
		end
		--return self:GetOwnersClosestVehicle(player), true;
	end,
	
	Lock = function(self, player)
		local playerId, channelId = player.id, player.Info.Channel;
		local vehicle, remote = self:CanLock(player);
		if (vehicle) then
			local ownerId = self:IsLocked(vehicle.id);
			if (ownerId) then
				return self:Unlock(vehicle, player, remote);
			else
				self.Locked[vehicle.id] = playerId;
				local info = self.Info[vehicle.class];
				if (info) then
					local pos = vehicle:GetPos();
					nCX.ParticleManager("misc.runway_light.flash_red", info[2], {pos.x, pos.y, pos.z + info[1]}, g_Vectors.up, 0);
				end
				if (not remote) then
					CryMP.Msg.Chat:ToPlayer(channelId, "LOCKED", self.Tag);
				else
					local distance = string.format("%.2f", player:GetDistance(vehicle.id));
					CryMP.Msg.Chat:ToPlayer(channelId, "LOCKED - Remote : "..distance.." m", self.Tag);
					local passengers = vehicle:GetPassengers();
					if (passengers) then
						for i, passengerId in pairs(passengers) do
							if (passengerId ~= player.id) then
								vehicle.vehicle:ExitVehicle(passengerId);
								CryMP.Msg.Chat:ToPlayer(nCX.GetChannelId(passengerId), "LOCKED - By owner "..player:GetName(), self.Tag);
							end
						end
					end
				end
				nCX.AbortEntityRemoval(vehicle.id);
				return true, false, false, "lockpick";
			end
		end
		return false, "no vehicle of your owner id found within radius of "..self.ScanRadius.." m";
	end,

	Unlock = function(self, vehicle, player, remote)
		local playerId, channelId = player.id, player.Info.Channel;
		self.Locked[vehicle.id] = nil;
		local info = self.Info[vehicle.class];
		if (info) then	
			local pos = vehicle:GetPos();
			nCX.ParticleManager("misc.runway_light.flash", info[2]-0.1, {pos.x, pos.y, pos.z + info[1]}, g_Vectors.up, 0);
		end
		if (not remote) then
			CryMP.Msg.Chat:ToPlayer(channelId, "UNLOCKED", self.Tag);
		else
			local distance = string.format("%.2f", player:GetDistance(vehicle.id));	
			CryMP.Msg.Chat:ToPlayer(channelId, "UNLOCKED - Remote : "..distance.." m", self.Tag);
			local passengers = vehicle:GetPassengers();
			if (passengers) then
				for i, passengerId in pairs(passengers) do
					vehicle.vehicle:ExitVehicle(passengerId);
					local channelId = nCX.GetChannelId(passengerId);
					if (channelId > 0) then
						CryMP.Msg.Chat:ToPlayer(channelId, "UNLOCKED - By owner "..player:GetName(), self.Tag);
					end
				end
			end
		end
		return true, false, false, "lockpick";
	end,
	
	Out = function(self, player, target)
		local vehicle, remote = self:CanLock(player);
		if (vehicle) then
			local playerId, channelId, vehicleId = player.id, player.Info.Channel, vehicle.id;
			local remote = remote and string.format("(REMOTE : %.2fm) ", player:GetDistance(vehicleId)) or "";
			local trgmsg = "*** You have been ejected from the vehicle ***";
			if (not target) then
				local passengers = vehicle:GetPassengers();
				if (passengers) then
					local c = 0;
					for i, id in pairs(passengers) do
						if (id ~= playerId) then
							vehicle.vehicle:ExitVehicle(id);
							nCX.SendTextMessage(3, trgmsg, nCX.GetChannelId(id));
							c = c + 1;
						end
					end
					if (c > 0) then
						nCX.SendTextMessage(3, "*** "..c.." player(s) removed from your vehicle "..remote.."***", channelId);
						return true;
					end
				end
				return false, "no passengers found";
			elseif (target.actor:GetLinkedVehicleId() == vehicleId) then
				local targetId = target.id;
				if (targetId ~= playerId) then
					vehicle.vehicle:ExitVehicle(targetId);
					nCX.SendTextMessage(3, "*** Player "..target:GetName().." removed from your vehicle "..remote.."***", channelId);
					nCX.SendTextMessage(3, trgmsg, target.Info.Channel);
					return true;
				end
				return false, "cannot remove yourself";
			end
			return false, "passenger not found", "Target '"..target:GetName().."' is not in your Vehicle!";
		end
		return false, "no vehicle of your owner-id found";
	end,
	
	Boot = function(self, player, info)
		local vehicle = player.actor:GetLinkedVehicle();
		if (vehicle) then
			vehicle.vehicle:ExitVehicle(player.id);
			if (info) then
				nCX.SendTextMessage(0, "You were forced out of your vehicle by an Admin!", player.Info.Channel);
				CryMP.Msg.Chat:ToOther(player.Info.Channel, player:GetName().." has been forced out of his vehicle!", self.Tag);
			end
            return true;
		end
		return false, "player is not on vehicle";
	end,
	
	Hijack = function(self, player, vehicle, kick)
		if (not vehicle) then
			return false, "target is not in vehicle"
		elseif (CryMP:IsServerVehicle(vehicle.id)) then
			return false, "cannot hijack server-vehicles";
		end
		local driver = vehicle:GetDriver();
		if (driver) then
			if (kick) then
				vehicle.vehicle:ExitVehicle(driver.id);
			else
				local done;
				for i = 2, #vehicle.Seats do
					local seat = vehicle.Seats[i];
					if (seat and seat.seat:IsFree()) then
						vehicle.vehicle:EnterVehicle(driver.id, i, false);
						done = true;
						break;
					end
				end
				if (not done) then
					vehicle.vehicle:ExitVehicle(driver.id);
				end
			end
			nCX.SendTextMessage(0, "Your vehicle was hijacked by an Admin!", driver.Info.Channel);
			CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "You have taken control of "..driver:GetName().."s "..CryMP.Ent:GetVehicleName(vehicle.class), self.Tag);
		else
			CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "You have taken control of "..CryMP.Ent:GetVehicleName(vehicle.class), self.Tag);
		end
		vehicle:EnterVehicle(player.id, 1);
		return true;
	end,
	
};