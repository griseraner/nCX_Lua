LockDowns = {

	---------------------------
	--		Config
	---------------------------
	AirMode = {
		["US_vtol"] 		 = 3,
		["Asian_helicopter"] = 3,
	},
	HUD 					 = {},
		
	Server = {
		
		OnBuyVehicle = function(self, player, itemName, def)
			local channelId = player.Info.Channel;
			local class = def.class;
			local mode = self:GetAirMode(class);
			local name = CryMP.Ent:GetVehicleName(class):upper();
			local restricted = (mode == 1 and name) or (mode == 2 and def.heavy and "HEAVY:"..name);
			if (restricted) then
				nCX.SendTextMessage(0, "*** "..restricted.."S ARE BEING SERVICED - COME BACK LATER  ***", channelId);
				return true;
			end
			if (class == "US_vtol") then
				if (mode == 3 and def.heavy) then
					local count = g_gameRules:GetActiveItems(class, nCX.GetTeam(player.id), true, def);
					if (#count >= self.Config.MaxHeavyVtols) then
						CryMP.Msg.Chat:ToPlayer(channelId, "Cannot build any more heavy VTOL ( Team Limit : max "..#count.." )");
						return true;
					end
				end
				local ping = nCX.GetPing(channelId);
				if (ping > self.Config.MaxPing) then
					nCX.SendTextMessage(0, "***  YOUR PING "..ping.." IS TOO HIGH - MAX PING "..self.Config.MaxPing.."  ***", channelId);
					return true;
				end
			end
		end,
		
		OnLeaveVehicleSeat = function(self, vehicle, seat, entity, exiting)
			if (exiting and self.HUD[entity.id]) then
				nCX.ForbiddenAreaWarning(false, 0, entity.id);
				self.HUD[entity.id] = nil;
			end
		end,
		
		OnVehicleDestroyed = function(self, vehicleId)
			local entities = self.Data and self.Data.Entities;
			if (entities and entities[vehicleId]) then
				entities[vehicleId] = nil;
			end
		end,
	
	},
	
	OnTick = function(self)
		local data = self.Data;
		if (data) then
			if (data.Timer == 11) then
				for vehicleId, vehicle in pairs(data.Entities) do
					local def = g_gameRules:GetItemDef(vehicle.builtas);
					if (def and def.price) then
						local ownerId = vehicle.vehicle:GetOwnerId();
						if (ownerId and ownerId ~= NULL_ENTITY) then
							g_gameRules:AwardPPCount(ownerId, def.price);
						end
					end
				end
			else
				for vehicleId, vehicle in pairs(data.Entities) do
					local passengers = vehicle:GetPassengers();
					if (passengers) then
						for i, playerId in pairs(passengers) do
							self.HUD[playerId] = true;
							nCX.ForbiddenAreaWarning(true, data.Timer, playerId);
							nCX.SendTextMessage(0, "! WARNING "..data.Name.." DETONATIONS ! ::: [ 00:"..math:zero(data.Timer).." ]", nCX.GetChannelId(playerId));
						end
					end
				end
				if (data.Timer==0) then
					for vehicleId, vehicle in pairs(data.Entities) do
						nCX.ParticleManager("explosions.TAC.small_close", 0.5, vehicle:GetWorldPos(), g_Vectors.up, 0);
						vehicle.vehicle:Destroy()
					end
					local count = nCX.Count(data.Entities);
					--CryMP.Msg.Animated:ToAll(2, "<b><font color=\"#afafaf\">***</font> <font color=\"#cf3535\">"..(count > 0 and count.." " or "")..data.Name..(count>1 and "S" or "").." GROUNDED FOR REPAIRS</font> <font color=\"#afafaf\">***</font></b>");			
					self:SetTick(false);
					self.Data = nil;
					return;
				end
			end
			data.Timer = data.Timer - 1;
		end
	end,
	
	OnShutdown = function(self, restart)
		if (not restart) then
			for entityId, v in pairs(self.HUD) do
				nCX.ForbiddenAreaWarning(false, 0, entityId);
			end
		end
	end,
			
	ToggleAirMode = function(self, class, auto)
		if (not class) then
			local classes = {"US_vtol", "Asian_helicopter"}; 
			class = classes[math.random(1, #classes)];
		end
		local current = self:GetAirMode(class);
		--local new = (current ~= 1 and class ~= "Asian_helicopter" and 1) or (nCX.GetPlayerCount() >= self.Config.MinPlayers and 3) or 2;
		local new = (nCX.GetPlayerCount() >= self.Config.MinPlayers and 3) or 2;
		return self:SetAirMode(class, new);
	end,
	
	SetAirMode = function(self, class, mode, auto)
		if (self.AirMode[class] == mode) then
			return false, "specified mode already set"
		elseif (self.Data) then
			return false, "wait untill vehicle destruction is complete"
		end
		local old = self.AirMode[class];
		if (mode < old) then
			self:Destroy(class, mode == 2);
		end
		local vehicleName = CryMP.Ent:GetVehicleName(class);
		local convert = {"OFF", "LIGHT", "HEAVY",};
		if (mode > old and not auto) then
			CryMP.Msg.Flash:ToAll({50, "#656565", "#009933",}, vehicleName:upper().." : "..convert[mode], "<font size=\"32\"><b><font color=\"#73d03b\">*** ONLINE</font><font color=\"#ababab\">-[  %s <font color=\"#ababab\"> ]-</font><font color=\"#73d03b\">ONLINE ***</font></b></font>");
		end
		self.AirMode[class] = mode;
		if (mode > 1) then
			local txt = mode == 3 and "Heavy" or "Light";
			self:Log(txt.." "..vehicleName.."s online");
		else
			self:Log(vehicleName.."s have been disabled");
		end
		return true;
	end, 
		
	GetAirMode = function(self, class, full)
		if (not class) then
			if (full) then
				local modes = {[1] = "OFF", [2] = "LIGHT", [3] = "HEAVY"};
				return "Vehicle Status : VTOL : "..modes[self.AirMode["US_vtol"]].." * Helicopter : "..modes[self.AirMode["Asian_helicopter"]];
			end
			return self.AirMode["US_vtol"], self.AirMode["Asian_helicopter"]
		end
		return self.AirMode[class];
	end,
	
	Destroy = function(self, class, heavy)
		local entities = {};
		for i, ent in pairs(System.GetEntitiesByClass(class) or {}) do
			local def = ent.builtas and g_gameRules:GetItemDef(ent.builtas) or g_gameRules:GetItemDef(ent.class, true);
			if (heavy and def.heavy or not heavy) then
				entities[ent.id] = ent;
			end
		end
		for i, player in pairs(nCX.GetPlayers() or {}) do
			local itemName = player.FACTORY_BUILD;
			if (itemName) then
				local def = g_gameRules:GetItemDef(itemName);
				if (def and def.class == class and (def.heavy or not heavy)) then
					for i, fac in pairs(g_gameRules.factories or {}) do
						fac:CancelJobForPlayer(player.id);
					end
				end
			end
		end
		local name = (heavy and "HEAVY:" or "")..CryMP.Ent:GetVehicleName(class):upper();
		if (nCX.Count(entities) == 0) then
			nCX.SendTextMessage(5, string.format("<font size=\"32\"><b><font color=\"#afafaf\">***</font> <font color=\"#cf3535\">"..name.."S GROUNDED FOR REPAIRS</font> <font color=\"#afafaf\">***</font></b></font>"), 0);
			return true;
		end
		nCX.SendTextMessage(2, "! WARNING:PLAYERS !-[ "..name.." ]-ENGINES UNSTABLE!", 0);
		self.Data = {
			Timer = 11, 
			Name = name, 
			Class = class, 
			Entities = entities,
			Heavy = heavy,
		};
		self:SetTick(1);
		return true;
	end,
		
};
