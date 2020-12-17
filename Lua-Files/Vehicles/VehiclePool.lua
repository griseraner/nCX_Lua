-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy / ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  3.0
--        ##     ####  #####  ##   ##   
-- *****************************************************************
Script.ReloadScript("Server/Lua-Files/Vehicles/VehicleBase.lua");

VEHICLE_SCRIPT_TIMER = 100;
PLAYEREXIT_TIMER = VEHICLE_SCRIPT_TIMER + 3
PLAYEREXIT_TIMEOUT = 3000

for i, vehicle in pairs(VehicleSystem.VehicleImpls) do
	local gVehicle = {
		Properties = {
			bDisableEngine = 0,
			Paint = "",
			bFrozen = 0,
			FrozenModel = "",
			Modification = "",
			soclasses_SmartObjectClass = "",
			--bAutoGenAIHidePts = 0,
			teamName = "",
		},
		Client = {},
		Server = {
			---------------------------
			--		OnInitClient		
			---------------------------
			OnInitClient = function(self, channelId)
				if (g_gameRules.vehicleBuyZones and g_gameRules.vehicleBuyZones[self.id]) then
					local factory = g_gameRules.factories and g_gameRules.factories[1];
					if (factory) then
						factory.onClient:ClSetBuyFlags(channelId, self.id, 13);
						--System.LogAlways("attached buyzone to "..channelId);
					end
				end
			end,
			---------------------------
			--		OnShutDown
			---------------------------
			OnShutDown = function(self)
				nCX.RemoveSpawnGroup(self.id);
				--nCX 
				if (self:IsRespawning() and self.class == "Asian_ltv") then
					local mods = {"MP", "Gauss", "MP", "Unarmed"};
					self.Properties.Modification  = mods[math.random(2)];
				end
			end,
			---------------------------
			--		OnEnterArea
			---------------------------
			OnEnterArea = function(self,entity, areaId)
				if (self.OnEnterArea) then
					self.OnEnterArea(self, entity, areaId);
				end
			end,
			---------------------------
			--		OnLeaveArea
			---------------------------
			OnLeaveArea = function(self, entity, areaId)
				if (self.OnLeaveArea) then
					self.OnLeaveArea(self, entity, areaId);
				end
			end,
		},
		---------------------------
		--		OnSpawn
		---------------------------
		OnSpawn = function(self)
			--System.LogAlways(self:GetName().." ---> OnSpawn");
			mergef(self, VehicleBase, 1);
			self:SpawnVehicleBase();
		end,
		-------------
		--		OnReset
		---------------------------
		OnReset = function(self)
			CryAction.ActivateExtensionForGameObject(self.id, "VehicleExtension", false); --nCX TEST
			CryAction.ActivateExtensionForGameObject(self.id, "VehicleExtension", true);	
			--System.LogAlways(self:GetName().." ---> OnReset");
			self:ResetVehicleBase();
			local teamId = nCX.GetTeamId(self.Properties.teamName);
			if (teamId and teamId ~= 0) then
				nCX.SetTeam(teamId, self.id);
			else
				nCX.SetTeam(0, self.id);
			end
		end,
		---------------------------
		--		OnFrost
		---------------------------
		OnFrost = function(self, shooterId, weaponId, frost)
			local f = self.vehicle:GetFrozenAmount() + frost;
			self.vehicle:SetFrozenAmount(f);
		end,
		---------------------------
		--		OnUnlocked
		---------------------------
		OnUnlocked = function(self, playerId)
			local player = System.GetEntity(playerId);
			if (player) then
				nCX.SendTextMessage(3, "@mp_VehicleUnlocked", player.Info.Channel);
				nCX.SetTeam(nCX.GetTeam(playerId), self.id);
				self.vehicle:SetOwnerId(NULL_ENTITY);
			end
		end;
	};

    if (_G[vehicle]) then
    	mergef(gVehicle, _G[vehicle], 1);
    end

	MakeRespawnable(gVehicle);
	gVehicle.Properties.Respawn.bAbandon = 1;
	gVehicle.Properties.Respawn.nAbandonTimer = 90;

	_G[vehicle] = gVehicle;

	Net.Expose {
		Class = _G[vehicle],
		ClientMethods = {},
		ServerMethods = {},
	};
end;





