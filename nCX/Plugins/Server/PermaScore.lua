PermaScore = {

	---------------------------
	--		Config
	---------------------------
	Tick		= 1,
	Tag			= 1,
	
	StartXP 	= 100,
	Jump 		= 0.1,
	Count 		= 0,
	MinLevel 	= 3,
	Premium 	= 20 * 60, -- minutes
	Hours 		= 20,
	Delay		= 2, -- kill info 

	Levels		= {},
	PlayTime	= {},
	Buffer 		= {},
	
	Awards = {
		{min =  0, kill = 3, assist = 1, death =  0, head = 2, melee = 1, suicide =  0, frag = 1, duel = 10,},
		{min = 20, kill = 5, assist = 2, death = -1, head = 3, melee = 2, suicide = -2, frag = 4, duel = 10,},
		{min = 40, kill = 7, assist = 2, death = -2, head = 5, melee = 3, suicide = -4, frag = 5, duel = 10,},
		{min = 80, kill = 9, assist = 3, death = -3, head = 6, melee = 4, suicide = -6, frag = 6, duel = 10,},
	},
		
	Server = {
		
		OnConnect = function(self, channelId, player, profileId, reset)
			if (not reset) then
				local data = self:GetData(profileId);
				if (tostring(profileId) == "-1") then
					return;
				end
				local access = player:GetAccess();
				if (access < 3 and player:IsNomad() and not data.Name:find("7Ox.")) then
					CryMP.Ent:Rename(player, data.Name); --server descision
				end
				local lastSeen = data.LastSeen;
				if (lastSeen and lastSeen ~= 0) then
					local ago = CryMP.Math:DaysAgo(lastSeen, true);
					CryMP.Msg.Chat:ToPlayer(channelId, "Your last visit: "..ago, self.Tag);
				end
				--[[
				if (access==0) then
					local playTime = self:GetPlayTime(profileId);		   
					if (playTime < self.Premium) then
						local hours, mins = CryMP.Math:ConvertTime((self.Premium - playTime), 60);
						CryMP:SetTimer(8, function()
							CryMP.Msg.Chat:ToPlayer(channelId, "Premium Membership in "..math:zero(hours).." hours : "..math:zero(mins).." mins", self.Tag);
						end);
					end
				end
				]]
			end
		end,

		OnDisconnect = function(self, channelId, player, profileId, cause)
			self:UpdatePlayTime(profileId);
			self.Buffer[player.id] = nil;
			self.PlayTime[profileId] = nil;
		end,
				
		OnKill = function(self, hit, shooter, target)
			if (not shooter or not shooter.Info or hit.server or (g_gameRules.class == "PowerStruggle" and nCX.IsSameTeam(shooter.id, target.id) and not hit.self)) then
				return;
			end
			local k = true;
			local s, hs, m, dw, f;
			local weapon, hitType = hit.weapon, hit.type;
			if (hit.self) then
				k, s = false, true;
			else
				if (hit.typeId == 9) then
					m = true;
				elseif (hit.typeId == 11) then
					f = true;
				end
				local PS = g_gameRules.class == "PowerStruggle";
				if (PS and shooter.IsDuelPlayer and shooter:IsDuelPlayer()) then
					dw = true;
				end
				--[[
				if (PS) then
					for shooterId, time in pairs(target.hitAssist or {}) do
						if (_time - time < 5 and shooterId ~= shooter.id) then
							local assister = nCX.GetPlayer(shooterId);
							if (assister and not target:IsOnVehicle()) then
								local killer = self:GetData(assister.Info.ID);
								local award = self:GetAwardTable(killer.Level);
								local buffer = self:GetBuffer(assister.id, true);
								if (buffer) then
									buffer.tbl = buffer.tbl or {};
									buffer.xp = (buffer.xp or 0) + award["assist"];
									self:AwardXP(assister, award["assist"]);
									if (not PS) then
										killer.Duelwins = killer.Duelwins + 1; -- in TIA, duelwins slot used for assists
									end
									buffer.tbl["assist"] = (buffer.tbl["assist"] or 0) + 1;
								end
							end
						end
					end
				end]]
			end
			self:Calculate(shooter, target, k, hit.headshot, m, s, dw, f, hit.accuracy);
			self.KILL_COUNTER = (self.KILL_COUNTER or 0) + 1;
			if (hit.self and shooter.SPIN_COUNT and shooter.SPIN_COUNT > 0) then
				--CryMP.Msg.Chat:ToPlayer(shooter.Info.Channel, "[ SPIN ]- Fruit Machine counter RESET!");
				shooter.SPIN_COUNT = 0;
			end
			--if (g_gameRules.class == "InstantAction") then
			--	if (hit.accuracy and hit.accuracy > 0) then
			--		nCX.SendTextMessage(4, shooter:GetName().." KILL:ACCURACY "..hit.accuracy.."% ("..shooter.actor:GetHealth()..") HP:REMAINING", target.Info.Channel);
			--	else
			--		nCX.SendTextMessage(4, shooter:GetName().." KILLED YOU ("..shooter.actor:GetHealth()..") HP:REMAINING", target.Info.Channel);
			--	end
			--end
		end,
		
		--[[
		OnProcessVehicleScores = function(self, shooter, vehicle, assist)	
			local PS = g_gameRules.class == "PowerStruggle";
			local ownerId = vehicle.vehicle:GetOwnerId();
			local owner = ownerId and nCX.GetPlayer(ownerId);
			if (owner and nCX.IsSameTeam(ownerId, vehicle.id)) then
				local killer = self:GetData(shooter.Info.ID);
				if (killer) then
					local buffer = self:GetBuffer(shooter.id, true);
					if (not buffer) then
						return;
					end
					buffer.tbl = buffer.tbl or {};
					if (assist) then
						buffer.tbl = buffer.tbl or {};
						local award = self:GetAwardTable(killer.Level);
						buffer.xp = (buffer.xp or 0) + award["assist"];
						self:AwardXP(killer, award["assist"]);
						if (not PS) then
							killer.Duelwins = killer.Duelwins + 1; -- in TIA, duelwins slot used for assists
						end
						buffer.tbl["assist"] = (buffer.tbl["assist"] or 0) + 1;
					else
						buffer.tbl["vehicle"] = (buffer.tbl["vehicle"] or 0) + 1;
						buffer.xp = (buffer.xp or 0) + 15;
						self:AwardXP(shooter, 15);
						killer.Vehicles = killer.Vehicles + 1;
					end
				end
				if (PS) then
					self:AwardXP(owner, -2);
					nCX.SendTextMessage(3, shooter:GetName().." destroyed your "..CryMP.Ent:GetVehicleName(vehicle.class).."! -2 xp", owner.Info.Channel);
				end
			end
		end,]]
		
		---------------------------
		--		OnNameChange		
		---------------------------	
		OnNameChange = function(self, player, name, reason)
			if (reason == "user descision") then
				local profileId = player.Info.ID;
				local access = player:GetAccess();
				if (access < 3 and self.Players[profileId]) then
					self.Players[profileId].Name = name;
				end
			end
		end,
	
	},
	
	OnInit = function(self, Config)
		self.Players = {};
		require("Data_PermaScore", "data file");
		local count = nCX.Count(self.Players);
		nCX.Log("Core", "Loaded "..count.." player stats.");
		self:Log("Loaded $3"..count.."$9 player stats");
		self:Setup();
	end,

	OnShutdown = function(self, reload)
		if (reload) then 
			local users = CryMP.Users and CryMP.Users:GetUsers(0, false, true)
			if (users) then
				for channelId, profileId in pairs(users) do
					self:UpdatePlayTime(profileId);
				end
			end
		end
		local FileHnd = io.open(CryMP.Paths.ServerData.."Data_PermaScore.lua", "w+");
		if (FileHnd) then
			local data = self:GetSortedData();
			for i, data in pairs(data) do
				local ago = CryMP.Math:DaysAgo(data.LastSeen);
				--if (data.Level >= self.MinLevel and (ago < 60 or data.Level >= 50 or CryMP.Users:HasAccess(data.Profile, 1))) then
					--local name = data.Name:gsub("%'", "");
					local line =  "CryMP.PermaScore:Add('"..data.Name.."', '"..data.Profile.."', "..data.Kills..", "..data.Deaths..", "..data.Headshots..", "..data.Melee..", "..data.Suicides..", "..data.Duelwins..", "..data.XP..", "..data.Level..", '"..tostring(data.LastSeen).."', "..data.PlayTime..", "..data.Vehicles..", "..data.Frags;
					line = line..");\n"
					FileHnd:write(line);
				--end
			end
			FileHnd:close();
		else
			System.LogAlways("[PermaScore] Error: No Data file found!");
		end
	end,
	
	OnTick = function(self, players)
		for i, player in pairs(players) do
			if (nCX.IsPlayerActivelyPlaying(player.id) and not player:IsAfk() and player.Info.ID ~= "-1") then
				local profileId = player.Info.ID;
				self.PlayTime[profileId] = (self.PlayTime[profileId] or 0) + 1;
				local name = player:GetName();
				local h = (self.PlayTime[profileId] / 60) / 60;
				local access = player:GetAccess();
				if (h==math.floor(h) and h > 0) then
					--[[
					local award = (1000 * h);
					local name = player:GetName();
					local vehicle = player.actor:GetLinkedVehicle();
					if (g_gameRules.AwardPPCount) then
						g_gameRules:AwardPPCount(player.id, award);
						CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "Ammo Boost : "..award.." PP Award for you!", self.Tag);
						CryMP.Msg.Chat:ToOther(player.Info.Channel, name.." has played "..math:zero(h)..":00 h : "..award.." PP awarded!", self.Tag);
						self:Log(name.." has played "..math:zero(h)..":00 h - "..award.." PP awarded");
					end]]
					if (vehicle) then
						vehicle:BoostAmmo();
						-- Repair Vehicle
						vehicle.vehicle:OnHit(vehicle.id, player.id, 1000, vehicle:GetWorldPos(), 0, "repair", false);					
					end
					--if (not g_gameRules.AwardPPCount) then
						--[[
						if (vehicle) then
							local mod = (vehicle.Properties.Modification == "" or vehicle.Properties.Modification == "MP" or vehicle.Properties.Modification == "LowBudget") and "" or vehicle.Properties.Modification.."-";
							local vehicleName = mod..CryMP.Ent:GetVehicleName(vehicle.class);
							CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "You have played "..math:zero(h)..":00 h : Ammo Boost for your "..vehicleName.."!", self.Tag);
							CryMP.Msg.Chat:ToOther(player.Info.Channel, name.." has played "..math:zero(h)..":00 h : Ammo Boost for his "..vehicleName, self.Tag);
						else
							CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "You have played "..math:zero(h)..":00 h : Ammo Boost for your Equipment!", self.Tag);
							CryMP.Msg.Chat:ToOther(player.Info.Channel, name.." has played "..math:zero(h)..":00 h : Ammo Boost awarded", self.Tag);
						end]]
						self:Log(name.." has played "..math:zero(h)..":00 h");						
					--end
				elseif ((h * 60) == 60 and access < 3) then
					--CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "PlayTime ( 60 min ) : Auto TeamBalance immunity > > > ENABLED", self.Tag);
					self:Log("You are now immune to TeamBalance!", player.Info.Channel, true);
				end
				
				local pTime = self:GetPlayTime(profileId);
				if (access==0 and (pTime > self.Premium) and not player:IsNomad()) then
					CryMP.Users:UpdateUser(profileId, 1, name, 1);
					if (pTime - self.Premium < 10) then
						self:PremiumAcquired(player);
						CryMP.Ent:PlaySound(player.id, "win");
					end
				end
			end
		end
		--[[
		for shooterId, buffer in pairs(self.Buffer) do
			if (buffer.tick <= 0) then
				local ok = self:DisplayKillInfo(nCX.GetPlayer(shooterId), buffer);
				if (ok) then
					self.Buffer[shooterId]=nil;
				end
			else
				buffer.tick = buffer.tick - 1;
			end
		end]]
		-- Write
		self.WRITE_TIMER = (self.WRITE_TIMER or 0) + 1;
		if (self.WRITE_TIMER > 500 and self.KILL_COUNTER and self.KILL_COUNTER > 0) then
			self:OnShutdown();
			self.WRITE_TIMER = 0;
		end
	end,
	
	Add = function(self, name, profileId, kills, deaths, headshots, melee, suicides, duelwins, xp, level, lastseen, playtime, vkills, frags)
		--if (level >= self.MinLevel) then
			self.Players[profileId] = self.Players[profileId] or {
				Name        =  name,
				Profile     =  profileId,
				Kills       =  kills,
				Deaths      =  deaths,
				Headshots   =  headshots,
				Melee		=  melee,
				Suicides    =  suicides,
				Duelwins	=  duelwins,
				XP		    =  xp,
				Level       =  level,
				LastSeen	=  lastseen,
				PlayTime	=  playtime,
				Vehicles	=  vkills,
				Frags 		=  frags,
			};
		--end
	end,	

	GetData = function(self, profileId)
		if (profileId == "-1") then	
			return;
		end
		return self.Players[profileId] or self:Register(profileId);
	end,
	
	GetBuffer = function(self, shooterId, create)
		if (create) then
			self.Buffer[shooterId] = self.Buffer[shooterId] or { tick = self.Delay, count = 0, accuracy = 0,};
		end
		return self.Buffer[shooterId];
	end,

	GetSortedData = function(self)
		local tbl = {};
		for profileId, v in pairs(self.Players) do
			tbl[#tbl + 1] = v;
		end
		local function sort_exp(t1, t2)
			return t1.XP > t2.XP;
		end
		table.sort(tbl, sort_exp);
		return tbl;
	end,
	
	GetPlayTime = function(self, profileId, round)
		local minutes, seconds = CryMP.Math:ConvertTime((self.PlayTime[profileId] or 1), 60);
		if (not round) then
			minutes = minutes + self:GetData(profileId).PlayTime; -- total
		end
		return minutes, seconds;
	end,

	UpdatePlayTime = function(self, profileId)
		local data = self:GetData(profileId);
		--System.LogAlways("UpdatePlayTime : "..data.PlayTime.." + "..self:GetPlayTime(profileId, true));
		data.PlayTime = data.PlayTime + self:GetPlayTime(profileId, true);
		data.LastSeen = tostring(os.date("%Y"))..tostring(os.date("%m"))..tostring(os.date("%d"));
	end,

	GetRank = function(self, profileId)
		if (not self.Players[profileId or ""]) then
			return 0;
		end
		local tbl = self:GetSortedData();
		for i, v in pairs(tbl) do
			if (v.Profile == profileId) then
				return i;
			end
		end
	end,
			
	GetAwardTable = function(self, level)   
		for i = #self.Awards, 1, -1 do
			if (level >= tonumber(self.Awards[i].min)) then
				return self.Awards[i];
			end
		end
	end,
	
	Calculate = function(self, shooter, target, k, hs, m, s, dw, f, accuracy)
		if (shooter.Info and shooter.Info.ID ~= "-1") then
			local amount = 0;
			local killer = self:GetData(shooter.Info.ID);
			local award = self:GetAwardTable(killer.Level);
			local tbl, xp = {}, 0;
			local buffer = self:GetBuffer(shooter.id);
			if (buffer) then
				tbl = buffer.tbl or {};
			end
			if (k) then
				amount = amount + award["kill"];
				killer.Kills = killer.Kills + 1;
				if (hs) then
					amount = amount + award["head"];
					killer.Headshots = killer.Headshots + 1;
					tbl["head"] = (tbl["head"] or 0) + 1;
				end
				if (m) then
					amount = amount + award["melee"];
					killer.Melee = killer.Melee + 1;
					tbl["melee"] = (tbl["melee"] or 0) + 1;
				end
				if (dw) then
					amount = amount + award["duel"];
					killer.Duelwins = killer.Duelwins + 1;
					tbl["duel"] = 1;
				end
				if (f) then
					amount = amount + award["frag"];
					killer.Frags = killer.Frags + 1;
					tbl["frag"] = (tbl["frag"] or 0) + 1;
				end
			end
			if (amount > 0) then
				self:AwardXP(shooter, amount);
				buffer = buffer or self:GetBuffer(shooter.id, true);
				buffer.xp = (buffer.xp or 0) + amount;
				buffer.count = (buffer.count or 0) + 1;
				if (accuracy) then
					buffer.accuracy = math.floor(accuracy);
				end
				for i, e in pairs(tbl) do
					buffer.tbl = tbl;
					break;
				end
			end
		end
		if (target.Info) then
			local amount = 0;
			local victim = self:GetData(target.Info.ID);
			local award = self:GetAwardTable(victim.Level);
			if (s) then
				amount = amount + award["suicide"];
				victim.Suicides = victim.Suicides + 1;
			else
				amount = amount + award["death"];
				victim.Deaths = victim.Deaths + 1;
			end
			if (amount ~= 0) then
				self:AwardXP(target, amount);
			end
		end
	end,

	AwardXP = function(self, player, amount)
		if (player and player.Info) then
			if (amount ~= 0) then
				local data = self:GetData(player.Info.ID);
				local XP = data.XP;
				data.XP = math.min(self.Levels[#self.Levels], math.max(200, data.XP + amount));
				amount = data.XP - XP;
				--System.LogAlways(data.XP.." - "..XP.." = "..amount);
				if (amount ~= 0) then
					self:LevelCheck(player, (amount > 0));
				end
			end
		end
	end,

	Setup = function(self)
		self.Levels = {};
		self.Levels[1] = self.StartXP;
		--System.LogAlways("Level 1 : "..self.StartXP.." XP.");
		for i=1, 99 do
			--System.LogAlways("Level "..i.." : "..(self.Levels[i] + math.floor(self.Levels[i] * self.Jump)).." XP.");
			self.Levels[i+1] = self.Levels[i] + math.floor(self.Levels[i] * self.Jump);
		end
	end,

	Register = function(self, profileId, force)
		local data = self.Players[profileId];
		if (data and not force) then
			return data;
		end
		self.Players[profileId] = {
			Name        =  "N/A",
			Profile     =  profileId,
			Kills       =  0,
			Deaths      =  0,
			Headshots   =  0,
			Melee		=  0,
			Suicides    =  0,
			Duelwins 	=  0,
			XP		    =  self.StartXP,
			Level       =  1,
			LastSeen	=  0,
			PlayTime	=  0,
			Vehicles	=  0,
			Frags 		=  0,
		};
		local player = CryMP.Users:GetPlayerByProfileId(profileId);
		if (player) then
			local name = CryMP.Ent:CheckName(player:GetName());
			self.Players[profileId].Name = name;
			nCX.Log("Player", "Player "..name.." has been added to the permascore database");
			--nCX.SendTextMessage(3, "[ PERMA:SCORE ] Registration complete. Your stats are now being tracked!", player.Info.Channel);
		end
		return self.Players[profileId];
	end,

	LevelCheck = function(self, player, add)
		local channelId = player.Info.Channel;
		local i = self:GetData(player.Info.ID);
		local xp = i.XP;
		local level = i.Level;
		local name = player:GetName();
		if (add) then
			local checkLevel = i.Level + 1;
			while (self.Levels[checkLevel] and xp >= self.Levels[checkLevel]) do
				--System.LogAlways(xp.." >= "..self.Levels[checkLevel].." (lvl "..checkLevel..")")
				checkLevel = checkLevel + 1;
			end
			i.Level = math.min(#self.Levels - 1, checkLevel - 1);
			if (i.Level > level) then
				nCX.Log("Player", "Player "..name.." advanced to rank "..i.Level);
				local award = CryMP.Equip and CryMP.Equip.OnLevelAdvanced and CryMP.Equip:OnLevelAdvanced(player, i.Level);
				if (i.Level >= 20 or award) then
					--CryMP.Msg.Chat:ToAll(name.." advanced to 7Ox-LEVEL [ "..i.Level.." ]"..(award and " :: Unlocked !EQUIP : "..award or ""), self.Tag);
					self:Log(name.." advanced to 7Ox-Level "..i.Level);
				end
			end
		else
			if (i.Level > 1) then
				local checkLevel = i.Level - 1;
				while (self.Levels[checkLevel] and xp < self.Levels[checkLevel]) do
					--System.LogAlways(xp.." < "..self.Levels[checkLevel].." (lvl "..checkLevel..")")
					checkLevel = checkLevel - 1;
				end
				i.Level = checkLevel + 1;
				if (i.Level < level) then
					i.Level = i.Level - 1;
					if (i.Level >= 10) then
						--nCX.SendTextMessage(3, ">> 7Ox:STATS  [ K : "..i.Kills.." ] - [ D : "..i.Deaths.." ] - [ HS : "..i.Headshots.." ] - [ XP : "..i.XP.." ] - [ LVL : "..i.Level.." ]  7Ox:STATS <<", channelId);
					end
					nCX.Log("Player", "Player "..name.." dropped to rank "..i.Level);
					if (i.Level >= 20) then
						--CryMP.Msg.Chat:ToAll(name.." dropped to 7Ox-LEVEL [ "..i.Level.." ]", self.Tag);
						self:Log(name.." dropped to 7Ox-Level "..i.Level);
					end
				end
			end
		end
	end,
	
	GetLevelProgress = function(self, profileId)
		local i = self:GetData(profileId);
		local level = i.Level;
		local xp = i.XP;
		local curr = self.Levels[level] or self.StartXP;
		local next = self.Levels[level + 1];
		local progress = (xp - curr);
		local target = (next - curr);
		local result = (progress/target) * 100;
		--System.LogAlways("lvl "..level.." xp "..xp.." curr "..curr.." next "..next.." progress "..progress.." target "..target.." result "..result)
		if (result >= 1) then
			result=math.floor(result);
		else
			result=tostring(result):sub(1, 3);
		end
		return math.max(0, math.min(result, 100)), level;
	end,

	GetLevel = function(self, profileId)
		return self:GetData(profileId).Level;
	end,

	GetName = function(self, profileId)
		return self:GetData(profileId).Name;
	end,

	PremiumAcquired = function(self, player)
		local channelId = player.Info.Channel;
		CryMP.Msg.Chat:ToAll(player:GetName().." has aquired Premium Membership for playing "..self.Hours.." hours on 7OXICiTY!", self.Tag);
		nCX.ParticleManager("misc.extremly_important_fx.celebrate", 3.75, player:GetPos(), g_Vectors.up, 0);
		CryMP.Users:AddTag(player, 1);
	end,

	DisplayKillInfo = function(self, shooter, buffer)
		if (not shooter or shooter.Info.ID == "-1") then
			return false;
		elseif (not shooter:IsDead()) then
			local channelId = shooter.Info.Channel;
			local progress, level = self:GetLevelProgress(shooter.Info.ID);
			local cnames = { [2] = {"DOUBLE:KILL","#ADFF2F"}; [3] = {"TRIPLE:KILL","#ADFF2F"}; [4] = {"QUAD:KILL","#FFA07A"}; };
			local count, xp = buffer.count, buffer.xp;
			if (count > 1) then
				cnames = cnames[count] or {"MULTI:KILL","#F8F8FF"};
				if (buffer.tbl and buffer.tbl["vehicle"]) then
					cnames = {"BINGO","#FF9900"};
				end
			else
				cnames = {""};
			end
			if (xp) then
				local accuracy = buffer.accuracy;
				if (buffer.tbl) then
					local str = "";
					for msg, count in pairs(buffer.tbl) do
						local multi;
						if (count > 1) then
							multi = count.."x "..msg:upper();
						end
						str = str..(multi or msg:upper()).." : ";
					end
					local msg = str:sub(1, -4);
				
					if (accuracy > 0) then
						if (accuracy == 100) then
							accuracy = "Perfect";
						else
							accuracy = accuracy.."%";
						end
						nCX.SendTextMessage(3, cnames[1].." +"..xp.." xp  ( "..msg.." ) - "..accuracy.." Accuracy", channelId);
					else
						nCX.SendTextMessage(3, cnames[1].." +"..xp.." xp  ( "..msg.." ) - "..progress.."% of Level "..level, channelId);
					end
				else
					if (accuracy > 0) then
						if (accuracy == 100) then
							accuracy = "Perfect";
						else
							accuracy = accuracy.."%";
						end
						nCX.SendTextMessage(3, cnames[1].." +"..xp.." xp  "..accuracy.." Accuracy", channelId);
					else
						nCX.SendTextMessage(3, cnames[1].." +"..xp.." xp  "..progress.."% of Level "..level, channelId);
					end
				end
			end
			self.Buffer[shooter.id] = nil;
			return true;
        end
	end,
	
	GetInfo = function(self, player, profileId)
		local players = self:GetSortedData();
		local infoline = function(id, done)
			local data = players[id] or self.Players[profileId];
			if (data) then
				local id = data.Profile;
				local playh, playm = CryMP.Math:ConvertTime(data.PlayTime, 60);
				local playm = playm < 10 and "0"..playm or playm;
				local c1 = done and "$3" or "$1";
				local rank = self:GetRank(id);
				local r = string:lspace(4, math:zero(rank));
				local info = done and rank > 10 and string.format("  $3YOUR$9:$3RANK$9 -> $1#$3%s$5", string:rspace(9,r)) or string.format("#%s  $5%s$5 ", c1..r, string:rspace(17, data.Name));
				return string.format("$9[%s|$4%s $5|$4%s $5|$4%s $5|$4%s $5|%s $5|$7%s $5|$4%s $5|$4%s $5|$4%s $5|$4%s $5|$4%s$9h:$4%s$9m$9 ]",
					info,string:lspace(6,data.Kills),string:lspace(6,data.Deaths),
					string:lspace(5,data.Headshots),string:lspace(5,data.Suicides),
					string:lspace(4,data.Level),string:lspace(7,data.XP),
					string:lspace(5,data.Melee),string:lspace(5,data.Frags),
					string:lspace(5,data.Vehicles),string:lspace(5,data.Duelwins),
					string:lspace(5,playh),playm
				);
			else
				local player = type(player) == "table" and player or nCX.GetPlayerByProfileId(id);
				return "$9       "..player:GetName().." $4No data available.";
			end
		end;

		if (type(player) == "table") then
			return infoline(profileId);
		elseif (type(player) == "number") then
			local done;
			local tbl = {};
			for i = 1, 10 do
				if (players[i]) then
					if (players[i].Profile == profileId) then
						done = true;
						tbl[#tbl+1] = infoline(profileId, true);
					else
						tbl[#tbl+1] = infoline(i);
					end
				end
			end
			if (not done and #tbl==10) then
				tbl[#tbl+1] = infoline(profileId, true);
			end
			return tbl;
		end
	end,
};