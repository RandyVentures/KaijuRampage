--[[
  BuildingService
  Responsibility: Manage destructible buildings, damage, rewards, and respawn.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildingsConfig = require(ReplicatedStorage.Modules.Config.BuildingsConfig)
local ServiceLocator = require(ReplicatedStorage.Modules.Shared.ServiceLocator)

local BuildingService = {}

local buildingCache = {}

local function cacheBuilding(building)
	BuildingsConfig.ApplyDefaults(building)
	local parts = {}
	for _, descendant in ipairs(building:GetDescendants()) do
		if descendant:IsA("BasePart") then
			parts[descendant] = {
				CFrame = descendant.CFrame,
				Anchored = descendant.Anchored,
				Size = descendant.Size,
				Color = descendant.Color,
				Transparency = descendant.Transparency,
				CanCollide = descendant.CanCollide,
				Material = descendant.Material,
			}
		end
	end

	buildingCache[building] = {
		parts = parts,
	}
end

local function restoreBuilding(building)
	local cache = buildingCache[building]
	if not cache then
		return
	end

	for part, state in pairs(cache.parts) do
		if part and part:IsDescendantOf(building) then
			part.CFrame = state.CFrame
			part.Anchored = state.Anchored
			part.Size = state.Size
			part.Color = state.Color
			part.Transparency = state.Transparency
			part.CanCollide = state.CanCollide
			part.Material = state.Material
		end
	end

	building:SetAttribute("Health", building:GetAttribute("MaxHealth"))
	building:SetAttribute("IsDestroyed", false)
end

local function shatterBuilding(building)
	for _, descendant in ipairs(building:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			local impulse = Vector3.new(
				math.random(-30, 30),
				math.random(20, 45),
				math.random(-30, 30)
			)
			descendant:ApplyImpulse(impulse * descendant:GetMass())
		end
	end
end

function BuildingService.Init()
	for _, building in ipairs(CollectionService:GetTagged("DestructibleBuilding")) do
		if not buildingCache[building] then
			cacheBuilding(building)
		end
	end
end

function BuildingService.ApplyDamage(buildingModel, amount, player)
	if not buildingModel or not buildingModel:IsA("Model") then
		return
	end
	if amount <= 0 then
		return
	end

	local antiExploit = ServiceLocator.Get("AntiExploit")
	if antiExploit and not antiExploit.CheckRateLimit(player, "DamageBuilding", 10, 2) then
		return
	end

	BuildingsConfig.ApplyDefaults(buildingModel)
	if buildingModel:GetAttribute("IsDestroyed") then
		return
	end

	local health = buildingModel:GetAttribute("Health")
	health = math.max(0, health - amount)
	buildingModel:SetAttribute("Health", health)

	if health <= 0 then
		buildingModel:SetAttribute("IsDestroyed", true)
		shatterBuilding(buildingModel)
		local reward = buildingModel:GetAttribute("Reward") or 0
		local economyService = ServiceLocator.Get("EconomyService")
		if economyService and player then
			economyService.AddRage(player, reward, "BuildingBreak")
		end

		local respawnSeconds = buildingModel:GetAttribute("RespawnSeconds") or 30
		task.delay(respawnSeconds, function()
			restoreBuilding(buildingModel)
		end)
	end
end

CollectionService:GetInstanceAddedSignal("DestructibleBuilding"):Connect(function(building)
	if not buildingCache[building] then
		cacheBuilding(building)
	end
end)

BuildingService.Init()

ServiceLocator.Register("BuildingService", BuildingService)

return BuildingService
