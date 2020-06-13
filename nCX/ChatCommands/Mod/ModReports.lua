--===================================================================================
-- REPORTS

CryMP.ChatCommands:Add("reports", {
		Access = 2, 
		Args = {
			{"index", Optional = true, Number = true, Info = "Choose Report index",},
			{"action", Access = 3, Optional = true, Output = {{"delete", "delete the entry"},},},
		},
		Info = "view reported players",
		self = "Reports",
	}, 
	function(self, player, channelId, index, action)
		local profileId = player.Info.ID;
		if (self:GetUnreadCount(profileId) == 0 and nCX.Count(self.Reports) == 0) then
			return false, "no data available"
		end
		local function view()
			local header = "$9======================================================================================================================";
			CryMP.Msg.Console:ToPlayer(channelId, header);
			CryMP.Msg.Console:ToPlayer(channelId, "$9 Id   Name                       Profile   Reason                                   PlayTime        Date");
			CryMP.Msg.Console:ToPlayer(channelId, header);
			local info = self:GetUnreadMessages(profileId) or self.Reports;
			local i = 1;
			for index, report in pairs(info) do
				local reason = string.sub(report[4], 1, 34);
				local data = CryMP.PermaScore and CryMP.PermaScore.Players[index];
				local playh, playm = CryMP.Math:ConvertTime((data and data.PlayTime) or 0, 60);
				local playTime = "$1"..math:zero(playh).."$9h:$1"..math:zero(playm).."$9m";
				local name = report[1];
				if (report[5] == "Controller") then
					name = "$4"..name;
				end
				CryMP.Msg.Console:ToPlayer(channelId, "$9($1%s$9) $5%s$9 %s %s (%s)   $1%s",
					string:lspace(3, i),
					string:rspace(26, name),
					string:rspace(9, index),
					string:rspace(40, reason),
					string:mspace(11, playTime),
					string:rspace(15, CryMP.Math:DaysAgo(report[6], true, true))
				);
				i = i+1;
			end
			CryMP.Msg.Console:ToPlayer(channelId, header);
			return true;
		end
		
		if (index) then
			local data;
			local i = 1;
			for ID, report in pairs(self.Reports) do
				if (i == index) then
					data = ID;
				end
				i = i+1;
			end
			if (data) then
				if (action == "delete") then
					self:UpdateFile(data);
					--view();
					CryMP.Msg.Chat:ToPlayer(channelId, "Report #"..math:zero(index).." successfully removed!");
					return true;
				else
					local info = {
						"$9[   Suspect Name | $5%s$9 ]",
						"$9[  Reporter Name | $5%s$9 ]",
						"$9[     Suspect ID | %s ]",
						"$9[         Reason | %s ]",
						"$9[  Suspect Setup | %s ]",
						"$9[           Date | $5%s$9 ]"
					};
					CryMP.Msg.Console:ToPlayer(channelId, "$9====[ #$1"..index.." $9]===========================================================================================================");
					for n, v in pairs(self.Reports[data]) do
						if (n~=7) then
							if (n == 6) then
								v = CryMP.Math:DaysAgo(v, true, true);
							elseif (n == 5 and v == "Controller") then
								v = "$4"..v.."$9";
							end
							CryMP.Msg.Console:ToPlayer(channelId, info[n]:format(string:rspace(26, v)));
						end
					end
					CryMP.Msg.Console:ToPlayer(channelId, "$9======================================================================================================================");
					return true;
				end
			end
			return false, "entry not found"
		end
		view();
		return true;
	end
);
