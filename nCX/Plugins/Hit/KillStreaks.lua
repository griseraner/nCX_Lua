KillStreaks = {

	Buffer = {},
	
	Server = {
		--[[
		OnChangeSpectatorMode = function(self, player) 
			if (self:IsMostWanted(player.Info.Channel)) then
				self:MostWantedEnd(player, 2);
			end
		end,

		OnDisconnect = function(self, channelId, player)
			if (self:IsMostWanted(channelId)) then
				self:MostWantedEnd(player, 1);
			end
		end,
		]]
		
		OnKill = function(self, hit, shooter, target)
			if (not target.Info) then
				return;
			end
			self.Buffer[target.id] = nil;
			--if (self:IsMostWanted(target.Info.Channel)) then
			--	return self:MostWantedEnd(target, 3, hit);
			--else
			if (not shooter or not shooter.actor or hit.server or hit.self) then
				return;
			end
			local msg = self.Config.Messages;
			local ps = (g_gameRules.class == "PowerStruggle")
			if (not nCX.FirstBlood) then
				nCX.FirstBlood = true;
				local award = ps and "WIN 500-POINTS" or "GANGSTA-RAPPER";
				award = not nCX.ProMode and " ::: "..award.."!" or "";
				if (ps) then
					g_gameRules:AwardPPCount(shooter.id, 500);
				elseif (not nCX.ProMode) then
					local ckills = 5 + (nCX.GetSynchedEntityValue(shooter.id, 100) or 0);
					--nCX.SetSynchedEntityValue(shooter.id, 100, ckills);
					--CryAction.SendGameplayEvent(shooter.id, 9, "kills", ckills);  --scoreboard nigga
				end
				local teamId = nCX.GetTeam(shooter.id);
				local info = teamId ~= 0 and " for the "..CryMP.Ent:GetTeamName(teamId):upper().." team" or "";
				CryMP.Msg.Chat:ToAll("Player : "..shooter:GetName().." scored FIRST BLOOD"..info.."!"..award, self.Tag);
				return;
			end
			
			local name = shooter:GetName();
			local shooterVehicle = shooter.actor:GetLinkedVehicle();
			local channelId, tchannelId = shooter.Info.Channel, target.Info.Channel;
			
			--if (hit.typeId==7 and not shooter.hitcontrol) then
			--	local scroll = msg.Melee and msg.Melee[math.random(1, #msg.Melee)];
			--	local msg = "<font size=\"32\"><i><b><font color=\"#a2a2a2\">*** !!</font> <font color=\"#ea1e1e\">%s</font> <font color=\"#a2a2a2\">!! ***</font></b></i></font>";
			--	CryMP.Msg.Scroll:ToPlayer(channelId, {"#E9FFE9", false, 2}, scroll, msg);
			if (hit.headshot) then
				local distance = tonumber(("%.2f"):format(shooter:GetDistance(target.id)));
				if (distance > 150) then
					local bonuspoints = math.floor(distance);
					local weapon = hit.weapon and hit.weapon.class;
					if (weapon) then
						--CryMP.Msg.Flash:ToPlayer(channelId, {40, "#900000", "#00FF00", false, 1}, "HEADSHOT", "<i><b>".."<font color=\"#00FF00\"><font size=\"24\">BONUS <font color=\"#707070\">+</font> "..tostring(bonuspoints).."pp</font>  <font color=\"#707070\">(  %s  )  <font size=\"24\"><font color=\"#00FF00\">RANGE <font color=\"#707070\">=</font> "..distance.."m".."</font></b></i>");
						CryMP.Msg.Chat:ToAll(name.." made a Headshot from "..distance.."m range! Award: "..weapon.." ammo", self.Tag);
						if (ps) then
							CryMP.Library:Pay(shooter, bonuspoints, 0, true);
							--CryMP.Library:Give(shooter, weapon, true);
						else
							if (shooterVehicle) then
								--shooterVehicle:BoostAmmo();
							else
								--CryMP.Library:Give(shooter, weapon, true);
							end
						end
					end
				--elseif (msg.Headshot) then
					if (not shooter.hitcontrol) then
					--	CryMP.Msg.Flash:ToPlayer(channelId, {10, "#bababa", "#cf3b3b", false, 2}, msg.Headshot.Shooter[1], msg.Headshot.Shooter[2]);
					end
					--CryMP.Msg.Flash:ToPlayer(tchannelId, {10, "#cf3b3b", "#00FF00", false, 2}, msg.Headshot.Target[1], msg.Headshot.Target[2]);
				end
			end
			local buffer = self:GetBuffer(shooter.id);
			buffer.normal = buffer.normal + 1;
			if (hit.headshot) then
				buffer.headshot = buffer.headshot + 1;
				
				local heallYeah ="targetdown_13";
				local goodKill = "targetdownreply_06";
				local niceShot = "targetdownreply_05";
				local ohYeah = "targetdownreply_03";
				local greatShot = "targetdownreply_01.mp2";
				local sweet = "targetdownreply_13";
				local yee = "targetdownreply_14";
				local beautiful = "targetdownreply_12";
				

				local tbl = {
					niceShotNomad = 14;
					keepPushing = 05,
					niceShot = 02,
					gottaRattle = 06,
					greatShot = 09,
					niceWork = 12,
					hitThemHard = 07,
					beautiful = 13,
					onTheRun = 10,
					youGotThem = 08,
				};
				
				
				local so = tbl.beautiful;
				--[[
				local s = buffer.headshot;
				if (s==3) then
					so = niceShot;
				elseif (s==6) then
					so = greatShot;
				elseif (s==9) then
					so = goodKill;
				end]]
				
				local c = "g_localActor:PlaySoundEvent('ai_prophet/targetdownreply_"..so.."', g_Vectors.v000, g_Vectors.v010, bor(bor(SOUND_EVENT, SOUND_VOICE), SOUND_DEFAULT_3D), SOUND_SEMANTIC_PLAYER_FOLEY);"
				CryMP:SetTimer(1, function()
					g_gameRules.onClient:ClWorkComplete(shooter.Info.Channel, shooter.id, "EX:"..c);
				end);
				
			end
			local con = self.Config;
			--if (not self.MostWanted and con.MostWanted and buffer.normal == con.MostWanted.Kills) then
			--	return self:MostWantedBegin(shooter);
			--end
			local x = con.Standard[buffer.normal];
			local y = con.Headshot[buffer.headshot];
			local killer = shooter:GetName();
			
			--HEADSHOT
			if (y and hit.headshot) then
				local name = y.name;
				local scroll = name.." : "..buffer.headshot;
				local msg = ""..killer.." is a "..scroll.." headshots";
				local client_func = 'HUD.BattleLogEvent(eBLE_Currency, "'..msg..'");';
				if (CryMP.RSE) then
					g_gameRules.allClients:ClWorkComplete(shooter.id, "EX:"..client_func);
							
				else
					nCX.SendTextMessage(4, msg, 0);
				end
				if (ps and not nCX.ProMode) then
					--CryMP.Library:Pay(shooter, buffer.headshot * 100, 0, true);
				end
				if (not nCX.ProMode) then
					if (not shooterVehicle) then
						local weapon = shooter.inventory:GetCurrentItem();
						if (weapon.class ~= "Fists") then
							--self:BoostAmmo(shooter);
							--CryMP.Library:Give(shooter, weapon.class, true);
							local pos = shooter:GetWorldPos();
							pos = CryMP.Library:CalcSpawnPos(shooter, 1.5);
							pos.z = pos.z - 0.5;
							--nCX.ParticleManager("explosions.light.mine_light", 2, pos, g_Vectors.up, 0);
							--CryMP.Msg.Flash:ToPlayer(shooter.Info.Channel, {40, "#1C1C1C", color, false, 1}, "AMMO UPGRADE", "<i><font size=\"32\"><b><font color=\"#e82727\">*** !!</font> %s <font color=\"#e82727\">!! ***</font></b></font></i>");
						else
							--CryMP.Msg.Flash:ToPlayer(shooter.Info.Channel, {40, "#08088A", "#00FFFF", false, 1}, "ENERGY BOOST", "<i><font size=\"32\"><b><font color=\"#e82727\">*** !!</font> %s <font color=\"#e82727\">!! ***</font></b></font></i>");
							--shooter.actor:SetNanoSuitEnergy(200);
							--nCX.ParticleManager("explosions.gauss.bullet_backup", 1.5, shooter:GetWorldPos(), g_Vectors.up, 0);
							--nCX.SetInvulnerability(shooter.id, true, 1);
						end
					else
						--CryMP.Msg.Flash:ToPlayer(shooter.Info.Channel, {40, "#1C1C1C", color, false, 1}, "AMMO UPGRADE", "<i><font size=\"32\"><b><font color=\"#e82727\">*** !!</font> %s <font color=\"#e82727\">!! ***</font></b></font></i>");
						--shooterVehicle:BoostAmmo();
					end
				end
			elseif (x) then
				local w = x.w or "is";
				local name = x.name;
				local scroll = name.." : "..buffer.normal;
				local msg = ""..killer.." "..w.." "..scroll.." kills";
				local client_func = 'HUD.BattleLogEvent(eBLE_Currency, "'..msg..'");';
				if (CryMP.RSE) then
					CryMP:SetTimer(1, function()
						g_gameRules.allClients:ClWorkComplete(shooter.id, "EX:"..client_func);
					end);
					local hellYeah ="targetdown_13";
					local goodKill = "targetdownreply_06";
					local niceShot = "targetdownreply_05";
					local ohYeah = "targetdownreply_03";
					local greatShot = "targetdownreply_01.mp2";
					local sweet = "targetdownreply_13";
					local yee = "targetdownreply_14";
					local beautiful = "targetdownreply_12";
					
					local tbl = {
						niceShotNomad = 14;
						keepPushing = 05,
						niceShot = 02,
						gottaRattle = 06,
						greatShot = 09,
						niceWork = 12,
						hitThemHard = 07,
						beautiful = 13,
						onTheRun = 10,
						youGotThem = 08,
					};
					--[[
					local so = sweet;
					local s = buffer.normal;
					if (s==3) then
						so = sweet;
					elseif (s==6) then
						so = beautiful;
					elseif (s==9) then
						so = ohYeah;
					elseif (s==12) then
						so = hellYeah;
					elseif (s==15) then
						so = beautiful;
					elseif (s==18) then
						so = greatShot;
					end
					]]
					local so = tbl.niceShot;
					local s = buffer.normal;
					if (s==3) then
						so = tbl.niceShot;
					elseif (s==6) then
						so = tbl.greatShot;
					elseif (s==9) then
						so = tbl.youGotThem;
					elseif (s==12) then
						so = tbl.hitThemHard;
					elseif (s==15) then
						so = tbl.greatShot;
					elseif (s==18) then
						so = tbl.keepPushing;
					elseif (s==21) then
						so = tbl.gottaRattle;
					end
					local c = "g_localActor:PlaySoundEvent('ai_prophet/targetdownreply_"..so.."', g_Vectors.v000, g_Vectors.v010, bor(bor(SOUND_EVENT, SOUND_VOICE), SOUND_DEFAULT_3D), SOUND_SEMANTIC_PLAYER_FOLEY);"
					g_gameRules.onClient:ClWorkComplete(shooter.Info.Channel, shooter.id, "EX:"..c);
				else
					nCX.SendTextMessage(4, msg, 0);
				end
				if (not nCX.ProMode) then
					if (shooter:IsBoxing()) then
						local grenades = shooter.inventory:GetAmmoCount("flashbang");
						if (grenades ~= 1) then
						--	shooter.actor:SetInventoryAmmo("flashbang", 1, 3);
						end
					else
						--self:BoostAmmo(shooter);
					end
				end
			end
		end,
		
	},
	
	BoostAmmo = function(self, player)
		local curr = player.inventory:GetCurrentItem();
		local tbl = {["avexplosive"] = "AVMine", ["c4explosive"] = "C4", ["claymoreexplosive"] = "Claymore",["flashbang"] = "",["smokegrenade"] = "",["explosivegrenade"] = "",["empgrenade"] = "",};
		for ammo, class in pairs(tbl) do
			player.actor:SetInventoryAmmo(ammo, player.inventory:GetAmmoCapacity(ammo) or 0, 3);
			if (#class > 0) then
				nCX.GiveItem(class, player.Info.Channel, false, true);
			end
		end
		if (curr and curr.weapon and curr ~= player.inventory:GetCurrentItem() and not player:IsOnVehicle()) then
			player.actor:SelectItemByNameRemote(curr.class);
		end
	end,
	
	Reset = function(self, playerId, normal, headshot)
		self.Buffer[playerId] = {
			normal = normal or 0,
			headshot = headshot or 0,
		};
		return self.Buffer[playerId];
	end,
	
	GetBuffer = function(self, playerId)
		return self.Buffer[playerId] or self:Reset(playerId);
	end,
	
	--[[
	OnTick = function(self)
		local data = self.MostWanted;
		if (data) then
			local channelId = data.Channel;
			local mwp = nCX.GetPlayerByChannelId(channelId);
			CryMP.Msg.Battle:ToAll("** MOST WANTED ** "..string.rep(" ", 38)..data.Message);
			if (math:GetWorldDistance(data.lastPos, mwp:GetWorldPos()) > 5) then
				data.warnings = nil;
			else
				data.warnings = (data.warnings or 0) + 1;
				if (data.warnings > 4) then
					g_gameRules:KillPlayer(mwp);
					nCX.ParticleManager("Alien_Weapons.singularity.Hunter_Singularity_Impact", 0.3, mwp:GetWorldPos(), g_Vectors.up, 0);
				elseif (data.warnings == 4) then
					CryMP.Msg.Chat:ToPlayer(channelId, "Stop camping or you will self-destruct in 20 seconds!");
				elseif (data.warnings == 3) then
					CryMP.Msg.Chat:ToPlayer(channelId, "Stop camping or you will self-destruct in 40 seconds!");
				end
			end
			data.lastPos = mwp:GetWorldPos();
		end
	end,
	
	MostWantedBegin = function(self, player)
		local name = player:GetName();
		self:SetTick(20);
		local info = g_gameRules.class == "PowerStruggle" and "Points" or "Kills";
		self.MostWanted = {
			Channel = player.Info.Channel, 
			lastPos = player:GetWorldPos(),
			Message = "Kill "..name.." for "..self.Config.MostWanted.Reward[1].." Bonus "..info.."!",
			Team = nCX.GetTeam(player.id);
		};
		CryMP:SetTimer(2, function()
			CryMP.Ent:NukeTag(player, true);
			nCX.SendTextMessage(5, "<font size=\"32\"><b><font color=\"#bababa\">[+] >>> KILL [ </font><font color=\"#cf3b3b\">"..name.."</font><font color=\"#bababa\"> ] FOR BONUS!</font></font></font>", 0);
			g_gameRules.allClients:ClMDAlert("");
			local msg = "<font size=\"32\"><b><font color=\"#bababa\">[+] >>> KILL [ </font><font color=\"#cf3b3b\">"..name.."</font><font color=\"#bababa\"> ] FOR BONUS!</font></font></font>";
			CryMP.Msg:AddToQueue(5, msg, 100, 0);
		end);
	end,

	MostWantedEnd = function(self, player, reason, hit)
		local reward = self.Config.MostWanted.Reward;
		local name = player:GetName();
		self:SetTick(false);
		local playerteam = self.MostWanted.Team;
		self.MostWanted = nil;
		local shooter;		
		if (hit) then
			shooter = hit.shooter;
			player = hit.target;
			if (not shooter.actor) then
				shooter = player;
			end
		end
		if (reason == 3 and shooter and not hit.self) then
			local ps = g_gameRules.class == "PowerStruggle";
			local info = ps and "POINTS" or "KILLS";
			if (ps) then
				CryMP.Library:Pay(shooter, reward[1], reward[2]);
			else
				local ckills = reward[1] + (nCX.GetSynchedEntityValue(shooter.id, 100) or 0);
				nCX.SetSynchedEntityValue(shooter.id, 100, ckills);
				CryAction.SendGameplayEvent(shooter.id, 9, "kills", ckills);
			end
			CryMP.Msg.Chat:ToAll("BOUNTY-[+]-HUNTER : "..shooter:GetName().." killed the MOST-WANTED-[ "..name.." ]-BONUS "..reward[1].." "..info.."!");
			nCX.SendTextMessage(5, "<font size=\"32\"><b><i><font color=\"#e82727\">*** !!</font> <font color=\"#1cacff\">BOUNTY : "..reward[1].." POINTS</font> <font color=\"#e82727\">!! ***</font></i></b></font>", shooter.Info.Channel);
			return;
		end
		CryMP.Ent:NukeTag(player, false);
		--maybe one kill for all if he doesnt get killed by another player
		local reason = reason == 1 and "disconnected" or reason == 2 and "went spectating" or "killed himself";
		local team = playerteam == 1 and 2 or 1;
		local count = nCX.GetTeamPlayerCount(team);
		if (not count or count == 0) then
			return;
		end
		local share = math.floor(reward[1]/(count)) or 100;
		CryMP.Msg.Chat:ToAll("BOUNTY-[+]-HUNTER : Most Wanted player "..name.." "..reason.." : "..share.." PP to "..CryMP.Ent:GetTeamName(team).." players");
		CryMP.Library:Pay(team, share, 0);
		return;
	end,

	OnShutdown = function(self, restart)
		if (not restart) then
			if (self.MostWanted and self.MostWanted.Channel) then
				local player = nCX.GetPlayerByChannelId(self.MostWanted.Channel);
				if (player) then
					self:MostWantedEnd(player, 1);
				end
			end
		end
	end,
		
	]]
	
	IsMostWanted = function(self, channelId)
		return self.MostWanted and self.MostWanted.Channel == channelId;
	end,

};
