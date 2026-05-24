--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("CivilizationWar"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WorldConfig = require(Shared:WaitForChild("WorldConfig"))

local WorldMapService = {}

local RESOURCE_COLORS = {
	food = Color3.fromRGB(219, 177, 74),
	wood = Color3.fromRGB(118, 80, 45),
	stone = Color3.fromRGB(156, 163, 168),
	iron = Color3.fromRGB(83, 92, 101),
}

local function createFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("ViewLayer", "World")
	folder.Parent = parent
	return folder
end

local function setWorldAttributes(instance: Instance, data: any): ()
	instance:SetAttribute("ViewLayer", "World")
	instance:SetAttribute("WorldSelectable", true)
	instance:SetAttribute("WorldId", data.id)
	instance:SetAttribute("WorldName", data.name)
	instance:SetAttribute("WorldType", data.worldType)
	instance:SetAttribute("WorldLevel", data.level or 1)
	instance:SetAttribute("WorldX", data.x)
	instance:SetAttribute("WorldY", data.y)
	instance:SetAttribute("WorldAction", "Futuro: marchas ainda bloqueadas")

	if data.resource then
		instance:SetAttribute("Resource", data.resource)
	end
	if data.enemyId then
		instance:SetAttribute("EnemyId", data.enemyId)
	end
	if data.biome then
		instance:SetAttribute("Biome", data.biome)
	end
	if data.amount then
		instance:SetAttribute("ResourceAmount", data.amount)
	end
end

local function createTile(parent: Instance, x: number, y: number): BasePart
	local biome = WorldConfig.GetBiome(x, y)
	local part = Instance.new("Part")
	part.Name = `Tile_{x}_{y}`
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(WorldConfig.TileSize - 0.08, 0.2, WorldConfig.TileSize - 0.08)
	part.Position = WorldConfig.GetTilePosition(x, y)
	part.Color = WorldConfig.BiomeColors[biome] or Color3.fromRGB(92, 140, 86)
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	setWorldAttributes(part, {
		id = `tile_{x}_{y}`,
		name = `Celula {x}, {y}`,
		worldType = "tile",
		biome = biome,
		level = 1,
		x = x,
		y = y,
	})
	part.Parent = parent
	return part
end

local function createMarker(parent: Instance, data: any): BasePart
	local part = Instance.new("Part")
	part.Name = data.id
	part.Anchored = true
	part.CanCollide = false
	part.Size = data.size
	part.Position = WorldConfig.GetTilePosition(data.x, data.y) + Vector3.new(0, data.heightOffset or 1.2, 0)
	part.Color = data.color
	part.Material = data.material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	setWorldAttributes(part, data)
	part.Parent = parent
	return part
end

local function createLabel(parent: Instance, text: string, position: Vector3): ()
	local anchor = Instance.new("Part")
	anchor.Name = "WorldMapLabelAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = position
	anchor:SetAttribute("ViewLayer", "World")
	anchor.Parent = parent

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WorldMapLabel"
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 360
	billboard.Size = UDim2.fromOffset(150, 28)
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(22, 27, 32)
	label.BackgroundTransparency = 0.2
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(245, 240, 228)
	label.TextSize = 12
	label.TextWrapped = true
	label.Text = text
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = billboard
end

function WorldMapService.Build(): Folder
	local root = Workspace:WaitForChild(Config.GameName)
	local worldMap = createFolder(root, "WorldMap")
	worldMap:SetAttribute("GridSize", WorldConfig.GridSize)
	worldMap:SetAttribute("TileSize", WorldConfig.TileSize)

	local tilesFolder = createFolder(worldMap, "Tiles")
	local markersFolder = createFolder(worldMap, "Markers")
	local labelsFolder = createFolder(worldMap, "Labels")

	for x = 1, WorldConfig.GridSize do
		for y = 1, WorldConfig.GridSize do
			createTile(tilesFolder, x, y)
		end
	end

	local castle = WorldConfig.PlayerCastle
	createMarker(markersFolder, {
		id = castle.id,
		name = castle.name,
		worldType = "playerCastle",
		x = castle.x,
		y = castle.y,
		level = castle.level,
		size = Vector3.new(7, 6, 7),
		heightOffset = 3,
		color = Color3.fromRGB(129, 132, 141),
		material = Enum.Material.Slate,
	})
	createLabel(labelsFolder, "Seu Castelo", WorldConfig.GetTilePosition(castle.x, castle.y) + Vector3.new(0, 8, 0))

	for _, resource in ipairs(WorldConfig.ResourceNodes) do
		createMarker(markersFolder, {
			id = resource.id,
			name = resource.name,
			worldType = "resource",
			resource = resource.resource,
			x = resource.x,
			y = resource.y,
			level = resource.level,
			amount = resource.amount,
			size = Vector3.new(4, 2.6, 4),
			heightOffset = 1.5,
			color = RESOURCE_COLORS[resource.resource] or Color3.fromRGB(200, 200, 200),
			material = Enum.Material.SmoothPlastic,
		})
	end

	for _, camp in ipairs(WorldConfig.NpcCamps) do
		createMarker(markersFolder, {
			id = camp.id,
			name = camp.name,
			worldType = "npcCamp",
			enemyId = camp.enemyId,
			x = camp.x,
			y = camp.y,
			level = camp.level,
			size = Vector3.new(5, 3, 5),
			heightOffset = 1.8,
			color = Color3.fromRGB(156, 72, 56),
			material = Enum.Material.Wood,
		})
	end

	return worldMap
end

return WorldMapService
