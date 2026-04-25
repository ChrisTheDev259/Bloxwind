--!strict
-- Clicked trigger: plays the animation, waits for its duration, then plays back.

local Types = require(script.Parent.Parent.Types)

local click: Types.TriggerModule = {
	name = "click",
	connect = function(gui)
		return gui.instance.Activated:Connect(function()
			gui:play()
			task.wait(gui.Config.Animation_config.duration)
			gui:play_back()
		end)
	end,
}

return click
