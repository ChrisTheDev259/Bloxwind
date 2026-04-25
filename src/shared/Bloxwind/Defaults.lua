-- Bloxwind global defaults.
-- These apply to every wrapped GuiObject unless overridden by a bw_* attribute,
-- a tag, or a runtime Set_Config call.
--
-- Keys must be lowercase and match the Animator's PROP_MAP / TweenInfo fields.
-- Safe to edit. Safe to delete entire entries (Animator has its own final fallbacks).

return {
	-- Tween timing
	duration        = 0.2,
	easing          = Enum.EasingStyle.Quad,
	easingDirection = Enum.EasingDirection.Out,
	repeatCount     = 0,
	reverses        = false,
	delayTime       = 0,

	-- Add any animated-property defaults here, e.g.:
	-- rotation = 0,
	-- backgroundtransparency = 0,
}
