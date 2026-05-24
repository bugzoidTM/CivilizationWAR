--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("CivilizationWar"):WaitForChild("Shared")
local Economy = require(Shared:WaitForChild("Economy"))
local MarchConfig = require(Shared:WaitForChild("MarchConfig"))
local WorldConfig = require(Shared:WaitForChild("WorldConfig"))

type Player = any

local MarchService = {}

local playerStateService: any = nil

local function copy(source: any): any
	return Economy.CopyDictionary(source)
end

local function findResourceNode(resourceId: string): any?
	for _, resource in ipairs(WorldConfig.ResourceNodes) do
		if resource.id == resourceId then
			return resource
		end
	end

	return nil
end

local function ensureMarchState(state: any): ()
	state.marches = state.marches or {}
	state.nextMarchId = state.nextMarchId or 1
	state.workers = state.workers or {
		total = MarchConfig.StartingWorkers,
	}
	state.workers.total = state.workers.total or MarchConfig.StartingWorkers
end

local function getMarches(state: any): { any }
	return (state.marches or {}) :: { any }
end

local function getTravelSeconds(resource: any): number
	local castle = WorldConfig.PlayerCastle
	local distance = math.abs((resource.x or 0) - castle.x) + math.abs((resource.y or 0) - castle.y)
	return math.max(1, math.ceil(MarchConfig.BaseTravelSeconds + distance * MarchConfig.SecondsPerTile))
end

local function getGatherReward(resource: any): any
	local capacity = MarchConfig.ResourceCapacity[resource.resource] or 100
	return {
		[resource.resource] = math.min(capacity, resource.amount or capacity),
	}
end

local function getUsedWorkers(state: any): number
	local used = 0
	for _, march in ipairs(getMarches(state)) do
		if march.status ~= "completed" then
			used += march.workerCount or 0
		end
	end

	return used
end

local function hasActiveResourceMarch(state: any, resourceId: string): boolean
	for _, march in ipairs(getMarches(state)) do
		if march.kind == "gather" and march.resourceId == resourceId and march.status ~= "completed" then
			return true
		end
	end

	return false
end

local function updateMarchStatus(march: any, now: number): ()
	if march.status == "completed" then
		return
	end

	if now >= (march.finishAt or math.huge) then
		march.status = "completed"
	elseif now >= (march.gatheringFinishAt or math.huge) then
		march.status = "returning"
	elseif now >= (march.outgoingFinishAt or math.huge) then
		march.status = "gathering"
	else
		march.status = "outgoing"
	end
end

function MarchService.Configure(options: any): ()
	playerStateService = options.playerStateService
end

function MarchService.EnsureState(state: any): ()
	ensureMarchState(state)
end

function MarchService.StartGatheringMarch(state: any, resourceId: string, now: number?): any
	ensureMarchState(state)
	local startedAt = now or os.time()
	local resource = findResourceNode(resourceId)
	if resource == nil then
		return {
			ok = false,
			error = "Ponto de recurso desconhecido.",
		}
	end

	if hasActiveResourceMarch(state, resourceId) then
		return {
			ok = false,
			error = "Ja existe uma coleta em andamento neste ponto.",
		}
	end

	local workerCount = MarchConfig.WorkersPerGatherMarch
	if getUsedWorkers(state) + workerCount > (state.workers.total or MarchConfig.StartingWorkers) then
		return {
			ok = false,
			error = "Todos os trabalhadores estao ocupados.",
		}
	end

	local travelSeconds = getTravelSeconds(resource)
	local outgoingFinishAt = startedAt + travelSeconds
	local gatheringFinishAt = outgoingFinishAt + MarchConfig.GatherSeconds
	local returningFinishAt = gatheringFinishAt + travelSeconds
	local castle = WorldConfig.PlayerCastle
	local march = {
		id = `gather_{state.nextMarchId}`,
		kind = "gather",
		status = "outgoing",
		resourceId = resource.id,
		resourceName = resource.name,
		resource = resource.resource,
		workerCount = workerCount,
		originX = castle.x,
		originY = castle.y,
		targetX = resource.x,
		targetY = resource.y,
		startAt = startedAt,
		outgoingFinishAt = outgoingFinishAt,
		gatheringFinishAt = gatheringFinishAt,
		finishAt = returningFinishAt,
		reward = getGatherReward(resource),
	}
	state.nextMarchId += 1
	table.insert(state.marches, march)

	return {
		ok = true,
		march = copy(march),
	}
end

function MarchService.UpdateMarches(state: any, now: number?): { any }
	ensureMarchState(state)
	local currentTime = now or os.time()
	local completed = {}

	for _, march in ipairs(getMarches(state)) do
		local previousStatus = march.status
		updateMarchStatus(march, currentTime)
		if previousStatus ~= "completed" and march.status == "completed" and march.rewardApplied ~= true then
			march.rewardApplied = true
			table.insert(completed, copy(march))
		end
	end

	return completed
end

function MarchService.GetMarchSnapshot(state: any, now: number?): { any }
	MarchService.UpdateMarches(state, now)
	local snapshot = {}
	for _, march in ipairs(getMarches(state)) do
		if march.status ~= "completed" then
			table.insert(snapshot, copy(march))
		end
	end

	return snapshot
end

function MarchService.DebugFinishAllMarches(state: any, now: number?): { any }
	ensureMarchState(state)
	local currentTime = now or os.time()
	for _, march in ipairs(getMarches(state)) do
		if march.status ~= "completed" then
			march.finishAt = currentTime - 1
			march.gatheringFinishAt = math.min(march.gatheringFinishAt or currentTime - 1, currentTime - 1)
			march.outgoingFinishAt = math.min(march.outgoingFinishAt or currentTime - 1, currentTime - 1)
		end
	end

	return MarchService.UpdateMarches(state, currentTime)
end

function MarchService.AttackNpc(player: Player, enemyId: string): any
	assert(playerStateService ~= nil, "MarchService was not configured")
	return playerStateService.AttackNpc(player, enemyId)
end

return MarchService
