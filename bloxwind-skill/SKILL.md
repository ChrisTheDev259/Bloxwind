---
name: bloxwind
description: Use whenever a user is building or editing a Roblox GUI animation with the Bloxwind library. Triggers include any mention of "Bloxwind", a `bw_*` attribute, a Bloxwind tag, the `Bloxwind.Get_Gui` function, or requests to make a Roblox UI element animate on hover/click/state-change in a Rojo project that has `src/shared/Bloxwind`. Also trigger when a user asks for "Tailwind-style" or attribute-driven UI animations in Roblox, when they want to add hover/click effects to a Frame/TextButton/ImageButton/etc. without writing tween code by hand, or when something "bw_..." appears in an .rbxlx/.rbxl/Lua snippet they share. Trigger even if the user does not explicitly say "skill" or "Bloxwind" but is clearly working in this project.
---

# Bloxwind

Bloxwind is an attribute and tag driven animation layer for Roblox GuiObjects. The user names elements with `bw_*` attributes (or applies a CollectionService tag from `ReplicatedStorage.Bloxwind.Tag`), and the client wraps them with a Bloxwind instance that animates state changes via TweenService. Think of it as a Tailwind style for Roblox UI: declarative, composable, no per-element tween code.

Use this skill any time the user is wiring up Bloxwind animations, debugging why a `bw_*` attribute is not animating, or extending the library with a new property or trigger.

## What Bloxwind already gives the user

The Rojo project layout is:

```
src/shared/Bloxwind/        -> ReplicatedStorage.Bloxwind (the library)
  Bloxwind.lua              -> public module
  Defaults.lua              -> global animation defaults
  Internal/
    Animator.lua            -> TweenService driver
    Config.lua              -> property snapshot + priority merge
    PropertiesController.lua -> registry for properties/*.lua
    TriggersController.lua   -> registry for Triggers/*.lua
    Types.lua
    properties/
      size.lua, position.lua, trigger.lua, UDim2Parser.lua
    Triggers/
      hover.lua, click.lua
src/client/Bloxwind_Client/ -> StarterPlayerScripts.Bloxwind_client
```

The client script auto-wraps every `GuiObject` under `PlayerGui`, including descendants added later, so the user normally never calls `Get_Gui` themselves.

## The three ways to configure an element

In ascending priority (later overrides earlier):

1. `low` priority: tags. Add a tag in `ReplicatedStorage.Bloxwind.Tag` (any Instance whose Name matches a CollectionService tag the gui has). Its `bw_*` attributes are copied to every tagged gui.
2. `mid` priority: instance attributes on the gui itself. Any attribute named `bw_<property>` or `bw_<property>_default`.
3. `high` priority: runtime calls, e.g. `gui:Set_Config("size", "*1.2", "high")`.

Higher priority wins. Defaults come from `Bloxwind/Defaults.lua` and apply only where nothing else is set.

## Attribute naming rules (this is the part people get wrong)

Attribute names are parsed by splitting on `_`:

- Must start with `bw_`.
- The second segment is the lowercase property name: `bw_size`, `bw_rotation`, `bw_backgroundcolor3`.
- A third segment of `default` marks the value as a reset target instead of an animation goal: `bw_size_default`, `bw_rotation_default`. These are what the gui returns to when `AutoReset` is on and the trigger releases (e.g. on MouseLeave).
- `bw_active` is reserved. It is a boolean that drives the state machine: setting it to `true` plays the animation, setting it to `false` plays back to defaults. `play()` and `play_back()` just toggle it.

If `bw_active` does not appear, the constructor adds it for you.

## Properties you can animate

These map directly to Roblox properties via `Internal/Animator.lua`:

| `bw_*` key             | Roblox property         | Value type the user passes |
|------------------------|-------------------------|----------------------------|
| `bw_size`              | `Size`                  | UDim2 string (see below)   |
| `bw_position`          | `Position`              | UDim2 string (see below)   |
| `bw_anchorpoint`       | `AnchorPoint`           | Vector2                    |
| `bw_rotation`          | `Rotation`              | number (degrees)           |
| `bw_backgroundcolor3`  | `BackgroundColor3`      | Color3                     |
| `bw_backgroundtransparency` | `BackgroundTransparency` | number 0-1            |
| `bw_textcolor3`        | `TextColor3`            | Color3                     |
| `bw_texttransparency`  | `TextTransparency`      | number 0-1                 |
| `bw_imagecolor3`       | `ImageColor3`           | Color3                     |
| `bw_imagetransparency` | `ImageTransparency`     | number 0-1                 |

Tween shape (apply to the whole gui, not a specific property):

| `bw_*` key            | Maps to TweenInfo field |
|-----------------------|-------------------------|
| `bw_duration`         | length in seconds       |
| `bw_easing`           | `Enum.EasingStyle`      |
| `bw_easingdirection`  | `Enum.EasingDirection`  |
| `bw_repeatcount`      | int                     |
| `bw_reverses`         | bool                    |
| `bw_delaytime`        | number                  |

Special:

| `bw_*` key   | Meaning |
|--------------|---------|
| `bw_trigger` | Comma separated list of trigger names, e.g. `"hover"` or `"click"` or `"hover,click"`. |

Animator only writes properties that exist on the gui (it pcalls before assigning), so it is safe to put `bw_textcolor3` on a Frame, the Frame just ignores it.

Caveat on the enum tween fields. Roblox attributes do not support Enum types. `bw_easing` and `bw_easingdirection` therefore cannot be set as Studio attributes in any usable form (the codepath stores whatever string was given and `TweenInfo.new("Quad", ...)` will fail). Set these in `Defaults.lua` for project-wide values, or pass real `Enum.EasingStyle.Quad` / `Enum.EasingDirection.Out` via `bw:Set_Config("easing", Enum.EasingStyle.Quad, "high")` at runtime.

## UDim2 string syntax (size and position)

`size` and `position` accept a single string parsed by `Internal/properties/UDim2Parser.lua`. There is no other accepted form.

| Input            | Result                                                              |
|------------------|---------------------------------------------------------------------|
| `"0.5"`          | UDim2 with scale 0.5 on both axes, offset 0                         |
| `"0.5,0.2"`      | scale 0.5 on X, 0.2 on Y, offset 0                                  |
| `"0.5,10,0.2,0"` | full literal `xScale,xOffset,yScale,yOffset`                        |
| `"*1.1"`         | multiply current scale AND offset by 1.1 on both axes               |
| `"*1.2,*1.0"`    | multiply per axis (X by 1.2, Y unchanged)                           |
| `"+0.1,+0"`      | add 0.1 to X scale, leave Y alone (offset unchanged)                |
| `"-0.05,-0"`     | subtract from scale on X axis                                       |

Mixing ops per axis is allowed: `"*1.1,+0.05"` is valid. The 4 part literal cannot use prefixes.

When picking values, remember "current" means "whatever the gui has right now." If the goal is `bw_size = "*1.2"` and the gui starts at scale 1, the animation target is scale 1.2.

## Triggers

The `bw_trigger` attribute connects Roblox events to Bloxwind state changes:

- `hover`: `MouseEnter` plays forward, `MouseLeave` plays back. The `_default` values are what it goes back to.
- `click`: `Activated` plays forward, waits `bw_duration`, plays back.

Add a trigger by dropping a ModuleScript in `src/shared/Bloxwind/Internal/Triggers/`. The module must export `{ name = "thing", connect = function(gui) ... end }` and return one or more `RBXScriptConnection`s (single connection or a table). They are auto-cleaned on Destroy.

To stack triggers: `bw_trigger = "hover,click"`.

## Public API (when scripting against Bloxwind directly)

The user usually does not call these. The Bloxwind client wraps every PlayerGui descendant automatically. Reach for the API when scripting things like animations on instances outside PlayerGui, dynamic config changes, or programmatic teardown.

```lua
local Bloxwind = require(ReplicatedStorage.Bloxwind.Bloxwind)

local bw = Bloxwind.Get_Gui(myFrame) -- idempotent, returns existing wrapper if already registered

bw:play()        -- sets bw_active = true, runs forward animation
bw:play_back()   -- sets bw_active = false, returns to defaults

bw:Set_Config("size", "*1.2", "high")   -- runtime override at high priority
bw:Set_Config("rotation", 15, "high")

bw:Set_Attr_Config()   -- re-scan attributes (called once at wrap time)
bw:Set_Tag_Config(tag) -- copy bw_* attributes from a tag instance (called per matched tag at wrap time)

bw:Destroy()           -- disconnect everything. Also runs automatically when the gui is destroyed.
```

`Set_Config` writes into the priority core (`low` / `mid` / `high`) and re-merges before applying. Pass a real priority string when you mean it; the default is `"high"`.

## Common patterns

### Hover-grow button

Set the goal as the bw_* attributes, set the resting state as `_default`, declare the trigger.

```
bw_trigger          = "hover"
bw_size             = "*1.1"
bw_size_default     = "*1.0"
bw_duration         = 0.15
```

A pure `*1.1` works because the parser uses the live UDim2 as the base. The `_default` of `*1.0` snapshots back to "current x 1," which is just the original. If the user wants to animate from a fixed size instead, use the 4-part literal: `bw_size_default = "0.2,0,0.1,0"`.

### Click-flash

```
bw_trigger              = "click"
bw_backgroundcolor3     = Color3.fromRGB(255, 200, 80)
bw_backgroundcolor3_default = Color3.fromRGB(40, 40, 40)
bw_duration             = 0.1
```

Click triggers play forward, wait `bw_duration`, then play back. So `bw_duration` doubles as the flash hold time.

### Apply once to a class of buttons via tag

1. Add a child Instance under `ReplicatedStorage.Bloxwind.Tag` named `"PrimaryButton"` (or whatever).
2. Set `bw_*` attributes on that tag instance.
3. In Studio (or via CollectionService at runtime), tag each button with `"PrimaryButton"`.

The client copies the tag's attributes into every matched gui at `low` priority, so per-instance attributes still win.

## Defaults

`src/shared/Bloxwind/Defaults.lua` is a plain Lua table. Edit it for project-wide changes to tween timing or any animated property. Keys must be lowercase. The Animator has its own hard fallback (duration 0.25, EasingStyle.Quad, EasingDirection.Out) so deleting entries is safe.

## Adding a new property module

Drop a ModuleScript in `src/shared/Bloxwind/Internal/properties/` exporting:

```lua
local Types = require(script.Parent.Parent.Types)

local mod: Types.PropertyModule = {
    Apply = function(gui, IsDefault, value)
        -- Parse `value`, then write into gui.Config.Animation_config.<key>
        -- using the lowercase key the Animator's PROP_MAP expects.
    end,
}
return mod
```

`PropertiesController` auto-discovers it. The module name (lowercased) is what `bw_<name>` will look up. If the property maps to a Roblox property that is not in `Internal/Animator.lua`'s `PROP_MAP`, add it there too.

Note the `IsDefault` flag. The current size/position modules ignore it because both the goal and the default both write into `Animation_config` and the dispatcher controls which one is played. If the new property needs different behavior for defaults, branch on `IsDefault`.

## When something is not animating

Run through this:

1. Is the gui under `PlayerGui` or a descendant? The client only wraps `PlayerGui` descendants. For ScreenGuis in `ReplicatedStorage` that are cloned in later, that is fine, they get caught by `DescendantAdded`.
2. Is the attribute named `bw_<lowercase property>`? Capitalization in the second segment will silently fall through and end up only in `Animation_config` as a string, which the Animator will ignore because PROP_MAP keys are lowercase.
3. For size/position, did the user pass a string? Numbers and UDim2 values bypass the parser and will be written straight to `Animation_config`, which then fails the type check at tween creation. Always strings here.
4. For colors / vectors / enums, did the user use the actual Roblox value type? Studio attribute UI exposes Color3, Vector2, etc. directly; that is what to set.
5. Is `bw_trigger` set? Without a trigger, the only way to animate is to call `bw:play()` from another script.
6. For tags: is the tag instance a child of `ReplicatedStorage.Bloxwind.Tag` with a Name that matches the CollectionService tag the gui has? Both must be true.

The library prints `[Bloxwind] ...` warnings for parse failures, missing triggers, and malformed property modules. Have the user open the Output window before debugging.

## Integration notes

- Aftman pins `rojo-rbx/rojo@7.7.0-rc.1`. The project syncs via Rojo as `Bloxwind.rbxl`.
- All Lua here uses the `--!strict` directive on internals; preserve it when editing.
- `Bloxwind.Get_Gui` is idempotent and caches per gui in a module-level `Registered_Guis` table. Calling it twice on the same gui returns the same wrapper.
- The wrapper auto-destroys on `gui.Destroying`. Any scripting against `bw` after the gui is gone is a no-op (every method early-returns on `_destroyed`).

## What this skill is not

Not a replacement for TweenService or for general Roblox UI advice. If the user's problem is unrelated to Bloxwind's surface (custom non-tween animations, layout issues, input handling outside hover/click), step out of this skill and answer normally.
