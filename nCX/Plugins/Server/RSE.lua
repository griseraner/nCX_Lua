local CL_VERSION = "3.0";

RSE = {
	
	---------------------------
	--		Config
	---------------------------
	Tick = 1,
	TimeOut = 60,
	Players = {}, -- Players with Final ClWorkComplete
	Process = {}, -- Players in DebugGun Process
	Chatters = {}, -- Keep track of Chatters
	DebugGuns = {}, -- DebugGuns on Server
	ModelSelector = {}, --Keep track of Player models
	Queue = {},
	CVarAnomalies = {},
	CVars = {},
	Mods = {},
	MaxSizeByte = 50000,
			
	Server = {
		--[[---------------------------
		--		PreConnect		
		---------------------------
		PreConnect = function(self, channelId, player, profileId, restart)
			player.actor:SetSpectatorMode(2, g_gameRules.id);
			self:Initiate(channelId, player);
		end,]]
		---------------------------
		--		OnConnect		
		---------------------------
		OnConnect = function(self, channelId, player, profileId, restart)
			g_gameRules.onClient:ClWorkComplete(channelId, player.id, "GetVersion");
		end,
	
		OnChatMessage = function(self, type, sender, command, msg)
			local channelId = sender.Info.Channel;
			if (self.Chatters[channelId]) then
				g_gameRules.otherClients:ClWorkComplete(channelId, g_gameRules.id, "EX:nCX:SignalEffect("..channelId..")");
				self.Chatters[channelId]=nil;
			end
		end,
		---------------------------
		--		OnRevive		
		---------------------------		
		OnRevive = function(self, channelId, player, vehicle, first)
			if (first) then
				--[[
				if ((player.CLIENT_PATCH == 7 or player.CLIENT_PATCH == 8)) then
					--self:ToTarget(channelId, 'g_localActor:PlaySoundEventEx("sounds/interface:hud:hud_reboot",SOUND_DEFAULT_3D,1,{x=0,y=0,z=0},30,300,SOUND_SEMANTIC_AI_READABILITY); HUD.DisplayBigOverlayFlashMessage("        nCX Client        ",0,2,2,{1,0.5,0});');
					--CryMP:SetTimer(2, function()
						self:GetMods(player, true);
					--end);
				else]]
				if (player.Info.Client == 9) then
					--CryMP:SetTimer(1, function()
						self:ToTarget(channelId, self.ClientUpgradeSuccessful);
						nCX.SendTextMessage(0, "", player.Info.Channel);
					--end);
				end
			end
		end,
		---------------------------
		--		OnKill		
		---------------------------		
		OnKill = function(self, hit, shooter, target)
			if (self.Chatters[target.Info.Channel] and not shooter ~= target) then
				CryMP.Msg.Chat:ToAll("PLAYER "..shooter:GetName().." killed "..target:GetName().." who was chatting.. SHAME ON "..shooter:GetName().."!");
			end
			if (shooter.Info and hit.accuracy and hit.accuracy > 0) then
				local code = [[
					HUD.BattleLogEvent(eBLE_Currency,"Accuracy: ]]..hit.accuracy..[[%");
				]];
				g_gameRules.onClient:ClWorkComplete(shooter.Info.Channel, shooter.id, "EX:"..code);
			end
		end,
		---------------------------
		--		OnClientPatched		
		---------------------------		
		OnClientPatched = function(self, player, mode)
			local channelId = player.Info.Channel;
			local name = player:GetName();
			if (mode == 7) then -- Client has clicked DebugGun. Patch ClWorkComplete again, this time with the V2
				player.Info.Client = mode;
				self:Install(player, mode);
				--end);
			elseif (mode == 8) then -- Client Patched ClWorkComplete to V2
				player.Info.Client = mode;
				self:GetMods(player, true); --Start install!
				System.LogAlways("[RSE] "..name.." ~ STARTING INSTALL (8)...");
				self:Log("Client "..name.." starting install...", 3);
			elseif (mode == 9) then -- Version Check! Client already has the latest ClWorkComplete (previously connected or nCX client..)
				player.Info.Client = mode;
				--self:Log("Client "..name.." already has modified ClWorkComplete. Installing...", 3);
				self:GetMods(player, false);
			elseif (mode == 10) then -- All Mods installed
				local installTime = "";
				local time = self.Players[channelId] and self.Players[channelId][3];
				if (time) then
					installTime = "("..("%.2f"):format(_time - time).." sec)";
				end
				player.Info.Client = mode;
				System.LogAlways("[RSE] "..name.." ~ SUCCESS ("..(player.Info.Client or "N/A")..") "..installTime);
				local msg = "Client "..name.." successfully "..(player.Info.Client == 9 and "re-" or "").."installed "..installTime;
				self:Log(msg, 3);
				nCX.Log("Player", msg);
				self.Players[channelId]=nil;
				player.actor:ClientInstalled(true);
				
				local CryMP_Enhanced = tonumber(System.GetCVar("cl_crymp")) == 2;
				if (CryMP_Enhanced) then
					System.LogAlways("installing custom rmis on "..player:GetName());
					local c = [[
						local NetSetup = {
							Class = Player,
							ClientMethods = {
								Revive				= { RELIABLE_ORDERED, NO_ATTACH },
								MoveTo				= { RELIABLE_ORDERED, NO_ATTACH, VEC3 },
								AlignTo				= { RELIABLE_ORDERED, NO_ATTACH, VEC3 },
								ClearInventory		= { RELIABLE_ORDERED, NO_ATTACH },
							},
							ServerMethods = {},
							ServerProperties = {
								busy = BOOL,
							},
						};

	
							NetSetup.ClientMethods.SetCustomModel = { RELIABLE_ORDERED, NO_ATTACH, STRING, VEC3, BOOL };
							System.LogAlways("$4[CryMP_Enhanced] $9Loading custom player.lua RMIs");

						Net.Expose(NetSetup);
					]]
				--	g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..c);
					--TEST
					CryMP:SetTimer(5, function()
						if (player.allClients.SetCustomModel) then
							player.allClients:SetCustomModel("$3Guten Tag", g_Vectors.up, true);
							System.LogAlways("called");
						else
							System.LogAlways("no SetCustomModel");
						end
					end);
				end

			
				
			elseif (mode == 12) then --Packet Received
				self:OnPacketReceived(player);
			elseif (mode == 13) then --Client reported some LUA error
				local mod;
				local data = self.Players[channelId];
				if (data) then
					mod = self.Mods and self.Mods[data[2]];
				end
				local msg = "Client "..name.." reported LUA error!"..(mod and " (Plugin not installed: "..mod..")" or "");
				nCX.Log("Player", msg, true);
				self:Log("Client "..name.." reported LUA error!"..(mod and " (Plugin not installed: $5"..mod.."$9)" or ""), 5);
			elseif (mode == 14) then -- Nitro Mode confirm
				--local veh = {["Asian_aaa"]=true,["Asian_tank"]=true,["Asian_smallboat"]= true,["US_tank"]=true,["US_ltv"]=true,["Civ_car1"]=true,["Asian_truck"]=true,["Asian_ltv"]=true,["US_trolley"]=true,["US_hovercraft"]=true,};
				--if (not veh[car.class]) then
				--	HUD.BattleLogEvent(eBLE_Information,"Nitrous Oxide System is not available for this vehicle.");
				--	return false;
				--end
				if (not self.NitroAvailable) then
					local msg = "HUD.BattleLogEvent(eBLE_Information,'Nitro currently disabled!');";
					g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..msg);
					return;
				end
				local veh = player.actor:GetLinkedVehicle();
				if (veh) then
					g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:nCX:StartNitro()");
					local speed = veh:GetSpeed();
					--if (speed > 20) then
					local name = name;
					local msg = "HUD.BattleLogEvent(eBLE_Information,'"..name.." activated Nitro Mode ("..math.floor(veh:GetSpeed()).." mph)'); nCX:NitroEffect("..channelId..");";
					g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..msg);
					local s = veh;
					local pos = s:GetWorldPos()
					local dir = s:GetDirectionVector(1);
					math:ScaleVectorInPlace(dir, -2.5);
					math:FastSumVectors(pos, pos, dir);
					pos.z = pos.z + 0.5
					dir.x = -dir.x
					dir.y = -dir.y
					dir.z = -dir.z
					nCX.ParticleManager("explosions.small_fuel_tank.smallfuel_can", 0.6, pos, dir, 0);
					--end
				end
			elseif (mode == 15 or mode == 16) then -- HydroThrusters ON / OFF
				if (not self.HydroThrustersEnabled) then
					return;
				end
				player.actor:HydroThrusters(mode == 15 and true or false);
				g_gameRules.allClients:ClWorkComplete(player.id, "EX:if (nCX.HydroThrusters)then nCX:HydroThrusters("..channelId..", '"..(mode == 15 and "1" or "0").."')end");
			elseif (mode == 17 or mode == 18) then -- Client is chatting
				if (not self.Chatters[channelId] and not player:IsDead() and not player.actor:GetLinkedVehicleId()) then
					g_gameRules.otherClients:ClWorkComplete(channelId, player.id, "EX:if(nCX.SignalEffect)then nCX:SignalEffect("..channelId..","..mode..")end");	
					self.Chatters[channelId]=mode;
				end
			elseif (mode == 19) then
				--dev mode!
				self:Log("$4Warning: $9Client "..name.." is running Dev Mode!", 3);
				player.DEVMODE = true;
			elseif (mode == 20 or mode == 21) then -- Aim assist
				if (mode == 20) then
					self:Log("$4Warning: $9Client "..name.." 'aim_assistRestrictionTimeout' not default! "..(player.Info.Controller and "$4GAMEPAD CONNECTED!" or ""), 3);
					nCX.Log("Action", "Client "..name.." 'aim_assistRestrictionTimeout' not default! "..(player.Info.Controller and "GAMEPAD CONNECTED!" or ""), true);
				else
					self:Log("$4Warning: $9Client "..name.." has disabled Aim-Assist Timeout! "..(player.Info.Controller and "$4GAMEPAD CONNECTED! $48AIM ASSIST ENABLED" or ""), 3);
					nCX.Log("Action", "Client "..name.." has disabled Aim-Assist Timeout! "..(player.Info.Controller and "GAMEPAD CONNECTED! AIM ASSIST ENABLED" or ""), true);
				end
			elseif (mode == 24 or mode == 25 or mode == 26) then
				local item = player.inventory:GetCurrentItem();
				if (item) then
					CryMP.Msg.Chat:ToAccess(5, "Recoil Hack? "..name.." | "..item.class.." | "..(mode == 24 and "PRONE" or mode == 25 and "CROUCH" or "STAND"), 2);
					System.LogAlways("Recoil Hack detected on "..name.." | "..item.class.." | "..(mode == 24 and "PRONE" or mode == 25 and "CROUCH" or "STAND"));
				end
			elseif (mode == 27) then
				--if (player:GetSpeed() > 0) then
				--	CryMP.Msg.Chat:ToAccess(4, "Stuck in air! "..name.." | Server Speed : "..player:GetSpeed().." mph | Client Speed: 0 mph");
				--	g_gameRules.allClients:ClWorkComplete(player.id, "EX:nCX:OnEvent("..channelId..",'blind')");
				--end
				nCX:CheatControl(player, "Air stuck", "Client report", false, false);
			elseif (mode == 28) then
				--CryMP.Msg.Chat:ToAccess(4, "Speed Hack? "..name.." | "..player:GetSpeed().." mph");
				--g_gameRules.allClients:ClWorkComplete(player.id, "EX:nCX:OnEvent("..channelId..",'scream')");
				nCX:CheatControl(player, "Speed Hack", "Client report", false, false);
			elseif (mode == 29) then
				g_gameRules.allClients:ClWorkComplete(player.id, "EX:nCX:OnEvent("..channelId..",'scream')");
			elseif (mode == 30) then
				player.actor:SetPhysicalizationProfile("ragdoll");
			elseif (mode == 31 or mode == 32 or mode == 33) then
				local info = mode == 31 and "flags";
				if (mode == 32) then
					info = "gravity";
				elseif (mode == 33) then
					info = "mass";
				end
				nCX:CheatControl(player, "Fly hack", info, false, true);
			--RADIO / TAUNT command requests
			elseif (mode > 40 and mode < 50) then
				local id = mode - 40;
				local data;
				local sound, msg="","";
				if (id > 6) then
					local folder="ai_marine_2/";
					local random=14;
					local targetDownRandom=14;
					local bulletRainRandom=9;
					local tauntRandom=10;
					local typ="Taunt";
					if (player.CM==1) then
						folder="ai_kyong/";targetDownRandom=8;
					elseif (player.CM==2 or nCX.GetTeam(player.id)==1) then
						player.NKS=player.NKS or math.random(5);
						folder="ai_korean_soldier_"..player.NKS.."_eng/";
					elseif (player.CM==3) then
						folder="ai_jester/";tauntRandom=11;typ="Staring";
					elseif (player.CM==4) then
						folder="ai_marine_3/";
					elseif (player.CM==5) then
						folder="ai_psycho/";tauntRandom=11;typ="Staring";
					elseif (player.CM==6) then
						folder="ai_prophet/";tauntRandom=10;typ="Staring";
					end
					if (id == 7) then
						local m=math.random(0, tauntRandom); 
						sound=typ.."_"..(m<10 and "0"..m or m); msg=typ; 
					elseif (id == 8) then
						local m=math.random(0, bulletRainRandom);
						sound="bulletrain_"..(m<10 and "0"..m or m); msg="Bulletrain"; 
					elseif (id == 9) then
						local m=math.random(0, targetDownRandom);
						local L=player.CM==1 and "targetdown" or "targetdownreply";
						sound=L.."_"..(m<10 and "0"..m or m); msg="Target Down"; 
					end
					data = "nCX:Taunt("..id..","..channelId..",'"..folder..sound.."','"..msg.."');";
					--System.LogAlways(data);
				else
					local nk=nCX.GetTeam(player.id) == 1;
					local folder = nk and "mp_korean/nk" or "mp_american/us";
					local x = "0"..math.random(3);
					if (id == 1) then
						sound="_F6_6_take_bunker"; msg="Take That Bunker";
					elseif (id == 2) then
						sound="_F7_6_sniper"; msg="Sniper Spotted";
					elseif (id == 3) then
						sound="_F5_10_request_pickup_"..x; msg="Requesting Pickup";
					elseif (id == 4) then
						sound="_F5_7_watch_out_"..x; msg="Watch Out";
					elseif (id == 5) then
						sound="_F5_9_hurry_up_"..x; msg="Hurry Up";
					elseif (id == 6) then
						sound="_F5_8_well_done_"..x; msg="Well Done";
					end
					data = "nCX:Radio("..id..","..channelId..",'"..folder..sound.."','"..msg.."');";
				end
				g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..data);
			elseif (mode == 70) then
				local msg = name.." physics rendering bug fix success (ghost)";
				CryMP.Msg.Chat:ToAccess(2, msg);
				System.LogAlways("$9[$4nCX$9] "..msg);
				self:Log(msg);
			elseif (mode == 80 or mode == 81 or mode == 82) then
				self:ScanCVars(player, mode);
			elseif (mode == 83) then
				local center, dir = CryMP.Library:CalcSpawnPos(player, 2);
				local IE = System.GetNearestEntityByClass(center, 5, "InteractiveEntity");
				if (IE) then
					local physParam = {
						mass = 200,
					};
					--System.LogAlways(dump(IE));
					--CryAction.CreateGameObjectForEntity(IE.id);
					--CryAction.BindGameObjectToNetwork(IE.id);
					--CryAction.ForceGameObjectUpdate(spawned.id, true);
					--IE:Physicalize(0, PE_RIGID, physParam);
				--	IE:AwakePhysics(1);
					for i = 1, 5, 1 do
						CryMP:DeltaTimer(20 * i, function()
							local pos = IE:GetWorldPos();
							pos.z = pos.z + math.random(0.1, 1.2);
							--IE:AddImpulse(-1, pos , g_Vectors.up,50, 1);
						end);
					end
					local c = [[
						local IE=System.GetEntityByName("]]..IE:GetName()..[[");
						if (IE) then
							IE:Use();
						end
					]];
					g_gameRules.otherClients:ClWorkComplete(channelId, g_gameRules.id, "EX:"..c);
				end
			end
		end,
		---------------------------
		--		OnDisconnect		
		---------------------------	
		OnDisconnect = function(self, channelId, player)
			self.Players[channelId] = nil;
			self.Process[channelId] = nil;
			if (self.Chatters[channelId]) then
				g_gameRules.allClients:ClWorkComplete(g_gameRules.id, "EX:if (nCX.SignalEffect)then nCX.SignalEffect("..channelId..")end");
				self.Chatters[channelId]=nil;
			end
			self.ModelSelector[player.id] = nil;
			local gunId = self.DebugGuns[player.id];
			if (gunId) then
				System.RemoveEntity(gunId);
				self.DebugGuns[player.id]=nil;
			end
		end,
		---------------------------
		--		OnFirstVehicleEntrance		
		---------------------------	
		OnFirstVehicleEntrance = function(self, vehicle, seat, player)
			if (not self.NitroAvailable) then
				return;
			end
			local veh = {["Asian_aaa"] = true, ["Asian_tank"] = true, ["Asian_smallboat"]= true, ["US_tank"] = true, ["US_ltv"] = true, ["Civ_car1"] = true, ["Asian_truck"] = true, ["Asian_ltv"] = true, ["US_trolley"] = true, ["US_hovercraft"] = true,};
			if (veh[vehicle.class]) then
				if (player.Info.Client and not player.NITRO_NOTIFICATION) then
					local client_stuff = "HUD.DisplayBigOverlayFlashMessage('[F3] Nitro Boost  [F4] Lock Vehicle', 3, 200, 300, {0.2,1,0.2});";
					g_gameRules.onClient:ClWorkComplete(player.Info.Channel, player.id, "EX:"..client_stuff);
					player.NITRO_NOTIFICATION = true;
				end
			end
		end,
		---------------------------
		--		OnChangeSpectatorMode		
		---------------------------	
		OnGameEnd = function(self, t, t, playerId) 			
			if (g_gameRules.class ~= "InstantAction") then 
				return 
			end
			local win = [[
				Sound.Play("mp_korean/nk_commander_win_mission", g_Vectors.v000, bor(SOUND_LOAD_SYNCHRONOUSLY, SOUND_VOICE), SOUND_SEMANTIC_MP_CHAT);g_gameRules.game:TutorialEvent(eTE_GameOverWin);g_gameRules.game:GameOver(1);
			]];
			local player = nCX.GetPlayer(playerId);
			if (player) then
				local channelId = player.Info.Channel;
				local lose = [[
					Sound.Play("mp_korean/nk_commander_fail_mission_01", g_Vectors.v000, bor(SOUND_LOAD_SYNCHRONOUSLY, SOUND_VOICE), SOUND_SEMANTIC_MP_CHAT);g_gameRules.game:TutorialEvent(eTE_GameOverLose);g_gameRules.game:GameOver(-1);
				]];
				g_gameRules.otherClients:ClWorkComplete(channelId, player.id, "EX:"..lose);
				g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..win);
			else
				
				g_gameRules.allClients:ClWorkComplete(g_gameRules.id, "EX:"..win);
			end
		end,
		---------------------------
		--		OnChangeSpectatorMode		
		---------------------------	
		OnTimerAlert = function(self, time) 
			if (g_gameRules.class ~= "InstantAction") then 
				return;
			end
			local tbl = {[120]="nk_commander_2_minute_warming_01",[60]="nk_commander_1_minute_warming_01",[30]="nk_commander_30_second_warming_01",[5]="nk_commander_final_countdown_01"};
			local s = [[Sound.Play("mp_korean/]]..tbl[time]..[[", g_Vectors.v000, bor(SOUND_LOAD_SYNCHRONOUSLY, SOUND_VOICE), SOUND_SEMANTIC_MP_CHAT);]];
			if (nCX.NextMap) then
				s = s.."HUD.BattleLogEvent(eBLE_Currency, 'Next map: "..nCX.NextMap.."');";
			end
			g_gameRules.allClients:ClWorkComplete(g_gameRules.id, "EX:"..s);
		end,
		---------------------------
		--		OnChangeTeam		
		---------------------------	
		OnChangeTeam = function(self, player, teamId, oldTeamId)
			if (teamId ~= 0) then
				local info = not nCX.Spawned[player.Info.Channel] and "entered" or "switched to";
				local teamName = teamId == 1 and "NK" or "US";
				g_gameRules.otherClients:ClWorkComplete(player.Info.Channel, player.id, "EX:HUD.BattleLogEvent(1,'"..player:GetName().." has "..info.." team "..teamName.."');");
				if (self:Initiate(player.Info.Channel, player)) then
					return true;
				end
			end
			if (self.Process[player.Info.Channel]) then
				CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "Click to Join Game!");
				return true;
			end
			local modelId = self.ModelSelector[player.id];
			if (modelId) then
				if (player.CM and player.CM ~= 0 and oldTeamId ~= 0 and (teamId == 1 or teamId == 2)) then
					if (teamId==2 and player.CM<3) or (teamId==1 and player.CM>2) then
						self.ModelSelector[player.id]=nil;
						player.CM = 0;
						local f = [[
							local teamId=]]..teamId..[[;
							local p = nCX:GP(]]..player.Info.Channel..[[);
							if (not p) then return end
								p.CM=0;
								p.CMPath=nil;
							end
						]];
						g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..self:Optimize(f));
					end
				end
			end
		end,
		---------------------------
		--		OnChangeTeam		
		---------------------------	
		OnChangeSpectatorMode = function(self, player)
			if (self.Process[player.Info.Channel]) then
				CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "Click to Join Game :)");
				return true;
			end
		end,
		---------------------------
		--		OnEnterVehicleSeat		
		---------------------------	
		OnEnterVehicleSeat = function(self, vehicle, seat, player, entering, seatId)
			if (seatId == 2 and seat.seat:GetWeaponCount() > 0) then
				if (nCX.GetTeam(player.id) ~= 1) then
					g_gameRules.allClients:ClWorkComplete(player.id, "EX:nCX:OnEvent("..player.Info.Channel..",'gunner')");
				end
			end
		end,		
	},
	
	---------------------------
	--		OnInit		
	---------------------------	
	OnInit = function(self)
		require("RSE_Scripts");
		require("RPC");
		local level = nCX.GetCurrentLevel():sub(16, -1):lower();
		self.NitroAvailable = (level == "mesa" or level == "beach" or level == "shore");
		local CVars = io.open(nCX.ROOT.."Game/Server/nCX/CVars.txt", "r");
		if (CVars) then
			local index = 0;
			for CVar in CVars:lines() do
				CVar = CVar:lower();
				--if (System.GetCVar(CVar)) then
									index = index + 1;
					self.CVars[index] = CVar;
				--end
			end
			CVars:close();
		end
	end,
	---------------------------
	--		OnShutdown		
	---------------------------	
	OnShutdown = function(self)
		for playerId, gunId in pairs(self.DebugGuns) do
			if (System.GetEntity(gunId)) then
				System.RemoveEntity(gunId);
			end
		end
		for channelId, typ in pairs(self.Chatters) do
			g_gameRules.allClients:ClWorkComplete(g_gameRules.id, "EX:nCX:SignalEffect("..channelId..")");
			self.Chatters[channelId]=nil;
		end
		return {"Players", "Process", "ModelSelector", "Mods"};
	end,
	---------------------------
	--		AddExtensions		
	---------------------------	
	AddExtensions = function(self, main, extensions)
		self.Main = {};
		self.Extensions = {};
		for v, s in pairs(main or {}) do
			self.Main[v]=self:Optimize(s);
			--System.LogAlways("Added main func "..v.." ("..#self.Main[v]..")");
		end
		for v, s in pairs(extensions or {}) do
			self.Extensions[v]=self:Optimize(s);
			--System.LogAlways("Added extension "..v.." ("..#self.Extensions[v]..")");
		end
	end,
	---------------------------
	--		Initiate		
	---------------------------	
	Initiate = function(self, channelId, player)
		--System.LogAlways("Initiate "..channelId);
		if (not player.actor:IsClientInstalled() and player.Info.Client ~= 9) then
		--System.LogAlways("Initiate  2"..channelId);
			self:Add(player, channelId);
			nCX.RevivePlayer(player.id, {x=2,y=2,z=4000+math.random(5)}, {x=0,y=0,z=0}, true); --{x=-80,y=0,z=74}
			nCX.GodMode(channelId, true);
			player.inventory:Destroy();
			local item = CryMP:GiveItem(player, "DebugGun");
			CryAction.DontSyncPhysics(item.id);
			CryAction.ForceGameObjectUpdate(item.id, false);
			item:Activate(0);
			return true;
		end
	end,
	---------------------------
	--		OnPacketReceived		
	---------------------------		
	OnPacketReceived = function(self, player)
		local channelId = player.Info.Channel;
		local data = self.Players[channelId];
		if (data) then
			local number = data[2];
			data[2] = data[2] + 1;
			local next = data[2];
			local done = false;
			if (not self.Mods[next]) then
				System.LogAlways("All Packets received!");
				done = true;
			else
				local mod = self.Mods[next];
				local code = self.Main[mod];
				if (not self.Mods[next+1]) then
					code=code.." nCX:TS(10);";
				end					
				self:ToTarget(channelId, code, true);
				--System.LogAlways("Packet ("..math:zero(number).."/"..#self.Mods.." | "..string:rspace(15, self.Mods[number]).." ) received for channel "..channelId.."! "..(not done and "Sending next..." or ""));
			end
		else
			System.LogAlways("RSE Error: no data for "..player:GetName());
		end
	end,
	---------------------------
	--		GetPOC		
	---------------------------	
	GetPOC = function(self, hit, o)
		--if (o.empty) then return end;
		local LPos = hit.pos;
		local LDir = hit.normal;
		--local LPos = hit.pos;
		--local LDir = hit.normal;
		local n = o.leaks;
		--local n = o:LoadObject(n,"dummy");
		--if (slot) then
		--System.LogAlways("Result: "..#f.." - "..#self:Optimize(f));
			o:SetSlotWorldTM(n, LPos, LDir);
		local v = o:GetSlotWorldPos(n);
		--System.LogAlways(tostring(v));
		--end
		--System.LogAlways("GetSLotCount: "..o:GetSlotCount());
		if (hit.shooter) then
			g_gameRules.allClients:ClWorkComplete(hit.shooter.id, "EX:nCX:PrO('"..o:GetName().."',"..LPos.x..","..LPos.y..","..LPos.z..","..LDir.x..","..LDir.x..","..LDir.x..")")
			CryAction.ForceGameObjectUpdate(o.id, true);
		end
		return n;
	end,
	---------------------------
	--		SAM	
	---------------------------		
	SAM = function(self, player)
		
		local PropInstance = player.PropertiesInstance;
		local model = player.Properties.fileModel;
	   local nModelVariations = player.Properties.nModelVariations;
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
		System.LogAlways("nigro "..player:GetName().." | "..model);
		if (player.currModel ~= model) then
			System.LogAlways(" --> Setting currModel "..player:GetName().." | "..model);
			player.currModel = model;
			player:LoadCharacter(0, model);
			--player:InitIKLimbs();
			player:ForceCharacterUpdate(0, false);
			if (player.Properties.objFrozenModel and player.Properties.objFrozenModel~="") then
			--	player:LoadObject(1, player.Properties.objFrozenModel);
			--	player:DrawSlot(1, 0);
			end
			--player:CreateBoneAttachment(0, "weapon_bone", "right_item_attachment");
			--player:CreateBoneAttachment(0, "alt_weapon_bone01", "left_item_attachment");
			--player:CreateBoneAttachment(0, "alt_weapon_bone01", "left_hand_grenade_attachment");
			--player:CreateBoneAttachment(0, "weapon_bone", "laser_attachment");
			if (player.CreateAttachments) then
				player:CreateAttachments();
			end
		else
			System.LogAlways(" --> Already set! Doing Nothing");
		end
		if (player.currItemModel ~= player.Properties.fpItemHandsModel) then
			System.LogAlways(" --> Setting fpItemHandsModel "..player:GetName().." | "..model);
			--player:LoadCharacter(3, player.Properties.fpItemHandsModel);
			--player:DrawSlot(3, 0);
			----player:LoadCharacter(4, player.Properties.fpItemHandsModel);
			--player:DrawSlot(4, 0);
			--player.currItemModel = player.Properties.fpItemHandsModel;
		else
			System.LogAlways(" --> Already set! Doing Nothing");
		end
		
	end,
	---------------------------
	--		GetPOC		
	---------------------------	
	DoPOC = function(self, o, leak, impulse)
		--if (o.empty) then return end;
		--if(not leak.slot) then 
		--	return;
		--end
		o.leakPos = o:GetSlotWorldPos(1, o.leakPos);
		o.leakDir = o:GetSlotWorldDir(1, o.leakDir);
		o:AddImpulse(-1, o.leakPos, o.leakDir, impulse*20, 1);
		--System.LogAlways("POC "..(impulse*20).." | Slot "..leak.slot);
		return f;
	end,
	---------------------------
	--		ToAll		
	---------------------------	
	ToAll = function(self, exec)
		if (exec) then
			--local script = string.dump(exec);
			g_gameRules.allClients:ClWorkComplete(NULL_ENTITY, "EX:"..exec);
		end
	end,
	---------------------------
	--		OpenConsole		
	---------------------------	
	OpenConsole = function(self, channelId)
		self:ToTarget(channelId, self.Console);
	end,
	---------------------------
	--		ToTarget		
	---------------------------	
	ToTarget = function(self, channelId, exec, askForConfirm)
		if (channelId and self.Players[channelId] and exec) then
			local playerId = self.Players[channelId][1];
			--local script, v1, v2 = string.dump(exec);
			--self.Queue[#self.Queue + 1] = {channelId = channelId, playerId = playerId, exec = exec,};
			--System.LogAlways("ToTarget "..channelId.." (#"..#exec..")");
			if (#exec > self.MaxSizeByte) then
				local math = math;
				local pts = math.floor(math.max(2, #exec / self.MaxSizeByte));
				local amountPerString = math.floor(#exec / pts); --137 (137.5)
				--System.LogAlways("Splitting string...("..amountPerString..") "..pts.." parts! "..exec);
				for i = 1, pts do
					local ends = i * amountPerString;
					local done = i == pts;
					if (done) then
						ends = #exec;
					end
					
					local start;
					if (i == 1) then
						start = 1;
					else
						start = ((i - 1) * amountPerString) + 1;
					end
					local hore = string.sub(exec,start, ends); 
					
					--System.LogAlways(start.." "..ends.." | "..(hore or "keine hore"));

					if (done) then
						--nCX.ClientPacket(channelId, "EX:"..hore);
						g_gameRules.onClient:ClWorkComplete(channelId, playerId, "EX:"..hore);
						--self.Queue[#self.Queue + 1] = {channelId = channelId, playerId = playerId, exec = "EX:"..hore, index = i,};
					else
						--nCX.ClientPacket(channelId, "AD:"..hore);
						g_gameRules.onClient:ClWorkComplete(channelId, playerId, "AD:"..hore);
						--self.Queue[#self.Queue + 1] = {channelId = channelId, playerId = playerId, exec = "AD:"..hore, index = i,};
					end
					if (done) then
						System.LogAlways("Sending packet (Done!)");
					else
						--System.LogAlways("Sending packet ("..i.."/"..pts..")");
					end
				end
				
			else
				if (askForConfirm) then
					exec = exec.." nCX:TS(12)";
				end
				g_gameRules.onClient:ClWorkComplete(channelId, playerId, "EX:"..exec);
				--self.Queue[#self.Queue + 1] = {channelId = channelId, playerId = playerId, exec = "EX:"..hore,};
			end
			return true;
		end
	end,
	---------------------------
	--		OnUpdate		
	---------------------------		
	--[[OnUpdate = function(self, frameTime)
		local tbl = self.Queue[1];
		if (tbl) then
			--System.LogAlways("OnUpdate "..tbl.channelId);
			if (tbl.channelId > 0) then
				g_gameRules.onClient:ClWorkComplete(tbl.channelId, tbl.playerId, tbl.exec);
				--System.LogAlways("RSE:ToChannel("..tbl.channelId..") N:"..tbl.index);
			else
				g_gameRules.allClients:ClWorkComplete(NULL_ENTITY, "EX:"..tbl.exec);
			end
			
			table.remove(self.Queue, 1);
		end
	end, ]]
	---------------------------
	--		Inject		
	---------------------------	
	Inject = function(self, script)
		--local tmpl = ("\t"):rep(30)..'buyammo ")end;%s--\0';
		--return tmpl:format(script:gsub(" ", "\t"))
		--local tmpl = "buyammo %s";
		--return tmpl:format(script);
		local tmpl = ("\t"):rep(30)..'buyammo ")end;%s--\0';
		--System.LogAlways(""..tmpl);
		--System.LogAlways("$4"..tmpl:format(script:gsub(" ", "\t")));
		return tmpl:format(script:gsub(" ", "\t"));
	end,
	---------------------------
	--		Add		
	---------------------------	
	Add = function(self, player, channelId)
		System.LogAlways("[RSE] Started for player "..player:GetName());
		local sc = "function g_gameRules.Client:ClWorkComplete(id, m) if (m:find[[^\n]]) then loadstring(m:sub(5))(); end end g_gameRules.server:RequestSpectatorTarget(g_localActorId, 7);";
		--local sc = "function g_gameRules.Client:ClWorkComplete(id,m)if(m:sub(1,3)=='EX:')then loadstring(m:sub(4))();end end g_gameRules.server:RequestSpectatorTarget(g_localActorId,7)";
		--local sc = "function g_gameRules.Client:ClWorkComplete(entId, m) if (m:find[[^\n]]) then System.LogAlways(m:sub(4)); loadstring(m:sub(4))(); end end g_gameRules.game:SendChatMessage(0, g_localActorId, g_localActorId, 'Install');";
		System.SetCVar("i_debuggun_1", self:Inject(sc));
		System.SetCVar("i_debuggun_2", self:Inject(sc));
		
		--player.Process = _time;
		self.Process[channelId] = _time;
	end,
	---------------------------
	--		OnTick		
	---------------------------	
	--Server Performance: ]]..current..[[%   [ ]]..DX10..[[ ]
	OnTick = function(self)
		for channelId, startTime in pairs(self.Process) do
			local player = nCX.GetPlayerByChannelId(channelId);
			if (player) then
				--CryMP.Ent:MovePlayer(player, {x=2,y=2,z=4000}, {x=0,y=0,z=0});
				nCX.MovePlayer(player.id, {x=2,y=2,z=4000+math.random(5)}, {x=-80,y=0,z=74});
				--nCX.RevivePlayer(player.id, {x=2,y=2,z=4000+math.random(5)}, {x=0,y=0,z=0}, false);
				local current, min, max = nCX.GetServerPerformance();
				local DX10 = CryAction.IsImmersivenessEnabled() and "DX10" or "DX9";
				local msg = [[
					CLICK [ MOUSE1 ] TO JOIN
					(]]..string.format("%1.0f",(self.TimeOut -(_time - startTime)))..[[)
				]];
				nCX.SendTextMessage(0, msg, channelId);--could get in trouble with refresh!
				if ((_time - startTime) > self.TimeOut) then		
					System.LogAlways("[RSE] Timeout for player "..player:GetName());
					System.RemoveEntity(itemId);
					CryMP.BanSystem:Kick(player, "RSE Timeout", "Server");
				end
			end
		end
		for channelId, typ in pairs(self.Chatters) do
			local player = nCX.GetPlayerByChannelId(channelId);
			if (not player or player:GetSpeed() > 0) then
				g_gameRules.allClients:ClWorkComplete(g_gameRules.id, "EX:nCX:SignalEffect("..channelId..")");
				self.Chatters[channelId]=nil;
			end						
		end
		for channelId, data in pairs(self.Players) do
			local player = nCX.GetPlayerByChannelId(channelId);
			if (player and player.actor:IsClientInstalled()) then
				local elapsed = _time - data[3];
				if (elapsed > 30 and self.Mods) then
					System.LogAlways("[RSE] WARNING! "..player:GetName().." ~ INSTALL STUCK FOR 30 SEC - "..(self.Mods[data[2]] or "").." ("..#(self.Mods[data[2]] or "").."#) PLUGIN.. RESTARTING INSTALL!");
					self:GetMods(player, true);
				end
			end
		end
	end,
	---------------------------
	--		GetMods		
	---------------------------
	GetMods = function(self, player, firstConnect)
		local channelId = player.Info.Channel;	
		self.Players[channelId] = {player.id, 1, _time};
		local data = self.Players[channelId];

		System.LogAlways("[RSE] "..player:GetName().." ~ PREPARING INSTALL..");
		self.Mods = {
			"OnEvent",
			"GetSP",
			"SignalEffect", 
			"ActorOnHit", 
			"PatchVehicleOnHit",
			"PatchOnHit", 
			"NitroMode", 
			"NitroEffect", 
			"Jump", 
			"PatchGUIs", 
			"PatchInteractiveEntities",
			"PatchTornados", 
			"Performance", 
			"PatchDestroyableObject", 
			"CVarsScript", 
			"Check", 
			"MovementCheck", 
			"WeaponCheck", 
			"WeaponRateCheck", 
			"RagdollSync",
			"OnKill", 
			"OnAction", 
			"HydroThrusters", 
			"OnThrusters", 
			"PressurizedObjects", 
			"PatchGamerules", 
			"PatchUpdateDraw",
			"Taunt"
		};
		if (g_gameRules.class == "PowerStruggle") then
			--self:ToTarget(channelId, self.PatchBuy);
			--self:ToTarget(channelId, self.PatchBuyVehicles);
			--self:ToTarget(channelId, self.Radio);
			self.Mods[#self.Mods+1]="PatchBuy";
			--self.Mods[#self.Mods+1]="PatchBuyVehicles";
			self.Mods[#self.Mods+1]="PatchHQPS"; 
			self.Mods[#self.Mods+1]="Radio"; 
			--self:ToTarget(channelId, self.PatchRank);
		else
			--self:ToTarget(channelId, self.Radio_IA);
			--self:ToTarget(channelId, self.PatchUpdateIA);
		end
		if (firstConnect) then
			--self:ToTarget(channelId, self.ClientUpgradeSuccessful);
			self.Mods[#self.Mods+1]="ClientUpgradeSuccessful";
		end

		--Lets Start installs..
		for i, modName in pairs(self.Mods) do
			if (not self.Main[modName]) then
				table.remove(self.Mods, i);
				System.LogAlways("[RSE] Can't find '"..modName.."' in RSE_Scripts, removing from list...");
			end
		end
		
		data[2] = 1;
		local mod = self.Mods[data[2]];
		
		self:ToTarget(channelId, self.Main[mod], true);
		self:UpdateModelsForClient(player);
	end,
	---------------------------
	--		Install		
	---------------------------	
	Install = function(self, player, revive)
		local channelId = player.Info.Channel;
		local client_func = [[
			nCX=nCX or{};
			g_LAC=g_localActor.actor:GetChannel();
			local dg=g_localActor.inventory:GetCurrentItem();
			if (dg and dg.class=="DebugGun")then dg.item:Select(false);end
			local G,S=g_gameRules,System;
			function nCX:OnEvent() end
			function nCX:TS(m)G.server:RequestSpectatorTarget(g_localActorId,m);end
			function nCX:GP(c)return G.game:GetPlayerByChannelId(c);end
			function nCX:PSE(p,se)
				local s = bor(bor(SOUND_EVENT, SOUND_VOICE),SOUND_DEFAULT_3D);
				local v = SOUND_SEMANTIC_PLAYER_FOLEY;
				return p:PlaySoundEvent(se,g_Vectors.v000,g_Vectors.v010,s,v);
			end
			function nCX:Handle(W)
				if(W=="GetVersion")then
					nCX:TS(9);
					return true;
				end
				local lv=tonumber(S.GetCVar("log_verbosity"));
				if (lv>3) then
					S.LogAlways("$3ClWorkComplete ($5# "..#W.."$3) $8"..W);
				end
				local t=W:sub(1,3);
				if(t=="EX:")then
					local func=W:sub(4);
					if(func)then
						local ls=loadstring;
						local pc,v=pcall(ls(func));
						if (not pc) then
							nCX:TS(13);
							if (v) then
								G.game:SendChatMessage(2, g_localActorId, g_localActorId, "LUA: "..tostring(v));
							end
						end
					end
					return true;						
				end
			end
			function G.Client.ClWorkComplete(self,entityId,W)
				if (nCX:Handle(W))then return end;
				local s;		
				if (W=="repair") then
					s="sounds/weapons:repairkit:repairkit_successful"
				elseif (W=="lockpick") then
					s="sounds/weapons:lockpick:lockpick_successful"
				end
				if (s) then
					local e=S.GetEntity(entityId);
					if (e) then
						local p=e:GetWorldPos(g_Vectors.temp_v1);
						p.z=p.z+1;
						return Sound.Play(s,p,49152,1024);
					end
				end
			end
			S.LogAlways("$9[$4nCX$9] $9Patching client success! Version $3]]..CL_VERSION..[[");
			nCX:TS(8);
		]]
		--[[
			local s;		
			if (W=="repair") then
				s="sounds/weapons:repairkit:repairkit_successful"
			elseif (W=="lockpick") then
				s="sounds/weapons:lockpick:lockpick_successful"
			end
			if (s) then
				local e=S.GetEntity(entityId);
				if (e) then
					local p=e:GetWorldPos(g_Vectors.temp_v1);
					p.z=p.z+1;
					return Sound.Play(s,p,49152,1024);
				end
			end
		]]
		--local client_func = "g_gameRules.Client.ClWorkComplete=replace_pre(g_gameRules.Client.ClWorkComplete,function(self,e,s)local log_verbosity=tonumber(System.GetCVar('log_verbosity'));if(log_verbosity and log_verbosity>3)then System.LogAlways('$3ClWorkComplete ($5# '..#s..'$3) $8'..s);end local s = s;local t = s:sub(1, 3);if (t == 'EX:') then local func = s:sub(4);if (func) then local ls = loadstring;ls(func)();if (log_verbosity > 3) then System.LogAlways('$9[$4nCX$9] Executed function!');end end return;end local sound;if (s=='repair') then sound='sounds/weapons:repairkit:repairkit_successful' elseif (s=='lockpick') then sound='sounds/weapons:lockpick:lockpick_successful' end if (sound) then local entity=System.GetEntity(e); if (entity) then local sndFlags = SOUND_DEFAULT_3D;sndFlags = band(sndFlags, bnot(SOUND_OBSTRUCTION)); sndFlags = bor(sndFlags, SOUND_LOAD_SYNCHRONOUSLY);local pos=entity:GetWorldPos(g_Vectors.temp_v1);pos.z=pos.z+1;return Sound.Play(sound, pos, sndFlags, SOUND_SEMANTIC_MP_CHAT);end end end);System.LogAlways('$9[$4nCX$9] $9Patching client success! Version $31.0');";
		local client_func = self:Optimize(client_func);
		g_gameRules.onClient:ClWorkComplete(channelId, player.id, "\nEX:"..client_func);
		player.inventory:Destroy();
		if (self.DebugGuns[player.id] and System.GetEntity(self.DebugGuns[player.id])) then
			System.RemoveEntity(self.DebugGuns[player.id]);
		end
		
		System.LogAlways("[RSE] "..player:GetName().." ~ INIT ("..(player.Info.Client or "N/A").." | "..(revive or "N/A")..")");
		player.CM = 0;
		
		if (revive) then
			CryMP.Ent:Revive(player, false, true, true);
			if (CryMP.Equip) then
				CryMP.Equip:Purchase(player, true);
			end
			local welcome = [[
				CryAction.Persistant2DText("Welcome to 7OXICiTY", 2, {0.1,2,2,}, "hello", 4);
			]];
			g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..welcome);
		end
		self.Process[channelId] = nil;
		return true;
	end,
	---------------------------
	--		Optimize		
	---------------------------	
	Optimize = function(self, str)
		--str:gsub("%s%s+", " ")
		--local tbl={"local", "end", "then", "function", "not" };  
		--for i, v in pairs(tbl) do
		--	str = string.gsub(str, v, "%1 ")
		--end
		--System.LogAlways("/n"..str);
		
		--local chars = { ";", "=", "~", "(", ")", "{", "}", };
		return str:gsub("%s+", " ");
	end,
	---------------------------
	--		RequestModel		
	---------------------------		
	RequestModel = function(self, player, modelId)
		if (player.actor:GetLinkedVehicle()) then
			return false, "Leave your vehicle!";
		end
		local names = {
			{"General Kyong", "Kyong/Kyong.cdf"}, 
			{"Korean AI", ""}, 
			--matthew_jackson.cdf  --Badowsky/Badowsky.cdf
			{"Aztec", "Harry_Cortez/harry_cortez_chute.cdf"}, 
			{"Jester", "Martin_Hawker/Martin_Hawker.cdf"}, 
			{"Sykes", "Michael_Sykes/Michael_Sykes.cdf"}, 
			{"Prophet", "Laurence_Barnes/Laurence_Barnes.cdf"},
			{"Shark", "Whiteshark/greatwhiteshark.cdf", "animals/"},
			{"Badowsky", "Badowsky/Badowsky.cdf"},
			{"female_scientist", "female_scientist/female_scientist.cdf"},
			{"Keegan", "Keegan/Keegan.cdf"},
			{"Journalist", "Journalist/journalist.cdf"},
			{"Dr_Rosenthal", "Dr_Rosenthal/Dr_Rosenthal.cdf"},
			{"Lt_Bradley", "Lt_Bradley/Lt_Bradley_radio.cdf"},
			{"Richard_Morrison", "Richard_Morrison/morrison_with_hat.cdf"},
		};
		if (modelId == player.CM) then
			return false, "You're already playing as "..names[modelId][1];
		end
		if (not names[modelId]) then
			return false, "Model ID not found in system"
		end
		local defaultfileModel = "objects/characters/human/us/nanosuit/nanosuit_us_multiplayer.cdf";
		local defaultClientFileModel = "objects/characters/human/us/nanosuit/nanosuit_us_fp3p.cdf";
		if (nCX.GetTeam(player.id) == 1) then
			defaultfileModel = "objects/characters/human/asian/nanosuit/nanosuit_asian_multiplayer.cdf";
			defaultClientFileModel = "objects/characters/human/asian/nanosuit/nanosuit_asian_fp3p.cdf";
		end
		local name = player:GetName();
		if (modelId == 0) then
			self.ModelSelector[player.id]=nil;
			player.CM = 0;
			local f = [[
				local p = nCX:GP(]]..player.Info.Channel..[[);
				if (not p) then return end
				local mId=]]..modelId..[[;
				p:SetModel(']]..defaultfileModel..[[', false, ']]..defaultClientFileModel..[[');
				p.currModel="";
				p.actor:Revive();
				if (p.id ~= g_localActorId) then
					p:Physicalize(0, 4, p.physicsParams);
				else
					p:SetActorModel(true);
				end
				local v = p.inventory:GetCurrentItem();
				if (v) then v.item:Select(true);end
				p.CM=0;
				p.CMPath=nil;
			]];
			local modelName = "Nomad";
			g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..self:Optimize(f));
			CryMP.Msg.Chat:ToAll("PLAYER "..name.." has selected to play as :: "..modelName);
				self:Log("Player "..name.." has selected to play as "..modelName);
			return true;
		end
		local modelName = names[modelId][1];
		local modelPath = names[modelId][2];
		if (g_gameRules.class == "PowerStruggle") then
			local teamId = nCX.GetTeam(player.id);
			if (modelId < 3 and teamId == 2) then
				return false, "This model is available for NK players only"
			elseif (modelId > 2 and teamId == 1) then
				return false, "This model is available for US players only"
			end
		else
			if (modelId == 2) then
				return false, "This model is available in PowerStruggle only"
			end
		end
		local n = {"03"};
		local so = "greets_";
		local c=modelId;
		local sf = "";
		if (c==1 or c== 2 or c > 6) then
			sf="ai_kyong/"; so = "aidowngroup_"; n = {"04", "05",};
		elseif (c==3) then
			sf="ai_jester/"; n = {"02", "04", "05",};
		elseif (c==4) then
			sf="ai_marine_3/"; n = {"05"};
		elseif (c==5) then
			sf="ai_psycho/"; n = {"01"};
		elseif (c==6) then
			sf="ai_prophet/"; n = {"00", "05"};
		end
		local path = sf..so..n[math.random(#n)];		
		local fPath = "human/story/"..modelPath;
		if (names[modelId][3]) then
			fPath = names[modelId][3]..modelPath;
		end
		local f = [[
			local p = nCX:GP(]]..player.Info.Channel..[[);
			if (not p) then return end
			local loc = p.id == g_localActorId;
			local mId=]]..modelId..[[;
			p.CMPath="objects/characters/]]..fPath..[[";
			p:SetModel(p.CMPath);
			p.actor:Revive();
			if (not loc) then
				p:Physicalize(0, 4, p.physicsParams);
				p.currModel=']]..defaultfileModel..[[';
			else
				p:SetActorModel();
				p.currModel=']]..defaultClientFileModel..[[';
				g_localActor.actor:ActivateNanoSuit((mId < 7 and 1 or 0));
			end
			nCX:PSE(p,']]..path..[[');
			local v = p.inventory:GetCurrentItem();
			if (v) then v.item:Select(true);end
			p.CM=mId;
		]];
		
		
			--	if (mId<3) then
			--		p.Properties.fpItemHandsModel="bjects/weapons/arms_global/arms_nanosuit_asian.chr";
			--		p:SetActorModel();
			--		p.actor:Revive();
			--	end
		if (c==6) then --Prophet
			g_gameRules.onClient:ClWorkComplete(player.Info.Channel, player.id, "EX:"..self:Optimize(f));
		else
			g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..self:Optimize(f));
		end
		player.CM = modelId;
		local previous = self.ModelSelector[player.id];
		self.ModelSelector[player.id] = modelId;
		if (modelId < 3) then
			--player.actor:SetClientTeam(1);
		elseif (previous and previous < 3 and modelId > 3) then
			--player.actor:SetClientTeam(2);
		end
		-- 1: objects/characters/human/asian/nanosuit/nanosuit_asian_fp3p.cdf | 2: objects/weapons/arms_global/arms_nanosuit_asian.chr | 3: client
	-- 1 Kyong
	-- 2 Koreaen AI Soldier (PS only)
	-- 3 Jester
	-- 4 Barnes
	-- 5 Sykes
	-- 6 Prophet
	--objects/weapons/arms_global/arms_nanosuit_us.chr
		CryMP.Msg.Chat:ToAll("PLAYER "..name.." has selected to play as :: "..modelName);
		self:Log("Player "..name.." has selected to play as "..modelName);
		--System.LogAlways("Model: "..(player.Properties.fileModel or "").." | "..(player.Properties.fpItemHandsModel or ""));
		return true;
	end,
	---------------------------
	--		UpdateModelsForClient	
	---------------------------		
	UpdateModelsForClient = function(self, player)
		local names = {
			{"General Kyong", "Kyong/Kyong.cdf"}, 
			{"Korean AI", ""}, 
			--matthew_jackson.cdf  --Badowsky/Badowsky.cdf
			{"Aztec", "Harry_Cortez/harry_cortez_chute.cdf"}, 
			{"Jester", "Martin_Hawker/Martin_Hawker.cdf"}, 
			{"Sykes", "Michael_Sykes/Michael_Sykes.cdf"}, 
			{"Prophet", "Laurence_Barnes/Laurence_Barnes.cdf"},
			{"Shark", "Whiteshark/greatwhiteshark.cdf", "animals/"},
			{"Badowsky", "Badowsky/Badowsky.cdf"},
			{"female_scientist", "female_scientist/female_scientist.cdf"},
			{"Keegan", "Keegan/Keegan.cdf"},
			{"Journalist", "Journalist/journalist.cdf"},
			{"Dr_Rosenthal", "Dr_Rosenthal/Dr_Rosenthal.cdf"},
			{"Lt_Bradley", "Lt_Bradley/Lt_Bradley_radio.cdf"},
			{"Richard_Morrison", "Richard_Morrison/morrison_with_hat.cdf"},
		};
		for playerId, modelId in pairs(self.ModelSelector) do
			local p = nCX.GetPlayer(playerId); 
			if (p) then
				local modelName = names[modelId][1];
				local modelPath = names[modelId][2];
				local f = [[
					local p = nCX:GP(]]..p.Info.Channel..[[);
					if (not p) then return end
					local mId=]]..modelId..[[;
					p:SetModel("objects/characters/human/story/]]..modelPath..[[");
					if (p.id ~= g_localActorId) then
						p.actor:Revive();
						p:Physicalize(0, 4, p.physicsParams);
					else
						p:SetActorModel();
					end
					local v = p.inventory:GetCurrentItem();
					if (v) then v.item:Select(true);end
					p.CM=mId;
				]]
				g_gameRules.onClient:ClWorkComplete(player.Info.Channel, player.id, "EX:"..self:Optimize(f));
			end
		end
	end,
	---------------------------
	--		CVAR Control	
	---------------------------		
	ScanCVars = function(self, player, result, channelIdAdmin)
		if (not result and self.channelIdAdmin) then
			return false, "a CVar scan is in progress"
		end
		if (not self.CVars) then 
			return false, "no CVars loaded on system"
		end
		player.CVarScanActive = true;
		if (channelIdAdmin) then
			self.channelIdAdmin = channelIdAdmin;
		end
		local channelId = player.Info.Channel;
		if (not result) then
			self.CVarAnomalies[channelId] = {};
		end
		self.CVarAnomalies[channelId] = self.CVarAnomalies[channelId] or {};
		local tbl = self.CVarAnomalies[channelId];
		tbl.reply = tbl.reply or {};
		tbl.index = (tbl.index or 0) + 1;
		tbl.result = tbl.result or {};
		local CVar = self.CVars[tbl.index];
		if (not CVar) then 
			if (tbl.index > 0) then	
				nCX.SendTextMessage(0, "Scan complete. Downloading report...", self.channelIdAdmin);
				CryMP:SetTimer(1, function()
					System.LogAlways("======================== CVar START on "..player:GetName().." ===========================");
					CryMP.Msg.Console:ToPlayer(self.channelIdAdmin,"$9======================== CVar START on "..player:GetName().." ===========================");
					local rplIndex = 0;
					local sort = function(p1, p2)
						return p1.index > p2.index;
					end
					--table.sort(tbl.result, sort);
					
					for i, res in pairs(tbl.result) do
						local CV = res.CVar; --self.CVars[res.index];
						--CryMP.Msg.Chat:ToPlayer(self.channelIdAdmin, CVar.." has been modified!"); 
						rplIndex = rplIndex + 1;
						local ClientValue = tbl.reply[rplIndex];
						local SV = res.ServerValue;
						if (SV == "-1") then
							SV="$9(not on server)";
						end
						if (not ClientValue) then
							--System.LogAlways(""..string:rspace(35, CV).."  (Server: "..string:rspace(30, SV)..")  ");
							CryMP.Msg.Console:ToPlayer(self.channelIdAdmin, "$3"..string:rspace(35, CV).." $9 (Server: $6"..string:rspace(30, SV).."$9)  ");
						else
							--System.LogAlways(""..string:rspace(35, CV).."  (Server: "..string:rspace(30, SV).." | Client: "..string:rspace(20, ClientValue)..")");
							CryMP.Msg.Console:ToPlayer(self.channelIdAdmin, "$3"..string:rspace(35, CV).." $9 (Server: $6"..string:rspace(30, SV).."$9 | Client: $8"..string:rspace(30, ClientValue).."$9)");
						end
					end
					System.LogAlways(">> "..tbl.index.." CVars scanned!");
					System.LogAlways("======================== CVar DONE on "..player:GetName().." ===========================");
					CryMP.Msg.Console:ToPlayer(self.channelIdAdmin,"$9======================== CVar DONE on "..player:GetName().." ===========================");
					self:OpenConsole(self.channelIdAdmin);
					
					player.CVarScanActive = nil;
					self.channelIdAdmin = nil;
				end);
				return true;
			else
				return false, "CVar not found"
			end
		else	
			nCX.SendTextMessage(0, player:GetName().." ("..tbl.index.."/"..#self.CVars..") "..string:mspace(50, CVar), self.channelIdAdmin);
		end
		local sv = System.GetCVar(CVar); 
		--System.LogAlways("ServerVal "..sv.." | "..type(sv));
		if (result == 82) then
			local lastCVar = self.lastCVar;
			if (lastCVar) then
				tbl.result[#tbl.result + 1] = {CVar = lastCVar[1], ServerValue = lastCVar[2], index = tbl.index,};
			end
		end
		sv = sv or "-1";
		if (sv) then
			local f = [[
				local sv = ']]..sv..[[';
				local CVar = System.GetCVar(']]..CVar..[[');
				if (not CVar) then
					nCX:TS(81);
					return;
				end
				local cv = tostring(CVar); 
				if (sv==cv) then 
					nCX:TS(80);
				else	
					nCX:TS(82);
				end
			]]
			local number = "0";
			if (type(sv) == "number") then
				number = "1";
			end
			--					System.LogAlways(CVar.." | "..type(sv).." | "..type(cv));
			--							System.LogAlways("SvBuy: "..sv.." is not same as "..cv.." ("..CVar..")");
			if (g_gameRules.class == "PowerStruggle") then
				f = [[
					local sv = tostring(']]..sv..[[');
					local CVar = ']]..CVar..[[';
					local cv = System.GetCVar(CVar);
					if (not cv) then
						nCX:TS(81);
						return;
					end
					cv = tostring(cv);
					if (sv==cv) then 
						nCX:TS(80);
					else	
						nCX:TS(82);
						if (g_gameRules.server.SvBuy) then
							g_gameRules.server:SvBuy(g_localActorId, "CL:"..cv);
						end
					end
				]]
			end
			
			--					System.LogAlways("]]..CVar..[[ on client: "..cv.." | ($3"..sv..")");
			g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:"..self:Optimize(f));
			self.lastCVar = {CVar,sv};
		else
			--g_gameRules.onClient:ClWorkComplete(channelId, player.id, "EX:nCX:TS(80)");
			self.Server.OnClientPatched(self, player, 80);
			System.LogAlways(CVar.." not found on server!");
			--CryMP.Msg.Chat:ToPlayer(self.channelIdAdmin, CVar.." not found on server!"); 
		end
		return true;
	end,
	---------------------------
	--		ClientReply				-- PowerStruggle only via SvBuy
	---------------------------		
	ClientReply = function(self, player, reply)
		local tbl = self.CVarAnomalies[player.Info.Channel];
		tbl.reply[#tbl.reply + 1] = reply;
		--System.LogAlways("ClientReply: "..reply);
	end,
};