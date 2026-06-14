-- Bloxwind client handles all gui changes, gui loading and so on

local plr = game:GetService("Players").LocalPlayer
local pg = plr.PlayerGui
local ReplictaedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Bloxwind = require(ReplictaedStorage.Bloxwind.Bloxwind)

local Tag_folder = ReplictaedStorage.Bloxwind.Tag

function New_gui(newGui)
	local gui = Bloxwind.Get_Gui(newGui)
	
	for i,tag:Instance in pairs(Tag_folder:GetChildren()) do

		if CollectionService:HasTag(newGui, tag.Name) then
			gui:Set_Tag_Config(tag)
		end
	end
	
	gui:Set_Attr_Config()
end

local function Get_New_Guis(gui)
	if gui:IsA("GuiObject") then
		New_gui(gui)
	end
end

local function Get_Guis()
	for i,inst in pairs(pg:GetDescendants()) do
		if inst:IsA("GuiObject") then
			New_gui(inst)
		end
	end
end

-- init
Get_Guis()

-- Events

pg.DescendantAdded:Connect(Get_New_Guis)