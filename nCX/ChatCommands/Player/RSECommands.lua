--===================================================================================
-- MATRIX

CryMP.ChatCommands:Add("hydrothrusters", {
		Access = 2, 
		Info = "toggle hydrothrusters", 
		self = "RSE",
	}, 
	function(self, player, channelId, duration)
		local msg = 'HUD.BattleLogEvent(eBLE_Currency, "Hydro Thrusters [ DISABLED ]");';
		if (self.HydroThrustersEnabled) then
			self.HydroThrustersEnabled = false;
			self:Log("Hydro Thrusters disabled");
		else
			self.HydroThrustersEnabled = true;
			self:Log("Hydro Thrusters enabled");
			msg = 'HUD.BattleLogEvent(eBLE_Currency, "Hydro Thrusters [ ENABLED ]");';
		end
		g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..msg);
		return true;
	end
);

--===================================================================================
-- MATRIX

CryMP.ChatCommands:Add("sb", {
		Access = 3, 
		Args = {
			{"amount", Number = true, Info = "Number of barrels"},
		}, 
		Info = "spawn barrels",
		self = "Library",
	}, 
	function(self, player, channelId, amount, mod, distance)
		for i = 1, amount do 
		    self:Spawn(player, 20, "GUI");
		end
		CryMP.Msg.Chat:ToAll("Spawned [ "..amount.." ] Barrels!");
		return true;
	end
);

--===================================================================================
-- MATRIX

CryMP.ChatCommands:Add("testcmd", {
		Access = 5, 
		Info = "toggle hydrothrusters", 
		self = "RSE",
	}, 
	function(self, player, channelId, duration)
		local msg = [[
			local trolley = System.GetNearestEntityByClass(g_localActor:GetPos(), 500, "US_trolley");
			if (not trolley) then
			
				HUD.BattleLogEvent(eBLE_Warning, "Trolley not found!");
				return;
			end
			local p1=System.GetViewCameraPos();
			local p2=trolley:GetCenterOfMassPos();
			
						System.LogAlways((System.IsPointVisible(p2) and "VISIBLE" or "NOT VISIBLE"));
			local rvDir = {};			
			SubVectors( rvDir, p2, p1 );
			local hits = Physics.RayWorldIntersection(p1,rvDir,1,ent_terrain+ent_static,nil,nil,g_HitTable);
			if (hits == 0) then
				HUD.BattleLogEvent(eBLE_Currency, "Trolley should be visible!");
				return;
			end
			HUD.BattleLogEvent(eBLE_Currency, "Terrain or static in way :o");
			local ent = g_HitTable[1];
			System.LogAlways(dump(g_HitTable));
			if (ent.entity and ent.entity.id  == trolley.id) then
				HUD.BattleLogEvent(eBLE_Currency, "Trolley is visible!");
			end
		]]
		System.LogAlways(player.actor:GetNanoSuitEnergy().." enr | mem "..System.GetSystemMem());
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..msg);
		return true;
	end
);

--===================================================================================
-- SUIT

CryMP.ChatCommands:Add("suit", { 
		Info = "toggle nanosuit on off", 
		self = "RSE",
	}, 
	function(self, player, channelId, duration)		
		local msg = 'HUD.BattleLogEvent(eBLE_Currency, "Player '..player:GetName()..' has reactivated his Nanosuit");';
		local code = [[
			Sound.Play("sounds/interface:hud:hud_malfunction", g_Vectors.v000, bor(SOUND_LOAD_SYNCHRONOUSLY, SOUND_VOICE), SOUND_SEMANTIC_MP_CHAT);
			g_localActor.actor:ActivateNanoSuit(0);
		]]
		if (player.NANOSUIT_DISABLED) then
			player.NANOSUIT_DISABLED = false;
			self:Log("Player "..player:GetName().." has reactivated his Nanosuit");
			code = [[
				Sound.Play("sounds/interface:hud:hud_malfunction", g_Vectors.v000, bor(SOUND_LOAD_SYNCHRONOUSLY, SOUND_VOICE), SOUND_SEMANTIC_MP_CHAT);
				g_localActor.actor:ActivateNanoSuit(1);
			]]
		else
			player.NANOSUIT_DISABLED = true;
			self:Log("Player "..player:GetName().." has disabled his Nanosuit");
			msg = 'HUD.BattleLogEvent(eBLE_Currency, "Player '..player:GetName()..' has disabled his Nanosuit");';
		end
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..code);
		g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..msg);
		return true;
	end
);

--===================================================================================
-- MATRIX

CryMP.ChatCommands:Add("nitromode", {
		Access = 2, 
		Info = "toggle nitromode", 
		self = "RSE",
	}, 
	function(self, player, channelId, duration)		
		local msg = 'HUD.BattleLogEvent(eBLE_Currency, "Nitro Mode [ DISABLED ]");';
		if (self.NitroAvailable) then
			self.NitroAvailable = false;
			self:Log("Nitro Mode disabled");
		else
			CryMP.Msg.Chat:ToAll("NITRO:MODE :::: ENABLED!");
			self.NitroAvailable = true;
			self:Log("Nitro Mode enabled");
			msg = 'HUD.BattleLogEvent(eBLE_Currency, "Nitro Mode [ ENABLED ]");';
		end
		g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..msg);
		return true;
	end
);

--==============================================================================
--!FPS [PLAYER] 
CryMP.ChatCommands:Add("fixghost", {}, function(self, player, channelId)	
	local f = [[
		local pos = System.GetEntitiesByClass("Player");
		if (pos) then
			for i, t in pairs(pos) do
				if (t.id~=g_localActorId) then
					local v = t.inventory:GetCurrentItem();
					t.actor:Revive();
					t:Physicalize(0, 4, t.physicsParams);
					if (v) then v.item:Select(true);end
					if (t.actor:GetHealth()>0) then
						t:DrawSlot(1, 0);
					end
					System.LogAlways("$9[$4nCX$9] Reset : "..t:GetName());
				end
			end
		end
	]]
	g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
	--player.actor:SetSpectatorMode(3, NULL_ENTITY);
	--player.actor:SetSpectatorMode(0, NULL_ENTITY);
	return true;
end);

--==============================================================================
--!STORY 
CryMP.ChatCommands:Add("story", 
	{
		Info = "tell a story",
	}, 
	function(self, player, channelId)	
	local f = [[
		local p = System.GetEntityByName(']]..player:GetName()..[[');
		local sndFlags=bor(bor(SOUND_EVENT, SOUND_VOICE), SOUND_DEFAULT_3D);
		local fol=SOUND_SEMANTIC_PLAYER_FOLEY;
		p:PlaySoundEvent("rescue/prophet_rescue_ab1_C5440015", g_Vectors.v000, g_Vectors.v010, sndFlags, fol);	
	]]
	g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..f);
	return true;
end);

--==============================================================================
--!FPS [PLAYER] 

CryMP.ChatCommands:Add("fps", {
		Args = {
			{"seconds", Number = true, Optional = true,},
			{"player", GetPlayer = true, Access = 3, Optional = true,},
		},
		Info = "display my average fps",
		Delay = 20,
		self = "RSE",
		
	},
	function(self, player, channelId, seconds, target)
		if (target) then
			player = target;
		end
		seconds = seconds or 60;
		CryMP.Msg.Chat:ToPlayer(channelId, "GATHERING FPS ~~~ ("..seconds.." SEC AVRG) ~~~ "..player:GetName().." PLEASE STAND BY!");			
		local client_func = [[
			local startId = System.GetFrameID(); Script.SetTimer(1000 * ]]..seconds..[[, function() local endId = System.GetFrameID(); local diff = endId - startId; local average = diff / ]]..seconds..[[; local dx10 = CryAction.IsImmersivenessEnabled(); g_gameRules.game:SendChatMessage(2, g_localActorId, g_localActorId, "My average FPS: "..average.." | "..(dx10 and "Server DX10" or "Server DX9")); end);
		]];
		g_gameRules.onClient:ClWorkComplete(player.Info.Channel, player.id, "EX:"..client_func);
		return true;
	end
);
	-- IDs
	-- 1 Kyong
	-- 2 Koreaen AI Soldier (PS only)
	-- 3 Jester
	-- 4 Barnes
	-- 5 Sykes
	-- 6 Prophet
	
CryMP.ChatCommands:Add("kyong", {
		Info = "play as General Kyong",
		Delay = 10,
		self = "RSE",
		InGame = true,
	},
	function(self, player, channelId)
		return self:RequestModel(player, 1);
	end
);
	
CryMP.ChatCommands:Add("aztec", {
		Info = "play as Aztec",
		Delay = 10,
		self = "RSE",
		InGame = true,
	},
	function(self, player, channelId)
		return self:RequestModel(player, 3);
	end
);

CryMP.ChatCommands:Add("modelid", {
		Info = "play as a custom model",
		Delay = 10,
		self = "RSE",
		InGame = true,
		Args = {
			{"modelId", Number = true, },
		},
		Access = 1,
	},
	function(self, player, channelId, modelId)
		return self:RequestModel(player, modelId);
	end
);

CryMP.ChatCommands:Add("jester", {
		Info = "play as jester",
		Delay = 10,
		self = "RSE",
		InGame = true,
	},
	function(self, player, channelId)
		return self:RequestModel(player, 4);
	end
);

CryMP.ChatCommands:Add("sykes", {
		Info = "play as Michael Sykes",
		Delay = 10,
		self = "RSE",
		InGame = true,
	},
	function(self, player, channelId)
		return self:RequestModel(player, 5);
	end
);

CryMP.ChatCommands:Add("prophet", {
		Info = "play as Prophet",
		Delay = 10,
		self = "RSE",
		InGame = true,
	},
	function(self, player, channelId)
		return self:RequestModel(player, 6);
	end
);

--[[
CryMP.ChatCommands:Add("nomad", {
		Info = "play as Nomad",
		Delay = 10,
		self = "RSE",
		InGame = true,
	},
	function(self, player, channelId)
		return self:RequestModel(player, 0);
	end
); --relaxed_idleScratchbutt_01
]]

CryMP.ChatCommands:Add("bpm", {
	Access = 1,		
	Hidden = true,
		Args = {
			{"class", },
			{"bpm", Number = true,},
		},
	}, 
	function(self, player, channelId, class, bpm)
	player.Info.BPM = player.Info.BPM or { };
	if (not player.Info.BPM[class]) then
		player.Info.BPM[class] = bpm;
	end
end);

CryMP.ChatCommands:Add("scratch", {
		Info = "have a scratch",
		Delay = 10,
		self = "RSE",
	}, 
	function(self, player, channelId)	
	local f = [[
		local v = System.GetEntityByName(']]..player:GetName()..[[');
		if (v) then
			v:StartAnimation(0, "relaxed_idleScratchbutt_01"); 
		end
	]]
	g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..f);
	CryMP.Msg.Chat:ToAll(player:GetName().." is scratching his butt...");
end);

CryMP.ChatCommands:Add("piss", {
		Info = "have a piss",
		Delay = 10,
		self = "RSE",
	}, 
	function(self, player, channelId)	
	local f = [[
		local v = System.GetEntityByName(']]..player:GetName()..[[');
		if (v) then
			v:StartAnimation(0, "relaxed_relief_nw_01"); 
		end
	]]
	g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..f);
	CryMP.Msg.Chat:ToAll(player:GetName().." is having a piss...");
end);

CryMP.ChatCommands:Add("stuck", {Access = 1,}, function(self, player, channelId)	
	local f = [[
		for i, p in pairs(System.GetEntitiesByClass("Player")) do
			if (not p:IsDead()) then
				for i=1, 15 do
					Script.SetTimer(i*122, function()
						p:AddImpulse(-1, p:GetCenterOfMassPos(), g_Vectors.up, 233, 1);
					end);
				end
			end
		end
	]]
	g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
	CryMP.Msg.Chat:ToAll(player:GetName().." unstuck");
end);


CryMP.ChatCommands:Add("xxxmod", {Access = 5,}, function(self, player, channelId)
	local self = player;
	local PropInstance = self.PropertiesInstance;
		local model = self.Properties.fileModel;
	   local nModelVariations = self.Properties.nModelVariations;
	   if (nModelVariations and nModelVariations > 0 and PropInstance and PropInstance.nVariation) then
		  local nModelIndex = PropInstance.nVariation;
		  if (nModelIndex < 1) then
			 nModelIndex = 1;
		  end
		  if (nModelIndex > nModelVariations) then
			 nModelIndex = nModelVariations;
		  end
		  local sVariation = ('%.2d'):format(znModelIndex);
		  model = (model):gsub("_%d%d", "_"..sVariation);
		end
		--if (self.currModel ~= model) then
			--self.currModel = model;
			self:LoadCharacter(0, model);
			self:InitIKLimbs();
			self:ForceCharacterUpdate(0, true);
			--if (self.Properties.objFrozenModel and self.Properties.objFrozenModel~="") then
				self:LoadObject(1, self.Properties.objFrozenModel);
				self:DrawSlot(1, 0);
			--end
			self:CreateBoneAttachment(0, "weapon_bone", "right_item_attachment");
			self:CreateBoneAttachment(0, "alt_weapon_bone01", "left_item_attachment");
			self:CreateBoneAttachment(0, "alt_weapon_bone01", "left_hand_grenade_attachment");
			self:CreateBoneAttachment(0, "weapon_bone", "laser_attachment");
			--if (self.CreateAttachments) then
			--	self:CreateAttachments();
			--end
		--end
		--if (self.currItemModel ~= self.Properties.fpItemHandsModel) then
			self:LoadCharacter(3, self.Properties.fpItemHandsModel);
			self:DrawSlot(3, 0);
			self:LoadCharacter(4, self.Properties.fpItemHandsModel);
			self:DrawSlot(4, 0);
		--	self.currItemModel = self.Properties.fpItemHandsModel;
		--end
		player:SetActorModel();
end);
CryMP.ChatCommands:Add("zphys", {Access = 5,}, function(self, player, channelId)
	--player.actor:Physicalize();
	--player:Hide(1);
			player:LoadCharacter(3, player.Properties.fpItemHandsModel);
			player:DrawSlot(3, 0);
			player:LoadCharacter(4, player.Properties.fpItemHandsModel);
			player:DrawSlot(4, 0);
			--player.currItemModel = player.Properties.fpItemHandsModel;
	
end);

--==============================================================================
--!BULLETSTATS

CryMP.ChatCommands:Add("clinfo", {
		Access = 2,
		Info = "view info on clients",
		OpenConsole = true,
		Args = {
			{"mode", Optional = true,  
				Output = {
					{"bullets", "Display the Client bpm",},
					{"fps", "Display the Client fps",},
				},
			},
		},
	},
	function(self, player, channelId, mode)
		local tnames = {
			[0] = "SPECTATORS",[1] = "NK$9:$3TEAM",
			[2] = "US$9:$3TEAM",
		};
		local acc = {
			[0] = "$9Player",[1] = "$6Premium",
			[2] = "$8Moderator",[3] = "$3Admin",
			[4] = "$4Super-Admin",[5] = "$7Developer",
		};
		local function info(scan)
			local profileId = scan.Info.ID;
			local scanId = scan.Info.Channel;
			local NA="$9<n/a>";
			local FPS = scan.Info.FPS or NA;
			local bpm = scan.Info.BPM or {};
			local installed = scan.CLIENT_PATCH;
				
			local SCAR, FY71, SMG = bpm["SCAR"] or NA, bpm["FY71"] or NA, bpm["SMG"] or NA;
			local controller = "$9";
			local reported = CryMP.Reports and CryMP.Reports.Reports[profileId] and "$1($4REPORT$1) " or "";
			reported = (scan.DEVMODE and "$1($6DEVMODE$1)" or "")..reported;
			local loggedIn = nCX.AdminSystem(scanId) and "$5Logged In$9" or profileId;
			local add = mode == "domain" and scan.Info.Host or mode == "ip" and scan.Info.IP or mode == "profile" and scan.Info.ID or scan.Info.Country;
			local bpmData = "( $1"..string:lspace(5, SCAR).." $9| $1"..string:lspace(5, FY71).." $9| $1"..string:lspace(5, SMG).."$9 )";      
			CryMP.Msg.Console:ToPlayer(channelId, "$9($3%s$9) %s %s %s %s 		%s",
				string:lspace(4, scanId),
				string:rspace(12, acc[scan:GetAccess()]),
				string:rspace(19, "$9"..scan:GetName()).."$9",
				string:rspace(6, installed).."$9",
				string:rspace(8, FPS).."$9",
				bpmData
			);
		end
		
		local function sort(p1, p2)
			local acc1, acc2 = p1:GetAccess(), p2:GetAccess()
			if (acc1 == acc2) then
				return p2.Info.Channel < p1.Info.Channel;
			end
			return acc2 > acc1;
		end
		local total = 0;
		local line = ("="):rep(112);
		if (g_gameRules.class=="InstantAction") then
			local totalPlayers = {{},{},};
			local function sort(p1, p2)
				local acc1, acc2 = p1.actor:GetSpectatorMode(), p1.actor:GetSpectatorMode();
				if (acc1 == acc2) then
					return p2.Info.Channel < p1.Info.Channel;
				end
				return acc2 < acc1;
			end
			tnames = {
				[1] = "PLAYERS",[2] = "SPECTATORS",
			};
			local players = nCX.GetPlayers();
			for i, s in pairs(players) do
				if (s.actor:GetSpectatorMode() == 0) then
					totalPlayers[1][#totalPlayers[1]+1] = s;
				else
					totalPlayers[2][#totalPlayers[2]+1] = s;
				end
			end
			local infoBar = "SCAR		FY71		SMG";
			for i = 1, 2 do
				local players = totalPlayers[i];
				if (#players > 0) then
					table.sort(players, sort);
					CryMP.Msg.Console:ToPlayer(channelId, "$9"..line);
					CryMP.Msg.Console:ToPlayer(channelId, "$9 Slot  Access       Name                     FPS       Game      Profile   "..infoBar..string:lspace(27, "[ $3"..string:mspace(10, tnames[i]).." $9($1"..#players.."$9) ]"));
					CryMP.Msg.Console:ToPlayer(channelId, "$9"..line);
					--CryMP.Msg.Console:ToPlayer(channelId, "$9");	
					for i, scan in pairs(players) do
						info(scan);
					end
					total = total + #players;
				end
			end	
		else
			local infoBar = " SCAR  : FY71  : SMG";
			for i = 2, 0, -1 do
				local players = nCX.GetTeamPlayers(i);
				if (players) then
					table.sort(players, sort);
					CryMP.Msg.Console:ToPlayer(channelId, "$9"..line);
					CryMP.Msg.Console:ToPlayer(channelId, "$9 Slot  Access       Name                CL     FPS       		"..infoBar..string:lspace(47, "[ $3"..string:mspace(10, tnames[i]).." $9($1"..#players.."$9) ]"));
					CryMP.Msg.Console:ToPlayer(channelId, "$9"..line);
					--CryMP.Msg.Console:ToPlayer(channelId, "$9");	
					for i, scan in pairs(players) do
						info(scan);
					end
					total = total + #players;
				end
			end
		end
		if (total > 0) then
			CryMP.Msg.Console:ToPlayer(channelId, "$9"..line);
			nCX.SendTextMessage(3, "Open console with [^] or [~] to view list of #"..math:zero(total).." player(s)", channelId);
			return -1;
		end
		return false, "critical error - no players found in system"
	end
);

CryMP.ChatCommands:Add("simulator", {Access = 1,		
		Args = {
			{"seconds", Number = true, Optional = true,},
			{"player", GetPlayer = true, Access = 3, Optional = true,},
		},
	}, 
	function(self, player, channelId)	

	local f = [[
		g_localActor.physicsParams =
		{
			flags = 0,
			mass = 80,
			stiffness_scale = 53,
						
			Living = 
			{
				gravity = -122.81,
							
				mass = 8,
				air_resistance = -2250.5, 
				
				k_air_control = 0.9,
				
				max_vel_ground = 58,
				
				min_slide_angle = 45.0,
				max_climb_angle = 50.0,
				min_fall_angle = 50.0,
				
				timeImpulseRecover = 1.0,
				
				colliderMat = "mat_player_collider",
			},
		};
		g_localActor.gameParams.jumpheight = 24; 
		g_localActor:Physicalize(0, 4, g_localActor.physicsParams);
	]]
	g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
	--CryMP.Msg.Chat:ToAll(player:GetName().." is physicalized...");
end);

CryMP.ChatCommands:Add("resetsimulator", {Access = 5,		

	}, 
	function(self, player, channelId)	

	local f = [[
		g_localActor.physicsParams =
		{
			flags = 0,
			mass = 80,
			stiffness_scale = 73,
						
			Living = 
			{
				gravity = 9.81,
					
				mass = 80,
				air_resistance = 0.5,
				
				k_air_control = 0.9,
				
				max_vel_ground = 16,
				
				min_slide_angle = 45.0,
				max_climb_angle = 50.0,
				min_fall_angle = 50.0,
				
				timeImpulseRecover = 1.0,
				
				colliderMat = "mat_player_collider",
			},
		};
		g_localActor.gameParams.jumpheight = 24; 
		g_localActor:Physicalize(0, 4, g_localActor.physicsParams);
	]]
	g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..f);
	--CryMP.Msg.Chat:ToAll(player:GetName().." is physicalized...");
end);

CryMP.ChatCommands:Add("reconnect", {		
		Info = "reconnect to server",
	}, 
	function(self, player, channelId)	

	local f = [[
		g_gameRules:GotoState("PostGame");
		Script.SetTimer(200, function()
			System.ExecuteCommand("connect");
		end);
	]]
	g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
end);

CryMP.ChatCommands:Add("scanclient", {		
		Info = "check most cvars on a client",
		Access = 4,
		Args = {
			{"player", GetPlayer = true,},
		},
		self = "RSE",
	}, 
	function(self, player, channelId, target)	
		return self:ScanCVars(target, nil, channelId);
	end
);

CryMP.ChatCommands:Add("performancemode", {		
		Info = "toggle performance mode",
		Access = 1,
	}, 
	function(self, player, channelId)	

		local f = [[
			if (nCX.PerformanceMode) then
				local c=0; local ents=System.GetEntities();
				for i, e in pairs(ents) do
					if (e.Hidden_By_nCX and e:IsHidden()) then
						e:Hide(0);
						c=c+1;
					end
				end
				CryAction.Persistant2DText("Performance Mode [ Disabled ] "..c.." entities unhidden.", 2, {0.1,2,2,}, "perf", 3);
				nCX.PerformanceMode = false;
			else
				CryAction.Persistant2DText("Performance Mode [ Enabled ]", 2, {0.1,2,2,}, "perf", 3);
				nCX.PerformanceMode = true;
			end
		]]
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
		return true;
	end
);

CryMP.ChatCommands:Add("awake", {		
		Info = "which items are visible",
		Access = 5,
	}, 
	function(self, player, channelId)	

		local f = [[
			local count, visible = 0, 0;
			for i, s in pairs(System.GetEntities()) do
				if (s:IsHidden()) then
					s:AwakePhysics(1);
				end
			end
						
		]]
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
	end
);
		

CryMP.ChatCommands:Add("statusobjects", {		
		Info = "which items are visible",
		Access = 5,
	}, 
	function(self, player, channelId)	

		local f = [[
			local count, visible = 0, 0;
			local inRange = 0;
			for i, s in pairs(System.GetEntities()or {}) do

					local vis = CryAction.IsGameObjectProbablyVisible(s.id);
					local iPos = s:GetCenterOfMassPos();
					local inrange = DistanceVectors(g_localActor:GetCenterOfMassPos(), iPos) < 100;
					local indoors = System.IsPointIndoors(iPos);
					System.LogAlways("$9 "..(inrange and "$8RNG" or "   ").." $9~ "..(vis and "$5VISIBLE" or "$9INVISIB").." ~ "..s:GetName().." "..(indoors and "~ $3INDOORS $9~" or "").." ");
					count  = count + 1;
					if (vis == 1) then
						visible = visible + 1;
					end
					if (inrange) then
						inRange = inRange + 1;
					end

			end
			System.LogAlways("$3"..count.." $9entities, $5"..visible.." $9visible, $3"..inRange.." $9in range!");
			
		]]
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
		return true;
	end
);

CryMP.ChatCommands:Add("area", {		
		Info = "are you in area",
		Access = 5,
	}, 
	function(self, player, channelId)	

		local f = [[
			local y = System.IsPointIndoors(g_localActor:GetPos());
			if (y) then
				CryAction.Persistant2DText("INDOORS", 2, {0.1,2,2,}, "hello", 3);
			else
				CryAction.Persistant2DText("OUTSIDE", 2, {0.1,2,2,}, "hello", 3);
			end
			
		]]
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
		return true;
	end
);

CryMP.ChatCommands:Add("soundbug", {		
		Info = "fix a sound bug",
	}, 
	function(self, player, channelId)	
		local msg = "Mesa /n Refinery Mesa /n Mesa /n Mesa /n Mesa /nMesa /n";

		local f = [[
			System.SetCVar("s_soundenable", 0);
			Script.SetTimer(100, function()
				System.SetCVar("s_soundenable", 1);
			end);
			CryAction.Persistant2DText("Sound System Reseted!", 2, {0.1,2,2,}, "hello", 3);
		]]

		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
		
		return true;
	end
);		

CryMP.ChatCommands:Add("hitsound", {		
		Info = "install new hit sounds",
		Access = 0,
	},
	function(self, player, channelId, target)
	local f = [[
		function nCX:OnHit(S, hit)
			local ht=hit.type;
			if (ht=="lockpick") then
				return;
			end
			local shooter = hit.shooter;
			S.MusicInfo=S.MusicInfo or {}
			local armor = S.actor:GetArmor();
			local hs = g_gameRules:IsHeadShot(hit);
			S.MusicInfo.headshot = hs;
			S:LastHitInfo(S.lastHit, hit);	
			local selfHit=S.id == g_localActorId;
			if (ht:find("bullet")) then
				if (not S:IsBleeding()) then
					S:SetTimer(BLEED_TIMER, 0);
				end
				if(hit.damage > 10) then
					if(S.id == g_localActorId) then
						local s=armor > 10 and "armor" or "flesh";
						S:PlaySoundEvent("sounds/physics:bullet_impact:mat_"..s.."_fp", g_Vectors.v000, g_Vectors.v010, SOUND_2D, SOUND_SEMANTIC_PLAYER_FOLEY);
					end	
					if(armor > 10) then
						local d=hit.dir; 
						d.x = d.x * -1.0;
						d.y = d.y * -1.0;
						d.z = d.z * -1.0;
						Particle.SpawnEffect("bullet.hit_flesh.armor", hit.pos, d, 0.5);
					end
				end
				S:WallBloodSplat(hit);
				if (nCX.HitFeedback) then
					nCX:HitFeedback(S,hit);
				end
			end
			local cSA = tonumber(System.GetCVar("cl_hitShake"));
			local cSD = 0.35;
			local cSF = 0.15;
			if (ht=="melee") then
				S.lastMelee = 1;
				S.lastMeleeImpulse = hit.damage * 2;
				cSA = 33;
				cSF = 0.2;
			else
				S.lastMelee = nil;
			end
			if (S.actor:GetHealth() <= 0) then
				return;
			end
			if (not selfHit) then
				return;
			end
			S.actor:CameraShake(cSA,cSD,cSF,g_Vectors.v000);
			S.viewBlur = 0.5;
			S.viewBlurAmt = tonumber(System.GetCVar("cl_hitBlur"));
		end
	]];

	local f2   = [[
		for i, s in pairs(System.GetEntitiesByClass("Player")or{}) do
			function s.Client:OnHit(hit)
				nCX:OnHit(s,hit);
			end
			function s:DoPainSounds()
			end
		end
		function BasicActor:DoPainSounds()
		end		
		function nCX:HitFeedback(S,hit)
			if(tonumber(System.GetCVar("g_useHitSoundFeedback")) > 0) then
				if(hit.shooter and hit.shooter == g_localActor) then
					local sound;
					if (headshot) then
						sound="sounds/physics:bullet_impact:headshot_feedback_mp";
					else
						if(armorEffect) then
							sound="sounds/physics:bullet_impact:generic_feedback";
						else
							if(hit.material_type == "kevlar") then
								sound="sounds/physics:bullet_impact:kevlar_feedback";
							else
								sound="sounds/physics:bullet_impact:flesh_feedback";
							end
						end
						sound="sounds/physics:bullet_impact:helmet_feedback";
					end
					if (sound and (sound~="")) then
						S:PlaySoundEvent(sound, g_Vectors.v000, g_Vectors.v010, SOUND_2D, SOUND_SEMANTIC_PLAYER_FOLEY);
					end
				end
			end
		end
		CryAction.Persistant2DText("New Hit sounds successfully installed!", 2, {0.1,2,2,}, "log", 3);
	]],
	g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
	g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f2);
end);

CryMP.ChatCommands:Add("checkaimvars", {		
		Info = "check clients aim assist cvars",
		Access = 5,
		Args = {
			{"player", GetPlayer = true,},
		},
	}, 
	function(self, player, channelId, target)	
		local f = [[
			local cmds = {
				["aim_assistAimEnabled"] = 1,
				["aim_assistAutoCoeff"] = 0.5,
				["aim_assistCrosshairDebug"] = 0,
				["aim_assistCrosshairSize"] = 25,
				["aim_assistMaxDistance"] = 150,
				["aim_assistRestrictionTimeout"] = 20,
				["aim_assistSearchBox"] = 100,
				["aim_assistSingleCoeff"]= 1,
				["aim_assistSnapDistance"] = 3,
				["aim_assistTriggerEnabled"] = 1,
				["aim_assistVerticalScale"] = 0.75,
				["aim_assistAimEnabled"] = 1,
			};
			local cc = 0;
			for cvar, c in pairs(cmds) do	
				local m = tonumber(System.GetCVar(cvar));
				if (m and m~= c) then
					nCX:TS(100+cc);
				end
				cc = cc + 1;
			end
		]]
		g_gameRules.onClient:ClWorkComplete(target.Info.Channel, target.id, "EX:"..f);
		return true;
	end
);

CryMP.ChatCommands:Add("screen", {		
		Info = "toggle fullscreen mode",
	}, 
	function(self, player, channelId)	

		local f = [[
			local m = tonumber(System.GetCVar("r_fullscreen"));
			System.SetCVar("r_fullscreen", (m ~= 0 and 0 or 1));
			local mode = (m ~= 0 and "WINDOWED MODE" or "FULL SCREEN");
			CryAction.Persistant2DText(mode, 2, {0.1,2,2,}, "hello", 3);
		]]
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
		return true;
	end
);

--[[			System.LogAlways(dump(System));
			for i, p in pairs(System.GetEntitiesByClass("Player")) do
				if (p.id ~= g_localActorId) then
				end
			end

				CryAction.Persistant2DText(msg, 1, {0.1,2,2,}, "maps", 10);
			System.LoadFont("hud");
			System.EnableMainView(false);
			System.LogAlways(g_localActor.actor:GetNanoSuitEnergy().." enr | mem "..System.GetSystemMem());
			System.ActivatePortal(g_localActor:GetPos(), true, g_localActorId);
			]]

CryMP.ChatCommands:Add("log", {		
		Info = "toggle log verbosity",
	}, 
	function(self, player, channelId)	

		local f = [[
			local m = tonumber(System.GetCVar("log_verbosity"));
			local new = (m ~= 0 and 0 or 3);
			System.SetCVar("log_verbosity", new);
			CryAction.Persistant2DText("Log Verbosity: "..new, 2, {0.1,2,2,}, "log", 3);
		]]
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
		return true;
	end
);

CryMP.ChatCommands:Add("pausegame", {		
		Info = "toggle pause game",
	}, 
	function(self, player, channelId)	
		
		local f = [[
			CryAction.Persistant2DText("Press ESC and !pausegame to go back", 2, {0.1,2,2,}, "hello", 2);
			CryAction.PauseGame(true);
		]]
		if (player.PAUSED_GAME) then
			f = [[
				CryAction.PauseGame(false);
			]]
			player.PAUSED_GAME=nil;
		else
			player.PAUSED_GAME=true;
		end
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..f);
		return true;
	end
);

CryMP.ChatCommands:Add("smoke", {
		Access = 0,
		Info = "have a smoke",
	}, 
	function(self, player, channelId)	
	local f = [[
		local v = System.GetEntityByName(']]..player:GetName()..[[');
		if (v) then
			v:StartAnimation(0, "relaxed_idlesmokeout_cigarette_01");
		end
	]]
	g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..f);
	CryMP.Msg.Chat:ToAll(player:GetName().." is enjoying a cigarette...");
	return true;
end);



CryMP.ChatCommands:Add("holyheavens", {Access = 5,}, function(self, player, channelId)	
		local distance = distance and tonumber(distance) or 10;
		local pos, dir = CryMP.Library:CalcSpawnPos(player, distance);
		local ep = {
			class = "GUI";
			position = pos;
			orientation = dir;
			name = "NOOBNIGGA"
		};		
		if (class == "GUI" and GUI) then
			ep.name = GUI.Properties.objModel;
		end
		
		
		local f = [[
				local spawned = System.GetEntityByName("NOOBNIGGA");
				if (not spawned) then
					System.LogAlways("keine noob nigga");
				end
				Script.SetTimer(2000, function()
					function GUI.Client:ClDestroyNigger(id, niggerId)

							HUD.BattleLogEvent(eBLE_Information, "Function called!!!");

					end
					
					local NetExpose = {
						Class = spawned,
						ClientMethods = {
						},
						ServerMethods = {

						},
						ServerProperties = {
						},
					};
					local NT = NetExpose.ClientMethods;
					NT.ClDestroyNigger	= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID, STRINGTABLE};
					if (not Net.Expose(NetExpose)) then
						System.LogAlways("FAILED!");
						
					else
						System.LogAlways("OK!");
					end
				end);
				
			]]
			g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..f);
		
		local spawned = System.GetEntityByName("NOOBNIGGA") or System.SpawnEntity(ep);
		if (spawned) then
		
			
			CryMP.Msg.Chat:ToAll(player:GetName().." is enjoying a holyheavens...");
				function spawned.Client:ClDestroyNigger(id, niggerId)

						HUD.BattleLogEvent(eBLE_Information, "Function called!!!");

				end
								function GUI.Client:ClDestroyNigger(id, niggerId)

						HUD.BattleLogEvent(eBLE_Information, "Function called!!!");

				end
				CryMP:SetTimer(3, function()
					--if (not spawned.onClient or not spawned.onClient.ClDestroyNigger) then
						local NetExpose = {
							Class = GUI,
							ClientMethods = {
							},
							ServerMethods = {

							},
							ServerProperties = {
							},
						};
						local NT = NetExpose.ClientMethods;
						NT.ClDestroyNigger	= { RELIABLE_ORDERED, POST_ATTACH, ENTITYID, STRINGTABLE};
						if (not Net.Expose(NetExpose)) then
							System.LogAlways("FAILED!");
							
						else
							System.LogAlways("OK!");
						end
						local spawned = System.GetEntityByName("NOOBNIGGA")
					---else
					--	System.LogAlways("RMI EXISTS!");
					--end
					CryMP:SetTimer(5, function()
						spawned.onClient:ClDestroyNigger(channelId, player.id, "hola");
					end);
				end);
		end
	return true;
end);



CryMP.ChatCommands:Add("helena", {
		Info = "play as Helena",
		Delay = 10,
		self = "RSE",
		Access = 5,
		InGame = true,
	},
	function(self, player, channelId)
		return self:RequestModel(player, 7);
	end
);