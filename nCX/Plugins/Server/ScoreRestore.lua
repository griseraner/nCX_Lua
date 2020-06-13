ScoreRestore = {
	
	---------------------------
	--		Config
	---------------------------
    Scores 			= {}, 
	
	Server = {
		
		OnConnect = function(self, channelId, player, profileId, reset)
			local restored = self:Restore(player);
			local name = player:GetName();
			local CC = player.Info.Country_Short;
			if (not player:IsNomad() and CC ~= "EU") then
				name = name.." ("..CC..")";
			end
			local access = player:GetAccess();
			local mask = CryMP.Users:GetMask(profileId);
			local mask = access > 0 and mask.." "..name or name;
			if (restored) then
				nCX.Log("Player", "Restored score for "..mask);
			end
			--CryMP.Msg.Chat:ToPlayer(channelId, self:GetWelcomeMessage(CC, restored):format(mask));
			self:Log(name.." connecting on slot "..channelId..(restored and " ($5restored$9)" or "").." ("..player.Info.Country.." | "..player.Info.Provider..")");

		end,

		OnDisconnect = function(self, channelId, player, profileId, access, cause)
			if (cause ~= 13 and not nCX.ProMode) then
				self:Save(player);
			end
			local cause, banned = CryMP.Ent:GetDisconnectReason(cause);
			if (not banned) then
				local name = player:GetName();
				local cause = cause:lower();
				local gameTime = player:GetPlayTime(true);
				if (gameTime > 0) then
					local hourRound, minRound = CryMP.Math:ConvertTime(gameTime, 60);
					local roundtime = hourRound > 0 and "$5"..math:zero(hourRound).."$9h:$5"..math:zero(minRound).."$9m" or "$5"..math:zero(minRound).."$9m";
					self:Log(name.." disconnecting from slot "..channelId.." ("..roundtime..", "..cause..")");
				else
					self:Log(name.." disconnecting from slot "..channelId.." ("..cause..")");
				end
			else
				System.LogAlways(player:GetName().." banned ("..cause..")");
			end
		end,

		OnNewMap = function(self, map, boot)
			if (not nCX.ProMode and (boot or (g_gameRules.class == "InstantAction" and nCX.Refresh))) then
				local count = self:Read(true);
				if (count > 0) then
					CryMP:SetTimer(5, function()
						self:Log("Loaded "..count.." x Scores from previous round");
						nCX.Refresh = false;
					end);
				end
			end
		end,

	},
	
	OnInit = function(self)
		if (not nCX.ProMode) then
			self:SetTick(160);
		end
	end,
	
	OnShutdown = function(self, restart)
		if (nCX.Refresh or restart == 1) then
			self:SaveScores();
			System.LogAlways("[ScoreRestore] Saving scores...");
		end
	end,
	
	OnTick = function(self)
		self:SaveScores();
	end,
	
	GetWelcomeMessage = function(self, country, restored)
		if (country == "UA" or country == "BG" or country == "BY") then
			country = "RU";
		end
		local tbl = {
			["DE"] = "Willkommen auf dem Server, %s!",
			["FR"] = "Bienvenue sur le serveur, %s!",
			["FI"] = "Tervetuloa palvelimelle, %s!",
			["DK"] = "Velkommen til serveren, %s!",
			["NO"] = "Velkommen til serveren, %s!",
			["SE"] = "Valkommen till servern, %s!",
			["IT"] = "Benvenuti al server, %s!",
			["NL"] = "Welkom op de server, %s!",
			["PL"] = "Witamy na serwerze, %s!",
			["PT"] = "Bem-vindo ao servidor, %s!",
			["SK"] = "Vitajte na serveri, %s!",
			["SI"] = "Dobrodošel na strežnik, %s!",
			["ES"] = "Bienvenido al servidor, %s!",
			["CZ"] = "Vítejte na serveru, %s!",
			["TR"] = "Sunucu Hosgeldiniz, %s!",	
			["RU"] = "Dobro pozhalovat' na server, %s!", 
		};
		if (restored) then
			tbl = {
				["DE"] = "Willkommen zurueck, %s. Dein Score wurde wiederhergestellt!",
				["FR"] = "Bienvenue, %s. Vos scores ont ete restaures!",
				["FI"] = "Tervetuloa takaisin, %s. Sinun pisteet on palautettu!",
				["DK"] = "Velkommen tilbage, %s. Dine scores er blevet gendannet!",
				["NO"] = "Velkommen tilbake, %s. Poengsummene er gjenopprettet!",
				["SE"] = "Vaelkommen tillbaka, %s. Dina poaeng har aterstaellts!",
				["IT"] = "Bentornato, %s. I tuoi punteggi sono stati ripristinati!",
				--["HR"] = "Dobrodošli natrag, %sa. Vaši rezultati su vraceni!",
				["NL"] = "Welkom terug, %s. Uw scores zijn hersteld!", 
				["PL"] = "Witaj z powrotem, %sa. Twoje wyniki zostaly przywrocone!", 
				["PT"] = "Bem-vindo de volta, %s. Suas pontuacoes foram restaurados!",  
				["SK"] = "Vitajte spaet, %s. Vase vysledky boli obnovene!",
				["SI"] = "Dobrodosel nazaj, %s. Vasi rezultati so bili obnovljeni!",
				["ES"] = "Bienvenido de nuevo, %s. Sus resultados han sido restaurados!", 
				["CZ"] = "Vítejte zpatky, %s. Vase vysledky byly obnoveny!", 
				["TR"] = "Geri %s hosgeldiniz. Puanlariniz restore edilmistir!",
				["RU"] = "S vozvrashcheniyem, %s. Vashi score byli vosstanovleny!",
			};
			return tbl[country] or "Welcome back, %s. Your scores have been restored!";
		end
		return tbl[country] or "Welcome to the server, %s!";	
	end,
	
	Restore = function(self, player)
		local profileId = player.Info.ID;
		local scores = self.Scores[profileId];
		if (scores) then
			nCX.SetSynchedEntityValue(player.id, 100, scores.Kills);
			nCX.SetSynchedEntityValue(player.id, 101, scores.Deaths);
			nCX.SetSynchedEntityValue(player.id, 102, scores.Headshots);
			CryAction.SendGameplayEvent(player.id, 9, "kills", scores.Kills); --eGE_Scored
			CryAction.SendGameplayEvent(player.id, 9, "deaths", scores.Deaths);
			if (g_gameRules.class == "PowerStruggle") then
				g_gameRules:SetPlayerPP(player.id, math.max(scores.PP, g_gameRules:GetRankPP(scores.Rank)));
				g_gameRules:SetPlayerCP(player.id, g_gameRules:GetRankCP(scores.Rank));
			else
				nCX.SetSynchedEntityValue(player.id, 105, scores.Assists);
			end
			return true;
		end
		return false;
	end,

	Save = function(self, player)
		local profileId = player.Info.ID;
		local kills = nCX.GetSynchedEntityValue(player.id, 100) or 0;
		local ps = (g_gameRules.class == "PowerStruggle");
		if (kills ~= 0) then
			self.Scores[profileId] = {
				Profile = profileId,
				Kills = kills,
				Deaths = nCX.GetSynchedEntityValue(player.id, 101) or 0,
				Headshots = nCX.GetSynchedEntityValue(player.id, 102) or 0,
				PP = (ps and g_gameRules:GetPlayerPP(player.id)) or 0,
				Rank = (ps and g_gameRules:GetPlayerRank(player.id)) or 0,
				Assists = (not ps and (nCX.GetSynchedEntityValue(player.id, 105) or 0)) or 0;
			};
		end
	end,

	Add = function(self, p, k, d, h, pp, rnk, a)
		local ps = (g_gameRules.class == "PowerStruggle");
		local pp = ps and pp or 0;
		local rnk = ps and rnk or 0;
		self.Scores[p] = {
			Profile = p,
			Kills = k,
			Deaths = d,
			Headshots = h,
			PP = pp,
			Rank = rnk,
			Assists = a or 0,
		};
		--if (p == "127492336") then
		--	System.LogAlways(p.." $4"..k.." $9"..debug.traceback("nil", 2));
		--end
	end,

	Write = function(self)
		local FileHnd = io.open(CryMP.Paths.ServerData.."Data_ScoreRestore_"..g_gameRules.class..".lua", "w+");
		if (FileHnd) then
			for index, Entry in pairs(self.Scores) do
				FileHnd:write("CryMP.ScoreRestore:Add('"..Entry.Profile.."', "..Entry.Kills..", "..Entry.Deaths..", "..Entry.Headshots..", "..Entry.PP..", "..Entry.Rank..", "..Entry.Assists..");\n");
			end
			FileHnd:close();
		else
			System.LogAlways("[ScoreRestore] Error: No Data file found!");
		end
	end,

	Read = function(self, apply)
		local a = require("Data_ScoreRestore_"..g_gameRules.class, "data file");
		if (not a) then
			return false;
		end
		if (apply) then
			local players = nCX.GetPlayers();
			if (players) then
				for i, player in pairs(players) do
					self:Restore(player)
				end
			end
		end
		local count = nCX.Count(self.Scores);
		System.LogAlways("[ScoreRestore] Reading "..count.."x scores");
		return count;
	end,

	Purge = function(self)
		local FileHnd = io.open(CryMP.Paths.ServerData.."Data_ScoreRestore_"..g_gameRules.class..".lua", "w+");
		if (FileHnd) then
			FileHnd:close();
		end
	end,
	   
	SaveScores = function(self)
        local players = nCX.GetPlayers();
	    for i, player in pairs(players or {}) do
    	    self:Save(player);
	    end
	    self:Write();
    end,

};

