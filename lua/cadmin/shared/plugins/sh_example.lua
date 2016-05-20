local PLUGIN = CAdmin.Plugins.Create ("Example")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Example plugin.")

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.Create ("testautocomplete", "Debugging", "Test Autocomplete")
	command:SetCommandType (CAdmin.COMMAND_CLIENT)
	command:SetConsoleCommand ("test_autocomplete")
	command:AddArgument ("String", nil, false, function (argument)
		print ("Autocomplete called with argument \"" .. argument .. "\".")
		return {"Autocomplete 1", "Autocomplete 2"}
	end)

	command:AddArgument ("Command", nil, true)
	command:AddArgument ("Player", nil, true)
	command:AddArgument ("Plugin", nil, true)
	command:AddArgument ("String", nil, true)
	command:SetExecute (function (ply, text)
		print ("Command called with parameter: \"" .. text .. "\".")
	end)

	command = CAdmin.Commands.Create ("testparams", "Debugging", "Test Parameters")
	command:SetCommandType (CAdmin.COMMAND_CLIENT)
	command:SetConsoleCommand ("test_params")
	command:AddArgument ("String")
	command:SetExecute (function (ply, text)
		print ("Command called with parameter: \"" .. text .. "\".")
	end)
end
