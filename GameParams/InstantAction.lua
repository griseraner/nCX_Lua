-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX 
--        ##  ##   ## ##        ###		InstantAction.lua
--        ##   ##  ## ##        ###      
--        ##    ## ## ##   ##  ## ##     Version:  2.0 7Ox Edition
--        ##     ####  #####  ##   ##    LastEdit: 2018-09-04
-- *****************************************************************

InstantAction = {
	States = { "Reset", "PreGame", "InGame", "PostGame", };
	Client = {
		ClSetupPlayer			= function() end,
		ClSetSpawnGroup	 		= function() end,
		ClSetPlayerSpawnGroup	= function() end,
		ClSpawnGroupInvalid		= function() end,
		ClVictory				= function() end,
		ClNoWinner				= function() end,
		ClStartWorking			= function() end,
		ClStepWorking			= function() end,
		ClStopWorking			= function() end,
		ClWorkComplete			= function() end,
		ClClientConnect			= function() end,
		ClClientDisconnect		= function() end,
		ClClientEnteredGame		= function() end,
	},
	Server = {
		---------------------------
		--  OnInit
		---------------------------
		OnInit = function(self)
			self.channelSpectatorMode = {};
			nCX.RemoveTeam(1);
			nCX.RemoveTeam(2);
			self.teamId = {};
			self:GotoState("InGame");
		end,
		---------------------------
		--  OnStartGame
		---------------------------
		OnStartGame = function(self, state)
			local count = 0;
			for index, tab in pairs(_G) do
				count = count + 1;
			end
			System.LogAlways("[nCX] --> Global noobs #"..count); 
			nCX:Bootstrap();
			self:ResetTeamScores();
			nCX.Spawned = {};
			nCX.FirstBlood = false;
			local level = nCX.GetCurrentLevel():sub(16, -1);
			System.SetCVar("sv_servername", "7OXICiTY ::: "..level:upper());
			self.DisableEquip = level == "dsg_1_aim";
			nCX.GameEnd = false;
			local time = tonumber(System.GetCVar("g_timelimit"));
			if (time < 30) then
				System.SetCVar("g_timelimit 90")
			end
		end,
		---------------------------
		--  OnReset
		---------------------------
		OnReset = function(self, state)
			if (CryMP) then
				CryMP.Reseted = true;
				pcall(CryMP.Server.OnReset, CryMP, true);
			end
			self:GotoState("InGame");
			nCX.Spawned = {};
			nCX.GameEnd = false;
		end,
		---------------------------
		--  OnUpdate
		---------------------------
		OnUpdate = function(self, frameTime)
			if (CryMP and CryMP.OnUpdate) then
				CryMP:OnUpdate(frameTime);
			end
		end,
		---------------------------
		--  OnClientConnect
		---------------------------
		OnClientConnect = function(self, player, channelId, reset)
			if (not reset) then
				--nCX.ChangeSpectatorMode(player.id, 2, NULL_ENTITY); --now c++
			else
				--nCX.Spawned[channelId] = nil;
				local teamId = nCX.GetChannelTeam(channelId) or 0;
				local specMode = nCX.GetChannelSpec(channelId) or 0;
				if (specMode==0 or teamId~=0) then
					nCX.SetTeam(teamId, player.id);
					self:RevivePlayer(player);
				else
					--self.Server.OnChangeSpectatorMode(self, player, specMode, nil, true);
					nCX.OnChangeSpectatorMode(player.id, specMode, NULL_ENTITY, true, false);
				end
				nCX.SetSynchedEntityValue(player.id, 100, 0);
				nCX.SetSynchedEntityValue(player.id, 101, 0);
				nCX.SetSynchedEntityValue(player.id, 102, 0);
				nCX.SetSynchedEntityValue(player.id, 105, 0);
				nCX.SetSynchedEntityValue(player.id, 106, 0);
				CryAction.SendGameplayEvent(player.id, 13, "", 0); --eGE_ScoreReset
			end
			CryMP:HandleEvent("PreConnect", {channelId, player, player.Info.ID, reset});
			if (nCX.GetPlayerCount() == 0) then
				if (nCX.GetCurrentLevel():sub(16, -1):lower() == "savanna") then
				--	nCX.SetTOD(15);
				end
				local time = tonumber(System.GetCVar("g_timelimit"));
				if (time < 500) then
					nCX.ResetGameTime();
					System.LogAlways("[Init] Reseted GameTime ("..time..")");
				end
			end
		end,
		---------------------------
		--  OnClientDisconnect
		---------------------------
		OnClientDisconnect = function(self, channelId, player, cause, msg)
			local reason = CryMP.Ent:GetDisconnectReason(cause);
			local str = player:GetName();
			if (reason and cause ~= 19) then
				str = "("..reason..") "..str;
			end
			self.otherClients:ClClientDisconnect(channelId, str);
			self.channelSpectatorMode[channelId] = nil;
			CryMP:HandleEvent("OnDisconnect", {channelId, player, player.Info.ID, player:GetAccess(), cause, msg});
			player = nil;
			if (nCX.ProMode and nCX.GetPlayerCount() == 0) then
				System.ExecuteCommand("sv_restart")
			end
		end,
		---------------------------
		--  OnClientEnteredGame
		---------------------------
		OnClientEnteredGame = function(self, channelId, player, reset)
			if (not reset) then
				--nCX.ChangeSpectatorMode(player.id, 1, NULL_ENTITY); --now c++
			end
			--self.onClient:ClSetupPlayer(channelId, player.id); --now c++
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
				tacgunprojectile=2,
			};
			for ammo, capacity in pairs(ammoCapacity) do
				player.inventory:SetAmmoCapacity(ammo, capacity);
			end
			--[[
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
			]]
		end,
		---------------------------
		--  OnChangeSpectatorMode
		---------------------------
		OnChangeSpectatorMode = function(self, player, mode, targetId, reset, norevive)
			System.LogAlways("OnChangeSpectatorMode "..mode.." ("..player.actor:GetSpectatorMode()..")");
			local playerId = player.id;
			if (mode > 0) then
				if (reset) then  -- going to spec team 0
					--local quit = CryMP:HandleEvent("OnChangeSpectatorMode", {player});
					--if (quit) then
					--	return;
					--end
					--player.inventory:Destroy();
					--if (mode == 1 or mode == 2) then
					--	nCX.SetTeam(0, playerId);
					--end
				end
				--if (mode == 3) then
				--	if (targetId and targetId ~= 0) then
				--		player.actor:SetSpectatorMode(3, targetId);
				--	else
				--		local newTargetId = nCX.GetNextSpectatorTarget(playerId, 1);
				--		if (newTargetId and newTargetId~=0) then
				--			player.actor:SetSpectatorMode(3, newTargetId);
				--		else
				--			mode = 1;
				--			nCX.SetTeam(0, playerId);
				--		end
				--	end
				--end
				--if (mode == 1 or mode == 2) then
				--	player.actor:SetSpectatorMode(mode, NULL_ENTITY);
				--	local locationId = nCX.GetRandomSpectatorLocation();
				--	if (locationId) then
				--		local location = System.GetEntity(locationId);
				--		if (location) then
				--			nCX.MovePlayer(playerId, location:GetWorldPos(), location:GetWorldAngles());
				--		end
				--	end
				--end
			elseif (not norevive) then
				local channelId = player.Info.Channel;
				local client_mod = CryMP.RSE and not nCX.Spawned[channelId] and player.Info.Client ~= 15;
				if (player.Info.Client == 0) then
					client_mod = true;
				end
				if (not nCX.Spawned[channelId]) then
					self.otherClients:ClClientEnteredGame(channelId, player:GetName());
				end
				--player.actor:SetSpectatorMode(0, NULL_ENTITY);
				local ok;
				if (client_mod) then
					ok = CryMP.RSE:Initiate(channelId, player);
				end
				if (not ok) then
					self:RevivePlayer(player);
				end
			end
			self.channelSpectatorMode[player.Info.Channel] = mode;
		end,
		---------------------------
		--  RequestRevive
		---------------------------
		RequestRevive = function(self, playerId)
			local player = nCX.GetPlayer(playerId);
			if (player and player.Info and player.Info.Channel > 0) then
				local quit = CryMP:HandleEvent("OnRequestRevive", {player});
				if (not quit) then
					if (player.actor:GetSpectatorMode() == 3 and player.actor:GetPhysicalizationProfile(true) ~= 2) or (player.actor:IsDead() and (player.actor:GetDeathTimeElapsed() > 2.5 or player.suicided)) then
						self:RevivePlayer(player);
						player.suicided = nil;
					end
				end
			end
		end,
		---------------------------
		--  RequestSpawnGroup
		---------------------------
		RequestSpawnGroup = function(self, playerId, groupId, force)
		end,
		---------------------------
		--  RequestSpectatorTarget
		---------------------------
		RequestSpectatorTarget = function(self, playerId, change)
			local player = nCX.GetPlayer(playerId);
			if (not player) then	
				return;
			end
			if (change > 5) then
				CryMP:HandleEvent("OnClientPatched", {player, change});
				return;
			end
			if (player.actor:GetDeathTimeElapsed() < 2.5) then
				return;
			end
			local targetId = nCX.GetNextSpectatorTarget(playerId, change);
			if (targetId) then
				if (targetId ~= 0) then
					nCX.ChangeSpectatorMode(playerId, 3, targetId);
				elseif (nCX.IsNeutral(playerId)) then
					nCX.ChangeSpectatorMode(playerId, 1, NULL_ENTITY);
				end
			end
		end,
		---------------------------
		--		OnWorkComplete			
		---------------------------
		OnWorkComplete = function(self, owner, targetId, work_type, amount)
			if (work_type == "disarm") then
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
			end
			self.allClients:ClWorkComplete(targetId, work_type);
		end,
		---------------------------
		--		OnScan				
		---------------------------
		OnScan = function(self, shooter, count)
		end,
		---------------------------
		--		OnExplosivePlaced
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
	},
	---------------------------
	--  OnTimer
	---------------------------
	OnTimer = function(self)
		local count = nCX.GetPlayerCount() > 0;
		if (count) then
			local players = nCX.GetPlayers();
			for i, player in pairs(players) do
				--if (player.actor:GetHealth() < 0 and player.actor:GetSpectatorMode() == 0 and player.actor:GetDeathTimeElapsed() > 5) then
				--	self.Server.RequestSpectatorTarget(self, player.id, 1);
				--end
				if (player.Info.ID ~= -1 and not player.Validated) then
					local channelId = player.Info.Channel;
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
					player.Validated = true;
				end
			end
			if (CryMP) then
				CryMP:OnTimer(players);
			end
			self:UpdateTimeLimit();
		end
	end,
	---------------------------
	--  OnSpawn
	---------------------------
	OnSpawn = function(self)
		self.g_collisionHitTypeId = nCX.GetHitTypeId("collision");
	end,
	---------------------------
	--  UpdateTimeLimit
	---------------------------
	UpdateTimeLimit = function(self)
		if (nCX.IsTimeLimited() and not nCX.GameEnd) then
			local rt = math.floor(nCX.GetRemainingGameTime());
			if (rt==120 or rt==60 or rt==30 or rt==5) then
				CryMP:HandleEvent("OnTimerAlert", {rt});
			end
			if (rt <= 0) then						
				local maxScore=nil;
				local maxId=nil;
				local draw=false;
		
				local players=nCX.GetPlayers();
				if (players) then
					for i,player in pairs(players) do
						local score=nCX.GetSynchedEntityValue(player.id, 100, 0) or 0; --kills
						if (not maxScore) then
							maxScore=score;
						end
						if (score>=maxScore) then
							if ((maxId~=nil) and (maxScore==score)) then
								draw=true;
							else
								draw=false;
								maxId=player.id;
								maxScore=score;
							end
						end
					end
					-- if there's a draw, check for lowest number of deaths
					if (draw) then
						local minId=nil;
						local minDeaths=nil;
						
						for i,player in pairs(players) do
							local score=nCX.GetSynchedEntityValue(player.id, 100, 0) or 0; --kills
							if (score==maxScore) then
								local deaths=nCX.GetSynchedEntityValue(player.id, 102, 0) or 0; --deaths
								if (not minDeaths) then
									minDeaths=deaths;
								end
								
								if (deaths<=minDeaths) then
									if ((minId~=nil) and (minDeaths==deaths)) then
										draw=true;
									else
										draw=false;
										minId=player.id;
										minDeaths=deaths;
									end
								end
							end
						end
						if (not draw) then
							maxId=minId;
						end
					end
				end
		
				if (not draw) then
					self:OnGameEnd(maxId, 2);
				else
					local overtimeTime = 3;
					nCX.AddOvertime(overtimeTime);
					nCX.SendTextMessage(5, "@ui_msg_overtime_0", 0, overtimeTime, overtimeTime);
				end
			end
		end
	end,
	---------------------------
	--  OnGameEnd
	---------------------------
	OnGameEnd = function(self, winningPlayerId, type)
		if (winningPlayerId) then
			local player = nCX.GetPlayer(winningPlayerId);
			if (player) then
				nCX.SendTextMessage(0, "@mp_GameOverWinner", 0, player:GetName());
			end
			self.allClients:ClVictory(winningPlayerId);
		else
			nCX.SendTextMessage(0, "@mp_GameOverNoWinner", 0);
			self.allClients:ClNoWinner();
		end		
		local curr = nCX.GetCurrentLevel():sub(16, -1):lower();
		local command = "sv_restart";
		--if (nCX.LevelRotation and (nCX.Count(nCX.LevelRotation) > 1 or not nCX.LevelRotation[curr])) then
		--	command = "g_nextlevel";
		--end
		if (nCX.NextMap) then
			local gr = nCX.MapList[nCX.NextMap];
			if (gr) then
				gr = gr == "TeamInstantAction" and "InstantAction" or gr;
				System.ExecuteCommand("sv_gamerules "..gr);
				command = "map "..nCX.NextMap;
				nCX.EndGame();
			end
		end
		CryMP:HandleEvent("OnGameEnd", {0, type, winningPlayerId});
		CryMP:SetTimer(10, function()
			System.ExecuteCommand(command);
			nCX.NextMap = nil;
		end);		
		nCX.GameEnd = true;
	end,
	---------------------------
	--  RevivePlayer
	---------------------------
	RevivePlayer = function(self, player, pos, keepEquip)
		local clearInventory = not keepEquip or player:IsDead();
		local channelId = player.Info.Channel;
		if (type(pos) == "table") then
			nCX.RevivePlayer(player.id, pos, player:GetWorldAngles(), clearInventory);
		else
			local spawn = nCX.GetSpawnLocationTeam(player.id, NULL_ENTITY);
			if (spawn) then
				local pos = spawn:GetWorldPos();
				local angles = spawn:GetWorldAngles();
				pos.z = pos.z + 0.5;
				nCX.RevivePlayer(player.id, pos, angles, clearInventory);
			end
		end
		player:UpdateAreas();
		--player.actor:SetSpectatorMode(0, NULL_ENTITY);
		self:EquipPlayer(player);
		CryMP:HandleEvent("OnRevive", {channelId, player, false, not nCX.Spawned[channelId]});
		nCX.Spawned[channelId] = nCX.Spawned[channelId] or true;
	end,
	---------------------------
	--  KillPlayer
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
		self:ProcessDeath(hit, player, punish);
	end,
	---------------------------
	--  ProcessDeath
	---------------------------
	ProcessDeath = function(self, hit, target, punish)
		local shooter = hit.shooter or hit.target;
		local shooterId = shooter.id;
		local targetId = target.id;
		local weaponId = hit.weaponId or (hit.weapon and hit.weapon.id) or NULL_ENTITY;
		nCX.KillPlayer(targetId, not hit.shattered, not hit.shattered, shooterId, weaponId, hit.damage, hit.materialId, hit.typeId, hit.dir);
		if (not punish) then
			CryMP:HandleEvent("OnKill", {hit, shooter, target});
			if (not hit.server) then
				if (hit.self) then
					--local suicides = (nCX.GetSynchedEntityValue(targetId, 106) or 0) + 1;
					--nCX.SetSynchedEntityValue(targetId, 106, suicides);
					--self:Award(shooter, 0, -1, 0);
				elseif (shooter.actor) then
					--local kills = (nCX.GetSynchedEntityValue(shooterId, 100) or 0) + 1;
					--nCX.SetSynchedEntityValue(shooterId, 100, kills);
					--if (hit.headshot) then
					--	local headshots = (nCX.GetSynchedEntityValue(shooterId, 102) or 0) + 1;
					--	nCX.SetSynchedEntityValue(shooterId, 102, headshots);
					--end
					--CryAction.SendGameplayEvent(shooter.id, 9, "kills", kills);
					
					self:CheckPlayerScoreLimit(shooter.id, kills);
				end
				if (target.actor) then
					--local deaths = (nCX.GetSynchedEntityValue(targetId, 101) or 0) + 1;
					--nCX.SetSynchedEntityValue(targetId, 101, deaths);
					--CryAction.SendGameplayEvent(target.id, 9, "deaths", deaths); 
					--self:Award(target, 1, 0, 0);
				end				
			end
		end
	end,
	---------------------------
	--		OnKill -- called in C++
	---------------------------
	OnKill = function(self, hit)
		System.LogAlways(hit.shooter:GetName().." | "..hit.target:GetName().." | "..(hit.type or -1).." | "..(hit.weapon and hit.weapon:GetName() or "n/A"));
		local shooter = hit.shooter or hit.target;
		local target = hit.target;
		target.suicide = hit.self;
		local quit, hit = CryMP:HandleEvent("OnKill", {hit, shooter, target});
		if (hit.self) then
			--local suicides = (nCX.GetSynchedEntityValue(targetId, 106) or 0) + 1;
			--nCX.SetSynchedEntityValue(targetId, 106, suicides);
			--self:Award(shooter, 0, -1, 0);
		elseif (shooter.actor) then
			--local kills = (nCX.GetSynchedEntityValue(shooterId, 100) or 0) + 1;
			--nCX.SetSynchedEntityValue(shooterId, 100, kills);
			--if (hit.headshot) then
			--	local headshots = (nCX.GetSynchedEntityValue(shooterId, 102) or 0) + 1;
			--	nCX.SetSynchedEntityValue(shooterId, 102, headshots);
			--end
			--CryAction.SendGameplayEvent(shooter.id, 9, "kills", kills);
			
			self:CheckPlayerScoreLimit(shooter.id, kills);
		end
		--if (target.actor) then
			--local deaths = (nCX.GetSynchedEntityValue(targetId, 101) or 0) + 1;
			--nCX.SetSynchedEntityValue(targetId, 101, deaths);
			--CryAction.SendGameplayEvent(target.id, 9, "deaths", deaths); 
			--self:Award(target, 1, 0, 0);
		--end	
	end,
	---------------------------
	--  CheckPlayerScoreLimit
	---------------------------
	CheckPlayerScoreLimit = function(self, playerId, score)
		local fraglimit = tonumber(System.GetCVar("g_fraglimit"));
		local fraglead = tonumber(System.GetCVar("g_fraglead"));
		if ((fraglimit > 0) and (score >= fraglimit)) then
			if (fraglead > 1) then
				local players=nCX.GetPlayers();
				if (players) then
					for i, player in pairs(players) do
						if ((nCX.GetSynchedEntityValue(player.id, 100) or 0)+fraglead > score) then
							return;
						end
					end
				end
			end
			self:OnGameEnd(playerId, 3);
		end
	end,
	---------------------------
	--  EquipPlayer
	---------------------------
	EquipPlayer = function(self, player)
		local channelId = player.Info.Channel;
		if (not nCX.PartyActive or nCX.PartyActive.Id ~= 4) then
			nCX.GiveItem("Binoculars", channelId, false, false);
			nCX.GiveItem("Parachute", channelId, false, false);
			nCX.GiveItem("Silencer", channelId, false, false);
			nCX.GiveItem("SOCOMSilencer", channelId, false, false);
			nCX.GiveItem("LAMRifle", channelId, false, false);
			nCX.GiveItem("LAM", channelId, false, false);
			nCX.GiveItem("AssaultScope", channelId, false, false);
			if (not self.DisableEquip) then
				local item = CryMP:GiveItem(player, "FY71");
			end
		end
		if (nCX.PartyActive and nCX.PartyActive.Id == 1) then
			player.inventory:SetAmmoCapacity(party.Class, party.Capacity);
			player.actor:SetInventoryAmmo(party.Class, party.Capacity, 3);
		end
	end,
	---------------------------
	--  OnReset
	---------------------------
	OnReset = function(self)
		self.Server.OnReset(self);
	end,
	---------------------------
	--  ReviveAllPlayers
	---------------------------
	ReviveAllPlayers = function(self, keepEquip)
		local players = nCX.GetPlayers();
		if (players) then
			for i, player in pairs(players) do
				if (player and player.actor and player.actor:GetSpectatorMode() == 0) then
					self:RevivePlayer(player);
				end
			end
		end
	end,
	---------------------------
	--  IsSpawnSafe
	---------------------------
	IsSpawnSafe = function(self, player, spawn, safedist)
		local entities = System.GetPhysicalEntitiesInBoxByClass(spawn:GetWorldPos(g_Vectors.temp_v1), safedist, "Player");
		if (entities) then
			for i, v in pairs(entities) do
				if (not v:IsDead() and player ~= v) then
					if (nCX.IsNeutral(player.id) or not nCX.IsSameTeam(v.id, player.id)) then
						return false;
					end
				end
			end
		end
		return true;
	end,
	---------------------------
	--  ResetTeamScores
	---------------------------
	ResetTeamScores = function(self)
		for i, teamId in pairs(self.teamId) do
			nCX.SetSynchedGlobalValue(10 + teamId, 0);
		end
	end,
	---------------------------
	--  SetTeamScore
	---------------------------
	SetTeamScore = function(self, teamId, score)
		nCX.SetSynchedGlobalValue(10 + teamId, score);
		--self:CheckScoreLimit(teamId, score);
	end,
	---------------------------
	--  GetTeamScore
	---------------------------
	GetTeamScore = function(self, teamId)
		return nCX.GetSynchedGlobalValue(10 + teamId) or 0;
	end,
	---------------------------
	--  CheckScoreLimit
	---------------------------
	CheckScoreLimit = function(self, shooter, score)
		local scoreLimit = System.GetCVar("g_scorelimit");
		if ((scoreLimit > 0) and (score >= scoreLimit)) then
			--self:OnGameEnd(teamId, 3);
		end
	end,
	---------------------------
	--	OnVehicleDestroyed		
	---------------------------
	OnVehicleDestroyed = function(self, vehicle)
		local vehicleId = vehicle.id;
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
	--		ProcessVehicleScores
	---------------------------
	ProcessVehicleScores = function(self, vehicle, shooter, assist)
		local vehicleId = vehicle.id;
		if (not nCX.IsNeutral(vehicleId) and not nCX.IsSameTeam(shooter.id, vehicleId)) then
			CryMP:HandleEvent("OnProcessVehicleScores", {shooter, vehicle, assist});
		end
	end,
	---------------------------
	--	GetPlayerSpawnGroup    	
	---------------------------
	GetPlayerSpawnGroup = function(self, playerId)
	end,
	---------------------------
	--		CreateExplosion	--
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
	--		DefaultState	--
	---------------------------
	DefaultState = function(self, cs, state)
		local default=self[cs];
		self[cs][state]={
			OnStartLevel = default.OnStartLevel,
			OnStartGame = default.OnStartGame,	
			OnUpdate = default.OnUpdate,	
		}
	end,
};

InstantAction:DefaultState("Server", "InGame");

Net.Expose {
	Class = InstantAction,
	ClientMethods = {
		ClSetupPlayer			= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, },
		ClSetSpawnGroup	 		= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, },
		ClSetPlayerSpawnGroup	= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, ENTITYID },
		ClSpawnGroupInvalid		= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, },
		ClVictory				= { RELIABLE_ORDERED,   NO_ATTACH, ENTITYID, },
		ClNoWinner				= { RELIABLE_ORDERED,   NO_ATTACH, },
		
		ClStartWorking			= { RELIABLE_ORDERED,   NO_ATTACH, ENTITYID; STRINGTABLE },
		ClStepWorking			= { RELIABLE_UNORDERED, NO_ATTACH, INT8 },
		ClStopWorking			= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, BOOL },
		ClWorkComplete			= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, STRINGTABLE },

		ClClientConnect			= { RELIABLE_UNORDERED, NO_ATTACH, STRING, BOOL },
		ClClientDisconnect		= { RELIABLE_UNORDERED, NO_ATTACH, STRING, },
		ClClientEnteredGame		= { RELIABLE_UNORDERED, NO_ATTACH, STRING, },
	},
	ServerMethods = {
		RequestRevive		 	= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, },
		RequestSpawnGroup		= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, ENTITYID },
		RequestSpectatorTarget	= { RELIABLE_UNORDERED, NO_ATTACH, ENTITYID, INT8 },
	},
	ServerProperties = {
	},
};
