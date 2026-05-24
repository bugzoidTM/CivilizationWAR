--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("CivilizationWar"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local DataRegistry = require(Shared:WaitForChild("DataRegistry"))

local NPCService = {}

local function getRoot(): Instance?
	return Workspace:FindFirstChild(Config.GameName)
end

function NPCService.ConnectPrompts(options: any): ()
	local root = getRoot()
	if root == nil then
		warn("CivilizationWAR world is not built yet.")
		return
	end

	local dialogues = DataRegistry.GetDataSet("dialogues")

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and not descendant:GetAttribute("CivilizationWARConnected") then
			descendant:SetAttribute("CivilizationWARConnected", true)

			local kind = descendant:GetAttribute("PromptKind")
			if kind == "Dialogue" then
				descendant.Triggered:Connect(function(player: Player)
					local dialogueId = descendant:GetAttribute("DialogueId")
					local dialogue = dialogueId and dialogues[dialogueId]
					if dialogue and options.onDialogue then
						options.onDialogue(player, dialogue)
					end
				end)
			elseif kind == "Attack" then
				descendant.Triggered:Connect(function(player: Player)
					local enemyId = descendant:GetAttribute("EnemyId")
					if enemyId and options.onAttack then
						options.onAttack(player, enemyId)
					end
				end)
			end
		end
	end
end

return NPCService
