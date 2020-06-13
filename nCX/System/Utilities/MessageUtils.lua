local msgTypes = {
		
	Chat = function(self, channelId, msg, chatId) 
		nCX.MsgFromChatEntity(channelId or 0, (msg or ""):gsub("%$%d", ""), chatId);
	end,
	
	ChatId = function(self, channelId, msg, chatId) 
		nCX.SendChatMessage(channelId, chatId or NULL_ENTITY, string.gsub(msg or "", "%$%d", ""));
	end,
			
	Console = function(self, channelId, fmt, ...)
		fmt = (... and fmt:format(...)) or fmt;
		nCX.SendTextMessage(1, fmt, channelId);
	end,
		
	Teletype = function(self, channelId, msg)
	end,

	--setup:
		-- 1: flash count
		-- 2: flash color #1 
		-- 3: flash color #2 
		-- 4: clear screen when done (true, false) 
		-- 5: frames between color changes
		-- 6: nigga cock in your ass <= lol
	
	Flash = function(self, channelId, setup, flashtext, msg)
	end,
		
	Scroll = function(self, channelId, setup, scroll, message)
	end,

	Animated = function(self, channelId, mode, msg, speed)
	end,

	Animation7ox = function(self, channelId, txt)
	end,

	Battle = function(self, channelId, msg)
		if (channelId == 0) then
			g_gameRules.allClients:ClClientDisconnect(msg..string.rep(" ", 280+#msg));
		else
			g_gameRules.onClient:ClClientDisconnect(channelId, msg..string.rep(" ", 280+#msg));
		end
	end,
	
	Info = function(self, channelId, msg)
		nCX.SendTextMessage(3, msg, channelId);
	end,
	
	Error = function(self, channelId, msg)
		nCX.SendTextMessage(2, msg, channelId);
	end,
	
	Zoom = function(self, channelId, msg) -- lol not tested
	end,

};


CryMP.Msg = {
	
	OnInit = function(self)
		for typ, f in pairs(msgTypes) do
			self[typ] = {
				ToAll = function(v, ...)
					f(self, 0, ...)
				end,
				ToPlayer = function(v, ...)
					f(self, ...)
				end,
				ToOther = function(self, channelId, ...)
					local players = nCX.GetPlayers();
					if (players) then
						for i, player in pairs(players) do
							if (player.Info.Channel ~= channelId) then
								self:ToPlayer(player.Info.Channel, ...);
							end
						end
					end
				end,
				ToAccess = function(self, access, ...)
					local users = CryMP.Users and CryMP.Users:GetUsers(access, false, true);
					if (users) then
						for channelId, profileId in pairs(users) do
							self:ToPlayer(channelId, ...);
						end
					end
				end,
				ToTeam = function(self, teamId, ...)
					local players = nCX.GetTeamPlayers(teamId);
					if (players) then
						for i, player in pairs(players) do
							self:ToPlayer(player.Info.Channel, ...);
						end
					end
				end,
				ToTeamAndAdmins = function(self, teamId, ...)
					self:ToAccess(2, ...);
					local players = nCX.GetTeamPlayers(teamId);
					if (players) then
						for i, player in pairs(players) do
							if (player:GetAccess() < 2) then
								self:ToPlayer(player.Info.Channel, ...);
							end
						end
					end
				end,
				AccessToOther = function(self, access, channelId, ...)
					local users = CryMP.Users and CryMP.Users:GetUsers(access, false, true);
					if (users) then
						for chan, profileId in pairs(users) do
							if (chan ~= channelId) then
								self:ToPlayer(chan, ...);
							end
						end
					end
				end,
			};
		end
	end,

	AddToQueue = function(self, type, msg, frames, channelId)
		nCX.SendQueueMessage(type, msg, frames or 0, channelId or 0);
	end,
		
};
