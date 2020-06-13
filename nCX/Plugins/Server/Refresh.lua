Refresh = {
	---------------------------
	--		Config
	---------------------------
	Tick 				= 1,
	Timer				= 60,
	MinDistance 		= 30,
	Entities 			= {"SpawnGroup", "AlienEnergyPoint", "Factory",},
	Players 			= {},
	Queue 				= {},
	Spectate 			= {},
	
	Server = {

		OnNewMap = function(self, map, reboot)
			if (reboot) then
				self:RestoreData();
			elseif (nCX.Refresh) then
				CryMP:SetTimer(4, function()
					self:FullRestore();
				end);
			end
		end,
		
		OnRevive = function(self, channelId, player, vehicle, first)
			if (first and not nCX.Refresh and self:CanRequest(player.id)) then
				local data = self:CanRestore(player);
				if (data and math:GetWorldDistance(player:GetPos(), data.Pos) > self.MinDistance) then	
					self.Queue[player.id] = {15, data};
					self:OnTick();
				end
			end
			if (nCX.Count(self.Spectate) > 0) then
				for channelId, targetId in pairs(self.Spectate) do
					if (targetId == player.id) then
						local spec = nCX.GetPlayerByChannelId(channelId);
						local specId = spec.actor:GetSpectatorTarget();
						if (specId and specId ~= player.id) then
							nCX.ChangeSpectatorMode(spec.id, 3, targetId); 
							break;
						end
					end
				end
			end
		end,
		
		OnRequestRevive = function(self, player)
			local channelId = player.Info.Channel;
			if (self.Spectate[channelId]) then
				self.Spectate[channelId] = nil;	
				local ok = self:RestorePlayer(player, false, true);
				if (ok) then
					nCX.SendTextMessage(5, "", channelId);
					return true;
				end
				return false;
			end
			if (player.actor:GetDeathTimeElapsed() > 2.5) then
				if (nCX.Count(self.Spectate) > 0) then
					for channelId, targetId in pairs(self.Spectate) do
						if (targetId == player.id) then
							if (not player:IsDuelPlayer() and not player:IsBoxing()) then
								CryMP.Msg.Chat:ToPlayer(channelId, "Spectator Target "..player:GetName().." requesting revive...");
							end
							break;
						end
					end
				end
			end
		end,
	
		OnDisconnect = function(self, channelId, player)
			self:SavePlayer(player)
			self.Queue[player.id]=nil;
			self.Spectate[channelId]=nil;
		end,

		OnRadioMessage = function(self, player, msg)
			local queue = self.Queue[player.id];
			if (queue) then
				local vehicle = queue[3];
				if (msg == 1) then
					local ok = true;
					if (vehicle) then
						vehicle:EnterVehicle(player.id, 1);
						CryMP.Ent:PlaySound(player.id,"lockpick");
						self:Reset(player, "Drivers seat claimed by user! Vehicle restore complete...");
					else
						nCX.SendTextMessage(0, "", player.Info.Channel);
						ok = self:RestorePlayer(player);
						self.Queue[player.id]=nil;
					end
					if (ok) then
						local name = player:GetName();
						self:Log(name.." has restored his pos");
						CryMP.Msg.Chat:ToOther(player.Info.Channel, "Player "..name.." has restored his pos");
					end
					return true;
				elseif (msg == 2) then
					if (vehicle) then 
						self:Reset(player, "Vehicle restore canceled by user...");
					else
						self:Reset(player, "Restore canceled by user...");
					end
					return true;
				end
			end
		end,
		
		OnVehicleDestroyed = function(self, vehicleId)
			if (nCX.Count(self.Queue) > 0) then
				for playerId, data in pairs(self.Queue) do
					if (data[3] and data[3].id == vehicleId) then
						self:Reset(nCX.GetPlayer(playerId), "Vehicle restore canceled... (vehicle destroyed)");
					end
				end
			end
		end,
	
		OnVehicleLockpicked = function(self, player, vehicle)  
			if (nCX.Count(self.Queue) > 0) then
				for playerId, data in pairs(self.Queue) do
					if (data[3] and data[3].id == vehicleId) then
						self:Reset(player, "Vehicle restore canceled... (vehicle lockpicked)");
					end
				end
			end
		end,
			
		OnStatusRequest = function(self, playerId)
			if (self.Queue[playerId]) then
				return true;
			end
		end,
		
	},
	
	GetRestoreCount = function(self)
	    local c=0;
		for profileId, player in pairs(self.Players) do
			if (nCX.GetPlayerByProfileId(profileId)) then
				c=c+1;
			end
		end
	    return c;
    end,

    OnTick = function(self, players)
		if (not nCX.Refresh and self.Timer <= 0) then
			self:SaveData();
			self.Timer = 60;			
		end
		if (nCX.Count(self.Queue) > 0) then
			for playerId, queue in pairs(self.Queue) do
				local player = nCX.GetPlayer(playerId);
				if (player) then
					local channelId = player.Info.Channel;
					if (queue[1]==0 or player:IsDuelPlayer() or CryMP.Voting) then
						self:Reset(player, "Restore timed out...");
						return;
					end
					local distance = math:GetWorldDistance(player:GetPos(), queue[2].Pos);
					if (distance < self.MinDistance) then
						self:Reset(player, "Canceled... Too close to restore point!");
					else
						nCX.SendTextMessage(0, "[  "..queue[1].."  ] :: Restore your last position? :: [  "..string:lspace(4, math.floor(distance)).." m  ] :: Press [ F5 + 1 ] for YES : [ F5 + 2 ] for NO", channelId);
					end
					if (players) then
						queue[1]=queue[1]-1;
					end
				end
			end
		end
		self.Timer = self.Timer - 1;
    end,
						
	Reset = function(self, player, msg)
		if (msg) then
			nCX.SendTextMessage(0, msg, player.Info.Channel);
		end
		self.Queue[player.id]=nil;
		self.Players[player.Info.ID] = nil;
    end,
	
	CanSave = function(self, player, force)
		return not (
			player.actor:IsFlying() 
		 or player.actor:GetSpectatorMode() ~= 0
		 or player.actor:GetHealth() <= 0
		 or player:IsDuelPlayer() 
		 or player:IsBoxing() 
		 or player:IsRacing() 
		 or player:IsAfk() 
		 or (System.GetNearestEntityByClass(player:GetPos(), 200, "HQ") and not player:IsOnVehicle() and not force)
		)
	end,
		
    SavePlayer = function(self, player, force, clear)
		local profileId = player.Info.ID;
		if (clear) then
			self.Players[profileId] = nil;
		end
		local can, msg = self:CanSave(player, force);  -- force: save even if in base
		if (not can) then
			return false;
		end
		local pos = player:GetWorldPos();
	    local dir = player:GetWorldAngles();
		local inventory = CryMP.Ent:DumpInventory(player);
	    local health = player.actor:GetHealth();
	    local energy = player.actor:GetNanoSuitEnergy();
	    self.Players[profileId] = {
	        Inventory = inventory,
		    Health = health,
		    Energy = energy,
		    Pos = pos,
		    Dir = dir,
    	};
		--[[
		if (not self.Vehicles) then  -- Refresh only
			local vehicle = player.actor:GetLinkedVehicle() or CryMP.Ent:GetOwnerVehicleInSphere(player);
			if (vehicle) then
				local data = self:GetVehicleData(vehicle, profileId);
				if (data) then
					self.Players[profileId].Vehicle = data;
					return true, vehicle;
				end
			end
		end
		]]
		return true;
	end,
	
	GetVehicleData = function(self, vehicle, profileId, passengers)
		if (CryMP:IsServerVehicle(vehicle.id)) then
			return;
	    end
		for i = 1, 2 do
			local seat = vehicle.Seats and vehicle.Seats[i];	
			if (seat and seat.seat:GetWeaponCount() > 0) then
				local weaponId = seat.seat:GetWeaponId(1);
				if (weaponId) then
					local weapon = System.GetEntity(weaponId);
					if (weapon and weapon.weapon:GetClipSize() ~= -1) then
						local type = weapon.weapon:GetAmmoType();
						if (type) then
							ammo = {
								Type = type,
								Count = vehicle.inventory:GetAmmoCount(type),
							};
							break;
						end
					end
				end
			end
		end
		local ownerId = vehicle.vehicle:GetOwnerId();
		if (not profileId) then
			local owner = ownerId and nCX.GetPlayer(ownerId);
			if (owner) then
				profileId = owner.Info.ID;
			end
		end
		return {
			Name = vehicle:GetName(),
		    Pos = vehicle:GetPos(),
	        Dir = vehicle:GetDirectionVector(),
		    Class = vehicle.class,
		    Mod = vehicle.Properties.Modification,
			SpawnGroup = nCX.IsSpawnGroup(vehicle.id),
			BuyZone = g_gameRules.vehicleBuyZones and g_gameRules.vehicleBuyZones[vehicle.id];
			Bought = (ownerId and ownerId ~= NULL_ENTITY);
			TeamId = nCX.GetTeam(vehicle.id);
			Ammo = ammo,
			VehicleId = nCX.GetVehicleId(vehicle.id),
			OwnerId = profileId,
			Passengers = passengers,
			BuiltAs = vehicle.builtas,
		};
	end,
				
	SaveVehicles = function(self)
		self.Vehicles = {};
		local ents = System.GetEntities();
		if (ents) then
			for i, vehicle in pairs(ents) do
				if (vehicle.vehicle) then
					local ownerId = vehicle.vehicle:GetOwnerId();
					local owned = (ownerId and ownerId ~= NULL_ENTITY);
					local passengers = (vehicle.GetPassengers and vehicle:GetPassengers());
					local emptyRemote = vehicle:GetLastDriverId() and vehicle:GetDistance(vehicle:GetLastDriverId()) < 30;
					if (owned or passengers or emptyRemote) then
						local ids;
						for i, id in pairs(passengers or {}) do
							ids = ids or {};
							local channelId = nCX.GetChannelId(id);
							if (channelId > 0) then
								ids[i] = channelId;
							end
						end
						local data = self:GetVehicleData(vehicle, false, ids);
						if (data) then
							data.emptyRemote = emptyRemote;
							self.Vehicles[#self.Vehicles + 1] = data;
						end
					end
				end
			end
		end
    end,
	
    SaveData = function(self, refresh)
		if (refresh) then
			self.EnergyLevel = {};
			for i = 1, 2 do
				local energy = g_gameRules:GetTeamPower(i);
				if (energy ~= 0) then
					self.EnergyLevel[i] = energy; 
				end
			end
			self.Players = {};
		else
			self.Map = {nCX.GetCurrentLevel()};
		end
		for i, class in pairs(self.Entities) do
			local entities = System.GetEntitiesByClass(class);
			if (entities) then
				for i, entity in pairs(entities) do
					if (not entity.default) then
						local teamId = nCX.GetTeam(entity.id);
						if (teamId ~= 0) then
							self[class] = self[class] or {};
							self[class][i] = nCX.GetTeam(entity.id);
						end
					end
				end
			end
		end			
	    local players = nCX.GetPlayers();
	    if (players) then
			for i, player in pairs(players) do
			    self:SavePlayer(player);
		    end
		end
	    self:Write();
    end,

    RestoreData = function(self)
		local data = self:Read();
	    if (not data) then
	    	return 0;
	    end
		if (self.Map and self.Map[1] ~= nCX.GetCurrentLevel()) then -- if restore data map differs from current, cancel restore
			self.EnergyLevel = nil;
			self.Vehicles = nil;
			self.Players = {};
			for i, class in pairs(self.Entities) do
				self[class] = nil;
			end
			self:Write();
			return -1;
		end
		local c=0;
		if (self.EnergyLevel) then
			for teamId, energy in pairs(self.EnergyLevel) do
				g_gameRules:SetTeamPower(teamId, energy);
				c=c+1;
			end
		end
		for i, class in pairs(self.Entities) do
			local tbl = self[class];
			if (tbl) then
				for i, entity in pairs(System.GetEntitiesByClass(class) or {}) do
					if (not entity.default) then
						local teamId = tbl[i];
						if (teamId and teamId ~= nCX.GetTeam(entity.id)) then
							entity:Capture(teamId)
							c=c+1;
						end
					end
				end
			end
		end
	    return c;
    end,

	CanRestore = function(self, player, force)
	    local data = self.Players[player.Info.ID];
		if (not data) then
			return false, "no data found";
		end
		local e, msg = CryMP.Ent:InEnemyTerritory(player, data.Pos);
		if (e) then
			return false, msg
		elseif (not force and (not nCX.IsPlayerActivelyPlaying(player.id) or nCX.IsNeutral(player.id))) then
			return false, "player is dead or team is 0"
		end
		return data;
	end,
		
    RestorePlayer = function(self, player, ignore_equip, force)
		local i, msg = self:CanRestore(player, force);
		if (not i) then
			return false, msg;
		end
		local pos, dir, vehicle, energy, health, inventory = i.Pos, i.Dir, i.Vehicle, i.Energy, i.Health, i.Inventory;
		if (not nCX.Refresh) then
			local nearby = CryMP.Ent:IsVehicleNearby(pos);
			if (nearby) then
				pos = nearby:GetExitPos(1) or pos;
			end
		end
   		CryMP.Ent:MovePlayer(player, pos, dir);
		nCX.ParticleManager("misc.emp.sphere", 0.5, pos, g_Vectors.up, 0);
		
		nCX.SetInvulnerability(player.id, true, 2);
        player.actor:SetNanoSuitEnergy(energy);
       	player.actor:SetHealth(health);
        if (not ignore_equip) then
			CryMP.Ent:RestoreInventory(player, inventory)
		end
		self.Players[player.Info.ID] = nil;
	    return true;
    end,
		
	AddVehicle = function(self, data, player) -- no player if Refresh
		if (player) then
			nCX.SendTextMessage(0, "Restoring your "..CryMP.Ent:GetVehicleName(data.Class).."... please wait...", player.Info.Channel);
		end
		local team = { [1] = "nk", [2] = "us", };
		local teamId = player and nCX.GetTeam(player.id) or data.TeamId; 
		local respawn = {
			bAbandon = 0,
		};
		if (not data.Bought) then
			respawn.bAbandon = 1;
			respawn.nAbandonTimer = 40;
		end
		local params = {
			class = data.Class,
			position = {x=data.Pos.x, y=data.Pos.y, z=data.Pos.z+2},
			orientation = data.Dir,
			name = data.Name,
			vehicleId = data.VehicleId, 
			properties = {
				Modification = data.Mod,
				Paint = team[teamId or 0] or "us",
				Respawn = respawn,
			};
		};		
		CryMP:Spawn(params, function(vehicle, current)
			if (not vehicle) then	
				vehicle = current;
			end
			if (vehicle) then
				vehicle.builtas = data.BuiltAs;
				local nextTick = false;
				local player = player or (data.OwnerId and nCX.GetPlayerByProfileId(data.OwnerId));
				if (player) then
					vehicle.vehicle:SetOwnerId(player.id);
				end
				if (current and self.Vehicles) then
					if (not vehicle.Teleport) then
						System.LogAlways("=> keine vehicle teleport function.........");
						for s, c in pairs(vehicle) do
							System.LogAlways(tostring(s).." | "..tostring(c));
						end
					end
					vehicle:Teleport(data.Pos, data.Dir);
					nextTick = true;
				end
				if (teamId) then
					nCX.SetTeam(teamId, vehicle.id);
				end
				if (data.BuyZone and not vehicle.Properties.Buyzone) then
					g_gameRules:MakeBuyZone(vehicle, 13, 11);
					if (not data.SpawnGroup) then
						nCX.AddMinimapEntity(vehicle.id, 1, 0);
					end
				end
				if (data.SpawnGroup) then
					nCX.AddSpawnGroup(vehicle.id);
				end
				if (vehicle.vehicle:GetMovementType()=="air") then
					vehicle:AddImpulse(-1, vehicle:GetCenterOfMassPos(), {x=0, y=0, z=1}, 600000, 1);
					nextTick = true;
				end
				if (data.Ammo) then
					vehicle.vehicle:SetAmmoCount(data.Ammo.Type, data.Ammo.Count);
				end
				local enter = function()
					if (self.Vehicles) then
						if (data.Passengers) then
							for seatId, channelId in pairs(data.Passengers) do
								local passenger = nCX.GetPlayerByChannelId(channelId);
								if (passenger and nCX.IsPlayerActivelyPlaying(passenger.id)) then
									vehicle:EnterVehicle(passenger.id, seatId);
									CryMP.Ent:PlaySound(passenger.id,"lockpick");
								end
							end	
						end
					elseif (player) then	
						if (nCX.IsPlayerActivelyPlaying(player.id)) then		
							vehicle:EnterVehicle(player.id, 1); 
						else
							g_gameRules:RevivePlayer(player, vehicle.id);
						end
						CryMP.Ent:PlaySound(player.id,"lockpick");
						nCX.SendTextMessage(0, "Completed...", player.Info.Channel);
					end
				end
				if (nextTick) then
					CryMP:SetTimer(0, function() enter() end);	 -- next tick!
				else
					enter();
				end
			end
		end);
	end,
	
    FullRestore = function(self)
		local c = 10;
		for i = 10, 0, -1 do
			CryMP:SetTimer(i * 1, function()
				if (c==0) then
					local counter = {0,0,0};
					counter[1] = self:RestoreData();
					local vehicles = self.Vehicles;
					if (vehicles) then
						for i, data in pairs(vehicles) do
							self:AddVehicle(data);
							counter[2] = counter[2] + 1;
						end
					end
					local players = nCX.GetPlayers();
					for i, player in pairs(players or {}) do
						local restore, msg = self:RestorePlayer(player);
						if (restore) then	
							counter[3] = counter[3] + 1;
						end
					end					
					local msg= counter[3].." players, "..counter[2].." vehicles and "..counter[1].." server data recovered!";
					CryMP.Msg.Chat:ToAll(msg);
					self:Log(msg);
					System.LogAlways("[CryMP] "..msg);
					CryMP:SetTimer(1, function()					
						self.Vehicles = nil;
					end);
					nCX.Refresh = nil;
				else
					System.LogAlways("Refresh: "..c);
					nCX.SendTextMessage(0, "SYSTEM:RESTORE  : : :  in [ "..math:zero(c).." ] seconds  : : :  STAND:BY", 0);
				end
				c=c-1;
			end);
		end
    end,
	
	Initiate = function(self)
		nCX.Refresh = true;
		local c=5;
		for i = 5, 0, -1 do
			CryMP:SetTimer(i * 1, function()
				if (c == 0) then
					System.ExecuteCommand("sv_restart")
				else
					nCX.SendTextMessage(5, "<font size=\"32\"><b><font color=\"#b53b3b\">SYSTEM REFRESH  : : :  [ </font><font color=\"#828282\">00 : 0"..c.."<font color=\"#b53b3b\"> ]  : : :  STAND BY </font></b></font>", 0);
				end
				if (c == 2) then
					self:SaveVehicles();
					self:SaveData(true);
				end
				c=c-1;
			end);
		end
	end,
	
    Write = function(self)
	    local FileHnd, err = io.open(CryMP.Paths.ServerData.."Data_Refresh.lua", "w+");
		if (FileHnd) then
			local line = "CryMP.Refresh:SetData({"
			for name,value in pairs(self) do
				if (type(value)=="table" and name == "EnergyLevel" or name == "SpawnGroup" or name == "Factory" or name == "AlienEnergyPoint" or name == "Players" or name == "Vehicles" or name == "Map") then
					line = self:WriteTable(value, name, FileHnd, line);
				end
			end
			FileHnd:write(line.."});");
			FileHnd:close();
		else
			System.LogAlways("[Refresh] Error: No Data file found!");
		end
    end,

    SetData = function(self, tbl)
	    self.EnergyLevel = tbl.EnergyLevel;
	    self.Vehicles = tbl.Vehicles;
	    self.Players = tbl.Players;
		for i, class in pairs(self.Entities) do
			self[class] = tbl[class];
		end
    end,

    Read = function(self)
	    return require("Data_Refresh");
    end,

    WriteTable = function(self, tbl, name, file, line)
	    line = line..name.." = {";
	    for name,value in pairs(tbl) do
		    if (type(name) == "number") then
		    	name = "["..name.."]";
		    else
		    	name = "['"..name.."']";
		    end
		    if (type(value)=="table") then
		    	line = self:WriteTable(value, name, file, line);
		    elseif (type(value)=="string") then
		    	line = line..name.." = '"..value.."', ";
		    elseif(type(value)=="number") then
		    	line = line..name.." = "..value..", ";
		    elseif (type(value)=="boolean") then
			    if (value == true) then
			    	line = line..name.." = true, ";
			    else
			    	line = line..name.." = false, ";
			    end
		    end
	    end
	    line = line.."}, ";
	    return line;
    end,
	
};
