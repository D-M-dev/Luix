local Signal = require(script.Parent.Signal)

local State = {}
State.__index = State

function State.new(initialValue)
	local self = setmetatable({}, State)
	self._value = initialValue
	self._changed = Signal.new()
	self._bindings = {}
	return self
end

function State:get()
	return self._value
end

function State:set(newValue)
	if type(newValue) == "function" then
		newValue = newValue(self._value)
	end
	if self._value == newValue then
		return
	end
	local oldValue = self._value
	self._value = newValue
	self._changed:Fire(newValue, oldValue)
end

function State:subscribe(callback)
	return self._changed:Connect(callback)
end

function State:map(transform)
	local derived = State.new(transform(self._value))
	self:subscribe(function(newValue)
		derived:set(transform(newValue))
	end)
	return derived
end

function State:bind(instance, property)
	instance[property] = self._value
	local conn = self:subscribe(function(newValue)
		instance[property] = newValue
	end)
	table.insert(self._bindings, conn)
	return conn
end

function State:destroy()
	self._changed:Destroy()
	for _, conn in ipairs(self._bindings) do
		conn:Disconnect()
	end
	table.clear(self._bindings)
end

local Store = {}
Store.__index = Store

function Store.new(initialState, reducers)
	local self = setmetatable({}, Store)
	self._state = {}
	self._reducers = reducers or {}
	self._changed = Signal.new()
	self._stateObjects = {}

	for key, value in pairs(initialState) do
		self._stateObjects[key] = State.new(value)
		self._state[key] = value
	end

	return self
end

function Store:getState()
	local snapshot = {}
	for key, stateObj in pairs(self._stateObjects) do
		snapshot[key] = stateObj:get()
	end
	return snapshot
end

function Store:dispatch(action, payload)
	local reducer = self._reducers[action]
	if not reducer then
		warn("[Framework.Store] Unknown action: " .. tostring(action))
		return
	end

	local currentState = self:getState()
	local newState = reducer(currentState, payload)

	for key, value in pairs(newState) do
		if self._stateObjects[key] then
			self._stateObjects[key]:set(value)
		else
			self._stateObjects[key] = State.new(value)
		end
	end

	self._changed:Fire(self:getState())
end

function Store:select(key)
	return self._stateObjects[key]
end

function Store:subscribe(callback)
	return self._changed:Connect(callback)
end

function Store:destroy()
	for _, stateObj in pairs(self._stateObjects) do
		stateObj:destroy()
	end
	self._changed:Destroy()
end

local Computed = {}
Computed.__index = Computed

function Computed.new(dependencies, compute)
	local self = setmetatable({}, Computed)
	self._compute = compute
	self._dependencies = dependencies
	self._changed = Signal.new()
	self._connections = {}

	local function getValues()
		local values = {}
		for i, dep in ipairs(dependencies) do
			values[i] = dep:get()
		end
		return values
	end

	self._value = compute(unpack(getValues()))

	for _, dep in ipairs(dependencies) do
		local conn = dep:subscribe(function()
			local newValue = compute(unpack(getValues()))
			if newValue ~= self._value then
				self._value = newValue
				self._changed:Fire(newValue)
			end
		end)
		table.insert(self._connections, conn)
	end

	return self
end

function Computed:get()
	return self._value
end

function Computed:subscribe(callback)
	return self._changed:Connect(callback)
end

function Computed:destroy()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._changed:Destroy()
end

return {
	State = State,
	Store = Store,
	Computed = Computed,
	new = State.new,
	createStore = Store.new,
	computed = Computed.new,
}