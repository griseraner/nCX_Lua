CryMP:SetConfig({

	--ServerMods = true,
	
	RSE = true,
	
	BanSystem = true,

	ServerDefence = true,

	SquadLeader = true,
	
	Reports = true,
	
	Repair = true,

	ChatCommands = true,

	Vehicles = true,
	
	Equip = true,
	
	Attach = true,

	--AFKManager = true,
	
	HQMods = true,
	
	ZoneOut = true,
	
	Synch = true,
	
	---------------------------
	--		Dynamic Plugins (enabled when needed)
	---------------------------
	
	Mute = false,
	
	PenaltyBox = false,
	
	Boxing = false,
	
	Duel = false,
	
	Race = false,
	
	--SelfDestruct = false,
		
	---------------------------
	--		Message Spam
	---------------------------
	--[[
	MessageSpam = {
		[-2] = {  	-- iNFO
			'return "Weapon Bullets are traveling after death. Will they reach the enemy?"',
			'return "A Big Surprise awaits players who cheat. Do NOT even attempt!"',
			'return "Challenge players to a 1v1 duel in the Duel Arena 2.0."',
			'return "Disarm and pick up Enemy Explosives."',
			'return "The Radar Scanner will detect nearby Enemy explosives and mark them on your Minimap."',
			'return "Gain extra Points for Kill Assists."',
			'return "The nCX DLL improves efficiency and provides anticheat tools."',
			'return "The Server Source has been rewritten for the best Stability & Performance."',
			'return "Blow up Doors Open with Explosives."',
			'return "Kill players and gain experience to Level Up."',
			'return "Lost connection? Dont worry, your score and rank are Auto - Saved."',
			'return "An Intelligent Team Balance conciders scores and balances teams if necessary."',
			'return "An Attachment System is saving your Configuration automatically."',
			--PS only
			'return "Special vehicle types such as Repair VTOL have been added."',
			'return "Intrude the Enemy Base Proximity and kill enemy players!"',
			'return "Base, Bunker & Tunnel protection ONLINE."',
			'return "Fight with your fists in ZeroG to survive in the Boxing Ring."',
			'return "The enemy got all Bunkers? Guide your Team mates as the Squad Leader."',
			'return "The TAC Protection applies only to players and vehicles not within Base Zone."',
		},
		[-1] = {	-- ALL
			'return nCX.GetPlayerCount().."/"..System.GetCVar("sv_maxplayers").." players connected" * 64 Bit Server Memory Usage: "..nCX.GetMemoryUsage().." mb * Average ping: "..nCX.GetPingAverage().." * Highest Channel: "..nCX.GetHighestChannel()',
			'return "Server powered by "..CryMP.Version.String.." and nCX 2.0.0"',
			'return "Banned players : #"..#nCX.BanList();',
			'return "Running "..g_gameRules.class.." : Map "..nCX.GetCurrentLevel():sub(16, -1);',
			'return "nCX AntiCheat Systems - ( ONLINE )"',
			'return "Server Runtime "..(CryMP.Math:GetServerUptime(true).days > 0 and CryMP.Math:GetServerUptime(true).days.." d : " or "")..CryMP.Math:GetServerUptime(true).hours.." h : "..CryMP.Math:GetServerUptime(true).minutes.." m"',
			'return CryMP:GetBoxingMsg();',
			"return os.date(\"It's %I:%M %p (GMT +1 hour)\")",
			'return "RPG (LAW) does NOT harm infantry."',
			'return (CryMP.LockDowns and CryMP.LockDowns:GetAirMode(nil, true)) or "Vehicle Status : VTOL : N/A * Helicopter : N/A"',
			'return "SPIN Jackpot : "..(CryMP.ChatCommands and CryMP.ChatCommands.Jackpot or 10000).." PP"',
			'return "BOXING : DUEL : RACE & many features available!"',
			function(player)
				return "Your Server Rank : #"..player:GetRank();
			end,
		},
		[2] =  {	-- Moderators + above
			'return nCX.GetPlayerCount().."/"..System.GetCVar("sv_maxplayers").." players connected."',
			'return "Average Ping : "..nCX.GetAveragePing().." * Dynamic Ping Limit : "..System.GetCVar("nCX_HighPingLimit");',
			'return "Last Ban: "..(CryMP.BanSystem:GetLastBan(true) or "None");',
			function(player)
				local errors = CryMP.ErrorHandler:GetStatus();
				local reports = CryMP.Reports and CryMP.Reports:GetUnreadCount(player.Info.ID);
				local errcount = player:GetAccess() > 3 and errors > 0 and errors;
				local repcount = reports and reports > 0 and reports;
				if (repcount) then 
					return "System ** ( #"..math:zero(repcount).." unread Report"..(repcount > 1 and "s" or "").." ) ** Status"; 
				elseif (errcount) then
					return "System ** ( #"..math:zero(errcount).." Error"..(errcount>1 and "s" or "").." detected ) ** Status";
				else
					local current, min, max = nCX.GetServerPerformance();
					return "64 Bit Server Memory Usage : "..nCX.GetMemoryUsage().." mb * Server Performance : "..current.." %";
				end
			end,
		},
		[1] = {		-- Premium
			'return nCX.GetPlayerCount().."/"..System.GetCVar("sv_maxplayers").." players connected" * 64 Bit Server Memory Usage: "..nCX.GetMemoryUsage().." mb * Average ping: "..nCX.GetPingAverage().." * Highest Channel: "..nCX.GetHighestChannel()',
			'return "Want to join our clan? Apply at www.7oxicity.tk."',
			'return "Like the server? Support us by donating at www.7oxicity.tk."',
		},
		[0] = {		-- Players
			'return "Visit our homepage - www.7oxicity.tk."',
			'return "Request a Public Vote with the !VOTE command! Vote to kick a player, to change the map and toggle vtol on & off."',
			'return "Discover our mods - type !MODS to find out more."',
			'return "Type !COMMANDS in chat for more chat commands."',
			'return "Type !TOP10 for a list of the top 10 players."',
		},
	},]]
	
	---------------------------
	--		Hit Plugin Settings
	---------------------------
	KillStreaks = {

		Standard = {
			[3] = {
				name = "KILLING SPREE", w = "is on a",
			},
			[6] = {
				name = "RAMPAGE", w = "is on a",
			},
			[9] = {
				name = "DOMINATING",
			},
			[12] = {
				name = "UNSTOPPABLE",
			},
			[15] = {
				name = "GODLIKE",
			},
			[18] = {
				name = "THE PUSSY LICKER",
			},
			[21] = {
				name = "CRAZY RAPIST", w = "is a",
			},
			[24] = {
				name = "SUPER FAPPER", w = "is a",
			},
			[27] = {
				name = "MENTALIST", w = "is a",
			},
			[30] = {
				name = "INSANE",
			},
			[33] = {
				name = "HEART BREAKER", w = "is a",
			},
			[36] = {
				name = "LIFE TAKER", w = "is a",
			},
			[39] = {
				name = "DRUNKEN STYLE",
			},
			[42] = {
				name = "MUMMY HUMPER", w = "is a",
			},
			[45] = {
				name = "?GODMODE?", w = "is on",
			},
			[48] = {
				name = "FATTER THEN ELVIS",
			},
			[51] = {
				name = "PEACE BE UPON YOU",
			},
			[54] = {
				name = "!!!ALLAH!!!",
			},
			[57] = {
				name = "OMG",
			},
			[60] = {
				name = "7OXICITY",
			},
		},
		Headshot = {
			[3] = {
				name = "HEADMASTER",
			},
			[6] = {
				name = "BRAIN DRAINER",
			},
			[9] = {
				name = "KAMPER KING",
			},
			[12] = {
				name = "GREAT ANTI-HEAD", w = "makes",
			},
		},
	},

	--RapeProtection = true,

	--HitDamage = {
	--	["LAW"] = {
	--		Shooter = "[ STOP ]  > > > >  NO ROCKET ON INFANTRY !",
	--		Target = "[ PROTECTED ]  < < < <  ROCKET LAUNCHER !",
	--		Effect = true,
	--	},
	--},
	
	--LevelSetup = true,

	--JoinMessages = true,

	--PermaScore = true,

	PerformanceMonitor = true,
	
	AutoBalance = true,

	--LockDowns = {
	--	MaxPing = 150,
	--	MaxHeavyVtols = 2, --max heavy vtols per team
	--	MinPlayers = 12, --min players to buy heavy vtol
	--},

	Refresh = true,

	ScoreRestore = true,
	
	--EventSystem  = true,

});
