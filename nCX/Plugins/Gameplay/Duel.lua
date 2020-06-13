Duel = {

	---------------------------
	--		Config
	---------------------------
	Tick 			= 1,
	Tag 			= 5,
	ParticleManager = true,
	Height 			= 0,
	PlayerInfo		= {},
	
	Round = {
		id 			= 1,
		CountDown 	= 5,
		Bonus 		= {[0]=300,[1]=500,[2]=300,[3]=300,[4]=300,},--200+ for hardcore
	},
	
	GlobalSettings	= {
		BestOf 		= 3,
		WinnerBonus = {[0]=1000,[1]=1500,[2]=1000,[3]=1000,[4]=1000,},--500+ for hardcore
		Timeout 	= 30,
		Capacity 	= 100, -- C4 and Frag mode
		WallOnHit   = false,
	},
	
	Weapon = {
		Available 	= {
			{"random", {}},
			{"C4", {}},
			{"Fists", {}},
			--{"FGL40", {}},
			{"Hurricane", {"LAMRifle"}},
			{"DSG1", {"LAMRifle"}},
			{"AlienMount", {"LAMRifle"}},
			{"Shotgun", {"AssaultScope", "LAMRifle"}},
			{"GaussRifle", {"LAMRifle"}},
			{"SOCOM", {"SOCOMSilencer", "LAM"}},
			--{"AY69", {"SOCOMSilencer", "LAM"}},
			{"SCAR", {"LAMRifle"}},
			{"FY71", {"Silencer","LAMRifle"}},
			{"SMG", {"Silencer","LAMRifle"}},
			{"SCARTutorial", {"Silencer","AssaultScope","LAMRifle","SCARIncendiaryAmmo","SCARIncendiaryAmmo","SCARIncendiaryAmmo"}},
		},
		Standard	= {"Fists","AlienCloak","OffHand"},
		Default 	= 12,
		Mode 		= 0,
		id 			= 0,
		Name 		= "",
	},
	
	Pos = {
	    {
			{x = 510,y = 1831,z = 365 }, {x = 0,y = 0,z = -0.5},
		},{
			{x = 510,y = 1859,z = 365 }, {x = 0,y = 0,z = 2.7},
		},
    },
	
	State 			= {},
	Flags 			= {{},{},},
	Guns 			= {},
	
	Debug 			= false,

	Server = {

		OnEnterArea = function(self, zone, entity)
			if (self.TriggerId == zone.id and not self:IsDuelPlayer(entity.id) and entity.GetAccess and entity:GetAccess() < 2) then
				nCX.ForbiddenAreaWarning(true, 0, entity.id);
				CryMP.Ent:Revive(entity);
				nCX.ParticleManager("misc.emp.sphere", 0.5, entity:GetWorldPos(), g_Vectors.up, 0);
			end
		end,
	
		OnLeaveArea = function(self, zone, entity)
			if (entity.Info and self.TriggerId == zone.id and self.PlayerInfo[entity.id]) then
				nCX.SetInvulnerability(entity.id, true, 1);
				local coord = self.Pos[nCX.GetTeam(entity.id)];
				local pos = {coord[1].x, coord[1].y, coord[1].z+self.Height};
				CryMP.Ent:MovePlayer(entity, pos, coord[2]);
				nCX.ParticleManager("misc.emp.sphere", 1, pos, g_Vectors.up, entity.Info.Channel);--maybe for both duellers (but not for all!)
			end
		end,
		
		OnKill = function(self, hit, shooter, target)
			if (shooter) then
				local shooterId, targetId = shooter.id, target.id;
				local s, t = self:IsDuelPlayer(shooterId);
				if (s and t) then
					self.State["postround"] = 2;
					if (shooterId ~= targetId and shooter.Info) then
						s.score = s.score + 1;
						local s_score, t_score = s.score, t.score; -- Requester score always first
						if (t.Requester) then 
							s_score, t_score = t.score, s.score;
						end
						nCX.SendTextMessage(3, "[ DUEL:ROUND:#"..self.Round.id.." ] Player [ "..t.name.." ] TERMINATED :: KILLS >> [ "..s_score.." | "..t_score.." ]-BEST-[ "..self.GlobalSettings.BestOf.." ]", 0);
						self.Round.id = self.Round.id + 1;
						local schannelId, tchannelId = shooter.Info.Channel, target.Info and target.Info.Channel;
						if (s.score < self.GlobalSettings.BestOf) then
							CryMP.Msg.Chat:ToPlayer(schannelId, "KILL:BONUS "..self.Round.Bonus[self.Weapon.Mode].." POINTS! - Next Round!", self.Tag);
							nCX.ProcessEMPEffect(targetId, 0.2);
							g_gameRules:AwardPPCount(shooterId, self.Round.Bonus[self.Weapon.Mode]);
						elseif (s.score == self.GlobalSettings.BestOf) then
							self.GameEnd = true;
							CryMP.Ent:PlaySound(shooterId, "win");
							CryMP.Ent:PlaySound(targetId, "lose");
							CryMP.Msg.Chat:ToAll("! DUEL:WIN ! :: Player "..s.name.." WINS! :: Player "..t.name.." lives in shame!", self.Tag);
							self:Log(s.name.." won the duel against "..t.name.."!");
							--CryMP.Msg.Animated:ToPlayer(schannelId, 2, "<b><i><font color=\"#e82727\">*** !!</font> <font color=\"#d53553\">WINNER</font> <font color=\"#e82727\">!! ***</font></i></b></font>");
							--CryMP.Msg.Animated:ToPlayer(tchannelId, 2, "<b><i><font color=\"#e82727\">*** !!</font> <font color=\"#d5b935\">LOSER</font> <font color=\"#e82727\">!! ***</font></i></b></font>");
							g_gameRules:AwardPPCount(shooterId, self.GlobalSettings.WinnerBonus[self.Weapon.Mode]);
							CryMP.Msg.Chat:ToPlayer(schannelId, "WINNER:BONUS "..self.GlobalSettings.WinnerBonus[self.Weapon.Mode].." POINTS! :: TYPE !top10 FOR SCORES!", self.Tag);
							nCX.ProcessEMPEffect(targetId, 0.2);
							return true;
						end
					else
						nCX.SendTextMessage(2, "[ DUEL:iNFO ] Player [ "..s.name.." ] killed themselves! :: NEXT:ROUND:RESTART!", 0);
						self.Round.id = self.Round.id + 1;
						nCX.ProcessEMPEffect(shooterId, 0.2);
					end
				end
			end
		end,

		PreHit = function(self, hit, shooter, target)
			if (target and target.actor) then
				local data = self:IsDuelPlayer(shooter.id);
				if (data) then
					if (self.State["preround"] or shooter:IsDead()) then
						return true;
					elseif (self.Weapon.Mode == 1) then
						hit.damage = hit.damage * 0.4;
					end
					if (not hit.self) then
						nCX.ParticleManager("bullet.hit_incendiary.a", 0.3, hit.pos, hit.dir, data.channelId);
					end
					return false, {hit, target};
				elseif (self.PlayerInfo[target.id]) then
					return true;
				end
			end
		end,

		OnChangeTeam = function(self, player, teamId)
			if (self:IsDuelPlayer(player.id)) then
				nCX.SendTextMessage(2, "Cannot change team in Duel mode", player.Info.Channel);
				return true;
			end
		end,
		
		OnChangeSpectatorMode = function(self, player, mode)
			if (self:IsDuelPlayer(player.id)) then
				nCX.SendTextMessage(2, "Cannot go spectating in Duel mode", player.Info.Channel);
				return true;
			end
		end,
									
		OnDisconnect = function(self, channelId, player, abort)
			if (self:IsDuelPlayer(player.id)) then
				if (abort ~= true) then
					CryMP.Msg.Chat:ToAll("! ABORTED ! :: Player "..player:GetName().." disconnected!", self.Tag);
				end
				self.GameEnd = true;
				self:ShutDown(true);
			end
		end,
		
		OnRadioMessage = function(self, player, msg)
			local p, t = self:IsDuelPlayer(player.id);
			if (p and self.State['preduel'] and self.State['preduel']) then
				if (not p.Requester and msg == 1) then
					self:OnAccept(player.id);
					return true;
				elseif (msg == 2) then
					self:OnDecline(player.id, "DECLINE");
					return true;
				end
			end
		end,
		
		OnGiveItem = function(self, player, item)	
			local data = self:IsDuelPlayer(player.id);
			local attaches = self.Weapon.id and self.Weapon.Available[self.Weapon.id][2];
			if (data and attaches) then
				for i, attach in pairs(attaches) do
					item.weapon:AttachAccessory(attach);
				end	
				self.Guns[item.id] = true;
			end
		end,
		
		OnRequestRevive = function(self, player)
			if (self:IsDuelPlayer(player.id)) then
				return true;
			end
		end,
		
		OnAwardKillPP = function(self, playerId, pp)
			if (self:IsDuelPlayer(playerId)) then
				return true;
			end
		end,
	
	},
		
    OnShutdown = function(self, restart)
		if (not restart) then 
			for i = 1, 2 do
				for flagId, c in pairs(self.Flags[i]) do
					System.RemoveEntity(flagId);
					self.Flags[i][flagId] = nil;
				end
			end
			if (self.TriggerId) then
				System.RemoveEntity(self.TriggerId);
				self.TriggerId = nil;
			end
			self:RemoveGuns();
			self:GravitySphere(false);
			if (self.GameEnd) then
				for playerId, data in pairs(self.PlayerInfo) do
					local player = nCX.GetPlayer(playerId);
					if (player) then
						g_gameRules:EquipPlayer(player);
						CryMP.Ent:Revive(player, true);
					end
				end
			end
		end
	end,

	Process = function(self, player, target, weapon, mode)
		self.PlayerInfo = {
			[player.id] = {
				Requester = true,
				score = 0,
				teamId = nCX.GetTeam(player.id),
				channelId = player.Info.Channel,
				name = player:GetName(),
			},
			[target.id] = {
				score = 0,
				teamId = nCX.GetTeam(target.id),
				channelId = target.Info.Channel,
				name = target:GetName(),
			},
		};
		local channelId = player.Info.Channel;
		if (weapon) then
			local weapon = weapon == 1 and math.random(1, #self.Weapon.Available) or weapon;
			self.Weapon.id = weapon;
			self.Weapon.Name = self.Weapon.Available[weapon][1]:upper();
		else
			self.Weapon.id = self.Weapon.Default;
			self.Weapon.Name = self.Weapon.Available[self.Weapon.id][1];
			nCX.SendTextMessage(0, "Using DEFAULT weapon : "..self.Weapon.Name, channelId);
		end
		CryMP.Ent:PlaySound(target.id, "timer30s");
		self.State['preduel'] = self.GlobalSettings.Timeout;
		CryMP.Msg.Chat:ToPlayer(channelId, "[ #"..((CryMP.DuelCount or 0) + 1).." ] Request sent to "..target:GetName().." : Stand by!", self.Tag);
		if (mode) then
			self.Weapon.Mode = mode;
			local msg = "Mode : ";
			local mode = mode == 1 and "Hardcore" or mode == 2 and "Frag Delivery" or mode == 3 and "Frag Delivery + ZeroG" or "Zero Gravity";
			CryMP.Msg.Chat:ToPlayer(channelId, msg..mode, self.Tag);
		end
		local mode = self.Weapon.Mode == 1 and "HARDCORE-" or self.Weapon.Mode == 2 and "FRAG-" or self.Weapon.Mode == 3 and "ZERO-G:FRAG-" or self.Weapon.Mode == 4 and "ZERO:G-";
		nCX.SendTextMessage(0, "You've been challenged to a "..(mode or "").."DUEL ( weapon:"..self.Weapon.Name.." ) by '"..player:GetName().."' :: Press [ F5 + 1 ] for YES : [ F5 + 2 ] for NO [ "..self.State['preduel'].." ]", target.Info.Channel);
		return true;
	end,
		
	GetStatus = function(self)
		if (self.State['preduel'] and self.State['preduel'] > 0) then
			return "request active - please try again later";
		else
			local r, t = self:IsDuelPlayer();
			return r.name.." and "..t.name.." are in a duel - please try again later";
		end
	end,
	
	OnAccept = function(self, targetId)
		self.State['preduel'] = nil;
		self:SpawnArena();
		if (self.Weapon.Mode == 3 or self.Weapon.Mode == 4) then
			self:GravitySphere(true, self.Weapon.Mode == 4)
		end
		local t, p = self:IsDuelPlayer(targetId);
		local target, player = t.player, p.player;
		nCX.SendTextMessage(0, "", t.channelId);
	    nCX.SendTextMessage(2, "*** DUEL :: "..p.name.." ~ VS ~ "..t.name.." :: BEST OF ( "..self.GlobalSettings.BestOf.." ) WINS :: DUEL ***", 0);
        CryMP.Msg.Chat:ToPlayer(t.channelId, "You have accepted a duel with "..p.name.." - Stand by!", self.Tag);	    
		for playerId, data in pairs(self.PlayerInfo) do
			local player = nCX.GetPlayer(playerId);
			if (player) then
				CryMP:GetPlugin("Refresh", function(self) self:SavePlayer(player); end);
				player.inventory:Destroy();
				self:SpawnParticles(t.channelId);
			end
		end
		self:PortalPlayers();
	end,
	
	OnDecline = function(self, playerId, reason)
		self.State['preduel'] = nil;
		local p, t = self:IsDuelPlayer(playerId);
		if (p.Requester) then
			CryMP.Msg.Chat:ToPlayer(p.channelId, "Duel aborted!", self.Tag);
			nCX.SendTextMessage(0, "! ABORTED ! : Duel aborted by Challenger!", t.channelId);
			self:ShutDown(true);
		else
			CryMP.Msg.Chat:ToPlayer(t.channelId, "Player "..p.name.." declined your duel!", self.Tag);
			nCX.SendTextMessage(0, "! "..reason.." ! : You declined a duel with "..t.name.."!", p.channelId);
			self:ShutDown(true);
		end
	end,
	
    OnTick = function(self)
		if (self.State['preduel']) then
			local mode = self.Weapon.Mode == 1 and "HARDCORE-" or self.Weapon.Mode == 2 and "FRAG-" or self.Weapon.Mode == 3 and "ZERO:GRAV-FRAG:" or self.Weapon.Mode == 4 and "ZERO:ITEM:GRAV-";
			local r, t = self:IsDuelPlayer();
			if (self.State['preduel'] <= 0) then
				self:OnDecline(playerId, "TIMEOUT");
			else
				nCX.SendTextMessage(0, "You've been challenged to a "..(mode or "").."DUEL ( weapon:"..self.Weapon.Name.." ) by '"..r.name.."' :: Press [ F5 + 1 ] for YES : [ F5 + 2 ] for NO [ "..self.State['preduel'].." ]", t.channelId);
				self.State['preduel'] = self.State['preduel'] - 1;
			end
		elseif (self.State["postround"]) then
			if (self.State["postround"] == 0) then
				if (self.GameEnd) then
					return self:ShutDown(true);
				end
				self:PortalPlayers();
				self.State['postround'] = nil;
				return;
			end
			self.State["postround"] = self.State["postround"] - 1;
		else
			for playerId, data in pairs(self.PlayerInfo) do
				local player = nCX.GetPlayer(playerId);
				if (player) then
					if (self.State['preround']) then
						if (self.State['preround'] == 0) then
							nCX.SendTextMessage(5, "<font size=\"32\"><b><i><font color=\"#e82727\">*** !!</font> <font color=\"#c42d2d\">FIGHT</font> <font color=\"#e82727\">!! ***</font></i></b></font>", player.Info.Channel);
							CryMP.Ent:PlaySound(playerId, "repair");
						else
							nCX.SendTextMessage(5, "<font size=\"32\"><b><font color=\"#c5c5c5\">[ <font color=\"#FFFFFF\">00:0"..self.State['preround'].."</font><font color=\"#c5c5c5\"> ] >>> GET [ </font><font color=\"#e14040\">DUEL</font><font color=\"#c5c5c5\"> ] READY!</font></b></font>", player.Info.Channel);
						end
					end
				end
			end
			if (self.State['preround'] == 0) then
				self:Doors('remove');
				self.State['preround'] = nil;
			elseif (self.State['preround']) then
				self.State['preround'] = self.State['preround'] - 1;
			end
		end
	end,
	
    PortalPlayers = function(self)
		self:Doors("spawn");
		self:RemoveGuns();
		self.State['preround'] = self.Round.CountDown;
		for playerId, data in pairs(self.PlayerInfo) do
			local player = nCX.GetPlayer(playerId);
			if (player) then
				local vehicle = player.actor:GetLinkedVehicle();
				if (vehicle) then
					vehicle.vehicle:ExitVehicle(playerId);
				end
				local teamId = data.teamId;
				CryMP.Msg.Chat:ToPlayer(data.channelId, "GET:READY > > > ROUND-[ "..self.Round.id.." ]-STARTING!", self.Tag);
				local v = self.Pos[teamId] or self.Pos[1];
				local pos = {v[1].x, v[1].y, v[1].z+self.Height};
				nCX.RevivePlayer(playerId, pos, v[2], teamId, true);
				nCX.ParticleManager("misc.emp.sphere", 0.5, v[1], g_Vectors.up, 0);
				nCX.SetInvulnerability(playerId, true, 4);
				self:Equip(player);
			end
		end
	end,

    Equip = function(self, player)
		local channelId = player.Info.Channel;
		local mode = self.Weapon.Mode;
		local c4 = self.Weapon.Name == "C4";
		local frag = mode == 2 or mode == 3;
		if (channelId > 0) then
			for i, item in pairs(self.Weapon.Standard) do
				if (not c4 or i ~= 1) and (frag or i ~= 3) then
					nCX.GiveItem(item, channelId, true, true);
				end
			end
			if (mode == 2 or mode == 3) then
				player.inventory:SetAmmoCapacity("explosivegrenade", self.GlobalSettings.Capacity);
				player.actor:SetInventoryAmmo("explosivegrenade", self.GlobalSettings.Capacity, 3);
				--return; --(no weapons-> choose fists!)
			end
			if (c4) then
				player.inventory:SetAmmoCapacity("c4explosive", self.GlobalSettings.Capacity);
				player.actor:SetInventoryAmmo("c4explosive", self.GlobalSettings.Capacity, 3);
			end
			if (self.Weapon.id) then
				CryMP:GiveItem(player, self.Weapon.Available[self.Weapon.id][1]);
				if (self.Weapon.id == 10 or self.Weapon.id == 11) then
					CryMP:GiveItem(player, self.Weapon.Name); 
				end
			end
		end
	end,

	IsDuelPlayer = function(self, playerId)
		if (playerId) then
			local info = self.PlayerInfo[playerId];
			if (info) then
				for userId, data in pairs(self.PlayerInfo) do
					if (userId ~= playerId) then
						return info, data;
					end
				end
			end
		else
			local r, t;
			for userId, data in pairs(self.PlayerInfo) do
				if (data.Requester) then
					r = data;
				else
					t = data;
				end
			end
			return r, t;
		end
	end,
		
    SpawnArena = function(self)
	    local coordinates = {
			{
				{{ x=0, y=0, z=0 }, { x=510, y=1844, z=365 }, { x=40, y=50, z=20 }},--nigga
			},{
				{{ x=0, y=1, z=0 }, { x=507, y=1852, z=365 }, 4},
				{{ x=0, y=-1, z=0 }, { x=512.99, y=1851.96, z=365 }, 4},
				{{ x=0, y=1, z=0 }, { x=507.01, y=1840.02, z=365 }, 4},
				{{ x=0, y=-1, z=0 }, { x=513, y=1840, z=365 }, 4},
				{{ x=0, y=1, z=0 }, { x=513, y=1847, z=365 }, 1},
				{{ x=0, y=-1, z=0 }, { x=507, y=1844, z=365 }, 1},
				{{ x=1, y=0, z=0 }, { x=513, y=1852, z=365 }, 2},
				{{ x=-1, y=0, z=0 }, { x=513, y=1847, z=365 }, 2},
				{{ x=-1, y=0, z=0 }, { x=507, y=1847, z=365 }, 2},
				{{ x=1, y=0, z=0 }, { x=507, y=1852, z=365 }, 2},
				{{ x=-1, y=0, z=0 }, { x=507, y=1840, z=365 }, 2},
				{{ x=1, y=0, z=0 }, { x=507, y=1844, z=365 }, 2},
				{{ x=-1, y=0, z=0 }, { x=513, y=1840, z=365 }, 2},
				{{ x=1, y=0, z=0 }, { x=513, y=1844, z=365 }, 2},
				{{ x=-0.71934, y=-0.694658, z=0 }, { x=507, y=1847, z=365 }, 1},
				{{ x=0.694658, y=0.71934, z=0 }, { x=513, y=1844, z=365 }, 1},
				{{ x=1, y=0, z=0 }, { x=510, y=1854.35, z=365 },4},
				{{ x=-1, y=0, z=0 }, { x=510, y=1837.65, z=365 },4},
			},{
				{{ x=1, y=0, z=0 }, { x=513.4, y=1863, z=366.5 }, 1, 2.5},
				{{ x=0, y=-1, z=0 }, { x=513.4, y=1863, z=366.5 }, 1, 2.5},
				{{ x=1, y=0, z=0 }, { x=506.65, y=1863, z=366.5 }, 1, 2.5},
			},{
				{{ x=-1, y=0, z=0 }, { x=513.4, y=1828, z=366.5 }, 1, 2.5},
				{{ x=0, y=-1, z=0 }, { x=513.4, y=1828, z=366.5 }, 1, 2.5},
				{{ x=-1, y=0, z=0 }, { x=506.65, y=1828, z=366.5 }, 1, 2.5},
			},{
				{{ x=0, y=1, z=0 }, { x=498, y=1833.7, z=368 }, 0, 3.5},
				{{ x=0, y=-1, z=0 }, { x=522, y=1833.7, z=368 }, 0, 3.5},
				{{ x=0, y=1, z=0 }, { x=498, y=1857.3, z=368 }, 0, 3.5},
				{{ x=0, y=-1, z=0 }, { x=522, y=1857.3, z=368 }, 0, 3.5},
				{{ x=1, y=0, z=0 }, { x=500, y=1859, z=368 }, 0, 5},
				{{ x=1, y=0, z=0 }, { x=500, y=1846, z=368 }, 0, 5},
				{{ x=1, y=0, z=0 }, { x=520, y=1846, z=368 }, 0, 5},
				{{ x=1, y=0, z=0 }, { x=520, y=1859, z=368 }, 0, 5},
			},{
				{{ x=-1, y=0, z=180 }, { x=517, y=1827, z=359.842 }, 0, 13.5},--boden
				{{ x=-1, y=0, z=180 }, { x=517, y=1827, z=373 }, 0, 13.5},--dach
			},
		};
		
		if (self.Weapon.Mode < 3) then
			coordinates[6][2] = nil;
		end
		if (self.Height == 0) then
			coordinates[6][1] = nil;
		end
			
		for j = 1, #coordinates do
			for i, data in pairs(coordinates[j]) do
				if (j == 1) then
					local pos = {data[2].x,data[2].y,data[2].z+self.Height};
					local params = {
						name = "Duel_Trigger",
						pos = pos,
						dir = data[1],
						dim = data[3],
					};
					local trigger = CryMP.Ent:SpawnTrigger(params, nil, self.Debug);
					if (trigger) then
						trigger.CanEnter = function(trigger, entity)
							return entity.Info and nCX.IsPlayerActivelyPlaying(entity.id);
						end
						self.TriggerId = trigger.id;
					end
				else
					local c = ((j==2 and 1.3) or ((j == 3 or j == 4) and 1.65) or 1);
					for p = 0, data[3] do
						local pos = {data[2].x,data[2].y,data[2].z+(p*c)+self.Height};
						local flag = self:Spawn("Wall", "Flag", pos, data[1]);
						if (data[4]) then
							flag:SetScale(data[4]);
						end
					end
				end
			end
		end
	end,

    SpawnParticles = function(self, channelId)
		local info = {
			{"misc.static_lights.red_flickering",{x=513.4,y=1828,z=393.6},},
			{"misc.static_lights.red_flickering",{x=506.7,y=1828,z=393.6},},
			{"misc.static_lights.green_flickering",{x=506.6,y=1863,z=393.6},},
			{"misc.static_lights.green_flickering",{x=513.3,y=1863,z=393.6},},
			{"smoke_and_fire.lantern.small_fire",{x=501.7,y=1856,z=363.842},},
			{"smoke_and_fire.lantern.small_fire",{x=518.2,y=1856.1,z=363.876},},
			{"smoke_and_fire.lantern.small_fire",{x=518.2,y=1835,z=363.835},},
			{"smoke_and_fire.lantern.small_fire",{x=501.8,y=1835,z=363.835},},
			{"misc.electric_man.kyong_constant",{x=513,y=1847,z=378.07},},
			{"misc.electric_man.kyong_constant",{x=513,y=1844,z=378.05},},
			{"misc.electric_man.kyong_constant",{x=507,y=1847,z=378.056},},
			{"misc.electric_man.kyong_constant",{x=507,y=1844,z=378.053},},
			{"misc.extremly_important_fx.lights_red",{x=510,y=1844,z=363.842},},
			--[[{"smoke_and_fire.pipe_steam_a.fleet_white_pulsed",{ x=510.101, y=1852.92, z=371.97 },}
			{"smoke_and_fire.pipe_steam_a.fleet_white_pulsed",{ x=509.906, y=1840.05, z=371.97 },}
			{"smoke_and_fire.VS2_Fire.small_flame_wall",{ x=507.158, y=1846.49, z=363.84 },}
			{"smoke_and_fire.VS2_Fire.small_flame_wall",{ x=512.815, y=1846.06, z=363.84 },}
			{"misc.fog.harbor_building_smoke_inside",{ x=509.916, y=1845.64, z=363.838 },}
			{"misc.sparks.heavy_dropping_collide",{ x=512.515, y=1840.03, z=381.933 },}
			{"misc.sparks.heavy_dropping_collide",{ x=507.471, y=1852.93, z=381.996 },}
			{"misc.sparks.heavy_dropping_collide",{ x=512.698, y=1852.88, z=381.982 },}
			{"misc.sparks.heavy_dropping_collide",{ x=507.296, y=1840.09, z=381.933 },}]]
		};
		for i, params in pairs(info) do
			if (i == #info and self.Height ~= 0) then
				return;
			end
			local pos = {params[2].x, params[2].y, params[2].z + self.Height};
			self:ParticleManager(params[1], 1, pos, g_Vectors.up, channelId);
		end
	end,
	
	Spawn = function(self, name, class, pos, dir, itemOnly)
		local prop = {
			class = class,
			name = class.."_Duel_"..name..tostring(CryMP.Library:SpawnCounter()),
			orientation = dir,
			position = pos,
			properties = {
				bPlayers = true,
			},	
		};
		if (class == "Gravity" and itemOnly) then
			prop.properties.bPlayers = false;
		end
		local entity = System.SpawnEntity(prop);
		if (class == "Flag") then
			local type = name == "Door" and 1 or 2;
			self.Flags[type][entity.id] = true;
			if (self.GlobalSettings.WallOnHit) then
				entity.OnHit = function(entity, hit)
					nCX.ParticleManager("bullet.hit_incendiary.a", 0.6, hit.pos, hit.dir, 0);
				end
			end
		end
		return entity;
	end,

	GravitySphere = function(self, add, itemOnly)
		if (add) then
			local pos, dir = { x=510, y=1844, z=365 }, { x=1, y=0, z=0, };
			local sphere = self:Spawn("Zone", "GravitySphere", pos, dir, itemOnly);
			if (sphere) then
				self.GravitySphereId = sphere.id;
				sphere:SetRadius(20);
				return true;
			end
		elseif (self.GravitySphereId) then
			System.RemoveEntity(self.GravitySphereId);
			self.GravitySphereId = nil;
			return true;
		end
	end,
	
    Doors = function(self, mode)
		local tbl = {
			{
				--{dir = { x=0, y=1, z=0 }, pos = { x=510, y=1834.5, z=365 }},
				--{dir = { x=0, y=-1, z=0 }, pos = { x=510, y=1834.5, z=365 }},
				{{ x=0, y=-1, z=0 }, { x=513.4, y=1833, z=366.5 }, 1, 2.5},
			},{
				--{dir = { x=0, y=-1, z=0 }, pos = { x=510, y=1856.51, z=365 }},
				--{dir = { x=0, y=1, z=0 }, pos = { x=510, y=1856.51, z=365 }},
				{{ x=0, y=-1, z=0 }, { x=513.4, y=1857, z=366.5 }, 1, 2.5}
			}			
		};
		local count = nCX.Count(self.Flags[1]);
		if (mode == "spawn") then
			if (count > 0) then
				return;
			end
			for i = 1, 2 do
				for i, data in pairs(tbl[i]) do
					for i = 0, 1 do
						local pos = {data[2].x,data[2].y,data[2].z+(i*1.65)+self.Height};
						local flag = self:Spawn("Door", "Flag", pos, data[1]);
						flag:SetScale(data[4]);
					end
				end
			end
		elseif (mode == "remove") then
			for flagId, c in pairs(self.Flags[1]) do
				System.RemoveEntity(flagId);
				self.Flags[1][flagId] = nil;
			end
			for playerId, data in pairs(self.PlayerInfo) do
				for i, t in pairs(tbl[data.teamId] or {}) do
					nCX.ParticleManager("explosions.gauss.bullet_backup", 0.3, t[2], t[1], data.channelId);
				end
			end
			return count;
		end
	end,
	
	RemoveGuns = function(self)
		for gunId, v in pairs(self.Guns) do
			local ent = System.GetEntity(gunId);
			if (ent) then
				System.RemoveEntity(gunId);
				nCX.AbortEntityRemoval(gunId);
			end
		end
		self.Guns = {};
	end,
	
};
