--==============================================================================
--!SPAWN

CryMP.ChatCommands:Add("spawn", {
		Access = 3, 
		Args = {
			{"class", Output = {{"Player",},{"Grunt",},{"Asian_aaa",},{"Asian_apc",},{"Asian_helicopter",},{"Asian_ltv",},{"Asian_patrolboat",},{"Asian_tank",},{"Asian_truck",},{"Civ_car1",},{"Civ_speedboat",},{"GUI",},{"InteractiveEntity",},{"Shark",},{"ShiTen",},{"Tornado",},{"US_apc",},{"US_asv",},{"US_hovercraft",},{"US_ltv",},{"US_smallboat",},{"US_tank",},{"US_trolley",},{"US_vtol",},{"WarriorMOARTurret"},{"AlienTurret",},{"AutoTurret",},},},
			{"mod", Optional = true, Info = "Vehicle modification"},
			{"distance", Optional = true, Number = true, Info = "Distance in meters"},
		}, 
		Info = "spawn an item or vehicle",
		self = "Library",
	}, 
	function(self, player, channelId, class, mod, distance)
		return self:Spawn(player, distance, class, mod);
	end
);

--==============================================================================
--!REMOVECLASS

CryMP.ChatCommands:Add("removeclass", {
		Access = 3, 
		Args = {
			{"class",},
		}, 
		Info = "remove entities by class",
		self = "Library",
	}, 
	function(self, player, channelId, class)
		return self:RemoveClass(class);
	end
);

--==============================================================================
--!REMOVESPAWNED

CryMP.ChatCommands:Add("removespawned", {
		Access = 3, 
		Args = {
			{"player", Optional = true, GetPlayer = true, Access = 4, Output = {{"all", "Remove spawned entities for all"},},},
		}, 
		Info = "remove spawned entities",
		self = "Library",
	}, 
	function(self, player, channelId, target)
		local id, msg;
		if (type(target) == "table") then
			id = target.id;
			msg = target:GetName();
		elseif (target == "all") then
			msg = "ADMINS";
		else
			id = player.id;
			msg = "YOU";
		end
		local count = self:RemoveSpawned(id);
		if (count > 0) then	
			CryMP.Msg.Chat:ToPlayer(channelId, "ENTS : REMOVED :: ["..math:zero(count).."]-SPAWNED-BY :: "..msg); 
			return true;
		end			
		return false, "no entities to remove";
	end
);

--==============================================================================
--!GIVE

CryMP.ChatCommands:Add("give", {
		Access = 3, 
		Args = {
			{"item", Output = {{"AlienMount",},{"AVMine",},{"Binoculars",},{"C4",},{"Claymore",},{"DebugGun",},{"Detonator",},{"DSG1",},{"Fists",},{"FY71",},{"GaussRifle",},{"Golfclub",},{"Hurricane",},{"LAW",},{"LockpickKit",},{"MOARAttach",},{"NightVision",},{"Offhand",},{"Parachute",},{"RadarKit",},{"RepairKit",},{"Rock",},{"SCAR",},{"SCARTutorial",},{"Shotgun",},{"SMG",},{"SOCOM",},{"TACGun",},{"TACGun_Fleet",},},},
			{"player", Optional = true, GetPlayer = true, Output = {{"nk", "NK Team",true},{"us", "US Team",true},{"all", "All players",true},},},
		}, 
		Info = "give someone an item",
		self = "Library",
	}, 
	function(self, player, channelId, item, target)
		local id, msg;
		if (type(target) == "table") then
			msg = target:GetName();
		elseif (target) then
			local teams = {"TEAM:NK","TEAM:US",};
			msg = teams[target] or "ALL";
		end
		if (msg) then
			CryMP.Msg.Chat:ToPlayer(channelId, "ITEM : [ "..item:upper().." ]-GIVEN-TO :: "..msg); 
		end	
		return self:Give(target or player, item);
	end
);

--==============================================================================
--!GIVE

CryMP.ChatCommands:Add("award", {
		Access = 3, 
		Args = {
			{"prestige", Info = "Amount of prestige", Number = true,},
			{"player", Optional = true, GetPlayer = true, Output = {{"nk", "NK Team", true},{"us", "US Team", true},{"all", "All players", true},},},
		},
		Map = {"ps/(.*)"},
		Info = "award someone prestige points",
		self = "Library",
	}, 
	function(self, player, channelId, pp, target)
		local id, msg;
		if (type(target) == "table") then
			msg = target:GetName();
		elseif (target) then
			local teams = {"TEAM:NK","TEAM:US",};
			msg = teams[target] or "ALL";
		end
		if (msg) then
			CryMP.Msg.Chat:ToPlayer(channelId, "AWARD : [ "..pp.." ]-PRESTIGE-TO :: "..msg); 
		end
		return self:Pay(target or player, pp);
	end
);

--==============================================================================
--!CAPACITY

CryMP.ChatCommands:Add("capacity", {
		Access = 4, 
		Args = {
			{"player", Optional = true, GetPlayer = true,},
		}, 
		Info = "increase ammo capacity of a player",
		self = "Library",
	}, 
	function(self, player, channelId, target)
		return self:Capacity(type(target) == "table" and target or player, target);
	end
);
