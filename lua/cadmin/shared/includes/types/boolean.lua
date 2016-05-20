local TYPE = CAdmin.Commands.RegisterType ("Boolean")

TYPE:SetAutocomplete (
	{
		"true",
		"false"
	}
)

TYPE:RegisterConverter ("Number", function (ply, value)
	return value > 0
end)

TYPE:RegisterConverter ("String", function (ply, value)
	return tobool (value)
end)

TYPE:SetSerializer (function (ply, value)
	return tostring (value)
end)