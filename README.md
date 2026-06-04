# Bloxwind

Attribute-driven animation for Roblox GUIs. Set `bw_*` attributes on a `GuiObject` (or on a `Configuration` used as a tag) and Bloxwind captures defaults, tweens to your targets, and reverts on the opposite event.

## Quick start

1. Place a `GuiObject` under `PlayerGui`.
2. In Properties, add:
   - `bw_trigger` (string) = `hover, click`
   - `bw_size` (string) = `*1.1`
   - `bw_duration` (number) = `0.2`
3. Run the game. Hover grows the GUI by 10%. Mouse leave reverts it.

That is the whole system.

## Core concept

Every attribute starting with `bw_` is an instruction. The second segment is the property name, lowercase.

```
bw_<property>          applied on activation (animation target)
bw_<property>_default  applied on deactivation (overrides the captured default)
```

| Attribute | Meaning |
|---|---|
| `bw_size` | size to animate to when the trigger fires |
| `bw_size_default` | replaces the captured default size |
| `bw_trigger` | events that activate the animation |
| `bw_duration` | tween duration in seconds |
| `bw_easing` | `Enum.EasingStyle` value |
| `bw_backgroundcolor3` | `Color3` to animate to |

One attribute, one value, one responsibility. No combined strings like `"bg-red-500 p-4 hover:scale-105"`.

## Value syntax

All string values are lowercase, no spaces. The parser trims whitespace, but don't rely on it.

### UDim2 (`bw_size`, `bw_position`)

| Form | Meaning | Example |
|---|---|---|
| `n` | both axes to scale `n`, offset 0 | `0.5` |
| `x,y` | each axis (scale only) | `0.5,0.2` |
| `xs,xo,ys,yo` | full literal | `0.5,10,0.2,0` |
| `*n` | multiply both axes (scale and offset) | `*1.1` |
| `*x,*y` | multiply each axis | `*1.2,*1.0` |
| `+n` / `+x,+y` | add to scale | `+0.1,+0` |
| `-n` / `-x,-y` | subtract from scale | `-0.05,-0` |

Operators mix per axis. `*1.1,+0.05` means "multiply X by 1.1, add 0.05 to Y scale."

### Triggers (`bw_trigger`)

Comma-separated list. No colons, no modifiers.

```
bw_trigger = "hover,hoverout"
bw_trigger = "clicked"
```

Built-ins: `hover`, `hoverout`, `clicked`.

### Plain values

Other properties accept their native Roblox types directly on the attribute.

| Property | Attribute type | Example |
|---|---|---|
| `bw_duration` | number | `0.2` |
| `bw_rotation` | number | `15` |
| `bw_backgroundtransparency` | number | `0.5` |
| `bw_backgroundcolor3` | Color3 | set as Color3 attribute |
| `bw_textcolor3` | Color3 | set as Color3 attribute |
| `bw_anchorpoint` | Vector2 | set as Vector2 attribute |

Numeric strings (`"0.2"`) auto-convert. Native types pass through unchanged.

## Triggers

A trigger is a `ModuleScript` in `ReplicatedStorage.Bloxwind.Internal.Triggers`:

```lua
return {
    name = "hover",
    connect = function(gui)
        gui.instance.MouseEnter:Connect(function()
            gui:play()
        end)
    end,
}
```

`gui:play()` flips `bw_active` to `true` and tweens to the target values. `gui:play_back()` flips it to `false` and tweens back to captured defaults.

To add a trigger, drop a new `ModuleScript` in that folder. `TriggersController` auto-loads every child at require time.

## Tags (reusable configs)

To reuse animations across many GUIs without copying attributes:

1. Create a `Configuration` instance under `ReplicatedStorage.Bloxwind.Tag` (e.g. `hover`).
2. Add `bw_*` attributes to the `Configuration`.
3. Tag any `GuiObject` with the matching name via `CollectionService`.

The client picks this up automatically. Tag values apply at low priority, so direct attributes on the GUI override them.

## Priority tiers

Values merge in this order, later overrides earlier:

1. **low**: tag-sourced attributes
2. **mid**: attributes directly on the GUI
3. **high**: runtime calls via `gui:Set_Config(property, value)`

A tag can define a default hover effect that individual instances still override.

## Full example

A button that grows and fades on hover, reverts on leave, squeezes on click. No scripts needed.

```
bw_trigger                 = "hover,hoverout,clicked"
bw_size                    = "*1.1"
bw_backgroundtransparency  = 0.2
bw_duration                = 0.15
```

## Runtime API

```lua
local Bloxwind = require(game.ReplicatedStorage.Bloxwind.Bloxwind)
local gui = Bloxwind.Set_Gui(myButton)
gui:Set_Config("size", "*1.3")  -- high-priority override
gui:play()                       -- trigger manually
```

| Method | Purpose |
|---|---|
| `Bloxwind.Set_Gui(guiObject)` | Wrap a `GuiObject`, return a Bloxwind instance |
| `instance:Set_Config(k, v)` | Override at high priority (runtime) |
| `instance:Set_Attr_Config()` | Re-read `bw_*` attributes from the GUI |
| `instance:Set_Tag_Config(tag)` | Apply a `Configuration` tag's attributes |
| `instance:play()` | Flip `bw_active` to true (tween forward) |
| `instance:play_back()` | Flip `bw_active` to false (tween to defaults) |

## Known limitations

- **Binary state.** `bw_active` is a boolean. Simultaneous triggers (hover + focus) fight over it. A state stack is a future improvement.
- **No validation.** Typos like `bw_durtation` silently do nothing. A property registry would catch these.
- **Reverse uses forward config.** The tween back reuses the same duration and easing. Use `bw_<property>_default` for asymmetric values, or wait for `bw_duration_back`.
