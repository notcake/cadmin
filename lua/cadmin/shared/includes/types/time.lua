local TYPE = CAdmin.Commands.RegisterType ("Time")

TYPE:SetAutocomplete (function (time)
	return {
		"60",
		"1:00",
		"2:00",
		"6:00",
		"12:00",
		"1:00:00",
		"7:00:00"
	}
end)

TYPE:RegisterConverter ("String", function (ply, time)
	return 60
end)