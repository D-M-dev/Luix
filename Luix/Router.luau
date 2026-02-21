local Signal = require(script.Parent.Signal)
local StateModule = require(script.Parent.State)

local Router = {}
Router.__index = Router

function Router.new(routes, initialRoute)
	local self = setmetatable({}, Router)
	self._routes = routes or {}
	self._history = {}
	self._currentRoute = StateModule.new(initialRoute or next(routes) or "")
	self._params = StateModule.new({})
	self._onNavigate = Signal.new()
	self._middleware = {}
	self._guards = {}

	if initialRoute then
		table.insert(self._history, { route = initialRoute, params = {} })
	end

	return self
end

function Router:addRoute(name, config)
	self._routes[name] = config
end

function Router:removeRoute(name)
	self._routes[name] = nil
end

function Router:addMiddleware(callback)
	table.insert(self._middleware, callback)
end

function Router:addGuard(routeName, callback)
	if not self._guards[routeName] then
		self._guards[routeName] = {}
	end
	table.insert(self._guards[routeName], callback)
end

function Router:navigate(routeName, params)
	if not self._routes[routeName] then
		warn("[Framework.Router] Route not found: " .. tostring(routeName))
		return false
	end

	params = params or {}

	for _, middleware in ipairs(self._middleware) do
		local allow = middleware(self._currentRoute:get(), routeName, params)
		if allow == false then
			return false
		end
	end

	local guards = self._guards[routeName]
	if guards then
		for _, guard in ipairs(guards) do
			local allow = guard(params)
			if allow == false then
				return false
			end
		end
	end

	local prevRoute = self._currentRoute:get()
	table.insert(self._history, { route = routeName, params = params })

	self._currentRoute:set(routeName)
	self._params:set(params)
	self._onNavigate:Fire(routeName, params, prevRoute)

	return true
end

function Router:back()
	if #self._history > 1 then
		table.remove(self._history)
		local prev = self._history[#self._history]
		self._currentRoute:set(prev.route)
		self._params:set(prev.params)
		self._onNavigate:Fire(prev.route, prev.params)
		return true
	end
	return false
end

function Router:getCurrentRoute()
	return self._currentRoute:get()
end

function Router:getParams()
	return self._params:get()
end

function Router:getRouteState()
	return self._currentRoute
end

function Router:getParamsState()
	return self._params
end

function Router:getCurrentConfig()
	return self._routes[self._currentRoute:get()]
end

function Router:canGoBack()
	return #self._history > 1
end

function Router:getHistory()
	return self._history
end

function Router:clearHistory()
	local current = self._history[#self._history]
	table.clear(self._history)
	if current then
		table.insert(self._history, current)
	end
end

function Router:onNavigate(callback)
	return self._onNavigate:Connect(callback)
end

function Router:onRouteChanged(callback)
	return self._currentRoute:subscribe(callback)
end

function Router:getRoutes()
	local names = {}
	for name in pairs(self._routes) do
		table.insert(names, name)
	end
	return names
end

function Router:destroy()
	self._currentRoute:destroy()
	self._params:destroy()
	self._onNavigate:Destroy()
end

return Router