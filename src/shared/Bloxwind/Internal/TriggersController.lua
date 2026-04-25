local Trigger = {}
Trigger.__index = Trigger

local triggers = {}

function Trigger.register(name, connect)
	local self = setmetatable({ connect = connect }, Trigger)
	triggers[name] = self
end

function Trigger.GetTriggers()
	return triggers
end

-- Auto-load every module in the Triggers folder
local folder
for _, child in ipairs(script.Parent:GetChildren()) do
	if child:IsA("Folder") and child.Name == "Triggers" then
		folder = child
		break
	end
end

if folder then
	for _, module in ipairs(folder:GetChildren()) do
		if module:IsA("ModuleScript") then
			local def = require(module)
			Trigger.register(def.name, def.connect)
		end
	end
end

return Trigger