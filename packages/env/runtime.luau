local runtime = {}

local cachedRuntime = nil

local function detectRuntime()
	if _G.UTIL_TARGET ~= nil then
		return _G.UTIL_TARGET
	else
		if string.sub(_VERSION, 1, 5):lower() == "lune " then
			return "lune"
		elseif typeof(script) == "Instance" then
			return "roblox"
		else
			return "unknown"
		end
	end
end

function runtime.getRuntime(): string
	if cachedRuntime then
		return cachedRuntime
	end

	local run = detectRuntime()
	cachedRuntime = run
	return run
end

return runtime
