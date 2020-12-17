local CL_VERSION = "3.0";

local function GetPrice(a)
	if (g_gameRules.GetPrice) then
		return g_gameRules:GetPrice(a);
	end
	return 0;
end

local tbl = {
	--Scripts
	ActorOnHit = [[
		function nCX:OnHit(S, hit)
			local ht=hit.type;
			if (ht=="lockpick") then
				return;
			end
			local shooter = hit.shooter;
			S.MusicInfo=S.MusicInfo or {}
			local armor = S.actor:GetArmor();
			local hs = g_gameRules:IsHeadShot(hit);
			S.MusicInfo.headshot = hs;
			S:LastHitInfo(S.lastHit, hit);	
			if (ht:find("bullet")) then
				if (not S:IsBleeding()) then
					S:SetTimer(BLEED_TIMER, 0);
				end
				if(hit.damage > 10) then
					if(S.id == g_localActorId) then
						local s=armor > 10 and "armor" or "flesh";
						S:PlaySoundEvent("sounds/physics:bullet_impact:mat_"..s.."_fp", g_Vectors.v000, g_Vectors.v010, SOUND_2D, SOUND_SEMANTIC_PLAYER_FOLEY);
					end	
					if(armor > 10) then
						local d=hit.dir; 
						d.x = d.x * -1.0;
						d.y = d.y * -1.0;
						d.z = d.z * -1.0;
						Particle.SpawnEffect("bullet.hit_flesh.armor", hit.pos, d, 0.5);
					end
				end
				S:WallBloodSplat(hit);
				if (nCX.HitFeedback) then
					nCX:HitFeedback(S,hit);
				end
			end
			local cSA = tonumber(System.GetCVar("cl_hitShake"));
			local cSD = 0.35;
			local cSF = 0.15;
			if (ht=="melee") then
				S.lastMelee = 1;
				S.lastMeleeImpulse = hit.damage * 2;
				cSA = 33;
				cSF = 0.2;
			else
				S.lastMelee = nil;
			end
			if (S.actor:GetHealth() <= 0) then
				return;
			end
			S.actor:CameraShake(cSA,cSD,cSF,g_Vectors.v000);
			S.viewBlur = 0.5;
			S.viewBlurAmt = tonumber(System.GetCVar("cl_hitBlur"));
		end
	]],
	
	NitroMode = [[
		nCX.NOS = nil;
		function nCX:RequestNitro()
			self:TS(14);
		end
		function nCX:StartNitro()
			local vid = g_localActor.actor:GetLinkedVehicleId();
			if (vid and not nCX.NOS) then
				local car = System.GetEntity(vid);
				nCX.NOS = true;
				local imp = (car:GetMass() * 0.25);
				if (car.vehicle:GetMovementType()=="air") then
					imp = imp * 1000;
				end
				local hsp=HUD.SetProgressBar;
				for i = 0, 100 do
					Script.SetTimer(40*i, function()
						if (not g_localActor.actor:GetLinkedVehicleId()) then
							nCX.NOS=nil;
							if (car.FXSlot) then car:FreeSlot(car.FXSlot); car.FXSlot=nil; end
							hsp(false,i,'Nitrous Oxide System');
							return false;
						end
						hsp(true, i, 'Nitrous Oxide System');
						local p=car:GetCenterOfMassPos();
						car:AddImpulse(-1, p, car:GetDirectionVector(), imp, 1);
						local AC=nCX.V_Action;
						if (AC["v_brake"] or AC["v_moveup"]) then
							car:AddImpulse(-1, p, g_Vectors.up, imp * 3, 1);
						end
						if (AC["v_rollleft"] or AC["v_rollright"]) then
							local test = car:GetDirectionVector(AC["v_rollleft"] and 0 or 2);
							car:AddImpulse(-1, p, test, imp * 2, 1);
						end
						if (i == 100) then
							nCX.NOS=nil;
							if (car.FXSlot) then car:FreeSlot(car.FXSlot); car.FXSlot=nil; end
							hsp(false,i,'Nitrous Oxide System');
						end
					end);
				end
			end
		end
		System.AddCCommand("nCX_Nitro", "nCX:RequestNitro()", "");
		System.ExecuteCommand("bind f3 nCX_Nitro");
		System.ExecuteCommand("bind f4 buy lock");
		SetJetpack(100,1000,100);
	]],
	
	HydroThrusters = [[
		function nCX:HydroThrusters(chn,e)
			local p=self:GP(chn);
			if (not p) then return end;
			local TD=SOUND_DEFAULT_3D;
			local loc = g_localActorId == p.id;
			local fol=SOUND_SEMANTIC_PLAYER_FOLEY;
			if (loc) then
				self.Thrusters = e=="1" and true or false;
			end
			for i,sl in pairs(p.T_ST or {}) do
				p:FreeSlot(sl);
			end
			if (p.thrusterSound) then
				p:StopSound(p.thrusterSound);
			end
			p.T_ST={};
			if (e == "1" and p.actor:IsFlying()) then
				local vc,vc2=g_Vectors.v000,g_Vectors.v010;
				p:PlaySoundEvent("sounds/interface:suit:thrusters_boost_activate",vc,vc2,TD,fol);
				p.thrusterSound = p:PlaySoundEvent("sounds/interface:suit:thrusters_use",vc,vc2,TD,fol);
				Sound.SetSoundLoop(p.thrusterSound,1);	
				local f="vehicle_fx.vtol.damaged_exhaust";				
				for i=-1,-2,-1 do
					p.T_ST[i]=p:LoadParticleEffect(i,f,{Scale = 0.5});
					local pos = p:GetBonePos(i==-1 and "Bip01 R Foot" or "Bip01 L Foot");
					local dir = g_Vectors.down;
					p:SetSlotWorldTM(p.T_ST[i],pos,dir);
				end
				local vm = tonumber(System.GetCVar("hud_voicemode"));
				local typ = vm == 1 and "male" or vm == 2 and "female" or "";
				if (typ~="" and loc and (not self.lHydro or _time - self.lHydro > 5)) then
					self:PSE(p,"suit/"..typ.."/suit_activating_hydrothrusters");	
					self.lHydro = _time;
				end
			end
		end
	]], 
	
	--HydroThrusters  = [[function nCX:HydroThrusters(a,b)local c=self:GP(a)if not c then return end;local d=SOUND_DEFAULT_3D;local e=g_localActorId==c.id;local f=bor(bor(SOUND_EVENT,SOUND_VOICE),d)local g=SOUND_SEMANTIC_PLAYER_FOLEY;if e then self.Thrusters=b=="1"and true or false end;if c.T_ST1 then c:FreeSlot(c.T_ST1)end;if c.T_ST2 then c:FreeSlot(c.T_ST2)end;if c.thrusterSound then c:StopSound(c.thrusterSound)end;if b=="1"and c.actor:IsFlying()then c:PlaySoundEvent("sounds/interface:suit:thrusters_boost_activate",g_Vectors.v000,g_Vectors.v010,d,g)c.thrusterSound=c:PlaySoundEvent("sounds/interface:suit:thrusters_use",g_Vectors.v000,g_Vectors.v010,d,g)Sound.SetSoundLoop(c.thrusterSound,1)local h="vehicle_fx.vtol.damaged_exhaust"c.T_ST1=c:LoadParticleEffect(-1,h,{Scale=0.5})c.T_ST2=c:LoadParticleEffect(-2,h,{Scale=0.5})local i=c:GetBonePos("Bip01 R Foot")local j=c:GetBonePos("Bip01 L Foot")local k=g_Vectors.down;c:SetSlotWorldTM(c.T_ST1,i,k)c:SetSlotWorldTM(c.T_ST2,j,k)local l=tonumber(System.GetCVar("hud_voicemode"))local m=l==1 and"male"or l==2 and"female"or""if m~=""and e and(not self.lHydro or _time-self.lHydro>5)then c:PlaySoundEvent("suit/"..m.."/suit_activating_hydrothrusters",g_Vectors.v000,g_Vectors.v010,f,g)self.lHydro=_time end end end]],
	
	PatchVehicleOnHit = [[
		function nCX:VehicleHit(v,hit)
			if (hit.typeId==5) then
				if (v:GetDriverId()) then
					v:AddImpulse(-1, hit.pos, hit.dir, v:GetMass() * 8, 1);
				end
			end
		end
		function VehicleBase.Client:OnHit(hit)
			if nCX.VehicleHit then nCX:VehicleHit(self,hit) end
		end
		for i,v in pairs(System.GetEntities()) do
			if(v.vehicle)then
				function v.Client:OnHit(hit)
					if nCX.VehicleHit then nCX:VehicleHit(self,hit) end
				end
			end
		end
	]],
	
	Radio = [[
		function nCX:RequestRadio(v) 
			if (self.lR) then 
				Script.KillTimer(self.lR);
				HUD.DisplayBigOverlayFlashMessage('(RADIO canceled)...', 2, 40, 200, {0.2,1,0.2});
				self.lR=nil;		
				return; 
			end
			local tmp={"Take That Bunker","Sniper Spotted","Requesting Pickup","Watch Out","Hurry Up","Well Done"};
			HUD.DisplayBigOverlayFlashMessage('(RADIO '..(tmp[tonumber(v)] or "")..')...', 1, 40, 200, {0.2,1,0.2});
			self.lR=Script.SetTimer(1500, function() self:TS(40+v); self.lR=nil; end);		
		end
		function nCX:Radio(v, chn, sound, msg) 
			v=tonumber(v);
			local id=g_localActorId;
			local p=nCX:GP(chn);
			local _g=g_gameRules.game;
			if (not _g:IsSameTeam(id, p.id) and v < 7) then return;end
			if (sound and msg) then
				nCX:PSE(p,sound);
				if (id == p.id) then
					_g:SendChatMessage(1, id, id, '(radio, '..g_gameRules:GetTextCoord(g_localActor)..'): '..msg);				
				end	
			end
		end
		System.AddCCommand("nCX_Radio", "nCX:RequestRadio(\%1)", "");
		for i=1, 6 do
			System.ExecuteCommand("bind np_"..i.." nCX_Radio "..i);
		end		
	]],     
               	
	-- IDs
	-- 1 Kyong
	-- 2 K Soldier
	-- 3 Jester
	-- 4 Barnes
	-- 5 Sykes
	-- 6 Prophet
					--elseif (p.CM==2) then
					--p.NKS=p.NKS or math.random(5);
					--folder="ai_korean_soldier_"..p.NKS.."_eng";
					
					--if (g_gameRules.GetTextCoord) then
					--	g_gameRules.game:SendChatMessage(1, id, id, '(radio, '..g_gameRules:GetTextCoord(g_localActor)..'): '..msg);
					--else	
	Taunt = [[
		function nCX:RequestTaunt(v) 
			if (self.lastR and _time-self.lastR < 2) then return end;
			self:TS(40+v);				
		end
		function nCX:Taunt(v, chn, sound, msg) 
			v=tonumber(v);
			local p=nCX:GP(chn);
			if (p and sound and msg) then
				nCX:PSE(p,sound);
				local id=g_localActorId;
				if (id == p.id) then 
					HUD.DisplayBigOverlayFlashMessage("("..msg..")...", 2, 40, 200, {0.2,1,0.2});			
					self.lastR=_time;
				end	
			end
		end
		System.AddCCommand("nCX_Taunt", "nCX:RequestTaunt(\%1)", "");
		for i=7, 9 do
			System.ExecuteCommand("bind np_"..i.." nCX_Taunt "..i);
		end		
	]],                                    
		
	Jump = [[
		function nCX_Jump()
			local vehicleId = g_localActor.actor:GetLinkedVehicleId();
			local vehicle = vehicleId and System.GetEntity(vehicleId);
			if (vehicle) then
				vehicle:AddImpulse(-1, vehicle:GetCenterOfMassPos(), g_Vectors.up, 3000000, 1);
			else
				g_localActor:AddImpulse(-1, g_localActor:GetPos(), g_Vectors.up, 50000, 1);
			end
		end
	]],
	
	NitroEffect = [[
		function nCX:NitroEffect(vs, vv)
			local v = self:GP(vs);
			if (not v) then return; end
			local sId = v and v.actor:GetLinkedVehicleId();
			local s = sId and System.GetEntity(sId);
			if (not s) then return; end
			if (s.FXSlot) then s:FreeSlot(s.FXSlot); s.FXSlot=nil; end
			s.FXSlot=s:LoadParticleEffect( -1, "smoke_and_fire.pipe_steam_a.steam_cooler_2",{});
			local pos = s:GetWorldPos();
			local dir = s:GetDirectionVector(1);
			ScaleVectorInPlace(dir, -2.5);
			FastSumVectors(pos, pos, dir);
			dir = s:GetDirectionVector(5);
			pos.z = pos.z + 0.5; dir.x = -dir.x; dir.y = -dir.y; dir.z = -dir.z;
			s:SetSlotWorldTM(s.FXSlot, pos, dir);
		end
	]],
	
	Check = [[
		function nCX:Check(gr,ff)
			local GL=g_localActor;local GLId=g_localActorId;
			if (self.Thrusters and self.OnThrusters) then
				self:OnThrusters(ff);
			end
			if (not GL.L_REP or _time - GL.L_REP > 1) then
				if (self.M_Check) then 
					self:M_Check();
				end
				GL.L_REP=_time;
			end
			if (self.RagdollSync) then 
				self:RagdollSync(ff);
			end
			if (self.W_Check) then 
				self:W_Check(ff);
			end
			if (self.R_Check) then
				self:R_Check(ff);
			end
			local pp = System.GetEntitiesByClass("DebugGuns") or {};
			for i, p in pairs(pp) do p.item:Select(false); end
			if (tonumber(System.GetCVar("cl_bob"))~=1)then
				System.SetCVar("cl_bob","1");
			end
			if (tonumber(System.GetCVar("g_enableAlternateIronSight"))~=1) then
				System.SetCVar("g_enableAlternateIronSight","1");
			end 
			if (nCX.Performance)then nCX:Performance()end
		end		
	]],
	
	--				p.B_SLOT=p:LoadParticleEffect( -1, "misc.blood_fx.ground",{Scale = (HS and 3 or 1.5)});
		--		p:SetSlotWorldTM(p.B_SLOT, hit.pos, hit.dir); 
		--[[
						p:CreateBoneAttachment(-1, "Bip01 Head", "signal");
				local effect="misc.static_lights.green_flickering";
				local sec="misc.signal_flare.on_ground_green";
				local pos = {x=0.5,y=0,z=0};
				p:SetAttachmentEffect(-1, "signal", effect, pos, g_Vectors.v010, 0.2, 0);
				]]

	SignalEffect = [[
		function nCX:SignalEffect(chn,enable)
			local p=nCX:GP(chn);
			if (p.T_CHT) then p:FreeSlot(p.T_CHT); end
			if (enable) then
				local pos = p:GetBonePos("Bip01 Head");
				if (not pos) then
					return;
				end
				local sec=enable==17 and "misc.signal_flare.on_ground_green" or "misc.signal_flare.on_ground";
				p.T_CHT=p:LoadParticleEffect(-1,sec,{Scale = 0.3});
				pos.z=pos.z+0.5;
				local dir = g_Vectors.up;
				p:SetSlotWorldTM(p.T_CHT, pos, dir);
			end
		end
	]],
	--[[
					--startbleeding
				local dir, pos = hit.dir, hit.pos;
				local dmg = hit.damage;
				if (type == "frag" or type == "" or dmg==0) then
					dir = g_Vectors.up; 
					dmg = hit.impulse;
				end
				p:AddImpulse(hit.partId,pos,dir,math.min(1000, dmg * 40),1);
	
]]
		
	OnKill = [[
		function nCX:OnKill(p, s, M, HS, type)
			local hit = p.lastHit; if (not hit) then return end
			local loc = p.id == g_localActorId;
			if (s == g_localActorId) then
				if (not p) then return end 
				function p:StartBleeding()
					self:DestroyAttachment(0, "wound");
					self:CreateBoneAttachment(0, "Bip01 Spine2", "wound");
					local hit = p.lastHit;
					local dir, pos = hit.dir, hit.pos;
					local effect=self.bloodFlowEffect;
					local level,normal,flow=CryAction.GetWaterInfo(pos);
					if (level and level>=pos.z) then
						effect=self.bloodFlowEffectWater;
					end
					self.bleeding = true;
					self:SetAttachmentEffect(0, "wound", effect, g_Vectors.v000, -hit, 1, 0);
				end
				if (not loc) then
					p:StartBleeding();
				end
			elseif (p.id~=s and loc) then
				s=System.GetEntity(s);
				if (s) then
					local hp = math.floor(s.actor:GetHealth());
					local en = math.floor(s.actor:GetNanoSuitEnergy() * 0.5);
					HUD.DisplayBigOverlayFlashMessage("Shooter Health: "..hp.." Energy: "..en ,1,70,20,{0.2,1,0.0});
				end
			end
			local dir, pos = hit.dir, hit.pos;
			dir.z  = dir.z + 1;
			local f = "ai_korean_soldier_1";
			local so = "death_0"..math.random(0, 8);
			if (M) then
				so = "meleedeath_0"..math.random(0, 9);
			else
				local c=p.CM;
				if (c==1) then
					f="ai_kyong";
				elseif (c==3) then
					f="ai_jester";
				elseif (c==4) then
					f="ai_marine_3";
				elseif (c==5) then
					f="ai_psycho";
				elseif (c==6) then
					f="ai_prophet";
				end
			end
			p.lastPainSound = nCX:PSE(p,f.."/"..so);
			p.lastPainTime = _time;
		end
	]],
	--[[			if (e=="d_imp")then
				local t=nCX:GP(tchn);
				local pos={x=x,y=y,z=z};
				local Xdir={x=tonumber(xx),y=tonumber(yy),z=tonumber(zz)};
				local imp=math.min(2000, dmg * 20);
				ScaleVectorInPlace(Xdir, 150.0 );
				local	dir = {x=xx,y=yy,z=1};

				g_localActor:AddImpulse(-1,pos,dir,imp,1);
				System.LogAlways("$7applying death impulse "..imp.." to myself!");
				System.LogAlways(dump(pos));
				System.LogAlways(dump(g_Vectors.up));
			end
			
			--				g_localActor:AddImpulse(-1,pos,dir,imp,1);
			]]
	OnEvent = [[	
		function nCX:OnEvent(chn,e,tchn,dmg,x,y,z,xx,yy,zz)
			local p=nCX:GP(chn);
			if (not p) then return;end
			local gg=g_gameRules.game;
			local mr=math.random;
			local teamId=gg:GetTeam(p.id);
			if (e=="d_imp")then
				local t=nCX:GP(tchn);
				local pos={x=x,y=y,z=z};
				local imp=math.min(2000, dmg*20);
				local dir = {x=xx,y=yy,z=zz+1};
			end
			if (e=="assist") then
				HUD.BattleLogEvent(eBLE_Currency, "Assist (+ "..(tchn and tchn or 0).." prestige points)");
				return;
			end
			if (e=="defibrillate") then
				local t=nCX:GP(tchn);
				g_gameRules.work_name="Rebooting "..(t and t:GetName() or "Dafuq Player not found").."'s Nanosuit";
				HUD.SetProgressBar(true, 0, g_gameRules.work_name);
				return;
			end
			if (e=="hqhit") then
				local t=System.GetEntityByName(teamId==1 and "HQ_US" or "HQ_NK");
				local dmg=t and t:GetHealth();
				local friendly=teamId==gg:GetTeam(g_localActorId);
				HUD.BattleLogEvent(friendly and eBLE_Currency or eBLE_Warning, p:GetName().." has severely damaged "..(friendly and "our HQ." or "the Enemy HQ"));
				return;
			end
			if (p.CM and p.CM<3) then
				teamId=1;
			end
			local S = nCX.GetSP and nCX:GetSP(e,p);
			if(S)then 
				nCX:PSE(p,S);
			end
		end
	]],
	
	GetSP = [[
		function nCX:GetSP(e,p)
			local f,S;
			local gg=g_gameRules.game;
			local mr=math.random;
			local teamId=gg:GetTeam(p.id);
			if (e=="reload") then
				local ent=System.GetEntitiesInSphereByClass(g_localActor:GetPos(),30,"Player");
				if (ent and #ent > 0) then
					for i, e in pairs(ent) do
						if (e.id~=g_localActorId and gg:GetTeam(e.id) == teamId) then
							S = teamId == 1 and "ai_korean_soldier_2_eng/reloading_0"..mr(0, 5) or "ai_marine_3/reloading_0"..mr(0, 5);
							break;
						end
					end
				end
			else
				local c=p.CM;
				f="ai_marine_2";
				if(c==3)then
					f="ai_jester";
				elseif(c==4)then
					f="ai_marine_3";
				elseif(c==5)then
					f="ai_psycho";
				elseif(c==6)then
					f="ai_prophet";
				end
				if (e=="gunner") then
					S="mountedweapon_0"..mr(0,3);
				else
					local NK=teamId==1;
					if(NK or e=="scream")then
						f=((c==1 or e == "scream") and "ai_kyong" or "ai_korean_soldier_2_eng");
					end
					if (e == "teamfire") then
						S=teamId==1 and "surprise_0"..mr(0,8) or "friendlyfire_0"..mr(0,5);
					elseif(e=="plant")then
						if (c==1) then
							S="contactsoloback_0"..mr(0,5);
						else
							S="explosionimminent_0"..mr(0,3);
						end
					elseif(e=="grenade")then
						S="grenade_0"..mr(0,4);
					elseif(e=="scream")then
						S="fallingdeath_0"..mr(0,3);
					end
					if(NK)then
						if(e=="selectnuke")then
							S="contactsoloclose_03";
						elseif(NK and e == "blind")then
							S="blind_0"..mr(0,4);
						end
					end
				end
			end
			if (S) then
				S= f and f.."/"..S or S;
				return S;
			end
		end
	]],
	
	--OnEvent = [[function nCX:OnEvent(a,b,c,d,e,f,g,h,i,j)local k=nCX:GP(a)if not k then return end;local l=g_gameRules.game;local m=math.random;local n=l:GetTeam(k.id)if b=="d_imp"then local o=nCX:GP(c)local p={x=e,y=f,z=g}local q=math.min(2000,d*20)local r={x=h,y=i,z=j+1}end;if b=="assist"then HUD.BattleLogEvent(eBLE_Currency,"Assist (+ "..(c and c or 0).." prestige points)")return end;if b=="defibrillate"then local o=nCX:GP(c)g_gameRules.work_name="Rebooting "..(o and o:GetName()or"Dafuq Player not found").."'s Nanosuit"HUD.SetProgressBar(true,0,g_gameRules.work_name)return end;if b=="hqhit"then local o=System.GetEntityByName(n==1 and"HQ_US"or"HQ_NK")local d=o and o:GetHealth()local s=n==l:GetTeam(g_localActorId)HUD.BattleLogEvent(s and eBLE_Currency or eBLE_Warning,k:GetName().." has severely damaged "..(s and"our HQ."or"the Enemy HQ"))return end;if k.CM and k.CM<3 then n=1 end;local t;if b=="reload"then local u=System.GetEntitiesInSphereByClass(g_localActor:GetPos(),30,"Player")if u and#u>0 then for v,b in pairs(u)do if b.id~=g_localActorId and l:GetTeam(b.id)==n then t=n==1 and"ai_korean_soldier_2_eng/reloading_0"..m(0,5)or"ai_marine_3/reloading_0"..m(0,5)break end end end else local w=k.CM;local x="ai_marine_2"if w==3 then x="ai_jester"elseif w==4 then x="ai_marine_3"elseif w==5 then x="ai_psycho"elseif w==6 then x="ai_prophet"end;if b=="gunner"then t="mountedweapon_0"..m(0,3)else local y=n==1;if y or b=="scream"then x=(w==1 or b=="scream")and"ai_kyong"or"ai_korean_soldier_2_eng"end;if b=="teamfire"then t=n==1 and"surprise_0"..m(0,8)or"friendlyfire_0"..m(0,5)elseif b=="plant"then if w==1 then t="contactsoloback_0"..m(0,5)else t="explosionimminent_0"..m(0,3)end elseif b=="grenade"then t="grenade_0"..m(0,4)elseif b=="scream"then t="fallingdeath_0"..m(0,3)end;if y then if b=="selectnuke"then t="contactsoloclose_03"elseif y and b=="blind"then t="blind_0"..m(0,4)end end end;if t then t=x.."/"..t end end;if t then nCX:PSE(k,t)end end]],
	
	--OnReload  = [[function nCX:OnEvent(a,b,c,d,e,f,g,h,i,j)local k=nCX:GP(a)if not k then return end;local l=g_gameRules.game;local m=math.random;local n=l:GetTeam(k.id)if b=="d_imp"then local o=nCX:GP(c)local p={x=e,y=f,z=g}local q=math.min(2000,d*20)local r={x=h,y=i,z=j+1}end;if b=="defibrillate"then local o=nCX:GP(c)System.LogAlways("Channel "..(c or"NONE").." ")g_gameRules.work_name="Rebooting "..(o and o:GetName()or"Dafuq Player not found").."'s Nanosuit"HUD.SetProgressBar(true,0,g_gameRules.work_name)return end;if k.CM and k.CM<3 then n=1 end;local s;if b=="reload"then local t=System.GetEntitiesInSphereByClass(g_localActor:GetPos(),30,"Player")if t and#t>0 then for u,b in pairs(t)do if b.id~=g_localActorId and l:GetTeam(b.id)==n then s=n==1 and"ai_korean_soldier_2_eng/reloading_0"..m(0,5)or"ai_marine_3/reloading_0"..m(0,5)break end end end else local v=k.CM;local w="ai_marine_2"if v==3 then w="ai_jester"elseif v==4 then w="ai_marine_3"elseif v==5 then w="ai_psycho"elseif v==6 then w="ai_prophet"end;if b=="gunner"then s="mountedweapon_0"..m(0,3)else local x=n==1;if x or b=="scream"then w=(v==1 or b=="scream")and"ai_kyong"or"ai_korean_soldier_2_eng"end;if b=="teamfire"then s=n==1 and"surprise_0"..m(0,8)or"friendlyfire_0"..m(0,5)elseif b=="plant"then if v==1 then s="contactsoloback_0"..m(0,5)else s="explosionimminent_0"..m(0,3)end elseif b=="grenade"then s="grenade_0"..m(0,4)elseif b=="scream"then s="fallingdeath_0"..m(0,3)end;if x then if b=="selectnuke"then s="contactsoloclose_03"elseif x and b=="blind"then s="blind_0"..m(0,4)end end end;if s then s=w.."/"..s end end;if s then nCX:PSE(k,s)end end]],
	
	OnThrusters = [[
		nCX=nCX or {};
		function nCX:OnThrusters(ff)
			self.Throttle = (self.Throttle or 1) + 1;
			local v1=math.min(30, self.Throttle);
			local v2=math.min(20, self.Throttle);
			local GL=g_localActor;
			local cmp=GL:GetCenterOfMassPos();
			GL.freefall = GL.actorStats and (GL.actorStats.inFreeFall == 1);
			if (not GL.freefall) then
				GL:AddImpulse( -1, cmp, g_Vectors.up, ff * v1 * 50, 1);
			end
			GL:AddImpulse( -1, cmp, System.GetViewCameraDir(), ff * v2 * 50 * (GL.freefall and 3 or 1), 1);
			if (GL.actor:GetLinkedVehicleId() or GL.actor:GetHealth() < 1 or not GL.actor:IsFlying()) then
				self:HydroThrusters(g_LAC, "0");
				self:TS(16);
			end
		end
	]],
	
	WeaponCheck = [[
		function nCX:W_Check(ff)
			local GL=g_localActor;local GLId=g_localActorId;local gr=g_gameRules;
			local item = GL and GL.inventory and GL.inventory:GetCurrentItem();
			if (item and item.weapon) then
				local cl = item and item.class;
				local iw = item.weapon;
				local fire=iw:IsFiring();
				if (not fire and cl~="DSG1") then
					gr.shots = {};
				end
				if (fire and (cl=="FY71" or cl=="SCAR" or cl=="SMG")) then
					gr.shots = gr.shots or {};
					local S = gr.shots;
					local aC = iw:GetAmmoCount();
					if (#S == 0 or S[#S].aC ~= aC) then
						if (#S > 0) then	
							local p = S[#S];
							if (p.id ~= item.id or p.stance ~= GL.actorStats.stance) then
								gr.shots={};
							end
						end
						S[#S+1] = {o = GL.actor:GetViewAngleOffset().x, aC = aC, id = item.id, stance = GL.actorStats.stance, l = _time, r=iw:GetRecoil(), s=iw:GetSpread(), z=iw:IsZoomed()};
						if (#S > 10) then
							local o=0;local D=S[#S];
							for v, f in pairs(S) do
								o=o+f.r;
							end
							o=o/#S;
							local st=D.stance;
							local v1 = 3.6;
							local v2 = 2.3;
							if (cl=="SCAR" or cl=="SMG" or st==2) then
								v1=v1-1;v2=v2-1;
							end
							if (D.z) then
								v1=v1-0.3;v2=v2-0.3;
							end
							local m=GL.actor:GetNanoSuitMode();
							if m~=1 and ((not D.z and o<v1)or(D.z and o<v2)) then
								self:TS(st==2 and 24 or st==1 and 25 or 26);
							end							
							gr.shots={};
						end
					end
				end		
			end
		end
	]],
	
	WeaponRateCheck = [[
		function nCX:R_Check(ff)
			local GL=g_localActor;local GLId=g_localActorId;local gr=g_gameRules;
			local I = GL and GL.inventory and GL.inventory:GetCurrentItem();
			if (I and I.weapon) then
				local cl = I.class;
				local iw = I.weapon;
				local fire=iw:IsFiring();
				local aC = iw:GetAmmoCount();
				if (fire and (cl=="FY71" or cl=="SCAR" or cl=="SMG")) then
					local tahm = CryAction.GetServerTime();
					if (not gr.fRate) then
						gr.fRate={};
					end
					local R=gr.fRate;
					if (not R[cl]) then
						R[cl]={Start=tahm,AmmoCount=iw:GetAmmoCount(),};
					end
					local timelapsed = tahm - gr.fRate[cl].Start;
					local bullets = R[cl].AmmoCount - iw:GetAmmoCount();
					if (bullets==10) then
						local ratio = 60 / timelapsed;
						if (not R["samples"]) then
							R["samples"]={};
						end
						local s=R["samples"];
						s[cl]=s[cl] or {};
						s[cl][#s[cl]+1]=(bullets * ratio); 
						local c=#s[cl];
						if (c == 10) then
							local avr=0;
							for i,ss in pairs(s[cl]) do
								avr=avr+ss; 
							end
							avr=avr/c;
							g_gameRules.game:SendChatMessage(4, GLId, GLId, "/bpm "..cl.." "..avr);
						end
						R[cl]=nil;
					end
	
				elseif (not fire and gr.fRate) then
					gr.fRate[cl]=nil;
				end		
			end
		end
	]],
	
	--[[		function nCX:M_Check(ff)
			local GL=g_localActor;local GLId=g_localActorId;
			if (GL.L_REP and _time - GL.L_REP < 1) or (GL:IsDead() or GL.actor:GetSpectatorMode()~=0) then
				GL.sDetect=0;GL.sDetect2=0;
				return;
			end
			local FLY=GL.actor:IsFlying();
			local speed=GL:GetSpeed();
			if (FLY and speed == 0) then
				GL.sDetect = (GL.sDetect or 0) + 1;
				if (GL.sDetect > 3) then
					self:TS(27);
					GL.sDetect=0;
				end
			else 
				local cSA = tonumber(System.GetCVar("g_suitSpeedMultMultiplayer"));
				if (speed > (1 / math.max(cSA, 0.3) * 13)) then
					GL.sDetect2 = (GL.sDetect2 or 0) + 1;
					if (GL.sDetect2 > 3) then
						self:TS(28);
						GL.sDetect2=0;
					end
				end
			end
			local stats = GL:GetPhysicalStats();
			if (stats and GL.actor:GetSpectatorMode() == 0 and not GL.actor:GetLinkedVehicleId() and GL.actor:GetHealth()>0) then
				local flags = tostring(stats.flags or 1.84682e+008);
				local gravity = stats.gravity or -9.8;
				if (tostring(gravity)~=tostring(System.GetCVar("p_gravity_z")) then
					self:TS(32);
				elseif (flags~="1.84682e+008" and flags~="1.84551e+008" and flags~="1.84584e+008") then
					self:TS(31);
				elseif (stats.mass~=80) then
					self:TS(33);
				end
			end
			GL.L_REP=_time;
		end]]
		
		---> flags: 1.84715e+008   						e:AddImpulse(-1, ePos, dir, 300, 1);
	
	--							e:AddImpulse(-1, ePos, dir, 1200*ft, 1);
	
	-- and (e.LAST_VELOCITY > 15
	--PHYSICPARAM_SIMULATION
	--e:SetPhysicParams(PHYSICPARAM_VELOCITY,{v=dir});
	--e:SetWorldPos(aPos);
	--e:SetPhysicParams(PHYSICPARAM_SIMULATION,{freefall_gravity={x=0,y=0,z=0},);
	--[[
							local distance=e:GetDistance(as.id);
						if (distance > 1 and (not e.LAST_DISTANCE or distance > e.LAST_DISTANCE) and e.LAST_VELOCITY > 3) then
							System.LogAlways("SetVel -> dist -> "..distance.." - last Dist ("..(e.LAST_DISTANCE and e.LAST_DISTANCE or -1)..")");
							e:SetWorldPos(aPos);
							e.LAST_VELOCITY=0;
						else
							
						end]]
	
	RagdollSync = [[
		function nCX:RagdollSync(ft)
			local GL=g_localActor;local GLId=g_localActorId;
			for id, s in pairs(nCX.Ragdolls or {}) do
				local e=System.GetEntity(id);
				if (e and e.actor:GetPhysicalizationProfile()=="ragdoll") then
					if (not s.Ragdoll) then
						s.Ragdoll = true;
						e.LAST_DISTANCE=nil;
						e:SetCharacterPhysicParams(PHYSICPARAM_SIMULATION,{freefall_gravity={x=0,y=0,z=0},gravity={x=0,y=0,z=0}});
					end
					local as=(s.ID and System.GetEntity(s.ID));
					if (not as) then
						as=System.GetEntityByName("nCX_Assault_"..e.actor:GetChannel());
						if (as) then 
							s.ID=as.id;
							System.LogAlways("Setting first time helper "..as:GetName());
						end
					end
					if (as) then
						local ePos=e:GetCenterOfMassPos();
						local dir={};
						local aPos=as:GetWorldPos();
						aPos.z = aPos.z - 1;
						SubVectors(dir, aPos,ePos);
						dir=NormalizeVector(ScaleVector(dir, 1));
						e.LAST_POS=e.LAST_POS or ePos;
						local d=e.LAST_POS;
						e.LAST_VELOCITY=(e.LAST_VELOCITY or 0) + 1;
						
						local blendSpeed = 150 * ft;
						d.x = Interpolate(d.x, aPos.x, blendSpeed);
						d.y = Interpolate(d.y, aPos.y, blendSpeed);
						d.z = Interpolate(d.z, aPos.z, blendSpeed);
						e.LAST_POS=d;
	
						e.LAST_DISTANCE = distance;
					
					else
						nCX.Ragdolls[id]=nil;
						HUD.BattleLogEvent(eBLE_Warning, "Lost entity nCX_Assault_"..e.actor:GetChannel());
					end
				elseif (not e or s.Ragdoll) then
					nCX.Ragdolls[id]=nil;
				end
			end
		end
	]],
	
	MovementCheck = [[
		function nCX:M_Check(ff)
			local GL=g_localActor;local GLId=g_localActorId;
			if (GL:IsDead() or GL.actor:GetSpectatorMode()~=0) then
				GL.sDetect=0;GL.sDetect2=0;
				return;
			end
			local FLY=GL.actor:IsFlying();
			local speed=GL:GetSpeed();
			if (FLY and speed == 0) then
				
			else 
				local cSA = tonumber(System.GetCVar("g_suitSpeedMultMultiplayer"));
				if (speed > (1 / math.max(cSA, 0.3) * 13)) then
					GL.sDetect2 = (GL.sDetect2 or 0) + 1;
					if (GL.sDetect2 > 3) then
						self:TS(28);
						GL.sDetect2=0;
					end
				end
			end
			local stats = GL:GetPhysicalStats();
			if (stats and GL.actor:GetSpectatorMode() == 0 and not GL.actor:GetLinkedVehicleId() and GL.actor:GetHealth()>0 and GL.actor:GetPhysicalizationProfile() == "alive") then
				local flags = tostring(stats.flags or 1.84682e+008);
				local gravity = tonumber(stats.gravity or -9.8);
				local mass = tonumber(stats.mass or 0);
				if (gravity==-9.81 or gravity==-19.62) then gravity = -9.8; end
				if (gravity~=tonumber(System.GetCVar("p_gravity_z") or -9.8)) then
					self:TS(32);
				elseif (flags~="1.84682e+008" and flags~="1.84551e+008" and flags~="1.84584e+008") then
					self:TS(31);
				elseif (stats.mass~=80) then
					self:TS(33);
				end
			end
			GL.L_REP=_time;
		end
	]],
		
	--[[
				if (FLY) then
				local falling = GL.actorStats and (GL.actorStats.inFreeFall == 1);
				if (falling and (GL:GetPos().z - System.GetTerrainElevation(GL:GetPos())) < 110) then
					self:TS(29);
					GL.L_REP=_time;
				end
			end
	
				elseif (speed > 27 and GL.actor:IsFlying()) then
				System.LogAlways("Walljump? $3slowing down! Speed "..speed);
				local dir = GL:GetVelocity();
				dir.x = -dir.x
				dir.y = -dir.y
				dir.z = -dir.z
				GL:AddImpulse(-1, GL:GetCenterOfMassPos(), dir, speed * 4, 1);
				]]
		
	
	PatchDestroyableObject = [[
		if(not DestroyableObject)then
			Script.ReloadScript("Scripts/Entities/Physics/DestroyableObject.lua");
		end
		DestroyableObject.Properties.object_Model = "objects/library/props/food/melon/melon.cgf";
	]],
	
	Hola = [[
		function DestroyableObject:Reload()
			System.LogAlways(self:GetName().." $3Reload");
			local model="objects/library/props/food/melon/melon.cgf";
			local t=self:GetName():sub(-4);
			if(t==".cga" or t==".cgf")then 
				model=self:GetName();
			end 
			self:ResetOnUsed();
			local props = self.Properties;
			self.bTemporaryUsable=self.Properties.bUsable;
			self.shooterId = NULL_ENTITY;
			self.health = props.fHealth;
			self.dead = nil;
			self.exploded = nil;
			self.rigidBodySlot = nil;
			self.isRigidBody = nil;
			if (self.bReloadGeoms == 1) then
				self:LoadObject(3,model); 
				self:DrawSlot(3,0); 
				self:SetCurrentSlot(0);
				self:PhysicalizeThis(0);
			end
			self:StopAllSounds();
			self.bReloadGeoms = 0;
			self:GotoState( "Alive" );
		end
	]],
	
	PatchInteractiveEntities = [[
		System.AddCCommand("gotointeractive", "gotointeractive()", "");
		function gotointeractive()
			local e = System.GetEntitiesByClass("InteractiveEntity")[math.random(#System.GetEntitiesByClass("InteractiveEntity"))];
			g_localActor:SetWorldPos(e:GetPos());
			System.LogAlways("goto "..e:GetName());
		end
		if(not InteractiveEntity)then
			Script.ReloadScript("Scripts/Entities/Others/InteractiveEntity.lua");
		end
		InteractiveEntity.Properties.OnUse = {
			fUseDelay = 0,
			fCoolDownTime = 1,
			bEffectOnUse = 1,
			bSoundOnUse = 1,
			bSpawnOnUse = 1,
			bChangeMatOnUse = 1,
		};
		function InteractiveEntity:OnUsed(user, idx)
			local UseProps=self.Properties.OnUse;
			if (self.bCoolDown==0)then
				if(self.iDelayTimer== -1)then
					if(UseProps.fUseDelay>0)then
						self.iDelayTimer=Script.SetTimerForFunction(UseProps.fUseDelay*1000,"InteractiveEntity.Use",self);
					else
						self:Use(user, 1);
						nCX:TS(83);
					end;
				end;
			end;	
		end			
		function InteractiveEntity:IsUsable(user)
			if(self:GetState()~="Destroyed")then
				return 1;
			else
				return 0;
			end
		end
		function InteractiveEntity:GetUsableMessage(idx)
			return "Order Drink"
		end
		for i, IE in pairs(System.GetEntitiesByClass("InteractiveEntity") or {}) do
			IE.IsUsable = InteractiveEntity.IsUsable;
			IE.GetUsableMessage = InteractiveEntity.GetUsableMessage;
			IE.OnUsed = InteractiveEntity.OnUsed;
			IE.Properties.OnUse = InteractiveEntity.Properties.OnUse;
		end
	]],
	
	PatchGUIs = [[
		if(not GUI)then
			Script.ReloadScript("Scripts/Entities/Others/GUI.lua");
		end
		function GUI:OnReset()
			self:Activate(1);self:SetUpdatePolicy(ENTITY_UPDATE_VISIBLE);
			local model=self.Properties.objModel;
			local t=self:GetName():sub(-4);
			if(t==".cga" or t==".cgf")then 
				model=self:GetName();
			end 
			self:SetViewDistRatio(300);
			self:LoadObject(0,model);
			self:DrawSlot(0,1);
			if(tonumber(self.Properties.bPhysicalized) ~= 0) then 
				local physType=PE_STATIC;
				local physParam = {mass = self.Properties.fMass,};
				if (tonumber(self.Properties.bRigidBody)~=0)then 
					physType=PE_RIGID;
				end 
				self:Physicalize(0, physType, physParam);
				if (tonumber(self.Properties.bResting) ~= 0) then
					self:AwakePhysics(0);
				else 
					self:AwakePhysics(1);
				end 
			end
		end
		for i, gui in pairs(System.GetEntitiesByClass("GUI")or{})do 
			gui:OnReset();
		end
	]],
	
	PatchTornados = [[
		if (not Tornado) then
			Script.ReloadScript( "Scripts/Entities/Environment/Tornado.lua" );
		end
		Tornado.Properties.Radius = 30;
		Tornado.Properties.fWanderSpeed = 10;
		Tornado.Properties.FunnelEffect = "wind.tornado.large";
		Tornado.Properties.fCloudHeight = 376;
		Tornado.Properties.fSpinImpulse = 9;
		Tornado.Properties.fAttractionImpulse = 150;
		Tornado.Properties.fUpImpulse = 18;
		function Tornado:OnReset()
			self.TEffect = self:LoadParticleEffect( -1, "wind.tornado.large_org",{});
		end
		for i, t in pairs(System.GetEntitiesByClass("Tornado")or{})do 
			if (not t.TEffect) then
				t:OnReset();
			end
		end
	]],
	
	PressurizedObjects = [[
		function nCX:PrO(s,x,y,z,x2,y2,z2) 
			local o=System.GetEntityByName(s);
			if (o) then
				local pos = {x=x,y=y,z=z};
				local dir = {x=x2,y=y2,z=z2};
				local leak = {};
				leak.pos = pos; 
				leak.dir = dir;
				table.insert(o.leakInfo, leak);
				leak.leaking=true;
				leak.slot = o:LoadParticleEffect(-1, o.Properties.Leak.Effect.Effect, o.Properties.Leak.Effect);
				o:SetSlotWorldTM(leak.slot, pos, dir );
			end
		end
	]],
		
	PatchBuy = [[
		function nCX:BL(o) 
			local x=g_gameRules.buyList;
			if (not x) then return end;
			x.gauss.price = o and ]]..GetPrice("gauss")..[[ or 600;
			x.scargrenade.price = o and ]]..GetPrice("scargrenade")..[[ or 20;
			x.ustactank.price = o and ]]..GetPrice("ustactank")..[[ or 750;
			x.ussingtank.price = o and ]]..GetPrice("ussingtank")..[[ or 800;
			x.tacgun.price = o and ]]..GetPrice("tacgun")..[[ or 500;
			x.dsg1.price = o and ]]..GetPrice("dsg1")..[[ or 200;
			x.lockkit.name = o and "Lockpick & Defibrillator" or "@mp_eLockpick";
		end
		nCX:BL(true);
	]],
		--VL[1] = {id="light4wd",name="Repair Vehicle",price=50,class="US_ltv",category=CV};
		--VL[2] = {id="us4wd",name="Spawn LTV",price=50,class="US_ltv",category=CV };
		--VL[4] = {id="nkapc",name="Spawn APC",price=800,class="Asian_truck",category=CV };
		--VL[#VL + 1] = {id="vtolrepair",name="Repair VTOL",price=500,class="US_vtol",vehicle=true,category=CV};	
		--VL[17] = {id="usvtol",name="Spawn VTOL",price=600,class="US_vtol",vehicle=true,category=CV};	
	PatchBuyVehicles = [[
	    local VL=g_gameRules.vehicleList; 
		local CV="@mp_catVehicles";
		VL[1].name="Repair Vehicle";VL[1].price=50;
		VL[2].name="Spawn LTV";VL[2].price=50;
		VL[4].name="Spawn APC";VL[4].price=800;
		VL[18] = {id="vtolrepair",name="Repair VTOL",price=500,class="US_vtol",vehicle=true,category=CV};	
		for i, f in pairs(System.GetEntitiesByClass("Factory") or {})do
			if (f.Properties.szName == "air") then
				f.vehicles["vtolrepair"]=true;f.vehicles["vtolspawn"]=true;
			elseif (f.Properties.szName == "proto") then
				f.vehicles["ushovercraft"]=true;
			end
		end
	]],
	
		--VL[#VL + 1] = {id="vtolgun",name="Gun VTOL",price=600,class="US_vtol",vehicle=true,category=CV};	
		--VL[#VL + 1] = {id="vtol50",name="VTOL 50",price=600,class="US_vtol",vehicle=true,category=CV};	
		--VL[#VL + 1] = {id="vtoltank",name="Tank VTOL",price=800,class="US_vtol",vehicle=true,category=CV};
		--VL[#VL + 1] = {id="vtolspit",name="Spitfire VTOL",price=1000,class="US_vtol",vehicle=true,category=CV};
	
	PatchRank = [[
		g_gameRules.rankList = {
			{ name="@ui_short_rank_1", desc="@ui_rank_1", cp=0, min_pp=300,	},
			{ name="@ui_short_rank_2", desc="@ui_rank_2", cp=25,   min_pp=350,	},
			{ name="@ui_short_rank_3", desc="@ui_rank_3", cp=75,   min_pp=400,	},
			{ name="@ui_short_rank_4", desc="@ui_rank_4", cp=150,  min_pp=500,	},
			{ name="@ui_short_rank_5", desc="@ui_rank_5", cp=400,  min_pp=800,	},
			{ name="@ui_short_rank_6", desc="@ui_rank_6", cp=700,  min_pp=1000,},
			{ name="@ui_short_rank_7", desc="@ui_rank_7", cp=1000, min_pp=1350,},
			{ name="@ui_short_rank_8", desc="@ui_rank_8", cp=1500, min_pp=1800,},
		};
	]],
		
	CVarsScript = [[
		System.ClearKeyState();
		local ClientCvars = {
			{"log_verbosity","0"},
			{"log_fileverbosity","0"},
			{"hud_onScreenNearSize","1.1"},
			{"hud_onScreenFarSize","0.5"},
			{"sys_flash_edgeaa","1"},
		}; 
		if (ClientCvars and #ClientCvars > 0) then
			for i, c in pairs(ClientCvars) do
				System.SetCVar(c[1],c[2])
			end
		end 
	]],
	
	Console = [[System.ShowConsole(1);]],

	PatchUpdatePS = [[
		function g_gameRules:UpdateVoiceQueue(f)
			if (not self.voiceBusy) then
				self:PlayQueueFront();
			else
				local front = self.voiceQueue[1];
				if (front) then
					if (_time >=front.endTime and not Sound.IsPlaying(front.soundId)) then
						table.remove(self.voiceQueue, 1);				
						self.voiceBusy=false;
						if (front.proc) then
							front.proc(front.param);
						end
						self:PlayQueueFront();
					elseif (_time -front.endTime > 10 and #self.voiceQueue > 1) then
						self.voiceQueue = {	self.voiceQueue[1] };
					end
				end
			end
		end
	]],
	
	PatchHQPS = [[
		function g_gameRules:PlayPA(alertName, teamId, building)
			local A;
			if (teamId) then
				local T=self.game:GetTeamName(teamId);
				if (T and T~="") then
					A=self.SoundAlert.PA[T];
					if (A) then
						A=A[alertName];
					end
				end
			else
				A=self.SoundAlert.PA[alertName];
			end
			if (A) then
				local s = bor(bor(SOUND_EVENT, SOUND_VOICE),SOUND_DEFAULT_3D);
				local v = SOUND_SEMANTIC_PLAYER_FOLEY;
				return building:PlaySoundEvent("sounds/environment:soundspots:alarm_harbor",g_Vectors.v000,g_Vectors.v010,s,v);
			end
		end
		function g_gameRules:CanWork() return true;end;
		local r=g_gameRules.SoundAlert.Radio;
		r.tan.hqhit2="mp_korean/nk_commander_hq_damaged_01";
		r.black.hqhit2="mp_american/us_commander_hq_damaged_01";
		function g_gameRules.Client:ClHQHit(d)
			if (not g_localActorId) then return end		
			local teamId=g_gameRules.game:GetTeam(g_localActorId);
			local hq=System.GetEntity(d); if (not hq) then return end
			local sn="hqhit";
			local HP=hq:GetHealth();
			if (HP<2000) then
				sn="hqhit2";
			end
			if (HP<1000) then	
				g_gameRules:PlayPA("hqhit", teamId, hq);
			end
			local soundId=g_gameRules:PlayRadioAlert(sn, teamId);	
			HUD.BattleLogEvent(eBLE_Warning, "@mp_BLUnderAttack");
		end
		for i,q in pairs(System.GetEntitiesByClass("HQ")or {}) do
			q:LoadGeometry(1,"objects/library/architecture/multiplayer/headquarter/hq_building_destroyed.cgf");
		end
	]],		 
		--				self:HideAllAttachments(0, hide, false);
		--g_localActor:HideAttachment(0, "nCX_pick", false, false); ??
		
		--[[				if (stats.thirdPerson) then
					self:HideAllAttachments(0, hide, false);
				else
					self:HideAttachment(0, "helmet", true, false);
					self:HideAttachment(0, "upper_body", true, false);
				end]]
		
	PatchUpdateDraw = [[
		function g_localActor:UpdateDraw()
			local stats = self.actorStats;		
			if (self.actor:GetSpectatorMode()~=0) then
				self:DrawSlot(0,0);
			else
				local hide=(stats.firstPersonBody or 0)>0;
				if (stats.thirdPerson or stats.isOnLadder) then
					hide=false;
				end
				local customModel=(self.CM and self.CM > 0) and hide;
				self:DrawSlot(0,(customModel and 0 or 1));
				self:HideAllAttachments(0, hide, false);
			end
			if (nCX.Check)then nCX:Check(g_gameRules,System.GetFrameTime())end
		end
		function g_localActor:UpdateScreenEffects(frameTime)
		end
	]],
	
	PatchGamerules = [[
		function g_gameRules.Client:OnKill(p, s, w, dmg, m, t)
			local matName = self.game:GetHitMaterialName(m) or "";
			local type = self.game:GetHitType(t) or "";
			local hs = matName:find("head");
			local melee = type:find("melee");
			local pp = p and System.GetEntity(p);
			if(p == g_localActorId) then
				local x=hs and 2 or melee and 3 or 5;
				HUD.ShowDeathFX(x);
			end
			if (nCX and nCX.OnKill and pp) then
				nCX.Ragdolls=nCX.Ragdolls or {};
				nCX.Ragdolls[p]={};
				nCX:OnKill(pp, s, melee, hs, type);
			end
		end
		g_gameRules.Client.InGame.OnKill = g_gameRules.Client.OnKill;
		function g_gameRules.Client:OnDisconnect(c, s)
			if (nCX and nCX.Check) then 
				nCX.Check=nil;nCX.OnKill=nil;nCX.DrawInfo=nil;nCX.Performance=nil; 
				System.ClearKeyState(); 
				local vl=g_gameRules.vehicleList;
				if (vl) then vl[18]=nil;end
				nCX:BL(false);
				System.LogAlways("$9[$4nCX$9] Deinstalled client successfully ("..s..")");
	
			end
		end
		g_gameRules.Client.InGame.OnDisconnect = g_gameRules.Client.OnDisconnect;
	]],
	
	--DistanceVectors(g_localActor:GetCenterOfMassPos(), s:GetCenterOfMassPos()) > 100 or 
	-- not CryAction.IsGameObjectProbablyVisible(s.id)
	
	--
	--				local p1=g_localActor:GetCenterOfMassPos();
					--local p2=s:GetCenterOfMassPos();
					--if (DistanceVectors(p1, p2) > 100) then
					
					--[[						if (HDN and vis~=1) then
							s:Hide(0);
							vis = CryAction.IsGameObjectProbablyVisible(s.id);
							if (vis~= 1) then
								s:Hide(1);
							end
						end]]
						
						--[[	
		function nCX:EntVisible(s)
			local p2 = g_localActor:GetCenterOfMassPos();
			local p1=s:GetCenterOfMassPos();
			local rvDir = {};
			local rvMyPos = {};
			local rvTargetPos = {};
			CopyVector( rvMyPos, p1 );
			CopyVector( rvTargetPos, p2 );

			SubVectors( rvDir, rvTargetPos, rvMyPos );

			local hits = Physics.RayWorldIntersection(rvMyPos,rvDir,10,ent_terrain+ent_static,s.id,nil,g_HitTable);
			if (hits == 0) then
				return;
			end
			local ent = g_HitTable[1];
			if (ent.entity and ent.entity.id  == g_localActorId) then
				return true;
			end
		end]]
		--[[
				g_localActor.OnEnterArea=replace_pre(g_localActor.OnEnterArea, function(self, entity, areaId)
			entity:Hide(0);
			System.LogAlways("$9Entity is within range: Turning on ($5"..entity:GetName().."$9)");
		end);
		g_localActor.OnLeaveArea=replace_pre(g_localActor.OnLeaveArea, function(self, entity, areaId)
			entity:Hide(1);
			System.LogAlways("$9Entity is within range: Turning off ($4"..entity:GetName().."$9)");
		end);
		local dim=2*100;
		
		local trigger=System.SpawnEntity{
			class="ProximityTrigger",
			flags=ENTITY_FLAG_CLIENT_ONLY,
			position={x=0, y=0, z=0},
			name=g_localActor:GetName().."_entity_trigger2",
			
			
			properties={
				DimX=dim,
				DimY=dim,
				DimZ=dim,
				bOnlyPlayer=0,
			},
		};
		g_localActor:AttachChild(trigger.id, 8);
		trigger:ForwardTriggerEventsTo(g_localActor.id);]]
					
					--							System.LogAlways("$9[$4nCX$9] "..s:GetName().." is marked $4INVISIBLE");
					--							System.LogAlways("$9[$4nCX$9] "..s:GetName().." is marked $5VISIBLE");
					
	Performance = [[
		function nCX:Performance()
			if (not self.PerformanceMode) then return end
			if (not self.ENVIRONMENT) then
				local e=System.GetEntities();
				self.ENVIRONMENT={e,0,#e};
				return;
			end
			self.ENVIRONMENT[2]=self.ENVIRONMENT[2]+1;
			local c=self.ENVIRONMENT[2];
			local entity=self.ENVIRONMENT[1][c];
			if (entity) then
				local p2=entity:GetCenterOfMassPos();
				if (p2) then
					self:CheckVisibility(entity,p2);
				end
			elseif (self.ENVIRONMENT[2] > self.ENVIRONMENT[3]) then
				System.LogAlways("Cycle done. "..self.ENVIRONMENT[3]);
				self.ENVIRONMENT=nil;
			end
		end
		function nCX:CheckVisibility(s,p2)
			local important=s.actor or s.vehicle;
			local skip=s.class=="Tornado";
			if (skip) then return end;
			local WP=s.item and s.item:GetOwnerId();
			if (WP==g_localActorId) then
				return;
			end
			local hidden=s:IsHidden(); 
			local p1=g_localActor:GetCenterOfMassPos();
			local dist=DistanceVectors(p1, p2);
			local vis=dist > 200 and 0 or 1;
			if (not important and vis==1 and not System.IsPointVisible(p2)) then
				vis=0;
			end	
			if (vis==1) then
				if (hidden and s.Hidden_By_nCX) then
					s:Hide(0);
					s.Hidden_By_nCX = nil;
					System.LogAlways("$9[$4nCX$9] Unhiding "..s:GetName());
				end
			else
				if (not hidden) then
					s:Hide(1);
					s.Hidden_By_nCX = true;
				end
			end
		end
	]],
	
	--[[
				if (vis==1 and not System.IsPointVisible(p2)) then
				vis=0;
			end	
	
	
				if (vis==1 and s.vehicle) then
				local rvDir = {};			
				SubVectors(rvDir,p2,p1);
				local hits = Physics.RayWorldIntersection(p1,rvDir,1,ent_terrain+ent_static,nil,nil,g_HitTable);
				if (hits~=0) then
					vis=0;
				end
			end	
			for i, s in pairs(System.GetEntitiesByClass("Door")or{}) do
			function s:Sound(open)
				self:PlaySoundEvent(self.Properties.Sounds.soundSoundOnMove, g_Vectors.v000, g_Vectors.v010, SOUND_2D, SOUND_SEMANTIC_PLAYER_FOLEY);
				self.stopSoundPlayed = nil;		
			end
			s.Properties.Sounds.soundSoundOnMove="Sounds/environment:doors:door_wood_1_open";
		end
		]]
	
	ClientUpgradeSuccessful = [[
		g_localActor:PlaySoundEventEx("Sounds/interface:suit:nano_suit_energy_pulse_1p", 0, 1, {x=0,y=0,z=0}, 0, 0, SOUND_SEMANTIC_NANOSUIT);
		g_localActor.actor:CameraShake(20, 2.0, 0.07, g_Vectors.v000);
		HUD.BattleLogEvent(eBLE_Information,"[ nCX ] Installed ]]..CL_VERSION..[[...");
		HUD.BattleLogEvent(eBLE_Information,"[ nCX ] Welcome to our server!");
		if (System.IsDevModeEnable()) then
			nCX:TS(19);
		end
		local cSA = tonumber(System.GetCVar("aim_assistRestrictionTimeout"));
		if (cSA<0) then
			nCX:TS(21);
		elseif (cSA~=20) then
			nCX:TS(20);
		end
	]],
	--			System.LogAlways(action.." | "..activation.." | "..value);
	
	OnAction = [[
		function g_localActor:OnAction(action, ac, value)
			local N=nCX;local g_=g_gameRules;
			if (g_ and g_.Client.OnActorAction) then
				if (not g_.Client.OnActorAction(g_, self, action, ac, value)) then
					return;
				end
			end
			if (action == "use" or action == "xi_use") then
				self:UseEntity( self.OnUseEntityId, self.OnUseSlot, ac=="press");
				N.Throttle = 0;
				if (value == 0) then
					if (N.Thrusters) then
						N.Thrusters = false;
						N:TS(16);
					end
				elseif (self.actor:IsFlying()) then
					N:TS(15);
				end
			elseif (action == "hud_openchat") then
				N:TS(17);
			elseif (action == "hud_openteamchat") then
				N:TS(18);
			elseif (self.actor:GetLinkedVehicleId()) then	
				N.V_Action=N.V_Action or {};
				N.V_Action[action]=(value==1 and true or nil);
			end
		end
	]],
	
	PatchOnHit   = [[
		for i, s in pairs(System.GetEntitiesByClass("Player")or{}) do
			function s.Client:OnHit(hit)
				nCX:OnHit(s,hit);
			end
			function s:ApplyDeathImpulse()
			end
			function s:DoPainSounds()
			end
		end
		function BasicActor:ApplyDeathImpulse()
		end
		function BasicActor:DoPainSounds()
		end		
		function g_gameRules.Client:OnExplosion(e)
			System.LogAlways("$8g_gameRules.Client:OnExplosion(e)");
			self:ClientViewShake(e.pos, math.min(3*e.radius, 30), math.min(e.pressure/1500, 10), 2, 0.02, "explosion");	
		end
		function g_gameRules.Client:OnHit(hit)
			System.LogAlways("$3g_gameRules.Client:OnHit(hit)");
			if ((not hit.target) or (not self.game:IsFrozen(hit.target.id))) then
				local trg = hit.target;
				if (trg and (not hit.backface) and trg.Client and trg.Client.OnHit) then
					trg.Client.OnHit(trg, hit);
				end
			end	
		end
		function nCX:HitFeedback(S,hit)
			if(tonumber(System.GetCVar("g_useHitSoundFeedback")) > 0) then
				if(hit.shooter and hit.shooter == g_localActor) then
					local sound;
					if (headshot) then
						sound="sounds/physics:bullet_impact:headshot_feedback_mp";
					else
						if(armorEffect) then
							sound="sounds/physics:bullet_impact:generic_feedback";
						else
							if(hit.material_type == "kevlar") then
								sound="sounds/physics:bullet_impact:kevlar_feedback";
							else
								sound="sounds/physics:bullet_impact:flesh_feedback";
							end
						end
						sound="sounds/physics:bullet_impact:helmet_feedback";
					end
					if (sound and (sound~="")) then
						S:PlaySoundEvent(sound, g_Vectors.v000, g_Vectors.v010, SOUND_2D, SOUND_SEMANTIC_PLAYER_FOLEY);
					end
				end
			end
		end
	]],
	
};

CryMP.RSE:AddExtensions(tbl);

	--[[
					local slotId = 5;
				local s = car;
				--wind.tornado.large_org
				s.FXSlot=s:LoadParticleEffect( -1, "wind.tornado.large_org",{});
				s.FXSlot=s:LoadParticleEffect( -1, "smoke_and_fire.pipe_steam_a.steam_cooler_2",{});
				s.FXSlot2=s:LoadParticleEffect( -1, "explosions.small_fuel_tank.smallfuel_can",{});
				local pos = s:GetWorldPos()
				local dir = s:GetDirectionVector(1);
				ScaleVectorInPlace(dir, -2.5);
				FastSumVectors(pos, pos, dir);
				pos.z = pos.z + 0.5
				dir = s:GetDirectionVector(slotId);
				dir.x = -dir.x
				dir.y = -dir.y
				dir.z = -dir.z
				s:SetSlotWorldTM(s.FXSlot, pos, dir); 
				s:SetSlotWorldTM(s.FXSlot2, pos, dir); 
				
						function g_localActor.Server:OnUpdate(frameTime)
			if (not self:IsDead()) then
				self:UpdateEvents(frameTime);
			else
				local flags = { 
					flags=
					geom_colltype_explosion + 
					geom_colltype_ray + 
					geom_colltype_foliage_proxy + 
					geom_colltype_player
				};
				self:SetPhysicParams(PHYSICPARAM_PART_FLAGS, flags);
			end
		end
				]]