local Framework = {}

Framework.Component = require(script.Component)
Framework.State = require(script.State)
Framework.Renderer = require(script.Renderer)
Framework.Scaler = require(script.Scaler)
Framework.Theme = require(script.Theme)
Framework.Hooks = require(script.Hooks)
Framework.Animation = require(script.Animation)
Framework.Element = require(script.Element)
Framework.Router = require(script.Router)
Framework.Signal = require(script.Signal)

function Framework.create(className, props, children)
	return Framework.Element.new(className, props, children)
end

function Framework.mount(element, parent)
	return Framework.Renderer.mount(element, parent)
end

function Framework.unmount(tree)
	return Framework.Renderer.unmount(tree)
end

function Framework.update(tree, newElement)
	return Framework.Renderer.update(tree, newElement)
end

return Framework