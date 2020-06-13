ServerDefence = {

	---------------------------
	--		Config
	---------------------------
	Required 						 = true,
	Tag								 = 8,
	
	Detections						 = {},	
	Actions = {	
		-- 0 = kick, -1 = permaban, -2 = botslap, -3 = log only, -4 = kill player, > 0 = time being banned
	
		["RMI Flood"] 				 = -3, 
		["RMI Manipulation"]		 =  0,
		["Chat Spam"] 				 =  0,
		["Chat Manipulation"] 		 =  0,
		["File Manipulation"] 		 = -3,
		
		["No Spread"] 				 = -2,
		["Low Spread"] 				 =  0,
		["Shot Spoof"] 				 =  0, --Longpoke etc
		["Melee"]   				 =  0,
		["FireMode"]   				 =  0,
		["Rapid Fire"] 				 = -1,
		["Weapon Cooldown"] 		 = -2,
		["Weapon Spinup"] 			 = 0,

		["RPG Auto-Aim"] 			 = 10,
		["SimpleHit Manipulation"]   =  0,
		["Shoot Pos"]				 =  0,
		["ShootEx Pos"]				 =  0,
		["Freeze"] 					 = -2,
	},
	
	Server = {
		
		OnCheatDetected = function(self, player, cheat, info, highLatency, safeDetect) -- SURE detection means not affected by lag => ban hard (long poke, norecoil etc)!
			local action = self.Actions[cheat] or -1;
			local isAdmin = (CryMP.Users:GetAccess(player.Info.ID) > 2);
			if (isAdmin) then 
				action = -3;
			end
			local name = player:GetName();
			local time = os.date("%H:%M:%S", time);
			local country = player.Info.Country.." ("..(player.Info.Country_Short or "n/a")..")";
			self.Detections[#self.Detections+1] = {Cheat = cheat, Action = action, Info = info, IP = player.Info.IP, HighLatency = highLatency, SafeDetect = safeDetect, Name = name, Time = time, ServerTime = _time,};
			
			if (cheat == "File Manipulation") then
				local file = info:match( "([^/]+)$");
				if (file) then
					file = file:sub(1,1):upper()..file:sub(2,#file);
				end
				CryMP.Msg.Chat:ToAll("Detected modified file on "..player:GetName().." ("..file..")", self.Tag);
				self:Log("Detected modified file on "..player:GetName().." ("..info..")");
				return;
			end
			System.LogAlways("OnCheatDetected "..player:GetName().." "..cheat.." "..info);
			--[[
			if (cheat:find("Pos")) then
				local msg = "Killing player "..player:GetName().." ("..cheat..", "..info..")";
				CryMP.Msg.Chat:ToAccess(2, msg, 2);
				System.LogAlways(msg);
				CryMP.Msg.Chat:ToAll("BUG:DETECT-[ S:POS ]- > > > RESET:"..player:GetName(), self.Tag);
				g_gameRules:KillPlayer(player);
				return;
			elseif (cheat == "Low Spread") then
				local weapon = player.inventory:GetCurrentItem();
				if (weapon) then
					CryMP.Msg.Chat:ToAll("BUG:DETECT-[ WEAPON SPREAD ]- > > > "..player:GetName().." LOST HIS "..weapon.class, self.Tag);
					player.actor:DropItem(weapon.id, 30);
					return;
				end
			end]]
			local admins = CryMP.Users:GetUsers(3);
			local highPing = (nCX.GetPing(player.Info.Channel) > 200);
			
			self:LogCheat(player, cheat, info, highLatency or highPing, safeDetect);
		
			-- Process non-admins:
			local value = tonumber(info);
			--if (RMI_Flood and value and value > 200) then	
			--	action = -1;
			--end
			if (action) then
				if (action == -3) then
					return;
				end
				if (action == -1) then
					CryMP.BanSystem:PermaBan(player, cheat, "nCX"); 
				elseif (action == -2) then
					local success = self:Punish(player, cheat);
					if (not success) then
						CryMP.BanSystem:PermaBan(player, cheat, "nCX");
					end
				elseif (action == -4) then
					g_gameRules:KillPlayer(player);
				elseif (action > 0) then
					CryMP.BanSystem:TempBan(player, cheat, action, "nCX");
				else
					CryMP.BanSystem:Kick(player, cheat, "nCX");
				end
			end
		end,
		
		OnDisconnect = function(self, channelId, player)
			local info = self.Cheater;
			if (info and info.channelId == channelId) then
				if (info.vehicleId) then
					System.RemoveEntity(info.vehicleId);
				end
				if (not info.banned) then
					CryMP.BanSystem:PermaBan(player, info.cheat, info.Admin);
				end
				self.Cheater = nil;
				self:SetTick(false);
			end
		end,
		
		CanEnterVehicle = function(self, vehicle, player)
			if (self:IsTruck(vehicle.id)) then
				return true, {false};
			elseif (not vehicle.PassengerEntered and vehicle.class == "US_vtol" and g_gameRules.class == "TeamInstantAction" and vehicle:IsRespawning()) then
				local ents = System.GetEntitiesByClass("US_vtol");
				if (ents) then
					for i, vtol in pairs(ents) do
						if (nCX.IsSameTeam(vtol.id, player.id) and vtol:GetDriverId()) then
							nCX.SendTextMessage(0, "[ + ] >>> MAX - [ 1 x VTOL ] - PER TEAM", player.Info.Channel);
							return true, {false};
						end
					end
				end
			end
		end,
		
		OnLeaveVehicleSeat = function(self, vehicle, seat, player, exiting)
			if (self:IsTruck(vehicle.id)) then
				nCX.ForbiddenAreaWarning(true, 0, player.id);
				return true;
			end
		end,
		
		OnRequestRevive = function(self, player)
			local info = self.Cheater;
			if (info and info.playerId == player.id) then
				return true;
			end			
		end,
				
	},
	
	OnInit = function(self)
		if (g_gameRules.Prototype) then
			local pos = g_gameRules.Prototype:GetWorldPos();
			local map = nCX.GetCurrentLevel():sub(16, -1):lower();
			local PunishInfo = {
				["mesa"] 		= {{x = 2086, y = 1996, z = 73}, {x = 2064, y = 1996, z = 58}},
				["beach"] 		= {{x = 1920, y = 2662, z = 227}, {x = 1920, y = 2642, z = 212}},
				["shore"] 		= {{x = 2130, y = 1482, z = 135}, {x = 2110, y = 1482, z = 125}},
				["tarmac"] 		= {{x = 1960, y = 1468, z = 191}, {x = 1939, y = 1462, z = 176}},
				["desolation"] 	= {{x = 1076, y = 1342, z = 270}, {x = 1076, y = 1319, z = 423}},
				["crossroads"] 	= {{x = 1053, y = 1010, z = 51}, {x = 1053, y = 1036, z = 144}},
				["plantation"] 	= {{x = pos.x, y = pos.y, z = pos.z+6}, {x = pos.x, y = pos.y, z = pos.z+125}},
				["refinery"] 	= {{x = 2642, y = 2595, z = 445}, {x = 2642, y = 2576, z = 499}},
				["frost"] 		= {{x = pos.x, y = pos.y, z = pos.z+6}, {x = pos.x, y = pos.y, z = pos.z+52}},
				["training"] 	= {{x = pos.x, y = pos.y, z = pos.z+6}, {x = pos.x, y = pos.y, z = pos.z+87}},
			};
			self.pos = PunishInfo[map][1] or {x = 2086, y = 1996, z = 73};
			self.truck = PunishInfo[map] and {PunishInfo[map][2], g_gameRules.Prototype:GetDirectionVector(1)} or {{ x=2064, y=1996, z=58 }, {0,0,0}};
		end	
	end,
	
	OnShutdown = function(self)
		return {"Detections"};
	end,
	
	GetDetectionCount = function(self, IP)
		local count = 0;
		for i, data in pairs(self.Detections) do
			if (data.IP == IP) then
				count = count + 1;
			end
		end
		return count;
	end,
	
	Punish = function(self, player, cheat, admin)
		if (not self.truck or not self.pos) then
			return false, "map not supported";
		end
		local info = self.Cheater;
		if (not info) then
			local admin = admin and admin:GetName() or "nCX";
			self.Cheater = {
				channelId = player.Info.Channel,
				playerId = player.id,
				cheat = cheat,
				timer = 0,
				name = player:GetName(),
				Admin = admin,
				banned = false,
			};
			self:SetTick(1);
			return true;
		else
			local player = nCX.GetPlayer(info.playerId);
			if (player) then
				if (player.id == info.playerId) then
					return false, "player is being punished";
				else
					return false, "punish in progress";
				end
			else
				self.Cheater = nil;
				return false, "player not found";
			end
		end
	end,
	
	LogCheat = function(self, player, cheat, info, lagging, safeDetect)
		local current = nCX.GetServerPerformance();
		local msg = "Detected $4"..cheat.." $9on "..(lagging and "$8" or "")..player:GetName();
		local access = player:GetAccess();
		if (access > 1 or not safeDetect) then	
			CryMP.Msg.Chat:ToAccess(2, msg, 2);
		else
			CryMP.Msg.Chat:ToAll(msg, self.Tag);
		end
		local toAccess = 2;
		if (self.Actions[cheat] and self.Actions[cheat] > -3) then
			toAccess = safeDetect and nil or 2;
		end
		self:Log(msg..(info and "$9 | "..info or ""), toAccess);
		if (math.abs(current - System.GetCVar("nCX_PerformanceValue")) > 10) then
			self:Log("Performance was: $1"..current.."%$9)", 3);
		end
	end,
		
	OnTick = function(self, players)
		local info = self.Cheater;
		if (info) then
			local pos = self.pos;
			local channelId, playerId = info.channelId, info.playerId;
			local player = nCX.GetPlayerByChannelId(channelId);
			if (not player) then
				if (info.vehicleId) then
					System.RemoveEntity(info.vehicleId);
				end
				self:SetTick(false);
				self.Cheater = nil;
				return;
			end
			if (info.timer == 0) then
				CryMP.Ent:PlaySound(playerId, "hq");
				nCX.ProcessEMPEffect(playerId, 2);
				nCX.ForbiddenAreaWarning(true, 0, playerId);
				if (not pos) then
					pos = player:GetWorldPos();
					pos.z = pos.z + 120;
				end
				CryMP.Ent:MovePlayer(player, pos, player:GetWorldAngles());
				CryMP.Library:Kill(player, 200);
				nCX.ParticleManager("misc.extremly_important_fx.celebrate", 3.75, pos, g_Vectors.up, 0);
			elseif (info.timer == 9) then
				nCX.RevivePlayer(playerId, pos or player:GetWorldPos(), player:GetWorldAngles(), nCX.GetTeam(playerId), false);
				CryMP.Ent:NukeTag(player, true);
			end
			if (g_gameRules.class == "PowerStruggle") then
				if (info.timer == 14) then
					self:GeneratePunishVehicle(info);
				elseif (info.timer == 19) then
					nCX.ParticleManager("explosions.TAC.Small", 6, player:GetWorldPos(), g_Vectors.up, 0);
					local vehicle = System.GetEntity(info.vehicleId);
					if (vehicle) then
						vehicle.vehicle:Destroy();
					end
					nCX.SendTextMessage(0, "CHEATER OWNED!", 0);
					CryMP.Msg.Chat:ToPlayer(channelId, "Nice try, cheater :)", self.Tag);
				elseif (info.timer == 21) then
					CryMP.BanSystem:PermaBan(player, info.cheat, info.Admin);
					info.banned = true;
				end
			elseif (info.timer == 10) then
				nCX.ParticleManager("explosions.TAC.Small", 6, player:GetWorldPos(), g_Vectors.up, 0);
			elseif (info.timer == 13) then
				CryMP.BanSystem:PermaBan(player, info.cheat, info.Admin);
				info.banned = true;
			end
			info.timer = info.timer + 1;
		else
			self:SetTick(false);
		end
	end,
	
	GeneratePunishVehicle = function(self, data)
		local classes = {"Asian_truck", "Asian_patrolboat",};
		local class = classes[math.random(#classes)];
		local params = {
			class = class,
			name = class.." "..data.name,
			position = self.truck[1],
			orientation = self.truck[2],
			properties = {
				Modification = "",
				Respawn = {
					bAbandon = 0,
					bRespawn = 0,
					bUnique = 1,
					nAbandonTimer = 0,
					nTimer = 0,
				},
			},
		};
		CryMP:Spawn(params, function(vehicle)
			if (vehicle) then
				data.vehicleId = vehicle.id;
				local pos = vehicle:GetWorldPos();
				nCX.ParticleManager("Alien_Weapons.singularity.Tank_Singularity_Spinup", 3, pos, g_Vectors.up, 0);
				nCX.ParticleManager("explosions.TAC.shockwave_smoke_lingering", 4, pos, g_Vectors.up, 0);
				nCX.ParticleManager("explosions.TAC.shockwave", 4, pos, g_Vectors.up, 0);
				vehicle:AddImpulse(-1, vehicle:GetCenterOfMassPos(), {x=0, y=0, z=1}, 30000000, 1);
				g_gameRules.allClients:ClTimerAlert(5);
				CryMP:SetTimer(0, function()
					vehicle:EnterVehicle(data.playerId, 3);
				end);
			end
		end);
	end,
	
	IsTruck = function(self, vehicleId)
		return self.Cheater and self.Cheater.vehicleId == vehicleId;
	end,
		
};
