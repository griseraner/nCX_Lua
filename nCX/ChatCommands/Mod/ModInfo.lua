 --==============================================================================
--!MONITOR

CryMP.ChatCommands:Add("monitor", {
		Access = 2,
		Info = "monitor server activity",
		self = "PerformanceMonitor",
		InGame = true,
		Args = {
			{"index", Optional = true, Number = true, Output = {{"full", "default mode with all info"},{"graph", "performance animation"},},},
		},
	},
	function(self, player, channelId, index)
		self:Toggle(channelId, index);
		return true;
	end
);

--==============================================================================
--!BANLIST

CryMP.ChatCommands:Add("bansystem", {
		Access = 2,
		Args = {
			{"index", Access = 2, Optional = true, Number = true, Info = "leave empty to view the last 10 entrys (0 to view all)",},
			{"action", Access = 3, Optional = true, Output = {{"unban", "unban this player"},},},
		},
		Info = "view the permanent banlist",
	},
	function(self, player, channelId, index, action)
		local banlist = nCX.BanList();
		if (banlist and #banlist > 0) then
			local function view(which)
				local header = "$9================================================================================================================";
				CryMP.Msg.Console:ToPlayer(channelId, header);
				CryMP.Msg.Console:ToPlayer(channelId, "$9     Name                  Reason                  Admin                 Date                    Expiry");
				CryMP.Msg.Console:ToPlayer(channelId, "$9"..("="):rep(112));
				for i = which, #banlist do
					local ban = banlist[i];
					if (ban) then
						local expiry = ban.time ~= 0 and "$8"..ban.time.." min" or "$4Infinite";
						while (#tostring(i) < 3) do
							i = "0"..i;
						end
						CryMP.Msg.Console:ToPlayer(channelId, "$9[$5%s$9] $9%s$5|$9 %s$5|$9 %s$5|$9 %s$5|$9 %s",
							i,
							string:rspace(20, ban.Name:sub(1, 20)),
							string:rspace(22, ban.Reason:sub(1, 22)),
							string:rspace(20, (ban.BannedBy=="nCX" and "$4" or "")..ban.BannedBy:sub(1, 20)),
							string:rspace(22, ban.Date),
							expiry
						);
					end
				end
				CryMP.Msg.Console:ToPlayer(channelId, header);
				nCX.SendTextMessage(3, "Open console with [^] or [~] to view the banlist", channelId);
				return -1;
			end
			if (index) then
				if (action) then
					return CryMP.BanSystem:Unban(index, player:GetName());
				else
					if (index == 0) then
						return view(1);
					else
						local ban = banlist[index];
						if (ban) then
							local admin = ban.BannedBy;
							local c = admin == "nCX" and "$4nCX" or admin;
							local expiry = ban.time ~= 0 and ban.time or "$8Infinite";
							local info = {
								--"$9[%s | "..color.."%s $9]"..add, string:lspace(15, what), string:rspace(space, info));
								"$9================================================================================================================",
								"$9[           Name | $9"..string:rspace(25,ban.Name  ).."$9]            Entry | #$5"..math:zero(index),
								"$9[             IP | $9"..string:rspace(25,ban.IP    ).."$9]           Domain | $9"..ban.Host,
								"$9[        Profile | $9"..string:rspace(25,ban.ID    ).."$9]                  | ",
								"$9[         Reason | $4"..string:rspace(25,ban.Reason).."$9]        Banned by | $5"..c,
								"$9[      Timestamp | $9"..string:rspace(25,ban.Date  ).."$9]           Expiry | $5"..expiry,
								"$9================================================================================================================",
							};
							for i, msg in pairs(info) do
								local close = ""
								if (i ~= 1 and i ~= #info) then
									close = string:lspace(112-#msg:gsub("%$%d", ""), "$9]");
								end
								CryMP.Msg.Console:ToPlayer(channelId, msg..close);
							end
							CryMP.Msg.Chat:ToPlayer(channelId, "Open console with [^] or [~] for infos about ban #"..math:zero(index).." ("..ban.Name..")", 13);
							return -1;
						else
							return false, "Entry #"..index.." not found";
						end
					end
				end
			end
			return view(#banlist>10 and #banlist-10 or 1);
		else
			return false, "no ban data available"
		end
	end
);

--==============================================================================
--!LOOKUP [PLAYER]

CryMP.ChatCommands:Add("lookup", {
		Access = 2,
		Args = {
			{"player", Optional = true,},
		},
		Info = "get connection info on a player",
		OpenConsole = true,
		self = "PermaScore",
	},
	function(self, player, channelId, target)
		local target = (player.actor:GetSpectatorMode() ~= 0 and not target and CryMP.Ent:GetPlayer("-", player)) or CryMP.Ent:GetPlayer(target, player) or target;
		local data = {};
		local header = "$9================================================================================================================";
		if (target) then
			if (type(target) == "table") then
				local tbl = CryMP.Ent:Lookup(target);
				for i, msg in pairs(tbl or {}) do
					CryMP.Msg.Console:ToPlayer(channelId, msg);
				end
				nCX.SendTextMessage(3, "Open console with [^] or [~] to view user info of "..target:GetName(), channelId);
				return -1;
			else
				local tmp = {};
				target = target:lower();
				for profile, d in pairs(self.Players) do
					if (d.Name:lower():find(target)) then
						tmp[#tmp + 1] = d;
					end
				end
				if (#tmp > 0) then
					table.sort(tmp, function(p1, p2)
						local acc1, acc2 = CryMP.Users:GetAccess(p1.Profile), CryMP.Users:GetAccess(p2.Profile);
						if (acc1 == acc2) then
							return p1.PlayTime < p2.PlayTime;
						end
						return acc2 > acc1;
					end);
					for i, d in pairs(tmp) do
						if (i == 1) then
							CryMP.Msg.Console:ToPlayer(channelId, header);
							CryMP.Msg.Console:ToPlayer(channelId, "$9 Level Access       Name                           GameTime       Profile  Last Connected");
							CryMP.Msg.Console:ToPlayer(channelId, header);
						end
						local reported = CryMP.Reports and CryMP.Reports.Reports[d.Profile] and "$1($4!$1) " or "";
						local playh, playm = CryMP.Math:ConvertTime(d.PlayTime, 60);
						local playTime = "$1"..math:zero(playh).."$9h:$1"..math:zero(playm).."$9m";

						local lastSeen = CryMP.Math:DaysAgo(d.LastSeen, true, true);
						CryMP.Msg.Console:ToPlayer(channelId, "$9($1%s$9) %s %s(%s)   %s  %s",
							string:lspace(4, d.Level),
							string:rspace(12, CryMP.Users:GetMask(d.Profile)),
							string:rspace(25, "$5"..reported..d.Name).."$9",
							string:lspace(13, playTime),
							string:lspace(10, d.Profile),
							"$1"..string:lspace(14, lastSeen)
						);
					end
					CryMP.Msg.Console:ToPlayer(channelId, header);
					nCX.SendTextMessage(3, "Open console with [^] or [~] to view "..#tmp.." cached user info", channelId);
					return -1;
				end
			end
		end
		return false, "no player match found";
	end
);

--==============================================================================
--!PLAYERS

CryMP.ChatCommands:Add("players", {
		Access = 2,
		Info = "view info on all players",
		OpenConsole = true,
		Args = {
			{"mode", Optional = true,  
				Output = {
					{"domain", "Display the Host names",},
					{"ip", "Display the IP addresses",},
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
			local detections = CryMP.ServerDefence:GetDetectionCount(scan.Info.IP);
			local warn = detections > 0 and "$4" or "$1";
			local controller = "$9";
			local rse = "$9<0>";
			if (scan.Info.Controller) then
				controller = "$4";
			end
			rse = scan.Info.Client and controller.."<$5"..scan.Info.Client..controller..">" or rse;
			local reported = CryMP.Reports and CryMP.Reports.Reports[profileId] and "$1($4REPORT$1) " or "";
			reported = (scan.DEVMODE and "$1($6DEVMODE$1)" or "")..reported;
			local loggedIn = nCX.AdminSystem(scanId) and "$5Logged In$9" or profileId;
			local add = mode == "domain" and scan.Info.Host or mode == "ip" and scan.Info.IP or mode == "profile" and scan.Info.ID or scan.Info.Country;
			local minRound, secRound = scan:GetPlayTime(true);
			local hourRound, minRound = CryMP.Math:ConvertTime(minRound, 60);
			local roundtime = "$1"..math:zero(hourRound).."$9h:$1"..math:zero(minRound).."$9m";
			CryMP.Msg.Console:ToPlayer(channelId, "$9($3%s$9) %s %s(%s : %s)  %s   %s",
				string:lspace(4, scanId),
				string:rspace(12, acc[scan:GetAccess()]),
				string:rspace(24, reported..rse..scan:GetName()).."$9",
				warn..string:lspace(3, detections).."$9x",
				roundtime,
				string:lspace(10, loggedIn),
				add
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
			
		local function Print(players, tnames)
			local infoBar = mode == "domain" and "Domain    " or mode == "ip" and "IP Address" or "Country   ";
			table.sort(players, sort);
			CryMP.Msg.Console:ToPlayer(channelId, "$9"..line);
			CryMP.Msg.Console:ToPlayer(channelId, "$9 Slot  Access       Name                  Detects      Game      Profile   "..infoBar..string:lspace(27, "[ $3"..string:mspace(10, tnames).." $9($1"..#players.."$9) ]"));
			CryMP.Msg.Console:ToPlayer(channelId, "$9"..line);
			--CryMP.Msg.Console:ToPlayer(channelId, "$9");	
			for i, scan in pairs(players) do
				info(scan);
			end
			return #players;
		end
		
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
			for i = 1, 2 do
				local players = totalPlayers[i];
				if (#players > 0) then
					total = Print(players, tnames[i]);
				end
			end	
		else
			for i = 2, 0, -1 do
				local players = nCX.GetTeamPlayers(i);
				if (players) then
					total = Print(players, tnames[i]) + #players;
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

--==============================================================================
--!NETWORK

CryMP.ChatCommands:Add("network", {
		Access = 2,
		Info = "view server and players network usage",
	},
	function(self, player, channelId, mode)
		local tnames = {
			[0] = "SPECTATORS",[1] = "NK$9:$3TEAM",
			[2] = "US$9:$3TEAM",
		};
		--[[local acc = {
			[0] = "$9Player",[1] = "$6Premium",
			[2] = "$8Moderator",[3] = "$3Admin",
			[4] = "$4Super-Admin",[5] = "$7Developer",
		};]]
		local acc = {
			[0] = "$9",[1] = "$6",
			[2] = "$8",[3] = "$3n",
			[4] = "$4",[5] = "$7",
		};
		local function info(scan)
			local profileId = scan.Info.ID;
			local scanId = scan.Info.Channel;
			local up, down = scan.actor:GetNetworkUsage();
			local str = "*";
			CryMP.Msg.Console:ToPlayer(channelId, "$9($3%s$9) %s %s %s",
				string:lspace(4, scanId),
				string:rspace(12, acc[scan:GetAccess()]..("*"):rep(scan:GetAccess())),
				string:rspace(22, "$1"..scan:GetName()).."$9",
				string:lspace(6, up).."$9 k/s                 "..string:lspace(6, down).."$9 k/s"
			);
		end
		
		local function sort(p1, p2)
			local acc1, acc2 = p1:GetAccess(), p2:GetAccess()
			if (acc1 == acc2) then
				return p2.Info.Channel < p1.Info.Channel;
			end
			return acc2 > acc1;
		end
		local line = ("="):rep(112);
		local total = 0;
		for i = 2, 0, -1 do
			local players = nCX.GetTeamPlayers(i);
			if (players) then
				table.sort(players, sort);
				CryMP.Msg.Console:ToPlayer(channelId, "$9"..line);
				CryMP.Msg.Console:ToPlayer(channelId, "$9 Slot  Access       Name                   Net Usage");
				CryMP.Msg.Console:ToPlayer(channelId, "$9"..line);
				--CryMP.Msg.Console:ToPlayer(channelId, "$9");	
				for i, scan in pairs(players) do
					info(scan);
				end
				total = total + #players;
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

--==============================================================================
--!STATS

CryMP.ChatCommands:Add("infostats", {--rough version
		Access = 1, 
		Info = "view stats on all players",
		self = "PermaScore",
	},
	function(self, player, channelId)
		local names = {
			[0] = "SPECTATORS",
			[1] = "NK:TEAM",
			[2] = "US:TEAM",
		};
		CryMP.Msg.Console:ToPlayer(channelId, "$9");
		CryMP.Msg.Console:ToPlayer(channelId, "$9[ $1INFO:STATS$9 ]=====================================$4 7OXICiTY $9=====================================[ $1INFO:STATS$9 ]");
		CryMP.Msg.Console:ToPlayer(channelId, "$9        $5NAME                  $4K       D      HS      S   $5LEVEL    $7XP     $4FIST   FRAG    VH    DUEL   PLAY:TIME");
		CryMP.Msg.Console:ToPlayer(channelId, "$9"..("="):rep(112));
		for i = 2, 0, -1 do
			if ((i == 0 and player:GetAccess() > 1) or (i > 0)) then
				local players = nCX.GetTeamPlayers(i);
				if (players) then
					local name = names[i];
					--CryMP.Msg.Console:ToPlayer(channelId, "$9"..string.rep("=", 112));
					CryMP.Msg.Console:ToPlayer(channelId, "$9"..string:lspace(112, "$9[ $3"..string:mspace(10,name).." $9($1"..#players.."$9) ]", nil, "="));
					CryMP.Msg.Console:ToPlayer(channelId, "$9"..("="):rep(112));
					for i, player in pairs(players) do
						CryMP.Msg.Console:ToPlayer(channelId, self:GetInfo(player, player.Info.ID));
					end
				end
			end
		end
		CryMP.Msg.Console:ToPlayer(channelId, "$9"..("="):rep(112));
		nCX.SendTextMessage(3, "Open console with [^] or [~] to view stats of players", channelId);
		return true;
	end
); 

--==============================================================================
--!DISCONNECTS

CryMP.ChatCommands:Add("disconnects", {
		Access = 2,
		Args = {
			{"index",   Optional = true, Number = true, Info = "Choose disconnect index",},
			{"action",  Optional = true, Access = 3, 
				Output = {
					{"ban",	   "Ban player",},
				},
			},
			{"bantype", Optional = true, Access = 3, Number = true, Info = "time the player should be banned (use 0 for permaban)",},
			{"reason",  Optional = true, Access = 3, Concat = true,},
		},
		Info = "view and manage recently disconnected players",
		self = "BanSystem",
	},
	function(self, player, channelId, index, action, time, reason)
		local line = "$9================================================================================================================";
		if (#self.Quits ~= 0) then
			local function view()
				CryMP.Msg.Console:ToPlayer(channelId, line);
				CryMP.Msg.Console:ToPlayer(channelId, "$9      Name                    Cause                                                            Time Ago");
				CryMP.Msg.Console:ToPlayer(channelId, line);
				local i = 0;
				for i, data in pairs(self.Quits) do
					local reason, banned = CryMP.Ent:GetDisconnectReason(data.Cause or 27);
					local reason = (banned and reason.." : "..data.Msg) or reason;
					local time = data.ServerTime;
					if (time) then
						local min, sec = CryMP.Math:ConvertTime(_time - time, 60);
						local hour, min = CryMP.Math:ConvertTime(min, 60);
						time = "$1"..string:lspace(4, math:zero(hour)).."$9h:$1"..math:zero(min).."$9m:$1"..math:zero(sec).."$9s";
					end
					CryMP.Msg.Console:ToPlayer(channelId, "$9[#$1"..math:zero(i).."$9]  $9"..string:rspace(22,data.Name or "").."$5|$9 "..string:rspace(62,reason or "").."$5|$9"..(time or ""));
				end
				CryMP.Msg.Console:ToPlayer(channelId, line);
			end
			if (index) then
				local data = self.Quits[index];
				if (data) then
					if (action == "ban") then
						if (time) then
							if (reason) then
								return self:LoadBan(index, reason, player:GetName(), time);
							end
							return false, "specify reason";
						end
						return false, "specify time", "0 for permaban";
					else
						--index = math:zero(index);
						CryMP.Msg.Console:ToPlayer(channelId, line);
						CryMP.Msg.Console:ToPlayer(channelId, "$9[%s | $5%s$9]", string:lspace(15, "Index"), string:rspace(92, index.." $3< Ex: $9!disco "..index.." ban cheater $3>"));
						local first = true;
						for n, v in pairs(data) do
							if (n == "Cause") then
								v, banned = CryMP.Ent:GetDisconnectReason(v or 27);
							elseif (n == "GameTime") then
								n = "Game Time";
								local hourRound, minRound = CryMP.Math:ConvertTime(v, 60);
								v = "$5"..math:zero(hourRound).."$9h:$5"..math:zero(minRound).."$9m";
							elseif (n == "ServerTime") then
								n = "Time Ago";
								local min, sec = CryMP.Math:ConvertTime(_time - data.ServerTime, 60);
								local hour, min = CryMP.Math:ConvertTime(min, 60);
								v = "$5"..math:zero(hour).."$9h:$5"..math:zero(min).."$9m:$5"..math:zero(sec).."$9s";
							end
							CryMP.Msg.Console:ToPlayer(channelId, "$9[%s | $5%s$9]", string:lspace(15, n), string:rspace(92, v));
						end
						CryMP.Msg.Console:ToPlayer(channelId, line);
						CryMP.Msg.Chat:ToPlayer(channelId, "Open console with [^] or [~] for "..(data["Name"] or "n/a").."'s disconnection data!", 1);
						return true;
					end
				end
				return false, "entry not found"
			end
			view();
			CryMP.Msg.Chat:ToPlayer(channelId, "Open console with [^] or [~] to view disconnection data!", 1);
			return true;
		end
		return false, "no data available"
	end
);

