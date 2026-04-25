local Config = {}

-- Load global defaults. Safe-fails if the Defaults module is missing or errors.
local DEFAULTS: { [string]: any } = {}
do
	local defaultsModule = script.Parent.Parent:FindFirstChild("Defaults")
	if defaultsModule and defaultsModule:IsA("ModuleScript") then
		local ok, result = pcall(require, defaultsModule)
		if ok and type(result) == "table" then
			DEFAULTS = result
		else
			warn("[Bloxwind] Defaults module failed to load:", result)
		end
	end
end

-- Shallow copy so no GUI can mutate the shared defaults table.
local function copyDefaults(): { [string]: any }
	local out = {}
	for k, v in pairs(DEFAULTS) do
		out[k] = v
	end
	return out
end

export type BloxwindConfig = {
	AutoReset: boolean,
	Default_Properties: { [string]: any },
	Animation_config: { [string]: any },
	properties: { [string]: any },
}

export type CoreConfig = {
	low: { [string]: any },
	mid: { [string]: any },
	high: { [string]: any },
}

function Config.Make_Config(self)
	
	local core_conf = {}
	local conf = {}
	
	local gui = self.instance	
	
	core_conf["low"]={}
	core_conf["mid"]={}
	core_conf["high"]={}
	
	local POSSIBLE_PROPS = {
		"Size","Position","BackgroundColor3","BackgroundTransparency",
		"TextColor3","ImageColor3","ImageTransparency","Rotation","AnchorPoint",
	}
	
	
	
	local function snapshotProps(gui: Instance, list: {string}?): {[string]: any} -- this function gets properties of different types if guis
		list = list or POSSIBLE_PROPS
		local t = {}
		for _, prop in ipairs(list) do
			local ok, v = pcall(function() return gui[prop] end)
			if ok then t[prop] = v or conf.Default_Properties[prop] end
		end
		return t
	end
	
	conf.AutoReset = true -- this determines if the gui will reset properties after animation finished playing. (example: hover and hoverout)
	conf.Default_Properties = snapshotProps(gui) -- resets to thesse properties after animation if AutoReset is on

	-- Seed Animation_config with global defaults. Attribute values overwrite these
	-- when Apply_Config runs, so defaults only apply where nothing else is set.
	conf.Animation_config = copyDefaults()
	
	self.core_config = core_conf
	
	self.Config = conf
	self.Config.properties = {}

	return core_conf, conf
end

local function merge_core(core)
	local merged = {}
	
	-- apply in ascending priority, so later tiers overwrite earlier ones
	for _, tier in ipairs({ "low", "mid", "high" }) do
		for k, v in pairs(core[tier]) do
			merged[k]=v
		end

	end
	
	return merged
end

function Config.Set_Config(setting, value, priority, gui)
	assert(setting ~= nil, "Config.Set_Config: 'setting' is required")
	
	local core = gui.core_config

	core = core or { low = {}, mid = {}, high = {} }
	local tier = priority or "high"
	assert(core[tier], ("Config.Set_Config: invalid priority '%s'"):format(tier))

	core[tier][setting] = value

	local merged = merge_core(core)
	
	gui.core_config = core
	gui.Config.properties[setting] = merged[setting]
	
end

function Config.Get_Formatted_Config(core)
	return
end

return Config