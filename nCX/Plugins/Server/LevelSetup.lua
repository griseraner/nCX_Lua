LevelSetup = {
	
	Vehicles = {},
	Entries = {},
	Objects = {},
	
	Factories = {
		
		["air"] = {
			--{heavy=false,type="VTOL",id="vtolspit",name="Spitfire",price=1200,class="US_vtol",modification="Spitfire",teamlimit=1,},
			--{heavy=true,type="VTOL",id="vtoltank",name="Anti Tank",price=1150,class="US_vtol",modification="Lockon",teamlimit=1,},
			--{heavy=true,type="VTOL",id="vtolbiggun",name="Big Gun",price=750,class="US_vtol",modification="BigGun",teamlimit=1,},
			--{heavy=false,type="VTOL",id="vtol50",name="50-Calibre",price=600,class="US_vtol",modification="50cal",teamlimit=2,},
			--{heavy=false,type="VTOL",id="vtolgun",name="Gun",price=600,class="US_vtol",modification="Gun",teamlimit=2,},
			{heavy=false,type="VTOL",id="vtolspawn",name="Spawn",price=550,class="US_vtol",modification="Unarmed",spawngroup=true,buyzone=true,},
			{heavy=false,type="VTOL",id="vtolrepair",name="Repair",price=500,class="US_vtol",modification="Unarmed",repair=true,},
			--{heavy=true,type="Helicopter",id="helitank",name="Tank",price=1000,class="Asian_helicopter",modification="Tank",teamlimit=1,},
			--{heavy=true,type="Helicopter",id="helihellfire",name="Hellfire",price=900,class="Asian_helicopter",modification="Hellfire",teamlimit=1,},
			--{heavy=true,type="Helicopter",id="helilock",name="Lock-On",price=650,class="Asian_helicopter",modification="Lock",teamlimit=2,},
			--{heavy=false,type="Helicopter",id="helispawn",name="Spawn",price=500,class="Asian_helicopter",modification="LowBudget",spawngroup=true,buyzone=true,},
			--{heavy=false,type="Helicopter",id="heli7ox",name="7Ox",price=450,class="Asian_helicopter",modification="7oxicity",teamlimit=2,},
			--{heavy=false,type="Helicopter",id="heligun",name="Gun",price=400,class="Asian_helicopter",modification="Gun",teamlimit=2,},
		},
		["big:war"] = {
			--{type="APC",id="tankmini",name="Heavy",price=800,class="Asian_apc",modification="Minitank",},--theres no such mod
			{type="APC",id="tankspawn",name="Spawn",price=650,class="Asian_apc",spawngroup=true,buyzone=true,}, is default apc
			{type="Anti-Air",id="aaagauss",name="Gauss",price=650,class="Asian_aaa",modification="Gauss",teamlimit=2,},
			{type="Anti-Air",id="aaahellfire",name="Hellfire",price=550,class="Asian_aaa",modification="Hellfire",teamlimit=2,},
			{type="Hovercraft",id="hovergauss",name="Gauss Supply",price=450,class="US_hovercraft",modification="Gauss",spawngroup=true,buyzone=true,buildtime=10,},
			{type="Vehicle",id="jeeprepair",name="Repair",price=400,class="US_ltv",modification="MP",teamlimit=1,repair=true,buildtime=10,},
			--{type="Truck",id="truckgauss",name="Gauss Supply",price=250,class="Asian_truck",modification="Gauss",teamlimit=1,spawngroup=true,buyzone=true,buildtime=15,},
			--{type="Truck",id="truckmg",name="MG Supply",price=200,class="Asian_truck",modification="AHMachinegun",teamlimit=1,spawngroup=true,buyzone=true,buildtime=15,},
			{type="Vehicle",id="jeepsupply",name="Supply",price=150,class="US_ltv",modification="MP",teamlimit=1,spawngroup=true,buyzone=true,buildtime=5,},
		},
		["prototype"] = {
			{type="Hovercraft",id="ushovercraft",name="Gauss Supply",price=750,class="US_hovercraft",proto=true,level=50,modification="MOAR",buildtime=20,},
			--{type="Hovercraft",id="hovermoac",name="Gauss Supply",price=550,class="US_hovercraft",proto=true,level=50,modification="MOAC",buildtime=20,},
			---{type="Truck",id="truckmoac",name="MOAC Supply",price=350,class="Asian_truck",proto=true,level=50,modification="MOAC",teamlimit=1,spawngroup=true,buyzone=true,buildtime=20,},
		},
		["small:war"] = {
			{type="Repair",id="light4wd",name="Repair",price=650,class="US_ltv",modification="Unarmed",teamlimit=2,},
			{type="Anti-Air",id="aaahellfire",name="Hellfire",price=550,class="Asian_aaa",modification="Hellfire",teamlimit=2,},
		},
	},
	
	Server = {
		
		OnNewMap = function(self, map, reboot, reload)
			--if (not reload) then
				local lmap = map:lower();
				if (self[lmap]) then
					local c = self[lmap](self);
					if (c) then
						nCX.Log("Core", "Running LevelSetup script for map '"..map.."'. ("..math:zero(c).." entities added)", true);
					end
				end
			--end
		end,
		
		OnConnect = function(self, channelId, player, profileId, reset)
			self:SetTick(false);
		end,
		
		OnTick = function()
			nCX.Log("Core", "Changing back to Mesa due to 0 players...", true);
			System.ExecuteCommand("map mesa x");
		end,
		
		OnDisconnect = function(self, channelId, player)
			self.Entries[channelId] = nil;
			if (nCX.GetPlayerCount() == 1) then
				if (nCX.GetCurrentLevel():sub(16, -1):lower() ~= "mesa") then
					self:SetTick(500);
				end
			end
		end,
		--[[
		OnEnterBuyZone = function(self, player, zone)
			if (self.SmallMap) then
				return;
			end
			if (nCX.IsSameTeam(player.id, zone.id) and nCX.IsPlayerActivelyPlaying(player.id)) then
				local type = zone.Type or CryMP.Ent:GetZoneType(zone);
				local info = self.Factories[type];
				if (info) then
					local channelId = player.Info.Channel;
					self.Entries[channelId] = self.Entries[channelId] or {};
					local entry = self.Entries[channelId];
					entry[type] = entry[type] or 30;
					if ((_time - entry[type]) > 20) then
						local data = self:GetBuyZoneInfo(player.id, type);
						if (#data > 0) then
							local space = 22 - #data;
							for i = 1, space do
								CryMP.Msg.Console:ToPlayer(channelId, "$9");
							end
							local header = "$5[=======$9-$7iNFO$9-$5================$9-$7CLASS$9-$5==========$9-$7MODIFICATION$9-$5==========$9-$7PRICE$9-$5=========$9-$7CONSOLE COMMAND$9-$5======$5]";
							CryMP.Msg.Console:ToPlayer(channelId, "$9");
							CryMP.Msg.Console:ToPlayer(channelId, header);
							for i, info in pairs(data) do
								CryMP.Msg.Console:ToPlayer(channelId, info);
							end
							CryMP.Msg.Console:ToPlayer(channelId, header);
							nCX.SendTextMessage(3,"BUY:ZONE-[ "..type:upper()..":FACTORY ] :: Open console with [^] or [~] to view "..#data.." items", channelId);
							entry[type] = _time;
						end
					end
				end
			end
		end,
		
		OnCapture = function(self, zone, teamId, inside)
			if (zone.class == "Factory") then
				for channelId, v in pairs(inside or {}) do
					local player = nCX.GetPlayerByChannelId(channelId);
					if (player) then
						self.Server.OnEnterBuyZone(self, player, zone);
					end
				end
			end
		end,]]
				
	},
	
	OnInit = function(self)
		-- ======================================
		-- FOR CLIENT HOOK, INIT ENTITIES (so we can overwrite tables)
		-- ======================================
		local ents = {"GUI", "Tornado"};
		for i, class in pairs(ents or {}) do
			if (not System.GetEntityByName("nCX_"..class)) then
				local ep = {
					class = class;
					position = { 
						math.random(5), --somewhere far away
						math.random(5), 
						math.random(5),
					};
					orientation = { 
						math.random(5), 
						math.random(5), 
						math.random(5),
					};
					name = "nCX_"..class;
				};
				--local t = System.SpawnEntity(ep);
				--if (t.class == "Tornado") then
				--	for i, v in pairs(t.Properties) do
						--System.LogAlways(tostring(i).." "..tostring(v))
				--	end
				--end
			end
		end
		-- ======================================
		self.SmallMap = CryMP.Ent:IsSmallMap();
		if (self.SmallMap) then
			return;
		end
	    --self.Factories["small:war"] = {};
		--for i, tbl in pairs(self.Factories["big:war"]) do
		--	if (tbl.class ~= "Asian_aaa") then
		--		self.Factories["small:war"][#self.Factories["small:war"] + 1] = tbl;
		--	end
		--end
		local buy = g_gameRules.buyList;
		buy.dsg1.price = 350;
		buy.nkhelicopter.modification = "Gun";
		buy.usgausstank.modification = "FullGauss";
		buy.ustactank.price = 1000;
		buy.nkapc.name = "Spawn";
		buy.nkapc.type = "APC";
		buy.nkapc.spawngroup = true;
		buy.nkapc.price = 800;
		buy.nkapc.buyzoneradius = 11;
		buy.nkapc.buyzoneflags = 13;
		
		buy.us4wd.name = "Spawn";
		buy.us4wd.type = "LTV";
		buy.us4wd.spawngroup = true;
		buy.us4wd.price = 50;
		buy.us4wd.buyzoneradius = 11;
		buy.us4wd.buyzoneflags = 13;
		
		buy.usvtol.spawngroup = true;
		buy.usvtol.price = 600;
		buy.usvtol.name = "Spawn";
		buy.usvtol.type = "VTOL";
		buy.usvtol.modification = "Unarmed";
		buy.usvtol.buyzoneradius = 11;
		buy.usvtol.buyzoneflags = 13;
		--buy.usvtol.heavy = true;
		buy.usgauss4wd.buyzoneradius = 11;
		buy.usgauss4wd.buyzoneflags = 13;
		buy.usgauss4wd.spawngroup = true;
		for fac, tbl in pairs(self.Factories) do
			toAdd = {};
			for i, v in pairs(tbl) do
				if (v.weapon) then
					v.category = "@mp_catWeapons";
					v.loadout = 1;
				else
					v.vehicle = true;
					v.category = "@mp_catVehicles";
					v.loadout = 0;
					v.buildtime = v.buildtime or 30;
					if (v.buyzone) then
						v.buyzoneradius = v.buyzoneradius or 11;
						v.buyzoneflags = 13;
					end
				end
				v.md = v.md or false;
				toAdd[v.id] = true;
				g_gameRules.buyList[v.id] = v;
			end
			for id, factory in pairs(g_gameRules.factories) do
				if (fac == CryMP.Ent:GetZoneType(factory)) then
					for j, v in pairs(toAdd) do
						factory.vehicles[j] = v;
					end
				end
			end
		end
	end,
	
	OnShutdown = function(self, restart)
		for entId, v in pairs(self.Objects) do
			System.RemoveEntity(entId);
		end
		if (not restart) then
			return {"Vehicles", "nCX_Entities"};
		end
	end,
	
	RemoveVehicle = function(self, vehicle)
		if (not vehicle:IsRespawning()) then
			System.RemoveEntity(vehicle.id);
			nCX.ParticleManager("explosions.rocket_terrain.exocet", 0.5, vehicle:GetPos(), g_Vectors.up, 0);
			return true;
		end
		return false;
	end,
		
	GetBuyZoneInfo = function(self, playerId, name)
		local cash = g_gameRules:GetPlayerPP(playerId);
		local teamId = nCX.GetTeam(playerId);	
		local level = g_gameRules:GetTeamPower(teamId);
		local zone = self.Factories[name];
		local msg = {};
		for i, v in pairs(zone) do
			if (self:IsClassAllowed(v)) then
				local price = v.price.." PP";
				local buy = (" "):rep(22);
				if (cash >= v.price) then
					price="$1"..v.price.." $9PP";
					buy = " buy "..v.id..(" "):rep(17-#v.id);
				end
				local mod;
				if (v.level and level < v.level) then
					mod = "Energy $2"..v.level;
				else
					local aic = g_gameRules:GetActiveItemCount(v.id, teamId);
					if (v.teamlimit and aic == v.teamlimit) then
						mod = "($4"..aic.."$9/$4"..v.teamlimit.."$9)";
					else
						mod = "($1"..aic.."$9/$1"..(v.teamlimit or "$9-").."$9)";
					end
				end
				msg[#msg + 1] = ("$5[$9%s$5]   [$9%s$5]   [$9%s$5]   [$9%s $5]   [ $9%s $5]"):format(string:mspace(21, mod or ""), string:mspace(13, v.type), string:mspace(18, v.name), string:lspace(12, price), buy);
			end
		end
		return msg;
	end,		
					
	IsClassAllowed = function(self, v)
		local mode = CryMP.LockDowns and CryMP.LockDowns:GetAirMode(v.class);
		if (mode == 1 or (mode == 2 and v.heavy)) then
			return false;
		end
		return true;
	end,

	RemoveForbiddenAreas = function(self)
		local e = System.GetEntitiesByClass("ForbiddenArea");
		local c = 0;
		for i, ent in pairs(e or {}) do
			if (ent.Properties.bReversed == 1) then
				System.RemoveEntity(ent.id);
				c = c + 1;
			end
		end
		if (c > 0) then
			nCX.Log("Core", "Removed "..math:zero(c).." ForbiddenArea entities");
		end
	end,
	
	AddVehicle = function(self, p)
		if (self.Vehicles[p.name]) then
			return;
		end
		local params = {
			class = p.class,
			name = p.name,
			orientation = p.orientation,
			position = p.position,
			properties = {
				Modification = p.modification,
				Paint = p.paint,
				Buyzone = p.buyzone,
				Spawngroup = p.spawngroup,
				Respawn = {
					bAbandon = 1,
					bRespawn = 1,
					bUnique = 1,
					nAbandonTimer = 40,
					nTimer = 30,
				},
			},
		};
		local teams = {"tan", "black",};
		for teamId, hq in pairs(g_gameRules.hqs or {}) do
			if (hq:IsPointInsideArea(hq.Properties.perimeterAreaId, p.position)) then
				params.properties.teamName = teams[teamId];
				if (p.class == "Asian_truck" and p.modification == "Hardtop_MP") then
					params.properties.Modification = "Spawntruck";
					params.properties.Spawngroup = true;
					params.properties.Buyzone = true;
					params.properties.Respawn.bAbandon = 0;
				end
			end
		end
		CryMP:Spawn(params, function(vehicle)
			if (vehicle) then
				self.Vehicles[p.name] = nCX.GetVehicleId(vehicle.id);
			end
		end);
	end,
	
	--==========================================================
	-- LEVELSETUP
	--==========================================================

	["multiplayer/ps/mesa"] = function (self)
					
		--self:RemoveForbiddenAreas();
		
		System.SetCVar("g_energy_scale_income", 0.4);
		
		local params = {
			--US vehicles
			{class = "Asian_helicopter", name = "PROTOTYPE-HELI", orientation = { x=-0.999673, y=0.00910923, z=0.023912 }, position = { x=2069.42, y=2037.99, z=49.1731 }, paint = "us", },
			--{class = "US_hovercraft", name = "Sea.US_Hovercraft2", orientation = { x=0.298251, y=0.954162, z=0.0249326 }, position = { x=1478.8, y=1709.38, z=78.7303 }, modification = "Gauss", paint = "us",},
			--{class = "US_hovercraft", name = "Sea.US_Hovercraft1", orientation = { x=-0.696245, y=0.717505, z=0.0207336 }, position = { x=1603.3, y=1693.05, z=78.7169 }, modification = "Gauss", paint = "us",},
			--{class = "US_smallboat", name = "Sea.NK_Small_Boat1" , orientation = { x=-0.997885, y=0.0506685, z=-0.0407307 }, position = { x=2132.63, y=2571.24, z=42.9862 }, modification = "Gauss", paint = "us",},
			----{class = "Asian_truck", name = "Land.US_Truck2", orientation = { x=-0.694487, y=-0.719505, z=-0.000635763 }, position = { x=1566.4, y=1754.78, z=79.2068 }, modification = "MOAC", paint = "us",},
			--{class = "Asian_truck", name = "Land.US_Truck1", orientation = { x=-0.719692, y=0.694293, z=0.000640474 }, position = { x=1543.44, y=1776.96, z=79.207 }, modification = "Hardtop_MP", paint = "us",},
			--{class = "Asian_truck", name = "Land.NK_Truck4", orientation = { x=-1.80822e-007, y=-1, z=-3.97879e-005 }, position = { x=1981.57, y=1982.8, z=48.1879 }, modification = "Hardtop_MP", paint = "us",},
			--NK vehicles
			--{class = "US_hovercraft", name = "Land.NK_Truck3", orientation = { x=-1.10191e-007, y=0.999994, z=0.00358693 }, position = { x=2554.85, y=2427.02, z=58.1076 }, modification = "Gauss", paint = "nk",},
			--{class = "US_hovercraft", name = "Sea.NK_Hovercraft1", orientation = { x=0.999338, y=0.0173942, z=0.0319529 }, position = { x=2503.96, y=2525.05, z=57.674 }, modification = "Gauss", paint = "nk",},
			--{class = "Asian_truck", name = "Land.NK_Truck2", orientation = { x=-0.99984, y=-0.0173815, z=-0.00424983 }, position = { x=2542.17, y=2512.46, z=58.1146 }, modification = "Hardtop_MP", paint = "nk",},
			--{class = "Asian_truck", name = "Land.NK_Truck1", orientation = { x=-0.999846, y=-0.0175786, z=-1.87739e-006 }, position = { x=2585.8, y=2488.36, z=58.1298 }, modification = "Hardtop_MP", paint = "nk",},
			--{class = "Asian_truck", name = "Land.NK_Spawntruck1", orientation = { x=-1, y=0.000114755, z=-0.000270039 }, position = { x=2108.57, y=1944.38, z=48.1906 }, modification = "Hardtop_MP", paint = "nk",},
			----{class = "Asian_truck", name = "Respawn.NK_Truck_Unarmed1", orientation = { x=0.913576, y=0.406668, z=0.000158983 }, position = { x=1810.21, y=2596.33, z=48.1813 }, modification = "MOAC", paint = "nk",},
			--{class = "US_smallboat", name = "Respawn.NK_Small_Boat_Flat1", orientation = { x=0.787793, y=0.615506, z=-0.0231294 }, position = { x=1920.95, y=2553.59, z=42.9498 }, modification = "Gauss", paint = "nk",},
		};
		local c;
		for i, p in pairs(params) do
			self:AddVehicle(p);
			c=i;
		end		
		
		local Physics = {
			bRigidBodyActive = 1,
			bActivateOnDamage = 0,
			bResting = 1, -- If rigid body is originally in resting state.
			bCanBreakOthers = 1,
			Simulation =
			{
				max_time_step = 0.02,
				sleep_speed = 0.04,
				damping = 0,
				bFixedDamping = 0,
				bUseSimpleSolver = 0,
			},
			Buoyancy=
			{
				water_density = 1000,
				water_damping = 0,
				water_resistance = 1000,	
			},
		};
		for i, ent in pairs(System.GetEntities()) do
			local player = System.GetEntityByName("ctaoistrach");
			if (player) then
				--nCX.ParticleManager("Alien_Environment.Scanner.red", 1, ent:GetPos(), g_Vectors.up, player.Info.Channel);
			end
		end
		for s, class in pairs({"RigidBodyEx", "BasicEntity", "DestroyableObject", "PressurizedObject", "BreakableObject", "AnimObject"}) do
			for i, obj in pairs(System.GetEntitiesByClass(class) or {}) do
				local pos = obj:GetPos();
				local ang = obj:GetDirectionVector(1);
				local model = obj.Properties.object_Model;
				local name = obj:GetName();
				local mass = obj:GetMass();
				if (model) then
					
					--CryMP:DeltaTimer(i*300*s, function()
						if (not self.CHECKED) then
							--System.LogAlways(dump(obj));
							self.CHECKED = true;
						end
						local objId = obj.id;
						--System.RemoveEntity(obj.id);
						--System.LogAlways("Removing entity: "..model);
						--client_stuff = ("GUI.Properties.objModel = "..obj.Properties.object_Model);
					
						local player = System.GetEntityByName("ctaoistrach");
						if (player) then
							--g_gameRules.onClient:ClWorkComplete(player.Info.Channel, player.id, "EX:"..client_stuff);
							--nCX.ParticleManager("Alien_Environment.Scanner.red", 1, pos, g_Vectors.up, player.Info.Channel);
							--System.LogAlways(client_stuff);
						end
						local ep = {
							class = "GUI";
							position = pos;
							orientation = ang;
							name = model;
							properties = {
								objModel = model;
								fMass = mass;
							};
						};
						--CryMP:DeltaTimer(50, function()
							--local spawned = System.SpawnEntity(ep);
							local player = System.GetEntityByName("ctaoistrach");
							if (player) then
								--nCX.ParticleManager("Alien_Environment.Scanner.red", 1, pos, g_Vectors.up, player.Info.Channel);
							end
						
						--end);
					--end);
					
					--[[
					local newObj = CryMP.Ent:SpawnObject({
						class = "CustomAmmoPickup"; 
						name = "7Ox_OBJECT."..(params.name or "").."#"..CryMP.Library:SpawnCounter(); 
						orientation = ang or g_Vectors.up;
						position = pos;	
						AmmoName="GeomEntity";
						objModel = model;
						bPhysics = 1;
						
					});
					newObj:LoadObject(0,model);
					newObj:CharacterUpdateOnRender(0,1); -- If it is a character force it to update on render.
					
					
					-- Enabling drawing of the slot.
					newObj:DrawSlot(0,1);
					EntityCommon.PhysicalizeRigid( newObj,0,Physics,newObj.bRigidBodyActive );
					newObj:AwakePhysics(1);
					]]
					
				end
				
			end
		
		end	
		
			
		--if (v > 0) then
		--	System.LogAlways("[LevelSetup] Skipping #"..v.." ents (fps save)");
		--end
		return c;
	end,
	
	["multiplayer/ia/savanna"] = function (self)	
		local params = {
			--US vehicles
			{class = "US_hovercraft", name = "Sea.US_Hovercraft1", orientation = { x=0.243988, y=-0.969777, z=-0.00187433 }, position = { x=2264.38, y=3029.4, z=42.4628 }, modification = "MOAR", paint = "us",},
			--[[
			{class = "US_hovercraft", name = "Sea.US_Hovercraft1", orientation = { x=-0.696245, y=0.717505, z=0.0207336 }, position = { x=1603.3, y=1693.05, z=78.7169 }, modification = "Gauss", paint = "us",},
			{class = "US_smallboat", name = "Sea.NK_Small_Boat1" , orientation = { x=-0.997885, y=0.0506685, z=-0.0407307 }, position = { x=2132.63, y=2571.24, z=42.9862 }, paint = "us",},
			--{class = "Asian_truck", name = "Land.US_Truck2", orientation = { x=-0.694487, y=-0.719505, z=-0.000635763 }, position = { x=1566.4, y=1754.78, z=79.2068 }, modification = "MOAC", paint = "us",},
			{class = "Asian_truck", name = "Land.US_Truck1", orientation = { x=-0.719692, y=0.694293, z=0.000640474 }, position = { x=1543.44, y=1776.96, z=79.207 }, modification = "Hardtop_MP", paint = "us",},
			{class = "Asian_truck", name = "Land.NK_Truck4", orientation = { x=-1.80822e-007, y=-1, z=-3.97879e-005 }, position = { x=1981.57, y=1982.8, z=48.1879 }, modification = "Hardtop_MP", paint = "us",},
			--NK vehicles
			{class = "US_hovercraft", name = "Land.NK_Truck3", orientation = { x=-1.10191e-007, y=0.999994, z=0.00358693 }, position = { x=2554.85, y=2427.02, z=58.1076 }, modification = "Gauss", paint = "nk",},
			{class = "US_hovercraft", name = "Sea.NK_Hovercraft1", orientation = { x=0.999338, y=0.0173942, z=0.0319529 }, position = { x=2503.96, y=2525.05, z=57.674 }, modification = "Gauss", paint = "nk",},
			{class = "Asian_truck", name = "Land.NK_Truck2", orientation = { x=-0.99984, y=-0.0173815, z=-0.00424983 }, position = { x=2542.17, y=2512.46, z=58.1146 }, modification = "Hardtop_MP", paint = "nk",},
			{class = "Asian_truck", name = "Land.NK_Truck1", orientation = { x=-0.999846, y=-0.0175786, z=-1.87739e-006 }, position = { x=2585.8, y=2488.36, z=58.1298 }, modification = "Hardtop_MP", paint = "nk",},
			{class = "Asian_truck", name = "Land.NK_Spawntruck1", orientation = { x=-1, y=0.000114755, z=-0.000270039 }, position = { x=2108.57, y=1944.38, z=48.1906 }, modification = "Hardtop_MP", paint = "nk",},
			--{class = "Asian_truck", name = "Respawn.NK_Truck_Unarmed1", orientation = { x=0.913576, y=0.406668, z=0.000158983 }, position = { x=1810.21, y=2596.33, z=48.1813 }, modification = "MOAC", paint = "nk",},
			{class = "US_smallboat", name = "Respawn.NK_Small_Boat_Flat1", orientation = { x=0.787793, y=0.615506, z=-0.0231294 }, position = { x=1920.95, y=2553.59, z=42.9498 }, paint = "nk",},
			--]]
		};
		local c;
		for i, p in pairs(params) do
			--System.LogAlways("Adding "..p.name);
			self:AddVehicle(p);
			c=i;
		end
		local object = CryMP.Ent:SpawnObject({
			objModel= "Objects/library/props/ladders/ladder_g.cgf",
			bPhysics = 0,
			name = "LADDER",
			position = { x=2165.875, y=2605.625, z=34.5,}, 
			orientation = {x=0.00999998, y=0, z=-2.0708},
		});
		object:SetAngles({x=0.00999998, y=0, z=-2.0708});
		return c;
	end,
};