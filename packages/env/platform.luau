export type Platform = "roblox" | "lune" | "unknown"

local platform = {}

local cachedPlatform = nil

local function detectPlatform()
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

function platform.getPlatform(): Platform
	if cachedPlatform then
		return cachedPlatform
	end

	local plat = detectPlatform()
	cachedPlatform = plat
	return plat
end

return platform
