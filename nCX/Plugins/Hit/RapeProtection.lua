RapeProtection = {
	
	--refinery only found shape for nk hq -> we need to spawn trigger for us hq or fapp another shape but which one..
	
	---------------------------
	--		Config
	---------------------------
	EntranceFee 	= 30,
	Timeout			= 30, -- timeout for bunkerprotection
	Warning			= 8,
	Base			= {},
	Bunker 			= {},
	Tunnel			= {},
	Zones			= {},
	Messages 		= {
		Shooter 	= "<font size=\"26\"><b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#ce3636\">%s-[+]-RAPE : DETECTED</font> <font color=\"#b9b9b9\">!! ***</font></b></font>",
        Target		= "<font size=\"26\"><b><font color=\"#bababa\">[+] >>> %s [ </font><font color=\"#cf3b3b\">PROTECTED</font><font color=\"#bababa\"> ] RAPE</font></font></font>",
	},
	Debug 			= false,
	Tac_HitType  	= 10;
	
	Server = {
		
		OnDisconnect = function(self, channelId, player)
			self.Base[player.id] = nil;
			self.Bunker[player.id] = nil;
			if (self.Tunnel) then
				self.Tunnel[player.id] = nil;
			end
		end,
			
		OnEnterArea = function(self, zone, entity)
			local bunkerId = self.Zones[zone.id];
			if (bunkerId and nCX.IsSameTeam(entity.id, bunkerId)) then
				self.Bunker[entity.id] = zone.id;
			end
		end,
		
		OnLeaveArea = function(self, zone, entity)
			if (self.Bunker[entity.id]) then
				self.Bunker[entity.id] = nil;
			end
		end,
		
		OnCapture = function(self, zone, teamId, inside)
			if (zone.class == "SpawnGroup") then
				for triggerId, bunkerId in pairs(self.Zones) do  
					if (zone.id == bunkerId) then
						local trigger = System.GetEntity(triggerId);
						if (trigger) then
							for channelId, v in pairs(inside or {}) do
								local player = nCX.GetPlayerByChannelId(channelId);
								if (player and trigger:IsInside(player)) then
									self.Bunker[player.id] = triggerId;
								end
							end
						end
						break;
					end
				end
			end
		end,
		
		OnPerimeterBreached = function(self, base, entity, areaId, entering)
			local channelId = entity.Info.Channel;
			if (areaId == 0) then
				self:OnEnteringTunnel(channelId, base, entity, entering);
				return;
			end
			if (entering) then
				if (not self.Base[entity.id]) then
					local mode;
					if (nCX.IsSameTeam(base.id, entity.id)) then
						if (nCX.IsPlayerActivelyPlaying(entity.id) and (not entity.LAST_BASE_ENTRANCE or _time - entity.LAST_BASE_ENTRANCE > 5)) then
							local vehicle = entity.actor:GetLinkedVehicle();
							local fee = self.EntranceFee;
							if (vehicle and vehicle:IsHeavy()) then
								if (g_gameRules:GetPlayerPP(entity.id) >= fee) then
									nCX.SendTextMessage(3, "[ BASE:PROTECTION ] Heavy vehicle entrance fee "..fee.." PP...", channelId);
									g_gameRules:AwardPPCount(entity.id, -fee, true);
								else
									nCX.SendTextMessage(3, "[ BASE:PROTECTION ] Shield disabled... (no pp left)", channelId);
									return;
								end
							else
								if (nCX.Spawned[channelId]) then	
									nCX.SendTextMessage(3, "[ BASE:PROTECTION ] You entered the safe zone...", channelId);
								end
								if (CryMP.RSE) then
									CryMP.RSE:ToTarget(channelId, 'g_localActor:PlaySoundEventEx("sounds/interface:hud:hud_reboot",SOUND_DEFAULT_3D,1,{x=0,y=0,z=0},30,300,SOUND_SEMANTIC_AI_READABILITY)');
								end
							end
							entity.LAST_BASE_ENTRANCE = _time;
						end
						mode = true;
					elseif (areaId ~= 3) then
						if (nCX.IsPlayerActivelyPlaying(entity.id)) then
							nCX.SendTextMessage(2, "[ WARNING ] You entered the Enemy Proximity...", channelId);
							g_gameRules.onClient:ClPerimeterBreached(channelId, base.id); -- intruder will hear enemy team voice
							self:Log("Player "..entity:GetName().." has intruded the "..CryMP.Ent:GetTeamName(nCX.GetTeam(entity.id)):upper().." Base Proximity");
						end
						mode = 1; -- base intruder can attack hq niggas who camp in base :)
					end
					if (mode) then
						self.Base[entity.id] = mode;
					end
				end
			elseif (self.Base[entity.id]) then
				if (nCX.IsSameTeam(base.id, entity.id) and nCX.IsPlayerActivelyPlaying(entity.id) and not entity:IsBoxing() and not entity:IsDuelPlayer() and not entity:IsAfk()) then
					if (nCX.Spawned[channelId]) then
						nCX.SendTextMessage(3, "[ BASE:PROTECTION ] You left the safe zone...", channelId);
					end
					if (CryMP.RSE) then
						CryMP.RSE:ToTarget(channelId, 'Sound.Play("sounds/interface:hud:hud_malfunction", g_Vectors.v000, bor(SOUND_LOAD_SYNCHRONOUSLY, SOUND_VOICE), SOUND_SEMANTIC_MP_CHAT);');
					end
				end
				self.Base[entity.id] = nil;
			end
		end,
					
		PreHit = function(self, hit, shooter, target, vehicle) -- shooter vehicle
			if (shooter.Info and hit.typeId ~= 9 and hit.typeId ~= 5 and not hit.self) then --collision
				local schannelId, tchannelId = shooter.Info.Channel, target.Info.Channel;
				if (self.Tunnel) then
					local target_tunnel = self.Tunnel[target.id];
					if (target_tunnel and target_tunnel == true and vehicle and vehicle:IsHeavy()) then
						if (vehicle.builtas) then
							local def = g_gameRules:GetItemDef(vehicle.builtas); 
							if (def and def.md) then -- nuclear vehicles excluded 
								return;
							end
						end
						self:Warn(hit, false, "TUNNEL");
						return true;
					end
				end
				local target_hq, target_bunkerId = self.Base[target.id], self.Bunker[target.id];
				local shooter_hq = self.Base[shooter.id];
				if (shooter_hq and shooter_hq ~= 1) then
					nCX.SendTextMessage(3, "[ BASE:PROTECTION ] Shield disabled...", schannelId);
					if (CryMP.RSE) then
						CryMP.RSE:ToTarget(channelId, 'Sound.Play("sounds/interface:hud:hud_malfunction", g_Vectors.v000, bor(SOUND_LOAD_SYNCHRONOUSLY, SOUND_VOICE), SOUND_SEMANTIC_MP_CHAT);');
					end
					self.Base[shooter.id] = nil;
				end							
				if (hit.typeId == self.Tac_HitType and not target_hq) then
					nCX.SendTextMessage(0, "[ STOP ]  > > > >  NUKES ARE FOR ENEMY BASES !", schannelId);
					nCX.SendTextMessage(0, "[ PROTECTED ]  < < < <  NUKE ATTACK !", tchannelId);
					return true;
				end			
				if (target_bunkerId) then
					if (hit.explosion) then
						if (vehicle and vehicle:IsHeavy()) then 
							local zone = System.GetEntity(target_bunkerId);
							if (zone) then
								zone:SpawnLights(schannelId, "explosions.explosive_bullet.alien", 0.5);
								local bunkerPos = zone:GetWorldPos();
								bunkerPos.z = bunkerPos.z + 2;
								local pos = vehicle:GetCenterOfMassPos();
								local vec = math:DifferenceVectors(pos, bunkerPos);
								local scale = 0.2;
								nCX.ParticleManager("Alien_Weapons.singularity.Tank_Singularity_Spinup", scale, bunkerPos, vec, 0);
							end
							self:Warn(hit, vehicle, "BUNKER");
							return true;
						end
					end
				elseif (target_hq and shooter_hq ~= 1 and target_hq ~= 1 and hit.typeId ~= self.Tac_HitType) then
					if (vehicle and vehicle.builtas) then
						local def = g_gameRules:GetItemDef(vehicle.builtas); 
						if (def and def.md) then -- nuclear vehicles excluded 
							return;
						end
					end
					self:Warn(hit);
					return true;
				end
			end
		end,

		PreVehicleHit = function(self, hit, vehicle, s_vehicle)
			local shooter, target = hit.shooter, hit.target;
			if (shooter.Info and (not hit.self) and hit.typeId ~= self.Tac_HitType and not nCX.IsSameTeam(shooter.id, vehicle.id)) then --collision
				local teamId = nCX.GetTeam(target.id);
				local hq = g_gameRules.hqs[teamId];
				local hqProtected;
				if (hq) then
					local props = hq.Properties;
					local areaId, areaId2 = props.perimeterAreaId, 3; -- -1 seems to be buggy
					hqProtected = (areaId and hq:IsEntityInsideArea(areaId, target.id)) or (areaId2 and hq:IsEntityInsideArea(areaId2, target.id));
					if (hqProtected and self.Base[shooter.id] ~= 1) then
						if (hit.typeId ~= 16) then --tac
							if (s_vehicle and s_vehicle.builtas) then
								local def = g_gameRules:GetItemDef(s_vehicle.builtas); 
								if (def and def.md) then -- nuclear vehicles excluded 
									return;
								end
							end
							self:Warn(hit, s_vehicle);
							return true;
						end
					elseif (self.Tunnel) then 
						if (s_vehicle and s_vehicle:IsHeavy()) then
							if (hq:IsEntityInsideArea(0, target.id)) then -- NK tunnel
								if (s_vehicle.builtas) then
									local def = g_gameRules:GetItemDef(s_vehicle.builtas); 
									if (def and def.md) then -- nuclear vehicles excluded 
										return;
									end
								end
								self:Warn(hit, s_vehicle, "TUNNEL");
								return true;
							end
						end
					end
				end
				if (vehicle.IsHeavy and vehicle:IsHeavy()) then
					if (self.Bunker[shooter.id]) then
						nCX.SendTextMessage(3, "[ BUNKER:PROTECTION ] Shield disabled...", shooter.Info.Channel);
						self.Bunker[shooter.id] = nil;
					end
				end
				if (hit.typeId == self.Tac_HitType and not hqProtected) then
					nCX.SendTextMessage(0, "[ STOP ]  > > > >  NUKES ARE FOR ENEMY BASES !", shooter.Info.Channel);
					return true;
				end				
			end
		end,
		
		OnVehicleDestroyed = function(self, vehicleId)
			if (self.Tunnel and nCX.Count(self.Tunnel) > 0) then
				for entityId, tbl in pairs(self.Tunnel) do
					if (tbl ~= true) then
						if (tbl[1] == vehicleId) then
							self.Tunnel[entityId] = nil;
							nCX.ForbiddenAreaWarning(false, 0, entityId);	
						end
					end
				end
			end
		end,
				
	};
	
	OnInit = function(self)
		local maps = {["Tarmac"] = true, ["Crossroads"] = true, ["Plantation"] = true,};
		local current = nCX.GetCurrentLevel():sub(16, -1);
		--weird flownode bugs while changin to shore (crywarning box appears wont start loading of map until we click ok), 
		--particleeffect 623 cant link edge <70, leave> to <71, set> flowgraph discarded
		--1 bunker not 100% aber noch in ordnung, 1 bunker nigga gedreht um 90°; while using unchanged dir all bunkers need populationcheck!
		local bunkers = System.GetEntitiesByClass("SpawnGroup");
		for i, bunker in pairs(bunkers) do
			if (not bunker.vehicle and not bunker.default) then
				local dir = bunker:GetWorldAngles();
				local params = {
					name = bunker:GetName(),
					pos = bunker:GetWorldPos(),
					dir = dir,
					dim = {x = 18, y = 18, z = 5,},
				};		
				if (not maps[current] and (dir.z > 1 or dir.z < 0)) then
					dir.z = 0;
				end
				local trigger = CryMP.Ent:SpawnTrigger(params, false, self.Debug);
				if (trigger) then
					trigger.CanEnter = function(trigger, entity)
						return entity.Info;
					end
					self.Zones[trigger.id] = bunker.id;
				end
			end
		end
		if (current ~= "Mesa") then
			self.Tunnel = nil;
		end
		if (self.Tunnel or self.Debug) then
			self:SetTick(1);
		end
	end,
	
	OnShutdown = function(self, restart)
		if (not restart) then
			for zoneId, bunkerId in pairs(self.Zones) do
				System.RemoveEntity(zoneId);
			end
			if (self.Tunnel) then
				for entityId, tbl in pairs(self.Tunnel) do
					nCX.ForbiddenAreaWarning(false, 0, entityId);	
				end
			end
		end
	end,
	
	OnTick = function(self, players)
		--[[
		local protection = self.Bunker;
		if (protection) then
			for playerId, time in pairs(protection) do
				local player = nCX.GetPlayer(playerId);
				if (time and player) then
					if (self.Bunker[playerId] == 0) then
						nCX.SendTextMessage(3, "[ BUNKER:PROTECTION ] Shield disabled... (Timeout)", player.Info.Channel);
						return self.Server.OnLeaveArea(self, NULL_ENTITY, player);
					end
					self.Bunker[playerId] = self.Bunker[playerId] - 1;
				end
			end
		end
		]]
		if (self.Debug) then
			for i, player in pairs(players or {}) do
				if (player:GetAccess() == 5) then
					local typ = "OUT";
					if (self.Base[player.id]) then
						typ = "BASE";
					elseif (self.Bunker[player.id]) then
						typ = "BUNKER";
					end
					nCX.SendTextMessage(3, "[ "..typ..":ZONE ] z: "..player:GetWorldPos().z, player.Info.Channel);
				end
			end
		end
		for entityId, tbl in pairs(self.Tunnel) do
			if (tbl ~= true) then
				tbl[2] = tbl[2] - 1;
				if (tbl[2] == 0) then
					nCX.ForbiddenAreaWarning(false, 0, entityId);	
					local vehicleId = tbl[1];
					local vehicle = vehicleId and System.GetEntity(vehicleId);
					if (vehicle) then
						vehicle.vehicle:Destroy();
						local entity = nCX.GetPlayer(entityId);
						if (entity) then
							local name, vName = entity:GetName(), CryMP.Ent:GetVehicleName(vehicle.class);
							nCX.SendTextMessage(2, "[ TUNNEL:CAMP ] "..name.."'s "..vName.." was destroyed. Do NOT camp in the NK tunnel with "..vName.."s!", 0);
							self:Log(name.."'s "..vName.." was destroyed due to Tunnel camping");
						end
					end
					self.Tunnel[entityId] = nil;
				else
					nCX.ForbiddenAreaWarning(true, tbl[2], entityId);	
				end
			end
		end
	end,
	
	OnEnteringTunnel = function(self, channelId, base, entity, entering)
		if (not self.Tunnel or nCX.IsNeutral(entity.id)) then
			return;
		end
		local tunnel = self.Tunnel[entity.id];
		if (entering and not tunnel) then
			if (nCX.IsSameTeam(entity.id, base.id)) then
				if (nCX.IsPlayerActivelyPlaying(entity.id)) then
					nCX.SendTextMessage(3, "[ TUNNEL:ZONE ] Vehicle protection enabled...", channelId);
				end
				self.Tunnel[entity.id] = true;
			else
				local vehicle = entity.actor:GetLinkedVehicle();
				if (vehicle and vehicle:IsHeavy()) then
					if (vehicle.builtas) then
						local def = g_gameRules:GetItemDef(vehicle.builtas); 
						if (def and def.md) then -- nuclear vehicles excluded 
							return;
						end
					end
					nCX.ForbiddenAreaWarning(true, self.Warning, entity.id);
					self.Tunnel[entity.id] = {vehicle.id, self.Warning};
				end
			end			
			if (self:Count() == 1) then
				self:SetTick(1);
			end
		elseif (nCX.IsSameTeam(entity.id, base.id)) then
			if (tunnel) then
				if (nCX.IsPlayerActivelyPlaying(entity.id)) then
					nCX.SendTextMessage(3, "[ TUNNEL:ZONE ] Vehicle protection disabled...", channelId);
				end
				self.Tunnel[entity.id] = nil;
			end
		else
			local vehicle = entity.actor:GetLinkedVehicle();
			if (vehicle and vehicle:IsHeavy()) then
				if (tunnel) then
					self.Tunnel[entity.id] = nil;		
					nCX.ForbiddenAreaWarning(false, 0, entity.id);
				elseif (nCX.Count(self.Tunnel) > 0) then
					for entityId, v in pairs(self.Tunnel) do
						if (entityId == vehicle.id) then
							self.Tunnel[entityId] = nil;
							nCX.ForbiddenAreaWarning(false, 0, entityId);
							break;
						end
					end
				end
				if (self:Count() == 0) then
					self:SetTick(false);
				end
			end
		end
	end,
	
	Count = function(self)
		local c = 0;
		for entityId, v in pairs(self.Tunnel) do
			if (v ~= true) then
				c = c + 1;
			end
		end
		return c; 
	end,
	
	Warn = function(self, hit, s_vehicle, type)
		if (self.Debug) then
			System.LogAlways("[RapeProtection:Warn] ("..(type or "BASE").." | "..(s_vehicle and "SV: "..s_vehicle:GetName() or "-").." | HitType : "..hit.typeId.." ("..hit.type..") | Target : "..hit.target:GetName()); 
		end
		--if (type ~= "BUNKER") then
			nCX.ParticleManager("explosions.gauss.bullet_backup", 0.5, hit.pos, hit.dir, 0);
		--end
		local tbl = self.Messages;
		type = type or "BASE";
		nCX.SendTextMessage(5, tbl.Shooter:format(type), hit.shooter.Info.Channel);
		local channelId = (hit.driver and hit.driver.Info.Channel) or (hit.target.Info and hit.target.Info.Channel);
		if (channelId) then
			--nCX.SendTextMessage(5, tbl.Target:format(type), channelId);	
		end
		if (s_vehicle and s_vehicle.vehicle) then
			s_vehicle.vehicle:OnHit(s_vehicle.id, s_vehicle.id, hit.damage/4, s_vehicle:GetPos(), 5, "punish", hit.explosion or false);
			if (s_vehicle.vehicle:IsDestroyed()) then
				local name, vName = hit.shooter:GetName(), CryMP.Ent:GetVehicleName(s_vehicle.class);
				nCX.SendTextMessage(2, "[ "..type..":RAPE ] "..name.."'s "..vName.." was destroyed!", 0);
				self:Log(name.."'s "..vName.." was destroyed due to "..type:lower().." rape");
			end
		end
	end,
	

};
