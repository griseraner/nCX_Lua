Attach = {

	---------------------------
	--		Config
	---------------------------
	Tag					= 15,
	Data 				= {},
	Changes 			= 0,
	Default = {
		["SCAR"] 		= {},
		["SOCOM"]		= {},
		["SMG"] 	    = {},
		["Shotgun"] 	= {},
		["FY71"] 		= {},
		["AlienMount"] 	= {},
		["Hurricane"]	= {},
		["DSG1"]		= {},
	},
	
	Server = {
	
		--OnConnect = function(self, channelId, actor, profileId, restart)
		
		OnAccessoriesChanged = function(self, actor, weapon, attachments)
			if (not actor:IsDuelPlayer()) then
				local data = self:GetData(actor.Info.ID);
				data[weapon.class] = attachments;
				--if (not actor.ATTACH_INFORMED) then
					--if (actor:GetAccess() > 0) then
					--	CryMP.Msg.Chat:ToPlayer(actor.Info.Channel, "Your Weapon Configuration is synched between 7OXICiTY Servers", self.Tag);
					--else
						--CryMP.Msg.Chat:ToPlayer(actor.Info.Channel, "This Server remembers your Weapon Configuration", self.Tag);
					--end
				--	actor.ATTACH_INFORMED = true;
				--end
			end
			self.Changes = self.Changes + 1;
			if (self.Changes > 15) then
				local data = self:GetData(actor.Info.ID);
				if (data and data.name == "N/A") then
					data.name = actor:GetName();
				end
				self:Write();
				self.Changes = 0;
			end
		end,
			
		OnGiveItem = function(self, actor, item)
			if (item.class == "SCARTutorial") then
				item.weapon:AttachAccessory("TacticalAttachment");
				item.weapon:AttachAccessory("SCARIncendiaryAmmo");
				item.weapon:AttachAccessory("SCARTagAmmo");
			end
			if (not actor:IsDuelPlayer() and not actor:IsDead()) then  
				local data = self:GetData(actor.Info.ID);
				local custom = (data and data[item.class]) or self.Default[item.class];
				if (custom) then
					CryMP:SetTimer(0, function()
						for i, attach in pairs(custom or {}) do
							item.weapon:AttachAccessory(attach);
						end	
					end);
				end
			end
		end,
		
		--[[
		OnItemPickedUp = function(self, actor, item)
			local data = self:GetData(actor.Info.ID);
			local custom = self.Default[item.class];
			if (custom) then
				--CryMP:DeltaTimer(1, function()
				for i, attach in pairs(custom or {}) do
					item.weapon:AttachAccessory(attach, true);
					--System.LogAlways("Trying to attach "..attach);
				end	
			end
		end,]]
		
		
		OnVehicleHit = function(self, hit, vehicle, destroyed, damage)
			local shooter = hit.shooter;
			if (destroyed) then
				for i, seat in pairs(vehicle.Seats) do
					local passengerId = seat:GetPassengerId();
					local passenger = passengerId and nCX.GetPlayer(passengerId);
					if (passenger and not passenger:IsDead()) then
						hit.target = passenger;
						hit.targetId = passenger.id;
						g_gameRules:ProcessDeath(hit, passenger);
						System.LogAlways("Killing "..hit.target:GetName().." in $4"..vehicle:GetName());
					end
				end
			end
		end,
		
	},
	
	OnInit = function(self, reload)
		self.Data = {};
		self.Count = 0;
		require("Data_Attach", "data file");
		if (not reload) then
			nCX.Log("Core", "Loaded Attachment Data for "..self.Count.." players.");
		end
	end,
	
	OnShutdown = function(self, restart)
		self:Write();
	end,
	
	Add = function(self, name, profileId, attach)
		self.Data[profileId] = {
			name = name,
			attach = attach,
		};
		self.Count = (self.Count or 0) + 1;
	end,
	
	GetData = function(self, profileId, mode)
		local data = self.Data[profileId];
		if (not data or not data.attach) then
			local name;
			local actor = CryMP.Users:GetPlayerByProfileId(profileId);
			if (actor) then
				name = CryMP.Ent:CheckName(actor:GetName());
			end
			self.Data[profileId] = {
				name = name or "empty",
				attach = {},
			};
			data = self.Data[profileId];
		end
		return data.attach;
	end,

	Reset = function(self, profileId)
		self.Data[profileId] = nil;
    end,
	
	ParseToString = function(self, data, profileId)
		local line =  "CryMP.Attach:Add('"..data.name.."', '"..profileId.."', ";
		local atch = "{";
		for class, tbl in pairs(data.attach) do
			atch = atch..'["'..class..'"] = ';
			local str = "{";
			for i, x in pairs(tbl) do
				str = str..'"'..x..'", ';
			end
			atch = atch..str:sub(1, -2).."}, ";
		end
		line = line..atch:sub(1, -2).."});\n";
		return line;
	end,
	
	Write = function(self)
		FileHnd = io.open(CryMP.Paths.GlobalData.."Data_Attach.lua", "w+")
		for profileId, data in pairs(self.Data) do
			if (data.attach and nCX.Count(data.attach) > 0 --[[ and CryMP.Users:GetAccess(profileId) > 0]]) then
				local line = self:ParseToString(data, profileId);
				FileHnd:write(line);
			end
		end
		CryMP.Synch:OnChange("Data_Attach", FileHnd:seek("end"));
		FileHnd:close();
	end,
	
};
