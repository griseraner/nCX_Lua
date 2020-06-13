-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy & ctaoistrach
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-05-29
-- *****************************************************************
Script.ReloadScript("Server/Lua-Files/Vehicles/VehicleSeat.lua");

VehicleBase = {
	State = {
		pos = {},
		Carriage = {},
	},
	Seats = {},
	---------------------------
	--		BoostAmmo
	---------------------------
	BoostAmmo = function(self)
		for i = 1, 2 do
			local seat = self.Seats[i];
			if (seat) then
				local weaponCount = seat.seat:GetWeaponCount();
				for j = 1, weaponCount do
					local weaponId = seat.seat:GetWeaponId(j);
					if (weaponId) then
						local weapon = System.GetEntity(weaponId);
						if (weapon) then
							local weaponAmmo = weapon.weapon:GetAmmoType();
							if (weaponAmmo and weapon.weapon:GetClipSize() ~= -1) then
								local c=self.inventory:GetAmmoCount(weaponAmmo) or 0;
								local m=self.inventory:GetAmmoCapacity(weaponAmmo) or 0;
								if (c ~= m) then
									self.vehicle:SetAmmoCount(weaponAmmo, m);
								end
							end
						end
					end
				end
			end
		end
	end,
	---------------------------
	--		Boot
	---------------------------
	Boot = function(self, playerId)
		if (playerId) then
			self.vehicle:ExitVehicle(playerId)
			nCX.SendTextMessage(0, "You were forced out of your vehicle", nCX.GetChannelId(playerId));
		else
			local passengers = self:GetPassengers();
			if (passengers) then
				for i, passengerId in pairs(passengers) do	
					self.vehicle:ExitVehicle(passengerId)
					nCX.SendTextMessage(0, "You were forced out of your vehicle", nCX.GetChannelId(passengerId));
				end
				return passengers;
			end
		end
	end,
	---------------------------
	--		Teleport
	---------------------------
	Teleport = function(self, pos, dir)
		self:Boot();
		if (pos) then
			self:SetWorldPos(pos);
		end
		if (dir) then
			self:SetDirectionVector(dir);
		end
		self:AddImpulse(-1, self:GetCenterOfMassPos(), {x=0, y=0, z=1}, 1, 1); 
		self.NeedUpdate = System.GetFrameID();
	end,
	---------------------------
	--		IsRespawning
	---------------------------
	IsRespawning = function(self)
		return (self.Properties.Respawn and self.Properties.Respawn.bRespawn == 1)
	end,
	---------------------------
	--		IsHeavy
	---------------------------
	IsHeavy = function(self)
		return (self:GetMass() > 7200)
	end,
	---------------------------
	--		GetFreeSeat
	---------------------------
	GetFreeSeat = function(self)
		for i, seat in pairs(self.Seats) do
			if (seat.seat:IsFree()) then
				return seat, i;
			end
		end
	end,
	---------------------------
	--		MoveToFreeSeat
	---------------------------
	MoveToFreeSeat = function(self, playerId)
		local seat, i = self:GetFreeSeat();
		if (seat) then
			self:EnterVehicle(playerId, i);
			return seat, i;
		end
	end,
	---------------------------
	--		GetPassengers
	---------------------------
	GetPassengers = function(self)
		local tbl = {};
		for i, seat in pairs(self.Seats) do	
			local id = seat:GetPassengerId();
			if (id) then
				tbl[#tbl + 1] = id;
			end
		end
		if (#tbl > 0) then
			return tbl;
		end
	end,
	---------------------------
	--		GetPassengerCount
	---------------------------
	GetPassengerCount = function(self)
		return self.PassengerCount or 0;
	end,
	---------------------------
	--		IsAnyPassenger
	---------------------------
	IsAnyPassenger = function(self)
		return self.PassengerCount and self.PassengerCount > 0;
	end,
	---------------------------
	--		HasDriver
	---------------------------
	HasDriver = function(self)
		for i,seat in pairs(self.Seats) do
			if (seat.isDriver) then
				if (seat.passengerId) then
					return true;
				end
			end
		end
		return false;
	end,
	---------------------------
	--		GetDriverId
	---------------------------
	GetDriver = function(self)
		local driverId = self:GetDriverId();
		if (driverId) then
			return nCX.GetPlayer(driverId);
		end
	end,
	---------------------------
	--		GetDriverId
	---------------------------
	GetDriverId = function(self)  
		local seat = self.Seats[1]; 
		if (seat) then
			return seat:GetPassengerId();
		end
	end,
	---------------------------
	--	GetLastDriverId 		-- called C++
	---------------------------
	GetLastDriverId = function(self)
		local driverId = self:GetDriverId();
		if (not driverId) then
			return self.lastDriverId;
		end
	end,
	---------------------------
	--	ClearLastDriverId
	---------------------------
	ClearLastDriverId = function(self)
		if (not self:HasDriver()) then
			self.lastDriverId = nil;
		end
	end,
	---------------------------
	--		InitSeats
	---------------------------
	InitSeats = function(self)
		if (self.Seats) then
			for i,seat in pairs(self.Seats) do
				mergef(seat, VehicleSeat, 1);
				seat:Init(self, i);
			end
		end
	end,
	---------------------------
	--	InitVehicleBase
	---------------------------
	InitVehicleBase = function(self)
		self:OnPropertyChange();
	end,
	---------------------------
	--	OnPropertyChange
	---------------------------
	OnPropertyChange = function(self)
		if (self.OnPropertyChangeExtra) then
			self:OnPropertyChangeExtra();
		end
	end,
	---------------------------
	--		MountEntity
	---------------------------
	MountEntity = function(self, a_className, transformTable, propertiesTable)
		System.LogAlways("MountEntity "..self:GetName().." "..a_className);
		local params = {};
		params.class = a_className;
		params.name = self:GetName().."_"..a_className.."_mount";
		params.scale = 1;
		params.flags = 0;
		if (transformTable.helper) then
			if (self.vehicle:HasHelper(transformTable.helper)) then
				params.position = self.vehicle:GetHelperPos(transformTable.helper, true);
				params.orientation = self.vehicle:GetHelperDir(transformTable.helper, true);
			else
				params.position = {0,0,0};
				params.orientation = {0,1,0};
			end
		else
			params.position = self:GetPos();
		end
		if (transformTable.position) then
			math:FastSumVectors(params.position, params.position, transformTable.position);
		end
		if (transformTable.orientation) then
			params.orientation = transformTable.orientation;
		end
		if (propertiesTable) then
			params.properties = new(propertiesTable);
		else
			params.properties = nil;
		end
		local spawnedEntity = System.SpawnEntity(params);
		if (spawnedEntity) then
			if (transformTable.scale) then
				spawnedEntity:SetScale(transformTable.scale);
			end
			spawnedEntity:EnablePhysics( 0 );
			spawnedEntity:SetFlags(ENTITY_FLAG_RECVSHADOW, 0);
			spawnedEntity:SetFlags(ENTITY_FLAG_CASTSHADOW, 0);
			self:AttachChild(spawnedEntity.id, 0);
			self.State.Carriage[count(self.State.Carriage)+1] = {
			  id = spawnedEntity.id,
			  object = propertiesTable.object_Model,
			  position = params.position,
			  orientation = params.orientation,
			  useText = transformTable.useText,
			};
		end
		return spawnedEntity
	end,
	---------------------------
	--	DestroyCarriage
	---------------------------
	DestroyCarriage = function(self)
		if (self.State.Carriage) then
			for i,cargo in pairs(self.State.Carriage) do
				if (cargo.id) then
					Entity.DetachThis(cargo.id, 0);
					System.RemoveEntity(cargo.id);
				end
			end
		end
	end,
	---------------------------
	--	DestroyVehicleBase
	---------------------------
	DestroyVehicleBase = function(self)
		self:DestroyCarriage();
	end,
	---------------------------
	--		GetExitPos
	---------------------------
	GetExitPos = function(self, seatId)
		if (self.Seats[seatId] == nil) then
			return;
		end
		local exitPos;
		local seat = self.Seats[seatId];
		if (seat.exitHelper) then
			exitPos = self.vehicle:MultiplyWithWorldTM(self:GetVehicleHelperPos(self.Seats[seatId].exitHelper));
		else
			exitPos = self.vehicle:MultiplyWithWorldTM(self:GetVehicleHelperPos(self.Seats[seatId].enterHelper));
		end
		return exitPos;
	end,
	---------------------------
	--		GetSeatPos
	---------------------------
	GetSeatPos = function(self, seatId)
		if (seatId == -1) then
			return {x=0, y=0, z=0,};
		else
			local helper = self.Seats[seatId].enterHelper;
			local pos;
			if (self.vehicle:HasHelper(helper)) then
			  pos = self.vehicle:GetHelperWorldPos(helper);
			else
			  pos = self:GetHelperPos(helper, HELPER_WORLD);
			end
			return pos;
		end
	end,
	---------------------------
	--		CanEnter			-- changed 18.06
	---------------------------
	CanEnter = function(self, playerId)
		local player = nCX.GetPlayer(playerId);
		if (player.seatTransitionActive and _time - player.seatTransitionActive < 2) then
			return false;
		end
		player.seatTransitionActive = nil;
		local channelId = player.Info.Channel;
		if (nCX.GodMode(channelId)) then
			return true;
		end
		local quit, canEnter = CryMP:HandleEvent("CanEnterVehicle", {self, player});
		if (quit) then
			return canEnter;
		elseif (nCX.IsSameTeam(self.id, playerId) or nCX.IsNeutral(self.id)) then
			local unclaimed = g_gameRules.unclaimedVehicle and g_gameRules.unclaimedVehicle[self.id];
			if (unclaimed) then
			    if (unclaimed.ownerId == playerId) then
					return true;
				end
				local owner = nCX.GetPlayer(unclaimed.ownerId);
				if (owner) then
					nCX.SendTextMessage(2, "OWNER - [ "..owner:GetName().." ] - RESERVED", channelId);
				end
				return false;
			end
			return true;
		end
		return false;
	end,
	---------------------------
	--		GetSeat
	---------------------------
	GetSeat = function(self, userId)
		for i,seat in pairs(self.Seats) do
			if (seat:GetPassengerId() == userId) then
				return seat;
			end
		end
		return;
	end,
	---------------------------
	--		GetSeatId
	---------------------------
	GetSeatId = function(self, userId)
		for i,seat in pairs(self.Seats) do
			if (seat:GetPassengerId() == userId) then
				return i;
			end
		end
		return;
	end,
	---------------------------
	--	ResetVehicleBase
	---------------------------
	ResetVehicleBase = function(self)
		self.State.pos = self:GetWorldPos(self.State.pos);
		self:OnPropertyChange();
		if (self.ClearLastDriverId) then
			self:ClearLastDriverId();
		end
	end,
	---------------------------
	--		OnDestroy
	---------------------------
	OnDestroy = function(self)
		self:DestroyVehicleBase();
	end,
	---------------------------
	--		IsGunner
	---------------------------
	IsGunner = function(self, userId)
		local seat = self:GetSeat(userId);
		if (seat and seat.Weapons) then
			return true;
		end
		return false;
	end,
	---------------------------
	--		IsDriver
	---------------------------
	IsDriver = function(self, userId)
		local seat = self:GetSeat(userId);
		if (seat) then
			if (seat.isDriver) then
				return true;
			end
		end
		return false;
	end,
	---------------------------
	--	GetVehicleHelperPos
	---------------------------
	GetVehicleHelperPos = function(self, helperName)
		if (not helperName) then
			helperName = "";
		end
		local pos;
		if (self.vehicle:HasHelper(helperName)) then
			pos = self.vehicle:GetHelperPos(helperName, true);
		else
			pos = self:GetHelperPos(helperName, true);
		end
		return pos;
	end,
	---------------------------
	--		ReserveSeat
	---------------------------
	ReserveSeat = function(self, userId, seatidx)
		self.Seats[seatidx].passengerId = userId;
	end,
	---------------------------
	--		IsDead
	---------------------------
	IsDead = function(self)
		return self.vehicle:IsDestroyed();
	end,
	---------------------------
	--	GetWeaponVelocity
	---------------------------
	GetWeaponVelocity = function(self, weaponId)
		return self:GetFiringVelocity();
	end,
	---------------------------
	--	SpawnVehicleBase
	---------------------------
	SpawnVehicleBase = function(self)
		if (self.OnPreSpawn) then
			self:OnPreSpawn();
		end
		if (_G[self.class.."Properties"]) then
			mergef(self, _G[self.class.."Properties"], 1);
		end
		if (self.OnPreInit) then
			self:OnPreInit();
		end
		self:InitVehicleBase();
		self.ProcessMovement = nil;
		if (not EmptyString(self.Properties.FrozenModel)) then
			self.frozenModelSlot = self:LoadObject(-1, self.Properties.FrozenModel);
			self:DrawSlot(self.frozenModelSlot, 0);
		end
		if (self.OnPostSpawn) then
			self:OnPostSpawn();
		end
		self:InitSeats();
		self:OnReset();
	end,
	---------------------------
	--		LoadXML
	---------------------------
	LoadXML = function(self)
		local dataTable = VehicleSystem:LoadXML(self.class);
		if (dataTable) then
			if (dataTable.Seats) then
				self.Seats = new(dataTable.Seats);
			end
		else
			return false;
		end
		return true;
	end,
	---------------------------
	--		GetFrozenSlot
	---------------------------
	GetFrozenSlot = function(self)
		return self.frozenModelSlot;
	end,
	---------------------------
	--		GetFrozenAmount
	---------------------------
	GetFrozenAmount = function(self)
		return self.vehicle:GetFrozenAmount();
	end,
	---------------------------
	--		GetSelfCollisionMult
	---------------------------
	GetSelfCollisionMult = function(self, hit)  
		local shooterId = hit.shooter and hit.shooter.id;
		if (not shooterId) then
			shooterId = hit.target and hit.target.id;
		end
	    return self.vehicle:GetSelfCollisionMult(hit.velocity, hit.normal, hit.partId or -1, shooterId or self.id);
	end,
	---------------------------
	--			OnHit
	---------------------------
	OnHit = function(self, hit)
		--if (nCX.LogVehicleOnHit) then
			--System.LogAlways("VehicleBase:OnHit "..hit.typeId.." "..self:GetName().." $4"..hit.damage); 
	--	end
		--if (hit.typeId == 0) then
		--	return;
		--end
		local fire, collision = hit.typeId == 7, hit.typeId == 13;
		if (hit.shooter and hit.shooter.actor and not fire and not collision) then
			if (nCX.IsSameTeam(hit.shooter.id, self.id) and self:IsAnyPassenger()) then
				return;
			end
		end
		local explosion = hit.explosion or false;
		local hitType = (explosion and hit.type == "") and "explosion" or hit.type;
		local hitShooterId = (hit.shooter and hit.shooter.id) or self.id;
		local driverId = self:GetDriverId();
		hit.driver = (driverId and nCX.GetPlayer(driverId));
		local shooter = hit.shooter or self;
		local destroyed = self.vehicle:IsDestroyed();
		if (not destroyed) then
			local lastDriverId = driverId or ((nCX.IsNeutral(self.id) or nCX.IsSameTeam(shooter.id, self.id)) and self.lastDriverId);
			local vehicle = (shooter.actor and shooter.actor:GetLinkedVehicle());
			hit.self = (shooter.id == lastDriverId or (vehicle and vehicle.id == self.id));
			--[[  -- move to C++
			if (hit.driver) then
				if (nCX.AdminSystem(hit.driver.Info.Channel, 3) and shooter.actor and hit.type ~= "collision" and shooter.id ~= driverId) then
					nCX.SendTextMessage(5, "<font size=\"32\"><font color=\"#c6c6c6\">***</font> <font color=\"#66aad9\"><b>ADMIN-[ <font color=\"#FFFFFF\">7Ox</font><font color=\"#66aad9\"> ]-GODMODE</b></font> <font color=\"#c6c6c6\">***</font></font>", shooter.Info.Channel);
				end
			end
			]]
			local damage = hit.damage;
			if (collision) then
				if (hit.velocity) then
					local mult = self:GetSelfCollisionMult(hit);
					damage = hit.damage * mult;
				else
					System.LogAlways("$4Keine velocity!");
				end
			end
			local quit = (hit.shooter and not fire and CryMP:HandleEvent("PreVehicleHit", {hit, self, vehicle}));
			if (not quit) then
				self.vehicle:OnHit(self.id, shooter.id, damage, hit.pos, hit.radius or 1, hitType, explosion);
				--System.LogAlways("VehicleBase:OnHit RADIUS "..(hit.radius or "$4N/A").." | "..hitType.." | "..self:GetName().." | "..shooter:GetName().." |$4"..hit.damage); 
				---------------------------
				--		Damage Indicators
				---------------------------
				if (not fire and hitShooterId ~= driverId and not collision) then
					nCX.SendHitIndicator(hitShooterId, hit.explosion or false);
				end
				if (hit.shooter) then
					local ratio = collision and math.floor(self.vehicle:GetRepairableDamage() * 100); -- only show dmg indicator if it actually did some damage (collision)
					if (not collision or (ratio ~= self.DamageStatus and ratio ~= 0)) then
						self.DamageStatus = ratio;
						if (self.Seats) then
							local weaponId = hit.weaponId;
							for i,seat in pairs(self.Seats) do
								local passengerId = seat:GetPassengerId();
								if (passengerId) then
									if (collision) then
										hitShooterId = passengerId; 
									end
									--nCX.SendDamageIndicator(passengerId, hitShooterId or NULL_ENTITY, weaponId or NULL_ENTITY);
									if (hit.shooter and damage > 0.1) then --TODO : Check damage
										local passenger = nCX.GetPlayer(passengerId);
										if (passenger) then
											passenger.hitAssist = passenger.hitAssist or {};  -- assist
											passenger.hitAssist[hit.shooter.id] = _time;
										end
									end
								end	
							end
						end
					end
				end
				if (fire) then 
					return;
				elseif (hit.shooter) then
					local destroyed = self.vehicle:IsDestroyed();
					CryMP:HandleEvent("OnVehicleHit", {hit, self, destroyed, dmgDone});
					if (destroyed) then
						local assist = self.hitAssist;
						if (assist) then  
							assist[hit.shooter.id] = nil;
							for shooterId, time in pairs(assist) do
								if (_time - time < 5) then
									local shooter = nCX.GetPlayer(shooterId);
									if (shooter) then
										if (g_gameRules.ProcessVehicleScores) then
											g_gameRules.ProcessVehicleScores(g_gameRules, self, shooter, true);
										end
									end
								end
							end
							self.hitAssist = nil;
						end
					elseif (hit.shooter.actor and not hit.self and not nCX.IsSameTeam(shooter.id, self.id)) then 
						if (hit.driver and self.vehicle:GetMovementType() == "air") then
							hit.driver.lastHit = {hit.shooter.id, _time, 8};
						end
						if (damage > 0.1) then
							self.hitAssist = self.hitAssist or {};
							self.hitAssist[shooter.id] = _time;
						end
					end
				end
				--LogHitToFile(hit);
			end
		end
	end,
	---------------------------
	--		EnterVehicle
	---------------------------
	EnterVehicle = function(self, playerId, seatId)
		local player = nCX.GetPlayer(playerId);
		if (not player) then
			return;
		elseif (not nCX.IsPlayerActivelyPlaying(playerId)) then  -- use gameRules:RevivePlayer
			return;
		end
		nCX.ResetAntiCheat(playerId);
		seatId = seatId or -1;
		local seat = self.Seats[seatId];
		if (not seat or not seat.seat:IsFree()) then
			for i = math.max(1, seatId), #self.Seats do
				local s = self.Seats[i];
				if (s and s.seat:IsFree()) then
					seat = s;
					break;
				end
			end
		end
		if (seat) then
			player.serverSeatChange = player.actor:GetLinkedVehicleId() ~= self.id and true or -1;
			if (self.NeedUpdate and self.NeedUpdate == System.GetFrameID()) then
				CryMP:DeltaTimer(1, function()
					self.vehicle:EnterVehicle(playerId, seat.seatId, false) 
					player.serverSeatChange = nil;
				end);
			else
				self.vehicle:EnterVehicle(playerId, seat.seatId, false) 
				player.serverSeatChange = nil;
			end
		end
		return seat;
	end,
	---------------------------
	--		EnterVehicle
	---------------------------
	LeaveVehicle = function(self, passengerId, fastLeave)
		return self.vehicle:ExitVehicle(passengerId);
	end,
	---------------------------
	-- OnActorSitDown
	---------------------------
	OnActorSitDown = function(self, seatId, entityId)
		local entity = nCX.GetPlayer(entityId);
		if (entity) then
			local previousId = entity.returnToSeat;
			if (previousId) then
				entity.returnToSeat = nil;
				if (not nCX.IsSpawnGroup(self.id) or seatId == 1) then
					self.vehicle:EnterVehicle(entityId, previousId, false);
					return;
				end
			end
			local entering = (not entity.vehicleId);
			local seat = self.Seats[seatId];
			if (seat) then
				seat.passengerId = entityId;
				if (g_gameRules.unclaimedVehicle) then
					g_gameRules.unclaimedVehicle[self.id] = nil;
				end
				if (entering) then
					self.PassengerCount = (self.PassengerCount or 0) + 1;
					entity.vehicleId = self.id;
					if (nCX.IsNeutral(self.id) and self:GetName() ~= "AFK_TRUCK") then
						nCX.SetTeam(nCX.GetTeam(entityId), self.id);
					end
				end
				if (not self.PassengerEntered) then
					CryMP:HandleEvent("OnFirstVehicleEntrance", {self, seat, entity});
					self.PassengerEntered = true;
				end
				CryMP:HandleEvent("OnEnterVehicleSeat", {self, seat, entity, entering, seatId});
				-- Always
				if (seatId == 1) then
					self.vehicle:SetOwnerId(entityId);
					if (self.nCX) then
						self.nCX:StoreLastDriverId(entityId);
					end
				end
			end
		end
	end,
	---------------------------
	-- 	OnActorStandUp
	---------------------------
	OnActorStandUp = function(self, entityId, exiting)
		local seat = self:GetSeat(entityId);
		if (seat) then -- seat is nil if returning immediately (returnToSeat = true)
			seat.passengerId = nil;
			local entity = nCX.GetPlayer(entityId);
			if (entity --[[ and not entity.serverSeatChange]]) then
				local seatId = seat.seatId;
				if (exiting) then
					self.PassengerCount = math.max(0, (self.PassengerCount or 0) - 1);
					entity.vehicleId = nil;
					entity.lastSeatId = nil;
					local empty=true;
					for i, seat in pairs(self.Seats) do
						local passengerId = seat:GetPassengerId();
						if (passengerId and passengerId~=NULL_ENTITY and passengerId~=entityId) then
							empty=false;
							break;
						end
					end
					if (empty) then
						if (g_gameRules.class == "InstantAction") then
							-- Neutralize on Exit
							self.vehicle:SetOwnerId(NULL_ENTITY);
							if (not nCX.IsNeutral(self.id)) then
								nCX.SetTeam(0, self.id); 
							end
						end
						self.lastOwnerId = entityId;
					end
					if (g_gameRules.OnLeaveVehicle) then
						g_gameRules:OnLeaveVehicle(self, seat, entity);
					end
					--if (seat.isDriver) then
					--	nCX.SetLastDriverId(self.id, entityId); 
					--end
				else
					entity.lastSeatId = seatId;
				end
				local pos = entity:GetWorldPos();
				local exitPos = self:GetExitPos(seat.seatId);
				local distance = math:GetWorldDistance(pos, exitPos);
				local server = entity.serverSeatExit or entity.serverSeatChange;
				local back, start, finish = CryMP:HandleEvent("OnLeaveVehicleSeat", {self, seat, entity, exiting, server, distance});
				entity.serverSeatExit = nil;
				if (back and not server) then
					if (exiting) then
						entity.seatTransitionActive = _time;
						CryMP:DeltaTimer(0, function()
							if (seat.seat:IsFree()) then
								self.vehicle:EnterVehicle(entity.id, seat.seatId, false);
							else					
								for i = (tonumber(start or 1) or 1), (tonumber(finish or #self.Seats) or #self.Seats), 1 do
									local seat = self.Seats[i];
									if (seat and seat.seat:IsFree()) then
										self.vehicle:EnterVehicle(entity.id, i, false);
										break;
									end
								end
							end
						end);
					else
						entity.returnToSeat = seat.seatId;
					end
				end
			end
		end
	end,

};
