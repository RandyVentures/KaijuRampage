--[[
  CooldownUtil
  Responsibility: Simple per-player cooldown tracking utilities.
]]

local CooldownUtil = {}

function CooldownUtil.New()
	return {
		lastUsed = {},
	}
end

function CooldownUtil.CanUse(cooldownState, key, cooldownSeconds)
	local now = os.clock()
	local last = cooldownState.lastUsed[key] or 0
	return (now - last) >= cooldownSeconds
end

function CooldownUtil.MarkUsed(cooldownState, key)
	cooldownState.lastUsed[key] = os.clock()
end

function CooldownUtil.GetRemaining(cooldownState, key, cooldownSeconds)
	local now = os.clock()
	local last = cooldownState.lastUsed[key] or 0
	local remaining = cooldownSeconds - (now - last)
	if remaining < 0 then
		return 0
	end
	return remaining
end

return CooldownUtil
