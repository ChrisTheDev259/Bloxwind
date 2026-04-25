--!strict
-- Shared types for Bloxwind internals. Lives in its own module so that
-- property modules and registries can reference these types without
-- creating circular dependencies.

local Types = {}

-- A property module owns parsing and applying one named animation property
-- (e.g. "size", "position", "trigger"). It receives the Bloxwind instance
-- (typed as `any` here to avoid importing Bloxwind.lua), an `IsDefault` flag
-- indicating whether the value should be treated as a reset target, and the
-- raw value pulled from the attribute / tag / runtime call.
--
-- Apply may return any value; the dispatcher in Bloxwind.Apply_Config decides
-- how to interpret it. The trigger property returns RBXScriptConnections so
-- they can be tracked for cleanup.
export type PropertyModule = {
	Apply: (gui: any, IsDefault: boolean, value: any) -> any,
}

-- A trigger module wires up Roblox events to drive Bloxwind animations on a
-- gui (e.g. hover, click). `connect` is called once per gui and should return
-- one or more RBXScriptConnections so they can be disconnected on destroy.
export type TriggerModule = {
	name: string,
	connect: (gui: any) -> any,
}

return Types
