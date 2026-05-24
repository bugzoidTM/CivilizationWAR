--!strict

local Config = {
	GameName = "CivilizationWAR",
	Version = "0.1.0",
	DefaultCivilization = "rome",
	EntryMissionId = "m001_raise_the_keep",
	EntryMapId = "starter_valley",
	ResourceTickSeconds = 5,
	ManualCollectCooldownSeconds = 20,
	MaxConstructionQueue = 2,
	DataStoreName = "CivilizationWAR_PlayerState_v1",
	AutoSaveIntervalSeconds = 60,
	MaxOfflineSeconds = 8 * 60 * 60,
	StartingResources = {
		food = 1200,
		wood = 1100,
		stone = 620,
		iron = 260,
		silver = 120,
		gold = 25,
	},
	StartingBuildings = {
		castle = 1,
	},
	StartingTroops = {
		swordsman = 24,
		archer = 10,
	},
}

return Config
