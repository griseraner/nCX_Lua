
CryMP.ChatCommands:Add("zoneout", {
		Access = 1,
		Info = "launch the sniper zones",
		Delay = 60,
		Map = {"ps/mesa"},
		InGame = true,
		self = "ZoneOut",
	},
	function(self, player, channelId)
		self:Lights();
		CryMP.Msg.Chat:ToAll("SUPER-[+]-SNIPER-ZONES ::: ACTIVE - FLARES LAUNCHED!");
		nCX.SendTextMessage(5, "<font size=\"32\"><b><i><font color=\"#afafaf\">***</font> <font color=\"#5ca9cf\">SUPER-[+]-SNIPER : POSITIONS AVAILABLE</font> <font color=\"#afafaf\">***</font></i></b></font>", 0);
		return true;
	end
);
	
CryMP.ChatCommands:Add("jukebox", {
		Args = {
			{"soundId", Optional = true, Number = true, Info = "Play selected music",},
		},
		Access = 1,
	
		}, 
		
		function(self, player, channelId, mode)	
		--for i, x in pairs(nCX.GetPlayers()) do
		--	x:SetScale(0.3);
		--end
				--Sound.SetMusicTheme("motivation", 1);
			--Sound.SetMusicMood("motivational_epic", 1);		
			--Sound.SetMusicMood("action", 1);
			--Sound.SetMusicTheme("village_driving_3_main", 1, 1, 1);
		local f  = [[


			Sound.SetMusicTheme("island", 1, 1, 1);
			Sound.SetMusicTheme("village_driving", 1);
			Sound.SetMusicMood("action", 1);
			
		]]
		if (mode == 1) then
			f = [[
				System.LogAlways(dump(Sound));
				for i, s in pairs(Sound.GetMusicMoods("test")) do
					System.LogAlways(tostring(i).." "..tostring(s));
				end
			]]
		end

		--nCX.MovePlayer(player.id, pp:GetPos(), pp:GetAngles());
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f)
end);
--[[
--==============================================================================
--SELFDESTRUCT

CryMP.ChatCommands:Add("selfdestruct", {
		Info = "destroy your nano fuel cells with explosive effect",
		Price = 2000,
		InGame = true,
		Map = {"ps/(.*)"},
		self = "CryMP",
	}, 
	function(self, player, channelId)
		if (self.SelfDestruct) then
			return false, "active"
		end
		if (self.LastSelfDestruct and _time - self.LastSelfDestruct < 600) then
			return false, "wait "..(600 - math.floor(_time - self.LastSelfDestruct)).." seconds";
		elseif (player:IsBoxing()) then
			return false, "cannot use while boxing"
		elseif (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		elseif (player:IsRacing()) then
			return false, "cannot use while racing"
		end
		return self:GetPlugin("SelfDestruct", function(self)
			return self:Initiate(player);
		end);
	end
);
]]

--==============================================================================
--AFK

CryMP.ChatCommands:Add("afk", {
		Info = "get to a safe location while you are afk",
		InGame = true,
		self = "AFKManager",
		Args = {
			{"player", Optional = true, GetPlayer = true, CompareAccess = true, Access = 2, Info = "Force player into afk truck",},
		},
	},
	function(self, player, channelId, target)
		local player = target or player;
		if (CryMP.SelfDestruct) then
			return false, "selfdestruct active"
		elseif (player:IsBoxing()) then
			return false, "cannot use while boxing"
		elseif (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		elseif (player:IsRacing()) then
			return false, "cannot use while racing"
		elseif (player.actor:IsFlying()) then
			return false, "use your parachute - keep fighting"
		elseif (player.actor:GetHealth()~=100) then
			return false, "requires 100 hp - keep fighting"
		end
		local vehicleId = self:IsAfk(player);
		local vehicle = vehicleId and System.GetEntity(vehicleId);
		if (vehicle) then
			vehicle.vehicle:ExitVehicle(player.id);
			return true;
		end
		local full, msg = self:Enable(player);
		if (not full) then
			return false, msg
		end
		return true;
	end
);

--==============================================================================
--NAME

CryMP.ChatCommands:Add("name", {
		Args = {
			{"name", Info = "your name", Concat = true,},
		},
		Info = "rename yourself",
		Delay = 100,
		self = "Ent",
	},
	function(self, player, channelId, name)
		local ok, err, r = self:Rename(player, name, "user descision");
		if (ok) then
			return true;
		else
			return false, err, r;
		end
	end
);

--==============================================================================
--!RESET

CryMP.ChatCommands:Add("reset", {
		Info = "reset your score and rank",
		Delay = 300,
		InGame = true,
	},
	function(self, player, channelId)
		local playerId = player.id;
		nCX.SetSynchedEntityValue(player.id, 100, 0);
		nCX.SetSynchedEntityValue(player.id, 101, 0);
		nCX.SetSynchedEntityValue(player.id, 102, 0);
		nCX.SetSynchedEntityValue(player.id, 105, 0);
		nCX.SetSynchedEntityValue(player.id, 106, 0);
		if (g_gameRules.class == "PowerStruggle") then
			g_gameRules:ResetPP(playerId);
			g_gameRules:ResetCP(playerId);
		end
		player.inventory:Destroy();
		CryMP:SetTimer(1, function()
			nCX.GiveItem("AlienCloak", channelId, false, false);
			nCX.GiveItem("OffHand", channelId, false, false);  
			nCX.GiveItem("Fists", channelId, false, false);
			g_gameRules:EquipPlayer(player);
			CryMP:GetPlugin("Equip", function(self) self:Purchase(player, true); end);
		end);
		CryMP:GetPlugin("KillStreaks", function(self) 
			self:Reset(playerId);
			if (self:IsMostWanted(channelId)) then
				self:MostWantedEnd(player);
			end
		end);
		nCX.SendTextMessage(3, "Your score has been reset!", channelId);
		return true;
	end
);

--==============================================================================
--!TRANSFER [PLAYER] [PP]

CryMP.ChatCommands:Add("transfer", {
		Args = {
			{"player", GetPlayer = true,},
			{"pp", Number = true, Info = "The Amount of Prestige Points",},
		},
		Info = "transfer prestige points to a player",
		Delay = 30,
		InGame = true,
		Map = {"ps/(.*)"},
		BigMap = true,
	},
	function(self, player, channelId, target, points)
		local points = math.abs(points);
		local playerId = player.id;
		if (nCX.IsNeutral(target.id)) then
			return false, "can't give your PP to spectators";
		end
		if (g_gameRules:GetPlayerPP(playerId) < points) then
			return false, "not enough points";
		else
			g_gameRules:AwardPPCount(playerId, -1 * points);
			g_gameRules:AwardPPCount(target.id, points);
			g_gameRules.onClient:ClPP(channelId, -1 * points, true);
			nCX.SendTextMessage(3, "You transferred [ "..points.." ] to "..target:GetName(), channelId);
			nCX.SendTextMessage(3, "You received [ "..points.." ] from "..player:GetName(), target.Info.Channel);
			return true;
		end
	end
);

--===================================================================================
-- PORTAL

CryMP.ChatCommands:Add("portal", {
		Info = "teleport back to your base",
		Delay = 60,
		InGame = true,
		Map = {"ps/(.*)"},
		Args = {
			{"ignore", Access = 5, Optional = true},
		},
		self = "Ent",
		BigMap = true,
	}, 
	function(self, player, channelId, ignore)
		local playerId = player.id;
		if (not ignore) then
			if (player:IsDuelPlayer()) then
				return false, "cannot use while duel"
			elseif (player:IsRacing()) then
				return false, "cannot use while racing"
			elseif (player:IsOnVehicle()) then
				return false, "leave your vehicle"
			elseif (player.actor:IsFlying()) then
				nCX.SendTextMessage(0, "PREPARE - [ ONLY ON GROUND ] - LANDING", channelId);
				return false, "use your parachute - keep fighting"
			elseif (player.actor:GetHealth() ~= 100) then
				nCX.SendTextMessage(0, "REQUIRES -[ 100 ]- HP", channelId);
				return false, "requires 100 hp - keep fighting"
			end
		end
		self:Portal(player);
		return true;
	end
);

--===================================================================================
-- JUMP PS

CryMP.ChatCommands:Add("jump", {
		Info = "jump into the sky", 
		Delay = 60, 
		Price = 25,
		InGame = true,
		BigMap = true,
		Map = {"ps/(.*)"},
	}, 
	function(self, player, channelId)
		if (player:IsRacing()) then
			return false, "cannot use while racing"
		elseif (player:IsBoxing()) then
			return false, "cannot use while boxing"
		elseif (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		elseif (player.actor:GetHealth()~=100) then
			nCX.SendTextMessage(0, "REQUIRES - [ 100 ] - HP", channelId);
			return false, "requires 100 hp - keep fighting"
		end
		local truck = System.GetEntityByName("AFK_TRUCK");
		if (truck and player:GetDistance(truck.id) < 12) then
			return false, "you cannot jump near the afk truck"
		end
		local height = 160;
		local map = nCX.GetCurrentLevel():sub(16, -1):lower();
		if (map == "refinery" or map == "frost" or map == "desolation" or map == "training" or map == "plantation") then
			height = 70;
		end
		height = height + System.GetTerrainElevation(player:GetPos());
		local playerId = player.id;
		local vehicle = player.actor:GetLinkedVehicle();
		if (vehicle) then
			local seat = vehicle:GetSeat(playerId);
			if(not seat.seat:IsDriver()) then
				return false, "you must be the driver to eject";
			end
			local passengers = vehicle:GetPassengers();
			if (passengers) then
				for i, passengerId in pairs(passengers) do
					local passenger = nCX.GetPlayer(passengerId);
					if (passenger) then
						nCX.ResetAntiCheat(passengerId);
						local pos = passenger:GetWorldPos();
						local x, y, z = pos.x, pos.y, pos.z;
						if (not player.CLIENT_PATCH) then
							nCX.SetInvulnerability(passengerId, true, 3);
							vehicle.vehicle:ExitVehicle(passengerId);
						end
						nCX.ParticleManager("explosions.cluster_bomb.impact", 0.2, {x = x, y = y, z = z - 1}, g_Vectors.up, 0);
						nCX.ParticleManager("explosions.Grenade_SCAR.alien", 0.2, {x = x, y = y, z = z - 0.5}, g_Vectors.up, 0);
						nCX.ParticleManager("Alien_Weapons.singularity.Tank_Singularity_Spinup", 1, {x = x, y = y, z = z - 8}, g_Vectors.up, 0);
					end
				end
				CryMP:DeltaTimer(7, function()
					for i, passengerId in pairs(passengers) do
						local passenger = nCX.GetPlayer(passengerId);
						if (passenger) then
							if (not player.CLIENT_PATCH) then
								if (passenger.inventory:GetCountOfClass("Parachute")==0) then
									nCX.GiveItem("Parachute", passenger.Info.Channel, false, false);
								end
								local pos = vehicle:GetSpeed() > 0 and vehicle:GetWorldPos() or vehicle:GetCenterOfMassPos();
								local x, y, z = pos.x, pos.y, pos.z;
								CryMP.Ent:MovePlayer(passenger, {x = x, y = y, z = z + 10}, {x = 275, y = 0, z = 75});
							end
							local posjumped = CryMP.Library:CalcSpawnPos(passenger,-1);
							nCX.ParticleManager("explosions.gauss.bullet_backup", 0.5, posjumped, g_Vectors.up, 0);
						end
					end
					if (player.CLIENT_PATCH) then
						local client_func = "nCX_Jump()";
						g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..client_func);
														--local sound = "ai_korean_soldier_1/fallingdeath_0"..math.random(0, 5);
							--p:PlaySoundEvent("ai_kyong/bulletrain_0"..math.random(5), g_Vectors.v000, g_Vectors.v010, sndFlags, SOUND_SEMANTIC_PLAYER_FOLEY);
						local code = [[
							local v = System.GetEntityByName("]]..vehicle:GetName()..[[");
							if (not v or not v.Seats) then return end;
							local sndFlags = bor(bor(SOUND_EVENT, SOUND_VOICE), SOUND_DEFAULT_3D);
							for i,seat in pairs(v.Seats) do
								local p = seat:GetPassengerId() and System.GetEntity(seat:GetPassengerId());
								if (p) then
									local sound = "ai_korean_soldier_1/fallingdeath_0"..math.random(0, 5);
									p:PlaySoundEvent(sound, g_Vectors.v000, g_Vectors.v010, sndFlags, SOUND_SEMANTIC_PLAYER_FOLEY);
								end
							end							
						]]
						--g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..code);
					else
						vehicle:AddImpulse(-1, vehicle:GetCenterOfMassPos(), g_Vectors.up, 3000000, 1);
					end
					CryMP.Msg.Chat:ToOther(channelId, "Player : "..player:GetName().." ejected from vehicle!");
					--CryMP:DeltaTimer(5, function() -- should prevent being stuck inside vehicle
						--vehicle.vehicle:Destroy()
					--	CryMP.Msg.Chat:ToOther(channelId, "Player : "..player:GetName().." ejected from vehicle!");
					--end);
				end);		
			end
		else
			nCX.ResetAntiCheat(playerId);
			nCX.SetInvulnerability(playerId, true, 5);
			local pos = player:GetWorldPos();
			local x, y, z = pos.x, pos.y, pos.z;
			local posjumped, dir = CryMP.Library:CalcSpawnPos(player,-1);
			nCX.ParticleManager("explosions.gauss.bullet_backup", 0.5, posjumped, g_Vectors.up, 0);
			nCX.ParticleManager("explosions.cluster_bomb.impact", 0.2, {x = x, y = y, z = z - 1}, g_Vectors.up, 0);
			nCX.ParticleManager("explosions.Grenade_SCAR.alien", 0.2, {x = x, y = y, z = z - 0.5}, g_Vectors.up, 0);
			if (not player.CLIENT_PATCH and CryMP.Ent:IsPosInZone(pos)) then
				player.actor:SetNanoSuitEnergy(1);
				nCX.ServerHit(playerId,playerId,98,"punish");
				nCX.MovePlayer(playerId, {x = x, y = y, z = z + 1.5}, {x = 275, y = 0, z = 75});
				return false, "not indoors", "Not indoors!"
			end
			if (not player.CLIENT_PATCH) then
				if (player.inventory:GetCountOfClass("Parachute")==0) then
					nCX.GiveItem("Parachute", channelId, false, false);
				end
				CryMP.Ent:MovePlayer(player, {x = x, y = y, z = height}, {x = 275, y = 0, z = 75});
			else
				--CryMP.Ent:MovePlayer(player, player:GetPos(), {x = 275, y = 0, z = 75});
				local client_func = "nCX_Jump()";
				g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..client_func);
				
				local code = [[
					local p = System.GetEntityByName("]]..player:GetName()..[[");
					if (not p) then return end;
					local sndFlags = bor(bor(SOUND_EVENT, SOUND_VOICE), SOUND_DEFAULT_3D);
					local sound = "ai_korean_soldier_1/fallingdeath_0"..math.random(0, 5);
					p:PlaySoundEvent(sound, g_Vectors.v000, g_Vectors.v010, sndFlags, SOUND_SEMANTIC_PLAYER_FOLEY);
				]]
				--g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..code);
				--CryMP.RSE:ToTarget(channelId, 'name=System.GetEntityByName(g_localActor:GetName()); name:AddImpulse(-1, name:GetPos(), g_Vectors.up, 50000, 1);HUD.BattleLogEvent(eBLE_Warning,"Have fun "..g_localActor:GetName().."");');
				--player:AddImpulse(-1, player:GetPos(), g_Vectors.up, 50000, 1);
			end
			--nCX.AddImpulse(playerId, 50000)
			--player:AddImpulse(-1, player:GetPos(), player:GetDirectionVector(1), 5000, 1);
			nCX.ParticleManager("Alien_Weapons.singularity.Tank_Singularity_Spinup", 1, {x = x, y = y, z = z - 8}, g_Vectors.up, 0);
			CryMP.Msg.Chat:ToOther(channelId, "Player : "..player:GetName().." SUPER-JUMPED!");
		end
		--nCX.SendTextMessage(5, "<font size=\"32\"><b><font color=\"#c4c4c4\">! CAUTION ! :::: [</font><font color=\"#b53b3b\"> DEPLOY PARACHUTE NOW <font color=\"#c4c4c4\">]</font></b></font>", channelId);
		return true;
	end
);

--===================================================================================
-- JUMP TIA
--[[
CryMP.ChatCommands:Add("jump", {
		Info = "jump into the sky", 
		Delay = 60, 
		InGame = true,
		Access = 1,
		Map = {"ia/(.*)"},
	}, 
	function(self, player, channelId)
		if (player:IsRacing()) then
			return false, "cannot use while racing"
		elseif (player:IsBoxing()) then
			return false, "cannot use while boxing"
		elseif (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		elseif (player.actor:GetHealth()~=100) then
			nCX.SendTextMessage(5, "<font size=\"32\"><b><font color=\"#bfbfbf\">REQUIRES - [</font><font color=\"#cf5454\"> 100 </font><font color=\"#bfbfbf\">] - HP</font></b></font>", channelId);
			return false, "requires 100 hp - keep fighting"
		end
		local truck = System.GetEntityByName("AFK_TRUCK");
		if (truck and player:GetDistance(truck.id) < 12) then
			return false, "you cannot jump near the afk truck"
		end
		local height = 70;
		local map = nCX.GetCurrentLevel():sub(16, -1):lower();

		height = height + System.GetTerrainElevation(player:GetPos());
		local playerId = player.id;
		local vehicle = player.actor:GetLinkedVehicle();
		if (vehicle) then
			local seat = vehicle:GetSeat(playerId);
			if(not seat.seat:IsDriver()) then
				return false, "you must be the driver to eject";
			end
			local passengers = vehicle:GetPassengers();
			if (passengers) then
				for i, passengerId in pairs(passengers) do
					local passenger = nCX.GetPlayer(passengerId);
					if (passenger) then
						nCX.ResetAntiCheat(passengerId);
						local pos = passenger:GetWorldPos();
						local x, y, z = pos.x, pos.y, pos.z;
						nCX.SetInvulnerability(passengerId, true, 3);
						vehicle.vehicle:ExitVehicle(passengerId);

						nCX.ParticleManager("explosions.cluster_bomb.impact", 0.2, {x = x, y = y, z = z - 1}, g_Vectors.up, 0);
						nCX.ParticleManager("explosions.Grenade_SCAR.alien", 0.2, {x = x, y = y, z = z - 0.5}, g_Vectors.up, 0);
						nCX.ParticleManager("Alien_Weapons.singularity.Tank_Singularity_Spinup", 1, {x = x, y = y, z = z - 8}, g_Vectors.up, 0);
					end
				end
				CryMP:DeltaTimer(7, function()
					for i, passengerId in pairs(passengers) do
						local passenger = nCX.GetPlayer(passengerId);
						if (passenger) then
							if (not CryMP.RSE) then
								if (passenger.inventory:GetCountOfClass("Parachute")==0) then
									nCX.GiveItem("Parachute", passenger.Info.Channel, false, false);
								end
								local pos = vehicle:GetSpeed() > 0 and vehicle:GetWorldPos() or vehicle:GetCenterOfMassPos();
								local x, y, z = pos.x, pos.y, pos.z;
								CryMP.Ent:MovePlayer(passenger, {x = x, y = y, z = z + 10}, {x = 275, y = 0, z = 75});
							end
							local posjumped = CryMP.Library:CalcSpawnPos(passenger,-1);
							nCX.ParticleManager("explosions.gauss.bullet_backup", 0.5, posjumped, g_Vectors.up, 0);
						end
					end
					vehicle:AddImpulse(-1, vehicle:GetCenterOfMassPos(), g_Vectors.up, 3000000, 1);
					CryMP.Msg.Chat:ToOther(channelId, "Player : "..player:GetName().." ejected from vehicle!");
				end);		
			end
		else
			nCX.ResetAntiCheat(playerId);
			nCX.SetInvulnerability(playerId, true, 5);
			local pos = player:GetWorldPos();
			local x, y, z = pos.x, pos.y, pos.z;
			local posjumped, dir = CryMP.Library:CalcSpawnPos(player,-1);
			nCX.ParticleManager("explosions.gauss.bullet_backup", 0.5, posjumped, g_Vectors.up, 0);
			nCX.ParticleManager("explosions.cluster_bomb.impact", 0.2, {x = x, y = y, z = z - 1}, g_Vectors.up, 0);
			nCX.ParticleManager("explosions.Grenade_SCAR.alien", 0.2, {x = x, y = y, z = z - 0.5}, g_Vectors.up, 0);
			if (CryMP.Ent:IsPosInZone(pos)) then
				player.actor:SetNanoSuitEnergy(1);
				nCX.ServerHit(playerId,playerId,98,"punish");
				nCX.MovePlayer(playerId, {x = x, y = y, z = z + 1.5}, {x = 275, y = 0, z = 75});
				return false, "not indoors", "Not indoors!"
			end
			if (player.inventory:GetCountOfClass("Parachute")==0) then
				nCX.GiveItem("Parachute", channelId, false, false);
			end
			CryMP.Ent:MovePlayer(player, {x = x, y = y, z = height}, {x = 275, y = 0, z = 75});
			nCX.ParticleManager("Alien_Weapons.singularity.Tank_Singularity_Spinup", 1, {x = x, y = y, z = z - 8}, g_Vectors.up, 0);
			CryMP.Msg.Chat:ToOther(channelId, "Player : "..player:GetName().." SUPER-JUMPED!");
		end
		--nCX.SendTextMessage(5, "<font size=\"32\"><b><font color=\"#c4c4c4\">! CAUTION ! :::: [</font><font color=\"#b53b3b\"> DEPLOY PARACHUTE NOW <font color=\"#c4c4c4\">]</font></b></font>", channelId);
		return true;
	end
);]]

--===================================================================================
-- SPIN (PS)

CryMP.ChatCommands:Add("spin", {
		Access = 1, 
		Info = "play the slot machine", 
		Delay = 4, 
		Price = 200,
		InGame = true,
		Map = {"ps/(.*)"},
		BigMap = true,
	}, 
	function(self, player, channelId)
		local playerId = player.id;
		local spins = 45; -- Configure the amount of spins here! should be dividable by three width maxspins%3==0
		local SpinNumbers = {0,0,0};-- Our numbers array
		self.Jackpot = (self.Jackpot or 10000) + self.Commands["spin"].Price;
		self.Spin_Amount = (self.Spin_Amount or 0) + 1
		--g_gameRules.onClient:ClPP(channelId, -self.Commands["spin"].Price, true);
		local function gsm(data, index, fixed)
			local v1, v2 = "", "";
			if (fixed) then
				--v1, v2 = "<font size=\"36\">", "</font>";
			end
			if (data[index] == 0) then
				--return "<font color=\"#FF0000\">7</font>";
				return v1.."   7   "..v2;
			elseif (data[index] == 1) then
				--return "<font color=\"#00FF21\">0</font>";
				return v1.." BAR"..v2;
			elseif (data[index] == 2) then
				return v1.."   X   "..v2;
				--return "<font color=\"#379f3c\">X</font>";
			else
				--return "<font color=\"#FFD800\">$</font>";
				return v1.."   0   "..v2;
			end
		end
		local mC = "#7d7d7d"; -- msgcolor ,#7d7d7d
		local msgs = {};
		local name = player:GetName();
		for i = 1, spins do
			local f1, f2;
			if (i < spins/3) then -- All 3 numbers can change
				SpinNumbers[1] = math.random(0,3);
				SpinNumbers[2] = math.random(0,3);
				SpinNumbers[3] = math.random(0,3);
			elseif (i < 2 * spins/3) then --First number is fixed
				SpinNumbers[2] = math.random(0,3);
				SpinNumbers[3] = math.random(0,3);			
				f1 = true;
			else --First and second number are fixed
				SpinNumbers[3] = math.random(0,3);
				f2 = true;
			end
			--msgs[#msgs + 1] = "<i><b><font color=\""..mC.."\">SPIN : (</font>"..gsm(SpinNumbers, 1, f1 or f2).."<font color=\"#000066\">~</font>"..gsm(SpinNumbers, 2, f2).."<font color=\"#000066\">~</font>"..gsm(SpinNumbers, 3, i == spins).."<font color=\""..mC.."\">) : LINE</font></b></i>";
			msgs[#msgs + 1] = "SPIN : ("..gsm(SpinNumbers, 1, f1 or f2).." ~ "..gsm(SpinNumbers, 2, f2).." ~ "..gsm(SpinNumbers, 3, i == spins)..") : LINE";
		end
		
		-- Uncomment for testing
		--SpinNumbers[1]=0;
		--SpinNumbers[2]=1;
		--SpinNumbers[3]=2;

		
		local jackpot = SpinNumbers[1]==0 and SpinNumbers[2]==3 and SpinNumbers[3]==2;
		local winner = SpinNumbers[1] ~= 3 and SpinNumbers[1]==SpinNumbers[2] and SpinNumbers[2]==SpinNumbers[3];
		
		for i, message in pairs(msgs) do
			CryMP.Msg:AddToQueue(0, message, 2, channelId);
			if (i == #msgs) then
				if (jackpot or winner) then
					--CryMP.Msg.Scroll:ToPlayer(channelId, {"#ffffff", false, 0}, message);
				else
					CryMP.Msg:AddToQueue(0, message, 40, channelId);
				end
			end
		end
			
		if (jackpot) then
			--CryMP.Msg.Animated:ToPlayer(channelId, 1, "<b><i><font color=\"#e82727\">*** !!</font> <font color=\"#d53553\">JACKPOT</font> <font color=\"#e82727\">!! ***</font></i></b></font>");
			--CryMP.Msg.Flash:ToPlayer(channelId, {50, "#d53553", "#FBF4FB",}, "JACKPOT", "<b><i><font color=\"#e82727\">*** !!</font> %s <font color=\"#e82727\">!! ***</font></i></b></font>");
		elseif (winner) then
			--CryMP.Msg.Animated:ToPlayer(channelId, 1, "<b><i><font color=\"#e82727\">*** !!</font> <font color=\"#d53553\">WINNER</font> <font color=\"#e82727\">!! ***</font></i></b></font>");
		else
			local ratio = self.Spin_Amount / 20;
			--if (ratio == math.floor(ratio)) then
				CryMP.Msg.Chat:ToAll("SPIN :: "..name.." :: CURRENT:JACKPOT :: "..self.Jackpot.." POINTS", 1);
				self:Log("$9Current Spin Jackpot: $7"..self.Jackpot.." $9prestige");
			--end
			--CryMP.Msg.Flash:ToPlayer(channelId, {50, "#af3838", "#ff0000",}, "~ SPIN ~ OVER ~", "<font size=\"30\"><b><i><font color=\""..mC.."\">SPIN : (</font><font color=\"#59c93a\"> </b>%s<b> </font><font color=\""..mC.."\">) : LOSE</font></i></b></font>");
			return true;
		end
		
		CryMP:SetTimer(3, function()--was * 20
			if (winner) then
				CryMP.Ent:PlaySound(playerId, "alert");
				-- 3 equal ones
				local award, msg = 1000, "7~7~7";
				if (SpinNumbers[1] == 1) then
					award, msg = 2000, "BAR~BAR~BAR";
				elseif(SpinNumbers[1] == 2) then 
					award, msg = 5000, "X~X~X";		
				end
				CryMP.Library:Pay(player, award);
				CryMP.Msg.Chat:ToAll("! WIN:SPIN :: "..name.." :: "..msg.." :: "..award.." POINTS !");
			elseif (jackpot)then  -- 7 O X = Jackpot
				CryMP.Ent:PlaySound(playerId, "win");
				CryMP.Library:Pay(player, tonumber(self.Jackpot));
				CryMP.Msg.Chat:ToAll("! WIN:SPIN :: "..name.." :: JACKPOT :: 7~O~X :: "..self.Jackpot.." POINTS !");
				self.Jackpot = nil;
			end
		end);
		return true;
	end
);

--===================================================================================
-- SPIN (IA VERSION)
--[[
CryMP.ChatCommands:Add("spin", {
		Access = 0, 
		Info = "play the slot machine", 
		Delay = 4, 
		InGame = true,
		Map = {"ia/(.*)"},
	}, 
	function(self, player, channelId)
		local playerId = player.id;
		local spins = 45; -- Configure the amount of spins here! should be dividable by three width maxspins%3==0
		local SpinNumbers = {0,0,0};-- Our numbers array
		self.Jackpot = (self.Jackpot or 10000) + self.Commands["spin"].Price;
		self.Spin_Amount = (self.Spin_Amount or 0) + 1
		--g_gameRules.onClient:ClPP(channelId, -self.Commands["spin"].Price, true);
		local function gsm(data, index, fixed)
			local v1, v2 = "", "";
			if (fixed) then
				--v1, v2 = "<font size=\"36\">", "</font>";
			end
			if (data[index] == 0) then
				--return "<font color=\"#FF0000\">7</font>";
				return v1.."   7   "..v2;
			elseif (data[index] == 1) then
				--return "<font color=\"#00FF21\">0</font>";
				return v1.." BAR"..v2;
			elseif (data[index] == 2) then
				return v1.."   X   "..v2;
				--return "<font color=\"#379f3c\">X</font>";
			else
				--return "<font color=\"#FFD800\">$</font>";
				return v1.."   0   "..v2;
			end
		end
		local mC = "#7d7d7d"; -- msgcolor ,#7d7d7d
		local msgs = {};
		local name = player:GetName();
		for i = 1, spins do
			local f1, f2;
			if (i < spins/3) then -- All 3 numbers can change
				SpinNumbers[1] = math.random(0,3);
				SpinNumbers[2] = math.random(0,3);
				SpinNumbers[3] = math.random(0,3);
			elseif (i < 2 * spins/3) then --First number is fixed
				SpinNumbers[2] = math.random(0,3);
				SpinNumbers[3] = math.random(0,3);			
				f1 = true;
			else --First and second number are fixed
				SpinNumbers[3] = math.random(0,3);
				f2 = true;
			end
			--msgs[#msgs + 1] = "<i><b><font color=\""..mC.."\">SPIN : (</font>"..gsm(SpinNumbers, 1, f1 or f2).."<font color=\"#000066\">~</font>"..gsm(SpinNumbers, 2, f2).."<font color=\"#000066\">~</font>"..gsm(SpinNumbers, 3, i == spins).."<font color=\""..mC.."\">) : LINE</font></b></i>";
			msgs[#msgs + 1] = "SPIN : ("..gsm(SpinNumbers, 1, f1 or f2).." ~ "..gsm(SpinNumbers, 2, f2).." ~ "..gsm(SpinNumbers, 3, i == spins)..") : LINE";
		end
		
		-- Uncomment for testing
		--SpinNumbers[1]=0;
		--SpinNumbers[2]=1;
		--SpinNumbers[3]=2;

		
		local jackpot = SpinNumbers[1]==0 and SpinNumbers[2]==3 and SpinNumbers[3]==2;
		local winner = SpinNumbers[1] ~= 3 and SpinNumbers[1]==SpinNumbers[2] and SpinNumbers[2]==SpinNumbers[3];
		
		for i, message in pairs(msgs) do
			CryMP.Msg:AddToQueue(0, message, 2, channelId);
			if (i == #msgs) then
				if (jackpot or winner) then
					--CryMP.Msg.Scroll:ToPlayer(channelId, {"#ffffff", false, 0}, message);
				else
					CryMP.Msg:AddToQueue(0, message, 40, channelId);
				end
			end
		end
			
		if (jackpot) then
			--CryMP.Msg.Animated:ToPlayer(channelId, 1, "<b><i><font color=\"#e82727\">*** !!</font> <font color=\"#d53553\">JACKPOT</font> <font color=\"#e82727\">!! ***</font></i></b></font>");
			--CryMP.Msg.Flash:ToPlayer(channelId, {50, "#d53553", "#FBF4FB",}, "JACKPOT", "<b><i><font color=\"#e82727\">*** !!</font> %s <font color=\"#e82727\">!! ***</font></i></b></font>");
		elseif (winner) then
			--CryMP.Msg.Animated:ToPlayer(channelId, 1, "<b><i><font color=\"#e82727\">*** !!</font> <font color=\"#d53553\">WINNER</font> <font color=\"#e82727\">!! ***</font></i></b></font>");
		else
			local ratio = self.Spin_Amount / 20;
			--if (ratio == math.floor(ratio)) then

			--end
			--CryMP.Msg.Flash:ToPlayer(channelId, {50, "#af3838", "#ff0000",}, "~ SPIN ~ OVER ~", "<font size=\"30\"><b><i><font color=\""..mC.."\">SPIN : (</font><font color=\"#59c93a\"> </b>%s<b> </font><font color=\""..mC.."\">) : LOSE</font></i></b></font>");
			return true;
		end
		
		CryMP:SetTimer(3, function()--was * 20
			player.SPIN_COUNT = 0;
			if (winner) then
				CryMP.Ent:PlaySound(playerId, "alert");
				-- 3 equal ones
				local award, msg = "Explosives", "7~7~7";
				if (SpinNumbers[1] == 1) then
					award, msg = "AlienMount", "BAR~BAR~BAR";
				elseif(SpinNumbers[1] == 2) then 
					award, msg = "GaussRifle", "X~X~X";		
				end
				if (award == "Explosives") then
					local tbl = {["avexplosive"] = "AVMine", ["c4explosive"] = "C4", ["claymoreexplosive"] = "Claymore",["flashbang"] = "",["smokegrenade"] = "",["explosivegrenade"] = "",["empgrenade"] = "",};
					for ammo, class in pairs(tbl) do
						player.actor:SetInventoryAmmo(ammo, player.inventory:GetAmmoCapacity(ammo) or 0, 3);
						if (#class > 0) then
							nCX.GiveItem(class, channelId, false, true);
						end
					end
					player.actor:SelectItemByNameRemote("C4");
				else
					local item = nCX.GiveItem(award, channelId, true, true);
					if (item) then
						if (award == "AlienMount") then
							item.weapon:AttachAccessory("MOARAttach");
						else
							item.weapon:AttachAccessory("SniperScope");
						end
					end
				end
				CryMP.Msg.Chat:ToAll("! WIN:SPIN :: "..name.." :: "..msg.." :: AWARDED -[ "..award.." ] !");
			elseif (jackpot)then  -- 7 O X = Jackpot
				--CryMP.Ent:PlaySound(playerId, "win");
				CryMP.Library:Pay(player, tonumber(self.Jackpot));
				CryMP.Msg.Chat:ToAll("! WIN:SPIN :: "..name.." :: JACKPOT :: 7~O~X :: AWARDED -[ TAC-GUN ] !");
				nCX.GiveItem("TACGun", channelId, false, true);
				CryMP.Ent:NukeTag(player, true);
				self.Jackpot = nil;
			end
			CryMP:SetTimer(2, function()
				CryMP.Msg.Chat:ToPlayer(channelId, "Received: 5x more SPIN attempts!");
			end);
		end);
		return true;
	end
);
]]
