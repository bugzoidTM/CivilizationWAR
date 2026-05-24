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
assertTrue(world.NpcCamps:GetAttribute("ViewLayer") == "World", "world layer missing on npc camps")
assertTrue(world.City:GetAttribute("ViewLayer") == "Kingdom", "kingdom layer missing on city")

local fakePlayer = {
	UserId = -260523,
	Name = "SmokeTester",
}

local state = PlayerStateService.GetState(fakePlayer)
assertTrue(state.resources.food >= 1200, "starting food missing")
assertTrue(state.buildings.castle == 1, "starting castle level wrong")

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
