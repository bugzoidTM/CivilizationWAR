--!strict

local GeneratedContent = require(script.Parent.GeneratedContent)

local AssetRegistry = {}

local FALLBACK_IMAGE = ""

local function getManifest(): any
	local assetsRoot = GeneratedContent.assets
	if assetsRoot == nil or assetsRoot.image_manifest == nil then
		return { assets = {} }
	end

	return assetsRoot.image_manifest
end

function AssetRegistry.GetImage(assetId: string): string
	local manifest = getManifest()
	local asset = manifest.assets and manifest.assets[assetId]
	if asset == nil or asset.robloxAssetId == nil or asset.robloxAssetId == "" then
		return FALLBACK_IMAGE
	end

	return asset.robloxAssetId
end

function AssetRegistry.GetPrompt(assetId: string): string?
	local manifest = getManifest()
	local asset = manifest.assets and manifest.assets[assetId]
	if asset == nil then
		return nil
	end

	local style = manifest.style or ""
	local prompt = asset.prompt or ""
	if style == "" then
		return prompt
	end

	return prompt .. ", " .. style
end

function AssetRegistry.ListByCategory(category: string): { string }
	local manifest = getManifest()
	local ids = {}

	for assetId, asset in pairs(manifest.assets or {}) do
		if asset.category == category then
			table.insert(ids, assetId)
		end
	end

	table.sort(ids)
	return ids
end

function AssetRegistry.CountReadyImages(): number
	local manifest = getManifest()
	local total = 0

	for _, asset in pairs(manifest.assets or {}) do
		if asset.robloxAssetId ~= nil and asset.robloxAssetId ~= "" then
			total += 1
		end
	end

	return total
end

return AssetRegistry
