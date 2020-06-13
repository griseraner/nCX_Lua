CryMP.Ent = {
		
	Lookup = function(self, player)
		local name = player:GetName();
		local i = player.Info;
		local profileId = i.ID;
		local d = (CryMP.PermaScore and CryMP.PermaScore.Players[profileId]) or {Name = player:GetName(), Level = "N/A", PlayTime = 0};
		local rank = CryMP.PermaScore and CryMP.PermaScore:GetRank(profileId) or "N/A";
		local playh, playm = CryMP.Math:ConvertTime(d.PlayTime, 60);
		local r_playh, r_playm = CryMP.Math:ConvertTime(player:GetPlayTime(true), 60);
		local ping = nCX.GetPing(i.Channel);
		local limit = System.GetCVar("nCX_HighPingLimit");
		local color = "$5";
		local warn = ping >= limit and "$4" or color;
		local tbl = {
			{"Name",      name},
			{"Alias",    (d.Name~=name and d.Name) or nil},
			{"Access",    "$7"..CryMP.Users:GetMask(profileId)},
			{"Channel",   i.Channel},
			{"Ping",      warn..ping},
			{"IP",        i.IP},
			{"Domain",    i.Host, #i.Host},
			{"ID",        profileId},
			{"Country",   i.Country or color.."N/A"},
			{"Setup",    (i.Controller and "$4Controller") or "$9Keyboard"},
			{"Last Seen", CryMP.Math:DaysAgo(d.LastSeen, true)},
			{"Game Time", "$7"..math:zero(r_playh).."$9h:$7"..math:zero(r_playm).."$9m"},
			{"Play Time", math:zero(playh).."$9h:"..color..math:zero(playm).."$9m"},
			{"Level",     d.Level},
			{"Rank",      "$9#"..color..rank},
		};
		local tmp = {};
		local header = "$9================================================================================================================";
		local space = tbl[7][3] or 30;
		space = math.max(space, 30);
		tmp[#tmp + 1] = header;
		for i, data in pairs(tbl) do
			local what, info = data[1], data[2];
			if (info) then
				local add = "";
				if (i == 1) then
					add = (" "):rep(81-space).."[ $5LOOKUP $9]";
				end
				tmp[#tmp + 1] = ("$9[%s | "..color.."%s $9]"..add):format(string:lspace(15, what), string:rspace(space, info));
			end
		end
		tmp[#tmp + 1] = header;
		return tmp, space;
	end,
		
	GetPlayerSpawnGroup = function(self, playerId)
		local spawnGroupId = g_gameRules:GetPlayerSpawnGroup(playerId);
		if (spawnGroupId and spawnGroupId~=NULL_ENTITY and nCX.IsSameTeam(playerId, spawnGroupId)) then
			return spawnGroupId;
		end
	end,
	
	Revive = function(self, player, inventory, default, clearInventory, pos)
		if (g_gameRules.GetPlayerSpawnGroup and g_gameRules.Server.RequestSpawnGroup) then
			local spawnGroupId = self:GetPlayerSpawnGroup(player.id);
			if (not spawnGroupId or default) then
				spawnGroupId = nCX.GetTeamDefaultSpawnGroup(nCX.GetTeam(player.id));
				g_gameRules.Server.RequestSpawnGroup(g_gameRules, player.id, spawnGroupId or NULL_ENTITY, true);
			end
		end
		g_gameRules:RevivePlayer(player, pos, not clearInventory);
		if (inventory) then
			self:RestoreInventory(player, inventory);
		end
	end,
	
	Portal = function(self, player)
		local HQ = g_gameRules.hqs and g_gameRules.hqs[nCX.GetTeam(player.id)] or g_gameRules.hqs[1];
		if (HQ) then
			local bpos = HQ:GetWorldPos();
			local bpos = {x = bpos.x, y = bpos.y, z = bpos.z + 9.5};
			local pos = player:GetWorldPos();
			nCX.SetInvulnerability(player.id, true, 3);
			nCX.ParticleManager("misc.emp.sphere", 0.5, {pos.x, pos.y, pos.z + 1}, g_Vectors.up, 0);
			CryMP:SetTimer(0, function()
				self:MovePlayer(player, bpos, player:GetWorldAngles());
				nCX.ParticleManager("misc.emp.sphere", 0.5, {bpos.x, bpos.y, bpos.z + 1.5}, g_Vectors.up, 0);
				CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "Teleport to BASE complete!", 1);
			end);
			return true;
		end
	end,	
		
	GetFactory = function(self, teamId)
		if (g_gameRules.factories) then
			for i, factory in pairs(g_gameRules.factories) do
				if (nCX.IsSameTeam(factory.id, teamId)) then
					return factory;
				end
			end
			return g_gameRules.factories[1];
		end
	end,
	
	GetZoneType = function(self, zone)
		local props = zone.Properties;
		if (props.szName == "air" or props.szName == "prototype") then
			return props.szName;
		elseif (props.szName == "war") then
			if (props.Vehicles:find("tank")) then
				return "big:war";
			elseif (not props.Vehicles:find("boat")) then
				return "small:war";
			end
		end
	end,
			
	GetPlayer = function(self, identifier, spec)
		local player;
		local value = tonumber(identifier);
		if (value) then
			return nCX.GetPlayerByChannelId(value) or nCX.GetPlayerByProfileId(identifier);
		elseif (type(identifier)=="string") then
			local target = nCX.GetPlayerByPartialName(identifier);
			if (spec and spec.actor and identifier=="-") then
				local specId = spec.actor:GetSpectatorTarget();
				if (specId) then
					return nCX.GetPlayer(specId);
				end
			end
			return target;
		end
	end,

	GetPlayersCount = function(self)
		return nCX.GetPlayerCount() - nCX.GetSpectatorCount();
	end,

	GetTeamName = function(self, teamId)
		if (not teamId) then
			return "N/A";
		end
		local c={	
			[1]="NK",
			[2]="US",
			[0]="Neutral",
		};
		return c[teamId];
	end,

	GetEnemyTeam = function(self, playerTeam)
		if (playerTeam) then
			local switch = { [1] = 2, [2] = 1, };
			return nCX.GetTeamPlayers(switch[tonumber(playerTeam) or 1]);
		end
	end,

	DumpInventory = function(self, player)
		if (player and player.inventory) then
			local inventory;
			for i, itemId in pairs(player.inventory:GetInventoryTable() or {}) do
				local item = System.GetEntity(itemId);
				if (item and item.weapon) then
					local type = item.weapon:GetAmmoType();
					if (type and item.class ~= "OffHand") then
						local capacity = player.inventory:GetAmmoCapacity(type);
						if (capacity > 0) then
							inventory = inventory or {};
							inventory[#inventory + 1] = item.class;
						end
					end
				end
			end
			local ammo = {"flashbang","smokegrenade","explosivegrenade","empgrenade",};
			local tmp = {};
			for i, name in pairs(ammo) do
				local count = player.inventory:GetAmmoCount(name) or 0;
				if (count ~= 0) then
					tmp[name] = count;
				end
			end
			return {inventory, tmp};
		end
	end,
	
	RestoreInventory = function(self, player, inventory)
		if (inventory and type(inventory) == "table") then	
			for i, class in pairs(inventory[1] or {}) do
				local itemId = CryMP:GiveItem(player, class) or nCX.GiveItem(class, player.Info.Channel, false, true);
			end
			for ammo, count in pairs(inventory[2] or {}) do
				player.actor:SetInventoryAmmo(ammo, count, 3);
			end
		elseif (CryMP.Equip) then
			CryMP.Equip:Purchase(player, true);
		end			
	end,
	
	IsDefaultEquip = function(self, class)
		local default = { 
			["AlienCloak"] = true,
			["OffHand"] = true,
			["Fists"] = true,
			["Binoculars"] = true,
			["Parachute"] = true,
		};
		return default[class] or false;
	end,
	
	SpawnObject = function(self, params)
		--if (not params or not params.objModel or not params.position) then
		--	System.LogAlways("[Error] Cannot spawn Object, wrong configuration (need objModel and position)");
	--		return;
	--	end
		CreateItemTable("CustomAmmoPickup");
		CustomAmmoPickup.Properties.objModel=params.objModel; 
		CustomAmmoPickup.Properties.bPhysics = params.bPhysics or 0;
		CustomAmmoPickup.Properties.nCX_OnItemPickEvent = params.nCX_OnItemPickEvent == nil and 0 or 1;
		CustomAmmoPickup.Properties.fMass = params.fMass or 0;
		CustomAmmoPickup.Properties.AmmoName="GeomEntity";
		CustomAmmoPickup.Properties.Count=30;
		CustomAmmoPickup.Properties.bUsable=nil;
		CustomAmmoPickup.Properties.bPickable=nil;
		return System.SpawnEntity{
			class = "CustomAmmoPickup"; 
			name = "7Ox_OBJECT."..(params.name or "").."#"..CryMP.Library:SpawnCounter(); 
			orientation = params.orientation or g_Vectors.up;
			position = params.position;
		};
	end,
			
	SpawnTrigger = function(self, params, vehicle, debug)
		local temp = {x = 0, y = 0, z = 0,};
		local pos = params.pos or temp;
		local dir = params.dir or temp;
		local dim = params.dim or {x = 5, y = 5, z = 5,};
		local class = params.class or "ActionTrigger";
		local name = class.."_"..params.name..CryMP.Library:SpawnCounter();
		local ep = {
			class = class,
			position = pos,
			orientation = dir,
			name = name,
			properties = {
				DimX = dim.x or dim[1],
				DimY = dim.y or dim[2],
				DimZ = dim.z or dim[3],
				Debug = debug,
				Vehicle = vehicle and vehicle.id,
			},
		};
		if (math:IsNullVector(dir)) then 
			ep.orientation.x = 1;
		end
		local trigger = System.GetEntityByName(name);
		if (trigger) then
			System.RemoveEntity(trigger.id);
			nCX.Log("Core", "Removing "..name.." (respawning)", true);
		end
		local trigger = System.SpawnEntity(ep);
		if (trigger) then
			trigger:SetWorldAngles(dir);
			trigger:SetWorldPos(pos);			
			if (type(vehicle) == "table") then
				vehicle:AttachChild(trigger.id, 0);
				trigger:ForwardTriggerEventsTo(vehicle.id);
			end
			trigger:OnReset();
			nCX.Log("Core", "Spawned "..name);
			return trigger;
		else
			nCX.Log("Core", "Failed to spawn "..name, true);
		end
	end,	
	
	IsLastExitedVehicleOwner = function(self, player)
		local vehicleId, time = player.actor:GetLastVehicle();
		if (vehicleId) then
			local vehicle = System.GetEntity(vehicleId);
			return vehicle and vehicle.vehicle:GetOwnerId() == player.id
		end
	end,
	
	GetOwnerVehicleInSphere = function(self, player, radius)
		local ents = System.GetEntitiesInSphere(player:GetPos(), radius and tonumber(radius) or 50);
		for i, ent in pairs(ents) do
			if (ent.vehicle and ent.vehicle:GetOwnerId() == player.id) then
				return ent;
			end
		end
	end,
		
	IsVehicleNearby = function(self, pos, radius)
		local ents = System.GetEntitiesInSphere(pos, radius or 10);
		for i,e in pairs(ents) do
			if (e.vehicle) then
				return e;
			end
		end
		return false;
	end,

	IsPosInZone = function(self, pos)
		local radius = 40;
		local factory = System.GetNearestEntityByClass(pos, radius, "Factory");
		if (factory) then
			local buyAreaId = factory.Properties.buyAreaId;
			if (buyAreaId and factory:IsPointInsideArea(buyAreaId, pos)) then
				return true;
			end
			for i = 1, factory.slotCount do
				local slot = factory.slots[i];
				local gateId = slot and slot.enabled and slot.vehicleAreaId;	
				if (gateId and factory:IsPointInsideArea(gateId, pos)) then
					return true;
				end
			end
		end
		local bunker = System.GetNearestEntityByClass(pos, radius, "SpawnGroup");
		if (bunker) then
			local buyAreaId = bunker.Properties.buyAreaId;
			if (buyAreaId and bunker:IsPointInsideArea(buyAreaId, pos) and not bunker.actor and not bunker.vehicle) then
				return true;
			end	
		end
		return false;
	end,
	
	GetVehicleName = function(self, class)
		local convert = {
			["US_vtol"] = "VTOL",
			["US_tank"] = "Tank",
			["US_smallboat"] = "Boat",
			["US_ltv"] = "Jeep",
			["US_hovercraft"] = "Hovercraft",
			["US_asv"] = "ASV",
			["US_apc"] = "APC",
			["Asian_truck"] = "Truck",
			["Asian_tank"] = "Tank",
			["US_trolley"] = "Trolley",
			["Asian_patrolboat"] = "Patrol-Boat",
			["Asian_helicopter"] = "Helicopter",
			["Asian_apc"] = "APC",
			["Asian_aaa"] = "Anti-Aircraft",
			["Civ_car1"] = "Car",
			["Civ_speedboat"] = "Speedboat",
			["Asian_ltv"] = "Jeep",
		};
		return convert[class or ""] or "N/A"
	end,
	
	IsEnemyNear = function(self, player, distance, enemy, pos)
		local ents = System.GetEntitiesInSphereByClass(pos or player:GetWorldPos(), distance, "Player");
		if (ents) then
			for i, e in pairs(ents) do
				if (nCX.IsPlayerActivelyPlaying(e.id)) then
					if (enemy and not nCX.IsSameTeam(e.id, player.id)) or (e.id ~= player.id) then
						return true;
					end
				end
			end
		end
		return false;
	end,
	
	InEnemyTerritory = function(self, entity, pos, teamId)
		pos = pos or entity:GetPos();
		local turret = System.GetNearestEntityByClass(pos, 150, "AutoTurret");
		if (turret and ((teamId and nCX.GetTeam(turret.id) ~= teamId) or not nCX.IsSameTeam(turret.id, entity.id))) then
			return true, "turret";
		end
		if (entity.actor) then
			local truck = System.GetEntityByName("AFK_TRUCK");
			if (truck and math:GetWorldDistance(truck:GetPos(), pos) < 150) then
				return true, "truck";
			end
		end
		return false;
	end,
	
	GetDisconnectReason = function(self, cause)
	    local list = {   
			[0] = "Timeout",
			[1] = "Protocol Error",
			[2] = "Failed to resolve address",
			[3] = "Version mismatch",
			[4] = "Server is full",
			[5] = "Kicked from server",
			[6] = "Banned from server",
			[7] = "Context database mismatch",
			[8] = "Password mismatch",
			[9] = "Not logged into GameSpy",
			[10] = "CD Key check failed",
			[11] = "Game Error",
			[12] = "DX10 not found",
			[13] = "Server shutdown",
			[14] = "ICMP Reported error",
			[15] = "NAT Error",
			[16] = "Files mismatch",
			[19] = "User Disconnected",
			[20] = "Controller needed",
			[21] = "Unable to connect",
			[22] = "Mod mismatch",
			[23] = "Map not found",
			[24] = "Map mismatch",
		    [25] = "Punkbuster required",
		    [26] = "New map required",
		    [27] = "Unknown",
	   };
	    local reason = list[cause];
		return reason, (cause==5 or cause==6);
	end,

	MovePlayer = function(self, player, pos, dir, destroyEquip)
		if (not nCX.IsPlayerActivelyPlaying(player.id)) then
			if (g_gameRules.class=="PowerStruggle") then
				if (nCX.IsNeutral(player.id) and g_gameRules.Server.RequestSpawnGroup) then
					local teamId = g_gameRules:AutoAssignTeam(player.id);
					g_gameRules.Server.RequestSpawnGroup(g_gameRules, player.id, nCX.GetTeamDefaultSpawnGroup(teamId) or NULL_ENTITY, true);
				end
			end
			g_gameRules:RevivePlayer(player, pos, not destroyEquip);
			return;
		end
		local vehicle = player.actor:GetLinkedVehicle();
		if (vehicle) then
			player.serverSeatExit = true;
			vehicle.vehicle:ExitVehicle(player.id);
			CryMP:DeltaTimer(10,function() 
				nCX.MovePlayer(player.id, pos, dir);
			end);
		else
			nCX.MovePlayer(player.id, pos, dir);
		end
	end,

	PlaySound = function(self, playerId, sound, rank)
		if (playerId) then
			local channelId = nCX.GetChannelId(playerId);
			if (channelId > 0) then
				local teamId = nCX.GetTeam(playerId);
				local PS = g_gameRules.class == "PowerStruggle";
				if (sound=="lockpick" or sound=="repair") then
					g_gameRules.onClient:ClWorkComplete(channelId, playerId, sound);
				elseif (PS and sound=="confirm") then
					g_gameRules.onClient:ClBuyOk(channelId, "");
				elseif (PS and sound=="error") then
					g_gameRules.onClient:ClBuyError(channelId, "");
				elseif (PS and sound=="promote") then
					g_gameRules.onClient:ClRank(channelId, rank or g_gameRules:GetPlayerRank(playerId) + 1, true);
				elseif (PS and sound=="demote") then
					g_gameRules.onClient:ClRank(channelId, rank or g_gameRules:GetPlayerRank(playerId) + 1, false);
				elseif (sound=="win") then
					g_gameRules.onClient:ClVictory(channelId, teamId, 3, playerId);
				elseif (sound=="lose") then
					local convert = { [1] = 2, [2] = 1, };
					g_gameRules.onClient:ClVictory(channelId, convert[teamId] or 2, 3, playerId);
				elseif (PS and sound=="perimeter") then
					g_gameRules.onClient:ClPerimeterBreached(channelId, playerId);
				elseif (sound=="timer2m") then
					g_gameRules.onClient:ClTimerAlert(channelId, 120, teamId);
				elseif (sound=="timer1m") then
					g_gameRules.onClient:ClTimerAlert(channelId, 60, teamId);
				elseif (sound=="timer30s") then
					g_gameRules.onClient:ClTimerAlert(channelId, 30, teamId);
				elseif (sound=="timer5s") then
					g_gameRules.onClient:ClTimerAlert(channelId, 5, teamId);
				elseif (PS and sound=="alert") then
					g_gameRules.onClient:ClMDAlert(channelId, "");
				elseif (PS and sound=="hq") then
					g_gameRules.onClient:ClHQHit(channelId, playerId);
				elseif (sound=="work") then
					g_gameRules.onClient:ClStartWorking(channelId, playerId, "repair");
					g_gameRules.onClient:ClStopWorking(channelId, playerId, true);
				end
			end
		end
	end,
	
	Rename = function(self, player, name, reason)
		if (name and #name > 2) then
			if (reason == "user descision" and (name == "!name" or System.GetEntityByName(name) or nCX.IsClassAvailable(name))) then
				return false, "invalid name", "Please chose a valid name!";
			end
			local reason = reason or "server descision";
			local previous = player:GetName();
			local access = player:GetAccess();
			local quit, player, name, newReason = CryMP:HandleEvent("OnNameChange", {player, name, reason});
			reason = newReason ~= "tag" and newReason or reason;
			if (quit) then
				return false, reason;
			end
			nCX.RenamePlayer(player.id, name);
			self:Log("Renamed player "..previous.." to "..name.." ($4"..reason.."$9)");
			return true;
		else
			return false, "name too short", "Minimum 3 characters!";
		end
	end,
	
	HasTag = function(self, name, tag)
		local saneTag = tag:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1");
		local saneName = name:lower():gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1");
		if (saneName:find(saneTag)) then
			return true;
		elseif (name:find(saneTag)) then
			return true;
		end
		return false;
	end,
	
	RemoveTag = function(self, name, tag, playerId)
		local newname = name:gsub(tag:gsub("[%[%]%^%$%(%)%%%.%*%+%-%?]", "%%%1"), "");
		if (not playerId) then
			return newname;
		end
		if (newname ~= name) then
			nCX.RenamePlayer(playerId, newname);
		end
		return newname;
	end,
	
	CheckName = function(self, name, playerId)
		if (not name) then
			return;
		end
		local tags = {"[AFK]-", "[MUTE]-", "<censored>",};
		for i, tag in pairs(tags) do
			name = self:RemoveTag(name, tag);
		end
		for i, tag in pairs( {"admin", "[7Ox] ", "70x"} ) do
			name = self:RemoveTag(name, tag);
		end
		return self:RemoveTag(name, "[VIP]", playerId);
	end,
	
	IsSmallMap = function(self, name)
		local name = name or nCX.GetCurrentLevel():sub(16, -1):lower();
		local smallMaps = {
			["plantation"] = true,
			["refinery"] = true,
			["desolation"] = true,
			["frost"] = true,
			["training"] = true,
		};
		return smallMaps[name];
	end,
	
};
