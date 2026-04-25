-- Animator.lua
local TweenService = game:GetService("TweenService")

local Animator = {}

-- Defaults (used only if missing in Animation_config)
local DEFAULTS = {
	duration        = 0.25,
	easing          = Enum.EasingStyle.Quad,
	easingDirection = Enum.EasingDirection.Out,
	repeatCount     = 0,
	reverses        = false,
	delayTime       = 0,
}

-- config key (lowercase) -> Roblox property
local PROP_MAP = {
	size                   = "Size",
	position               = "Position",
	anchorpoint            = "AnchorPoint",
	rotation               = "Rotation",
	backgroundcolor3       = "BackgroundColor3",
	backgroundtransparency = "BackgroundTransparency",
	textcolor3             = "TextColor3",
	texttransparency       = "TextTransparency",
	imagecolor3            = "ImageColor3",
	imagetransparency      = "ImageTransparency",
}

local function lowerKeys(t)
	local out = {}
	for k,v in pairs(t or {}) do
		out[type(k)=="string" and k:lower() or k] = v
	end
	return out
end

function Animator.play(gui,AnimConfig)
	
	AnimConfig = AnimConfig or gui.Config.Animation_config

	local base = lowerKeys(AnimConfig or {})
	for k, v in pairs(DEFAULTS) do if base[k] == nil then base[k] = v end end
	
	local info = TweenInfo.new(
		base.duration		 or DEFAULTS.duration,
		base.easing			 or DEFAULTS.easing,
		base.easingDirection or DEFAULTS.easingdirection,
		base.repeatCount     or DEFAULTS.repeatcount,
		base.reverses		 or DEFAULTS.reverses,
		base.delayTime       or DEFAULTS.delaytime
	)


	local goals = {}
	for kLower, propName in pairs(PROP_MAP) do
		local v = base[kLower]
		if v ~= nil then
			if pcall(function() return gui[propName] end) then
				goals[propName] = v
			end
		end
	end

	local tween = TweenService:Create(gui.instance, info, goals)
	tween:Play()
	return tween
end

return Animator