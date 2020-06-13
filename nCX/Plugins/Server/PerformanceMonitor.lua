PerformanceMonitor = {

	---------------------------
	--		Config
	---------------------------
	Monitor 		= {},
	Tick 			= 1,
	DefaultMaxRate  = 60,
	MinMaxRate 		= 5,

	Server = {
		
		OnConnect = function(self, channelId, player, id, reset)
			local joined = nCX.GetHighestChannel();
			if (joined > 0 and joined % 500 == 0) then
				CryMP.Msg.Chat:ToAll(joined.." players have joined since the last reboot!", self.Tag);
				local pp = joined * 2;
				CryMP.Msg.Chat:ToAll(pp.." PP for everyone!", self.Tag);
				CryMP.Library:Pay(3, pp, 0, true);
			end
			local count = nCX.GetPlayerCount();
			if (tonumber(System.GetCVar("sv_dedicatedMaxRate"))~=self.DefaultMaxRate and not reset) then
				System.SetCVar("sv_dedicatedMaxRate", self.DefaultMaxRate);
				System.LogAlways("[nCX] > 1 Players. Setting Default Maxrate: "..self.DefaultMaxRate);
			end
			--System.SetCVar("g_revivetime", math.min(8, count));
		end,
		
		OnDisconnect = function(self, channelId, player, id)
			self.Monitor[channelId] = nil;
			local count = nCX.GetPlayerCount();
			if (count == 1) then
				System.SetCVar("sv_dedicatedMaxRate", self.MinMaxRate);
				System.LogAlways("[nCX] 0 Players. Throttling down! Maxrate: "..self.MinMaxRate);
			end
			--System.SetCVar("g_revivetime", math.max(1, count));
		end,
		
		OnChangeSpectatorMode = function(self, player, mode, targetId, reset)
			self.Monitor[player.Info.Channel] = nil;
		end,
	
		OnRevive = function(self, channelId, player, vehicle, first)
			if (player:GetAccess() > 1) then
				--nCX.SendTextMessage(0, " ", channelId);
				nCX.SendQueueMessage(0, "", 0, channelId);
			end
		end,

	},
	
	OnShutdown = function(self, restart) 
		if (not restart) then
			System.SetCVar("sv_dedicatedMaxRate", self.DefaultMaxRate);
		end
	end,
	
	Toggle = function(self, channelId, index)
		if (self.Monitor[channelId]) then
			if (index) then
				self.Monitor[channelId] = index;
				CryMP.Msg.Chat:ToPlayer(channelId, "SERVER:MONITOR -[ UPDATED ]", self.Tag);
			else
				self.Monitor[channelId] = nil;
				--if (nCX.Count(self.Monitor) == 0) then
					--self:SetTick(false);
				--end
				CryMP.Msg.Chat:ToPlayer(channelId, "SERVER:MONITOR -[ DISABLED ]", self.Tag);
				nCX.SendTextMessage(5, "", channelId);
			end
		else
			self.Monitor[channelId] = index or 1;
			--if (nCX.Count(self.Monitor) == 1) then
				--self:SetTick(1);
			--end
			CryMP.Msg.Chat:ToPlayer(channelId, "SERVER:MONITOR -[ ENABLED ]", self.Tag);
		end
	end,
			  
	OnTick = function(self, players)
		local current, min, max = nCX.GetServerPerformance();
		local mem = nCX.GetMemoryUsage();
		local ping = nCX.GetAveragePing();
		local count = nCX.GetPlayerCount();
		local soundWarning = false;
		if (ping > 200 and nCX.GetPlayerCount() > 5) then
			CryMP.Msg.Chat:ToAccess(3, "[Warning] Average ping ("..ping..") too high!");
			self:Log("[$4Warning$9] System Status ("..current.."%, "..mem.."mb, $4"..ping.."$9)", true);
			nCX.Log("Performance", "[Warning] Average Ping too high! System Status ("..current.."%, "..mem.."mb, "..ping..")", true);
			--soundWarning = true;
		end
		for i, player in pairs(players) do
			local access = player:GetAccess();
			if (soundWarning and access > 2) then
				CryMP.Ent:PlaySound(player.id, "alert");
			end
			if (player.actor:GetSpectatorMode() == 3 and (not g_gameRules.reviveQueue or not g_gameRules.reviveQueue[player.id])) then
				local specId = player.actor:GetSpectatorTarget(); 
				local target = specId and nCX.GetPlayer(specId);
				if (target) then
					local chan = target.Info.Channel;
					nCX.SendTextMessage(0, string.rep(" ", 157).." ( "..math:zero(chan).." : "..string:lspace(5, nCX.GetPing(chan)).." ms, "..(target.Info.Country_Short or "N/A").." )", player.Info.Channel);
				end
			end
		end				
		if (nCX.Count(self.Monitor) > 0) then
			local maxp = System.GetCVar("sv_maxplayers");
			local chan = nCX.GetHighestChannel();
			local ping = nCX.GetAveragePing();
			local mcolor, vcolor = "#007ACC", "#A4A4A4";
			local up, down = nCX.GetServerNetworkUsage();
			for channelId, v in pairs(self.Monitor) do
				if (v == 1) then
					nCX.SendTextMessage(0, "PERFORMANCE ( "..current.."% ) MEMORY:USAGE ( "..mem.." mb ) PLAYERS ( "..count.." / "..maxp.." ) MAX:CHANNEL ( "..chan.." ) AVERAGE:PING ( "..ping.." ) NETWORK ( "..up.." / "..down.." )", channelId);				
					--nCX.SendTextMessage(0, min.." | "..max, channelId);
				else
					local hull = string.rep("|", math.min(200, current));
					local remaining = string.rep("|", math.min(200, 200 - current))
					local normal = System.GetCVar("nCX_PerformanceValue");
					local diff = math.abs(normal - current);
					if (diff > 20 and diff < 50) then
						mcolor = "#FF8000";
					elseif (diff > 50) then
						mcolor = "#B40404";
					end
					nCX.SendTextMessage(0, hull..remaining, 0, channelId);
					local msg = [[
						
						
						
						
						
														
																		Current Performance : ]]..string:lspace(3, current)..[[%  ( MaxRate ]]..System.GetCVar("sv_dedicatedMaxRate")..[[ )
					]];
					--nCX.SendTextMessage(0, msg, channelId);
				end
			end
		end
	end,

};
