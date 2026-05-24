--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("CivilizationWar"):WaitForChild("Shared")
local Economy = require(Shared:WaitForChild("Economy"))
local DataRegistry = require(Shared:WaitForChild("DataRegistry"))

local EconomyService = {}

function EconomyService.CalculateProductionPerMinute(state: any): any
	return Economy.CalculateProductionPerMinute(state)
end

function EconomyService.GetMissingResources(resources: any, cost: any): any
	local missing = {}

	for resource, amount in pairs(cost or {}) do
		local available = resources and (resources[resource] or 0) or 0
		if available < amount then
			missing[resource] = amount - available
		end
	end

	return missing
end

function EconomyService.HasMissingResources(missing: any): boolean
	return next(missing or {}) ~= nil
end

function EconomyService.CanAfford(resources: any, cost: any): boolean
	return Economy.CanAfford(resources, cost)
end

function EconomyService.Spend(resources: any, cost: any): boolean
	return Economy.Spend(resources, cost)
end

function EconomyService.AddResources(resources: any, rewards: any): ()
	Economy.AddResources(resources, rewards)
end

function EconomyService.ApplyProduction(state: any, deltaSeconds: number, now: number?): any
	local production = EconomyService.CalculateProductionPerMinute(state)
	local gains = {}

	for resource, perMinute in pairs(production) do
		local amount = math.floor((perMinute * deltaSeconds / 60) + 0.5)
		if amount > 0 then
			state.resources[resource] = (state.resources[resource] or 0) + amount
			gains[resource] = amount
		end
	end

	state.lastTick = now or os.time()
	return gains
end

function EconomyService.ApplyOfflineProduction(state: any, elapsedSeconds: number, maxSeconds: number, now: number): any
	local cappedSeconds = math.max(0, math.min(elapsedSeconds, maxSeconds))
	local gains = EconomyService.ApplyProduction(state, cappedSeconds, now)

	state.lastOfflineGains = {
		seconds = cappedSeconds,
		resources = gains,
	}

	return state.lastOfflineGains
end

function EconomyService.FormatResources(resources: any): string
	local names = {
		food = "Comida",
		wood = "Madeira",
		stone = "Pedra",
		iron = "Ferro",
		silver = "Prata",
		gold = "Ouro",
	}
	local parts = {}

	for _, resource in ipairs(DataRegistry.GetResourceOrder()) do
		local amount = resources and resources[resource]
		if amount and amount > 0 then
			table.insert(parts, `{names[resource] or resource} {math.floor(amount)}`)
		end
	end

	if #parts == 0 then
		return "nenhum"
	end

	return table.concat(parts, ", ")
end

return EconomyService
