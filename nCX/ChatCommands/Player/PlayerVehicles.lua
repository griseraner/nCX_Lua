--===================================================================================
-- BUYZONE

CryMP.ChatCommands:Add("buyzone", {
		Info = "mount a buyzone to your vehicle", 
		InGame = true,
		Price = 700,
		Delay = 300,
		Access = 1,
		Map = {"ps/(.*)"},
		BigMap = true,
	}, 
	function(self, player, channelId)
		if (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		elseif (player:IsBoxing()) then
			return false, "not while boxing"
		elseif (player:IsRacing()) then
			return false, "not while racing"
		elseif (player:IsAfk()) then
			return false, "not while afk"
		end
		local vehicle = player.actor:GetLinkedVehicle();
		if (not vehicle) then
			local vehicleId, time = player.actor:GetLastVehicle();
			vehicle = vehicleId and System.GetEntity(vehicleId);
			if (not vehicle) then
				return false, "you must be inside vehicle", "You must be inside a vehicle!"
			end
		end
		vehicle.vehicle:KillAbandonTimer();
		if (g_gameRules:MakeBuyZone(vehicle, 13, 13)) then
			local class = CryMP.Ent:GetVehicleName(vehicle.class);
			CryMP.Msg.Chat:ToPlayer(channelId, "[+] >> BUY:ZONE enabled on this "..class.."!", 17);
			nCX.ParticleManager("expansion_fx.weapons.emp_grenade", 0.6, vehicle:GetPos(), g_Vectors.up, 0);
			CryMP.Ent:PlaySound(player.id, "lockpick");
			CryMP.Msg.Chat:ToTeam(nCX.GetTeam(player.id), "Player : "..player:GetName().." created a Buy-Zone on "..class.."!");
			return true;
		end 
		return false, "already a buyzone", "This vehicle already got a Buy-Zone!";
	end
);

--===================================================================================
-- SPAWNZONE

CryMP.ChatCommands:Add("spawnzone", {
		Info = "mount a spawnzone to your vehicle", 
		InGame = true,
		Price = 700,
		Delay = 500,
		Access = 0,
		Map = {"ps/(.*)"},
		BigMap = true,
	}, 
	function(self, player, channelId)
		if (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		elseif (player:IsBoxing()) then
			return false, "not while boxing"
		elseif (player:IsRacing()) then
			return false, "not while racing"
		elseif (player:IsAfk()) then
			return false, "not while afk"
		end
		local vehicle = player.actor:GetLinkedVehicle();
		if (not vehicle) then
			return false, "you must be inside vehicle", "You must be inside a vehicle!"
		end
		if (not nCX.IsSpawnGroup(vehicle.id)) then
			vehicle.vehicle:KillAbandonTimer();
			nCX.AddSpawnGroup(vehicle.id);
			local class = CryMP.Ent:GetVehicleName(vehicle.class);
			CryMP.Msg.Chat:ToPlayer(channelId, "[+] >> SPAWN:ZONE enabled on this "..class.."!", 17);
			CryMP.Ent:PlaySound(player.id, "lockpick");
			CryMP.Msg.Chat:ToTeam(nCX.GetTeam(player.id), "Player : "..player:GetName().." created a Spawn-Zone on "..class.."!");
			nCX.AbortEntityRemoval(vehicle.id);
			return true;
		end 
		return false, "already a spawn zone", "This vehicle already got a Spawn-Zone!";
	end
);

--==============================================================================
--!REPAIR

CryMP.ChatCommands:Add("repair", {
		Info = "repair your vehicle",
		Price = "N/A",
		self = "Repair",
		Delay = 250,
	},
	function(self, player, channelId)
		if (player:IsRacing()) then
			return false, "not while racing"
		end
		return self:Fix(player);
	end
);

--==============================================================================
--!LOCK

CryMP.ChatCommands:Add("lock", {
		Info = "toggle lock on your vehicle",
		InGame = true,
		self = "Vehicles",
	},
	function(self, player, channelId)
		return self:Lock(player);
	end
);

--==============================================================================
--!OUT [PLAYER]

CryMP.ChatCommands:Add("out", {
		Args = {
			{"player", Optional = true, GetPlayer = true,},
		},
		Info = "remove one or all players from your vehicle",
		InGame = true;
		self = "Vehicles",
	}, 
	function(self, player, channelId, target)
		return self:Out(player, target);
	end
);

--===================================================================================
-- TAXI

CryMP.ChatCommands:Add("taxi", {
		Info = "drop a taxi from the sky", 
		InGame = true,
		--Price = 25,
		--Delay = 10,
		--Map = {"ps/(.*)"},
	}, 
	function(self, player, channelId)
		if (player.TAXI_PROCESSING) then
			return false, "wait for taxi", "Wait for the Taxi!";
		elseif (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		elseif (player:IsBoxing()) then
			return false, "not while boxing"
		elseif (player:IsRacing()) then
			return false, "not while racing"
		elseif (player:IsAfk()) then
			return false, "not while afk"
		end
		--if (CryMP.Ent:IsPosInZone(player:GetPos())) then
		--	return false, "leave building", "Leave the building!"
		--end
		local height = 2;
		local distance = player:IsOnVehicle() and 16 or 6;
		local pos, dir = CryMP.Library:CalcSpawnPos(player, distance);
		--if (CryMP.Ent:IsPosInZone(pos)) then
		--	return false, "cannot spawn here", "Cannot spawn taxi inside buildings!"
		--end		
		local entities = System.GetPhysicalEntitiesInBox(pos, 2); 
		if (entities) then
			for i, ent in pairs(entities) do
				if (ent.actor and ent.id ~= player.id) then
					return false, "player near", "Player "..ent:GetName().." in front of you!"
				elseif (ent.vehicle) then
					return false, "vehicle near", CryMP.Ent:GetVehicleName(ent.class).." in front of you!"
				end
			end
		end
		local TaxiType, TaxiMod = "Civ_car1", "PoliceCar";
		local TaxiPaints = {"black","blue","green","blue","police","red","silver","utility","pink","darkblue","orange"};
		local bottom = System.GetTerrainElevation(pos);
		local testPos = {x=pos.x, y=pos.y, z=bottom};
		if (nCX.IsPosUnderWater(testPos)) then
			TaxiType, TaxiMod, TaxiPaint = "US_smallboat", (math.random(2) == 1 and "" or "Gauss"), {"us", "nk",};
		end
		local params = {
			class = TaxiType; 
			name = "supercab"..tostring(CryMP.Library:SpawnCounter());
			orientation = dir;
			position = pos;
			properties = {
				bAdjustToTerrain = 1; 
				Modification = TaxiMod; 
				Paint = TaxiPaints[math.random(1, 11)];
				Respawn = {
					bAbandon = 0, 
					bRespawn = 0,
					bUnique = 1,
					nAbandonTimer = 0, 
					nTimer = 0,
				};
			};
		};
		local previousId = self.Taxis[channelId];
		if (previousId) then
			local taxi = System.GetEntity(previousId);
			if (taxi) then
				taxi.vehicle:ExitVehicle(player.id);
				if (not taxi:IsAnyPassenger()) then
					System.RemoveEntity(previousId);
				end
			end
			self.Taxis[channelId] = nil;
		end
		--CryMP.Ent:GetFactory(player.id).onClient:ClVehicleBuildStart(channelId, "Taxi", player.id, nCX.GetTeam(player.id), 1, 1)
		player.TAXI_PROCESSING = true;
		CryMP:Spawn(params, function(vehicle)
			if (vehicle) then
				vehicle:EnterVehicle(player.id, 1);
				--local factory = CryMP.Ent:GetFactory(player.id);
				--if (factory) then
					--factory.onClient:ClVehicleBuilt(channelId, "Taxi", player.id, player.id, nCX.GetTeam(player.id), 0);	
				--end
				nCX.SetTeam(nCX.GetTeam(player.id), vehicle.id);
				--nCX.AddSpawnGroup(vehicle.id);
				--g_gameRules:MakeBuyZone(vehicle, 13, 13)
				self.Taxis[channelId] = vehicle.id;
				player.TAXI_PROCESSING = nil;
			end
		end);
		nCX.SendTextMessage(3, "::: ! 7OXICITY.TAXI.COMPANY ! :::", channelId);
		nCX.ParticleManager("misc.emp.sphere", 0.5, {pos.x,pos.y,pos.z+height}, g_Vectors.up, 0);
		return true;
	end
);

