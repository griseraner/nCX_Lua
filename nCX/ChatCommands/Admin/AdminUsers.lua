CryMP.ChatCommands:Add("adduser", {
		Access = 0,
		Args = {
			{"player", GetPlayer = true},
			{"access",
				Output = {
					{"Premium",nil,true},
					{"Moderator",nil,true},
					{"Administrator",nil,true},
					{"Super-Admin",nil,true},
				},
			},
		},
		Info = "add or change a user",
		self = "Users",
	},
	function(self, player, channelId, target, access)
		local access = math.max(0, math.floor(access));
		local name = target:GetName();
		self:UpdateUser(target.Info.ID, access, name);
		nCX.SendTextMessage(0, "Added "..name.." to UserGroup "..access, channelId);
		if (access > 1) then
			nCX.SendTextMessage(0, "Your UserGroup changed to [ "..self.Access[access]:upper().." ]", target.Info.Channel);
		end
		return true;
	end
);

--[[CryMP.ChatCommands:Add("deluser", {
		Access = 5, 
		Args = {
			{"player", Number = true, Info = "User by index",},
		}, 
		Info = "delete a user", 
		self = "Users",
	},
	function(self, player, channelId, index)
		local data = self.Users[index];
		if (not data) then
			return false, "user not found";
		elseif (data[2] > 3) then
			return false, "cannot delete this user";
		end
		self:UpdateUser(data[1], 0, data[3]);
		return true;
	end
);]]
