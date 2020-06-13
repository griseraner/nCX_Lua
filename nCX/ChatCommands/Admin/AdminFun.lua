--===================================================================================
-- MATRIX

CryMP.ChatCommands:Add("matrix", {
		Access = 4, 
		Args = {
			{"duration", Optional = true, Number = true, Info = "The duration in seconds",},
		}, 
		Info = "slow down time for a few seconds", 
		Delay = 120
	}, 
	function(self, player, channelId, duration)
		local duration = math.max(5, math.min(math.floor(duration or 5), 60));
		if (System.GetCVar("time_scale") == 1) then
			CryMP.Msg.Chat:ToPlayer(channelId, "TIME:FLUX :: STARTING :: CHARGING REACTOR!");
			local t = 5;
			for i = 0, t do
				CryMP:SetTimer(i, function()
					if (t==0) then
						nCX.SendTextMessage(5, string.format("<font size=\"32\"><b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#C00000\">WARP [<font color=\"#FFFFFF\"> ENGAGED </font><font color=\"#C00000\">] WARP</font> <font color=\"#b9b9b9\">!! ***</font></b></font>"), 0);
						System.SetCVar ("time_scale", .25);
						CryMP:SetTimer((duration)/2, function()
							if (System.GetCVar("time_scale") ~= 1) then
								nCX.SendTextMessage(5, string.format("<font size=\"32\"><b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#C00000\">WARP [<font color=\"#ec2020\"> OVER </font><font color=\"#C00000\">] WARP</font> <font color=\"#b9b9b9\">!! ***</font></b></font>"), 0);
								System.SetCVar("time_scale", 1);
							end
						end);
					else
						CryMP.Msg.Flash:ToAll({12, "#d77676", "#ec2020",}, "00:0"..t, "<font size=\"32\"><b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#C00000\">WARP [<font color=\"#d77676\"> %s </font><font color=\"#C00000\">] WARP</font> <font color=\"#b9b9b9\">!! ***</font></b></font>");
					end
					t = t - 1;
				end);
			end
		else
			CryMP.Msg.Chat:ToAll("TIME:FLUX :::: DISABLED!");
			System.SetCVar ("time_scale", 1);
		end
		return true;
	end
);

--===================================================================================
-- HAPPYHOUR

CryMP.ChatCommands:Add("happyhour", {
		Access = 4,
		Info = "make everything free", 
		Delay = 1200,
		self = "EventSystem",
		Map = {"ps/(.*)"},
	}, 
	function(self, player, channelId)
		return self:HappyHour();
	end
);

--===================================================================================
-- SETTOD

CryMP.ChatCommands:Add("tod", {
		Access = 3, 
		Info = "set time of day",
		Args = {
			{"time", Number = true, Info = "The time you want to set (0 - 23)",},
		},
	}, 
	function(self, player, channelId, time)
		local time = math.floor(time);
		if (time < 0 or time > 23) then
			return false, "time not valid", "Choose Time [ 0 - 23 ]";
		end
		nCX.SetTOD(time);
		nCX.SendTextMessage(2, "New map time: "..time..":00 "..((time < 12) and "am" or "pm").." (Admin Decision)", 0);
		return true;
	end
);
