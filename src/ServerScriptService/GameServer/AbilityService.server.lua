--[[
  AbilityService
  Responsibility: Validate and execute player abilities server-side.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AbilitiesConfig = require(ReplicatedStorage.Modules.Config.AbilitiesConfig)
local UpgradesConfig = require(ReplicatedStorage.Modules.Config.UpgradesConfig)
local MathUtil = require(ReplicatedStorage.Modules.Shared.MathUtil)
local CooldownUtil = require(ReplicatedStorage.Modules.Shared.CooldownUtil)
local ServiceLocator = require(ReplicatedStorage.Modules.Shared.ServiceLocator)
local RemoteUtil = require(ReplicatedStorage.Modules.Shared.RemoteUtil)

local AbilityService = {}

local abilityRemote = RemoteUtil.GetOrCreateRemote("Remotes", "AbilityRequest", "RemoteEvent")
local abilityConfirmedRemote = RemoteUtil.GetOrCreateRemote("Remotes", "AbilityConfirmed", "RemoteEvent")
local uiStateRemote = RemoteUtil.GetOrCreateRemote("Remotes", "UIState", "RemoteEvent")

local playerCooldowns = {}
local lastPositions = {}
local lastRequestTimes = {}

local function getCooldownState(player)
	playerCooldowns[player.UserId] = playerCooldowns[player.UserId] or CooldownUtil.New()
	return playerCooldowns[player.UserId]
end

local function getAbilityParams(player, abilityName)
	local base = AbilitiesConfig.GetBase(abilityName)
	if not base then
		return nil
	end
	local economyService = ServiceLocator.Get("EconomyService")
	local profile = economyService and economyService.GetProfile(player) or nil
	local upgradesData = profile and profile.Upgrades or nil

	return UpgradesConfig.ApplyAbilityScaling(base, upgradesData)
end

local function getPlayerRoot(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function applyDamageInRadius(player, origin, radius, damage)
	local buildingService = ServiceLocator.Get("BuildingService")
	if not buildingService then
		return 0
	end

	local hitCount = 0
	for _, building in ipairs(CollectionService:GetTagged("DestructibleBuilding")) do
		if building:IsA("Model") and not building:GetAttribute("IsDestroyed") then
			local position = building:GetPivot().Position
			if MathUtil.IsInRadius(origin, position, radius) then
				buildingService.ApplyDamage(building, damage, player)
				hitCount += 1
			end
		end
	end
	return hitCount
end

local function applyDamageInCone(player, root, range, dotThreshold, damage)
	local buildingService = ServiceLocator.Get("BuildingService")
	if not buildingService then
		return 0
	end

	local hitCount = 0
	for _, building in ipairs(CollectionService:GetTagged("DestructibleBuilding")) do
		if building:IsA("Model") and not building:GetAttribute("IsDestroyed") then
			local position = building:GetPivot().Position
			local originFlat = Vector3.new(root.Position.X, 0, root.Position.Z)
			local positionFlat = Vector3.new(position.X, 0, position.Z)
			local toTarget = positionFlat - originFlat
			local distance = toTarget.Magnitude
			if distance <= range and distance > 0 then
				local targetDir = toTarget.Unit
				local moveDir = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid") and root.Parent:FindFirstChildOfClass("Humanoid").MoveDirection or Vector3.zero
				local forwardDir
				if moveDir.Magnitude > 0.05 then
					forwardDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
				else
					local look = root.CFrame.LookVector
					forwardDir = Vector3.new(look.X, 0, look.Z).Unit
				end

				local dot = forwardDir:Dot(targetDir)
				local right = root.CFrame.RightVector
				local rightDir = Vector3.new(right.X, 0, right.Z).Unit
				local dotRight = rightDir:Dot(targetDir)

				local hit = dot >= dotThreshold
				if not hit and dot >= -0.2 and math.abs(dotRight) >= 0.15 then
					hit = true
				end

				if hit then
					buildingService.ApplyDamage(building, damage, player)
					hitCount += 1
				end
			elseif distance == 0 then
				buildingService.ApplyDamage(building, damage, player)
				hitCount += 1
			end
		end
	end
	return hitCount
end

local function applyRoarKnockback(origin, radius)
	for _, part in ipairs(workspace:GetPartBoundsInRadius(origin, radius)) do
		if part:IsA("BasePart") and not part.Anchored then
			local direction = (part.Position - origin).Unit
			part:ApplyImpulse(direction * part:GetMass() * 60)
		end
	end
end

local function findNearestBuilding(origin, maxDistance)
	local nearest = nil
	local nearestDistance = maxDistance

	for _, building in ipairs(CollectionService:GetTagged("DestructibleBuilding")) do
		if building:IsA("Model") and not building:GetAttribute("IsDestroyed") then
			local position = building:GetPivot().Position
			local distance = (position - origin).Magnitude
			if distance <= nearestDistance then
				nearestDistance = distance
				nearest = building
			end
		end
	end

	return nearest
end

local function sendCooldown(player, abilityName, cooldownSeconds)
	local serverNow = os.clock()
	uiStateRemote:FireClient(player, {
		type = "Cooldown",
		ability = abilityName,
		duration = cooldownSeconds,
		serverNow = serverNow,
		readyAt = serverNow + cooldownSeconds,
	})
end

local function handleAbility(player, abilityName)
	local antiExploit = ServiceLocator.Get("AntiExploit")
	if antiExploit and not antiExploit.IsCharacterValid(player) then
		if RunService:IsStudio() then
			print(("[AbilityReject] %s invalid character"):format(abilityName))
		end
		return
	end

	local params = getAbilityParams(player, abilityName)
	if not params then
		if RunService:IsStudio() then
			print(("[AbilityReject] %s missing params"):format(abilityName))
		end
		return
	end

	local cooldownState = getCooldownState(player)
	local canUse = CooldownUtil.CanUse(cooldownState, abilityName, params.cooldown)
	if not canUse then
		if RunService:IsStudio() then
			print(("[AbilityReject] %s cooldown active"):format(abilityName))
		end
		return
	end

	local root = getPlayerRoot(player)
	if not root then
		if RunService:IsStudio() then
			print(("[AbilityReject] %s missing root"):format(abilityName))
		end
		return
	end

	if antiExploit and not antiExploit.CheckRateLimit(player, "Ability_" .. abilityName, 4, 1) then
		if RunService:IsStudio() then
			print(("[AbilityReject] %s rate limited"):format(abilityName))
		end
		return
	end

	CooldownUtil.MarkUsed(cooldownState, abilityName)
	abilityConfirmedRemote:FireClient(player, abilityName)
	sendCooldown(player, abilityName, params.cooldown)
	local origin = root.Position

	if abilityName == "Stomp" then
		local hitCount = applyDamageInRadius(player, origin, 25, 40)
		if RunService:IsStudio() then
			print(("Stomp hits: %d"):format(hitCount))
		end
	elseif abilityName == "TailSwipe" then
		local hitCount = applyDamageInCone(player, root, 35, 0.15, 25)
		if RunService:IsStudio() then
			print(("TailSwipe hits: %d"):format(hitCount))
			local nearest = findNearestBuilding(origin, 80)
			if nearest then
				local targetPos = nearest:GetPivot().Position
				local originFlat = Vector3.new(origin.X, 0, origin.Z)
				local targetFlat = Vector3.new(targetPos.X, 0, targetPos.Z)
				local toTarget = targetFlat - originFlat
				local distance = toTarget.Magnitude
				local targetDir = distance > 0 and toTarget.Unit or Vector3.zero
				local moveDir = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid") and root.Parent:FindFirstChildOfClass("Humanoid").MoveDirection or Vector3.zero
				local forwardDir
				if moveDir.Magnitude > 0.05 then
					forwardDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
				else
					local look = root.CFrame.LookVector
					forwardDir = Vector3.new(look.X, 0, look.Z).Unit
				end
				local right = root.CFrame.RightVector
				local rightDir = Vector3.new(right.X, 0, right.Z).Unit
				local dot = forwardDir:Dot(targetDir)
				local dotRight = rightDir:Dot(targetDir)
				print(("TailSwipe nearest distance: %.2f, forward: (%.2f, %.2f, %.2f), target: (%.2f, %.2f, %.2f), dot: %.3f, dotRight: %.3f"):format(
					distance,
					forwardDir.X, forwardDir.Y, forwardDir.Z,
					targetDir.X, targetDir.Y, targetDir.Z,
					dot,
					dotRight
				))
			end
		end
	elseif abilityName == "Roar" then
		local hitCount = applyDamageInRadius(player, origin, 55, 10)
		applyRoarKnockback(origin, 55)
		if RunService:IsStudio() then
			print(("Roar hits: %d"):format(hitCount))
		end
	end

	-- Ability confirmation and cooldown are sent before heavy work to keep UI responsive.
end

abilityRemote.OnServerEvent:Connect(function(player, abilityName, clientTimestamp)
	if type(abilityName) ~= "string" then
		if RunService:IsStudio() then
			print("[AbilityReject] Invalid ability name type")
		end
		return
	end
	local isDebug = abilityName == "DebugDamageNearest"
	local base = isDebug and nil or AbilitiesConfig.GetBase(abilityName)
	if not isDebug and not base then
		if RunService:IsStudio() then
			print(("[AbilityReject] %s unknown ability"):format(abilityName))
		end
		return
	end

	local antiExploit = ServiceLocator.Get("AntiExploit")
	if antiExploit and not antiExploit.CheckRateLimit(player, "AbilityRequest", 8, 2) then
		if RunService:IsStudio() then
			print(("[AbilityReject] %s request rate limited"):format(abilityName))
		end
		return
	end

	local root = getPlayerRoot(player)
	if not root then
		if RunService:IsStudio() then
			print(("[AbilityReject] %s no root at request"):format(abilityName))
		end
		return
	end

	if isDebug then
		if antiExploit and not antiExploit.CheckRateLimit(player, "DebugDamageNearest", 4, 2) then
			return
		end
		local nearest = findNearestBuilding(root.Position, 80)
		if nearest then
			local buildingService = ServiceLocator.Get("BuildingService")
			if buildingService then
				buildingService.ApplyDamage(nearest, 50, player)
			end
		end
		return
	end

	if antiExploit then
		local lastPosition = lastPositions[player.UserId]
		local lastTime = lastRequestTimes[player.UserId]
		if lastPosition and lastTime then
			local maxRange = (base and base.maxRange) or 80
			local humanoid = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
			local walkSpeed = humanoid and humanoid.WalkSpeed or 16
			local deltaTime = math.max(0, os.clock() - lastTime)
			local maxDistance = maxRange + (walkSpeed * deltaTime * 1.5)
			if (root.Position - lastPosition).Magnitude > maxDistance then
				if RunService:IsStudio() then
					print(("[AbilityReject] %s movement delta too large"):format(abilityName))
				end
				return
			end
		end
		lastPositions[player.UserId] = root.Position
		lastRequestTimes[player.UserId] = os.clock()
	end

	handleAbility(player, abilityName)
end)

ServiceLocator.Register("AbilityService", AbilityService)

return AbilityService
