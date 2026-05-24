--!strict

local WorldConfig = {
	GridSize = 64,
	TileSize = 4,
	Origin = Vector3.new(-128, 0.6, -128),
	PlayerCastle = {
		id = "player_castle",
		name = "Castelo do Comandante",
		x = 32,
		y = 32,
		level = 1,
	},
	ResourceNodes = {
		{ id = "wood_01", name = "Bosque de Madeira", resource = "wood", x = 25, y = 31, level = 1, amount = 900 },
		{ id = "food_01", name = "Campos de Trigo", resource = "food", x = 37, y = 29, level = 1, amount = 1000 },
		{ id = "stone_01", name = "Pedreira Baixa", resource = "stone", x = 20, y = 43, level = 2, amount = 1200 },
		{ id = "iron_01", name = "Veio de Ferro", resource = "iron", x = 45, y = 42, level = 2, amount = 800 },
	},
	NpcCamps = {
		{
			id = "camp_bandit_scouts_01",
			name = "Batedores Bandidos",
			enemyId = "bandit_scouts",
			x = 32,
			y = 21,
			level = 1,
		},
		{
			id = "camp_rebel_raiders_01",
			name = "Saqueadores Rebeldes",
			enemyId = "rebel_raiders",
			x = 43,
			y = 24,
			level = 2,
		},
	},
	BiomeColors = {
		plains = Color3.fromRGB(92, 140, 86),
		forest = Color3.fromRGB(50, 111, 68),
		mountain = Color3.fromRGB(108, 113, 118),
	},
}

function WorldConfig.GetBiome(x: number, y: number): string
	if x < 15 or y > 48 or (x < 25 and y > 38) then
		return "mountain"
	elseif (x > 41 and y < 38) or (x < 29 and y < 29) then
		return "forest"
	end

	return "plains"
end

function WorldConfig.GetTilePosition(x: number, y: number): Vector3
	return WorldConfig.Origin + Vector3.new((x - 0.5) * WorldConfig.TileSize, 0, (y - 0.5) * WorldConfig.TileSize)
end

return WorldConfig
