--[[
  ServiceLocator
  Responsibility: Register and fetch server services safely.
]]

local ServiceLocator = {}

local registry = {}
local waiting = {}

function ServiceLocator.Register(name, service)
	registry[name] = service
	if waiting[name] then
		for _, callback in ipairs(waiting[name]) do
			callback(service)
		end
		waiting[name] = nil
	end
end

function ServiceLocator.Get(name)
	return registry[name]
end

function ServiceLocator.WaitFor(name, timeoutSeconds)
	local existing = registry[name]
	if existing then
		return existing
	end

	local bindable = Instance.new("BindableEvent")
	waiting[name] = waiting[name] or {}
	table.insert(waiting[name], function(service)
		bindable:Fire(service)
	end)

	local timeout = timeoutSeconds or 10
	local service
	local connection
	connection = bindable.Event:Connect(function(found)
		service = found
		connection:Disconnect()
	end)

	local start = os.clock()
	while not service and (os.clock() - start) < timeout do
		task.wait(0.05)
	end

	bindable:Destroy()
	return service
end

return ServiceLocator
