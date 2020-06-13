SquadLeader = {

	---------------------------
	--		Config
	---------------------------
	Tag		 	= 20,
	
	Stats = {
		[1]	= 0,
		[2] = 0,
	},
	
	Server = {
		
		OnDisconnect = function(self, channelId, player)
			self:Disable(player, "disconnected");					
		end,
					
		OnKill = function(self, hit, shooter, target)
			self:Disable(target, "has been killed");
		end,
		
		OnChangeTeam = function(self, player, teamId, oldTeamId)
			if (oldTeamId == 0) then
				if (nCX.GetPlayerCount() > 2) then
					local newId = teamId == 1 and 2 or 1;
					if (self.Stats[newId] == 0) then
						local diff = nCX.GetTeamPlayerCount(teamId) - nCX.GetTeamPlayerCount(newId);
						if (diff == 1 and player:GetAccess() < 3) then
							local team = CryMP.Ent:GetTeamName(newId):upper();
							g_gameRules:AwardPPCount(player.id, 1000);
							CryMP.Msg.Chat:ToPlayer(player.Info.Channel, team.." Team needs your help - 1000 PP extra Start Bonus", self.Tag); 
							self:Log("Changing player "..player:GetName().."'s Team request to "..team.." Team");
							return false, {player, newId};
						end
					end
				end
			else	
				self:Disable(player, "changed team");	
			end
		end,
		
		OnChangeSpectatorMode = function(self, player)
			self:Disable(player, "went spectating");
		end,

		OnRevive = function(self, channelId, player, group, first)
			if (self.RequestMobilize) then
				local teamId = nCX.GetTeam(player.id);
				if (teamId == self.RequestMobilize) then
					self:Enable(teamId, player, true);
					return;
				end
			end
			if (group and group.actor and player.id ~= group.actor.id) then
				g_gameRules:AwardPPCount(player.id, 10);	
				if (not self.Last_Effect or _time - self.Last_Effect > 5) then
					local pos = group:GetPos();
					if (g_gameRules.inCaptureZone and g_gameRules.inCaptureZone[group.id]) then
						pos.z = pos.z + 100;
					end						
					nCX.ParticleManager("alien_special.Hunter.Pre_Self_Destruct_body", 1, pos, g_Vectors.up, 0); 
					self.Last_Effect = _time;							
				end
			end
		end,
		
		OnCapture = function(self, zone, teamId, inside)
			if (zone.class == "SpawnGroup" and self.Stats[teamId]) then
				self.Stats[teamId] = self.Stats[teamId] + 1;
				local data = self.SqaudLeader;
				local defaultId = nCX.GetTeamDefaultSpawnGroup(teamId);
				local players = nCX.GetTeamPlayers(teamId);
				if (data and self.Stats[teamId] == 1) then
					if (data.PlayerId) then
						nCX.RemoveSpawnGroup(data.PlayerId);
					end
					self:SetTick(false);
					self.SqaudLeader = nil;
					self.RequestMobilize = nil; 
					System.LogAlways("[SqaudLeader] Team "..teamId.." has gathered a bunker!");
					local soldiers;
					for i, player in pairs(players or {}) do
						if (g_gameRules.inCaptureZone[player.id] == zone.id and nCX.IsPlayerActivelyPlaying(player.id)) then
							CryMP.Library:Pay(player, 1000);
							if (not soldiers) then
								soldiers = player:GetName();
							else
								soldiers = soldiers..", "..player:GetName();
							end
						else
							CryMP.Library:Pay(player, 250, 0, true);
						end
						local spawnId = g_gameRules:GetPlayerSpawnGroup(player.id);
						if (spawnId == defaultId or spawnId == NULL_ENTITY) then
							g_gameRules.Server.RequestSpawnGroup(g_gameRules, player.id, zone.id); -- select captured bunker for whole team 
						end
					end
					if (soldiers) then
						CryMP.Msg.Chat:ToTeam(teamId, "BUNKER CAPTURED > > > 1000 BONUS-PP to ("..soldiers..")", self:GetTagId(teamId));
						self:Log("Team "..CryMP.Ent:GetTeamName(teamId).." has gathered a bunker!");
					end
				else
					for i, player in pairs(players or {}) do
						if (g_gameRules.inCaptureZone[player.id] == zone.id) then
							local spawnId = g_gameRules:GetPlayerSpawnGroup(player.id);
							if (spawnId == defaultId or spawnId == NULL_ENTITY) then
								g_gameRules.Server.RequestSpawnGroup(g_gameRules, player.id, zone.id); -- select captured bunker for guys who spawn in base
							end
						end
					end
				end
			end
		end,
		
		OnUncapture = function(self, zone, teamId, oldTeamId) 
			if (zone.class == "SpawnGroup" and self.Stats[oldTeamId]) then
				self.Stats[oldTeamId] = self.Stats[oldTeamId] - 1;
				if (self.Stats[oldTeamId] == 0 and self.Stats[teamId] ~= 0) then
					CryMP:SetTimer(15, function()
						if (self.Stats[oldTeamId] == 0 and self.Stats[teamId] ~= 0) then
							self:Mobilize(oldTeamId);
						end
					end);
				end
			end
		end,
		
		PreHit = function(self, hit, shooter, target)
			if (not hit.server and self.SqaudLeader) then
				if (target and target.actor and self.SqaudLeader.PlayerId == target.id) then
					hit.damage = hit.damage * 0.5;
					return false, {hit, target};
				end
			end
		end,
			
	},
	
	OnInit = function(self, restart)
		if (not restart) then
			local SpawnGroups = System.GetEntitiesByClass("SpawnGroup");
			for i, bunker in pairs(SpawnGroups or {}) do
				local teamId = nCX.GetTeam(bunker.id);
				if (self.Stats[teamId] and not bunker.default and not bunker.vehicle) then
					self.Stats[teamId] = self.Stats[teamId] + 1;
				end
			end		
		end
	end,
	
	OnShutdown = function(self, restart) 
		if (not restart) then
			local mobile = self.SqaudLeader;
			if (mobile) then
				local mobileId = mobile.PlayerId;
				nCX.RemoveSpawnGroup(mobileId);
			end
		end
	end,
	
	OnTick = function(self, tick)
		local mobile = self.SqaudLeader;
		if (mobile) then
			local teamId, mobileId = mobile.TeamId, mobile.PlayerId;
			local players = nCX.GetTeamPlayers(teamId);
			if (players) then
				local mobile = nCX.GetPlayer(mobileId);
				if (mobile) then
					for i, player in pairs(players) do
						if (player.id == mobileId) then	
							local vehicle = player.actor:GetLinkedVehicle();
							if (vehicle) then
								nCX.SendTextMessage(3, "[ SQUAD:LEADER ]- Team players may spawn in your "..CryMP.Ent:GetVehicleName(vehicle.class), mobile.Info.Channel);
							else
								nCX.SendTextMessage(3, "[ SQUAD:LEADER ]- Team players may spawn nearby", mobile.Info.Channel);
							end
						else
							nCX.SendTextMessage(3, "[ iNFO ]- SQUAD LEADER active -[ "..mobile:GetName().." ]", player.Info.Channel);
						end
					end
				else
					self:Disable(false, "disconnected");	
				end
			end
		end
	end,
		
	Mobilize = function(self, teamId, new, ignoreId)
		local previousId = self.SqaudLeader and self.SqaudLeader.PlayerId;
		self.SqaudLeader = nil;
		local players = nCX.GetTeamPlayers(teamId);
		local closest, mostCP;
		if (players) then
			local groups = System.GetEntitiesByClass("SpawnGroup");
			for i, player in pairs(players) do
				if (ignoreId ~= player.id and nCX.IsPlayerActivelyPlaying(player.id) and not player:IsBoxing() and not player:IsDuelPlayer() and not player:IsRacing() and not player:IsAfk()) then
					local distance = 5000;
					for i, bunker in pairs(groups or {}) do
						if (not bunker.default and not bunker.vehicle) then
							distance = math.min(distance, player:GetDistance(bunker.id))
						end
					end
					if (not closest or distance < closest[2]) then
						closest = {player, distance};
					end	
					local cp = g_gameRules:GetPlayerCP(player.id);
					if (not mostCP or cp > mostCP[2]) then
						mostCP = {player, cp};
					end						
				end
			end
			local mobile = (closest and closest[1]) or (mostCP and mostCP[1]);		
			if (mobile) then
				self:Enable(teamId, mobile, new);
				--local defaultId = nCX.GetTeamDefaultSpawnGroup(teamId);
				--[[
				for i, player in pairs(players) do
					local spawnId = g_gameRules:GetPlayerSpawnGroup(player.id);
					if (spawnId == NULL_ENTITY or spawnId == previousId) then
						g_gameRules.Server.RequestSpawnGroup(g_gameRules, player.id, mobile.id); 
						--CryMP.Ent:PlaySound(player.id, "work");
					end
				end
				]]
				return mobile.id;
			end
		end			
	end,
	
	Enable = function(self, teamId, player, new)
		if (nCX.GetTeamPlayerCount(teamId) > 2) then
			nCX.AddSpawnGroup(player.id);
			self.SqaudLeader = {TeamId = teamId, PlayerId = player.id};
			local msg = player:GetName().." is the "..(new and "new " or "").."Squad Leader";
			CryMP.Msg.Chat:ToTeam(teamId, msg.."!", self:GetTagId(teamId));
			self:Log(msg);
			self.RequestMobilize = nil;
			self:SetTick(30);
		end
	end,	
	
	Disable = function(self, player, msg)
		if (self.SqaudLeader and (not player or player.id == self.SqaudLeader.PlayerId)) then
			nCX.RemoveSpawnGroup(self.SqaudLeader.PlayerId);
			local teamId = self.SqaudLeader.TeamId;
			if (msg ~= "has been killed" and player) then
				CryMP.Msg.Chat:ToTeam(teamId, "Our SQUAD:LEADER "..player:GetName().." "..msg.."!", self:GetTagId(teamId)); 
			end
			local mobileId = self:Mobilize(teamId, true, player and player.id);
			if (not mobileId) then
				self.RequestMobilize = teamId;
				self:SetTick(false)
			end
		end
	end,

	GetTagId = function(teamId)
		return teamId == 2 and 19 or 18;
	end,
	
};
