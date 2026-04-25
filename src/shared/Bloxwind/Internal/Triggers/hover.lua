-- Hover trigger: plays forward on MouseEnter, back on MouseLeave.

return {
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
