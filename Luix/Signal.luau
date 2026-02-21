local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self._listeners = {}
	self._once = {}
	return self
end

function Signal:Connect(callback)
	local id = tostring(callback) .. tostring(os.clock())
	self._listeners[id] = callback

	return {
		Disconnect = function()
			self._listeners[id] = nil
		end
	}
end

function Signal:Once(callback)
	local id = tostring(callback) .. tostring(os.clock())
	self._once[id] = callback

	return {
		Disconnect = function()
			self._once[id] = nil
		end
	}
end

function Signal:Fire(...)
	for _, cb in pairs(self._listeners) do
		task.spawn(cb, ...)
	end
	for id, cb in pairs(self._once) do
		self._once[id] = nil
		task.spawn(cb, ...)
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Once(function(...)
		coroutine.resume(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	table.clear(self._listeners)
	table.clear(self._once)
end

function Signal:Destroy()
	self:DisconnectAll()
	setmetatable(self, nil)
end

return Signal