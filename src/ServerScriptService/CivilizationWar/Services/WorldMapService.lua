--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("CivilizationWar"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WorldConfig = require(Shared:WaitForChild("WorldConfig"))

local WorldMapService = {}

local RESOURCE_COLORS = {
	food = Color3.fromRGB(220, 178, 70),
	wood = Color3.fromRGB(111, 74, 43),
	stone = Color3.fromRGB(165, 170, 174),
	iron = Color3.fromRGB(74, 87, 98),
}

local BIOME_COLOR_OFFSET = {
	plains = Color3.fromRGB(95, 136, 78),
	forest = Color3.fromRGB(42, 102, 62),
	mountain = Color3.fromRGB(112, 117, 121),
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
	instance:SetAttribute("WorldAction", "Marchas ainda bloqueadas ate a proxima fase")

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
	if data.markerShape then
		instance:SetAttribute("WorldMarkerShape", data.markerShape)
	end
	if data.visualPriority then
		instance:SetAttribute("VisualPriority", data.visualPriority)
	end
end

local function createTile(parent: Instance, x: number, y: number): BasePart
	local biome = WorldConfig.GetBiome(x, y)
	local part = Instance.new("Part")
	part.Name = `Tile_{x}_{y}`
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Size = Vector3.new(WorldConfig.TileSize - 0.16, 0.18, WorldConfig.TileSize - 0.16)
	part.Position = WorldConfig.GetTilePosition(x, y)
	part.Color = BIOME_COLOR_OFFSET[biome] or WorldConfig.BiomeColors[biome] or Color3.fromRGB(92, 140, 86)
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	setWorldAttributes(part, {
		id = `tile_{x}_{y}`,
		name = `Terreno {x}, {y}`,
		worldType = "tile",
		biome = biome,
		level = 1,
		x = x,
		y = y,
	})
	part.Parent = parent
	return part
end

local function createMarkerModel(parent: Instance, data: any): Model
	local model = Instance.new("Model")
	model.Name = data.id
	setWorldAttributes(model, data)
	model.Parent = parent
	return model
end

local function createMarkerPart(
	model: Model,
	data: any,
	name: string,
	size: Vector3,
	offset: Vector3,
	color: Color3,
	material: Enum.Material,
	partType: Enum.PartType?,
	className: string?,
	rotation: CFrame?
): BasePart
	local part: BasePart
	if className == "WedgePart" then
		part = Instance.new("WedgePart")
	else
		local block = Instance.new("Part")
		if partType then
			block.Shape = partType
		end
		part = block
	end

	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Size = size
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	local cframe = CFrame.new(WorldConfig.GetTilePosition(data.x, data.y) + offset)
	if rotation then
		cframe *= rotation
	end
	part.CFrame = cframe

	setWorldAttributes(part, data)
	part.Parent = model
	return part
end

local function createCastleMarker(parent: Instance, castle: any): Model
	local data = {
		id = castle.id,
		name = castle.name,
		worldType = "playerCastle",
		x = castle.x,
		y = castle.y,
		level = castle.level,
		markerShape = "castle_keep",
		visualPriority = 100,
	}
	local model = createMarkerModel(parent, data)
	local base = createMarkerPart(
		model,
		data,
		"CastleBase",
		Vector3.new(13, 2.4, 13),
		Vector3.new(0, 1.2, 0),
		Color3.fromRGB(95, 102, 112),
		Enum.Material.Slate,
		nil,
		nil,
		nil
	)
	createMarkerPart(
		model,
		data,
		"CastleKeep",
		Vector3.new(8, 10, 8),
		Vector3.new(0, 7, 0),
		Color3.fromRGB(130, 137, 148),
		Enum.Material.Slate,
		nil,
		nil,
		nil
	)
	createMarkerPart(
		model,
		data,
		"CastleBeacon",
		Vector3.new(3.5, 3.5, 3.5),
		Vector3.new(0, 13.6, 0),
		Color3.fromRGB(240, 199, 91),
		Enum.Material.Neon,
		Enum.PartType.Ball,
		nil,
		nil
	)
	model.PrimaryPart = base
	return model
end

local function createResourceMarker(parent: Instance, resource: any): Model
	local data = {
		id = resource.id,
		name = resource.name,
		worldType = "resource",
		resource = resource.resource,
		x = resource.x,
		y = resource.y,
		level = resource.level,
		amount = resource.amount,
		markerShape = "resource_pillar",
		visualPriority = 40,
	}
	local model = createMarkerModel(parent, data)
	createMarkerPart(
		model,
		data,
		"ResourceBase",
		Vector3.new(5.2, 1.2, 5.2),
		Vector3.new(0, 0.8, 0),
		Color3.fromRGB(49, 55, 57),
		Enum.Material.SmoothPlastic,
		nil,
		nil,
		nil
	)
	local pillar = createMarkerPart(
		model,
		data,
		"ResourcePillar",
		Vector3.new(4.2, 5.2, 4.2),
		Vector3.new(0, 3.6, 0),
		RESOURCE_COLORS[resource.resource] or Color3.fromRGB(200, 200, 200),
		Enum.Material.SmoothPlastic,
		Enum.PartType.Cylinder,
		nil,
		nil
	)
	createMarkerPart(
		model,
		data,
		"ResourceCap",
		Vector3.new(4.8, 4.8, 4.8),
		Vector3.new(0, 7.0, 0),
		RESOURCE_COLORS[resource.resource] or Color3.fromRGB(200, 200, 200),
		Enum.Material.Neon,
		Enum.PartType.Ball,
		nil,
		nil
	)
	model.PrimaryPart = pillar
	return model
end

local function createCampMarker(parent: Instance, camp: any): Model
	local data = {
		id = camp.id,
		name = camp.name,
		worldType = "npcCamp",
		enemyId = camp.enemyId,
		x = camp.x,
		y = camp.y,
		level = camp.level,
		markerShape = "npc_tent",
		visualPriority = 55,
	}
	local model = createMarkerModel(parent, data)
	createMarkerPart(
		model,
		data,
		"CampBase",
		Vector3.new(7, 1.1, 7),
		Vector3.new(0, 0.7, 0),
		Color3.fromRGB(65, 48, 42),
		Enum.Material.Wood,
		nil,
		nil,
		nil
	)
	local tent = createMarkerPart(
		model,
		data,
		"CampTent",
		Vector3.new(7.2, 4.8, 6.8),
		Vector3.new(0, 3.2, 0),
		Color3.fromRGB(164, 75, 56),
		Enum.Material.SmoothPlastic,
		nil,
		"WedgePart",
		CFrame.Angles(0, math.rad(45), 0)
	)
	createMarkerPart(
		model,
		data,
		"CampFlag",
		Vector3.new(1.4, 6, 1.4),
		Vector3.new(3.3, 5.5, -3.3),
		Color3.fromRGB(97, 42, 37),
		Enum.Material.Wood,
		nil,
		nil,
		nil
	)
	model.PrimaryPart = tent
	return model
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
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 520
	billboard.Size = UDim2.fromOffset(172, 30)
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(22, 27, 32)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(245, 240, 228)
	label.TextSize = 13
	label.TextWrapped = true
	label.Text = text
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = billboard
end

local function getRenderBounds(): (number, number, number, number)
	local renderSize = WorldConfig.RenderSize or WorldConfig.GridSize
	local castle = WorldConfig.PlayerCastle
	local minX = math.max(1, castle.x - math.floor(renderSize / 2) + 1)
	local minY = math.max(1, castle.y - math.floor(renderSize / 2) + 1)
	local maxX = math.min(WorldConfig.GridSize, minX + renderSize - 1)
	local maxY = math.min(WorldConfig.GridSize, minY + renderSize - 1)
	minX = math.max(1, maxX - renderSize + 1)
	minY = math.max(1, maxY - renderSize + 1)
	return minX, maxX, minY, maxY
end

function WorldMapService.Build(): Folder
	local root = Workspace:WaitForChild(Config.GameName)
	local worldMap = createFolder(root, "WorldMap")
	local renderSize = WorldConfig.RenderSize or WorldConfig.GridSize
	worldMap:SetAttribute("GridSize", WorldConfig.GridSize)
	worldMap:SetAttribute("RenderSize", renderSize)
	worldMap:SetAttribute("TileSize", WorldConfig.TileSize)

	local tilesFolder = createFolder(worldMap, "Tiles")
	local markersFolder = createFolder(worldMap, "Markers")
	local labelsFolder = createFolder(worldMap, "Labels")

	local minX, maxX, minY, maxY = getRenderBounds()
	worldMap:SetAttribute("RenderMinX", minX)
	worldMap:SetAttribute("RenderMaxX", maxX)
	worldMap:SetAttribute("RenderMinY", minY)
	worldMap:SetAttribute("RenderMaxY", maxY)

	for x = minX, maxX do
		for y = minY, maxY do
			createTile(tilesFolder, x, y)
		end
	end

	local castle = WorldConfig.PlayerCastle
	createCastleMarker(markersFolder, castle)
	createLabel(labelsFolder, "Seu Castelo", WorldConfig.GetTilePosition(castle.x, castle.y) + Vector3.new(0, 17, 0))

	for _, resource in ipairs(WorldConfig.ResourceNodes) do
		createResourceMarker(markersFolder, resource)
	end

	for _, camp in ipairs(WorldConfig.NpcCamps) do
		createCampMarker(markersFolder, camp)
	end

	return worldMap
end

return WorldMapService
