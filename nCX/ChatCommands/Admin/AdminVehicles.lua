--===================================================================================
-- CONTROL

CryMP.ChatCommands:Add("control", {
		Access = 3,
		Info = "a powerful tool to control vehicles", 
		Args = {
			{"class", Output = {{"US_vtol",},{"Asian_helicopter",},},},
			{"mode", Output = {{"off", "Disables all types of selected class", true},{"light", "Restricts to selected class without explosive cannons", true},{"heavy", "Enables all types of selected class", true},},},
		}, 
		self = "LockDowns",
	},
	function(self, player, channelId, class, mode)
		return self:SetAirMode(class, mode);
	end
);

