--==============================================================================
--!SAY [TYPE] [MESSAGE]

CryMP.ChatCommands:Add("say", {
		Access = 2,
		Args = {
			{"type", Output = {{"server", "Server message at the bottom",},{"center", "Center message",},{"big", "Big center message",},{"scroll", "Scroll message",},{"animated", "Animation message",},{"flash", "Flash message",},{"admin", "Admin message",},},},
			{"message", Concat = true, Info = "the message you wish to send"},
		}, 
		Info = "send a message to all players",
		self = "Msg",
	}, 
	function(self, player, channelId, type, message)
		if (type == "server") then
			nCX.SendTextMessage(4, message, 0);
		elseif (type == "center") then
			nCX.SendTextMessage(0, message, 0);
		elseif (type == "big") then
			nCX.SendTextMessage(5, "<font size=\"32\"><font color=\"#868686\">***</font> <font color=\"#ababab\"><b>SPAM-[ <font color=\"#67c072\">"..message.."</font><font color=\"#ababab\"> ]-SPAM</b></font> <font color=\"#868686\">***</font></font>", 0);
		elseif (type == "scroll") then
			--self.Teletype:ToAll(message);
			self.Scroll:ToAll({"#000000", false, 0}, message, "<font color=\"#868686\">***</font> <font color=\"#ababab\"><b>SPAM-[ <font color=\"#00FF00\">%s</font><font color=\"#ababab\"> ]-SPAM</b></font> <font color=\"#868686\">***</font>");
		elseif (type == "animated") then
			self.Animated:ToAll(2,"<font color=\"#868686\">***</font> <font color=\"#ababab\"><b>SPAM-[ <font color=\"#00FF00\">"..message.."</font><font color=\"#ababab\"> ]-SPAM</b></font> <font color=\"#868686\">***</font>");
		elseif (type == "flash") then
			self.Flash:ToAll({50, "#3366FF", "#0000FF",}, string.upper(message), "<font size=\"32\"><font color=\"#868686\">***</font> <b><font color=\"#ababab\">7Ox-[</font> %s <font color=\"#ababab\">]-MSG</b></font> <font color=\"#868686\">***</font></font>");
			return true;
		elseif (type == "admin") then
			if (CryMP.Users:HasAccess(player.Info.ID, 3)) then
				nCX.SendTextMessage(5, "<font size=\"32\"><b><font color=\"#ababab\">7Ox.ADMIN-( </font><font color=\"#ff0000\">"..message.."</font><font color=\"#ababab\"> )</font></b></font>", 0);
				return true;
			end
			return false, "only admins may send this type"
		end
		return true;
	end
);
