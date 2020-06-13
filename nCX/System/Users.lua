CryMP.Users = {
   
    Access = {
		"Premium",
		"Moderator", 
		"Administrator", 
		"Super-Admin",
		"Developer",
	},

	Tags = {"[VIP]", "[7Ox]"},
	
	UserCache = {
		[0] = {},
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
	},
	
	Server = {
		---------------------------
		--		PreConnect		
		---------------------------
		OnConnect = function(self, channelId, player, profileId, restart)
			local access = self:GetAccess(profileId);
			System.LogAlways("OnConnect "..channelId.." : profile: "..type(profileId).." : Access : "..access);
			self:CacheAccess(access, channelId, profileId);
			local passed = true;
			local name = player:GetName();
			CryMP.Ent:CheckName(name, player.id);
			if (access > 3) then
				nCX.AdminSystem(channelId, true);
			end
			if (access < 3 and not player:IsNomad()) then
				local reserved = self:VerifyReservedNames(profileId, name);
				local extra = "";
				if (#tostring(channelId) == 1) then
					extra = "000";
				elseif (#tostring(channelId) == 2) then
					extra = "00";
				elseif (#tostring(channelId) == 3) then
					extra = "0";
				end
				local new = "[7Ox."..player.Info.Country_Short.."]::[#"..extra..channelId.."]";
				if (reserved) then
					CryMP.Ent:Rename(player, new, "reserved name");
					passed = false;
				elseif (access < 2) then
					for i, tag in pairs( {"admin", "7Ox", "70x"} ) do
						if (CryMP.Ent:HasTag(name, tag)) then
							CryMP.Ent:Rename(player, new, "invalid name");
							passed = false;
							break;
						end
					end
				end
				if (access == 0 and CryMP.Ent:HasTag(name, self.Tags[1]:lower())) then
					CryMP.Ent:RemoveTag(name, self.Tags[1]:lower(), player.id);
				end
			end
			if (passed and access > 0) then
				local i = self.Users[profileId];
				if (i and (i[4] or (not i[4] and access == 1))) then
					self:AddTag(player, i[4] or 1);
				end
			end
		end,
		---------------------------
		--		OnDisconnect		
		---------------------------
		OnDisconnect = function(self, channelId, player, profileId, cause)
			local access = self:GetAccess(profileId);
			self.UserCache[access][channelId] = nil;
		end,
		---------------------------
		--		OnNameChange		
		---------------------------	
		OnNameChange = function(self, player, name)
			local profileId = player.Info.ID;
			local access = self:GetAccess(profileId);
			if (access < 3) then
				local reserved = self:VerifyReservedNames(profileId, name);
				if (reserved) then
					return true, {[3]="reserved name",}; 
				end
				if (access < 2) then
					for i, tag in pairs( {"admin", "7ox", "70x"} ) do
						if (CryMP.Ent:HasTag(name, tag)) then
							return true, {[3]="invalid name",}; 
						end
					end
				end
				if (access == 0 and CryMP.Ent:HasTag(name, "vip")) then
					return true, {[3]="vip tag only for premium members",}; 
				end					
			end
			local tagId = self.Users[profileId] and self.Users[profileId][4];
			local tag = tagId and self.Tags[tagId];
			if (tag and not CryMP.Ent:HasTag(name, tag)) then
				local new = tagId == 2 and tag.." "..name or name.." "..tag;
				return false, {[2]=new, [3]="tag"}; 
			end
		end,
	},
	
	OnInit = function(self, reload)
		self.Users = {};
		local mt = {
			__index = function(t, k)
				for i, data in pairs(t) do
					if (data[1] == k) then
						return data;
					end
				end
			end,
		};
		setmetatable(self.Users, mt);
		require("Data_Users", "data file");
		if (not reload) then
			nCX.Log("Core", "Loaded "..#self.Users.." users.");
		end
	end,
	
	OnShutdown = function(self, restart)
		return {"UserCache"};
	end,

	Sort = function(self)
		local function sort_by_access(t1, t2)
			return (t1[2] or 0) > (t2[2] or 0);
		end
		table.sort(self.Users,sort_by_access);
	end,
	
	Write = function(self)
		if (#self.Users > 0) then
			self:Sort();
			local FileHnd = io.open(CryMP.Paths.GlobalData.."Data_Users.lua", "w+");
			for i, data in pairs(self.Users) do
				local line = "CryMP.Users:Add("..data[2]..", '"..data[1].."', '"..data[3].."'"; 
				if (data[4]) then
					line = line..", "..data[4];
				end			
				line =  line..");\n";
				FileHnd:write(line);
			end
			CryMP.Synch:OnChange("Data_Users", FileHnd:seek("end"));
			FileHnd:close();
		end
	end,
	
	Add = function(self, access, profileId, name, tag)
		if (not self.Users[profileId]) then
			self.Users[#self.Users + 1] = {profileId, tonumber(access), CryMP.Ent:CheckName(name), tag};
			local user = self:GetPlayerByProfileId(profileId);
			if (user) then
				self:CacheAccess(access, user.Info.Channel, profileId);
			end
		end
	end,

	UpdateUser = function(self, profileId, access, name)
		access = tonumber(access);
		if (access) then	
			if (name) then
				name = CryMP.Ent:CheckName(name);
			end
			local old = self.Users[profileId];
			if (not old) then
				self:Add(access, profileId, name, tag);
			elseif (access == 0) then
				self:Remove(profileId);
				if (old) then
					for channelId, id in pairs(self.UserCache[old[2]]) do
						if (id == profileId) then
							self.UserCache[old[2]][channelId] = nil;
							break;
						end
					end
				end
			else
				local i = self.Users[profileId];
				i[2] = access or i[2];
				i[3] = name or CryMP.Ent:CheckName(i[3]);
			end
			self:Write();
			local user = self:GetPlayerByProfileId(profileId);
			if (user) then
				self:CacheAccess(access, user.Info.Channel, profileId);
			end
		end
	end,

	GetPlayerByProfileId = function(self, profileId)
		for i, player in pairs(nCX.GetPlayers() or {}) do
			if (player.Info.ID == profileId) then
				return player;
			end
		end
	end,
	
	Remove = function(self, profileId)
		for i, data in pairs(self.Users) do
			if (data[1] == profileId) then
				table.remove(self.Users, i);
				break;
			end
		end
	end,

	GetMask = function(self, profileId)
		if (type(access) == "table" and profileId.actor) then
			profileId = profileId.Info.ID;
		end
		local x = self:GetAccess(profileId);
		return self.Access[profileId] or self.Access[x] or "Player";
	end,
	
	GetName = function(self, profileId)
		return (self.Users[profileId] and self.Users[profileId][3]) or ""
	end,
	
	AddTag = function(self, player, tagId, remove)
		local name = player:GetName();
		if (not player:IsNomad() and (remove or (not CryMP.Ent:HasTag(name, self.Tags[tagId]) and #name < 17))) then
			self.Users[player.Info.ID][4] = not remove and tagId or nil;
			for id, tag in pairs(self.Tags) do
				CryMP.Ent:RemoveTag(name, tag, (remove and player.id or nil));
			end
			if (not remove) then
				local new = tagId == 2 and (self.Tags[tagId].." "..name) or (name.." "..self.Tags[tagId]);
				nCX.RenamePlayer(player.id, new);
			end
			self:Write();
			return true;
		end
	end,
	
	VerifyReservedNames = function(self, profileId, new)
		local access = self:GetAccess(profileId);
		if (access < 3) then	
			for i, user in pairs(self.Users or {}) do
				local id, access, username = user[1], user[2], user[3];
				if (access > 2 and id ~= profileId) then
					if (CryMP.Ent:HasTag(new, username)) then
						return true;
					end
				end
			end
		end
	end,
	
	-- ====================================
	-- Get Access Funcs
	-- ====================================

	GetAccess = function(self, profileId)
		local v = type(profileId);
		if (v == "table" and profileId.Info) then
			profileId = profileId.Info.ID;
		elseif (v == "number") then
			profileId = self:GetProfileByChannelId(profileId);
		end
		return (profileId and self.Users[profileId] and self.Users[profileId][2]) or 0;
	end,
	
	HasAccess = function(self, profileId, access)
		return self:GetAccess(profileId) >= access;
	end,

	CompareAccess = function(self, p1, p2)
		return self:GetAccess(p1) > self:GetAccess(p2) or p1 == p2;
	end,

	GetUsers = function(self, access, exclusive, raw)
		local cache = self.UserCache;
		if (access and cache[access]) then			
			local tbl;
			for i = access, #cache do 
				if (nCX.Count(cache[i]) > 0) then
					tbl = tbl or {};
					for channelId, profileId in pairs(cache[i]) do		
						if (raw) then
							tbl[channelId] = profileId;
						else
							tbl[#tbl+1] = nCX.GetPlayerByChannelId(channelId);
						end
					end
				end
				if (exclusive) then
					return tbl;
				end
			end
			return tbl;
		end
	end,
	
	GetProfileByChannelId = function(self, channelId)
		for i = 0, #self.UserCache, 1 do 
			local cache = self.UserCache[i];
			if (cache) then
				for chan, profileId in pairs(cache) do		
					if (chan == channelId) then
						return profileId;
					end
				end
			end
		end
	end,

	CacheAccess = function(self, access, channelId, profileId)
		if (access and channelId and profileId) then
			self.UserCache[access][channelId] = profileId;
		end
	end,
	
};
