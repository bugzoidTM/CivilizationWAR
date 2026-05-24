--!strict

local GeneratedContent = require(script.Parent.GeneratedContent)

local DataRegistry = {}

DataRegistry.Content = GeneratedContent

function DataRegistry.GetDataSet(name: string): any
	local data = GeneratedContent.data
	assert(data ~= nil, "Generated content is missing data/")

	local value = data[name]
	assert(value ~= nil, `Missing content data set: {name}`)

	return value
end

function DataRegistry.GetMap(mapId: string): any
	local maps = GeneratedContent.maps
	assert(maps ~= nil, "Generated content is missing maps/")

	local map = maps[mapId]
	assert(map ~= nil, `Missing map blueprint: {mapId}`)

	return map
end

function DataRegistry.GetPrefab(prefabId: string): any
	local models = GeneratedContent.models
	assert(models ~= nil and models.building_prefabs ~= nil, "Generated content is missing model prefabs")

	local prefab = models.building_prefabs[prefabId]
	assert(prefab ~= nil, `Missing model prefab: {prefabId}`)

	return prefab
end

function DataRegistry.GetResourceOrder(): { string }
	return { "food", "wood", "stone", "iron", "silver", "gold" }
end

function DataRegistry.ListIds(dictionary: any): { string }
	local ids = {}
	for id in pairs(dictionary) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

return DataRegistry
