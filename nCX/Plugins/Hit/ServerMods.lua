ServerMods = {

	---------------------------
	--		Config
	---------------------------
    Tick 		= 1,
	Reward 		= 1000,
	Bombs		= {};
	Zones		= {};
	MapWeapons	= {};
	
	Server = {
		
		OnNewMap = function(self, map, reboot, reload)
			if (not reload) then
				for i, ent in pairs(System.GetEntities() or {}) do
					if (ent.weapon and ent.Properties.Respawn and  ent.Properties.Respawn.bRespawn == 1) then
						self.MapWeapons[ent.id] = {ent.class, ent:GetWorldPos(), ent:GetDirectionVector(1), ent.Properties};
					end
				end
			end
		end,
	
		OnChangeSpectatorMode = function(self, player) 
			if (player.id == self.ID) then
				self:End(true, false, "went spectating");
			end
		end,

		OnDisconnect = function(self, channelId, player)
			if (player.id == self.ID) then
				self:End(true, false, "disconnected");
			end
		end,
		
		OnKill = function(self, hit, shooter, target)
			if (not shooter) then
				return;
			end
			if (target.id == self.ID) then
				if (hit.self) then
					if (self.CD == 0) then
						self:End();
					else
						self:End(true);
					end
				else
					self:End(false, shooter);
				end
			end
		end,
		
		OnEnterArea = function(self, zone, player)
			local area = self.Zones[zone.id];
			if (area) then
				nCX.SendTextMessage(0, "[ "..area.RemainingTime.." ] >>> MORTAR [ INCOMING ] ATTACK!", player.Info.Channel);
				area.Players = area.Players or {};
				area.Players[player.Info.Channel] = true;
			end
		end,
		
		OnLeaveArea = function(self, zone, player)
			local area = self.Zones[zone.id];
			if (area) then
				local channelId = player.Info.Channel;
				if (area.Players) then
					area.Players[channelId] = nil;
				end
				nCX.SendTextMessage(5, "", channelId);
			end
		end,
		
	},
	
	Initiate = function(self, player)
		local playerId = player.id;
		CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "// SELF DESTRUCT SEQUENCE INITIATED!", self.Tag);
		self.ID = playerId;
		self.CD = 10;
		self.Radius = {};
		g_gameRules:SendMDAlert(nCX.GetTeam(playerId), "tacgun", playerId)
		nCX.AddMinimapEntity(playerId, 2, 0);
		CryMP.LastSelfDestruct = _time;
		return true;
	end,
	
	MortarAttack = function(self, player, distance)
		local confDelay = 3;                    -- Delay between selection of target and strike (in seconds)
		local confMaxDistance = 300;            -- Maximal distance of strike
		local confMinDistance = 50;             -- Minimal distance of strike
		local confUseDelay = 60;                -- Delay between each use of mortar
		local confExplosions = 20;              -- Number of explosions by mortar
		local confFrequency = 0.2;              -- Delay between each explosion (in seconds)
		local confRadius = 6;                   -- Radius of the strike (keep it minimalistic)
		local confWarnRadius = confRadius + 10; -- Radius where to warn players about strike
		local confAngle = 45;
		local confPressure = 200;
		local confEffects = {"explosions.rocket_terrain.exocet"};
		local confScale = 0.8;
		local confHoleSize = 2;
		local confBombRadius = 15;
		local confBombDamage = 100;
		local confHeight = 150;
		confRadius = nCX.GetCurrentLevel():sub(16, -1):lower() == "savanna" and 10 or confRadius;
		local playerId = player.id;
		self.Bombs[player.id] = {};
		nCX.AddMinimapEntity(playerId, 2, 0);
		CryMP.Msg.Chat:ToAll("PLAYER :: "..player:GetName().." launched a mortar attack!");
		local pos = player:GetWorldPos();
		local dir = player:GetDirectionVector(1);
		local hit = {x=0, y=0, z=0};
		hit.x = pos.x + (dir.x * distance);
		hit.y = pos.y + (dir.y * distance);
		hit.z = pos.z + (dir.z * distance);
		hit.z = System.GetTerrainElevation(hit);
		local entities = System.GetPhysicalEntitiesInBox(hit, confRadius); 
		if (entities) then
			for i, ent in pairs(entities) do
				if (ent.vehicle and ent:GetName() == "AFK_TRUCK") then
					return false, "afk truck near", CryMP.Ent:GetVehicleName(ent.class).." in target pos!"
				end
			end
		end	
		g_gameRules:CreateExplosion(player.id,nil,0,hit,g_Vectors.up,1,1,1,1,"explosions.flare.night_time_selfillum",1, 1, 1, 1);
		local params = {
			name = player:GetName().."_mortar_trigger",
			class = "ActionTrigger",
			dim = {x = confWarnRadius, y = confWarnRadius, z = confWarnRadius * 3,},
			pos = hit,
		};	
		local trigger = CryMP.Ent:SpawnTrigger(params);
		if (trigger) then
			trigger.CanEnter = function(trigger, entity)
				return entity.Info;
			end
			self.Zones[trigger.id] = { RemainingTime = confDelay+1,};
		else
			return false, "trigger error";
		end
		-- #BOMB 
		-- "Objects/library/props/watermine/watermine.cgf" -- "Objects/characters/human/story/female_scientist/female_scientist.cdf"; ---("Objects/library/props/snowman/snowman.cgf");  --Objects/library/props/watermine/watermine.cgf -- Objects\characters\animals\whiteshark\greatwhiteshark.cdf
		local strike;
		CryMP:SetTimer(confDelay-1, function()
			nCX.RemoveMinimapEntity(playerId);
		end);
		CryMP:SetTimer(1, function()
			for strike = 0, confExplosions do
				CryMP:DeltaTimer(strike * confFrequency * 80, function()
					local randx = math.random(-confRadius, confRadius);
					local randy = math.random(-confRadius, confRadius);
					local position = {x = hit.x + randx, y = hit.y + randy, z = hit.z};
					local terrain_z = System.GetTerrainElevation(position);
					local bomb = CryMP.Ent:SpawnObject({
						objModel= "Objects/library/props/watermine/watermine.cgf",
						bPhysics = 1,
						name = "MORTAR_BOMB",
						position = {x = position.x, y = position.y, z = terrain_z+confHeight},
						orientation = g_Vectors.up,
					});
					if (bomb) then
						bomb:AddImpulse(-1,bomb:GetCenterOfMassPos(),g_Vectors.down,400,1);
						bomb.OnHit = function(self, hit)
							if (hit.typeId ~= 0) then
								--System.LogAlways(self:GetName().." $4HIT shooter "..hit.shooter:GetName().." => "..hit.target:GetName().." "..hit.type.." "..hit.typeId.." "..hit.damage.." "..(hit.explosion and "EXPLOSION" or "No Expl"));						
								local effect = confEffects[math.random(1, #confEffects)];
								g_gameRules:CreateExplosion(playerId, playerId, confBombDamage, hit.pos, g_Vectors.up, confBombRadius, confAngle, confPressure, confHoleSize, effect, confScale, confScale, confScale, confScale);
								--nCX.ParticleManager(effect, confScale, hit.pos, g_Vectors.up, 0);
								System.RemoveEntity(self.id);
							end
						end;
						self.Bombs[player.id][bomb.id] = true;
						bomb:SetScale(1.4);
					else
						System.LogAlways("Failed spawning Mortar Bomb");
					end
			   end);
			end
		end);
		return true;
	end,
	
	OnShutdown = function(self, restart) 
		for playerId, ok in pairs(self.Radius or {}) do
			nCX.SendTextMessage(5, "", nCX.GetChannelId(playerId));
			nCX.ForbiddenAreaWarning(false, 0, playerId);
		end
		if (not restart) then
			for playerId, tbl in pairs(self.Bombs) do
				for bombId, v in pairs(tbl) do
					System.RemoveEntity(bombId);
				end
			end
			for zoneId, tbl in pairs(self.Zones) do
				System.RemoveEntity(zoneId);
			end
		end
	end,

	End = function(self, suicide, shooter, reason)
		local nukerId = self.ID;
		local nuker = nCX.GetPlayer(nukerId);
		if (nuker) then
			nCX.SendTextMessage(5, "", nuker.Info.Channel);
			nCX.ForbiddenAreaWarning(false, 0, nukerId);
			if (suicide or shooter) then
				local name = nuker:GetName();	
				if (shooter and shooter.actor and not nCX.IsSameTeam(shooter.id, nukerId)) then
					CryMP.Msg.Chat:ToAll("NANO-[+]-CELL : "..shooter:GetName().." killed the SELF-DESTRUCTOR-[ "..name.." ]-BONUS "..self.Reward.." POINTS!");
					nCX.ParticleManager("Alien_Weapons.singularity.Hunter_Singularity_Impact", 0.2, nuker:GetWorldPos(), g_Vectors.up, 0);
					CryMP.Library:Pay(shooter, self.Reward);
				else
					CryMP.Msg.Chat:ToAll("NANO-[+]-CELL : Self Destructor "..name.." "..(reason or "killed himself"), self.Tag);
				end
				CryMP.LastSelfDestruct = nil;
			end
		end
		self:ShutDown(true);
	end,

	OnTick = function(self)
		for triggerId, data in pairs(self.Zones or {}) do
			local attack = data.RemainingTime <= 0;
			if (data.Players) then
				for channelId, v in pairs(data.Players) do
					if (attack) then
						nCX.SendTextMessage(0, "", channelId);
					else
						nCX.SendTextMessage(0, "[ "..data.RemainingTime.." ] >>> MORTAR [ INCOMING ] ATTACK!", channelId);
					end
				end
			end
			if (attack) then
				System.RemoveEntity(triggerId);
				self.Zones[triggerId] = nil;
			else
				data.RemainingTime = data.RemainingTime - 1;		
			end
		end
		local nukerId = self.ID;
		if (nukerId) then
			local nuker = nCX.GetPlayer(nukerId);
			if (not nuker) then
				self:End();
				return;
			end
			if (self.CD==10) then
				nCX.SendTextMessage(2, "! WARNING ! :: "..nuker:GetName().." is about to SELF-NUKE! :: You have "..self.CD.." seconds to reach MINIMUM SAFE DISTANCE!", 0);
			elseif (self.CD==5) then
				CryMP.Ent:PlaySound(nukerId, "timer5s");
				nCX.SendTextMessage(2, "! WARNING ! :: SELF-DESTRUCT INITIATED :: You have "..self.CD.." seconds to reach MINIMUM SAFE DISTANCE!", 0);
			end
			local CD = self.CD < 10 and "0"..self.CD or CD;
			if (self.CD == 0) then
				g_gameRules:CreateExplosion(nukerId,nil,500,nuker:GetWorldPos(),g_Vectors.up,100,100,100,100,"explosions.TAC.rifle_far",1, 1, 1, 1);
				g_gameRules:KillPlayer(nuker);
				self:End();
			else
				nCX.ForbiddenAreaWarning(true, self.CD, nukerId);
				local c=0;
				local ents = System.GetEntitiesInSphereByClass(nuker:GetWorldPos(), 100, "Player");
				if (ents) then
					for i, player in pairs(ents) do
						if (not player:IsDead() and player.actor:GetSpectatorMode() == 0) then
							local playerId = player.id;
							if (playerId ~= self.ID and not self.Radius[playerId]) then
								self.Radius[playerId] = true;
							end
							if (not nCX.IsSameTeam(playerId, nukerId)) then
								nCX.ForbiddenAreaWarning(true, self.CD, playerId);
								nCX.SendTextMessage(0, "! CAUTION NUCLEAR DETONATION ! ::: [ 00:"..CD.." ]", player.Info.Channel);
								c=c+1;
							end
						end
					end
				end
				if (self.CD ~= 10) then
					for playerId, ok in pairs(self.Radius) do
						if (not nCX.IsSameTeam(playerId, nukerId)) then
							if (nuker:GetDistance(playerId) > 100) then
								nCX.SendTextMessage(5, "", nCX.GetChannelId(playerId));
								nCX.ForbiddenAreaWarning(false, 0, playerId);
								self.Radius[playerId] = nil;
							end
						end
					end
				end
				nCX.SendTextMessage(0, "! SELF DESTRUCT SEQUENCE ! ::: [ 00:"..CD.." ] ::: ! ENEMY IN EXPLOSION RADIUS ! ::: [ "..c.." ] ::: ", nuker.Info.Channel);
			end
			self.CD = (self.CD or 10) - 1;
		end
	end,
	
};
