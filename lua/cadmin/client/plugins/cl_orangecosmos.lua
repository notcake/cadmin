local PLUGIN = CAdmin.Plugins.Create ("Orange Cosmos")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("I really do not want to create an account.")

function PLUGIN:Initialize ()
	if OCRegisterCL then
		local _, usermessageHooks = debug.getupvalue(usermessage.Hook,2)
		if usermessageHooks ["UsernameFree"] then
			local func = usermessageHooks ["UsernameFree"].Function
			local _, frame = debug.getupvalue (func, 3)
			frame:SetVisible (false)
		end
	end
end