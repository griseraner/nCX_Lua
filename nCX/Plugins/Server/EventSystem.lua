EventSystem = {

	---------------------------
	--		Config
	---------------------------
	Tick 			= 1000,
	Last 			= 0,
	DisableBoxing   = false,
	
	Events = {
		--{"VehicleChange", "ps/(.*)"},
		{"Award", "ps/(.*)"},
		{"Race", "ps/mesa"},
		{"Boxing", "ps/(.*)"},
		{"Tornado", "ps/(.*)"},
		--{"HappyHour", "ps/(.*)"},
		{"WeaponParty", "ia/(.*)", 
			{
				{ 
					Class = "explosivegrenade", 
					Title = "GRENADE",
					mod = true,
				}, 
				{
					Class = "GaussRifle",
					Title = "GAUSS",
				}, 
				{
					Class = "TACGun", 
					Title = "NUKE",
				},
				{
					Class = "Fists",
					Title = "MAN vs MAN",
					mod = true,
				},
				{
					Class = "Speed",
					Title = "SPEED",
					mod = true,
				},
				{
					Class = "AlienMount", 
					Title = "MOAR",
				},	
			},
		},
	},
	
	--[[Server = {
		
		OnBuyVehicle = function(self, player, itemName)
			if (System.GetCVar("g_pp_scale_price") == 0) then
				local restricted = {["ussingtank"] = true, ["nktactank"] = true, ["ustactank"] = true};
				if (restricted[itemName]) then
					CryMP.Msg.Chat:ToPlayer(player.Info.Channel, "Buying NUKE while HappyHour is Active is not a good idea", 2);
					return true;
				end
			end
		end,
		
	},]]

	OnTick = function(self)		
		if (nCX.GetTeamPlayerCount(1) + nCX.GetTeamPlayerCount(2) < 1) then
			return;
		end
		self.Last = self.Last + 1;
		if (self.Last > #self.Events) then
			self.Last = 1;
		end
		local chosen = self.Events[self.Last];
		local event, map = chosen[1], chosen[2];
		local current = nCX.GetCurrentLevel():sub(13, -1):lower();
		if (map and not current:match(map)) then
			return self:OnTick();
		end
		local timer = self.DisableBoxing and 2 or 0;
		if (self.DisableBoxing) then
			self.DisableBoxing = self.DisableBoxing - 1;
			if (self.DisableBoxing < 1) then
				self["Boxing"](self);
				self.DisableBoxing = nil;
			end
		end
		CryMP:SetTimer(timer, function()
			local x, error = pcall(self[event], self, self.Events[self.Last]);
			if (x) then
				nCX.Log("Core", "Event started: "..event);
			else
				nCX.Log("Core", "Event failed: "..event.." ("..error..")");
				self:OnTick();
			end
		end);
	end,
	
	VehicleChange = function(self)
		return CryMP:GetPlugin("LockDowns", function(self)
			return self:ToggleAirMode();
		end);
	end,
	
	Award = function(self)
		CryMP.Library:Pay(3, 500, 0, true);
		CryMP.Msg.Chat:ToAll("500 PP to all!");
		for i, hq in pairs(g_gameRules.hqs or {}) do
			nCX.ParticleManager("misc.extremly_important_fx.celebrate", 1, hq:GetWorldPos(), g_Vectors.up, 0);
		end
		return true;
	end,
	
	Tornado = function(self)
		local Tornados = System.GetEntitiesByClass("Tornado");
		if (Tornados) then
			for i, t in pairs(Tornados or {}) do
				if (t:GetName() ~= "nCX_Tornado") then
					System.RemoveEntity(t.id);
				end
			end
		end
		local energySites = System.GetEntitiesByClass("AlienEnergyPoint");
		local class = "Tornado";
		for i, energy in pairs(energySites or {}) do
			local ep = {
				class = class;
				position = energy:GetPos();
				orientation = energy:GetAngles();
				name = "Event_"..class;
			};
			local t = System.SpawnEntity(ep);
		end	
		local data = [[
			g_gameRules:PlaySoundAlert("tacalarm");
			HUD.BattleLogEvent(eBLE_Warning, "Tornados spawned near AlienEnergy Sites!");
		]]		
		g_gameRules.allClients:ClWorkComplete(g_gameRules.id, "EX:"..data);
		CryMP:SetTimer(60 * 6, function()
			local Tornados = System.GetEntitiesByClass("Tornado");
			if (Tornados) then
				for i, t in pairs(Tornados or {}) do
					if (t:GetName() ~= "nCX_Tornado") then
						System.RemoveEntity(t.id);
					end
				end
			end
		end);
		return true;
	end,
	
	Race = function(self)
		local courses = {"sprint","medium",};
		local cars = {"jeep","taxi","truck","hover","ltv",};
		if (not CryMP.Race) then
			return CryMP:GetPlugin("Race", function(self)
				return self:Activate(courses[math.random(1, #courses)], cars[math.random(1, #cars)]);
			end);
		end
	end,
	
	Boxing = function(self)
		local positions = {"", "sky"};
		if (CryMP.Boxing) then
			return CryMP.Boxing:ShutDown(true);
		else
			self.DisableBoxing = 2;
			return CryMP:GetPlugin("Boxing", function(self)
				local ok = self:Activate("");
				if (ok) then
					local types = {"gravity", ""};
					local v = types[math.random(#types)];
					if (v ~= "") then
						self:Boxmode(0, v);
					end
					local data = [[	HUD.BattleLogEvent(eBLE_Currency, "Boxing has been activated. Join with !boxing"); ]]		
					g_gameRules.allClients:ClWorkComplete(g_gameRules.id, "EX:"..data);
				end
				return ok;
			end);
		end
	end,
	
	HappyHour = function(self)
		if (System.GetCVar("g_pp_scale_price") == 0) then
			return false, "happy hour active";
		elseif (nCX.IsTimeLimited() and nCX.GetRemainingGameTime() <= 180) then
			return false, "time runs out";
		--elseif (g_gameRules:GetTeamPower(1) > 99 or g_gameRules:GetTeamPower(2) > 99) then
		--	return false, "energy to high";
		end
		System.SetCVar("g_pp_scale_price", 0);
		CryMP.Msg.Flash:ToAll({30, "#af3838", "#ff0000"}, "~ EVERYTHING FOR FREE ~", "<font size=\"30\"><b><font color=\"#FFD800\">HAPPY : (</font><font color=\"#59c93a\"> </b>%s<b> </font><font color=\"#FFD800\">) : HOUR");
		CryMP:SetTimer(3, function()
			CryMP.Msg.Flash:ToAll({30, "#af3838", "#ff0000"}, "~ RUN TO YOUR NEAREST BUYZONE ~", "<font size=\"30\"><b><font color=\"#FFD800\">HAPPY : (</font><font color=\"#59c93a\"> </b>%s<b> </font><font color=\"#FFD800\">) : HOUR");
		end);
		
		for i=1, 5 do
			CryMP:SetTimer(10*i, function()
				CryMP.Msg.Battle:ToAll("Happy hour active ("..tostring(60-i*10).." seconds)");
			end);
		end
		
		CryMP:SetTimer(60, function()
			CryMP.Msg.Flash:ToAll({30, "#af3838", "#ff0000"}, "~ OVER ~", "<font size=\"30\"><b><font color=\"#FFD800\">HAPPY : (</font><font color=\"#59c93a\"> </b>%s<b> </font><font color=\"#FFD800\">) : HOUR");
			System.SetCVar("g_pp_scale_price", 1);
		end);
		return true;
	end,

	WeaponParty = function(self, fullData)
		local data = fullData[3][math.random(1, #fullData[3])];
		if (data.mod) then
			
		else
			CryMP.Library:Give(3, data.class, true);
		end
		CryMP.Msg.Flash:ToAll({12, "#d77676", "#ec2020", true}, "~ GO ~", "<font size=\"32\"><b><font color=\"#b9b9b9\">*** !!</font> <font color=\"#C00000\">"..data.Title.." [<font color=\"#d77676\"> %s </font><font color=\"#C00000\">] PARTY</font> <font color=\"#b9b9b9\">!! ***</font></b></font>");
		return true;
	end,
};