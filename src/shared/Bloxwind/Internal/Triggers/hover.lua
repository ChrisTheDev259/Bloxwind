--!strict
-- Hover trigger: plays forward on MouseEnter, back on MouseLeave.

local Types = require(script.Parent.Parent.Types)

local hover: Types.TriggerModule = {
	name = "hover",
	connect = function(gui)
		local enter = gui.instance.MouseEnter:Connect(function()
			gui:play()
		end)

		local leave = gui.instance.MouseLeave:Connect(function()
			gui:play_back()
		end)

		return { enter, leave }
	end,
}

return hover
