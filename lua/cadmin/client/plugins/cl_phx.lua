local PLUGIN = CAdmin.Plugins.Create ("PHX")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides PHX entity finding support.")

function PLUGIN:Initialize ()
	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_phx/amraam.mdl")
	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_phx/ball.mdl")
	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_phx/cannonball.mdl")
	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_phx/mk-82.mdl")
	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_phx/oildrum001_explosive.mdl")
	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_phx/torpedo.mdl")
	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_phx/ww2bomb.mdl")
	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_phx/misc/flakshell_big.mdl")
end