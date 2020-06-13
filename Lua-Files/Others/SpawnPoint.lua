-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-04-27
-- *****************************************************************
SpawnPoint = {
	Properties = {
		teamName = "",
		bEnabled = 1,
	},
	Client = {},
	Server = {
		---------------------------
		--		OnInit
		---------------------------	
		OnInit = function(self)
			nCX.SetTeam(nCX.GetTeamId(self.Properties.teamName) or 0, self.id);
			self:Enable(tonumber(self.Properties.bEnabled)~=0);	
		end,
		---------------------------
		--		OnShutDown
		---------------------------	
		OnShutDown = function(self)
			nCX.RemoveSpawnLocation(self.id);
		end,
	},
	---------------------------
	--		Enable
	---------------------------
	Enable = function(self, enable)
		if (enable) then
			nCX.AddSpawnLocation(self.id);
		else
			nCX.RemoveSpawnLocation(self.id);
		end
		self.enabled = enable;
	end,
	---------------------------
	--		Spawned
	---------------------------
	Spawned = function(self, entity)
		BroadcastEvent(self, "Spawn");
	end,
	---------------------------
	--		IsEnabled
	---------------------------
	IsEnabled = function(self)
		return self.enabled;
	end,
	---------------------------
	--		Event_Spawn
	---------------------------
	Event_Spawn = function(self)
		local player = g_localActor;
		player:SetWorldPos(self:GetWorldPos(g_Vectors.temp_v1));		
		player:SetWorldAngles(self:GetAngles(g_Vectors.temp_v1));	
		BroadcastEvent(self, "Spawn");
	end,
	
};

SpawnPoint.FlowEvents = {
	Inputs = {
		Spawn = { SpawnPoint.Event_Spawn, "bool" },
	},
	Outputs = {
		Spawn = "bool",
	},
};
