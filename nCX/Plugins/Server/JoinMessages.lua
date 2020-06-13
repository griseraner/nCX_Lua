JoinMessages = {

	Server = {
	
	--[[
		OnConnect = function(self, channelId, player, profileId, restart) 
			if (not restart) then
				local msgs = self:GetPDA(player);
				local counter = #msgs;
				--CryMP:SetTimer(2, function() 
					for i, msg in pairs(msgs) do
						--local m = msgs[counter];
						CryMP.Msg.Console:ToPlayer(channelId,msg);
						--counter = counter - 1;
					end
				--end);
			end
		end,]]
--[[
		OnRevive = function(self, channelId, player, vehicle, first)
			if (first) then
				local profileId = player.Info.ID;
				CryMP:SetTimer(3, function() 
					if (not nCX.ProMode) then
						local name = player.GetName and player:GetName();
						if (name) then
							CryMP.Msg.Animation7ox:ToPlayer(channelId, "Welcome "..(CryMP.Users:GetMask(profileId) or "Player").." "..name);
						end
					end
					if (not CryMP.Equip) then
						CryMP:SetTimer(5, function() 
							CryMP.Msg.Chat:ToPlayer(channelId, "Server Mod Version: "..CryMP.Version.String, 1);
						end);
					end
				end);
			end
		end,]]
	
	},
	
	GetPDA = function(self, player)
		local sspace, lspace, rspace, boxspace = 6, 13, 15, 54;
		local channelId, profileId = player.Info.Channel, player.Info.ID;
		local admin = CryMP.Users:HasAccess(profileId, 2);
		local name = player:GetName();
		local host = player.Info.Host;
		local ip = player.Info.IP;
		local country = player.Info.Country or "N/A";
		local mask = CryMP.Users:GetMask(profileId);
		local vers = CryMP.Version.String;
		local class = g_gameRules.class;
		local tbl = {["PowerStruggle"]="PS",["TeamInstantAction"]="TIA",};
		local sclass = tbl[class] or "IA";
		local map = nCX.GetCurrentLevel():sub(16, -1);
		local maxp = System.GetCVar("sv_maxplayers");
		local count = nCX.GetPlayerCount();
		local mem = nCX.GetMemoryUsage();
		local chan = nCX.GetHighestChannel();
		local aping = nCX.GetAveragePing();
		local ping = nCX.GetPing(channelId);
		local limit = System.GetCVar("nCX_HighPingLimit");
		ping = ping >= limit and "$4"..ping or "$5"..ping;
		local current, min, max = nCX.GetServerPerformance();
		local rank = (CryMP.PermaScore and CryMP.PermaScore:GetRank(profileId));
		rank = rank and "#$9"..rank or "n/a";
		local days, hours, mins, secs = CryMP.Math:GetServerUptime();
		local uptime = days > 0 and "$5"..days.."$9d:$5"..hours.."$9h:$5"..mins.."$9m" or "$5"..hours.."$9h:$5"..mins.."$9m";
		local min, sec = player:GetPlayTime();
		local hour, min = CryMP.Math:ConvertTime(min, 60);
		local totalTime = math:zero(hour).."$9h:$5"..math:zero(min).."$9m";
		local info2, air;
		local restored = ((nCX.GetSynchedEntityValue(player.id, 100) or 0) ~= 0) and "Yes" or "No";
		local bans = #(nCX.BanList() or {});
		if (g_gameRules.class == "PowerStruggle") then
			if (CryMP.HQMods) then
				local us, nk = CryMP.HQMods:GetInfo();
				info2 = "$9HQ US: $5"..us.."% $9HQ NK: $5"..nk.."%";
			end
			if (CryMP.LockDowns) then
				local vtol, heli = CryMP.LockDowns:GetAirMode();		
				local modes = {[1] = "$9Off", [2] = "$5Light", [3] = "$5Heavy"};
				air = "VTOL / Heli  :$5"..string:mspace(sspace+7, modes[vtol].."$9/"..modes[heli])
			end
			--restored = (CryMP.Refresh and CryMP.Refresh.Players and CryMP.Refresh.Players[profileId]) and "Yes" or "No";
			--restored = "Restored : $5"..string:rspace(lspace, restored);
		end
		if (not air and admin) then
			air = "Ban Count    :$5"..string:lspace(sspace, bans).."       ";
		end
		if (not info2) then
			--if (admin) then
				info2 = "$9Map "..map.." ($5"..sclass.."$9)";
			--else
			--	info2 = "$9Visit our homepage www.7oxicity.tk ";
			--end
		end
		local msgs = {
			"$9", 
			"$9   $7                       ################  ###  ## ###  ###### ### ############  ######                     $9   ",
			"$9   $7                            ###  ##   ## ###  ## ### ###     ###    ###   ###  ###                        $9   ",
			"$9   $7                             ##  ##   ##  #####  ### ###     ###    ###   #######                         $9   ",
			"$9   $7                             ##  ##   ## ###  ## ### ###     ###    ###     ###                           $9   ",
			"$9   $7                             ##   #####  ###  ## ###  ###### ###    ###     ###                           $9   ",
			"$9   $7                             ##                                             ###   $9Since $52009                        $9   ",			
			"$9"..("_"):rep(122),
			"$9",  							
			string:mspace(112, "$9Welcome, $5"..player:GetName().." $9to the 7OXICiTY Server!"),	
			"$9"..("_"):rep(122),
			"$9     [  $9SERVER$5:$9STATUS$9  ]    |                    [ $9USER$5:$9DATA $9]                     |    [  $9SERVER$5:$9STATUS$9  ]    ",
			"$9                            |"..(" "):rep(boxspace)                                                                                                                  .."|", 
		};
		if (admin) then
			local status = CryMP.ErrorHandler:GetStatus();
			local status = status == 0 and "$5OK" or "$4"..status.." $9errors";
			local banMsg = CryMP.BanSystem:GetLastBan(true, true) or "None";
			local reports, tReports;
			if (CryMP.Reports) then
				reports, tReports = CryMP.Reports:GetUnreadCount(profileId);
				reports = (reports > 0 and "$5"..tReports.." $9($5"..reports.." $9unread)") or (tReports > 0 and "$5"..tReports) or "None";
			end	
			local m = string:rspace(6, " ($5"..System.GetCVar("sv_dedicatedMaxRate").."$9)");
			local info = banMsg or "$9Running "..map.." ($5"..class.."$9)";
			msgs[#msgs+1] = "$9 Performance  :$5"..string:lspace(sspace, current).."$9%"..m.."|  User     : $7"..string:rspace(lspace, mask     ).."$9| $9Ping     : $5"..string:rspace(rspace, ping     ).."$9|    $9System   : "..status; 
			msgs[#msgs+1] = "$9 Memory Usage :$5"..string:lspace(sspace, mem    ).."$9       |  Rank     : $5"..string:rspace(lspace, rank     ).."$9| $9IP       : $5"..string:rspace(rspace, ip       ).."$9|    $9Runtime  : $5"..uptime; 
			msgs[#msgs+1] = "$9 Average Ping :$5"..string:lspace(sspace, aping  ).."$9       |  Playtime : $5"..string:rspace(lspace, totalTime).."$9| $9Profile  : $5"..string:rspace(rspace, profileId).."$9|    $9Players  : "..count.."/"..maxp; 
			msgs[#msgs+1] = "$9 Highest Slot :$5"..string:lspace(sspace, chan   ).."$9       |  Restored : $5"..string:rspace(lspace,  restored).."$9| $9Country  : $5"..string:rspace(rspace, country  ).."$9|    $9Max Ping : $4"..limit;
			msgs[#msgs+1] = "$9 "..(air or "")                                          .."$9|"..("_"):rep(boxspace)                                                                                 .."|    $9Reports  : "..reports;
			msgs[#msgs+1] = "$9";
			msgs[#msgs+1] = "$9";
			--msgs[#msgs+1] = string:mspace(112, info);
			msgs[#msgs+1] = string:mspace(112, "$9Server CPU: "..nCX.GetCPU().." ("..nCX.GetCPUSpeed().."Mhz)");
			msgs[#msgs+1] = string:mspace(112, info2);
		else
			msgs[#msgs+1] = "$9 Highest Slot :$5"..string:lspace(sspace, chan   ).."$9       |  User     : $7"..string:rspace(lspace, mask     ).."$9| $9Ping     : $5"..string:rspace(rspace, ping     ).."$9|    $9Runtime  : $5"..uptime; 
			msgs[#msgs+1] = "$9 Ban Count    :$5"..string:lspace(sspace, bans   ).."$9       |  Rank     : $5"..string:rspace(lspace, rank     ).."$9| $9IP       : $5"..string:rspace(rspace, ip       ).."$9|    $9Max Ping : $4"..limit; 
			msgs[#msgs+1] = "$9 Average Ping :$5"..string:lspace(sspace, aping  ).."$9       |  Playtime : $5"..string:rspace(lspace, totalTime).."$9| $9Profile  : $5"..string:rspace(rspace, profileId).."$9|    $9Players  : "..count.."/"..maxp; 
			msgs[#msgs+1] = "$9 "..(air or (" "):rep(27))                         .."$9|  Restored : $5"..string:rspace(lspace,  restored).."$9| $9Country  : $5"..string:rspace(rspace, country  ).."$9|    ";
			msgs[#msgs+1] = "$9                            $9|"..("_"):rep(boxspace)                                                                                                            .."|    ";
			msgs[#msgs+1] = "$9";
			msgs[#msgs+1] = "$9";
			--msgs[#msgs+1] = string:mspace(112, "$9Running $7"..vers.." $9by ctaoistrach and $4nCX 2.0 $9by Arcziy"); 
			msgs[#msgs+1] = string:mspace(112, "$9Server CPU: "..nCX.GetCPU().." ("..nCX.GetCPUSpeed().."Mhz)");
			msgs[#msgs+1] = string:mspace(112, info2);
		end
		return msgs;
	end,
	
};
