local Internal = script.Parent.Internal

local config = require(Internal.Config)
local Animator = require(Internal.Animator)
local properties = Internal.properties

-- Re-export Config's types so callers only need to require Bloxwind.
export type BloxwindConfig = config.BloxwindConfig
export type CoreConfig = config.CoreConfig

-- Class

local Bloxwind = {}
Bloxwind.__index = Bloxwind

export type BloxwindInstance = typeof(setmetatable(
	{} :: {
		instance: GuiObject,
		Config: BloxwindConfig,
		core_config: CoreConfig,
		_connections: { RBXScriptConnection },
		_triggerConnections: { RBXScriptConnection },
		_destroyed: boolean,
	},
	Bloxwind
))

-- Utils

-- Flattens the output from trigger.Apply, which may be a single connection or a list
local function collectConnections(value: any, out: { RBXScriptConnection })
	if value == nil then return end

	if typeof(value) == "RBXScriptConnection" then
		table.insert(out, value)
		return
	end

	if type(value) == "table" then
		for _, v in ipairs(value) do
			collectConnections(v, out)
		end
	end
end

-- disconnect every tracked connection and drop references.
local function OnGuiDeleted(self: BloxwindInstance)
	if self._destroyed then return end
	self._destroyed = true

	for _, c in ipairs(self._connections) do
		if c.Connected then c:Disconnect() end
	end
	table.clear(self._connections)

	for _, c in ipairs(self._triggerConnections) do
		if c.Connected then c:Disconnect() end
	end
	table.clear(self._triggerConnections)
	
	if self.instance then self.instance:Destroy() end
	
	self = nil
end

-- Main

function Bloxwind.Apply_Config(self: BloxwindInstance, prop: string, value: any, IsDefault: boolean?)
	if self._destroyed then return end
	prop = prop:lower()

	-- Look up a property module. If one exists, it owns parsing and applying the value.
	local module = properties:FindFirstChild(prop)
	if module and module:IsA("ModuleScript") then
		local property = require(module) :: any
		if property and property.Apply then
			local result = property.Apply(self, IsDefault == true, value)

			-- The trigger property returns connections we need to track for cleanup.
			if prop == "trigger" then
				collectConnections(result, self._triggerConnections)
			end
			return
		end
	end

	-- No property module: store the value directly on the animation config.
	if type(value) == "string" then
		local asNumber = tonumber(value)
		self.Config.Animation_config[prop] = asNumber or value
	else
		self.Config.Animation_config[prop] = value
	end
end

function Bloxwind.Bind_Active_Changed(self: BloxwindInstance): RBXScriptConnection
	return self.instance:GetAttributeChangedSignal("bw_active"):Connect(function()
		if self._destroyed then return end
		if self.instance:GetAttribute("bw_active") == true then
			Animator.play(self)
			
		else
			Animator.play(self, self.Config.Default_Properties)
		end
	end)
end

function Bloxwind.play(self: BloxwindInstance)
	if self._destroyed then return end
	self.instance:SetAttribute("bw_active", true)
end

function Bloxwind.play_back(self: BloxwindInstance)
	if self._destroyed then return end
	self.instance:SetAttribute("bw_active", false)
end

function Bloxwind.Set_Attr_Config(self: BloxwindInstance)
	if self._destroyed then return end
	local attributes = self.instance:GetAttributes()

	for name: string, value in pairs(attributes) do
		if name == "bw_active" then continue end

		local segments = name:split("_")
		if segments[1] ~= "bw" then continue end

		local bw_property = segments[2]
		local IsDefault = segments[3] == "default"
		self:Set_Config(bw_property, value, "mid", IsDefault)
	end
end

function Bloxwind.Set_Tag_Config(self: BloxwindInstance, tag: Instance)
	if self._destroyed then return end
	local tagAttributes = tag:GetAttributes()

	for name: string, value in pairs(tagAttributes) do
		if name == "bw_active" then continue end

		local segments = name:split("_")
		if segments[1] ~= "bw" then continue end

		local bw_property = segments[2]
		local IsDefault = segments[3] == "default"
		self:Set_Config(bw_property, value, "low", IsDefault)
	end
end

function Bloxwind.Set_Config(self: BloxwindInstance, setting: string, value: any, priority: string, IsDefault: boolean?)
	if self._destroyed then return end
	if type(value) == "boolean" then return end -- this is bw_active

	if not setting or value == nil then
		warn("[Bloxwind] Value or setting missing: Bloxwind:Set_Config( ? , ? )")
		return
	end

	-- Nil priority = called from an external script, treat as dynamic/high priority.
	config.Set_Config(setting, value, priority or "high", self)

	local merged = self.Config.properties[setting]
	self:Apply_Config(setting, merged, IsDefault)

	return self.Config
end

-- Public teardown. Also called automatically when the GuiObject is destroyed.
function Bloxwind.Destroy(self: BloxwindInstance)
	OnGuiDeleted(self)
end

-- Constructor

function Bloxwind.Set_Gui(gui: GuiObject): BloxwindInstance
	-- Seed with empty config shapes so the strict type is satisfied before
	-- Make_Config replaces them with the real snapshot.
	local self = setmetatable({
		instance = gui,
		Config = {
			AutoReset = true,
			Default_Properties = {},
			Animation_config = {},
			properties = {},
		} :: BloxwindConfig,
		core_config = { low = {}, mid = {}, high = {} } :: CoreConfig,
		_connections = {},
		_triggerConnections = {},
		_destroyed = false,
	}, Bloxwind) :: BloxwindInstance

	gui:SetAttribute("bw_active", false)

	config.Make_Config(self) -- replaces self.Config and self.core_config with real data

	-- Track the active-changed connection for cleanup.
	table.insert(self._connections, self:Bind_Active_Changed())

	-- Auto-cleanup when the GuiObject is destroyed.
	table.insert(self._connections, gui.Destroying:Connect(function()
		OnGuiDeleted(self)
	end))

	return self
end

return Bloxwind