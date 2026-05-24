-- Run this in Roblox Studio's Command Bar after syncing the Rojo project.
-- It builds the starter map into Workspace while Studio is in edit mode.

local ServerScriptService = game:GetService("ServerScriptService")

local CivilizationWAR = ServerScriptService:WaitForChild("CivilizationWar")
local WorldBuilder = require(CivilizationWAR:WaitForChild("Services"):WaitForChild("WorldBuilder"))

WorldBuilder.Build("starter_valley")
