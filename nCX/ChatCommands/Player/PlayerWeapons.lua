--===================================================================================
-- EQUIP

CryMP.ChatCommands:Add("pack", {
		InGame = true,
		Delay = 30,
		Info = "choose between 4 preset equipment classes",
		self = "Equip",
	},
	function(self, player, channelId)
		return self:RequestPack(player);
	end
);

--===================================================================================
-- EQUIP

CryMP.ChatCommands:Add("equip", {
		Args = {
			{"class", Optional = true, Output = {{"primary","The Primary class will spawn as your main weapon"},{"secondary","The Secondary class will be in your inventory"},{"explosives","Customize grenades, RPG etc with this one"},{"tool", "Add a tool-kit to your equipment"},{"reset", "$1RESET $9the Equipment"},},},
			{"weapon", Optional = true, Info = "Weapon by index $11-10 $19or partial names ($1DEL $9to remove)"},
		}, 
		Info = "change and view your equipment",
		OpenConsole = true,
		self = "Equip",
	}, 
	function(self, player, channelId, class, weapon, count)
		local success, msg, err = self:Change(player, class, weapon, count)
		if (msg and not success) then
			CryMP.Msg.Chat:ToPlayer(channelId, msg, 15);
		end
		return (success and -1) or success, err;
	end
);

--===================================================================================
-- MYEQUIP
CryMP.ChatCommands:Add("suite", {
		InGame = true,
		Access = 5,
		Info = "customize your spawn equip in the weapon suite",
		self = "Equip",
	}, 
	function(self, player, channelId)
		if (player:IsOnVehicle()) then
			return false, "leave your vehicle";
		end
		return self:GotoSuite(player);
	end
);

--===================================================================================
-- AMMO

CryMP.ChatCommands:Add("ammo", {
		Info = "reload your weapons for full effect",
		Delay = 90,
		Price = "N/A",
		InGame = true,
		Map = {"ps/(.*)"},
		BigMap = true,
	},
	function(self, player, channelId)
		if (player:IsBoxing()) then
			return false, "cannot use while boxing"
		elseif (player:IsDuelPlayer()) then
			return false, "cannot use while duel"
		end
		local buyMessage;
		local pp = g_gameRules:GetPlayerPP(player.id);
		local start_pp = pp;
		local vehicle = player.actor:GetLinkedVehicle();
		local p_v = vehicle and vehicle or player;
		local tmp = {};
		if (vehicle) then
			for i = 1, 2 do
				local seat = vehicle.Seats[i];
				if (seat) then
					local weaponCount = seat.seat:GetWeaponCount();
					for j = 1, weaponCount do
						tmp[#tmp + 1] = seat.seat:GetWeaponId(j);
					end
				end
			end
		else
			tmp = p_v.inventory:GetInventoryTable();
		end
		local pos = player:GetWorldPos();
		pos = CryMP.Library:CalcSpawnPos(player, 1.5);
		pos.z = pos.z - 0.5;
		for i, itemId in pairs(tmp or {}) do
			local item = System.GetEntity(itemId);
			if (item and item.weapon) then
				local type = item.weapon:GetAmmoType();
				if (type) then
					local capacity = p_v.inventory:GetAmmoCapacity(type);
					if (capacity > 0) then
						local clipSize = item.weapon:GetClipSize();
						local clipCount = item.weapon:GetAmmoCount();
						--if (item.weapon:GetClipSize() ~= -1) then
						--	item.weapon:Reload();
						--	System.LogAlways("Reloading $4"..item.class);
						--else
						--	System.LogAlways("won't reload "..item.class);
						--end
						local count = p_v.inventory:GetAmmoCount(type) or 0;
						local need = {clipSize - clipCount, capacity - count};
						if (need[1] + need[2] > 0) then
							local def = g_gameRules:GetItemDef(type);
							if (def) then	
								local costPerAmmo = def.price * 2;
								if (def.amount > 1) then
									costPerAmmo = costPerAmmo / def.amount;
								end
								local needTotal = need[1] + need[2];
								local canBuy = needTotal;
								local fullCost = (needTotal * costPerAmmo);
								local cancel = fullCost > pp;
								--System.LogAlways("CANCEL: fullCost "..fullCost.." - pp "..pp.." : needTotal "..needTotal.." * costPerAmmo "..costPerAmmo.." "..type);
								if (cancel) then
									canBuy = math.floor(pp / fullCost) * canBuy;
								end
								if (canBuy > 0) then
									local increaseClip = 0;
									if (clipSize > 0 and need[1] > 0) then
										increaseClip = math.min(canBuy, need[1]); 
										item.weapon:SetAmmoCount(type, clipCount + increaseClip)
										--System.LogAlways("ammo: increasing clip for "..item.class.." : clipcount "..clipCount.." + "..increaseClip.." (size "..clipSize..")");
									end
									local remaining = canBuy - increaseClip;
									if (p_v.vehicle) then
										p_v.vehicle:SetAmmoCount(type, count + remaining);
									else
										p_v.actor:SetInventoryAmmo(type, count + remaining, 3);	
									end
									local str = item.class.." (+ "..canBuy..")";
									if (not buyMessage) then
										buyMessage = str;
									else
										buyMessage = buyMessage.." : "..str;
									end
								end
								local cost = canBuy * costPerAmmo;
								pp = pp - cost;
								if (cancel) then
									if (buyMessage) then
										CryMP.Msg.Chat:ToPlayer(channelId, "BOUGHT:AMMO -[ "..buyMessage.." ]", 1);
									end
									--CryMP.Msg.Flash:ToPlayer(channelId, {50, "#d77676", "#ec2020",}, "INSUFFICIENT PRESTIGE", "<font size=\"32\"><b><font color=\"#b9b9b9\">*** </font> <font color=\"#843b3b\">UPGRADE [<font color=\"#d77676\">  %s  </font><font color=\"#843b3b\">] CANCELED</font> <font color=\"#b9b9b9\"> ***</font></b></font>");
									local totalPrice = start_pp - pp;
									g_gameRules:AwardPPCount(player.id, -totalPrice, nil, true);
									return false, "no more prestige left";
								end
							end
						end
					end
				end
			end
		end
		if (buyMessage) then
			local totalPrice = math.floor(start_pp - pp);
			--CryMP.Msg.Animated:ToPlayer(channelId, 1, "<b><font color=\"#b9b9b9\">*** </font> <font color=\"#843b3b\">SCAN [<font color=\"#d77676\"> COST : "..totalPrice.." PP </font><font color=\"#843b3b\">] FINISHED</font> <font color=\"#b9b9b9\"> ***</font></b>");
			nCX.ParticleManager("explosions.light.mine_light", 2, pos, g_Vectors.up, 0);
			CryMP.Msg.Chat:ToPlayer(channelId, "BOUGHT:AMMO -[ "..buyMessage.." ]");
			g_gameRules:AwardPPCount(player.id, -totalPrice, nil, true);
		else
			return false, "you do not need any ammo for your current equipment"
		end
		return true;
	end
);