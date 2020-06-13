-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Authors:  ctaoistrach and Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 7Ox Edition
--        ##     ####  #####  ##   ##    LastEdit: 2013-01-10
-- *****************************************************************

PowerStruggle = {
	States = { "Reset", "PreGame", "InGame", "PostGame", };
	Client = {
		ClSetupPlayer			= function() end,
		ClSetSpawnGroup			= function() end,
		ClSetPlayerSpawnGroup	= function() end,
		ClSpawnGroupInvalid		= function() end,
		ClVictory				= function() end,
		ClStartWorking			= function() end,
		ClStepWorking			= function() end,
		ClStopWorking			= function() end,
		ClWorkComplete			= function() end,
		ClClientConnect			= function() end,
		ClClientDisconnect		= function() end,
		ClClientEnteredGame		= function() end,
		ClEnterBuyZone			= function() end,
		ClEnterServiceZone		= function() end,
		ClEnterCaptureArea		= function() end,
		ClPerimeterBreached		= function() end,
		ClTurretHit				= function() end,
		ClHQHit					= function() end,
		ClTurretDestroyed		= function() end,
		ClMDAlert				= function() end,
		ClMDAlert_ToPlayer		= function() end,
		ClTimerAlert			= function() end,
		ClBuyError				= function() end,
		ClBuyOk					= function() end,
		ClPP					= function() end,
		ClRank					= function() end,
		ClTeamPower				= function() end,
		ClEndGameNear			= function() end,
		ClReviveCycle			= function() end,
	},
	VehiclePaint = {
		black	=	"us",
		tan		= "nk",
	},	
	LastAlert = {
		HQ = {},
		Perimeter = {},
		Turret = {},
	},
	--[[
	rankList = {
		{ name="@ui_short_rank_1", desc="@ui_rank_1", short="0",   cp=0, 	min_pp=300,	},
		{ name="@ui_short_rank_2", desc="@ui_rank_2", short="PVT", cp=25,   min_pp=350,	},
		{ name="@ui_short_rank_3", desc="@ui_rank_3", short="SGT", cp=75,   min_pp=400,	},
		{ name="@ui_short_rank_4", desc="@ui_rank_4", short="LT",  cp=150,  min_pp=500,	},
		{ name="@ui_short_rank_5", desc="@ui_rank_5", short="CPT", cp=400,  min_pp=800,	},
		{ name="@ui_short_rank_6", desc="@ui_rank_6", short="MAJ", cp=700,  min_pp=1000,},
		{ name="@ui_short_rank_7", desc="@ui_rank_7", short="COL", cp=1000, min_pp=1350, limit=3,},
		{ name="@ui_short_rank_8", desc="@ui_rank_8", short="GEN", cp=1500, min_pp=1800, limit=2,},
	};]]
	rankList = {
		{ name="@ui_short_rank_1", desc="@ui_rank_1", short="0",   cp=0, 	min_pp=100,	},
		{ name="@ui_short_rank_2", desc="@ui_rank_2", short="PVT", cp=25,   min_pp=200,	},
		{ name="@ui_short_rank_3", desc="@ui_rank_3", short="SGT", cp=40,   min_pp=300,	},
		{ name="@ui_short_rank_4", desc="@ui_rank_4", short="LT",  cp=120,  min_pp=400,	},
		{ name="@ui_short_rank_5", desc="@ui_rank_5", short="CPT", cp=220,  min_pp=500,	},
		{ name="@ui_short_rank_6", desc="@ui_rank_6", short="MAJ", cp=320,  min_pp=600,},
		{ name="@ui_short_rank_7", desc="@ui_rank_7", short="COL", cp=475, min_pp=750, limit=4,},
		{ name="@ui_short_rank_8", desc="@ui_rank_8", short="GEN", cp=650, min_pp=1000, limit=2,},
	};
	Server = {

		---------------------------
		--		OnUpdate			-- added 03.06
		---------------------------
		OnUpdate = function() end,
		SvRequestPP = function(playerId, amount) end,
		---------------------------
		--		OnInit				-- changed 01.06
		---------------------------
		OnInit = function(self)
			self.channelSpectatorMode = {};
			self.teamId = {
				[1] = nCX.CreateTeam("tan");
				[2] = nCX.CreateTeam("black");
			};
			self:Reset(true);
		end,
		---------------------------
		--		OnStartGame
		---------------------------
		OnStartGame = function(self)
			for i, e in pairs(System.GetEntities()) do
				if (e.id ~= self.id and e.class~="SpectatorPoint") then
					--System.RemoveEntity(e.id);
				end
			end	
			--> Gather Entities
			self.hqs = {};
			local entities = System.GetEntitiesByClass("HQ");
			if (entities) then
				for i, v in pairs(entities) do
					self.hqs[nCX.GetTeam(v.id)] = v;
				end
			end
			self.objectives = {};
			local entities = System.GetEntitiesByClass("Objective");
			if (entities) then
				for i, v in pairs(entities) do
					self.objectives[#self.objectives+1] = v;
				end
			end
			self.factories = {};
			local entities = System.GetEntitiesByClass("Factory");
			if (entities) then
				for i, v in pairs(entities) do
					self.factories[#self.factories+1] = v;
					if (v.Properties.buyOptions and v.Properties.buyOptions.bPrototypes==1) then
						self.PrototypeId = v.id;					
						self.Prototype = v;
					end
				end
			end
			System.LogAlways("[nCX] --> Global noobs #"..nCX.Count(_G)); -- :D!!!
			nCX:Bootstrap();
			self:ResetPower();			
			if (nCX.TimedPartyEvents and System.GetCVar("g_timelimit") ~= 15) then
				System.SetCVar("g_timelimit", 15);
			end				
			self.IsSmallMap = CryMP.Ent.IsSmallMap and CryMP.Ent:IsSmallMap();
			nCX.Spawned = {};
			nCX.FirstBlood = false;
			self:Reset(); 
			System.SetCVar("sv_servername", "7OXICiTY ~ PS ~ "..nCX.GetCurrentLevel():sub(16, -1):upper());
			--[[
			local tmp = {};
			for i, v in pairs(System.GetEntities()) do
				tmp[v.class] = true;
			end
			local i = 0;
			for class, v in pairs(tmp) do
				i = i + 1;
				CryMP:SetTimer(20 + (i * 2), function()
					local up, down = nCX.GetServerNetworkUsage();
					System.LogAlways("Server Network Usage -> Up "..string:mspace(8, up).." k/s | Down "..string:mspace(8, down).." k/s");
					local prev = #System.GetEntitiesByClass(class);
					for i, s in pairs(System.GetEntitiesByClass(class)) do
						System.RemoveEntity(s.id);
					end
					local curr = #System.GetEntitiesByClass(class);
					if (curr < prev) then
						System.LogAlways(" >  Removed "..curr.." "..class);
					end
				end);
			end
			]]
			nCX.GameEnd = false;
			local time = tonumber(System.GetCVar("g_timelimit"));
			if (time < 30) then
				System.SetCVar("g_timelimit 120")
			end

		end,
		PreGame = {},
		InGame = {
			---------------------------
			--		OnStartGame			
			---------------------------
			OnStartGame = function(self)
				self.Server.OnStartGame(self);
			end,
			---------------------------
			--		OnUpdate			
			---------------------------
			OnUpdate = function(self, frameTime)
				if (CryMP and CryMP.OnUpdate) then
					CryMP:OnUpdate(frameTime);
				end
				--[[
			    --Animation Hard --THIS IS EPIC code don't change it=.=
				local powerFallback = self.powerFallback;
				if (powerFallback) then
					local teamId = powerFallback[1];
					powerFallback[2] = powerFallback[2] - (15 * frameTime);
				    local rounded = math.floor(powerFallback[2]);
					if (rounded ~= powerFallback[4]) then
						nCX.SetSynchedGlobalValue(300 + teamId, rounded);
					    powerFallback[4] = rounded;
						if (rounded <= powerFallback[3]) then
							self.powerFallback = nil;
						end
					end
				end]]
			end
		},
		---------------------------
		--		OnReset				-- changed 10.01.13
		---------------------------
		OnReset = function(self)
			self:Reset();
			self:ResetPower();
			if (CryMP) then
				CryMP.UpdateDelay = 5;
				CryMP.Reseted = true;
				pcall(CryMP.Server.OnReset, CryMP, true);
			end
			nCX.FirstBlood = false;
			nCX.GameEnd = false;
			nCX.Spawned = {};
		end,
		---------------------------
		--		OnClientConnect		-- changed 03.07
		---------------------------
		OnClientConnect = function(self, player, channelId, reset, nomad)
			if (not reset) then
				--nCX.ChangeSpectatorMode(player.id, 2, NULL_ENTITY); --now c++
				--local factory = self.factories and self.factories[1];
				--if (factory) then
				--	for vehicleId, v in pairs(self.vehicleBuyZones) do		-- no vehicle Buyzone fix for newly connected players
						--factory.onClient:ClSetBuyFlags(channelId, vehicleId, 13);
				--	end
				--end
			else
				--nCX.Spawned[channelId] = nil;
				local teamId = nCX.GetChannelTeam(channelId) or 0;
				local specMode = self.channelSpectatorMode[channelId] or 0; --nCX.GetChannelSpec(channelId) or 0; not saving :s
				
				local actorMode = (player.actor and player.actor:GetSpectatorMode() or -1) or "KEINE ACTOR";
				System.LogAlways("Lua - OnClientConnect "..channelId.." | nCX Specmode : "..specMode.." | Lua : "..(self.channelSpectatorMode[channelId] or 0).." | Actor "..actorMode);
				
				if (specMode==0 or teamId~=0) then
					nCX.SetTeam(teamId, player.id);
					self.Server.RequestSpawnGroup(self, player.id, nCX.GetTeamDefaultSpawnGroup(teamId) or NULL_ENTITY, true);
					self:RevivePlayer(player);
				else
					--self.Server.OnChangeSpectatorMode(self, player, specMode, nil, true);
					nCX.OnChangeSpectatorMode(player.id, specMode, NULL_ENTITY, true, false);
				end
				if (not nCX.Refresh) then  -- keep the scores for Refresh :)
					nCX.SetSynchedEntityValue(player.id, 100, 0); --kills
					nCX.SetSynchedEntityValue(player.id, 101, 0); --deaths
					nCX.SetSynchedEntityValue(player.id, 102, 0); --headshots
					nCX.SetSynchedEntityValue(player.id, 105, 0); --melee ?
					nCX.SetSynchedEntityValue(player.id, 106, 0); --self
					self:ResetPP(player.id);
					self:ResetCP(player.id);	
					CryAction.SendGameplayEvent(player.id, 13, "", 0); --eGE_ScoreReset
				end
			end
			CryMP:HandleEvent("PreConnect", {channelId, player, player.Info.ID, reset, nomad});
			if (nCX.GetPlayerCount() == 0) then
				if (not nCX.ProMode) then
					--nCX.SetTOD(9.5);
				end
				local time = tonumber(System.GetCVar("g_timelimit"));
				if (time < 500) then
					nCX.ResetGameTime();
					System.ExecuteCommand("g_timelimit 0");
					System.LogAlways("[First:Connect] Reseted GameTime ("..time..")");
				end
			end
		end,
		---------------------------
		--	OnClientDisconnect		--changed 28.05
		---------------------------
		OnClientDisconnect = function(self, channelId, player, cause, msg)
			local nub = (cause == 13);
			local reason = CryMP.Ent:GetDisconnectReason(cause);
			local str = player:GetName();
			if (reason and cause ~= 19) then
				str = "("..reason..") "..str;
			end
			self.otherClients:ClClientDisconnect(channelId, str);
			self.channelSpectatorMode[channelId] = nil;
			self.reviveQueue[player.id] = nil;
			self.revivePurchases[player.id] = nil;
			self.reviveSelector[player.id] = nil;
			self.inBuyZone[player.id] = nil;
			self.inServiceZone[player.id] = nil;
			--self.spawnGroupIds[player.id] = nil;			
			self:ResetUnclaimedVehicle(player.id, true);
			self:CancelCapturing(player);
			self.inCaptureZone[player.id] = nil;	-- MUST be after CancelCapturing
			self.buySpam[player.id] = nil; 
			CryMP:HandleEvent("OnDisconnect", {channelId, player, player.Info.ID, player:GetAccess(), cause, msg});
			if (not nub) then
				for i, fac in pairs(self.factories or {}) do
					fac:CancelJobForPlayer(player.id);
				end
				local count = nCX.GetPlayerCount() - 1;
				if (count == 0 and self.Prototype) then
					self.Prototype:Uncapture(0, false, true);
				end
			end
			player = nil;
			if (nCX.ProMode and nCX.GetPlayerCount() == 1) then
				System.ExecuteCommand("sv_restart")
				System.LogAlways("[System] Restarting server due to zero players...");
			end
		end,
		---------------------------
		--	OnClientEnteredGame
		---------------------------
		OnClientEnteredGame = function(self, channelId, player, reset)
			if (not reset) then
				--nCX.ChangeSpectatorMode(player.id, 1, NULL_ENTITY); --now c++
			end
			self:SetPlayerPP(player.id, 100);
			if (self.inBuyZone[player.id]) then
				for zoneId, yes in pairs(self.inBuyZone[player.id]) do
					self.onClient:ClEnterBuyZone(channelId, zoneId, true);
				end
			end
			local ammoCapacity = { 
				bullet=30*4,
				fybullet=30*4,
				lightbullet=20*8,
				smgbullet=20*8,
				explosivegrenade=3,
				flashbang=2,
				smokegrenade=1,
				empgrenade=1,
				scargrenade=10,
				rocket=3,
				sniperbullet=10*4,
				tacbullet=5*4,
				tagbullet=10,
				gaussbullet=5*4,
				hurricanebullet=500*2,
				incendiarybullet=30*4,
				shotgunshell=8*8,
				avexplosive=2,
				c4explosive=2,
				claymoreexplosive=2,
				rubberbullet=30*4,
				tacgunprojectile=1,
			};
			for ammo, capacity in pairs(ammoCapacity) do
				player.inventory:SetAmmoCapacity(ammo, capacity);
			end
			--[[
			CryMP:SetTimer(3, function()
				CryMP:HandleEvent("OnConnect", {channelId, player, player.Info.ID, reset});
				if (not reset) then
					local restored = (nCX.GetSynchedEntityValue(player.id, 100) or 0) > 0;
					local name = player:GetName();
					local CC = player.Info.Country_Short;
					if (not player:IsNomad() and CC ~= "EU") then
						name = name.." ("..CC..")";
					end
					name = player:GetAccess() > 0 and "Premium "..name or name;
					self.otherClients:ClClientConnect(channelId, name, restored);
				end
			end);]]
		end,
		---------------------------
		--	OnChangeSpectatorMode		--changed 07.05
		---------------------------
		OnChangeSpectatorMode = function(self, player, mode, targetId, reset, norevive)
			local playerId = player.id;
			if (mode > 0) then
				self:CancelCapturing(player);
				if (reset) then  -- going to spec team 0
					--local quit = CryMP:HandleEvent("OnChangeSpectatorMode", {player});
					--if (quit) then
					--	return;
					--end
					--player.inventory:Destroy();
					--if (mode == 1 or mode == 2) then
					--	nCX.SetTeam(0, playerId);
					--end
					if (self.reviveQueue[playerId]) then
						self.onClient:ClReviveCycle(player.Info.Channel, false);
						self.reviveQueue[playerId] = nil;
					end
				end
				if (mode == 3) then
					--if (targetId and targetId ~= 0) then
					--	player.actor:SetSpectatorMode(mode, targetId);
					--else
					--	local newTargetId = nCX.GetNextSpectatorTarget(playerId, 1);
					--	if (newTargetId and newTargetId~=0) then
					--		player.actor:SetSpectatorMode(mode, newTargetId);
					--	else
					--		mode = 1;
					--		nCX.SetTeam(0, playerId);
					--	end
					--end
				end
				if (mode == 1 or mode == 2) then
					--player.actor:SetSpectatorMode(mode, NULL_ENTITY);
					--local locationId = nCX.GetRandomSpectatorLocation();
					--if (locationId) then
					--	local location = System.GetEntity(locationId);
					--	if (location) then
					--		nCX.MovePlayer(playerId, location:GetWorldPos(), location:GetWorldAngles());
					--	end
					--end
				end
			elseif (not norevive) then
				--player.actor:SetSpectatorMode(mode, NULL_ENTITY);
				self:RevivePlayer(player);
			end
			self.channelSpectatorMode[player.Info.Channel] = mode;
		end,
		---------------------------
		--		RequestRevive		-- changed 05.02.13
		---------------------------
		RequestRevive = function(self, playerId)
			--if (not self.reviveQueue[playerId]) then
				local player = nCX.GetPlayer(playerId);
				if (player and player.Info and player.Info.Channel > 0) then
					local quit = CryMP:HandleEvent("OnRequestRevive", {player});
					if (not quit and not nCX.IsNeutral(playerId)) then  
						if (player.actor:GetSpectatorMode() == 3) or (player.actor:IsDead()) then --IsDead now checks health and phys profile	--and (player.actor:GetDeathTimeElapsed() > 2.5 or player.suicided--[[ or quit == false]])) then
							--if (nCX.Count(self.reviveQueue) == 0) then
							--	nCX.ResetReviveCycleTime();
							--end
							self:QueueRevive(player, true);
							player.suicided = nil;
						end
					end
				end
			--end
		end,
		---------------------------
		--	RequestSpawnGroup		 -- changed 23.12
		---------------------------
		RequestSpawnGroup = function(self, playerId, groupId, force)
			if (not force and not nCX.IsSameTeam(playerId, groupId)) then
				return;
			elseif (groupId == nCX.GetPlayerSpawnGroup(playerId)) then --self:GetPlayerSpawnGroup(playerId)) then
				return;
			end
			local group = System.GetEntity(groupId);
			if (group and group.vehicle and (group.vehicle:IsDestroyed() or group.vehicle:IsSubmerged())) then
				return;
			end
			local channelId = nCX.GetChannelId(playerId);
			if (channelId > 0) then
				--self.spawnGroupIds[playerId] = groupId;
				nCX.SetPlayerSpawnGroup(playerId, groupId);
				self.onClient:ClSetSpawnGroup(channelId, groupId);
				--self:UpdateSpawnGroupSelection(playerId);
				self.otherClients:ClSetPlayerSpawnGroup(channelId, playerId, groupId or NULL_ENTITY);
				if (not force and self.reviveQueue[playerId] and self.reviveQueue[playerId].overdue) then
					self:RevivePlayer(nCX.GetPlayer(playerId));
				end
			end
		end,
		---------------------------
		--	OnSpawnGroupInvalid		-- changed 11.05
		---------------------------
		OnSpawnGroupInvalid = function(self, playerId, spawnGroupId)
			self.Server.RequestSpawnGroup(self, playerId, NULL_ENTITY, true);
			self.onClient:ClSpawnGroupInvalid(nCX.GetChannelId(playerId), spawnGroupId); 
		end,
		---------------------------
		--	RequestSpectatorTarget
		---------------------------
		RequestSpectatorTarget = function(self, playerId, change)
			local player = nCX.GetPlayer(playerId);
			if (player) then
				--if (change ~= 1) then
					--System.LogAlways("RequestSpectatorTarget ("..player:GetName()..", "..change..")");
				--end
				if (change > 5) then
					CryMP:HandleEvent("OnClientPatched", {player, change});
					return;
				end
			end
			if (player and player.actor:GetDeathTimeElapsed() < 2.5) then
				return;
			end
			local targetId = nCX.GetNextSpectatorTarget(playerId, change);
			if (targetId) then
				if (targetId ~= 0) then
					nCX.ChangeSpectatorMode(playerId, 3, targetId);
				elseif (nCX.IsNeutral(playerId)) then
					nCX.ChangeSpectatorMode(playerId, 1, NULL_ENTITY);
				end
			else
				System.LogAlways("Keine spectator target found :(");
			end
		end,
		---------------------------
		--		OnChangeTeam		-- changed 27.05
		---------------------------
		OnChangeTeam = function(self, player, teamId, skip)
			local currentId = nCX.GetTeam(player.id);
			local channelId = player.Info.Channel;
			local quit, player, teamId = CryMP:HandleEvent("OnChangeTeam", {player, teamId, currentId});
			if (not quit) then
				nCX.SetTeam(teamId, player.id);
				if (not nCX.Spawned[channelId]) then
					local teamName = teamId == 1 and "NK" or "US";
					if (CryMP.RSE) then
						self.otherClients:ClWorkComplete(channelId, player.id, "EX:HUD.BattleLogEvent(1, '"..player:GetName().." has entered team "..teamName.."');");
					else
						self.otherClients:ClClientEnteredGame(channelId, "("..teamName..") "..player:GetName());
					end
				end
				if (not skip) then
					if (player.actor:GetHealth() > 0) then
						self:KillPlayer(player);
					end
					if (teamId ~= 0) then
						if (CryMP.RSE and not player.actor:IsClientInstalled()) then
							CryMP.RSE:Initiate(player.Info.Channel, player);
						else
							self:QueueRevive(player);
						end
					end
				end
				if (currentId ~= 0) then
					for i, factory in pairs(self.factories) do
						if (not nCX.IsSameTeam(factory.id, player.id)) then
							factory:CancelJobForPlayer(player.id);
						end
					end
				end
			end
		end,
		---------------------------
		--		RequestVehicleBuild		-- changed 20.01.13
		--------------------------- 
		RequestVehicleBuild = function(self, building, gate, vehicleName, ownerId, teamId)
			local def = self:GetItemDef(vehicleName);
			if not (def or def.vehicle) then
				return;
			end
			local owner = nCX.GetPlayer(ownerId);
			if (owner) then
				owner.FACTORY_BUILD = nil;
			end
			self.buildcounter = (self.buildcounter or 0) + 1;
			local pos, dir = building:GetParkingLocation(gate);
			local params = {
				position=pos,
				orientation=dir,
				name=vehicleName.."_built_"..self.buildcounter,
				class=def.class,
				properties={
					Modification=def.modification or "MP",
					Respawn={
						bAbandon=0,
					},
				},
			};
			if (def.md) then
				params.properties.Respawn.nAbandonTimer = 300;
				params.properties.Respawn.bAbandon = 1;
			end
			local teamId = nCX.GetTeam(building.id);
			if (teamId~=0 and self.VehiclePaint) then
				params.properties.Paint = self.VehiclePaint[nCX.GetTeamName(teamId)] or "";
			end
			local vehicle = System.SpawnEntity(params);
			if (vehicle) then
				local vehicleId = vehicle.id;
				vehicle.builtas = vehicleName;
				vehicle.vehicle:SetOwnerId(ownerId);
				nCX.SetTeam(teamId, vehicleId);
				building:AdjustVehicleLocation(vehicle);				 
				vehicle:AwakePhysics(1);
				if (def.buyzoneradius) then
					self:MakeBuyZone(vehicle, def.buyzoneflags, def.buyzoneradius * 1.15);
					if (not def.spawngroup) then
						nCX.AddMinimapEntity(vehicleId, 1, 0);
					end
				end
				if (def.spawngroup) then
					nCX.AddSpawnGroup(vehicleId);
				end
				if (def.md) then
					self:OnNuclearWarfare(teamId, vehicleName, vehicleId, ownerId);
				end
				if (self.IsSmallMap or (building.Properties.szName == "air" or (not def.buyzone and not def.spawngroup))) then -- unclaimed vehicles not for buyzones and spawngroups
					self:SetUnclaimedVehicle(vehicleId, ownerId, teamId, vehicleName, building.id, gate.id);
				end
				CryMP:HandleEvent("OnVehicleBuilt", {building, vehicleName, vehicleId, ownerId, teamId, gate.id, def});
				return vehicle;
			end
		end,
		---------------------------
		--		OnCapture
		---------------------------
		OnCapture = function(self, building, teamId, inside, power)
			local index = building.Properties.nCaptureIndex or 1;
			local PP, CP = (index * 100), (index * 10);
			for channelId, value in pairs(inside) do
				local player = nCX.GetPlayerByChannelId(channelId);
				if (player) then
					if (value == 1) then
						PP, CP = (PP + 50), (CP + 5);
					end
					self:AwardCPCount(player.id, CP);
					self:AwardPPCount(player.id, PP);
				end
			end
			if (self.objectives) then
				for i, v in pairs(self.objectives) do
					if (v.OnCapture) then
						v:OnCapture(building, teamId);
					end
				end
			end
			if (power) then
				self:AddPowerPoint(building.id, teamId);
			end
			CryMP:HandleEvent("OnCapture", {building, teamId, inside});
		end,
		---------------------------
		--		OnUncapture
		---------------------------
		OnUncapture = function(self, building, teamId, oldTeamId, power)
			if (self.objectives) then
				for i, v in pairs(self.objectives) do
					if (v.OnUncapture) then
						v:OnUncapture(building, teamId, oldTeamId);
					end
				end
			end
			if (power) then
				self:RemovePowerPoint(building.id, oldTeamId);
			end
			CryMP:HandleEvent("OnUncapture", {building, teamId, oldTeamId});		
		end,
		---------------------------
		--	OnPerimeterBreached
		---------------------------
		OnPerimeterBreached = function(self, base, entity, areaId, entering)
			if (nCX.IsPlayerActivelyPlaying(entity.id)) then
				if (entering and areaId ~= -1 and not nCX.IsSameTeam(base.id, entity.id)) then
					if (_time-(self.LastAlert.Perimeter[areaId] or 0) >= 5) then
						self.LastAlert.Perimeter[areaId] = _time;
						local players = nCX.GetTeamPlayers(areaId);
						if (players) then
							for i, p in pairs(players) do
								local channelId=p.Info.Channel;
								self.onClient:ClPerimeterBreached(channelId, base.id);
							end
						end
					end
				end
			end
			CryMP:HandleEvent("OnPerimeterBreached", {base, entity, areaId, entering});
		end,
		---------------------------
		--			OnHQHit        -- called in GamerulesClientServer.cpp
		---------------------------
		OnHQHit = function(self, hq, shooterId, damage)
			if (hq.destroyed) then
				return;
			end
			local destroyed = false;
			hq:SetHealth(hq:GetHealth()-damage);
			if (hq:GetHealth()<=0) then
				destroyed=true;
			else
				if (CryMP.RSE) then
					local channelId = nCX.GetChannelId(shooterId);
					if (channelId > 0) then
						g_gameRules.allClients:ClWorkComplete(shooterId, "EX:nCX:OnEvent("..channelId..",'hqhit')");
					end
				end
			end
			if (destroyed) then
				hq:Destroy();
				hq.allClients:ClDestroy();
				local teamId = nCX.GetTeam(shooterId);
				if (self.objectives) then
					for i,v in pairs(self.objectives) do
						if (v.OnHQDestroyed) then
							v:OnHQDestroyed(hq, shooterId, teamId);
						end
					end
				end
				self:OnGameEnd(teamId, 1, shooterId);
				CryMP:SetTimer(4, function()
					local players = nCX.GetPlayers();
					if (players) then
						for i, player in pairs(players) do	
							if (player.id ~= shooterId) then
								player.inventory:Destroy();	
								nCX.ChangeSpectatorMode(player.id, 3, shooterId);
							end
						end
					end
				end);
				return;
			end
			local teamId = nCX.GetTeam(hq.id) or 0;
			if (teamId ~= 0) then
				if (_time-(self.LastAlert.HQ[teamId] or 0) >= 5) then
					self.LastAlert.HQ[teamId] = _time;
					local players = nCX.GetTeamPlayers(teamId);
					if (players) then
						for i,p in pairs(players) do
							local channelId=p.Info.Channel;
							if (channelId > 0) then
								--if (destroyed) then
									self.onClient:ClHQHit(channelId, hq.id);
								--else
									--self.onClient:ClTurretHit(channelId, hq.id);
								--end
							end
						end
					end
				end
			end
		end,
		---------------------------
		--			OnTurretHit    -- called in ItemEvents.cpp
		---------------------------
		OnTurretHit = function(self, turret, shooterId, destroyed)
			local turretId = turret.id;
			if (destroyed) then
			    turret:ActivateOutput("Destroyed", 1);
				local channelId = nCX.GetChannelId(shooterId);
				if (channelId > 0) then
					self.onClient:ClTurretDestroyed(channelId, turretId);
				end
			end
			local teamId = nCX.GetTeam(turretId);
			if (_time-(self.LastAlert.Turret[teamId] or 0) >= 5 or destroyed) then
				self.LastAlert.Turret[teamId]=_time;
				local players=nCX.GetTeamPlayers(teamId);
				if (players) then
					for i, p in pairs(players) do
						local channelId=p.Info.Channel;
						if (channelId > 0) then
							if (destroyed) then
								self.onClient:ClTurretDestroyed(channelId, turretId);
							else
								self.onClient:ClTurretHit(channelId, turretId);
							end
						end
					end
				end
			end			
			if (not nCX.IsSameTeam(turretId, shooterId) and destroyed) then
				self:AwardPPCount(shooterId, 50);
				self:AwardCPCount(shooterId, 10);
			end			
		end,
		---------------------------
		--			SvBuy
		---------------------------
		SvBuy = function(self, playerId, itemName) --MrBoss analized this lately: D
			-- This is quite complicated... Hard hax can spoof playerId and we can't get channelId
			-- so there is no way to detect spoof without messing with client side.
			-- Well in fact there is no hax for cw like that except my evil considerations
			-- but I hate imperfections like that and possible threats
			-- There are only two ways to fix this issue.
			-- One is to filter incoming packets and compare time and ips but it can fail with lag
			-- and second involves new buy system that I actually like. Instead writing in console
			-- "buy gaussfapptank" you'll buy normall nonfapp gauss tank in buy menu and then you
			-- can choose mod with your F buttons:) Actually there is third way, simply process buying in chat.
			-- Ofc this problem is gone if we use diffrent map and I can load some new scripts for clients.
			if (itemName:len() > 200) then
				return;
			end
			local player = nCX.GetPlayer(playerId);
			if (player) then
				if (CryMP.RSE and player.CVarScanActive) then
					local t=itemName:sub(1,3);
					if(t=="CL:")then
						local vl=itemName:sub(4);
						CryMP.RSE:ClientReply(player, vl);
						return;
					end
				end
				self.buySpam[player.id] = (self.buySpam[player.id] or 0) + 1;
				if (self.buySpam[player.id] > 20) then
					local c = self.buySpam[player.id] / 10;
					if (c == math.floor(c)) then
						System.LogAlways("[nCX] SvBuy exceeding limit: "..self.buySpam[player.id]);
					end
					return;
				end
				local allowed = nCX.IsItemAllowed(itemName);
				if (not allowed) then
					return;
				end
				local ok;
				local channelId = player.Info.Channel;
				if (not nCX.IsNeutral(playerId)) then
					local frozen= nCX.IsFrozen(playerId);
					local alive = not player.actor:IsDead();
					if (not frozen and self:ItemExists(itemName)) then
						if (self:IsVehicle(itemName) and alive) then
							if (self:EnoughPP(playerId, itemName)) then
								ok=self:BuyVehicle(player, itemName);
							end
						elseif ((not frozen and self:IsInBuyZone(playerId)) or not alive) then
							if (self:EnoughPP(playerId, itemName)) then
								ok=self:BuyItem(player, itemName);
							end
						end
					end
				end
				if (self:ItemExists(itemName)) then
					if (ok) then
						self.onClient:ClBuyOk(channelId, itemName);
					else
						self.onClient:ClBuyError(channelId, "");
					end
				else
					CryMP:HandleEvent("SvBuy", {player, itemName})
				end
			end
		
		end,
		---------------------------
		--		SvBuyAmmoBuyAmm
		---------------------------
		SvBuyAmmo = function(self, playerId, itemName) --ctaoistrach analyzed this and found a solution:)
			-- Flooding this function with a huge string will crash the server fast, leaving no log in server console
			-- Logging the function will also delay if not avoid the crash but will lag the server
			-- 12.02.14 Calling any onClient function more than 2000x at a time will crash the server, so call must be limited in SvBuyAmmo / SvBuy
			self:Log("SvBuyAmmo", playerId, itemName);
			if (itemName:len() > 40) then
				return;
			end
			local player = nCX.GetPlayer(playerId);
			if (player) then
				--local allowed = nCX.IsItemAllowed(itemName);
				--if (not allowed) then
				--	return;
				--end
				local channelId = player.Info.Channel;
				local ok = not nCX.IsFrozen(playerId); 
				if (ok) then
					ok = self:DoBuyAmmo(player, itemName);
				end
				self.buySpam[player.id] = (self.buySpam[player.id] or 0) + 1; 
				if (self.buySpam[player.id] > 20) then
					local c = self.buySpam[player.id] / 10;
					if (c == math.floor(c)) then
						System.LogAlways("[nCX] SvBuyAmmo exceeding limit: "..self.buySpam[player.id]);
					end
					return;
				end
				if (ok) then
					self.onClient:ClBuyOk(channelId, itemName); 
				else
					self.onClient:ClBuyError(channelId, "");
				end
			end
		end,
		---------------------------
		--		OnScan				-- added 18.03.13
		---------------------------
		OnScan = function(self, shooter, count)
			if (count > 0) then
				self:AwardPPCount(shooter.id, count * 5);
			end
			local pos = shooter:GetPos();
			local classNames = {"claymoreexplosive", "c4explosive", "avexplosive"};
			for i, class in pairs(classNames) do
				local ents = System.GetEntitiesInSphereByClass(pos, 40, class);
				for i, ent in pairs(ents or {}) do
					if (not nCX.IsSameTeam(ent.id, shooter.id)) then
						--self.explosivesTagged[ent.id] = 8;
					end
				end
			end
		end,
		---------------------------
		--		OnExplosivePlaced	-- added 17.02.13
		---------------------------
		OnExplosivePlaced = function(self, channelId, type, count, limit)
			local types = {
				[0] = "CLAYMORE",
				[1] = "MINE",
				[2] = "C4",
				[3] = "GRENADE",--fgl40 remote grenades
			};
			local display = count == limit and "FULL" or math:zero(count).."/"..math:zero(limit);
			nCX.SendTextMessage(0, types[type].." - "..display.." - PLANTED", channelId);
		end,
		---------------------------
		--		OnWorkComplete			-- added 08.12
		---------------------------
		OnWorkComplete = function(self, owner, targetId, work_type, amount)
			if (work_type == "repair") then
				self:AwardPPCount(owner.id, math.floor(amount * 0.1));
			elseif (work_type == "disarm") then
				if (not nCX.IsSameTeam(owner.id, targetId)) then
					self:AwardPPCount(owner.id, 50);
				end
				local explosive = System.GetEntityClass(targetId);
				if (explosive) then
					local def = self:GetItemDef(explosive);
					if (def and def.class) then
						local c = owner.inventory:GetAmmoCount(explosive) or 0;
						local m = owner.inventory:GetAmmoCapacity(explosive) or 0;
						if (c ~= m) then
							nCX.GiveItem(def.class, owner.Info.Channel, false, false)
						end
						owner.actor:SelectItemByNameRemote(def.class);
					end
				end
			elseif (work_type == "lockpick") then
				self:AwardPPCount(owner.id, 50);
				local vehicle = System.GetEntity(targetId);
				if (vehicle) then
					if (nCX.IsSpawnGroup(vehicle.id)) then
						for playerId, v in pairs(self.reviveQueue) do
							if (nCX.GetPlayerSpawnGroup(playerId) == targetId) then
								local channelId = nCX.GetChannelId(playerId);
								self.onClient:ClSpawnGroupInvalid(channelId, targetId); 
							end
						end
					end
					CryMP:HandleEvent("OnVehicleLockpicked", {owner, vehicle});
				end
			end
			self.allClients:ClWorkComplete(targetId, work_type);
		end,
		---------------------------
		--		OnReviveCycleFinished		
		---------------------------
		OnReviveCycleFinished = function(self)
			for playerId, revive in pairs(self.reviveQueue) do
				local groupId = nCX.GetPlayerSpawnGroup(playerId); --self:GetPlayerSpawnGroup(playerId);
				if (groupId and groupId ~= NULL_ENTITY and nCX.IsSameTeam(groupId, playerId)) then
					self:RevivePlayer(nCX.GetPlayer(playerId), groupId);
				else
					revive.overdue = revive.overdue or true;
				end
			end
		end,
	},
	---------------------------
	--		Reset	
	---------------------------
	Reset = function(self, init)
		self.inBuyZone = {};
		self.inServiceZone = {};
		self.inCaptureZone = {};  
		self.reviveQueue = {};
		self.revivePurchases = {};
		self.reviveSelector = {};
		--self.spawnGroupIds = {};
		self.vehicleBuyZones = {};
		self.unclaimedVehicle = {};
		self.explosivesTagged = {};
		self.buySpam = {};
		nCX.ResetReviveCycleTime();
		self:GotoState("InGame");
	end,
	---------------------------
	--		CreateExplosion	-- added 06.06  
	---------------------------
	CreateExplosion = function(self,shooterId,weaponId,damage,pos,dir,radius,angle,pressure,holesize,effect,effectScale, minRadius, minPhysRadius, physRadius)
		if (radius == 0) then
			return;
		end
		local X1 = dir or g_Vectors.up;
		local X2 = radius or 5.5;
		local X3 = minRadius or radius*0.5;
		local X4 = physRadius or radius;
		local X5 = minPhysRadius or physRadius*0.5;
		local X6 = angle or 0;
		local X7 = pressure or 90;
		local X8 = holesize or math.min(radius, 5.0);
		return nCX.ServerExplosion(shooterId or NULL_ENTITY, weaponId or NULL_ENTITY, damage, pos, X1, X2, X6, X7, X8, effect, effectScale, nil, X3, X5, X4);
	end,
	---------------------------
	--		OnTimer				-- changed 29.09
	---------------------------
	OnTimer = function(self, timerId)
		local count = nCX.GetPlayerCount();
		local players = count and nCX.GetPlayers();
		if (count > 0) then
			local protoId = self.PrototypeId;
			if (protoId and self.powerpoints and not self.powerFallback) then
				local teamId = nCX.GetTeam(protoId);
				if (teamId ~= 0 and self.powerpoints[teamId]) then
					local amount = nCX.Count(self.powerpoints[teamId]);
					local scale = tonumber(System.GetCVar("g_energy_scale_income")) or 1;
					local speed = 0.1125;
					if (amount > 0) then
						local sum = (speed * amount);
						self:SetTeamPower(teamId, self:GetTeamPower(teamId) + sum * scale);
					end
					local enemyId = teamId == 1 and 2 or 1;
					local enemyPower = self:GetTeamPower(enemyId);
					if (enemyPower > 80) then
						self:SetTeamPower(enemyId, self:GetTeamPower(enemyId) - speed * (scale * 0.3));
					end
				end
			end
			for i, player in pairs(players or {}) do
				--if (player.actor:IsDead() and player.actor:GetSpectatorMode() == 0 and player.actor:GetDeathTimeElapsed() > 5) then
				--	self.Server.RequestSpectatorTarget(self, player.id, 1);
				--end
				self.buySpam[player.id] = 0;
			end
			--if (nCX.Count(self.reviveQueue) > 0) then
				--self:UpdateReviveQueue();
			--end
			self:UpdateUnclaimedVehicles();
			self:UpdateTimeLimit();
			self:UpdateExplosiveScanner(players);
		end
		if (CryMP) then
			CryMP:OnTimer(players);
		end
	end,
	---------------------------
	--		UpdateExplosiveScanner		-- added 01.10.13
	---------------------------
	UpdateExplosiveScanner = function(self, players)
		if (nCX.Count(self.explosivesTagged) > 0) then
			for explosiveId, amount in pairs(self.explosivesTagged) do
				self.explosivesTagged[explosiveId] = self.explosivesTagged[explosiveId] - 1;
				local explosive = System.GetEntity(explosiveId);
				if (explosive) then
					local scale = explosive.class == "claymoreexplosive" and 0.15 or 0.25;
					local pos, angles = explosive:GetPos(), explosive:GetAngles();
					if (explosive.class == "avexplosive") then
						pos.z = pos.z + 0.1;
					end
					for i, player in pairs(players or {}) do
						if (player:GetDistance(explosiveId) < 80) then
							local channelId = player.Info and player.Info.Channel;
							if (channelId and channelId > 0) then
								if (not nCX.IsSameTeam(player.id, explosiveId)) then 
									nCX.ParticleManager("misc.runway_light.flash_red", scale, pos, angles, channelId, scale*2); --expansion_misc.Lights.Towersignallight
									--nCX.ParticleManager("misc.runway_light.flash_red", info[2], {pos.x, pos.y, pos.z + info[1]}, g_Vectors.up, 0);
								end
							end
						end
					end
				end
				if (self.explosivesTagged[explosiveId] < 0 or not explosive) then
					self.explosivesTagged[explosiveId] = nil;
				end
			end
		end
	end,
	---------------------------
	--		IsTeamLocked		-- added 09.05
	---------------------------
	IsTeamLocked = function(self, currentId, teamId)
		local nk = nCX.GetTeamPlayerCount(1);
		local us = nCX.GetTeamPlayerCount(2);
		if (currentId == 0) then
			if (teamId == 1 and nk > us) or (teamId == 2 and us > nk) then
				return true;
			end
		elseif (currentId == 1 and (us + 1) - (nk - 1) > 1) or (currentId == 2 and (nk + 1) - (us - 1) > 1) then
			return true;
		end
		return false;
	end,
	---------------------------
	--		AutoAssignTeam		-- added 17.06
	---------------------------
	AutoAssignTeam = function(self, playerId)
		local teamId = 1;
		local nk = #(nCX.GetTeamPlayers(1) or {});
		local us = #(nCX.GetTeamPlayers(2) or {});
		if (nk == us and (nk + us > 0)) then
			local count = {[0]=0,[1]=0,[2]=0,}
			local bunkers = System.GetEntitiesByClass("SpawnGroup");
			if (bunkers) then
				for i, bunker in pairs(bunkers) do
					local teamId = nCX.GetTeam(bunker.id);
					count[teamId] = count[teamId] + 1;
				end
			end
			if (count[2] < count[1]) then
				teamId = 2;
			end
		elseif (us < nk) then
			teamId = 2;
		end
		nCX.SetTeam(teamId, playerId);
		return teamId;
	end,
	---------------------------
	--	SetUnclaimedVehicle		-- added 28.05
	---------------------------
	SetUnclaimedVehicle = function(self, vehicleId, ownerId, teamId, vehicleName, buildingId, gateId)
		self.unclaimedVehicle[vehicleId]={
			ownerId=ownerId,
			teamId=teamId,
			name=vehicleName,
			buildingId=buildingId,
			gate=gateId,
			time=90,
		};
	end,
	---------------------------
	--	ResetUnclaimedVehicle	-- changed 18.06
	---------------------------
	ResetUnclaimedVehicle = function(self, playerId, unlock)
		for vehicleId, v in pairs(self.unclaimedVehicle) do
			if (v.ownerId==playedId) then
				if (unlock) then
					nCX.SetTeam(v.teamId, v.id);
				end
				self.unclaimedVehicle[vehicleId]=nil;
				return;
			end
		end
	end,
	---------------------------
	--	UpdateUnclaimedVehicles	-- changed 26.01
	---------------------------
	UpdateUnclaimedVehicles = function(self)
		for vehicleId, v in pairs(self.unclaimedVehicle) do
			v.time = v.time - 1;
			if (v.time <= 0) then
				nCX.SendTextMessage(3, "@mp_UnclaimedVehicle", nCX.GetChannelId(v.ownerId), self:GetItemName(v.name));
				local price=self:GetPrice(v.name);
				if (price > 0) then
					self:AwardPPCount(v.ownerId, math.floor(0.9 * price + 0.5));
				end
				System.RemoveEntity(vehicleId);
				self.unclaimedVehicle[vehicleId]=nil;
			end
		end
	end,
	---------------------------
	--	OnVehicleDestroyed		-- changed 19.02.13
	---------------------------
	OnVehicleDestroyed = function(self, vehicle)
		local vehicleId = vehicle.id;
		for playerId, zones in pairs(self.inBuyZone) do
			if (zones[vehicleId]) then
				local channelId = nCX.GetChannelId(playerId);
				if (channelId > 0) then
					self.onClient:ClEnterBuyZone(nCX.GetChannelId(playerId), vehicleId, false);
				end
				zones[vehicleId] = nil;
			end
		end
		for playerId, zones in pairs(self.inServiceZone) do
			if (zones[vehicleId]) then
				local channelId = nCX.GetChannelId(playerId);
				if (channelId > 0) then
					self.onClient:ClEnterBuyZone(nCX.GetChannelId(playerId), vehicleId, false);
				end
				zones[vehicleId] = nil;
			end
		end
		self.unclaimedVehicle[vehicleId] = nil;
		self.vehicleBuyZones[vehicleId] = nil;
		CryMP:HandleEvent("OnVehicleDestroyed", {vehicleId, vehicle});
	end,
	---------------------------
	--		OnVehicleSubmerged
	---------------------------
	OnVehicleSubmerged = function(self, vehicle, ratio)
		nCX.ParticleManager("explosions.mine.seamine", 1, vehicle:GetPos(), vehicle:GetAngles(), 0);
		self:OnVehicleDestroyed(vehicle);
	end,
	---------------------------
	--	OnLeaveVehicle			-- added 18.09
	---------------------------
	OnLeaveVehicle = function(self, vehicle, seat, player)
		local class = self.reviveSelector[player.id] and self.reviveSelector[player.id][1];
		if (class) then
			self.reviveSelector[player.id] = nil;
			--CryMP:DeltaTimer(1, function()
				--nCX.GiveItem("OffHand", player.Info.Channel, true, true); -- Grenade switching stuck fix
			--end);
			self:CommitRevivePurchases(player);
			player.actor:SelectItemByNameRemote(class);
		end
	end,
	---------------------------
	--	GetPlayerSpawnGroup    	 -- added 02.05
	---------------------------
	GetPlayerSpawnGroup = function(self, playerId)
		return nCX.GetPlayerSpawnGroup(playerId);
		--return self.spawnGroupIds[playerId];
	end,
	---------------------------
	--		OnSpawn
	---------------------------
	OnSpawn = function(self)
		self.g_collisionHitTypeId = nCX.GetHitTypeId("collision");
	end,
	---------------------------
	--		UpdateTimeLimit
	---------------------------
	UpdateTimeLimit = function(self)
		if (nCX.IsTimeLimited() and self:GetState() == "InGame" and not nCX.GameEnd) then
			local rt = math.floor(nCX.GetRemainingGameTime());
			if (rt <= 0) then				
				local nk = self:GetTeamPower(1);
				local us = self:GetTeamPower(2);
				local teamId;
				if (us > nk) then
					teamId = 2;
				elseif (nk > us) then
					teamId = 1;
				end
				if (not teamId) then
					if (not self.overtimeAdded) then
						local overtimeTime = 3;
						nCX.AddOvertime(overtimeTime);
						nCX.SendTextMessage(5, "@ui_msg_overtime_0", 0, tostring(overtimeTime));
						self.overtimeAdded = 1;
					else
						self:OnGameEnd(nil, 0);
					end
				else
					self:OnGameEnd(teamId, 2);
				end
			end
		end
		local timelimit = tonumber(nCX.Config.CVars["g_timelimit"] or "");
		if (timelimit and timelimit < 500) then
			if (nCX.GetTeamPlayerCount(1) + nCX.GetTeamPlayerCount(2) > 1) then
				if (not self.GameStarted) then
					System.ExecuteCommand("g_timelimit "..timelimit);
					self.GameStarted = true;
				end
			elseif (self.GameStarted) then
				System.ExecuteCommand("g_timelimit 0");
				self.GameStarted = false;
			end
		end
	end,
	---------------------------
	--		OnGameEnd
	---------------------------
	OnGameEnd = function(self, teamId, type, shooterId)
		self.allClients:ClVictory(teamId or 0, type or 0, shooterId or NULL_ENTITY);
		local curr = nCX.GetCurrentLevel():sub(13, -1):lower();
		local command = "sv_restart";
		if (nCX.NextMap) then
			local gr = nCX.MapList[nCX.NextMap];
			if (gr) then
				gr = gr == "TeamInstantAction" and "InstantAction" or gr;
				System.ExecuteCommand("sv_gamerules "..gr);
				command = "map "..nCX.NextMap;
				nCX.EndGame();
			end
		end
		CryMP:HandleEvent("OnGameEnd", {teamId, type, shooterId});
		CryMP:SetTimer(10, function()
			System.ExecuteCommand(command);
			nCX.NextMap = nil;
		end);		
		nCX.GameEnd = true;
	end,
	---------------------------
	--		OnLeaveCaptureZone	--added 10.06
	---------------------------
	CancelCapturing = function(self, player)
		local zoneId = self.inCaptureZone[player.id];
		if (zoneId) then
			local zone = System.GetEntity(zoneId);
			if (zone and zone.Server and zone.Server.OnLeaveArea) then
				zone.Server.OnLeaveArea(zone, player, false);
			end
		end
	end,
	---------------------------
	--		RevivePlayer		-- changed 03.07
	---------------------------
	RevivePlayer = function(self, player, groupId, keepEquip, angles)
		--System.LogAlways("RevivePlayer PS.lua");
		player.serverSeatExit = true;
		player.vehicleId = nil;
		local clearInventory = not keepEquip or player:IsDead();
		local channelId = player.Info.Channel;
		local typeGroupId = type(groupId);
		self:ResetUnclaimedVehicle(player.id, false);
		local vehicle;
		local pos = (typeGroupId == "table") and groupId;
		if (pos) then
			groupId = nil;
		end
		local groupId = groupId or nCX.GetPlayerSpawnGroup(player.id); -- self:GetPlayerSpawnGroup(player.id);
		if (pos) then
			nCX.RevivePlayer(player.id, pos, type(angles) == "table" and angles or player:GetWorldAngles(), clearInventory);
		else
			if (groupId and groupId ~= NULL_ENTITY) then
				local group = System.GetEntity(groupId);
				if (group) then
					if (group.actor) then
						group = group.actor:GetLinkedVehicle() or group; 
					end
					if (group.vehicle) then
						local seatId;
						for i, seat in pairs(group.Seats) do
							if (i > 2 and seat.seat:IsFree())  then   -- dont spawn in driver or gunner seat.. buggy
								seatId = i;
								break;
							end
						end
						nCX.RevivePlayerInVehicle(player.id, group.id, seatId or -1, clearInventory);
						vehicle = group;
						self.reviveSelector[player.id] = {"Fists", vehicle}; -- Initiate fix for no weapon in hands on leaving spawn vehicle
					elseif (group.actor) then
						local pos = group:GetWorldPos();
						local angles = group:GetWorldAngles();
						if (self.inCaptureZone[group.id]) then
							pos.z = pos.z + 100 + math.random(4);
						else
							pos.z = pos.z + 1.2;
						end
						nCX.RevivePlayer(player.id, pos, angles, clearInventory);
						vehicle = group;
					end
				end
			end
			if (not vehicle and groupId) then
				local spawn = nCX.GetSpawnLocationTeam(player.id, groupId);
				if (spawn) then
					local pos = spawn:GetWorldPos();
					local angles = spawn:GetWorldAngles();
					pos.z = pos.z + 0.5;
					nCX.RevivePlayer(player.id, pos, angles, clearInventory);
				end
			end
		end			
		self.reviveQueue[player.id] = nil;
		--player:UpdateAreas();
		--player.actor:SetSpectatorMode(0, NULL_ENTITY);
		local first = not nCX.Spawned[channelId];
		--if (first) then
		--	nCX.Spawned[channelId] = true;
		--end
		if (nCX.IsPlayerInGame(player.id)) then
			self.onClient:ClReviveCycle(channelId, false);
		end
		self:EquipPlayer(player, (vehicle and vehicle.vehicle));
		if (not pos) then
			CryMP:HandleEvent("OnRevive", {channelId, player, vehicle, first});
		end
		if (not vehicle) then
			self:CommitRevivePurchases(player); --if vehicle, bought on vehicle exit
		end
		local zoneId = self.inCaptureZone[player.id];
		local zone = zoneId and System.GetEntity(zoneId);
		if (zone and zone.IsInside and not zone:IsInside(player) and zone.Server and zone.Server.OnEnterArea) then
			zone.Server.OnEnterArea(zone, player, false);
		end
		player.serverSeatExit = nil;
		if (first) then
			nCX.Spawned[channelId] = true;
		end
		self.buySpam[player.id] = 0;
	end,
	---------------------------
	--		KillPlayer			-- updated 07.05
	---------------------------
	KillPlayer = function(self, player, punish, shooter)
		local shooter = shooter or player;
		local hit = {
			pos = player:GetWorldPos(),
			dir = {x=0,y=1,z=0},
			radius = 0,
			partId = -1,
			target = player,
			targetId = player.id,
			weapon = player,
			weaponId = player.id,
			shooter = shooter,
			shooterId = shooter.id,
			materialId = 0,
			damage = 0,
			typeId = nCX.GetHitTypeId("normal"),
			type = "normal",
			server = true,
		};
		local weaponId = hit.weaponId or (hit.weapon and hit.weapon.id) or NULL_ENTITY;
		nCX.KillPlayer(player.id, true, true, shooter.id, weaponId, hit.damage, hit.materialId, hit.typeId, hit.dir); 
		if (not punish) then
			self:OnKill(hit);
		end
		self:CancelCapturing(player);
	end,
	---------------------------
	--		OnKill -- called in C++
	---------------------------
	OnKill = function(self, hit) 
		local shooter = hit.shooter or hit.target;
		local target = hit.target;
		target.suicide = hit.self;
		if (not hit.server) then
			local rank = self.rankList[self:GetPlayerRank(target.id)];
			if (rank and rank.min_pp and rank.min_pp > 0) then
				local minAward = 100;
				minAward = math.max(minAward, rank.min_pp);
				local currentpp = self:GetPlayerPP(target.id);
				if (currentpp < minAward) then
					self:AwardPPCount(target.id, minAward-currentpp);  -- should be award before OnKill event (Equip purchase...)
				end
			end
		end
		local quit, hit = CryMP:HandleEvent("OnKill", {hit, shooter, target});
		if (not hit.server) then
			local sameTeam = nCX.IsSameTeam(shooter.id, target.id);
			if (hit.self or not sameTeam) then
				self:Award(hit, target);
			end
			local pp = self:CalcKillPP(hit);
			local cp = self:CalcKillCP(hit);
			if (hit.shooter and not hit.self and not sameTeam) then
				local quit = CryMP:HandleEvent("OnAwardKillPP", {shooter.id, pp, hit});
				if (not quit and shooter.actor) then
					self:AwardPPCount(shooter.id, pp);
					self:AwardCPCount(shooter.id, cp);
				end
			end
		end
		self:CancelCapturing(target);
	end,
	---------------------------
	--		OnVehicleKill
	---------------------------
	OnVehicleKill = function(self, vehicle, shooter, lastHit)
		local vehicleId = vehicle.id;
		local pp, cp, def = 10, 10;
		if (vehicle.builtas) then
			def = self:GetItemDef(vehicle.builtas);
			if (def) then
				pp = math.max(pp, math.floor(def.price*0.25));
				cp = math.max(cp, math.floor(def.price*0.25));
			end
		end
		if (lastHit) then
			pp, cp = pp * 0.5, cp * 0.5;
			--nCX.SendTextMessage(3, "VEHICLE:ASSIST-[ "..pp..":PRESTIGE ]", shooter.Info.Channel);
		end
		self:AwardPPCount(shooter.id, pp);
		self:AwardCPCount(shooter.id, cp);
		if (not lastHit) then
			CryMP:HandleEvent("OnProcessVehicleScores", {shooter, vehicle, def});
		end
	end,
	---------------------------
	--		Award
	---------------------------
	Award = function(self, hit, target)
		local shooter = hit.shooter;
		if (hit.self) then
			local suicides  = (nCX.GetSynchedEntityValue(target.id, 106) or 0) + 1;
			nCX.SetSynchedEntityValue(target.id, 106, suicides);
		end
	end,
	---------------------------
	--		EquipPlayer			-- changed 26.08
	---------------------------
	EquipPlayer = function(self, player, reviveInVehicle)
		local channelId = player.Info.Channel;
		nCX.GiveItem("Binoculars", channelId, false, false);
		nCX.GiveItem("Parachute", channelId, false, false);		
	end,
	---------------------------
	--		OnPurchaseCancelled		-- changed 09.05
	---------------------------
	OnPurchaseCancelled = function(self, playerId, teamId, itemName)
		local price, energy = self:GetPrice(itemName);
		if (price > 0) then
			self:AwardPPCount(playerId, price);
		end
		if (energy > 0) then
			self:SetTeamPower(teamId, self:GetTeamPower(teamId) + energy);
		end
	end,
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		self.Server.OnReset(self);
	end,
	---------------------------
	--		UpdateSpawnGroupSelection	-- changed 11.05
	---------------------------
	UpdateSpawnGroupSelection = function(self, playerId)
		local teamId = nCX.GetTeam(playerId);
		local players = teamId == 0 and nCX.GetPlayers() or nCX.GetTeamPlayers(teamId);
		if (players) then
			for i, player in pairs(players) do
				if (player.id ~= playerId) then
					local channelId = player.Info.Channel;
					if (channelId > 0) then
						local groupId = nCX.GetPlayerSpawnGroup(player.id); --self:GetPlayerSpawnGroup(player.id);
						if (groupId) then
							self.onClient:ClSetPlayerSpawnGroup(channelId, playerId, groupId or NULL_ENTITY);
						end
					end
				end
			end
		end
	end,
	---------------------------
	--		QueueRevive				
	---------------------------
	QueueRevive = function(self, player, invalid)
		local playerId = player.id;
		local channelId = player.Info.Channel;
		if (channelId < 1) then
			return;
		end
		if (self.reviveQueue[playerId]) then
			self.reviveQueue[playerId] = nil;
			self.onClient:ClReviveCycle(channelId, false);
			return;
		end
		self.onClient:ClReviveCycle(channelId, true);
		self.reviveQueue[playerId] = {};
		local groupId = nCX.GetPlayerSpawnGroup(playerId) or NULL_ENTITY; --self:GetPlayerSpawnGroup(playerId) or NULL_ENTITY;
		if (groupId == NULL_ENTITY or not nCX.IsSameTeam(playerId, groupId)) then
			if (invalid) then
				self.reviveQueue[playerId].overdue = true;
				if (channelId > 0) then
					self.onClient:ClSpawnGroupInvalid(channelId, groupId); 
				end
			else
				local teamId = nCX.GetTeam(playerId);
				self.Server.RequestSpawnGroup(self, playerId, nCX.GetTeamDefaultSpawnGroup(teamId) or NULL_ENTITY, true);
			end
		end
		self.channelSpectatorMode[channelId] = nil;
	end,
	---------------------------
	--		GetPurchaseCart			 -- added 10.05
	---------------------------
	GetPurchaseCart = function(self, playerId, type)
		if (not type) then
			return self.revivePurchases[playerId];
		end
		return self.revivePurchases[playerId] and self.revivePurchases[playerId][type];
	end,
	---------------------------
	--		AddToPurchaseCart		-- added 10.05
	---------------------------
	AddToPurchaseCart = function(self, playerId, type, item, count)
		self.revivePurchases[playerId] = self.revivePurchases[playerId] or {};
		local cart = self.revivePurchases[playerId];
		cart[type] = cart[type] or {};
		if (count) then
			cart[type][item] = count;
		else
			cart[type][#cart[type] + 1] = item;
		end
	end,
	---------------------------
	--		CommitRevivePurchases	-- changed 11.05
	---------------------------
	CommitRevivePurchases = function(self, player, vehicle)
		local buy = self:GetPurchaseCart(player.id);
		if (buy) then
			local class;
			if (buy[1]) then
				for ammo,c in pairs(buy[1]) do
					player.actor:SetInventoryAmmo(ammo, c, 3);
				end
			end
			if (buy[2]) then
				for i, itemName in pairs(buy[2]) do
					local ok = self:BuyItem(player, itemName, true, true);
					if (not ok) then
						break;
					end
				end
			end
			self.revivePurchases[player.id] = nil;
		end
	end,
	---------------------------
	--		SendMDAlert			-- changed 06.11
	---------------------------
	SendMDAlert = function(self, teamId, name, playerId)
		local ids = { [1] = 2, [2] = 1, };
		local id = ids[teamId];
		if (id) then
			local players = nCX.GetTeamPlayers(id);
			if (players) then
				for i, player in pairs(players) do
					self.onClient:ClMDAlert(player.Info.Channel, name);
				end
			end
		end
		self.onClient:ClMDAlert_ToPlayer(nCX.GetChannelId(playerId));
	end,
	---------------------------
	--		OnNuclearWarfare	-- added 06.11
	---------------------------
	OnNuclearWarfare = function(self, teamId, itemName, itemId, playerId)
		self:SendMDAlert(teamId, itemName, playerId);
		nCX.AddMinimapEntity(itemId, 2, 0);
		if (self.objectives and itemName:find("tac")) then
			for i,v in pairs(self.objectives) do
				if (v.OnNuclearWarfare) then
					v:OnNuclearWarfare(teamId);
				end
			end
		end
		CryMP:SetTimer(1, function()
			self.allClients:ClEndGameNear(itemId);
		end);
	end,
	---------------------------
	--		BuyList
	---------------------------
	buyList = {
		--weaponList
		["flashbang"]			= { id="flashbang",			name="@mp_eFlashbang",		price=10, 		amount=1, ammo=true, weapon=false, category="@mp_catExplosives", loadout=1},
		["smokegrenade"] 		= { id="smokegrenade",		name="@mp_eSmokeGrenade",	price=10, 		amount=1, ammo=true, weapon=false, category="@mp_catExplosives", loadout=1 },
		["explosivegrenade"] 	= { id="explosivegrenade",	name="@mp_eFragGrenade",	price=25, 		amount=1, ammo=true, weapon=false, category="@mp_catExplosives", loadout=1 },
		["empgrenade"] 			= { id="empgrenade",		name="@mp_eEMPGrenade",		price=50,		amount=1, ammo=true, weapon=false, category="@mp_catExplosives", loadout=1 },
		["pistol"] 				= { id="pistol",			name="@mp_ePistol", 		price=50, 		class="SOCOM",						category="@mp_catWeapons", loadout=1, 		uniqueloadoutgroup=3, uniqueloadoutcount=2},
		["claymore"] 			= { id="claymore",			name="@mp_eClaymore",		price=25,		class="Claymore",				amount=1,	buyammo="claymoreexplosive",	selectOnBuyAmmo="true", category="@mp_catExplosives", loadout=1 },
		["avmine"] 				= { id="avmine",			name="@mp_eMine",			price=25,		class="AVMine",					amount=1,	buyammo="avexplosive",				selectOnBuyAmmo="true", category="@mp_catExplosives", loadout=1 },
		["c4"] 					= { id="c4",				name="@mp_eExplosive", 		price=50, 		class="C4", 							buyammo="c4explosive",				selectOnBuyAmmo="true", category="@mp_catExplosives", loadout=1 },
		["shotgun"] 			= { id="shotgun",           name="@mp_eShotgun", 		price=50, 		class="Shotgun", 					uniqueId=4,		category="@mp_catWeapons", loadout=1, 		uniqueloadoutgroup=1, uniqueloadoutcount=2},
		["smg"] 				= { id="smg",               name="@mp_eSMG", 			price=75, 		class="SMG", 							uniqueId=5,		category="@mp_catWeapons", loadout=1, 		uniqueloadoutgroup=1, uniqueloadoutcount=2},
		["fy71"] 				= { id="fy71",				name="@mp_eFY71", 			price=125, 		class="FY71", 						uniqueId=6,		category="@mp_catWeapons", loadout=1, 	uniqueloadoutgroup=1, uniqueloadoutcount=2},
		["macs"]				= { id="macs",              name="@mp_eSCAR", 			price=150, 		class="SCAR", 						uniqueId=7,		category="@mp_catWeapons", loadout=1, 		uniqueloadoutgroup=1, uniqueloadoutcount=2},
		["rpg"] 				= { id="rpg",               name="@mp_eML", 			price=200, 		class="LAW", 							uniqueId=8,		category="@mp_catExplosives", loadout=1},
		["dsg1"] 				= { id="dsg1",				name="@mp_eSniper"	,		price=350, 		class="DSG1", 						uniqueId=9,		category="@mp_catWeapons", loadout=1, uniqueloadoutgroup=1, uniqueloadoutcount=2},
		["gauss"] 				= { id="gauss",				name="@mp_eGauss", 			price=1000, 	class="GaussRifle",			        uniqueId=10,	category="@mp_catWeapons", loadout=1, 		uniqueloadoutgroup=1, uniqueloadoutcount=2},
		--equipList
		["binocs"] 				= { id="binocs",			name="@mp_eBinoculars",		price=50,		class="Binoculars", 	uniqueId=101,	category="@mp_catEquipment", loadout=1 },
		["nsivion"] 			= { id="nsivion",			name="@mp_eNightvision", 	price=10, 		class="NightVision", 	uniqueId=102,	category="@mp_catEquipment", loadout=1 },
		["pchute"]				= { id="pchute",			name="@mp_eParachute",		price=25,		class="Parachute",		uniqueId=103,	category="@mp_catEquipment", loadout=1 },
		["lockkit"]				= { id="lockkit",			name="@mp_eLockpick",		price=25, 		class="LockpickKit",	uniqueId=110,	category="@mp_catEquipment", loadout=1, 	uniqueloadoutgroup=2, uniqueloadoutcount=1},
		["repairkit"] 			= { id="repairkit",			name="@mp_eRepair",			price=50, 		class="RepairKit", 		uniqueId=110,	category="@mp_catEquipment", loadout=1, 	uniqueloadoutgroup=2, uniqueloadoutcount=1},
		["radarkit"] 			= { id="radarkit",			name="@mp_eRadar",			price=50, 		class="RadarKit", 		uniqueId=110,	category="@mp_catEquipment", loadout=1, 	uniqueloadoutgroup=2, uniqueloadoutcount=1},
		--protoList
		["moac"] 				= { id="moac",				name="@mp_eAlienWeapon", 	price=300, 		class="AlienMount", 	level=50,	uniqueId=11,	category="@mp_catWeapons", loadout=1, 		uniqueloadoutgroup=1, uniqueloadoutcount=2},
		["moar"] 				= { id="moar",				name="@mp_eAlienMOAR", 		price=100, 		class="MOARAttach", 	level=50,	uniqueId=12,	category="@mp_catWeapons", loadout=1 },
		["minigun"] 			= { id="minigun",			name="@mp_eMinigun",		price=250, 		class="Hurricane", 		level=50,	uniqueId=13,	category="@mp_catWeapons", loadout=1, 		uniqueloadoutgroup=1, uniqueloadoutcount=2},
		["tacgun"] 				= { id="tacgun",			name="@mp_eTACLauncher", 	price=1000, 	class="TACGun", 		level=100,	restricted=1,	energy=5, uniqueId=14,	category="@mp_catWeapons", md=true, loadout=1, uniqueloadoutgroup=1, uniqueloadoutcount=2},
		["usmoac4wd"] 			= { id="usmoac4wd",			name="@mp_eMOACVehicle",	price=300, 		class="US_ltv", 		level=50, 	modification="MOAC", 				vehicle=true, buildtime=10,	category="@mp_catVehicles", loadout=0 },
		["usmoar4wd"] 			= { id="usmoar4wd",			name="@mp_eMOARVehicle",	price=350,		class="US_ltv", 		level=50,	modification="MOAR", 				vehicle=true, buildtime=10,	category="@mp_catVehicles", loadout=0 },
		["ussingtank"] 			= { id="ussingtank",		name="@mp_eSingTank",		price=2500, 	class="US_tank",		level=100, 	energy=10, modification="Singularity",	vehicle=true, md=true, buildtime=45,	category="@mp_catVehicles", loadout=0 },
		["ustactank"] 			= { id="ustactank",			name="@mp_eTACTank",		price=1500,		class="US_tank", 		level=100, 	energy=10, modification="TACCannon",		vehicle=true, md=true, buildtime=45,	category="@mp_catVehicles", loadout=0 },
		["nktactank"] 			= { id="nktactank",			name="@mp_eLightTACTank",	price=1000,		class="Asian_tank", 	level=100, 	energy=10, modification="TACCannon",		vehicle=true, md=true, buildtime=45,	category="@mp_catVehicles", loadout=0 },
		--vehicleList
		["light4wd"] 			= { id="light4wd",			name="@mp_eLightVehicle", 	price=0,		class="US_ltv",				modification="Unarmed", 	buildtime=5,		category="@mp_catVehicles", loadout=0 },
		["us4wd"] 				= { id="us4wd",				name="@mp_eHeavyVehicle", 	price=0,		class="US_ltv",				modification="MP",			buildtime=5,		category="@mp_catVehicles", loadout=0 },
		["usgauss4wd"] 			= { id="usgauss4wd",		name="@mp_eGaussVehicle",	price=200,		class="US_ltv", 			modification="Gauss",		buildtime=10,		category="@mp_catVehicles", loadout=0 },
		["nktruck"] 			= { id="nktruck",			name="@mp_eTruck",			price=0,		class="Asian_truck", 		modification="Hardtop_MP",	buildtime=5,		category="@mp_catVehicles", loadout=0 },
		["ussupplytruck"] 		= { id="ussupplytruck",		name="@mp_eSupplyTruck",	price=150,		class="Asian_truck",		modification="spawntruck",	buildtime=15,		category="@mp_catVehicles", loadout=0, teamlimit = 3, spawngroup = true, buyzoneradius = 11, servicezoneradius = 11, buyzoneflags = 13,},
		["usboat"] 				= { id="usboat",			name="@mp_eSmallBoat", 		price=0,		class="US_smallboat", 		modification="MP", 			buildtime=5,		category="@mp_catVehicles", loadout=0 },
		["nkboat"] 				= { id="nkboat",			name="@mp_ePatrolBoat", 	price=100,		class="Asian_patrolboat", 	modification="MP", 			buildtime=10,		category="@mp_catVehicles", loadout=0 },
		["nkgaussboat"] 		= { id="nkgaussboat",		name="@mp_eGaussPatrolBoat",price=200,		class="Asian_patrolboat", 	modification="Gauss", 		buildtime=10,		category="@mp_catVehicles", loadout=0 },
		["ushovercraft"] 		= { id="ushovercraft",		name="@mp_eHovercraft", 	price=100,		class="US_hovercraft",		modification="MP", 			buildtime=10,		category="@mp_catVehicles", loadout=0 },
		["nkaaa"] 				= { id="nkaaa",				name="@mp_eAAVehicle",		price=200,		class="Asian_aaa", 			modification="MP",			buildtime=15,		category="@mp_catVehicles", loadout=0 },
		["usasv"] 				= { id="usasv",				name="@mp_eASV",			price=250,		class="US_asv",											buildtime=15,		category="@mp_catVehicles", loadout=0 },
		["usapc"] 				= { id="usapc",				name="@mp_eICV",			price=300,		class="US_apc", 										buildtime=20,		category="@mp_catVehicles", loadout=0 },
		["nkapc"] 				= { id="nkapc",				name="@mp_eAPC",			price=350,		class="Asian_apc", 										buildtime=20,		category="@mp_catVehicles", loadout=0 },
		["nktank"] 				= { id="nktank",			name="@mp_eLightTank", 		price=400,		class="Asian_tank",										buildtime=25,		category="@mp_catVehicles", loadout=0 },
		["ustank"] 				= { id="ustank",			name="@mp_eBattleTank",		price=450,		class="US_tank", 			modification="MP", 			buildtime=30,		category="@mp_catVehicles", loadout=0 },
		["usgausstank"] 		= { id="usgausstank",		name="@mp_eGaussTank",		price=500,		class="US_tank", 			modification="GaussCannon", buildtime=35,		category="@mp_catVehicles", loadout=0 },
		["nkhelicopter"] 		= { id="nkhelicopter",		name="@mp_eHelicopter",		price=350,		class="Asian_helicopter",	modification="MP",			buildtime=20,		category="@mp_catVehicles", loadout=0 },
		["usvtol"] 				= { id="usvtol",			name="@mp_eVTOL", 			price=800,		class="US_vtol", 			modification="MP",			buildtime=20, 		category="@mp_catVehicles", loadout=0 },
		--ammoList
		[""] 					= { id="",					name="@mp_eAutoBuy",		price=0,								category="@mp_catAmmo", loadout=1 },
		["bullet"] 				= { id="bullet",			name="@mp_eBullet", 		price=5,		amount=40,				category="@mp_catAmmo", loadout=1 },
		["fybullet"] 			= { id="fybullet",			name="@mp_eFYBullet", 		price=5,		amount=30,				category="@mp_catAmmo", loadout=1 },
		["shotgunshell"] 		= { id="shotgunshell",		name="@mp_eShotgunShell",	price=5,		amount=8,				category="@mp_catAmmo", loadout=1 },
		["smgbullet"]			= { id="smgbullet",			name="@mp_eSMGBullet",		price=5,		amount=50,				category="@mp_catAmmo", loadout=1 },
		["lightbullet"] 		= { id="lightbullet",		name="@mp_eLightBullet",	price=5,		amount=40,				category="@mp_catAmmo", loadout=1 },
		["sniperbullet"] 		= { id="sniperbullet",		name="@mp_eSniperBullet",	price=10,		amount=10,				category="@mp_catAmmo", loadout=1 },
		["scargrenade"] 		= { id="scargrenade",		name="@mp_eRifleGrenade",	price=100,		amount=1,				category="@mp_catAmmo", loadout=1 },
		["gaussbullet"] 		= { id="gaussbullet",		name="@mp_eGaussSlug",		price=50,		amount=5, level=50, 	category="@mp_catAmmo", loadout=1 },
		["incendiarybullet"] 		= { id="incendiarybullet",						    price=50,		amount=30,		invisible=true,		category="@mp_catAmmo", loadout=1 },	
		["hurricanebullet"] 	= { id="hurricanebullet",	name="@mp_eMinigunBullet",	price=100,		amount=500,				category="@mp_catAmmo", loadout=1 },
		["claymoreexplosive"] 	= { id="claymoreexplosive",	class = "Claymore",			price=25,		amount=1,			invisible=true,		category="@mp_catAmmo", loadout=1 },
		["avexplosive"] 		= { id="avexplosive",		class = "AVMine",			price=25,		amount=1,			invisible=true,		category="@mp_catAmmo", loadout=1 },
		["c4explosive"] 		= { id="c4explosive",									price=50,		amount=1,			invisible=true,		category="@mp_catAmmo", loadout=1 },
		["Tank_singularityprojectile"] = { id="Tank_singularityprojectile",	name="@mp_eSingularityShell", price=200,		amount=1,					category="@mp_catAmmo", loadout=0, vehicleammo=1},
		["towmissile"] 			= { id="towmissile",		name="@mp_eAPCMissile",		price=50,		amount=2,					category="@mp_catAmmo", loadout=0, vehicleammo=1 },
		["dumbaamissile"] 		= { id="dumbaamissile",		name="@mp_eAAAMissile",		price=50,		amount=4,					category="@mp_catAmmo", loadout=0, vehicleammo=1 },
		["tank125"] 			= { id="tank125",			name="@mp_eTankShells",		price=100,		amount=10,				category="@mp_catAmmo", loadout=0, vehicleammo=1 },
		["helicoptermissile"] 	= { id="helicoptermissile",	name="@mp_eHelicopterMissile",price=100,	amount=7,					category="@mp_catAmmo", loadout=0, vehicleammo=1 },
		["tank30"] 				= { id="tank30",			name="@mp_eAPCCannon",		price=100,		amount=100,				category="@mp_catAmmo", loadout=0, vehicleammo=1 },
		["tankaa"] 				= { id="tankaa",			name="@mp_eAAACannon",		price=100,		amount=250,				category="@mp_catAmmo", loadout=0, vehicleammo=1 },
		["a2ahomingmissile"] 	= { id="a2ahomingmissile",	name="@mp_eVTOLMissile",	price=100,		amount=6,					category="@mp_catAmmo", loadout=0, vehicleammo=1 },
		["gausstankbullet"] 	= { id="gausstankbullet",	name="@mp_eGaussTankSlug",	price=100,		amount=10,				category="@mp_catAmmo", loadout=0, vehicleammo=1 },
		["tacgunprojectile"]    = { id="tacgunprojectile",name="@mp_eTACGrenade",		price=200,		amount=1,	ammo=true, 			level=100,		category="@mp_catAmmo", loadout=1 },		
		["tacprojectile"] 		= { id="tacprojectile",		name="@mp_eTACTankShell",	price=200,		amount=1,	ammo=true, 			level=100,		category="@mp_catAmmo", vehicleammo=1 },
		["iamag"]			    = { id="iamag",				name="@mp_eIncendiaryBullet",price=50, 		class="FY71IncendiaryAmmo",			ammo=false, equip=true, 	buyammo="incendiarybullet", category="@mp_catAddons", loadout=1 },	
		["psilent"] 			= { id="psilent",			name="@mp_ePSilencer",		price=10, 		class="SOCOMSilencer",			uniqueId=121, ammo=false, equip=true,		category="@mp_catAddons", loadout=1 },
		["plam"] 				= { id="plam",				name="@mp_ePLAM",			price=25, 		class="LAM",				uniqueId=122, ammo=false, equip=true,		category="@mp_catAddons", loadout=1 },
		["silent"] 				= { id="silent",			name="@mp_eRSilencer",		price=10, 		class="Silencer", 				uniqueId=123, ammo=false, equip=true,		category="@mp_catAddons", loadout=1 },
		["lam"] 				= { id="lam",				name="@mp_eRLAM",			price=25, 		class="LAMRifle",						uniqueId=124, ammo=false, equip=true,		category="@mp_catAddons", loadout=1 },
		["reflex"] 				= { id="reflex",			name="@mp_eReflex",			price=25,		class="Reflex", 					uniqueId=125, ammo=false, equip=true,		category="@mp_catAddons", loadout=1 },
		["ascope"]				= { id="ascope",			name="@mp_eAScope",			price=50, 		class="AssaultScope", 			uniqueId=126, ammo=false, equip=true,		category="@mp_catAddons", loadout=1 },
		["scope"] 				= { id="scope",				name="@mp_eSScope",			price=100, 		class="SniperScope", 			uniqueId=127, ammo=false, equip=true,		category="@mp_catAddons", loadout=1 },
		["gl"] 					= { id="gl",				name="@mp_eGL",				price=50, 		class="GrenadeLauncher",		uniqueId=128, ammo=false, equip=true,		category="@mp_catAddons", loadout=1 },
	},
	---------------------------
	--		SetPlayerPP
	---------------------------
	SetPlayerPP = function(self, playerId, pp)
		pp = math.min(9999999, math.max(0, math.floor(pp)))
		nCX.SetSynchedEntityValue(playerId, 200, pp);
		return pp;
	end,
	---------------------------
	--		GetPlayerPP
	---------------------------
	GetPlayerPP = function(self, playerId)
		return nCX.GetSynchedEntityValue(playerId, 200) or 0;
	end,
	---------------------------
	--		CalcKillPP
	---------------------------
	CalcKillPP = function(self, hit)
		local shooter, target = hit.shooter, hit.target;
		if (shooter and target ~= shooter) then
			if (not nCX.IsSameTeam(shooter.id, target.id)) then
				local ownRank = self:GetPlayerRank(shooter.id);
				local enemyRank = self:GetPlayerRank(target.id);
				local bonus = 0;
				if (hit.headshot) then
					bonus = bonus + 50;
				end
				if (hit.typeId == 9) then -- melee
					bonus = bonus + 50;
				end
				local rankDiff = enemyRank - ownRank;
				if (rankDiff ~= 0) then
					bonus = bonus + rankDiff * 10;
				end
				local zoneId = self.inCaptureZone[target.id];
				if (zoneId and nCX.IsSameTeam(zoneId, shooter.id)) then
					bonus = bonus + 100;
				end
				return math.max(0, 100 + bonus);
			else
				return -200;
			end
		else
			return 0;
		end
	end,
	---------------------------
	--		AwardPPCount		-- changed 01.06
	---------------------------
	AwardPPCount = function(self, playerId, c, kill)
		local channelId = nCX.GetChannelId(playerId);
		if (channelId > 0 and c ~= 0) then
			local total = self:GetPlayerPP(playerId) + c;
			if (total < 0) then
				return;
			end
			total = self:SetPlayerPP(playerId, total);
			if (kill ~= -1) then
				self.onClient:ClPP(channelId, c);
			end
			CryAction.SendGameplayEvent(playerId, 10, nil, total);
			CryAction.SendGameplayEvent(playerId, 10, nil, c);
		end
	end,
	---------------------------
	--		GetPrice			-- changed 08.05
	---------------------------
	GetPrice = function(self, itemName)
		if (not itemName) then
			return 0, 0;
		end
		local entry = self.buyList[itemName];
		local price, energy = 0, 0;
		if (entry) then
			price, energy = (entry.price or 0), (entry.energy or 0);
		end
		if (price > 0) then
			local g_pp_scale_price = System.GetCVar("g_pp_scale_price");
			if (g_pp_scale_price) then
				price = math.floor(price * math.max(0, g_pp_scale_price));
			end
		end
		return price, energy;
	end,
	---------------------------
	--		EnoughPP			-- changed 08.05
	---------------------------
	EnoughPP = function(self, playerId, itemName, price)
		price = price or self:GetPrice(itemName);
		local pp = self:GetPlayerPP(playerId);
		if (price > pp) then
			local channelId = nCX.GetChannelId(playerId);
			if (channelId > 0 and itemName) then
				nCX.SendTextMessage(2, "You need "..(price-pp).." more prestige for '"..itemName.."' ( COST : "..price.." )", channelId);
				nCX.SendConsoleMessage(channelId, "You need $7"..(price-pp).." $9more prestige for '$4"..itemName.."$9' ($4"..price.."$9)");
			end
			return false;
		end
		return true;
	end,
	---------------------------
	--		GetItemName
	---------------------------
	GetItemName = function(self, itemName)
		if (not itemName) then
			return "";
		end
		local entry = self.buyList[itemName];
		if (entry) then
			return entry.name;
		end
		return itemName;
	end,
	---------------------------
	--		GetItemDef			-- changed 02.06
	---------------------------
	GetItemDef = function(self, itemName, class)
		if (class) then
			for name, entry in pairs(self.buyList) do
				if (entry.name == itemName or entry.class == itemName) then
					return entry;
				end
			end
		end
		return self.buyList[itemName];
	end,
	---------------------------
	--		GetVehicleName			-- changed 02.06
	---------------------------
	GetVehicleName = function(self, itemName)
		local v = self.buyList[itemName];
		if (v and v.type and v.name) then
			return v.name.." "..v.type;
		end
		return itemName;
	end,
	---------------------------
	--		ItemExists
	---------------------------
	ItemExists = function(self, itemName)
		--if (self.buyList[itemName] == nil) then
		--	System.LogAlways("$4Item "..itemName.." doesnt exist!");
		--end
		return self.buyList[itemName] ~= nil;
	end,
	---------------------------
	--		IsVehicle			-- changed 08.05
	---------------------------
	IsVehicle = function(self, itemName)
		return self:ItemExists(itemName) and self.buyList[itemName].category == "@mp_catVehicles";
	end,
	---------------------------
	--		IsWeapon			
	---------------------------
	IsWeapon = function(self, itemName)
		return self:ItemExists(itemName) and self.buyList[itemName].category == "@mp_catWeapons"
	end,
	---------------------------
	--		IsAttachment			
	---------------------------
	IsAttachment = function(self, itemName)
		return self:ItemExists(itemName) and self.buyList[itemName].equip;
	end,
	---------------------------
	--		CheckBuyLimit		-- changed 16.06
	---------------------------
	CheckBuyLimit = function(self, channelId, itemName, teamId, teamOnly)
		local def = self:GetItemDef(itemName);
		if (not def) then
			return false;
		end
		if (def.minplayers) then
			local count = nCX.GetPlayerCount();
			if (count < def.minplayers) then
				if (channelId) then
					nCX.SendTextMessage(2, "At least "..def.minplayers.." players have to be in game to buy "..itemName, channelId);
					nCX.SendConsoleMessage(channelId, "At least $7"..def.minplayers.." $9players have to be in game to buy '$4"..itemName.."$9'");
				end
				return false;
			end
		end
		if (def.limit and not teamOnly) then
			local current = self:GetActiveItemCount(itemName);
			if (current >= def.limit) then
				if (channelId) then
					nCX.SendTextMessage(2, "@mp_GlobalItemLimit", channelId, def.name);
				end
				return false;
			end
		end
		if (teamId and def.teamlimit) then
			local current = self:GetActiveItemCount(itemName, teamId);
			if (current >= def.teamlimit) then
				if (channelId) then
					nCX.SendTextMessage(2, "@mp_TeamItemLimit", channelId, def.name);
				end
				return false, true;
			end
		end
		return true;
	end,
	---------------------------
	--	VehicleCanUseAmmo		-- changed 02.06
	---------------------------
	VehicleCanUseAmmo = function(self, vehicle, ammo)
		--[[for i = 1, 2 do
			local seat = vehicle.Seats[i];
			if (seat) then
				local weaponCount = seat.seat:GetWeaponCount();
				for j = 1, weaponCount do
					local weaponId = seat.seat:GetWeaponId(j);
					if (weaponId) then
						local weapon = System.GetEntity(weaponId);
						if (weapon) then
							local weaponAmmo = weapon.weapon:GetAmmoType();
							if ((weaponAmmo == ammo or ammo == false) and weapon.weapon:GetClipSize() ~= -1) then
								return true;
							end
						end
					end
				end
			end
		end--]]
		local ammoCapacity = vehicle.inventory:GetAmmoCapacity(ammo);
		return ammoCapacity > 0;
	end,
	---------------------------
	--	GetActiveItems       -- changed 02.06
	---------------------------
	GetActiveItems = function(self, itemName, teamId, armor, def)
		local def = def or self:GetItemDef(itemName, true);
		local temp = {};
		if (def) then
			local entities=System.GetEntitiesByClass(def.class);
			if (entities) then
				for i, entity in pairs(entities) do
					if (entity and entity.builtas==def.id and (not armor or self:VehicleCanUseAmmo(entity, false))) then
						if (not teamId or nCX.GetTeam(entity.id)==teamId) then
							temp[#temp + 1] = entity;
						end
					end
				end
			end
		end
		return temp;
	end,
	---------------------------
	--	GetActiveItemCount       -- changed 08.05
	---------------------------
	GetActiveItemCount = function(self, itemName, teamId, armor)
		local def=self:GetItemDef(itemName);
		if (not def) then
			return 0;
		end
		if (not def.class) then
			return -1;
		end
		return #self:GetActiveItems(itemName, teamId, armor, def);
	end,
	---------------------------
	--		DoBuyAmmo			-- changed 29.05
	---------------------------
	DoBuyAmmo = function(self, player, name, noPrice)
		local def = self:GetItemDef(name);
		if (not def) then
			return false;
		end
		local playerId, channelId = player.id, player.Info.Channel;
		local alive = not player.actor:IsDead();
		local vehicle = player.actor:GetLinkedVehicle();
		local service = (vehicle and (not vehicle.buyFlags or vehicle.buyFlags == 0));
	    local price, energy = self:GetPrice(name);
		if (noPrice) then
			price = 0;
		end
		local teamId = nCX.GetTeam(playerId);
		if (def.level and def.level > 0) then
			local zones = self.inBuyZone[playerId];
			if (service) then
				zones = self.inServiceZone[playerId];
			end
			local protoId = self.PrototypeId;
			local ok = false; 
			if (zones and protoId) then
				if (zones[protoId] and def.level <= self:GetTeamPower(teamId) and nCX.IsSameTeam(protoId, playerId)) then
					ok = true; 
				end
			end
			if (not ok) then
				nCX.SendTextMessage(2, "@mp_AlienEnergyRequired", channelId, def.name);
				return false;
			end
		end
		if (service) then
			if (alive) then
				if (self:IsInServiceZone(playerId) and (price==0 or self:EnoughPP(playerId, nil, price)) and self:VehicleCanUseAmmo(vehicle, name)) then
					local c=vehicle.inventory:GetAmmoCount(name) or 0;
					local m=vehicle.inventory:GetAmmoCapacity(name) or 0;
					if (c < m or m == 0) then
						local need=def.amount;
						if (m > 0) then
							need=math.min(m-c, def.amount);
						end
						vehicle.vehicle:SetAmmoCount(name, c+need);
						if (price > 0) then
							if (need < def.amount) then
								price=math.ceil((need*price)/def.amount);
							end
							self:AwardPPCount(playerId, -price);
						end
						return true;
					end
				end
			end
		elseif (self:IsInBuyZone(playerId) or not alive) and (price==0 or self:EnoughPP(playerId, nil, price)) then
			local c=player.inventory:GetAmmoCount(name) or 0;
			local m=player.inventory:GetAmmoCapacity(name) or 0;
			if (not alive) then
				local ammo = self:GetPurchaseCart(playerId, 1);
				if (ammo) then
					c = ammo[name] or 0;
				end
			end
			if (c < m or m == 0) then
				local need=def.amount;
				if (m > 0) then
					need=math.min(m-c, def.amount);
				end
				if (alive) then
					player.actor:SetInventoryAmmo(name, c + need, 3);
				else
					self:AddToPurchaseCart(playerId, 1, name, c + need);
					player.actor:SetInventoryAmmo(name, c + need, 3);
				end
				if (price > 0) then
					if (need < def.amount) then
						price = math.ceil((need * price)/def.amount);
					end
					self:AwardPPCount(playerId, -price);
				end
				return true, def;
			end
		end
		return false;
	end,
	---------------------------
	--		BuyItem				-- changed 29.05
	---------------------------
	BuyItem = function(self, player, itemName, noPrice, equip)
		local playerId, channelId = player.id, player.Info.Channel;
		local def = self:GetItemDef(itemName);
		if (not def) then
			return false;
		elseif (def.ammo) then
			return self:DoBuyAmmo(player, itemName, noPrice);
		end
		if (def.buyammo and player.inventory and player.inventory:GetItemByClass(def.class)) then
			local ret = self:DoBuyAmmo(player, def.buyammo, noPrice);
			if (def.selectOnBuyAmmo and ret) then
				player.actor:SelectItemByNameRemote(def.class);
			end
			return ret;
		elseif (def.uniqueId and not equip) then
			local hasUnique, currentUnique = self:HasUniqueItem(player, def.uniqueId);
			if (hasUnique) then
				local equipCategory = def.category == "@mp_catEquipment";
				if (self.IsSmallMap) then
					if (equipCategory) then
						nCX.SendTextMessage(2, "@mp_CannotCarryMoreKit", channelId);
					else
						nCX.SendTextMessage(2, "@mp_CannotCarryMore", channelId);
					end
					return false;
				elseif (not equipCategory) then
					nCX.SendTextMessage(2, "@mp_CannotCarryMore", channelId);
					return false;
				end
			end
		end
		local alive = not player.actor:IsDead();
		local price, energy = self:GetPrice(def.id);
		local teamId = nCX.GetTeam(playerId);
		if (def.level and def.level > 0) then
			local zones = self.inBuyZone[playerId];
			local protoId = self.PrototypeId;
			local power = 0;
			if (protoId and nCX.IsSameTeam(protoId, playerId) and (equip or (zones and zones[protoId]))) then
				power = self:GetTeamPower(teamId);
			end
			if (def.level > power) then
				nCX.SendTextMessage(2, "@mp_AlienEnergyRequired", channelId, def.name);
				return false;
			end
		end
		local limitOk = self:CheckBuyLimit(channelId, itemName, teamId);
		if (not limitOk) then
			return false;
		end
		local ok = true;
		if (alive) then
			ok = equip or player.actor:CheckInventoryRestrictions(def.class);
		elseif (not equip) then
			local items = self:GetPurchaseCart(playerId, 2);
			if (items and #items > 0) then
				local inventory={};
				for i, v in pairs(items) do
					local item=self:GetItemDef(v);
					if (item) then
						inventory[#inventory+1] = item.class;
					end
				end
				ok = player.actor:CheckVirtualInventoryRestrictions(inventory, def.class);
			end
		end
		if (ok) then
			if (alive) then
				if (energy > 0) then
					self:SetTeamPower(teamId, self:GetTeamPower(teamId)-energy);
				end
				if (self.reviveSelector[player.id]) then
					self.reviveSelector[player.id][1]= def.class;  -- Select last purchased item on leaving spawn vehicle 
				end
				--Try to attach accessory to weapon, Wars style..
				if (self:IsAttachment(itemName)) then
					local weapon = player.inventory:GetCurrentItem();
					if (weapon and not weapon.weapon:GetAccessory(def.class)) then
						weapon.weapon:AttachAccessory(def.class);
						weapon.weapon:NotifyAccessoriesChanged(); --update attachment saver
					end
				end
			elseif (energy <= 0) then
				self:AddToPurchaseCart(playerId, 2, def.id);
			else 
				return false;
			end
			if (noPrice ~= true) then
				self:AwardPPCount(playerId, -price, not equip and not alive);
			end
			local item;
			if (self:IsWeapon(itemName)) then
				item = CryMP:GiveItem(player, def.class);
			else
				item = nCX.GiveItem(def.class, channelId, true, false);
			end
			if (item) then
				item.builtas = def.id;
				if (def.md) then
					self:OnNuclearWarfare(teamId, itemName, item.id, playerId);
				end
			end
		else
			nCX.SendTextMessage(2, "@mp_CannotCarryMore", channelId);
			
			return false;
		end
		return true, def;
	end,
	---------------------------
	--		HasUniqueItem		-- changed 10.05
	---------------------------
	HasUniqueItem = function(self, player, uniqueId)
		local alive = (not player.actor:IsDead());
		if (alive) then
			local inventory = player and player.inventory;
			if (inventory) then
				for item, def in pairs(self.buyList) do
					if (def.uniqueId and def.uniqueId == uniqueId) then
						local itemId = inventory:GetItemByClass(def.class);
						if (itemId) then
							local item = System.GetEntity(itemId);
							if (item and item.builtas == def.id) then
								return true, def.id;
							end
						end
					end
				end
			end
		else
			local items = self:GetPurchaseCart(player.id, 2);
			if (items) then
				for i, v in pairs(items) do
					local def = self:GetItemDef(v);
					if (def and def.uniqueId and def.uniqueId == uniqueId) then
						return true, def.id;
					end
				end
			end
		end
		return false;
	end,
	---------------------------
	--	GetProductionFactory	-- changed 10.11
	---------------------------
	GetProductionFactory = function(self, playerId, itemName, insideOnly, vehiclecheck)
		if (not self.factories) then
			return;
		end
		local def = self:GetItemDef(itemName);
		if (not def or (vehiclecheck==true and not self:IsVehicle(itemName)))then
			return;
		end
		local teamId = nCX.GetTeam(playerId);
		local ok = (not def.level or (nCX.IsSameTeam(playerId, self.Prototype.id) and def.level <= self:GetTeamPower(teamId)));
		if (ok) then
			for i, factory in pairs(self.factories) do
				if (nCX.IsSameTeam(factory.id, playerId) and (vehiclecheck==false or factory:CanBuild(itemName))) then
					if (not insideOnly or self:IsInBuyZone(playerId, factory.id)) then
						return factory;
					end
				end
			end
		end
	end,
	---------------------------
	--		BuyVehicle			-- changed 02.06
	---------------------------
	BuyVehicle = function(self, player, itemName)
		local playerId, channelId = player.id, player.Info.Channel;
		local factory = self:GetProductionFactory(playerId, itemName, true, true);
		if (factory and factory:CanBuy(itemName)) then
			player.FACTORY_BUILD = itemName;
			local limitOk=self:CheckBuyLimit(channelId, itemName, nCX.GetTeam(playerId));
			local quit, player, itemName = CryMP:HandleEvent("OnBuyVehicle", {player, itemName, self:GetItemDef(itemName)});
			if (quit or not limitOk) then
				return false;
			end
			local price,energy=self:GetPrice(itemName);
			if (factory:Buy(playerId, itemName)) then
				self:AwardPPCount(playerId, -price, true);
				if (energy > 0) then
					local teamId=nCX.GetTeam(playerId);
					if (teamId and teamId~=0) then
						self:SetTeamPower(teamId, self:GetTeamPower(teamId)-energy);
					end
				end
				for i, fac in pairs(self.factories) do
					if (fac.id ~= factory.id) then
						fac:CancelJobForPlayer(playerId);
					end
				end
				return true;
			end
		end
		return false;
	end,
	---------------------------
	--		OnEnterBuyZone		--added 27.05
	---------------------------
	OnEnterBuyZone = function(self, zone, player)
		if (zone.vehicle and (zone.vehicle:IsDestroyed() or zone.vehicle:IsSubmerged())) then
			return;
		end
		self.inBuyZone[player.id] = self.inBuyZone[player.id] or {};
		self.inBuyZone[player.id][zone.id] = true;
		if (nCX.IsPlayerInGame(player.id)) then
			local channelId = player.Info.Channel;
			if (channelId > 0) then
				self.onClient:ClEnterBuyZone(channelId, zone.id, true);
			end
		end
	end,
	---------------------------
	--		OnLeaveBuyZone
	---------------------------
	OnLeaveBuyZone = function(self, zone, player)
		if (self.inBuyZone[player.id] and self.inBuyZone[player.id][zone.id]) then
			self.inBuyZone[player.id][zone.id]=nil;
			local channelId = player.Info.Channel;
			if (channelId > 0) then
				self.onClient:ClEnterBuyZone(channelId, zone.id, false);
			end
		end
	end,
	---------------------------
	--		IsInBuyZone			-- changed 09.05
	---------------------------
	IsInBuyZone = function(self, playerId, zoneId)
		local zones = self.inBuyZone[playerId];
		if (zones) then
			if (zoneId) then
				return zones[zoneId] and nCX.IsSameTeam(zoneId, playerId);
			else
				for zoneId, inside in pairs(zones) do
					if (inside and nCX.IsSameTeam(zoneId, playerId)) then
						return true;
					end
				end
			end
		end
		return false;
	end,
	---------------------------
	--	OnEnterServiceZone		--added 27.05
	---------------------------
	OnEnterServiceZone = function(self, zone, player)
		self.inServiceZone[player.id] = self.inServiceZone[player.id] or {};
		local was = self.inServiceZone[player.id][zone.id];
		if (not was) then
			self.inServiceZone[player.id][zone.id]=true;
			local channelId = player.Info.Channel;
			if (channelId > 0) then
				self.onClient:ClEnterServiceZone(channelId, zone.id, true);
			end
		end
	end,
	---------------------------
	--	OnLeaveServiceZone
	---------------------------
	OnLeaveServiceZone = function(self, zone, player)
		if (self.inServiceZone[player.id] and self.inServiceZone[player.id][zone.id]) then
			self.inServiceZone[player.id][zone.id]=nil;
			local channelId = player.Info.Channel;
			if (channelId > 0) then
				self.onClient:ClEnterServiceZone(channelId, zone.id, false);
			end
		end
	end,
	---------------------------
	--	IsInServiceZone			--changed 09.05
	---------------------------
	IsInServiceZone = function(self, playerId, zoneId)
		local zones = self.inServiceZone[playerId];
		if (zones) then
			if (zoneId) then
				return zones[zoneId] and nCX.IsSameTeam(zoneId, playerId);
			else
				for zoneId, inside in pairs(zones) do
					if (inside and nCX.IsSameTeam(zoneId, playerId)) then 
						return true;
					end
				end
			end
		end
		return false;
	end,
	---------------------------
	--		SetTeamPower
	---------------------------
	SetTeamPower = function(self, teamId, power)
		local prevpower=self:GetTeamPower(teamId) or 0;
		power = math.max(0, math.min(100, power));
		if (power < prevpower and prevpower > 0 and prevpower-power > 4 and power ~= 0) then
			self.powerFallback = {teamId, prevpower, math.floor(power)}; -- math floor was missing
			--nCX.SetEnergyAnimation(teamId, math.floor(power));
			nCX.SetSynchedGlobalValue(300 + teamId, power);
		else
			--self.powerFallback = nil;
			nCX.SetSynchedGlobalValue(300 + teamId, power);
			--nCX.SetEnergyAnimation(teamId, math.floor(power));
			if (prevpower < 100 and power >= 100) then
				self.allClients:ClTeamPower(teamId, 100);
			elseif (prevpower < 90 and power >= 90) then
				self.allClients:ClTeamPower(teamId, 90);
			elseif (prevpower < 50 and power >= 50) then
				self.allClients:ClTeamPower(teamId, 50);
			end
		end
	end,
	---------------------------
	--		GetTeamPower
	---------------------------
	GetTeamPower = function(self, teamId)
		return nCX.GetSynchedGlobalValue(300 + teamId) or 0;
	end,
	---------------------------
	--		AddPowerPoint		-- changed 29.09
	---------------------------
	AddPowerPoint = function(self, entityId, teamId)
		self.powerpoints = self.powerpoints or {};
		if (teamId ~= 0) then
			self.powerpoints[teamId] = self.powerpoints[teamId] or {};
			self.powerpoints[teamId][entityId] = true;
		end
	end,
	---------------------------
	--	RemovePowerPoint		-- changed 29.09
	---------------------------
	RemovePowerPoint = function(self, entityId, teamId)
		if (self.powerpoints and self.powerpoints[teamId]) then
			self.powerpoints[teamId][entityId] = nil;
		end
	end,
	---------------------------
	--		ResetPower
	---------------------------
	ResetPower = function(self)
		for i, teamId in pairs(self.teamId) do
			self:SetTeamPower(teamId, 0);
		end
	end,
	---------------------------
	--		GetPlayerRank
	---------------------------
	GetPlayerRank = function(self, playerId)
		return nCX.GetSynchedEntityValue(playerId, 202) or 1;
	end,
	---------------------------
	--		SetPlayerRank		-- changed 02.05
	---------------------------
	SetPlayerRank = function(self, playerId, rank, reset)	
		local current = self:GetPlayerRank(playerId);
		if (rank ~= current and not reset) then
			local channelId = nCX.GetChannelId(playerId);
			if (channelId > 0) then
				local promote = (rank > current);
				self.onClient:ClRank(channelId, rank, promote);
			end
		end
		CryAction.SendGameplayEvent(playerId, 11, nil, rank);	
		return nCX.SetSynchedEntityValue(playerId, 202, rank);
	end,
	---------------------------
	--		GetPlayerRankName
	---------------------------
	GetPlayerRankName = function(self, playerId)
		return self:GetRankName(self:GetPlayerRank(playerId));
	end,
	---------------------------
	--		GetRankName
	---------------------------
	GetRankName = function(self, rank, longName, includeShortName)
		local rankdef = self.rankList[rank];
		if (rankdef) then
			if (not longName) then
				return rankdef.name;
			else
				return rankdef.desc;
			end
		end
		return;
	end,
	---------------------------
	--		GetRankCP
	---------------------------
	GetRankCP = function(self, rank)
		local rankdef=self.rankList[rank];
		if (rankdef) then
			return rankdef.cp;
		end
		return;
	end,
	---------------------------
	--		GetRankPP
	---------------------------
	GetRankPP = function(self, rank)
		local rankdef=self.rankList[rank];
		if (rankdef) then
			return rankdef.min_pp;
		end
		return;
	end,
	---------------------------
	--		CheckPlayerRank		-- changed 09.05
	---------------------------
	CheckPlayerRank = function(self, playerId, cp)	
		local ranks = self.rankList;
		local current = self:GetPlayerRank(playerId);
		if (current < #ranks) then
			for i = #ranks, (current + 1), -1 do
				local tbl = ranks[i];
				if (cp > tbl.cp) then
					self:SetPlayerRank(playerId, i);
					break;
				end
			end
		end
	end,
	---------------------------
	--		ResetPP
	---------------------------
	ResetPP = function(self, playerId)
		self:SetPlayerPP(playerId, 0);
	end,
	---------------------------
	--		ResetCP
	---------------------------
	ResetCP = function(self, playerId)
		self:SetPlayerCP(playerId, 0);
		self:SetPlayerRank(playerId, 1, true);
	end,
	---------------------------
	--		SetPlayerCP			-- changed 09.05
	---------------------------
	SetPlayerCP = function(self, playerId, cp)
		nCX.SetSynchedEntityValue(playerId, 201, cp);
		self:CheckPlayerRank(playerId, cp);  -- check rank
	end,
	---------------------------
	--		GetPlayerCP
	---------------------------
	GetPlayerCP = function(self, playerId)
		return nCX.GetSynchedEntityValue(playerId, 201) or 0;
	end,
	---------------------------
	--		CalcKillCP
	---------------------------
	CalcKillCP = function(self, hit)
		local shooter, target = hit.shooter, hit.target;
		if (shooter and target ~= shooter) then
			if (not nCX.IsSameTeam(shooter.id, target.id)) then
				local ownRank = self:GetPlayerRank(shooter.id);
				local enemyRank = self:GetPlayerRank(target.id);
				return 10 + math.max(0, (enemyRank-ownRank));
			else
				return -10;
			end
		end
		return 0;
	end,
	---------------------------
	--		AwardCPCount
	---------------------------
	AwardCPCount = function(self, playerId, c)
		self:SetPlayerCP(playerId, self:GetPlayerCP(playerId) + c);
	end,
	---------------------------
	--		MakeBuyZone		-- changed 09.04.2013
	---------------------------
	MakeBuyZone = function(self, zone, flags, radius)
		if (zone.vehicle) then
			if (zone.buyFlags) then
				return;
			end
			local function replace_pre(old, new)
				if (not old) then
					return new;
				else
					return function(...)
						local res=new(...);
						old(...)
						return res;
					end
				end
			end
			zone.OnEnterArea=replace_pre(zone.OnEnterArea, function(zone, entity, areaId)
				if (entity.actor and (not zone.State.destroyed)) then
					if (g_gameRules.OnEnterBuyZone) then
						g_gameRules.OnEnterBuyZone(g_gameRules, zone, entity);
					end
					if (g_gameRules.OnEnterServiceZone) then
						g_gameRules.OnEnterServiceZone(g_gameRules, zone, entity);
					end
				end
			end);
			zone.OnLeaveArea=replace_pre(zone.OnLeaveArea, function(zone, entity, areaId)
				if (entity.actor) then
					if (g_gameRules.OnLeaveBuyZone) then
						g_gameRules.OnLeaveBuyZone(g_gameRules, zone, entity);
					end
					if (g_gameRules.OnLeaveServiceZone) then
						g_gameRules.OnLeaveServiceZone(g_gameRules, zone, entity);
					end
				end	
			end);
			zone.GetBuyFlags=function(zone)
				return zone.buyFlags;
			end
			zone.buyFlags = flags or 8; --ammo
			local dim = 2 * (radius or 11);
			local trigger=System.SpawnEntity{
				class="ServerTrigger",
				position={x=0, y=0, z=0},
				name=zone:GetName().."_buy_zone_trigger",
				properties={
					DimX=dim,
					DimY=dim,
					DimZ=dim,
				},
			};
			if (trigger) then
				zone:AttachChild(trigger.id, 0);
				trigger:ForwardTriggerEventsTo(zone.id);	
				local factory = self.factories and self.factories[1];
				if (factory) then
					factory.allClients:ClSetBuyFlags(zone.id, 13);
				end		
				self.vehicleBuyZones[zone.id] = true;
				return true;
			end
		else
			local function replace_post(old, new)
				if (not old) then
					return new;
				else
					return function(...)
						local res=old(...);
						return new(...) or res;
					end
				end
			end
			local hasFlag=function(option, flag)
				if (band(option, flag)~=0) then
					return 1;
				else
					return 0;
				end
			end
			if (zone.class) then
				local buyFlags=0;
				local options=zone.Properties.buyOptions;
				if (tonumber(options.bVehicles)~=0) then	 	buyFlags=bor(buyFlags, 2); end;
				if (tonumber(options.bWeapons)~=0) then 		buyFlags=bor(buyFlags, 1); end;
				if (tonumber(options.bEquipment)~=0) then		buyFlags=bor(buyFlags, 4); end;
				if (tonumber(options.bPrototypes)~=0) then   	buyFlags=bor(buyFlags, 16); end;
				if (tonumber(options.bAmmo)~=0) then		 	buyFlags=bor(buyFlags, 8); end;
				zone.buyFlags=buyFlags;
			else
				zone.Properties.buyAreaId	= 0;
				zone.Properties.buyOptions={
					bVehicles 	= hasFlag(flags, 2),
					bWeapons 	= hasFlag(flags, 1),
					bEquipment	= hasFlag(flags, 4),
					bPrototypes	= hasFlag(flags, 16),
					bAmmo		= hasFlag(flags, 8),
				};
				zone.OnSpawn=replace_post(zone.OnSpawn, function(zone)
					local buyFlags=0;
					local options=zone.Properties.buyOptions;
					if (tonumber(options.bVehicles)~=0) then	 	buyFlags=bor(buyFlags, 2); end;
					if (tonumber(options.bWeapons)~=0) then 		buyFlags=bor(buyFlags, 1); end;
					if (tonumber(options.bEquipment)~=0) then		buyFlags=bor(buyFlags, 4); end;
					if (tonumber(options.bPrototypes)~=0) then  	buyFlags=bor(buyFlags, 16); end;
					if (tonumber(options.bAmmo)~=0) then		 	buyFlags=bor(buyFlags, 8); end;
					zone.buyFlags=buyFlags;
				end);
			end
			zone.GetBuyFlags=replace_post(zone.GetBuyFlags, function(zone)
				return zone.buyFlags;
			end);
			local server = zone;
			if (not zone.class) then
				server = zone.Server;
			end
			server.OnEnterArea=replace_post(server.OnEnterArea, function(zone, entity, areaId)
				if (areaId == zone.Properties.captureAreaId) then
					g_gameRules.inCaptureZone[entity.id] = zone.id;
				end
				if (areaId == zone.Properties.buyAreaId) then
					local distance = zone:GetDistance(entity.id);
					if (zone.id == g_gameRules.PrototypeId and distance < 7.0 and distance > 5.0) then  -- must be g_gameRules and not self
						return;
					end
					g_gameRules.OnEnterBuyZone(g_gameRules, zone, entity);
				end
			end);
			server.OnLeaveArea=replace_post(server.OnLeaveArea, function(zone, entity, areaId)
				if (areaId == zone.Properties.captureAreaId) then
					g_gameRules.inCaptureZone[entity.id] = nil;
				end			
				if (areaId == zone.Properties.buyAreaId) then
					local distance = zone:GetDistance(entity.id);
					if (zone.id == g_gameRules.PrototypeId and distance < 7.0 and distance > 5.0) then
						return;
					end
					g_gameRules.OnLeaveBuyZone(g_gameRules, zone, entity);
				end
			end);
		end
	end,
	
	Log = function(self, name, a1, a2, a3)
		--System.LogAlways("[log] "..type(name).." "..type(a1).." "..type(a2).." "..type(a3));
		local t1, t2, t3 = type(a1), type(a2), type(a3)
		if (t1 == "userdata") then
			local ent = System.GetEntity(a1);
			if (ent) then
				local add = (ent.Info and ent.Info.Channel and ":Channel "..ent.Info.Channel) or "";
				t1 = tostring(a1)..":"..ent:GetName()..add;
			else
				t1 = tostring(a1)..":N/A";
			end
		elseif (t1 == "string") then
			if (#a1 > 20) then
				t1 = "!WARNING:STRING! #"..#a1;
			else
				t1 = "string #"..#a1..":"..a1;
			end
		else
			t1 = t1..", "..tostring(a1);
		end
		--System.LogAlways("1");
		if (t2 == "userdata") then
			local ent = System.GetEntity(a2);
			if (ent) then
				t2 = tostring(a2)..":"..ent:GetName();
			else
				t2 = tostring(a2)..":N/A";
			end
		elseif (t2 == "string") then
			if (#a2 > 20) then
				t2 = "!WARNING:STRING! #"..#a2;
			else
				t2 = "string #"..#a2..":"..a2;
			end
		else
			t2 = t2..", "..tostring(a2);
		end
		--System.LogAlways("2");
		if (t3 == "userdata") then
			local ent = System.GetEntity(a3);
			if (ent) then
				t3 = tostring(a3)..":"..ent:GetName();
			else
				t3 = tostring(a3)..":N/A";
			end
		elseif (t3 == "string") then
			if (#a3 > 20) then
				t3 = "!WARNING:STRING! #"..#a3;
			else
				t3 = "string #"..#a3..":"..a3;
			end
		else
			t3 = t3..", "..tostring(a3);
		end
		local msg = ("[rmi:server] [%s] %s (%s) (%s) (%s)"):format(os.date("%H:%M:%S",time),name,tostring(t1),tostring(t2),tostring(t3));
		--System.LogAlways(msg);
	end,
};
Net.Expose {
	Class = PowerStruggle,
	ClientMethods = {
		ClSetupPlayer				= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, },
		ClSetSpawnGroup	 			= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, },
		ClSetPlayerSpawnGroup		= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, ENTITYID },
		ClSpawnGroupInvalid			= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, },
		ClVictory					= { RELIABLE_ORDERED, NO_ATTACH, INT8, INT8, ENTITYID },
		ClStartWorking				= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID; STRINGTABLE },
		ClStepWorking				= { RELIABLE_ORDERED, NO_ATTACH, INT8 },
		ClStopWorking				= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, BOOL },
		ClWorkComplete				= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, STRINGTABLE },--RELIABLE_ORDERED
		ClClientConnect				= { RELIABLE_UNORDERED, NO_ATTACH, STRING, BOOL },
		ClClientDisconnect			= { RELIABLE_UNORDERED, NO_ATTACH, STRING, },
		ClClientEnteredGame			= { RELIABLE_UNORDERED, NO_ATTACH, STRING, },
		ClEnterBuyZone				= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID, BOOL }; 
		ClEnterServiceZone			= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID, BOOL };
		ClEnterCaptureArea			= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID, BOOL }; 
		ClPerimeterBreached			= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID };
		ClTurretHit					= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID };
		ClHQHit						= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID };
		ClTurretDestroyed			= { RELIABLE_ORDERED, NO_ATTACH, ENTITYID };
		ClMDAlert					= { RELIABLE_UNORDERED, NO_ATTACH, STRING },
		ClMDAlert_ToPlayer			= { RELIABLE_UNORDERED, NO_ATTACH, },
		ClTimerAlert				= { RELIABLE_UNORDERED, NO_ATTACH, INT8 },
		ClBuyError					= { RELIABLE_UNORDERED, NO_ATTACH, STRING, },
		ClBuyOk						= { RELIABLE_UNORDERED, NO_ATTACH, STRING, },
		ClPP						= { RELIABLE_UNORDERED, NO_ATTACH, FLOAT },
		ClRank						= { RELIABLE_UNORDERED, NO_ATTACH, INT8, BOOL },
		ClTeamPower					= { RELIABLE_UNORDERED, NO_ATTACH, INT8, FLOAT },
		ClEndGameNear				= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID },
		ClReviveCycle				= { RELIABLE_UNORDERED, NO_ATTACH, BOOL },
	},
	ServerMethods = {
		RequestRevive		 		= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, },
		RequestSpawnGroup			= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, ENTITYID },
		SvBuy						= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, STRINGTABLE },
		SvBuyAmmo					= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, STRINGTABLE },
		SvRequestPP					= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, INT32 }; 
		RequestSpectatorTarget		= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, INT8 },
	},
	ServerProperties = {
	},
};
--[[
Net.Expose {
	Class = PowerStruggle,
	ClientMethods = {
		ClSetupPlayer				= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID, },
		ClSetSpawnGroup	 			= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID, },
		ClSetPlayerSpawnGroup		= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID, ENTITYID },
		ClSpawnGroupInvalid			= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID, },
		ClVictory					= { RELIABLE_ORDERED, POST_ATTACH, INT8, INT8, ENTITYID },
		ClStartWorking				= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID; STRINGTABLE },
		ClStepWorking				= { RELIABLE_ORDERED, POST_ATTACH, INT8 },
		ClStopWorking				= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID, BOOL },
		ClWorkComplete				= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, STRINGTABLE },--RELIABLE_ORDERED
		ClClientConnect				= { RELIABLE_UNORDERED, POST_ATTACH, STRING, BOOL },
		ClClientDisconnect			= { RELIABLE_UNORDERED, POST_ATTACH, STRING, },
		ClClientEnteredGame			= { RELIABLE_UNORDERED, POST_ATTACH, STRING, },
		ClEnterBuyZone				= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID, BOOL };
		ClEnterServiceZone			= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID, BOOL };
		ClEnterCaptureArea			= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID, BOOL };
		ClPerimeterBreached			= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID };
		ClTurretHit					= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID };
		ClHQHit						= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID };
		ClTurretDestroyed			= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID };
		ClMDAlert					= { RELIABLE_UNORDERED, POST_ATTACH, STRING },
		ClMDAlert_ToPlayer			= { RELIABLE_UNORDERED, POST_ATTACH, },
		ClTimerAlert				= { RELIABLE_UNORDERED, POST_ATTACH, INT8 },
		ClBuyError					= { RELIABLE_UNORDERED, POST_ATTACH, STRING, },
		ClBuyOk						= { RELIABLE_UNORDERED, POST_ATTACH, STRING, },
		ClPP						= { RELIABLE_UNORDERED, POST_ATTACH, FLOAT },
		ClRank						= { RELIABLE_UNORDERED, POST_ATTACH, INT8, BOOL },
		ClTeamPower					= { RELIABLE_UNORDERED, POST_ATTACH, INT8, FLOAT },
		ClEndGameNear				= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID },
		ClReviveCycle				= { RELIABLE_UNORDERED, POST_ATTACH, BOOL },
	},
	ServerMethods = {
		RequestRevive		 		= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID, },
		RequestSpawnGroup			= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID, ENTITYID },
		SvBuy							= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID, STRINGTABLE },
		SvBuyAmmo					= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID, STRINGTABLE },
		SvRequestPP					= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID, INT32 }; --INT32
		RequestSpectatorTarget		= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID, INT8 },
	},
	ServerProperties = {
	},
};]]