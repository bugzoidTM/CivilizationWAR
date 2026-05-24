--!strict

local Config = require(script.Parent.Config)
local DataRegistry = require(script.Parent.DataRegistry)

local Economy = {}

local function copyDictionary(source: any): any
	local target = {}
	if source == nil then
		return target
	end

	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] = copyDictionary(value)
		else
			target[key] = value
		end
	end

	return target
end

local function addResources(target: any, delta: any)
	for resource, amount in pairs(delta or {}) do
		target[resource] = math.max(0, (target[resource] or 0) + amount)
	end
end

function Economy.CopyDictionary(source: any): any
	return copyDictionary(source)
end

function Economy.CreateStartingResources(civilizationId: string?): any
	local resources = copyDictionary(Config.StartingResources)
	local civilizations = DataRegistry.GetDataSet("civilizations")
	local civilization = civilizations[civilizationId or Config.DefaultCivilization]

	if civilization and civilization.startingResources then
		addResources(resources, civilization.startingResources)
	end

	return resources
end

function Economy.GetLevelDefinition(building: any, level: number): any?
	for _, levelDefinition in ipairs(building.levels or {}) do
		if levelDefinition.level == level then
			return levelDefinition
		end
	end

	return nil
end

function Economy.GetCivilizationBonus(state: any, statName: string): number
	local civilizations = DataRegistry.GetDataSet("civilizations")
	local civilization = civilizations[state.civilizationId]

	if civilization == nil then
		return 0
	end

	local amount = 0
	for _, bonus in ipairs(civilization.bonuses or {}) do
		if bonus.stat == statName then
			amount += bonus.amount
		end
	end

	return amount
end

function Economy.CanAfford(resources: any, cost: any): boolean
	for resource, amount in pairs(cost or {}) do
		if (resources[resource] or 0) < amount then
			return false
		end
	end

	return true
end

function Economy.Spend(resources: any, cost: any): boolean
	if not Economy.CanAfford(resources, cost) then
		return false
	end

	for resource, amount in pairs(cost or {}) do
		resources[resource] = (resources[resource] or 0) - amount
	end

	return true
end

function Economy.AddResources(resources: any, rewards: any): ()
	addResources(resources, rewards)
end

function Economy.CalculateProductionPerMinute(state: any): any
	local buildings = DataRegistry.GetDataSet("buildings")
	local production = {}

	for buildingId, level in pairs(state.buildings or {}) do
		local building = buildings[buildingId]
		if building and building.production then
			local levelDefinition = Economy.GetLevelDefinition(building, level)
			if levelDefinition and levelDefinition.productionPerMinute then
				local resource = building.production.resource
				local statName = resource .. "Production"
				local multiplier = 1 + Economy.GetCivilizationBonus(state, statName)
				production[resource] = (production[resource] or 0) + (levelDefinition.productionPerMinute * multiplier)
			end
		end
	end

	return production
end

function Economy.ApplyProductionTick(state: any, deltaSeconds: number): any
	local production = Economy.CalculateProductionPerMinute(state)
	local gains = {}

	for resource, perMinute in pairs(production) do
		local amount = math.floor((perMinute * deltaSeconds / 60) + 0.5)
		if amount > 0 then
			state.resources[resource] = (state.resources[resource] or 0) + amount
			gains[resource] = amount
		end
	end

	state.lastTick = os.time()
	return gains
end

function Economy.ScaleCost(cost: any, amount: number): any
	local scaled = {}
	for resource, value in pairs(cost or {}) do
		scaled[resource] = value * amount
	end

	return scaled
end

return Economy
