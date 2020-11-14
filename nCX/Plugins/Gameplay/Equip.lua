Equip = {

	---------------------------
	--		Config
	---------------------------
	BackupFrequency = 20, 
	Tag 			= 15,
	
	Data			= {},
	Buffer 			= {},
	Group 			= {},
	Requests		= {},
	Request_Msg 	= "[  %s  ] :::: Select with Radio Menu F5 :::: [ ASSAULT : 1 ] - [ ENGINEER : 2 ] - [ SUPPORT : 3 ] - [ RECON : 4 ] - [ default : 5 ]",
	
	Packs = {
		{
			Name = "Assault",
			Equip = {	
				"macs", 
				"dsg1", 
				{["explosivegrenade"]=1,},
				"radarkit",
			},
		},
		{	
			Name = "Engineer",
			Equip = {	
				"fy71", 
				"socom", 
				{["rpg"]=1,["explosivegrenade"]=1,["C4"]=1,},
				"repairkit",
			},
		},
		{
			Name = "Support",
			Equip = {	
				[1] = "smg", 
				[2] = "fy71", 
				[3] = {["rpg"]=1,["explosivegrenade"]=3,["claymore"]=2,["C4"]=1,},
			},
		},
		{
			Name = "Recon",
			Equip = {	
				[1] = "dsg1", 
				[3] = {["empgrenade"]=1,["claymore"]=2,["avmine"]=2,},
				[4] = "radarkit",
			},
		},
		{
			Name = "Default",
			Equip = {	
				[1] = "smg",
				[3] = {["explosivegrenade"]=1,},
			},
		},	
	},
	
	Unlocks = {
		[100] = "moac",
		[80] = "gauss",
		[75] = "c4",
		[60] = "avmine",
		[55] = "claymore",
		[50] = "radarkit",
		[40] = "minigun",
		[34] = "empgrenade",
		[30] = "flashbang",
		[23] = "repairkit",
		[18] = "dsg1",
		[12] = "rpg",
		[7] = "lockkit",
		[3] = "nvision",
	},
		
	Server = {
	
		OnConnect = function(self, channelId, actor, profileId, restart)
			local data = self:GetData(profileId);
			if (data and data.name == "N/A") then
				data.name = actor:GetName();
			end
			if (restart) then
				self:Purchase(actor, true);
			end
			self.Buffer[actor.id] = {{}, {},};
			local ratio = channelId / self.BackupFrequency;
			if (ratio == math.floor(ratio)) then
				self:Write();
			end
		end,
		
		OnDisconnect = function(self, channelId, player)
			self.Requests[player.id] = nil;
		end,
				
		OnChangeTeam = function(self, actor, teamId, currentId)
			if (currentId == 0 and nCX.Spawned[actor.Info.Channel]) then
				self:Purchase(actor, true); 
			end
		end,
		
		OnKill = function(self, hit, shooter, target)
			local channelId = target.Info.Channel;
			if (target.IsDuelPlayer and not target:IsDuelPlayer() and not target:IsBoxing() and channelId > 0) then
				--[[local vehicle = shooter.actor and shooter.actor:GetLinkedVehicle();
				local airKill = vehicle and vehicle.vehicle:GetMovementType() == "air"
				if (airKill) then
					g_gameRules:BuyItem(target, "rpg", true, true);
					CryMP.Msg.Chat:ToPlayer(channelId, "Free RPG awarded - take down that flying bastard!", self.Tag);
					target.airKilled = true;
				end]]
				self:Purchase(target, true, airKill); 
			end
		end,
			
		OnRevive = function(self, channelId, actor, vehicle, first)
			if (first) then
				self:Purchase(actor, true);
			end
		end,
		
		OnRadioMessage = function(self, actor, packId)
			local timer = self.Requests[actor.id];
			if (timer) then
				if (packId > 5) then
					CryMP.Msg.Chat:ToPlayer(actor.Info.Channel, "Invalid Pack ID ("..packId..") - Use Radio menu F5 and select 1 - 5", self.Tag);
					return true;
				end
				self:LoadPack(actor, packId);
				self.Requests[actor.id] = nil;
				return true;
			end
		end,
		
		OnStatusRequest = function(self, actorId)
			if (self.Requests[actorId]) then
				return true;
			end
		end,
		
	},
	
	OnInit = function(self)
		self.Data = {};
		require("Data_Equip");
		nCX.Log("Core", "Loaded Equipment Data for "..self.Count.." players.");
	end,
	
	OnShutdown = function(self, restart)
		self:Write();
		if (not restart) then
			return {"Buffer"};
		end
	end,
	
	OnTick = function(self, players)
		for actorId, timer in pairs(self.Requests) do
			if (timer == 0) then
				self.Requests[actorId] = nil;
				nCX.SendTextMessage(0, "Pack selector timed out...", nCX.GetChannelId(actorId));
				if (nCX.Count(self.Requests) == 0) then
					self:SetTick(false);
					break;
				end			
			else
				nCX.SendTextMessage(0, self.Request_Msg:format(math:zero(timer)), nCX.GetChannelId(actorId));
				self.Requests[actorId] = self.Requests[actorId] - 1;
			end
		end
	end,
	
	RequestPack = function(self, actor)
		if (not self:CanRequest(actor.id)) then
			return false, "do current request first";
		end
		if (nCX.Count(self.Requests) == 0) then
			self:SetTick(1);
		end
		self.Requests[actor.id] = 15;
		nCX.SendTextMessage(0, self.Request_Msg:format("--"), actor.Info.Channel);
		return true;
	end,
	
	LoadPack = function(self, actor, packId)
		if (nCX.Count(self.Requests) == 0) then
			self:SetTick(false);
		end
		local profileId = actor.Info.ID;
		local data = self:GetData(profileId, true, true);
		data.equip = self.Packs[packId].Equip;
		if (data.equip) then
			local name = self.Packs[packId].Name;
			actor.inventory:Destroy();
			nCX.SendTextMessage(0, "Loading Equipment "..name.."...", actor.Info.Channel);
			CryMP:SetTimer(1, function()
				g_gameRules:EquipPlayer(actor);
				self:Purchase(actor, true);
				if (packId == 5) then
					self:SendInfo(actor, "EQUIP:PACK [ default ] ::: LOADED! Open console with [^] or [~]");
				else
					local cost = self:GetWeaponPackPrice(data.equip);
					self:SendInfo(actor, "EQUIP:PACK [ "..name.." ] ::: LOADED!"..(cost > 0 and " COST: "..cost.." pp" or ""));
				end
				nCX.SendTextMessage(0, "", actor.Info.Channel);
			end);
		end		
	end,
	
	Add = function(self, name, profileId, primary, secondary, tool, explosives)
		self.Data[profileId] = {
			name = name,
			equip = {
				primary, 
				secondary, 
				explosives, 
				tool,
			},
		};
		self.Count = (self.Count or 0) + 1;
	end,
	
	GetData = function(self, profileId, register, fullData)
		local data = self.Data[profileId];
		if (register and (not data or type(data.equip[3]) ~= "table")) then
			local name;
			local actor = nCX.GetPlayerByProfileId(profileId);
			if (actor) then
				name = CryMP.Ent:CheckName(actor:GetName());
			end
			self.Data[profileId] = {
				name = name or "N/A",
			};
			data = self.Data[profileId];
		end
		if (data and (data.equip or fullData)) then
			return fullData and data or data.equip;
		end
		if (register) then
			data.equip = self.Packs[5].Equip;
		end
		return not fullData and self.Packs[5].Equip;			
	end,
		    	
	Purchase = function(self, actor, free, airKill)
		local actorId = actor.id
		local data = self:GetData(actor.Info.ID);
		if (data) then
			local info = {};
			local cart = {};
			for i, itemName in pairs(data) do
				if (type(itemName) == "table") then
					for itemName, amount in pairs(itemName) do
						local rpg = (itemName == "rpg")
						for i = 1, amount do
							if (not rpg or (rpg and not airKill)) then 
								local enough = free or (g_gameRules:GetPrice(itemName) <= g_gameRules:GetPlayerPP(actorId));
								if (enough) then
									g_gameRules:BuyItem(actor, itemName, true--[[free]], true);
								else
									if (amount > 1) then
										itemName = (amount - (i - 1)).."x "..itemName;
									end
									info[#info+1] = itemName;
									break;
								end
							end
						end
					end
				else
					local price = g_gameRules:GetPrice(itemName);
					local enough = free or (price <= g_gameRules:GetPlayerPP(actorId));
					if (not enough and (i ~= 1 or price > 175)) then  --award the primary weapon for free if not enough pp
						info[#info+1] = itemName;
					else
						cart[(4 - i + 1)] = itemName;  --primary weapon last, secondary on 3. etc
					end
				end
			end	
			for i = 1, 4, 1 do
				local itemName = cart[i];
				if (itemName) then
					g_gameRules:BuyItem(actor, itemName, true, true);
					--if (itemName == 'pistol' or itemName == 'ay69') then
					--	g_gameRules:BuyItem(actor, itemName, true, true);
					--end 
				end
			end
			if (not free) then
				local noPP;
				for i, msg in pairs(info) do
					noPP = (noPP or "")..msg.." : ";
					if (i > 5) then
						break;
					end
				end
				if (noPP) then
					local pp = g_gameRules:GetPlayerPP(actorId);
					CryMP.Msg.Chat:ToPlayer(actor.Info.Channel, "Your Prestige is insufficient for ( "..noPP:sub(1, -3)..")", self.Tag);
				end
			end
		else
			local default = (self.Packs[5] and self.Packs[5].Equip and self.Packs[5].Equip[1]) or "smg";
			g_gameRules:BuyItem(actor, default, true, true);
			--g_gameRules:BuyItem(actor, "explosivegrenade", true, true);
		end
		--local msg = "HUD.BattleLogEvent(eBLE_Information,'Custom Equipment loaded');";
		--g_gameRules.onClient:ClWorkComplete(actor.Info.Channel, actor.id, "EX:"..msg);
	end,
	
	CheckInput = function(self, actor, class, weapon)
		local supported = {
			["primary"] = 1,
			["secondary"] = 2,
			["explosives"] = 3,
			["tool"] = 4,
		};
		local id, className;
		local n = tonumber(class);
		for c, v in pairs(supported) do
			if (n and n == v) or (c:find(class)) then
				id = v;
				className = c:sub(1, 1):upper()..c:sub(2, #c);
				break;
			end
		end
		local channelId = actor.Info.Channel;
		if (not id) then
			CryMP.Msg.Chat:ToPlayer(channelId, "Class '"..class.."' not recognized. Use index 1-4 or [ primary : secondary : explosives : tool ]", self.Tag);
			return false, "invalid class"
		elseif (not weapon) then
			CryMP.Msg.Chat:ToPlayer(channelId, "Class '"..className.."' chosen, but you need to specify a weapon!", self.Tag);
			return false, "specify a weapon"
		end
		local converter = {
			[3] = 1,
			[4] = 2,
		};
		local name = self:GetName(weapon, converter[id])
		if (not name and not weapon:find("del")) then
			CryMP.Msg.Chat:ToPlayer(channelId, className.." '"..weapon.."' not recognized. Use name or index number in console!", self.Tag);
			return false, "weapon not recognized"
		end
		return id, name or weapon, className;
	end,		
		
	Change = function(self, actor, class, input, count)
		if (not actor) then
			return;
		elseif (not class) then
			self:SendInfo(actor);
			return true;
		end
		local channelId = actor.Info.Channel;
		class = class:lower();
		if (class:find("del") or class == "reset") then
			self:Reset(actor.Info.ID);
			self:SendInfo(actor, "Equipment Settings successfully reset...");
			return true;
		end
		local id, weapon, className = self:CheckInput(actor, class, input);
		if (not id) then
			return false, nil, weapon;
		end
		local ok, msg, err = self:ProcessEquip(actor, id, className, input, weapon, count);
		if (ok and not msg) then
			local count = tonumber(count);
			if (count and count > 0) then
				CryMP.Msg.Chat:ToPlayer(channelId, count.."x '"..weapon.."' successfully set for "..className.." class!", self.Tag);
			else
				CryMP.Msg.Chat:ToPlayer(channelId, "'"..weapon.."' successfully added to "..className.." class!", self.Tag);
			end
		end
		self:SendInfo(actor);
		return ok, msg, err
	end,
		
	ProcessEquip = function(self, actor, id, className, input, weapon, count)	
		local profileId = actor.Info.ID;
		local data = self:GetData(profileId, true);
		local currLevel = actor:GetLevel();
		local switch = {
			[1] = 2,
			[2] = 1,
		};
		if (input:find("del") or input == "reset") then
			if (id == 3) then
				data[id] = {
					["explosivegrenade"]=1,
				};
				return true, className.." slot reset...";
			else
				data[id] = nil;
			end
			return true, className.." slot deleted...";
		elseif (id == 3) then
			local ammo = data[3];
			local capacity = self:GetCapacity(actor, weapon);
			local pass, required = self:LevelRequirements(currLevel, weapon);
			if (not pass and (not count or tonumber(count) ~= 0)) then			
				if (capacity > 1 and ammo[weapon] == 1) then
					return false, "Multiple '"..weapon.."' unlocked at Level "..required.." (Your Level: "..currLevel..")", "requires level "..required
				else
					return false, "'"..weapon.."' requires Level "..required.." (Your Level: "..currLevel..")", "requires level "..required
				end
			end
			if (count) then
				count = tonumber(count);
				if (not count) then
					return false, "To set capacity, use !equip explosives "..weapon.." 0-"..capacity, "invalid capacity input"
				end
				if (count > capacity) then
					return false, "Max "..capacity.." "..weapon.."(s) permitted!", "max capacity exceeded"
				else
					ammo[weapon] = count;	
					if (count == 0) then
						return true, className.." '"..weapon.."' emptied..."; 
					end
				end
			elseif (ammo[weapon] ~= capacity) then
				ammo[weapon] = (ammo[weapon] or 0) + 1; 
			else
				ammo[weapon] = nil;
				return true, className.." '"..weapon.."' emptied! Set count by typing: !equip explo "..weapon.." 0-"..capacity;
			end
		else
			local pass, required = self:LevelRequirements(currLevel, weapon);
			if (not pass) then
				return false, "'"..weapon.."' requires Level "..required.." (Your Level: "..currLevel..")", "requires level "..required
			end
			if (data[id] == weapon) then
				data[id] = nil;
				return true, "'"..weapon.."' removed from "..className.." slot...";
			else
				local previous = data[id];
				data[id] = weapon;
				local move = switch[id];
				if (move) then
					if (data[move] == weapon) then
						data[move] = nil;
						local o = {
							[1] = "Secondary",
							[2] = "Primary",
						};
						return true, "'"..weapon.."' moved to "..className.." slot ("..o[id].." slot now empty)"; 
					end
				end
				if (previous) then
					return true, "'"..previous.."' replaced with '"..weapon.."' for "..className.." class!";
				end
			end
		end
		return true;
	end, 
	
	GetName = function(self, input, mode)
		if (not input) then
			return;
		end
		local mode = mode or 0;
		local c={[0]="weapon",[1]="explosives",[2]="tool",};
		local number = tonumber(input);
		if (number) then
			input = math.abs(math.floor(number));
		else
			input = input:lower();
		end
		local tbl = {"scar","fy71","smg","shotgun","dsg1","gauss","minigun","moac","pistol",--[["ay69",]]};
		local rpl = {["scar"] = "macs",};
		if (mode == 1) then
			tbl = {"flashbang","smokegrenade","frag","empgrenade","c4","mine","claymore","rpg",}; 
			rpl = {["frag"] = "explosivegrenade", ["mine"] = "avmine",};
		elseif (mode == 2) then
			tbl = {"nvision","lockkit","repairkit","radarkit",}; 
			rpl = {};
		end
		if (input) then
			local item = tbl[input];			
			if (not item) then
				for i, v in pairs(tbl) do
					if (v:find(input)) then  -- partial name support
						v = rpl[v] or v;
						return v;
					end
				end
				for s, v in pairs(rpl) do
					if (v:find(input)) then  -- partial name support #2
						return v;
					end
				end
				return false, "Invalid id '"..input.."' : check accepted "..c[mode].." ids in your console";
			end
			return rpl[item] or item;
		else
			return false, "Invalid id : check accepted "..c[mode].." ids in your console";
		end
	end,
		
	GetWeaponPackPrice = function(self, e)
		local price=0;
		for i, itemName in pairs(e or {}) do
			if (type(itemName) == "table") then
				for itemName, count in pairs(itemName) do
					price = price + g_gameRules:GetPrice(itemName) * count;
				end
			else
				price = price + g_gameRules:GetPrice(itemName);
			end
		end
		return price;
	end,

	GetCapacity = function(self, actor, itemName)
		local def = g_gameRules:GetItemDef(itemName);
		if (def) then
			local capacity = actor.inventory:GetAmmoCapacity(def.buyammo or itemName);
			return math.max(1, capacity)
		end
		return 0;
	end,
	
	LevelRequirements = function(self, level, weapon)
	    if not (level or weapon) then
		    return true;
		end
		for lvl, wp in pairs(self.Unlocks) do
			if (weapon == wp) then
				return level >= lvl, lvl;
			end
		end
		return true;
	end,

	OnLevelAdvanced = function(self, actor, level)
		local itemName = self.Unlocks[level];
		if (itemName) then
			local def = g_gameRules:GetItemDef(itemName);
			if (def) then
				local name = actor:GetName();
				local class = def.class or itemName;
				self:Log("Item '"..class.."' unlocked for "..name.." (Level $8"..level.."$9)");
				local next, lvl = self:GetNextUnlock(level);
				if (next) then
					local def = g_gameRules:GetItemDef(next);
					local class = def.class or next;
					CryMP:SetTimer(1, function()
						CryMP.Msg.Chat:ToPlayer(actor.Info.Channel, "Next Unlock: '"..class.."' at Level "..lvl, self.Tag);
					end);
				end
				return class;
			end
		end
	end,
	
	GetNextUnlock = function(self, level)
		local v;
		for lvl, wp in pairs(self.Unlocks) do
			if (level < lvl) then
				if (not v) then	
					v = lvl;
				elseif (lvl < v) then
					v = lvl;
				end				
			end
		end	
		if (v) then
			return self.Unlocks[v], v;
		end
	end,
	
	Reset = function(self, profileId)
		self.Data[profileId] = nil;
    end,

	WeaponInfo = function(self, actor)
		local channelId, profileId = actor.Info.Channel, actor.Info.ID;
	    local data = self:GetData(profileId, true);	
		local p={{"","(empty)"},{"","(empty)"},{"","(empty)"},{"","(empty)"},};
		local empty = string.rep(" ", 7);
		local inter = "$5|$9";
		local level = actor:GetLevel();
		local order = {
			{"macs", "fy71", "smg", "shotgun", "dsg1", "gauss", "minigun", "moac", "pistol",},
			{"macs", "fy71", "smg", "shotgun", "dsg1", "gauss", "minigun", "moac", "pistol",},
		    {"flashbang","smokegrenade","explosivegrenade","empgrenade","c4","avmine","claymore","rpg",},
		    {"nvision", "lockkit", "repairkit", "radarkit",},
		};
		local info={};
		
		for i = 1, #order do
			local class = data[i] or "";
			if (type(class) == "table") then
				local temp, count = {},{};
				local convert = {"Flash","Smoke","Frag","EMP","C4","Mine","Claymore","RPG",};
				for index, explosive in pairs(order[i]) do
					local color;
					local displayName = convert[index];
					local pass = self:LevelRequirements(level, explosive);
					if (not pass) then
						color = "$4";
					elseif (class[explosive] and class[explosive] > 0) then
						color = "$6";
						p[i][1] = color; 
						p[i][2] = empty;
					end
					local add = {[4] = 1, [7] = 1,};
					local slots = 8 + (add[index] or 0);
					temp[#temp + 1] = (color or "$9")..string:mspace(slots, displayName);
					local display = "$9($5"..(class[explosive] or 0).."$9/$5"..self:GetCapacity(actor, explosive).."$9)";
					count[#count + 1] = string:mspace(slots, display);
				end
				info[i] = {};
				info[i][1] = table.concat(temp, inter)
				info[i][2] = table.concat(count, inter);
			else
				local temp = {};
				local active = { -- #2 is Displayname!
					["macs"]="SCAR",["fy71"]="FY71",["smg"]="SMG",["shotgun"]="Shotgun",["dsg1"]="DSG1",["gauss"]="Gauss",["minigun"]="Minigun",["moac"]="MOAC",["pistol"]="Pistol",
				};
				if (i == 4) then
					active = {
						["nvision"]="Nvision",["lockkit"]="Lockpick",["repairkit"]="Repair",["radarkit"]="Radar",
					};
				end
				for index, weapon in pairs(order[i]) do
					local pass = self:LevelRequirements(level, weapon);
					local add = {[4] = 1, [7] = 1,};
					if (i == 4) then
						add[4] = nil;
					end
					local slots = 8 + (add[index] or 0);
					local color;
					if (weapon == class) then
						color = "$6";
						p[i][1] = color; 
						p[i][2] = empty;
					elseif (not pass) then
						color = "$4";
					end
					local item = string:mspace(slots, active[weapon]);
					temp[#temp + 1] = (color or "$9")..item.."$9";
					
				end
				info[i] = table.concat(temp, inter);
			end
		end
		local pp = g_gameRules:GetPlayerPP(actor.id);
		local cp = g_gameRules:GetPlayerCP(actor.id);
		local price = self:GetWeaponPackPrice(data);
		local msg = "Your pp: $1"..pp;
		if (pp < price) then
		    for i=1, 8 do
				local rankPP = g_gameRules:GetRankPP(i);
			    if (rankPP >= price and i > cp) then 
					msg = "Available at $1"..g_gameRules:GetRankName(i, false, true).." $9rank";
					break;
				end
			end
		end
		local next, lvl = self:GetNextUnlock(level);
		if (next) then
			local def = g_gameRules:GetItemDef(next);
			next = "$9Next Unlock: '$5"..((def and def.class) or next).."$9' at Level "..lvl;
		end
		local r = "$5                 |        |        |        |	     |        |        |         |        |        |        |";
		local header = "$5[$9 INDEX $5]===========[$9 1 $5]===[$9 2 $5]=====[$9 3 $5]====[$9 4 $5]====[$9 5 $5]=====[$9 6 $5]====[$9 7 $5]=====[$9 8 $5]===[$9 9 $5]====[$9 10 $5]=======";
		return  {
			"$9",
			header,
			r,
			r,
			r,
			r,
			"$5[$91$5]$9 "..p[1][1].."PRIMARY$5:     $5|$5"..info[1].."$5|",
			"$9    "..p[1][2].."$5      |        |        |        |	     |        |        |         |        |        |        |";
			"$5[$92$5]$9 "..p[2][1].."SECONDARY$5:   $5|$5"..info[2].."$5|",
			"$9    "..p[2][2].."$5      |        |        |        |	     |        |        |         |        |        |        |";
			"$5[$93$5]$9 "..p[3][1].."EXPLOSIVES$5:  $5|$5"..info[3][1].."$5|        |        |",
			"$9    "..p[3][2].."$5      $5|$5"..info[3][2].."$5|        |        |        |",
			r,
			"$5[$94$5]$9 "..p[4][1].."EQUIP$5:       $5|$5"..info[4].." $5|        |        |         |        |        |        |",
			"$9    "..p[4][2].."$5      |        |        |        |	     |        |        |         |        |        |        |";
			r,
			r,
			r,
			r,
			header,
			"$5",
			"$5             "..string:rspace(50, (next or "")).." $9Equip Cost: $4"..price.." $9pp - "..msg,
		};
	end,

	SendInfo = function(self, actor, msg)
		local channelId = actor.Info.Channel;
		local info = self:WeaponInfo(actor);
		for i, msg in pairs(info) do
			CryMP.Msg.Console:ToPlayer(channelId, msg);
		end
		if (msg) then
			CryMP.Msg.Chat:ToPlayer(channelId, msg, self.Tag);
		end
	end,
	
	ParseToString = function(self, data, profileId)
		local pri = "nil, ";
		local sec = "nil, ";
		local eqp = "nil";
		local e = data.equip;
		if (e[1]) then
			pri = "'"..e[1].."', ";
		end
		if (e[2]) then
			sec = "'"..e[2].."', ";
		end
		if (e[4]) then
			eqp = "'"..e[4].."'";
		end
		local line =  "CryMP.Equip:Add('"..data.name.."', '"..profileId.."', "..pri..sec..eqp;
		if (e[3]) then
			local xpl = ", {";
			for name, count in pairs(e[3]) do
				xpl = xpl..'["'..name..'"] = '..count..', ';
			end
			line = line..xpl.."}";
		end
		line = line..");\n";
		return line;
	end,
	
	Write = function(self)
		FileHnd = io.open(CryMP.Paths.ServerData.."Data_Equip.lua", "w+")
		for profileId, data in pairs(self.Data) do
			if (data.equip) then
				local line = self:ParseToString(data, profileId);
				FileHnd:write(line);
			end
		end
		FileHnd:close();
	end,
	
};
