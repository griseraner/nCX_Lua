--===================================================================================
-- INTEL

CryMP.ChatCommands:Add("intel", {
		Info = "gather important enemy data",
		Delay = 60,
		--self = "HQMods",
		BigMap = true,
		Map = {"ps/(.*)"},
	}, 
	function(self, player, channelId)
		local neutral = nCX.IsNeutral(player.id);
		if (not neutral and (player:IsDead() or player.actor:GetSpectatorMode()~=0)) then
			return false, "actively playing only"
		end
		-- LOAD ----------------------
		local teamId = nCX.GetTeam(player.id);
		local team = neutral and "$57OXICiTY" or teamId == 1 and "$2US-TEAM" or "$4NK-TEAM";
		local c=0;
		local players = nCX.GetPlayers()-- neutral and nCX.GetPlayers() or not neutral and CryMP.Ent:GetEnemyTeam(teamId);
		if (not players) then
			return false, "no players to scan"
		end
		local header = "$9"..("="):rep(112);
		CryMP.Msg.Console:ToPlayer(channelId, header);
		local us, nk; -- = self:GetInfo("health");
		us = us or "";
		nk = nk or "";
		local baselife = teamId == 1 and us or nk;
		local percent = "$9%";
		local display;
		if (neutral) then
			display = "US:BASE $4"..string:lspace(3, us)..percent.." $9- NK:BASE $4"..string:lspace(3, nk)..percent;
		else
			display = "ENEMY-BASE:DAMAGE $4"..string:lspace(3,baselife)..percent;
		end
		CryMP.Msg.Console:ToPlayer(channelId, "$9[ $1MI6 $9] "..string:rspace(89, "$1INTEL-REPORT $9: $1SCANNING $9[ %s $9| %s ]", "-").." [ $1MI6 $9]", team, string:lspace(3, baselife)..percent);
		CryMP.Msg.Console:ToPlayer(channelId, header);

		local vehicleclass = {
			["US_vtol"] = "$5VTOL",["US_tank"] = "$6TANK",["US_smallboat"] = "$9BOAT",["US_ltv"] = "$8JEEP",["US_hovercraft"] = "$5HOVER",
			["US_asv"] = "$6ASV",["US_apc"] = "$6APC",["Asian_truck"] = "$6TRUCK",["Asian_tank"] = "$6TANK",["US_trolley"] = "$9TROLLEY",
			["Asian_patrolboat" ] = "$9BOAT",["Asian_helicopter"] = "$5HELI",["Asian_apc"] = "$6APC",["Asian_aaa"] = "$5ANTI-AIR",
			["Civ_car1"] = "$9CAR",["Asian_ltv"] = "$8JEEP",
		};

		local vehicleweapon = {
			["GaussCannon"] = "$7GAUSS",["SideWinder_AscMod"] = "$6BOMBER",["USTankCannon"] = "$3TANK-SHELL",["AARocketLauncher"] = "$2BLASTER",
			["APCRocketLauncher"] = "$4INTERCEPTOR",["Asian50Cal"] = "$850-CAL",["Exocet"] = "$5EXOCET-MISSILE",["Hellfire"] = "$4HELLFIRE",
			["APCCannon"] = "$3BIG-GUN",["AHMachinegun"] = "$3MACHINE-GUN",["AACannon"] = "$4SPITFIRE",["VehicleUSMachinegun"] = "$3MACHINE-GUN",
			["TACCannon"] = "$4NUKE",["AVMachinegun"] = "$3MACHINE-GUN",["GaussAAA"] = "$1CLASSIFIED", ["USCoaxialGun_VTOL"] = "$9LOW-BUDGET",
			["AvengerCannon"] = "$3GUNNER",["AsianCoaxialGun"] = "$9LOW-BUDGET",["VehicleShiTenV2"] = "$3MACHINE-GUN",["VehicleMOAC"] = "$5MOAC",
			["VehicleMOACMounted"] = "$5MOAC",["VehicleMOARMounted"] = "$5MOAR",["VehicleMOAR"] = "$5MOAR", ["VehicleGaussMounted"] = "$7GAUSS",
			["VehicleSingularity"] = "$1CLASSIFIED",["SingularityCannon"] = "$1CLASSIFIED",["BunkerBuster"] = "$4FIREBOMB",
		};

		local weaponclass = {
			["SOCOM"] = "$6PISTOL",["DSG1"] = "$4SNIPER",["GaussRifle"] = "$7GAUSS",["TACGun"] = "$4NUKE-LAUNCHER",["Fists"] = "$5FISTS",
			["LockpickKit"] = "$8LOCK-PICK",["RadarKit"] = "$8RADAR-KIT",["RepairKit"] = "$8REPAIR-KIT",["DualSOCOM"] = "$6DUAL PISTOL",
			["Shotgun"] = "$3SHOTGUN",["SCAR"] = "$1SCAR",["SMG"] = "$3SUBMACHINE-GUN",["Binoculars"] = "$9BINOCULARS",["C4"] = "$4EXPLOSIVES",
			["Claymore"] = "$8CLAYMORE",["AVMine"] = "$8AT-MINE",["Detonator"] = "$1BOMB-TRIGGER",["FGL40"] = "$7NOOB-TUBE",["FY71"] = "$1FY71",["LAW"] = "$4RPG",
			["explosivegrenade"] = "$6FRAG-GRENADE",["AY69"] = "$5MINI-UZI",["Hurricane"] = "$4MINIGUN",["ShiTen"] = "$3GROUND-MG",["AlienMount"] = "$2FREEZE-RAY",
		};

		-- SCAN -----------------------
		for i, scan in pairs(players) do
			if (not scan:IsBoxing() and not scan:IsDuelPlayer() and nCX.IsPlayerActivelyPlaying(scan.id)) then
				c=c+1;
				
				local name = scan:GetName();
				local health = scan.actor:GetHealth();
				local distance = math.floor(player:GetDistance(scan.id));
				local distance = distance < 200 and "$4"..distance or distance;
				
				local intel = "----";
				local display_1, display_2;
				local temp = c < 10 and "0"..c or c;
				
				local vehicle = scan.actor:GetLinkedVehicle();
				if (vehicle) then
					display_1 = vehicleclass[vehicle.class] or "$9UNKNOWN";
					display_2 = math.floor((vehicle.vehicle:GetRepairableDamage() * 100));
					local seat = vehicle:GetSeat(scan.id);
					if (seat and seat.seat:GetWeaponCount()>0) then
						local weaponId 	= seat.seat:GetWeaponId(1);
						if (weaponId) then
							local class = System.GetEntityClass(weaponId);
							intel = vehicleweapon[class or ""] or "NONE";
						end
					end
				else
					local weapon = scan.inventory:GetCurrentItem();
					intel = weapon and weaponclass[weapon.class] or "NONE"
					local convert = {[0] = "SPEED",[1] = "STRENGTH",[2] = "CLOAK",[3] = "ARMOR",};
					local mode = scan.actor:GetNanoSuitMode();
					display_1 = convert[mode];
					display_2 = math.floor(scan.actor:GetNanoSuitEnergy() / 2);
				end
				-- DISPLAY --
				CryMP.Msg.Console:ToPlayer(channelId, "$9[ #$1%s $9] NAME:[$5%s$9]-GPS-[$1%sm$9]-$9HEALTH:[$3%s$9]-"..(vehicle and "$7VEHICLES$9:DAMAGE" or "$1NANOSUIT$9:ENERGY").."[$3%s$9|$3%s$9]-$9WEAPON:[$8%s$9]", 
					temp, 
					string:mspace(17,name), 
					string:lspace(5,distance), 
					string:lspace(3,health), 
					string:mspace(10,display_1), 
					string:lspace(3,display_2), 
					string:mspace(12,intel)
				);
				-- DISPLAY --
			end
		end
		-- SCAN COMPLETED -----------------------
		CryMP.Msg.Console:ToPlayer(channelId, header);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[ $1MI6 $9] $9: "..string:mspace(92,"[******* $1SCAN$9:$9COMPLETE $9*******]", "-").." $9: [ $1MI6 $9]");
		CryMP.Msg.Console:ToPlayer(channelId, header);
		nCX.SendTextMessage(3, "INTEL downloaded :: Open console to view report!", channelId);
		return -1;
	end
);

--===================================================================================
-- HQ

CryMP.ChatCommands:Add("hq", {
		Info = "display the hq status",
		Args = {
			{"reset", Access = 2, Optional = true, Output = {{"reset", "Reset HQ Damages"},},},
		},
		Delay = 20,
		self = "HQMods",
	}, 
	function(self, player, channelId, reset)
		if (reset == "reset") then
			for teamId, HQ in pairs(g_gameRules.hqs or {}) do
				HQ:OnReset();
			end
			CryMP.Msg.Chat:ToAccess(2, "HQs reset by "..player:GetName(), 2);
			return true;
		end
		local us, nk = self:GetInfo();
		--if (player.actor:GetSpectatorMode() ~= 0) then
			CryMP.Msg.Chat:ToPlayer(channelId, "US-HQ:DAMAGE [ "..us.." ]  NK-HQ:DAMAGE [ "..nk.." ]");
		--else
		--[[
			local teamId = nCX.GetTeam(player.id);
			local friendly = teamId == 2 and us or nk;
			friendly = friendly < 10 and " "..friendly or friendly;
			local enemy = teamId == 2 and nk or us;
			enemy = enemy < 10 and " "..enemy or enemy;
			CryMP.Msg.Flash:ToPlayer(channelId, {50, "#180000", "#db3434",}, tostring(friendly).."%", "<font size=\"32\"><b><font color=\"#007ACC\">TEAM:HQ <font color=\"#a8a8a8\">- [ </font><font color=\"#db3434\">%s</font><font color=\"#a8a8a8\"> ] - DAMAGE</font></b></font></font>");
			CryMP:SetTimer(3, function()
				CryMP.Msg.Flash:ToPlayer(channelId, {50, "#180000", "#db3434",}, tostring(enemy).."%", "<font size=\"32\"><b><font color=\"#db3434\">ENEMY:HQ <font color=\"#a8a8a8\">- [ </font><font color=\"#db3434\">%s</font><font color=\"#a8a8a8\"> ] - DAMAGE</font></b></font></font>");
			end);
		]]
		--end
		return true;
	end
);

--===================================================================================
-- SPY

CryMP.ChatCommands:Add("spy", {
		Info = "spy your enemy with this highly advanced scanner", 
		Delay = 300, 
		Price = 500,
		InGame = true,	
		BigMap = true,
		Map = {"ps/(.*)"},
	}, 
	function(self, player, channelId)
		local c=0;
		local team = { [1] = "US"; [2] = "NK"; };
		local teamId = nCX.GetTeam(player.id);
		local enemyId, int = 1, 1
		if (teamId == 1) then
			enemyId, int = 2, -1
		end
		for v = enemyId, teamId, int do
			local players = nCX.GetTeamPlayers(v);
			if (not players) then
				return false, "no enemy players";
			else
				for i, target in pairs(players) do
					if (target.actor:GetSpectatorMode()==0) then
						local tchannelId = target.Info.Channel;
						if (v == teamId) then
							self:SetLastUsage(tchannelId, "spy");
							if (target.id ~= player.id and not (target:IsBoxing() or target:IsDuelPlayer())) then
								nCX.SendTextMessage(0, "*** PLAYER [  "..player:GetName().."  ] GATHERED POSITIONS OF "..c.." ENEMY ***", tchannelId);
							end
						elseif (not target:IsMostWanted()) then
							local energy;
							if (not CryMP.Ent:IsEnemyNear(player, 20, true)) then
								energy = target.actor:GetNanoSuitEnergy()
								nCX.ProcessEMPEffect(target.id, 0.25);
							end 
							nCX.SendTextMessage(2, ":: [ WARNING ] :: ! :: POSITIONS REVEALED :: ! :: [ WARNING ] ::", tchannelId);
							CryMP.Ent:PlaySound(target.id, "alert");
							nCX.AddMinimapEntity(target.id, 2, 0);
							CryMP:SetTimer( 4,function()
								if (energy) then
									target.actor:SetNanoSuitEnergy(energy);
								end
								nCX.RemoveMinimapEntity(target.id);
							end);
							c=c+1;
						end
					end
				end
				if (s == teamId and c == 0) then
					return false, "no alive enemy players";
				end
			end
		end
		if (c ~= 0) then
			CryMP.Msg.Chat:ToTeam(teamId, "SPYING ::: [ "..c.." ] ::: POSITIONS GATHERED", 1);
			CryMP.Msg.Chat:ToTeam(enemyId, "! :: WARNING - POSITIONS REVEALED :: !", 1);
		end
		return true;
	end
);
