--==============================================================================
--!NANO

CryMP.ChatCommands:Add("nano", {	
		Access =  3, 
		Info = "control the nanosuit settings", 
		Args = {
			{"mode", Output = {{"reset","Reset all nanosuit values"},{"speed"},{"strength"},{"cloak"}}},
			{"settings", Info = "1-10 or 0 to reset", Optional = true, Number = true,},
			{"drain", Output = {{"on", "Enable no energy drain"},{"off", "Disable no energy drain"}}, Optional = true},
		},
	}, 
	function (self, player, channelId, mode, settings, drain)
		local Info = {
			["speed"] = {0.42, "g_suitspeedmultmultiplayer"},
			["consumption"] = {35, "g_suitSpeedEnergyConsumptionMultiplayer"},
			["strength"] = {1, "cl_strengthscale"},
			["cloak"] = {1, "g_suitCloakEnergyDrainAdjuster"}
		};
		if (mode == "reset") then
			System.ExecuteCommand(Info["speed"][2].." "..Info["speed"][1]);
			System.ExecuteCommand(Info["strength"][2].." "..Info["strength"][1]);
			System.ExecuteCommand(Info["consumption"][2].." "..Info["consumption"][1]);
			System.ExecuteCommand(Info["cloak"][2].." "..Info["cloak"][1]);
			CryMP.Msg.Chat:ToPlayer(channelId, "All suit settings set to server default", 1);
			nCX.SendTextMessage(2, "[ NANO:SETTINGS ] All suit settings set to server default", 0);
		else
			local max = 10;
			local settings = settings or 0;
			local settings = math.max(0, math.min(settings, max));
			local d = "";
			if (Info[mode]) then
				if (mode == "speed") then
					if (drain) then
						if (drain == "on") then
							System.ExecuteCommand(Info["consumption"][2].." 0");
							d = " (No Energy Drain ON)";
						else
							System.ExecuteCommand(Info["consumption"][2].." "..Info["consumption"][1]);
						end
					end
				end
				if (settings == 0) then
					System.ExecuteCommand(Info[mode][2].." "..Info[mode][1]);
					if (mode == "speed") then
						System.ExecuteCommand(Info["consumption"][2].." "..Info["consumption"][1]);
					end
					CryMP.Msg.Chat:ToPlayer(channelId, mode:upper().." set to server default!", 1);
					nCX.SendTextMessage(2, "[ SUIT:SETTINGS ] SUIT-"..mode:upper().." set to server default", 0);
				else
					local max = settings == max and " (MAX)" or "";
					CryMP.Msg.Chat:ToPlayer(channelId, mode:upper().." is now level : "..settings..max..d, 1);
					nCX.SendTextMessage(2, "[ SUIT:SETTINGS ] SUIT-"..mode:upper().." set to level "..settings..max..d, 0);
					local settings = mode == "strength" and settings*200 or settings;
					System.ExecuteCommand(Info[mode][2].." "..settings);
				end
			end
		end
		return true;
	end
);
