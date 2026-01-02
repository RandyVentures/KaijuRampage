--[[
  HUDController
  Responsibility: Build HUD UI for Rage, Size, and ability buttons with cooldowns.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local abilityRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AbilityRequest")
local uiStateRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UIState")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KaijuHUD"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 60)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BackgroundTransparency = 0.2
topBar.BorderSizePixel = 0
topBar.Parent = screenGui

local rageLabel = Instance.new("TextLabel")
rageLabel.Name = "RageLabel"
rageLabel.Text = "Rage: 0"
rageLabel.Font = Enum.Font.GothamBold
rageLabel.TextSize = 20
rageLabel.TextColor3 = Color3.fromRGB(255, 170, 70)
rageLabel.BackgroundTransparency = 1
rageLabel.Size = UDim2.new(0, 200, 1, 0)
rageLabel.Parent = topBar

local sizeLabel = Instance.new("TextLabel")
sizeLabel.Name = "SizeLabel"
sizeLabel.Text = "Size: 1"
sizeLabel.Font = Enum.Font.GothamBold
sizeLabel.TextSize = 20
sizeLabel.TextColor3 = Color3.fromRGB(120, 210, 255)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Size = UDim2.new(0, 200, 1, 0)
sizeLabel.Position = UDim2.new(0, 210, 0, 0)
sizeLabel.Parent = topBar

local abilitiesFrame = Instance.new("Frame")
abilitiesFrame.Name = "Abilities"
abilitiesFrame.Size = UDim2.new(1, 0, 0, 110)
abilitiesFrame.Position = UDim2.new(0, 0, 1, -120)
abilitiesFrame.BackgroundTransparency = 1
abilitiesFrame.Parent = screenGui

local cooldownOverlays = {}
local cooldownEndTimes = {}

local function createAbilityButton(labelText, abilityName, position)
	local button = Instance.new("TextButton")
	button.Name = abilityName .. "Button"
	button.Text = labelText
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	button.BorderSizePixel = 0
	button.Size = UDim2.new(0, 120, 0, 80)
	button.Position = position
	button.Parent = abilitiesFrame

	local overlay = Instance.new("Frame")
	overlay.Name = "Cooldown"
	overlay.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.new(1, 0, 0, 0)
	overlay.Position = UDim2.new(0, 0, 1, 0)
	overlay.Parent = button

	cooldownOverlays[abilityName] = overlay

	button.Activated:Connect(function()
		abilityRemote:FireServer(abilityName, os.clock())
	end)
end

createAbilityButton("1 Stomp", "Stomp", UDim2.new(0.5, -190, 0, 10))
createAbilityButton("2 Tail", "TailSwipe", UDim2.new(0.5, -60, 0, 10))
createAbilityButton("3 Roar", "Roar", UDim2.new(0.5, 70, 0, 10))

local function updateCooldownOverlays()
	local now = os.clock()
	for ability, endTime in pairs(cooldownEndTimes) do
		local remaining = endTime - now
		local overlay = cooldownOverlays[ability]
		if overlay then
			if remaining <= 0 then
				overlay.Size = UDim2.new(1, 0, 0, 0)
				overlay.Position = UDim2.new(0, 0, 1, 0)
				cooldownEndTimes[ability] = nil
			else
				local duration = overlay:GetAttribute("CooldownDuration") or remaining
				local ratio = math.clamp(remaining / duration, 0, 1)
				overlay.Size = UDim2.new(1, 0, ratio, 0)
				overlay.Position = UDim2.new(0, 0, 1 - ratio, 0)
			end
		end
	end
end

uiStateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.type == "Rage" or payload.type == "Profile" then
		local rage = payload.rage
		if rage ~= nil then
			rageLabel.Text = "Rage: " .. tostring(rage)
		end
		local sizeLevel = payload.sizeLevel
		if sizeLevel ~= nil then
			sizeLabel.Text = "Size: " .. tostring(sizeLevel)
		end
	elseif payload.type == "Cooldown" then
		local duration = payload.duration or 0
		cooldownEndTimes[payload.ability] = os.clock() + duration
		local overlay = cooldownOverlays[payload.ability]
		if overlay then
			overlay:SetAttribute("CooldownDuration", duration)
		end
	end
end)

local function bindLeaderstats()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local rageValue = leaderstats:FindFirstChild("Rage")
	if rageValue then
		rageLabel.Text = "Rage: " .. tostring(rageValue.Value)
		rageValue.Changed:Connect(function(newValue)
			rageLabel.Text = "Rage: " .. tostring(newValue)
		end)
	end
	local sizeValue = leaderstats:FindFirstChild("SizeLevel")
	if sizeValue then
		sizeLabel.Text = "Size: " .. tostring(sizeValue.Value)
		sizeValue.Changed:Connect(function(newValue)
			sizeLabel.Text = "Size: " .. tostring(newValue)
		end)
	end
end

player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		bindLeaderstats()
	end
end)

bindLeaderstats()

RunService.RenderStepped:Connect(updateCooldownOverlays)

return nil
