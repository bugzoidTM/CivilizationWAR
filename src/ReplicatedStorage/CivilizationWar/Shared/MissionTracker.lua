--!strict

local Config = require(script.Parent.Config)
local DataRegistry = require(script.Parent.DataRegistry)

local MissionTracker = {}

local function objectiveKey(objective: any): string
	if objective.type == "building_level" then
		return `building:{objective.buildingId}`
	elseif objective.type == "train_troops" then
		return `troop:{objective.troopId}`
	elseif objective.type == "defeat_enemy" then
		return `enemy:{objective.enemyId}`
	elseif objective.type == "collect_resource" then
		return `resource:{objective.resource}`
	elseif objective.type == "research_complete" then
		return `research:{objective.technologyId}`
	elseif objective.type == "explore_region" then
		return `region:{objective.regionId}`
	end

	return objective.type
end

local function requiredAmount(objective: any): number
	if objective.type == "building_level" then
		return objective.level or 1
	end

	return objective.amount or 1
end

local function eventMatchesObjective(event: any, objective: any): boolean
	if event.type ~= objective.type then
		return false
	end

	if objective.buildingId and event.buildingId ~= objective.buildingId then
		return false
	end

	if objective.troopId and event.troopId ~= objective.troopId then
		return false
	end

	if objective.enemyId and event.enemyId ~= objective.enemyId then
		return false
	end

	if objective.resource and event.resource ~= objective.resource then
		return false
	end

	if objective.technologyId and event.technologyId ~= objective.technologyId then
		return false
	end

	if objective.regionId and event.regionId ~= objective.regionId then
		return false
	end

	return true
end

function MissionTracker.CreateState(entryMissionId: string?): any
	return {
		activeMissionId = entryMissionId or Config.EntryMissionId,
		completed = {},
		progress = {},
	}
end

function MissionTracker.GetActiveMission(missionState: any): any?
	if missionState.activeMissionId == nil then
		return nil
	end

	local missions = DataRegistry.GetDataSet("missions")
	return missions[missionState.activeMissionId]
end

function MissionTracker.ApplyEvent(missionState: any, event: any): any
	local mission = MissionTracker.GetActiveMission(missionState)
	if mission == nil then
		return { completed = false }
	end

	local progress = missionState.progress[mission.id] or {}
	missionState.progress[mission.id] = progress

	for _, objective in ipairs(mission.objectives or {}) do
		if eventMatchesObjective(event, objective) then
			local key = objectiveKey(objective)
			local eventAmount = event.amount or event.level or 1
			local nextValue = (progress[key] or 0) + eventAmount

			if event.absolute then
				nextValue = math.max(progress[key] or 0, eventAmount)
			end

			if objective.type == "building_level" then
				nextValue = math.max(progress[key] or 0, event.level or 1)
			end

			progress[key] = nextValue
		end
	end

	local allComplete = true
	for _, objective in ipairs(mission.objectives or {}) do
		local key = objectiveKey(objective)
		if (progress[key] or 0) < requiredAmount(objective) then
			allComplete = false
			break
		end
	end

	if not allComplete then
		return {
			completed = false,
			missionId = mission.id,
			progress = progress,
		}
	end

	missionState.completed[mission.id] = true
	missionState.activeMissionId = mission.nextMission

	return {
		completed = true,
		missionId = mission.id,
		nextMissionId = mission.nextMission,
		rewards = mission.rewards or {},
		progress = progress,
	}
end

return MissionTracker
