local Element = require(script.Parent.Element)
local Hooks = require(script.Parent.Hooks)
local Scaler = require(script.Parent.Scaler)
local Theme = require(script.Parent.Theme)
local Animation = require(script.Parent.Animation)

local Renderer = {}

local EVENT_PREFIX = "On"
local CHANGE_PREFIX = "Changed_"
local REF_KEY = "ref"
local KEY_KEY = "key"
local ANIMATE_KEY = "animate"
local STYLE_KEY = "style"
local SCALED_KEY = "scaled"
local CHILDREN_KEY = "children"

local activeTrees = {}

local function applyStyle(instance, style)
	local theme = Theme.get()

	local styleMap = {
		bg = "BackgroundColor3",
		bgAlpha = "BackgroundTransparency",
		textColor = "TextColor3",
		font = "Font",
		textSize = "TextSize",
		borderColor = "BorderColor3",
		borderWidth = "BorderSizePixel",
		cornerRadius = function(inst, value)
			local corner = inst:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
			if type(value) == "number" then
				corner.CornerRadius = UDim.new(0, value)
			else
				corner.CornerRadius = value
			end
			corner.Parent = inst
		end,
		padding = function(inst, value)
			local pad = inst:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
			if type(value) == "number" then
				pad.PaddingTop = UDim.new(0, value)
				pad.PaddingRight = UDim.new(0, value)
				pad.PaddingBottom = UDim.new(0, value)
				pad.PaddingLeft = UDim.new(0, value)
			elseif type(value) == "table" then
				pad.PaddingTop = UDim.new(0, value.top or value[1] or 0)
				pad.PaddingRight = UDim.new(0, value.right or value[2] or value[1] or 0)
				pad.PaddingBottom = UDim.new(0, value.bottom or value[3] or value[1] or 0)
				pad.PaddingLeft = UDim.new(0, value.left or value[4] or value[2] or value[1] or 0)
			end
			pad.Parent = inst
		end,
		stroke = function(inst, value)
			local stroke = inst:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
			if type(value) == "table" then
				stroke.Color = value.color or theme.colors.border
				stroke.Thickness = value.thickness or 1
				stroke.Transparency = value.transparency or 0
				stroke.ApplyStrokeMode = value.mode or Enum.ApplyStrokeMode.Border
			else
				stroke.Thickness = value
			end
			stroke.Parent = inst
		end,
		gradient = function(inst, value)
			local grad = inst:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
			if value.colors then
				local keypoints = {}
				for i, c in ipairs(value.colors) do
					table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (#value.colors - 1), c))
				end
				grad.Color = ColorSequence.new(keypoints)
			end
			if value.rotation then
				grad.Rotation = value.rotation
			end
			grad.Parent = inst
		end,
		listLayout = function(inst, value)
			local layout = inst:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout")
			layout.FillDirection = value.direction or Enum.FillDirection.Vertical
			layout.HorizontalAlignment = value.alignX or Enum.HorizontalAlignment.Center
			layout.VerticalAlignment = value.alignY or Enum.VerticalAlignment.Top
			layout.Padding = UDim.new(0, value.gap or 0)
			layout.SortOrder = value.sortOrder or Enum.SortOrder.LayoutOrder
			if value.wraps then
				layout.Wraps = true
			end
			layout.Parent = inst
		end,
		gridLayout = function(inst, value)
			local grid = inst:FindFirstChildOfClass("UIGridLayout") or Instance.new("UIGridLayout")
			grid.CellSize = value.cellSize or UDim2.new(0, 100, 0, 100)
			grid.CellPadding = value.cellPadding or UDim2.new(0, 4, 0, 4)
			grid.FillDirection = value.direction or Enum.FillDirection.Horizontal
			grid.SortOrder = value.sortOrder or Enum.SortOrder.LayoutOrder
			grid.Parent = inst
		end,
		aspectRatio = function(inst, value)
			local ar = inst:FindFirstChildOfClass("UIAspectRatioConstraint") or Instance.new("UIAspectRatioConstraint")
			ar.AspectRatio = value
			ar.Parent = inst
		end,
		sizeConstraint = function(inst, value)
			local sc = inst:FindFirstChildOfClass("UISizeConstraint") or Instance.new("UISizeConstraint")
			if value.min then
				sc.MinSize = value.min
			end
			if value.max then
				sc.MaxSize = value.max
			end
			sc.Parent = inst
		end,
		flexItem = function(inst, value)
			local flex = inst:FindFirstChildOfClass("UIFlexItem") or Instance.new("UIFlexItem")
			if value.grow then
				flex.FlexMode = Enum.UIFlexMode.Fill
			end
			flex.Parent = inst
		end,
	}

	for key, value in pairs(style) do
		local mapping = styleMap[key]
		if mapping then
			if type(mapping) == "function" then
				mapping(instance, value)
			elseif type(mapping) == "string" then
				pcall(function()
					instance[mapping] = value
				end)
			end
		end
	end
end

local function applyProps(instance, props)
	local connections = {}

	for key, value in pairs(props) do
		if key == REF_KEY then
			if type(value) == "table" then
				value.current = instance
			elseif type(value) == "function" then
				value(instance)
			end
		elseif key == KEY_KEY or key == CHILDREN_KEY then
			continue
		elseif key == STYLE_KEY then
			applyStyle(instance, value)
		elseif key == SCALED_KEY then
			for prop, val in pairs(value) do
				if typeof(val) == "UDim2" then
					instance[prop] = Scaler.scaleUDim2(val)
				elseif typeof(val) == "UDim" then
					instance[prop] = Scaler.scaleUDim(val)
				elseif type(val) == "number" then
					instance[prop] = Scaler.scale(val)
				end
			end
		elseif key == ANIMATE_KEY then
			if value.preset then
				task.defer(function()
					Animation.preset(instance, value.preset, value.to)
				end)
			elseif value.from and value.to then
				for prop, val in pairs(value.from) do
					instance[prop] = val
				end
				task.defer(function()
					Animation.tween(instance, value.to, value.info)
				end)
			end
		elseif string.sub(key, 1, #EVENT_PREFIX) == EVENT_PREFIX and string.sub(key, #EVENT_PREFIX + 1, #EVENT_PREFIX + 1) == string.upper(string.sub(key, #EVENT_PREFIX + 1, #EVENT_PREFIX + 1)) then
			local eventName = string.sub(key, #EVENT_PREFIX + 1)
			local success, event = pcall(function()
				return instance[eventName]
			end)
			if success and typeof(event) == "RBXScriptSignal" then
				local conn = event:Connect(value)
				table.insert(connections, conn)
			end
		elseif string.sub(key, 1, #CHANGE_PREFIX) == CHANGE_PREFIX then
			local propName = string.sub(key, #CHANGE_PREFIX + 1)
			local conn = instance:GetPropertyChangedSignal(propName):Connect(function()
				value(instance[propName])
			end)
			table.insert(connections, conn)
		else
			local success = pcall(function()
				instance[key] = value
			end)
			if not success then
				warn("[Framework.Renderer] Failed to set property: " .. key)
			end
		end
	end

	return connections
end

local function createInstance(element, parent)
	if not Element.isElement(element) then
		return nil
	end

	local tree = {
		element = element,
		instance = nil,
		children = {},
		connections = {},
		componentInstance = nil,
	}

	if element.type == Element.Type.Instance then
		local instance = Instance.new(element.className)
		tree.instance = instance
		tree.connections = applyProps(instance, element.props)

		for key, childElement in pairs(element.children) do
			if Element.isElement(childElement) then
				local childTree = createInstance(childElement, instance)
				if childTree then
					tree.children[key] = childTree
					if childTree.instance then
						childTree.instance.Name = type(key) == "string" and key or tostring(key)
						childTree.instance.Parent = instance
					end
				end
			end
		end

		if parent then
			instance.Parent = parent
		end

	elseif element.type == Element.Type.Component then
		if element._isFunctional then
			Hooks._setContext(element.component)
			local rendered = element.component(element.props)
			Hooks._clearContext()

			if rendered then
				local childTree = createInstance(rendered, parent)
				tree.children["_rendered"] = childTree
				tree.instance = childTree and childTree.instance
			end
		else
			local comp = element.component.new(element.props)
			tree.componentInstance = comp

			local rendered = comp:render()
			if rendered then
				local childTree = createInstance(rendered, parent)
				tree.children["_rendered"] = childTree
				tree.instance = childTree and childTree.instance
			end

			comp:_mount(parent)
		end

	elseif element.type == Element.Type.Fragment then
		for key, childElement in pairs(element.children) do
			if Element.isElement(childElement) then
				local childTree = createInstance(childElement, parent)
				if childTree then
					tree.children[key] = childTree
				end
			end
		end

	elseif element.type == Element.Type.Portal then
		local target = element.props.target
		for key, childElement in pairs(element.children) do
			if Element.isElement(childElement) then
				local childTree = createInstance(childElement, target)
				if childTree then
					tree.children[key] = childTree
				end
			end
		end
	end

	return tree
end

local function destroyTree(tree)
	if not tree then return end

	if tree.componentInstance then
		tree.componentInstance:_unmount()
	end

	for _, conn in ipairs(tree.connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		elseif type(conn) == "table" and conn.Disconnect then
			conn:Disconnect()
		end
	end

	for _, childTree in pairs(tree.children) do
		destroyTree(childTree)
	end

	if tree.instance and tree.element and tree.element.type == Element.Type.Instance then
		tree.instance:Destroy()
	end
end

function Renderer.mount(element, parent)
	local tree = createInstance(element, parent)
	if tree then
		local id = tostring(tree)
		activeTrees[id] = tree
		tree._id = id
	end
	return tree
end

function Renderer.unmount(tree)
	if not tree then return end
	if tree._id then
		activeTrees[tree._id] = nil
	end
	destroyTree(tree)
end

function Renderer.update(tree, newElement)
	if not tree then
		return Renderer.mount(newElement)
	end

	local parent = tree.instance and tree.instance.Parent
	Renderer.unmount(tree)
	return Renderer.mount(newElement, parent)
end

function Renderer.unmountAll()
	for id, tree in pairs(activeTrees) do
		destroyTree(tree)
	end
	table.clear(activeTrees)
end

return Renderer