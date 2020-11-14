
CryMP.ChatCommands:Add("barrels", {Access = 5, Info = "spawn barrels"}, function(self, player, channelId, remove)
	if (remove and remove:lower() == "remove") then
		local barrels = nCX.Barrels;
		if (barrels) then
			for barrelId, v in pairs(barrels) do
				System.RemoveEntity(barrelId);
			end
			nCX.Barrels = nil;
			return true;
		end
	end
	local pos, dir = CryMP.Library:CalcSpawnPos(player, 5);
	 
	CreateItemTable("CustomAmmoPickup");
	CustomAmmoPickup.Properties.objModel="objects/library/architecture/multiplayer/reactor_building/indutrial_building.cgf"; 
	CustomAmmoPickup.Properties.bPhysics = 1;
	CustomAmmoPickup.Properties.fMass = 400;
	CustomAmmoPickup.Properties.AmmoName="explosivegrenade";
	CustomAmmoPickup.Properties.Count=30;
	CustomAmmoPickup.Properties.bUsable=nil;
	CustomAmmoPickup.Properties.bPickable=nil;

	local barrel = {class = "CustomAmmoPickup"; 
		name = "Barrel_"..CryMP.Library:SpawnCounter();
		orientation = dir;
		position = pos;
	};
	local barrel = System.SpawnEntity(barrel);
	local physParam = {
		mass = barrel.Properties.fMass * 40000,
	};
	barrel:Physicalize(0, PE_RIGID, physParam);
	nCX.Barrels = nCX.Barrels or {};
	nCX.Barrels[barrel.id] = true;
	barrel:AwakePhysics(1);	
	--barrel:SetScale(5);	
end);
	
--==============================================================================
--!BOTSREMOVE

CryMP.ChatCommands:Add("botsremove", {
		Info = "bots remove",
		Access = 5,
	},
	function(self, player, channelId)
		for i, player in pairs(System.GetEntitiesByClass("Player")) do
			if (not player.Info or player.Info.Channel <= 0) then	
				System.RemoveEntity(player.id);
			end
		end
		return -1;
	end
);

--==============================================================================
--!weaponforce

CryMP.ChatCommands:Add("weaponforce", {
		Info = "force change weapon class across map",
		Access = 3,
		Args = {
			{"class", Output = {{"AlienMount",},{"C4",},{"DSG1",},{"Fists",},{"FY71",},{"GaussRifle",},{"Hurricane",},{"LAW",},{"Rock",},{"SCAR",},{"SCARTutorial",},{"Shotgun",},{"reset",},},},
		},
		self = "ServerMods",
	},
	function(self, player, channelId, class)
		if (not self.MapWeapons) then
			return false, "no weapons saved for this map"
		end
		for i, weapon in pairs(System.GetEntities()) do
			if (weapon.item and weapon.Properties.Respawn and weapon.Properties.Respawn.bRespawn == 1) then
				nCX.AbortEntityRespawn(weapon.id, true);
				System.RemoveEntity(weapon.id);
			end
		end
		local reset=class=="reset";
		for entId, data in pairs(self.MapWeapons) do
			local Respawn = data[4].Respawn;
			local parameters = {
				class = reset and data[1] or class;
				position = data[2];
				orientation = data[3];
				name = class..tostring(entId);
				properties = {Respawn = Respawn, initialSetup = data[4].initialSetup },
			};
			local item = System.SpawnEntity(parameters);
			if (item) then
			
			end
		end
		if (reset) then
			self:Log("Changed all map weapons to default classes");
		else
			self:Log("Changed all map weapons to "..class);
		end
		return true;
	end
);

--==============================================================================
--!RZONE

CryMP.ChatCommands:Add("rzone", {
		Access = 3, 
		Info = "fix nearest bunker", 
	}, 
	function(self, player, channelId, target)
		System.LogAlways(g_gameRules:GetState().." !");
		local classes = {"AlienEnergyPoint", "Factory", "SpawnGroup"};
		for i, class in pairs(classes) do
			for i, bunker in pairs(System.GetEntitiesByClass(class)) do
				for i, s in pairs(bunker.inside) do
					--System.LogAlways(i.." ===========");
					for v, f in pairs(s) do
						if (not nCX.GetPlayerByChannelId(v)) then
							System.LogAlways("Channel $4"..v.." $9(team "..i..") not in game! Deleting entry from "..bunker:GetName());
							bunker.inside[i][v] = nil;
						else
							System.LogAlways("Channel $4"..v.." $9(team "..i..") inside "..bunker:GetName());
						end
					end
				end
			end
		end
		local zoneId = g_gameRules.inCaptureZone[player.id];
		local bunker = zoneId and System.GetEntity(zoneId);
		if (bunker) then
			if (bunker.contested) then  
				System.LogAlways("contested");
			end
			for i, s in pairs(bunker.inside) do
				System.LogAlways(i.." ===========");
				for v, f in pairs(s) do
					System.LogAlways(v.." "..tostring(f));
				end
			end
				bunker.contested = nil;
				bunker.allClients:ClContested(false);
				CryMP.Msg.Chat:ToPlayer(channelId, "Contested deactivated for "..bunker:GetName());
				bunker.inside = {
					[1] = {},
					[2] = {},
				};
				return true;
		end
		--CryMP.Msg.Chat:ToPlayer(channelId, "NUKER - ( "..player:GetName().." ) BLASTS > > > 05 SOLDIERS in NK:ZONE");
		for i, player in pairs( nCX.GetPlayers() or {} ) do
			local tbl = player:GetGravity(true);
			--System.LogAlways(player:GetName().." =============");
			for v, s in pairs(tbl or {}) do
				--System.LogAlways(tostring(v).." $4"..tostring(s));
			end
		end
	end
);
--==============================================================================
--!SHITEN

CryMP.ChatCommands:Add("shiten", {
		Access = 5, 
		Info = "lift nearest shiten", 
	}, 
	function(self, player, channelId, target)
		local ShiTen = System.GetNearestEntityByClass(player:GetPos(), 20, "ShiTen");
		if (ShiTen) then
			local pos = ShiTen:GetWorldPos();
			pos.z = pos.z + 0.5;
			local parameters = {
			    class = ShiTen.class;
			    position = pos;
			    orientation = ShiTen:GetWorldAngles();
			    name = ShiTen:GetName().."_FIXED";
			};
			local item = System.SpawnEntity(parameters);
			item.item:SetMountedAngleLimits(ShiTen.Properties.MountedLimits.pitchMin,ShiTen.Properties.MountedLimits.pitchMax, ShiTen.Properties.MountedLimits.yaw	);
			System.RemoveEntity(ShiTen.id);
			return true;
		end
		return false, "no nearby shiten found";
	end
);

--==============================================================================
--!GOD
CryMP.ChatCommands:Add("god", {
		Access = 3, 
		Args = {
			{"player", GetPlayer = true, Optional = true,},
		}, 
		Info = "toggle godmode on player", 
	}, 
	function(self, player, channelId, target)
		local goal = target or player;
		if (not goal.actor:IsGod()) then
			CryMP.Msg.Chat:ToPlayer(channelId, "GOD-ON ::: "..goal:GetName());
			self:Log(CryMP.Users:GetMask(player.Info.ID).." "..goal:GetName().." god-on "..(player.id==goal.id and "themselves" or goal:GetName()));
			nCX.GodMode(goal.Info.Channel, true);
			nCX.GiveItem("SOCOM", channelId, false, false);
		else
			CryMP.Msg.Chat:ToPlayer(channelId, "GOD-OFF ::: "..goal:GetName());
			self:Log(CryMP.Users:GetMask(player.Info.ID).." "..goal:GetName().." god-off "..(player.id==goal.id and "themselves" or goal:GetName()));
			nCX.GodMode(goal.Info.Channel, false);
		end
		return true; 
	end
);	
--objects/library/lights/flare.cgf  equipment/lights.signal_flare1
--==============================================================================
--!CRAZYOBJECT
CryMP.ChatCommands:Add("crazyobject", {
		Access = 3, 
		Args = {
			{"mode", Number = true,},
			{"player", GetPlayer = true, Optional = true,},
		}, 
		Info = "shoot crazy objects of pistol or fists", 
	}, 
	function(self, player, channelId, mode, target)
		local goal = target or player;
		if (not mode or mode == 0) then
			CryMP.Msg.Chat:ToPlayer(channelId, "CRAZY-OBJECT [ OFF ] ::: "..goal:GetName());
			self:Log(CryMP.Users:GetMask(player.Info.ID).." "..goal:GetName().." crazy-object disabled on "..(player.id==goal.id and "themselves" or goal:GetName()));
			goal.actor:SetCrazyObject(0);
		else
			CryMP.Msg.Chat:ToPlayer(channelId, "CRAZY-OBJECT [ "..mode.." ] ::: "..goal:GetName());
			self:Log(CryMP.Users:GetMask(player.Info.ID).." "..goal:GetName().." crazy-object enabled ("..mode..") on "..(player.id==goal.id and "themselves" or goal:GetName()));
			goal.actor:SetCrazyObject(mode);
			nCX.GiveItem("SOCOM", channelId, false, false);
		end
		return true; 
	end
);	

--==============================================================================
--!CRAZYWEAPON
CryMP.ChatCommands:Add("crazyweapon", {
		Access = 3, 
		Args = {
			{"mode", Number = true,},
			{"player", GetPlayer = true, Optional = true,},
		}, 
		Info = "shoot crazy missiles of your weapon", 
	}, 
	function(self, player, channelId, mode, target)
		local goal = target or player;
		if (not mode or mode == 0) then
			CryMP.Msg.Chat:ToPlayer(channelId, "CRAZY-WEAPON [ OFF ] ::: "..goal:GetName());
			self:Log(CryMP.Users:GetMask(player.Info.ID).." "..goal:GetName().." crazy-weapon disabled on "..(player.id==goal.id and "themselves" or goal:GetName()));
			goal.actor:SetCrazyWeapon(0);
		else
			CryMP.Msg.Chat:ToPlayer(channelId, "CRAZY-WEAPON [ "..mode.." ] ::: "..goal:GetName());
			self:Log(CryMP.Users:GetMask(player.Info.ID).." "..goal:GetName().." crazy-weapon enabled ("..mode..") on "..(player.id==goal.id and "themselves" or goal:GetName()));
			goal.actor:SetCrazyWeapon(mode);
			nCX.GiveItem("SOCOM", channelId, false, false);
		end
		return true; 
	end
);	


--==============================================================================
--!EXEC

CryMP.ChatCommands:Add("exec", {
		Access = 5, 
		Args = {
			{"command", Info = "Your command", Concat = true,},
		}, 
		Info = "execute a command in server console", 
	}, 
	function(self, player, channelId, command)
		CryMP.Msg.Chat:ToPlayer(channelId, "Command executed ("..command..")");
		self:Log("Developer "..player:GetName().." executed command ("..command..")", true);
		System.ExecuteCommand(command);
		return true; 
	end
);

--==============================================================================
--!GFX
--[[
CryMP.ChatCommands:Add("gfx", {
		Access = 3, 
		Info = "toggle graphic mod", 
	}, 
	function(self, player, channelId, target)
		local cmds = {
			["e_sky_type"] 				= "1",
			["e_sky_update_rate"]		= "1",
			["r_DetailTextures"] 		= "1",
			["r_DetailNumLayers"] 		= "2",
			["r_DetailDistance"] 		= "8",
			["r_SSAO"] 					= "1",
			["r_SSAO_quality"] 			= "2",
			["r_SSAO_radius"] 			= "2",
			["r_SSAO_darkening"] 		= "3.5",
			["r_SSAO_amount"] 			= "0.150",
			["r_HDRRendering"] 			= "2",
			["r_HDRLevel"] 				= "0.9",
			["r_HDRBrightOffset"] 		= "8",
			["r_HDRBrightThreshold"] 	= "5",
			["r_TerrainAO"]  			= "7",
			["r_TerrainAO_FadeDist"]  	= "5.3",
			["r_eyeadaptationfactor"] 	= "0.44",
			["r_EyeAdaptionClamp"] 		= "4",
			["v_lights"] 				= "3",
			["v_deformable"] 			= "1",
			["r_refraction"] 			= "1",
			["e_ram_maps"] 				= "1",
			["sys_flash_edgeaa"] 		= "1",
			["e_terrain_ao"] 			= "1",
			["e_terrain_normal_map"] 	= "0",
			["e_max_entity_lights"] 	= "16",
			["r_HairSortingQuality"] 	= "1",
			["r_FillLights"]  			= "14",
			["e_particles_lights"] 		= "1",
			["i_lighteffectShadows"] 	= "3",
			-- Shadows
			["e_shadows"] 				= "1",
			["r_ShadowBlur"] 			= "0",
			["e_shadows_max_texture_size"] = "1200", --is 1024 default
			["r_ShadowJittering"] 		= "0.9",
			["e_gsm_lods_num"] 			= "5",
			["e_gsm_range"] 			= "3", 
			["e_shadows_cast_view_dist_ratio"] = "0.65", --is 0.8 default
			["r_ShadowsMaskResolution"] = "0",
			["e_gsm_cache"] 			= "1", -- + 10 FPS!!
			["e_voxel_make_shadows"] 	= "1",
			["e_shadows_water"] 		= "1",
			["e_shadows_slope_bias"] 	= "0",
		};
		if (not nCX.DefaultGFX) then
			nCX.DefaultGFX = {};
			for CVar, value in pairs(cmds) do
				nCX.DefaultGFX[CVar] = System.GetCVar(CVar);
			end
		end
		if (nCX.GFX_Loaded) then
			for CVar, value in pairs(nCX.DefaultGFX) do
				System.SetCVar(CVar, value);
				nCX.SetCVarSynch(CVar, false);
			end
			nCX.GFX_Loaded = nil;
			CryMP.Msg.Chat:ToPlayer(channelId, "GFX:MODE [ DISABLED ]");
		else
			local c = 0;
			for CVar, value in pairs(cmds) do
				local diff = value - nCX.DefaultGFX[CVar];
				if (diff ~= 0) then
					c = c + 1;
					nCX.SetCVarSynch(CVar, true);
					System.SetCVar(CVar, value);	
					System.LogAlways("[$4GFX$9] "..CVar.. "("..value..")");
				end
			end
			CryMP.GFX_Loaded = true;
			CryMP.Msg.Chat:ToPlayer(channelId, "GFX:MODE [ ENABLED ]");
		end
	end
);]]

--==============================================================================
--!SPECTATE

CryMP.ChatCommands:Add("spectate", {
		Access = 3, 
		Args = {
			{"player", GetPlayer = true,},
		}, 
		Info = "spectate a player", 
		self = "Refresh",
	}, 
	function(self, player, channelId, target)
		if (player.id == target.id) then
			return false, "you cannot spectate yourself";
		elseif (target.actor:GetSpectatorMode()~=0) then
			return false, "target is spectating";
		end
		self:SavePlayer(player, true, true);
		player.inventory:Destroy();
		nCX.OnChangeSpectatorMode(player.id, 3, target.id, true, false);
		local tchannelId = target.Info.Channel;
		local ping = nCX.GetPing(tchannelId);
		CryMP.Msg.Chat:ToPlayer(channelId, "SPECTATING ::: ("..target:GetName()..", Ping: "..ping..", Channel: "..tchannelId..")");
		self:Log(CryMP.Users:GetMask(player.Info.ID).." "..player:GetName().." is spectating "..target:GetName(), true);
		self.Spectate[channelId] = target.id;
		return true; 
	end
);

--==============================================================================
--!TAG

CryMP.ChatCommands:Add("tag", {
		Access = 3, 
		Info = "tag a player", 
		Args = {
			{"player", GetPlayer = true, CompareAccess = true,},
		}, 
	}, 
	function(self, player, channelId, target)
		if (target.actor:GetSpectatorMode()~=0) then
			return false, "target is spectating";
		end
		if (self.Tagged[target.id]) then
			nCX.RemoveMinimapEntity(target.id);
			CryMP.Msg.Chat:ToPlayer(channelId, "UN-TAGGED ::: "..target:GetName());
			self:Log(CryMP.Users:GetMask(player.Info.ID).." "..player:GetName().." untagged "..target:GetName());
			self.Tagged[target.id] = nil;
		else
			local channel = target.Info.Channel;
			nCX.AddMinimapEntity(target.id, 2, 0);
			local ping = nCX.GetPing(channel);
			CryMP.Msg.Chat:ToPlayer(channelId, "TAGGED ::: ("..target:GetName()..", Ping: "..ping..", Channel: "..channel..")");
			self:Log(CryMP.Users:GetMask(player.Info.ID).." "..player:GetName().." tagged "..target:GetName(), true);
			self.Tagged[target.id] = true;
		end
		return true;
	end
);

--==============================================================================
--!USAGE

CryMP.ChatCommands:Add("usage", {
		Access = 4,
		Info = "view usage of commands",
	}, 
	function(self, player, channelId)
		if (self.Usage) then
			local usage = {
				[0] = {}, [2] = {},
				[1] = {}, [3] = {},
				[4] = {}, [5] = {},
			};
			for access, info in pairs(self.Usage) do
				if (type(info) == "table") then
					for cmd, inf in pairs(info) do
						usage[access][#usage[access] + 1] = {
							cmd = cmd,
							Used = inf.Used or 0,
							Failed = inf.Failed or 0,
						};
					end
				end
			end
			local function sort_usage(a, b)
				if (a.Used == b.Used) then
					return a.Failed > b.Failed;
				end
				return a.Used > b.Used;
			end
			for i = 0, 5 do
				table.sort(usage[i], sort_usage);
			end
			CryMP.Msg.Console:ToPlayer(channelId, "$9");
			CryMP.Msg.Console:ToPlayer(channelId, "$9Log Started at $1"..self.Usage.Created);
			CryMP.Msg.Console:ToPlayer(channelId, "$9");
			for i = 5, 0, -1 do
				local info = usage[i];
				if (#info > 0) then
					CryMP.Msg.Console:ToPlayer(channelId, "$9Access : $7%s", CryMP.Users.Access[i] or "Player");
					for j, inf in pairs(info) do
						CryMP.Msg.Console:ToPlayer(channelId, "  $5!%s$9 executed $3%s$1x$9 (failed $4%s$1x$9)",
							string:rspace(16, inf.cmd or ""),
							string:lspace(4, math:zero(inf.Used)),
							string:lspace(4, math:zero(inf.Failed or 0))
						);
					end
				end
			end
			return -1;
		end
		return false, "no usage info available";
	end
);