--!strict
-- trigger property: connects one or more triggers to a GUI.
-- Value syntax: comma-separated list of trigger names, e.g. "hover,hoverout" or "clicked".

local Types = require(script.Parent.Parent.Types)
local TriggersController = require(script.Parent.Parent.TriggersController)

local trigger: Types.PropertyModule = {
	Apply = function(gui, IsDefault, value)
		local connected: { RBXScriptConnection } = {}

		if typeof(value) ~= "string" then
			warn(("[Bloxwind] trigger on %s: expected string, got %s"):format(gui.instance.Name, typeof(value)))
			return connected
		end

		for name in string.gmatch(value:lower(), "([^,]+)") do
			name = (name:gsub("%s+", ""))
			local def = TriggersController.Get(name)

			if def then
				local connection = def.connect(gui)
				if connection then
					table.insert(connected, connection)
				end
			else
				warn(("[Bloxwind] unknown trigger '%s' on %s"):format(name, gui.instance.Name))
			end
		end

		return connected
	end,
}

return trigger
