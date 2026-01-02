--[[
  PurchaseService
  Responsibility: Handle upgrade purchases and basic monetization hooks.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceLocator = require(ReplicatedStorage.Modules.Shared.ServiceLocator)
local UpgradesConfig = require(ReplicatedStorage.Modules.Config.UpgradesConfig)
local RemoteUtil = require(ReplicatedStorage.Modules.Shared.RemoteUtil)

local PurchaseService = {}

local purchaseRemote = RemoteUtil.GetOrCreateRemote("Remotes", "PurchaseRequest", "RemoteEvent")

local function sendPurchaseResult(player, success, message, data)
	local uiState = RemoteUtil.GetOrCreateRemote("Remotes", "UIState", "RemoteEvent")
	uiState:FireClient(player, {
		type = "PurchaseResult",
		success = success,
		message = message,
		data = data,
	})
end

local function handleUpgradePurchase(player, upgradeId)
	local antiExploit = ServiceLocator.Get("AntiExploit")
	if antiExploit and not antiExploit.CheckRateLimit(player, "PurchaseRequest", 6, 4) then
		sendPurchaseResult(player, false, "Too many requests")
		return
	end

	local economyService = ServiceLocator.Get("EconomyService")
	if not economyService then
		sendPurchaseResult(player, false, "Service unavailable")
		return
	end

	local profile = economyService.GetProfile(player)
	if not profile then
		sendPurchaseResult(player, false, "Profile unavailable")
		return
	end

	if not UpgradesConfig.Upgrades[upgradeId] then
		sendPurchaseResult(player, false, "Invalid upgrade")
		return
	end

	local currentLevel = UpgradesConfig.GetLevel(profile.Upgrades, upgradeId)
	if currentLevel >= UpgradesConfig.MaxTier then
		sendPurchaseResult(player, false, "Max tier reached")
		return
	end

	local cost = UpgradesConfig.GetCost(upgradeId, currentLevel)
	if not economyService.SpendRage(player, cost) then
		sendPurchaseResult(player, false, "Not enough Rage")
		return
	end

	profile.Upgrades[upgradeId] = currentLevel + 1
	economyService.ApplyPlayerStats(player)

	sendPurchaseResult(player, true, "Upgrade purchased", {
		upgradeId = upgradeId,
		newLevel = profile.Upgrades[upgradeId],
	})
end

purchaseRemote.OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.type == "Upgrade" then
		handleUpgradePurchase(player, payload.upgradeId)
	end
end)

ServiceLocator.Register("PurchaseService", PurchaseService)

return PurchaseService
