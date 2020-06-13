
CryMP.ChatCommands:Add("bigsmoke", {
		Access = 1,
		Info = "distract your enemy with a big smoke bomb",
		Delay = 60,
		InGame = true,
		BigMap = true,
	},
	function(self, player, channelId)
		if (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		end
		local pos = CryMP.Library:CalcSpawnPos(player, -1);
		nCX.ParticleManager("explosions.Smoke_grenade.smoke", 3, pos, g_Vectors.up, 0);
		nCX.SendTextMessage(5, "<font size=\"32\"><b><i><font color=\"#d26bbb\">Lots of smoke...</font></i></b></font>", channelId);
		return true;
	end
);

--===================================================================================
-- FLARE [RANGE]

CryMP.ChatCommands:Add("flare", {
		Info = "launch a flare",
		Args = {
			{"range", Optional = true, Number = true, Info = "range in meters (1 - 300)",},
		},
		Delay = 30,
		InGame = true,
	},
	function(self, player, channelId, distance)
		local flarePos = player:GetWorldPos();
		if (distance) then
			distance = math.max(5, math.min(300, distance));
			local pos = player:GetWorldPos();
			local dir = player:GetDirectionVector(1);
			local hit = {x=0, y=0, z=0};
			hit.x = pos.x + (dir.x * distance);
			hit.y = pos.y + (dir.y * distance);
			hit.z = pos.z + (dir.z * distance);
			hit.z = System.GetTerrainElevation(hit);
			flarePos = {x = hit.x, y = hit.y, z = hit.z};
		end
		nCX.ParticleManager("explosions.flare.night_time", 1, flarePos, g_Vectors.up, 0);
		nCX.SendTextMessage(3, "! :: FLARE AWAY :: !", channelId);
		return true;
	end
);


--===================================================================================
-- FIREWORKS [RANGE]

CryMP.ChatCommands:Add("fireworks", {
		Info = "launch some fireworks",
		Args = {
			{"range", Optional = true, Number = true, Info = "range in meters (1 - 300)",},
		}, 
		Delay = 30,
		InGame = true,
		BigMap = true,
	},
	function(self, player, channelId, distance)
		local flarePos = player:GetWorldPos();
		if (distance) then
			distance = math.max(5, math.min(300, distance));
			local pos = player:GetWorldPos();
			local dir = player:GetDirectionVector(1);
			local hit = {x=0, y=0, z=0};
			hit.x = pos.x + (dir.x * distance);
			hit.y = pos.y + (dir.y * distance);
			hit.z = pos.z + (dir.z * distance);
			hit.z = System.GetTerrainElevation(hit);
			flarePos = {x = hit.x, y = hit.y, z = hit.z};
		end
		nCX.ParticleManager("misc.extremly_important_fx.celebrate", 1, flarePos, g_Vectors.up, 0);
		return true;
	end
);

--===================================================================================
-- MORTAR [RANGE]

CryMP.ChatCommands:Add("mortar", {
		Info = "launch a mortar attack in front of you",
		Args = {
			{"range", Number = true, Info = "range in meters (5 - 300)",},
		}, 
		Delay = 300,
		InGame = true,
		self = "ServerMods",
		Map = {"ia/(.*)"},
		Access = 1,
	},
	function(self, player, channelId, distance)
		local distance = math.max(5, math.min(300, distance));
		return self:MortarAttack(player, distance);
	end
);

--===================================================================================
-- MORTAR [RANGE]

CryMP.ChatCommands:Add("mortar", {
		Info = "launch a mortar attack in front of you",
		Args = {
			{"range", Number = true, Info = "range in meters (5 - 300)",},
		}, 
		Delay = 300,
		InGame = true,
		BigMap = true,
		Price = 800,
		self = "ServerMods",
		Map = {"ps/(.*)"},
		Access = 5,
	},
	function(self, player, channelId, distance)
		if (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		elseif (player:IsRacing()) then
			return false, "not while racing"
		elseif (player:IsAfk()) then
			return false, "not while afk"
		elseif (player:IsBoxing()) then
			return false, "not while boxing"
		end
		local distance = math.max(5, math.min(300, distance));
		return self:MortarAttack(player, distance);
	end
);