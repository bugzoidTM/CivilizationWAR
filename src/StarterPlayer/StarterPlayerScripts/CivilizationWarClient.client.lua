--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local root = ReplicatedStorage:WaitForChild("CivilizationWar")
local remotes = root:WaitForChild("Remotes")

local StateSnapshot = remotes:WaitForChild("StateSnapshot") :: RemoteEvent
local DialogueEvent = remotes:WaitForChild("Dialogue") :: RemoteEvent
local CombatReportEvent = remotes:WaitForChild("CombatReport") :: RemoteEvent

local GetState = remotes:WaitForChild("GetState") :: RemoteFunction
local CollectProduction = remotes:WaitForChild("CollectProduction") :: RemoteFunction
local UpgradeBuilding = remotes:WaitForChild("UpgradeBuilding") :: RemoteFunction
local TrainTroops = remotes:WaitForChild("TrainTroops") :: RemoteFunction
local Research = remotes:WaitForChild("Research") :: RemoteFunction
local AttackNpc = remotes:WaitForChild("AttackNpc") :: RemoteFunction
local ExploreRegion = remotes:WaitForChild("ExploreRegion") :: RemoteFunction

type ViewMode = "Kingdom" | "World"

local resourceOrder = { "food", "wood", "stone", "iron", "silver", "gold" }
local resourceNames = {
	food = "Comida",
	wood = "Madeira",
	stone = "Pedra",
	iron = "Ferro",
	silver = "Prata",
	gold = "Ouro",
}

local viewMode: ViewMode = "Kingdom"
local latestState: any = nil
local activeCameraTween: Tween? = nil
local visibilityCache: { [Instance]: { transparency: number?, canCollide: boolean?, enabled: boolean? } } = {}

local gui = Instance.new("ScreenGui")
gui.Name = "CivilizationWARHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function addCorner(instance: GuiObject, radius: number): ()
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function addStroke(instance: GuiObject, transparency: number): ()
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 241, 201)
	stroke.Thickness = 1
	stroke.Transparency = transparency
	stroke.Parent = instance
end

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.BackgroundColor3 = Color3.fromRGB(20, 24, 29)
topBar.BackgroundTransparency = 0.08
topBar.BorderSizePixel = 0
topBar.Position = UDim2.new(0.5, 0, 0, 12)
topBar.Size = UDim2.new(1, -340, 0, 42)
topBar.Parent = gui
addCorner(topBar, 8)
addStroke(topBar, 0.82)

local topBarLimit = Instance.new("UISizeConstraint")
topBarLimit.MaxSize = Vector2.new(760, 42)
topBarLimit.MinSize = Vector2.new(500, 42)
topBarLimit.Parent = topBar

local resourceLayout = Instance.new("UIListLayout")
resourceLayout.FillDirection = Enum.FillDirection.Horizontal
resourceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
resourceLayout.VerticalAlignment = Enum.VerticalAlignment.Center
resourceLayout.Padding = UDim.new(0, 6)
resourceLayout.Parent = topBar

local resourcePadding = Instance.new("UIPadding")
resourcePadding.PaddingLeft = UDim.new(0, 8)
resourcePadding.PaddingRight = UDim.new(0, 8)
resourcePadding.Parent = topBar

local resourceLabels: { [string]: TextLabel } = {}

local function createResourceLabel(resource: string): ()
	local label = Instance.new("TextLabel")
	label.Name = resource
	label.BackgroundColor3 = Color3.fromRGB(37, 43, 49)
	label.BackgroundTransparency = 0.05
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(246, 242, 232)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Size = UDim2.fromOffset(116, 28)
	label.Parent = topBar
	addCorner(label, 6)
	resourceLabels[resource] = label
end

for _, resource in ipairs(resourceOrder) do
	createResourceLabel(resource)
end

local missionPanel = Instance.new("Frame")
missionPanel.Name = "MissionPanel"
missionPanel.BackgroundColor3 = Color3.fromRGB(22, 27, 32)
missionPanel.BackgroundTransparency = 0.1
missionPanel.BorderSizePixel = 0
missionPanel.Position = UDim2.fromOffset(14, 14)
missionPanel.Size = UDim2.fromOffset(286, 74)
missionPanel.Parent = gui
addCorner(missionPanel, 8)
addStroke(missionPanel, 0.86)

local missionTitle = Instance.new("TextLabel")
missionTitle.Name = "MissionTitle"
missionTitle.BackgroundTransparency = 1
missionTitle.Font = Enum.Font.GothamBold
missionTitle.TextColor3 = Color3.fromRGB(247, 235, 206)
missionTitle.TextSize = 16
missionTitle.TextXAlignment = Enum.TextXAlignment.Left
missionTitle.Text = "CivilizationWAR"
missionTitle.Position = UDim2.fromOffset(12, 8)
missionTitle.Size = UDim2.new(1, -24, 0, 20)
missionTitle.Parent = missionPanel

local missionText = Instance.new("TextLabel")
missionText.Name = "MissionText"
missionText.BackgroundTransparency = 1
missionText.Font = Enum.Font.Gotham
missionText.TextColor3 = Color3.fromRGB(215, 221, 225)
missionText.TextSize = 12
missionText.TextWrapped = true
missionText.TextXAlignment = Enum.TextXAlignment.Left
missionText.TextYAlignment = Enum.TextYAlignment.Top
missionText.Position = UDim2.fromOffset(12, 32)
missionText.Size = UDim2.new(1, -24, 0, 34)
missionText.Parent = missionPanel

local modeButton = Instance.new("TextButton")
modeButton.Name = "ModeButton"
modeButton.AnchorPoint = Vector2.new(0.5, 1)
modeButton.BackgroundColor3 = Color3.fromRGB(72, 97, 116)
modeButton.BorderSizePixel = 0
modeButton.Font = Enum.Font.GothamBold
modeButton.TextColor3 = Color3.fromRGB(252, 248, 235)
modeButton.TextSize = 14
modeButton.Position = UDim2.new(0.5, 0, 1, -146)
modeButton.Size = UDim2.fromOffset(154, 38)
modeButton.Parent = gui
addCorner(modeButton, 8)
addStroke(modeButton, 0.82)

local summaryPanel = Instance.new("Frame")
summaryPanel.Name = "SummaryPanel"
summaryPanel.AnchorPoint = Vector2.new(0, 1)
summaryPanel.BackgroundColor3 = Color3.fromRGB(21, 25, 30)
summaryPanel.BackgroundTransparency = 0.13
summaryPanel.BorderSizePixel = 0
summaryPanel.Position = UDim2.new(0, 14, 1, -146)
summaryPanel.Size = UDim2.fromOffset(300, 78)
summaryPanel.Parent = gui
addCorner(summaryPanel, 8)
addStroke(summaryPanel, 0.88)

local summaryText = Instance.new("TextLabel")
summaryText.BackgroundTransparency = 1
summaryText.Font = Enum.Font.GothamMedium
summaryText.TextColor3 = Color3.fromRGB(230, 234, 236)
summaryText.TextSize = 12
summaryText.TextXAlignment = Enum.TextXAlignment.Left
summaryText.TextYAlignment = Enum.TextYAlignment.Top
summaryText.Position = UDim2.fromOffset(12, 10)
summaryText.Size = UDim2.new(1, -24, 1, -18)
summaryText.Parent = summaryPanel

local constructionPanel = Instance.new("Frame")
constructionPanel.Name = "ConstructionPanel"
constructionPanel.AnchorPoint = Vector2.new(1, 1)
constructionPanel.BackgroundColor3 = Color3.fromRGB(21, 25, 30)
constructionPanel.BackgroundTransparency = 0.12
constructionPanel.BorderSizePixel = 0
constructionPanel.Position = UDim2.new(1, -14, 1, -146)
constructionPanel.Size = UDim2.fromOffset(350, 112)
constructionPanel.Parent = gui
addCorner(constructionPanel, 8)
addStroke(constructionPanel, 0.88)

local constructionTitle = Instance.new("TextLabel")
constructionTitle.BackgroundTransparency = 1
constructionTitle.Font = Enum.Font.GothamBold
constructionTitle.TextColor3 = Color3.fromRGB(247, 235, 206)
constructionTitle.TextSize = 14
constructionTitle.TextXAlignment = Enum.TextXAlignment.Left
constructionTitle.Position = UDim2.fromOffset(12, 8)
constructionTitle.Size = UDim2.new(1, -24, 0, 18)
constructionTitle.Text = "Construcao"
constructionTitle.Parent = constructionPanel

local constructionText = Instance.new("TextLabel")
constructionText.BackgroundTransparency = 1
constructionText.Font = Enum.Font.Gotham
constructionText.TextColor3 = Color3.fromRGB(222, 228, 231)
constructionText.TextSize = 12
constructionText.TextWrapped = true
constructionText.TextXAlignment = Enum.TextXAlignment.Left
constructionText.TextYAlignment = Enum.TextYAlignment.Top
constructionText.Position = UDim2.fromOffset(12, 30)
constructionText.Size = UDim2.new(1, -24, 1, -38)
constructionText.Parent = constructionPanel

local actionBar = Instance.new("Frame")
actionBar.Name = "ActionBar"
actionBar.AnchorPoint = Vector2.new(0.5, 1)
actionBar.BackgroundColor3 = Color3.fromRGB(21, 25, 30)
actionBar.BackgroundTransparency = 0.09
actionBar.BorderSizePixel = 0
actionBar.Position = UDim2.new(0.5, 0, 1, -14)
actionBar.Size = UDim2.new(1, -420, 0, 118)
actionBar.Parent = gui
addCorner(actionBar, 8)
addStroke(actionBar, 0.88)

local actionLimit = Instance.new("UISizeConstraint")
actionLimit.MaxSize = Vector2.new(800, 118)
actionLimit.MinSize = Vector2.new(540, 118)
actionLimit.Parent = actionBar

local actionGrid = Instance.new("UIGridLayout")
actionGrid.CellPadding = UDim2.fromOffset(8, 8)
actionGrid.CellSize = UDim2.fromOffset(136, 46)
actionGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionGrid.VerticalAlignment = Enum.VerticalAlignment.Center
actionGrid.SortOrder = Enum.SortOrder.LayoutOrder
actionGrid.Parent = actionBar

local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.BackgroundColor3 = Color3.fromRGB(31, 36, 42)
toast.BackgroundTransparency = 0.04
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamMedium
toast.TextColor3 = Color3.fromRGB(250, 229, 161)
toast.TextSize = 13
toast.TextWrapped = true
toast.Visible = false
toast.Position = UDim2.new(0.5, 0, 0, 64)
toast.Size = UDim2.fromOffset(420, 34)
toast.Parent = gui
addCorner(toast, 8)

local popup = Instance.new("Frame")
popup.Name = "Popup"
popup.AnchorPoint = Vector2.new(1, 0)
popup.BackgroundColor3 = Color3.fromRGB(24, 29, 35)
popup.BackgroundTransparency = 0.03
popup.BorderSizePixel = 0
popup.Position = UDim2.new(1, -14, 0, 62)
popup.Size = UDim2.fromOffset(330, 132)
popup.Visible = false
popup.Parent = gui
addCorner(popup, 8)
addStroke(popup, 0.84)

local popupClose = Instance.new("TextButton")
popupClose.Name = "Close"
popupClose.BackgroundTransparency = 1
popupClose.Font = Enum.Font.GothamBold
popupClose.Text = "x"
popupClose.TextColor3 = Color3.fromRGB(223, 229, 232)
popupClose.TextSize = 18
popupClose.Position = UDim2.new(1, -36, 0, 3)
popupClose.Size = UDim2.fromOffset(28, 28)
popupClose.Parent = popup

local popupText = Instance.new("TextLabel")
popupText.BackgroundTransparency = 1
popupText.Font = Enum.Font.Gotham
popupText.TextColor3 = Color3.fromRGB(244, 239, 226)
popupText.TextSize = 13
popupText.TextWrapped = true
popupText.TextXAlignment = Enum.TextXAlignment.Left
popupText.TextYAlignment = Enum.TextYAlignment.Top
popupText.Position = UDim2.fromOffset(14, 34)
popupText.Size = UDim2.new(1, -28, 1, -44)
popupText.Parent = popup

local worldInfoPanel = Instance.new("Frame")
worldInfoPanel.Name = "WorldInfoPanel"
worldInfoPanel.AnchorPoint = Vector2.new(1, 1)
worldInfoPanel.BackgroundColor3 = Color3.fromRGB(21, 25, 30)
worldInfoPanel.BackgroundTransparency = 0.1
worldInfoPanel.BorderSizePixel = 0
worldInfoPanel.Position = UDim2.new(1, -14, 1, -14)
worldInfoPanel.Size = UDim2.fromOffset(340, 162)
worldInfoPanel.Visible = false
worldInfoPanel.Parent = gui
addCorner(worldInfoPanel, 8)
addStroke(worldInfoPanel, 0.86)

local worldInfoTitle = Instance.new("TextLabel")
worldInfoTitle.BackgroundTransparency = 1
worldInfoTitle.Font = Enum.Font.GothamBold
worldInfoTitle.TextColor3 = Color3.fromRGB(247, 235, 206)
worldInfoTitle.TextSize = 15
worldInfoTitle.TextXAlignment = Enum.TextXAlignment.Left
worldInfoTitle.Position = UDim2.fromOffset(12, 10)
worldInfoTitle.Size = UDim2.new(1, -24, 0, 20)
worldInfoTitle.Text = "Mapa Mundial"
worldInfoTitle.Parent = worldInfoPanel

local worldInfoText = Instance.new("TextLabel")
worldInfoText.BackgroundTransparency = 1
worldInfoText.Font = Enum.Font.Gotham
worldInfoText.TextColor3 = Color3.fromRGB(222, 228, 231)
worldInfoText.TextSize = 12
worldInfoText.TextWrapped = true
worldInfoText.TextXAlignment = Enum.TextXAlignment.Left
worldInfoText.TextYAlignment = Enum.TextYAlignment.Top
worldInfoText.Position = UDim2.fromOffset(12, 36)
worldInfoText.Size = UDim2.new(1, -24, 1, -48)
worldInfoText.Text = "Clique em um tile, recurso, acampamento ou castelo."
worldInfoText.Parent = worldInfoPanel

local selectionBox = Instance.new("SelectionBox")
selectionBox.Name = "WorldSelectionBox"
selectionBox.Color3 = Color3.fromRGB(255, 230, 130)
selectionBox.LineThickness = 0.045
selectionBox.SurfaceTransparency = 0.82
selectionBox.Visible = false
selectionBox.Parent = gui

local actionButtons: { [TextButton]: ViewMode | "Both" } = {}
local buildButtons: { [string]: TextButton } = {}
local selectedBuildingId = "castle"
local latestSnapshotReceivedAt = os.clock()
local latestServerTime = os.time()
local nextConstructionPanelRefresh = 0
local shownOfflineKey = ""

local function formatAmount(value: number?): string
	local numberValue = value or 0
	if numberValue >= 1000000 then
		return string.format("%.1fM", numberValue / 1000000)
	elseif numberValue >= 1000 then
		return string.format("%.1fk", numberValue / 1000)
	end

	return tostring(math.floor(numberValue))
end

local function formatDuration(seconds: number?): string
	local value = math.max(0, math.floor(seconds or 0))
	if value >= 3600 then
		return string.format("%dh %dm", math.floor(value / 3600), math.floor((value % 3600) / 60))
	elseif value >= 60 then
		return string.format("%dm %ds", math.floor(value / 60), value % 60)
	end

	return `{value}s`
end

local function formatCost(cost: any): string
	local parts = {}
	for _, resource in ipairs(resourceOrder) do
		local amount = cost and cost[resource]
		if amount and amount > 0 then
			table.insert(parts, `{resourceNames[resource]} {formatAmount(amount)}`)
		end
	end

	if #parts == 0 then
		return "Sem custo"
	end

	return table.concat(parts, ", ")
end

local function getAdjustedServerTime(): number
	return latestServerTime + math.floor(os.clock() - latestSnapshotReceivedAt)
end

local function setToast(text: string): ()
	toast.Text = text
	toast.Visible = text ~= ""
	if text ~= "" then
		task.delay(3.6, function()
			if toast.Text == text then
				toast.Visible = false
			end
		end)
	end
end

local function showPopup(text: string): ()
	popupText.Text = text
	popup.Visible = true
	task.delay(7, function()
		if popupText.Text == text then
			popup.Visible = false
		end
	end)
end

local function getWorldRoot(): Instance?
	return Workspace:FindFirstChild("CivilizationWAR")
end

local function getInheritedViewLayer(instance: Instance): string
	local current: Instance? = instance
	while current ~= nil do
		local layer = current:GetAttribute("ViewLayer")
		if type(layer) == "string" then
			return layer
		end
		current = current.Parent
	end

	return "Shared"
end

local function setLayerVisibility(instance: Instance, shouldShow: boolean): ()
	if instance:IsA("BasePart") then
		local cached = visibilityCache[instance]
		if cached == nil then
			cached = {
				transparency = instance.Transparency,
				canCollide = instance.CanCollide,
			}
			visibilityCache[instance] = cached
		end

		instance.Transparency = if shouldShow then cached.transparency or 0 else 1
		instance.CanCollide = shouldShow and (cached.canCollide == true)
	elseif instance:IsA("BillboardGui") or instance:IsA("ProximityPrompt") then
		local cached = visibilityCache[instance]
		if cached == nil then
			cached = {
				enabled = instance.Enabled,
			}
			visibilityCache[instance] = cached
		end

		instance.Enabled = shouldShow and (cached.enabled ~= false)
	end
end

local function applyViewLayers(): ()
	local worldRoot = getWorldRoot()
	if worldRoot == nil then
		return
	end

	for _, instance in ipairs(worldRoot:GetDescendants()) do
		local layer = getInheritedViewLayer(instance)
		local shouldShow = layer == "Shared" or layer == viewMode
		setLayerVisibility(instance, shouldShow)
	end
end

local function setCharacterVisible(isVisible: boolean): ()
	local character = player.Character
	if character == nil then
		return
	end

	for _, instance in ipairs(character:GetDescendants()) do
		if instance:IsA("BasePart") then
			instance.LocalTransparencyModifier = if isVisible then 0 else 1
		elseif instance:IsA("Decal") then
			instance.Transparency = if isVisible then 0 else 1
		end
	end
end

local function setCameraForView(): ()
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end

	local cameraPosition: Vector3
	local focus: Vector3
	local fieldOfView: number

	if viewMode == "Kingdom" then
		cameraPosition = Vector3.new(112, 108, 118)
		focus = Vector3.new(0, 5, 0)
		fieldOfView = 35
	else
		cameraPosition = Vector3.new(0, 285, 250)
		focus = Vector3.new(0, 0, 0)
		fieldOfView = 30
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = fieldOfView

	if activeCameraTween then
		activeCameraTween:Cancel()
	end

	activeCameraTween = TweenService:Create(
		camera,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = CFrame.lookAt(cameraPosition, focus) }
	)
	activeCameraTween:Play()
end

local function refreshActionVisibility(): ()
	for button, view in pairs(actionButtons) do
		button.Visible = view == "Both" or view == viewMode
	end
	modeButton.Text = if viewMode == "Kingdom" then "Abrir Mundo" else "Voltar ao Reino"
	actionBar.Visible = viewMode == "Kingdom"
	summaryPanel.Visible = viewMode == "Kingdom"
	constructionPanel.Visible = viewMode == "Kingdom"
	worldInfoPanel.Visible = viewMode == "World"
end

local function setViewMode(nextView: ViewMode): ()
	viewMode = nextView
	applyViewLayers()
	setCharacterVisible(viewMode == "Kingdom")
	setCameraForView()
	refreshActionVisibility()
	if viewMode == "Kingdom" then
		selectionBox.Visible = false
	else
		worldInfoTitle.Text = "Mapa Mundial"
		worldInfoText.Text =
			"Clique em um tile, recurso, acampamento ou castelo.\nAções de marcha ficam bloqueadas até a próxima fase."
	end
end

local function updateBuildButtons(state: any): ()
	local actions = state.buildingActions or {}
	for buildingId, button in pairs(buildButtons) do
		local action = actions[buildingId]
		if action then
			local levelText = `Nv.{action.targetLevel or ((action.currentLevel or 0) + 1)}`
			if action.status == "queued" then
				button.Text = `{action.displayName}\nEm fila`
				button.BackgroundColor3 = Color3.fromRGB(102, 92, 62)
			elseif
				action.status == "blocked"
				or action.status == "missing_resources"
				or action.status == "queue_full"
			then
				button.Text = `{action.displayName}\n{action.statusText or "Bloqueado"}`
				button.BackgroundColor3 = Color3.fromRGB(82, 73, 72)
			elseif action.status == "max" then
				button.Text = `{action.displayName}\nMax`
				button.BackgroundColor3 = Color3.fromRGB(54, 71, 73)
			else
				button.Text = `{action.displayName}\n{levelText} {action.durationText or ""}`
				button.BackgroundColor3 = Color3.fromRGB(65, 86, 104)
			end
		end
	end
end

local function updateConstructionPanel(): ()
	if latestState == nil then
		constructionText.Text = "Carregando dados do reino..."
		return
	end

	local now = getAdjustedServerTime()
	local queue = latestState.constructionQueue or {}
	local selected = latestState.buildingActions and latestState.buildingActions[selectedBuildingId]

	local lines = {}
	if queue[1] then
		local active = queue[1]
		local remaining = math.max(0, (active.finishAt or now) - now)
		table.insert(lines, `Em obra: {active.displayName or active.buildingId} Nv.{active.targetLevel}`)
		table.insert(
			lines,
			`Termina em {formatDuration(remaining)}   Fila {#queue}/{latestState.maxConstructionQueue or 2}`
		)
	else
		table.insert(lines, "Fila livre.")
	end

	if selected then
		table.insert(lines, `Selecionado: {selected.displayName} Nv.{selected.targetLevel or "-"}`)
		table.insert(lines, `Custo: {formatCost(selected.cost)}   Tempo: {selected.durationText or "-"}`)
		table.insert(lines, selected.requirementText or selected.statusText or "Requisitos OK")
	end

	constructionText.Text = table.concat(lines, "\n")
end

local function findWorldSelectable(target: Instance?): BasePart?
	local current = target
	while current do
		if current:IsA("BasePart") and current:GetAttribute("WorldSelectable") == true then
			return current
		end
		current = current.Parent
	end

	return nil
end

local function getWorldTypeLabel(worldType: string?): string
	if worldType == "playerCastle" then
		return "Castelo"
	elseif worldType == "resource" then
		return "Recurso"
	elseif worldType == "npcCamp" then
		return "Acampamento NPC"
	elseif worldType == "tile" then
		return "Terreno"
	end

	return "Ponto do mapa"
end

local function getBiomeLabel(biome: string?): string
	if biome == "plains" then
		return "Planicie"
	elseif biome == "forest" then
		return "Floresta"
	elseif biome == "mountain" then
		return "Montanha"
	end

	return "Indefinido"
end

local function updateWorldInfo(selection: BasePart?): ()
	if selection == nil then
		selectionBox.Visible = false
		worldInfoTitle.Text = "Mapa Mundial"
		worldInfoText.Text =
			"Clique em um tile, recurso, acampamento ou castelo.\nAções de marcha ficam bloqueadas até a próxima fase."
		return
	end

	selectionBox.Adornee = selection
	selectionBox.Visible = true

	local worldName = selection:GetAttribute("WorldName") or selection.Name
	local worldType = selection:GetAttribute("WorldType")
	local worldLevel = selection:GetAttribute("WorldLevel") or 1
	local x = selection:GetAttribute("WorldX") or 0
	local y = selection:GetAttribute("WorldY") or 0
	local biome = selection:GetAttribute("Biome")
	local resource = selection:GetAttribute("Resource")
	local amount = selection:GetAttribute("ResourceAmount")
	local enemyId = selection:GetAttribute("EnemyId")
	local action = selection:GetAttribute("WorldAction") or "Futuro: marchas ainda bloqueadas"

	worldInfoTitle.Text = tostring(worldName)

	local lines = {
		`Tipo: {getWorldTypeLabel(worldType)}`,
		`Nivel: {worldLevel}   Coordenada: {x}, {y}`,
	}

	if biome then
		table.insert(lines, `Bioma: {getBiomeLabel(biome)}`)
	end
	if resource then
		table.insert(lines, `Recurso: {resourceNames[resource] or resource}   Quantidade: {formatAmount(amount)}`)
	end
	if enemyId then
		table.insert(lines, `Inimigo: {enemyId}`)
	end

	table.insert(lines, tostring(action))
	worldInfoText.Text = table.concat(lines, "\n")
end

local function updateHud(state: any): ()
	latestState = state
	latestServerTime = state.serverTime or os.time()
	latestSnapshotReceivedAt = os.clock()
	for _, resource in ipairs(resourceOrder) do
		local label = resourceLabels[resource]
		label.Text = `{resourceNames[resource]} {formatAmount(state.resources and state.resources[resource])}`
	end

	local activeMission = state.activeMission
	if activeMission then
		missionTitle.Text = activeMission.title or "Missao atual"
		missionText.Text = "Complete o objetivo destacado para avancar o capitulo."
	else
		missionTitle.Text = "Capitulo concluido"
		missionText.Text = "O reino inicial esta pronto para o mapa mundial."
	end

	local castleLevel = state.buildings and state.buildings.castle or 0
	local farmLevel = state.buildings and state.buildings.farm or 0
	local sawmillLevel = state.buildings and state.buildings.lumber_mill or 0
	local barracksLevel = state.buildings and state.buildings.barracks or 0
	local swordsmen = state.troops and state.troops.swordsman or 0
	local archers = state.troops and state.troops.archer or 0
	local production = state.productionPerMinute or {}

	summaryText.Text = `Castelo Nv.{castleLevel}   Fazenda Nv.{farmLevel}   Serraria Nv.{sawmillLevel}`
		.. `\nQuarteis Nv.{barracksLevel}   Espadachins {swordsmen}   Arqueiros {archers}`
		.. `\nProd/min: comida {formatAmount(production.food)} madeira {formatAmount(production.wood)}`

	local offline = state.lastOfflineGains
	if offline and offline.seconds and offline.seconds > 0 then
		local key = `{offline.seconds}:{formatCost(offline.resources)}`
		if key ~= shownOfflineKey then
			shownOfflineKey = key
			setToast(`Producao offline: {formatCost(offline.resources)} em {formatDuration(offline.seconds)}.`)
		end
	end

	updateBuildButtons(state)
	updateConstructionPanel()
end

local function describeGains(gains: any): string
	local parts = {}
	for _, resource in ipairs(resourceOrder) do
		local amount = gains and gains[resource]
		if amount and amount > 0 then
			table.insert(parts, `{resourceNames[resource]} +{formatAmount(amount)}`)
		end
	end

	if #parts == 0 then
		return "Ordem executada."
	end

	return table.concat(parts, "   ")
end

local function handleResult(result: any): ()
	if result == nil then
		setToast("Sem resposta do servidor.")
		return
	end

	if not result.ok then
		if result.state then
			updateHud(result.state)
		end
		setToast(result.error or "Acao recusada.")
		return
	end

	if result.state then
		updateHud(result.state)
	end

	if result.gains then
		setToast(describeGains(result.gains))
	elseif result.construction then
		setToast(
			`{result.construction.displayName or result.construction.buildingId} Nv.{result.construction.targetLevel} em construcao.`
		)
	elseif result.mission and result.mission.completed then
		setToast("Missao concluida. Recompensas recebidas.")
	else
		setToast("Ordem executada.")
	end
end

local function createActionButton(text: string, order: number, view: ViewMode | "Both", callback: () -> ()): TextButton
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.fromRGB(65, 86, 104)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(250, 246, 235)
	button.TextSize = 12
	button.TextWrapped = true
	button.TextYAlignment = Enum.TextYAlignment.Center
	button.Text = text
	button.LayoutOrder = order
	button.Parent = actionBar
	addCorner(button, 6)

	button.Activated:Connect(callback)
	actionButtons[button] = view
	return button
end

local function createBuildButton(buildingId: string, text: string, order: number): TextButton
	local button = createActionButton(text, order, "Kingdom", function()
		selectedBuildingId = buildingId
		updateConstructionPanel()
		handleResult(UpgradeBuilding:InvokeServer(buildingId))
	end)
	buildButtons[buildingId] = button

	button.MouseEnter:Connect(function()
		selectedBuildingId = buildingId
		updateConstructionPanel()
	end)

	return button
end

createActionButton("Coletar", 1, "Kingdom", function()
	handleResult(CollectProduction:InvokeServer())
end)

createBuildButton("farm", "Fazenda", 2)
createBuildButton("lumber_mill", "Serraria", 3)
createBuildButton("castle", "Castelo", 4)
createBuildButton("barracks", "Quarteis", 5)
createBuildButton("academy", "Academia", 6)

createActionButton("Treinar", 7, "Kingdom", function()
	handleResult(TrainTroops:InvokeServer("swordsman", 10))
end)

createActionButton("Pesquisar", 8, "Kingdom", function()
	handleResult(Research:InvokeServer("economy_gathering_1"))
end)

createActionButton("Atacar NPC", 1, "World", function()
	handleResult(AttackNpc:InvokeServer("bandit_scouts"))
end)

createActionButton("Explorar", 2, "World", function()
	handleResult(ExploreRegion:InvokeServer("alliance_plain"))
end)

createActionButton("Relatorio", 3, "World", function()
	if latestState and latestState.reports and latestState.reports[1] then
		local report = latestState.reports[1]
		local resultText = report.attackerWon and "Vitoria" or "Derrota"
		showPopup(
			`{resultText} contra {report.enemyName}`
				.. `\nAliado {report.attackerPower}   Inimigo {report.defenderPower}`
		)
	else
		setToast("Nenhum relatorio ainda.")
	end
end)

createActionButton("Sincronizar", 10, "Both", function()
	local state = GetState:InvokeServer()
	updateHud(state)
	setToast("Estado sincronizado.")
end)

modeButton.Activated:Connect(function()
	setViewMode(if viewMode == "Kingdom" then "World" else "Kingdom")
end)

popupClose.Activated:Connect(function()
	popup.Visible = false
end)

mouse.Button1Down:Connect(function()
	if viewMode ~= "World" then
		return
	end

	updateWorldInfo(findWorldSelectable(mouse.Target))
end)

StateSnapshot.OnClientEvent:Connect(updateHud)

DialogueEvent.OnClientEvent:Connect(function(dialogue: any)
	local speakerName = dialogue.speakerName or "Conselho"
	local lines = table.concat(dialogue.lines or {}, "\n")
	showPopup(speakerName .. "\n\n" .. lines)
end)

CombatReportEvent.OnClientEvent:Connect(function(report: any)
	local resultText = report.attackerWon and "Vitoria" or "Derrota"
	showPopup(
		`{resultText} contra {report.enemyName}`
			.. `\nPoder aliado: {report.attackerPower}   Poder inimigo: {report.defenderPower}`
	)
end)

player.CharacterAdded:Connect(function()
	task.wait(0.25)
	setCharacterVisible(viewMode == "Kingdom")
	setCameraForView()
end)

RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	if camera and camera.CameraType ~= Enum.CameraType.Scriptable then
		setCameraForView()
	end

	if os.clock() >= nextConstructionPanelRefresh then
		nextConstructionPanelRefresh = os.clock() + 0.5
		updateConstructionPanel()
	end
end)

task.spawn(function()
	local state = GetState:InvokeServer()
	updateHud(state)
	setViewMode("Kingdom")
end)
