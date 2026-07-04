
local addonId, wqtInternal = ...

---@type detailsframework
local detailsFramework = DetailsFramework

--world quest tracker object
local WorldQuestTracker = WorldQuestTrackerAddon
if (not WorldQuestTracker) then
	return
end

local worldFramePOIs = WorldQuestTrackerWorldMapPOI
local anchorFrame = WorldMapFrame.ScrollContainer

--localization
local L = detailsFramework.Language.GetLanguageTable(addonId)

local repStatusbarWidth = 7

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

function wqtInternal.CreateSummary()
    -- world map summary ~summary ~worldsummary
    local worldSummary = WorldQuestTracker.WorldSummary
    worldSummary:SetWidth(100)
    --Keep the interactive summary above the map pin layer (world quest pins use 302).
    worldSummary:SetFrameLevel(math.max(worldSummary:GetFrameLevel(), 320))
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
    worldSummary.FactionSelectedTemplate = detailsFramework:InstallTemplate("button", "WQT_FACTION_SELECTED", {backdropbordercolor = {1, .8, 0, 1}}, "OPTIONS_BUTTON_TEMPLATE")

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
        worldSummary.RefreshAnchorTitleVisibility()
        worldSummary.ApplyHierarchyToggleState()
    end

    worldSummary.HideAnimation = detailsFramework:CreateAnimationHub(worldSummary, function()end, function() worldSummary:Hide() end)
    detailsFramework:CreateAnimation(worldSummary.HideAnimation, "Translation", 1, 0.9, -300, 0)

    function worldSummary.ShowSummary()
        if (worldSummary.HideAnimation:IsPlaying()) then
            worldSummary.HideAnimation:Stop()
        end

        worldSummary:Show()
        C_Timer.After(0, worldSummary.ApplyHierarchyToggleState)
    end

    --The zone/type toggle can keep the same quest IDs while requiring every
    --summary square to move to a different anchor. Mark the layout dirty so
    --StartLazyUpdate does a full rebuild instead of treating it as no change.
    function worldSummary.InvalidateLayout()
        worldSummary.ForceLayoutRebuild = true
    end

    --DetailsFramework labels wrap a FontString. Use the FontString directly here:
    --the zone headings are unnamed labels, and wrapper Show/Hide calls are not
    --reliable for unnamed regions. This also prevents stale by-zone headings from
    --remaining on the map after switching back to by-type ordering.
    local function setAnchorTitleVisibility(anchor, shouldShow)
        local titleWidget = anchor.Title and (anchor.Title.widget or anchor.Title.label)
        local titleText = shouldShow and (anchor.AnchorTitle or "") or ""

        if (anchor.Title and anchor.Title.SetText) then
            anchor.Title:SetText(titleText)
        end
        if (titleWidget) then
            titleWidget:SetText(titleText)
            titleWidget:SetAlpha(shouldShow and 1 or 0)
            titleWidget:SetShown(shouldShow)
        end

        if (anchor.ConfigFrame) then
            anchor.ConfigFrame:SetShown(shouldShow)
        end
    end

    function worldSummary.RefreshAnchorTitleVisibility()
        local showZoneTitles = WorldQuestTracker.db.profile.world_map_config.summary_showby == "byzone"

        for _, anchor in pairs(worldSummary.Anchors) do
            local shouldShow = showZoneTitles and anchor.InUse and anchor.mapID and anchor.AnchorTitle and anchor.AnchorTitle ~= ""
            setAnchorTitleVisibility(anchor, not not shouldShow)
        end
    end

    function worldSummary.HideSummary()
        if (worldSummary.HierarchyToggleButton) then
            worldSummary.HierarchyToggleButton:Hide()
        end
        worldSummary:Hide()
        --worldSummary.HideAnimation:Play()
    end

    local function getHierarchyYOffsetKey(hierarchy)
        if (hierarchy == "continent") then
            return "summary_y_offset_continent"
        end
        return "summary_y_offset_world"
    end

    function worldSummary.GetHierarchyYOffset(hierarchy)
        hierarchy = hierarchy or WorldQuestTracker.GetMapHierarchyLevel(WorldMapFrame and WorldMapFrame.mapID)
        local config = WorldQuestTracker.db.profile.world_map_config
        return config[getHierarchyYOffsetKey(hierarchy)] or 0
    end

    function worldSummary.SetHierarchyYOffset(hierarchy, value)
        hierarchy = hierarchy or WorldQuestTracker.GetMapHierarchyLevel(WorldMapFrame and WorldMapFrame.mapID)
        local config = WorldQuestTracker.db.profile.world_map_config
        config[getHierarchyYOffsetKey(hierarchy)] = math.max(-500, math.min(500, value or 0))
        worldSummary.ReAnchor()
        worldSummary.ApplyHierarchyToggleState()
    end

    local function getFirstHierarchySummaryWidget()
        local firstAnchor
        for _, anchor in ipairs(worldSummary.Anchors) do
            if (anchor.InUse and anchor.Widgets and anchor.Widgets[1]) then
                if (not firstAnchor or (anchor.AnchorOrder or 999) < (firstAnchor.AnchorOrder or 999)) then
                    firstAnchor = anchor
                end
            end
        end

        return firstAnchor and firstAnchor.Widgets and firstAnchor.Widgets[1]
    end

    local function createHierarchySummaryToggle()
        if (worldSummary.HierarchyToggleButton) then
            return worldSummary.HierarchyToggleButton
        end

        local button = CreateFrame("button", "WorldQuestTrackerHierarchySummaryToggle", worldSummary, "BackdropTemplate")
        button:SetSize(16, 16)
        button:SetFrameLevel(worldSummary:GetFrameLevel() + 100)
        button:EnableMouse(true)
        button:RegisterForClicks("LeftButtonUp")

        button.Icon = button:CreateTexture(nil, "overlay")
        button.Icon:SetAllPoints()
        button.Icon:SetTexCoord(.25, .75, .28, .75)

        button:RegisterForDrag("LeftButton")

        button:SetScript("OnDragStart", function(self)
            local hierarchy = WorldQuestTracker.GetMapHierarchyLevel(WorldMapFrame and WorldMapFrame.mapID)
            if (hierarchy ~= "world" and hierarchy ~= "continent") then
                return
            end

            local _, cursorY = GetCursorPosition()
            self.DragHierarchy = hierarchy
            self.DragStartCursorY = cursorY / UIParent:GetEffectiveScale()
            self.DragStartYOffset = worldSummary.GetHierarchyYOffset(hierarchy)
            self.DidVerticalDrag = false

            self:SetScript("OnUpdate", function(dragButton)
                local _, currentCursorY = GetCursorPosition()
                currentCursorY = currentCursorY / UIParent:GetEffectiveScale()
                local deltaY = currentCursorY - dragButton.DragStartCursorY
                if (math.abs(deltaY) >= 2) then
                    dragButton.DidVerticalDrag = true
                end
                worldSummary.SetHierarchyYOffset(dragButton.DragHierarchy, dragButton.DragStartYOffset + deltaY)
            end)
        end)

        button:SetScript("OnDragStop", function(self)
            self:SetScript("OnUpdate", nil)
            self.SuppressNextClick = self.DidVerticalDrag
            self.DragHierarchy = nil
        end)

        button:SetScript("OnClick", function(self)
            if (self.SuppressNextClick) then
                self.SuppressNextClick = nil
                return
            end

            local config = WorldQuestTracker.db.profile.world_map_config
            config.summary_minimized = not config.summary_minimized
            worldSummary.ApplyHierarchyToggleState()
        end)

        worldSummary.HierarchyToggleButton = button
        return button
    end

    function worldSummary.ApplyHierarchyToggleState()
        local button = createHierarchySummaryToggle()
        local hierarchy = WorldQuestTracker.GetMapHierarchyLevel(WorldMapFrame and WorldMapFrame.mapID)
        local config = WorldQuestTracker.db.profile.world_map_config
        local canShow = worldSummary:IsShown()
            and config.summary_show
            and config.summary_showby == "bytype"
            and WorldQuestTracker.db.profile.show_summary_minimize_button
            and (hierarchy == "world" or hierarchy == "continent")

        if (not canShow) then
            button:Hide()
            return
        end

        local anchorSide = worldSummary.GetAnchorSide(true)
        local firstWidget = getFirstHierarchySummaryWidget()
        button:ClearAllPoints()

        if (firstWidget) then
            if (anchorSide == "right") then
                button:SetPoint("left", firstWidget, "right", -4, 0)
            else
                button:SetPoint("right", firstWidget, "left", 4, 0)
            end
        elseif (anchorSide == "right") then
            button:SetPoint("topright", worldSummary, "topright", -2, -38)
        else
            button:SetPoint("topleft", worldSummary, "topleft", 2, -38)
        end

        local minimized = config.summary_minimized == true
        if (anchorSide == "right") then
            button.Icon:SetTexture(minimized and [[Interface\BUTTONS\UI-SpellbookIcon-PrevPage-Up]] or [[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Up]])
        else
            button.Icon:SetTexture(minimized and [[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Up]] or [[Interface\BUTTONS\UI-SpellbookIcon-PrevPage-Up]])
        end

        for _, anchor in ipairs(worldSummary.Anchors) do
            if (minimized) then
                anchor:Hide()
            elseif (anchor.InUse) then
                anchor:Show()
            end
        end

        if (worldSummary.FactionAnchor) then
            if (minimized) then
                worldSummary.FactionAnchor:Hide()
            else
                worldSummary.UpdateFactionAnchor()
            end
        end

        button:Show()
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
            local widget = table.remove(questsToTrack)
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
        anchor:SetFrameLevel(worldSummary:GetFrameLevel() + 1)

        anchor.ContentsBorder = CreateFrame("frame", nil, anchor)
        anchor.ContentsBorder:EnableMouse(false)
        anchor.ContentsBorder:SetScript("OnUpdate", function(self)
            if InCombatLockdown() then
                return
            end
            for j = 1, #anchor.Widgets do
                local widget = anchor.Widgets[j]
                widget.DefaultPin = nil
                widget:EnableMouse(true)
                widget:SetMouseMotionEnabled(true)
            end
        end)

        anchor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
        anchor:SetBackdropColor(0, 0, 0, 0)
        anchor:SetBackdropBorderColor(0, 0, 0, 0)

        anchor.Title = detailsFramework:CreateLabel(anchor)
        anchor.Title.widget:SetFontObject(GameFontNormal)
        anchor.Title.textcolor = {1, .8, .2, .854}
        anchor.Title.textsize = 10

        anchor.WidgetsAmount = 0
        anchor.Widgets = {}

        --config on hover over
            anchor.ConfigFrame = CreateFrame("frame", nil, anchor, "BackdropTemplate")
            anchor.ConfigFrame:SetFrameLevel(anchor:GetFrameLevel() + 30)
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
                    GameCooltip:SetOption("TextSize", 12)
                    GameCooltip:SetOption("FixedWidth", 180)
                    GameCooltip:SetOption("IconBlendMode", "ADD")
                end
            }

            GameCooltip:CoolTipInject(anchor.ConfigFrame)

        --button to track all quests in the anchor
        local anchorButton = detailsFramework:CreateButton(anchor, on_click_anchor_button, 20, 20, "", anchorID)
        anchorButton:SetFrameLevel(anchor:GetFrameLevel() + 25)
        anchorButton.Texture = anchorButton:CreateTexture(nil, "overlay")
        anchorButton.Texture:SetTexture([[Interface\MINIMAP\SuperTrackerArrow]])
        anchorButton.Texture:SetAlpha(.9)
        anchor.Button = anchorButton
        anchorButton.Anchor = anchor

        --anchor pin - hack to set the anchor location in the map based in a x y coordinate
        local pinAnchor = WorldQuestTracker.CreateOwnedPinAnchor(nil, worldFramePOIs)
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

    local function getSummaryVisualSettings()
        return WorldQuestTracker.GetWorldMapVisualSettings(WorldMapFrame and WorldMapFrame.mapID)
    end

    --World and continent summaries scale each icon directly. The reward amount
    --text is anchored 10 UI units below the icon and its background extends
    --slightly farther. Include that footprint in the row step so the next row
    --clears both the icon and its label at every scale.
    local SUMMARY_LABEL_FOOTPRINT = 11
    local SUMMARY_ROW_GAP = 1

    local function getRenderedSummaryRowStep(summaryVisuals, summaryScale)
        local iconSize = (summaryVisuals and summaryVisuals.summaryIconSize) or 25
        local scale = summaryScale or 1
        return ((iconSize + SUMMARY_LABEL_FOOTPRINT) * scale) + SUMMARY_ROW_GAP
    end

    function worldSummary.ReAnchor()
        if (WorldQuestTracker.db.profile.world_map_config.summary_showby == "byzone") then
            for _, anchor in pairs(worldSummary.Anchors) do
                setAnchorTitleVisibility(anchor, false)

                local mapID = anchor.mapID
                local mapTable = mapID and WorldQuestTracker.mapTables[mapID]

                if (anchor.InUse and mapTable) then
                    local config = WorldQuestTracker.db.profile.anchor_options[mapID]
                    if (not config) then
                        config = {Enabled = true, YOffset = 0, Alpha = 1, TextColor = {1, .8, .2, .854}, ScaleOffset = 0}
                        WorldQuestTracker.db.profile.anchor_options[mapID] = config
                    end

                    local x, y = mapTable.Anchor_X, mapTable.Anchor_Y
                    y = y + config.YOffset

                    WorldQuestTracker.UpdateWorldMapAnchors(x, y, anchor.PinAnchor)
                    anchor:ClearAllPoints()
                    anchor:SetPoint("center", anchor.PinAnchor, "center", 0, 0)
                    setAnchorTitleVisibility(anchor, true)
                end
            end

        elseif (WorldQuestTracker.db.profile.world_map_config.summary_showby == "bytype") then
            local hierarchy = WorldQuestTracker.GetMapHierarchyLevel(WorldMapFrame and WorldMapFrame.mapID)
            local Y = -24 + worldSummary.GetHierarchyYOffset(hierarchy)

            table.sort(worldSummary.Anchors, anchorReorderFunc)

            local previousAnchor
            local anchorSide = worldSummary.GetAnchorSide(true)
            local summaryScale = WorldQuestTracker.db.profile.world_map_config.summary_scale
            local summaryVisuals = getSummaryVisualSettings()
            local renderedRowStep = getRenderedSummaryRowStep(summaryVisuals, summaryScale)

            for _, anchor in ipairs(worldSummary.Anchors) do
                anchor:ClearAllPoints()
                anchor.mapID = nil
                setAnchorTitleVisibility(anchor, false)

                --Only visible categories participate in the stack. Empty
                --categories previously consumed a full row each, creating the
                --large gaps visible between continent-summary groups.
                if (anchor.InUse and anchor.WidgetsAmount > 0) then
                    if (previousAnchor) then
                        local previousRows = math.max(1, math.ceil(previousAnchor.WidgetsAmount / worldSummary.MaxWidgetsPerRow))
                        local verticalOffset = -(previousRows * renderedRowStep)

                        if (anchorSide == "left") then
                            anchor:SetPoint("topleft", previousAnchor, "topleft", 0, verticalOffset)
                        else
                            anchor:SetPoint("topright", previousAnchor, "topright", 0, verticalOffset)
                        end
                    elseif (anchorSide == "left") then
                        anchor:SetPoint("topleft", worldSummary, "topleft", 2, Y)
                    else
                        anchor:SetPoint("topright", worldSummary, "topright", -4, Y)
                    end

                    previousAnchor = anchor
                end
            end
        end

        worldSummary.RefreshAnchorTitleVisibility()
        worldSummary.ApplyHierarchyToggleState()
    end

    --giving a type of a quest, this function returns the anchor where that quest should be attached to
    --it also checks if the world map are showing quests by the zone and returns the anchor for that particular zone
    function worldSummary.GetAnchor(filterType, worldQuestType, questName, mapID)
        local anchor, anchorTitle
        local isShowingByZone = WorldQuestTracker.db.profile.world_map_config.summary_showby == "byzone"

        if (not isShowingByZone) then
            --if not showing by the zone, get the anchor based on the type of the quest
            if (filterType == "artifact_power") then
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_ARTIFACTPOWER]]
                anchorTitle = WorldQuestTracker.MapData.QuestTypeIcons[WQT_QUESTTYPE_APOWER].name

            elseif (filterType == "reputation_token") then
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_REPUTATION]]
                anchorTitle = "Reputation"
                anchor.anchorType = filterType

            elseif (filterType == "garrison_resource") then
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_RESOURCES]]
                anchorTitle = WorldQuestTracker.MapData.QuestTypeIcons[WQT_QUESTTYPE_RESOURCE].name

            elseif (filterType == "equipment") then
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_EQUIPMENT]]
                anchorTitle = "Equipment"

            elseif (filterType == "gold") then
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_GOLD]]
                anchorTitle = "Gold"

            elseif (filterType == "pet_battles") then
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_PETBATTLE]]
                anchorTitle = "Pet Battles"

            elseif (filterType == "racing") then
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_RACING]]
                anchorTitle = "Racing"

            else
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_MISC]]
                anchorTitle = "Misc"
            end

            anchor.mapID = nil
        else
            --return the anchor chosen to hold quests of this zone
            local anchorIndex = worldSummary.ZoneAnchors[mapID]

            if (not anchorIndex) then
                anchorIndex = worldSummary.ZoneAnchors.NextAnchor
                worldSummary.ZoneAnchors[mapID] = anchorIndex

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
        worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_ARTIFACTPOWER]].AnchorOrder = math.abs(order[WQT_QUESTTYPE_APOWER] -(WQT_QUESTTYPE_MAX + 1))
        --resource
        worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_RESOURCES]].AnchorOrder = math.abs(order[WQT_QUESTTYPE_RESOURCE] -(WQT_QUESTTYPE_MAX + 1))
        --equipment
        worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_EQUIPMENT]].AnchorOrder = math.abs(order[WQT_QUESTTYPE_EQUIPMENT] -(WQT_QUESTTYPE_MAX + 1))
        --gold
        worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_GOLD]].AnchorOrder = math.abs(order[WQT_QUESTTYPE_GOLD] -(WQT_QUESTTYPE_MAX + 1))
        --reputation
        worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_REPUTATION]].AnchorOrder = math.abs(order[WQT_QUESTTYPE_REPUTATION] -(WQT_QUESTTYPE_MAX + 1))
        --misc
        worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_MISC]].AnchorOrder = 100
        --7th anchor
        worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_MISC2]].AnchorOrder = 101
        --pet_battles
        worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_PETBATTLE]].AnchorOrder = math.abs(order[WQT_QUESTTYPE_PETBATTLE] -(WQT_QUESTTYPE_MAX + 1))
        --racing
        worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_RACING]].AnchorOrder = math.abs(order[WQT_QUESTTYPE_RACING] -(WQT_QUESTTYPE_MAX + 1))
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
                local widget = anchor.Widgets[i]

                if (isSortByTime) then
                    widget.WidgetOrder =(widget.TimeLeft * 10) +(widget.questID / 100)
                else
                    local orderPoints = widget.questID + abs(widget.TimeLeft - 1440) * 10

                    --move quests for the selected fation to show first
                    if (worldSummary.DoesWidgetAwardFactionReputation and worldSummary.DoesWidgetAwardFactionReputation(widget, worldSummary.FactionSelected)) then
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
                local widget = anchor.Widgets[i]

                if (isSortByTime) then
                    widget.WidgetOrder = (widget.TimeLeft * 10) +(widget.questID / 100)
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
                    return (widget1.FactionID or 0) < (widget2.FactionID or 0) --attempt to compare nil with number
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

        local summaryScale = WorldQuestTracker.db.profile.world_map_config.summary_scale
        local summaryVisuals = getSummaryVisualSettings()
        local summaryIconSize = summaryVisuals.summaryIconSize
        local summaryFontSize = summaryVisuals.fontSize
        local summaryColumnStep = summaryVisuals.summaryColumnStep or 25
        local summaryRowStep = getRenderedSummaryRowStep(summaryVisuals, summaryScale)

        local X, Y = 1, -1
        local trackAllButtonAnchor = anchor.Widgets[#anchor.Widgets]
        local nextBreakLine = worldSummary.MaxWidgetsPerRow

        local firstWidget = anchor.Widgets[1]
        local hasBreakLine = #anchor.Widgets > nextBreakLine
        local lastWidget = anchor.Widgets[nextBreakLine] or anchor.Widgets[#anchor.Widgets]

        anchor.ContentsBorder:ClearAllPoints()
        if (firstWidget) then
            anchor.ContentsBorder:SetPoint("topleft", firstWidget, "topleft", -2, 2)
            anchor.ContentsBorder:SetPoint("bottomright", lastWidget, "bottomright", 2, hasBreakLine and -summaryRowStep or -2)
        end

        --Use WQT's upstream layout: icons are children of the category anchor,
        --their slots remain fixed, and only the icon frame receives the scale.
        for i = 1, #anchor.Widgets do
            local widget = anchor.Widgets[i]
            widget:SetParent(anchor)
            WorldQuestTracker.ApplyWorldSummaryWidgetSize(widget, summaryIconSize, summaryFontSize)
            widget:SetScale(summaryScale)
            widget:ClearAllPoints()
            widget.WidgetAnchorID = i

            if (growDirection == "right") then
                widget:SetPoint("topleft", anchor, "topleft", X, Y)
                X = X + summaryColumnStep
                if (i == nextBreakLine) then
                    trackAllButtonAnchor = widget
                    Y = Y - summaryRowStep
                    X = 1
                    nextBreakLine = nextBreakLine + worldSummary.MaxWidgetsPerRow
                end
            else
                widget:SetPoint("topright", anchor, "topright", X, Y)
                X = X - summaryColumnStep
                if (i == nextBreakLine) then
                    trackAllButtonAnchor = widget
                    Y = Y - summaryRowStep
                    X = 1
                    nextBreakLine = nextBreakLine + worldSummary.MaxWidgetsPerRow
                end
            end
        end

        anchor.Button.widget:SetParent(anchor)
        anchor.Button:SetScale(1)
        anchor.Button:ClearAllPoints()
        anchor.Button.Texture:ClearAllPoints()

        if (trackAllButtonAnchor) then
            if (growDirection == "right") then
                anchor.Button:SetPoint("left", trackAllButtonAnchor, "right", 1, 0)
                anchor.Button.Texture:SetRotation(math.pi * 2 * .75)
                anchor.Button.Texture:SetPoint("left", anchor.Button.widget, "left", -16, 0)
            else
                anchor.Button:SetPoint("right", trackAllButtonAnchor, "left", -1, 0)
                anchor.Button.Texture:SetRotation(math.pi / 2)
                anchor.Button.Texture:SetPoint("right", anchor.Button.widget, "right", 16, 0)
            end
            anchor.Button:Show()
        else
            anchor.Button:Hide()
        end

        if (anchor.SummaryRows) then
            for _, rowAnchor in ipairs(anchor.SummaryRows) do
                rowAnchor:Hide()
            end
        end

        worldSummary.ApplyHierarchyToggleState()
    end

    --Apply the summary scale using the upstream direct-anchor layout. Reorder
    --each active category so the row offsets are recalculated with the rendered
    --icon and label height; no row containers or reparenting are introduced.
    function worldSummary.RefreshSummaryScale()
        for _, anchor in ipairs(worldSummary.Anchors) do
            if (anchor.InUse and anchor.Widgets and #anchor.Widgets > 0) then
                worldSummary.ReorderAnchorWidgets(anchor)
            end
        end

        worldSummary.ReAnchor()
        worldSummary.ApplyHierarchyToggleState()
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
            anchor.mapID = nil
            anchor.AnchorTitle = nil
            setAnchorTitleVisibility(anchor, false)
            wipe(anchor.Widgets)

            if (anchor.SummaryRows) then
                for _, rowAnchor in ipairs(anchor.SummaryRows) do
                    rowAnchor:Hide()
                end
            end
        end

        for _, summarySquare in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
            summarySquare:Hide()
        end

        for _, factionButton in ipairs(worldSummary.FactionAnchor.Widgets) do
            factionButton.AmountQuests = 0
            factionButton.Text:SetText(0)
        end
    end

    ---@param questData wqt_questdata
    function worldSummary.AddQuest(questData)
        --unpack quest information

        --get the information for the locals above from the questData
        local questID = questData.questID
        local mapID = questData.mapID
        local numObjectives = questData.numObjectives
        local questCounter = questData.questCounter
        local questName = questData.title
        local x = questData.x
        local y = questData.y
        local filterType = questData.filter
        local worldQuestType = questData.worldQuestType
        local isCriteria = questData.isCriteria
        local isNew = questData.isNew
        local timeLeft = questData.timeLeft
        local order = questData.order

        local artifactPowerIcon = WorldQuestTracker.MapData.ItemIcons["BFA_ARTIFACT"]
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
            if (not WorldQuestTracker.db.profile.anchor_options[mapID].Enabled) then
                anchor.Button:Hide()
                return
            end
        end

        --get the widget and setup it
        local summarySquare = WorldQuestTracker.WorldSummaryQuestsSquares[worldSummary.WidgetIndex]
        worldSummary.WidgetIndex = worldSummary.WidgetIndex + 1

        if (not summarySquare) then
            WorldQuestTracker:Msg("exception: AddQuest() while cache still loading, close and reopen the map.")
            return
        end

        table.insert(anchor.Widgets, summarySquare)

        summarySquare.questData = questData
        summarySquare.lastUpdate = time()
        summarySquare.WidgetID = worldSummary.WidgetIndex
        summarySquare.questID = questID
        summarySquare.CurrentAnchor = anchor

        local summaryVisuals = getSummaryVisualSettings()
        summarySquare:SetParent(anchor)
        summarySquare.DefaultPin = nil
        summarySquare:EnableMouse(true)
        if (summarySquare.SetMouseClickEnabled) then
            summarySquare:SetMouseClickEnabled(true)
        end
        if (summarySquare.SetMouseMotionEnabled) then
            summarySquare:SetMouseMotionEnabled(true)
        end
        summarySquare:RegisterForClicks("LeftButtonDown", "MiddleButtonDown", "RightButtonDown")
        summarySquare:SetFrameLevel(anchor:GetFrameLevel() + 10)
        anchor.Button:SetFrameLevel(anchor:GetFrameLevel() + 25)
        WorldQuestTracker.ApplyWorldSummaryWidgetSize(summarySquare, summaryVisuals.summaryIconSize, summaryVisuals.fontSize)
        summarySquare:SetScale(WorldQuestTracker.db.profile.world_map_config.summary_scale)
        summarySquare:Show()
        summarySquare.Anchor = anchor
        summarySquare.Order = order
        summarySquare.X = x
        summarySquare.Y = y

        local okay, gold, resource, apower = WorldQuestTracker.UpdateSquareWidget(summarySquare, questData, isUsingTracker)
        summarySquare.texture:SetTexCoord(.1, .9, .1, .9)

        if (summarySquare.FactionID == worldSummary.FactionSelected) then
            --widget.factionBorder:Show()
        else
            summarySquare.factionBorder:Hide()
        end

        if not detailsFramework.IsAddonApocalypseWow() and worldSummary.DoesWidgetAwardFactionReputation then
            for factionID, factionButton in pairs(worldSummary.FactionAnchor.WidgetsByFactionID) do
                if (worldSummary.DoesWidgetAwardFactionReputation(summarySquare, factionID)) then
                    factionButton.AmountQuests = factionButton.AmountQuests + 1
                    factionButton.Text:SetText(factionButton.AmountQuests)
                end
            end
        end

        summarySquare:SetAlpha(WorldQuestTracker.db.profile.world_summary_alpha)

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
                if (worldSummary.TotalAPower > 999) then
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
                summarySquare:SetAlpha(WorldQuestTracker.db.profile.world_summary_alpha)

                if (timePriority and timePriority > 0) then
                    if (timeLeft <= timePriority) then
                        detailsFramework:SetFontColor(summarySquare.timeLeftText, "yellow")
                        summarySquare.timeLeftText:SetAlpha(1)
                    else
                        detailsFramework:SetFontColor(summarySquare.timeLeftText, "white")
                        summarySquare.timeLeftText:SetAlpha(0.8)

                        if (WorldQuestTracker.db.profile.alpha_time_priority) then
                            summarySquare:SetAlpha(ALPHA_BLEND_AMOUNT - 0.35)
                        end
                    end
                else
                    detailsFramework:SetFontColor(summarySquare.timeLeftText, "white")
                    summarySquare.timeLeftText:SetAlpha(1)
                end

                summarySquare.timeLeftText:SetText(timeLeft > 1440 and floor(timeLeft/1440) .. "d" or timeLeft > 60 and floor(timeLeft/60) .. "h" or timeLeft .. "m")

                --widget.timeLeftText:SetJustifyH("center")
                summarySquare.timeLeftText:SetJustifyH("center")
                summarySquare.timeLeftText:Show()
            else
                summarySquare.timeLeftText:Hide()
                summarySquare:SetAlpha(WorldQuestTracker.db.profile.world_summary_alpha)
            end
        end

        --Every time a new row begins, refresh the category stack so all
        --following anchors move by exactly one scaled row height.
        if (anchor.WidgetsAmount > 1 and ((anchor.WidgetsAmount - 1) % worldSummary.MaxWidgetsPerRow == 0)) then
            worldSummary.ReAnchor()
        end

        worldSummary.ReorderAnchorWidgets(anchor)

        --save the quest in the quests shown in the world summary
        worldSummary.ShownQuests[questID] = summarySquare
    end

    function worldSummary.LazyUpdate(self, deltaTime)
        if (not WorldMapFrame:IsShown()) then
            return
        end

        --if framerate is low, update more quests at the same time
        local frameRate = GetFramerate()
        local amountToUpdate = 6 + (not WorldQuestTracker.db.profile.hoverover_animations and 5 or 0)

        if (frameRate < 20) then
            amountToUpdate = amountToUpdate + 3
        elseif (frameRate < 30) then
            amountToUpdate = amountToUpdate + 2
        elseif (frameRate < 40) then
            amountToUpdate = amountToUpdate + 1
        end

        for i = 1, amountToUpdate do
            if (WorldMapFrame:IsShown() and #worldSummary.ScheduleToUpdate > 0 and WorldQuestTracker.IsWorldQuestHub(WorldMapFrame.mapID)) then
                ---@type wqt_questdata
                local questData = table.remove(worldSummary.ScheduleToUpdate)

                if (questData) then
                    --check if the quest is already shown(return the widget being use to show the quest)
                    local widgetShown = worldSummary.ShownQuests[questData.questID]
                    if (widgetShown) then
                        --quick update the quest widget
                        WorldQuestTracker.UpdateSquareWidget(widgetShown, widgetShown.questData)
                        worldSummary.ReorderAnchorWidgets(widgetShown.Anchor)
                    else
                        worldSummary.AddQuest(questData)
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
    ---@param questData_AddToWorldMap wqt_questdata[]
    function worldSummary.StartLazyUpdate(questData_AddToWorldMap, questsToUpdate)
        if (not WorldMapFrame:IsShown()) then
            return
        end

        if (not WorldQuestTracker.db.profile.world_map_hubenabled[WorldMapFrame.mapID]) then
            worldSummary.HideSummary()
            return
        end

        if detailsFramework.IsAddonApocalypseWow() then
            if worldSummary.FactionAnchor then
                worldSummary.UpdateFactionRenown()
            else
                C_Timer.After(3, worldSummary.UpdateFactionRenown)
            end
        end

        if (not WorldQuestTracker.db.profile.world_map_config.summary_show) then
            worldSummary.HideSummary()
            return
        end

        local currentShowBy = WorldQuestTracker.db.profile.world_map_config.summary_showby
        local forceLayoutRebuild = worldSummary.ForceLayoutRebuild or worldSummary.LastSummaryShowBy ~= currentShowBy
        worldSummary.ForceLayoutRebuild = nil
        worldSummary.LastSummaryShowBy = currentShowBy

        local bNeedToUpdate = forceLayoutRebuild and true or false

        local numQuestsShown = 0
        for questID in pairs(worldSummary.ShownQuests) do
            numQuestsShown = numQuestsShown + 1
        end

        if (numQuestsShown ~= #questData_AddToWorldMap) then
            bNeedToUpdate = true
        end

        if (not bNeedToUpdate) then
            --check the quests already shown in the summary, if there is not changes in the quests, don't update
            for i = 1, #questData_AddToWorldMap do
                local questData = questData_AddToWorldMap[i]
                local questID = questData.questID
                if (not worldSummary.ShownQuests[questID]) then
                    bNeedToUpdate = true
                    break
                end
            end
        end

        if (not bNeedToUpdate) then
            if (not worldSummary:IsShown()) then
                worldSummary.UpdateMaxWidgetsPerRow()
                worldSummary.ShowSummary()
                worldSummary.RefreshSummaryAnchor()
            end

            for questID, questSummary in pairs(worldSummary.ShownQuests) do
                questSummary:Show()
            end

            worldSummary.ApplyHierarchyToggleState()
            return
        end

        worldSummary.UpdateMaxWidgetsPerRow()
        worldSummary.ShowSummary()
        worldSummary.RefreshSummaryAnchor()

        --A zone/type layout change must be a full rebuild even when this update
        --was originally requested as a partial quest refresh.
        if (forceLayoutRebuild or not questsToUpdate) then
            worldSummary.ClearSummary()
        end

        --copy the quest list
        ---@type wqt_questdata[]
        worldSummary.ScheduleToUpdate = detailsFramework.table.copy({}, questData_AddToWorldMap)

        worldSummary:SetScript("OnUpdate", worldSummary.LazyUpdate)

        --Update the primary/secondary currency display for the map's expansion.
        local currencyProfile, questHubByExp = WorldQuestTracker.RefreshExpansionCurrencyInfo(WorldMapFrame.mapID)
        local texture = currencyProfile and currencyProfile.primary.icon

        if (not texture) then
            if (questHubByExp == 9) then --shadowlands
                texture = WorldQuestTracker.MapData.ArtifactPowerSummaryIcons.SHADOWLANDS_ARTIFACT
            elseif (questHubByExp == 8) then --bfa
                texture = WorldQuestTracker.MapData.ArtifactPowerSummaryIcons.BFA_ARTIFACT
            elseif (questHubByExp == 7) then --legion
                texture = WorldQuestTracker.MapData.ArtifactPowerSummaryIcons.LEGION_ARTIFACT
            end
        end

        if (texture) then
            WorldQuestTracker.WorldMap_APowerIndicatorTexture:SetTexture(texture)
            WorldQuestTracker.WorldMap_APowerIndicatorTexture:SetSize(16, 16)
            WorldQuestTracker.WorldMap_APowerIndicatorTexture:SetTexCoord(0, 1, 0, 1)
        end
    end

    WorldQuestTracker.InitializeFactions()

end
