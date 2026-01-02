--[[
  BuildingsConfig
  Responsibility: Default building attribute values and utility helpers.
]]

local BuildingsConfig = {}

BuildingsConfig.Defaults = {
	Health = 100,
	Reward = 10,
	RespawnSeconds = 45,
}

function BuildingsConfig.ApplyDefaults(buildingModel)
	if not buildingModel:GetAttribute("MaxHealth") then
		buildingModel:SetAttribute("MaxHealth", BuildingsConfig.Defaults.Health)
	end
	if not buildingModel:GetAttribute("Health") then
		buildingModel:SetAttribute("Health", buildingModel:GetAttribute("MaxHealth"))
	end
	if not buildingModel:GetAttribute("Reward") then
		buildingModel:SetAttribute("Reward", BuildingsConfig.Defaults.Reward)
	end
	if not buildingModel:GetAttribute("RespawnSeconds") then
		buildingModel:SetAttribute("RespawnSeconds", BuildingsConfig.Defaults.RespawnSeconds)
	end
	if buildingModel:GetAttribute("IsDestroyed") == nil then
		buildingModel:SetAttribute("IsDestroyed", false)
	end
end

return BuildingsConfig
