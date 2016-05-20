local TYPE = CAdmin.Commands.RegisterType ("Command")

TYPE:SetAutocomplete (function (commandName)
	local ply = nil
	if CLIENT then
		ply = LocalPlayer ()
	else
		ply = CAdmin.Players.GetConsole ()
	end
	local commandList = {}
	local lowerName = commandName:lower ()
	local lowerNameLength = lowerName:len ()
	for k, v in pairs (CAdmin.Commands.GetConsoleCommands ()) do
		if k:sub (1, lowerNameLength) == lowerName then
			if CAdmin.Commands.CanExecute (ply, CAdmin.Commands.COMMAND_CONSOLE, k) or CAdmin.Commands.CanExecute (ply, CAdmin.Commands.COMMAND_CONSOLE, k, "*") then
				table.insert (commandList, k)
			end
		end
	end
	table.sort (commandList)
	return commandList
end)

TYPE:RegisterConverter ("String", function (ply, commandName)
	return CAdmin.Commands.GetConsoleCommand (commandName:lower ())
end)