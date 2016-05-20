local TAB = TAB
TAB:SetName ("Entity Finder")
TAB:SetIcon ("gui/silkicons/magnifier.vmt")
TAB:SetTabPosition (1)
TAB:SetTooltip ("Find Entities.")

function TAB:Init ()
	self.MultiChoice = self:Create ("DMultiChoice")
	self.PlayerChoice = self:Create ("DMultiChoice")
	
	self.Refresh = self:Create ("CToolbarButton")
	self.Refresh:SetImage ("gui/silkicons/arrow_refresh")
	self.Refresh:SizeToContents ()
	self.Refresh.DoClick = function (button)
		self:PopulateItems (self.MultiChoice.SelectedData)
	end
	
	self.CommandList = self:Create ("CCommandList")
	self.CommandList:SetCommandArgumentType ("Entity")
	self.CommandList:PopulateCommands ()

	self.ListView = self:Create ("CListView")

	self.ListView:AddColumn ("Index")
	self.ListView:AddColumn ("Class Name")
	self.ListView:AddColumn ("Owner")
	self.ListView:AddColumn ("Model")
	self.ListView:SetObjectConverter ("Entity")
	self.ListView.Tab = self
	self.ListView:AddEventListener ("SelectionChanged",
		function (_)
			self.CommandList:SetCommandArgumentsList ({self.ListView:GetSelectedObjects ()})
			self.CommandList:PopulateCommands ()
		end
	)

	CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "Custom Filter", function (ent)
		return true
	end)

	CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "NPCs", function (ent)
		return ent:GetClass ():find ("npc_", 1, true) ~= nil
	end)

	CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "Players", function (ent)
		return ent:GetClass () == "player"
	end)
	
	CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "Minge Devices", function (ent)
		if CAdmin.Lists.IsInKVLists (
			{
				"CAdmin.ExplosiveEntities",
				"CAdmin.IgnitingEntities",
				"CAdmin.MingeDevices",
				"CAdmin.PropSpawningEntities",
				"CAdmin.TurretEntities",
			}, ent:GetClass ()) then
			return true
		end
		if ent:GetModel () and CAdmin.Lists.IsInKVList ("CAdmin.ExplosiveModels", ent:GetModel ():lower ()) then
			return true
		end
		return false
	end)
	CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "Explosives", function (ent)
		if CAdmin.Lists.IsInKVList ("CAdmin.ExplosiveEntities", ent:GetClass ()) then
			return true
		end
		if ent:GetModel () and CAdmin.Lists.IsInKVList ("CAdmin.ExplosiveModels", ent:GetModel ():lower ()) then
			return true
		end
		return false
	end)
	CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "Igniters", function (ent)
		if CAdmin.Lists.IsInKVLists (
			{
				"CAdmin.ExplosiveEntities",
				"CAdmin.IgnitingEntities",
				"CAdmin.TurretEntities"
			}, ent:GetClass ()) then
			return true
		end
		return false
	end)
	CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "Prop Spawners", function (ent)
		if CAdmin.Lists.IsInKVList ("CAdmin.PropSpawningEntities", ent:GetClass ()) then
			return true
		end
		return false
	end)
	CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "Turrets", function (ent)
		if CAdmin.Lists.IsInKVList ("CAdmin.TurretEntities", ent:GetClass ()) then
			return true
		end
		return false
	end)

	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveEntities", "gmod_dynamite")
	CAdmin.Lists.AddToKVList ("CAdmin.PropSpawningEntities", "gmod_spawner")
	CAdmin.Lists.AddToKVList ("CAdmin.TurretEntities", "gmod_turret")

	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_c17/oildrum001_explosive.mdl")
	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_junk/gascan001a.mdl")
	CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveModels", "models/props_junk/propane_tank001a.mdl")

	function self.MultiChoice.OnSelect (multichoice, index, value, data)
		self:PopulateItems ()
	end
	function self.PlayerChoice.OnSelect (multichoice, index, value, data)
		self:PopulateItems ()
	end

	self:PopulateChoices ()
end

function TAB:EntityPassesFilters (ent)
	local filterFunc = self.MultiChoice:GetSelectedData ()
	if not filterFunc then
		return false
	end
	if filterFunc (ent) then
		if self.PlayerChoice:GetSelectedData () then
			return self.PlayerChoice:GetSelectedData () (ent)
		end
		return true
	end
	return false
end

function TAB:PerformLayout (firstTime, ...)
	self.MultiChoice:SetPos (self:GetPadding (), self:GetPadding ())
	self.MultiChoice:SetSize ((self:GetWide () - 2 * self:GetPadding ()) * 0.4, 20)
	self.PlayerChoice:SetPos (self:GetPadding (), self:GetPadding () * 2 + self.MultiChoice:GetTall ())
	self.PlayerChoice:SetSize ((self:GetWide () - 2 * self:GetPadding ()) * 0.4, 20)

	self.Refresh:SetPos (self.MultiChoice:GetWide () + 2 * self:GetPadding (), self:GetPadding ())

	self.CommandList:PerformLayoutRight ()
	
	self.ListView:SetPos (self:GetPadding (), self.MultiChoice:GetTall () * 2 + self:GetPadding () * 3)
	self.ListView:SetSize (self:GetWide () - 3 * self:GetPadding () - self.CommandList:GetWide (), self:GetTall () - self.MultiChoice:GetTall () * 2 - self:GetPadding () * 4)

	if firstTime then
		self.ListView:GetColumn (1):SetWidth (48)
		self.ListView:GetColumn (2):SetWidth ((self.ListView:GetWide () - 48) * 0.3)
		self.ListView:GetColumn (3):SetWidth ((self.ListView:GetWide () - 48) * 0.3)
		self.ListView:GetColumn (4):SetWidth ((self.ListView:GetWide () - 48) * 0.4)
	end
end

function TAB:PopulateChoices ()
	self.MultiChoice:Clear ()
	local t = CAdmin.Lists.GetList ("CAdmin.EntityFinders")
	local tbl = {}
	for k, _ in pairs (t) do
		table.insert (tbl, k)
	end
	table.sort (tbl)
	for _, v in pairs (tbl) do
		local idx = self.MultiChoice:AddChoice (v, t [v])
		if v == "Minge Devices" then
			self.MultiChoice:ChooseOptionID (idx)
		end
	end
	
	self.PlayerChoice:Clear ()
	self.PlayerChoice:ChooseOptionID (self.PlayerChoice:AddChoice ("All", function (ent)
		return true
	end))
	self.PlayerChoice:AddChoice ("None", function (ent)
		return CAdmin.PropProtection.GetOwnerName (ent) == nil
	end)
	self.PlayerChoice:AddChoice ("World", function (ent)
		return CAdmin.PropProtection.GetOwnerName (ent) == "World"
	end)
	for _, ply in pairs (CAdmin.Players.GetPlayers ()) do
		self.PlayerChoice:AddChoice (ply:Name (), function (ent)
			return CAdmin.PropProtection.GetOwnerName (ent) == ply:Name ()
		end)
	end
end

local function SortEntityFunction (a, b)
	return a:EntIndex () < b:EntIndex ()
end

function TAB:PopulateItems ()
	local entityList = {}
	for _, v in pairs (ents.GetAll ()) do
		if self:EntityPassesFilters (v) then
			entityList [#entityList + 1] = v
		end
	end
	
	table.sort (entityList, SortEntityFunction)

	self.ListView:Clear ()
	local line = nil
	for _, v in ipairs (entityList) do
		line = self.ListView:AddLine (v:EntIndex (), v:GetClass (), CAdmin.PropProtection.GetOwnerName (v), v:GetModel ())
		line.Entity = v
	end
end