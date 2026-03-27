
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

local hideWQTTextAndIcon = function(pin)
	pin.Display.WQTGlow:Hide()
	pin.Display.WQTIcon:Hide()
	pin.Display.WQTText:Hide()
end

function WorldQuestTracker.UpdateQuestIdentification(self, event)
	if (not WorldQuestTracker.db.profile.numerate_quests) then
		return
	end

	local map = WorldQuestTrackerDataProvider:GetMap()

	do
		--world map quest log, reset widgets
		local questContents = WorldMapFrame.QuestLog.QuestsFrame.Contents or WorldMapFrame.QuestLog.QuestsFrame.ScrollFrame.Contents
		local children = {questContents:GetChildren()}
		for i = 1, #children do
			local child = children[i]
			if (child.Display) then
				child.Display.Icon:Show()
				if (child.Display.WQTText) then
					child.Display.WQTText:Hide()
				end
			end
		end
	end

	local questIndex = 1

	--world map quest pins, reset widgets and build a table with the quest pins
	local questsOnMapFound = {}
	for pin in map:EnumeratePinsByTemplate("QuestPinTemplate") do
		local questId = pin:GetQuestID()
		if (questId) then
			if (pin.Display) then
				pin.Display.Icon:Show()
				if (pin.Display.WQTText) then
					pin.Display.WQTText:Hide()
				end
			end

			if (pin.style ~= POIButtonUtil.Style.QuestComplete) then
				--get the quest name
				local questTitle = C_QuestLog.GetTitleForQuestID(questId)
				questsOnMapFound[#questsOnMapFound+1] = {questId = questId, pin = pin, questName = questTitle}
			end
		end
	end

	table.sort(questsOnMapFound, function(t1, t2) return t1.questName < t2.questName end)

	local bFoundQuestsOnMap = #questsOnMapFound > 0

	local questsOnTrackerFound = {}
	local questsOnTrackerQuestId_to_Info = {}

    for moduleFrame in pairs (ObjectiveTrackerManager.moduleToContainerMap) do
		if (type(moduleFrame) == "table" and moduleFrame.GetObjectType and moduleFrame:GetObjectType() == "Frame" and moduleFrame:IsShown()) then
			local contentsFrame = moduleFrame.ContentsFrame
        	local children = {contentsFrame:GetChildren()}

			local bHasOneChildren = #children == 1
			local bModuleIsCampaing = moduleFrame == CampaignQuestObjectiveTracker

			for i = 1, #children do
				local child = children[i]
				local poiButton = child.poiButton

				--reset the wqt text
				if (poiButton and poiButton.Display) then
					poiButton.Display.Icon:Show()
					if (poiButton.Display.WQTText) then
						poiButton.Display.WQTText:Hide()
					end
				end

				if (poiButton and child.poiQuestID and child.poiQuestID > 0 and not child.poiIsComplete) then
					local questId = child.poiQuestID
					local questTitle = C_QuestLog.GetTitleForQuestID(questId)

					questsOnTrackerFound[#questsOnTrackerFound+1] = {questId = questId, questName = questTitle, child = child, poiButton = child.poiButton}
					questsOnTrackerQuestId_to_Info[questId] = questsOnTrackerFound[#questsOnTrackerFound]

					if (bModuleIsCampaing and bHasOneChildren) then
						local playerLevel = UnitLevel("player")
						if (playerLevel < 80) then
							QuestUtil.TrackWorldQuest(questId, Enum.QuestWatchType.Automatic)
							C_SuperTrack.SetSuperTrackedQuestID(questId)
						end
					end

					if (not poiButton) then
						local parent = WorldMapFrame.QuestLog.QuestsFrame.Contents
						local parentChilds = {parent:GetChildren()}
						for j = 1, #parentChilds do
							if (parentChilds[j].shouldShowGlow and parentChilds[j].questID == child.questID) then
								poiButton = parentChilds[j]
							end
						end
					end

					if (poiButton) then
						poiButton.Display.Icon:Show()

						if (not poiButton.Display.WQTText) then
							WorldQuestTracker.CreateTextAndIconForQuest(poiButton, 1, 0)
						else
							poiButton.Display.WQTText:Hide()
							poiButton.Display.WQTIcon:Hide()
						end

						hideWQTTextAndIcon(poiButton)

						if (not bFoundQuestsOnMap and not child.poiIsComplete) then
							local iconFound = WorldQuestTracker.SetIconForQuest(poiButton)

							if not iconFound then
								poiButton.Display.Icon:Hide()
								poiButton.Display.WQTText:Show()
								poiButton.Display.WQTText:SetText(questIndex)
							end

							questIndex = questIndex + 1
						end
					end
				end
			end
		end
    end

	for i = 1, #questsOnMapFound do
		local questId = questsOnMapFound[i].questId
		local pin = questsOnMapFound[i].pin

		--world map
		if (not pin.Display.WQTText) then
			WorldQuestTracker.CreateTextAndIconForQuest(pin, zoneMap_EnumerationXOffset)
		end

		hideWQTTextAndIcon(pin)

		local iconFound = WorldQuestTracker.SetIconForQuest(pin)
		if not iconFound then
			pin.Display.Icon:Hide()
			pin.Display.WQTText:SetText(i)
			pin.Display.WQTText:Show()
			pin.Display.WQTIcon:Hide()
		end

		local trackerFrame = questsOnTrackerQuestId_to_Info[questId]
		if (trackerFrame) then
			local poiButton = trackerFrame.poiButton
			if (poiButton) then
				--quest tracker
				if (not poiButton.Display.WQTText) then
					WorldQuestTracker.CreateTextAndIconForQuest(poiButton, questTracker_EnumerationXOffset)
				end

				if not iconFound then
					iconFound = WorldQuestTracker.SetIconForQuest(poiButton)
					if not iconFound then
						poiButton.Display.Icon:Hide()
						poiButton.Display.WQTText:SetText(i)
						poiButton.Display.WQTText:Show()
						poiButton.Display.WQTIcon:Hide()
					end
				end
			end
		end

		--quest log on map
		local questContents = WorldMapFrame.QuestLog.QuestsFrame.Contents or WorldMapFrame.QuestLog.QuestsFrame.ScrollFrame.Contents
		local button = questContents:FindButtonByQuestID(questId)

		if (button) then
			if (not button.Display.WQTText) then
				WorldQuestTracker.CreateTextAndIconForQuest(button, 1, 0)
			end

			if not iconFound then
				iconFound = WorldQuestTracker.SetIconForQuest(button)
				if not iconFound then
					button.Display.Icon:Hide()
					button.Display.WQTText:SetText(i)
					button.Display.WQTText:Show()
					button.Display.WQTIcon:Hide()
				end
			end
		end

		questIndex = questIndex + 1
	end
end

local c = CreateFrame("frame")
c:RegisterEvent("QUEST_LOG_UPDATE")
c:SetScript("OnEvent", function()
	C_Timer.After(0, WorldQuestTracker.UpdateQuestIdentification)
end)