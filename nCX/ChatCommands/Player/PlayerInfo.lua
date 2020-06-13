--==============================================================================
--!VIP
CryMP.ChatCommands:Add("mytag", {--vip
		Access = 1, 
		--Info = "toggle VIP tag on connect",
		Info = "toggle your tag",
		self = "Users",
	},
	function(self, player, channelId)
		--[[if (self:GetAccess(player) > 1) then
			return false, "reserved for premium-players";
		end
		local info = self.Users[player.Info.ID];
		if (info) then
			if (not info[4]) then
				local added = self:AddTag(player, 1);
				if (added) then
					CryMP.Msg.Chat:ToPlayer(channelId, "VIP tag attached. Disable with !vip", 1);
				else
					return false, "failed - check your name";
				end
			else
				info[4] = nil;
				CryMP.Msg.Chat:ToPlayer(channelId, "VIP tag disabled. Re-enable with !vip", 1);
			end
			return true;
		else
			return false, "user info not found in database";
		end]]
		local tag = (self:GetAccess(player) == 1 and 1) or (self:GetAccess(player) > 1 and 2);
		if (tag) then
			local info = self.Users[player.Info.ID];
			if (info) then
				if (not info[4]) then
					local added = self:AddTag(player, tag);
					if (added) then
						CryMP.Msg.Chat:ToPlayer(channelId, (tag == 1 and "VIP" or "Clan").." tag attached. Disable with !mytag", 1);
					else
						return false, "failed - check your name";
					end
				else
					local added = self:AddTag(player, tag, true);
					info[4] = nil;
					self:Write();
					CryMP.Msg.Chat:ToPlayer(channelId, (tag == 1 and "VIP" or "Clan").." tag disabled. Re-enable with !mytag", 1);
				end
				return true;
			end
			return false, "user info not found in database";
		end
		return false, "no tag found for your usergroup";
	end
);

--==============================================================================
--!PDA

CryMP.ChatCommands:Add("pda", {
		Info = "view player and server info",
		OpenConsole = true,
		self = "JoinMessages",
	},
	function(self, player, channelId)
		local msgs = self:GetPDA(player);
		local counter = #msgs;
		for i, msg in pairs(msgs or {}) do
			--local m = msgs[counter];
			CryMP.Msg.Console:ToPlayer(channelId,msg);
			--counter = counter - 1;
		end
		return -1;
	end
);

--==============================================================================
--COMMANDS

CryMP.ChatCommands:Add("commands", {
		Info = "list the commands",
		OpenConsole = true,
	},
	function(self, player, channelId)
		local access = player:GetAccess();
		local count = 0;
		for i = 0, access do --players watch premium commands
			local tbl = self.Sorted[i];
			if (tbl and #tbl > 0) then
				local c = 0;
				for i, d in pairs(tbl) do
					if (not d.Disabled and d.Info ~= "test command" and not d.Hidden and d.Name~="validate" and d.Name~="synch") then
						c=c+1;
					end
				end
				if (c > 0) then
					local group = (CryMP.Users.Access and CryMP.Users.Access[i]) or "Player";
					CryMP.Msg.Console:ToPlayer(channelId, "$9");
					CryMP.Msg.Console:ToPlayer(channelId, "$9"..("="):rep(35).."$9[ $5"..string:mspace(22,group.." ($6"..c.."$1)").." $9]"..("="):rep(68));
					CryMP.Msg.Console:ToPlayer(channelId, "$9");
				end
				local tmp="";
				for i, data in pairs(tbl) do
					if (i==#tbl) or (not data.Disabled and data.Info ~= "test command" and not data.Hidden and data.Name~="validate" and data.Name~="synch") then
						--local display = self:GetCommandInfoLine(channelId, data);
						local access = CryMP.Users:GetAccess(channelId);
						local unavailable = access + 1 == data.Access;
						local price = (data.Price and not unavailable) and "$9($1"..data.Price.." $9pp)";
						local msg = unavailable and "$8Premium " or self:GetRemainingTimeMessage(channelId, data);
						local wait = msg and "$9" or "$7";
						local msg = msg and "$4"..msg;
						tmp = tmp.." $1!$9"..string:rspace(15,(msg or "")..data.Name);
						--System.LogAlways(tmp);
						if (#tmp > 112 or i==#tbl) then
							CryMP.Msg.Console:ToPlayer(channelId, tmp);
							tmp = "";
						end
						count = count + 1;
					end
				end
			end
		end
		CryMP.Msg.Console:ToPlayer(channelId, "$9");
		CryMP.Msg.Console:ToPlayer(channelId, "$9                                          $9                            CMD-Help ( $1!COM $6? $9)");
		nCX.SendTextMessage(3, "Open console with [^] or [~] to view list of Commands ("..count..")", channelId);
		return -1;
	end
);

--==============================================================================
--TOP10

CryMP.ChatCommands:Add("top10", {
		Info = "view the server highscores",
		self = "PermaScore",
		OpenConsole=true,
	}, 
	function(self, player, channelId)
		nCX.SendTextMessage(3, "Open console with [^] or [~] to view the Top 10 Data", channelId);
		local header = "$9"..string.rep("=", 112);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[ $1HIGH:SCORES$9 ]========== $4################  ###  ## ###  ###### ### ############  ###### $9========[ $1HIGH:SCORES$9 ]");
		CryMP.Msg.Console:ToPlayer(channelId, "$9[  $7                            ###  ##   ## ###  ## ### ###     ###    ###   ###  ###                        $9  ]");
		CryMP.Msg.Console:ToPlayer(channelId, "$9[  $8                             ##  ##   ##  #####  ### ###     ###    ###   #######                         $9  ]");
		CryMP.Msg.Console:ToPlayer(channelId, "$9[  $8                             ##  ##   ## ###  ## ### ###     ###    ###     ###                           $9  ]");
		CryMP.Msg.Console:ToPlayer(channelId, "$9[  $9                             ##   #####  ###  ## ###  ###### ###    ###     ###                           $9  ]");
		CryMP.Msg.Console:ToPlayer(channelId, "$9[  $9                             ##  $9TOP$9:$9TEN$9                                    ###                           $9  ]");
		CryMP.Msg.Console:ToPlayer(channelId, header);
		if (g_gameRules.class == "PowerStruggle") then
			CryMP.Msg.Console:ToPlayer(channelId, "$9        $5NAME                  $9K       D      HS      S   $5LEVEL    $7XP     $9FIST   FRAG    VH    DUEL   PLAY$5:$9TIME");
		else
			CryMP.Msg.Console:ToPlayer(channelId, "$9        $5NAME                  $9K       D      HS      S   $5LEVEL    $7XP     $9FIST   FRAG    VH   ASSIST  PLAY$5:$9TIME");
		end
		CryMP.Msg.Console:ToPlayer(channelId, header);
		local info = self:GetInfo(10, player.Info.ID);
		for i, msg in pairs(info) do
			if (#info > 10 and i == 11) then
				CryMP.Msg.Console:ToPlayer(channelId, header);
			end
			CryMP.Msg.Console:ToPlayer(channelId, msg);	
		end
		CryMP.Msg.Console:ToPlayer(channelId, header);
		return -1;
	end
);

--==============================================================================
--STATS

CryMP.ChatCommands:Add("myrank", {
		Info = "view your server perma scores", 
		self = "PermaScore",
		OpenConsole=true,
	}, 
	function(self, player, channelId)
		local PS = (g_gameRules.class == "PowerStruggle");
		local lspace, rspace = 12, 5;
		local mspace = lspace + rspace;
		if (not self.gformat) then
			self.gformat = function(self, X, round, add)
				local color = round and "$6" or "$4";
				if (add) then
					return color..string:lspace(12, X)..string:rspace(5, add).."$9";
				end
				return color..string:lspace(12, X)..(" "):rep(5).."$9"
			end
		end
		if (not self.split) then
			self.split = function(self, C)
				local p1, p2;
				for value in C:gmatch("%w+") do
					if (not p1) then
						p1 = value;
					else
						p2 = value;
					end
				end
				return p1, (p2 and "."..p2);
			end		
		end
		local info, xp = {}, {};
		local keys = {100, 101, 102, 106,}; --kills, deaths, heads, selfkill
		for i, key in pairs(keys) do
			local amount = nCX.GetSynchedEntityValue(player.id, key) or 0;
			info[i] = amount;
		end
		local roundkdr = "0";
		if (info[1] ~= 0 and info[2] ~= 0) then
			roundkdr = tostring(info[1]/info[2]):sub(1, 3);
		end
		for i, amount in pairs(info) do
			info[i] = self:gformat(amount, true)
		end
		local r1, r2 = self:split(roundkdr)
		info.RoundRatio = self:gformat(r1, true, r2)
		local profileId = player.Info.ID;
		local rank = self:GetRank(profileId);
		local data = self:GetData(profileId)
		local data_xp = self:GetAwardTable(data.Level);
		for t, v in pairs(data_xp) do
			local red = v < 0;
			v = math.abs(v);
			xp[t] = string:mspace(rspace, (red and "$4-" or "$3+").."$9"..math:zero(v).."$9");
		end
		xp["empty"] = (" "):rep(rspace);
		for name, count in pairs(data) do
			info[name] = self:gformat(count);
		end
		info["empty"] = (" "):rep(mspace); 
		local ratio = ("%.2f"):format(data.Kills / math.max(data.Deaths, 1));
		local p1, p2 = self:split(ratio);
		info.Ratio = self:gformat(p1, false, p2);
		
		---------------------------
		--		Total Time
		---------------------------
		local totalMins, sec = self:GetPlayTime(profileId);
		local hour, min = CryMP.Math:ConvertTime(totalMins, 60);
		info.TotalTime = "$4"..string:mspace(mspace, math:zero(hour).."$9h:$4"..math:zero(min).."$9m");

		if (not PS) then
			local totalRatio = (data.Kills / math.max(totalMins, 1));
			totalRatio = ("%.2f"):format(totalRatio);
			local s1, s2 = self:split(totalRatio, true);
			info.Vehicles = self:gformat(s1, false, s2, true);
		end
			
		---------------------------
		--		Round Time
		---------------------------
		local roundMin, roundSec = self:GetPlayTime(profileId, true);
		local roundHour, minRound = CryMP.Math:ConvertTime(roundMin, 60);
		info.RoundTime = "$6"..string:mspace(mspace,math:zero(roundHour).."$9h:$6"..math:zero(minRound).."$9m");
		
		if (not PS) then
			local killRatio = (nCX.GetSynchedEntityValue(player.id, 100) or 0) / math.max(roundMin, 1);
			local roundRatio = ("%.2f"):format(killRatio);
			local v1, v2 = self:split(roundRatio, true);
			info.RoundKPM = self:gformat(v1, true, v2, true);
		end
		
		local streak, streakHS, mwlimit = 0, 0, 0;
		local ks = CryMP.KillStreaks and CryMP.KillStreaks:GetBuffer(player.id);
		if (ks) then
			streak, streakHS = ks.normal, ks.headshot;
			mwlimit = CryMP.KillStreaks.Config.MostWanted and CryMP.KillStreaks.Config.MostWanted.Kills or 0;
		end
		info.KillStreak = self:gformat(streak, true, "$9/$7"..mwlimit);
		info.HeadStreak = self:gformat(streakHS, true); 

		info.Alias = "$6"..string:mspace(mspace, data.Name).."$9";
		
		info.LevelProgress = self:gformat(data.Level, false, "$9($7"..self:GetLevelProgress(profileId).."%$9)");
		
		local next, lvl;
		if (CryMP.Equip) then
			next, lvl = CryMP.Equip:GetNextUnlock(data.Level);
			if (next) then
				local def = g_gameRules:GetItemDef(next);
				next = "$9"..((def and def.class) or next).."$9";
			end
		end
		local premium;
		if (self.Premium and totalMins < self.Premium) then
			local hours, mins = CryMP.Math:ConvertTime((self.Premium - totalMins), 60);
			premium = "Premium Access in: $5"..math:zero(hours).."$9h:$5"..math:zero(mins).."$9m";
		end			
		local header = "$9          [   $3XP:iNFO  $9]---------------[    $4ALL:TIME:STATS   $9]-----------------[     $6ROUND:STATS     $9]          ";
		local percent = "%";		
		CryMP.Msg.Console:ToPlayer(channelId, "$9[ RANK ]========================================================================================================");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$4                       ################  ###  ## ###  ###### ### ############  ######                     $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$7                            ###  ##   ## ###  ## ### ###     ###    ###   ###  ###                        $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$8                             ##  ##   ##  #####  ### ###     ###    ###   #######                         $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$8                             ##  ##   ## ###  ## ### ###     ###    ###     ###                           $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$9                             ##   #####  ###  ## ###  ###### ###    ###     ###                           $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$9                             ##   %s###                           $9===", string:rspace(42, "#$5"..rank.."$9:RANK"));
		CryMP.Msg.Console:ToPlayer(channelId, "$9================================================================================================================");
		--CryMP.Msg.Console:ToPlayer(channelId, header);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]                     [%s]                     [%s]", 			    xp.empty, info.empty, info.empty);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [      Kills [%s]        [      Kills [%s]",               xp.kill, info.Kills, info[1]);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [     Deaths [%s]        [     Deaths [%s]",               xp.death, info.Deaths, info[2]);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [   Suicides [%s]        [   Suicides [%s]",               xp.suicide, info.Suicides, info[4]);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [  HeadShots [%s]        [  HeadShots [%s]",               xp.head, info.Headshots, info[3]);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [   KD Ratio [%s]        [   KD Ratio [%s]",   		    xp.empty, info.Ratio, info.RoundRatio);
	if (PS) then
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [   Duelwins [%s]        [ KillStreak [%s]",         	    xp.duel, info.Duelwins, info.KillStreak);
	else
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [    Assists [%s]        [ KillStreak [%s]",         	    xp.duel, info.Duelwins, info.KillStreak);
	end
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [      Melee [%s]        [ HeadStreak [%s]",               xp.melee, info.Melee, info.HeadStreak);
	if (PS) then
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [   Vehicles [%s]        [            [%s]",               xp.empty, info.Vehicles, info.empty);
	else
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [  KPM Total [%s]        [  KPM Round [%s]",               xp.empty, info.Vehicles, info.RoundKPM);
	end
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [      Frags [%s]        [    Profile [%s]",        	    xp.frag, info.Frags, info.Alias);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [ Experience [%s]        [            [%s]",               xp.empty, info.XP, info.empty);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [      Level [%s]        [Next Unlock [%s]",               xp.empty, info.LevelProgress, string:mspace(mspace,(next or "PS only")));
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]        [  TotalTime [%s]        [   GameTime [%s]  %s",           xp.empty, info.TotalTime, info.RoundTime, (player:GetAccess() == 0 and premium or ""));
		CryMP.Msg.Console:ToPlayer(channelId, "$9[%s]                     [%s]                     [%s]",               xp.empty, info.empty, info.empty);
		--CryMP.Msg.Console:ToPlayer(channelId, header);
		CryMP.Msg.Console:ToPlayer(channelId, "$9================================================================================================================");
		nCX.SendTextMessage(3, "Open console with [^] or [~] to view your stats.", channelId);
		return -1;
	end
);

--===================================================================================
-- MODS

CryMP.ChatCommands:Add("mods", {
		Info = "display information about CryMP"
	}, 
	function(self, player, channelId)
		local Features = {
			"$5Features$9: $4 * $5Anticheat            $4~ $9The $5Ultimate Anticheat$9, provided by $5nCX 2.0$9.",
			"          $4 * $5Ban List             $4~ $9Noobs banned so far: $5"..#nCX.BanList(),
			"          $4 * $5Bullet Physics       $4~ $9Weapon Bullets are traveling after death. Will they reach the enemy?",
			--"          $4 * $5Battle Log           $4~ $9Notifications are sent to the client's $5Battle Log$9 display.",
			"          $4 * $5Chat Commands        $4~ $9Ingame commands with $5Partial Matching$9. Use $5!COM$9 for a list.",
			"          $4 * $5Cheater Punishment   $4~ $9A $5Big Surprise$9 awaits players who cheat...",
			--"          $4 * $5Console Commands     $4~ $9Execute commands via the $5console$9. Use $5!commands$9 for more information.",
			--"          $4 * $5Crash Detection      $4~ $9Server crashes are detected, and round stats $5restored automatically$9.",
			--"          $4 * $5Player Restore       $4~ $9You are being restored on reconnect automatically$9.",
			--"          $4 * $5Custom Vehicles      $4~ $9Special vehicle types such as $5Repair VTOL $9have been added.",
			"          $4 * $5Duel Arena           $4~ $9Challenge players to a 1v1 duel in the $5Duel Arena 2.0$9.",
			--"          $4 * $5Dynamic HQ Damage    $4~ $9Will your shot be a $5critical hit$9?",
			"          $4 * $5Error Handler        $4~ $9Internal mod errors are silently detected and will be $5Fixed Rapidly$9.",
			"          $4 * $5Enemy Base           $4~ $9Intrude the Enemy $5Base Proximity $9and kill enemy players!",
			"          $4 * $5Event System         $4~ $9Events are triggered every $515 mins$9...what will they be?",
			"          $4 * $5Equipment            $4~ $9Choose between $54 Preset Classes $9or customize your loadout individually.",
			"          $4 * $5Explosive Disarmer   $4~ $9Disarm and pick up the Enemy Explosives",
			"          $4 * $5Explosive Scanner    $4~ $5Enemy Explosives $9will be lightened up and marked on your Minimap.",
			"          $4 * $5Killstreaks          $4~ $9Get $5Rewards$9 for killing multiple players.",
			--"          $4 * $5Kill Assist          $4~ $9Gain extra Prestige Points for $5Kill Assists",
			--"          $4 * $5Most Wanted          $4~ $9Hunt down the most skilled players for $5great rewards$9.",
			"          $4 * $4nCX                  $4~ $9The $5nCX$9 DLL improves efficiency and provides anticheat tools.",
			"          $4 * $5New Scripts          $4~ $9New $5Factory, Capture & Buyzone $9system created from scratch.",
			"          $4 * $5Optimized Core       $4~ $9The Server Source has been rewritten for the best $5Stability & Performance$9.",
			"          $4 * $5Physicalized Doors   $4~ $9Blow up $5Doors Open $9with Explosives.",
			"          $4 * $5Race Mode            $4~ $9Can you beat the $5Other Racers$9?",
			"          $4 * $5Rank System          $4~ $9Kill players and gain experience to $5Level Up$9.",
			"          $4 * $5Rape Protection      $4~ $9$5Base$9, $5Bunker$9 & $5Tunnel $9protection from noobs.",
			"          $4 * $5Round Refresh        $4~ $9The $5Whole Round$9 is saved automatically, in case of a crash!",
			"          $4 * $5Score Restore        $4~ $9Lost connection? Don't worry, your score and rank are $5Auto - Saved$9.",
			"          $4 * $5Sound Effects        $4~ $9$5Sound effects$9 will play when some events happen, such as chatcommand usage.",
			"          $4 * $5Skill Balance        $4~ $9An $5Intelligent $9Team Balance conciders scores and balances teams if necessary.",
			"          $4 * $5Sky Boxing           $4~ $9Fight with your fists in $5ZeroG $9to survive in the $5Boxing Ring$9.",
			"          $4 * $5Squad Leader         $4~ $9The enemy got all Bunkers? Guide your Team Mates as the $5Squad Leader$9.",
			--"          $4 * $5TAC Protection       $4~ $9The $5TAC Protection $9applies only to players and vehicles not within Base Zone$9.",
			"          $4 * $5Vehicle Control      $4~ $9Tired of assholes stealing your vehicle? $5Lock & Remove$9 them remotely!",
			"          $4 * $5Weapon Attachments   $4~ $9An $5Attachment System $9is saving your Configuration automatically.",
			"          $4 * $5And Much More        $4~ $9Play and find out!",
			--"",
		};

		local Credits = {
			"$5Credits$9:",
			"$9~$4ctaoistrach$9 and $4DarkLite$9 who wrote $4"..CryMP.Version.String.."$9.",
			"$9~$4Arcziy$9, for creating $4nCX$9, a great anticheat DLL.",
			--"$9~$4Rod-Serling$9, $4Sitting-Duc>XI<$9, and $4-BROS-Zeppelin$9, for their work in $4Kinetic Developments$9.",
			"$9~$47Oxic$9, for providing a server with a $4great community$9, and for writing an awesome mod for $4Patriot$9.",
		};

		CryMP.Msg.Console:ToPlayer(channelId, "$9[ MODS ]========================================================================================================");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$4                       ################  ###  ## ###  ###### ### ############  ######                     $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$7                            ###  ##   ## ###  ## ### ###     ###    ###   ###  ###                        $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$8                             ##  ##   ##  #####  ### ###     ###    ###   #######                         $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$8                             ##  ##   ## ###  ## ### ###     ###    ###     ###                           $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$9                             ##   #####  ###  ## ###  ###### ###    ###     ###                           $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9===$9                             ##                                             ###                           $9===");
		CryMP.Msg.Console:ToPlayer(channelId, "$9================================================================================================================");
		--CryMP.Msg.Console:ToPlayer(channelId, "$9");
		--CryMP.Msg.Console:ToPlayer(channelId, "$9");
		for i, mod in pairs(Features) do
			CryMP.Msg.Console:ToPlayer(channelId, mod);
		end
		CryMP.Msg.Console:ToPlayer(channelId, "$9================================================================================================================");
		--CryMP.Msg.Console:ToPlayer(channelId, "$9");
		--for i, credit in pairs(Credits) do
		--	CryMP.Msg.Console:ToPlayer(channelId, string:mspace(112,credit));
		--end
		--CryMP.Msg.Console:ToPlayer(channelId, "$9");
		nCX.SendTextMessage(3, "SERVER:MODS :: CHECK YOUR CONSOLE!", channelId);
		return -1;
	end
);

--===================================================================================
-- RULES

CryMP.ChatCommands:Add("rules", {
		Info="display the server rules"
	}, 
	function(self, player, channelId)
		local Rules = {
			"$9[ $1RULES$9 ]================ $7################  ###  ## ###  ###### ### ############  ####$9 ================[ $1RULES$9 ]",
			"$9[  $7                            ###  ##   ## ###  ## ### ###     ###    ###   ###  ###                        $9  ]",
			"$9[  $7                             ##  ##   ##  #####  ### ###     ###    ###   #######                         $9  ]",
			"$9[  $7                             ##  ##   ## ###  ## ### ###     ###    ###     ###                           $9  ]",
			"$9[  $7                             ##   #####  ###  ## ###  ###### ###    ###     ###                           $9  ]",
			"$9[  $7                             ##  $57OXICiTY:RULES$7                             ###                           $9  ]",
			"$9==[ $5GAIN:ADVANTAGES$9 ]===========================================================================================",
			"$9",
			string:mspace(112,"$9Using $4CHEATS$9 and $4BUGABUSE$9 is prohibited in our server and will lead to a ban from the server"),
			"$9",
			"$9==[   $5FAIR:PLAY$9	   ]===========================================================================================",
			"$9",
			string:mspace(112,"$9Any kind of excessive Base and Bunker raping / Camping / Spawn Kill is not allowed and might be punished!"),
			"$9",
			"$9==[ $5GENERAL:STUFF$9   ]===========================================================================================",
			"$9",
			string:mspace(112, "$9Chat-Spam is not wanted.. for longer discussions use Skype or something similar!"),
			string:mspace(112, "$9Complaints about server / bugs are preferable by PM to Devs, not via Public Chat"),
			"$9",
			"$9",
			string:mspace(112, "$9Play $3Fair$9, have $3Fun$9 and $5Respect$9 your Playmates"),
			"$9",
		};
		for i, rule in ipairs(Rules) do
			CryMP.Msg.Console:ToPlayer(channelId, rule);
		end
		nCX.SendTextMessage(3, "Open console with [^] or [~] to view the rules.", channelId);
		return -1;
	end
);

--[[CryMP.ChatCommands:Add("updates", {
		Info = "view update info",
		self = "Msg",
	}, 
	function(self, player, channelId)
		local Updates = {
			{
				Info = "5.0.0 | (28/7/2013)",
				Admin = {
					"",
				},
				Public = {
					"",
				},
			},
		};
		self.Console:ToPlayer(channelId, "$9"..string:mspace(112, "[  $4CHANGE$9:$4LOG$9  ]", "="));
		for version, changes in ipairs(Updates) do
			self.Console:ToPlayer(channelId, "$9[ $1Version $9: $7"..changes.Info.."$9 ]");
			self.Console:ToPlayer(channelId, " ");
			for i, msg in pairs(changes.Public or {}) do
				self.Console:ToPlayer(channelId, "          $5-$9 "..msg);
			end
			if (player:GetAccess() > 1) then
				for i, msg in pairs(changes.Admin or {}) do
					self.Console:ToPlayer(channelId, "          $5-$4 "..msg);
				end
			end
			self.Console:ToPlayer(channelId, " ");
		end
		self.Console:ToPlayer(channelId, "$9"..string:mspace(112, "[  $4END$9:$4OF$9:$4LOG$9  ]", "="));
		nCX.SendTextMessage(3, "SERVER:UPDATES :: CHECK YOUR CONSOLE!", channelId);
		return -1;
	end
);]]

--==============================================================================
--!USERS
--[[
CryMP.ChatCommands:Add("users", {
		Access = 1, 
		Args = {
			{"group", Optional = true, Output = {{"Premium"},{"Moderator"},{"Administrator"},{"Super-Admin"},{"Developer"},},},
		},
		Info = "view the user list",
		self = "Users",
	},
	function(self, player, channelId, group)
		local acolor = { [1] = 6; [2] = 8; [3] = 3; [4] = 4; [5] = 7; };
		local extended = self:HasAccess(player.Info.ID, 4);
		CryMP.Msg.Console:ToPlayer(channelId, "$9[ USER:LIST ]===================================================================================================");
		CryMP.Msg.Console:ToPlayer(channelId, "$9              Name                          Access"..(extended and "             Profile") or "");
		CryMP.Msg.Console:ToPlayer(channelId, "$9----------------------------------------------------------------------------------------------------------------");
		for i,user in pairs(self.Users) do
			local access = user[2];
			local profile = extended and user[1] or "";
			local mask = self.Access[access];
			local c = "$"..acolor[access];
			if (not group or (group == mask)) then
				local status = "      ";
				local nc = "$9";
				local name = user[3];
				if (CryMP.Ent:GetPlayer(profile) and extended) then
					status = "$3ONLINE";
					nc = "$3";
					if (name ~= player:GetName()) then
						name = name.." $9($5"..player:GetName().."$9)";
					end
				end
				CryMP.Msg.Console:ToPlayer(channelId, "$9["..status.."$9]      "..nc..string:rspace(30, name)..c..string:rspace(18, mask).." $9"..profile);
			end;
		end
		CryMP.Msg.Console:ToPlayer(channelId, "$9"..string.rep("=", 112));
		nCX.SendTextMessage(3, "Open console with [^] or [~] to view the list of "..(group and group.."s" or "users"), channelId);
		return -1;
	end
);
]]