--[[
  MathUtil
  Responsibility: Shared geometry helpers for hit detection.
]]

local MathUtil = {}

function MathUtil.IsInCone(origin, forward, targetPosition, range, dotThreshold)
	local offset = targetPosition - origin
	local distance = offset.Magnitude
	if distance > range then
		return false
	end
	if distance == 0 then
		return true
	end
	local direction = offset.Unit
	local dot = forward:Dot(direction)
	return dot >= dotThreshold
end

function MathUtil.IsInRadius(origin, targetPosition, radius)
	return (targetPosition - origin).Magnitude <= radius
end

return MathUtil
