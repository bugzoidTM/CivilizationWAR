--!strict

local CityService = {}

function CityService.GetPowerSummary(state: any): any
	local buildingPower = 0
	local troopCount = 0

	for _, level in pairs(state.buildings or {}) do
		buildingPower += level * 35
	end

	for _, amount in pairs(state.troops or {}) do
		troopCount += amount
	end

	return {
		buildingPower = buildingPower,
		troopCount = troopCount,
		total = buildingPower + (troopCount * 8),
	}
end

return CityService
