CAdmin.RequireInclude ("sh_lua")
CAdmin.Util = CAdmin.Util or {}
local Util = CAdmin.Util

function Util.CharToHexString (charString)
		return string.format ("%%%02X", string.byte (charString))
end

-- Explode an argument string.
function Util.ExplodeQuotedString (arguments)
	local argumentList = {}
	local currentPart = nil
	local quoteType = nil
	local startingNewPart = false
	
	local argumentsLength = arguments:len ()
	for i = 1, argumentsLength do
		local c = arguments:sub (i, i)
	
		-- These control what happens to the character.
		local shouldAppendToPart = true
		local nextstr = nil
		startingNewPart = false
		if c == " " or c == "\t" then
			--[[
				Whitespace - new part if not enclosed by quotation marks.
			]]
			if not quoteType then
				shouldAppendToPart = false
				startingNewPart = true
			end
		else
			if c == "\"" or c == "'" then
				--[[
					Quotation marks - try to match them, otherwise, if not already
					in a quotation, start a new part.
				]]
				if quoteType then
					if quoteType == c then
						quoteType = nil
						startingNewPart = true
						currentPart = currentPart or ""
						shouldAppendToPart = false
					end
				else
					startingNewPart = true
					quoteType = c
					shouldAppendToPart = false
				end
			end
		end
		if shouldAppendToPart then
			currentPart = (currentPart or "") .. c
		elseif startingNewPart then
			if currentPart then
				argumentList [#argumentList + 1] = currentPart
				currentPart = nil
			end
		end
	end
	if currentPart then
		argumentList [#argumentList + 1] = currentPart
		currentPart = nil
	elseif startingNewPart then
		argumentList [#argumentList + 1] = ""
	end
	if #argumentList == 0 then
		argumentList [1] = ""
	end
	return argumentList
end

function Util.GetStringBytes (str)
	if not str then
		return {}
	end
	local length = str:len ()
	local bytes = {}
	for i = 1, length do
		bytes [#bytes + 1] = str:byte (i)
	end
	return bytes
end

function Util.GetStringChars (str)
	if not str then
		return {}
	end
	local length = str:len ()
	local chars = {}
	for i = 1, length do
		chars [#chars + 1] = str:sub (i, i)
	end
	return chars
end

function Util.GetStringWidth (str)
	if not str then
		return 0
	end
	local length = str:len ()
	local width = 0

	-- UTF-8
	local in_sequence = false
	local sequence_length = 0
	for i = 1, length do
		local c = str:byte (i)
		if c >= 194 and c <= 223 then
			in_sequence = true
			sequence_length = 2
			width = width + 1
		end
		if c >= 224 and c <= 239 then
			in_sequence = true
			sequence_length = 3
			width = width + 1
		end
		if c >= 240 and c <= 244 then
			in_sequence = true
			sequence_length = 3
			width = width + 1
		end
		if c <= 127 then
			width = width + 1
		end
	end
	return width
end

function Util.HexStringToChar (hexString)
	return string.char (tonumber ("0x" .. hexString, 16))
end

function Util.IsTableEmpty (tbl)
	if not tbl then
		return true
	end
	return next (tbl) == nil and true or false
end

function Util.PopBack (array)
	local arraySize = #array
	local lastItem = array [arraySize]
	array [arraySize] = nil
	return lastItem
end

function Util.PopFront (array)
	local firstItem = array [1]
	local arraySize = #array
	for i = 1, arraySize do
		array [i] = array [i + 1]
	end
	return firstItem
end

function Util.PushFront (array, firstItem)
	local arraySize = #array + 1
	for i = arraySize + 1, 1, -1 do
		array [i] = array [i - 1]
	end
	array [1] = firstItem
end

function Util.PrependString (tbl, str)
	for k, v in ipairs (tbl) do
		tbl [k] = str .. v
	end
	return tbl
end

--[[
	Places a string in quotation marks for use in the console if needed.
]]
function Util.QuoteConsoleString (str)
	if str:find ("[ '¦£()]") or str == "" then
		return "\"" .. str .. "\""
	end
	return str
end

function Util.QuoteConsoleStrings (stringList)
	for i = 1, #stringList do
		stringList [i] = Util.QuoteConsoleString (stringList [i])
	end
	return stringList
end

function Util.ReindexArray (array)
	local newArray = {}
	for _, v in pairs (array) do
		newArray [#newArray + 1] = v
	end
	return newArray
end

function Util.RemoveEmptyTables (array)
	local arraySize = #array
	for i = 1, arraySize do
		if type (array [i]) == "table" and Util.IsTableEmpty (array [i]) then
			array [i] = nil
		end
	end
	return array
end

--[[
	Attempts to reverse a CRC by brute force.
	Extremely slow for anything other than small inputs.
]]
function Util.ReverseCRC (crc, length, charSet)
	crc = tostring (crc)
	local characters = {}
	local characterCount = charSet:len ()
	for i = 1, characterCount do
		characters [i] = charSet:sub (i, i)
	end
	local str = ""
	local stringChars = {}
	for i = 1, length do
		stringChars [i] = 1
		str = str .. characters [1]
	end

	while true do
		if util.CRC (str) == crc then
			return str
		end
		local outOfStrings = true
		for i = 1, length do
			stringChars [i] = stringChars [i] + 1
			if stringChars [i] > characterCount then
				stringChars [i] = 1
			else
				outOfStrings = false
			end
			str = str:sub (1, i - 1) .. characters [stringChars [i]] .. str:sub (i + 1, length)
			if not outOfStrings then
				break
			end
		end
		if outOfStrings then
			return nil
		end
	end
	return nil
end

function Util.URLDecode (text)
	if not text then
		return ""
	end
	text = string.gsub (text, "%%(%x%x)", CAdmin.Util.HexStringToChar)
	return text
end

function Util.URLEncodeCapitals (text)
	if not text then
		return ""
	end
	text = string.gsub (text, "([A-Z%%])", CAdmin.Util.CharToHexString)
	return text
end