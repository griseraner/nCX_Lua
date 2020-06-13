Mute = {
	
	---------------------------
	--		Config
	---------------------------
	Tick			 = 1,
	NameTag 		 = "[MUTE]-",
	Tag 			 = 10,
	MsgTag     		 = "[ MUTE ]",
	Data 			 = {},
	
	Server = {
		
		OnChatMessage = function(self, type, player, command, msg)
			local profileId = player.Info.ID;
			local data = self.Data[profileId];
			if (data) then
				if not (player:GetAccess() > 1 and command and #command > 0) then
					self:Log("Blocked Chat '$4"..msg.."$9' from "..data[2], true);
					local remaining = self:GetRemainingTimeMessage(data[1]);
					CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "You are muted ("..remaining.." left)", self.Tag);
					CryMP.Ent:PlaySound(player.id, "error");
					return true;
				end
			end
		end,
			
		OnRadioMessage = function(self, player, msg)
			local profileId = player.Info.ID;
			local data = self.Data[profileId];
			if (data) then
				self:Log("Blocked Radio Command from "..data[2], true);
				local remaining = self:GetRemainingTimeMessage(data[1]);
				CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "You are muted ("..remaining.." left)", self.Tag);
				CryMP.Ent:PlaySound(player.id, "error");
				return true;
			end
		end,
	
	},
	
	OnShutdown = function(self, players, restart)
		for profileId, data in pairs(self.Data) do
			local player = nCX.GetPlayerByProfileId(profileId);
			if (player) then
				self:Remove(player, false, true)
			end
		end
	end,
		
	Add = function(self, player, duration)
		if (not self.Data[player.Info.ID]) then
			local name = player:GetName();
			if (duration < 1) then
				self:Log("Adjusted duration to minimum length of one minute", true);
			end
			local duration = math.max(1, math.ceil(duration));
			self.Data[player.Info.ID] = {duration * 60, name};
			nCX.SendTextMessage(2, self.MsgTag.." Muting player "..name.." for "..duration.." minutes", 0);
			self:Log("Muting player "..name.." for "..duration.." minutes");
			nCX.Log("Player", "Muting player "..name.." for "..duration.." minutes.");
			nCX.RenamePlayer(player.id, self.NameTag..name);
			return true;
		end
		return false, "player already muted";
	end,

	Remove = function(self, player, reason, shutdown)
		if (self.Data[player.Info.ID]) then
			local old = CryMP.Ent:RemoveTag(player:GetName(), self.NameTag, player.id);
			nCX.RenamePlayer(player.id, old);
			self.Data[player.Info.ID] = nil;
			if (reason) then
				nCX.SendTextMessage(2, self.MsgTag.." Unmuted "..old.." ("..reason..")", 0);
				self:Log("Unmuted "..old.." ("..reason..")");
				nCX.Log("Player", "Unmuted "..old.." ("..reason..")");
			end
			if (not shutdown and nCX.Count(self.Data) == 0) then
				self:ShutDown(true);
			end
			return true;
		end
		return false, "player not muted";
	end,

	OnTick = function(self)
		for profileId, data in pairs(self.Data) do
			data[1] = data[1] - self.Tick;
			if (data[1] <= 0) then
				local player = nCX.GetPlayerByProfileId(profileId);
				if (player) then
					self:Remove(player, "timeout");
				end
			end
		end
	end,
	
	GetRemainingTimeMessage = function(self, duration)
		local mins, secs = CryMP.Math:ConvertTime(duration, 60);
		return math:zero(mins).." min : "..math:zero(secs).." sec";
	end,

};
