HitDamage = {

	Tick = 10,

	DamageTable = {
		["Unarmed"]			 = 0.6,
		["LowBudget"] 		 = 0.6,
		["Repair"] 			 = 0.6,
	},	
		
	Server = {
		--[[
		OnKill = function(self, hit, shooter, target)
			if (shooter.Info and target.Info and shooter.killcontrol or target.killcontrol) then
				self:KillControl(hit, shooter, target);
			end
		end,
		]]
		
		PreHit = function(self, hit, shooter, target, vehicle)
			if (not hit.self and hit.explosion and g_gameRules.class == "PowerStruggle") then
				local weapon = hit.weaponId and System.GetEntity(hit.weaponId);
				local data = self.Config and self.Config[(hit.weapon and hit.weapon.class) or ""];
				if (data) then
					local vehicleId, time = target.actor:GetLastVehicle();
					if (not vehicleId or time > 3 and not target:IsOnVehicle()) then
						if (data.Effect) then
							nCX.ForbiddenAreaWarning(true, 0, shooter.id);
						end
						if (data.Shooter) then
							nCX.SendTextMessage(0, data.Shooter, shooter.Info.Channel);
						end
						if (data.Target) then
							nCX.SendTextMessage(0, data.Target, target.Info.Channel);
						end
						if (data.Mult) then
							hit.damage = hit.damage * data.Mult;
							return false, {hit, target};
						end
						return true;
					end
				end
			end
			if (hit.self and hit.typeId == 8 and not nCX.ProMode) then
				hit.damage = hit.damage * 0;
				return false, {hit, target};
			end
		end,
		
		
		OnHit = function(self, hit, shooter, target, vehicle)
			if (shooter.Info and target.Info and (shooter.hitcontrol or target.hitcontrol) and not hit.self) then
				if (not target:IsOnVehicle()) then
					self:PlayerControl(hit, shooter, target);
				end
			end
		end,
		
		OnVehicleHit = function(self, hit, vehicle, destroyed, damage)
			local shooter = hit.shooter;	
			if (shooter and shooter.hitcontrol and shooter.Info) then
				self:VehicleControl(hit, shooter, vehicle);
			end
		end,
		
	},
	---------------------------
	--		OnTick		
	---------------------------	
	OnTick = function(self)
		for i, clay in pairs(System.GetEntitiesByClass("claymoreexplosive") or {}) do
			clay:AddImpulse(-1, clay:GetCenterOfMassPos(), g_Vectors.up, 600, 1);
			--nCX.ParticleManager("misc.runway_light.flash_red", 0.2, clay:GetPos(), g_Vectors.up, 0);
		end
		for i, clay in pairs(System.GetEntitiesByClass("avexplosive") or {}) do
			clay:AddImpulse(-1, clay:GetCenterOfMassPos(), g_Vectors.up, 200, 1);
			--nCX.ParticleManager("misc.runway_light.flash_red", 0.2, clay:GetPos(), g_Vectors.up, 0);
		end
	end,
	
	PlayerControl = function(self, hit, shooter, target)
		local convert = {[0] = "Speed",[1] = "Power",[2] = "Cloak",[3] = "Armor",};
		local s_Health = shooter.actor:GetHealth();
		local t_Health = target.actor:GetHealth();
		local s_Mode = convert[shooter.actor:GetNanoSuitMode()];
		local t_Mode = convert[target.actor:GetNanoSuitMode()];
		local s_Energy = math.floor(shooter.actor:GetNanoSuitEnergy() / 2);
		local t_Energy = math.floor(target.actor:GetNanoSuitEnergy() / 2);
		local s_Suit = s_Mode.." $1"..string:lspace(3,s_Energy).."$9";
		local t_Suit = t_Mode.." $1"..string:lspace(3,t_Energy).."$9";
		local weaponClass = hit.weapon and hit.weapon.class or "";
		local weaponType = weaponClass;
		if (hit.explosion) then
			weaponType = hit.type~="" and hit.type or (hit.explosion and "explosion" or "other");
		else
			weaponType = string:rspace(11, weaponType);
		end
		local s_Name = shooter:GetName();
		local t_Name = target:GetName()
		local channelId = shooter.Info.Channel;
		local deadly = t_Health < 1;
		local accuracy = hit.accuracy and math.floor(hit.accuracy);
		local damage = math.floor(hit.damage);
		local line = (" "):rep(112);
		if (shooter.hitcontrol) then
			if (deadly) then
				local acc = (accuracy and accuracy ~= 0) and "($7"..string:lspace(3, accuracy).."$9% Accuracy)" or "";
				local shooterMsg = ("$9 (%s : Hp $1%s$9) $1==> $9%s (%s : $7Deadly$9) : $4%s $9: %s%s %s"):format(
					s_Suit,
					string:lspace(3, s_Health),
					string:lspace(15, t_Name),
					t_Suit,
					string:lspace(5, damage),
					weaponType,
					(hit.material_type and "("..string:rspace(10, hit.material_type..")") or ""),
					acc
				);
				local flash_amount = 16;
				local remove = false;
				local mode = "HEALTH  ";
				if (not accuracy or accuracy == 0) then
					t_Health = "TOAST";
				else
					flash_amount = flash_amount + 1;
					t_Health = accuracy;
					mode = "ACCURACY"
					if (accuracy == 100) then
						t_Health = "PERFECT";
						flash_amount = flash_amount + 6;
					else
						remove = false;
					end
				end				
				CryMP.Msg.Flash:ToPlayer(channelId, {flash_amount, "#e7e7e7", "#973c3c", remove}, t_Health, "<font size=\"24\"><b><font color=\"#aaaaaa\">SUIT</font><font color=\"#aaaaaa\"> ::: ( </font><font color=\"#cdcc59\">"..t_Mode:upper().."</font><font color=\"#aaaaaa\"> )                                                                                         </font><font color=\"#aaaaaa\">( </font><font color=\"#a03c3c\">%s</font><font color=\"#7d7d7d\"> ) ::: <font color=\"#aaaaaa\">"..mode.."</font></font></b></font>");
				CryMP.Msg.Console:ToPlayer(channelId, shooterMsg);
				CryMP.Msg.Console:ToPlayer(channelId, "$9"..line);
			else
				local shooterMsg = ("$9 (%s : Hp $1%s$9) $1==> $9%s (%s : Hp $1%s$9) : $4%s $9: %s%s"):format(
					s_Suit,
					string:lspace(3, s_Health),
					string:lspace(15, t_Name),
					t_Suit,
					string:lspace(3, t_Health),
					string:lspace(5, damage),
					weaponType,
					(hit.material_type and "("..hit.material_type..")" or "")
				);
				CryMP.Msg.Console:ToPlayer(channelId, shooterMsg);
				local display = "<font size=\"24\"><b><font color=\"#aaaaaa\">SUIT</font><font color=\"#aaaaaa\"> ::: ( </font><font color=\"#cdcc59\">"..t_Mode:upper().."</font><font color=\"#aaaaaa\"> )                                                                                        </font><font color=\"#aaaaaa\">( </font><font color=\"#a03c3c\">"..string:lspace(3, t_Health).."</font><font color=\"#7d7d7d\"> ) ::: <font color=\"#aaaaaa\">HEALTH</font></font></b></font>";
				nCX.SendTextMessage(5, display, channelId);
			end
		end
		if (target.hitcontrol) then
			local targetMsg;
			if (deadly) then
				accuracy = (accuracy and accuracy ~= 0) and "($4"..string:lspace(3, accuracy).."$9% Accuracy)" or "";
				targetMsg = ("$9 (%s : $4Deadly$9) <== $4%s $9(%s : Hp $1%s$9) : $4%s $9: %s%s %s"):format(
					t_Suit,
					string:lspace(15, s_Name),
					s_Suit,
					string:lspace(3, s_Health),
					string:lspace(5, math.floor(damage)),
					weaponType,
					(hit.material_type and "("..string:rspace(10, hit.material_type..")") or ""),
					accuracy
				);			
			else
				targetMsg = ("$9 (%s : Hp $1%s$9) <== $4%s $9(%s : Hp $1%s$9) : $4%s $9: %s%s"):format(
					t_Suit,
					string:lspace(3, t_Health),
					string:lspace(15, s_Name),
					s_Suit,
					string:lspace(3, s_Health),
					string:lspace(5, damage),
					weaponType,
					(hit.material_type and "("..hit.material_type..")" or "")
				);
			end
			CryMP.Msg.Console:ToPlayer(target.Info.Channel, targetMsg);
			if (deadly) then
				CryMP.Msg.Console:ToPlayer(target.Info.Channel, "$9"..line);
			end
		end
	end,

	VehicleControl = function(self, hit, shooter, vehicle)
		if (hit.typeId~=9 and not hit.self) then
			local type = CryMP.Ent:GetVehicleName(vehicle.class):upper();
			local damage = math.floor((vehicle.vehicle:GetRepairableDamage() * 100));
			local hull = ("|"):rep(damage * 0.5);
			local channelId = shooter.Info.Channel;
			if (damage >= 100) then
				CryMP.Msg.Flash:ToPlayer(channelId, {14, "#e7e7e7", "#973c3c", true,}, "TOAST", "<font size=\"24\"><b><font color=\"#EEEEEE\">VEHICLE</font><font color=\"#7d7d7d\"> - ( </font><font color=\"#973c3c\">"..type.."</font><font color=\"#7d7d7d\"> )</font><font size=\"14\"><font color=\"#ff0000\">"..(" "):rep(100).."</font></font><font color=\"#7d7d7d\">( </font><font color=\"#973c3c\">%s</font><font color=\"#7d7d7d\"> ) - <font color=\"#EEEEEE\">DAMAGE</font></font></b></font>");
				return;
			end
			local display = "<font size=\"24\"><b><font color=\"#EEEEEE\">VEHICLE</font><font color=\"#7d7d7d\"> - ( </font><font color=\"#973c3c\">"..type.."</font><font color=\"#7d7d7d\"> )</font><font size=\"14\"><font color=\"#ff0000\">"..string:lspace(50,hull)..string:rspace(50,hull).."</font></font><font color=\"#7d7d7d\">( </font><font color=\"#973c3c\">"..string:lspace(3,damage).."</font><font color=\"#7d7d7d\"> ) - <font color=\"#EEEEEE\">DAMAGE</font></font></b></font>";
			nCX.SendTextMessage(5, display, channelId);
		end
	end,
	
	--[[
	KillControl = function(self, hit, shooter, target)
		if (not hit.self and not nCX.IsSameTeam(shooter.id, target.id)) then
			local channelId = shooter.Info.Channel;
			local tchannelId = target.Info.Channel;
			local health = shooter.actor:GetHealth();
			local energy = math.floor(shooter.actor:GetNanoSuitEnergy() / 2);
			local convert = {[0] = "Speed";[1] = "Strength";[2] = "Cloak";[3] = "Armor";};
			local suitmode = convert[shooter.actor:GetNanoSuitMode()];
			local distance = math.floor(target:GetDistance(shooter.id));
			local weapon = shooter.inventory:GetCurrentItem();
			local hittype = nCX.GetHitType(hit.typeId);
			local hittype = hittype or (hit.explosion and "Explosion") or "N/A";
			local matName = hit.material_type and nCX.GetHitMaterialName(hit.materialId) or "Unknown";
			local weapon = (weapon and weapon.class) or "N/A";
			local health = health <= 20 and "$4"..health or health;
			local energy = energy <= 20 and "$4"..energy or energy;
			local header = "$9"..string.rep("-", 116);
			
			local targetMsg = string.format(CryMP:Tag().." $9Killer$5-[$7%s$9]$5-$9GPS$5-[$1%sm$9]$5-$9Suit$5-[$1%s$9]$5-$9Hp:Energy$9-[$5%s $9|$5%s $9]",
				string:mspace(22,shooter:GetName()),
				string:lspace(5,distance),
				string:mspace(24,suitmode),
				string:lspace(5,health),
				string:lspace(5,energy)
			);
			local shooterMsg = string.format(CryMP:Tag().." $9Target$5-[$7%s$9]$5-$9GPS$5-[$1%sm$9]$5-$9Suit$5-[$1%s$9]$5-$9Hp:Energy$9-[$5%s $9|$5%s $9]",
				string:mspace(22,target:GetName()),
				string:lspace(5,distance),
				string:mspace(24,suitmode),
				string:lspace(5,health),
				string:lspace(5,energy)
			);
			local secline = string.format(CryMP:Tag().." $9Weapon$5-[$4%s$9]$5-$9DMG$5-[$4%s$9]$5-$9Type$5-[$4%s$9]$5-$9Hit:Local$9-[$4%s$9]",
				string:mspace(22,weapon),
				string:lspace(6,hit.damage),
				string:mspace(24,hittype),
				string:mspace(13,matName)
			);
				
			if (target.killcontrol) then
				CryMP.Msg.Console:ToPlayer(tchannelId, header);
				CryMP.Msg.Console:ToPlayer(tchannelId, targetMsg);
				CryMP.Msg.Console:ToPlayer(tchannelId, secline);
				CryMP.Msg.Console:ToPlayer(tchannelId, header);
				nCX.SendTextMessage(0, "[-CryMP-] Kill-Control data received! Check your console", tchannelId);
			end
			if (shooter.killcontrol) then
				CryMP.Msg.Console:ToPlayer(channelId, header);
				CryMP.Msg.Console:ToPlayer(channelId, shooterMsg);
				CryMP.Msg.Console:ToPlayer(channelId, secline);
				CryMP.Msg.Console:ToPlayer(channelId, header);
			end
		end
	end,
	
	]]
	
};
