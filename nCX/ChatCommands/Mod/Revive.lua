--==============================================================================
--!REVIVE

CryMP.ChatCommands:Add("revive", {
		Access = 2, 
		Args = {
			{"player", Optional = true, GetPlayer = true,},
		}, 
		Info = "revive a target or yourself", 
		self = "Ent",
	}, 
	function(self, player, channelId, target)
		target = target or player;
		if (target:IsBoxing()) then
			CryMP.Boxing:Teleport(target, false, true);
		elseif (target:IsDuelPlayer()) then
			--CryMP.Duel:OnDisconnect(target.Info.Channel, target, true);
			CryMP.Duel:ShutDown(true);
			nCX.SendTextMessage(0, "Duel Engine has been reset...", channelId);
		else
			self:Revive(target, true, false, true);
		end
		if (player.id~=target.id) then
			nCX.SendTextMessage(0, "You were revived by an administrator", target.Info.Channel);
		end
		return true;
	end
);
