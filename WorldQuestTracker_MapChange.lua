
local addonId, wqtInternal = ...
local _

--world quest tracker object
local WorldQuestTracker = WorldQuestTrackerAddon
if (not WorldQuestTracker) then
	return
end

local GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID or C_TaskQuest.GetQuestsOnMap

--framework
---@type detailsframework
local DF = _G ["DetailsFramework"]
if (not DF) then
	print("|cFFFFAA00World Quest Tracker: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

--localization
local L = DF.Language.GetLanguageTable(addonId)

local check_for_quests_on_unknown_map = function()
	local mapID = WorldMapFrame.mapID

	if (not WorldQuestTracker.MapData.WorldQuestZones[mapID] and not WorldQuestTracker.IsWorldQuestHub(mapID)) then
		local taskInfo = GetQuestsForPlayerByMapID(mapID, mapID)
		if (taskInfo and #taskInfo > 0) then
			--> there's quests on this map
			WorldQuestTracker.MapData.WorldQuestZones[mapID] = true
			WorldQuestTracker.OnMapHasChanged(WorldMapFrame)
		end
	end
end

WorldQuestTracker.OnMapHasChanged = function(self)
	WorldQuestTracker.AdjustThatThingInTheBottomLeftCorner()

	WorldQuestTrackerDataProvider:GetMap():RemoveAllPinsByTemplate("WorldQuestTrackerPOIPinTemplate")
	WorldQuestTracker.HideAllPOIPins()

	local mapID = WorldMapFrame.mapID
	WorldQuestTracker.InitializeWorldWidgets()

	--set the current map in the addon
	WorldQuestTracker.LastMapID = WorldQuestTracker.CurrentMapID
	WorldQuestTracker.MapChangedTime = time()
	WorldQuestTracker.CurrentMapID = mapID

	--update the status bar
	WorldQuestTracker.RefreshStatusBarVisibility()

	--check if quest summary is shown and if can hide it
	if (WorldQuestTracker.QuestSummaryShown and not WorldQuestTracker.CanShowZoneSummaryFrame()) then
		WorldQuestTracker.ClearZoneSummaryButtons()
	end

	--cancel an update scheduled for the world map if any
	if (WorldQuestTracker.ScheduledWorldUpdate and not WorldQuestTracker.ScheduledWorldUpdate._cancelled) then
		WorldQuestTracker.ScheduledWorldUpdate:Cancel()
	end

	if (WorldQuestTracker.WorldMap_GoldIndicator) then
		WorldQuestTracker.WorldMap_GoldIndicator.text = "0"
		WorldQuestTracker.WorldMap_ResourceIndicator.text = "0"
		WorldQuestTracker.WorldMap_APowerIndicator.text = "0"
		WorldQuestTracker.WorldMap_PetIndicator.text = "0"
	end

	--> clear custom map pins
	local map = WorldQuestTrackerDataProvider:GetMap()

	for pin in map:EnumeratePinsByTemplate("WorldQuestTrackerRarePinTemplate") do
		pin.RareWidget:Hide()
		map:RemovePin(pin)
	end

	for pin in map:EnumeratePinsByTemplate("WorldQuestTrackerWorldMapPinTemplate") do
		map:RemovePin(pin)
		if (pin.Child) then
			pin.Child:Hide()
		end
	end

	if (not WorldQuestTracker.MapData.WorldQuestZones[mapID] and not WorldQuestTracker.IsWorldQuestHub(mapID)) then
		C_Timer.After(0.5, check_for_quests_on_unknown_map)
	end

	WorldQuestTracker.UpdateExtraMapTextures()

	--is the map a zone map with world quests?
	if (WorldQuestTracker.MapData.WorldQuestZones[mapID]) then
		--hide the toggle world quests button
		if (WorldQuestTracker.ToggleQuestsSummaryButton) then
			WorldQuestTracker.ToggleQuestsSummaryButton:Hide()
		end

		--update widgets
		WorldQuestTracker.UpdateZoneWidgets(true)

		--hide world quest
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
	else
		--the world map is not a zone map with world quests, is it a hub map?
		--is zone widgets shown?
		if (WorldQuestTracker.ZoneWidgetPool[1] and WorldQuestTracker.ZoneWidgetPool[1]:IsShown()) then
			--hide zone widgets
			WorldQuestTracker.HideZoneWidgets()
		end

		--check if is a hub map
		if (WorldQuestTracker.IsWorldQuestHub(mapID)) then
			--show the toggle world quests button
			if (WorldQuestTracker.ToggleQuestsSummaryButton) then
				WorldQuestTracker.ToggleQuestsSummaryButton:Show()
			end

			--is there at least one world widget created?
			if (WorldQuestTracker.WorldMapFrameSummarySquareReference) then
				if (not WorldQuestTracker.WorldMapFrameSummarySquareReference:IsShown() or WorldQuestTracker.LatestQuestHub ~= WorldQuestTracker.CurrentMapID) then
					WorldQuestTracker.LatestQuestHub = WorldQuestTracker.CurrentMapID
					WorldQuestTracker.ShowWorldQuestPinsOnNextFrame()
				end
			end
		else
			WorldQuestTracker.HideWorldQuestsOnWorldMap()
		end
	end

	--if the blacklist quest panel is opened, refresh it
	local WorldQuestTrackerBanPanel = WorldQuestTrackerBanPanel
	if (WorldQuestTrackerBanPanel) then
		if (WorldQuestTrackerBanPanel:IsShown()) then
			if (WorldQuestTracker.GetCurrentZoneType() == "world") then
				C_Timer.After(.5, WorldQuestTrackerBanPanel.UpdateQuestList)
				C_Timer.After(1.5, WorldQuestTrackerBanPanel.UpdateQuestList)
				C_Timer.After(2.5, WorldQuestTrackerBanPanel.UpdateQuestList)

			elseif (WorldQuestTracker.GetCurrentZoneType() == "zone") then
				C_Timer.After(.5, WorldQuestTrackerBanPanel.UpdateQuestList)
				C_Timer.After(1.5, WorldQuestTrackerBanPanel.UpdateQuestList)
			end
		end
	end

	C_Timer.After(0.05, function()
		if (C_QuestLog.HasActiveThreats() and WorldQuestTracker.DoubleTapFrame) then
			--this was the place where the nzoth invasion botton left button has modified
		end
	end)

	DF.Schedules.RunNextTick(WorldQuestTracker.UpdateQuestIdentification)
end

hooksecurefunc(WorldMapFrame, "OnMapChanged", WorldQuestTracker.OnMapHasChanged)