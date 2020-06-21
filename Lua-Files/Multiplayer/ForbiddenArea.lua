-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach & Arcziy  
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-09-27
-- *****************************************************************
ForbiddenArea = {
	type = "ForbiddenArea",
	Properties = {
		bReversed = 1,
		DamagePerSecond = 35,
		Delay = 5,
		bShowWarning = 1,
		teamName = "",
	},
	Client = {},		
	Server = {
		---------------------------
		--		OnInit
		---------------------------
		OnInit = function(self)
			self.inside = {};
			self:OnReset();
		end,
		---------------------------
		--		OnEnterArea
		---------------------------		
		OnEnterArea = function(self, entity, areaId)
			if (entity.Info and not self.inside[entity.id]) then
				if (not self.teamId or self.teamId ~= nCX.GetTeam(entity.id)) then
					if (not self.reverse) then
						self.inside[entity.id] = self.delay;
						if (self.showWarning) then
							if (entity.actor:GetSpectatorMode()==0 and not entity:IsDead()) then
								nCX.ForbiddenAreaWarning(true, self.delay, entity.id);
								if (nCX.Count(self.inside) == 1) then
									nCX.UpdateObjectTimer(self.id, true);
								end
							end
						end
					else
						if (self.showWarning) then
							nCX.ForbiddenAreaWarning(false, 0, entity.id);
						end
					end
				end
			end
		end,
		---------------------------
		--		OnLeaveArea
		---------------------------		
		OnLeaveArea = function(self, entity, areaId)
			if (entity.actor) then
				if (not self.teamId or self.teamId ~= nCX.GetTeam(entity.id)) then
					if (self.reverse) then
						if (self.inside[entity.id]) then
							self.inside[entity.id] = self.delay;
							if (self.showWarning) then
								if (entity.actor:GetSpectatorMode()==0 and not entity:IsDead()) then
									nCX.ForbiddenAreaWarning(true, self.delay, entity.id);
								end
							end
						end
					else
						self.inside[entity.id] = nil;
						if (self.showWarning) then
							nCX.ForbiddenAreaWarning(false, 0, entity.id);
						end
						if (nCX.Count(self.inside) == 0) then
							nCX.UpdateObjectTimer(self.id, false);
						end
					end
				end
			end
		end,
	},
	---------------------------
	--		OnTimer
	---------------------------	
	OnTimer = function(self)
		if (not self.reverse) then
			for playerId, time in pairs(self.inside) do
				local player = nCX.GetPlayer(playerId);
				if (player and not player:IsDead() and nCX.IsPlayerInGame(playerId)) then
					if (not self.teamId or self.teamId ~= nCX.GetTeam(playerId)) then
						self:PunishPlayer(player);
					end
				end
			end
		else
			local players = nCX.GetPlayers();
			if (players) then
				for i, player in pairs(players) do
					if (not self:IsPlayerInside(player.id) and nCX.IsPlayerInGame(player.id)) then
						if (not self.teamId or self.teamId ~= nCX.GetTeam(player.id)) then
							self:PunishPlayer(player);
						end
					end
				end
			end
		end
	end,
	---------------------------
	--		OnPropertyChange
	---------------------------
	OnPropertyChange = function(self)
		self:OnReset();
	end,
	---------------------------
	--		PunishPlayer
	---------------------------
	PunishPlayer = function(self, player)
		if (nCX.GodMode(player.Info.Channel)) then
			self.Server.OnLeaveArea(self, player);
			return;
		end
		if (player.actor:GetSpectatorMode() ~= 0 or player:IsDead()) then
			return;
		end
		local warning = self.inside;
		if (warning[player.id] and warning[player.id] > 0) then
			warning[player.id] = warning[player.id] - 1;
		end
		warning[player.id] = warning[player.id] or self.delay;
		if (self.showWarning) then	
			nCX.ForbiddenAreaWarning(true, warning[player.id], player.id);
		end
		if (warning[player.id] <= 0) then
			nCX.ServerHit(player.id,player.id,self.dps * 0.5,"punish");
			--nCX.ProcessEMPEffect(player.id, 1);
		end
	end,
	---------------------------
	--		OnSave
	---------------------------
	OnSave = function(self, svTbl)
		svTbl.inside = self.inside;
	end,
	---------------------------
	--		OnLoad
	---------------------------
	OnLoad = function(self, svTbl)
		self:OnReset();
		self.inside = svTbl.inside;
	end,
	---------------------------
	--		OnReset
	---------------------------
	OnReset = function(self)
		self.reverse = tonumber(self.Properties.bReversed) ~= 0;
		self.delay = tonumber(self.Properties.Delay);
		self.dps = tonumber(self.Properties.DamagePerSecond);
		self.showWarning = tonumber(self.Properties.bShowWarning) ~= 0;
		if (self.Properties.teamName ~= "") then
			self.teamId = nCX.GetTeamId(self.Properties.teamName);
			if (self.teamId == 0) then
				self.teamId = nil;
			end
		end
	end,
	---------------------------
	--		IsPlayerInside
	---------------------------
	IsPlayerInside = function(self, playerId)
		return self.inside[playerId] or false;
	end,
};