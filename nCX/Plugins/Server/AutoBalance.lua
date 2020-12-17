AutoBalance = {
	
	---------------------------
	--		Config
	---------------------------
	Tag 				= 12,
	Changed 			= {},
	
	Server = {
	
		OnKill = function(self, hit, shooter, target)
			if (self.Active and not hit.server) then
				local mostId, leastId = self:GetMaxTeamId();
				if (leastId and nCX.GetTeam(target.id) == mostId) then
					CryMP:SetTimer(1, function()
						if (self:GetMaxTeamId()) then
							self:CheckPlayer(target, leastId);	
						end
					end);
				end
			end
		end,
	
		OnChangeSpectatorMode = function(self, player) 
			local channelId = player.Info.Channel; 
			local passed = self.Changed[channelId] and _time - self.Changed[channelId]; 
			local time = (60 * 2); 
			if (passed and passed < time) then 
				local mins, secs = CryMP.Math:ConvertTime(time - passed, 60); 
				CryMP.Msg.Chat:ToPlayer(channelId, "Cannot change to Spectator mode ("..math:zero(mins).." min : "..math:zero(secs).." sec left)", self.Tag); 
				return true; 
			else 
				self:Scan(); 
			end 
		end,
		
		OnChangeTeam = function(self, player, teamId, oldTeamId)
			if (self.Active and not self:GetMaxTeamId()) then
				self:End();
			else
				local channelId = player.Info.Channel; 
				local passed = self.Changed[channelId] and _time - self.Changed[channelId]; 
				local time = (60 * 2); 
				if (passed and passed < time) then 
					local mins, secs = CryMP.Math:ConvertTime(time - passed, 60); 
					CryMP.Msg.Chat:ToPlayer(channelId, "Cannot change Teams ("..math:zero(mins).." min : "..math:zero(secs).." sec left)", self.Tag); 
					return true; 
				end 
			end
		end,
		
		OnDisconnect = function(self, channelId, player, profileId)
			self.Changed[channelId] = nil;
			self:Scan();
		end,
		
	},
	
	OnShutdown = function(self, restart) 
		if (not restart) then
			if (self.Active) then
				--CryMP.Msg.Chat:ToAccess(2, "Canceled...", self.Tag);
			end
		end
	end,
	
	Scan = function(self)
		local mostId, leastId, diff = self:GetMaxTeamId();
		if (mostId) then
			local players = nCX.GetPlayers();
			if (not self.Active and players) then
				self.Active = true;
				nCX.Log("Player", "Auto Team Balance starting...");
			end
			if (not self.Active) then 
				return;
			end
			local force = diff > 2 and #players < 8; 
			local skillDiff = self:GetStatistics(players, mostId, leastId); 
			local inactive, active = self:CategoryPlayers(players, mostId, force); 
			local sort = function(p1, p2)
				if (skillDiff > 0) then	-- one team is stronger than the other
					return (math.abs(self:GetSkill(p1) - skillDiff) < math.abs(self:GetSkill(p2) - skillDiff)); -- find player who would balance the skill gap the best
				else 					
					return (p1:GetPlayTime(p1, true) < p1:GetPlayTime(p2, true))  -- else we want to prioritize the players with lowest playtime
				end
			end
			if (inactive) then
				if (#inactive > 1) then 
					table.sort(inactive, sort);
					for i, player in ipairs(inactive) do
						if (self:CheckPlayer(player, leastId, true, force)) then
							return;
						end
					end
				elseif (self:CheckPlayer(inactive[1], leastId, false, force)) then
					return;
				end
			end
		end
	end,
			
	CategoryPlayers = function(self, players, mostId, force)
		local p, a;
		for i, player in pairs(players) do
			if (player:GetAccess() < 3) then
				local teamId = nCX.GetTeam(player.id);
				if (teamId == mostId or (force and teamId == 0)) then
					if (not nCX.IsPlayerActivelyPlaying(player.id) or force) then
						p = p or {};
						p[#p + 1] = player;
					else
						a = a or {};
						a[#a + 1] = player;
					end
				end
			end
		end
		return p, a;
	end,
	
	GetStatistics = function(self, players, mostId, leastId)
		local stats = {0, 0,};
		for i, player in pairs(players) do
			local teamId = nCX.GetTeam(player.id);
			if (teamId ~= 0 --[[ and not player:IsDuelPlayer() and not player:IsBoxing() and not player:IsAfk()]]) then
				stats[teamId] = stats[teamId] + self:GetSkill(player);
			end
		end
		return stats[mostId] - stats[leastId];
	end,
		
	GetSkill = function(self, player)
		local kills = (nCX.GetSynchedEntityValue(player.id, 100) or 1);
		local deaths = (nCX.GetSynchedEntityValue(player.id, 101) or 1);
		local kdr = math.min(5, math.max(1, kills) / math.max(1, deaths));
		local rank = (g_gameRules.GetPlayerRank and g_gameRules:GetPlayerRank(player.id)) or 1;
		local hit_accuracy_avrg = player.actor:GetHitAccuracyAverage() / 100; -- 0 - 1
		return (kdr * math.max(1, rank)) * hit_accuracy_avrg;
	end,
	
	CheckPlayer = function(self, player, dstId, multiple, force)
		if (player:GetPlayTime(true) < 60) then
			if (not self.Changed[player.Info.Channel] and not player:IsDuelPlayer() and not player:IsBoxing() and not player:IsAfk() and not player:IsRacing()) then
				local dstTeam = CryMP.Ent:GetTeamName(dstId):upper();
				local name = player:GetName();
				local channelId = player.Info.Channel;
				local typ = "";
				if (multiple) then
					typ = " (Calculated Balance)";
				end
				self:Log("Switching player "..name.." to Team "..dstTeam..typ);
				CryMP.Msg.Error:ToOther(channelId, "[ TEAM:BALANCE ] Moved "..name.." to Team "..dstTeam, self.Tag);
				CryMP.Msg.Chat:ToPlayer(channelId, "You were moved to Team "..dstTeam..typ, self.Tag);
				nCX.Log("Player", "Auto Team Balance moved player "..name.." to Team "..dstTeam..typ);
				CryMP.Library:Team(player, dstId, true);
				self.Changed[channelId] = _time;
				if (not self:GetMaxTeamId()) then
					self:End();
					return true;
				end
			end
		end
	end,
	
	ChangedRecenctly = function(self, channelId, remove)
		local last = self.Changed[channelId];
		if (last and _time - last < (60 * 15)) then
			return true;
		end
	end,
	
	GetMaxTeamId = function(self)
		local nk = nCX.GetTeamPlayerCount(1);
		local us = nCX.GetTeamPlayerCount(2);
		local diff = math.abs(nk - us);
		if (diff >= 2) then
			if (us > nk) then
				return 2, 1, diff;
			end
			return 1, 2, diff;
		end
	end,

	End = function(self, silent)
		if (self.Active) then
			self.Active = nil;
			--if (not silent or nCX.GetPlayerCount() > 2) then
			--	CryMP.Msg.Chat:ToAll("Finished...", self.Tag);
			--end
			nCX.Log("Player", "Auto Team Balance finished...");
		end
	end,

};
