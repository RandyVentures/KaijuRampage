--[[
  VFXController
  Responsibility: Client-side camera shake and lightweight effects.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local uiStateRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UIState")

local activeShake = nil

local function startShake(intensity, duration)
	activeShake = {
		intensity = intensity,
		endTime = os.clock() + duration,
	}
end

RunService.RenderStepped:Connect(function()
	if not activeShake then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local now = os.clock()
	if now >= activeShake.endTime then
		activeShake = nil
		return
	end
	local offset = Vector3.new(
		(math.random() - 0.5) * activeShake.intensity,
		(math.random() - 0.5) * activeShake.intensity,
		0
	)
	camera.CFrame = camera.CFrame * CFrame.new(offset)
end)

uiStateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.type == "Cooldown" then
		startShake(0.15, 0.12)
	end
end)

return nil
