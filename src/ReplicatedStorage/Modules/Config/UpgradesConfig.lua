--[[
  UpgradesConfig
  Responsibility: Upgrade definitions, costs, and effect math.
]]

local UpgradesConfig = {}

UpgradesConfig.MaxTier = 10
UpgradesConfig.CostScale = 1.35

UpgradesConfig.Upgrades = {
	StompRadius = {
		baseCost = 60,
		perTierMultiplier = 0.07,
		description = "Increase Stomp radius",
	},
	CooldownReduction = {
		baseCost = 75,
		perTierMultiplier = 0.04,
		description = "Reduce ability cooldowns",
	},
	MoveSpeed = {
		baseCost = 80,
		perTierMultiplier = 0.05,
		description = "Increase move speed",
	},
	SizeLevel = {
		baseCost = 120,
		perTierMultiplier = 0.08,
		description = "Increase kaiju size",
	},
	RageMultiplier = {
		baseCost = 100,
		perTierMultiplier = 0.06,
		description = "Increase Rage earned",
	},
}

function UpgradesConfig.GetCost(upgradeId, currentLevel)
	local def = UpgradesConfig.Upgrades[upgradeId]
	if not def then
		return nil
	end
	local scaled = def.baseCost * (UpgradesConfig.CostScale ^ currentLevel)
	return math.floor(scaled)
end

function UpgradesConfig.ClampLevel(level)
	return math.clamp(level, 0, UpgradesConfig.MaxTier)
end

function UpgradesConfig.GetLevel(upgradesData, upgradeId)
	if not upgradesData then
		return 0
	end
	return UpgradesConfig.ClampLevel(upgradesData[upgradeId] or 0)
end

function UpgradesConfig.GetMultiplier(upgradesData, upgradeId)
	local def = UpgradesConfig.Upgrades[upgradeId]
	if not def then
		return 1
	end
	local level = UpgradesConfig.GetLevel(upgradesData, upgradeId)
	return 1 + (def.perTierMultiplier * level)
end

function UpgradesConfig.ApplyAbilityScaling(base, upgradesData)
	local scaled = {
		radius = base.baseRadius,
		damage = base.baseDamage,
		cooldown = base.baseCooldown,
		range = base.baseRange,
		coneDotThreshold = base.coneDotThreshold,
		maxRange = base.maxRange,
	}

	local cooldownReduction = UpgradesConfig.GetMultiplier(upgradesData, "CooldownReduction")
	scaled.cooldown = math.max(0.5, base.baseCooldown / cooldownReduction)

	local stompRadius = UpgradesConfig.GetMultiplier(upgradesData, "StompRadius")
	if base.baseRadius then
		scaled.radius = base.baseRadius * stompRadius
	end

	return scaled
end

function UpgradesConfig.GetMoveSpeedMultiplier(upgradesData)
	return UpgradesConfig.GetMultiplier(upgradesData, "MoveSpeed")
end

function UpgradesConfig.GetSizeLevelBonus(upgradesData)
	return UpgradesConfig.GetLevel(upgradesData, "SizeLevel")
end

function UpgradesConfig.GetRageMultiplier(upgradesData)
	return UpgradesConfig.GetMultiplier(upgradesData, "RageMultiplier")
end

function UpgradesConfig.GetDefaultData()
	return {
		StompRadius = 0,
		CooldownReduction = 0,
		MoveSpeed = 0,
		SizeLevel = 0,
		RageMultiplier = 0,
	}
end

return UpgradesConfig
