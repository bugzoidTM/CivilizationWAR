--!strict

local MarchConfig = {
	StartingWorkers = 3,
	WorkersPerGatherMarch = 1,
	BaseTravelSeconds = 3,
	SecondsPerTile = 1,
	GatherSeconds = 8,
	ResourceCapacity = {
		food = 180,
		wood = 160,
		stone = 130,
		iron = 90,
	},
}

return MarchConfig
