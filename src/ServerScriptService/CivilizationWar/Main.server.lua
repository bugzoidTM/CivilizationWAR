--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = ReplicatedStorage:WaitForChild("CivilizationWar")
local shared = root:WaitForChild("Shared")

local Config = require(shared:WaitForChild("Config"))
local PlayerStateService = require(script.Parent.Services.PlayerStateService)
local WorldBuilder = require(script.Parent.Services.WorldBuilder)
local WorldMapService = require(script.Parent.Services.WorldMapService)
local NPCService = require(script.Parent.Services.NPCService)
local MarchService = require(script.Parent.Services.MarchService)

local remotes = root:FindFirstChild("Remotes")
if remotes == nil then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = root
end

local function ensureRemoteEvent(name: string): RemoteEvent
	local remote = remotes:FindFirstChild(name)
	if remote == nil then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end

	return remote :: RemoteEvent
end

local function ensureRemoteFunction(name: string): RemoteFunction
	local remote = remotes:FindFirstChild(name)
	if remote == nil then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remotes
	end

	return remote :: RemoteFunction
end

local StateSnapshot = ensureRemoteEvent("StateSnapshot")
local DialogueEvent = ensureRemoteEvent("Dialogue")
local CombatReportEvent = ensureRemoteEvent("CombatReport")

local GetState = ensureRemoteFunction("GetState")
local CollectProduction = ensureRemoteFunction("CollectProduction")
local UpgradeBuilding = ensureRemoteFunction("UpgradeBuilding")
local TrainTroops = ensureRemoteFunction("TrainTroops")
local Research = ensureRemoteFunction("Research")
local AttackNpc = ensureRemoteFunction("AttackNpc")
local ExploreRegion = ensureRemoteFunction("ExploreRegion")
local StartGatheringMarch = ensureRemoteFunction("StartGatheringMarch")

WorldBuilder.Build(Config.EntryMapId)
WorldMapService.Build()
MarchService.Configure({
	playerStateService = PlayerStateService,
})

local function sendSnapshot(player: Player): ()
	StateSnapshot:FireClient(player, PlayerStateService.GetSnapshot(player))
end

NPCService.ConnectPrompts({
	onDialogue = function(player: Player, dialogue: any)
		DialogueEvent:FireClient(player, dialogue)
	end,
	onAttack = function(player: Player, enemyId: string)
		local result = MarchService.AttackNpc(player, enemyId)
		if result.report then
			CombatReportEvent:FireClient(player, result.report)
		end
		if result.state then
			StateSnapshot:FireClient(player, result.state)
		end
	end,
})

Players.PlayerAdded:Connect(function(player: Player)
	PlayerStateService.GetState(player)
	task.defer(sendSnapshot, player)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	PlayerStateService.SaveState(player)
	PlayerStateService.RemoveState(player)
end)

GetState.OnServerInvoke = function(player: Player)
	return PlayerStateService.GetSnapshot(player)
end

CollectProduction.OnServerInvoke = function(player: Player)
	return PlayerStateService.CollectProduction(player)
end

UpgradeBuilding.OnServerInvoke = function(player: Player, buildingId: string)
	return PlayerStateService.UpgradeBuilding(player, buildingId)
end

TrainTroops.OnServerInvoke = function(player: Player, troopId: string, amount: number)
	return PlayerStateService.TrainTroops(player, troopId, amount)
end

Research.OnServerInvoke = function(player: Player, technologyId: string)
	return PlayerStateService.Research(player, technologyId)
end

AttackNpc.OnServerInvoke = function(player: Player, enemyId: string)
	local result = MarchService.AttackNpc(player, enemyId)
	if result.report then
		CombatReportEvent:FireClient(player, result.report)
	end
	return result
end

ExploreRegion.OnServerInvoke = function(player: Player, regionId: string)
	return PlayerStateService.ExploreRegion(player, regionId)
end

StartGatheringMarch.OnServerInvoke = function(player: Player, resourceId: string)
	return PlayerStateService.StartGatheringMarch(player, resourceId)
end

task.spawn(function()
	while true do
		task.wait(Config.ResourceTickSeconds)
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerStateService.Tick(player, Config.ResourceTickSeconds)
			sendSnapshot(player)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(Config.AutoSaveIntervalSeconds)
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerStateService.SaveState(player)
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerStateService.SaveState(player)
	end
end)
