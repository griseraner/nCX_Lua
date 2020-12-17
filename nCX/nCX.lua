-- *****************************************************************
--        ####     ##  #####  ##   ##
--        ## ##    ## ##   ##  ## ##	Crysis nCX
--        ##  ##   ## ##        ###
--        ##   ##  ## ##        ###     
--        ##    ## ## ##   ##  ## ##     Version:  3.0 Public
--        ##     ####  #####  ##   ##    
-- *****************************************************************

local port = System.GetCVar("sv_port");
nCX.ProMode = port == 50020 or port == 50030;

Script.ReloadScript("Server/Common.lua");	-- load math before all entities
Script.ReloadScript("Server/Lua-Files/actor/BasicActor.lua"); 

OnInit = function() 
end

--> Remove synching
local CVars = io.open(nCX.ROOT.."Game/Server/nCX/CVars.cfg", "r");
if (not CVars) then
	System.ExecuteCommand("sys_dump_cvars");
	CVars = io.open(nCX.ROOT.."Game/Server/nCX/CVars.cfg", "r");
end

if (CVars) then
	local us, sy = 0, 0;
	for CVar in CVars:lines() do
		CVar = CVar:lower();
		local foundSV;
		for sCV, set in pairs(nCX.Config.CVars_Server or {}) do
			if (CVar == sCV:lower()) then
				nCX.SetCVarSynch(CVar, false);
				nCX.ForceCVar(CVar, set);
				foundSV = true;
				us = us + 1;
			end
		end		
		if (not nCX.Config.CVars[CVar] and not nCX.Config.KeepSynching[CVar] and not foundSV) then
			nCX.SetCVarSynch(CVar, false);
			us = us + 1;
			foundSV = true;
		end
		if (not foundSV) then
			sy = sy + 1;
		end
	end
	if (sy > 0) then
		System.LogAlways("[nCX] "..us.." CVars are synced.");
	end
	CVars:close();
end

--[[ 
	CHRIS: changed shutdown process! 
	needed for permascore for example
	ensure that no function is called OnShutdown (such as nCX.Log()) which has been deleted earlier!
]]
OnShutdown = function()
	System.LogAlways("CryMP shutdown");
	if (CryMP.Plugins) then
		pcall(CryMP.Server.OnReset, CryMP, 1);
	end
end

---------------------------
--		Bootstrap
---------------------------
function nCX:Bootstrap(reload)
    if (not reload) then
    --	self:RemoveGarbageEnts();
	end
	local port = System.GetCVar("sv_port");
	self.ProMode = port == 50020 or port == 50030;
	if (self.ProMode) then
		System.LogAlways("[nCX] PRO-MODE ENABLED");
	end
	self.Spawned = self.Spawned or {};
	if (CryMP) then
		if (not CryMP.Reseted) then
			pcall(CryMP.Server.OnReset, CryMP, not reload);
		else
			CryMP.Reseted = nil;
		end
	end
	if (not CryMP or (CryMP and reload)) then
		local function LoadCore(path)
			assert(loadfile(path))();
		end
		local a, b = pcall(LoadCore, self.ROOT.."Game/Server/nCX/System/CryMP.lua");
		if (not a) then
			System.LogAlways("[nCX Lua] Aborted bootstrap (CryMP.lua loading failed: "..b..").");
			return;
		end
		System.AddCCommand("reload", "nCX:Bootstrap(true)", "reload CryMP LUA Mod");
	end
	-- Let's get this party started! Trigger the Core loader!
	CryMP:Initialize(reload);	
end

---------------------------
--		OnVehicleSpawn
---------------------------
function nCX:OnVehicleSpawn(vehicle)
	CryMP:HandleEvent("OnVehicleSpawn", {vehicle});
end
---------------------------
--		CheatControl
---------------------------
function nCX:CheatControl(player, cheat, info, lagging, sure)
	CryMP:HandleEvent("OnCheatDetected", {player, cheat, info, lagging, sure});
end
---------------------------
--		OnValidationSuccess
---------------------------
function nCX:OnValidationSuccess(player, profileId, token)
	profileId = tostring(profileId);
	player.Info.ID = profileId;
	player.Info.Token = token;
	local channelId = player.Info.Channel;
	CryMP:HandleEvent("OnConnect", {channelId, player, player.Info.ID, reset});

	local restored = (nCX.GetSynchedEntityValue(player.id, 100) or 0) > 0;
	local name = player:GetName();
	local CC = player.Info.Country;
	if (not player:IsNomad() and CC ~= "Europe") then
		name = name.." (from "..CC..")";
	end
	name = player:GetAccess() > 0 and "Premium "..name or name;
	g_gameRules.otherClients:ClClientConnect(channelId, name, restored);

	player.Validated = true;
end
---------------------------
--		OnRadioMessage
---------------------------
function nCX:OnRadioMessage (player, msg)
	local quit = CryMP:HandleEvent("OnRadioMessage", {player, msg + 1});
	if (quit) then
		return false;
	end
end
---------------------------
--		OnChatMessage
---------------------------
function nCX:OnChatMessage(type, sender, command, msg)
	local quit = CryMP:HandleEvent("OnChatMessage", {type, sender, command, msg});
	if (quit or (command and #command > 0)) then
		return false;
	end
	return true;
end
---------------------------
--		VoteResult
---------------------------
function nCX:VoteResult(type, channelId)
	if (self.Config.VoteSystem[type]) then
		if (channelId > 0) then
			local player = self.GetPlayerByChannelId(channelId);
			if (player) then
				if (type == "Mute") then
					CryMP:GetPlugin('Mute', function(self) self:Add(player, 5); end);
				elseif (type == "Kick") then
					CryMP.BanSystem:TempBan(player, 'vote ban', 5, 'Vote');
				end
			end
		else
			if (type == "Vtol") then
				CryMP:GetPlugin('LockDowns', function(self) self:ToggleAirMode('US_vtol'); end);
			elseif (type == "Nextmap") then
				local count = self.Count(self.Config.LevelRotation);
				if (count > 1) then
					CryMP.Msg.Chat:ToAll("Changing to next level...", 3);
					CryMP:SetTimer(5, function() System.ExecuteCommand("g_nextlevel"); end);
				else
					CryMP.Msg.Chat:ToAll("Voting failed! (only 1 map in levelrotation)", 3);
				end
			end
		end
	end
end

---------------------------
--		OnFileChange
---------------------------
function nCX:OnFileChange(file, newsize)
	local file = io.open(CryMP.Paths.GlobalData.."BanList.lua", "r");
	if (file and file:seek("end") == newsize) then
		CryMP.Synch:OnChange(file, newsize);
		file:close();
		return
	end
end

--[[
---------------------------
--		OnItemPickedUp
---------------------------
function nCX:OnItemPickedUp(actor, item)
	--System.LogAlways("OnItemPickedUp "..type(actor).." "..type(item));
	--if (item.Properties.nCX_OnItemPickEvent == 1) then
		if (CryMP:HandleEvent("OnItemPickedUp", {actor, item})) then
			return false;
		end
	--end
	return true;
end

---------------------------
--		OnItemDropped
---------------------------
function nCX:OnItemDropped(actor, item)
	--System.LogAlways("OnItemDropped "..type(actor).." "..type(item));
	if (item.Properties.nCX_OnItemPickEvent == 1) then
		if (CryMP:HandleEvent("OnItemDropped", {actor, item})) then
			return false;
		end
	end
	return true;
end
]]

---------------------------
--		RemoveGarbageEnts
---------------------------
function nCX:RemoveGarbageEnts()
	local garbage = {
		"MusicPlayPattern","ReverbVolume","Light","ParticleEffect","TeamRandomSoundVolume","RandomSoundVolume","AmbientVolume","AmbientVolume","SoundEventSpot","Chickens","MusicMoodSelector","Birds","Frogs","Crabs","Fish","Turtles",
		"MusicEndTheme", "Cloud", "FogVolume", "MusicThemeSelector","TagPoint","PrecacheCamera",--[["ProximityTrigger",]]"Plover","ParticleEffect",
	};
	local total = 0;
	for i, class in pairs(garbage) do
		local ents = System.GetEntitiesByClass(class) or {};
		for i, ent in pairs(ents) do
			if (not ent.class:find("Sound") and not ent.class:find("Volume") and not ent.class:find("Music")) then
				System.RemoveEntity(ent.id);
				total = total + 1;
				if (total == 1) then
					System.LogAlways("------------------------------");
				end
			end
		end
		local c = #ents;
		if (c > 0) then
			System.LogAlways("   #$4"..math:zero(c).." $9"..class);
		end
	end
	local ents = {};
	if (total > 0) then
		System.LogAlways("  #$4"..math:zero(total).." $9Client Entities removed");
		System.LogAlways("------------------------------");
	end
	for i, ent in pairs(System.GetEntities()) do
		ents[ent.class] = (ents[ent.class] or 0) + 1;
	end
	for class, count in pairs(ents) do
		System.LogAlways("  #$4"..math:zero(count).." $9"..class);
	end
end