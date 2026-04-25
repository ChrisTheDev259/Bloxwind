--!strict
-- TriggersController: discovers every trigger module under Internal/Triggers
-- once at module load and exposes a name-keyed registry.

local Types = require(script.Parent.Types)

export type TriggerModule = Types.TriggerModule

local Trigger = {}

local triggers: { [string]: TriggerModule } = {}

local function isValidModule(value: any): boolean
	return type(value) == "table"
		and type(value.name) == "string"
		and type(value.connect) == "function"
end

function Trigger.register(def: TriggerModule)
	triggers[def.name:lower()] = def
end

function Trigger.GetTriggers(): { [string]: TriggerModule }
	return triggers
end

-- Returns the trigger module registered for `name` (case-insensitive), or nil.
function Trigger.Get(name: string): TriggerModule?
	return triggers[name:lower()]
end

local folder = script.Parent:FindFirstChild("Triggers")
if folder then
	for _, module in ipairs(folder:GetChildren()) do
		if module:IsA("ModuleScript") then
			local ok, def = pcall(require, module)
			if not ok then
				warn(("[Bloxwind] trigger '%s' failed to load: %s"):format(module.Name, tostring(def)))
			elseif isValidModule(def) then
				Trigger.register(def)
			else
				warn(("[Bloxwind] trigger '%s' missing 'name' or 'connect', skipped"):format(module.Name))
			end
		end
	end
else
	warn("[Bloxwind] TriggersController: no 'Triggers' folder next to Internal")
end

return Trigger
