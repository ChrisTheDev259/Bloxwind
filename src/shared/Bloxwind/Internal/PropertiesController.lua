--!strict
-- PropertiesController: discovers every property module under Internal/properties
-- once at module load and exposes a hashmap lookup. Avoids repeated FindFirstChild
-- calls in the hot path (Bloxwind.Apply_Config runs on every animated property).

export type PropertyModule = {
	Apply: (gui: any, IsDefault: boolean, value: any) -> any,
}

local Properties = {}

local registry: { [string]: PropertyModule } = {}

-- Validates the shape of a required module so a malformed property module
-- doesn't crash the whole library at load time.
local function isValidModule(value: any): boolean
	return type(value) == "table" and type(value.Apply) == "function"
end

local function loadFolder(folder: Instance)
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("ModuleScript") then
			local ok, mod = pcall(require, child)
			if not ok then
				warn(("[Bloxwind] property '%s' failed to load: %s"):format(child.Name, tostring(mod)))
			elseif isValidModule(mod) then
				-- Modules without an Apply function are treated as helpers
				-- (e.g. UDim2Parser) and silently skipped.
				registry[child.Name:lower()] = mod
			end
		end
	end
end

local folder = script.Parent:FindFirstChild("properties")
if folder then
	loadFolder(folder)
else
	warn("[Bloxwind] PropertiesController: no 'properties' folder next to Internal")
end

-- Returns the property module registered for `name`, or nil.
function Properties.Get(name: string): PropertyModule?
	return registry[name:lower()]
end

-- Returns the full registry (read-only by convention).
function Properties.GetAll(): { [string]: PropertyModule }
	return registry
end

return Properties
