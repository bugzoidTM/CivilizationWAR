--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("CivilizationWar"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DataRegistry = require(Shared:WaitForChild("DataRegistry"))
local Economy = require(Shared:WaitForChild("Economy"))
local MissionTracker = require(Shared:WaitForChild("MissionTracker"))
local CombatResolver = require(Shared:WaitForChild("CombatResolver"))
local ConstructionService = require(script.Parent.ConstructionService)
local EconomyService = require(script.Parent.EconomyService)
local MarchService = require(script.Parent.MarchService)

local PlayerStateService = {}

local statesByUserId: { [number]: any } = {}
local dataStore: any = nil
local dataStoreUnavailable = false
local syncMissionProgress = nil

local function clone(source: any): any
	return Economy.CopyDictionary(source)
end

local function getStoreKey(player: Player): string
	return `player_{player.UserId}`
end

local function canUseDataStore(player: Player): boolean
	return type(player.UserId) == "number" and player.UserId > 0
end

local function getDataStore(): any?
	if dataStoreUnavailable then
		return nil
	end

	if dataStore ~= nil then
		return dataStore
	end

	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)

	if not ok then
		dataStoreUnavailable = true
		warn(`CivilizationWAR DataStore unavailable: {result}`)
		return nil
	end

	dataStore = result
	return dataStore
end

local function addMissionRewards(state: any, missionResult: any): ()
	if missionResult.completed and missionResult.rewards then
		Economy.AddResources(state.resources, missionResult.rewards)
		state.lastMissionReward = {
			missionId = missionResult.missionId,
			rewards = missionResult.rewards,
		}
	end
end

local function applyMissionEvent(state: any, event: any): any
	local result = MissionTracker.ApplyEvent(state.missionState, event)
	addMissionRewards(state, result)
	if result.completed and syncMissionProgress then
		syncMissionProgress(state)
	end
	return result
end

local function applyConstructionCompletions(state: any, completed: { any }): ()
	for _, entry in ipairs(completed) do
		applyMissionEvent(state, {
			type = "building_level",
			buildingId = entry.buildingId,
			level = entry.targetLevel,
		})
	end
end

local function addGatherReport(state: any, march: any): ()
	local amount = march.reward and march.reward[march.resource] or 0
	table.insert(state.reports, 1, {
		type = "gather",
		title = "Coleta concluida",
		resourceId = march.resourceId,
		resourceName = march.resourceName,
		resource = march.resource,
		amount = amount,
		reward = march.reward,
		completedAt = march.finishAt or os.time(),
	})
	if #state.reports > 10 then
		table.remove(state.reports)
	end
end

local function applyCompletedMarches(state: any, completed: { any }): ()
	for _, march in ipairs(completed) do
		Economy.AddResources(state.resources, march.reward)
		for resource, amount in pairs(march.reward or {}) do
			state.stats.collectedResources[resource] = (state.stats.collectedResources[resource] or 0) + amount
			applyMissionEvent(state, {
				type = "collect_resource",
				resource = resource,
				amount = amount,
			})
		end
		addGatherReport(state, march)
	end
end

local function updateConstructionQueue(state: any, now: number?): { any }
	local completed = ConstructionService.UpdateQueue(state, now or os.time())
	applyConstructionCompletions(state, completed)
	return completed
end

local function updateMarches(state: any, now: number?): { any }
	local completed = MarchService.UpdateMarches(state, now or os.time())
	applyCompletedMarches(state, completed)
	return completed
end

local function ensureStateShape(state: any, player: Player): any
	state.userId = player.UserId
	state.playerName = player.Name
	state.civilizationId = state.civilizationId or Config.DefaultCivilization
	state.resources = state.resources or Economy.CreateStartingResources(state.civilizationId)
	state.buildings = state.buildings or clone(Config.StartingBuildings)
	state.troops = state.troops or clone(Config.StartingTroops)
	state.technologies = state.technologies or {}
	state.greatmenFragments = state.greatmenFragments or {}
	state.stats = state.stats or {}
	state.stats.trainedTroops = state.stats.trainedTroops or {}
	state.stats.defeatedEnemies = state.stats.defeatedEnemies or {}
	state.stats.collectedResources = state.stats.collectedResources or {}
	state.stats.completedResearch = state.stats.completedResearch or {}
	state.stats.exploredRegions = state.stats.exploredRegions or {}
	state.reports = state.reports or {}
	state.constructionQueue = state.constructionQueue or {}
	MarchService.EnsureState(state)
	state.missionState = state.missionState or MissionTracker.CreateState(Config.EntryMissionId)
	state.lastTick = state.lastTick or os.time()
	state.lastManualCollect = state.lastManualCollect or 0
	state.lastSavedAt = state.lastSavedAt or state.lastTick
	state.lastOfflineGains = state.lastOfflineGains or nil
	state.lastMissionReward = state.lastMissionReward or nil
	state.version = Config.Version

	return state
end

local function loadFromDataStore(player: Player): any?
	if not canUseDataStore(player) then
		return nil
	end

	local store = getDataStore()
	if store == nil then
		return nil
	end

	local ok, result = pcall(function()
		return store:GetAsync(getStoreKey(player))
	end)

	if not ok then
		warn(`CivilizationWAR DataStore load failed for {player.UserId}: {result}`)
		return nil
	end

	if type(result) ~= "table" then
		return nil
	end

	return result
end

local function applyOfflineProgress(state: any, elapsedSeconds: number, now: number): any
	local completed = updateConstructionQueue(state, now)
	local completedMarches = updateMarches(state, now)
	local offline = EconomyService.ApplyOfflineProduction(state, elapsedSeconds, Config.MaxOfflineSeconds, now)

	for resource, amount in pairs(offline.resources or {}) do
		state.stats.collectedResources[resource] = (state.stats.collectedResources[resource] or 0) + amount
		applyMissionEvent(state, {
			type = "collect_resource",
			resource = resource,
			amount = amount,
		})
	end

	offline.completedConstructions = #completed
	offline.completedMarches = #completedMarches
	return offline
end

syncMissionProgress = function(state: any): ()
	for _ = 1, 10 do
		local mission = MissionTracker.GetActiveMission(state.missionState)
		if mission == nil then
			return
		end

		local completedDuringPass = false
		for _, objective in ipairs(mission.objectives or {}) do
			local event = nil

			if objective.type == "building_level" then
				local level = state.buildings[objective.buildingId] or 0
				if level > 0 then
					event = {
						type = "building_level",
						buildingId = objective.buildingId,
						level = level,
						absolute = true,
					}
				end
			elseif objective.type == "train_troops" then
				local amount = state.stats.trainedTroops[objective.troopId] or 0
				if amount > 0 then
					event = {
						type = "train_troops",
						troopId = objective.troopId,
						amount = amount,
						absolute = true,
					}
				end
			elseif objective.type == "defeat_enemy" then
				local amount = state.stats.defeatedEnemies[objective.enemyId] or 0
				if amount > 0 then
					event = {
						type = "defeat_enemy",
						enemyId = objective.enemyId,
						amount = amount,
						absolute = true,
					}
				end
			elseif objective.type == "collect_resource" then
				local amount = state.stats.collectedResources[objective.resource] or 0
				if amount > 0 then
					event = {
						type = "collect_resource",
						resource = objective.resource,
						amount = amount,
						absolute = true,
					}
				end
			elseif objective.type == "research_complete" then
				if state.stats.completedResearch[objective.technologyId] then
					event = {
						type = "research_complete",
						technologyId = objective.technologyId,
						amount = 1,
						absolute = true,
					}
				end
			elseif objective.type == "explore_region" then
				if state.stats.exploredRegions[objective.regionId] then
					event = {
						type = "explore_region",
						regionId = objective.regionId,
						amount = 1,
						absolute = true,
					}
				end
			end

			if event then
				local result = MissionTracker.ApplyEvent(state.missionState, event)
				addMissionRewards(state, result)
				if result.completed then
					completedDuringPass = true
					break
				end
			end
		end

		if not completedDuringPass then
			return
		end
	end
end

function PlayerStateService.CreateState(player: Player, civilizationId: string?): any
	local selectedCivilization = civilizationId or Config.DefaultCivilization
	local state = {
		userId = player.UserId,
		playerName = player.Name,
		civilizationId = selectedCivilization,
		resources = Economy.CreateStartingResources(selectedCivilization),
		buildings = clone(Config.StartingBuildings),
		troops = clone(Config.StartingTroops),
		technologies = {},
		greatmenFragments = {},
		stats = {
			trainedTroops = {},
			defeatedEnemies = {},
			collectedResources = {},
			completedResearch = {},
			exploredRegions = {},
		},
		reports = {},
		constructionQueue = {},
		marches = {},
		nextMarchId = 1,
		workers = {
			total = 3,
		},
		missionState = MissionTracker.CreateState(Config.EntryMissionId),
		lastTick = os.time(),
		lastManualCollect = 0,
		lastSavedAt = os.time(),
		lastOfflineGains = nil,
		lastMissionReward = nil,
		version = Config.Version,
	}

	applyMissionEvent(state, {
		type = "building_level",
		buildingId = "castle",
		level = 1,
	})

	return state
end

function PlayerStateService.GetState(player: Player): any
	local state = statesByUserId[player.UserId]
	if state == nil then
		state = loadFromDataStore(player)
		if state == nil then
			state = PlayerStateService.CreateState(player, Config.DefaultCivilization)
		else
			state = ensureStateShape(state, player)
			local now = os.time()
			local elapsedSeconds = math.max(0, now - (state.lastSavedAt or state.lastTick or now))
			if elapsedSeconds > 0 then
				applyOfflineProgress(state, elapsedSeconds, now)
			end
		end
		statesByUserId[player.UserId] = state
	end

	return state
end

function PlayerStateService.RemoveState(player: Player): ()
	statesByUserId[player.UserId] = nil
end

function PlayerStateService.SaveState(player: Player): boolean
	if not canUseDataStore(player) then
		return false
	end

	local store = getDataStore()
	if store == nil then
		return false
	end

	local state = statesByUserId[player.UserId]
	if state == nil then
		return false
	end

	updateConstructionQueue(state, os.time())
	updateMarches(state, os.time())
	state.lastSavedAt = os.time()
	local payload = clone(state)

	local ok, result = pcall(function()
		store:SetAsync(getStoreKey(player), payload)
	end)

	if not ok then
		warn(`CivilizationWAR DataStore save failed for {player.UserId}: {result}`)
	end

	return ok
end

function PlayerStateService.DebugFinishAllConstructions(player: Player): { any }
	local state = PlayerStateService.GetState(player)
	local queue = state.constructionQueue or {}
	local now = os.time()

	for _, entry in ipairs(queue) do
		entry.finishAt = now - 1
	end

	return updateConstructionQueue(state, now)
end

function PlayerStateService.DebugFinishAllMarches(player: Player): { any }
	local state = PlayerStateService.GetState(player)
	local completed = MarchService.DebugFinishAllMarches(state, os.time())
	applyCompletedMarches(state, completed)
	return completed
end

function PlayerStateService.DebugApplyOfflineProduction(player: Player, elapsedSeconds: number): any
	local state = PlayerStateService.GetState(player)
	return applyOfflineProgress(state, elapsedSeconds, os.time())
end

function PlayerStateService.GetSnapshot(player: Player): any
	local state = PlayerStateService.GetState(player)
	local now = os.time()
	updateConstructionQueue(state, now)
	updateMarches(state, now)
	local snapshot = clone(state)
	snapshot.serverTime = now
	snapshot.maxConstructionQueue = Config.MaxConstructionQueue
	snapshot.productionPerMinute = EconomyService.CalculateProductionPerMinute(state)
	snapshot.constructionQueue = ConstructionService.GetQueueSnapshot(state, now)
	snapshot.marches = MarchService.GetMarchSnapshot(state, now)
	snapshot.buildingActions = ConstructionService.GetActionSnapshot(state, now)
	snapshot.activeMission = MissionTracker.GetActiveMission(state.missionState)

	return snapshot
end

function PlayerStateService.Tick(player: Player, deltaSeconds: number): any
	local state = PlayerStateService.GetState(player)
	updateConstructionQueue(state, os.time())
	updateMarches(state, os.time())
	local gains = EconomyService.ApplyProduction(state, deltaSeconds, os.time())

	for resource, amount in pairs(gains) do
		state.stats.collectedResources[resource] = (state.stats.collectedResources[resource] or 0) + amount
		applyMissionEvent(state, {
			type = "collect_resource",
			resource = resource,
			amount = amount,
		})
	end

	return gains
end

function PlayerStateService.CollectProduction(player: Player): any
	local state = PlayerStateService.GetState(player)
	local now = os.time()
	updateConstructionQueue(state, now)
	local cooldown = Config.ManualCollectCooldownSeconds
	local remaining = cooldown - (now - (state.lastManualCollect or 0))

	if remaining > 0 then
		return {
			ok = false,
			error = `A coleta estará pronta em {remaining}s.`,
			state = PlayerStateService.GetSnapshot(player),
		}
	end

	local production = EconomyService.CalculateProductionPerMinute(state)
	local gains = {}

	for resource, perMinute in pairs(production) do
		local amount = math.max(12, math.floor((perMinute or 0) * 0.75 + 0.5))
		if amount > 0 then
			gains[resource] = amount
			state.stats.collectedResources[resource] = (state.stats.collectedResources[resource] or 0) + amount
			applyMissionEvent(state, {
				type = "collect_resource",
				resource = resource,
				amount = amount,
			})
		end
	end

	if next(gains) == nil then
		return {
			ok = false,
			error = "Construa uma Fazenda ou Serraria para coletar produção.",
			state = PlayerStateService.GetSnapshot(player),
		}
	end

	EconomyService.AddResources(state.resources, gains)
	state.lastManualCollect = now

	return {
		ok = true,
		gains = gains,
		state = PlayerStateService.GetSnapshot(player),
	}
end

function PlayerStateService.StartGatheringMarch(player: Player, resourceId: string): any
	local state = PlayerStateService.GetState(player)
	local now = os.time()
	updateConstructionQueue(state, now)
	updateMarches(state, now)

	local result = MarchService.StartGatheringMarch(state, resourceId, now)
	if not result.ok then
		return {
			ok = false,
			error = result.error or "Coleta indisponivel.",
			state = PlayerStateService.GetSnapshot(player),
		}
	end

	return {
		ok = true,
		march = result.march,
		state = PlayerStateService.GetSnapshot(player),
	}
end

function PlayerStateService.UpgradeBuilding(player: Player, buildingId: string): any
	local state = PlayerStateService.GetState(player)
	local now = os.time()
	updateConstructionQueue(state, now)
	local result = ConstructionService.StartConstruction(state, buildingId, now)

	if not result.ok then
		return {
			ok = false,
			error = result.error or "Construcao indisponivel.",
			action = result.action,
			state = PlayerStateService.GetSnapshot(player),
		}
	end

	return {
		ok = true,
		construction = result.construction,
		state = PlayerStateService.GetSnapshot(player),
	}
end

function PlayerStateService.TrainTroops(player: Player, troopId: string, amount: number): any
	amount = math.floor(tonumber(amount) or 0)
	if amount <= 0 or amount > 500 then
		return { ok = false, error = "Quantidade inválida." }
	end

	local state = PlayerStateService.GetState(player)
	updateConstructionQueue(state, os.time())
	local troops = DataRegistry.GetDataSet("troops")
	local troop = troops[troopId]

	if troop == nil then
		return { ok = false, error = "Tropa desconhecida." }
	end

	local buildings = DataRegistry.GetDataSet("buildings")
	local barracks = buildings.barracks
	local barracksLevel = state.buildings.barracks or 0
	local barracksDefinition = Economy.GetLevelDefinition(barracks, barracksLevel)

	if barracksDefinition == nil or (barracksDefinition.unlocksTroopTier or 1) < troop.tier then
		return { ok = false, error = `Requer quartéis melhores para tier {troop.tier}.` }
	end

	local cost = Economy.ScaleCost(troop.trainCost, amount)
	if not Economy.Spend(state.resources, cost) then
		return { ok = false, error = "Recursos insuficientes." }
	end

	state.troops[troopId] = (state.troops[troopId] or 0) + amount
	state.stats.trainedTroops[troopId] = (state.stats.trainedTroops[troopId] or 0) + amount
	local missionResult = applyMissionEvent(state, {
		type = "train_troops",
		troopId = troopId,
		amount = amount,
	})

	return {
		ok = true,
		state = PlayerStateService.GetSnapshot(player),
		mission = missionResult,
	}
end

function PlayerStateService.Research(player: Player, technologyId: string): any
	local state = PlayerStateService.GetState(player)
	updateConstructionQueue(state, os.time())
	local technologies = DataRegistry.GetDataSet("tech_tree")
	local technology = technologies[technologyId]

	if technology == nil then
		return { ok = false, error = "Tecnologia desconhecida." }
	end

	if state.technologies[technologyId] then
		return { ok = false, error = "Pesquisa já concluída." }
	end

	local academyLevel = state.buildings.academy or 0
	if academyLevel < (technology.academyLevel or 1) then
		return { ok = false, error = `Requer Academia nível {technology.academyLevel}.` }
	end

	for _, prerequisite in ipairs(technology.prerequisites or {}) do
		if not state.technologies[prerequisite] then
			return { ok = false, error = "Pré-requisito de pesquisa ausente." }
		end
	end

	if not Economy.Spend(state.resources, technology.cost or {}) then
		return { ok = false, error = "Recursos insuficientes." }
	end

	state.technologies[technologyId] = true
	state.stats.completedResearch[technologyId] = true
	local missionResult = applyMissionEvent(state, {
		type = "research_complete",
		technologyId = technologyId,
		amount = 1,
	})

	return {
		ok = true,
		state = PlayerStateService.GetSnapshot(player),
		mission = missionResult,
	}
end

function PlayerStateService.AttackNpc(player: Player, enemyId: string): any
	local state = PlayerStateService.GetState(player)
	local report = CombatResolver.ResolveNpcBattle(state.troops, enemyId)

	state.troops = report.remainingAttackers

	local missionResult = nil
	if report.attackerWon then
		Economy.AddResources(state.resources, report.rewards)
		state.stats.defeatedEnemies[enemyId] = (state.stats.defeatedEnemies[enemyId] or 0) + 1
		missionResult = applyMissionEvent(state, {
			type = "defeat_enemy",
			enemyId = enemyId,
			amount = 1,
		})
	end

	table.insert(state.reports, 1, report)
	if #state.reports > 10 then
		table.remove(state.reports)
	end

	return {
		ok = true,
		report = report,
		state = PlayerStateService.GetSnapshot(player),
		mission = missionResult,
	}
end

function PlayerStateService.ExploreRegion(player: Player, regionId: string): any
	local state = PlayerStateService.GetState(player)
	state.stats.exploredRegions[regionId] = true
	local missionResult = applyMissionEvent(state, {
		type = "explore_region",
		regionId = regionId,
		amount = 1,
	})

	return {
		ok = true,
		state = PlayerStateService.GetSnapshot(player),
		mission = missionResult,
	}
end

return PlayerStateService
