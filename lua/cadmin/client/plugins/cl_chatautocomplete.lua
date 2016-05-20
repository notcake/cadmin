local PLUGIN = CAdmin.Plugins.Create ("Chat Autocompletion")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides autocompletion for chat commands.")

function PLUGIN:Initialize ()
	self.AutocompleteText = ""
	self.AutocompleteSelected = 1
	self.AutocompleteSuggestions = {}

	CAdmin.Chat.AddChatTextChangeHook (function (text)
		local c = text:sub (1, 1)
		if c ~= "!" and c ~= "/" and c ~= "#" then
			text = ""
		end
		if text != self.AutocompleteText then
			self.AutocompleteText = text
			self:Autocomplete (text)
		end
	end)
	
	CAdmin.Hooks.Add ("HUDPaint", "CAdmin.Chat.Autocomplete", function ()
		if CAdmin.Settings.GetSession ("CAdmin.ChatAutocomplete.Enabled", true) then
			self:DrawAutocomplete ()
		end
	end)

	CAdmin.Chat.AddCompletionHook ("CAdmin.Chat.Autocomplete", function (chatText)
		return self.AutocompleteSuggestions [self.AutocompleteSelected]
	end)

	self.KeyUp = false
	self.LastKeyUp = 0
	self.LastRepeatKeyUp = 0
	self.KeyDown = false
	self.LastKeyDown = 0
	self.LastRepeatKeyDown = 0
	CAdmin.Hooks.Add ("Think", "CAdmin.Chat.Autocomplete", function ()
		local repeatwait = 1
		local repeatdelay = 0.1
		if input.IsKeyDown (KEY_UP) then
			local scroll = false
			if not self.KeyUp then
				scroll = true
				self.LastKeyUp = RealTime ()
			else
				if RealTime () - self.LastKeyUp > repeatwait then
					if RealTime () - self.LastRepeatKeyUp > repeatdelay then
						self.LastRepeatKeyUp = RealTime ()
						scroll = true
					end
				end
			end
			if scroll then
				self.AutocompleteSelected = self.AutocompleteSelected - 1
				if self.AutocompleteSelected < 1 then
					self.AutocompleteSelected = #self.AutocompleteSuggestions
				end
			end
			self.KeyUp = true
		else
			self.KeyUp = false
		end
		if input.IsKeyDown (KEY_DOWN) then
			local scroll = false
			if not self.KeyDown then
				scroll = true
				self.LastKeyDown = RealTime ()
			else
				if RealTime () - self.LastKeyDown > repeatwait then
					if RealTime () - self.LastRepeatKeyDown > repeatdelay then
						self.LastRepeatKeyDown = RealTime ()
						scroll = true
					end
				end
			end
			if scroll then
				self.AutocompleteSelected = self.AutocompleteSelected + 1
				if self.AutocompleteSelected > #self.AutocompleteSuggestions then
					self.AutocompleteSelected = 1
				end
			end
			self.KeyDown = true
		else
			self.KeyDown = false
		end
	end)
end

function PLUGIN:Autocomplete (text)
	self.AutocompleteSelected = 1
	if text:len () == 0 then
		table.Empty (self.AutocompleteSuggestions)
		return
	end
	self.AutocompleteSuggestions = CAdmin.Util.PrependString (CAdmin.Commands.Autocomplete (CAdmin.Commands.COMMAND_CHAT, text:sub (2)), text:sub (1, 1))
end

function PLUGIN:DrawAutocomplete ()
	local drawn = 0
	local x, y = chat.GetChatBoxPos ()
	local x = x + 10 / 800 * ScrW ()
	local y = y + 120 / 480 * ScrH ()

	surface.SetFont ("ChatFont")
	local w = 0
	if CAdmin.Chat.GetInputMode () == CAdmin.Chat.CHAT_PUBLIC then
		w = surface.GetTextSize ("Say :")
	else
		w = surface.GetTextSize ("Say (TEAM) :")
	end
	x = x + w + 7
	local limit = 432 / 480 * ScrH ()

	local highlightwidth = 280 / 800 * ScrW () - w - 3
	local lineheight = 16
	local numlines = limit - y
	numlines = math.floor (numlines / lineheight)

	-- Now work out which lines to draw

	local first = math.floor (self.AutocompleteSelected - numlines / 2)
	if first < 1 then
		first = 1
	end
	local last = first + numlines
	if last > #self.AutocompleteSuggestions then
		first = #self.AutocompleteSuggestions - numlines
		last = #self.AutocompleteSuggestions
	end
	if first < 1 then
		first = 1
	end
	for i = first, last do
		if not self.AutocompleteSuggestions [i] then
			break
		end
		if i == self.AutocompleteSelected then
			local textwidth = surface.GetTextSize (self.AutocompleteSuggestions [i]) + 4
			if textwidth > highlightwidth then
				highlightwidth = textwidth
			end
			draw.RoundedBox (4, x - 2, y, highlightwidth, lineheight, Color (0, 128, 255, 255))
		end
		draw.DrawText (self.AutocompleteSuggestions [i], "ChatFont", x, y, Color (255, 255, 255, 255))
		y = y + lineheight
		drawn = drawn + 1
	end
end