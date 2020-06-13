-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis Wars nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###      Author:   Arcziy
--        ##    ## ## ##   ##  ## ##     Version:  2.0 Public
--        ##     ####  #####  ##   ##    LastEdit: 2012-05-09
-- *****************************************************************
--HELPER_WORLD = 0;
--HELPER_LOCAL = 1;
VehicleSystem = {
	VehicleImpls = Vehicle.GetVehicleImplementations("Scripts/Entities/Vehicles/Implementations/Xml/");
	LoadXML = function(self, vehicleImpl)
		local dataFile = "Server/Lua-Files/Vehicles/Implementations/Xml/"..vehicleImpl..".xml";
		local dataTable = CryAction.LoadXML("Server/Lua-Files/Vehicles/def_vehicle.xml", dataFile );
		return dataTable;
	end,
	ReloadVehicleSystem = function(self)
		Vehicle.ReloadSystem();
		Script.ReloadScript("Server/Lua-Files/Vehicles/VehicleSystem.lua");
	end,
	SetTpvDistance = function(self, dist)
		Vehicle.SetTpvDistance(tonumber(dist));
	end,
	SetTpvHeight = function(self, height)
		Vehicle.SetTpvHeight(tonumber(height));
	end;
}
--[[
function ForcePassengersToExit(vehicleName)
	local v = System.GetEntityByName(vehicleName);
	if (v and v.vehicle) then
		for i,seat in pairs(v.Seats) do
			local passengerId = seat:GetPassengerId();
			if (passengerId) then
				v:LeaveVehicle(passengerId);
			end
		end
	end
end

function DestroyVehicle(vehicleName)
	local v = System.GetEntityByName(vehicleName);
	if (v and v.vehicle) then
		v.allClients:Destroy(true);
	end
end--]]
