--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("CivilizationWar"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BuildingConfig = require(Shared:WaitForChild("BuildingConfig"))
local EconomyService = require(script.Parent.EconomyService)

local ConstructionService = {}

local TRACKED_BUILDINGS = {
	"castle",
	"farm",
	"lumber_mill",
	"barracks",
	"academy",
}

local function ensureQueue(state: any): { any }
	state.constructionQueue = state.constructionQueue or {}
	return state.constructionQueue
end

local function getQueueLength(state: any): number
	return #ensureQueue(state)
end

local function countQueuedLevels(state: any, buildingId: string): number
	local total = 0
	for _, entry in ipairs(ensureQueue(state)) do
		if entry.buildingId == buildingId then
			total += 1
		end
	end

	return total
end

local function getQueuedEntry(state: any, buildingId: string): any?
	for _, entry in ipairs(ensureQueue(state)) do
		if entry.buildingId == buildingId then
			return entry
		end
	end

	return nil
end

local function appendTiming(queue: { any }, entry: any, now: number): ()
	local lastEntry = queue[#queue]
	local startAt = now
	if lastEntry and lastEntry.finishAt and lastEntry.finishAt > startAt then
		startAt = lastEntry.finishAt
	end

	entry.queuedAt = now
	entry.startedAt = startAt
	entry.finishAt = startAt + entry.durationSeconds
end

function ConstructionService.GetTrackedBuildings(): { string }
	return table.clone(TRACKED_BUILDINGS)
end

function ConstructionService.GetActionInfo(state: any, buildingId: string, now: number?): any?
	local pending = getQueuedEntry(state, buildingId)
	if pending then
		local remaining = math.max(0, (pending.finishAt or (now or os.time())) - (now or os.time()))
		return {
			buildingId = buildingId,
			displayName = pending.displayName or buildingId,
			currentLevel = state.buildings[buildingId] or 0,
			targetLevel = pending.targetLevel,
			cost = pending.cost or {},
			costText = BuildingConfig.FormatResources(pending.cost or {}),
			durationSeconds = pending.durationSeconds or 0,
			durationText = BuildingConfig.FormatDuration(pending.durationSeconds or 0),
			requirementText = "Construcao em andamento",
			canStart = false,
			status = "queued",
			statusText = `Em fila: faltam {BuildingConfig.FormatDuration(remaining)}`,
			remainingSeconds = remaining,
		}
	end

	local queuedLevels = countQueuedLevels(state, buildingId)
	local info = BuildingConfig.GetNextLevelInfo(state, buildingId, queuedLevels)
	if info == nil then
		return nil
	end

	if info.isMaxLevel then
		info.canStart = false
		info.status = "max"
		info.statusText = "Nivel maximo"
		info.requirementText = "Completo"
		return info
	end

	local requirementsOk, requirementText = BuildingConfig.CheckRequirements(state, buildingId, info.targetLevel)
	if not requirementsOk then
		info.canStart = false
		info.status = "blocked"
		info.statusText = requirementText or "Requisito ausente"
		info.requirementText = requirementText or "Requisito ausente"
		return info
	end

	if getQueueLength(state) >= Config.MaxConstructionQueue then
		info.canStart = false
		info.status = "queue_full"
		info.statusText = "Fila cheia"
		info.requirementText = "Aguarde uma construcao terminar"
		return info
	end

	local missing = EconomyService.GetMissingResources(state.resources, info.cost)
	if EconomyService.HasMissingResources(missing) then
		info.canStart = false
		info.status = "missing_resources"
		info.statusText = "Faltam recursos"
		info.requirementText = "Falta: " .. EconomyService.FormatResources(missing)
		info.missingResources = missing
		return info
	end

	info.canStart = true
	info.status = "ready"
	info.statusText = "Pronto para construir"
	info.requirementText = "Requisitos OK"
	return info
end

function ConstructionService.StartConstruction(state: any, buildingId: string, now: number?): any
	local timestamp = now or os.time()
	local info = ConstructionService.GetActionInfo(state, buildingId, timestamp)
	if info == nil then
		return {
			ok = false,
			error = "Edificio desconhecido.",
		}
	end

	if not info.canStart then
		return {
			ok = false,
			error = info.statusText or "Construcao indisponivel.",
			action = info,
		}
	end

	if not EconomyService.Spend(state.resources, info.cost or {}) then
		local missing = EconomyService.GetMissingResources(state.resources, info.cost or {})
		info.missingResources = missing
		info.status = "missing_resources"
		info.statusText = "Faltam recursos"
		info.requirementText = "Falta: " .. EconomyService.FormatResources(missing)
		return {
			ok = false,
			error = info.requirementText,
			action = info,
		}
	end

	local queue = ensureQueue(state)
	local entry = {
		id = `{buildingId}_{info.targetLevel}_{timestamp}_{#queue + 1}`,
		buildingId = buildingId,
		displayName = info.displayName,
		targetLevel = info.targetLevel,
		durationSeconds = info.durationSeconds or 0,
		cost = info.cost or {},
	}

	appendTiming(queue, entry, timestamp)
	table.insert(queue, entry)

	return {
		ok = true,
		construction = entry,
	}
end

function ConstructionService.UpdateQueue(state: any, now: number?): { any }
	local timestamp = now or os.time()
	local queue = ensureQueue(state)
	local completed = {}

	while queue[1] and (queue[1].finishAt or math.huge) <= timestamp do
		local entry = table.remove(queue, 1)
		state.buildings[entry.buildingId] = math.max(state.buildings[entry.buildingId] or 0, entry.targetLevel or 1)
		entry.completedAt = timestamp
		table.insert(completed, entry)
	end

	return completed
end

function ConstructionService.GetQueueSnapshot(state: any, now: number?): { any }
	local timestamp = now or os.time()
	local snapshot = {}

	for index, entry in ipairs(ensureQueue(state)) do
		local copy = table.clone(entry)
		copy.index = index
		copy.remainingSeconds = math.max(0, (entry.finishAt or timestamp) - timestamp)
		table.insert(snapshot, copy)
	end

	return snapshot
end

function ConstructionService.GetActionSnapshot(state: any, now: number?): any
	local actions = {}

	for _, buildingId in ipairs(TRACKED_BUILDINGS) do
		actions[buildingId] = ConstructionService.GetActionInfo(state, buildingId, now or os.time())
	end

	return actions
end

return ConstructionService
