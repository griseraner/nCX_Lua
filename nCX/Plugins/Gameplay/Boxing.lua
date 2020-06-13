Boxing = {

	---------------------------
	--		Config
	---------------------------
	Tick 			= 1,
	Tag 			= 7,
	Rounds 			= 3,
	ForbiddenArea 	= 8,
	Scale 			= 4, -- 1, 2, 4, 8 works (1 lags really hard)
	StartPosX		= 3000,
	Boxers			= {},
	Intruders 		= {},
	Flags			= {},
	FlagDim			= {
		Length = 2.55,
		Height = 1.31,
	},

	Server = {
	
		OnKill = function(self, hit, shooter, target)
			if (target.Info) then
				local playerId, channelId = target.id, target.Info.Channel;
				if (self.Intruders[playerId]) then
					self:IntruderLeftArea(playerId);
				--elseif (self.Boxers[channelId] and nCX.Count(self.Boxers) == 0) then
				--	self.Boxers[channelId] = nil;
				end
			end
		end,
			
		OnDisconnect = function(self, channelId, player)
			self.Intruders[player.id] = nil;
			self.Boxers[channelId] = nil;
		end,
		
		OnEnterArea = function(self, zone, entity)
			if (zone.id == self.ZoneId) then
				local channelId = entity.Info.Channel;
				if (nCX.GodMode(channelId)) then
					return;
				end
				if (self.Boxers[channelId]) then
					if (self.Intruders[entity.id]) then
						self:IntruderLeftArea(entity.id);
					end
				else
					for channelId, playerId in pairs(self.Boxers) do
						local player = nCX.GetPlayerByChannelId(channelId);
						if (player) then
							CryMP.Ent:PlaySound(player.id, "perimeter");
						end
					end
					self:HandleIntruder(entity.id, true);
				end
			end
		end,
				
		OnLeaveArea = function(self, zone, entity)
			if (zone.id == self.ZoneId and entity.Info and nCX.IsPlayerActivelyPlaying(entity.id)) then
				if (self.Boxers[entity.Info.Channel]) then
					self:Teleport(entity, true);
					if (g_gameRules.AwardPPCount) then
						g_gameRules:AwardPPCount(entity.id, -100, true);
					end
				elseif (self.Intruders[entity.id]) then
					self:IntruderLeftArea(entity.id);
				end
			end
		end,
		
		OnChangeSpectatorMode = function(self, player)
			if (self.Intruders[player.id]) then
				self:IntruderLeftArea(player.id);
			end
			local channelId = player.Info.Channel;
			if (self.Boxers[channelId]) then
				self.Boxers[channelId] = nil;
			end
		end,
		
		OnRequestRevive = function(self, player)
			local channelId = player.Info.Channel;
			local rounds = self.Boxers[channelId];
			if (rounds) then
				if (rounds == self.Rounds) then
					self.Boxers[channelId] = nil;
					return false;
				else
					if (player.actor:GetDeathTimeElapsed() > 3.0) then
						self:Teleport(player, true);
					end
					return true;
				end
			end				
		end,
		
	},
	
	Activate = function(self, position)
		local map = nCX.GetCurrentLevel():sub(16, -1):lower();
		local height = map ~= "mesa" and 1500 or position == "sky" and 1500 or position == "underground" and 200 or 334;
		self.Height = height;
		self:SpawnArena();
		local typ = self.Height == 334 and "ground" or self.Height == 1500 and "sky" or "underground";
		local text = self.Height == 334 and "~ OPEN ~" or self.Height == 1500 and "~ OPEN : SKY ~" or "~ OPEN : UNDERGROUND ~";
		--CryMP.Msg.Flash:ToAll({50, "#e7e7e7", "#9f9f9f", false}, text, "<font size=\"32\"><b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#3366CC\">BOXING ( </font>%s <font color=\"#3366CC\">) ARENA</font> <font color=\"#b9b9b9\">!! ***</font></b></font>");
		self:Log("Boxing started (arena: "..typ..")");
		return true;
	end,
		
	OnShutdown = function(self, restart)		
		if (not restart) then
			for channelId, c in pairs(self.Boxers) do
				local player = nCX.GetPlayerByChannelId(channelId);
				if (player) then
					CryMP.Msg.Chat:ToPlayer(channelId, "Boxing closed - you were returned home!", self.Tag);
					self:Teleport(player);
				end
			end	
			for entityId, nigga in pairs(self.Intruders or {}) do
				self:IntruderLeftArea(entityId);
			end
			self:RemoveArena();
			self:GravitySphere(false);
			--CryMP.Msg.Animated:ToAll(2,"<b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#C00000\">BOXING ( <font color=\"#e7e7e7\">CLOSED</font> <font color=\"#C00000\">) ARENA</font> <font color=\"#b9b9b9\">!! ***</font></b>");
			self:Log("Boxing closed...");
		end
	end,
	
	OnTick = function(self, players)
		for entId, v in pairs(self.Intruders) do
			self:HandleIntruder(entId);
		end
	end,
	
	IsBoxing = function(self, channelId)
		return self.Boxers[channelId];
	end,
	
	Teleport = function(self, player, ignore, revive)
		local playerId, channelId = player.id, player.Info.Channel;
		local dead = player:IsDead();
		if (self.Intruders[playerId]) then
			self:IntruderLeftArea(playerId);
		end
		if (not ignore) then
			if (self.Boxers[channelId]) then
				self.Boxers[channelId] = nil;
				if (revive) then
					CryMP.Ent:Revive(player, true);
					return true;
				end
				return self:Return(player);
			else
				CryMP.Ent:PlaySound(playerId, "alert");
				CryMP:GetPlugin("Refresh", function(self) self:SavePlayer(player); end);
			end
		end
		local coordinates = self:GetSafeLocation(player);
		nCX.SetInvulnerability(playerId, true, 4);
		player.actor:SetNanoSuitEnergy(200);
		nCX.ParticleManager("misc.emp.sphere", 0.5, player:GetWorldPos(), g_Vectors.up, 0);
		CryMP.Ent:MovePlayer(player,coordinates[1],coordinates[2]); 
		nCX.ParticleManager("misc.emp.sphere", 0.5, coordinates[1], g_Vectors.up, 0);
		player.inventory:Destroy();
		player.actor:SetInventoryAmmo("explosivegrenade", 0, 3);
		CryMP:DeltaTimer(10, function()
			nCX.GiveItem("AlienCloak", channelId, false, false);
			nCX.GiveItem("OffHand", channelId, false, false);  
			nCX.GiveItem("Fists", channelId, false, false);
			g_gameRules:EquipPlayer(player); 
		end);
		if (not ignore) then
			self.Boxers[channelId] = (self.Boxers[channelId] or 0) + 1;
			CryMP.Msg.Chat:ToAll("[ #"..math:zero(nCX.Count(self.Boxers)).." "..player:GetName().." ]:: Entering WEAPON-FREE Arena :: Get Ready!", self.Tag);
			--nCX.SendTextMessage(5, "<font size=\"32\"><b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#df4242\">BOXING (<font color=\"#DDDDDD\"> x O x </font><font color=\"#df4242\">) MATCH</font> <font color=\"#b9b9b9\">!! ***</font></b></font>", channelId);
		elseif (not dead) then
			CryMP.Msg.Chat:ToPlayer(channelId, "Stay inside the zone!", self.Tag);
		end
		return true;
	end,
	
	Return = function(self, player, revive)
		local done, warum = CryMP:GetPlugin("Refresh", function(self) return self:RestorePlayer(player); end);
		if (not done and not player:IsDead()) then
			CryMP.Ent:RestoreInventory(player);
			return CryMP.Ent:Portal(player);
		elseif (not done) then
			CryMP.Ent:Revive(player, true);
			return true;
		end
	end,
	
	SpawnArena = function(self)
		self:SpawnRow(self.Height, "Wall");
		local params = {
			name = "Boxing", 
			pos = self:GetCenterPos(true), 
			dir = { x=0, y=1, z=0 }, 
			dim = { x=70, y=135, z=50,},
		};
		if (self.Height == 334) then
			params.dim = { x=52, y=52, z=85,};
		end
		local trigger = CryMP.Ent:SpawnTrigger(params, false, true);
		self.ZoneId = trigger.id;
		trigger.CanEnter = function(trigger, entity)
			return entity.Info and nCX.IsPlayerActivelyPlaying(entity.id);
		end		
		if (self.Height ~= 334) then
			for i=0, 16/self.Scale do
				for j=0, 32/self.Scale+1 do
					local pos, dir = {x = self.StartPosX + i * self.FlagDim.Length * self.Scale,y = self.StartPosX + j * self.FlagDim.Height * self.Scale, z = self.Height - 1,}, { x=0, y=0, z=1 };
					self:Spawn("Floor", "Flag", pos, dir);
				end
			end
		end
	end,
	
	SpawnArenaCage = function(self, roof)	
		local amount = 16/self.Scale;
		if (not self.CageBuilt) then
			for i = 1, amount do
				self:SpawnRow(self.Height+i*1.55*self.Scale, "Cage");
			end
			self.CageBuilt = true;
		end
		if (roof and not self.RoofBuilt) then
			local height = self.Height+amount*1.55*self.Scale + 2;
			for i=0, amount do
				for j=0, 32/self.Scale+1 do
					local pos, dir = {x = self.StartPosX + i * self.FlagDim.Length * self.Scale,y = self.StartPosX + j * self.FlagDim.Height * self.Scale, z = height,}, { x=0, y=0, z=1 };
					self:Spawn("Roof", "Flag", pos, dir);
				end
			end
			self.RoofBuilt = true;
		end
		return true;
	end,
	
	Spawn = function(self, name, class, pos, dir)
		local flag = System.SpawnEntity({
			class = class,
			name = class.."_Boxing_"..name..tostring(CryMP.Library:SpawnCounter()),
			orientation = dir,
			position = pos,
		});
		--[[
		if (name == "Wall") then
			local players = nCX.GetPlayers();
			if (players) then
				local pos = flag:GetPos();
				pos.z = pos.z + 2*self.Scale;
				for i, player in pairs(players) do
					self:ParticleManager("smoke_and_fire.VS2_Fire.smallfire_base",1,pos,g_Vectors.up,player.Info.Channel);
				end
			end
		end
		]]
		if (class == "Flag") then
			self.Flags[flag.id] = (name == "Cage" and 1) or (name == "Roof" and 2) or 0;
			flag:SetScale(self.Scale);
		end
		return flag;
	end,
	
	SpawnRow = function(self, height, name)
		local startPos = self.StartPosX; -- 2944;
		local count = 16/self.Scale;
		local flagLength = self.FlagDim.Length * self.Scale;
		local rowLength = count * flagLength;
		for i=0, count do
			local pos, dir = { x=startPos+i*flagLength, y=startPos, z=height, }, { x=0, y=1, z=0, };
			self:Spawn( name, "Flag", pos, dir);
		end
		for i=0, count do
			local pos, dir = { x=startPos+rowLength+flagLength, y=startPos+i*flagLength, z=height }, { x=-1, y=0, z=0 };
			self:Spawn( name, "Flag", pos, dir);
		end
		for i=1, count+1 do
			local pos, dir = { x=startPos+i*flagLength, y=startPos+rowLength+flagLength, z=height }, { x=0, y=-1, z=0 }; 
			self:Spawn( name, "Flag", pos, dir);
		end
		for i=1, count+1 do
			local pos, dir = { x=startPos, y=startPos+i*flagLength, z=height }, { x=1, y=0, z=0 };
			self:Spawn( name, "Flag", pos, dir);
		end
		System.LogAlways("SpawnRow: Flag count: #$4"..nCX.Count(self.Flags));
	end,
	
	GetCenterPos = function(self, in3d)
		local startPos = self.StartPosX; 
		local count = 16/self.Scale;
		local flagLength = self.FlagDim.Length * self.Scale;
		local halfRow = count * flagLength * 0.5 + (flagLength * 0.5);
		local pos = {x = startPos + halfRow, y = startPos + halfRow, z = self.Height};
		if (in3d) then
			local flagHeight = self.FlagDim.Height * self.Scale;
			pos.z = pos.z + (count * 1.55 * self.Scale + 2) * 0.5 + (flagHeight * 0.5);
		else
			pos.z = pos.z - 0.3;
		end
		return pos;
	end,		
	
	GravitySphere = function(self, add)
		if (add) then
			local pos, dir = self:GetCenterPos(true), { x=0, y=0, z=0, };
			local sphere = self:Spawn("Zone", "GravitySphere", pos, dir);
			if (sphere) then
				self.GravitySphereId = sphere.id;
				if (sphere.SetRadius) then
					sphere:SetRadius(37);
				end
				return true;
			end
		elseif (self.GravitySphereId) then
			System.RemoveEntity(self.GravitySphereId);
			self.GravitySphereId = nil;
			return true;
		end
	end,
	
	HandleIntruder = function(self, entityId, display)
		self.Intruders[entityId] = self.Intruders[entityId] or self.ForbiddenArea;
		nCX.ForbiddenAreaWarning(true, self.Intruders[entityId], entityId);
		if (self.Intruders[entityId] == 0) then
			nCX.ServerHit(entityId,entityId,10,"punish");
			return;
		end
		if (not display) then
			self.Intruders[entityId] = self.Intruders[entityId] - 1;
		end
	end,

	IntruderLeftArea = function(self, entityId)
		self.Intruders[entityId] = nil;
		nCX.ForbiddenAreaWarning(false, 0, entityId);
	end,

	RemoveArena = function(self, type)
		if (not type and self.ZoneId) then
			System.RemoveEntity(self.ZoneId);
			self.ZoneId = nil;
		end
		for flagId, v in pairs(self.Flags) do
			if (not type or v == type or v > type) then
				System.RemoveEntity(flagId);
				self.Flags[flagId] = nil;
			end
		end
		if (type == 2) then
			self.RoofBuilt = nil;
		elseif (type) then
			self.CageBuilt = nil;
		end
	end,

	GetSafeLocation = function(self, player)
		local count = 16/self.Scale;
		local flagLength = self.FlagDim.Length * self.Scale;
		local rowLength = count * flagLength;
		local coordinates = {
			{{x=self.StartPosX, y=self.StartPosX, z=self.Height+1}, {0,0,-0.842285}},
			{{x=self.StartPosX+rowLength, y=self.StartPosX, z=self.Height+1}, {0,0,0.754898}},
			{{x=self.StartPosX, y=self.StartPosX+rowLength, z=self.Height+1}, {0,0,-2.40345}},
			{{x=self.StartPosX+rowLength, y=self.StartPosX+rowLength, z=self.Height+1}, {0,0,2.31749}},
	    };
		local possiblePoints={};
		for i, pos in pairs(coordinates) do
			if (not CryMP.Ent:IsEnemyNear(player, 3, false, pos[1])) then
				possiblePoints[#possiblePoints+1]=pos;
			end
		end
		local pos = #possiblePoints > 0 and possiblePoints[math.random(1, #possiblePoints)] or coordinates[math.random(1, #coordinates)];
		pos[1].x = pos[1].x + 3;
		pos[1].y = pos[1].y + 3;
		return pos;
	end,
	
	Boxmode = function(self, channelId, mode)
		if (mode == "lights") then
			local effects = {"misc.extremly_important_fx.lights_red","misc.extremly_important_fx.lights_green","misc.extremly_important_fx.lights_random"};
			local height = self.Height~=334 and self.Height-0.6 or self.Height-0.8;
			nCX.ParticleManager(effects[math.random(1,#effects)], 3, self:GetCenterPos(), g_Vectors.up, 0);
			CryMP.Msg.Chat:ToPlayer(channelId, "Partylights active...", self.Tag);
			return true;
		elseif (mode == "smoke") then
			local pos = self:GetCenterPos()
			for chan, y in pairs(self.Boxers) do
				nCX.ParticleManager("explosions.Smoke_grenade.smoke", 3, pos, g_Vectors.up, chan);
			end
			CryMP.Msg.Chat:ToPlayer(channelId, "Smoke active...", self.Tag);
			return true;
		elseif (mode == "gravity") then
			if (self.GravitySphereId) then
				self:RemoveZeroGravity(channelId);
			else
				local spawned = self:GravitySphere(true);
				if (spawned) then
					self:SpawnArenaCage(true);
				end
				CryMP.Msg.Chat:ToPlayer(channelId, "Zero Gravity "..(spawned and "active..." or "failed!"), self.Tag);
			end
			return true;
		elseif (mode == "cage") then
			if (self.CageBuilt) then
				self:RemoveArena(1);
				self:RemoveZeroGravity(channelId);
				return true;
			else
				for channel, c in pairs(self.Boxers) do
					local player = nCX.GetPlayerByChannelId(channel);
					if (player) then
						local x = math.random(self.StartPosX, self.StartPosX + 30);
						local y = math.random(self.StartPosX, self.StartPosX + 30);
						local z = math.random(self.Height, self.Height+3);
						nCX.SetInvulnerability(player.id, true, 3);
						player.actor:SetNanoSuitEnergy(200);
						nCX.MovePlayer(player.id,{x, y, z},player:GetWorldAngles());
						nCX.ParticleManager("misc.emp.sphere", 0.5, player:GetWorldPos(), g_Vectors.up, 0);
					end
				end
				self:SpawnArenaCage();
				return true;
			end
		end
		return false, "mode not recognized";
	end,
	
	RemoveZeroGravity = function(self, channelId)
		self:RemoveArena(2);
		local grav = self:GravitySphere(false);
		if (grav) then
			CryMP.Msg.Chat:ToPlayer(channelId, "Zero Gravity removed...", self.Tag);
		end
		for channel, c in pairs(self.Boxers) do
			local player = nCX.GetPlayerByChannelId(channel);
			if (player) then
				nCX.SetInvulnerability(player.id, true, 3);
			end
		end
	end,
	
};