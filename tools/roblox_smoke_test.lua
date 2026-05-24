local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local CivilizationWar = ReplicatedStorage:WaitForChild("CivilizationWar")
local Shared = CivilizationWar:WaitForChild("Shared")
local DataRegistry = require(Shared:WaitForChild("DataRegistry"))
local CombatResolver = require(Shared:WaitForChild("CombatResolver"))

local ServerRoot = ServerScriptService:WaitForChild("CivilizationWar")
local Services = ServerRoot:WaitForChild("Services")
local WorldBuilder = require(Services:WaitForChild("WorldBuilder"))
local WorldMapService = require(Services:WaitForChild("WorldMapService"))
local PlayerStateService = require(Services:WaitForChild("PlayerStateService"))

local function assertTrue(condition, message)
	if not condition then
		error("CIVWAR_SMOKE_FAIL: " .. message, 2)
	end
end

local function assertOk(result, action)
	assertTrue(result ~= nil, action .. " returned nil")
	assertTrue(result.ok == true, action .. " failed: " .. tostring(result.error))
	return result
end

local function finishConstructions(fakePlayer)
	local completed = PlayerStateService.DebugFinishAllConstructions(fakePlayer)
	assertTrue(#completed >= 1, "no construction completed")
	return completed
end

print("CIVWAR_SMOKE: begin")

local content = DataRegistry.Content
assertTrue(content.data.buildings.castle ~= nil, "castle data missing")
assertTrue(content.data.troops.swordsman ~= nil, "swordsman data missing")
assertTrue(content.maps.starter_valley.version == 3, "starter_valley version should be 3")
assertTrue(#content.maps.starter_valley.decorations >= 10, "decorations were not generated")

WorldBuilder.Build("starter_valley")
local world = Workspace:FindFirstChild("CivilizationWAR")
assertTrue(world ~= nil, "world was not built")
assertTrue(world:FindFirstChild("Decorations") ~= nil, "decorations folder missing")
assertTrue(#world.Decorations:GetChildren() >= 10, "decorations were not instantiated")
assertTrue(#world.NpcCamps:GetChildren() >= 4, "npc camps missing")
assertTrue(world.NpcCamps:GetAttribute("ViewLayer") == "LegacyWorld", "legacy world layer missing on old npc camps")
assertTrue(world.City:GetAttribute("ViewLayer") == "Kingdom", "kingdom layer missing on city")

WorldMapService.Build()
local worldMap = world:FindFirstChild("WorldMap")
assertTrue(worldMap ~= nil, "world map was not built")
assertTrue(worldMap:GetAttribute("GridSize") == 64, "world map grid size wrong")
assertTrue(worldMap:GetAttribute("RenderSize") == 32, "world map render size should be 32")
assertTrue(worldMap:GetAttribute("TileSize") == 8, "world map tile size should be readable")
assertTrue(#worldMap.Tiles:GetChildren() == 32 * 32, "world map should render a readable 32x32 area")
assertTrue(#worldMap.Markers:GetChildren() == 7, "world map marker count wrong")
assertTrue(worldMap.Markers:FindFirstChild("player_castle") ~= nil, "player castle marker missing")
assertTrue(worldMap.Markers:FindFirstChild("wood_01") ~= nil, "wood marker missing")
assertTrue(worldMap.Markers:FindFirstChild("food_01") ~= nil, "food marker missing")
assertTrue(worldMap.Markers:FindFirstChild("stone_01") ~= nil, "stone marker missing")
assertTrue(worldMap.Markers:FindFirstChild("iron_01") ~= nil, "iron marker missing")
assertTrue(worldMap.Markers:FindFirstChild("camp_bandit_scouts_01") ~= nil, "first npc camp marker missing")
assertTrue(worldMap.Markers:FindFirstChild("camp_rebel_raiders_01") ~= nil, "second npc camp marker missing")
assertTrue(worldMap.Markers.player_castle:IsA("Model"), "castle marker should be a distinct model")
assertTrue(
	worldMap.Markers.player_castle:GetAttribute("WorldMarkerShape") == "castle_keep",
	"castle marker shape missing"
)
assertTrue(worldMap.Markers.player_castle:GetAttribute("WorldSelectable") == true, "castle marker is not selectable")
assertTrue(
	worldMap.Markers.player_castle:GetAttribute("VisualPriority") == 100,
	"castle should be most visually prominent"
)
assertTrue(
	worldMap.Markers.wood_01:GetAttribute("WorldMarkerShape") == "resource_pillar",
	"resource marker shape missing"
)
assertTrue(
	worldMap.Markers.camp_bandit_scouts_01:GetAttribute("WorldMarkerShape") == "npc_tent",
	"camp marker shape missing"
)
assertTrue(
	worldMap.Markers.wood_01.PrimaryPart:GetAttribute("WorldSelectable") == true,
	"resource marker part is not selectable"
)
assertTrue(
	worldMap.Markers.camp_bandit_scouts_01.PrimaryPart:GetAttribute("WorldAction") ~= nil,
	"camp action feedback missing"
)
assertTrue(worldMap:GetAttribute("ViewLayer") == "World", "world map layer should be World")
assertTrue(worldMap.Tiles.Tile_32_32:GetAttribute("WorldSelectable") == true, "world tile selection missing")
assertTrue(worldMap.Tiles.Tile_32_32:GetAttribute("Biome") ~= nil, "world tile biome feedback missing")
assertTrue(
	worldMap.Markers.player_castle.PrimaryPart:GetAttribute("WorldType") == "playerCastle",
	"castle selection type missing"
)
assertTrue(world.City:GetAttribute("ViewLayer") == "Kingdom", "kingdom mode layer missing")

local fakePlayer = {
	UserId = -260523,
	Name = "SmokeTester",
}

local state = PlayerStateService.GetState(fakePlayer)
assertTrue(state.resources.food >= 1200, "starting food missing")
assertTrue(state.buildings.castle == 1, "starting castle level wrong")

local foodBeforeGathering = state.resources.food
local gatheringMarch = assertOk(PlayerStateService.StartGatheringMarch(fakePlayer, "food_01"), "start food gathering")
assertTrue(gatheringMarch.march ~= nil, "gathering march missing")
assertTrue(gatheringMarch.march.resourceId == "food_01", "gathering march target wrong")
assertTrue(gatheringMarch.march.resource == "food", "gathering march resource wrong")
assertTrue(gatheringMarch.march.workerCount == 1, "gathering should use one abstract worker")
assertTrue(gatheringMarch.march.status == "outgoing", "gathering march should start outgoing")

local duplicateGathering = PlayerStateService.StartGatheringMarch(fakePlayer, "food_01")
assertTrue(duplicateGathering.ok == false, "duplicate gathering march should be blocked")
assertTrue(duplicateGathering.error ~= nil, "duplicate gathering feedback missing")

local gatheringSnapshot = PlayerStateService.GetSnapshot(fakePlayer)
assertTrue(#gatheringSnapshot.marches == 1, "active gathering march missing from snapshot")
assertTrue(gatheringSnapshot.marches[1].finishAt > gatheringSnapshot.serverTime, "gathering march timer missing")

local completedGathering = PlayerStateService.DebugFinishAllMarches(fakePlayer)
assertTrue(#completedGathering >= 1, "gathering march did not complete")
assertTrue(state.resources.food > foodBeforeGathering, "gathering reward was not added")
assertTrue(#state.reports >= 1 and state.reports[1].type == "gather", "gathering report missing")

local farmConstruction = assertOk(PlayerStateService.UpgradeBuilding(fakePlayer, "farm"), "queue farm")
assertTrue(farmConstruction.construction ~= nil, "farm construction missing")
assertTrue((state.buildings.farm or 0) == 0, "farm should not complete instantly")
finishConstructions(fakePlayer)
assertTrue(state.buildings.farm == 1, "farm did not finish")
assertOk(PlayerStateService.CollectProduction(fakePlayer), "collect production")

assertOk(PlayerStateService.UpgradeBuilding(fakePlayer, "lumber_mill"), "queue sawmill")
finishConstructions(fakePlayer)
assertTrue(state.buildings.lumber_mill == 1, "sawmill did not finish")

local productionBeforeUpgrade = PlayerStateService.GetSnapshot(fakePlayer).productionPerMinute.food or 0
assertOk(PlayerStateService.UpgradeBuilding(fakePlayer, "castle"), "queue castle")
assertTrue((state.constructionQueue[1] and state.constructionQueue[1].durationSeconds or 0) > 0, "castle needs a timer")
finishConstructions(fakePlayer)
assertTrue(state.buildings.castle == 2, "castle did not finish")

assertOk(PlayerStateService.UpgradeBuilding(fakePlayer, "farm"), "queue farm level 2")
finishConstructions(fakePlayer)
local productionAfterUpgrade = PlayerStateService.GetSnapshot(fakePlayer).productionPerMinute.food or 0
assertTrue(productionAfterUpgrade > productionBeforeUpgrade, "farm upgrade did not increase production")

local offlineFoodBefore = state.resources.food
local offlineResult = PlayerStateService.DebugApplyOfflineProduction(fakePlayer, 3600)
assertTrue((offlineResult.resources.food or 0) > 0, "offline food was not produced")
assertTrue(state.resources.food > offlineFoodBefore, "offline resources were not applied")

PlayerStateService.Tick(fakePlayer, 180)
assertOk(PlayerStateService.UpgradeBuilding(fakePlayer, "barracks"), "queue barracks")
finishConstructions(fakePlayer)
assertOk(PlayerStateService.TrainTroops(fakePlayer, "swordsman", 10), "train swordsmen")
assertOk(PlayerStateService.UpgradeBuilding(fakePlayer, "academy"), "queue academy")
finishConstructions(fakePlayer)
assertOk(PlayerStateService.Research(fakePlayer, "economy_gathering_1"), "research gathering")

local blockedRequirement = PlayerStateService.UpgradeBuilding(fakePlayer, "iron_mine")
assertTrue(blockedRequirement.ok == false, "iron mine should require a higher castle")
assertTrue(blockedRequirement.error ~= nil, "requirement feedback missing")

assertOk(PlayerStateService.UpgradeBuilding(fakePlayer, "embassy"), "queue embassy")
finishConstructions(fakePlayer)
assertOk(PlayerStateService.ExploreRegion(fakePlayer, "alliance_plain"), "explore alliance plain")

local combatReport = CombatResolver.ResolveNpcBattle(state.troops, "bandit_scouts")
assertTrue(combatReport.attackerPower > 0, "combat attacker power invalid")
assertTrue(combatReport.defenderPower > 0, "combat defender power invalid")

local attackResult = assertOk(PlayerStateService.AttackNpc(fakePlayer, "bandit_scouts"), "attack bandit scouts")
assertTrue(attackResult.report ~= nil, "attack report missing")
assertTrue(type(attackResult.report.attackerWon) == "boolean", "attack result missing winner boolean")

local snapshot = PlayerStateService.GetSnapshot(fakePlayer)
assertTrue(snapshot.activeMission ~= nil or snapshot.missionState.activeMissionId == nil, "mission snapshot invalid")
assertTrue(#snapshot.reports >= 1, "combat report was not stored")

print("CIVWAR_SMOKE: PASS")
