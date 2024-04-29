--sort when showing by zone
--faction buttons are hidding when summary hide()

-- ~review

local addonId, wqtInternal = ...

--world quest tracker object
local WorldQuestTracker = WorldQuestTrackerAddon
if (not WorldQuestTracker) then
	return
end

--framework
local DF = _G ["DetailsFramework"]
if (not DF) then
	print("|cFFFFAA00World Quest Tracker: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

--localization
local L = DF.Language.GetLanguageTable(addonId)

local ff = WorldQuestTrackerFinderFrame

local anchorFrame = WorldMapFrame.ScrollContainer
local worldFramePOIs = WorldQuestTrackerWorldMapPOI

WorldQuestTracker.WorldSummary = CreateFrame("frame", "WorldQuestTrackerWorldSummaryFrame", anchorFrame, "BackdropTemplate")

local _
local isWorldQuest = QuestUtils_IsQuestWorldQuest
local GameCooltip = GameCooltip2

local LibWindow = LibStub("LibWindow-1.1")
if (not LibWindow) then
	print("|cFFFFAA00World Quest Tracker|r: libwindow not found, did you just updated the addon? try reopening the client.|r")
end

--on hover over an icon on the world map(possivle deprecated on 8.0)
hooksecurefunc("TaskPOI_OnEnter", function(self)
	WorldQuestTracker.CurrentHoverQuest = self.questID
	if (self.Texture and self.IsZoneQuestButton) then
		self.Texture:SetBlendMode("ADD")
	end
end)

--on leave the hover over of an icon in the world map(possivle deprecated on 8.0)
hooksecurefunc("TaskPOI_OnLeave", function(self)
	WorldQuestTracker.CurrentHoverQuest = nil
	if (self.Texture and self.IsZoneQuestButton) then
		self.Texture:SetBlendMode("BLEND")
	end
end)

--update the zone which the player are current placed(possivle deprecated on 8.0)
function WorldQuestTracker:UpdateCurrentStandingZone()
	if (WorldMapFrame:IsShown()) then
		return
	end

	if (WorldQuestTracker.ScheduledMapFrameShownCheck and not WorldQuestTracker.ScheduledMapFrameShownCheck._cancelled) then
		WorldQuestTracker.ScheduledMapFrameShownCheck:Cancel()
	end

	local mapID = WorldQuestTracker.GetCurrentMapAreaID()
	if (mapID == 1080 or mapID == 1072) then
		mapID = 1024
	end
	WorldMapFrame.currentStandingZone = mapID
	WorldQuestTracker:FullTrackerUpdate()
end

--i'm not sure what this is for
function WorldQuestTracker:WaitUntilWorldMapIsClose()
	if (WorldQuestTracker.ScheduledMapFrameShownCheck and not WorldQuestTracker.ScheduledMapFrameShownCheck._cancelled) then
		WorldQuestTracker.ScheduledMapFrameShownCheck:Cancel()
	end
	WorldQuestTracker.ScheduledMapFrameShownCheck = C_Timer.NewTicker(1, WorldQuestTracker.UpdateCurrentStandingZone)
end

local check_for_quests_on_unknown_map = function()
	local mapID = WorldMapFrame.mapID

	if (not WorldQuestTracker.MapData.WorldQuestZones [mapID] and not WorldQuestTracker.IsWorldQuestHub(mapID)) then
		local taskInfo = C_TaskQuest.GetQuestsForPlayerByMapID(mapID, mapID)
		if (taskInfo and #taskInfo > 0) then
			--> there's quests on this map
			WorldQuestTracker.MapData.WorldQuestZones [mapID] = true
			WorldQuestTracker.OnMapHasChanged(WorldMapFrame)
		end
	end

end

local add_checkmark_icon = function(isOptionEnabled, isMainMenu)
	if (isMainMenu) then
		if (isOptionEnabled) then
			GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
		else
			GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
		end
	else
		if (isOptionEnabled) then
			GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
		else
			GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
		end
	end
end

--~mapchange ~map change ~change map ~changemap
WorldQuestTracker.OnMapHasChanged = function(self)
	WorldQuestTracker.AdjustThatThingInTheBottomLeftCorner()

	local mapID = WorldMapFrame.mapID
	WorldQuestTracker.InitializeWorldWidgets()

	--set the current map in the addon
	WorldQuestTracker.LastMapID = WorldQuestTracker.CurrentMapID
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
		WorldQuestTracker.WorldMap_GoldIndicator.text = 0
		WorldQuestTracker.WorldMap_ResourceIndicator.text = 0
		WorldQuestTracker.WorldMap_APowerIndicator.text = 0
		WorldQuestTracker.WorldMap_PetIndicator.text = 0
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

	if (not WorldQuestTracker.MapData.WorldQuestZones [mapID] and not WorldQuestTracker.IsWorldQuestHub(mapID)) then
		C_Timer.After(0.5, check_for_quests_on_unknown_map)
	end

	WorldQuestTracker.UpdateExtraMapTextures()

	--is the map a zone map with world quests?
	if (WorldQuestTracker.MapData.WorldQuestZones [mapID]) then
		--hide the toggle world quests button
		if (WorldQuestTrackerToggleQuestsSummaryButton) then
			WorldQuestTrackerToggleQuestsSummaryButton:Hide()
		end

		--update widgets
		WorldQuestTracker.UpdateZoneWidgets(true)

		--hide world quest
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
	else
		--is zone widgets shown?
		if (WorldQuestTracker.ZoneWidgetPool[1] and WorldQuestTracker.ZoneWidgetPool[1]:IsShown()) then
			--hide zone widgets
			WorldQuestTracker.HideZoneWidgets()
		end

		--check if is a hub map
		if (WorldQuestTracker.IsWorldQuestHub(mapID)) then
			--show the toggle world quests button
			if (WorldQuestTrackerToggleQuestsSummaryButton) then
				WorldQuestTrackerToggleQuestsSummaryButton:Show()
			end

			--is there at least one world widget created?
			if (WorldQuestTracker.WorldMapFrameReference) then
				if (not WorldQuestTracker.WorldMapFrameReference:IsShown() or WorldQuestTracker.LatestQuestHub ~= WorldQuestTracker.CurrentMapID) then
					WorldQuestTracker.LatestQuestHub = WorldQuestTracker.CurrentMapID
					WorldQuestTracker.DelayedShowWorldQuestPins()
					--WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
				end

			end
		else
			WorldQuestTracker.HideWorldQuestsOnWorldMap()
		end
	end

	--if the blacklist quest panel is opened, refresh it
	if (WorldQuestTrackerBanPanel) then
		if (WorldQuestTrackerBanPanel:IsShown()) then
			if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
				C_Timer.After(.5, WorldQuestTrackerBanPanel.UpdateQuestList)
				C_Timer.After(1.5, WorldQuestTrackerBanPanel.UpdateQuestList)
				C_Timer.After(2.5, WorldQuestTrackerBanPanel.UpdateQuestList)

			elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
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

end

hooksecurefunc(WorldMapFrame, "OnMapChanged", WorldQuestTracker.OnMapHasChanged)

-- default world quest pins from the map
hooksecurefunc(WorldMap_WorldQuestPinMixin, "RefreshVisuals", function(self)
	if (self.questID) then
		WorldQuestTracker.DefaultWorldQuestPin [self.questID] = self

		if (not WorldQuestTracker.ShowDefaultWorldQuestPin [self.questID]) then
			if (WorldQuestTracker.db.profile.zone_map_config.show_widgets) then
				self:Hide()
			end
		end
	end
end)

--OnTick
local OnUpdateDelay = .5
WorldMapFrame:HookScript("OnUpdate", function(self, deltaTime)

	-- todo: need to get the world map Pins from blizzard

	if (OnUpdateDelay < 0) then

		--todo: check if map locker is still viable in 8.0
		--[=[
		if (WorldQuestTracker.db.profile.map_lock and(GetCurrentMapContinent() == 8 or WorldQuestTracker.WorldQuestButton_Click+30 > GetTime())) then
			if (WorldQuestTracker.CanChangeMap) then
				WorldQuestTracker.CanChangeMap = nil
				WorldQuestTracker.LastMapID = WorldQuestTracker.GetCurrentMapAreaID()
			else
				if (WorldQuestTracker.LastMapID ~= WorldQuestTracker.GetCurrentMapAreaID() and WorldQuestTracker.LastMapID and not InCombatLockdown()) then
					WorldMapFrame:NavigateToMap(WorldQuestTracker.LastMapID)
					WorldQuestTracker.UpdateZoneWidgets()
				end
			end
		end
		--]=]

		--[=[

		--check the map type and show the world of zone widget if necessary

		--is there at least one world widget created?
		if (WorldQuestTracker.WorldMapFrameReference) then
			--current map is a quest hub
			if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
				if (not WorldQuestTracker.WorldMapFrameReference:IsShown()) then
					--WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
					WorldQuestTracker.DelayedShowWorldQuestPins()
				end
			else
				--current map is a zone, check if world widgets are shown
				if (WorldQuestTracker.WorldMapFrameReference:IsShown()) then
					--hide world widgets
					WorldQuestTracker.HideWorldQuestsOnWorldMap()
				end
			end
		end
		--]=]


		OnUpdateDelay = .5
	else
		OnUpdateDelay = OnUpdateDelay - deltaTime
	end
end)

-- ?
local currentMap
local deny_auto_switch = function()
	WorldQuestTracker.NoAutoSwitchToWorldMap = true
	currentMap = WorldQuestTracker.GetCurrentMapAreaID()
end

--apos o click, verifica se pode mostrar os widgets e permitir que o mapa seja alterado no proximo tick
local allow_map_change = function(...)
	if (currentMap == WorldQuestTracker.GetCurrentMapAreaID()) then
		WorldQuestTracker.CanShowWorldMapWidgets(true)
	else
		WorldQuestTracker.CanShowWorldMapWidgets(false)
	end
	WorldQuestTracker.CanChangeMap = true
	WorldQuestTracker.LastMapID = WorldQuestTracker.GetCurrentMapAreaID()
	WorldQuestTracker.UpdateZoneWidgets(true)

	if (not WorldQuestTracker.MapData.QuestHubs [WorldQuestTracker.LastMapID] and WorldQuestTracker.IsPlayingLoadAnimation()) then
		WorldQuestTracker.StopLoadingAnimation()
	end
end

-- 8.0 is this still applied? - argus button is nameless in 8.0
if (BrokenIslesArgusButton) then
	--> at the current PTR state, goes directly to argus map
	BrokenIslesArgusButton:HookScript("OnClick", function(self)
		if (not BrokenIslesArgusButton:IsProtected() and WorldQuestTracker.db.profile.rarescan.autosearch and WorldQuestTracker.db.profile.rarescan.add_from_premade and WorldQuestTracker.LastGFSearch + WorldQuestTracker.db.profile.rarescan.autosearch_cooldown < time()) then
			C_LFGList.Search(6, LFGListSearchPanel_ParseSearchTerms(""))
			WorldQuestTracker.LastGFSearch = time()
		end
		allow_map_change()
	end)
	--> argus map zone use an overlaied button for each of its three zones
	MacAreeButton:HookScript("OnClick", function(self)
		allow_map_change()
	end)
	AntoranWastesButton:HookScript("OnClick", function(self)
		allow_map_change()
	end)
	KrokuunButton:HookScript("OnClick", function(self)
		allow_map_change()
	end)
end

--8.0 doesnt work:

--WorldMapButton:HookScript("PreClick", deny_auto_switch)
--WorldMapButton:HookScript("PostClick", allow_map_change)


--[=[
hooksecurefunc("WorldMap_CreatePOI", function(index, isObjectIcon, atlasIcon)
	local POI = _G [ "WorldMapFramePOI"..index]
	if (POI) then
		POI:HookScript("PreClick", deny_auto_switch)
		POI:HookScript("PostClick", allow_map_change)
	end
end)
--]=]

--troca a fun��o de click dos bot�es de quest no mapa da zona
--[=[
hooksecurefunc("WorldMap_GetOrCreateTaskPOI", function(index)
	local button = _G ["WorldMapFrameTaskPOI" .. index]
	if (button:GetScript("OnClick") ~= WorldQuestTracker.OnQuestButtonClick) then
		--button:SetScript("OnClick", WorldQuestTracker.OnQuestButtonClick)
		table.insert(WorldQuestTracker.AllTaskPOIs, button)
	end
end)
--]=]


WorldMapActionButtonPressed = function()
	WorldQuestTracker.Temp_HideZoneWidgets = GetTime() + 5
	WorldQuestTracker.UpdateZoneWidgets(true)
	WorldQuestTracker.ScheduleZoneMapUpdate(6)
end
hooksecurefunc("ClickWorldMapActionButton", function()
	--WorldMapActionButtonPressed()
end)

WorldMapFrame:HookScript("OnHide", function()
	if (WorldQuestTracker.RefreshTrackerWidgets) then  --[string "@WorldQuestTracker/WorldQuestTracker_Core.lua"]:379: in function <WorldQuestTracker/WorldQuestTracker_Core.lua:378>
		C_Timer.After(0.2, WorldQuestTracker.RefreshTrackerWidgets) --2452x bad argument #2 to '?'(Usage: C_Timer.After(seconds, callback)) --WorldQuestTracker.RefreshTrackerWidgets is nil?
	end
end)

WorldQuestTracker.UpdateWorldMapFrameAnchor = function(resetLeft)
	if (WorldQuestTracker.db.profile.map_frame_anchor == "center") then
		if (not resetLeft) then
			WorldMapFrame:ClearAllPoints()
			WorldMapFrame:SetPoint("center", UIParent, "center", 100, 0)
		else
			C_Timer.After(0.1, function()
				WorldMapFrame:ClearAllPoints()
				WorldMapFrame:SetPoint("center", UIParent, "center", 100, 0)
			end)
		end

	elseif (WorldQuestTracker.db.profile.map_frame_anchor == "left" and resetLeft) then
		local mapID = WorldMapFrame.mapID
		ToggleWorldMap()
		C_Timer.After(0.03, function()
			OpenWorldMap(mapID)
		end)
	end
end

local defaultWorldMapScale
WorldQuestTracker.UpdateWorldMapFrameScale = function(reset)

	--this feature is having some problem in 8.1 retail -- ~review
	if (true) then
		return
	end

	if (WorldQuestTracker.db.profile.map_frame_scale_enabled) then
		--save the original scale if is the first time applying the modifier
		if (not defaultWorldMapScale) then
			defaultWorldMapScale = WorldMapFrame:GetScale()
		end

		--apply the scale modifier
		local scaleMod = WorldQuestTracker.db.profile.map_frame_scale_mod
		WorldMapFrame:SetScale(scaleMod)

	elseif (reset) then
		--if reset is called from the options menu, check if there's a default value saved and restore it
		if (defaultWorldMapScale) then
			WorldMapFrame:SetScale(defaultWorldMapScale)
		end
	end
end

-- ~toggle
local firstAnchorRun = true
WorldQuestTracker.OnToggleWorldMap = function(self)

	if (not WorldMapFrame:IsShown()) then
		--closed
		C_Timer.After(0.2, WorldQuestTracker.RefreshTrackerWidgets)
	else
		--opened
		C_Timer.After(0.2, WorldQuestTracker.RefreshStatusBarVisibility)
		WorldQuestTrackerAddon.CatchMapProvider(true)
		WorldQuestTracker.InitializeWorldWidgets()
	end

	WorldQuestTracker.IsLoaded = true

	WorldMapFrame.currentStandingZone = WorldQuestTracker.GetCurrentMapAreaID()

	if (WorldMapFrame:IsShown()) then
		WorldQuestTracker.MapSeason = WorldQuestTracker.MapSeason + 1
		WorldQuestTracker.MapOpenedAt = GetTime()

		if (WorldQuestTrackerBanPanel) then
			if (WorldQuestTrackerBanPanel:IsShown()) then
				C_Timer.After(1, WorldQuestTrackerBanPanel.UpdateQuestList)
			end
		end
	end

	WorldQuestTracker.lastMapTap = GetTime()

	WorldQuestTracker.LastMapID = WorldMapFrame.mapID

	if (WorldMapFrame:IsShown()) then
		--� a primeira vez que � mostrado?
		if (not WorldMapFrame.firstRun) then
			local currentMapId = WorldMapFrame.mapID

			WorldMapFrame.firstRun = true

			--> some addon is adding these words on the global namespace.
			--> I trully believe that it's not intended at all, so let's just clear.
			--> it is messing with the framework.
			_G ["left"] = nil
			_G ["right"] = nil
			_G ["topleft"] = nil
			_G ["topright"] = nil

			function WorldQuestTracker.OpenSharePanel()
				if (WorldQuestTrackerSharePanel) then
					WorldQuestTrackerSharePanel:Show()
					return
				end

				local f = DF:CreateSimplePanel(UIParent, 460, 90, "Discord Server", "WorldQuestTrackerSharePanel")
				f:SetFrameStrata("TOOLTIP")
				f:SetPoint("center", UIParent, "center", 0, 0)

				DF:CreateBorder(f)

				local LinkBox = DF:CreateTextEntry(f, function()end, 380, 20, "ExportLinkBox", _, _, DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
				LinkBox:SetPoint("center", f, "center", 0, -10)

				f:SetScript("OnShow", function()
					LinkBox:SetText(DF.AuthorInfo.Discord)
					C_Timer.After(1, function()
						LinkBox:SetFocus(true)
						LinkBox:HighlightText()
					end)
				end)

				f:Hide()
				f:Show()
			end

			function WorldQuestTracker.OpenQuestBanPanel()
				if (not WorldQuestTrackerBanPanel) then

					local config = {
						scroll_width = 480,
						scroll_height = 270,
						scroll_line_height = 18,
						scroll_lines = 14,
						backdrop_color = {.4, .4, .4, .2},
						backdrop_color_highlight = {.4, .4, .4, .6},
					}

					local f = DF:CreateSimplePanel(UIParent, config.scroll_width + 30, config.scroll_height + 30, "World Quest Tracker Quest Blacklist", "WorldQuestTrackerBanPanel")
					f:SetFrameStrata("DIALOG")
					f:SetPoint("center", UIParent, "center")

					DF:CreateBorder(f)

					local banQuestRefresh = function(self, questList, offset, totalLines)

						for i = 1, totalLines do
							local index = i + offset
							local data = questList [index]
							if (data) then
								local line = self:GetLine(i)
								if (line) then
									local questTitle, questID, factionID, alreadyBanned = unpack(data)

									line.name:SetText(questTitle)
									line.questIDLabel:SetText(questID)
									line.questID = questID
									line.icon:SetTexture(WorldQuestTracker.MapData.FactionIcons [factionID])

									line.removebutton.questID = questID
									line.addbutton.questID = questID

									if (alreadyBanned) then
										line.addbutton:Hide()
										line.removebutton:Show()
									else
										--not banned
										line.addbutton:Show()
										line.removebutton:Hide()
									end
								end
							end
						end
					end

					local banQuestScroll = DF:CreateScrollBox(f, "$parentBanQuestScroll", banQuestRefresh, {}, config.scroll_width, config.scroll_height, config.scroll_lines, config.scroll_line_height)
					DF:ReskinSlider(banQuestScroll)
					banQuestScroll:SetPoint("topleft", f, "topleft", 5, -25)

					local onclick_add_button = function(self)
						local questID = self.questID

						WorldQuestTracker.db.profile.banned_quests [questID] = true

						if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
							WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true, true, false, true)

						elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
							WorldQuestTracker.UpdateZoneWidgets(true)
						end

						f:UpdateQuestList()
					end

					local onclick_remove_button = function(self)
						local questID = self.questID
						WorldQuestTracker.db.profile.banned_quests [questID] = nil

						if (WorldMapFrame:IsShown()) then
							if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
								WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true, true, false, true)

							elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
								WorldQuestTracker.UpdateZoneWidgets(true)
							end
						end

						f:UpdateQuestList()
					end

					local highlightColor = {1, .2, .1}
					local line_onenter = function(self)
						self:SetBackdropColor(unpack(config.backdrop_color_highlight))

						if (self.questID) then
							if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
								WorldQuestTracker.HighlightOnWorldMap(self.questID, 1.3, highlightColor)

							elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
								WorldQuestTracker.HighlightOnZoneMap(self.questID, 1.3, highlightColor)
							end
						end
					end

					local line_onleave = function(self)
						self:SetBackdropColor(unpack(config.backdrop_color))
						WorldQuestTracker.HideMapQuestHighlight()
					end

					--create the scroll widgets
					local createLine = function(self, index)
						local line = CreateFrame("button", "$parentLine" .. index, self, "BackdropTemplate")
						line:SetPoint("topleft", self, "topleft", 1, -((index-1)*(config.scroll_line_height+1)) - 1)
						line:SetSize(config.scroll_width - 2, config.scroll_line_height)
						line:SetScript("OnEnter", line_onenter)
						line:SetScript("OnLeave", line_onleave)

						line:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
						line:SetBackdropColor(unpack(config.backdrop_color))

						local name = line:CreateFontString("$parentName", "overlay", "GameFontNormal")
						local questIDLabel = line:CreateFontString("$parentName", "overlay", "GameFontNormal")

						DF:SetFontSize(name, 10)
						DF:SetFontSize(questIDLabel, 10)

						local icon = line:CreateTexture("$parentIcon", "overlay")
						icon:SetSize(config.scroll_line_height - 2, config.scroll_line_height - 2)
						icon:SetTexCoord(.1, .9, .1, .9)

						local add_button = CreateFrame("button", "$parentRemoveButton", line, "UIPanelCloseButton")
						add_button:SetSize(21, 21)
						add_button:SetScript("OnClick", onclick_add_button)
						add_button:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
						add_button:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
						add_button:GetNormalTexture():SetDesaturated(true)
						add_button:GetPushedTexture():SetDesaturated(true)
						add_button:GetPushedTexture():ClearAllPoints()
						add_button:GetPushedTexture():SetPoint("center")
						add_button:GetPushedTexture():SetSize(18, 18)

						local remove_button = CreateFrame("button", "$parentRemoveButton", line, "UIPanelCloseButton")
						remove_button:SetSize(21, 21)
						remove_button:SetScript("OnClick", onclick_remove_button)
						remove_button:SetNormalTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
						remove_button:SetPushedTexture([[Interface\GLUES\LOGIN\Glues-CheckBox-Check]])
						remove_button:GetPushedTexture():ClearAllPoints()
						remove_button:GetPushedTexture():SetPoint("center")
						remove_button:GetPushedTexture():SetSize(18, 18)

						icon:SetPoint("left", line, "left", 2, 0)
						name:SetPoint("left", icon, "right", 4, 0)

						add_button:SetPoint("right", line, "right", -2, 0)
						remove_button:SetPoint("right", line, "right", -2, 0)
						questIDLabel:SetPoint("right", line, "right", -26, 0)

						line.icon = icon
						line.name = name
						line.questIDLabel = questIDLabel
						line.removebutton = remove_button
						line.addbutton = add_button

						return line
					end

					--create the scroll widgets
					for i = 1, config.scroll_lines do
						banQuestScroll:CreateLine(createLine, i)
					end

					--this build a list of quests and send it to the scroll
					function f:UpdateQuestList()

						--if this panel isn't shown, just quit, this can happen since some functions schedule a refresh on this frame
						if (not f:IsShown()) then
							return
						end

						local data = {}
						local alreadyAdded = {}
						local alreadyBanned = WorldQuestTracker.db.profile.banned_quests

						for questID, _ in pairs(WorldQuestTracker.db.profile.banned_quests) do
							if (not alreadyAdded [questID]) then
								local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData(questID)
								if (title) then
									table.insert(data, {title, questID, factionID, alreadyBanned [questID]})
									alreadyAdded [questID] = true
								end
							end
						end

						for _, questID in ipairs(WorldQuestTracker.Cache_ShownQuestOnZoneMap) do
							if (not alreadyAdded [questID]) then
								local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData(questID)
								if (title) then
									table.insert(data, {title, questID, factionID, alreadyBanned [questID]})
									alreadyAdded [questID] = true
								end
							end
						end

						for _, questButton in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
							local questID = questButton.questID
							if (questID) then
								if (not alreadyAdded [questID]) then
									local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData(questID)
									if (title) then
										table.insert(data, {title, questID, factionID, alreadyBanned [questID]})
										alreadyAdded [questID] = true
									end
								end
							end
						end

						for _, widget in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
							local questID = widget.questID
							if (questID) then
								if (not alreadyAdded [questID]) then
									local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData(questID)
									if (title) then
										table.insert(data, {title, questID, factionID, alreadyBanned [questID]})
										alreadyAdded [questID] = true
									end
								end
							end
						end
						banQuestScroll:SetData(data)
						banQuestScroll:Refresh()
					end
				end

				WorldQuestTrackerBanPanel:UpdateQuestList()
				WorldQuestTrackerBanPanel:Show()
			end

			--go to broken isles button ~worldquestbutton ~worldmapbutton ~worldbutton
			--create two world quest button, for alliance and horde

			local toggleButtonsAlpha = 0.75

			--user reported on this line "attempt to index a nil value": The following error message appears ONCE when opening the world map after logging in. It appears regardless of windowed or full screen world map. It does not appear again after closing and reopening the world map:
			--looks like ElvUI removes the highlight texture from the button
			local closeButtonHighlightTexture = WorldMapFrame.SidePanelToggle.CloseButton:GetHighlightTexture()
			if (closeButtonHighlightTexture) then
				closeButtonHighlightTexture:SetAlpha(toggleButtonsAlpha)
			end

			local openButtonHighlightTexture = WorldMapFrame.SidePanelToggle.OpenButton:GetHighlightTexture()
			if (openButtonHighlightTexture) then
				openButtonHighlightTexture:SetAlpha(toggleButtonsAlpha)
			end

			WorldMapFrame.SidePanelToggle.CloseButton:SetFrameLevel(anchorFrame:GetFrameLevel()+2)
			WorldMapFrame.SidePanelToggle.OpenButton:SetFrameLevel(anchorFrame:GetFrameLevel()+2)

			local navigateButtonsSize = {22, 30}
			local navigateButtonsbackdropColor = {.2, .2, .2, .7}
			local navigateButtonsBorderColor = {0, 0, .0, 1}
			local navigateButtonsBackdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1}

			--Alliance
			--[=[
				local AllianceWorldQuestButton = CreateFrame("button", "WorldQuestTrackerGoToAllianceButton", anchorFrame, "BackdropTemplate")
				AllianceWorldQuestButton:SetSize(unpack(navigateButtonsSize))
				AllianceWorldQuestButton:SetFrameLevel(WorldMapFrame.SidePanelToggle.CloseButton:GetFrameLevel())

				AllianceWorldQuestButton:SetBackdrop(navigateButtonsBackdrop)
				AllianceWorldQuestButton:SetBackdropBorderColor(unpack(navigateButtonsBorderColor))
				AllianceWorldQuestButton:SetBackdropColor(unpack(navigateButtonsbackdropColor))

				AllianceWorldQuestButton:SetNormalTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])
				AllianceWorldQuestButton:SetPushedTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])

				AllianceWorldQuestButton:GetNormalTexture():ClearAllPoints()
				AllianceWorldQuestButton:GetNormalTexture():SetPoint("topleft", 1, -1)
				AllianceWorldQuestButton:GetNormalTexture():SetPoint("bottomright", -1, 1)
				AllianceWorldQuestButton:GetNormalTexture():SetTexCoord(64/256, 92/256, 0, 1)

				AllianceWorldQuestButton.Highlight = AllianceWorldQuestButton:CreateTexture(nil, "highlight")
				AllianceWorldQuestButton.Highlight:SetColorTexture(.9, .9, .9, .3)
				AllianceWorldQuestButton.Highlight:SetBlendMode("ADD")
				AllianceWorldQuestButton.Highlight:SetAlpha(toggleButtonsAlpha)
				AllianceWorldQuestButton.Highlight:SetSize(unpack(navigateButtonsSize))
				AllianceWorldQuestButton.Highlight:SetPoint("center")

				AllianceWorldQuestButton:SetScript("OnClick", function()
					WorldMapFrame:SetMapID(WorldQuestTracker.MapData.ZoneIDs.KULTIRAS)
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
					WorldQuestTracker.AllianceWorldQuestButton_Click = GetTime()
				end)

			--Horde
				local HordeWorldQuestButton = CreateFrame("button", "WorldQuestTrackerGoToHordeButton", anchorFrame, "BackdropTemplate")
				HordeWorldQuestButton:SetSize(unpack(navigateButtonsSize))
				HordeWorldQuestButton:SetFrameLevel(WorldMapFrame.SidePanelToggle.CloseButton:GetFrameLevel())

				HordeWorldQuestButton:SetBackdrop(navigateButtonsBackdrop)
				HordeWorldQuestButton:SetBackdropBorderColor(unpack(navigateButtonsBorderColor))
				HordeWorldQuestButton:SetBackdropColor(unpack(navigateButtonsbackdropColor))

				HordeWorldQuestButton:SetNormalTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])
				HordeWorldQuestButton:SetPushedTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])

				HordeWorldQuestButton:GetNormalTexture():ClearAllPoints()
				HordeWorldQuestButton:GetNormalTexture():SetPoint("topleft", 1, -1)
				HordeWorldQuestButton:GetNormalTexture():SetPoint("bottomright", -1, 1)
				HordeWorldQuestButton:GetNormalTexture():SetTexCoord(32/256, 64/256, 0, 1)

				HordeWorldQuestButton.Highlight = HordeWorldQuestButton:CreateTexture(nil, "highlight")
				HordeWorldQuestButton.Highlight:SetColorTexture(.9, .9, .9, .3)
				HordeWorldQuestButton.Highlight:SetBlendMode("ADD")
				HordeWorldQuestButton.Highlight:SetAlpha(toggleButtonsAlpha)
				HordeWorldQuestButton.Highlight:SetSize(unpack(navigateButtonsSize))
				HordeWorldQuestButton.Highlight:SetPoint("center")

				HordeWorldQuestButton:SetScript("OnClick", function()
					WorldMapFrame:SetMapID(WorldQuestTracker.MapData.ZoneIDs.ZANDALAR)
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
					WorldQuestTracker.HordeWorldQuestButton_Click = GetTime()
				end)

			--legion
				local LegionWorldQuestButton = CreateFrame("button", "WorldQuestTrackerGoToLegionButton", anchorFrame, "BackdropTemplate")
				LegionWorldQuestButton:SetSize(unpack(navigateButtonsSize))
				LegionWorldQuestButton:SetFrameLevel(WorldMapFrame.SidePanelToggle.CloseButton:GetFrameLevel())

				LegionWorldQuestButton:SetNormalTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])
				LegionWorldQuestButton:SetPushedTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])

				LegionWorldQuestButton:GetNormalTexture():ClearAllPoints()
				LegionWorldQuestButton:GetNormalTexture():SetPoint("topleft", 1, -1)
				LegionWorldQuestButton:GetNormalTexture():SetPoint("bottomright", -1, 1)
				LegionWorldQuestButton:GetNormalTexture():SetTexCoord(32/256, 64/256, 0, 1)

				LegionWorldQuestButton:SetBackdrop(navigateButtonsBackdrop)
				LegionWorldQuestButton:SetBackdropBorderColor(unpack(navigateButtonsBorderColor))
				LegionWorldQuestButton:SetBackdropColor(unpack(navigateButtonsbackdropColor))

				LegionWorldQuestButton.Highlight = LegionWorldQuestButton:CreateTexture(nil, "highlight")
				LegionWorldQuestButton.Highlight:SetColorTexture(.9, .9, .9, .3)
				LegionWorldQuestButton.Highlight:SetBlendMode("ADD")
				LegionWorldQuestButton.Highlight:SetAlpha(toggleButtonsAlpha)
				LegionWorldQuestButton.Highlight:SetSize(unpack(navigateButtonsSize))
				LegionWorldQuestButton.Highlight:SetPoint("center")

				LegionWorldQuestButton:SetScript("OnClick", function()
					WorldMapFrame:SetMapID(WorldQuestTracker.MapData.ZoneIDs.ZANDALAR)
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
					WorldQuestTracker.LegionWorldQuestButton_Click = GetTime()
				end)

			--]=]

			--azeroth
			local AzerothWorldQuestButton = CreateFrame("button", "WorldQuestTrackerGoToAzerothButton", anchorFrame, "BackdropTemplate")
			AzerothWorldQuestButton:SetSize(unpack(navigateButtonsSize))
			AzerothWorldQuestButton:SetFrameLevel(WorldMapFrame.SidePanelToggle.CloseButton:GetFrameLevel())

			AzerothWorldQuestButton:SetNormalTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])
			AzerothWorldQuestButton:SetPushedTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])

			local azerothIconIndex = 5
			AzerothWorldQuestButton:GetNormalTexture():ClearAllPoints()
			AzerothWorldQuestButton:GetNormalTexture():SetPoint("topleft", 1, -1)
			AzerothWorldQuestButton:GetNormalTexture():SetPoint("bottomright", -1, 1)
			AzerothWorldQuestButton:GetNormalTexture():SetTexCoord(((azerothIconIndex-1)*32)/256,(azerothIconIndex*32)/256, 0, 1)
			AzerothWorldQuestButton:GetPushedTexture():ClearAllPoints()
			AzerothWorldQuestButton:GetPushedTexture():SetPoint("topleft", 1, -1)
			AzerothWorldQuestButton:GetPushedTexture():SetPoint("bottomright", -1, 1)
			AzerothWorldQuestButton:GetPushedTexture():SetTexCoord(((azerothIconIndex-1)*32)/256,(azerothIconIndex*32)/256, 0, 1)

			AzerothWorldQuestButton:SetBackdrop(navigateButtonsBackdrop)
			AzerothWorldQuestButton:SetBackdropBorderColor(unpack(navigateButtonsBorderColor))
			AzerothWorldQuestButton:SetBackdropColor(unpack(navigateButtonsbackdropColor))

			AzerothWorldQuestButton.Highlight = AzerothWorldQuestButton:CreateTexture(nil, "highlight")
			AzerothWorldQuestButton.Highlight:SetColorTexture(.9, .9, .9, .3)
			AzerothWorldQuestButton.Highlight:SetBlendMode("ADD")
			AzerothWorldQuestButton.Highlight:SetAlpha(toggleButtonsAlpha)
			AzerothWorldQuestButton.Highlight:SetSize(unpack(navigateButtonsSize))
			AzerothWorldQuestButton.Highlight:SetPoint("center")

			AzerothWorldQuestButton:SetScript("OnClick", function()
				WorldMapFrame:SetMapID(WorldQuestTracker.MapData.ZoneIDs.AZEROTH)
				WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
				WorldQuestTracker.AzerothWorldQuestButton_Click = GetTime()
			end)

			--broken isles
				local BrokenIslesWorldQuestButton = CreateFrame("button", "WorldQuestTrackerGoToBrokenIsles", anchorFrame, "BackdropTemplate")
				BrokenIslesWorldQuestButton:SetSize(unpack(navigateButtonsSize))
				BrokenIslesWorldQuestButton:SetFrameLevel(WorldMapFrame.SidePanelToggle.CloseButton:GetFrameLevel())

				BrokenIslesWorldQuestButton:SetNormalTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])
				BrokenIslesWorldQuestButton:SetPushedTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])

				local brokenIslesIconIndex = 6
				BrokenIslesWorldQuestButton:GetNormalTexture():ClearAllPoints()
				BrokenIslesWorldQuestButton:GetNormalTexture():SetPoint("topleft", 1, -1)
				BrokenIslesWorldQuestButton:GetNormalTexture():SetPoint("bottomright", -1, 1)
				BrokenIslesWorldQuestButton:GetNormalTexture():SetTexCoord(((brokenIslesIconIndex-1)*32)/256,(brokenIslesIconIndex*32)/256, 0, 1)
				BrokenIslesWorldQuestButton:GetPushedTexture():ClearAllPoints()
				BrokenIslesWorldQuestButton:GetPushedTexture():SetPoint("topleft", 1, -1)
				BrokenIslesWorldQuestButton:GetPushedTexture():SetPoint("bottomright", -1, 1)
				BrokenIslesWorldQuestButton:GetPushedTexture():SetTexCoord(((brokenIslesIconIndex-1)*32)/256,(brokenIslesIconIndex*32)/256, 0, 1)

				BrokenIslesWorldQuestButton:SetBackdrop(navigateButtonsBackdrop)
				BrokenIslesWorldQuestButton:SetBackdropBorderColor(unpack(navigateButtonsBorderColor))
				BrokenIslesWorldQuestButton:SetBackdropColor(unpack(navigateButtonsbackdropColor))

				BrokenIslesWorldQuestButton.Highlight = BrokenIslesWorldQuestButton:CreateTexture(nil, "highlight")
				BrokenIslesWorldQuestButton.Highlight:SetColorTexture(.9, .9, .9, .3)
				BrokenIslesWorldQuestButton.Highlight:SetBlendMode("ADD")
				BrokenIslesWorldQuestButton.Highlight:SetAlpha(toggleButtonsAlpha)
				BrokenIslesWorldQuestButton.Highlight:SetSize(unpack(navigateButtonsSize))
				BrokenIslesWorldQuestButton.Highlight:SetPoint("center")

				BrokenIslesWorldQuestButton:SetScript("OnClick", function()
					WorldMapFrame:SetMapID(WorldQuestTracker.MapData.ZoneIDs.BROKENISLES)
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
					WorldQuestTracker.BrokenIslesWorldQuestButton_Click = GetTime()
				end)

			--shadowlands
				local ShadowlandsWorldQuestButton = CreateFrame("button", "WorldQuestTrackerGoToShadowlandsButton", anchorFrame, "BackdropTemplate")
				ShadowlandsWorldQuestButton:SetSize(unpack(navigateButtonsSize))
				ShadowlandsWorldQuestButton:SetFrameLevel(WorldMapFrame.SidePanelToggle.CloseButton:GetFrameLevel())

				ShadowlandsWorldQuestButton:SetNormalTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])
				ShadowlandsWorldQuestButton:SetPushedTexture([[Interface\AddOns\WorldQuestTracker\media\icon_worlds]])

				local shadowlandsIconIndex = 1
				ShadowlandsWorldQuestButton:GetNormalTexture():ClearAllPoints()
				ShadowlandsWorldQuestButton:GetNormalTexture():SetPoint("topleft", 1, -1)
				ShadowlandsWorldQuestButton:GetNormalTexture():SetPoint("bottomright", -1, 1)
				ShadowlandsWorldQuestButton:GetNormalTexture():SetTexCoord(((shadowlandsIconIndex-1)*32)/256,(shadowlandsIconIndex*32)/256, 0, 1)
				ShadowlandsWorldQuestButton:GetPushedTexture():ClearAllPoints()
				ShadowlandsWorldQuestButton:GetPushedTexture():SetPoint("topleft", 1, -1)
				ShadowlandsWorldQuestButton:GetPushedTexture():SetPoint("bottomright", -1, 1)
				ShadowlandsWorldQuestButton:GetPushedTexture():SetTexCoord(((shadowlandsIconIndex-1)*32)/256,(shadowlandsIconIndex*32)/256, 0, 1)

				ShadowlandsWorldQuestButton:SetBackdrop(navigateButtonsBackdrop)
				ShadowlandsWorldQuestButton:SetBackdropBorderColor(unpack(navigateButtonsBorderColor))
				ShadowlandsWorldQuestButton:SetBackdropColor(unpack(navigateButtonsbackdropColor))

				ShadowlandsWorldQuestButton.Highlight = ShadowlandsWorldQuestButton:CreateTexture(nil, "highlight")
				ShadowlandsWorldQuestButton.Highlight:SetColorTexture(.9, .9, .9, .3)
				ShadowlandsWorldQuestButton.Highlight:SetBlendMode("ADD")
				ShadowlandsWorldQuestButton.Highlight:SetAlpha(toggleButtonsAlpha)
				ShadowlandsWorldQuestButton.Highlight:SetSize(unpack(navigateButtonsSize))
				ShadowlandsWorldQuestButton.Highlight:SetPoint("center")

				ShadowlandsWorldQuestButton:SetScript("OnClick", function()
					WorldMapFrame:SetMapID(WorldQuestTracker.MapData.ZoneIDs.THESHADOWLANDS)
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
					WorldQuestTracker.ShadowlandsWorldQuestButton_Click = GetTime()
				end)

			--arrange alliance and horde buttons
			--LegionWorldQuestButton:SetPoint("right", WorldMapFrame.SidePanelToggle, "left", -1, -2)
			--AllianceWorldQuestButton:SetPoint("right", LegionWorldQuestButton, "left", -1, 0)
			--HordeWorldQuestButton:SetPoint("right", AllianceWorldQuestButton, "left", -1, 0)
			--ShadowlandsWorldQuestButton:SetPoint("right", HordeWorldQuestButton, "left", -1, 0)
			BrokenIslesWorldQuestButton:SetPoint("right", WorldMapFrame.SidePanelToggle, "left", -1, -1)
			AzerothWorldQuestButton:SetPoint("right", BrokenIslesWorldQuestButton, "left", -1, 0)
			ShadowlandsWorldQuestButton:SetPoint("right", AzerothWorldQuestButton, "left", -1, 0)
			local locationAlphaButton = 0.75
			BrokenIslesWorldQuestButton:SetAlpha(locationAlphaButton)
			AzerothWorldQuestButton:SetAlpha(locationAlphaButton)
			ShadowlandsWorldQuestButton:SetAlpha(locationAlphaButton)

			--LegionWorldQuestButton:SetAlpha(.7)
			--AllianceWorldQuestButton:SetAlpha(.7)
			--HordeWorldQuestButton:SetAlpha(.7)
			ShadowlandsWorldQuestButton:SetAlpha(.96)

			function WorldQuestTracker.SetShownWorldShortcuts()
				local bIsShown = WorldQuestTracker.db.profile.show_world_shortcuts
				BrokenIslesWorldQuestButton:SetShown(bIsShown)
				AzerothWorldQuestButton:SetShown(bIsShown)
				ShadowlandsWorldQuestButton:SetShown(bIsShown)

				WorldQuestTrackerToggleQuestsSummaryButton:ClearAllPoints()
				if (bIsShown) then
					WorldQuestTrackerToggleQuestsSummaryButton:SetPoint("bottomleft", ShadowlandsWorldQuestButton, "topleft", 0, 0)
				else
					WorldQuestTrackerToggleQuestsSummaryButton:SetPoint("bottomright", WorldMapFrame.SidePanelToggle, "bottomleft", 0, 20)
				end
			end

			--toggle between by zone and by type
			local ToggleQuestsSummaryButton = CreateFrame("button", "WorldQuestTrackerToggleQuestsSummaryButton", anchorFrame, "BackdropTemplate")
			ToggleQuestsSummaryButton:SetSize(100, 14)
			ToggleQuestsSummaryButton:SetFrameLevel(1025)

			ToggleQuestsSummaryButton.Highlight = ToggleQuestsSummaryButton:CreateTexture(nil, "highlight")
			ToggleQuestsSummaryButton.Highlight:SetTexture([[Interface\Buttons\UI-Common-MouseHilight]])
			ToggleQuestsSummaryButton.Highlight:SetBlendMode("ADD")
			ToggleQuestsSummaryButton.Highlight:SetAlpha(toggleButtonsAlpha)
			ToggleQuestsSummaryButton.Highlight:SetSize(128*1.5, 20*1.5)
			ToggleQuestsSummaryButton.Highlight:SetPoint("center")

			--create shadow below order by zone button
			ToggleQuestsSummaryButton.ShadowBelow = ToggleQuestsSummaryButton:CreateTexture(nil, "border")
			--ToggleQuestsSummaryButton.ShadowBelow:SetTexture([[Interface\ENCOUNTERJOURNAL\DungeonJournal]])
			--ToggleQuestsSummaryButton.ShadowBelow:SetTexCoord(900/1024, 934/1024, 15/512, 46/512)
			ToggleQuestsSummaryButton.ShadowBelow:SetPoint("left", ToggleQuestsSummaryButton, "left", 0, 0)
			ToggleQuestsSummaryButton.ShadowBelow:SetSize(100, 13)

			ToggleQuestsSummaryButton.TextLabel = DF:CreateLabel(ToggleQuestsSummaryButton, "Toggle Summary", DF:GetTemplate("font", "WQT_TOGGLEQUEST_TEXT"))
			ToggleQuestsSummaryButton.TextLabel:SetPoint("center", ToggleQuestsSummaryButton, "center")

			function ToggleQuestsSummaryButton:UpdateText()
				if (WorldQuestTracker.db.profile.world_map_config.summary_showby == "byzone") then
					--show by type
					ToggleQuestsSummaryButton.TextLabel:SetText(L["S_WORLDBUTTONS_SHOW_TYPE"])

				elseif (WorldQuestTracker.db.profile.world_map_config.summary_showby == "bytype") then
					--show by zone
					ToggleQuestsSummaryButton.TextLabel:SetText(L["S_WORLDBUTTONS_SHOW_ZONE"])
				end
			end

			ToggleQuestsSummaryButton:SetScript("OnClick", function()
				if (WorldQuestTracker.db.profile.world_map_config.summary_showby == "byzone") then
					--show by type
					WorldQuestTracker.db.profile.world_map_config.summary_show = true
					WorldQuestTracker.db.profile.world_map_config.summary_showby = "bytype"

				elseif (WorldQuestTracker.db.profile.world_map_config.summary_showby == "bytype") then
					--show by zone
					WorldQuestTracker.db.profile.world_map_config.summary_show = true
					WorldQuestTracker.db.profile.world_map_config.summary_showby = "byzone"
				end

				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.DoAnimationsOnWorldMapWidgets = true
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
				end

				ToggleQuestsSummaryButton:UpdateText()
			end)

			ToggleQuestsSummaryButton:UpdateText()

			ToggleQuestsSummaryButton:SetScript("OnMouseDown", function()
				ToggleQuestsSummaryButton.TextLabel:SetPoint("center", ToggleQuestsSummaryButton, "center", -1, -1)
			end)

			ToggleQuestsSummaryButton:SetScript("OnMouseUp", function()
				ToggleQuestsSummaryButton.TextLabel:SetPoint("center", ToggleQuestsSummaryButton, "center")
			end)

			ToggleQuestsSummaryButton:Hide()

			WorldQuestTracker.SetShownWorldShortcuts()

			-- �ptionsfunc ~optionsfunc
			local options_on_click = function(_, _, option, value, value2, mouseButton)
				if (option == "use_tracker") then
					C_Timer.After(0, WorldQuestTracker.RefreshTrackerAnchor)
				end

				if (option == "accessibility") then
					if (value == "extra_tracking_indicator") then
						WorldQuestTracker.db.profile.accessibility.extra_tracking_indicator = value2
					elseif (value == "use_bounty_ring") then
						WorldQuestTracker.db.profile.accessibility.use_bounty_ring = value2
					end

					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneWidgets(true)
					end
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
						WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true, true, false, true)
					end

					GameCooltip:Hide()
					return
				end

				if (option == "pathdots") then
					WorldQuestTracker.db.profile.path[value] = value2
					GameCooltip:Hide()
					return
				end

				if (option == "oribos_flight_master") then
					WorldQuestTracker.db.profile.flymaster_tracker_enabled = not WorldQuestTracker.db.profile.flymaster_tracker_enabled
					GameCooltip:Hide()
				end

				if (option == "talkinghead") then
					if (value == "talking_heads_openworld") then
						WorldQuestTracker.db.profile.talking_heads_openworld = not WorldQuestTracker.db.profile.talking_heads_openworld
					elseif (value == "talking_heads_dungeon") then
						WorldQuestTracker.db.profile.talking_heads_dungeon = not WorldQuestTracker.db.profile.talking_heads_dungeon
					elseif (value == "talking_heads_raid") then
						WorldQuestTracker.db.profile.talking_heads_raid = not WorldQuestTracker.db.profile.talking_heads_raid
					elseif (value == "talking_heads_torgast") then
						WorldQuestTracker.db.profile.talking_heads_torgast = not WorldQuestTracker.db.profile.talking_heads_torgast
					end

					GameCooltip:Hide()
					return
				end

				if (option == "ignore_quest") then
					WorldQuestTracker.OpenQuestBanPanel()
					GameCooltip:Hide()
					return
				end

				if (option == "bar_visible") then
					WorldQuestTracker.db.profile.bar_visible = value
					WorldQuestTracker.RefreshStatusBarVisibility()
					GameCooltip:Hide()
					WorldQuestTracker:Msg(L["S_MAPBAR_OPTIONSMENU_STATUSBAR_ONDISABLE"])
					return
				end

				if (option == "emissary_quest_info") then
					WorldQuestTracker.db.profile.show_emissary_info = value
					GameCooltip:Hide()
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneSummaryFrame()
					end
					return
				end

				if (option == "show_summary_minimize_button") then
					WorldQuestTracker.db.profile.show_summary_minimize_button = value

					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneSummaryFrame()
					end
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
						WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
					end

					WorldQuestTracker.ForceRefreshBountyBoard()

					GameCooltip:Hide()
					return
				end

				if (option == "world_map_config") then

					if (value == "incsize") then
						WorldQuestTracker.db.profile.world_map_config [value2] = WorldQuestTracker.db.profile.world_map_config [value2] + 0.05
						WorldQuestTracker:Msg("- " .. WorldQuestTracker.db.profile.world_map_config [value2])
					elseif (value == "decsize") then
						WorldQuestTracker.db.profile.world_map_config [value2] = WorldQuestTracker.db.profile.world_map_config [value2] - 0.05
						WorldQuestTracker:Msg("- " .. WorldQuestTracker.db.profile.world_map_config [value2])
					elseif (value == "incrows") then
						WorldQuestTracker.db.profile.world_map_config [value2] = WorldQuestTracker.db.profile.world_map_config [value2] + 1
						WorldQuestTracker:Msg("- " .. WorldQuestTracker.db.profile.world_map_config [value2])
					elseif (value == "decrows") then
						WorldQuestTracker.db.profile.world_map_config [value2] = WorldQuestTracker.db.profile.world_map_config [value2] - 1
						WorldQuestTracker:Msg("- " .. WorldQuestTracker.db.profile.world_map_config [value2])
					else
						WorldQuestTracker.db.profile.world_map_config [value] = value2
					end

					WorldQuestTracker.UpdateWorldQuestsOnWorldMap()

					if (value == "onmap_show" or value == "summary_show" or value == "summary_anchor" or value == "summary_widgets_per_row") then
						WorldQuestTracker.OnMapHasChanged()
						GameCooltip:Close()
					end

					--old(perhaps deprecated)
					if (value == "textsize") then
						WorldQuestTracker.SetTextSize("WorldMap", value2)

					elseif (value == "scale" or value == "quest_icons_scale_offset") then
						if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
							WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
						end

					elseif (value == "disable_world_map_widgets") then
						WorldQuestTracker.db.profile.disable_world_map_widgets = value2
						if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
							WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
							GameCooltip:Close()
						end

					end
					return

				elseif (option == "zone_map_config") then

					if (value == "incsize") then
						WorldQuestTracker.db.profile.zone_map_config [value2] = WorldQuestTracker.db.profile.zone_map_config [value2] + 0.05
						WorldQuestTracker:Msg("- " .. WorldQuestTracker.db.profile.zone_map_config [value2])
						--update if showing zone map
						if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
							WorldQuestTracker.UpdateZoneWidgets(true)
						end
						return

					elseif (value == "decsize") then
						WorldQuestTracker.db.profile.zone_map_config [value2] = WorldQuestTracker.db.profile.zone_map_config [value2] - 0.05
						WorldQuestTracker:Msg("- " .. WorldQuestTracker.db.profile.zone_map_config [value2])
						--update if showing zone map
						if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
							WorldQuestTracker.UpdateZoneWidgets(true)
						end
						return

					else
						WorldQuestTracker.db.profile.zone_map_config [value] = value2
					end

					--update if showing zone map
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneWidgets(true)
					end
					GameCooltip:Close()

					return
				end

				if (option == "reset_map_frame_scale_mod") then
					WorldQuestTracker.db.profile.map_frame_scale_mod = 1

					if (WorldQuestTracker.db.profile.map_frame_scale_enabled) then
						WorldQuestTracker.UpdateWorldMapFrameScale()
					end

					GameCooltip:Close()
					return

				elseif (option == "show_faction_frame") then
					WorldQuestTracker.db.profile.show_faction_frame = value

					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
						WorldQuestTracker.WorldSummary.UpdateFactionAnchor()
					end

					GameCooltip:Close()
					return

				elseif (option == "map_frame_anchor") then
					WorldQuestTracker.db.profile.map_frame_anchor = value

					if (not WorldMapFrame.isMaximized) then
						WorldQuestTracker.UpdateWorldMapFrameAnchor(true)
					end

					ReloadUI()

					GameCooltip:Close()
					return

				elseif (option == "map_frame_scale_mod") then
					--option, value, value2, mouseButton
					--"map_frame_scale_mod", "incsize"
					if (WorldQuestTracker.db.profile.map_frame_scale_enabled) then
						if (value == "incsize") then
							WorldQuestTracker.db.profile.map_frame_scale_mod = WorldQuestTracker.db.profile.map_frame_scale_mod + 0.05
							WorldQuestTracker:Msg("- " .. WorldQuestTracker.db.profile.map_frame_scale_mod)
						elseif (value == "decsize") then
							WorldQuestTracker.db.profile.map_frame_scale_mod = WorldQuestTracker.db.profile.map_frame_scale_mod - 0.05
							WorldQuestTracker:Msg("- " .. WorldQuestTracker.db.profile.map_frame_scale_mod)
						end

						WorldQuestTracker.UpdateWorldMapFrameScale()

						WorldQuestTracker:Msg("Value: " .. WorldQuestTracker.db.profile.map_frame_scale_mod)
					else
						WorldQuestTracker:Msg(L["S_OPTIONS_MAPFRAME_ERROR_SCALING_DISABLED"])
					end

					GameCooltip:Close()
					return

				elseif (option == "map_frame_scale_enabled") then

					-- ~review
					if (true) then
						WorldQuestTracker:Msg("this feature is disabled at the moment.")
						WorldQuestTracker.db.profile.map_frame_scale_enabled = false
						return
					end

					WorldQuestTracker.db.profile.map_frame_scale_enabled = value

					if (value) then
						WorldQuestTracker.UpdateWorldMapFrameScale()
					else
						WorldQuestTracker.UpdateWorldMapFrameScale(true)
					end

					GameCooltip:Close()
					return
				end

				if (option == "rarescan") then
					WorldQuestTracker.db.profile.rarescan [value] = value2
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneWidgets()
					end
					GameCooltip:Close()
					return
				end

				if (option:find("tomtom")) then
					local option = option:gsub("tomtom%-", "")
					WorldQuestTracker.db.profile.tomtom [option] = value
					GameCooltip:Hide()

					if (option == "enabled") then
						if (value) then
							--adiciona todas as quests to tracker no tomtom
							for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
								local quest = WorldQuestTracker.QuestTrackList [i]
								local questID = quest.questID
								local mapID = quest.mapID
								WorldQuestTracker.AddQuestTomTom(questID, mapID, true)
							end
							--WorldQuestTracker.RemoveAllQuestsFromTracker()
						else
							--desligou o tracker do tomtom
							for questID, t in pairs(WorldQuestTracker.TomTomUIDs) do
								if (type(questID) == "number" and isWorldQuest(questID)) then
									--procura o bot�o da quest
									for _, widget in ipairs(WorldQuestTracker.WorldMapWidgets) do
										if (widget.questID == questID) then
											WorldQuestTracker.AddQuestToTracker(widget)
											TomTom:RemoveWaypoint(t)
											break
										end
									end
								end
							end
							wipe(WorldQuestTracker.TomTomUIDs)

							if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
								WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true, false, false, true)
							end
						end
					end

					return
				end

				if (option == "share_addon") then
					WorldQuestTracker.OpenSharePanel()
					GameCooltip:Hide()
					return

				elseif (option == "tracker_scale") then
					WorldQuestTracker.db.profile [option] = value
					WorldQuestTracker.UpdateTrackerScale()

				elseif (option == "clear_quest_cache") then
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
						WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true, true, false, true)
					else

					end

				elseif (option == "arrow_update_speed") then
					WorldQuestTracker.db.profile.arrow_update_frequence = value
					WorldQuestTracker.UpdateArrowFrequence()
					GameCooltip:Hide()
					return

				elseif (option == "untrack_quests") then
					WorldQuestTracker.RemoveAllQuestsFromTracker()

					if (TomTom and IsAddOnLoaded("TomTom")) then
						for questID, t in pairs(WorldQuestTracker.TomTomUIDs) do
							TomTom:RemoveWaypoint(t)
						end
						wipe(WorldQuestTracker.TomTomUIDs)
					end

					GameCooltip:Hide()
					return

				elseif (option == "use_quest_summary") then
					WorldQuestTracker.db.profile [option] = value
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneWidgets()
					end
				else
					WorldQuestTracker.db.profile [option] = value

					if (option == "bar_anchor") then
						WorldQuestTracker:SetStatusBarAnchor()

					elseif (option == "use_old_icons") then
						if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
							WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true, true, false, true)
						else
							WorldQuestTracker.UpdateZoneWidgets()
						end

					elseif (option == "tracker_textsize") then
						WorldQuestTracker.RefreshTrackerWidgets()

					end
				end

				if (option == "zone_only_tracked") then
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneWidgets()
					end
				end

				if (option == "tracker_is_locked") then
					if (not WorldQuestTracker.db.profile.tracker_attach_to_questlog) then
						if (value) then
							--locked, disable mouse
							WorldQuestTrackerScreenPanel:EnableMouse(false)
						else
							--unlocked, enable mouse
							WorldQuestTrackerScreenPanel:EnableMouse(true)
						end
					end
				end

				if (option == "tracker_attach_to_questlog") then
					if (value) then
						WorldQuestTrackerScreenPanel:EnableMouse(false)
					else
						LibWindow.RestorePosition(WorldQuestTrackerScreenPanel)

						if (not WorldQuestTracker.db.profile.tracker_is_locked) then
							WorldQuestTrackerScreenPanel:EnableMouse(true)
							
						end
					end

					WorldQuestTracker.RefreshTrackerAnchor()
				end

				if (option == "tracker_is_locked") then
					WorldQuestTracker.RefreshTrackerAnchor()
				end

				if (option ~= "show_timeleft" and option ~= "alpha_time_priority" and option ~= "force_sort_by_timeleft") then
					--GameCooltip:ExecFunc(WorldQuestTrackerOptionsButton)
				else
					--> se for do painel de tempo, dar refresh no world map
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
						WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true, true, false, true)
					end
					GameCooltip:Close()
				end
			end

			WorldQuestTracker.SetSetting = function(...)
				options_on_click(nil, nil, ...)
			end

			--path frame based on where do we go now addon which i co-wrote with my dear friend yakumile
			--create the frame to check if the map is open
			local WQTPathFrame = CreateFrame("frame")

			function WQTPathFrame.IsDragonflightMap()
				return WorldQuestTracker.MapData.DragonflightZones[WorldMapFrame.mapID]
			end

			--data provider
			local worldQuestTrackerPathProvider = CreateFromMixins(MapCanvasDataProviderMixin)

			function worldQuestTrackerPathProvider:HideLine()
				self:GetMap():RemoveAllPinsByTemplate("WorldQuestTrackerPathPinTemplate")
				for i = 1, #WQTPathFrame.texturePool do
					local Dot = WQTPathFrame.texturePool[i]
					Dot:Hide()
				end
				WQTPathFrame.bIsShowingLine = false
			end

			function worldQuestTrackerPathProvider:ShowLine()
				WQTPathFrame.LinePin = self:GetMap():AcquirePin("WorldQuestTrackerPathPinTemplate")
				WQTPathFrame.bIsShowingLine = true
			end

			--pin mixin
			WorldQuestTrackerPathPinMixin = CreateFromMixins(MapCanvasPinMixin)
			function WorldQuestTrackerPathPinMixin:OnLoad()
				self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
			end

			WQTPathFrame.texturePool = {}
			WQTPathFrame.texturesNotInUse = {}

			--line size need to be dynamic with the canvas size
			local dotScale = WorldQuestTracker.DotLineScale[WorldMapFrame.mapID] or 1
			local dotAmount = WorldQuestTracker.db.profile.path.DotAmount
			dotAmount = math.floor(dotAmount * dotScale)

			WQTPathFrame.DotScale = dotScale
			WQTPathFrame.Distance = WorldQuestTracker.db.profile.path.LineSize / (WorldQuestTracker.db.profile.path.DotAmount * dotAmount)
			WQTPathFrame.bIsShowingLine = false

			function WQTPathFrame.RefreshDot(Dot)
				local dotSize = WorldQuestTracker.db.profile.path.DotSize
				dotSize = dotSize * WQTPathFrame.DotScale
				Dot:SetTexture(WorldQuestTracker.db.profile.path.DotTexture)
				Dot:SetSize(dotSize, dotSize)
				Dot:SetVertexColor(unpack(WorldQuestTracker.db.profile.path.ColorSRGB))
			end

			--add the provider to pins
			WorldMapFrame:AddDataProvider(worldQuestTrackerPathProvider)

			--pre create all dots
			if (not WQTPathFrame.bIsShowingLine) then
				worldQuestTrackerPathProvider:ShowLine()
			end

			for i = 1, WorldQuestTracker.db.profile.path.DotAmount do
				local dotTexture = WQTPathFrame.LinePin:CreateTexture(nil, "overlay")
				dotTexture:SetPoint("center")
				WQTPathFrame.RefreshDot(dotTexture)
				table.insert(WQTPathFrame.texturePool, dotTexture)
			end

			function WQTPathFrame.Refresh()
				for i = 1, #WQTPathFrame.texturePool do
					local dotTexture = WQTPathFrame.texturePool[i]
					WQTPathFrame.RefreshDot(dotTexture)
				end

				local dotAmount = WorldQuestTracker.db.profile.path.DotAmount
				local dotScale = WorldQuestTracker.DotLineScale[WorldMapFrame.mapID] or 1
				dotAmount = math.floor(dotAmount * dotScale)

				--line length
				WQTPathFrame.DotScale = dotScale
				WQTPathFrame.Distance = WorldQuestTracker.db.profile.path.LineSize / dotAmount
				WQTPathFrame.Distance = WQTPathFrame.Distance * 2

				--if (not WQTPathFrame.bIsShowingLine) then
				--	worldQuestTrackerPathProvider:ShowLine()
				--end

				--dot amount
				if (#WQTPathFrame.texturePool ~= dotAmount) then
					if (#WQTPathFrame.texturePool < dotAmount) then
						--increase
						for i = #WQTPathFrame.texturePool+1, dotAmount do
							local Dot = tremove(WQTPathFrame.texturesNotInUse)
							if (not Dot) then
								Dot = WQTPathFrame.LinePin:CreateTexture(nil, "overlay")
							end

							Dot:SetPoint("center")
							Dot:Show()
							WQTPathFrame.RefreshDot(Dot)
							table.insert(WQTPathFrame.texturePool, Dot)
						end
					else
						--decrease
						for i = dotAmount+1, #WQTPathFrame.texturePool do
							local Dot = tremove(WQTPathFrame.texturePool)
							Dot:Hide()
							table.insert(WQTPathFrame.texturesNotInUse, Dot)
						end
					end
				end

				--worldQuestTrackerPathProvider:HideLine()
			end

			WQTPathFrame.Refresh()
			worldQuestTrackerPathProvider:HideLine()

			WQTPathFrame:SetScript("OnUpdate", function()
				--check if the map is opened and if the player is flying
				if (WorldMapFrame:IsShown() and IsFlying() and not IsInInstance() and WorldQuestTracker.db.profile.path.enabled and GetPlayerFacing()) then
					--get the direction the player is facing
					local direction = GetPlayerFacing()
					--build a forward vector based on the the direction the player is facing
					local forwardVector = {x = -math.sin(direction), y = -math.cos(direction), z = 0}

					--get the player map position
					local vec2Position = C_Map.GetPlayerMapPosition(WorldMapFrame.mapID, "player") --C_Map.GetBestMapForUnit("player")

					--if player doesn't have a position in this map, hide the line
					if (not vec2Position) then
						if (WQTPathFrame.bIsShowingLine) then
							worldQuestTrackerPathProvider:HideLine()
						end
						return
					else
						if (not WQTPathFrame.bIsShowingLine) then
							worldQuestTrackerPathProvider:ShowLine()
							WQTPathFrame.Refresh()
						end
					end

					local playerXPos, playerYPos = vec2Position.x, vec2Position.y

					--update pin position
					WQTPathFrame.LinePin:SetPosition(playerXPos, playerYPos)

					--update all dot position
					for i = 1, #WQTPathFrame.texturePool do
						local dotTexture = WQTPathFrame.texturePool[i]

						--calculate the dot position
						local nx, ny = forwardVector.x * WQTPathFrame.Distance * i, forwardVector.y * WQTPathFrame.Distance * i
						nx, ny = nx + playerXPos, ny + playerYPos

						--set the dot position
						dotTexture:SetPoint("CENTER", WQTPathFrame.LinePin, "CENTER", nx, -ny)

						if (not dotTexture:IsShown()) then
							dotTexture:Show()
							if (WQTPathFrame.IsDragonflightMap()) then
								dotTexture:SetScale(2)
							else
								dotTexture:SetScale(1)
							end
						end
					end
				else
					--the map is closed or the player isn't flying, check if the line is showing
					if (WQTPathFrame.bIsShowingLine) then
						worldQuestTrackerPathProvider:HideLine()
					end
				end
			end)

			-- world map summary ~summary ~worldsummary
			local worldSummary = WorldQuestTracker.WorldSummary
			worldSummary:SetWidth(100)
			worldSummary:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
			worldSummary:SetBackdropColor(0, 0, 0, 0)
			worldSummary:SetBackdropBorderColor(0, 0, 0, 0)

			worldSummary.WidgetIndex = 1
			worldSummary.TotalGold = 0
			worldSummary.TotalResources = 0
			worldSummary.TotalAPower = 0
			worldSummary.TotalPet = 0
			worldSummary.FactionSelected = 1
			worldSummary.FactionSelected_OnInit = 6 --the index 6 is the tortollan faction which has less quests and add less noise
			worldSummary.AnchorAmount = 9
			worldSummary.MaxWidgetsPerRow = 9
			worldSummary.FactionIDs = {}
			worldSummary.ZoneAnchors = {}
			worldSummary.AnchorsByQuestType = {}
			worldSummary.FactionSelectedTemplate = DF:InstallTemplate("button", "WQT_FACTION_SELECTED", {backdropbordercolor = {1, .8, 0, 1}}, "OPTIONS_BUTTON_TEMPLATE")

			worldSummary.Anchors = {}
			worldSummary.AnchorsInUse = {}
			worldSummary.Widgets = {}
			worldSummary.ScheduleToUpdate = {}
			worldSummary.FactionWidgets = {}
			--store quests that are shown in the summary with the value poiting to its widget
			worldSummary.ShownQuests = {}

			worldSummary.QuestTypesByIndex = {
				"ANCHORTYPE_ARTIFACTPOWER",
				"ANCHORTYPE_RESOURCES",
				"ANCHORTYPE_EQUIPMENT",
				"ANCHORTYPE_GOLD",
				"ANCHORTYPE_REPUTATION",
				"ANCHORTYPE_MISC",
				"ANCHORTYPE_MISC2",
				"ANCHORTYPE_PETBATTLE",
				"ANCHORTYPE_RACING",
			}

			worldSummary.QuestTypes = {
				["ANCHORTYPE_ARTIFACTPOWER"] = 1,
				["ANCHORTYPE_RESOURCES"] = 2,
				["ANCHORTYPE_EQUIPMENT"] = 3,
				["ANCHORTYPE_GOLD"] = 4,
				["ANCHORTYPE_REPUTATION"] = 5,
				["ANCHORTYPE_MISC"] = 6,
				["ANCHORTYPE_MISC2"] = 7,
				["ANCHORTYPE_PETBATTLE"] = 8,
				["ANCHORTYPE_RACING"] = 9,
			}

			function worldSummary.UpdateMaxWidgetsPerRow()
				worldSummary.MaxWidgetsPerRow = WorldQuestTracker.db.profile.world_map_config.summary_widgets_per_row
			end

			--return which side of the world map the anchor is attached to
			--if requesting the raw value it'll directly get the value from the user profile
			--if not, it'll consider what is the type of anchor being used
			function worldSummary.GetAnchorSide(isRaw, anchor)
				if (isRaw) then
					return WorldQuestTracker.db.profile.world_map_config.summary_anchor
				else
					if (WorldQuestTracker.db.profile.world_map_config.summary_showby) then
						local mapID = anchor.mapID
						local mapTable = WorldQuestTracker.mapTables[mapID]
						if (mapTable) then
							return mapTable.GrowRight and "left" or "right"
						end
						return "left"
					else
						return WorldQuestTracker.db.profile.world_map_config.summary_anchor
					end
				end
			end

			--set the anchor point of the summary frame on a side of the map
			--anchors can be the string 'left' or 'right'
			function worldSummary.RefreshSummaryAnchor()
				worldSummary:ClearAllPoints()
				local anchorSide = worldSummary.GetAnchorSide(true)

				if (anchorSide == "left") then
					worldSummary:SetPoint("topleft")
					worldSummary:SetPoint("bottomleft")

				elseif (anchorSide == "right") then
					worldSummary:SetPoint("topright")
					worldSummary:SetPoint("bottomright")

				end

				if (not worldSummary.BuiltFactionWidgets) then
					worldSummary.CreateFactionButtons()
					worldSummary.BuiltFactionWidgets = true
				end

				worldSummary.UpdateFactionAnchor()
			end

			worldSummary.HideAnimation = DF:CreateAnimationHub(worldSummary, function()end, function() worldSummary:Hide() end)
			DF:CreateAnimation(worldSummary.HideAnimation, "translation", 1, 0.9, -300, 0)

			function worldSummary.ShowSummary()
				if (worldSummary.HideAnimation:IsPlaying()) then
					worldSummary.HideAnimation:Stop()
				end

				worldSummary:Show()
			end

			function worldSummary.HideSummary()
				worldSummary:Hide()
				--worldSummary.HideAnimation:Play()
			end

			-- �nchorbutton ~anchorbutton
			local on_click_anchor_button = function(self, button, param1, param2)
				local anchor = self.MyObject.Anchor
				local questsToTrack = {}

				for i = 1, #anchor.Widgets do
					local widget = anchor.Widgets [i]
					if (widget:IsShown() and widget.questID) then
						table.insert(questsToTrack, widget)
					end
				end

				C_Timer.NewTicker(.04, function(tickerObject)
					local widget = tremove(questsToTrack)
					if (widget) then
						WorldQuestTracker.CheckAddToTracker(widget, widget, true)
						local questID = widget.questID

						WorldQuestTracker.PlayTick(3)

						for _, widget in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
							if (widget.questID == questID and widget:IsShown()) then
								--animations
								if (widget.onEndTrackAnimation:IsPlaying()) then
									widget.onEndTrackAnimation:Stop()
								end
								widget.onStartTrackAnimation:Play()
								if (not widget.AddedToTrackerAnimation:IsPlaying()) then
									widget.AddedToTrackerAnimation:Play()
								end
							end
						end
					else
						tickerObject:Cancel()
					end
				end)
			end

			local on_select_anchor_options = function(self, fixedParam, configTable, configName, configValue)
				if (configName == "Enabled") then
					configTable.Enabled = configValue
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true, true, false, true)
					GameCooltip:Hide()

				elseif (configName == "YOffset") then
					if (configValue == "up") then
						configTable.YOffset = configTable.YOffset - 0.02
						WorldQuestTracker:Msg("OffSet:", format("%.2f", configTable.YOffset))

					elseif (configValue == "down") then
						configTable.YOffset = configTable.YOffset + 0.02
						WorldQuestTracker:Msg("OffSet:", format("%.2f", configTable.YOffset))
					end
				end

				worldSummary.ReAnchor()
			end

			--create anchors
			for i = 1, worldSummary.AnchorAmount do
				local anchor = CreateFrame("frame", nil, worldSummary, "BackdropTemplate")
				anchor:SetSize(1, 1)

				anchor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
				anchor:SetBackdropColor(0, 0, 0, 0)
				anchor:SetBackdropBorderColor(0, 0, 0, 0)

				anchor.Title = DF:CreateLabel(anchor)
				anchor.Title.textcolor = {1, .8, .2, .854}
				anchor.Title.textsize = 11

				anchor.WidgetsAmount = 0
				anchor.Widgets = {}

				--config on hover over
					anchor.ConfigFrame = CreateFrame("frame", nil, anchor, "BackdropTemplate")
					anchor.ConfigFrame:SetSize(40, 12)
					anchor.ConfigFrame:SetPoint("bottomleft", anchor.Title.widget, "bottomleft")
					anchor.ConfigFrame:SetPoint("bottomright", anchor.Title.widget, "bottomright")

					local createMenu = function()
						GameCooltip:Preset(2)

						local mapID = anchor.mapID
						local anchorOptions = WorldQuestTracker.db.profile.anchor_options[mapID]

						if (not anchorOptions) then
							GameCooltip:AddLine("nop, there no options")
							return
						end

						GameCooltip:AddLine("Enabled", "", 1)
						add_checkmark_icon(anchorOptions.Enabled, true)
						GameCooltip:AddMenu(1, on_select_anchor_options, anchorOptions, "Enabled", not anchorOptions.Enabled)

						GameCooltip:AddLine("$div")

						GameCooltip:AddLine("Move Up", "", 1)
						GameCooltip:AddIcon([[Interface\BUTTONS\UI-MicroStream-Yellow]], 1, 1, 16, 16, 0, 1, 1, 0)
						GameCooltip:AddMenu(1, on_select_anchor_options, anchorOptions, "YOffset", "up")

						GameCooltip:AddLine("Move Down", "", 1)
						GameCooltip:AddIcon([[Interface\BUTTONS\UI-MicroStream-Yellow]], 1, 1, 16, 16, 0, 1, 0, 1)
						GameCooltip:AddMenu(1, on_select_anchor_options, anchorOptions, "YOffset", "down")
					end

					anchor.ConfigFrame.CoolTip = {
						Type = "menu",
						BuildFunc = createMenu, --> called when user mouse over the frame
						OnEnterFunc = function(self)
							anchor.ConfigFrame.button_mouse_over = true
							anchor.Title.textcolor = {1, .9, .7, 1}
							--button_onenter(self)
						end,
						OnLeaveFunc = function(self)
							anchor.ConfigFrame.button_mouse_over = false
							anchor.Title.textcolor = {1, .8, .2, .854}
							--GameCooltip:Hide()
						end,
						FixedValue = "none",
						ShowSpeed = 0.150,
						Options = function()
							GameCooltip:SetOption("MyAnchor", "bottom")
							GameCooltip:SetOption("RelativeAnchor", "top")
							GameCooltip:SetOption("WidthAnchorMod", 0)
							GameCooltip:SetOption("HeightAnchorMod", 0)
							GameCooltip:SetOption("TextSize", 10)
							GameCooltip:SetOption("FixedWidth", 180)
							GameCooltip:SetOption("IconBlendMode", "ADD")
						end
					}

					GameCooltip:CoolTipInject(anchor.ConfigFrame)

				--button to track all quests in the anchor
				local anchorButton = DF:CreateButton(anchor, on_click_anchor_button, 20, 20, "", anchorID)
				anchorButton:SetFrameLevel(anchor:GetFrameLevel()-1)
				anchorButton.Texture = anchorButton:CreateTexture(nil, "overlay")
				anchorButton.Texture:SetTexture([[Interface\MINIMAP\SuperTrackerArrow]])
				anchorButton.Texture:SetAlpha(.5)
				anchor.Button = anchorButton
				anchorButton.Anchor = anchor

				--anchor pin - hack to set the anchor location in the map based in a x y coordinate
				local pinAnchor = CreateFrame("frame", nil, worldFramePOIs, WorldQuestTracker.DataProvider:GetPinTemplate())
				pinAnchor.dataProvider = WorldQuestTracker.DataProvider
				pinAnchor.worldQuest = true
				pinAnchor.owningMap = WorldQuestTracker.DataProvider:GetMap()
				pinAnchor.questID = 1
				pinAnchor.numObjectives = 1
				anchor.PinAnchor = pinAnchor

				anchorButton:SetHook("OnEnter", function()
					anchorButton.Texture:SetBlendMode("ADD")
					GameCooltip:Preset(2)
					GameCooltip:AddLine(" " .. L["S_WORLDMAP_TOOLTIP_TRACKALL"])
					GameCooltip:AddIcon([[Interface\AddOns\WorldQuestTracker\media\ArrowFrozen]], 1, 1, 20, 20, 0.1171, 0.6796, 0.1171, 0.7343)
					GameCooltip:ShowCooltip(anchor.Button)
				end)

				anchorButton:SetHook("OnLeave", function()
					anchorButton.Texture:SetBlendMode("BLEND")
					GameCooltip:Hide()
				end)

				anchor:SetScript("OnHide", function()
					anchorButton:Hide()
				end)

				worldSummary.Anchors[i] = anchor

				--store a point to this table by its quest type
				worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[i]] = anchor
				anchor.QuestType = worldSummary.QuestTypesByIndex[i]
			end

			--called when using the anchor for the first time after addin a quest square
			--it'll iterate among all anchors in use and reorder them the sort order defined by the user under the 'Sort Order' menu
			--if the user set to show quest by map, it will ignore the order and use positions from the built-in map tables in WQT
			local anchorReorderFunc = function(anchor1, anchor2)
				return anchor1.AnchorOrder < anchor2.AnchorOrder
			end

			function worldSummary.ReAnchor()
				if (WorldQuestTracker.db.profile.world_map_config.summary_showby == "byzone") then
					for index, anchor in pairs(worldSummary.Anchors) do
						local mapID = anchor.mapID
						local mapTable = WorldQuestTracker.mapTables [mapID]

						if (mapTable) then
							local config = WorldQuestTracker.db.profile.anchor_options [mapID]
							if (not config) then
								config = {Enabled = true, YOffset = 0, Alpha = 1, TextColor = {1, .8, .2, .854}, ScaleOffset = 0}
								WorldQuestTracker.db.profile.anchor_options [mapID] = config
							end

							local x, y = mapTable.Anchor_X, mapTable.Anchor_Y

							--update config
								y = y + config.YOffset
								--not using the scale since there's the scale options already, text color why?, alpha the default is okay
								--anchor:SetScale(1 + config.ScaleOffset)
								--anchor.Title.textcolor = config.TextColor
								--anchor:SetAlpha(config.Alpha)

							WorldQuestTracker.UpdateWorldMapAnchors(x, y, anchor.PinAnchor)
							anchor:ClearAllPoints()
							anchor:SetPoint("center", anchor.PinAnchor, "center", 0, 0)
							anchor.Title:SetText(anchor.AnchorTitle)
						end
					end

				elseif (WorldQuestTracker.db.profile.world_map_config.summary_showby == "bytype") then
					local Y = -24

					--reorder the widgets of this anchor by the order set under the UpdateOrder function
					table.sort(worldSummary.Anchors, anchorReorderFunc)

					local previousAnchor
					--get which point in the world map the anchor is located, can the 'left' or 'right'
					local anchorSide = worldSummary.GetAnchorSide(true)
					local summaryScale = WorldQuestTracker.db.profile.world_map_config.summary_scale
					local padding = -40

					for index, anchor in pairs(worldSummary.Anchors) do
						anchor:ClearAllPoints()
						anchor.mapID = nil

						if (anchorSide == "left") then
							if (previousAnchor) then
								local spacePadding = padding
								local addSecondLine = previousAnchor.WidgetsAmount > worldSummary.MaxWidgetsPerRow and -40 or 0
								anchor:SetPoint("topleft", previousAnchor, "bottomleft", 0, (spacePadding + addSecondLine) * summaryScale)
							else
								anchor:SetPoint("topleft", worldSummary, "topleft", 2, Y)
							end
						else
							if (previousAnchor) then
								local addSecondLine = previousAnchor.WidgetsAmount > worldSummary.MaxWidgetsPerRow and -40 or 0
								anchor:SetPoint("topright", previousAnchor, "bottomright", 0, (padding + addSecondLine) * summaryScale)
							else
								anchor:SetPoint("topright", worldSummary, "topright", -4, Y)
							end
						end

						--anchor.Title:SetText(anchor.AnchorTitle)
						--not showing the anchor name when ordering by the quest type
						if (index == 1) then
							--anchor.Title:SetText("All Quests")
							--anchor.mapID = WorldMapFrame.mapID
							anchor.Title:SetText("")
						else
							anchor.Title:SetText("")
						end

						previousAnchor = anchor
					end
				end
			end

			--giving a type of a quest, this function returns the anchor where that quest should be attached to
			--it also checks if the world map are showing quests by the zone and returns the anchor for that particular zone
			function worldSummary.GetAnchor(filterType, worldQuestType, questName, mapID)
				local anchor, anchorTitle
				local isShowingByZone = WorldQuestTracker.db.profile.world_map_config.summary_showby == "byzone"

				if (not isShowingByZone) then
					--if not showing by the zone, get the anchor based on the type of the quest
					if (filterType == "artifact_power") then
						anchor = worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_ARTIFACTPOWER]]
						anchorTitle = "Artifact Power"

					elseif (filterType == "reputation_token") then
						anchor = worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_REPUTATION]]
						anchorTitle = "Reputation"
						anchor.anchorType = filterType

					elseif (filterType == "garrison_resource") then
						anchor = worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_RESOURCES]]
						anchorTitle = "Resources"

					elseif (filterType == "equipment") then
						anchor = worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_EQUIPMENT]]
						anchorTitle = "Equipment"

					elseif (filterType == "gold") then
						anchor = worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_GOLD]]
						anchorTitle = "Gold"

					elseif (filterType == "pet_battles") then
						anchor = worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_PETBATTLE]]
						anchorTitle = "Pet Battles"

					elseif (filterType == "racing") then
						anchor = worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_RACING]]
						anchorTitle = "Racing"

					else
						anchor = worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_MISC]]
						anchorTitle = "Misc"
					end

					anchor.mapID = nil
				else
					--return the anchor chosen to hold quests of this zone
					local anchorIndex = worldSummary.ZoneAnchors[mapID]

					if (not anchorIndex) then
						anchorIndex = worldSummary.ZoneAnchors.NextAnchor
						worldSummary.ZoneAnchors [mapID] = anchorIndex

						if (worldSummary.ZoneAnchors.NextAnchor < worldSummary.AnchorAmount) then
							worldSummary.ZoneAnchors.NextAnchor = worldSummary.ZoneAnchors.NextAnchor + 1
						end
					end

					anchor = worldSummary.Anchors [anchorIndex]
					anchor.mapID = mapID
					anchorTitle = WorldQuestTracker.GetMapName(mapID)
				end

				anchor:Show()
				anchor.InUse = true
				anchor.AnchorTitle = anchorTitle
				return anchor
			end

			--get the values set by the use in the sort order menu and arrange anchors by those values
			--if showing by the zone,
			function worldSummary.UpdateOrder()
				local order = WorldQuestTracker.db.profile.sort_order
				--artifact power
				worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_ARTIFACTPOWER]].AnchorOrder = math.abs(order [WQT_QUESTTYPE_APOWER] -(WQT_QUESTTYPE_MAX + 1))
				--resource
				worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_RESOURCES]].AnchorOrder = math.abs(order [WQT_QUESTTYPE_RESOURCE] -(WQT_QUESTTYPE_MAX + 1))
				--equipment
				worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_EQUIPMENT]].AnchorOrder = math.abs(order [WQT_QUESTTYPE_EQUIPMENT] -(WQT_QUESTTYPE_MAX + 1))
				--gold
				worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_GOLD]].AnchorOrder = math.abs(order [WQT_QUESTTYPE_GOLD] -(WQT_QUESTTYPE_MAX + 1))
				--reputation
				worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_REPUTATION]].AnchorOrder = math.abs(order [WQT_QUESTTYPE_REPUTATION] -(WQT_QUESTTYPE_MAX + 1))
				--misc
				worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_MISC]].AnchorOrder = 100
				--7th anchor
				worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_MISC2]].AnchorOrder = 101
				--pet_battles
				worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_PETBATTLE]].AnchorOrder = math.abs(order [WQT_QUESTTYPE_PETBATTLE] -(WQT_QUESTTYPE_MAX + 1))
				--racing
				worldSummary.AnchorsByQuestType [worldSummary.QuestTypesByIndex [worldSummary.QuestTypes.ANCHORTYPE_RACING]].AnchorOrder = math.abs(order [WQT_QUESTTYPE_RACING] -(WQT_QUESTTYPE_MAX + 1))
			end

			--reorder widgets within the anchor, sorting by the questID, time left and selected faction
			--called when a world quest is added and when it is refreshing the faction anchor
			--at this point, widgets in the anchor are full refreshed and showing correct information
			function worldSummary.ReorderAnchorWidgets(anchor)

				local isSortByTime = WorldQuestTracker.db.profile.force_sort_by_timeleft
				local isShowingByZone = WorldQuestTracker.db.profile.world_map_config.summary_showby == "byzone"

				--calculate the weight of the quest to give to the sort function
				if (not isShowingByZone) then
					--showing by the quest reward type

					for i = 1, #anchor.Widgets do
						local widget = anchor.Widgets [i]

						if (isSortByTime) then
							widget.WidgetOrder =(widget.TimeLeft * 10) +(widget.questID / 100)
						else
							local orderPoints = widget.questID + abs(widget.TimeLeft - 1440) * 10

							--move quests for the selected fation to show first
							if (widget.FactionID == worldSummary.FactionSelected) then
								orderPoints = orderPoints + 200000
							end

							--move quest for the selected criteria(dailly quest from a faction)
							if (widget.IsCriteria) then
								orderPoints = orderPoints + 100000
							end

							widget.WidgetOrder = orderPoints
						end
					end
				else
					--if showing by zone, sort by what the user has selected in the sort order menu or by the time left if the user has selected it

					for i = 1, #anchor.Widgets do
						local widget = anchor.Widgets [i]

						if (isSortByTime) then
							widget.WidgetOrder =(widget.TimeLeft * 10) +(widget.questID / 100)
						else
							widget.WidgetOrder = widget.Order +(widget.questID / 100000)
						end
					end
				end

				if (isSortByTime) then
					table.sort(anchor.Widgets, function(widget1, widget2)
						return widget1.WidgetOrder > widget2.WidgetOrder
					end)
				else
					table.sort(anchor.Widgets, function(widget1, widget2)
						return widget1.WidgetOrder < widget2.WidgetOrder
					end)
				end

				--sort the reputation by faction id when not using show by zone
				if (not isShowingByZone and not isSortByTime) then
					if (anchor.anchorType == "reputation_token") then
						table.sort(anchor.Widgets, function(widget1, widget2)
							return widget1.FactionID < widget2.FactionID --attempt to compare nil with number
						end)
					end
				end

				local growDirection
				--get which side the summary is anchored to, can be a string 'left' or 'right'
				local anchorSide = worldSummary.GetAnchorSide(false, anchor)

				if (anchorSide == "left") then
					--make the squares grow to right direction
					growDirection = "right"
					anchor.Title:ClearAllPoints()
					anchor.Title:SetPoint("bottomleft", anchor, "topleft", 0, 0)

				elseif (anchorSide == "right") then
					--make the squares grow to left direction
					growDirection = "left"
					anchor.Title:ClearAllPoints()
					anchor.Title:SetPoint("bottomright", anchor, "topright", 2, 0)
				end

				local X, Y = 1, -1
				--by default make the anchor be the latest widget in the anchor
				--if the anchor has a breakline, make the anchor be the last widget in the first row
				local trackAllButtonAnchor = anchor.Widgets [#anchor.Widgets]

				--reorder the squares by settings its point
				local nextBreakLine = worldSummary.MaxWidgetsPerRow
				for i = 1, #anchor.Widgets do
					local widget = anchor.Widgets [i]
					widget:ClearAllPoints()
						widget.WidgetAnchorID = i

					if (growDirection == "right") then
						widget:SetPoint("topleft", anchor, "topleft", X, Y)
						X = X + 25
						if (i == nextBreakLine) then
							trackAllButtonAnchor = widget
							Y = Y - 40
							X = 1
							nextBreakLine = nextBreakLine + worldSummary.MaxWidgetsPerRow
						end

					elseif (growDirection == "left") then
						widget:SetPoint("topright", anchor, "topright", X, Y)
						X = X - 25
						if (i == nextBreakLine) then
							trackAllButtonAnchor = widget
							Y = Y - 40
							X = 1
							nextBreakLine = nextBreakLine + worldSummary.MaxWidgetsPerRow
						end
					end
				end

				--set the point of the track all quests
				anchor.Button:ClearAllPoints()
				anchor.Button.Texture:ClearAllPoints()

				if (growDirection == "right") then
					anchor.Button:SetPoint("left", trackAllButtonAnchor, "right", 1, 0)
					anchor.Button.Texture:SetRotation(math.pi * 2 * .75)
					anchor.Button.Texture:SetPoint("left", anchor.Button.widget, "left", -16, 0)

				elseif (growDirection == "left") then
					anchor.Button:SetPoint("right", trackAllButtonAnchor, "left", -1, 0)
					anchor.Button.Texture:SetRotation(math.pi / 2)
					anchor.Button.Texture:SetPoint("right", anchor.Button.widget, "right", 16, 0)

				end
				anchor.Button:Show()
			end

			--update anchors for the faction button in the topleft or topright corners
			function worldSummary.UpdateFactionAnchor()
				local factionAnchor = worldSummary.FactionAnchor
				local anchorSide = worldSummary.GetAnchorSide(true)
				factionAnchor:ClearAllPoints()

				local anchorWidth = 0
				local anchorHeight = 0
				local buttonId = 1
				local amountShown = 0
				local previousFactionButton
				local buttonWidth = 25

				--set the point of each individual button
				local widgetWidget = factionAnchor.Widgets [1]:GetWidth() + 3
				for buttonIndex, factionButton in ipairs(factionAnchor.Widgets) do
					factionButton:ClearAllPoints()
					local mapId = WorldQuestTracker.GetCurrentMapAreaID()
					local factionsOfTheMap = WorldQuestTracker.GetFactionsAllowedOnMap(mapId)

					if (factionsOfTheMap) then
						if (factionsOfTheMap[factionButton.FactionID]) then
							if (anchorSide == "left") then
								if (not previousFactionButton) then
									factionButton:SetPoint("bottomleft", factionAnchor, "bottomleft", 0, 0)
								else
									factionButton:SetPoint("left", previousFactionButton, "right", 5, 0)
								end

							elseif (anchorSide == "right") then
								if (buttonId == 1) then
									factionButton:SetPoint("center", factionAnchor, "topright", 0, 0)
								else
									factionButton:SetPoint("center", factionAnchor, "topright", -widgetWidget *(buttonId-1), 0)
								end
							end

							previousFactionButton = factionButton

							buttonWidth = factionButton:GetWidth() + 5
							anchorWidth = anchorWidth + factionButton:GetWidth() + 3
							anchorHeight = factionButton:GetHeight()

							--see the reputation amount and change the alpha
							local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfoByID(factionButton.FactionID)
							local repAmount = barValue
							barMax = barMax - barMin
							barValue = barValue - barMin
							barMin = 0

							if (repAmount > 41900) then --exalted
								factionButton:SetAlpha(1)
								local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionButton.FactionID)
								if (hasRewardPending) then
									factionButton.paragonRewardIcon:Show()
									factionButton.glowTexture:Show()
									factionButton.paragonRewardIcon.glowAnimation:Play()
								else
									factionButton.paragonRewardIcon:Hide()
									factionButton.glowTexture:Hide()
								end
							else
								factionButton:SetAlpha(1)
							end

							buttonId = buttonId + 1
							factionButton:Show()
							amountShown = amountShown + 1
						else
							--this faction shouldn't show on this map
							factionButton:Hide()
						end
					else
						--no faction is supported by this map
						--hide all?
						factionButton:Hide()
					end
				end

				factionAnchor:SetSize(amountShown * buttonWidth, 40) --~factionachor
				factionAnchor:ClearAllPoints()
				factionAnchor:SetPoint("bottom", anchorFrame, "bottom", 1, 2)

				--print("factions shown:?", amountShown)
				--DF:ApplyStandardBackdrop(factionAnchor)

				if (WorldQuestTracker.db.profile.show_faction_frame) then
					factionAnchor:Show()
				else
					factionAnchor:Hide()
				end
			end

			--create faction buttons ~faction
			function worldSummary.CreateFactionButtons()
				local playerFaction = UnitFactionGroup("player")
				local factionButtonIndex = 1

				--anchor frame
				local factionAnchor = CreateFrame("frame", nil, worldSummary, "BackdropTemplate")
				factionAnchor:SetSize(1, 1)
				factionAnchor.Widgets = {}
				factionAnchor.WidgetsByFactionID = {}
				worldSummary.FactionAnchor = factionAnchor
				factionAnchor:SetAlpha(ALPHA_BLEND_AMOUNT)

				--scripts
				local buttonOnEnter = function(self)
					self.MyObject.Icon:SetBlendMode("BLEND")

					--local data = C_MajorFactions.GetMajorFactionData(self.MyObject.FactionID)

					--dumpt(data)
					--[=[
						["unlockDescription"] = "Complete the quest For the Benefit of the Queen near the Ruby Life Pools in the Waking Shores.",
						["renownReputationEarned"] = 0,
						["bountySetID"] = 119,
						["renownLevel"] = 0,
						["isUnlocked"] = false,
						["factionID"] = 2510,
						["expansionID"] = 9,
						["celebrationSoundKit"] = 213204,
						["name"] = "Valdrakken Accord",
						["renownFanfareSoundKitID"] = 213208,
						["renownLevelThreshold"] = 2500,
						["textureKit"] = "Valdrakken",
						["unlockOrder"] = 4,
					]=]

					--local name = data.name

					local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfoByID(self.MyObject.FactionID)
					barMax = barMax - barMin
					barValue = barValue - barMin
					barMin = 0

					GameCooltip:Preset(2)
					if (WorldMapFrame.isMaximized) then
						GameCooltip:SetOwner(self)
					else
						GameCooltip:SetOwner(self, "top", "bottom", 0, -30)
					end

					GameCooltip:AddLine(name)
					GameCooltip:AddIcon(WorldQuestTracker.MapData.FactionIcons [factionID], 1, 1, 20, 20, .1, .9, .1, .9)

					local currentValue, threshold, rewardQuestID, hasRewardPending, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(factionID)
					if (not tooLowLevelForParagon and rewardQuestID and currentValue and threshold) then
						--shows paragon statusbar
						local value = currentValue % threshold
						GameCooltip:AddLine("Paragon", HIGHLIGHT_FONT_COLOR_CODE.." "..format(REPUTATION_PROGRESS_FORMAT, BreakUpLargeNumbers(value), BreakUpLargeNumbers(threshold))..FONT_COLOR_CODE_CLOSE)
						GameCooltip:AddIcon([[Interface\GossipFrame\VendorGossipIcon]], 1, 1, 20, 20, 0, 1, 0, 1)
						GameCooltip:AddStatusBar(value / threshold * 100, 1, 0, 0.65, 0, 0.7, nil, {value = 100, color = {.21, .21, .21, 0.8}, texture = [[Interface\Tooltips\UI-Tooltip-Background]]}, [[Interface\Tooltips\UI-Tooltip-Background]])

					else
						--shows reputation statusbar
						GameCooltip:AddLine(_G ["FACTION_STANDING_LABEL" .. standingID], HIGHLIGHT_FONT_COLOR_CODE.." "..format(REPUTATION_PROGRESS_FORMAT, BreakUpLargeNumbers(barValue), BreakUpLargeNumbers(barMax))..FONT_COLOR_CODE_CLOSE)
						GameCooltip:AddIcon("", 1, 1, 1, 20)
						barValue = max(barValue, 0.001)
						barMax = max(barMax, 0.001)
						GameCooltip:AddStatusBar(barValue / barMax * 100, 1, 0, 0.65, 0, 0.7, nil, {value = 100, color = {.21, .21, .21, 0.8}, texture = [[Interface\Tooltips\UI-Tooltip-Background]]}, [[Interface\Tooltips\UI-Tooltip-Background]])
					end

					GameCooltip:AddLine(L["S_FACTION_TOOLTIP_SELECT"], "", 1, "orange", "orange", 9)
					GameCooltip:AddLine(L["S_FACTION_TOOLTIP_TRACK"], "", 1, "orange", "orange", 9)
					GameCooltip:AddIcon([[Interface\AddOns\WorldQuestTracker\media\ArrowFrozen]], 1, 1, 12, 12, 0.1171, 0.6796, 0.1171, 0.7343)

					GameCooltip:Show()

					if (self.MyObject.OnLeaveAnimation:IsPlaying()) then
						self.MyObject.OnLeaveAnimation:Stop()
					end
					self.MyObject.OnEnterAnimation:Play()

					--play quick flash on squares showing quests of this faction
					for _, widget in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
						if (widget.FactionID == self.MyObject.FactionID) then
							widget.LoopFlash:Play()
						end
					end

					--play quick flash on widgets shown in the world map(quest locations)
					for questCounter, button in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
						if (button.FactionID == self.MyObject.FactionID) then
							button.FactionPulseAnimation:Play()
						end
					end

					WorldQuestTracker.PlayTick(2)
				end

				local buttonOnLeave = function(self)
					self.MyObject.Icon:SetBlendMode("BLEND")
					GameCooltip:Hide()

					if (self.MyObject.OnEnterAnimation:IsPlaying()) then
						self.MyObject.OnEnterAnimation:Stop()
					end
					self.MyObject.OnLeaveAnimation:Play()

					--stop quick flash on squares showing quests of this faction
					for _, widget in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
						if (widget.FactionID == self.MyObject.FactionID) then
							widget.LoopFlash:Stop()
						end
					end

					--stop quick flash on widgets shown in the world map(quest locations)
					for questCounter, button in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
						if (button.FactionID == self.MyObject.FactionID) then
							button.FactionPulseAnimation:Stop()
						end
					end
				end

				--create buttons
				--for factionID, factionInfo in pairs(WorldQuestTracker.MapData.ReputationByFaction [playerFaction]) do
				for factionID, _ in pairs(WorldQuestTracker.MapData.AllFactionIds) do --creates one button for each faction registered
					if (type(factionID) == "number") then
						local factionName = GetFactionInfoByID(factionID)
						if (factionName) then
							local factionButton = DF:CreateButton(factionAnchor, worldSummary.OnSelectFaction, 24, 25, "", factionButtonIndex)

							--animations
							factionButton.OnEnterAnimation = DF:CreateAnimationHub(factionButton, function() end, function() end)
							local anim = WorldQuestTracker:CreateAnimation(factionButton.OnEnterAnimation, "Scale", 1, WQT_ANIMATION_SPEED, 1, 1, 1.1, 1.1, "center", 0, 0)
							anim:SetEndDelay(60) --this fixes the animation going back to 1 after it finishes

							factionButton.OnLeaveAnimation = DF:CreateAnimationHub(factionButton, function() end, function() end)
							WorldQuestTracker:CreateAnimation(factionButton.OnLeaveAnimation, "Scale", 2, WQT_ANIMATION_SPEED, 1.1, 1.1, 1, 1, "center", 0, 0)

							--button widgets
							--factionButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
							factionButton:HookScript("OnEnter", buttonOnEnter)
							factionButton:HookScript("OnLeave", buttonOnLeave)

							factionButton.FactionID = factionID
							factionButton.AmountQuests = 0
							factionAnchor.WidgetsByFactionID [factionID] = factionButton
							factionButton.Index = factionButtonIndex

							DF:CreateBorder(factionButton.widget, 0.85, 0, 0)

							factionButton.OverlayFrame = CreateFrame("frame", nil, factionButton.widget, "BackdropTemplate")
							factionButton.OverlayFrame:SetFrameLevel(factionButton:GetFrameLevel()+1)
							factionButton.OverlayFrame:SetAllPoints()
							DF:CreateBorder(factionButton.OverlayFrame, 1, 0, 0)
							factionButton.OverlayFrame:SetBorderColor(1, .85, 0)
							factionButton.OverlayFrame:SetBorderAlpha(.843, .1, .05)

							local paragonRewardIcon = factionButton:CreateTexture(nil, "overlay")
							paragonRewardIcon:SetTexture([[Interface\GossipFrame\VendorGossipIcon]])
							paragonRewardIcon:SetPoint("topright", factionButton.widget, "topright", 6, 10)

							local glowTexture = factionButton:CreateTexture(nil, "overlay")
							glowTexture:SetTexture([[Interface\PETBATTLES\PetBattle-SelectedPetGlow]])
							glowTexture:SetSize(32, 32)
							glowTexture:SetPoint("center", paragonRewardIcon, "center")
							factionButton.glowTexture = glowTexture

							paragonRewardIcon.glowAnimation = DF:CreateAnimationHub(glowTexture, function() end, function() end)
							WorldQuestTracker:CreateAnimation(paragonRewardIcon.glowAnimation, "Alpha", 1, 0.750, 0.4, 1)
							WorldQuestTracker:CreateAnimation(paragonRewardIcon.glowAnimation, "Alpha", 2, 0.750, 1, 0.4)
							paragonRewardIcon.glowAnimation:SetLooping("REPEAT")

							paragonRewardIcon.anim = paragonRewardIcon.glowAnimation

							paragonRewardIcon:SetDrawLayer("overlay", 6)
							glowTexture:SetDrawLayer("overlay", 5)

							paragonRewardIcon:Hide()
							factionButton.paragonRewardIcon = paragonRewardIcon

							local selectedBorder = factionButton:CreateTexture(nil, "overlay")
							selectedBorder:SetPoint("center")
							selectedBorder:SetTexture([[Interface\Artifacts\Artifacts]])
							selectedBorder:SetTexCoord(137/1024, 195/1024, 920/1024, 978/1024)
							selectedBorder:SetBlendMode("BLEND")
							selectedBorder:SetSize(28, 28)
							selectedBorder:SetAlpha(0)
							factionButton.SelectedBorder = selectedBorder

							local factionIcon = factionButton:CreateTexture(nil, "artwork")
							factionIcon:SetPoint("topleft", factionButton.widget, "topleft", 0, 0)
							factionIcon:SetPoint("bottomright", factionButton.widget, "bottomright", 0, 0)
							factionIcon:SetTexture(WorldQuestTracker.MapData.FactionIcons [factionID])
							factionIcon:SetTexCoord(.1, .9, .1, .96)
							factionButton.Icon = factionIcon

							--add a highlight effect
							local factionIconHighlight = factionButton:CreateTexture(nil, "highlight")
							factionIconHighlight:SetPoint("topleft", factionButton.widget, "topleft", 0, 0)
							factionIconHighlight:SetPoint("bottomright", factionButton.widget, "bottomright", 0, 0)
							factionIconHighlight:SetTexture(WorldQuestTracker.MapData.FactionIcons [factionID])
							factionIconHighlight:SetTexCoord(.1, .9, .1, .96)
							factionIconHighlight:SetBlendMode("ADD")
							factionIconHighlight:SetAlpha(.5)

							--local amountQuestsBackground = factionButton:CreateTexture(nil, "artwork")
							--amountQuestsBackground:SetPoint("bottom", factionIcon, "top", 0, 0)
							--amountQuestsBackground:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
							--amountQuestsBackground:SetSize(34, 12)
							--amountQuestsBackground:SetAlpha(.5)
							--amountQuestsBackground:Hide()

							local amountQuestsBackground2 = factionButton:CreateTexture(nil, "artwork", nil, 3)
							--amountQuestsBackground2:SetPoint("bottomright", factionIcon, "bottomright", 0, 0)
							amountQuestsBackground2:SetPoint("bottomleft", factionIcon, "bottomleft", 0, 0)
							amountQuestsBackground2:SetColorTexture(0, 0, 0, 1)
							amountQuestsBackground2:SetSize(10, 10)

							local amountQuests = factionButton:CreateFontString(nil, "overlay", "GameFontNormal", nil, 4)
							amountQuests:SetPoint("center", amountQuestsBackground2, "center", 0, 0)
							amountQuests:SetDrawLayer("overlay", 6)
							amountQuests:SetAlpha(.832)
							WorldQuestTracker:SetFontSize(amountQuests, 10)
							factionButton.Text = amountQuests
							factionButton.Text:SetText("")

							table.insert(worldSummary.FactionIDs, factionID)
							table.insert(factionAnchor.Widgets, factionButton)
							factionButtonIndex = factionButtonIndex + 1
						end
					end
				end

				worldSummary.FactionSelected = worldSummary.FactionIDs [worldSummary.FactionSelected_OnInit]
				if (not worldSummary.FactionSelected) then
					WorldQuestTracker:Msg("(debug) failed to get the initial faction selection.")
				end

				worldSummary.RefreshFactionButtons()
			end

			function worldSummary.RefreshFactionButtons()
				for i, factionButton in ipairs(worldSummary.FactionAnchor.Widgets) do
					if (factionButton.FactionID == worldSummary.FactionSelected) then
						factionButton.OverlayFrame:SetAlpha(1)
					else
						factionButton.OverlayFrame:SetAlpha(0)
					end
				end
			end

			function worldSummary.OnSelectFaction(self, _, buttonIndex)

				PlaySoundFile("Interface\\AddOns\\WorldQuestTracker\\media\\faction_on_click.ogg")

				if (IsShiftKeyDown()) then
					local questsToTrack = {}

					local factionID = worldSummary.FactionIDs [buttonIndex]

					--get all anchors, check if quests on this anchor are from the faction and track them
					for index, anchor in pairs(worldSummary.Anchors) do
						for i = 1, #anchor.Widgets do
							local widget = anchor.Widgets [i]
							if (widget:IsShown() and widget.questID and widget.FactionID == factionID) then
								table.insert(questsToTrack, widget)
							end
						end
					end

					--lazy add to tracker
					C_Timer.NewTicker(.04, function(tickerObject)
						local widget = tremove(questsToTrack)
						if (widget) then
							WorldQuestTracker.CheckAddToTracker(widget, widget, true)
							local questID = widget.questID

							for _, widget in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
								if (widget.questID == questID and widget:IsShown()) then
									--animations
									if (widget.onEndTrackAnimation:IsPlaying()) then
										widget.onEndTrackAnimation:Stop()
									end
									widget.onStartTrackAnimation:Play()
									if (not widget.AddedToTrackerAnimation:IsPlaying()) then
										widget.AddedToTrackerAnimation:Play()
									end
								end
							end
						else
							tickerObject:Cancel()
						end
					end)
				else
					worldSummary.FactionSelected = worldSummary.FactionIDs [buttonIndex]
					worldSummary.RefreshFactionButtons()
					worldSummary.UpdateFaction()

					--check if is showing a zone map
					if (WorldQuestTracker.GetCurrentZoneType() == "zone") then
						local mapId = WorldQuestTracker.MapData.FactionMapId[worldSummary.FactionSelected]
						--print("faction ID:", worldSummary.FactionSelected)
						if (mapId) then
							--change the map to faction map
							WorldMapFrame:SetMapID(mapId)
							WorldQuestTracker.UpdateZoneWidgets(true)
						end
					end
				end
			end

			--called when pressing a button to select another faction or when the lazy update is finished
			function worldSummary.UpdateFaction()
				for _, widget in pairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
					local conduitType, borderTexture, borderColor, itemLink = WorldQuestTracker.GetConduitQuestData(widget.questID)
					--print("widget.questID = ", widget.questID)
					WorldQuestTracker.UpdateBorder(widget, nil, nil, nil, nil, nil, conduitType, borderTexture, borderColor, itemLink)

					if (widget.FactionID == worldSummary.FactionSelected) then
						--widget.factionBorder:Show()
					else
						widget.factionBorder:Hide()
					end
				end

				for anchorID, anchor in pairs(worldSummary.Anchors) do
					worldSummary.ReorderAnchorWidgets(anchor)
				end
			end

			--hide all anchors, widgets and refresh the order of the anchors
			function worldSummary.ClearSummary()
				worldSummary.UpdateOrder()

				wipe(worldSummary.ScheduleToUpdate)
				wipe(worldSummary.ShownQuests)
				wipe(worldSummary.ZoneAnchors)
				worldSummary.ZoneAnchors.NextAnchor = 1

				worldSummary.WidgetIndex = 1
				worldSummary.TotalGold = 0
				worldSummary.TotalResources = 0
				worldSummary.TotalAPower = 0
				worldSummary.TotalPet = 0

				for _, anchor in pairs(worldSummary.Anchors) do
					anchor:Hide()
					anchor.InUse = false
					anchor.WidgetsAmount = 0
					wipe(anchor.Widgets)
				end

				for _, widget in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
					widget:Hide()
				end

				for _, factionButton in ipairs(worldSummary.FactionAnchor.Widgets) do
					factionButton.AmountQuests = 0
					factionButton.Text:SetText(0)
				end
			end

			function worldSummary.AddQuest(questTable)
				--unpack quest information
				local questID, mapID, numObjectives, questCounter, questName, x, y, filterType, worldQuestType, isCriteria, isNew, timeLeft, order = unpack(questTable)
				local artifactPowerIcon = WorldQuestTracker.MapData.ItemIcons ["BFA_ARTIFACT"]
				local isUsingTracker = WorldQuestTracker.db.profile.use_tracker

				--get the anchor for this quest
				local anchor = worldSummary.GetAnchor(filterType, worldQuestType, questName, mapID)

				--check if need to refresh the anchor positions
				if (anchor.WidgetsAmount == 0) then
					worldSummary.ReAnchor()
				end
				anchor.WidgetsAmount = anchor.WidgetsAmount + 1

				--is this anchor enabled
				if (anchor.mapID) then
					if (not WorldQuestTracker.db.profile.anchor_options [mapID].Enabled) then
						anchor.Button:Hide()
						return
					end
				end

				--get the widget and setup it
				local widget = WorldQuestTracker.WorldSummaryQuestsSquares [worldSummary.WidgetIndex]
				worldSummary.WidgetIndex = worldSummary.WidgetIndex + 1
				table.insert(anchor.Widgets, widget)

				if (not widget) then
					WorldQuestTracker:Msg("exception: AddQuest() while cache still loading, close and reopen the map.")
					return
				end

				widget.WidgetID = worldSummary.WidgetIndex
				widget.questID = questID
				widget.CurrentAnchor = anchor

				widget:SetScale(WorldQuestTracker.db.profile.world_map_config.summary_scale)
				widget:Show()
				widget.Anchor = anchor
				widget.Order = order
				widget.X = x
				widget.Y = y

				local okay, gold, resource, apower = WorldQuestTracker.UpdateWorldWidget(widget, questID, numObjectives, mapID, isCriteria, isNew, isUsingTracker, timeLeft, artifactPowerIcon)
				widget.texture:SetTexCoord(.1, .9, .1, .9)

				if (widget.FactionID == worldSummary.FactionSelected) then
					--widget.factionBorder:Show()
				else
					widget.factionBorder:Hide()
				end

				local factionButton = worldSummary.FactionAnchor.WidgetsByFactionID [widget.FactionID]
				if (factionButton) then
					factionButton.AmountQuests = factionButton.AmountQuests + 1
					factionButton.Text:SetText(factionButton.AmountQuests)
				end

				widget:SetAlpha(WorldQuestTracker.db.profile.world_summary_alpha)

				if (okay) then
					if (gold) then worldSummary.TotalGold = worldSummary.TotalGold + gold end
					if (resource) then worldSummary.TotalResources = worldSummary.TotalResources + resource end
					if (apower) then worldSummary.TotalAPower = worldSummary.TotalAPower + apower end

					if (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
						worldSummary.TotalPet = worldSummary.TotalPet + 1
					end

					if (WorldQuestTracker.WorldMap_GoldIndicator) then
						WorldQuestTracker.WorldMap_GoldIndicator.text = floor(worldSummary.TotalGold / 10000)

						if (worldSummary.TotalResources > 999) then
							WorldQuestTracker.WorldMap_ResourceIndicator.text = WorldQuestTracker.ToK(worldSummary.TotalResources)
						else
							WorldQuestTracker.WorldMap_ResourceIndicator.text = floor(worldSummary.TotalResources)
						end

						--update the amount of artifact power
						if (worldSummary.TotalResources > 999) then
							WorldQuestTracker.WorldMap_APowerIndicator.text = WorldQuestTracker.ToK(worldSummary.TotalAPower)
						else
							WorldQuestTracker.WorldMap_APowerIndicator.text = floor(worldSummary.TotalAPower)
						end

						WorldQuestTracker.WorldMap_APowerIndicator.Amount = worldSummary.TotalAPower

						WorldQuestTracker.WorldMap_PetIndicator.text = worldSummary.TotalPet
					end

					if (WorldQuestTracker.db.profile.show_timeleft) then
						--timePriority is now zero instead of false if disabled
						local timePriority = WorldQuestTracker.db.profile.sort_time_priority and WorldQuestTracker.db.profile.sort_time_priority * 60 --4 8 12 16 24

						--reset the widget alpha
						widget:SetAlpha(WorldQuestTracker.db.profile.world_summary_alpha)

						if (timePriority and timePriority > 0) then
							if (timeLeft <= timePriority) then
								DF:SetFontColor(widget.timeLeftText, "yellow")
								widget.timeLeftText:SetAlpha(1)
							else
								DF:SetFontColor(widget.timeLeftText, "white")
								widget.timeLeftText:SetAlpha(0.8)

								if (WorldQuestTracker.db.profile.alpha_time_priority) then
									widget:SetAlpha(ALPHA_BLEND_AMOUNT - 0.35)
								end
							end
						else
							DF:SetFontColor(widget.timeLeftText, "white")
							widget.timeLeftText:SetAlpha(1)
						end

						widget.timeLeftText:SetText(timeLeft > 1440 and floor(timeLeft/1440) .. "d" or timeLeft > 60 and floor(timeLeft/60) .. "h" or timeLeft .. "m")

						--widget.timeLeftText:SetJustifyH("center")
						widget.timeLeftText:SetJustifyH("center")
						widget.timeLeftText:Show()
					else
						widget.timeLeftText:Hide()
						widget:SetAlpha(WorldQuestTracker.db.profile.world_summary_alpha)
					end
				end

				if (anchor.WidgetsAmount == worldSummary.MaxWidgetsPerRow + 1) then
					worldSummary.ReAnchor()
				end

				worldSummary.ReorderAnchorWidgets(anchor)

				--save the quest in the quests shown in the world summary
				worldSummary.ShownQuests [questID] = widget
			end

			function worldSummary.LazyUpdate(self, deltaTime)
				--if framerate is low, update more quests at the same time
				local frameRate = GetFramerate()
				local amountToUpdate = 2 +(not WorldQuestTracker.db.profile.hoverover_animations and 5 or 0)

				if (frameRate < 20) then
					amountToUpdate = amountToUpdate + 3
				elseif (frameRate < 30) then
					amountToUpdate = amountToUpdate + 2
				elseif (frameRate < 40) then
					amountToUpdate = amountToUpdate + 1
				end

				for i = 1, amountToUpdate do
					if (WorldMapFrame:IsShown() and #worldSummary.ScheduleToUpdate > 0 and WorldQuestTracker.IsWorldQuestHub(WorldMapFrame.mapID)) then
						local questTable = tremove(worldSummary.ScheduleToUpdate)
						if (questTable) then
							--check if the quest is already shown(return the widget being use to show the quest)
							local alreadyShown = worldSummary.ShownQuests [questTable [1]]
							if (alreadyShown) then
								--quick update the quest widget
								WorldQuestTracker.UpdateWorldWidget(alreadyShown, true)
								worldSummary.ReorderAnchorWidgets(alreadyShown.Anchor)
							else
								worldSummary.AddQuest(questTable)
							end
						end
					else
						--is still on the map?
						if (WorldQuestTracker.IsWorldQuestHub(WorldMapFrame.mapID)) then
							worldSummary.UpdateFaction()
						end
						--shutdown lazy updates
						worldSummary:SetScript("OnUpdate", nil)
					end
				end
			end

			--questsToUpdate is a hash table with questIDs to update
			--it only exists when it's not a full update and it carry a small list of quests to update
			--the list is equal to questList but is hash with true values
			function worldSummary.Update(questList, questsToUpdate)
				if (not WorldQuestTracker.db.profile.world_map_config.summary_show) then
					worldSummary.HideSummary()
					return
				end
				worldSummary.UpdateMaxWidgetsPerRow()

				worldSummary.ShowSummary()
				worldSummary.RefreshSummaryAnchor()

				--clear all if this is a full update
				if (not questsToUpdate) then
					worldSummary.ClearSummary()
				end

				--copy the quest list
				worldSummary.ScheduleToUpdate = DF.table.copy({}, questList)

				worldSummary:SetScript("OnUpdate", worldSummary.LazyUpdate)

				--adjust the artifact power icon for each region
				local questHubByExp = WorldQuestTracker.MapData.ExpMaps[WorldMapFrame.mapID]
				local texture
				if (questHubByExp == 9) then --shadowlands
					texture = WorldQuestTracker.MapData.ArtifactPowerSummaryIcons.SHADOWLANDS_ARTIFACT
				elseif (questHubByExp == 8) then --bfa
					texture = WorldQuestTracker.MapData.ArtifactPowerSummaryIcons.BFA_ARTIFACT
				elseif (questHubByExp == 7) then --legion
					texture = WorldQuestTracker.MapData.ArtifactPowerSummaryIcons.LEGION_ARTIFACT
				end

				if (texture) then
					WorldQuestTracker.WorldMap_APowerIndicatorTexture:SetTexture(texture)
					WorldQuestTracker.WorldMap_APowerIndicatorTexture:SetSize(16, 16)
					WorldQuestTracker.WorldMap_APowerIndicatorTexture:SetTexCoord(0, 1, 0, 1)
				end
			end

			-- ~bar ~statusbar

			WorldQuestTracker.ParentTapFrame = CreateFrame("frame", "WorldQuestTrackerParentTapFrame", anchorFrame, "BackdropTemplate")
			WorldQuestTracker.DoubleTapFrame = CreateFrame("frame", "WorldQuestTrackerDoubleTapFrame", anchorFrame, "BackdropTemplate")
			WorldQuestTracker.DoubleTapFrame:SetHeight(18)
			WorldQuestTracker.DoubleTapFrame:SetFrameLevel(WorldMapFrame.SidePanelToggle.CloseButton:GetFrameLevel()-1)
			WorldQuestTracker.ParentTapFrame:SetAllPoints()

			--background
			local doubleTapBackground = WorldQuestTracker.DoubleTapFrame:CreateTexture(nil, "artwork")
			doubleTapBackground:SetColorTexture(0, 0, 0, 0.5)
			doubleTapBackground:SetHeight(18)
			WorldQuestTracker.DoubleTapFrame.Background = doubleTapBackground

			--border
			local doubleTapBorder = WorldQuestTracker.DoubleTapFrame:CreateTexture(nil, "overlay")
			doubleTapBorder:SetTexture([[Interface\AddOns\WorldQuestTracker\media\golden_line]])
			doubleTapBorder:SetHorizTile(true)
			doubleTapBorder:SetPoint("topleft", doubleTapBackground, "topleft")
			doubleTapBorder:SetPoint("topright", doubleTapBackground, "topright")

			WorldQuestTracker.DoubleTapFrame.BackgroundTexture = doubleTapBackground
			WorldQuestTracker.DoubleTapFrame.BackgroundBorder = doubleTapBorder

			function WorldQuestTracker:SetStatusBarAnchor(anchor)
				anchor = anchor or WorldQuestTracker.db.profile.bar_anchor
				WorldQuestTracker.db.profile.bar_anchor = anchor
				WorldQuestTracker.UpdateStatusBarAnchors()
			end

			---------------------------------------------------------

			local SummaryFrame = CreateFrame("frame", "WorldQuestTrackerSummaryPanel", WorldQuestTrackerWorldMapPOI, "BackdropTemplate")
			SummaryFrame:SetPoint("topleft", WorldQuestTrackerWorldMapPOI, "topleft", 0, 0)
			SummaryFrame:SetPoint("bottomright", WorldQuestTrackerWorldMapPOI, "bottomright", 0, 0)
			SummaryFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
			SummaryFrame:SetBackdropColor(0, 0, 0, 1)
			SummaryFrame:SetBackdropBorderColor(0, 0, 0, 1)
			SummaryFrame:SetFrameStrata("DIALOG")
			SummaryFrame:SetFrameLevel(3500)
			SummaryFrame:EnableMouse(true)
			SummaryFrame:Hide()

			SummaryFrame.RightBorder = SummaryFrame:CreateTexture(nil, "overlay")
			SummaryFrame.RightBorder:SetTexture([[Interface\ACHIEVEMENTFRAME\UI-Achievement-HorizontalShadow]])
			SummaryFrame.RightBorder:SetTexCoord(1, 0, 0, 1)
			SummaryFrame.RightBorder:SetPoint("topright")
			SummaryFrame.RightBorder:SetPoint("bottomright")
			SummaryFrame.RightBorder:SetPoint("topleft")
			SummaryFrame.RightBorder:SetPoint("bottomleft")
			SummaryFrame.RightBorder:SetWidth(125)
			SummaryFrame.RightBorder:SetDesaturated(true)
			SummaryFrame.RightBorder:SetDrawLayer("background", -7)

			local SummaryFrameUp = CreateFrame("frame", "WorldQuestTrackerSummaryUpPanel", SummaryFrame, "BackdropTemplate")
			SummaryFrameUp:SetPoint("topleft", WorldQuestTrackerWorldMapPOI, "topleft", 0, 0)
			SummaryFrameUp:SetPoint("bottomright", WorldQuestTrackerWorldMapPOI, "bottomright", 0, 0)
			SummaryFrameUp:SetFrameLevel(3501)
			SummaryFrameUp:Hide()

			local SummaryFrameDown = CreateFrame("frame", "WorldQuestTrackerSummaryDownPanel", SummaryFrame, "BackdropTemplate")
			SummaryFrameDown:SetPoint("topleft", WorldQuestTrackerWorldMapPOI, "topleft", 0, 0)
			SummaryFrameDown:SetPoint("bottomright", WorldQuestTrackerWorldMapPOI, "bottomright", 0, 0)
			SummaryFrameDown:SetFrameLevel(3499)
			SummaryFrameDown:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
			SummaryFrameDown:SetBackdropColor(0, 0, 0, 1)
			SummaryFrameDown:SetBackdropBorderColor(0, 0, 0, 1)
			SummaryFrameDown:Hide()

			local CloseSummaryPanel = CreateFrame("button", "WorldQuestTrackerCloseSummaryButton", SummaryFrameUp, "BackdropTemplate")
			CloseSummaryPanel:SetSize(64, 32)
			CloseSummaryPanel:SetPoint("right", WorldMapFrame.SidePanelToggle, "left", -2, 0)
			CloseSummaryPanel.Background = CloseSummaryPanel:CreateTexture(nil, "background")
			CloseSummaryPanel.Background:SetSize(64, 32)
			CloseSummaryPanel.Background:SetAtlas("MapCornerShadow-Right")
			CloseSummaryPanel.Background:SetPoint("bottomright", 2, -1)
			CloseSummaryPanel:SetNormalTexture([[Interface\AddOns\WorldQuestTracker\media\close_summary_button]])
			CloseSummaryPanel:GetNormalTexture():SetTexCoord(0, 1, 0, .5)
			CloseSummaryPanel:SetPushedTexture([[Interface\AddOns\WorldQuestTracker\media\close_summary_button_pushed]])
			CloseSummaryPanel:GetPushedTexture():SetTexCoord(0, 1, 0, .5)

			CloseSummaryPanel.Highlight = CloseSummaryPanel:CreateTexture(nil, "highlight")
			CloseSummaryPanel.Highlight:SetTexture([[Interface\Buttons\UI-Common-MouseHilight]])
			CloseSummaryPanel.Highlight:SetBlendMode("ADD")
			CloseSummaryPanel.Highlight:SetSize(64*1.5, 32*1.5)
			CloseSummaryPanel.Highlight:SetPoint("center")

			CloseSummaryPanel:SetScript("OnClick", function()
				SummaryFrame.HideAnimation:Play()
				SummaryFrameUp.HideAnimation:Play()
				SummaryFrameDown.HideAnimation:Play()
			end)

			SummaryFrame:SetScript("OnMouseDown", function(self, button)
				if (button == "RightButton") then
					--SummaryFrame:Hide()
					--SummaryFrameUp:Hide()
					SummaryFrame.HideAnimation:Play()
					SummaryFrameUp.HideAnimation:Play()
					SummaryFrameDown.HideAnimation:Play()
				end
			end)

			local x = 10

			local TitleTemplate = DF:GetTemplate("font", "WQT_SUMMARY_TITLE")

			local accountLifeTime_Texture = DF:CreateImage(SummaryFrameUp, [[Interface\BUTTONS\AdventureGuideMicrobuttonAlert]], 16, 16, "artwork", {5/32, 27/32, 5/32, 27/32})
			accountLifeTime_Texture:SetPoint(x, -10)
			accountLifeTime_Texture:SetAlpha(.7)

			local characterLifeTime_Texture = DF:CreateImage(SummaryFrameUp, [[Interface\BUTTONS\AdventureGuideMicrobuttonAlert]], 16, 16, "artwork", {5/32, 27/32, 5/32, 27/32})
			characterLifeTime_Texture:SetPoint(x, -97)
			characterLifeTime_Texture:SetAlpha(.7)

			local graphicTime_Texture = DF:CreateImage(SummaryFrameUp, [[Interface\BUTTONS\AdventureGuideMicrobuttonAlert]], 16, 16, "artwork", {5/32, 27/32, 5/32, 27/32})
			graphicTime_Texture:SetPoint(x, -228)
			graphicTime_Texture:SetAlpha(.7)

			local otherCharacters_Texture = DF:CreateImage(SummaryFrameUp, [[Interface\BUTTONS\AdventureGuideMicrobuttonAlert]], 16, 16, "artwork", {5/32, 27/32, 5/32, 27/32})
			otherCharacters_Texture:SetPoint("topleft", SummaryFrameUp, "topright", -220, -10)
			otherCharacters_Texture:SetAlpha(.7)

			local accountLifeTime = DF:CreateLabel(SummaryFrameUp, L["S_SUMMARYPANEL_LIFETIMESTATISTICS_ACCOUNT"] .. "(BfA):", TitleTemplate)
			accountLifeTime:SetPoint("left", accountLifeTime_Texture, "right", 2, 1)
			SummaryFrameUp.AccountLifeTime_Gold = DF:CreateLabel(SummaryFrameUp, L["S_QUESTTYPE_GOLD"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_Resources = DF:CreateLabel(SummaryFrameUp, L["S_QUESTTYPE_RESOURCE"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_APower = DF:CreateLabel(SummaryFrameUp, L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_QCompleted = DF:CreateLabel(SummaryFrameUp, L["S_QUESTSCOMPLETED"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_Gold:SetPoint(x, -30)
			SummaryFrameUp.AccountLifeTime_Resources:SetPoint(x, -45)
			SummaryFrameUp.AccountLifeTime_APower:SetPoint(x, -60)
			SummaryFrameUp.AccountLifeTime_QCompleted:SetPoint(x, -75)

			local characterLifeTime = DF:CreateLabel(SummaryFrameUp, L["S_SUMMARYPANEL_LIFETIMESTATISTICS_CHARACTER"] .. "(BfA):", TitleTemplate)
			characterLifeTime:SetPoint("left", characterLifeTime_Texture, "right", 2, 1)
			SummaryFrameUp.CharacterLifeTime_Gold = DF:CreateLabel(SummaryFrameUp, L["S_QUESTTYPE_GOLD"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_Resources = DF:CreateLabel(SummaryFrameUp, L["S_QUESTTYPE_RESOURCE"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_APower = DF:CreateLabel(SummaryFrameUp, L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_QCompleted = DF:CreateLabel(SummaryFrameUp, L["S_QUESTSCOMPLETED"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_Gold:SetPoint(x, -120)
			SummaryFrameUp.CharacterLifeTime_Resources:SetPoint(x, -135)
			SummaryFrameUp.CharacterLifeTime_APower:SetPoint(x, -150)
			SummaryFrameUp.CharacterLifeTime_QCompleted:SetPoint(x, -165)

			function WorldQuestTracker.UpdateSummaryFrame()

				local acctLifeTime = WorldQuestTracker.QueryHistory(WQT_QUERYTYPE_REWARD, WQT_QUERYDB_ACCOUNT)
				acctLifeTime = acctLifeTime or {}
				local questsLifeTime = WorldQuestTracker.QueryHistory(WQT_QUERYTYPE_QUEST, WQT_QUERYDB_ACCOUNT)
				questsLifeTime = questsLifeTime or {}

				SummaryFrameUp.AccountLifeTime_Gold.text = format(L["S_QUESTTYPE_GOLD"] .. ": %s",(acctLifeTime.gold or 0) > 0 and GetCoinTextureString(acctLifeTime.gold) or 0)
				SummaryFrameUp.AccountLifeTime_Resources.text = format(L["S_QUESTTYPE_RESOURCE"] .. ": %s", WorldQuestTracker.ToK(acctLifeTime.resource or 0))
				SummaryFrameUp.AccountLifeTime_APower.text = format(L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s", WorldQuestTracker.ToK(acctLifeTime.artifact or 0))
				SummaryFrameUp.AccountLifeTime_QCompleted.text = format(L["S_QUESTSCOMPLETED"] .. ": %s", DF:CommaValue(questsLifeTime.total or 0))

				local chrLifeTime = WorldQuestTracker.QueryHistory(WQT_QUERYTYPE_REWARD, WQT_QUERYDB_LOCAL)
				chrLifeTime = chrLifeTime or {}
				local questsLifeTime = WorldQuestTracker.QueryHistory(WQT_QUERYTYPE_QUEST, WQT_QUERYDB_LOCAL)
				questsLifeTime = questsLifeTime or {}

				SummaryFrameUp.CharacterLifeTime_Gold.text = format(L["S_QUESTTYPE_GOLD"] .. ": %s",(chrLifeTime.gold or 0) > 0 and GetCoinTextureString(chrLifeTime.gold) or 0)
				SummaryFrameUp.CharacterLifeTime_Resources.text = format(L["S_QUESTTYPE_RESOURCE"] .. ": %s", WorldQuestTracker.ToK(chrLifeTime.resource or 0))
				SummaryFrameUp.CharacterLifeTime_APower.text = format(L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s", WorldQuestTracker.ToK(chrLifeTime.artifact or 0))
				SummaryFrameUp.CharacterLifeTime_QCompleted.text = format(L["S_QUESTSCOMPLETED"] .. ": %s", DF:CommaValue(questsLifeTime.total or 0))

			end

			----------

			SummaryFrameUp.ShowAnimation = DF:CreateAnimationHub(SummaryFrameUp,
			function()
				SummaryFrameUp:Show()
				WorldQuestTracker.UpdateSummaryFrame()
				SummaryFrameUp.CharsQuestsScroll:Refresh()
			end,
			function()
				SummaryFrameDown.ShowAnimation:Play()
			end)
			DF:CreateAnimation(SummaryFrameUp.ShowAnimation, "Alpha", 1, .15, 0, 1)

			SummaryFrame.ShowAnimation = DF:CreateAnimationHub(SummaryFrame,
				function()
					SummaryFrame:Show()
					if (WorldQuestTracker.db.profile.sound_enabled) then
						if (math.random(5) == 1) then
							PlaySoundFile("Interface\\AddOns\\WorldQuestTracker\\media\\swap_panels1.mp3")
						else
							PlaySoundFile("Interface\\AddOns\\WorldQuestTracker\\media\\swap_panels2.mp3")
						end
					end
				end,
				function()
					SummaryFrameUp.ShowAnimation:Play()
				end)
			DF:CreateAnimation(SummaryFrame.ShowAnimation, "Scale", 1, .1, .1, 1, 1, 1, "left", 0, 0)

			SummaryFrame.HideAnimation = DF:CreateAnimationHub(SummaryFrame, function()
				--PlaySound("igMainMenuOptionCheckBoxOn")
			end,
				function()
					SummaryFrame:Hide()
				end)
			DF:CreateAnimation(SummaryFrame.HideAnimation, "Scale", 1, .1, 1, 1, .1, 1, "left", 1, 0)

			SummaryFrameUp.HideAnimation = DF:CreateAnimationHub(SummaryFrameUp, _,
				function()
					SummaryFrameUp:Hide()
				end)
			DF:CreateAnimation(SummaryFrameUp.HideAnimation, "Alpha", 1, .1, 1, 0)

			SummaryFrameDown.ShowAnimation = DF:CreateAnimationHub(SummaryFrameDown,
				function()
					SummaryFrameDown:Show()
				end,
				function()
					SummaryFrameDown:SetAlpha(.7)
				end
			)
			DF:CreateAnimation(SummaryFrameDown.ShowAnimation, "Alpha", 1, 3, 0, .7)

			SummaryFrameDown.HideAnimation = DF:CreateAnimationHub(SummaryFrameDown, function()
				SummaryFrameDown.ShowAnimation:Stop()
			end,
			function()
				SummaryFrameDown:Hide()
			end)
			DF:CreateAnimation(SummaryFrameDown.HideAnimation, "Alpha", 1, .1, 1, 0)
			-----------

			local scroll_refresh = function()

			end

			local AllQuests = WorldQuestTracker.db.profile.quests_all_characters
			local formated_quest_table = {}
			local chrGuid = UnitGUID("player")
			for guid, questTable in pairs(AllQuests or {}) do
				if (guid ~= chrGuid) then
					table.insert(formated_quest_table, {"blank"})
					table.insert(formated_quest_table, {true, guid})
					table.insert(formated_quest_table, {"blank"})
					for questID, questInfo in pairs(questTable or {}) do
						table.insert(formated_quest_table, {questID, questInfo})
					end
				end
			end

			local scroll_line_height = 14
			local scroll_line_amount = 26
			local scroll_width = 195

			local line_onenter = function(self)
				if (self.questID) then
					self.numObjectives = 10
					self.UpdateTooltip = TaskPOI_OnEnter
					TaskPOI_OnEnter(self)
					self:SetBackdropColor(.5, .50, .50, 0.75)
				end
			end
			local line_onleave = function(self)
				TaskPOI_OnLeave(self)
				self:SetBackdropColor(0, 0, 0, 0.2)
			end
			local line_onclick = function()

			end

			local scroll_createline = function(self, index)
				local line = CreateFrame("button", "$parentLine" .. index, self, "BackdropTemplate")
				line:SetPoint("topleft", self, "topleft", 0, -((index-1)*(scroll_line_height+1)))
				line:SetSize(scroll_width, scroll_line_height)
				line:SetScript("OnEnter", line_onenter)
				line:SetScript("OnLeave", line_onleave)
				line:SetScript("OnClick", line_onclick)

				line:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
				line:SetBackdropColor(0, 0, 0, 0.2)

				local icon = line:CreateTexture("$parentIcon", "overlay")
				icon:SetSize(scroll_line_height, scroll_line_height)
				local name = line:CreateFontString("$parentName", "overlay", "GameFontNormal")
				DF:SetFontSize(name, 9)
				icon:SetPoint("left", line, "left", 2, 0)
				name:SetPoint("left", icon, "right", 2, 0)
				local timeleft = line:CreateFontString("$parentTimeLeft", "overlay", "GameFontNormal")
				DF:SetFontSize(timeleft, 9)
				timeleft:SetPoint("right", line, "right", -2, 0)
				line.icon = icon
				line.name = name
				line.timeleft = timeleft
				name:SetHeight(10)
				name:SetJustifyH("left")

				return line
			end

			local scroll_refresh = function(self, data, offset, total_lines)
				for i = 1, total_lines do
					local index = i + offset
					local quest = data [index]

					if (quest) then
						local line = self:GetLine(i)
						line:SetAlpha(1)
						line.questID = nil
						if (quest [1] == "blank") then
							line.name:SetText("")
							line.timeleft:SetText("")
							line.icon:SetTexture(nil)

						elseif (quest [1] == true) then
							local name, realm, class = WorldQuestTracker.GetCharInfo(quest [2])
							local color = RAID_CLASS_COLORS [class]
							local name = name .. " - " .. realm
							if (color) then
								name = "|c" .. color.colorStr .. name .. "|r"
							end
							line.name:SetText(name)
							line.timeleft:SetText("")
							line.name:SetWidth(180)

							if (class) then
								line.icon:SetTexture([[Interface\WORLDSTATEFRAME\Icons-Classes]])
								line.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS [class]))
							else
								line.icon:SetTexture(nil)
							end
						else
							local questInfo = quest [2]
							local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info(quest [1])

							title = title or L["S_UNKNOWNQUEST"]

							local rewardAmount = questInfo.rewardAmount
							if (questInfo.questType == QUESTTYPE_GOLD) then
								rewardAmount = floor(questInfo.rewardAmount / 10000)
							end

							local colorByRarity = ""

							--[=[
							if (rarity  == LE_WORLD_QUEST_QUALITY_EPIC) then
								colorByRarity = "FFC845F9"
							elseif (rarity  == LE_WORLD_QUEST_QUALITY_RARE) then
								colorByRarity = "FF0091F2"
							else
								colorByRarity = "FFFFFFFF"
							end
							--]=]

							colorByRarity = "FFFFFFFF"

							local timeLeft =((questInfo.expireAt - time()) / 60) --segundos / 60
							local color
							if (timeLeft > 120) then
								color = "FFFFFFFF"
							elseif (timeLeft > 45) then
								color = "FFFFAA22"
							else
								color = "FFFF3322"
							end

							if (type(questInfo.rewardTexture) == "string" and questInfo.rewardTexture:find("icon_artifactpower")) then
								--for�ando sempre mostrar icone vermelho
								line.icon:SetTexture([[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blueT]])

								--format the artifact power amount
								if (rewardAmount > 100000) then
									rewardAmount = WorldQuestTracker.ToK(rewardAmount)
								end

							else
								line.icon:SetTexture(questInfo.rewardTexture)
							end

							line.name:SetText("|cFFFFDD00[" .. rewardAmount .. "]|r |c" .. colorByRarity .. title .. "|r")
							line.timeleft:SetText(timeLeft > 0 and "|c" .. color .. SecondsToTime(timeLeft * 60) .. "|r" or "|cFFFF5500" .. L["S_SUMMARYPANEL_EXPIRED"] .. "|r")

							line.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
							line.name:SetWidth(100)

							if (timeLeft <= 0) then
								line:SetAlpha(.5)
							end

							line.questID = quest [1]
						end
					end
				end
			end

			local ScrollTitle = DF:CreateLabel(SummaryFrameUp, L["S_SUMMARYPANEL_OTHERCHARACTERS"] .. ":", TitleTemplate)
			ScrollTitle:SetPoint("left", otherCharacters_Texture, "right", 2, 1)

			local CharsQuestsScroll = DF:CreateScrollBox(SummaryFrameUp, "$parentChrQuestsScroll", scroll_refresh, formated_quest_table, scroll_width, 400, scroll_line_amount, scroll_line_height)
			CharsQuestsScroll:SetPoint("topright", SummaryFrameUp, "topright", -25, -30)
			for i = 1, scroll_line_amount do
				CharsQuestsScroll:CreateLine(scroll_createline)
			end
			SummaryFrameUp.CharsQuestsScroll = CharsQuestsScroll
			CharsQuestsScroll:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
			CharsQuestsScroll:SetBackdropColor(0, 0, 0, .4)

			-----------

			local GF_LineOnEnter = function(self)
				GameCooltip:Preset(2)
				GameCooltip:SetOption("TextSize", 10)
				GameCooltip:SetOption("ButtonsYMod", -2)
				GameCooltip:SetOption("YSpacingMod", 1)
				GameCooltip:SetOption("FixedHeight", 95)

				local today = self.data.table

				local t = WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_GOLD]
				GameCooltip:AddLine(t.name .. ":", today.gold and today.gold > 0 and GetCoinTextureString(today.gold) or 0, 1, "white", "orange")
				GameCooltip:AddIcon(t.icon, 1, 1, 16, 16)

				local t = WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_RESOURCE]
				GameCooltip:AddLine(t.name .. ":", DF:CommaValue(today.resource or 0), 1, "white", "orange")
				GameCooltip:AddIcon(t.icon, 1, 1, 14, 14)

				local t = WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_APOWER]
				GameCooltip:AddLine(t.name .. ":", DF:CommaValue(today.artifact or 0), 1, "white", "orange")
				GameCooltip:AddIcon(t.icon, 1, 1, 16, 16)

				local t = WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_TRADE]
				GameCooltip:AddLine(t.name .. ":", DF:CommaValue(today.blood or 0), 1, "white", "orange")
				GameCooltip:AddIcon(t.icon, 1, 1, 16, 16, unpack(t.coords))

				GameCooltip:AddLine(L["S_QUESTSCOMPLETED"] .. ":", today.quest or 0, 1, "white", "orange")
				GameCooltip:AddIcon([[Interface\GossipFrame\AvailableQuestIcon]], 1, 1, 16, 16)

				GameCooltip:ShowCooltip(self)
			end
			local GF_LineOnLeave = function(self)
				GameCooltip:Hide()
			end

			-- ~gframe
			local GoldGraphic = DF:CreateGFrame(SummaryFrameUp, 422, 160, 28, GF_LineOnEnter, GF_LineOnLeave, "GoldGraphic", "WorldQuestTrackerGoldGraphic")
			GoldGraphic:SetPoint("topleft", 40, -248)
			GoldGraphic:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
			GoldGraphic:SetBackdropColor(0, 0, 0, .6)

			local GoldGraphicTextBg = CreateFrame("frame", nil, GoldGraphic, "BackdropTemplate")
			GoldGraphicTextBg:SetPoint("topleft", GoldGraphic, "bottomleft", 0, -2)
			GoldGraphicTextBg:SetPoint("topright", GoldGraphic, "bottomright", 0, -2)
			GoldGraphicTextBg:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
			GoldGraphicTextBg:SetBackdropColor(0, 0, 0, .4)
			GoldGraphicTextBg:SetHeight(20)
			--DF:CreateBorder(GoldGraphic, .4, .2, .05)

			local leftLine = DF:CreateImage(GoldGraphic)
			leftLine:SetColorTexture(1, 1, 1, .35)
			leftLine:SetSize(1, 160)
			leftLine:SetPoint("topleft", GoldGraphic, "topleft", -1, 0)
			leftLine:SetPoint("bottomleft", GoldGraphic, "bottomleft", -1, -20)

			local bottomLine = DF:CreateImage(GoldGraphic)
			bottomLine:SetColorTexture(1, 1, 1, .35)
			bottomLine:SetSize(422, 1)
			bottomLine:SetPoint("bottomleft", GoldGraphic, "bottomleft", -35, -2)
			bottomLine:SetPoint("bottomright", GoldGraphic, "bottomright", 0, -2)

			GoldGraphic.AmountIndicators = {}
			for i = 0, 5 do
				local text = DF:CreateLabel(GoldGraphic, "")
				text:SetPoint("topright", GoldGraphic, "topleft", -4, -(i*32) - 2)
				text.align = "right"
				text.textcolor = "silver"
				table.insert(GoldGraphic.AmountIndicators, text)
				local line = DF:CreateImage(GoldGraphic)
				line:SetColorTexture(1, 1, 1, .05)
				line:SetSize(420, 1)
				line:SetPoint(0, -(i*32))
			end

			local GoldGraphicTitle = DF:CreateLabel(SummaryFrameUp, L["S_SUMMARYPANEL_LAST15DAYS"] .. ":", TitleTemplate)
			--GoldGraphicTitle:SetPoint("bottomleft", GoldGraphic, "topleft", 0, 6)
			GoldGraphicTitle:SetPoint("left", graphicTime_Texture, "right", 2, 1)

			local GraphicDataToUse = 1
			local OnSelectGraphic = function(_, _, value)
				GraphicDataToUse = value
				SummaryFrameUp.RefreshGraphic()
			end

			local class = select(2, UnitClass("player"))
			local color = RAID_CLASS_COLORS [class] and RAID_CLASS_COLORS [class].colorStr or "FFFFFFFF"
			local graphic_options = {
				{label = L["S_OVERALL"] .. " [|cFFC0C0C0" .. L["S_MAPBAR_SUMMARYMENU_ACCOUNTWIDE"] .. "|r]", value = 1, onclick = OnSelectGraphic,
				icon = [[Interface\GossipFrame\BankerGossipIcon]], iconsize = {14, 14}}, --texcoord = {3/32, 29/32, 3/32, 29/32}
				{label = L["S_QUESTTYPE_GOLD"] .. " [|cFFC0C0C0" .. L["S_MAPBAR_SUMMARYMENU_ACCOUNTWIDE"] .. "|r]", value = 2, onclick = OnSelectGraphic,
				icon = WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_GOLD].icon, iconsize = {14, 14}},
				{label = L["S_QUESTTYPE_RESOURCE"] .. " [|c" .. color .. UnitName("player") .. "|r]", value = 3, onclick = OnSelectGraphic,
				icon = WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_RESOURCE].icon, iconsize = {14, 14}},
				{label = L["S_QUESTTYPE_ARTIFACTPOWER"] .. " [|c" .. color .. UnitName("player") .. "|r]", value = 4, onclick = OnSelectGraphic,
				icon = WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_APOWER].icon, iconsize = {14, 14}}
			}
			local graphic_options_func = function()
				return graphic_options
			end

			local dropdown_diff = DF:CreateDropDown(SummaryFrameUp, graphic_options_func, 1, 180, 20, "dropdown_graphic", _, DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
			dropdown_diff:SetPoint("left", GoldGraphicTitle, "right", 4, 0)

			local empty_day = {
				["artifact"] = 0,
				["resource"] = 0,
				["quest"] = 0,
				["gold"] = 0,
				["blood"] = 0,
			}

			SummaryFrameUp.RefreshGraphic = function()
				GoldGraphic:Reset()

				local twoWeeks
				local dateString

				if (GraphicDataToUse == 1 or GraphicDataToUse == 2) then --account overall
					twoWeeks = WorldQuestTracker.QueryHistory(WQT_QUERYTYPE_PERIOD, WQT_QUERYDB_ACCOUNT, WQT_DATE_2WEEK)
					dateString = WorldQuestTracker.GetDateString(WQT_DATE_2WEEK)
				elseif (GraphicDataToUse == 3 or GraphicDataToUse == 4) then
					twoWeeks = WorldQuestTracker.QueryHistory(WQT_QUERYTYPE_PERIOD, WQT_QUERYDB_LOCAL, WQT_DATE_2WEEK)
					dateString = WorldQuestTracker.GetDateString(WQT_DATE_2WEEK)
				end

				local data = {}
				for i = 1, #dateString do
					local hadTable = false
					twoWeeks = twoWeeks or {}
					for o = 1, #twoWeeks do
						if (twoWeeks[o].day == dateString[i]) then
							if (GraphicDataToUse == 1) then
								local gold =(twoWeeks[o].table.gold and twoWeeks[o].table.gold/10000) or 0
								local resource = twoWeeks[o].table.resource or 0
								local artifact = twoWeeks[o].table.artifact or 0
								local blood =(twoWeeks[o].table.blood and twoWeeks[o].table.blood*300) or 0

								local total = gold + resource + artifact + blood

								data [#data+1] = {value = total or 0, text = dateString[i]:gsub("^%d%d%d%d", ""), table = twoWeeks[o].table}
								hadTable = true

							elseif (GraphicDataToUse == 2) then
								local gold =(twoWeeks[o].table.gold and twoWeeks[o].table.gold/10000) or 0
								data [#data+1] = {value = gold, text = dateString[i]:gsub("^%d%d%d%d", ""), table = twoWeeks[o].table}
								hadTable = true

							elseif (GraphicDataToUse == 3) then
								local resource = twoWeeks[o].table.resource or 0
								data [#data+1] = {value = resource, text = dateString[i]:gsub("^%d%d%d%d", ""), table = twoWeeks[o].table}
								hadTable = true

							elseif (GraphicDataToUse == 4) then
								local artifact = twoWeeks[o].table.artifact or 0
								data [#data+1] = {value = artifact, text = dateString[i]:gsub("^%d%d%d%d", ""), table = twoWeeks[o].table}
								hadTable = true
							end
							break
						end
					end
					if (not hadTable) then
						data [#data+1] = {value = 0, text = dateString[i]:gsub("^%d%d%d%d", ""), table = empty_day}
					end

				end

				data = DF.table.reverse(data)
				GoldGraphic:UpdateLines(data)

				for i = 1, 5 do
					local text = GoldGraphic.AmountIndicators [i]
					local percent = 20 * abs(i - 6)
					local total = GoldGraphic.MaxValue / 100 * percent
					text.text = WorldQuestTracker.ToK(total)
				end

				--customize text anchor
				for _, line in ipairs(GoldGraphic._lines) do
					line.timeline:SetPoint("bottomright", line, "bottomright", -2, -18)
				end
			end

			GoldGraphic:SetScript("OnShow", function(self)
				SummaryFrameUp.RefreshGraphic()
			end)

			-----------

			local buttons_width = 65

			local setup_button = function(button, name)
				button:SetSize(buttons_width, 16)
				button:SetFrameLevel(1000)

				button.Text = button:CreateFontString(nil, "overlay", "GameFontNormal")
				button.Text:SetText(name)

				WorldQuestTracker:SetFontSize(button.Text, 10)
				WorldQuestTracker:SetFontColor(button.Text, "orange")
				button.Text:SetPoint("center")

				local shadow = button:CreateTexture(nil, "background")
				shadow:SetPoint("center")
				shadow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
				shadow:SetSize(buttons_width+10, 10)
				shadow:SetAlpha(.3)
			end

			local button_onenter = function(self)
				WorldQuestTracker:SetFontColor(self.Text, "WQT_ORANGE_ON_ENTER")
			end
			local button_onleave = function(self)
				WorldQuestTracker:SetFontColor(self.Text, "orange")
			end

			WorldQuestTracker.SetupStatusbarButton = setup_button
			WorldQuestTracker.OnEnterStatusbarButton = button_onenter
			WorldQuestTracker.OnLeaveStatusbarButton = button_onleave


			---------------------------------------------------------
			--options button
			local optionsButton = CreateFrame("button", "WorldQuestTrackerOptionsButton", WorldQuestTracker.ParentTapFrame, "BackdropTemplate")
			--point is set on WorldQuestTracker.UpdateStatusBarAnchors()
			optionsButton:SetScript("OnClick", function()
				WorldQuestTracker.OpenOptionsPanel()
			end)
			setup_button(optionsButton, L["S_MAPBAR_OPTIONS"]) --~options

			---------------------------------------------------------



			---------------------------------------------------------



			---------------------------------------------------------
			-- ~time left

			local change_sort_timeleft_mode = function(_, _, amount)
				if (WorldQuestTracker.db.profile.sort_time_priority == amount) then
					WorldQuestTracker.db.profile.sort_time_priority = 0
				else
					WorldQuestTracker.db.profile.sort_time_priority = amount
				end

				GameCooltip:Hide()

				--atualiza as quests

				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
				elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
					WorldQuestTracker.UpdateZoneWidgets()
				end
			end

			local timeLeftButton = CreateFrame("button", "WorldQuestTrackerTimeLeftButton", WorldQuestTracker.ParentTapFrame, "BackdropTemplate")
			timeLeftButton:SetPoint("left", optionsButton, "right", 0, 0)
			setup_button(timeLeftButton, L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_TITLE"])


			local buildTimeLeftMenu = function()
				GameCooltip:Preset(2)
				GameCooltip:SetOption("TextSize", 10)
				GameCooltip:SetOption("FixedWidth", 180)
				GameCooltip:SetOption("FixedWidthSub", 180)
				GameCooltip:SetOption("SubMenuIsTooltip", true)
				GameCooltip:SetOption("IgnoreArrows", true)

				GameCooltip:AddLine(L["S_OPTIONS_TIMELEFT_NOPRIORITY"])
				GameCooltip:AddMenu(1, change_sort_timeleft_mode, 0)
				if (WorldQuestTracker.db.profile.sort_time_priority == 0) then
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end

				GameCooltip:AddLine(format(L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"], 4))
				GameCooltip:AddMenu(1, change_sort_timeleft_mode, 4)
				if (WorldQuestTracker.db.profile.sort_time_priority == 4) then
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end

				GameCooltip:AddLine(format(L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"], 8), "", 1)
				GameCooltip:AddMenu(1, change_sort_timeleft_mode, 8)
				if (WorldQuestTracker.db.profile.sort_time_priority == 8) then
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end

				GameCooltip:AddLine(format(L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"], 12), "", 1)
				GameCooltip:AddMenu(1, change_sort_timeleft_mode, 12)
				if (WorldQuestTracker.db.profile.sort_time_priority == 12) then
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end

				GameCooltip:AddLine(format(L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"], 16), "", 1)
				GameCooltip:AddMenu(1, change_sort_timeleft_mode, 16)
				if (WorldQuestTracker.db.profile.sort_time_priority == 16) then
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end

				GameCooltip:AddLine(format(L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"], 24), "", 1)
				GameCooltip:AddMenu(1, change_sort_timeleft_mode, 24)
				if (WorldQuestTracker.db.profile.sort_time_priority == 24) then
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end

				GameCooltip:AddLine("$div", nil, 1, nil, -5, -11)

				GameCooltip:AddLine(L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_SHOWTEXT"], "", 1)
				GameCooltip:AddMenu(1, options_on_click, "show_timeleft", not WorldQuestTracker.db.profile.show_timeleft)
				if (WorldQuestTracker.db.profile.show_timeleft) then
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end

				GameCooltip:AddLine(L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_FADE"], "", 1)
				GameCooltip:AddMenu(1, options_on_click, "alpha_time_priority", not WorldQuestTracker.db.profile.alpha_time_priority)
				if (WorldQuestTracker.db.profile.alpha_time_priority) then
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end

				GameCooltip:AddLine(L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_SORTBYTIME"], "", 1)
				GameCooltip:AddMenu(1, options_on_click, "force_sort_by_timeleft", not WorldQuestTracker.db.profile.force_sort_by_timeleft)
				if (WorldQuestTracker.db.profile.force_sort_by_timeleft) then
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end

			end

			timeLeftButton.CoolTip = {
				Type = "menu",
				BuildFunc = buildTimeLeftMenu, --> called when user mouse over the frame
				OnEnterFunc = function(self)
					timeLeftButton.button_mouse_over = true
					button_onenter(self)
				end,
				OnLeaveFunc = function(self)
					timeLeftButton.button_mouse_over = false
					button_onleave(self)
				end,
				FixedValue = "none",
				ShowSpeed = 0.05,
				Options = function()
					if (WorldQuestTracker.db.profile.bar_anchor == "top") then
						GameCooltip:SetOption("MyAnchor", "top")
						GameCooltip:SetOption("RelativeAnchor", "bottom")
						GameCooltip:SetOption("WidthAnchorMod", 0)
						GameCooltip:SetOption("HeightAnchorMod", -10)
					else
						GameCooltip:SetOption("MyAnchor", "bottom")
						GameCooltip:SetOption("RelativeAnchor", "top")
						GameCooltip:SetOption("WidthAnchorMod", 0)
						GameCooltip:SetOption("HeightAnchorMod", -5)
					end
				end,
			}

			GameCooltip:CoolTipInject(timeLeftButton)


			--sort options
			local sortButton = CreateFrame("button", "WorldQuestTrackerSortButtonStatusBar", WorldQuestTracker.ParentTapFrame, "BackdropTemplate")
			sortButton:SetPoint("left", timeLeftButton, "right", 2, 0)
			setup_button(sortButton, L["S_MAPBAR_SORTORDER"])

			-- ~sort
			local change_sort_mode = function(a, b, questType, _, _, mouseButton)
				local currentIndex = WorldQuestTracker.db.profile.sort_order [questType]
				if (currentIndex < WQT_QUESTTYPE_MAX) then
					for type, order in pairs(WorldQuestTracker.db.profile.sort_order) do
						if (WorldQuestTracker.db.profile.sort_order [type] == currentIndex+1) then
							WorldQuestTracker.db.profile.sort_order [type] = currentIndex
							break
						end
					end

					WorldQuestTracker.db.profile.sort_order [questType] = WorldQuestTracker.db.profile.sort_order [questType] + 1
				end

				GameCooltip:ExecFunc(sortButton)
			---------------------------------------------------------

				--atualiza as quests
				if (WorldQuestTracker.IsWorldQuestHub(WorldQuestTracker.GetCurrentMapAreaID())) then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
				end
			end

			local overlayColor = {.5, .5, .5, 1}
			local BuildSortMenu = function()
				local t = {}
				for type, order in pairs(WorldQuestTracker.db.profile.sort_order) do
					table.insert(t, {type, order})
				end
				table.sort(t, function(a, b) return a[2] > b[2] end)

				GameCooltip:Preset(2)
				GameCooltip:SetOption("TextSize", 10)
				GameCooltip:SetOption("FixedWidth", 180)

				--warning: this looks like is running in protective mode without any error message

				for i = 1, #t do
					local questInfoTable = t[i]
					local questType = questInfoTable[1]
					local info = WorldQuestTracker.MapData.QuestTypeIcons[questType]
					local bIsEnabled = WorldQuestTracker.db.profile.filters[WorldQuestTracker.QuestTypeToFilter[questType]]

					if (bIsEnabled) then
						GameCooltip:AddLine(info.name)
						GameCooltip:AddIcon(info.icon, 1, 1, 16, 16, unpack(info.coords))
						GameCooltip:AddIcon([[Interface\BUTTONS\UI-MicroStream-Yellow]], 1, 2, 16, 16, 0, 1, 1, 0, overlayColor, nil, true)
					else
						GameCooltip:AddLine(info.name, _, _, "silver")
						local l, r, t, b = unpack(info.coords)
						GameCooltip:AddIcon(info.icon, 1, 1, 16, 16, l, r, t, b, _, _, true)
					end

					GameCooltip:AddMenu(1, change_sort_mode, questType)
				end
			end

			sortButton.CoolTip = {
				Type = "menu",
				BuildFunc = BuildSortMenu, --> called when user mouse over the frame
				OnEnterFunc = function(self)
					sortButton.button_mouse_over = true
					button_onenter(self)
				end,
				OnLeaveFunc = function(self)
					sortButton.button_mouse_over = false
					button_onleave(self)
				end,
				FixedValue = "none",
				ShowSpeed = 0.05,
				Options = function()

					if (WorldQuestTracker.db.profile.bar_anchor == "top") then
						GameCooltip:SetOption("MyAnchor", "top")
						GameCooltip:SetOption("RelativeAnchor", "bottom")
						GameCooltip:SetOption("WidthAnchorMod", 0)
						GameCooltip:SetOption("HeightAnchorMod", -10)
					else
						GameCooltip:SetOption("MyAnchor", "bottom")
						GameCooltip:SetOption("RelativeAnchor", "top")
						GameCooltip:SetOption("WidthAnchorMod", 0)
						GameCooltip:SetOption("HeightAnchorMod", -5)
					end

				end
			}

			GameCooltip:CoolTipInject(sortButton, openOnClick)


			--filter button
			local filterButton = CreateFrame("button", "WorldQuestTrackerFilterButton", WorldQuestTracker.ParentTapFrame, "BackdropTemplate")
			filterButton:SetPoint("left", sortButton, "right", 0, 0)
			setup_button(filterButton, L["S_MAPBAR_FILTER"])

			local filter_quest_type = function(_, _, questType, _, _, mouseButton)
				WorldQuestTracker.db.profile.filters[questType] = not WorldQuestTracker.db.profile.filters[questType]

				GameCooltip:ExecFunc(filterButton)

				--atualiza as quests
				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
				elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
					WorldQuestTracker.UpdateZoneWidgets()
				end
			end

			local toggle_faction_objectives = function()
				WorldQuestTracker.db.profile.filter_always_show_faction_objectives = not WorldQuestTracker.db.profile.filter_always_show_faction_objectives
				GameCooltip:ExecFunc(filterButton)

				--atualiza as quests
				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
				elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
					WorldQuestTracker.UpdateZoneWidgets()
				end
			end

			local toggle_brokenshore_bypass = function()
				WorldQuestTracker.db.profile.filter_force_show_brokenshore = not WorldQuestTracker.db.profile.filter_force_show_brokenshore
				GameCooltip:ExecFunc(filterButton)
				--atualiza as quests
				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
				elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
					WorldQuestTracker.UpdateZoneWidgets()
				end
			end

			if (WorldQuestTracker.db.profile.filter_force_show_brokenshore) then
				GameCooltip:AddLine("Ignore New Zones", "", 1, "orange")
				GameCooltip:AddLine("World quets on new zones will always be shown.\n\nCurrent new zones:\n-Najatar\n-Machagon.", "", 2)
				GameCooltip:AddIcon([[Interface\ICONS\70_inscription_vantus_rune_tomb]], 1, 1, 23*.54, 37*.40, 0, 1, 0, 1)
				GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 2, 16, 16, 0, 1, 0, 1, overlayColor, nil, true)
			else
				GameCooltip:AddLine("Ignore New Zones", "", 1, "silver")
				GameCooltip:AddLine("World quets on new zones will always be shown.\n\nCurrent new zones:\n-Najatar\n-Machagon", "", 2)
				--GameCooltip:AddIcon([[Interface\ICONS\70_inscription_vantus_rune_tomb]], 1, 1, 23*.54, 37*.40, l, r, t, b, nil, nil, true)
			end
			GameCooltip:AddMenu(1, toggle_brokenshore_bypass)
			--]=]

			local toggle_filters_all_on = function()
				for filterType, canShow in pairs(WorldQuestTracker.db.profile.filters) do
					local questType = filterType
					WorldQuestTracker.db.profile.filters [questType] = true
				end

				GameCooltip:ExecFunc(filterButton)

				--update quest on current map shown
				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)

				elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
					WorldQuestTracker.UpdateZoneWidgets()
				end
			end

			local toggle_filters_all_off = function()
				for filterType, canShow in pairs(WorldQuestTracker.db.profile.filters) do
					local questType = filterType
					WorldQuestTracker.db.profile.filters[questType] = false
				end

				GameCooltip:ExecFunc(filterButton)

				--update quest on current map shown
				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)

				elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
					WorldQuestTracker.UpdateZoneWidgets()
				end
			end

			local BuildFilterMenu = function()
				GameCooltip:Preset(2)
				GameCooltip:SetOption("TextSize", 10)
				GameCooltip:SetOption("FixedWidth", 180)
				GameCooltip:SetOption("FixedWidthSub", 200)
				GameCooltip:SetOption("SubMenuIsTooltip", true)
				GameCooltip:SetOption("IgnoreArrows", true)

				local t = {}
				for filterType, canShow in pairs(WorldQuestTracker.db.profile.filters) do
					local sortIndex = WorldQuestTracker.db.profile.sort_order[WorldQuestTracker.FilterToQuestType[filterType]]
					table.insert(t, {filterType, sortIndex})
				end

				table.sort(t, function(a, b) return a[2] > b[2] end)

				for i, filter in ipairs(t) do
					local filterType = filter [1]
					local info = WorldQuestTracker.MapData.QuestTypeIcons[WorldQuestTracker.FilterToQuestType[filterType]]
					local isEnabled = WorldQuestTracker.db.profile.filters[filterType]
					if (isEnabled) then
						GameCooltip:AddLine(info.name)
						GameCooltip:AddIcon(info.icon, 1, 1, 16, 16, unpack(info.coords))
						GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 2, 16, 16, 0, 1, 0, 1, overlayColor, nil, true)
					else
						GameCooltip:AddLine(info.name, _, _, "silver")
						local l, r, t, b = unpack(info.coords)
						GameCooltip:AddIcon(info.icon, 1, 1, 16, 16, l, r, t, b, _, _, true)
					end
					GameCooltip:AddMenu(1, filter_quest_type, filterType)
				end

				GameCooltip:AddLine("$div")

				GameCooltip:AddLine("Select All")
				GameCooltip:AddMenu(1, toggle_filters_all_on)

				GameCooltip:AddLine("Select None")
				GameCooltip:AddMenu(1, toggle_filters_all_off)

				GameCooltip:AddLine("$div")

				local l, r, t, b = unpack(WorldQuestTracker.MapData.GeneralIcons.CRITERIA.coords)

				if (WorldQuestTracker.db.profile.filter_always_show_faction_objectives) then
					GameCooltip:AddLine(L["S_MAPBAR_FILTERMENU_FACTIONOBJECTIVES"])
					GameCooltip:AddLine(L["S_MAPBAR_FILTERMENU_FACTIONOBJECTIVES_DESC"], "", 2)
					GameCooltip:AddIcon(WorldQuestTracker.MapData.GeneralIcons.CRITERIA.icon, 1, 1, 23*.54, 37*.40, l, r, t, b)
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 2, 16, 16, 0, 1, 0, 1, overlayColor, nil, true)
				else
					GameCooltip:AddLine(L["S_MAPBAR_FILTERMENU_FACTIONOBJECTIVES"], "", 1, "silver")
					GameCooltip:AddLine(L["S_MAPBAR_FILTERMENU_FACTIONOBJECTIVES_DESC"], "", 2)
					GameCooltip:AddIcon(WorldQuestTracker.MapData.GeneralIcons.CRITERIA.icon, 1, 1, 23*.54, 37*.40, l, r, t, b, nil, nil, true)
				end
				GameCooltip:AddMenu(1, toggle_faction_objectives)

				GameCooltip:AddLine("$div")

				--[= --this is deprecated at the moment, but might be needed again in the future
				if (WorldQuestTracker.db.profile.filter_force_show_brokenshore) then
					GameCooltip:AddLine("Ignore New Zones", "", 1, "orange")
					GameCooltip:AddLine("World quets on new zones will always be shown.\n\nCurrent new zones:\n-Najatar\n-Machagon.", "", 2)
					GameCooltip:AddIcon([[Interface\ICONS\70_inscription_vantus_rune_tomb]], 1, 1, 23*.54, 37*.40, 0, 1, 0, 1)
					GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 2, 16, 16, 0, 1, 0, 1, overlayColor, nil, true)
				else
					GameCooltip:AddLine("Ignore New Zones", "", 1, "silver")
					GameCooltip:AddLine("World quets on new zones will always be shown.\n\nCurrent new zones:\n-Najatar\n-Machagon", "", 2)
					--GameCooltip:AddIcon([[Interface\ICONS\70_inscription_vantus_rune_tomb]], 1, 1, 23*.54, 37*.40, l, r, t, b, nil, nil, true)
				end
				GameCooltip:AddMenu(1, toggle_brokenshore_bypass)
				--]=]
			end

			filterButton.CoolTip = {
				Type = "menu",
				BuildFunc = BuildFilterMenu, --> called when user mouse over the frame
				OnEnterFunc = function(self)
					filterButton.button_mouse_over = true
					button_onenter(self)
				end,
				OnLeaveFunc = function(self)
					filterButton.button_mouse_over = false
					button_onleave(self)
				end,
				FixedValue = "none",
				ShowSpeed = 0.05,
				Options = function()

					if (WorldQuestTracker.db.profile.bar_anchor == "top") then
						GameCooltip:SetOption("MyAnchor", "top")
						GameCooltip:SetOption("RelativeAnchor", "bottom")
						GameCooltip:SetOption("WidthAnchorMod", 0)
						GameCooltip:SetOption("HeightAnchorMod", -10)
					else
						GameCooltip:SetOption("MyAnchor", "bottom")
						GameCooltip:SetOption("RelativeAnchor", "top")
						GameCooltip:SetOption("WidthAnchorMod", 0)
						GameCooltip:SetOption("HeightAnchorMod", -5)
					end

				end,
			}

			GameCooltip:CoolTipInject(filterButton)

			--end of filter button

			function WorldQuestTracker.RefreshStatusBarButtons()
				timeLeftButton:Hide()
				sortButton:Hide()
				filterButton:Hide()

				local buttonShown = {}
				if (WorldQuestTracker.db.profile.show_timeleft_button) then
					timeLeftButton:Show()
					buttonShown[#buttonShown+1] = timeLeftButton
				end

				if (WorldQuestTracker.db.profile.show_sort_button) then
					sortButton:Show()
					buttonShown[#buttonShown+1] = sortButton
				end

				if (WorldQuestTracker.db.profile.show_filter_button) then
					filterButton:Show()
					buttonShown[#buttonShown+1] = filterButton
				end

				--iterage among shown buttons and set the point
				for i = 1, #buttonShown do
					local button = buttonShown[i]
					if (i == 1) then
						button:SetPoint("left", optionsButton, "right", 5, 0)
					else
						button:SetPoint("left", buttonShown[i-1], "right", 2, 0)
					end
				end
			end

			C_Timer.After(1, WorldQuestTracker.RefreshStatusBarButtons)

			---------------------------------------------------------
			-- ~map ~anchor ~�nchor
			-- WorldQuestTracker.MapAnchorButton - need to remove all references of this button

			---------------------------------------------------------

			local button_onLeave = function(self)
				GameCooltip:Hide()
				button_onleave(self)
			end

			--build option menu

			local BuildOptionsMenu = function() -- �ptions ~options
				GameCooltip:Preset(2)
				GameCooltip:SetOption("TextSize", 10)
				GameCooltip:SetOption("FixedWidth", 180)

				local IconSize = 14

				--create a sub menu for the map frame scale
				--[=[ -- ~review
				GameCooltip:AddLine(L["S_OPTIONS_MAPFRAME_SCALE"])
				GameCooltip:AddIcon([[Interface\COMMON\UI-ModelControlPanel]], 1, 1, 16, 16, 20/64, 34/64, 38/128, 52/128)
				--is enabled?
				GameCooltip:AddLine(L["S_OPTIONS_MAPFRAME_SCALE_ENABLED"], "", 2)
				add_checkmark_icon(WorldQuestTracker.db.profile.map_frame_scale_enabled)
				GameCooltip:AddMenu(2, options_on_click, "map_frame_scale_enabled", not WorldQuestTracker.db.profile.map_frame_scale_enabled)
				--increase and decrease the map scale
				GameCooltip:AddLine(L["S_INCREASESIZE"], "", 2)
				GameCooltip:AddIcon([[Interface\BUTTONS\UI-MicroStream-Yellow]], 2, 1, 16, 16, 0, 1, 1, 0)
				GameCooltip:AddMenu(2, options_on_click, "map_frame_scale_mod", "incsize")
				GameCooltip:AddLine(L["S_DECREASESIZE"], "", 2)
				GameCooltip:AddIcon([[Interface\BUTTONS\UI-MicroStream-Yellow]], 2, 1, 16, 16, 0, 1, 0, 1)
				GameCooltip:AddMenu(2, options_on_click, "map_frame_scale_mod", "decsize")
				--reset the scale setting
				GameCooltip:AddLine("$div", nil, 2, nil, -5, -11)
				GameCooltip:AddLine(L["S_OPTIONS_RESET"], "", 2)
				GameCooltip:AddIcon([[Interface\GLUES\CharacterSelect\CharacterUndelete]], 2, 1, 16, 16, .1, .9, .1, .9)
				GameCooltip:AddMenu(2, options_on_click, "reset_map_frame_scale_mod")
				--]=]

				--
				if (TomTom and IsAddOnLoaded("TomTom")) then
					GameCooltip:AddLine("$div")

					GameCooltip:AddLine("TomTom")
					GameCooltip:AddIcon([[Interface\AddOns\TomTom\Images\Arrow.blp]], 1, 1, 16, 14, 0, 56/512, 0, 43/512, "lightgreen")

					GameCooltip:AddLine(L["S_ENABLE"], "", 2)
					GameCooltip:AddMenu(2, options_on_click, "tomtom-enabled", not WorldQuestTracker.db.profile.tomtom.enabled)
					if (WorldQuestTracker.db.profile.tomtom.enabled) then
						GameCooltip:AddIcon([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
				end

				GameCooltip:AddLine(L["S_MAPBAR_OPTIONSMENU_REFRESH"])
				GameCooltip:AddMenu(1, options_on_click, "clear_quest_cache", true)
				GameCooltip:AddIcon([[Interface\GLUES\CharacterSelect\CharacterUndelete]], 1, 1, IconSize, IconSize, .2, .8, .2, .8)

				GameCooltip:AddLine(L["S_OPTIONS_QUESTBLACKLIST"])
				GameCooltip:AddIcon([[Interface\COMMON\icon-noloot]], 1, 1, IconSize, IconSize)
				GameCooltip:AddMenu(1, options_on_click, "ignore_quest")

				GameCooltip:AddLine(L["S_MAPBAR_OPTIONSMENU_UNTRACKQUESTS"])
				GameCooltip:AddMenu(1, options_on_click, "untrack_quests", true)
				GameCooltip:AddIcon([[Interface\BUTTONS\UI-GROUPLOOT-PASS-HIGHLIGHT]], 1, 1, IconSize, IconSize)

				GameCooltip:AddLine("$div")

				GameCooltip:AddLine("Discord Server")
				GameCooltip:AddIcon("Interface\\AddOns\\WorldQuestTracker\\media\\ds_icon.tga", nil, 1, 14, 14, 0, 1, 0, 1)
				GameCooltip:AddMenu(1, options_on_click, "share_addon", true)

				GameCooltip:AddLine("$div")

				GameCooltip:AddLine(L["S_OPTIONS_OPEN"])
				GameCooltip:AddIcon([[Interface\BUTTONS\UI-OptionsButton]], nil, 1, 14, 14, 0, 1, 0, 1)
				GameCooltip:AddMenu(1, WorldQuestTrackerAddon.OpenOptionsPanel)

				GameCooltip:SetOption("IconBlendMode", "ADD")
				GameCooltip:SetOption("SubFollowButton", true)
			end

			optionsButton.CoolTip = {
				Type = "menu",
				BuildFunc = BuildOptionsMenu, --> called when user mouse over the frame
				OnEnterFunc = function(self)
					optionsButton.button_mouse_over = true
					button_onenter(self)
				end,
				OnLeaveFunc = function(self)
					optionsButton.button_mouse_over = false
					button_onleave(self)
				end,
				FixedValue = "none",
				ShowSpeed = 0.05,
				Options = function()
					if (WorldQuestTracker.db.profile.bar_anchor == "top") then
						GameCooltip:SetOption("MyAnchor", "top")
						GameCooltip:SetOption("RelativeAnchor", "bottom")
						GameCooltip:SetOption("WidthAnchorMod", 0)
						GameCooltip:SetOption("HeightAnchorMod", -10)
					else
						GameCooltip:SetOption("MyAnchor", "bottom")
						GameCooltip:SetOption("RelativeAnchor", "top")
						GameCooltip:SetOption("WidthAnchorMod", 0)
						GameCooltip:SetOption("HeightAnchorMod", -5)
					end
				end
			}

			GameCooltip:CoolTipInject(optionsButton)

			do
				--register a new category on the settings panel
				local frame = CreateFrame("Frame")
				local background = frame:CreateTexture()
				background:SetAllPoints(frame)
				background:SetColorTexture(1, 0, 1, 0.5)

				local category = Settings.RegisterCanvasLayoutCategory(frame, "World Quest Tracker")
				Settings.RegisterAddOnCategory(category)

				--local optionsButtonOnInterfacePanel = CreateFrame("button", nil, frame, "BackdropTemplate")
				local optionsButtonOnInterfacePanel = DF:CreateButton(frame, function() WorldQuestTrackerAddon.OpenOptionsPanel() end, 400, 50, L["S_OPTIONS_OPEN_FROM_INTERFACE_PANEL"], -1)
				optionsButtonOnInterfacePanel:SetTemplate(DetailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
				optionsButtonOnInterfacePanel:SetSize(250, 50)
				optionsButtonOnInterfacePanel:SetText(L["S_OPTIONS_OPEN_FROM_INTERFACE_PANEL"])
				optionsButtonOnInterfacePanel:SetPoint("center", frame, "center", 0, 0)
				optionsButtonOnInterfacePanel.Text = optionsButtonOnInterfacePanel:CreateFontString(nil, "overlay", "GameFontNormal")
				optionsButtonOnInterfacePanel.widget.Text = optionsButtonOnInterfacePanel.Text
				DetailsFramework:ApplyStandardBackdrop(optionsButtonOnInterfacePanel)

				optionsButtonOnInterfacePanel.CoolTip = {
					Type = "menu",
					BuildFunc = BuildOptionsMenu, --> called when user mouse over the frame
					OnEnterFunc = function(self)
						optionsButtonOnInterfacePanel.button_mouse_over = true
					end,
					OnLeaveFunc = function(self)
						optionsButtonOnInterfacePanel.button_mouse_over = false
					end,
					FixedValue = "none",
					ShowSpeed = 0.05,
					Options = function()
					end
				}

				GameCooltip:CoolTipInject(optionsButtonOnInterfacePanel)
			end

			local ResourceFontTemplate = DF:GetTemplate("font", "WQT_RESOURCES_AVAILABLE")

			--> party members ~party

		-----------
			--recursos dispon�veis
			local xOffset = 35

			local resource_GoldFrame = CreateFrame("button", nil, WorldQuestTracker.ParentTapFrame, "BackdropTemplate")
			resource_GoldFrame.QuestType = WQT_QUESTTYPE_GOLD

			local resource_ResourcesFrame = CreateFrame("button", nil, WorldQuestTracker.ParentTapFrame, "BackdropTemplate")
			resource_ResourcesFrame.QuestType = WQT_QUESTTYPE_RESOURCE

			local resource_APowerFrame = CreateFrame("button", nil, WorldQuestTracker.ParentTapFrame, "BackdropTemplate")
			resource_APowerFrame.QuestType = WQT_QUESTTYPE_APOWER

			local resource_PetFrame = CreateFrame("button", nil, WorldQuestTracker.ParentTapFrame, "BackdropTemplate")
			resource_PetFrame.QuestType = WQT_QUESTTYPE_PETBATTLE

			-- ~resources ~recursos
			local resource_GoldIcon = DF:CreateImage(resource_GoldFrame, [[Interface\AddOns\WorldQuestTracker\media\icons_resourcesT]], 16, 16, "overlay", {64/128, 96/128, 0, .25})
			resource_GoldIcon:SetDrawLayer("overlay", 7)
			resource_GoldIcon:SetAlpha(.78)
			local resource_GoldText = DF:CreateLabel(resource_GoldFrame, "", ResourceFontTemplate)

			local resource_ResourcesIcon = DF:CreateImage(resource_ResourcesFrame, [[Interface\AddOns\WorldQuestTracker\media\icons_resourcesT]], 16, 16, "overlay", {0, 32/128, 0, .25})
			resource_ResourcesIcon:SetDrawLayer("overlay", 7)
			resource_ResourcesIcon:SetAlpha(.78)
			local resource_ResourcesText = DF:CreateLabel(resource_ResourcesFrame, "", ResourceFontTemplate)

			local resource_APowerIcon = DF:CreateImage(resource_APowerFrame, [[Interface\AddOns\WorldQuestTracker\media\icons_resourcesT]], 16, 16, "overlay", {32/128, 64/128, 0, .25})
			resource_APowerIcon:SetDrawLayer("overlay", 7)
			resource_APowerIcon:SetAlpha(.78)
			resource_APowerFrame.Icon = resource_APowerIcon
			local resource_APowerText = DF:CreateLabel(resource_APowerFrame, "", ResourceFontTemplate)

			local resource_PetIcon = DF:CreateImage(resource_PetFrame, WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_PETBATTLE].icon, 16, 16, "overlay", {0.05, 0.95, 0.05, 0.95})
			resource_PetIcon:SetDrawLayer("overlay", 7)
			resource_PetIcon:SetAlpha(.78)
			local resource_PetText = DF:CreateLabel(resource_PetFrame, "", ResourceFontTemplate)

			resource_APowerIcon:SetPoint("right", resource_APowerText, "left", -2, 0)

			resource_ResourcesText:SetPoint("right", resource_APowerIcon, "left", -10, 0)
			resource_ResourcesIcon:SetPoint("right", resource_ResourcesText, "left", -2, 0)

			resource_GoldText:SetPoint("right", resource_ResourcesIcon, "left", -10, 0)
			resource_GoldIcon:SetPoint("right", resource_GoldText, "left", -2, 0)

			resource_PetText:SetPoint("right", resource_GoldIcon, "left", -2, 0)
			resource_PetIcon:SetPoint("right", resource_PetText, "left", -2, 0)

			resource_PetText.text = 996

			WorldQuestTracker.IndicatorsAnchor = resource_APowerText --ANCHOR

			WorldQuestTracker.WorldMap_GoldIndicator = resource_GoldText
			WorldQuestTracker.WorldMap_ResourceIndicator = resource_ResourcesText
			WorldQuestTracker.WorldMap_APowerIndicator = resource_APowerText
			WorldQuestTracker.WorldMap_PetIndicator = resource_PetText

			WorldQuestTracker.WorldMap_ResourceIndicatorTexture = resource_ResourcesIcon
			WorldQuestTracker.WorldMap_APowerIndicatorTexture = resource_APowerIcon

			local track_all_quests_thread = function(tickerObject)
				local questsToTrack = tickerObject.questsToTrack
				local widget = tremove(questsToTrack)

				if (widget) then
					--add quest to the tracker
					WorldQuestTracker.CheckAddToTracker(widget, widget, true)
					--get the questID
					local questID = widget.questID

					--check if showing the world map
					local mapType = WorldQuestTrackerAddon.GetCurrentZoneType()
					if (mapType == "zone") then
						--animations
						if (widget.onEndTrackAnimation:IsPlaying()) then
							widget.onEndTrackAnimation:Stop()
						end
						widget.onStartTrackAnimation:Play()
						if (not widget.AddedToTrackerAnimation:IsPlaying()) then
							widget.AddedToTrackerAnimation:Play()
						end

					elseif (mapType == "world") then
						for _, widget in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
							if (widget.questID == questID and widget:IsShown()) then
								--animations
								if (widget.onEndTrackAnimation:IsPlaying()) then
									widget.onEndTrackAnimation:Stop()
								end
								widget.onStartTrackAnimation:Play()
								if (not widget.AddedToTrackerAnimation:IsPlaying()) then
									widget.AddedToTrackerAnimation:Play()
								end
							end
						end
					end
				else
					tickerObject:Cancel()
				end
			end

			local start_all_track_thread = function(questsToTrack)
				local ticker = C_Timer.NewTicker(.04, track_all_quests_thread)
				ticker.questsToTrack = questsToTrack
			end

			-- ~trackall
			local TrackAllFromType = function(self)
				local mapID
				if (mapType == "zone") then
					mapID = WorldQuestTracker.GetCurrentMapAreaID()
				end

				local mapType = WorldQuestTrackerAddon.GetCurrentZoneType()
				local questTableToTrack = {}

				if (mapType == "zone") then
					local qType = self.QuestType

					if (qType == "gold") then
						qType = QUESTTYPE_GOLD

					elseif (qType == "resource") then
						qType = QUESTTYPE_RESOURCE

					elseif (qType == "apower") then
						qType = QUESTTYPE_ARTIFACTPOWER

					elseif (qType == "petbattle") then
						qType = QUESTTYPE_PET
					end

					local widgets = WorldQuestTracker.Cache_ShownWidgetsOnZoneMap
					for _, widget in ipairs(widgets) do
						if (widget.QuestType == qType) then
							table.insert(questTableToTrack, widget)
						end
					end

					if (WorldQuestTracker.db.profile.sound_enabled) then
						if (math.random(2) == 1) then
							PlaySoundFile("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker_mass1.mp3")
						else
							PlaySoundFile("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker_mass2.mp3")
						end
					end
					WorldQuestTracker.UpdateZoneWidgets()

				elseif (mapType == "world") then

					if (not WorldQuestTracker.db.profile.world_map_config.summary_show) then

						local qType = self.QuestType
						if (qType == "gold") then
							qType = QUESTTYPE_GOLD

						elseif (qType == "resource") then
							qType = QUESTTYPE_RESOURCE

						elseif (qType == "apower") then
							qType = QUESTTYPE_ARTIFACTPOWER

						elseif (qType == "petbattle") then
							qType = QUESTTYPE_PET
						end

						for _, widget in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
							if (widget.QuestType == qType) then
								table.insert(questTableToTrack, widget)
							end
						end

						if (WorldQuestTracker.db.profile.sound_enabled) then
							if (math.random(2) == 1) then
								PlaySoundFile("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker_mass1.mp3")
							else
								PlaySoundFile("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker_mass2.mp3")
							end
						end
					else
						local questType = self.QuestType
						local questsAvailable = WorldQuestTracker.Cache_ShownQuestOnWorldMap [questType]

						if (questsAvailable) then
							for i = 1, #questsAvailable do
								local questID = questsAvailable [i]
								--> track this quest
								local widget = WorldQuestTracker.GetWorldWidgetForQuest(questID)

								if (widget) then
									table.insert(questTableToTrack, widget)
								end
							end

							if (WorldQuestTracker.db.profile.sound_enabled) then
								if (math.random(2) == 1) then
									PlaySoundFile("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker_mass1.mp3")
								else
									PlaySoundFile("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker_mass2.mp3")
								end
							end
						end
					end
				end

				start_all_track_thread(questTableToTrack)

			end

			resource_GoldFrame:SetScript("OnClick", TrackAllFromType)
			resource_ResourcesFrame:SetScript("OnClick", TrackAllFromType)
			resource_APowerFrame:SetScript("OnClick", TrackAllFromType)
			resource_PetFrame:SetScript("OnClick", TrackAllFromType)

			--animations
			local animaSettings = {
				scaleMax = 1.075,
				speed = 0.1,
			}
			do
				resource_GoldFrame.OnEnterAnimation = DF:CreateAnimationHub(resource_GoldFrame, function() end, function() end)
				local anim = WorldQuestTracker:CreateAnimation(resource_GoldFrame.OnEnterAnimation, "Scale", 1, animaSettings.speed, 1, 1, animaSettings.scaleMax, animaSettings.scaleMax, "center", 0, 0)
				anim:SetEndDelay(60) --this fixes the animation going back to 1 after it finishes
				anim:SetSmoothing("IN")
				resource_GoldFrame.OnLeaveAnimation = DF:CreateAnimationHub(resource_GoldFrame, function() end, function() end)
				local anim = WorldQuestTracker:CreateAnimation(resource_GoldFrame.OnLeaveAnimation, "Scale", 2, animaSettings.speed, animaSettings.scaleMax, animaSettings.scaleMax, 1, 1, "center", 0, 0)
				anim:SetSmoothing("OUT")
			end
				--
			do
				resource_ResourcesFrame.OnEnterAnimation = DF:CreateAnimationHub(resource_ResourcesFrame, function() end, function() end)
				local anim = WorldQuestTracker:CreateAnimation(resource_ResourcesFrame.OnEnterAnimation, "Scale", 1, animaSettings.speed, 1, 1, animaSettings.scaleMax, animaSettings.scaleMax, "center", 0, 0)
				anim:SetEndDelay(60) --this fixes the animation going back to 1 after it finishes
				anim:SetSmoothing("IN")
				resource_ResourcesFrame.OnLeaveAnimation = DF:CreateAnimationHub(resource_ResourcesFrame, function() end, function() end)
				local anim = WorldQuestTracker:CreateAnimation(resource_ResourcesFrame.OnLeaveAnimation, "Scale", 2, animaSettings.speed, animaSettings.scaleMax, animaSettings.scaleMax, 1, 1, "center", 0, 0)
				anim:SetSmoothing("OUT")
			end
				--
			do
				resource_APowerFrame.OnEnterAnimation = DF:CreateAnimationHub(resource_APowerFrame, function() end, function() end)
				local anim = WorldQuestTracker:CreateAnimation(resource_APowerFrame.OnEnterAnimation, "Scale", 1, animaSettings.speed, 1, 1, animaSettings.scaleMax, animaSettings.scaleMax, "center", 0, 0)
				anim:SetEndDelay(60) --this fixes the animation going back to 1 after it finishes
				anim:SetSmoothing("IN")
				resource_APowerFrame.OnLeaveAnimation = DF:CreateAnimationHub(resource_APowerFrame, function() end, function() end)
				local anim = WorldQuestTracker:CreateAnimation(resource_APowerFrame.OnLeaveAnimation, "Scale", 2, animaSettings.speed, animaSettings.scaleMax, animaSettings.scaleMax, 1, 1, "center", 0, 0)
				anim:SetSmoothing("OUT")
			end
				--
			do
				resource_PetFrame.OnEnterAnimation = DF:CreateAnimationHub(resource_PetFrame, function() end, function() end)
				local anim = WorldQuestTracker:CreateAnimation(resource_PetFrame.OnEnterAnimation, "Scale", 1, animaSettings.speed, 1, 1, animaSettings.scaleMax, animaSettings.scaleMax, "center", 0, 0)
				anim:SetEndDelay(60) --this fixes the animation going back to 1 after it finishes
				anim:SetSmoothing("IN")
				resource_PetFrame.OnLeaveAnimation = DF:CreateAnimationHub(resource_PetFrame, function() end, function() end)
				local anim = WorldQuestTracker:CreateAnimation(resource_PetFrame.OnLeaveAnimation, "Scale", 2, animaSettings.speed, animaSettings.scaleMax, animaSettings.scaleMax, 1, 1, "center", 0, 0)
				anim:SetSmoothing("OUT")
			end

			--this function is called when the mouse enters the indicator area, here it handles only the animation
			local indicatorsAnimationOnEnter = function(self, questType)

				--play sound
				WorldQuestTracker.PlayTick(2)

				if (self.OnLeaveAnimation:IsPlaying()) then
					self.OnLeaveAnimation:Stop()
				end
				self.OnEnterAnimation:Play()

				--play quick flash on squares showing quests of this faction
				local mapType = WorldQuestTrackerAddon.GetCurrentZoneType()

				if (mapType == "world") then

					for _, widget in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
						if (widget.QuestType == questType and widget:IsShown()) then
							widget.LoopFlash:Play()
						end
					end

					--play quick flash on widgets shown in the world map(quest locations)
					for questCounter, button in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
						if (button.QuestType == questType and button:IsShown()) then
							button.FactionPulseAnimation:Play()
						end
					end

				elseif (mapType == "zone") then

					for _, widget in ipairs(WorldQuestTracker.Cache_ShownWidgetsOnZoneMap) do
						if (widget.QuestType == questType and widget:IsShown()) then
							widget.FactionPulseAnimation:Play()
						end
					end
				end
			end

			local indicatorsAnimationOnLeave = function(self, questType)
				if (self.OnEnterAnimation:IsPlaying()) then
					self.OnEnterAnimation:Stop()
				end
				self.OnLeaveAnimation:Play()

				--stop animation in the world map zone
				for _, widget in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
					if (widget:IsShown()) then
						widget.LoopFlash:Stop()
					end
				end
				for questCounter, button in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
					if (button:IsShown()) then
						button.FactionPulseAnimation:Stop()
					end
				end

				for _, widget in ipairs(WorldQuestTracker.Cache_ShownWidgetsOnZoneMap) do
					if (widget:IsShown()) then
						widget.FactionPulseAnimation:Stop()
					end
				end
			end


			local shadow = WorldQuestTracker.ParentTapFrame:CreateTexture(nil, "background")
			shadow:SetPoint("left", resource_GoldIcon.widget, "left", 2, 0)
			shadow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
			shadow:SetSize(58, 10)
			shadow:SetAlpha(.3)

			local shadow = WorldQuestTracker.ParentTapFrame:CreateTexture(nil, "background")
			shadow:SetPoint("left", resource_ResourcesIcon.widget, "left", 2, 0)
			shadow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
			shadow:SetSize(58, 10)
			shadow:SetAlpha(.3)

			local shadow = WorldQuestTracker.ParentTapFrame:CreateTexture(nil, "background")
			shadow:SetPoint("left", resource_APowerIcon.widget, "left", 2, 0)
			shadow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
			shadow:SetSize(58, 10)
			shadow:SetAlpha(.3)

			local shadow = WorldQuestTracker.ParentTapFrame:CreateTexture(nil, "background")
			shadow:SetPoint("left", resource_PetIcon.widget, "left", 2, 0)
			shadow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
			shadow:SetSize(58, 10)
			shadow:SetAlpha(.3)

			resource_GoldFrame:SetSize(55, 20)
			resource_ResourcesFrame:SetSize(55, 20)
			resource_APowerFrame:SetSize(55, 20)
			resource_PetFrame:SetSize(55, 20)

			resource_GoldFrame:SetPoint("left", resource_GoldIcon.widget, "left", -2, 0)
			resource_ResourcesFrame:SetPoint("left", resource_ResourcesIcon.widget, "left", -2, 0)
			resource_APowerFrame:SetPoint("left", resource_APowerIcon.widget, "left", -2, 0)
			resource_PetFrame:SetPoint("left", resource_PetIcon.widget, "left", -2, 0)

			resource_GoldFrame:SetScript("OnEnter", function(self)
				resource_GoldText.textcolor = "WQT_ORANGE_ON_ENTER"

				indicatorsAnimationOnEnter(self, QUESTTYPE_GOLD)

				GameCooltip:Preset(2)
				GameCooltip:SetType("tooltip")
				GameCooltip:SetOption("TextSize", 10)
				GameCooltip:SetOption("FixedWidth", 220)

				if (WorldQuestTracker.db.profile.bar_anchor == "top") then
					GameCooltip:SetOption("MyAnchor", "top")
					GameCooltip:SetOption("RelativeAnchor", "bottom")
					GameCooltip:SetOption("WidthAnchorMod", 0)
					GameCooltip:SetOption("HeightAnchorMod", -29)
				else
					GameCooltip:SetOption("MyAnchor", "bottom")
					GameCooltip:SetOption("RelativeAnchor", "top")
					GameCooltip:SetOption("WidthAnchorMod", 0)
					GameCooltip:SetOption("HeightAnchorMod", 0)
				end

				GameCooltip:AddLine(L["S_QUESTTYPE_GOLD"])
				GameCooltip:AddIcon(WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_GOLD].icon, 1, 1, 20, 20)

				GameCooltip:AddLine("", "", 1, "green", _, 10)
				GameCooltip:AddLine(format(L["S_MAPBAR_RESOURCES_TOOLTIP_TRACKALL"], L["S_QUESTTYPE_GOLD"]), "", 1, "green", _, 10)

				GameCooltip:SetOwner(self)
				GameCooltip:Show(self)
			end)

			resource_ResourcesFrame:SetScript("OnEnter", function(self)
				resource_ResourcesText.textcolor = "WQT_ORANGE_ON_ENTER"

				indicatorsAnimationOnEnter(self, QUESTTYPE_RESOURCE)

				GameCooltip:Preset(2)
				GameCooltip:SetType("tooltip")
				GameCooltip:SetOption("TextSize", 10)
				GameCooltip:SetOption("FixedWidth", 220)

				if (WorldQuestTracker.db.profile.bar_anchor == "top") then
					GameCooltip:SetOption("MyAnchor", "top")
					GameCooltip:SetOption("RelativeAnchor", "bottom")
					GameCooltip:SetOption("WidthAnchorMod", 0)
					GameCooltip:SetOption("HeightAnchorMod", -29)
				else
					GameCooltip:SetOption("MyAnchor", "bottom")
					GameCooltip:SetOption("RelativeAnchor", "top")
					GameCooltip:SetOption("WidthAnchorMod", 0)
					GameCooltip:SetOption("HeightAnchorMod", 0)
				end

				GameCooltip:AddLine(L["S_QUESTTYPE_RESOURCE"])
				GameCooltip:AddIcon(WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_RESOURCE].icon, 1, 1, 20, 20)

				GameCooltip:AddLine("", "", 1, "green", _, 10)
				GameCooltip:AddLine(format(L["S_MAPBAR_RESOURCES_TOOLTIP_TRACKALL"], L["S_QUESTTYPE_RESOURCE"]), "", 1, "green", _, 10)

				GameCooltip:SetOwner(self)
				GameCooltip:Show(self)
			end)

			resource_APowerFrame:SetScript("OnEnter", function(self)
				resource_APowerText.textcolor = "WQT_ORANGE_ON_ENTER"

				indicatorsAnimationOnEnter(self, QUESTTYPE_ARTIFACTPOWER)

				GameCooltip:Preset(2)
				GameCooltip:SetType("tooltipbar")
				GameCooltip:SetOption("TextSize", 10)
				GameCooltip:SetOption("FixedWidth", 220)
				GameCooltip:SetOption("StatusBarTexture", [[Interface\RaidFrame\Raid-Bar-Hp-Fill]])

				if (WorldQuestTracker.db.profile.bar_anchor == "top") then
					GameCooltip:SetOption("MyAnchor", "top")
					GameCooltip:SetOption("RelativeAnchor", "bottom")
					GameCooltip:SetOption("WidthAnchorMod", 0)
					GameCooltip:SetOption("HeightAnchorMod", -29)
				else
					GameCooltip:SetOption("MyAnchor", "bottom")
					GameCooltip:SetOption("RelativeAnchor", "top")
					GameCooltip:SetOption("WidthAnchorMod", 0)
					GameCooltip:SetOption("HeightAnchorMod", 0)
				end

				GameCooltip:AddLine(L["S_QUESTTYPE_ARTIFACTPOWER"])
				GameCooltip:AddIcon(WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_APOWER].icon, 1, 1, 20, 20)

				GameCooltip:AddLine("", "", 1, "green", _, 10)
				GameCooltip:AddLine(format(L["S_MAPBAR_RESOURCES_TOOLTIP_TRACKALL"], L["S_QUESTTYPE_ARTIFACTPOWER"]), "", 1, "green", _, 10)
				GameCooltip:SetOption("LeftTextHeight", 22)
				GameCooltip:SetOwner(self)
				GameCooltip:Show(self)
			end)

			resource_PetFrame:SetScript("OnEnter", function(self)
				resource_PetText.textcolor = "WQT_ORANGE_ON_ENTER"

				indicatorsAnimationOnEnter(self, QUESTTYPE_PET)

				GameCooltip:Preset(2)
				GameCooltip:SetType("tooltipbar")
				GameCooltip:SetOption("TextSize", 10)
				GameCooltip:SetOption("FixedWidth", 220)
				GameCooltip:SetOption("StatusBarTexture", [[Interface\RaidFrame\Raid-Bar-Hp-Fill]])

				if (WorldQuestTracker.db.profile.bar_anchor == "top") then
					GameCooltip:SetOption("MyAnchor", "top")
					GameCooltip:SetOption("RelativeAnchor", "bottom")
					GameCooltip:SetOption("WidthAnchorMod", 0)
					GameCooltip:SetOption("HeightAnchorMod", -29)
				else
					GameCooltip:SetOption("MyAnchor", "bottom")
					GameCooltip:SetOption("RelativeAnchor", "top")
					GameCooltip:SetOption("WidthAnchorMod", 0)
					GameCooltip:SetOption("HeightAnchorMod", 0)
				end

				GameCooltip:AddLine("Pet Battle")
				GameCooltip:AddIcon(WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_PETBATTLE].icon, 1, 1, 20, 20)

				GameCooltip:AddLine("", "", 1, "green", _, 10)
				GameCooltip:AddLine(format(L["S_MAPBAR_RESOURCES_TOOLTIP_TRACKALL"], "Pet Battles"), "", 1, "green", _, 10)
				GameCooltip:SetOption("LeftTextHeight", 22)
				GameCooltip:SetOwner(self)
				GameCooltip:Show(self)
			end)

			local resource_IconsOnLeave = function(self)
				GameCooltip:Hide()
				resource_GoldText.textcolor = "WQT_ORANGE_RESOURCES_AVAILABLE"
				resource_ResourcesText.textcolor = "WQT_ORANGE_RESOURCES_AVAILABLE"
				resource_APowerText.textcolor = "WQT_ORANGE_RESOURCES_AVAILABLE"
				resource_PetText.textcolor = "WQT_ORANGE_RESOURCES_AVAILABLE"

				indicatorsAnimationOnLeave(self)
			end

			resource_GoldFrame:SetScript("OnLeave", resource_IconsOnLeave)
			resource_ResourcesFrame:SetScript("OnLeave", resource_IconsOnLeave)
			resource_APowerFrame:SetScript("OnLeave", resource_IconsOnLeave)
			resource_PetFrame:SetScript("OnLeave", resource_IconsOnLeave)

			--------------

			--anima��o
			worldFramePOIs:SetScript("OnShow", function()
				worldFramePOIs.fadeInAnimation:Play()
			end)
		end

		if (WorldQuestTracker.IsWorldQuestHub(WorldMapFrame.mapID)) then
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap(false, true)

		else
			WorldQuestTracker.HideWorldQuestsOnWorldMap()

			--is zone map?
			if (WorldQuestTracker.ZoneHaveWorldQuest(WorldMapFrame.mapID)) then
				--roda nosso custom update e cria nossos proprios widgets
				WorldQuestTracker.UpdateZoneWidgets(true)
				C_Timer.After(1.35, function()
					if (WorldQuestTracker.ZoneHaveWorldQuest(WorldMapFrame.mapID)) then
						WorldQuestTracker.UpdateZoneWidgets(true)
					end
				end)
			end

		end

		-- ~tutorial
		--check bfa version launch on 8.1, if the tutorial is at 3, reset if bfa setting is false
		if (WorldQuestTracker.db.profile.TutorialPopupID) then
			if (WorldQuestTracker.db.profile.TutorialPopupID >= 3) then
				--player already saw all tutorials
				if (not WorldQuestTracker.db.profile.is_BFA_version) then
					--player just isntalled the bfa version, reset the tutorial
					WorldQuestTracker.db.profile.TutorialPopupID = 1
				end
			end
		end

		--the user is using the bfa version
		WorldQuestTracker.db.profile.is_BFA_version = true

		--check for tutorials
		WorldQuestTracker.ShowTutorialAlert()

		--news ~news
			function WorldQuestTracker.OpenNewsWindow()
				if (not WorldQuestTrackerNewsFrame) then
					local options = {
						width = 550,
						height = 700,
						line_amount = 13,
						line_height = 50,
					}

					local newsFrame = DF:CreateNewsFrame(UIParent, "WorldQuestTrackerNewsFrame", options, WorldQuestTracker.GetChangelogTable(), WorldQuestTracker.db.profile.news_frame)
					newsFrame:SetFrameStrata("FULLSCREEN")

					local lastNews = WorldQuestTracker.db.profile.last_news_time

					newsFrame.NewsScroll.OnUpdateLineHook = function(line, lineIndex, data)
						local thisEntryTime = data [1]
						if (thisEntryTime > lastNews) then
							line.backdrop_color = {.4, .4, .4, .6}
							line.backdrop_color_highlight = {.5, .5, .5, .8}
							line:SetBackdropColor(.4, .4, .4, .6)
						end
					end
				end

				WorldQuestTrackerNewsFrame:Show()
				WorldQuestTrackerNewsFrame.NewsScroll:Refresh()
				WorldQuestTracker.db.profile.last_news_time = time()
				WorldQuestTracker.NewsButton:Hide()
			end

			function WorldQuestTracker.GetChangelogTable()
				return WorldQuestTracker.ChangeLogTable
			end

			local numNews = DF:GetNumNews(WorldQuestTracker.GetChangelogTable(), WorldQuestTracker.db.profile.last_news_time)
			if (numNews > 0 and WorldQuestTracker.DoubleTapFrame and false) then --adding a false here to not show the news button for now(15/02/2019)
				-- /run WorldQuestTrackerAddon.db.profile.last_news_time = 0

				local openNewsButton = DF:CreateButton(WorldQuestTracker.ParentTapFrame, WorldQuestTracker.OpenNewsWindow, 120, 20, L["S_WHATSNEW"], -1, nil, nil, nil, nil, nil, DF:GetTemplate("button", "WQT_NEWS_BUTTON"), DF:GetTemplate("font", "WQT_TOGGLEQUEST_TEXT"))
				openNewsButton:SetPoint("bottom", WorldQuestTracker.ParentTapFrame, "top", -5, 2)
				WorldQuestTracker.NewsButton = openNewsButton

				local numNews = DF:GetNumNews(WorldQuestTracker.GetChangelogTable(), WorldQuestTracker.db.profile.last_news_time)
				if (numNews > 0) then
					WorldQuestTracker.NewsButton:SetText(L["S_WHATSNEW"] .. "(|cFFFFFF00" .. numNews .. "|r)")
				end
			end

		--end news
	else
		WorldQuestTracker.NoAutoSwitchToWorldMap = nil
	end

	-- ~frame anchor
	if (not WorldMapFrame.isMaximized) then
		WorldQuestTracker.UpdateWorldMapFrameAnchor()
	end

	-- ~frame scale
	if (WorldQuestTracker.db.profile.map_frame_scale_enabled) then
		WorldQuestTracker.UpdateWorldMapFrameScale()
	end

	-- ~eye on 8.3 patch - REMOVE ON 9.0
	local eyeFrame = WorldQuestTracker.GetOverlay("Eye")
	if (not WorldQuestTracker.eyeFrameBuilt and eyeFrame) then
		eyeFrame:SetScale(0.5)
		eyeFrame:ClearAllPoints()
		eyeFrame:SetPoint("bottomleft", WorldMapFrame, "bottomleft", 0, 32)
		WorldQuestTracker.eyeFrameBuilt = true

		--hook the hover over script and show all details about the quest
	end

	eyeFrame:Refresh()
end

hooksecurefunc("ToggleWorldMap", WorldQuestTracker.OnToggleWorldMap)

WorldQuestTracker.CheckIfLoaded = function(self)
	if (not WorldQuestTracker.IsLoaded) then
		if (WorldMapFrame:IsShown()) then
			WorldQuestTracker.OnToggleWorldMap()
		end
	end
end

WorldMapFrame:HookScript("OnShow", function()
	if (not WorldQuestTracker.IsLoaded) then
		C_Timer.After(0.5, WorldQuestTracker.CheckIfLoaded)
	end
end)


