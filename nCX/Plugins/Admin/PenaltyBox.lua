PenaltyBox = {
     
	---------------------------
	--		Config
	---------------------------
    Tick 			= 1,
	Tag 			= 9,
	MsgTag			= "[ PENALTY:BOX ]",
	Data 			= {},
	
	Server = {
	
		OnGiveItem = function(self, player, item)
			local data = self.Data[player.Info.ID];
			if (data) then
				System.RemoveEntity(item.id);
			end
		end,
	
		CanEnterVehicle = function(self, vehicle, player)
			local data = self.Data[player.Info.ID];
			if (data) then
				CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "Access denied!", self.Tag);
				self:Punish(player.id, data.duration);
				return true, {false};
			end
		end,
		
		OnDisconnect = function(self, channelId, player, profileId)
			local data = self.Data[profileId];
			if (data) then
				self:Remove(player, "user disconnected");
			end
		end,
		
		OnChangeTeam = function(self, player, teamId)
			local data = self.Data[player.Info.ID];
			if (data) then
				CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "Access denied!", self.Tag);
				return true;
			end
		end,
		
		OnChangeSpectatorMode = function(self, player, mode)
			local data = self.Data[player.Info.ID];
			if (data) then
				CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "Access denied!", self.Tag);
				return true;
			end
		end,

	},
	
	OnShutdown = function(self, restart)
		for profileId, data in pairs(self.Data) do
			local player = nCX.GetPlayerByProfileId(profileId);
			if (player) then
				self:Remove(player);
			end
		end
	end,
	
	Add = function(self, player, duration, msg, extended)
		if (nCX.IsPlayerActivelyPlaying(player.id)) then
			g_gameRules:KillPlayer(player);
		end
		local adjust = duration < 1 and "minimum length of one minute" or duration > 10 and "maximum length of ten minutes";
		if (adjust) then
			self:Log("Adjusted duration to "..adjust, true);
		end
		local duration = math.max(1, math.min(math.floor(duration), 10));
		if (extended) then
			CryMP:GetPlugin("Mute", function(self)
				self:Add(player, duration);
			end);
			g_gameRules:ResetScore(player.id);
			g_gameRules:ResetPP(player.id);
			g_gameRules:ResetCP(player.id);
		end
		self.Data[player.Info.ID] = {
			message = msg,
			duration = 60 * duration,
			Extended = extended,
			Inventory = CryMP.Ent:DumpInventory(player);
		};
		local name = player:GetName();
		local vehicle = player.actor:GetLinkedVehicle();
		if (vehicle and vehicle.vehicle:GetOwnerId() == player.id) then
			vehicle.vehicle:SetOwnerId(NULL_ENTITY);
		end
		local ext = extended and ", extended)" or ")";
		nCX.SendTextMessage(2, self.MsgTag.." Punishing player "..name.." for "..duration.." minutes ("..msg..ext, 0);
		self:Log("Punishing player "..name.." for "..duration.." minutes ("..msg..ext);
		nCX.Log("Player", "Punishing player "..name.." for "..duration.." minutes ("..msg..ext);
		return true;
	end,

	Remove = function(self, player, reason)
		local name = player:GetName();
		local profileId = player.Info.ID;
		local data = self.Data[profileId];
		if (data) then
			if (CryMP.Mute and self.Data[profileId].Extended) then
				CryMP.Mute:Remove(player);
			end
			local inventory = data.Inventory;
			CryMP.Ent:Revive(player, inventory);
			self.Data[profileId] = nil;
			if (reason) then
				nCX.SendTextMessage(2, self.MsgTag.." Removed "..name.." from the penalty box ("..reason..")", 0);
				self:Log("Removed "..name.." from the penalty box ("..reason..")");
				nCX.Log("Player", "Removed "..name.." from the penalty box ("..reason..")");
			end
			if (nCX.Count(self.Data) == 0) then
				return self:ShutDown(true)
			end
			return true;
		end
		return false, "player is not in penalty box";
	end,

	OnTick = function(self)
		for profileId, data in pairs(self.Data) do
			local player = nCX.GetPlayerByProfileId(profileId);
			data.duration = data.duration - self.Tick;
			if (data.duration <= 0) then
				self:Remove(player, "timeout");
			elseif (player) then
				local count = player.inventory:GetCount();	
				if (count > 0) then
					self:Punish(player.id, data.duration)
					player.inventory:Destroy();
				end
				nCX.SendTextMessage(0, "PENALTY BOX ["..data.duration.." seconds left]: "..data.message, player.Info.Channel);
			end
		end
	end,

	Punish = function(self, playerId, time)
		nCX.ProcessEMPEffect(playerId, time/15);
	end,
		
};
