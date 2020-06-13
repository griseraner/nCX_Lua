Reports = {

	---------------------------
	--		Config
	---------------------------
	Tag 			 = 2,

	Server = {
	
		OnConnect = function(self, channelId, player, profileId, reset)
			if (not reset) then
				local count = nCX.Count(self.Reports);
				if (count ~= 0) then
					if (self.Reports[profileId]) then
						CryMP.Msg.Chat:ToAccess(2, "Reported player ("..player:GetName()..") has connected. More info in console!", self.Tag);
						self:Lookup(player, profileId);
					end
				end
			end
		end,
	},
	
	OnInit = function(self, reload)
		self.Reports = {};
		--System.LogAlways("Reports:OnInnit");
		require("Data_Reports", "data file");
		local count = nCX.Count(self.Reports);
		if (count > 0) then
			if (not reload) then
				nCX.Log("Core", "Loaded "..math:zero(count).." player reports from file.");
			end
			for ID, report in pairs(self.Reports) do
				for index, value in ipairs(report[7]) do
				--System.LogAlways(tostring(index).." "..tostring(value));
					self.Reports[ID][7][index] = nil;
					self.Reports[ID][7][value] = value;
				end
			end
		end
	end,
	
	Lookup = function(self, player, profileId)
		local report = self.Reports[profileId];
		local tbl, space = CryMP.Ent:Lookup(player);
		local m = {};
		m[#m+1]={"$9[  Reporter Name | %s $9]", report[2]};
		m[#m+1]={"$9[         Reason | %s $9]", report[4]};
		m[#m+1]={"$9[  Suspect Setup | %s $9]", report[5]};
		local header = "$9================================================================================================================";
		for i, msg in pairs(m) do
			if (msg[2] and msg[2] ~= "") then
				tbl[#tbl + 1] = msg[1]:format(string:rspace(space, msg[2]));
			end
		end
		tbl[#tbl + 1] = header;
		for i, msg in pairs(tbl) do
			CryMP.Msg.Console:ToAccess(2, msg);
		end
	end,

	Add = function(self, name, profileId, rname, rprofile, reason, setup, timestamp, ids)
		if (not self.Reports[profileId]) then
			self.Reports[profileId] = {name, rname, rprofile, reason, setup, timestamp, ids or {},};
		end
	end,

	GetUnreadCount = function(self, profileId)
		local c = 0;
		for i, report in pairs(self.Reports) do
			if (not report[7][profileId]) then
				c = c + 1;
			end
		end
		return c, nCX.Count(self.Reports);
	end,
	
	GetUnreadMessages = function(self, profileId)
		local msgs = {};
		for i, report in pairs(self.Reports) do
			if (not report[7][profileId]) then
				report[7][profileId] = profileId;
				--msgs[#msgs + 1] = report;
				msgs[i] = report;
			end
		end
		if (#msgs > 0) then
			self:UpdateFile();
			return msgs;
		end
	end,

	UpdateFile = function(self, profileId)
		if (profileId) then
			self.Reports[profileId] = nil;
			self:UpdateFile();
			return true;
		else
			local FileHnd, Err = io.open(CryMP.Paths.GlobalData.."Data_Reports.lua", "w+");
			for profileId, report in pairs(self.Reports) do
				local profileIds = "";
				if (nCX.Count(report[7]) > 0) then
					local tbl={};
					for ID, v in pairs(report[7]) do
						tbl[#tbl + 1] = '"'..ID..'"';
					end
					profileIds = table.concat(tbl,",");
					System.LogAlways("UpdateFile: $4"..profileIds);
				end
				local line = "CryMP.Reports:Add('"..report[1].."', '"..profileId.."', '"..report[2].."', '"..report[3].."', '"..report[4].."', '"..report[5].."', '"..report[6].."', {'"..profileIds.."'});\n";
				FileHnd:write(line);
			end
			CryMP.Synch:OnChange("Data_Reports", FileHnd:seek("end"));
			FileHnd:close();
		end
	end,

	Write = function(self, line)
		local FileHnd, Err = io.open(CryMP.Paths.GlobalData.."Data_Reports.lua", "a+");
		if (FileHnd) then
			FileHnd:write(line);
			CryMP.Synch:OnChange("Data_Reports", FileHnd:seek("end"));
			FileHnd:close();
		end
	end,

	OnReport = function(self, player, reason, reporter)
		local reason = reason:gsub("'", "");
		if (player:GetAccess() > 1) then
			return false, "cannot report server staff";
		end
		if (#reason < 3) then
			return false, "invalid reason", true;
		end
		if (self.Reports[player.Info.ID]) then
			self:Lookup(player, player.Info.ID);
			CryMP.Msg.Chat:ToAccess(2, "Report received from "..reporter:GetName().." ("..reason..", "..player:GetName()..")!", self.Tag);
			return false, "player already reported";
		end
		local date = tostring(os.date("%Y"))..tostring(os.date("%m"))..tostring(os.date("%d"));
		local setup = player.Info.Controller and "$4Controller$9" or "Keyboard";
		local report = {player:GetName(),reporter:GetName(), reporter.Info.ID, reason, setup, date, {},};
		self.Reports[player.Info.ID] = report;	
		self:Lookup(player, player.Info.ID);
		local profileIds = "";
		local admins = CryMP.Users:GetUsers(2, false, true);
		if (admins) then
			local ids = report[7];
			for channelId, profileId in pairs(admins) do -- admins already connected shouldnt get unread notifications
				ids[profileId] = profileId;
			end		
			local tbl={};
			for ID, value in pairs(report[7]) do
				tbl[#tbl + 1] = '"'..ID..'"';
			end
			profileIds = table.concat(tbl,",");
			--System.LogAlways("OnReport: $4"..profileIds);
		end
		self:Write("CryMP.Reports:Add('"..report[1].."', '"..player.Info.ID.."', '"..report[2].."', '"..report[3].."', '"..reason.."', '"..setup.."', '"..date.."', {'"..profileIds.."'});\n");
		CryMP.Msg.Chat:ToAccess(2, "Player report received from "..report[2].."!", self.Tag);
		CryMP.Msg.Chat:ToPlayer(reporter.Info.Channel, "Thanks for the report! We'll look into it as soon as possible.", 0);
		return true;
	end,

};