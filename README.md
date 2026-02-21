# Luix

A modular, React-inspired UI framework for Roblox built in Luau.

Luix provides reactive state management, component lifecycle, theming, responsive scaling, animations, routing, and a custom signal system — all in one lightweight package.

## Features

- **Reactive State** — Observable values, Redux-like stores, computed state
- **Components** — Class-based with full lifecycle (`init`, `render`, `didMount`, `willUnmount`)
- **Hooks** — `useState`, `useEffect`, `useMemo`, `useReducer`, `useStore` and more
- **Theming** — Dark/Light/Midnight built-in, extendable with custom themes
- **Scaler** — Automatic responsive scaling across all screen sizes
- **Animation** — Tweens, presets, springs, stagger, typewriter, number counters
- **Router** — SPA-style navigation with guards, middleware, and history
- **Signal** — Lightweight custom event system

## Installation

1. Place the `Luix` folder (with all modules) in `ReplicatedStorage`
2. Each `.lua` file = one `ModuleScript` inside the `Luix` folder
3. `init.lua` is the folder's root `ModuleScript`

```
ReplicatedStorage/
└── Luix/
    ├── init.lua
    ├── State.lua
    ├── Component.lua
    ├── Element.lua
    ├── Renderer.lua
    ├── Scaler.lua
    ├── Theme.lua
    ├── Hooks.lua
    ├── Animation.lua
    ├── Router.lua
    └── Signal.lua
```

## Quick Start

```lua
local Luix = require(game.ReplicatedStorage.Luix)
local State = Luix.State
local Theme = Luix.Theme
local Scaler = Luix.Scaler
local Animation = Luix.Animation

Theme.set("Dark")
Scaler.setBaseResolution(1280, 720)

local counter = State.new(0)

counter:subscribe(function(value)
    print("Counter:", value)
end)

counter:set(counter:get() + 1)
```

## Modules

| Module | Description |
|---|---|
| `State` | Reactive state, stores, computed values |
| `Component` | Class-based components with lifecycle |
| `Element` | Virtual UI element representation |
| `Renderer` | Reconciliation engine, mounts elements to Roblox |
| `Scaler` | Responsive auto-scaling with breakpoints |
| `Theme` | Theming system with live switching |
| `Hooks` | React-like hooks for functional patterns |
| `Animation` | Tweening, presets, springs, sequences |
| `Router` | Client-side routing with guards |
| `Signal` | Custom event/callback system |

## Documentation

See the full documentation at the [Luix Docs](https://luixrbx.netlify.app/) page.

## License

MIT
