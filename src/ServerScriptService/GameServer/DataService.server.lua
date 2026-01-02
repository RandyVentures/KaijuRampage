--[[
  DataService
  Responsibility: Load and save player data with retries and autosave.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServiceLocator = require(ReplicatedStorage.Modules.Shared.ServiceLocator)
local UpgradesConfig = require(ReplicatedStorage.Modules.Config.UpgradesConfig)

local DataService = {}

local dataStore = DataStoreService:GetDataStore("KaijuRampage_v1")
local autoSaveInterval = 90
local saving = {}

local function defaultProfile()
	return {
		Rage = 0,
		SizeLevel = 1,
		Upgrades = UpgradesConfig.GetDefaultData(),
		OwnedCosmetics = {},
	}
end

local function retry(operation, maxAttempts)
	local attempt = 0
	local delay = 1
	while attempt < maxAttempts do
		attempt += 1
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		if attempt < maxAttempts then
			task.wait(delay)
			delay *= 2
		end
	end
	return false, nil
end

function DataService.LoadProfile(player)
	local key = "player_" .. player.UserId
	local ok, data = retry(function()
		return dataStore:GetAsync(key)
	end, 3)

	if ok and data then
		data.Upgrades = data.Upgrades or UpgradesConfig.GetDefaultData()
		data.OwnedCosmetics = data.OwnedCosmetics or {}
		data.Rage = data.Rage or 0
		data.SizeLevel = data.SizeLevel or 1
		return data
	end

	return defaultProfile()
end

function DataService.SaveProfile(player, profile)
	if saving[player.UserId] then
		return false
	end
	local key = "player_" .. player.UserId
	saving[player.UserId] = true

	local ok = retry(function()
		dataStore:SetAsync(key, profile)
		return true
	end, 3)

	saving[player.UserId] = nil
	return ok
end

function DataService.SavePlayer(player)
	local economyService = ServiceLocator.Get("EconomyService")
	if not economyService then
		return false
	end
	local profile = economyService.GetProfile(player)
	if not profile then
		return false
	end
	return DataService.SaveProfile(player, profile)
end

local function autoSaveLoop()
	while true do
		task.wait(autoSaveInterval)
		for _, player in ipairs(Players:GetPlayers()) do
			DataService.SavePlayer(player)
		end
	end
end

task.spawn(autoSaveLoop)

Players.PlayerRemoving:Connect(function(player)
	DataService.SavePlayer(player)
end)

ServiceLocator.Register("DataService", DataService)

return DataService
