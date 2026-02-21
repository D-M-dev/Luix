local Players = game:GetService("Players")

local Scaler = {}
Scaler.__index = Scaler

local BASE_RESOLUTION = Vector2.new(1920, 1080)
local MIN_SCALE = 0.4
local MAX_SCALE = 3.0

local currentScale = 1
local currentViewport = BASE_RESOLUTION
local connections = {}
local onScaleChanged = Instance.new("BindableEvent")

local breakpoints = {
	mobile = 600,
	tablet = 1024,
	desktop = 1920,
	ultrawide = 2560,
}

local function getViewportSize()
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return BASE_RESOLUTION
end

local function calculateScale(viewportSize)
	local scaleX = viewportSize.X / BASE_RESOLUTION.X
	local scaleY = viewportSize.Y / BASE_RESOLUTION.Y
	local scale = math.min(scaleX, scaleY)
	return math.clamp(scale, MIN_SCALE, MAX_SCALE)
end

local function updateScale()
	local viewport = getViewportSize()
	local newScale = calculateScale(viewport)
	if newScale ~= currentScale or viewport ~= currentViewport then
		currentScale = newScale
		currentViewport = viewport
		onScaleChanged:Fire(currentScale, currentViewport)
	end
end

function Scaler.init()
	local camera = workspace.CurrentCamera
	if camera then
		local conn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		table.insert(connections, conn)
	end

	local conn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local cam = workspace.CurrentCamera
		if cam then
			local c = cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
			table.insert(connections, c)
			updateScale()
		end
	end)
	table.insert(connections, conn)

	updateScale()
end

function Scaler.getScale()
	return currentScale
end

function Scaler.getViewport()
	return currentViewport
end

function Scaler.getBreakpoint()
	local width = currentViewport.X
	if width <= breakpoints.mobile then
		return "mobile"
	elseif width <= breakpoints.tablet then
		return "tablet"
	elseif width <= breakpoints.desktop then
		return "desktop"
	else
		return "ultrawide"
	end
end

function Scaler.isMobile()
	return Scaler.getBreakpoint() == "mobile"
end

function Scaler.isTablet()
	return Scaler.getBreakpoint() == "tablet"
end

function Scaler.isDesktop()
	return Scaler.getBreakpoint() == "desktop" or Scaler.getBreakpoint() == "ultrawide"
end

function Scaler.setBaseResolution(width, height)
	BASE_RESOLUTION = Vector2.new(width, height)
	updateScale()
end

function Scaler.setBreakpoints(newBreakpoints)
	for key, value in pairs(newBreakpoints) do
		breakpoints[key] = value
	end
end

function Scaler.scale(value)
	return math.round(value * currentScale)
end

function Scaler.scaleUDim2(udim2)
	return UDim2.new(
		udim2.X.Scale, Scaler.scale(udim2.X.Offset),
		udim2.Y.Scale, Scaler.scale(udim2.Y.Offset)
	)
end

function Scaler.scaleUDim(udim)
	return UDim.new(udim.Scale, Scaler.scale(udim.Offset))
end

function Scaler.scalePadding(top, right, bottom, left)
	return {
		Top = UDim.new(0, Scaler.scale(top or 0)),
		Right = UDim.new(0, Scaler.scale(right or top or 0)),
		Bottom = UDim.new(0, Scaler.scale(bottom or top or 0)),
		Left = UDim.new(0, Scaler.scale(left or right or top or 0)),
	}
end

function Scaler.responsive(values)
	local bp = Scaler.getBreakpoint()
	if values[bp] then
		return values[bp]
	end
	local order = { "mobile", "tablet", "desktop", "ultrawide" }
	local found = false
	for i = #order, 1, -1 do
		if order[i] == bp then
			found = true
		end
		if found and values[order[i]] then
			return values[order[i]]
		end
	end
	return values.desktop or values[next(values)]
end

function Scaler.fontSize(base)
	local bp = Scaler.getBreakpoint()
	local multipliers = {
		mobile = 0.75,
		tablet = 0.9,
		desktop = 1.0,
		ultrawide = 1.2,
	}
	return math.round(base * (multipliers[bp] or 1) * currentScale)
end

function Scaler.onChanged(callback)
	return onScaleChanged.Event:Connect(callback)
end

function Scaler.applyAutoScale(screenGui)
	if not screenGui:FindFirstChildOfClass("UIScale") then
		local uiScale = Instance.new("UIScale")
		uiScale.Scale = currentScale
		uiScale.Parent = screenGui

		Scaler.onChanged(function(newScale)
			uiScale.Scale = newScale
		end)
	end
end

function Scaler.createConstraint(config)
	local constraint = {}
	constraint.minWidth = config.minWidth or 0
	constraint.maxWidth = config.maxWidth or math.huge
	constraint.minHeight = config.minHeight or 0
	constraint.maxHeight = config.maxHeight or math.huge
	constraint.aspectRatio = config.aspectRatio

	function constraint:apply(instance)
		if self.aspectRatio then
			local ar = Instance.new("UIAspectRatioConstraint")
			ar.AspectRatio = self.aspectRatio
			ar.Parent = instance
		end

		local sc = Instance.new("UISizeConstraint")
		sc.MinSize = Vector2.new(Scaler.scale(self.minWidth), Scaler.scale(self.minHeight))
		if self.maxWidth < math.huge and self.maxHeight < math.huge then
			sc.MaxSize = Vector2.new(Scaler.scale(self.maxWidth), Scaler.scale(self.maxHeight))
		end
		sc.Parent = instance
	end

	return constraint
end

function Scaler.destroy()
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)
	onScaleChanged:Destroy()
end

Scaler.init()

return Scaler