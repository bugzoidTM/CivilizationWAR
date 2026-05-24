--!strict

local DataRegistry = require(script.Parent.DataRegistry)

local CombatResolver = {}

local function clamp(value: number, minValue: number, maxValue: number): number
	return math.max(minValue, math.min(maxValue, value))
end

local function listContains(list: any, value: string): boolean
	for _, item in ipairs(list or {}) do
		if item == value then
			return true
		end
	end

	return false
end

local function armyPower(army: any, opposingArmy: any): number
	local troops = DataRegistry.GetDataSet("troops")
	local total = 0

	for troopId, count in pairs(army or {}) do
		local troop = troops[troopId]
		if troop and count > 0 then
			local base = (troop.attack * 2.0) + (troop.defense * 1.25) + (troop.health * 0.45) + (troop.carry * 0.1)
			local counterMultiplier = 1

			for opposingTroopId in pairs(opposingArmy or {}) do
				local opposingTroop = troops[opposingTroopId]
				if
					listContains(troop.counters, opposingTroopId)
					or (opposingTroop and listContains(troop.counters, opposingTroop.category))
				then
					counterMultiplier += 0.08
				end
			end

			total += base * count * counterMultiplier
		end
	end

	return total
end

local function calculateLosses(army: any, lossRate: number): any
	local losses = {}
	local remaining = {}

	for troopId, count in pairs(army or {}) do
		local lost = math.floor((count * lossRate) + 0.5)
		lost = clamp(lost, 0, count)
		losses[troopId] = lost
		remaining[troopId] = math.max(0, count - lost)
	end

	return losses, remaining
end

function CombatResolver.CalculateArmyPower(army: any, opposingArmy: any?): number
	return armyPower(army, opposingArmy or {})
end

function CombatResolver.ResolveBattle(attackerArmy: any, defenderArmy: any, rewardTable: any?): any
	local attackerPower = armyPower(attackerArmy, defenderArmy)
	local defenderPower = armyPower(defenderArmy, attackerArmy)
	local totalPower = math.max(1, attackerPower + defenderPower)
	local ratio = attackerPower / math.max(1, defenderPower)
	local attackerWon = ratio >= 0.92

	local attackerLossRate = clamp((defenderPower / totalPower) * 0.58, 0.04, 0.82)
	local defenderLossRate = clamp((attackerPower / totalPower) * 0.72, 0.08, 0.95)

	if not attackerWon then
		attackerLossRate = clamp(attackerLossRate + 0.22, 0.15, 0.94)
		defenderLossRate = clamp(defenderLossRate - 0.18, 0.03, 0.72)
	end

	local attackerLosses, remainingAttackers = calculateLosses(attackerArmy, attackerLossRate)
	local defenderLosses, remainingDefenders = calculateLosses(defenderArmy, defenderLossRate)

	return {
		attackerWon = attackerWon,
		attackerPower = math.floor(attackerPower),
		defenderPower = math.floor(defenderPower),
		ratio = ratio,
		attackerLosses = attackerLosses,
		defenderLosses = defenderLosses,
		remainingAttackers = remainingAttackers,
		remainingDefenders = remainingDefenders,
		rewards = attackerWon and (rewardTable or {}) or {},
	}
end

function CombatResolver.ResolveNpcBattle(attackerArmy: any, enemyId: string): any
	local enemies = DataRegistry.GetDataSet("enemies")
	local enemy = enemies[enemyId]
	assert(enemy ~= nil, `Missing enemy definition: {enemyId}`)

	local report = CombatResolver.ResolveBattle(attackerArmy, enemy.army, enemy.rewards)
	report.enemyId = enemyId
	report.enemyName = enemy.displayName
	report.enemyLevel = enemy.level

	return report
end

return CombatResolver
