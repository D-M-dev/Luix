local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Animation = {}

local DEFAULT_TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Presets = {
	fadeIn = {
		from = { BackgroundTransparency = 1 },
		to = { BackgroundTransparency = 0 },
		info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	},
	fadeOut = {
		from = { BackgroundTransparency = 0 },
		to = { BackgroundTransparency = 1 },
		info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	},
	slideInLeft = {
		from = { Position = UDim2.new(-1, 0, 0, 0) },
		to = { Position = UDim2.new(0, 0, 0, 0) },
		info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	},
	slideInRight = {
		from = { Position = UDim2.new(1, 0, 0, 0) },
		to = { Position = UDim2.new(0, 0, 0, 0) },
		info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	},
	slideInTop = {
		from = { Position = UDim2.new(0, 0, -1, 0) },
		to = { Position = UDim2.new(0, 0, 0, 0) },
		info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	},
	slideInBottom = {
		from = { Position = UDim2.new(0, 0, 1, 0) },
		to = { Position = UDim2.new(0, 0, 0, 0) },
		info = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	},
	scaleIn = {
		from = { Size = UDim2.new(0, 0, 0, 0) },
		to = nil,
		info = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	},
	bounce = {
		from = nil,
		to = nil,
		info = TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
	},
	pop = {
		from = { Size = UDim2.new(0.8, 0, 0.8, 0) },
		to = nil,
		info = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	},
	pulse = {
		info = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	},
	shake = {
		info = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 5, true),
	},
}

function Animation.tween(instance, properties, tweenInfo)
	tweenInfo = tweenInfo or DEFAULT_TWEEN_INFO
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

function Animation.tweenAsync(instance, properties, tweenInfo)
	local tween = Animation.tween(instance, properties, tweenInfo)
	tween.Completed:Wait()
	return tween
end

function Animation.preset(instance, presetName, customTo)
	local preset = Presets[presetName]
	if not preset then
		warn("[Framework.Animation] Unknown preset: " .. tostring(presetName))
		return
	end

	if preset.from then
		for prop, value in pairs(preset.from) do
			instance[prop] = value
		end
	end

	local target = customTo or preset.to
	if target then
		return Animation.tween(instance, target, preset.info)
	end

	return nil
end

function Animation.presetAsync(instance, presetName, customTo)
	local tween = Animation.preset(instance, presetName, customTo)
	if tween then
		tween.Completed:Wait()
	end
	return tween
end

function Animation.sequence(steps)
	local current = 0
	local cancelled = false

	local function run()
		for i, step in ipairs(steps) do
			if cancelled then break end
			current = i

			if step.delay then
				task.wait(step.delay)
			end

			if step.callback then
				step.callback()
			end

			if step.instance and step.properties then
				local tween = Animation.tween(step.instance, step.properties, step.info)
				if step.wait ~= false then
					tween.Completed:Wait()
				end
			end

			if step.preset and step.instance then
				local tween = Animation.preset(step.instance, step.preset, step.to)
				if step.wait ~= false and tween then
					tween.Completed:Wait()
				end
			end
		end
	end

	task.spawn(run)

	return {
		cancel = function()
			cancelled = true
		end,
		getCurrentStep = function()
			return current
		end,
	}
end

function Animation.parallel(tweens)
	local activeTweens = {}

	for _, config in ipairs(tweens) do
		local tween = Animation.tween(config.instance, config.properties, config.info)
		table.insert(activeTweens, tween)
	end

	return {
		tweens = activeTweens,
		cancel = function()
			for _, t in ipairs(activeTweens) do
				t:Cancel()
			end
		end,
		wait = function()
			for _, t in ipairs(activeTweens) do
				t.Completed:Wait()
			end
		end,
	}
end

function Animation.stagger(instances, properties, tweenInfo, staggerDelay)
	staggerDelay = staggerDelay or 0.05
	local tweens = {}

	for i, instance in ipairs(instances) do
		task.delay(staggerDelay * (i - 1), function()
			local tween = Animation.tween(instance, properties, tweenInfo)
			table.insert(tweens, tween)
		end)
	end

	return tweens
end

function Animation.spring(instance, property, target, config)
	config = config or {}
	local stiffness = config.stiffness or 180
	local damping = config.damping or 12
	local mass = config.mass or 1
	local precision = config.precision or 0.01

	local current = instance[property]
	local velocity = 0
	local connection

	if typeof(current) == "number" then
		connection = RunService.Heartbeat:Connect(function(dt)
			local displacement = current - target
			local springForce = -stiffness * displacement
			local dampingForce = -damping * velocity
			local acceleration = (springForce + dampingForce) / mass

			velocity = velocity + acceleration * dt
			current = current + velocity * dt

			if math.abs(displacement) < precision and math.abs(velocity) < precision then
				current = target
				instance[property] = current
				connection:Disconnect()
				return
			end

			instance[property] = current
		end)
	end

	return {
		cancel = function()
			if connection then
				connection:Disconnect()
			end
		end,
	}
end

function Animation.lerp(instance, property, target, speed)
	speed = speed or 0.1
	local connection

	connection = RunService.Heartbeat:Connect(function()
		local current = instance[property]

		if typeof(current) == "number" then
			local new = current + (target - current) * speed
			if math.abs(new - target) < 0.001 then
				instance[property] = target
				connection:Disconnect()
			else
				instance[property] = new
			end
		elseif typeof(current) == "UDim2" then
			local new = current:Lerp(target, speed)
			instance[property] = new
		elseif typeof(current) == "Color3" then
			local new = current:Lerp(target, speed)
			instance[property] = new
		end
	end)

	return {
		cancel = function()
			connection:Disconnect()
		end,
	}
end

function Animation.typewriter(textLabel, text, charDelay)
	charDelay = charDelay or 0.03
	textLabel.Text = ""

	local cancelled = false

	task.spawn(function()
		for i = 1, #text do
			if cancelled then break end
			textLabel.Text = string.sub(text, 1, i)
			task.wait(charDelay)
		end
	end)

	return {
		cancel = function()
			cancelled = true
		end,
		skip = function()
			cancelled = true
			textLabel.Text = text
		end,
	}
end

function Animation.numberCounter(textLabel, startValue, endValue, duration, format)
	duration = duration or 1
	format = format or "%d"

	local elapsed = 0
	local connection

	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		alpha = 1 - (1 - alpha) ^ 3

		local current = startValue + (endValue - startValue) * alpha
		textLabel.Text = string.format(format, current)

		if alpha >= 1 then
			connection:Disconnect()
		end
	end)

	return {
		cancel = function()
			connection:Disconnect()
		end,
	}
end

function Animation.registerPreset(name, config)
	Presets[name] = config
end

Animation.Presets = Presets

return Animation