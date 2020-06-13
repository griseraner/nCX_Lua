--===================================================================================
-- RESTART

CryMP.ChatCommands:Add("restart", {
		Access = 4,
		Info = "restart the round",
		Delay = 6,
		self = "Library",
	},
	function(self, player, channelId)
		local c = 5;
		for i = 0, c do
			CryMP:SetTimer(i, function()
				if (c==0) then
					System.ExecuteCommand("sv_restart");--works now!
				else
					nCX.SendTextMessage(0, "SYSTEM RESTART  : : :  [ 00 : 0"..c.." ]  : : :  STAND BY", 0);
				end
				c = c-1;
			end);
		end
		return true;
	end
);

--===================================================================================
-- REFRESH

CryMP.ChatCommands:Add("refresh", {
		Access = 3,
		Args = {
			{"force", Optional = true, Output = {{"force", "Force restore on players",},},},
		},
		Info = "restart the round and keep the scores",
		Delay = 6,
		--self = "Refresh",
	},
	function(self, player, channelId, force)
		local Refresh = CryMP.Refresh;
		if (Refresh and g_gameRules.class == "PowerStruggle") then
			if (force) then
				local count = Refresh:GetRestoreCount();
				if (count > 0) then
					Refresh:RestoreFull();
					CryMP.Msg.Chat:ToAccess(2, "Forced restore on "..count.." players..");
					return true;
				end
				return false, "no players matched backup data"
			end
			Refresh:Initiate();
		elseif (g_gameRules.class == "TeamInstantAction") then
			nCX.Refresh = true;
		end
		return false;
	end
);

--===================================================================================
-- REBOOT

CryMP.ChatCommands:Add("reboot", {
		Access = 5,
		Info = "$4restart the server$9"
	},
	function(self, player, channelId)
		local msg = "!!! SERVER REBOOT : COME BACK SOON !!!";
		CryMP.Msg.Chat:ToAll("ALERT! SERVER REBOOT IN PROGRESS!");
		if (CryMP.Refresh) then
			CryMP.Refresh:SaveData();
			CryMP.Msg.Chat:ToAll("Your data has been saved!");
		end
		nCX.Log("Action", "Server reboot triggered by "..player:GetName());
		local function info()
			nCX.SendTextMessage(0, msg, 0);
			nCX.SendTextMessage(2, msg, 0);
			nCX.SendTextMessage(3, msg, 0);
			nCX.SendTextMessage(4, msg, 0);
		end;
		for i = 0, 10, 5 do
			CryMP:SetTimer(i, function()
				info();
			end);
			if (i == 10) then
				CryMP:SetTimer(i+2, function()
					System.ExecuteCommand("quit");
				end);
			end
		end
		return true;
	end
);

--===================================================================================
-- SCORESRESTORE

CryMP.ChatCommands:Add("scores", {
		Access = 3,
		Args = {
			{"mode", Output = {{"load", "Load the previously saved scores"},{"save", "Save current scores and overwrite data file"},{"delete", "Flush the score data"},},},
		},
		Info = "control the last known scores",
		self = "ScoreRestore",
	},
	function(self, player, channelId, mode)
		if (mode == "load") then
			local count = self:Read(true);
			if (count) then
				CryMP.Msg.Chat:ToAccess(2, "Loaded "..count.." x Scores..");
			else
				CryMP.Msg.Chat:ToAccess(2, "Failed to load scores..");
			end
		elseif (mode == "delete") then
			self:Purge();
			CryMP.Msg.Chat:ToAccess(2, "Scores deleted..");
		elseif (mode == "save") then
			for i, player in pairs(nCX.GetPlayers()) do
				self:Save(player);
			end
			self:Write();
		end
		return true;
	end
);

--===================================================================================
-- MAP

CryMP.ChatCommands:Add("map", {
		Access = 3,
		Args = {
			{"map", Info = "The map you wish to load"},
			{"options", Info = "Load immediately", Optional = true, Output = {{"fast", "Load faster"},{"saveScores", "Save current scores for next round"},{"both", "Both options enabled"},},},
		},
		Info = "change to specified map",
	},
	function(self, player, channelId, map, mode)
		if (nCX.MapList) then
			local map = map:lower();
			local rules = nCX.MapList[map];
			local fast = mode == "fast";
			local saveScores = mode == "saveScores";
			local both = mode == "both";
			if rules == "TeamInstantAction" then
				rules = "InstantAction";
			end
			if (saveScores and g_gameRules.class ~= rules) then
				return false, "you have to load a map with "..g_gameRules.class.." to keep scores";
			end
			if (both) then
				fast = true; saveScores = true;
			end
			if (rules) then
				if rules == "TeamInstantAction" then
					rules = "InstantAction";
				end
				self:Log("Changing map to "..map:upper().." ("..rules..")");
				if (rules ~= g_gameRules.class) then
					System.ExecuteCommand("sv_gamerules "..rules);
				end
				local message = "*** NEW MAP  >  >  >  "..map:upper().." ("..rules..") ***";
				local s = "HUD.BattleLogEvent(eBLE_Currency, 'Next map: "..map:upper().." ("..rules..")');";
				if (saveScores) then
					s = "HUD.BattleLogEvent(eBLE_Currency, 'Next map: "..map:upper().." ("..rules..") /n Keeping scores for next round!');";
					nCX.Refresh = true;
				end
				if (not fast) then
					g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..s);
					if (g_gameRules.allClients.ClTimerAlert) then
						g_gameRules.allClients:ClTimerAlert(5);
					end
				end
				--g_gameRules:OnGameEnd(0, 0, nil)
				local code = [[
					Script.DumpLoadedScripts();
					nCX.SPAWNED = false;
					for i = 1, 20, 1 do
						Script.SetTimer(i * 2000, function()
							if (not System.GetEntities()) then
								local ep = {
									class = "Shark";
									position = { 
										math.random(11, 222), 
										math.random(11, 222), 
										1111 + 3,
									};
									orientation = {x=0,y=0,z=0};
									name = "Shark_niggae";
								};
								local spawned = System.SpawnEntity(ep);
								if (spawned and spawned.actor) then
									System.LogAlways("$3Successfully spawned SHARK!!!!!");
									nCX.SPAWNED = true;
								end
							end
							System.LogAlways("$3 timer "..i.." | "..type(nCX.CL_BACKUP).." | "..(System.GetEntities() and #System.GetEntities() or 0));
							Script.ReloadScript("scripts/gamerules/instantaction.lua");
							function g_gameRules.Client.ClWorkComplete(self,entityId,W)
								if (nCX:Handle(W))then return end;
								local s;		
								if (W=="repair") then
									s="sounds/weapons:repairkit:repairkit_successful"
								elseif (W=="lockpick") then
									s="sounds/weapons:lockpick:lockpick_successful"
								end
								if (s) then
									local e=System.GetEntity(entityId);
									if (e) then
										local p=e:GetWorldPos(g_Vectors.temp_v1);
										p.z=p.z+1;
										return Sound.Play(s,p,49152,1024);
									end
								end
							end
						end);
					end
				]];
				--g_gameRules.allClients:ClWorkComplete(g_gameRules.id, "EX:"..code);
				if (fast) then
					System.ExecuteCommand("map "..map);
				else
					nCX.EndGame();	
					CryMP:SetTimer(10, function()
						System.ExecuteCommand("map "..map);
					end);
				end
				return true;
			end
			return false, "map not found", "Map [ "..map.." ] not in database!";
		end
		return false, "levelsystem not found";
	end
);

--===================================================================================
-- MAP

CryMP.ChatCommands:Add("setnextmap", {
		Access = 3,
		Args = {
			{"map", Info = "The map you wish to load next after this round"},
		},
		Info = "set next map",
	},
	function(self, player, channelId, map)
		if (nCX.MapList) then
			local map = map:lower();
			local rules = nCX.MapList[map];
			if (rules) then
				if rules == "TeamInstantAction" then
					rules = "InstantAction";
				end
				self:Log("Setting next map to "..map:upper().." ("..rules..")");		
				local s = "HUD.BattleLogEvent(eBLE_Currency, 'Next map: "..map:upper().." ("..rules..")');";
				g_gameRules.allClients:ClWorkComplete(player.id, "EX:"..s);
				nCX.NextMap=map;
				return true;
			end
			return false, "map not found", "Map [ "..map.." ] not in database!";
		end
		return false, "levelsystem not found";
	end
);