--==============================================================================
--!PM [PLAYER] [MESSAGE]

CryMP.ChatCommands:Add("pm", {
		Args = {
			{"player", Optional = true, GetPlayer = true,},
			{"message", Optional = true, Info = "include message if you want to send it directly", Concat = true,},
		},
		Info = "start a private chat conversation with a player",
	}, 
	function(self, player, channelId, target, message)
		if (not target or target.id ~= player.id) then
			if (target and message) then
				self:SendPM(player, target, message);
				return true;
			elseif (self.PM[channelId]) then
				CryMP.Msg.Chat:ToPlayer(channelId, "Private Conversation disabled...");
				self.PM[channelId] = nil;
				return true;
			else
				if (target) then
					local targetChannel = target.Info.Channel;
					local name = player:GetName();
					self.PM[channelId] = {targetChannel}; 
					CryMP.Msg.Chat:ToPlayer(channelId, "Private Conversation started > > >  "..target:GetName().." ("..targetChannel..")");
				else
					for channel, tbl in pairs(self.PM) do
						if (tbl[1] == channelId) then
							local target = nCX.GetPlayerByChannelId(channel);
							if (target) then
								self.PM[channelId] = {channel}; 
								CryMP.Msg.Chat:ToPlayer(channelId, "Private Conversation started > > >  "..target:GetName().." ("..channel..")");
								return true;
							end
						end
					end
					return false, "last sender not found"
				end
				return true;
			end
		else
			return false, "cannot send message to yourself";
		end
	end
);

--==============================================================================
--!TOADMINS [MESSAGE]

CryMP.ChatCommands:Add("toadmins", {
		Args = {
			{"message", Concat = true, Info = "Your message to admins",},
		},
		Info = "send a message to all admins",
		self = "Users",
	}, 
	function(self, player, channelId, message)
		local count = 0;
		local name = player:GetName();
		local message = "$9[ $5"..name.." $9(Channel $4"..channelId.."$9) to $1ADMINS$9: $5"..message.."$9 ]";
		local users = self:GetUsers(2, false, true);
		if (users) then
			for cid, profileId in pairs(users) do
				if (cid ~= channelId) then
					CryMP.Msg.Chat:ToPlayer(cid, "PM received by ("..name..", channel "..channelId..") Check your console!", 1);
					CryMP.Msg.Console:ToPlayer(cid, "$9====[ $4PM$1:$4INBOX$9 ]================================================================================================");
					CryMP.Msg.Console:ToPlayer(cid, "$9"..string:mspace(116,message,"-"));
					CryMP.Msg.Console:ToPlayer(cid, "$9================================================================================================[ $4PM$1:$4INBOX$9 ]====")
					count = count + 1;
				end
			end
		end
		if (count > 0) then
			CryMP.Msg.Chat:ToPlayer(channelId, "Message successfully sent to "..count.." staff!");
			return true;
		end
		return false, "no staff online";
	end
);
