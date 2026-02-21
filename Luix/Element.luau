local Element = {}
Element.__index = Element

Element.Type = {
	Instance = "Instance",
	Component = "Component",
	Fragment = "Fragment",
	Portal = "Portal",
}

function Element.new(source, props, children)
	local self = setmetatable({}, Element)

	self.props = props or {}
	self.children = children or {}

	if type(source) == "string" then
		self.type = Element.Type.Instance
		self.className = source
	elseif type(source) == "table" and source._isComponent then
		self.type = Element.Type.Component
		self.component = source
	elseif type(source) == "function" then
		self.type = Element.Type.Component
		self.component = source
		self._isFunctional = true
	else
		self.type = Element.Type.Fragment
	end

	return self
end

function Element.fragment(children)
	local self = setmetatable({}, Element)
	self.type = Element.Type.Fragment
	self.props = {}
	self.children = children or {}
	return self
end

function Element.portal(target, children)
	local self = setmetatable({}, Element)
	self.type = Element.Type.Portal
	self.props = { target = target }
	self.children = children or {}
	return self
end

function Element.isElement(value)
	return type(value) == "table" and getmetatable(value) == Element
end

function Element:clone(overrideProps, overrideChildren)
	local newProps = {}
	for k, v in pairs(self.props) do
		newProps[k] = v
	end
	if overrideProps then
		for k, v in pairs(overrideProps) do
			newProps[k] = v
		end
	end

	local source
	if self.type == Element.Type.Instance then
		source = self.className
	elseif self.type == Element.Type.Component then
		source = self.component
	end

	return Element.new(source, newProps, overrideChildren or self.children)
end

return Element