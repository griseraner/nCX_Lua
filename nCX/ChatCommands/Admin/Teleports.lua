--==============================================================================
--!HIJACK

CryMP.ChatCommands:Add("hijack", {
		Access = 3, 
		Info = "hijack a players vehicle", 
		Args = {
			{"player", GetPlayer = true,},
			{"force", Optional = true, Output = {{"force", "Force exit",},},},
		},
		self = "Vehicles",
	}, 
	function(self, player, channelId, target, force)
		if (player == target) then
			return false, "you cannot hijack yourself"
		elseif (target:IsDuelPlayer()) then
			return false, "target is in a duel - use revive command"
		elseif (target:IsBoxing()) then
			return false, "target is boxing"
		end
		return self:Hijack(player, target.actor:GetLinkedVehicle(), force);
	end
);

--==============================================================================
--!BRING

CryMP.ChatCommands:Add("bring", {
		Access = 2,
		Info = "teleport a player to your location",
		Args = {
			{"player", GetPlayer = true,},
			{"seat", Optional = true, Output = {{"seat", "Enter the vehicle seat",},},},
		},
	},
	function(self, player, channelId, target, seat)
		if (target:IsDuelPlayer()) then
			return false, "target is in a duel", "Use !revive command";
		elseif (target:IsBoxing()) then
			return false, "target is boxing";
		elseif (target:IsRacing()) then
			return false, "target is racing";
		elseif (target:IsAfk()) then
			return false, "target is afk", "Use !revive command";
		end
		local tname = target:GetName();
		if (seat) then
			local ok;
			local vehicle = player.actor:GetLinkedVehicle();
			if (not vehicle) then
				local vehicleId, time = player.actor:GetLastVehicle();
				vehicle = vehicleId and System.GetEntity(vehicleId);
				if (not vehicle) then
					local vehicleId = target.actor:GetLastVehicle();
					vehicle = vehicleId and System.GetEntity(vehicleId);
					if (not vehicle) then
						return false, "no vehicle of your or targets owner id found";
					end
				end
			end
			if (vehicle and not CryMP:IsServerVehicle(vehicle.id)) then
				if (nCX.IsPlayerActivelyPlaying(target.id)) then
					ok = vehicle:MoveToFreeSeat(target.id);
				else
					g_gameRules:RevivePlayer(target, vehicle.id);
					ok = (target.actor:GetLinkedVehicle() == vehicle);
				end
				if (not ok) then
					return false, "no seat free";
				end
			else
				return false, "no vehicle of your or targets owner-id found";
			end
		else
			local tgtpos, tgtdir = CryMP.Library:CalcSpawnPos(player, 2);
			nCX.SetInvulnerability(target.id, true, 2);
			local vehicle = target.actor:GetLinkedVehicle();
			if (vehicle) then
				nCX.SendTextMessage(0, "Forced "..CryMP.Ent:GetVehicleName(vehicle.class).." boot on "..tname, channelId);
			end
			CryMP.Ent:MovePlayer(target, tgtpos, {x = 0, y = 0, z = math.atan2(tgtdir.y, tgtdir.x)-g_Pi2}, true);
		end
		if (player.id ~= target.id) then
			CryMP.Msg.Chat:ToPlayer(channelId, "You brought "..tname.." to your "..(seat and "vehicle" or "location").."...");
			CryMP.Msg.Chat:ToPlayer(target.Info.Channel, "Admin "..player:GetName().." brought you to his "..(seat and "vehicle" or "location").."..");
		elseif (seat) then
			CryMP.Msg.Chat:ToPlayer(channelId, "You brought yourself to last exited vehicle...");
		end
		nCX.ParticleManager("explosions.light.portable_light", 1, target:GetPos(), g_Vectors.up, 0);
		return true;
	end
);

--==============================================================================
--!GOTO

CryMP.ChatCommands:Add("goto", {
		Access = 2, 
		Info = "teleport behind a player", 
		Args = {
			{"player", GetPlayer = true,},
			{"seat", Optional = true, Output = {{"seat", "Enter the vehicle seat",},},},
		},
	}, 
	function(self, player, channelId, target, seat)
		local dead = not nCX.IsPlayerActivelyPlaying(player.id);
		if (nCX.IsNeutral(player.id) and dead) then
			return false, "must be alive as neutral player";
		elseif (target.actor:GetSpectatorMode() ~= 0) then
			return false, "target player "..target:GetName().." is spectating";
		elseif (target:IsBoxing()) then
			CryMP.Boxing.Boxers[channelId] = (CryMP.Boxing.Boxers[channelId] or 0) + 1;
		end
		local tchannelId = target.Info.Channel;
		local name, tname = player:GetName(), target:GetName();
		if (seat) then
			local ok;
			--[[local vehicle = target.actor:GetLinkedVehicle();
			if (not vehicle) then
				local vehicleId = target.actor:GetLastVehicle();
				vehicle = vehicleId and System.GetEntity(vehicleId);
				if (not vehicle) then
					return false, "target has no vehicle"
				end
			end]]
			local vehicle = CryMP:GetPlugin("Vehicles", function(self) return self:CanLock(target); end);
			if (vehicle) then
				if (dead) then
					g_gameRules:RevivePlayer(player, vehicle.id);
					ok = (player.actor:GetLinkedVehicle() == vehicle);
				else
					ok = vehicle:MoveToFreeSeat(player.id);
				end
				if (ok) then
					if (player.id == target.id) then
						CryMP.Msg.Chat:ToPlayer(channelId, "You went to your last exited vehicle...");
					else
						CryMP.Msg.Chat:ToPlayer(tchannelId, name.." has entered your vehicle...", 1);
						CryMP.Msg.Chat:ToPlayer(channelId, "You went to "..tname.."'s vehicle...");
					end
				else
					return false, "no seat free";
				end
			else
				return false, "target has no vehicle";
			end
		elseif (player.id == target.id) then
			return false, "you cannot go to yourself";
		else
			local tgtpos, tgtdir = CryMP.Library:CalcSpawnPos(target, -2);
			nCX.SetInvulnerability(player.id, true, 2);
			CryMP.Ent:MovePlayer(player, tgtpos, {x = 0, y = 0, z = math.atan2(tgtdir.y, tgtdir.x)-g_Pi2}, true);
			if (CryMP.Users:HasAccess(target.Info.ID, 3)) then
				CryMP.Msg.Chat:ToPlayer(tchannelId, "Visit for you by "..name.."...", 1);
			end
			CryMP.Msg.Chat:ToPlayer(channelId, "You went to "..tname.."'s location...");
		end
		nCX.ParticleManager("explosions.light.portable_light", 1, target:GetPos(), g_Vectors.up, 0);
		return true;
	end
);

--==============================================================================
--[[!TELEPORT

CryMP.ChatCommands:Add("teleport", {
		Access = 4, 
		Info = "go to a location on the map", 
		Args = {
			{"x", Number = true,},
			{"y", Number = true,},
			{"z", Number = true,},
		}, 
	}, 
	function(self, player, channelId, x, y, z)
		nCX.SetInvulnerability(player.id, true, 2);
		CryMP.Ent:MovePlayer(player, {x = x, y = y, z = z}, player:GetWorldAngles(), true);
		return true;
	end
);]]

--==============================================================================
--!POS

CryMP.ChatCommands:Add("pos", {
		Access = 4, 
		Args = {
			{"type", Output = {{"save", "Save your position",},{"load", "Load your saved position",},},},
			{"player", Optional = true, GetPlayer = true, Info = "Select another player to load his position"},
		}, 
		Info = "save or load your last position", 
	}, 
	function(self, player, channelId, mode, target)
		if (mode == "save") then
			self.LastPos[player.id] = player:GetPos();
		    CryMP.Msg.Chat:ToPlayer(channelId, "Your last position has been updated!");
		    return true;
		elseif (mode == "load") then
			local pos = self.LastPos[player.id];
			if (target) then
				if (type(target) == "table") then
					pos = self.LastPos[target.id];
					if (not pos) then
						return false, "no position found for target"
					end
				else
					return false, "target not found"
				end
			end
			if (not pos) then
				return false, "no position saved"
			end
			local pos = {pos.x, pos.y, pos.z+1};
			--g_gameRules:CreateExplosion(player.id,nil,0,player:GetPos(),g_Vectors.up,1,1,1,1,"explosions.light.portable_light",1, 1, 1, 1);
			nCX.SetInvulnerability(player.id, true, 3);
			CryMP.Ent:MovePlayer(player, pos, player:GetWorldAngles(), true);
			return true;
		end
	end
);
