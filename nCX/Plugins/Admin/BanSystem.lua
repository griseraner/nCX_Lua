BanSystem = {

	---------------------------
	--		Config
	---------------------------
	Required	 	= true,
	Quits 			= {},

	Server = {
	
		OnDisconnect = function(self, channelId, player, profileId, access, cause, msg)
			local name, ip, domain = player:GetName(), player.Info.IP, player.Info.Host;
			local time = os.date("%H:%M:%S", time);
			local country = player.Info.Country.." ("..(player.Info.Country_Short or "n/a")..")";
			local gameTime = player:GetPlayTime(true);
			local detects = CryMP.ServerDefence:GetDetectionCount(player.Info.IP);
			self.Quits[#self.Quits+1] = {Name = name, ProfileId = profileId, IP = ip, Domain = domain, Cause = cause, Msg = msg, Time = time, Country = country, GameTime = gameTime, ServerTime = _time, Detections = detects,};
			while (#self.Quits > 40) do
				table.remove(self.Quits, 1);
			end
			--[[
			local filesMismatch = cause == 16;
			local cause, banned = CryMP.Ent:GetDisconnectReason(cause);
			if (not banned or filesMismatch) then
				local cause = cause:lower();
				if (filesMismatch) then
					CryMP.Msg.Chat:ToAll(name.." kicked from Server : Files mismatch (probable cheat)", 8);
					System.LogAlways(name.." kicked from Server : Files mismatch (probable cheat)");
				elseif (cause ~= "user disconnected") then
					CryMP.Msg.Chat:ToAccess(3, name.." disconnected ("..cause..")", 2);
				end
			end]]
		end,
		
	},
	
	OnInit = function(self, reload)
		nCX.ReloadBanSystem();
	end,
	
	OnShutdown = function(self, restart)
		return {"Quits"};
	end,
	
	GetLastBan = function(self, full, console)
		local list = nCX.BanList();
		local ban = list[#list];
		if (full and ban) then
			local m, d, y, h, mi, s = ban.Date:match("(%d%d)/(%d%d)/(%d%d) | (%d%d):(%d%d):(%d%d)");
			local time = console and "$4"..h.."$9:$4"..mi.."$9:$4"..s or h..":"..mi..":"..s;
			local date = CryMP.Math:DaysAgo("20"..y..m..d, true, console);
			return console and ("$4%s$9 for $4%s $9($4%s $9at $4%s$9)"):format(ban.Name, ban.Reason, date, time) or ("%s for %s (%s at %s)"):format(ban.Name, ban.Reason, date, time);
		end
		return ban;
	end,

	Kick = function(self, player, reason, kickedBy)
		local reason = reason and #reason > 2 and reason or "ADMIN DECISION";
		local bannedBy = bannedBy or "nCX";
		local color = bannedBy == "nCX" and "$4" or "";
		local name = player:GetName();
		if (nCX.BanPlayer(player.Info.Channel, -1, reason, kickedBy)) then
			player.IS_BANNED = true;
			nCX.SendTextMessage(2, "[ BAN:SYSTEM ] Player "..name.." was kicked from Server ("..reason..")", 0);
			self:Log("Player "..name.." was kicked by "..(color or "")..kickedBy.." $9("..reason..")");
			return true;
		end
		return false, "cannot kick admins"
	end,

	TempBan = function(self, player, reason, timeout, bannedBy)
		local timeout = tonumber(timeout);
		if (not timeout) then
			return self:Kick(player, reason, bannedBy);
		end
		local reason = reason and #reason > 2 and reason or "ADMIN DECISION";
		local bannedBy = bannedBy or "nCX";
		local color = bannedBy == "nCX" and "$4" or "";
		local name = player:GetName();
		if (nCX.BanPlayer(player.Info.Channel, timeout, reason, bannedBy)) then
			player.IS_BANNED = true;
			nCX.SendTextMessage(2, "[ BAN:SYSTEM ] "..name.." was banned from Server ("..reason..", "..timeout.." min)", 0);
			self:Log("Player "..name.." was banned by "..(color or "")..bannedBy.." $9("..reason..", $4"..timeout.." $9min)");
			return true;
		end
		return false, "cannot ban admins"
	end,

	PermaBan = function(self, player, reason, bannedBy, load)
		local reason = reason and #reason > 2 and reason or "ADMIN DECISION";
		local bannedBy = bannedBy or "nCX";
		local color = bannedBy == "nCX" and "$4" or "";
		local name = player:GetName();
		--this means that we should have good backup in case we ban trusted players :p
		--[[local profileId = player.Info.ID;
		if (player:GetAccess() > 0) then
			CryMP.Users:UpdateUser(profileId, 0);
		end
		if (CryMP.PermaScore) then
			CryMP.PermaScore.Players[profileId] = nil;
			CryMP.PermaScore:OnShutdown();
		end
		if (CryMP.Attach and CryMP.Attach.Data[profileId]) then
			CryMP.Attach:Reset(profileId);
			CryMP.Attach:Write();
		end
		if (CryMP.Equip) then
			CryMP.Equip:Reset(profileId);
			CryMP.Equip:Write();
		end]]
		if (load) then
			local date = os.date("%x").." | "..os.date("%X");
			nCX.LoadBan(name, player.Info.ID, player.Info.IP, player.Info.Host, date, reason, bannedBy, 0);
		else
			if (nCX.BanPlayer(player.Info.Channel, 0, reason, bannedBy)) then
				player.IS_BANNED = true;
				self:Log("Player "..name.." was banned by "..(color or "")..bannedBy.." $9("..reason..", $4infinite$9)");
				nCX.SendTextMessage(2, "[ BAN:SYSTEM ] "..name.." was perma-banned from Server ("..reason..")", 0);
				return true;
			end
			return false, "cannot ban admins";
		end
		return true;
	end,

	LoadBan = function(self, index, reason, bannedBy, time)
		local data = self.Quits[index];
		if (data) then
			local reason = reason and #reason > 2 and reason or "ADMIN DECISION";
			local bannedBy = bannedBy or "nCX";
			local color = bannedBy == "nCX" and "$4" or "";
			local date = os.date("%x").." | "..os.date("%X");
			nCX.LoadBan(data.Name, data.ProfileId, data.IP, data.Domain, date, reason, bannedBy, time);
			self:Log("Loaded ban on "..data.Name.." ("..data.ProfileId..", "..data.Domain..") by "..(color or "")..bannedBy, true);
			return true;
		else
			return false, "entry not found";
		end
	end,

	Unban = function(self, index, admin)
		local list = nCX.BanList();
		local data = list[index];
		if (data) then
			local admin = admin or "nCX";
			local color = admin == "nCX" and "$4" or "";
			local unbanned = nCX.Unban(index, admin);
			if (unbanned) then
				self:Log("Unbanned "..data.Name.." ("..data.ID..", "..data.Host..") by "..(color or "")..admin, true);
				CryMP.Msg.Chat:ToAccess(2, "Unbanned "..data.Name.." ("..data.ID..", "..data.Host..") by "..admin, 2);
				return true;
			end
			return false;
		else
			return false, "ban not found";
		end
	end,

};
