--[[
  KaijuAnimator
  Responsibility: Play ability animations when the server confirms ability use.
  Configuration: Set Humanoid attributes StompAnimId, TailAnimId, RoarAnimId.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local abilityConfirmed = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AbilityConfirmed")

local abilityToAttribute = {
	Stomp = "StompAnimId",
	TailSwipe = "TailAnimId",
	Roar = "RoarAnimId",
}

local loadedTracks = {}

local function normalizeAssetId(value)
	if type(value) == "number" then
		return "rbxassetid://" .. tostring(value)
	end
	if type(value) == "string" then
		if value == "" then
			return nil
		end
		if value:find("^rbxassetid://") then
			return value
		end
		if value:match("^%d+$") then
			return "rbxassetid://" .. value
		end
	end
	return nil
end

local function getAnimator(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

local function ensureDefaultAttributes(humanoid)
	if humanoid:GetAttribute("StompAnimId") == nil then
		humanoid:SetAttribute("StompAnimId", "rbxassetid://108755068504591")
	end
	if humanoid:GetAttribute("TailAnimId") == nil then
		humanoid:SetAttribute("TailAnimId", "")
	end
	if humanoid:GetAttribute("RoarAnimId") == nil then
		humanoid:SetAttribute("RoarAnimId", "")
	end
end

local function loadTrackForAbility(humanoid, abilityName)
	local attributeName = abilityToAttribute[abilityName]
	if not attributeName then
		return nil
	end

	local assetId = normalizeAssetId(humanoid:GetAttribute(attributeName))
	if not assetId then
		return nil
	end

	loadedTracks[abilityName] = loadedTracks[abilityName] or {}
	local cached = loadedTracks[abilityName][assetId]
	if cached then
		return cached
	end

	local animator = getAnimator(humanoid)
	local animation = Instance.new("Animation")
	animation.AnimationId = assetId
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok then
		if RunService:IsStudio() then
			warn(("KaijuAnimator: failed to load animation for %s (%s)"):format(abilityName, tostring(assetId)))
		end
		return nil
	end
	loadedTracks[abilityName][assetId] = track
	return track
end

local function playAbilityAnimation(abilityName)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	ensureDefaultAttributes(humanoid)
	local track = loadTrackForAbility(humanoid, abilityName)
	if track then
		track:Play(0.1, 1, 1)
	end
end

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	getAnimator(humanoid)
	ensureDefaultAttributes(humanoid)
end)

if player.Character then
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		getAnimator(humanoid)
		ensureDefaultAttributes(humanoid)
	end
end

abilityConfirmed.OnClientEvent:Connect(function(abilityName)
	if type(abilityName) ~= "string" then
		return
	end
	if abilityToAttribute[abilityName] then
		playAbilityAnimation(abilityName)
	end
end)

return nil
