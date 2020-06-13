MessageSpam = {
	
	---------------------------
	--		Config
	---------------------------
	Tick = 60,
	Index = {},
	
	Server = {
		
		OnDisconnect = function(self, channelId)
			self.Index[channelId] = nil;
		end,
	
	},
	
	GetMessageTable = function(self, channelId, access)
		self.Index[channelId] = self.Index[channelId] or {};
		local access = math.min(2, access);
		local v = {access, -1, -2};
		self.Index[channelId]["L"] = (self.Index[channelId]["L"] or 0) + 1;
		if (self.Index[channelId]["L"] > #v) then
			self.Index[channelId]["L"] = 1;
		end
		local value = v[self.Index[channelId]["L"]];
		return self.Config[value], value;
	end,
	
	OnTick = function(self, players)
		for i, player in pairs(players) do
			if (nCX.IsPlayerActivelyPlaying(player.id) and not player:IsAfk()) then
				local profileId, channelId = player.Info.ID, player.Info.Channel;
				local access = player:GetAccess();
				local tbl, value = self:GetMessageTable(channelId, access);
				self.Index[channelId][value] = (self.Index[channelId][value] or 0)  + 1;
				local last = self.Index[channelId][value];
				local msg = tbl[last];
				if (not msg) then
					msg = tbl[1];
					self.Index[channelId][value] = 1; --reset
				end
				if (msg) then
					if (type(msg) == "string") then
						msg = loadstring(msg);
					end
					if (msg) then
						msg = msg(player);
					end
				end
				local display = "";
				if (access > 2) then
					local mask = CryMP.Users:GetMask(profileId);
					--if (nCX.AdminSystem(channelId)) then
						display = mask.." : "..CryMP.Users:GetName(profileId).."";
					--else
					--	display = mask.." Account : Server Authentification failed";
					--	msg = "";
					--end
				elseif (access == 2) then
					display = "Moderator : "..CryMP.Users:GetName(profileId);
				elseif (access == 1) then
					display = "Premium : "..CryMP.Users:GetName(profileId);
				elseif (access == 0) then
					local map = nCX.GetCurrentLevel():sub(16, -1);
					--if (map == "refinery" or map == "dsg_1_aim" or nCX.ProMode) then
						display = "Player";
					--else				
					--	local time = CryMP.PermaScore and CryMP.PermaScore.Premium or 3600;
					--	local hours, mins = CryMP.Math:ConvertTime((time - player:GetPlayTime()), 60);
					--	display = math:zero(hours).."h : "..math:zero(mins).."m to Premium Membership";
					--end
				end
				if (msg) then
					local type = 4;
					if (not CryMP.PermaScore) then
						type = 3;
					end
					local client_func
					if (access == 0) then
						client_func = 'HUD.BattleLogEvent(eBLE_Information, "'..msg..'");';
					else
						client_func = 'HUD.BattleLogEvent(eBLE_Information, "('..display..') '..msg..'");';
					end
					--nCX.SendTextMessage(type, "("..display..") "..msg, channelId);
					g_gameRules.onClient:ClWorkComplete(player.Info.Channel, player.id, "EX:"..client_func);
				end
			end
		end
	end,
};
