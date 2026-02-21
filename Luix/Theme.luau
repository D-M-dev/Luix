local Signal = require(script.Parent.Signal)

local Theme = {}
Theme.__index = Theme

local activeTheme = nil
local themeChanged = Signal.new()
local themes = {}

local DEFAULT_THEMES = {
	Dark = {
		name = "Dark",
		colors = {
			background = Color3.fromRGB(18, 18, 24),
			surface = Color3.fromRGB(28, 28, 38),
			surfaceHover = Color3.fromRGB(38, 38, 52),
			surfaceActive = Color3.fromRGB(48, 48, 62),
			primary = Color3.fromRGB(88, 130, 255),
			primaryHover = Color3.fromRGB(110, 150, 255),
			secondary = Color3.fromRGB(160, 120, 255),
			accent = Color3.fromRGB(0, 210, 180),
			success = Color3.fromRGB(80, 220, 120),
			warning = Color3.fromRGB(255, 200, 60),
			danger = Color3.fromRGB(255, 80, 80),
			info = Color3.fromRGB(60, 180, 255),
			text = Color3.fromRGB(240, 240, 245),
			textSecondary = Color3.fromRGB(160, 160, 180),
			textMuted = Color3.fromRGB(100, 100, 120),
			border = Color3.fromRGB(50, 50, 65),
			overlay = Color3.fromRGB(0, 0, 0),
			shadow = Color3.fromRGB(0, 0, 0),
		},
		transparency = {
			overlay = 0.4,
			shadow = 0.6,
			disabled = 0.5,
			hover = 0.9,
		},
		typography = {
			fontFamily = Enum.Font.GothamMedium,
			fontBold = Enum.Font.GothamBold,
			fontLight = Enum.Font.Gotham,
			h1 = 32,
			h2 = 24,
			h3 = 20,
			h4 = 16,
			body = 14,
			caption = 12,
			small = 10,
		},
		spacing = {
			xs = 4,
			sm = 8,
			md = 12,
			lg = 16,
			xl = 24,
			xxl = 32,
		},
		radius = {
			none = 0,
			sm = 4,
			md = 8,
			lg = 12,
			xl = 16,
			full = 9999,
		},
	},

	Light = {
		name = "Light",
		colors = {
			background = Color3.fromRGB(245, 245, 250),
			surface = Color3.fromRGB(255, 255, 255),
			surfaceHover = Color3.fromRGB(240, 240, 245),
			surfaceActive = Color3.fromRGB(230, 230, 238),
			primary = Color3.fromRGB(60, 100, 230),
			primaryHover = Color3.fromRGB(45, 85, 210),
			secondary = Color3.fromRGB(130, 90, 220),
			accent = Color3.fromRGB(0, 180, 155),
			success = Color3.fromRGB(40, 180, 90),
			warning = Color3.fromRGB(230, 170, 20),
			danger = Color3.fromRGB(220, 50, 50),
			info = Color3.fromRGB(30, 150, 230),
			text = Color3.fromRGB(20, 20, 30),
			textSecondary = Color3.fromRGB(80, 80, 100),
			textMuted = Color3.fromRGB(140, 140, 160),
			border = Color3.fromRGB(210, 210, 220),
			overlay = Color3.fromRGB(0, 0, 0),
			shadow = Color3.fromRGB(0, 0, 0),
		},
		transparency = {
			overlay = 0.5,
			shadow = 0.8,
			disabled = 0.5,
			hover = 0.95,
		},
		typography = {
			fontFamily = Enum.Font.GothamMedium,
			fontBold = Enum.Font.GothamBold,
			fontLight = Enum.Font.Gotham,
			h1 = 32,
			h2 = 24,
			h3 = 20,
			h4 = 16,
			body = 14,
			caption = 12,
			small = 10,
		},
		spacing = {
			xs = 4,
			sm = 8,
			md = 12,
			lg = 16,
			xl = 24,
			xxl = 32,
		},
		radius = {
			none = 0,
			sm = 4,
			md = 8,
			lg = 12,
			xl = 16,
			full = 9999,
		},
	},

	Midnight = {
		name = "Midnight",
		colors = {
			background = Color3.fromRGB(10, 10, 20),
			surface = Color3.fromRGB(18, 18, 32),
			surfaceHover = Color3.fromRGB(25, 25, 45),
			surfaceActive = Color3.fromRGB(35, 35, 55),
			primary = Color3.fromRGB(120, 80, 255),
			primaryHover = Color3.fromRGB(140, 100, 255),
			secondary = Color3.fromRGB(255, 100, 180),
			accent = Color3.fromRGB(0, 255, 200),
			success = Color3.fromRGB(0, 230, 130),
			warning = Color3.fromRGB(255, 180, 40),
			danger = Color3.fromRGB(255, 60, 90),
			info = Color3.fromRGB(80, 160, 255),
			text = Color3.fromRGB(230, 230, 250),
			textSecondary = Color3.fromRGB(150, 150, 180),
			textMuted = Color3.fromRGB(90, 90, 120),
			border = Color3.fromRGB(40, 40, 60),
			overlay = Color3.fromRGB(0, 0, 0),
			shadow = Color3.fromRGB(0, 0, 0),
		},
		transparency = {
			overlay = 0.3,
			shadow = 0.5,
			disabled = 0.5,
			hover = 0.9,
		},
		typography = {
			fontFamily = Enum.Font.GothamMedium,
			fontBold = Enum.Font.GothamBold,
			fontLight = Enum.Font.Gotham,
			h1 = 32,
			h2 = 24,
			h3 = 20,
			h4 = 16,
			body = 14,
			caption = 12,
			small = 10,
		},
		spacing = {
			xs = 4,
			sm = 8,
			md = 12,
			lg = 16,
			xl = 24,
			xxl = 32,
		},
		radius = {
			none = 0,
			sm = 4,
			md = 8,
			lg = 12,
			xl = 16,
			full = 9999,
		},
	},
}

for name, theme in pairs(DEFAULT_THEMES) do
	themes[name] = theme
end

activeTheme = themes.Dark

function Theme.get()
	return activeTheme
end

function Theme.set(themeName)
	if themes[themeName] then
		activeTheme = themes[themeName]
		themeChanged:Fire(activeTheme)
	else
		warn("[Framework.Theme] Theme not found: " .. tostring(themeName))
	end
end

function Theme.register(name, themeData)
	themes[name] = themeData
	themeData.name = name
end

function Theme.extend(baseName, name, overrides)
	local base = themes[baseName]
	if not base then
		warn("[Framework.Theme] Base theme not found: " .. tostring(baseName))
		return
	end

	local newTheme = {}
	local function deepCopy(source, target)
		for k, v in pairs(source) do
			if type(v) == "table" and type(target[k]) == "table" then
				local merged = {}
				deepCopy(v, merged)
				for mk, mv in pairs(target[k]) do
					merged[mk] = mv
				end
				target[k] = merged
			elseif target[k] == nil then
				target[k] = v
			end
		end
	end

	for k, v in pairs(overrides) do
		if type(v) == "table" then
			newTheme[k] = {}
			for ik, iv in pairs(v) do
				newTheme[k][ik] = iv
			end
		else
			newTheme[k] = v
		end
	end

	for k, v in pairs(base) do
		if newTheme[k] == nil then
			if type(v) == "table" then
				newTheme[k] = {}
				for ik, iv in pairs(v) do
					newTheme[k][ik] = iv
				end
			else
				newTheme[k] = v
			end
		elseif type(v) == "table" and type(newTheme[k]) == "table" then
			for ik, iv in pairs(v) do
				if newTheme[k][ik] == nil then
					newTheme[k][ik] = iv
				end
			end
		end
	end

	newTheme.name = name
	themes[name] = newTheme
end

function Theme.color(key)
	return activeTheme.colors[key]
end

function Theme.font(key)
	return activeTheme.typography[key]
end

function Theme.space(key)
	return activeTheme.spacing[key]
end

function Theme.round(key)
	return activeTheme.radius[key]
end

function Theme.alpha(key)
	return activeTheme.transparency[key]
end

function Theme.onChanged(callback)
	return themeChanged:Connect(callback)
end

function Theme.list()
	local names = {}
	for name in pairs(themes) do
		table.insert(names, name)
	end
	return names
end

function Theme.toggle()
	if activeTheme.name == "Dark" then
		Theme.set("Light")
	else
		Theme.set("Dark")
	end
end

return Theme