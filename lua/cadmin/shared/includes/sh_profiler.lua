CAdmin.RequireInclude ("sh_debug")

CAdmin.Profiler = CAdmin.Profiler or {}
local Profiler = CAdmin.Profiler

Profiler.CallStack = Profiler.CallStack or {}
Profiler.Functions = Profiler.Functions or {}
Profiler.FunctionCount = Profiler.FunctionCount or 0

for _, v in ipairs (Profiler.CallStack) do
	Profiler.Functions [v.Name] = {
		Calls = 1,
		Name = v.Name,
		TotalTime = 0
	}
end

function Profiler.EnterFunction (functionName, description)
	if not functionName then
		return
	end
	local startTime = os.clock ()
	local functionInfo = Profiler.CallStack [#Profiler.CallStack]
	if functionInfo then
		Profiler.Functions [functionInfo.Name].TotalTime = Profiler.Functions [functionInfo.Name].TotalTime + startTime - functionInfo.StartTime
	end
	
	functionInfo = {
		Description = description,
		Name = functionName,
		RealStartTime = startTime,
		StartTime = startTime
	}
	Profiler.CallStack [#Profiler.CallStack + 1] = functionInfo
	if Profiler.Functions [functionName] then
		Profiler.Functions [functionName].Calls = Profiler.Functions [functionName].Calls + 1
	else
		Profiler.Functions [functionName] = {
			Calls = 1,
			Name = functionName,
			TotalTime = 0
		}
		Profiler.FunctionCount = Profiler.FunctionCount + 1
	end
end

function Profiler.ExitFunction ()
	local functionInfo = Profiler.CallStack [#Profiler.CallStack]
	Profiler.CallStack [#Profiler.CallStack] = nil
	
	if not functionInfo then
		return
	end
	
	local endTime = os.clock ()
	local totalTime = endTime - functionInfo.RealStartTime
	if totalTime > 0 and CAdmin.Debug.GetDebugMode () > 0 then
		if functionInfo.Description then
			print (string.rep ("    ", #Profiler.CallStack) .. functionInfo.Name .. " (" .. functionInfo.Description .. ") took " .. string.format ("%.3f", totalTime) .. " seconds.")
		else
			print (string.rep ("    ", #Profiler.CallStack) .. functionInfo.Name .. " took " .. string.format ("%.3f", totalTime) .. " seconds.")
		end
	end
	Profiler.Functions [functionInfo.Name].TotalTime = Profiler.Functions [functionInfo.Name].TotalTime + endTime - functionInfo.StartTime
	
	functionInfo = Profiler.CallStack [#Profiler.CallStack]
	if functionInfo then
		functionInfo.StartTime = os.clock ()
	end
end

local function SortFunctionData (a, b)
	return a.TotalTime > b.TotalTime
end

function Profiler.PrintData ()
	print (tostring (Profiler.FunctionCount) .. " functions profiled.")
	local functions = {}
	for _, v in pairs (Profiler.Functions) do
		functions [#functions + 1] = v
	end
	table.sort (functions, SortFunctionData)
	for i = 1, #functions do
		local totalCalls = string.format ("%d", functions [i].Calls)
		local totalTime = string.format ("%.3f", functions [i].TotalTime)
		print (string.rep (" ", 8 - totalTime:len ()) .. totalTime .. ": " .. string.rep (" ", 4 - totalCalls:len ()) .. totalCalls.. ": " .. functions [i].Name)
	end
end