--!strict
-- position property: sets the animation target's Position to a parsed UDim2.
-- Value syntax is documented in properties/UDim2Parser.

local Types = require(script.Parent.Parent.Types)
local UDim2Parser = require(script.Parent.UDim2Parser)

local position: Types.PropertyModule = {
	Apply = function(gui, IsDefault, value)
		local current = gui.instance.Position
		local result, err = UDim2Parser.Parse(value, current)
		if not result then
			warn(("[Bloxwind] position on %s: %s (got '%s')"):format(gui.instance.Name, err or "invalid", tostring(value)))
			return
		end
		gui.Config.Animation_config.position = result
	end,
}

return position
