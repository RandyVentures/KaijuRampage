--[[
  ShopController
  Responsibility: Simple upgrade shop UI and purchase requests.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpgradesConfig = require(ReplicatedStorage.Modules.Config.UpgradesConfig)

local player = Players.LocalPlayer
local purchaseRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PurchaseRequest")
local uiStateRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UIState")

local screenGui = player:WaitForChild("PlayerGui"):WaitForChild("KaijuHUD")

local shopToggle = Instance.new("TextButton")
shopToggle.Name = "ShopToggle"
shopToggle.Text = "Upgrades"
shopToggle.Font = Enum.Font.GothamBold
shopToggle.TextSize = 18
shopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
shopToggle.BorderSizePixel = 0
shopToggle.Size = UDim2.new(0, 120, 0, 36)
shopToggle.Position = UDim2.new(1, -130, 0, 12)
shopToggle.Parent = screenGui

local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.Size = UDim2.new(0, 300, 0, 280)
panel.Position = UDim2.new(1, -320, 0, 60)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Text = "Upgrade Shop"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 30)
title.Parent = panel

local list = Instance.new("Frame")
list.Name = "List"
list.Size = UDim2.new(1, 0, 1, -40)
list.Position = UDim2.new(0, 0, 0, 34)
list.BackgroundTransparency = 1
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local upgradeRows = {}
local profileUpgrades = {}

local function requestUpgrade(upgradeId)
	purchaseRemote:FireServer({
		type = "Upgrade",
		upgradeId = upgradeId,
	})
end

local function createRow(upgradeId, def)
	local row = Instance.new("Frame")
	row.Name = upgradeId
	row.Size = UDim2.new(1, -10, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	row.BorderSizePixel = 0
	row.Parent = list

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Text = upgradeId
	label.Font = Enum.Font.Gotham
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.55, 0, 1, 0)
	label.Parent = row

	local button = Instance.new("TextButton")
	button.Name = "Buy"
	button.Text = "Buy"
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundColor3 = Color3.fromRGB(50, 90, 45)
	button.BorderSizePixel = 0
	button.Size = UDim2.new(0.45, -8, 0, 32)
	button.Position = UDim2.new(0.55, 4, 0.5, -16)
	button.Parent = row
	button.Activated:Connect(function()
		requestUpgrade(upgradeId)
	end)

	upgradeRows[upgradeId] = {
		row = row,
		button = button,
		label = label,
	}
end

for upgradeId, def in pairs(UpgradesConfig.Upgrades) do
	createRow(upgradeId, def)
end

local function refreshRows()
	for upgradeId, row in pairs(upgradeRows) do
		local level = UpgradesConfig.GetLevel(profileUpgrades, upgradeId)
		local cost = UpgradesConfig.GetCost(upgradeId, level)
		row.label.Text = string.format("%s (Lv %d)", upgradeId, level)
		if level >= UpgradesConfig.MaxTier then
			row.button.Text = "Max"
			row.button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			row.button.Active = false
		else
			row.button.Text = "Buy - " .. tostring(cost)
			row.button.BackgroundColor3 = Color3.fromRGB(50, 90, 45)
			row.button.Active = true
		end
	end
end

uiStateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.type == "Profile" and payload.upgrades then
		profileUpgrades = payload.upgrades
		refreshRows()
	elseif payload.type == "PurchaseResult" and payload.data then
		local upgradeId = payload.data.upgradeId
		if upgradeId and payload.data.newLevel then
			profileUpgrades[upgradeId] = payload.data.newLevel
			refreshRows()
		end
	end
end)

shopToggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

refreshRows()

return nil
