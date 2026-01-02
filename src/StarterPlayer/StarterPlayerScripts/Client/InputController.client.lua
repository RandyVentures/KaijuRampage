--[[
  InputController
  Responsibility: Capture player input and request abilities.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local abilityRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AbilityRequest")

local keyToAbility = {
	[Enum.KeyCode.One] = "Stomp",
	[Enum.KeyCode.Two] = "TailSwipe",
	[Enum.KeyCode.Three] = "Roar",
	[Enum.KeyCode.B] = "DebugDamageNearest",
}

local function requestAbility(abilityName)
	abilityRemote:FireServer(abilityName, os.clock())
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	local abilityName = keyToAbility[input.KeyCode]
	if abilityName then
		requestAbility(abilityName)
	end
end)

return nil
