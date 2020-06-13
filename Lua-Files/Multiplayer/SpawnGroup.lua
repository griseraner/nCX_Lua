-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   ctaoistrach und NiggaZerstörer
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2013-02-06
-- *****************************************************************
SpawnGroup = {
	Client = {
		ClStartCapture      = function() end,
		ClCancelCapture     = function() end,
		ClStepCapture       = function() end,
		ClCapture           = function() end,
		ClStartUncapture    = function() end,
		ClCancelUncapture   = function() end,
		ClStepUncapture     = function() end,
		ClUncapture         = function() end,
		ClContested         = function() end,
		ClInit              = function() end,
	},
	Properties = {
		objModel 	= "",
		teamName	= "",
		bEnabled	= 1,
		bDefault	= 0,
		teamName            = "",
		bCapturable         = 1,
		captureRequirement  = 2,
		captureAreaId		= 0,
		nCaptureIndex		= 1,
		statusSubMtlId		= 5,
		captureTime 		= 15,
		captureRequirement	= 2,
	},
	Server = {
		---------------------------
		--		OnInit
		---------------------------
		OnInit = function(self)
			self.inside = {
				[1] = {},
				[2] = {},
			};
			local teamId = nCX.GetTeamId(self.Properties.teamName);
			if (teamId and teamId ~= 0) then
				nCX.SetTeam(teamId, self.id);
				self.captured = true;
			else
				nCX.SetTeam(0, self.id);
				self.captured = false;
			end
			self.default=(tonumber(self.Properties.bDefault)~=0);
		end,
		---------------------------
		--		OnStartGame
		---------------------------
		OnStartGame = function(self)
			self:Enable(tonumber(self.Properties.bEnabled)~=0);
			nCX.UpdateObjectTimer(self.id, true);
		end,
		---------------------------
		--		OnEnterArea
		---------------------------
		OnEnterArea = function(self, entity, areaId)
			local force = (areaId == false);
			if (not self.default and entity.Info) then
				if (force or (nCX.IsPlayerActivelyPlaying(entity.id) and areaId == self.Properties.captureAreaId)) then
					local entityId = entity.id;
					local teamId = nCX.GetTeam(entityId);
					local inside = self.inside[teamId];
					if (inside) then
						local channelId = entity.Info.Channel;
						local otherId = teamId == 1 and 2 or 1;
						inside[channelId] = (nCX.Count(inside) > 0) and 0 or 1;
						if (channelId > 0) then
							g_gameRules.onClient:ClEnterCaptureArea(channelId, self.id, true);
						end
						self:CheckChannels(self.inside[otherId]);
						if (nCX.Count(self.inside[otherId]) > 0) then
							if (not self.contested) then
								self.allClients:ClContested(true);
								self.contested = teamId;
							end
						elseif (not nCX.IsSameTeam(entityId, self.id) and not self.data) then
							self.data = {self.Properties.captureTime, teamId};
							if (self.captured) then
								self.allClients:ClStartUncapture(teamId);
							else
								self.allClients:ClStartCapture(teamId);
							end	
						end
					end
				end
			end	
		end,
		---------------------------
		--		OnLeaveArea
		---------------------------
		OnLeaveArea = function(self, entity, areaId)
			local force = areaId == false;
			if (not self.default and entity.Info) then
				if ((force or areaId == self.Properties.captureAreaId)) then
					local entityId = entity.id;
					local teamId = nCX.GetTeam(entityId);
					local channelId = entity.Info.Channel;			
					local inside = self.inside[teamId];
					if (teamId == 0) then 	 -- handle leaving spectators
						if (self.inside[2][channelId]) then
							inside = self.inside[2];
						end
						inside = inside or self.inside[1];
					end
					if (inside and inside[channelId]) then
						inside[channelId] = nil;
						local otherId = teamId == 1 and 2 or 1;
						if (channelId > 0) then
							g_gameRules.onClient:ClEnterCaptureArea(channelId, self.id, false);
						end
						if (nCX.Count(inside) == 0) then  
							if (self.contested) then
								self.allClients:ClContested(false);
								self.contested = nil;
								if (self.captured ~= otherId) then --bunker neutral or team of leaving player
									self.data = self.data or {self.Properties.captureTime, otherId};
									if (self.data[2] ~= otherId) then
										self.data = {self.Properties.captureTime, otherId};
									end						
									if (self.captured) then
										self.allClients:ClStartUncapture(otherId);
										self.allClients:ClStepUncapture(otherId, self.data[1]);	 -- update hud immediately, next ontick call might be up to 1 sec later
									else
										self.allClients:ClStartCapture(otherId);
										self.allClients:ClStepCapture(otherId, self.data[1]);
									end	
								elseif (self.data) then -- bunker is of same team as remaining player (means its captured!)
									self.allClients:ClCancelUncapture();
									self.data = nil;	
								end
							elseif (nCX.Count(self.inside[otherId]) == 0) then
								if (self.captured) then
									self.allClients:ClCancelUncapture();
								else
									self.allClients:ClCancelCapture();
								end
								self.data = nil;
							end
						end
					end
				end
			end	
		end,
	};
	---------------------------
	--		OnSpawn
	---------------------------
	OnSpawn = function(self)
		local model = self.Properties.objModel;
		if (#model > 0) then
			local ext = model:sub(-4):lower();
			if ((ext == ".chr") or (ext == ".cdf") or (ext == ".cga")) then
				self:LoadCharacter(0, model);
			else
				self:LoadObject(0, model);
			end
		end
		self:Physicalize(0, PE_STATIC, {mass=0});
		CryAction.CreateGameObjectForEntity(self.id);
		CryAction.BindGameObjectToNetwork(self.id);
	end,
	---------------------------
	--		Enable
	---------------------------
	Enable = function(self, enable)
		if (enable) then
			nCX.AddSpawnGroup(self.id);
			local teamId=nCX.GetTeam(self.id)
			if (self.default and teamId ~= 0) then
				nCX.SetTeamDefaultSpawnGroup(teamId, self.id);
			end
			self:AddSpawnPoints("spawn");
			self:AddSpawnPoints("spawnpoint");		
		else
			nCX.RemoveSpawnGroup(self.id);
		end
	end,
	---------------------------
	--		AddSpawnPoints
	---------------------------
	AddSpawnPoints = function(self, linkName)
		local i=0;
		local link=self:GetLinkTarget(linkName, i);
		while (link) do
			nCX.AddSpawnLocationToSpawnGroup(self.id, link.id);
			i=i+1;
			link=self:GetLinkTarget(linkName, i);
		end
	end,
	---------------------------
	--		Capture
	---------------------------
	Capture = function(self, teamId)
		self.captured = teamId;
		if (self.contested) then  -- just incase
			self.contested = nil;
			self.allClients:ClContested(false);
		end
		self.data = nil;
		nCX.SetTeam(teamId, self.id);
		self.allClients:ClCapture(teamId);
		local inside = self.inside[teamId];
		if (g_gameRules.Server.OnCapture) then
			g_gameRules.Server.OnCapture(g_gameRules, self, teamId, inside);
		end
	end,
	---------------------------
	--		Uncapture
	---------------------------
	Uncapture = function(self, teamId, skip)
		local oldTeamId = nCX.GetTeam(self.id) or 0;
		self.allClients:ClUncapture(teamId, oldTeamId);
		if (not skip) then
			self.captured = nil;
			nCX.SetTeam(0, self.id);
			self.data = {self.Properties.captureTime, teamId,};
			self.allClients:ClStartCapture(self.data[2]);
		end
		if (g_gameRules.Server.OnUncapture) then
			g_gameRules.Server.OnUncapture(g_gameRules, self, teamId, oldTeamId);
		end
	end,
	---------------------------
	--		OnTimer
	---------------------------
	OnTimer = function(self)
		local data = self.data;
		if (not self.contested and data) then
			--data[1] = data[1] - (0.8 + math.min(1.0, math.max(3, nCX.Count(self.inside[data[2]])) * 0.2));
			local count = 0.85 + math.min(3, nCX.Count(self.inside[data[2]]) - tonumber(self.Properties.captureRequirement)) * 0.33;
			data[1] = data[1] - count;
			if (data[1] <= 0) then
				if (self.captured) then
					self:Uncapture(data[2]);
				else
					self:Capture(data[2]);
				end
				return;
			end
			if (self.captured) then
				self.allClients:ClStepUncapture(data[2], data[1]);
			else
				self.allClients:ClStepCapture(data[2], data[1]);
			end
		end
	end,
	---------------------------
	--		IsInside
	---------------------------
	IsInside = function(self, entity)
		local teamId = nCX.GetTeam(entity.id);
		local inside = self.inside[teamId];
		return inside and entity.Info and inside[entity.Info.Channel];
	end,
	---------------------------
	--		CheckChannels
	---------------------------
	CheckChannels = function(self, tbl)
		for chan, v in pairs(tbl or {}) do 
			if (not nCX.GetPlayerByChannelId(chan)) then
				tbl[chan] = nil;
				System.LogAlways("[$4Warning$9] Channel $4"..chan.." not in game! Deleting entry from "..self:GetName());
			end
		end
	end,
	
	GetBunkerCount = function(self, teamId)
		return (CryMP and CryMP.SquadLeader and CryMP.SquadLeader.Stats and CryMP.SquadLeader.Stats[teamId]) or 0;
		--[[
		local count = 0;
		for i, group in pairs(System.GetEntitiesByClass("SpawnGroup")) do
			if (nCX.GetTeam(group.id) == teamId and not group.default and not group.vehicle) then
				count = count+1;
			end
		end
		return count;
		]]
	end,
};

local NetSetup = {
	Class = SpawnGroup,
	ClientMethods =	{},
	ServerMethods = {},
	ServerProperties = {}
};
--> Weird fix
local NT = NetSetup.ClientMethods;
NT.ClStartCapture		= { RELIABLE_ORDERED, NO_ATTACH, INT8 };
NT.ClCancelCapture		= { RELIABLE_ORDERED, NO_ATTACH, };
NT.ClStepCapture		= { RELIABLE_ORDERED, NO_ATTACH, INT8,  FLOAT };
NT.ClCapture			= { RELIABLE_ORDERED, NO_ATTACH, INT8 };
NT.ClStartUncapture		= { RELIABLE_ORDERED, NO_ATTACH, INT8 };
NT.ClCancelUncapture	= { RELIABLE_ORDERED, NO_ATTACH, };
NT.ClStepUncapture		= { RELIABLE_ORDERED, NO_ATTACH, INT8,  FLOAT };
NT.ClUncapture			= { RELIABLE_ORDERED, NO_ATTACH, INT8, INT8 };
NT.ClContested			= { RELIABLE_ORDERED, NO_ATTACH, BOOL };
NT.ClInit				= { RELIABLE_ORDERED, NO_ATTACH, BOOL, INT8 };

g_gameRules:MakeBuyZone(SpawnGroup, 10); 

Net.Expose(NetSetup);