
local addonId, wqtInternal = ...

--world quest tracker object
local WorldQuestTracker = WorldQuestTrackerAddon
if (not WorldQuestTracker) then
	return
end

--framework
local detailsFramework = _G ["DetailsFramework"]
if (not detailsFramework) then
	print("|cFFFFAA00World Quest Tracker: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

--localization
local L = detailsFramework.Language.GetLanguageTable(addonId)

local questDifficultyColors = {
    [0] = {0.3, 1, 0, 1}, --green
    [1] = {1, 1, 0, 1}, --yellow
    [2] = {1, 0.15, 0, 1}, --red
}

local questDifficultyIds = {
    [91261] = 2, -- nightmare
    [91233] = 2, -- nightmare
    [91256] = 2, -- nightmare
    [91225] = 2, -- nightmare
    [91245] = 1, -- hard
    [91240] = 1, -- hard
    [91121] = 0, -- normal
    [91107] = 0, -- normal
}

local f = CreateFrame("frame")
f:RegisterEvent("ADVENTURE_MAP_OPEN")
f:SetScript("OnEvent", function(self, event, ...)
    if CovenantMissionFrame and false then
        C_Timer.After(0.7, function()
            if CovenantMissionFrame:IsShown() then
                local children = {CovenantMissionFrame.MapTab.ScrollContainer.Child:GetChildren()}
                for i = 1, #children do
                    local child = children[i]
                    if child and child.Icon and child.IconHighlight and child.Icon:GetAtlas() == "AdventureMapIcon-DailyQuest" then
                        local questID = child.questID
                        local pinTemplate = child.pinTemplate

                        if pinTemplate == "AdventureMap_QuestOfferPinTemplate" then
                            local questDiff = questDifficultyIds[questID] or 0
                            if not questDiff then
                                if child.description:find("Nightmare") then
                                    questDiff = 2
                                elseif child.description:find("Hard") then
                                    questDiff = 1
                                elseif child.description:find("Normal") then
                                    questDiff = 0
                                end
                            end

                            if questDiff then
                                local color = questDifficultyColors[questDiff]
                                child.Icon:SetTexture([[Interface\AddOns\WorldQuestTracker\media\quest_repeat.png]])
                                child.Icon:SetVertexColor(color[1], color[2], color[3], color[4])
                            end
                        end
                    end
                end
            end
        end)
    end
end)