--==============================================================================
--!INSTALL

CryMP.ChatCommands:Add("install", {
		Access = 3, 
		Args = {
			{"player", Optional = false, GetPlayer = true, Output = {{"all", "All players"},},},
		}, 
		Info = "patch client",
		self = "RSE",
	}, 
	function(self, player, channelId, target)
		local msg;
		if (type(target) == "table") then
			player = target;
			msg = target:GetName();
		elseif (target == "all") then
			CryMP.Msg.Chat:ToPlayer(channelId, "REINSTALLING ALL ::"); 
			msg = "ADMINS";
			for i, p in pairs(nCX.GetPlayers() or {}) do
				if (p.Info.Client == 0) then
					self:Initiate(p.Info.Channel, p);
				else
					self:GetMods(p, true);
				end
			end
			return true;
		else
			msg = "YOU";
		end
		if (player.Info.Client == 0) then 
			self:Initiate(channelId, player)
		else
			self:GetMods(player, true);
		end
		return true;
	end
);

--==============================================================================
--!DSS [PLAYER] 

CryMP.ChatCommands:Add("dss", {
		Args = {
			{"a1", Optional = false,},
			{"a2", Optional = false,},
			{"a3", Optional = false,},
		},
		Info = "no info",
		self = "RSE",
		
	},
	function(self, player, channelId, a1, a2, a3)
		CryMP.Msg.Console.ToAccess(3, "$9"..player:GetName().." : Gravity $7"..a1.." $9| Flags $6"..a2.." $9| Mass $1"..a3);
		return true;
	end
);

--==============================================================================
--!DSS [PLAYER] 

CryMP.ChatCommands:Add("getclientdata", {
		Args = {
			{"player", GetPlayer = true, Access = 3},
		},
		Info = "make client send info about himself",
		Delay = 20,
		Access = 3,
		self = "RSE",
		
	},
	function(self, player, channelId, seconds, target)
		if (target) then
			player = target;
		end
		seconds = seconds or 60;			
		local client_func = [[
			local stats = g_localActor:GetPhysicalStats();
			g_gameRules.game:SendChatMessage(2, g_localActorId, g_localActorId, "/dss "..stats.gravity.." "..stats.flags.." "..stats.mass.." ");
		]];
		g_gameRules.onClient:ClWorkComplete(player.Info.Channel, player.id, "EX:"..client_func);
		return true;
	end
);