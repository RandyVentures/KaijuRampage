--[[
  HUDController
  Responsibility: Build HUD UI for Rage, Size, and ability buttons with cooldowns.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local abilityRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AbilityRequest")
local abilityConfirmedRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AbilityConfirmed")
local uiStateRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UIState")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KaijuHUD"
screenGui.IgnoreGuiInset = false
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
abilitiesFrame.Size = UDim2.new(0, 360, 0, 90)
abilitiesFrame.Position = UDim2.new(1, -380, 1, -110)
abilitiesFrame.BackgroundTransparency = 1
abilitiesFrame.Parent = screenGui

local cooldownOverlays = {}
local cooldownEndTimes = {}
local cooldownLabels = {}
local abilityButtons = {}
local cooldownReadyAt = {}
local cooldownOffsets = {}
local debugLabel = nil

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
	abilityButtons[abilityName] = button

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.85
	stroke.Parent = button

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.6
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.Position = UDim2.new(0, -5, 0, 6)
	shadow.ZIndex = button.ZIndex - 1
	shadow.Parent = button

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 12)
	shadowCorner.Parent = shadow

	local overlay = Instance.new("Frame")
	overlay.Name = "Cooldown"
	overlay.BackgroundColor3 = Color3.fromRGB(20, 80, 140)
	overlay.BackgroundTransparency = 0.25
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.new(1, 0, 0, 0)
	overlay.Position = UDim2.new(0, 0, 1, 0)
	overlay.Parent = button

	cooldownOverlays[abilityName] = overlay

	local cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.Text = ""
	cooldownText.Font = Enum.Font.GothamBold
	cooldownText.TextSize = 22
	cooldownText.TextColor3 = Color3.fromRGB(255, 255, 255)
	cooldownText.BackgroundTransparency = 1
	cooldownText.Size = UDim2.new(1, 0, 1, 0)
	cooldownText.Visible = false
	cooldownText.Parent = button
	cooldownLabels[abilityName] = cooldownText

	button.Activated:Connect(function()
		abilityRemote:FireServer(abilityName, os.clock())
	end)
end

createAbilityButton("1 Stomp", "Stomp", UDim2.new(0.5, -190, 0, 10))
createAbilityButton("2 Tail", "TailSwipe", UDim2.new(0.5, -60, 0, 10))
createAbilityButton("3 Roar", "Roar", UDim2.new(0.5, 70, 0, 10))

if RunService:IsStudio() then
	debugLabel = Instance.new("TextLabel")
	debugLabel.Name = "CooldownDebug"
	debugLabel.Text = "Cooldowns: --"
	debugLabel.Font = Enum.Font.Gotham
	debugLabel.TextSize = 14
	debugLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	debugLabel.BackgroundTransparency = 1
	debugLabel.Size = UDim2.new(0, 320, 0, 20)
	debugLabel.Position = UDim2.new(0, 16, 1, -28)
	debugLabel.TextXAlignment = Enum.TextXAlignment.Left
	debugLabel.Parent = screenGui
end

local function updateCooldownOverlays()
	local now = os.clock()
	local debugParts = {}
	for ability, endTime in pairs(cooldownEndTimes) do
		local offset = cooldownOffsets[ability] or 0
		local readyAt = cooldownReadyAt[ability]
		local remaining = endTime - now
		if readyAt then
			local serverTimeApprox = now + offset
			remaining = readyAt - serverTimeApprox
		end
		local overlay = cooldownOverlays[ability]
		local label = cooldownLabels[ability]
		local button = abilityButtons[ability]
		if overlay then
			if remaining <= 0 then
				overlay.Size = UDim2.new(1, 0, 0, 0)
				overlay.Position = UDim2.new(0, 0, 1, 0)
				if label then
					label.Visible = false
					label.Text = ""
				end
				if button then
					local scale = button:FindFirstChild("ReadyPulse")
					if not scale then
						scale = Instance.new("UIScale")
						scale.Name = "ReadyPulse"
						scale.Parent = button
					end
					scale.Scale = 1
					local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true)
					TweenService:Create(scale, tweenInfo, {Scale = 1.08}):Play()
				end
				cooldownReadyAt[ability] = nil
				cooldownOffsets[ability] = nil
				cooldownEndTimes[ability] = nil
			else
				local duration = overlay:GetAttribute("CooldownDuration") or remaining
				local ratio = math.clamp(remaining / duration, 0, 1)
				overlay.Size = UDim2.new(1, 0, ratio, 0)
				overlay.Position = UDim2.new(0, 0, 1 - ratio, 0)
				if label then
					label.Visible = true
					label.Text = tostring(math.ceil(remaining))
				end
			end
		end
		if debugLabel and remaining > 0 then
			table.insert(debugParts, string.format("%s %.1fs", ability, math.max(0, remaining)))
		end
	end
	if debugLabel then
		if #debugParts == 0 then
			debugLabel.Text = "Cooldowns: --"
		else
			debugLabel.Text = "Cooldowns: " .. table.concat(debugParts, " | ")
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
		local now = os.clock()
		cooldownEndTimes[payload.ability] = now + duration
		if payload.serverNow and payload.readyAt then
			cooldownOffsets[payload.ability] = payload.serverNow - now
			cooldownReadyAt[payload.ability] = payload.readyAt
		end
		local overlay = cooldownOverlays[payload.ability]
		if overlay then
			overlay:SetAttribute("CooldownDuration", duration)
		end
		if RunService:IsStudio() then
			local readyAt = cooldownReadyAt[payload.ability]
			if readyAt then
				print(string.format(
					"[Cooldown] %s duration=%.2fs readyIn=%.2fs offset=%.3fs",
					tostring(payload.ability),
					duration,
					math.max(0, readyAt - (now + (cooldownOffsets[payload.ability] or 0))),
					cooldownOffsets[payload.ability] or 0
				))
			else
				print(string.format(
					"[Cooldown] %s duration=%.2fs (no server timestamp)",
					tostring(payload.ability),
					duration
				))
			end
		end
	end
end)

abilityConfirmedRemote.OnClientEvent:Connect(function(abilityName)
	if RunService:IsStudio() then
		print(string.format("[AbilityConfirmed] %s", tostring(abilityName)))
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
