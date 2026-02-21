local StateModule = require(script.Parent.State)
local Signal = require(script.Parent.Signal)
local Theme = require(script.Parent.Theme)
local Scaler = require(script.Parent.Scaler)

local Hooks = {}

local hookContext = {
	component = nil,
	hookIndex = 0,
	hooks = {},
}

function Hooks._setContext(component)
	hookContext.component = component
	hookContext.hookIndex = 0
	if not hookContext.hooks[component] then
		hookContext.hooks[component] = {}
	end
end

function Hooks._clearContext()
	hookContext.component = nil
	hookContext.hookIndex = 0
end

local function getHook()
	hookContext.hookIndex += 1
	local idx = hookContext.hookIndex
	local comp = hookContext.component
	return hookContext.hooks[comp], idx
end

function Hooks.useState(initialValue)
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		hooks[idx] = {
			state = StateModule.new(initialValue),
		}
	end

	local hook = hooks[idx]
	local function setState(newValue)
		hook.state:set(newValue)
	end

	return hook.state:get(), setState, hook.state
end

function Hooks.useEffect(callback, dependencies)
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		hooks[idx] = {
			deps = nil,
			cleanup = nil,
		}
	end

	local hook = hooks[idx]
	local shouldRun = false

	if hook.deps == nil then
		shouldRun = true
	elseif dependencies then
		for i, dep in ipairs(dependencies) do
			if dep ~= hook.deps[i] then
				shouldRun = true
				break
			end
		end
	else
		shouldRun = true
	end

	if shouldRun then
		if hook.cleanup then
			hook.cleanup()
		end
		hook.deps = dependencies and table.clone(dependencies) or nil
		task.defer(function()
			hook.cleanup = callback()
		end)
	end
end

function Hooks.useMemo(compute, dependencies)
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		hooks[idx] = {
			value = nil,
			deps = nil,
		}
	end

	local hook = hooks[idx]
	local shouldCompute = false

	if hook.deps == nil then
		shouldCompute = true
	elseif dependencies then
		for i, dep in ipairs(dependencies) do
			if dep ~= hook.deps[i] then
				shouldCompute = true
				break
			end
		end
	end

	if shouldCompute then
		hook.value = compute()
		hook.deps = dependencies and table.clone(dependencies) or nil
	end

	return hook.value
end

function Hooks.useCallback(callback, dependencies)
	return Hooks.useMemo(function()
		return callback
	end, dependencies)
end

function Hooks.useRef(initialValue)
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		hooks[idx] = { current = initialValue }
	end

	return hooks[idx]
end

function Hooks.useTheme()
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		hooks[idx] = {
			theme = Theme.get(),
		}

		Theme.onChanged(function(newTheme)
			hooks[idx].theme = newTheme
		end)
	end

	return hooks[idx].theme
end

function Hooks.useScale()
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		hooks[idx] = {
			scale = Scaler.getScale(),
			breakpoint = Scaler.getBreakpoint(),
			viewport = Scaler.getViewport(),
		}

		Scaler.onChanged(function(newScale, newViewport)
			hooks[idx].scale = newScale
			hooks[idx].viewport = newViewport
			hooks[idx].breakpoint = Scaler.getBreakpoint()
		end)
	end

	return {
		scale = hooks[idx].scale,
		breakpoint = hooks[idx].breakpoint,
		viewport = hooks[idx].viewport,
		isMobile = Scaler.isMobile(),
		isTablet = Scaler.isTablet(),
		isDesktop = Scaler.isDesktop(),
	}
end

function Hooks.useReducer(reducer, initialState)
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		hooks[idx] = {
			state = initialState,
		}
	end

	local hook = hooks[idx]

	local function dispatch(action)
		local newState = reducer(hook.state, action)
		hook.state = newState
	end

	return hook.state, dispatch
end

function Hooks.useStore(store, selector)
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		local initial = selector and selector(store:getState()) or store:getState()
		hooks[idx] = {
			value = initial,
		}

		store:subscribe(function(state)
			hooks[idx].value = selector and selector(state) or state
		end)
	end

	return hooks[idx].value
end

function Hooks.useAnimation(initialValue, config)
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		hooks[idx] = {
			value = initialValue,
			target = initialValue,
			playing = false,
		}
	end

	local hook = hooks[idx]

	local function animate(targetValue, tweenInfo)
		hook.target = targetValue
		hook.playing = true
		hook.tweenInfo = tweenInfo or TweenInfo.new(
			(config and config.duration) or 0.3,
			(config and config.easingStyle) or Enum.EasingStyle.Quad,
			(config and config.easingDirection) or Enum.EasingDirection.Out
		)
	end

	local function set(value)
		hook.value = value
		hook.target = value
	end

	return hook.value, animate, set, hook
end

function Hooks.useToggle(initial)
	local value, setValue = Hooks.useState(initial or false)
	local function toggle()
		setValue(not value)
	end
	return value, toggle, setValue
end

function Hooks.useDebounce(value, delay)
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		hooks[idx] = {
			debounced = value,
			thread = nil,
		}
	end

	local hook = hooks[idx]

	if hook.thread then
		task.cancel(hook.thread)
	end

	hook.thread = task.delay(delay or 0.3, function()
		hook.debounced = value
	end)

	return hook.debounced
end

function Hooks.useInterval(callback, interval)
	local hooks, idx = getHook()

	if hooks[idx] == nil then
		hooks[idx] = {
			connection = nil,
		}
	end

	local hook = hooks[idx]

	if hook.connection then
		hook.connection:Disconnect()
	end

	if interval and interval > 0 then
		hook.connection = game:GetService("RunService").Heartbeat:Connect(function()
			-- Simplified interval
		end)
	end

	return function()
		if hook.connection then
			hook.connection:Disconnect()
			hook.connection = nil
		end
	end
end

function Hooks._cleanup(component)
	local hooks = hookContext.hooks[component]
	if hooks then
		for _, hook in pairs(hooks) do
			if type(hook) == "table" and hook.cleanup then
				hook.cleanup()
			end
		end
		hookContext.hooks[component] = nil
	end
end

return Hooks