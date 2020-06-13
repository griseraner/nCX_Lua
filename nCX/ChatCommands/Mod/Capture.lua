--==============================================================================
--MODERATOR CHAT COMMANDS:
--==============================================================================

CryMP.ChatCommands:Add("capture", {
		Access = 2, 
		Args = {
			{"Entity", Optional = true, Number = true, Info = "entity by index",},
		}, 
		Info = "capture a specific entity",
		Map = {"ps/(.*)"},
	}, 
	function(self, player, channelId, input)
		local function display(msg)
			local header = "$9==============================================================================================";
			--CryMP.Msg.Console:ToPlayer(channelId, header);
			local classes = {"SpawnGroup", "AlienEnergyPoint", "Factory"};
			local index = 0;
			for i, class in pairs(classes) do
				local entities = System.GetEntitiesByClass(class);
				if (entities) then
					CryMP.Msg.Console:ToPlayer(channelId, "$9"..string.rep("=", 112));
					local teamStats = {[0]=0,[1]=0,[2]=0,};
					for i, entity in pairs(entities) do
						if (not entity.default) then
							local teamId = nCX.GetTeam(entity.id);
							teamStats[teamId] = teamStats[teamId] + 1;
						end
					end
					local count = 0;
					for i, entity in pairs(entities) do
						if (not entity.default) then
							index = index + 1;
							count = count + 1;
							local teamId = nCX.GetTeam(entity.id);
							local teams = {"neutral", "NK", "US",};
							local color = teamId == 0 and "$9" or teamId == 1 and "$4" or "$5";
							local team = color..teams[teamId+1];
							local name = entity:GetName()..(entity.contested and " ($4contested$9)" or "");
							local infoBar = "";
							if (count == 1) then
								infoBar = "$9( $5"..teamStats[2].." $9: $4"..teamStats[1].." $9: $9"..teamStats[0].." $9)";
							end
							CryMP.Msg.Console:ToPlayer(channelId, "$9[ $9#$1"..math:zero(index).."$9 ]               [$7"..string:mspace(7, team).."$9]         $9($1"..string:lspace(5, math.floor(entity:GetDistance(player.id))).."$9m)     "..color..(#infoBar > 0 and name..string:lspace(59-#name, infoBar) or name));
						end
					end
				end
				if (i == #classes) then
					CryMP.Msg.Console:ToPlayer(channelId, "$9"..string.rep("=", 112));
				end
			end
			if (msg) then
				nCX.SendTextMessage(3, "Open console with [^] or [~] to view list of Entities ("..index..")", channelId);
			end
			--CryMP.Msg.Console:ToPlayer(channelId, header);
		end
		local zoneId = nCX.IsPlayerActivelyPlaying(player.id) and g_gameRules.inCaptureZone[player.id];
		if (not input and not zoneId) then
			display(true)
			return -1;
		end
		local list = {};
		local classes = {"SpawnGroup", "AlienEnergyPoint", "Factory"};
		for i, class in pairs(classes) do
			local entities = System.GetEntitiesByClass(class);
			if (entities) then
				for i, entity in pairs(entities) do
					if (not entity.default) then
						list[#list + 1] = entity.id;
						if (not input and entity.id == zoneId) then
							input = i;
						end
					end
				end
			end
		end
		--if (zoneId) then
		--	System.LogAlways(tostring(zoneId).." "..System.GetEntity(zoneId):GetName().." "..System.GetEntity(zoneId).class);
		--end
		input = input or -1;
		local entityId = zoneId or list[input];
		if (entityId) then
			local entity = System.GetEntity(entityId);
			local teamId = nCX.GetTeam(entityId);
			local pteamId = nCX.GetTeam(player.id);
			local team = { [1] = "NK"; [2] = "US"; [0] = "UNCAPTURED";};
			local convert = {
				[1] = 2,
				[2] = 1,
			};
			local newId = convert[teamId];
			if (newId) then
				entity:Uncapture(newId, true);
				entity:Capture(newId);
				local c = 0;
				local inside = entity.inside[teamId];
				for channelId, value in pairs(inside) do
					local player = nCX.GetPlayerByChannelId(channelId);
					if (player) then
						entity.Server.OnLeaveArea(entity, player, false);
						entity.Server.OnEnterArea(entity, player, entity.Properties.captureAreaId);
						c = c + 1;
					end
				end
				if (c > 0) then
					CryMP.Msg.Chat:ToPlayer(channelId, "Affected players: #"..math:zero(c));
				end
			else
				pteamId = pteamId ~= 0 and pteamId or 2;
				entity:Capture(pteamId);
			end
			local name = entity:GetName();
			newId = newId or pteamId;
			nCX.SendTextMessage(2, "[ CAPTURE:CONTROL ] "..entity.class.." team swapped to "..team[newId].." (Admin Descision)", 0);
			self:Log(entity.class.." ("..input..") team swapped to "..team[newId].." ("..name..")");
			display()
		else
			return false, "entity not found"
		end
		return -2;
	end
);
