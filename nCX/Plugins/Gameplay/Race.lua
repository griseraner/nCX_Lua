Race = {

	---------------------------
	--		Config
	---------------------------
	LightOffset		= 0,
	FirstSector		= 2,
	LastSector		= 1,
	CarMessage 		= "<font size=\"32\"><font color=\"#c6c6c6\">***</font> <font color=\"#ec1c1c\"><b>RACE-[ <font color=\"#ce3636\">STOP</font><font color=\"#ec1c1c\"> ]-DRIVER</b></font> <font color=\"#c6c6c6\">***</font></font>",
	NameTag 		= "[RACER]-";
	Seat			= 3,	-- Use -1 to make players spawn in the lobby!
	Award			= {5000, 2500, 500},-- 1st place, 2nd place, 3rd place
	Timer			= 60,
	TimeOut			= 15, 
	Tag				= 6,
	Debug 			= false, 
	
	Checkpoints		= {},
	Vehicles		= {},
	FreeVehicles	= {},
	Racers			= {},
	Declined 		= {},
	Started			= false,
	--[[ todo	
		
	]]
	
	ChatSpam = {
		[50] = "YOUR VEHICLES ARE WAITING AT THE START LINE!",
		[40] = "USE [ F5 + 1 ] TO PARTICIPATE IN THE RACE!",
		[30] = "YOU MUST PASS THE CHECKPOINTS - NO CHEATING!",
		[20] = "FLARES WILL FIRE TO START THE RACE!",
		[5] = "COUNTDOWN STARTED - GET READY!",
		[0] = "GO!",
	},
	
	Tracks = {
		["medium"] = {
			id = 1,
			Lights = {--[i]: Sector
				{--[1] position, [2] LightGroup: 0: blink r/w, 1: blink red, 2: blink white
					{{ 2560.5093,1955.3475,64.605202 },	0}, 
					{{ 2582.4097,1946.1788,64.613663 },	0},
					{{ 2622.8015,2043.2192,50.200687 },	0},
					{{ 2603.0347,2051.3323,49.533199 },	0},
					{{ 2673.6013,2174.3464,49.6311 },	0},
					{{ 2652.9097,2181.562,49.507153 },	0},
					{{ 2678.6809,2351.322,49.626606 },	0},
					{{ 2655.2549,2351.5173,50.229927 },	0},
					{{ 2681.8516,2520.1475,53.386456 },	0},
					{{ 2657.8342,2520.9453,53.671322 },	0},
					{{ 2492.1047,2586.0583,54.859512 },	0},
					{{ 2492.2317,2576.7021,54.925545 },	0},
				},{
					{{ 2290.8521,2588.386,54.900196 },	2},
					{{ 2289.4771,2582.1936,54.895889 },	2},
					{{ 2257.3557,2602.4675,54.886295 },	2},
					{{ 2253.4902,2596.8694,54.942997 },	2},
					{{ 2050.1147,2757.9771,47.315289 },	0},
					{{ 2046.9067,2750.5874,47.448063 },	0},
					{{ 1813.4492,2799.6309,46.200264 },	0},
					{{ 1813.2878,2791.1194,46.317719 },	0},
					{{ 1693.4984,2841.2964,39.797039 },	0},
					{{ 1693.7998,2832.936,39.774929 },	0},
					{{ 1589.418,2832.7954,38.862129 },	2},
					{{ 1598.2634,2832.6606,38.967403 },	2},
					{{ 1597.9713,2808.6309,39.044971 },	2},
					{{ 1588.8823,2809.0039,39.112572 },	2},
					{{ 1588.3815,2786.3423,38.03793 },	2},
					{{ 1597.6979,2786.1514,38.035954 },	2},
				},{
					{{ 1587.8485,2655.9351,37.352516 },	0},
					{{ 1597.9148,2655.5872,37.313637 },	0},
					{{ 1668.334,2572.2439,35.217625 },	2},
					{{ 1661.2427,2567.3542,35.18758 },	2},
					{{ 1681.4955,2547.2375,35.718681 },	2},
					{{ 1673.5492,2545.5249,35.715107 },	2},
				},{
					{{ 1540.2349,2421.3711,58.870022 },	0},
					{{ 1531.0472,2420.7393,60.076759 },	0},
					{{ 1652.079,2331.9819,52.959663 },	0},
					{{ 1657.7581,2335.7708,53.760643 },	0},
					{{ 1671.1455,2111.9382,53.062744 },	0},
					{{ 1670.2958,2102.5544,53.034397 },	0},
					{{ 1887.3501,2181.0112,48.189598 },	0},
					{{ 1894.0198,2174.3071,48.185349 },	0},
				},{
					{{ 2161.4055,2102.9597,48.055687 },	0},
					{{ 2169.8423,2107.3333,47.966873 },	0},
					{{ 2200.1436,1864.7166,59.207344 },	0},
					{{ 2198.2981,1864.5875,59.22459 },	0},
					{{ 2207.7781,1839.8086,54.157146 },	0},
					{{ 2198.4883,1839.4701,53.567017 },	0},
					{{ 2209.353,1820.3684,53.443584 },	0},
					{{ 2200.0886,1818.9626,53.262524 },	0},
					{{ 2205.6826,1798.6781,53.280491 },	0},
					{{ 2214.2871,1802.3153,53.27449 },	0},
					{{ 2222.2861,1784.8328,53.239395 },	0},
					{{ 2214.1985,1780.229,53.243069 },	0},
					{{ 2218.8618,1791.6364,53.271194 },	0},
					{{ 2210.7002,1787.4268,53.217613 },	0},
					{{ 2218.3718,1782.6055,54.183601 },	0},
					{{ 2225.0054,1762.4768,56.465115 },	0},
					{{ 2229.7578,1765.2209,56.49921 },	0},
				},
			},
			StartFlarePos = {--[i]: Position
				{2584, 1980, 51},
				{2576, 1983, 51}, 
				{2593, 1976, 51},
			},
			CarPositions = {--[1]: Rotation, [2]:Position
				{{x=0, y=0,	z=math.rad(330)}, {x=2565, y=1966, z=50}},	
				{{x=0, y=0,	z=math.rad(330)}, {x=2569, y=1964, z=50}},	
				{{x=0, y=0,	z=math.rad(345)}, {x=2584, y=1956, z=50}},	
				{{x=0, y=0,	z=math.rad(345)}, {x=2589, y=1955, z=50}},	
			},
			CheckpointData = {--[1] Dimension, [2] Position, [3]: Rotation,
				{{x = 4, y = 50, z = 10}, {2403.125, 2576, 56}, {0, 0, 0}},
				{{x = 10, y = 5, z = 10}, {1593, 2785, 39}, {0, 0, 0}},
				{{x = 20, y = 4, z = 10}, {1643, 2470, 45}, {0, 0, 5.77704}},
				{{x = 4, y = 16, z = 20}, {1961, 2218, 49}, {0, 0, 0.2617994}},
				{{x = 5, y = 20, z = 10}, {2218, 1785, 53}, {0, 0, 5.2505206}},
			},
		},
		["long"] = {
			id = 2,
			Lights = {
				{
					{{ 1399.625,1852.75,78.0861 },	0},
					{{ 1392.625,1859.75,78.0373 },	1},
					{{ 1387.625,1865.75,77.9339 },	1},
					{{ 1381.625,1872.125,77.8672 },	0},		
					{{ 1418.25,1908.75,74.0094 },	0},
					{{ 1434.625,1894.5,74.031 },	0},
					{{ 1474.375,1943.625,70.5535 },	0},
					{{ 1458.625,1958.25,70.5324 },	0},
					{{ 1514.375,2026.25,65.7143 },	0},
					{{ 1530.125,2012.375,65.71 },	0},
					{{ 1568.125,2043.375,62.6935 },	0},
					{{ 1567.5,2045.625,69.6605 },	1},
					{{ 1566.5,2047.125,69.6605 },	1},
					{{ 1560.25,2055.75,69.6605 },	1},
					{{ 1556.25,2061.375,69.6605 },	1},
					{{ 1555.125,2062.375,62.5566 },	0},
				},{
					{{ 1639.625,2097.5,57.5094 },	0},
					{{ 1627.5,2115.75,57.5779 },	0},
					{{ 1672.75,2102.125,52.8032 },	0},
					{{ 1674.375,2124.125,52.8653 },	0},
					{{ 1763.25,2114,44.5427 },		0},
					{{ 1766.5,2091.75,44.549 },		0},
					{{ 1806.125,2108.25,44.2405 },	0},
					{{ 1800.75,2118.25,44.0105 },	2},
					{{ 1795.125,2127.625,43.9873 },	0},
				},{
					{{ 1840.5,2158.625,44.3927 },	0},
					{{ 1846.25,2150.125,44.3637 },	2},
					{{ 1852.125,2140.875,44.2054 },	0},
					{{ 1878.75,2160,47.4569 },		1},
					{{ 1879.5,2168.25,47.4569 },	1},
					{{ 1878.375,2174,48.1558 },		0},
					{{ 1872.5,2182.5,48.1657 },		0},
					{{ 1934.375,2244.625,48.2078 },	0},
					{{ 1940.75,2237.25,48.2078 },	0},
				   
					{{ 2066.5,2376.875,48.4419 },	0},
					{{ 2073.875,2370.25,48.2078 },	0},
					{{ 2123.625,2422.875,55.4594 },	2},
					{{ 2118.75,2427.625,55.4594 },	2},
				},{
					{{ 2252,2593,54.900196 },		0},
					{{ 2244,2589,54.895889 },		0},
					{{ 2258,2575,54.886295 },		0},
					{{ 2249,2574,54.942997 },		0},
					{{ 2050.1147,2757.9771,47.315289 },	0},
					{{ 2046.9067,2750.5874,47.448063 },	0},
					{{ 1813.4492,2799.6309,46.200264 },	0},
					{{ 1813.2878,2791.1194,46.317719 },	0},
					{{ 1693.4984,2841.2964,39.797039 },	0},
					{{ 1693.7998,2832.936,39.774929 },	0},
					{{ 1589.418,2832.7954,38.862129 },	0},
					{{ 1598.2634,2832.6606,38.967403 },	0},
					{{ 1597.9713,2808.6309,39.044971 },	0},
					{{ 1588.8823,2809.0039,39.112572 },	0},
					{{ 1588.3815,2786.3423,38.03793 },	0},
					{{ 1597.6979,2786.1514,38.035954 },	0},
				},{
					{{ 1587.8485,2655.9351,37.352516 },	0},
					{{ 1597.9148,2655.5872,37.313637 },	0},
					{{ 1668.334,2572.2439,35.217625 },	0},
					{{ 1661.2427,2567.3542,35.18758 },	0},
					{{ 1681.4955,2547.2375,35.718681 },	0},
					{{ 1673.5492,2545.5249,35.715107 },	0},
				},{
					{{ 1540.2349,2421.3711,58.870022 },	0},
					{{ 1531.0472,2420.7393,60.076759 },	0},
					{{ 1652.079,2331.9819,52.959663 },	0},
					{{ 1657.7581,2335.7708,53.760643 },	0},
						
					{{ 1671.1455,2111.9382,53.062744 },	0},
					{{ 1670.2958,2102.5544,53.034397 },	0},
					{{ 1887.3501,2181.0112,48.189598 },	0},
					{{ 1894.0198,2174.3071,48.185349 },	0},
				},{
					{{ 2161.4055,2102.9597,48.055687 },	0},
					{{ 2169.8423,2107.3333,47.966873 },	0},
					{{ 2200.1436,1864.7166,59.207344 },	0},
					{{ 2198.2981,1864.5875,59.22459 },	0},
					{{ 2207.7781,1839.8086,54.157146 },	0},
					{{ 2198.4883,1839.4701,53.567017 },	0},
					{{ 2209.353,1820.3684,53.443584 },	0},
					{{ 2200.0886,1818.9626,53.262524 },	0},
					{{ 2205.6826,1798.6781,53.280491 },	0},
					{{ 2214.2871,1802.3153,53.27449 },	0},
					{{ 2222.2861,1784.8328,53.239395 },	0},
					{{ 2214.1985,1780.229,53.243069 },	0},
					{{ 2218.8618,1791.6364,53.271194 },	0},
					{{ 2210.7002,1787.4268,53.217613 },	0},
					{{ 2218.3718,1782.6055,54.183601 },	0},
					{{ 2225.0054,1762.4768,56.465115 },	0},
					{{ 2229.7578,1765.2209,56.49921 },	0},
				},
			},
			StartFlarePos = {
				{1418.875,	1876.875,	78.0373},
				{1411, 		1883.5,		78.0373}, 
				{1403.375, 	1890.5, 	78.0373},
			},
			CarPositions = {
				{{x=0, 	y=0, 	z=5.5}, 	{x=1387, 	y=1843, 	z=78.625 },},	
				{{x=0, 	y=0, 	z=5.5}, 	{x=1383, 	y=1846,	 	z=78.625 },},	
				{{x=0, 	y=0, 	z=5.375}, 	{x=1371, 	y=1862, 	z=78.625 },},	
				{{x=0, 	y=0, 	z=5.375}, 	{x=1374, 	y=1858, 	z=78.625 },},		
			},
			CheckpointData = {
				{{x = 25, y = 5, z = 5}, {1562.5, 2054.125, 63.125}, {0, 0, 5.41}},
				{{x = 40, y = 6, z = 12}, {1802.125, 2119.875, 42}, {0, 0, 5.41}},
				{{x = 15, y = 6, z = 5}, {2121.767, 2425.22, 48.2078}, {0, 0, 5.41}},
				{{x = 10, y = 5, z = 10}, {1593, 2785, 39}, {0, 0, 0}},
				{{x = 20, y = 6, z = 10}, {1643, 2470, 45}, {0, 0, 5.77704}},
				{{x = 6, y = 16, z = 20}, {1961, 2218, 49}, {0, 0, 0.2617994}},
				{{x = 5, y = 20, z = 10}, {2218, 1785, 53}, {0, 0, 5.2505206}},
			},
		},
		["sprint"] = {
			id = 3,
			Lights = {
				{
					{{ 1399.625,1852.75,78.0861 },	0},
					{{ 1392.625,1859.75,78.0373 },	1},
					{{ 1387.625,1865.75,77.9339 },	1},
					{{ 1381.625,1872.125,77.8672 },	0},
					{{ 1418.25,1908.75,74.0094 },	0},
					{{ 1434.625,1894.5,74.031 },	0},
					{{ 1474.375,1943.625,70.5535 },	0},
					{{ 1458.625,1958.25,70.5324 },	0},
					{{ 1514.375,2026.25,65.7143 },	0},
					{{ 1530.125,2012.375,65.71 },	0},
					{{ 1568.125,2043.375,62.6935 },	0},
					{{ 1567.5,2045.625,69.6605 },	1},
					{{ 1566.5,2047.125,69.6605 },	1},
					{{ 1560.25,2055.75,69.6605 },	1},
					{{ 1556.25,2061.375,69.6605 },	1},
					{{ 1555.125,2062.375,62.5566 },	0},
				},{
					{{ 1639.625,2097.5,57.5094 },	0},
					{{ 1627.5,2115.75,57.5779 },	0},
					{{ 1672.75,2102.125,52.8032 },	0},
					{{ 1674.375,2124.125,52.8653 },	0},
					{{ 1763.25,2114,44.5427 },		0},
					{{ 1766.5,2091.75,44.549 },		0},
					{{ 1806.125,2108.25,44.2405 },	0},
					{{ 1800.75,2118.25,44.0105 },	2},
					{{ 1795.125,2127.625,43.9873 },	0},
				}
			},
			StartFlarePos = {
				{1418.875, 1876.875, 78.0373},
				{1411, 1883.5, 78.0373}, 
				{1403.375, 1890.5, 78.0373},
			},
			CarPositions = {
				{{x=0, y=0,	z=5.5}, {x=1387, y=1843, z=78.625 },},
				{{x=0, y=0,	z=5.5}, {x=1383, y=1846, z=78.625 },},
				{{x=0, y=0,	z=5.375}, {x=1371, y=1862, z=78.625 },},
				{{x=0, y=0,	z=5.375}, {x=1374, y=1858, z=78.625 },},
			},
			CheckpointData = {
				{{x = 25, y = 5, z = 5,}, {1562.5, 2054.125, 63.125}, {0,0,5.41}},
				{{x = 40, y = 6, z = 12,}, {1802.125, 2119.875, 42}, {0,0,5.41}},
			},
		},
	},
	
	Server = {
					
		OnDisconnect = function(self, channelId)
			local racer = self:GetRacer(channelId)
			if (racer) then
				self:OnDisqualify(channelId, 1, racer.VehicleId);
			end
		end,

		OnEnterArea = function(self, zone, vehicle)
			if (zone.CheckpointNr and vehicle.vehicle) then
				local channelId = self.Vehicles[vehicle.id];
				if (channelId) then
					local racer = self.Racers[channelId];
					if (racer and racer.Checkpoint) then
						local passed = (racer.Checkpoint>=zone.CheckpointNr);
						if (not passed) then
							local isShortCutting = (zone.CheckpointNr-racer.Checkpoint)>1;
							local isFinish = (zone.CheckpointNr == #self.Checkpoints);
							System.LogAlways(zone.CheckpointNr.." =====["..vehicle:GetName().."]========== "..#self.Checkpoints);
							if (isShortCutting) then
								self:OnDisqualify(channelId, 5, vehicle.id);
								return;
							end
							if (zone.CheckpointNr==self.FirstSector-1 and (zone.CheckpointNr+1)<=#self.Checkpoints) then
								self.FirstSector=zone.CheckpointNr+2;
							end
							local lapTime = self:GetTimePassed(self.StartTime);
							racer.Checkpoint = zone.CheckpointNr;
							local place = 1;
							for chan, racer2 in pairs(self.Racers) do
								if (chan ~= channelId and racer2.Checkpoint >= zone.CheckpointNr) then
									place = place + 1;
								end
							end
							racer.Position = place;
							local position = place == 1 and "1st" or place == 2 and "2nd" or place == 3 and "3rd" or "4th";
							local player = nCX.GetPlayerByChannelId(channelId);
							if (isFinish and not self.WinTime) then
								self.WinTime = _time;
								if (not self.IsAlone) then
									g_gameRules:AwardPPCount(player.id, self.Award[place]);
								end
								nCX.ParticleManager("misc.extremly_important_fx.celebrate", 2, player:GetWorldPos(), g_Vectors.up, 0);
								local teamName = CryMP.Ent:GetTeamName(nCX.GetTeam(player.id)):upper();
								CryMP.Msg.Chat:ToAll(racer.Name.." WINS for the "..teamName.." team! :: TIME-[ "..lapTime.." ]"..(not self.IsAlone and  ":: PRIZE "..self.Award[place].." POINTS!" or ""), self.Tag);
								self:Log(racer.Name.." wins for the "..teamName.." team!");
								CryMP.Ent:PlaySound(player.id, "win");
								racer.isFinish = true;
								--CryMP.Msg.Flash:ToAll({50, "#e7e7e7", "#9f9f9f", true},"~ "..racer.Name.." WON THE RACE ~", "<font size=\"32\"><b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#006600\">RACE ( %s <font color=\"#006600\">) TRACK</font> <font color=\"#b9b9b9\">!! ***</font></b></font>");
							elseif (isFinish and place ~= 4) then
								g_gameRules:AwardPPCount(player.id, self.Award[place]);
								CryMP.Msg.Chat:ToAll(racer.Name.." made the "..position.." place :: TIME-[ "..lapTime.." ]", self.Tag);
								racer.isFinish = true;
							else
								--local chatmsg = place == 1 and " [FIRST PLACE]" or " at position "..tostring(place);
								local scrollmsg = place == 1 and "CHECKPOINT "..tostring(zone.CheckpointNr).." - FIRST PLACE " or "CHECKPOINT "..tostring(zone.CheckpointNr).." - #"..tostring(place);
								--CryMP.Msg.Scroll:ToPlayer(channelId, {"#000000", true, 1}, scrollmsg, "<b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#006600\">RACE (  <font color=\"#e7e7e7\">%s</font> ) TRACK</font> <font color=\"#b9b9b9\">!! ***</font></b>");
								--CryMP.Msg.Chat:ToAll(racer.Name.." passed checkpoint "..tostring(zone.CheckpointNr)..chatmsg..", time: "..time.." sec", self.Tag);
								--CryMP.Msg.Scroll:ToPlayer(channelId, {"#000000", false, 0}, "<font size=\"32\"><b><font color=\"#a09e85\">..oO</font><font color=\"#d5ca53\">  CHECKPOINT  </font><font color=\"#a09e85\">Oo..</font></b></font>");
								CryMP.Msg.Chat:ToAll(">> CHECKPOINT << [ TIME : "..lapTime.." ] :: "..racer.Name.." is in "..position.." place!", self.Tag);
								if (place == 1) then
									nCX.ParticleManager("explosions.flare.night_time_selfillum", 1, zone:GetWorldPos(), g_Vectors.up, 0);
									CryMP.Ent:PlaySound(player.id, "confirm");
								else
									CryMP.Ent:PlaySound(player.id, "error");
								end
							end
							--## VEHICLE:REPAIR - CHECKPOINT
							
							vehicle.vehicle:OnHit(vehicle.id, player.id, 500, vehicle:GetPos(), 0, "repair", false); 
							
							--## VEHICLE:REPAIR - CHECKPOINT
							for cpindex, cpid in pairs(self.Checkpoints) do
								local zone = System.GetEntity(cpid);
								if (zone) then
									local passedplayers=0;
									for index, racer in pairs(self.Racers) do
										if (racer.Checkpoint >= zone.CheckpointNr) then
											passedplayers=passedplayers+1;
										end
									end
									if (passedplayers==self:Count()) then
										if (zone.CheckpointNr == self.LastSector) then
											self.LastSector=self.LastSector+1;
										end
										System.RemoveEntity(zone.id);
										--self.Checkpoints[cpindex] = nil;
									end
								end
							end
						end
					end
				end
			end
		end,
			
		CanEnterVehicle = function(self, vehicle, player)
			if (self.Vehicles[vehicle.id] or self.FreeVehicles[vehicle.id]) then
				local channelId = player.Info.Channel;
				local racer = self:GetRacer(channelId);
				if (not racer) then
					if (self:Count()==4) then
						nCX.SendTextMessage(0, "*** !! YOU'RE NOT A RACER !!***", channelId);
					elseif (self.Timer) then
						nCX.SendTextMessage(0, "'** !! USE [ F5 + 1 ] TO RACE !!***", channelId);
					end
					return true, {false};
				--else
				--	nCX.SendTextMessage(5, "<font size=\"32\"><b><font color=\"#b9b9b9\">*** !! </font><font color=\"#C00000\">Please wait until the race starts! </font><font color=\"#b9b9b9\">!!***</font></b></font>", channelId);
				--	return true, {false};
				end
			end
		end,
		
		OnLeaveVehicleSeat = function(self, vehicle, seat, player, exiting, server)
			local channelId = self.Vehicles[vehicle.id];
			if (channelId) then
				if (exiting) then
					if (server and server ~= -1) then
						self:OnDisqualify(channelId, 9, vehicle.id);
						return;
					end
					if (not server) then
						nCX.SendTextMessage(3, "RACER:ACTIVE - [ F5 + 2 ] to GIVEUP", channelId);
						CryMP.Ent:PlaySound(player.id, "error");
					end
				end
				local seatId = self.Seat;
				if (not self.Timer or self.Timer < 3) then
					seatId = 1;
				end
				return true, {seatId};
			end
		end,

		OnVehicleDestroyed = function(self, vehicleId, vehicle)
			local channelId = self.Vehicles[vehicleId];
			if (channelId) then
				nCX.GodMode(channelId, false);
				CryMP:SetTimer(3, function()
					self:OnDisqualify(channelId, vehicle.vehicle:IsSubmerged() and 4 or 2, vehicle.id);
				end);
			end
		end,
		
		--[[
		PreHit = function(self, hit, shooter, target)
			if (target and target.actor) then
				local channelId = target.Info.Channel;
				local racer = self:GetRacer(channelId);
				if (racer) then
					if (shooter and shooter.actor and shooter.id~=target.id) then
						nCX.SendTextMessage(5, self.Message, shooter.Info.Channel);
					end
					return true;
				end
			end
		end,
		]]
		
		PreVehicleHit = function(self, hit, vehicle)
			if (self.FreeVehicles[vehicle.id] or self.Vehicles[vehicle.id]) then
				if (hit.typeId == 35) then -- this one is a bit too overpowered for death races...
					return true;
				end
				if (hit.typeId == 13) then -- this one is a bit too overpowered for death races...
					return true;
				end
				local shooter = hit.shooter;
				local channelId = shooter.Info and shooter.Info.Channel;
				if (shooter and shooter.Info) then
					if (not self:GetRacer(channelId)) then
						nCX.SendTextMessage(5, self.CarMessage, channelId);
						return true;
					end
				end
				if (vehicle:IsHeavy()) then
					hit.damage = hit.damage * 0.2; --reduce hitdamage if tanks
				end
				if (self.IsDeathRace) then
					local ratio = self:GetTeamRatio(hit.damage, channelId); -- new! 
					if (ratio ~= 0) then
						hit.damage = hit.damage * ratio;
					end
				end
				return false, {hit};
			end
		end,
		
		OnKill = function(self, hit)
			if (hit.target and hit.target.Info) then
				local channelId = hit.target.Info.Channel;
				local racer = self:GetRacer(channelId);
				if (racer) then
					self:OnDisqualify(channelId, 3, racer.VehicleId);
				end
			end
		end,
		
		OnChangeTeam = function(self, player, teamId)
			local channelId = player.Info.Channel;
			if (self:GetRacer(channelId)) then
				nCX.SendTextMessage(2, "Cannot change team in Racing mode", channelId);
				return true;
			end
		end,
		
		OnChangeSpectatorMode = function(self, player, mode)
			local channelId = player.Info.Channel;
			local racer = self:GetRacer(channelId);
			if (racer) then
				self:Disqualify(channelId, 8);
			end
		end,
			
		OnRadioMessage = function(self, player, msg)
			if (not self.Declined[player.id]) then
				local channelId = player.Info.Channel;
				local racer = self:GetRacer(channelId);
				if (not racer and self:Count() < 4 and self.Timer and self.Timer > 5) then
					if (msg == 1) then
						self.Declined[player.id] = nil;
						local ok , error = self:Teleport(player);
						if (not ok) then
							CryMP.Msg.Chat:ToPlayer(channelId, error, self.Tag);
						end
						return ok;
					elseif (msg == 2 and not self.Declined[player.id]) then
						nCX.SendTextMessage(0, "", channelId);
						self.Declined[player.id] = true;
						CryMP.Msg.Chat:ToPlayer(channelId, "RACE DECLINED [ F5 + 1 ] to REJOIN", self.Tag);
						return true;
					end
				elseif (racer and msg == 2) then
					self:OnDisqualify(channelId, 7, racer.VehicleId);
					return true;
				end
			end
		end,	
		
		OnStatusRequest = function(self, actorId)
			if (self.Timer and self.Timer > 5) then
				return true;
			end
		end,
		
	},
	
	Activate = function(self, course, car)
		local course = course or "medium";
		local car = car or "jeep";
		
		self.Track = self.Tracks[course];
		self.Tracks = nil;
		
		local settings = {
			["jeep"]	= {Class = "US_ltv", Mod = "Unarmed",},
			["taxi"] 	= {Class = "Civ_car1", Seat = 2,},
			["truck"] 	= {Class = "Asian_truck",},
			["apc"] 	= {Class = "Asian_apc", Death = true,},
			["tank"] 	= {Class = "US_apc", Death = true,},
			["hover"] 	= {Class = "US_hovercraft", Death = true,},
			["ltv"] 	= {Class = "Asian_ltv", Death = true,},			
		};
		
		local tbl = settings[car];
		if (tbl.Class == "US_hovercraft") then
			local mods = {"HovercraftGun", "Gauss", "MOAC"};
			tbl.Mod = mods[math.random(#mods)];
		end
		self:CarsSpawn(tbl.Class, tbl.Mod or "");
		self:TriggersSpawn();
		
		self.IsDeathRace = tbl.Death;
		self.Seat = tbl.Seat or self.Seat;
		
		local track = self.Track.id == 1 and "medium" or self.Track.id == 2 and "long" or "sprint";
		local text = self.Track.id == 1 and "~ MEDIUM : " or self.Track.id == 2 and "~ LONG : " or "~ SPRINT : ";
		local text = text..car:upper().." ~";
		nCX.SendTextMessage(3, "*** "..text.." RACE : :  started  : : Go to START-LINE ***", 0);
		--CryMP.Msg.Animated:ToAll(2,"<b><i><font color=\"#efefef\">*** "..text.." RACE</font><font color=\"#a7a6a6\"> : :  started  : : Go to </font><font color=\"#efefef\"> START-LINE</font><font color=\"#a7a6a6\"> *** </b></i>");
		--CryMP.Msg.Flash:ToAll({50, "#e7e7e7", "#9f9f9f", true, 5}, text, "<font size=\"32\"><b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#efefef\">RACE ( </font>%s <font color=\"#efefef\">) TRACK</font> <font color=\"#b9b9b9\">!! ***</font></b></font>");
		g_gameRules.allClients:ClTimerAlert(self.Timer);
		self:SetTick(1);
		self:Log("Race started (track: "..track..", "..car..")");
		return true;
	end,
	
	OnShutdown = function(self)
		for channelId, racer in pairs(self.Racers) do
			local player = nCX.GetPlayerByChannelId(channelId);
			self:Return(player);
		end
		for carId, free in pairs(self.FreeVehicles) do
			if (System.GetEntity(carId)) then
				System.RemoveEntity(carId);
			end
		end
		for i, triggerId in pairs(self.Checkpoints) do
			System.RemoveEntity(triggerId);
		end
		--CryMP.Msg.Animated:ToAll(2, "<b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#C00000\">RACE ( <font color=\"#e7e7e7\">CLOSED</font> <font color=\"#C00000\">) TRACK</font> <font color=\"#b9b9b9\">!! ***</font></b>");
		nCX.SendTextMessage(0, "*** !! RACE ( CLOSED ) TRACK!! ***", 0);
		self:Log("Race Finished...");
	end,
	
	GetTeamRatio = function(self, shooterChannel)
		local tbl = self.Racers[shooterChannel];
		if (tbl and tbl.TeamId ~= 0) then	
			if (not self.TeamStats) then
				local teamCount = {[1] = 0, [2] = 0,};
				for channelId, racer in pairs(self.Racers) do
					if (teamCount[racer.TeamId]) then
						teamCount[racer.TeamId] = teamCount[racer.TeamId] + 1;
					end
				end
				self.TeamStats = {
					[1] = teamCount[1],
					[2] = teamCount[2],
				};
			end
			local enemyId = tbl.TeamId == 1 and 2 or 1;
			if (self.TeamStats[tbl.TeamId] > self.TeamStats[enemyId]) then
				return 1 / (self.TeamStats[tbl.TeamId] / self.TeamStats[enemyId]);
			end
		end
		return 1;
	end,
	
	Count = function(self)
		return nCX.Count(self.Racers);
	end,
	
	GetRacer = function(self, channelId)
		return self.Racers[channelId];
	end,

	Teleport = function(self, player)
		local playerId, channelId = player.id, player.Info.Channel;
		if (player:IsDuelPlayer()) then
			return false, "cannot use while duel";
		elseif (player:IsBoxing()) then
			return false, "cannot use while duel";
		elseif (not nCX.IsPlayerActivelyPlaying(playerId)) then
			return false, "actively playing only";
		elseif (self:Count()==4) then
			return false, "only 4 players can participate";
		end
		
		--CryMP:GetPlugin("Refresh", function(self) self:SavePlayer(player); end);
		
		local car = System.GetEntity(self:GetFreeCar());
		if (not car) then
			return false, "error";
		end
		
		self.Racers[channelId] = self:CreateRacer(player, car);
		self.FreeVehicles[car.id] = false;
		self.Vehicles[car.id] = channelId;
		
		local name = player:GetName();
		
		nCX.ParticleManager("misc.emp.sphere", 0.5, player:GetWorldPos(), g_Vectors.up, 0);
		CryMP.Msg.Chat:ToAll("[ RACER "..name.." #"..math:zero(self:Count()).." ] :: Entering the LOBBY :: Get Ready!", self.Tag);
		if (self.Seat == -1) then
			player.inventory:Destroy();
			--CryMP.Msg.Flash:ToPlayer(channelId, {30,"#e7e7e7", "#9f9f9f",true},"~ LOBBY ~", "<font size=\"30\"><b><font color=\"#006600\">RACE : (</font><font color=\"#59c93a\"> </b>%s<b> </font><font color=\"#006600\">) : RACE");
			nCX.SetInvulnerability(playerId, true, 3);
			player.actor:SetNanoSuitEnergy(200);
			CryMP.Ent:MovePlayer(player,car:GetExitPos(1) or {1807,2604,50},g_Vectors.v000); 
		else
			car:EnterVehicle(playerId, self.Seat);
			local factory = CryMP.Ent:GetFactory(playerId);
			factory.allClients:ClVehicleBuilt(car:GetName(), car.id, playerId, nCX.GetTeam(playerId), self:Count());
			nCX.GodMode(channelId, true);
			--local msg = self.IsDeathRace and "OF DEATH" or "DRIVER";
			--nCX.SendTextMessage(5, "<font size=\"32\"><b> <font color=\"#006600\">RACE (<font color=\"#DDDDDD\">~ "..msg.." ~</font><font color=\"#006600\">) RACE</font></b></font>", channelId);
		end
		CryMP.Ent:NukeTag(player, true);
		if (self.NameTag) then
			nCX.RenamePlayer(player.id, self.NameTag..name);
		end
		return true;
	end,
	
	Return = function(self, player)
		local channelId = player.Info.Channel;
		nCX.GodMode(channelId, false);
		if (self.NameTag) then
			CryMP.Ent:RemoveTag(player:GetName(), self.NameTag, player.id);
		end
		CryMP.Ent:NukeTag(player, false);
		if (self.Seat == -1) then
			g_gameRules:EquipPlayer(player);
		end
		CryMP.Ent:Revive(player, true);
		--[[
		local done = CryMP:GetPlugin("Refresh", function(self) return self:RestorePlayer(player); end);
		if (not done and not player:IsDead()) then
			CryMP.Ent:RestoreInventory(player);
			return CryMP.Ent:Portal(player);
		elseif (not done) then
			CryMP.Ent:Revive(player, true);
			return true;
		end
		]]
		return done;
	end,
			
	BuildLights = function(self)
		self.LightOffset = self.LightOffset + 1;
		for channelId, racer in pairs(self.Racers) do
			local light = 0;
			for sector = self.LastSector, math.min(self.FirstSector, #self.Track.Lights) do
				for index = 1, #self.Track.Lights[sector] do
					local data = self.Track.Lights[sector][index];
					if (data[2] ~= 0) then
						local red = data[2] == 1 and "_red" or "";
						nCX.ParticleManager("misc.runway_light.flash"..red, 1, data[1], g_Vectors.up, channelId);
					else
						light = light + 1;
						local red = (self.LightOffset == 2 and (light > 2 and "_red" or "")) or (light > 2 and "" or "_red");
						local scale = red ~= "" and 1 or 0.9;
						nCX.ParticleManager("misc.runway_light.flash"..red, scale, data[1], g_Vectors.up, channelId);
						if (light == 4) then
							light = 0;
						end
					end
				end
			end
			if (self.LightOffset > 1) then
				self.LightOffset = 0;
			end
		end
	end,
		
	OnTick = function(self, players)
		self:BuildLights();
		if (self.Timer) then
			local msg = self.ChatSpam[self.Timer];
			if (msg) then
				if (self.Timer ~= 5 and self.Timer ~= 0) then
					for i, player in pairs(players) do
						if (not self.Declined[player.id] and not player:IsDuelPlayer() and not player:IsBoxing()) then
							CryMP.Msg.Chat:ToPlayer(player.Info.Channel, msg, self.Tag);
						end
					end
				else
					for channelId, racer in pairs(self.Racers) do
						CryMP.Msg.Chat:ToPlayer(channelId, msg, self.Tag);
					end
				end
			end
			
			if (self:Count() == 4 and self.Timer > 11) then
				self.Timer = 11;
			end
			
			if (self.Timer == 30) then
				for i, player in pairs(players) do
					if (not self.Declined[player.id] and not player:IsDuelPlayer() and not player:IsBoxing()) then
						g_gameRules.onClient:ClTimerAlert(player.Info.Channel, self.Timer);
					end
				end
			elseif (self.Timer == 5) then
				for channelId, racer in pairs(self.Racers) do
					CryMP.Ent:PlaySound(racer.id, "timer5s");
					CryMP.Msg.Teletype:ToPlayer(channelId, '..ooO  !-GET-READY-FOR-THE-RACE-!  Ooo..');
				end
			end
			
			for i, player in pairs(players) do
				if (not self.Declined[player.id]) then
					local channelId = player.Info.Channel;
					if (not self:GetRacer(channelId) and self:Count() < 4 and self.Timer > 5) then
						if (nCX.IsPlayerActivelyPlaying(player.id) and not player:IsBoxing() and not player:IsDuelPlayer() and not player:IsAfk()) then
							nCX.SendTextMessage(0, "RACE :: starts in [ "..math:zero(self.Timer).." ] seconds :: Press [ F5 + 1 ] to get a RACECAR [ 0"..(4 - self:Count()).." cars left ]", channelId);
						end
					elseif (self:GetRacer(channelId)) then
						local names = {};
						for chan, racer in pairs(self.Racers) do
							names[#names + 1] = racer.Name;
						end
						if (self.Timer > 5) then
							nCX.SendTextMessage(0, "RACE :: starts in [ "..math:zero(self.Timer).." ] seconds :: RACERS [ "..table.concat(names, " : ").." ]", channelId);
						end
					end
				end
			end
			
			if (self.Timer == 2) then
				for i, racer in pairs(self.Racers) do
					local car = System.GetEntity(racer.VehicleId);
					car:EnterVehicle(racer.id, 1);
					car:Hide(0);
				end
			elseif (self.Timer == 0) then
				nCX.SendTextMessage(0, " ", 0);
				if (self:Count()==0) then
					return self:ShutDown(true);
				elseif (self:Count()==1) then
					self.IsAlone = true;
				end
				for i, pos in pairs(self.Track.StartFlarePos) do
					nCX.ParticleManager("explosions.flare.night_time_selfillum", 1, pos, g_Vectors.up, 0);
				end
				for channelId, racer in pairs(self.Racers) do
					--CryMP.Msg.Flash:ToPlayer(channelId, {30, "#e7e7e7", "#9f9f9f", true}, "~ GO! ~", "<font size=\"30\"><b><font color=\"#006600\">RACE : (</font><font color=\"#59c93a\"> </b>%s<b> </font><font color=\"#006600\">) : RACE");
				end
				self.Started = true;
				self.StartTime = os.clock(); --_time;
				self.Timer = nil;
				return;
			end
			self.Timer = self.Timer - 1;
		elseif (self.WinTime and (_time - self.WinTime) >= 30) then
			return self:ShutDown(true);
		elseif (self.Started and not self.WinTime) then
			for vehicleId, channelId in pairs(self.Vehicles) do
				local car = System.GetEntity(vehicleId);
				if (car) then
					local racer = self.Racers[channelId];
					if (racer) then
						if (car:GetSpeed() < 1 and not self.Debug) then
							racer.TimeOut = (racer.TimeOut or self.TimeOut) - 1;
							if (racer.TimeOut < 11) then
								nCX.SendTextMessage(0, "You're going to slow... Timeout in [ "..math:zero(racer.TimeOut).." ]", channelId);
								racer.Slow = true;
							end
							if (racer.TimeOut < 1) then
								self:OnDisqualify(channelId, 6, racer.VehicleId);
							end
						else
							if (racer.Slow) then
								nCX.SendTextMessage(0, "", channelId);
								racer.Slow = nil;
							end
							racer.TimeOut = nil;
						end
					end
				end
			end
		end
	end,
		
	TriggersSpawn = function(self)
		for index, data in pairs(self.Track.CheckpointData) do
			local params = {
				name = "RACE_CHECKPOINT "..index,
				pos = data[2],
				dir = data[3],
				dim = data[1],
			};
			local trigger = CryMP.Ent:SpawnTrigger(params, nil, self.Debug);
			self.Checkpoints[#self.Checkpoints+1] = (trigger and trigger.id);
			trigger.CheckpointNr = index;
			System.LogAlways("Spawning trigger index "..index.." as "..trigger:GetName());
		end
	end,
	
	CarsSpawn = function(self, class, mod)
		for index, carpos in pairs(self.Track.CarPositions) do
			local CarPaints = class == "Civ_car1" and {"black","blue","green","blue","police","red","silver","utility","pink","darkblue","orange"} or {"us", "nk"};
			local params = {
				class = class,
				name = "RACECAR #"..index,
				orientation = carpos[1],
				position = carpos[2],
				properties = {
					Modification = mod,
					Paint = CarPaints[math.random(#CarPaints)],
					Respawn = {
						bAbandon = 0,
						bRespawn = 0,
						bUnique = 1,
						nAbandonTimer = 0,
						nTimer = 0,
					},
				},
			};
			CryMP:Spawn(params, function(spawned) 
				if (spawned) then
					spawned:Hide(1);
					self.FreeVehicles[spawned.id] = true;
					spawned:SetWorldAngles(carpos[1]);
				end
			end);
		end
	end,
	
	OnDisqualify = function(self, channelId, reason, vehicleId)
		local racer = self.Racers[channelId];
		if (racer and racer.isFinish) then
			return;
		end
		local player = nCX.GetPlayerByChannelId(channelId);
		local name = racer and racer.Name or player:GetName();
		self.Racers[channelId] = nil;
		local count = self:Count();
		local remain = count > 0 and " - "..count.." RACERS:REMAINING!" or self.Started and " - RACE:ABORTED!" or "";
		local reasons = {
			" disconnected",
			"'s car was destroyed",
			" was killed",
			" is swimming with the fishes",
			" was disqualified (shortcutting)",
			" was disqualified (timeout)",
			" gave up the race",
			" went spectating",
			" was disqualified (ADMIN DESCISION)",
		};
		local reason = reasons[reason]..remain;
		CryMP.Msg.Chat:ToAll("Racer "..name..reason, self.Tag);
		if (vehicleId and System.GetEntity(vehicleId) and self.Timer and self.Timer > 5) then
			self.Vehicles[vehicleId] = nil;
			self.FreeVehicles[vehicleId] = true;
		elseif (vehicleId and System.GetEntity(vehicleId)) then
			self.Vehicles[vehicleId] = nil;
			self.FreeVehicles[vehicleId] = nil;
			System.RemoveEntity(vehicleId);
		end
		if (reason == 5 or reason == 6) then
			nCX.ForbiddenAreaWarning(true, 0, player.id);
			nCX.SendTextMessage(0, "", channelId);
		end
		self:Return(player);
		if (self.Started and count == 0) then
			self:ShutDown(true);
		end
	end,
	
	GetFreeCar = function(self)
		for carid, yes in pairs(self.FreeVehicles) do
			if (yes) then
				return carid;
			end
		end
	end,
	
	CreateRacer = function(self, player, car)
		return {
			id = player.id,
			Checkpoint = 0,
			Position = 4,
			VehicleId = car.id,
			Name = player:GetName(),
			TeamId = nCX.GetTeam(player.id),
		};
	end,
	
	IsRacing = function(self, channelId)
		return self:GetRacer(channelId);
	end,
	
	GetTimePassed = function(self, startTime)
		local time = os.clock();
		local passed = time - startTime;
		local rpassed = math.floor(passed);
		local ms = passed - rpassed;
		local minutes, secsRem = CryMP.Math:ConvertTime(rpassed, 60);
		return math:zero(minutes)..":"..math:zero(secsRem)..":"..string.sub(ms, 3, 5);
	end,
	
};
