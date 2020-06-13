HQMods = {
	---------------------------
	--		Config
	---------------------------
	PowerFallback = 30,

	Server = {
		
		OnHQHit = function(self, hq, hit)
			local damage = self:CalculateDamage(hit.damage);
			local health = (hq:GetHealth() - damage);
			local destroyed = (health <= 0);
			local dmgus, dmgnk = self:GetInfo();
			local teamId = nCX.GetTeam(hit.shooter.id);
			local previousDmg = teamId == 1 and dmgus or dmgnk;
			hq:SetHealth(health);
			if (not destroyed) then
				local team = teamId == 1 and "NK" or "US";
				local var = 0.25;
				--System.SetCVar("time_scale", var);
				local energy = g_gameRules:GetTeamPower(teamId);
				local newEnergy = math.floor(energy-self.PowerFallback);
				if (newEnergy <= 0) then
					newEnergy = 0;
				end
				for i=1, 4 do
					CryMP:SetTimer(i, function()
						var = math.min(var * i, 1);
						--System.SetCVar("time_scale", var);
						if (i == 2) then
							CryMP.Msg.Error:ToAll("[ HQ:HIT ] "..team.." ENERGY > > > dropping to "..newEnergy.."%");
							self:Log("Energy of Team "..team.." dropping to $5"..newEnergy.."$9%");
						elseif (i == 3) then
							g_gameRules:SetTeamPower(teamId, newEnergy);
						end
					end);
				end
				local display = "BASE - [ "..team.."-HQ : DAMAGE %s ] - STRIKE";
				nCX.SendTextMessage(0, display:format(tostring(previousDmg).."%"), 0);
				local dmgus, dmgnk = self:GetInfo();
				local newDmg = teamId == 1 and dmgus or dmgnk;
				nCX.SendQueueMessage(0, display:format(tostring(newDmg).."%"), 30, 0);
				--CryMP.Msg.Flash:ToAll({80, "#99FF33", "#1C1C1C",}, tostring(newDmg).."%", display);
				if (hit.shooter and hit.shooter.actor) then
					g_gameRules:AwardPPCount(hit.shooter.id, 500);
				end
				if (previousDmg == 0) then
					self:Log(team.." HQ damage to $4"..newDmg.."$9%");
				else
					self:Log(team.." HQ damage from $4"..previousDmg.." $9to $4"..newDmg.."$9%");
				end
			end
			return destroyed, {hq, hit};
		end,
	
		OnKill = function(self, hit, shooter, target)
			if (hit.typeId == 10) then
				if (not hit.shooter or not target.Info or hit.server or hit.self) then
					return;
				end
				hit.shooter.TAC_BASE_KILLS = (hit.shooter.TAC_BASE_KILLS or 0) + 1;
				if (not hit.shooter.TAC_BASE_KILLS_INIT or _time - hit.shooter.TAC_BASE_KILLS_INIT > 5) then 
					local shooterId = hit.shooter.id;
					CryMP:SetTimer(1, function()
						local sh = nCX.GetPlayer(shooterId);
						if (sh) then
							local kills = sh.TAC_BASE_KILLS;
							if (kills and kills > 0) then
								local name = sh:GetName();
								local otherId = nCX.GetTeam(target.id);
								local team = CryMP.Ent:GetTeamName(otherId):upper();
								self:Log("Player "..name.." nuked $7"..kills.." $9"..team.." "..(kills > 1 and "soldiers" or "soldier").." in their Base Zone");
								CryMP.Msg.Chat:ToAll("NUKER - ( "..name.." ) BLASTS > > > "..math:zero(kills).." "..(kills > 1 and "VICTIMS" or "VICTIM").." in "..team.." : ZONE");
							end
							sh.TAC_BASE_KILLS = nil;
						end
					end);
					hit.shooter.TAC_BASE_KILLS_INIT = _time;
				end
			end
		end,				
	
	},

	OnShutdown = function(self, restart)
		if (System.GetCVar("time_scale") ~= 1) then
			System.SetCVar("time_scale", 1);
		end
	end,
	
	CalculateDamage = function(self, dmg)
		--[[
			hq.props.nHitPoints set to 5999 now
			no. of hq hits needed to win is set with this multiplier
			*0.125 => 8 hits needed
			*1 => 1 hit needed
		]]
		return dmg * 0.5;
	end;
		
	GetInfo = function(self, mode)
		local tbl = {{Damage = 0, Health = 100,}, {Damage = 0, Health = 100,},};
		for teamId, hq in pairs(g_gameRules.hqs or {}) do
			local health = math.ceil((hq:GetHealth() * 100) / hq.Properties.nHitPoints);
			tbl[teamId].Health = health;
			tbl[teamId].Damage = 100 - health;
		end
		if (mode=="health") then
			return tbl[2].Health, tbl[1].Health;
		else
			return tbl[2].Damage, tbl[1].Damage;
		end
	end;
	
};
