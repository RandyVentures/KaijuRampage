--[[
  EconomyService
  Responsibility: Track Rage currency and apply player stat upgrades.
]]

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServiceLocator = require(ReplicatedStorage.Modules.Shared.ServiceLocator)
local UpgradesConfig = require(ReplicatedStorage.Modules.Config.UpgradesConfig)
local RemoteUtil = require(ReplicatedStorage.Modules.Shared.RemoteUtil)

local EconomyService = {}

local profiles = {}
local dataService

local uiStateRemote = RemoteUtil.GetOrCreateRemote("Remotes", "UIState", "RemoteEvent")

local function getProfile(player)
	return profiles[player.UserId]
end

local function ensureLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local rageValue = leaderstats:FindFirstChild("Rage")
	if not rageValue then
		rageValue = Instance.new("IntValue")
		rageValue.Name = "Rage"
		rageValue.Parent = leaderstats
	end

	local sizeValue = leaderstats:FindFirstChild("SizeLevel")
	if not sizeValue then
		sizeValue = Instance.new("IntValue")
		sizeValue.Name = "SizeLevel"
		sizeValue.Parent = leaderstats
	end

	return rageValue, sizeValue
end

local function updateUI(player)
	local profile = getProfile(player)
	if not profile then
		return
	end
	uiStateRemote:FireClient(player, {
		type = "Profile",
		rage = profile.Rage,
		sizeLevel = profile.SizeLevel,
		upgrades = profile.Upgrades,
	})
end

function EconomyService.SetProfile(player, profile)
	profiles[player.UserId] = profile
	local rageValue, sizeValue = ensureLeaderstats(player)
	rageValue.Value = profile.Rage
	sizeValue.Value = profile.SizeLevel
	updateUI(player)
end

function EconomyService.GetProfile(player)
	return getProfile(player)
end

function EconomyService.AddRage(player, amount, reason)
	local profile = getProfile(player)
	if not profile then
		return
	end
	local multiplier = UpgradesConfig.GetRageMultiplier(profile.Upgrades)
	local adjusted = math.floor(amount * multiplier)
	profile.Rage = math.max(0, profile.Rage + adjusted)
	local rageValue = ensureLeaderstats(player)
	rageValue.Value = profile.Rage
	uiStateRemote:FireClient(player, {
		type = "Rage",
		rage = profile.Rage,
		reason = reason or "",
	})
end

function EconomyService.SpendRage(player, amount)
	local profile = getProfile(player)
	if not profile then
		return false
	end
	if amount <= 0 then
		return false
	end
	if profile.Rage < amount then
		return false
	end
	profile.Rage -= amount
	local rageValue = ensureLeaderstats(player)
	rageValue.Value = profile.Rage
	uiStateRemote:FireClient(player, {
		type = "Rage",
		rage = profile.Rage,
	})
	return true
end

function EconomyService.ApplyPlayerStats(player)
	local profile = getProfile(player)
	if not profile then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local baseWalkSpeed = 16
	local baseJumpPower = 50
	local moveMultiplier = UpgradesConfig.GetMoveSpeedMultiplier(profile.Upgrades)
	local sizeBonus = UpgradesConfig.GetSizeLevelBonus(profile.Upgrades)

	humanoid.WalkSpeed = baseWalkSpeed * moveMultiplier
	humanoid.JumpPower = baseJumpPower

	profile.SizeLevel = 1 + sizeBonus
	local _, sizeValue = ensureLeaderstats(player)
	sizeValue.Value = profile.SizeLevel

	if humanoid.Parent then
		local depthScale = humanoid:FindFirstChild("BodyDepthScale")
		local heightScale = humanoid:FindFirstChild("BodyHeightScale")
		local widthScale = humanoid:FindFirstChild("BodyWidthScale")
		local headScale = humanoid:FindFirstChild("HeadScale")
		if depthScale then
			depthScale.Value = 1 + (profile.SizeLevel - 1) * 0.05
		end
		if heightScale then
			heightScale.Value = 1 + (profile.SizeLevel - 1) * 0.07
		end
		if widthScale then
			widthScale.Value = 1 + (profile.SizeLevel - 1) * 0.05
		end
		if headScale then
			headScale.Value = 1 + (profile.SizeLevel - 1) * 0.03
		end
	end

	updateUI(player)
end

Players.PlayerAdded:Connect(function(player)
	dataService = dataService or ServiceLocator.WaitFor("DataService", 10)
	if dataService then
		local profile = dataService.LoadProfile(player)
		EconomyService.SetProfile(player, profile)
	else
		EconomyService.SetProfile(player, {
			Rage = 0,
			SizeLevel = 1,
			Upgrades = UpgradesConfig.GetDefaultData(),
			OwnedCosmetics = {},
		})
	end

	player.CharacterAdded:Connect(function()
		EconomyService.ApplyPlayerStats(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	profiles[player.UserId] = nil
end)

ServiceLocator.Register("EconomyService", EconomyService)

return EconomyService
