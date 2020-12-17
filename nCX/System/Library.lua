CryMP.Library = {
	
	---------------------------
	--		Config
	---------------------------
	Spawned 			= {},
	--GuardName 			= "SERVER:GUARD",
	GuardName			= "7Ox.BOT",
	
	Server = {
		
		OnDisconnect = function(self, channelId, player)
			self:RemoveSpawned(player.id);
		end,
		
		OnKill = function(self, hit, shooter, target)
			if (target.Info and target.Info.Channel == -2) then
				for adminId, v in pairs(self.Spawned) do
					if (v[target.id]) then
						CryMP:SetTimer(15, function()
							System.RemoveEntity(target.id);  -- remove bots 
							nCX.ParticleManager("explosions.rocket_terrain.exocet", 0.3, target:GetPos(), g_Vectors.up, 0);
						end);
						break;
					end
				end
			end
		end,
		
		OnVehicleSpawn = function(self, vehicle)
			if (vehicle and vehicle.ownerId) then
				vehicle.vehicle:SetOwnerId(vehicle.ownerId);
				vehicle.nCX:EnableInvulnerability(true);
				CryMP:SetTimer(3, function()
					vehicle.nCX:EnableInvulnerability(false);
				end);
			end
		end,
		
	
	},

	--[[
	OnInit = function(self)
		local guard = System.GetEntityByName(self.GuardName);
		if (guard) then
			System.RemoveEntity(guard.id);
		end
		local ep = {
			class = "Player",
			position = { 
				x = 2104.26, 
				y = 2010.67,
				z = 51,
			},
			orientation = {
				x = 1,
				y = -1,
				z = -2.59346,
			},
			name = self.GuardName;
		};
		local guard = System.SpawnEntity(ep);
		if (guard) then
			guard.Info = {
				Channel = -2,
				ID 		= "0",
				IP 		= "127.0.0.1",
				Host 	= "127.0.0.1-nigga.slowconnection.net",
				Name 	= self.GuardName,
				Port	= "1",
				Country = "Niggerania",
				Country_Short = "NI",
			};
			nCX.SetTeam(1, guard.id);
			nCX.Guard = guard;
			CryMP:SetTimer(1, function()
				nCX.SetTeam(0, guard.id);
				nCX.RevivePlayer(guard.id, ep.position, guard:GetWorldAngles(), false);  -- make it move
			end);
		end
	end,
	]]
	
	OnShutdown = function(self, restart) 
		self:RemoveSpawned();
	end,
	
	Capacity = function(self, player)
		if not (type(player)=="table" and player.actor) then
			return false, "player not found";
		end
		local tbl = {["avexplosive"] = "AVMine", ["c4explosive"] = "C4", ["claymoreexplosive"] = "Claymore",["flashbang"] = "",["smokegrenade"] = "",["explosivegrenade"] = "",["empgrenade"] = "",};
		for ammo, class in pairs(tbl) do
			player.inventory:SetAmmoCapacity(ammo, 2000);
			player.actor:SetInventoryAmmo(ammo, 2000, 3);
			if (#class > 0) then
				nCX.GiveItem(class, player.Info.Channel, false, true)
			end
		end
		player.actor:SelectItemByNameRemote("C4");
		nCX.Log("Player", "Increased Ammo Capacity of player "..player:GetName());
		self:Log("Increased Ammo Capacity of player "..player:GetName(), true);
	end,
	
	RemoveClass = function(self, class)
		if (not class) then
			return false, "specify class";
		end
		if (class:lower()=="player" or class:lower()=="spawnpoint") then
			return false, "you cannot remove "..class:lower().." class";
		end
		local ents = System.GetEntitiesByClass(class);
		if (ents) then
			for i, e in pairs(ents) do
				System.RemoveEntity(e.id);
			end
			nCX.Log("Core", "Removed "..#ents.." entities of class "..class, true);
			self:Log("Removed "..#ents.." entities of class "..class, true);
			return true;
		end
		return false, "entity class not found";
	end,

	RemoveSpawned = function(self, playerId)
		local count = 0;
		if (playerId) then
			local ids = self.Spawned[playerId];
			if (ids) then
				for entityId, c in pairs(ids) do
					if (System.GetEntity(entityId)) then
						System.RemoveEntity(entityId);
						count = count + 1;
					end
				end
				self.Spawned[playerId] = nil;
			end
			if (count > 0) then
				local name = System.GetEntity(playerId):GetName();
				nCX.Log("Core", "Removed "..count.." entities spawned by "..name, true);
				self:Log("Removed "..count.." entities spawned by "..name, true);
			end
		else
			local tbl = self.Spawned;
			for playerId, v in pairs(tbl) do
				for entityId, c in pairs(v) do
					if (System.GetEntity(entityId)) then
						System.RemoveEntity(entityId);
						count = count + 1;
					end
				end
				self.Spawned[playerId]=nil;
			end
			if (count > 0) then
				nCX.Log("Core", "Removed "..math:zero(count).." spawned entities");
				self:Log("Removed "..math:zero(count).." spawned entities");
			end
		end
		return count;
	end,
	
	RemoveEntity = function(self, id)
		local e = System.GetEntity(id);
		if (e) then
			System.RemoveEntity(e.id);
			nCX.Log("Core", "Removed entity with ID "..tostring(id));
			self:Log("Removed entities with ID "..tostring(id), true);
			return true;
		end
		return false, "entity ID not found";
	end,

	RemoveName = function(self, name)
		local e = System.GetEntityByName(name);
		if (e) then
			local class = e.class;
			System.RemoveEntity(e.id);
			nCX.Log("Core", "Removed entity of name "..name);
			return true;
		end
		return false, "entity name not found";
	end,

	Spawn = function(self, player, distance, class, mod)
		if not (player and player.actor) then
			return false, "player not found"
		elseif (not class) then
			return false, "specify a class";
		end
		if (class:match("US_.*") or class:match("Asian_.*") or class:match("Civ_.*")) then
			return self:SpawnVehicle(player, distance, class, mod)
		end
		distance = distance and tonumber(distance) or 10;
		if (class == "InteractiveEntity") then
			distance = distance - 5;
		end
		local pos, dir = self:CalcSpawnPos(player, distance);
		local ep = {
			class = class;
			position = pos;
			orientation = dir;
			name = class..tostring(self:SpawnCounter());
			properties = {bEnabled  = 1, bPhysics  = 1, },
		};		
		if (class == "GUI" and GUI) then
			ep.name = GUI.Properties.objModel;
		elseif (class == "InteractiveEntity") then
			local cpos = pos;
			cpos.z = cpos.z - 1.0;
			local hits;-- = Physics.RayWorldIntersection(cpos,g_Vectors.down,15,ent_terrain+ent_static+ent_rigid+ent_sleeping_rigid,player.id,nil,g_HitTable);
			if ( hits == 0 ) then
				System.LogAlways("not hit found: "..ep.position.z);
			else
				local firstHit = g_HitTable[1];
				if (firstHit) then
					--ep.position.z = firstHit.pos.z;
					--System.LogAlways("hit found: "..ep.position.z);
				end
			end	
		end
		local spawned = System.SpawnEntity(ep);
		if (spawned) then
			if (spawned.class == "Player") then
				local suits = {[1] = NANOMODE_CLOAK; [2] = NANOMODE_STRENGTH; [3] = NANOMODE_SPEED;};
				--spawned.actor:SetNanoSuitMode(suits[math.random(1, #suits)]);
				spawned.Info = {
					Channel = -2,
					ID = "0",
					IP = "0",
					Host = "0",
				};
				local c = {[1]=2,[2]=1,};
				local teamId = c[nCX.GetTeam(player.id)] or 2;
				nCX.SetTeam(teamId, spawned.id);
			elseif (spawned.class == "AlienTurret") then
				local physParam = {
					mass = 200,
				};
				CryAction.CreateGameObjectForEntity(spawned.id);
				CryAction.BindGameObjectToNetwork(spawned.id);
				CryAction.ForceGameObjectUpdate(spawned.id, true);
				spawned:Physicalize(0, PE_RIGID, physParam);
				spawned:AwakePhysics(1);
				local c = {[1]=2,[2]=1,};
				local teamId = c[nCX.GetTeam(player.id)] or 2;
				nCX.SetTeam(teamId, spawned.id);
			elseif (spawned.class == "InteractiveEntity") then
				local physParam = {
					mass = 200,
				};
				CryAction.CreateGameObjectForEntity(spawned.id);
				CryAction.BindGameObjectToNetwork(spawned.id);
				--CryAction.ForceGameObjectUpdate(spawned.id, true);
				--spawned:Physicalize(0, PE_RIGID, physParam);
				--spawned:AwakePhysics(1);
			elseif (spawned.class == "AutoTurret") then
				local physParam = {
					mass = 200,
				};
				spawned:Physicalize(0, PE_RIGID, physParam);
				CryAction.CreateGameObjectForEntity(spawned.id);
				CryAction.BindGameObjectToNetwork(spawned.id);
				spawned:AwakePhysics(1);
			end
			self.Spawned[player.id]=self.Spawned[player.id] or {};
			self.Spawned[player.id][spawned.id] = true;
			nCX.Log("Core", "Spawned entity of class "..class.." for player "..player:GetName());
			self:Log("Spawned class "..class.." for "..player:GetName(), true);
			return true, spawned;
		else
			return false, "spawn of "..class.." failed";
		end
	end,

	SpawnVehicle = function(self, player, distance, class, mod)
		if not (player and player.actor) then
			return false, "player not found"
		elseif (not class) then
			return false, "specify a class"
		end
		distance = distance and tonumber(distance) or 10;
		if (class == "Asian_helicopter" or class == "Asian_patrolboat") then
			distance = distance + 5;
		end
		if (not class:match("US_.*") and not class:match("Asian_.*") and not class:match("Civ_.*")) then
			return self:Spawn(player, distance, class)
		end
		local pos, dir = self:CalcSpawnPos(player, distance);
		pos.z = pos.z + 5;
		if (mod == "") then
			mod = "MP";
		end
		local ep = {
			class = class,
			position = pos,
			orientation = dir,
			name = class..tostring(self:SpawnCounter());
			properties = {
				Modification = mod or (class == "Asian_ltv" and "" or "MP"),
				Respawn = {
					bRespawn = 0,
					nTimer = 30,
					bUnique = 1,
					bAbandon = 0,
					nAbandonTimer = 0,
				};
			};
		};
		local teamId = nCX.GetTeam(player.id);
		if (teamId ~= 0 and g_gameRules.VehiclePaint) then
			ep.properties.Paint = g_gameRules.VehiclePaint[nCX.GetTeamName(teamId)] or "";
		end
		--[[if (CryMP.AFKManager) then
			local afk = CryMP.AFKManager;
			local truck = afk:GetVehicle();
			System.LogAlways(tostring(truck).."");
			if (truck and player:GetDistance(truck.id) < 20) then
				System.LogAlways("distance < 20");
				--if (truck:IsPointInsideArea(0, pos)) then
				--	return false, "spawning near afk truck is not allowed";
				--end
				return false, "spawning near afk truck is not allowed";
			end
		end	]]
		local entities = System.GetPhysicalEntitiesInBox(pos, 2); 
		if (entities) then
			for i, ent in pairs(entities) do
				if (ent.vehicle and ent.class == class) then
					return false, "vehicle near", CryMP.Ent:GetVehicleName(ent.class).." in front of you!"
				end
			end
		end	
		local spawned = nCX.Spawn(ep);
		local msg;
		local name=player:GetName();
		if (spawned) then	
			msg = "Spawned class "..class.." for "..name..((mod and " with mod "..mod) or "");
			self.Spawned[player.id]=self.Spawned[player.id] or {};
			self.Spawned[player.id][spawned.id] = true;
			spawned.ownerId = player.id;
		else
			msg = "Failed to spawn class "..class.." for "..name;
		end
		nCX.Log("Core", msg);
		self:Log(msg, true);

		return true;
	end,

	CalcSpawnPos = function(self, player, distance)
		--nCX.UpdateAreas(player.id); --update areas..
		distance = distance or 1.0;
		local pos = player:GetBonePos("Bip01 head");
		local dir = player:GetBoneDir("Bip01 head");
		math:ScaleVectorInPlace(dir, tonumber(distance));
		math:FastSumVectors(pos, pos, dir);
		dir = player:GetDirectionVector(1);
		return pos, dir;
	end,

	SpawnCounter = function(self)
		nCX.SpawnCounter = (nCX.SpawnCounter or 0) + 1;
		return nCX.SpawnCounter;
	end,

	Kill = function(self, player, count)
		if not (player and player.actor) then
			return false, "player not found"
		elseif (player.actor:GetSpectatorMode() ~= 0) then
		   return false, "player is spectating";
		elseif (player.actor:GetHealth()<=0) then
		   return false, "player is dead";
		end
		local c = tonumber(count) or 1;
		c = math.max(1, math.min(200, c));
		local name = player:GetName();
		local deaths = (nCX.GetSynchedEntityValue(player.id, 101) or 0);
		for i=1, c do
		   CryMP:DeltaTimer(i, function()
				g_gameRules:KillPlayer(player, true, nCX.Guard);
				nCX.SendTextMessage(0, "Killing player "..name.." [ "..i.." ] times!", 0);
				deaths = deaths + 1;
				nCX.SetSynchedEntityValue(player.id, 101, deaths);
				if (i == c) then
					if (CryMP.Equip) then
						CryMP.Equip:Purchase(player, true);
					end
				end
		   end);
		end
		--local deaths = (nCX.GetSynchedEntityValue(player.id, 101) or 0) + c;
		--nCX.SetSynchedEntityValue(player.id, 101, deaths);
		self:Log("Killed player "..name.." "..c.." times");
		nCX.Log("Player", "Killed player "..name.." "..c.." times.");
		return true;
	end,

	Time = function(self, mapTime)
		if(tonumber(mapTime)) then
			System.SetCVar("g_timelimit", mapTime);
			nCX.ResetGameTime();
			self:Log("New time limit set to "..mapTime);
			nCX.Log("Core", "New time limit set to "..mapTime);
			return true;
		end
		return false, "invalid time specified";
	end,

	Team = function(self, player, teamId, auto)
		if not (player and player.actor) then
			return false, "player not found"
		end
		local currentId = nCX.GetTeam(player.id);
		teamId = teamId and tonumber(teamId);
		if (teamId) then
			if (teamId == currentId) then
				return false, "already on specified team"
			elseif (teamId == 3) then
				teamId = 0;
			end
		else
			if (nCX.IsNeutral(player.id)) then
				teamId = g_gameRules:AutoAssignTeam(player.id)
			else
				teamId = currentId == 1 and 2 or 1;
			end
		end
		local afk = CryMP.AFKManager;
		if (afk and afk:IsAfk(player)) then
			afk:Disable(player, false, true);
		end
		local alive = nCX.IsPlayerActivelyPlaying(player.id);
		if (alive and teamId ~= 0) then
			-- bugged atm.. maybe not?
			if (g_gameRules.class == "PowerStruggle" and (auto or (not player:IsOnVehicle() and ((not CryMP.Ent:InEnemyTerritory(player, player:GetPos(), teamId) and not CryMP.Ent:IsLastExitedVehicleOwner(player)) or player:GetAccess() > 1)))) then
				player.actor:SetPhysicalizationProfile("ragdoll"); --trigger a physicalization
				g_gameRules.Server.OnChangeTeam(g_gameRules, player, teamId, true);
				local zoneId = g_gameRules.inCaptureZone and g_gameRules.inCaptureZone[player.id];
				local zone = zoneId and System.GetEntity(zoneId);
				if (zone and zone.Server and zone.Server.OnLeaveArea) then
					zone.Server.OnLeaveArea(zone, player, false);
				end
				nCX.RevivePlayer(player.id, player:GetWorldPos(), player:GetWorldAngles(), false);
				if (zone and zone.Server and zone.Server.OnEnterArea) then
					zone.Server.OnEnterArea(zone, player, false);
				end
			else
				g_gameRules:KillPlayer(player);
				alive = false;			
			end
			--g_gameRules:KillPlayer(player);
			--alive = false;	
		end
		if (teamId == 0) then
			nCX.OnChangeSpectatorMode(player.id, 1, NULL_ENTITY, true, false);
		elseif (not alive) then
			nCX.SetTeam(teamId, player.id);
			if (g_gameRules.QueueRevive) then
				g_gameRules:QueueRevive(player);
			else
				g_gameRules:RevivePlayer(player);
			end
			if (CryMP.AutoBalance) then
				CryMP.AutoBalance.Changed[player.Info.Channel] = _time;
			end
		end
		if (not auto) then
			local name = player:GetName();
			local team = CryMP.Ent:GetTeamName(teamId):upper();
			nCX.SendTextMessage(2, "[ TEAM:CHANGE ] Moved player "..name.." to team "..team, 0);
			self:Log("Moved player "..name.." to team "..team);
			nCX.Log("Player", "Moved player "..name.."  to team "..team);
		end
		return true;
	end,

	Give = function(self, player, itemName, nolog)
		if (not itemName) then
			return false, "specify item"
		end
		local teamId = player and tonumber(player);
		local function give(player)
			local name = player:GetName();
			--[[
			local ok = player.actor:CheckInventoryRestrictions(itemName);
			if (not ok) then
				local current = player.inventory:GetCurrentItem()
				if (current and not CryMP.Ent:IsDefaultEquip(current.class)) then
					player.actor:DropItem(current.id);
				else 
					local last = player.inventory:GetLastItem();
					if (last) then
						player.actor:SelectItemByNameRemote(last.class)
					end
					return false, "inventory full"
				end
			end
			]]
			local boosted;
			local itemId = player.inventory:GetItemByClass(itemName);
			local item = CryMP:GiveItem(player, itemName);
			if (itemId) then	
				player.actor:SelectItemByNameRemote(itemName)
			end
			if (item) then
				if (not nolog) then
					CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "ITEM : [ "..item.class.." ]-RECEIVED"); 
					self:Log("Equipped player "..name.." with "..item.class, true);
					nCX.Log("Player", "Equipped player "..name.." with "..item.class);
				end
				return true;
			elseif (itemId) then
				local item = System.GetEntity(itemId);
				if (item and item.weapon) then
					local clipSize = item.weapon:GetClipSize();
					local clipCount = item.weapon:GetAmmoCount();
					local type = item.weapon:GetAmmoType();
					if (type) then
						if (clipSize > 0 and clipSize ~= clipCount) then
							item.weapon:SetAmmoCount(type, clipSize);
							boosted = true;
						end
						local count = player.inventory:GetAmmoCount(type) or 0;
						local capacity = player.inventory:GetAmmoCapacity(type) or 0;
						if (capacity > 0 and count ~= capacity) then
							player.actor:SetInventoryAmmo(type, capacity, 3);
							boosted = true;
						end
					end
				end
			end
			if (boosted) then
				CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "ITEM : [ "..itemName.." ]-AMMO:BOOST"); 
				self:Log("Boosted ammo clip of "..name.."'s "..itemName);
				nCX.Log("Player", "Boosted ammo clip of "..name.."'s "..itemName);
				return true;
			else
				self:Log("Failed to equip "..name.." with "..itemName, true);
				nCX.Log("Player", "Failed to equip "..name.." with "..itemName);
				return false, "arming of "..name.." with item '"..itemName.."' failed";
			end
		end
		if (not teamId) then
			if not (player and player.actor) then
				return false, "player not found"
			end
			return give(player)
		else
			local players = teamId == 3 and nCX.GetPlayers() or nCX.GetTeamPlayers(teamId);
			if (not players) then
				return false, "no players of specified team"
			end
			for i, player in pairs(players) do
				give(player)
			end
			return true;
		end
	end,

	Pay = function(self, player, pp, cp, nolog)
		if (not g_gameRules.AwardPPCount or not g_gameRules.AwardCPCount) then
			return false, "only powerstruggle"
		end
		local teamId = player and tonumber(player);
		pp = pp and tonumber(pp) or 0;
		cp = cp and tonumber(cp) or 0;
		if (not teamId) then
			if not (player and player.actor) then
				return false, "player not found"
			end
			g_gameRules:AwardPPCount(player.id, pp);
			g_gameRules:AwardCPCount(player.id, cp);
			if (not nolog) then
				local name = player:GetName();
				self:Log("Awarded player "..name.." with "..pp.." PP and "..cp.." CP", true);
				nCX.Log("Player", "Awarded player "..name.." with "..pp.." PP and "..cp.." CP");
			end
		else
			local players = teamId == 3 and nCX.GetPlayers() or nCX.GetTeamPlayers(teamId);
			if (not players) then
				return false, "no players of specified team"
			end
			for i, player in pairs(players) do
				g_gameRules:AwardPPCount(player.id, pp);
				g_gameRules:AwardCPCount(player.id, cp);
			end
			if (not nolog) then
				local teamName = CryMP.Ent:GetTeamName(teamId) or "ALL";
				self:Log("Awarded "..teamName.." with "..pp.." PP and "..cp.." CP");
				nCX.Log("Player", "Awarded "..teamName.." with "..pp.." PP and "..cp.." CP");
			end
		end
		return true;
	end,

};
