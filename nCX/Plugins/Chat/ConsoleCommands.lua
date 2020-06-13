ConsoleCommands = {

	--do we need that? almost every consolecommand has been implemented as chatcommand

	Commands = {};

	OnInit = function(self)
		for command, code in pairs(CryMP.Library) do
			if (type(code) == "function") then
				--add
			end
		end
	end;

	Execute = function(self, command, ...)
		local arg = {...};
		if (CryMP.Library[command]) then
			luasuccess, success, err = pcall(CryMP.Library[command], CryMP.Library, unpack(arg));
			local msg = "mod_"..self.Commands[command].Class.." "..table.concat(arg, " ");
			local feedback;
			if (not luasuccess) then
				CryMP.ErrorHandler:HandleConsoleCommand(success, command, msg);
				feedback = "$4failed: LUA ERROR";
			elseif (success) then
				feedback = "$3success";
			elseif (err and not success) then
				feedback = "$4failed: "..err;
			end
			if (CryMP.CommandLogging) then
				CryMP.CommandLogging:Log(player, msg, feedback or "$6no feedback", true)
			end
		end
	end;

	Add = function(self, class, func, args, desc)
		class = string.gsub(string.lower(class), "mod_", "");
		func = string.lower(func)
		local vars = nil;
		self.Commands[func] = {Args = args, Class = class, Func = func, Desc = desc};
		local command = "mod_"..class;
		if (args) then
			if (args[#args]=="message" or args[#args]=="reason" or args[#args]=="mod" or args[#args]=="team") then
				vars = "\%\%";
			else
				vars = "\%1";
				for i=2, #args do
					vars = vars..", \%"..i;
				end
			end
		end
		if (vars) then
		   func = "CryMP.ConsoleCommands.Execute(CryMP.ConsoleCommands, \'"..func.."\', "..vars..")";
		else
		   func = "CryMP.ConsoleCommands.Execute(CryMP.ConsoleCommands, \'"..func.."\')";
		end

		System.AddCCommand(command, func, desc);
	end;
};
