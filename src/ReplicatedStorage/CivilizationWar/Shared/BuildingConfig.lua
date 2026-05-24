--!strict

local DataRegistry = require(script.Parent.DataRegistry)
local Economy = require(script.Parent.Economy)

local BuildingConfig = {}

local BUILD_ORDER = {
	"castle",
	"farm",
	"lumber_mill",
	"barracks",
	"academy",
	"quarry",
	"iron_mine",
}

local RESOURCE_NAMES = {
	food = "Comida",
	wood = "Madeira",
	stone = "Pedra",
	iron = "Ferro",
	silver = "Prata",
	gold = "Ouro",
}

function BuildingConfig.GetAll(): any
	return DataRegistry.GetDataSet("buildings")
end

function BuildingConfig.Get(buildingId: string): any?
	return BuildingConfig.GetAll()[buildingId]
end

function BuildingConfig.GetBuildOrder(): { string }
	return table.clone(BUILD_ORDER)
end

function BuildingConfig.GetCurrentLevel(state: any, buildingId: string): number
	return state.buildings and (state.buildings[buildingId] or 0) or 0
end

function BuildingConfig.GetLevelDefinition(buildingId: string, level: number): any?
	local building = BuildingConfig.Get(buildingId)
	if building == nil then
		return nil
	end

	return Economy.GetLevelDefinition(building, level)
end

function BuildingConfig.FormatResources(resources: any): string
	local parts = {}
	local order = DataRegistry.GetResourceOrder()

	for _, resource in ipairs(order) do
		local amount = resources and resources[resource]
		if amount and amount > 0 then
			table.insert(parts, `{RESOURCE_NAMES[resource] or resource} {math.floor(amount)}`)
		end
	end

	if #parts == 0 then
		return "Sem custo"
	end

	return table.concat(parts, ", ")
end

function BuildingConfig.FormatDuration(seconds: number?): string
	local value = math.max(0, math.floor(seconds or 0))
	if value >= 3600 then
		local hours = math.floor(value / 3600)
		local minutes = math.floor((value % 3600) / 60)
		return `{hours}h {minutes}m`
	elseif value >= 60 then
		return `{math.floor(value / 60)}m {value % 60}s`
	end

	return `{value}s`
end

function BuildingConfig.GetRequirements(buildingId: string, targetLevel: number): { any }
	local building = BuildingConfig.Get(buildingId)
	if building == nil then
		return {}
	end

	local requirements = {}
	local requiredCastleLevel = building.unlockAtCastleLevel or 1

	if buildingId ~= "castle" and requiredCastleLevel > 1 then
		table.insert(requirements, {
			type = "building_level",
			buildingId = "castle",
			level = requiredCastleLevel,
			text = `Requer Castelo Nv.{requiredCastleLevel}`,
		})
	end

	if buildingId ~= "castle" and targetLevel > 1 then
		table.insert(requirements, {
			type = "building_level",
			buildingId = "castle",
			level = targetLevel,
			text = `Requer Castelo Nv.{targetLevel}`,
		})
	end

	return requirements
end

function BuildingConfig.CheckRequirements(state: any, buildingId: string, targetLevel: number): (boolean, string?)
	for _, requirement in ipairs(BuildingConfig.GetRequirements(buildingId, targetLevel)) do
		if requirement.type == "building_level" then
			local currentLevel = BuildingConfig.GetCurrentLevel(state, requirement.buildingId)
			if currentLevel < requirement.level then
				return false, requirement.text
			end
		end
	end

	return true, nil
end

function BuildingConfig.GetNextLevelInfo(state: any, buildingId: string, queuedLevels: number?): any?
	local building = BuildingConfig.Get(buildingId)
	if building == nil then
		return nil
	end

	local currentLevel = BuildingConfig.GetCurrentLevel(state, buildingId)
	local targetLevel = currentLevel + (queuedLevels or 0) + 1
	local maxLevel = building.maxLevel or targetLevel
	local levelDefinition = Economy.GetLevelDefinition(building, targetLevel)

	return {
		buildingId = buildingId,
		displayName = building.displayName or buildingId,
		description = building.description or "",
		currentLevel = currentLevel,
		targetLevel = targetLevel,
		maxLevel = maxLevel,
		isMaxLevel = currentLevel >= maxLevel,
		cost = if levelDefinition then levelDefinition.cost or {} else {},
		costText = if levelDefinition
			then BuildingConfig.FormatResources(levelDefinition.cost or {})
			else "Nivel maximo",
		durationSeconds = if levelDefinition then levelDefinition.buildSeconds or 0 else 0,
		durationText = if levelDefinition
			then BuildingConfig.FormatDuration(levelDefinition.buildSeconds or 0)
			else "-",
		requirements = BuildingConfig.GetRequirements(buildingId, targetLevel),
		production = building.production,
		productionPerMinute = if levelDefinition then levelDefinition.productionPerMinute else nil,
	}
end

return BuildingConfig
