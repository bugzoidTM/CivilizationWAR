--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("CivilizationWar"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DataRegistry = require(Shared:WaitForChild("DataRegistry"))

local WorldBuilder = {}

local function normalizeViewLayer(value: any, fallback: string): string
	if type(value) ~= "string" then
		return fallback
	end

	local lowered = string.lower(value)
	if lowered == "world" or lowered == "mundo" then
		return "World"
	elseif lowered == "kingdom" or lowered == "reino" then
		return "Kingdom"
	elseif lowered == "shared" or lowered == "ambos" then
		return "Shared"
	elseif lowered == "legacyworld" or lowered == "legacy_world" then
		return "LegacyWorld"
	end

	return fallback
end

local function withViewLayer(source: any, fallback: string): any
	local spec = table.clone(source or {})
	spec.viewLayer = normalizeViewLayer(spec.viewLayer or spec.layer, fallback)
	return spec
end

local function toVector3(value: any, fallback: Vector3?): Vector3
	if typeof(value) == "Vector3" then
		return value
	end

	if type(value) == "table" then
		return Vector3.new(value[1] or 0, value[2] or 0, value[3] or 0)
	end

	return fallback or Vector3.zero
end

local function toColor3(value: any, fallback: Color3?): Color3
	if typeof(value) == "Color3" then
		return value
	end

	if type(value) == "table" then
		return Color3.fromRGB(value[1] or 255, value[2] or 255, value[3] or 255)
	end

	return fallback or Color3.fromRGB(255, 255, 255)
end

local function getMaterial(materialName: string?): Enum.Material
	if materialName and Enum.Material[materialName] then
		return Enum.Material[materialName]
	end

	return Enum.Material.SmoothPlastic
end

local function createPart(spec: any, parent: Instance, baseCFrame: CFrame?): BasePart
	local shape = spec.shape or "Block"
	local part: BasePart

	if shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		part = Instance.new("Part")
		if shape == "Cylinder" then
			(part :: Part).Shape = Enum.PartType.Cylinder
		elseif shape == "Ball" then
			(part :: Part).Shape = Enum.PartType.Ball
		end
	end

	local localCFrame = CFrame.new(toVector3(spec.position or spec.offset, Vector3.zero))
	local rotation = spec.rotation
	if type(rotation) == "table" then
		localCFrame *= CFrame.Angles(math.rad(rotation[1] or 0), math.rad(rotation[2] or 0), math.rad(rotation[3] or 0))
	end

	part.Name = spec.name or "Part"
	part.Anchored = true
	part.Size = toVector3(spec.size, Vector3.new(4, 1, 4))
	part.Color = toColor3(spec.color, Color3.fromRGB(160, 160, 160))
	part.Material = getMaterial(spec.material)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = (baseCFrame or CFrame.identity) * localCFrame
	part:SetAttribute("ViewLayer", normalizeViewLayer(spec.viewLayer or spec.layer, "Shared"))
	part.Parent = parent

	return part
end

local function createLabel(text: string, position: Vector3, parent: Instance, viewLayer: string?): ()
	local holder = Instance.new("Part")
	holder.Name = "LabelAnchor"
	holder.Anchored = true
	holder.Transparency = 1
	holder.CanCollide = false
	holder.Size = Vector3.new(1, 1, 1)
	holder.Position = position
	holder:SetAttribute("ViewLayer", normalizeViewLayer(viewLayer, "World"))
	holder.Parent = parent

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WorldLabel"
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 220
	billboard.Size = UDim2.fromOffset(150, 28)
	billboard.StudsOffset = Vector3.new(0, 1.5, 0)
	billboard.Parent = holder

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 0.18
	label.BackgroundColor3 = Color3.fromRGB(28, 31, 36)
	label.TextColor3 = Color3.fromRGB(245, 240, 228)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = false
	label.TextSize = 13
	label.TextWrapped = true
	label.Text = text
	label.Size = UDim2.fromScale(1, 1)
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
end

function WorldBuilder.CreatePrefab(
	prefabId: string,
	parent: Instance,
	position: any,
	rotation: any?,
	modelName: string?,
	viewLayer: string?
): Model
	local prefab = DataRegistry.GetPrefab(prefabId)
	local model = Instance.new("Model")
	model.Name = modelName or prefab.displayName or prefabId
	model:SetAttribute("ViewLayer", normalizeViewLayer(viewLayer, "Shared"))

	local base = CFrame.new(toVector3(position, Vector3.zero))
	if type(rotation) == "table" then
		base *= CFrame.Angles(math.rad(rotation[1] or 0), math.rad(rotation[2] or 0), math.rad(rotation[3] or 0))
	end

	local primaryPart: BasePart? = nil
	for _, piece in ipairs(prefab.pieces or {}) do
		local part = createPart(withViewLayer(piece, normalizeViewLayer(viewLayer, "Shared")), model, base)
		primaryPart = primaryPart or part
	end

	if primaryPart then
		model.PrimaryPart = primaryPart
	end

	model:SetAttribute("PrefabId", prefabId)
	model.Parent = parent

	return model
end

local function createNpc(spec: any, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = spec.displayName or spec.id
	model:SetAttribute("NpcId", spec.id)
	model:SetAttribute("DialogueId", spec.dialogueId)
	model:SetAttribute("ViewLayer", "Kingdom")

	local body = createPart({
		name = "Body",
		shape = "Cylinder",
		size = { 3, 6, 3 },
		position = spec.position,
		color = spec.color,
		material = "SmoothPlastic",
		viewLayer = "Kingdom",
	}, model)

	local head = createPart({
		name = "Head",
		shape = "Ball",
		size = { 3.2, 3.2, 3.2 },
		position = { spec.position[1], spec.position[2] + 4.2, spec.position[3] },
		color = { 230, 205, 175 },
		material = "SmoothPlastic",
		viewLayer = "Kingdom",
	}, model)

	model.PrimaryPart = body

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DialoguePrompt"
	prompt.ActionText = "Conversar"
	prompt.ObjectText = spec.displayName or "NPC"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt:SetAttribute("PromptKind", "Dialogue")
	prompt:SetAttribute("DialogueId", spec.dialogueId)
	prompt.Parent = body

	model.Parent = parent
	createLabel(spec.displayName or spec.id, head.Position + Vector3.new(0, 3, 0), model, "Kingdom")

	return model
end

local function attachAttackPrompt(model: Model, enemyId: string): ()
	local primaryPart = model.PrimaryPart
	if primaryPart == nil then
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "AttackPrompt"
	prompt.ActionText = "Atacar"
	prompt.ObjectText = model.Name
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 20
	prompt:SetAttribute("PromptKind", "Attack")
	prompt:SetAttribute("EnemyId", enemyId)
	prompt.Parent = primaryPart
end

function WorldBuilder.Build(mapId: string?): Folder
	local map = DataRegistry.GetMap(mapId or Config.EntryMapId)
	local existing = Workspace:FindFirstChild(Config.GameName)
	if existing then
		existing:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = Config.GameName
	root:SetAttribute("MapId", map.id)
	root:SetAttribute("MapDisplayName", map.displayName)
	root.Parent = Workspace

	local terrainFolder = Instance.new("Folder")
	terrainFolder.Name = "Terrain"
	terrainFolder:SetAttribute("ViewLayer", "Shared")
	terrainFolder.Parent = root

	local cityFolder = Instance.new("Folder")
	cityFolder.Name = "City"
	cityFolder:SetAttribute("ViewLayer", "Kingdom")
	cityFolder.Parent = root

	local resourcesFolder = Instance.new("Folder")
	resourcesFolder.Name = "ResourceNodes"
	resourcesFolder:SetAttribute("ViewLayer", "LegacyWorld")
	resourcesFolder.Parent = root

	local campsFolder = Instance.new("Folder")
	campsFolder.Name = "NpcCamps"
	campsFolder:SetAttribute("ViewLayer", "LegacyWorld")
	campsFolder.Parent = root

	local npcsFolder = Instance.new("Folder")
	npcsFolder.Name = "NPCs"
	npcsFolder:SetAttribute("ViewLayer", "Kingdom")
	npcsFolder.Parent = root

	local wondersFolder = Instance.new("Folder")
	wondersFolder.Name = "Wonders"
	wondersFolder:SetAttribute("ViewLayer", "LegacyWorld")
	wondersFolder.Parent = root

	local decorationsFolder = Instance.new("Folder")
	decorationsFolder.Name = "Decorations"
	decorationsFolder:SetAttribute("ViewLayer", "Kingdom")
	decorationsFolder.Parent = root

	createPart(withViewLayer(map.baseplate, "Shared"), terrainFolder)

	for _, tile in ipairs(map.terrainTiles or {}) do
		createPart({
			name = tile.name,
			position = tile.position,
			size = tile.size,
			color = tile.color,
			material = tile.material,
			viewLayer = normalizeViewLayer(tile.viewLayer or tile.layer, "Shared"),
		}, terrainFolder)
	end

	for _, slot in ipairs(map.citySlots or {}) do
		local model =
			WorldBuilder.CreatePrefab(slot.prefab, cityFolder, slot.position, slot.rotation, slot.id, "Kingdom")
		model:SetAttribute("CitySlotId", slot.id)
		if slot.buildingId then
			model:SetAttribute("BuildingId", slot.buildingId)
		end
	end

	for _, decoration in ipairs(map.decorations or {}) do
		local model = WorldBuilder.CreatePrefab(
			decoration.prefab,
			decorationsFolder,
			decoration.position,
			decoration.rotation,
			decoration.id,
			"Kingdom"
		)
		model:SetAttribute("DecorationId", decoration.id)
	end

	for _, node in ipairs(map.resourceNodes or {}) do
		local model =
			WorldBuilder.CreatePrefab(node.prefab, resourcesFolder, node.position, nil, node.id, "LegacyWorld")
		model:SetAttribute("Resource", node.resource)
		model:SetAttribute("ResourceAmount", node.amount)
		model:SetAttribute("NodeLevel", node.level)
	end

	for _, camp in ipairs(map.npcCamps or {}) do
		local model = WorldBuilder.CreatePrefab(camp.prefab, campsFolder, camp.position, nil, camp.id, "LegacyWorld")
		model:SetAttribute("EnemyId", camp.enemyId)
		attachAttackPrompt(model, camp.enemyId)
	end

	for _, npc in ipairs(map.npcs or {}) do
		createNpc(npc, npcsFolder)
	end

	for _, wonder in ipairs(map.wonders or {}) do
		local model =
			WorldBuilder.CreatePrefab(wonder.prefab, wondersFolder, wonder.position, nil, wonder.id, "LegacyWorld")
		model:SetAttribute("EnemyId", wonder.enemyId)
		model:SetAttribute("CaptureRadius", wonder.captureRadius)
		attachAttackPrompt(model, wonder.enemyId)
	end

	for _, label in ipairs(map.labels or {}) do
		createLabel(
			label.text,
			toVector3(label.position, Vector3.zero),
			root,
			normalizeViewLayer(label.viewLayer or label.layer, "World")
		)
	end

	if map.spawn then
		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = "PlayerSpawn"
		spawnLocation.Anchored = true
		spawnLocation.Size = Vector3.new(10, 1, 10)
		spawnLocation.Position = toVector3(map.spawn, Vector3.new(0, 8, 0))
		spawnLocation.Neutral = true
		spawnLocation.Transparency = 1
		spawnLocation.CanCollide = false
		spawnLocation:SetAttribute("ViewLayer", "Kingdom")
		spawnLocation.Parent = root
	end

	return root
end

return WorldBuilder
