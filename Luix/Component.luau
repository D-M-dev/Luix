local Signal = require(script.Parent.Signal)
local StateModule = require(script.Parent.State)
local Element = require(script.Parent.Element)

local Component = {}
Component.__index = Component
Component._isComponent = true

function Component:extend(name)
	local NewComponent = setmetatable({}, { __index = Component })
	NewComponent.__index = NewComponent
	NewComponent._isComponent = true
	NewComponent._name = name or "UnnamedComponent"

	function NewComponent.new(props)
		local self = setmetatable({}, NewComponent)
		self.props = props or {}
		self.state = {}
		self._stateObjects = {}
		self._connections = {}
		self._mounted = false
		self._instance = nil
		self._children = {}
		self._onUnmount = Signal.new()
		self:init()
		return self
	end

	return NewComponent
end

function Component:init()
end

function Component:render()
	return nil
end

function Component:didMount()
end

function Component:didUpdate(prevProps, prevState)
end

function Component:willUnmount()
end

function Component:shouldUpdate(nextProps, nextState)
	return true
end

function Component:setState(partialState)
	local prevState = {}
	for k, v in pairs(self.state) do
		prevState[k] = v
	end

	if type(partialState) == "function" then
		partialState = partialState(self.state, self.props)
	end

	local changed = false
	for key, value in pairs(partialState) do
		if self.state[key] ~= value then
			self.state[key] = value
			changed = true
			if self._stateObjects[key] then
				self._stateObjects[key]:set(value)
			end
		end
	end

	if changed and self._mounted then
		if self:shouldUpdate(self.props, self.state) then
			self:_rerender()
			self:didUpdate(self.props, prevState)
		end
	end
end

function Component:createState(key, initialValue)
	local stateObj = StateModule.new(initialValue)
	self._stateObjects[key] = stateObj
	self.state[key] = initialValue

	stateObj:subscribe(function(newValue)
		self.state[key] = newValue
	end)

	return stateObj
end

function Component:connectTo(signal, callback)
	local conn = signal:Connect(callback)
	table.insert(self._connections, conn)
	return conn
end

function Component:createElement(className, props, children)
	return Element.new(className, props, children)
end

function Component:_rerender()
end

function Component:_mount(parent)
	self._mounted = true
	self:didMount()
end

function Component:_unmount()
	self._mounted = false
	self:willUnmount()
	self._onUnmount:Fire()

	for _, conn in ipairs(self._connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		elseif type(conn) == "table" and conn.Disconnect then
			conn:Disconnect()
		end
	end

	for _, stateObj in pairs(self._stateObjects) do
		stateObj:destroy()
	end

	table.clear(self._connections)
	table.clear(self._stateObjects)
	self._onUnmount:Destroy()
end

return Component