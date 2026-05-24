--!strict

local MarchService = {}

local playerStateService: any = nil

function MarchService.Configure(options: any): ()
	playerStateService = options.playerStateService
end

function MarchService.AttackNpc(player: Player, enemyId: string): any
	assert(playerStateService ~= nil, "MarchService was not configured")
	return playerStateService.AttackNpc(player, enemyId)
end

return MarchService
