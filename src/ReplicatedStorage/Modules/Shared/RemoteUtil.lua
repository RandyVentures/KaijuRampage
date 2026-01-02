--[[
  RemoteUtil
  Responsibility: Ensure RemoteEvents/RemoteFunctions exist in ReplicatedStorage.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteUtil = {}

function RemoteUtil.GetOrCreateFolder(folderName)
	local folder = ReplicatedStorage:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = ReplicatedStorage
	end
	return folder
end

function RemoteUtil.GetOrCreateRemote(folderName, remoteName, className)
	local folder = RemoteUtil.GetOrCreateFolder(folderName)
	local remote = folder:FindFirstChild(remoteName)
	if not remote then
		remote = Instance.new(className)
		remote.Name = remoteName
		remote.Parent = folder
	end
	return remote
end

return RemoteUtil
