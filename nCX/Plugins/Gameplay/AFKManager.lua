AFKManager = {

	---------------------------
	--		Config
	---------------------------
	Tick 			= 250,
	Tag 			= 11,
	Distance 		= {},
	Players 		= {},
	NameTag			= "[AFK]-",
	ParticleManager = true,

	Truck = {
		Name 		= "AFK_TRUCK",
		Info = {
			["mesa"] 		= {{x = 3835, y = 2703, z = 403}, {x = -2, y = 1, z = 0}},
			["tarmac"] 		= {{x = 1385, y = 3521, z = 135}, {x = 0, y = 1, z = 0}},
			["beach"] 		= {{x = 3048, y = 2900, z = 537}, {x = -1, y = 0, z = 0}},
			["shore"] 		= {{x = 1044, y = 1295, z = 309}, {x = 1, y = 0, z = 0}},
			["tarmac"] 		= {{x = 1385, y = 3521, z = 135}, {x = 0, y = 1, z = 0}},
			["desolation"] 	= {{x = 947,  y = 170,  z = 420}, {x = 0, y = 1, z = 0}},
			["crossroads"] 	= {{x = 957,  y = 1902, z = 100}, {x = 0, y = 1, z = 0}},
			["plantation"] 	= {{x = 1628, y = 2006, z = 337}, {x = 0, y = -1, z = 0}},
			["refinery"] 	= {{x = 2539, y = 2449, z = 421}, {x = 0, y = -1, z = 0}},
			["frost"] 		= {{x = 3592, y = 2901, z = 293}, {x = -1, y = 0, z = 0}},
			["training"] 	= {{x = 2436, y = 1586, z = 130}, {x = -1, y = 0, z = 0}},
		},
		Pos 		= {--[[x = 3835, y = 2703, z = 403]]},-- z = 407.5
		Dir			= {--[[x = -2, y = 1, z = 0]]},-- z = 2
	},
	
	Server = {
	
		OnRevive = function(self, channelId, player, vehicle, first)
			if (not first) then
				local name = player:GetName();
				if (CryMP.Ent:HasTag(name, self.NameTag)) then
					CryMP.Ent:RemoveTag(name, self.NameTag, player.id);
				end
			end				
		end,
	
		OnDisconnect = function(self, channelId, player)
			self.Distance[channelId]=nil;
		end,
			
		OnEnterArea = function(self, zone, vehicle)
			local area = (self.Proximity == zone.id);
			if (area) then
				if (vehicle.id ~= self.Truck.id) then
					if (vehicle:HasDriver() or vehicle:GetSpeed() < 3) then
						System.RemoveEntity(vehicle.id);
						nCX.ParticleManager("misc.runway_light.flash_red", 0.6, vehicle:GetCenterOfMassPos(), g_Vectors.up, 0);
					else
						local vec = vehicle:GetDirectionVector();
						vec.x = -vec.x
						vec.y = -vec.y
						vec.z = -vec.z
						local pos = vehicle:GetCenterOfMassPos();
						vehicle:AddImpulse(-1, pos, vec, 30000000, 1);
						nCX.ParticleManager("explosions.flashbang.explode", 1.2, pos, vec, 0);
						nCX.ParticleManager("Alien_Weapons.singularity.Tank_Singularity_Spinup", 1.2, pos, vec, 0);
					end
				end					
			end
		end,
				
		CanEnterVehicle = function(self, vehicle, player)
			if (self:IsTruck(vehicle.id)) then
				if (not nCX.GodMode(player.Info.Channel)) then
					self:Disable(player, true);
					CryMP.Ent:Revive(player);
					return true, {false};
				end
			end
		end,		
			
		OnLeaveVehicleSeat = function(self, vehicle, seat, player, exiting, force, distance)
			if (self:IsTruck(vehicle.id)) then
				local last = player.lastSeatId;
				local channelId = player.Info.Channel;
				if (distance and distance > 10) then
					System.LogAlways("[$6Warning$9] OnLeaveVehicleSeat distance invalid :: $4"..distance);
				end
				if (exiting) then
					local admin = nCX.GodMode(channelId);
					local tbl = self.Players[player.id];
					local passed = tbl and _time - tbl[1];
					if (passed and passed < 10 and not force) then
						local remaining = math.ceil(10 - passed);
						nCX.SendTextMessage(0, "AFK - [ 00:"..math:zero(remaining).." ] - TIME", channelId);					
						return true, {4};
					end
					nCX.SendTextMessage(0, "", channelId);
					CryMP:DeltaTimer(5, function()
						self:Disable(player, true, true);
					end);
				elseif (not force) then
					return true;		
				end
			end
		end, 

		OnChangeTeam = function(self, player, teamId)
			if (self:IsAfk(player)) then
				nCX.SendTextMessage(2, "Cannot change team in AFK mode", player.Info.Channel);
				return true;
			end
		end,
		
		OnChangeSpectatorMode = function(self, player, mode)
			if (self:IsAfk(player)) then
				nCX.SendTextMessage(2, "Cannot go spectating in AFK mode", player.Info.Channel);
				return true;
			end
		end,
		
		PreVehicleHit = function(self, hit, vehicle)
			local shooter, target = hit.shooter, hit.target;
			if (self:IsTruck(target.id)) then
				if (shooter.IsDead and not shooter:IsDead() and not hit.self) then
					nCX.ParticleManager("explosions.TAC.small_close_new", 1, shooter:GetPos(), g_Vectors.up, 0);
					if (shooter.actor) then
						g_gameRules:KillPlayer(shooter);
					end
					nCX.SendTextMessage(2, "[ AFK:MANAGER ] "..shooter:GetName().." was nuked. Do NOT attempt to damage the AFK Truck!", 0);
					return true;
				end
			end
		end,
	
		OnNewMap = function(self, map, reboot)
			local map = map:sub(16, -1):lower();
			if (map == "tarmac") then
				local params = {
					class = "Flag",
					name = "AFK_FLAG",
					position = {x = 1383.65, y = 3524, z = 134.2 },
					orientation = {x = 1, y = 0, z = 180},
				};
				local flag = System.SpawnEntity(params);
				if (flag) then
					flag:SetScale(2.5);
					self.Truck.Flag = flag.id;
				end
			end
			local truck = self.Truck;
			local info = truck.Info[map];
			truck.Pos, truck.Dir = info[1], info[2];
			local params = {
				class = "Asian_truck",
				name = truck.Name,
				position = truck.Pos,
				orientation = truck.Dir,
				properties = {
					Modification = "Unarmed",
					Respawn = {
						bAbandon = 0,
						bRespawn = 0,
						bUnique = 1,
						nAbandonTimer = 0,
						nTimer = 0,
					},
				},
			};
			CryMP:Spawn(params, function(vehicle, current)
				vehicle = vehicle or current;
				if (vehicle) then
					vehicle:Hide(1);
					truck.id = vehicle.id;
					local params = {
						name = truck.Name,
						class = "ActionTrigger",
						dim = {x = 30, y = 30, z = 30,},
					};	
					local trigger = CryMP.Ent:SpawnTrigger(params, vehicle);
					self.Proximity = trigger.id;
					trigger.CanEnter = function(trigger, entity)
						return entity.vehicle;
					end
				end
			end);
		end,
		
	},
	
	OnShutdown = function(self, restart)
		if (restart) then
			for playerId, v in pairs(self.Players) do
				CryMP.Ent:RemoveTag(v[2], self.NameTag, playerId);
			end
		else
			if (self.Proximity) then
				System.RemoveEntity(self.Proximity);
			end
			local truck = self.Truck;
			if (truck) then
				if (truck.Flag) then
					System.RemoveEntity(truck.Flag);
				end
				local truckId = truck.id;
				if (truckId) then
					local truck = System.GetEntity(truckId);
					if (truck) then
						local players = truck:GetPassengers();
						for i, playerId in pairs(players or {}) do
							local player = nCX.GetPlayer(playerId);
							if (player) then
								local v = self.Players[player.id];
								nCX.SetTeam(v[3], playerId);
								nCX.GodMode(player.Info.Channel, false);
								CryMP.Ent:RemoveTag(player:GetName(), self.NameTag, player.id);
								CryMP.Ent:Revive(player);
							end 
						end
					end
					System.RemoveEntity(truckId);
				end
			end
		end
	end,
	
	IsAfk = function(self, player, get)
		if (player and player.actor) then
		    local vehicleId = player.actor:GetLinkedVehicleId();
			if (vehicleId == self.Truck.id) then
				return vehicleId;
			end
		end
		return false;
	end,

	OnTick = function(self, players)
		if (self.Truck) then
			for i, player in pairs(players) do
				local channelId = player.Info.Channel;
				if (not nCX.GodMode(channelId) and nCX.IsPlayerActivelyPlaying(player.id) and not player:IsBoxing() and not player:IsDuelPlayer() and not self:IsAfk(player)) then
					local distance = player:GetDistance(self.Truck.id);
					if (not	self.Distance[channelId]) then
						self.Distance[channelId] = distance;
					elseif (distance == self.Distance[channelId]) then
						if (player:GetAccess() > 2) then
							nCX.GodMode(channelId, true);
						else
							self:Enable(player, true);
						end
					else
						self.Distance[channelId] = distance; 
					end
				end
			end
		end
	end,
	
	EnterTruck = function(self, player)
		local truck = self:GetVehicle();
		if (truck) then
			return truck, truck:EnterVehicle(player.id, 4);
		end
	end,

	GetCount = function(self)
		local truck = self:GetVehicle();
		if (truck) then
			return #(truck:GetPassengers() or {});
		end
		return 0;
	end,

	Enable = function(self, player, auto)
		local name = player:GetName();
		local channelId = player.Info.Channel;
		local hasTag = CryMP.Ent:HasTag(name, self.NameTag);
		if (self:IsAfk(player) or hasTag) then
			self:Disable(player);
			return true;
		elseif (self:GetCount() > 5) then
			return false, "too many afk";
		end
		CryMP:GetPlugin("Refresh", function(self) self:SavePlayer(player, true); end);
		local vehicle, seat = self:EnterTruck(player);
		if (vehicle and seat) then
			if (auto) then
				CryMP.Msg.Error:ToAll("[ AFK:MANAGER ] ENABLED > > > "..name.." ("..self.Tick.." sec inactivity)", self.Tag);
				self:Log("Enabled on "..name.." (inactivity)");
			else
				CryMP.Msg.Error:ToAll("[ AFK:MANAGER ] ENABLED > > > "..name.." (user descision)", self.Tag);
				self:Log("Enabled on "..name.." (user descision)");
			end
  		    nCX.RenamePlayer(player.id, self.NameTag..name);
			self.Distance[channelId] = nil;
			local pos = self.Truck.Pos;
			self:ParticleManager("misc.extremly_important_fx.lights_red",1,pos,g_Vectors.up,channelId);
			--pos.z = pos.z - 3;
			local teamId = nCX.GetTeam(player.id);
			self.Players[player.id] = {_time, name, teamId};
			player.CURRENT_TEAM = teamId; -- for emergency
			nCX.GodMode(channelId, true);
			nCX.SetTeam(0, player.id);
			return true;
		end
		return false;
	end,

	Disable = function(self, player, restore, skip)
		if (nCX.GetPlayerByChannelId(player.Info.Channel)) then --tempfix
			local teamId = self.Players[player.id] and self.Players[player.id][3] or player.CURRENT_TEAM or 2;
			nCX.SetTeam(teamId, player.id);
			if (skip or self:IsAfk(player)) then
				if (restore) then
					local name = (CryMP.Ent:HasTag(player:GetName(), self.NameTag) and CryMP.Ent:RemoveTag(player:GetName(), self.NameTag, player.id)) or player:GetName();
					local done, warum = CryMP:GetPlugin("Refresh", function(self) return self:RestorePlayer(player, true); end);
					if (not done) then
						CryMP.Ent:Revive(player);
					end
					local teamName = CryMP.Ent:GetTeamName(teamId);
					CryMP.Msg.Chat:ToAll("RETURNED > > > "..name.." (Team "..teamName..")", self.Tag);
					self:Log(name.." has returned (Team "..teamName..")");
				end
				nCX.GodMode(player.Info.Channel, false);
			end
			self.Players[player.id] = nil;
		end
	end,

	GetVehicle = function(self)
		local truckId = self.Truck and self.Truck.id;
	    local vehicle = truckId and System.GetEntity(truckId);
		if (vehicle and not vehicle.vehicle:IsDestroyed()) then
		    return vehicle;
	    end
    end,
	    
	IsTruck = function(self, vehicleId)
		return (self.Truck.id == vehicleId)
	end,
	
};

