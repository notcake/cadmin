CAdmin.Timers = CAdmin.Timers or {}
local Timers = CAdmin.Timers
Timers.Timers = {}

function Timers.Create (timerName, delay, times, timerFunc, ...)
	if Timers.IsTimer (timerName) then
		Timers.Destroy (timerName)
	end
	timer.Create (timerName, delay, times, timerFunc, ...)
	Timers.Timers [timerName] = {
		Delay = delay,
		Times = times,
		TimesRun = 0,
		Callback = timerFunc,
		Arguments = {...}
	}
end

function Timers.Destroy (timerName)
	if not Timers.IsTimer (timerName) then
		return
	end
	timer.Destroy (timerName)
end

function Timers.IsTimer (timerName)
	if Timers.Timers [timerName] then
		return true
	end
	return timer.IsTimer (timerName)
end

function Timers.RunAfter (time, timerFunc, ...)
	timer.Simple (time, timerFunc, ...)
end

function Timers.RunEveryTick (timerName, timerFunc, ...)
	Timers.Create (timerName, 0, 0, timerFunc, ...)
end

function Timers.RunNextTick (timerFunc, ...)
	timer.Simple (0, timerFunc, ...)
end

-- Manual timer system
