-- size property: sets the animation target's Size to a parsed UDim2.
-- Value syntax is documented in properties/UDim2Parser.

local UDim2Parser = require(script.Parent.UDim2Parser)

local size = {}

function size.Apply(gui, IsDefault, value: string)
	local current = gui.instance.Size
	local result, err = UDim2Parser.Parse(value, current)
	if not result then
		warn(("[Bloxwind] size on %s: %s (got '%s')"):format(gui.instance.Name, err or "invalid", tostring(value)))
		return
	end
	gui.Config.Animation_config.size = result
end

return size
