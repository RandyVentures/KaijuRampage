--[[
  AbilitiesConfig
  Responsibility: Base ability parameters for Kaiju Rampage and scaling helpers.
]]

local AbilitiesConfig = {}

AbilitiesConfig.Abilities = {
	Stomp = {
		baseRadius = 18,
		baseDamage = 40,
		baseCooldown = 4,
		maxRange = 60,
	},
	TailSwipe = {
		baseRange = 22,
		baseDamage = 25,
		baseCooldown = 3,
		coneDotThreshold = 0.6,
		maxRange = 70,
	},
	Roar = {
		baseRadius = 24,
		baseDamage = 10,
		baseCooldown = 8,
		maxRange = 80,
	},
}

function AbilitiesConfig.GetBase(abilityName)
	return AbilitiesConfig.Abilities[abilityName]
end

return AbilitiesConfig
