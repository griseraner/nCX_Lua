-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-05-09
-- *****************************************************************
VehicleSeat = {
	---------------------------
	--			Init
	---------------------------
	Init = function(self, vehicle, seatId)
		--System.LogAlways("$4Init seat "..vehicle:GetName().." "..(vehicle.Properties.Modification or "").." | "..seatId);
		self.vehicleId = vehicle.id;
		local vehicle = System.GetEntity(self.vehicleId);
		self.seatId = seatId;
		self.status = 0;
		self.playerId = 0;
		--if (self.locked) then
		--	System.LogAlways("Seat "..seatId.." locked for "..vehicle:GetName().." "..tostring(self.locked));
		--end
		--self.locked = true;
		
		--XDumpObjectToFile(io.open(nCX.ROOT.."Dump/Test/"..vehicle.class.."_"..vehicle.Properties.Modification.."_SeatId_"..seatId..".lua", "w+"), "seat", self, 99);
		if (vehicle:GetName():find("RACER") and seatId > 1) then
			System.LogAlways("[VehicleSeat] Skipping passenger seats for "..self:GetName().."...");
			return;
		--elseif (seatId == 2 and vehicle.class == "Asian_ltv") then
		--	System.LogAlways("[VehicleSeat] Skipping vehicle seat gunner for "..vehicle:GetName().."... ("..(vehicle.Properties.Modification and vehicle.Properties.Modification or "N/A")..")");
		--	return;
		end
		vehicle.vehicle:AddSeat(self);
	end,
	---------------------------
	--		IsFreeInit
	---------------------------
	IsFree = function(self)
		return self.seat:IsFree();
	end,
	---------------------------
	--		GetExitPos
	---------------------------
	GetExitPos = function(self)
		local vehicle = System.GetEntity(self.vehicleId);
		local exitPos = {x=0,y=0,z=0};
		if (self.exitHelper) then
			exitPos = vehicle.vehicle:MultiplyWithWorldTM(vehicle:GetVehicleHelperPos(self.exitHelper));
		elseif (self.enterHelper) then
			exitPos = vehicle.vehicle:MultiplyWithWorldTM(vehicle:GetVehicleHelperPos(self.enterHelper));
		end
		if (math:LengthSqVector(exitPos) == 0) then
			math:CopyVector(exitPos, vehicle.State.pos);
			exitPos.z = exitPos.z + 1;
		end
		return exitPos;
	end,
	---------------------------
	--		GetPassengerId
	---------------------------
	GetPassengerId = function(self)
		return self.passengerId;
	end,
	---------------------------
	--		GetWeaponId
	---------------------------
	GetWeaponId = function(self, index)
		if (self.Weapons and self.Weapons[index]) then
			return self.seat:GetWeapon(i);
		end
	end,
	---------------------------
	--		GetWeaponCount
	---------------------------
	GetWeaponCount = function(self)
		return nCX.Count(self.Weapons);
	end,
	---------------------------
	--	IsPassengerReady
	---------------------------
	IsPassengerReady = function(self)
		System.LogAlways("IsPassengerReady ");
		return true;
	end,
	---------------------------
	--	IsPassengerRemote
	---------------------------
	IsPassengerRemote = function(self)
		System.LogAlways("IsPassengerRemote ");
		return self.isRemote;
	end,
	
	---------------------------
	--	IsPassengerRemote
	---------------------------
	LoadPassenger = function(self)
		System.LogAlways("LoadPassenger ");
	end;
};
