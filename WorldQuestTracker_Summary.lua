
local addonId, wqtInternal = ...

---@type detailsframework
local DF = DetailsFramework

--world quest tracker object
local WorldQuestTracker = WorldQuestTrackerAddon
if (not WorldQuestTracker) then
	return
end

local worldFramePOIs = WorldQuestTrackerWorldMapPOI
local anchorFrame = WorldMapFrame.ScrollContainer

--localization
local L = DF.Language.GetLanguageTable(addonId)

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
    DF:CreateAnimation(worldSummary.HideAnimation, "Translation", 1, 0.9, -300, 0)

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
        local pinAnchor = CreateFrame("button", nil, worldFramePOIs, WorldQuestTracker.DataProvider:GetPinTemplate())
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
                local mapTable = WorldQuestTracker.mapTables[mapID]

                if (mapTable) then
                    local config = WorldQuestTracker.db.profile.anchor_options[mapID]
                    if (not config) then
                        config = {Enabled = true, YOffset = 0, Alpha = 1, TextColor = {1, .8, .2, .854}, ScaleOffset = 0}
                        WorldQuestTracker.db.profile.anchor_options[mapID] = config
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
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_ARTIFACTPOWER]]
                anchorTitle = "Artifact Power"

            elseif (filterType == "reputation_token") then
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_REPUTATION]]
                anchorTitle = "Reputation"
                anchor.anchorType = filterType

            elseif (filterType == "garrison_resource") then
                anchor = worldSummary.AnchorsByQuestType[worldSummary.QuestTypesByIndex[worldSummary.QuestTypes.ANCHORTYPE_RESOURCES]]
                anchorTitle = "Resources"

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

        local X, Y = 1, -1
        --by default make the anchor be the latest widget in the anchor
        --if the anchor has a breakline, make the anchor be the last widget in the first row
        local trackAllButtonAnchor = anchor.Widgets[#anchor.Widgets]

        --reorder the squares by settings its point
        local nextBreakLine = worldSummary.MaxWidgetsPerRow
        for i = 1, #anchor.Widgets do
            local widget = anchor.Widgets[i]
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
        local widgetWidget = factionAnchor.Widgets[1]:GetWidth() + 3
        for buttonIndex, factionButton in ipairs(factionAnchor.Widgets) do
            factionButton:ClearAllPoints()
            local mapId = WorldQuestTracker.GetCurrentMapAreaID()
            local factionsOfTheMap = WorldQuestTracker.GetFactionsAllowedOnMap(mapId)
            --dumpt(factionsOfTheMap) = none
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
                    local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = WorldQuestTracker.GetFactionDataByID(factionButton.FactionID)
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

            local name, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = WorldQuestTracker.GetFactionDataByID(self.MyObject.FactionID)
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
                GameCooltip:AddLine("Paragon", HIGHLIGHT_FONT_COLOR_CODE .. " " .. format(REPUTATION_PROGRESS_FORMAT, BreakUpLargeNumbers(value), BreakUpLargeNumbers(threshold)) .. FONT_COLOR_CODE_CLOSE)
                GameCooltip:AddIcon([[Interface\GossipFrame\VendorGossipIcon]], 1, 1, 20, 20, 0, 1, 0, 1)
                GameCooltip:AddStatusBar(value / threshold * 100, 1, 0, 0.65, 0, 0.7, nil, {value = 100, color = {.21, .21, .21, 0.8}, texture = [[Interface\Tooltips\UI-Tooltip-Background]]}, [[Interface\Tooltips\UI-Tooltip-Background]])

            else
                --shows reputation statusbar
                GameCooltip:AddLine(_G ["FACTION_STANDING_LABEL" .. standingID], HIGHLIGHT_FONT_COLOR_CODE .. " " .. format(REPUTATION_PROGRESS_FORMAT, BreakUpLargeNumbers(barValue), BreakUpLargeNumbers(barMax)) .. FONT_COLOR_CODE_CLOSE)
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
            for _, summarySquare in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
                if (summarySquare.FactionID == self.MyObject.FactionID) then
                    local bAwardReputation = C_QuestLog.DoesQuestAwardReputationWithFaction(summarySquare.questID or 0, factionID or 0)
                    if (bAwardReputation) then
                        summarySquare.LoopFlash:Play()
                    end
                end
            end

            --play quick flash on widgets shown in the world map(quest locations)
            for questCounter, button in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
                if (button.FactionID == self.MyObject.FactionID) then
                    local bAwardReputation = C_QuestLog.DoesQuestAwardReputationWithFaction(button.questID or 0, factionID or 0)
                    if (bAwardReputation) then
                        button.FactionPulseAnimation:Play()
                    end
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
            for _, summarySquare in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
                if (summarySquare.FactionID == self.MyObject.FactionID) then
                    summarySquare.LoopFlash:Stop()
                end
            end

            --stop quick flash on widgets shown in the world map(quest locations)
            for questCounter, button in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
                if (button.FactionID == self.MyObject.FactionID) then
                    button.FactionPulseAnimation:Stop()
                end
            end
        end

        --create buttons, one for each faction, amount of buttons created is around ~42 button
        for factionID, _ in pairs(WorldQuestTracker.MapData.AllFactionIds) do --creates one button for each faction registered
            if (type(factionID) == "number") then
                local factionName = WorldQuestTracker.GetFactionDataByID(factionID)
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
                    factionAnchor.WidgetsByFactionID[factionID] = factionButton
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
                    glowTexture:SetPoint("center", paragonRewardIcon, "center", 0, 0)
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
                    factionIcon:SetTexture(WorldQuestTracker.MapData.FactionIcons[factionID])
                    factionIcon:SetTexCoord(.1, .9, .1, .96)
                    factionButton.Icon = factionIcon

                    --add a highlight effect
                    local factionIconHighlight = factionButton:CreateTexture(nil, "highlight")
                    factionIconHighlight:SetPoint("topleft", factionButton.widget, "topleft", 0, 0)
                    factionIconHighlight:SetPoint("bottomright", factionButton.widget, "bottomright", 0, 0)
                    factionIconHighlight:SetTexture(WorldQuestTracker.MapData.FactionIcons[factionID])
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

        worldSummary.FactionSelected = worldSummary.FactionIDs[worldSummary.FactionSelected_OnInit]
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
            local factionID = worldSummary.FactionIDs[buttonIndex]

            --get all anchors, check if quests on this anchor are from the faction and track them
            for index, anchor in pairs(worldSummary.Anchors) do
                for i = 1, #anchor.Widgets do
                    local widget = anchor.Widgets[i]
                    if (widget:IsShown() and widget.questID and widget.FactionID == factionID) then
                        table.insert(questsToTrack, widget)
                    end
                end
            end

            --lazy add to tracker
            C_Timer.NewTicker(.04, function(tickerObject)
                local widget = table.remove(questsToTrack)
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
            worldSummary.FactionSelected = worldSummary.FactionIDs[buttonIndex]
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
        for _, summarySquare in pairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
            if (summarySquare:IsShown()) then
                local conduitType, borderTexture, borderColor, itemLink = WorldQuestTracker.GetConduitQuestData(summarySquare.questID)
                WorldQuestTracker.UpdateBorder(summarySquare)

                if (summarySquare.FactionID == worldSummary.FactionSelected) then
                    --widget.factionBorder:Show()
                else
                    summarySquare.factionBorder:Hide()
                end
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
        table.insert(anchor.Widgets, summarySquare)

        if (not summarySquare) then
            WorldQuestTracker:Msg("exception: AddQuest() while cache still loading, close and reopen the map.")
            return
        end

        summarySquare.questData = questData
        summarySquare.lastUpdate = time()
        summarySquare.WidgetID = worldSummary.WidgetIndex
        summarySquare.questID = questID
        summarySquare.CurrentAnchor = anchor

        summarySquare:SetScale(WorldQuestTracker.db.profile.world_map_config.summary_scale)
        summarySquare:Show()
        summarySquare.Anchor = anchor
        summarySquare.Order = order
        summarySquare.X = x
        summarySquare.Y = y

        local okay, gold, resource, apower = WorldQuestTracker.UpdateWorldWidget(summarySquare, questData, isUsingTracker)
        summarySquare.texture:SetTexCoord(.1, .9, .1, .9)

        if (summarySquare.FactionID == worldSummary.FactionSelected) then
            --widget.factionBorder:Show()
        else
            summarySquare.factionBorder:Hide()
        end

        local factionButton = worldSummary.FactionAnchor.WidgetsByFactionID[summarySquare.FactionID]
        if (factionButton) then
            local bAwardReputation = C_QuestLog.DoesQuestAwardReputationWithFaction(questID or 0, summarySquare.FactionID or 0)
            if (bAwardReputation) then
                factionButton.AmountQuests = factionButton.AmountQuests + 1
                factionButton.Text:SetText(factionButton.AmountQuests)
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
                summarySquare:SetAlpha(WorldQuestTracker.db.profile.world_summary_alpha)

                if (timePriority and timePriority > 0) then
                    if (timeLeft <= timePriority) then
                        DF:SetFontColor(summarySquare.timeLeftText, "yellow")
                        summarySquare.timeLeftText:SetAlpha(1)
                    else
                        DF:SetFontColor(summarySquare.timeLeftText, "white")
                        summarySquare.timeLeftText:SetAlpha(0.8)

                        if (WorldQuestTracker.db.profile.alpha_time_priority) then
                            summarySquare:SetAlpha(ALPHA_BLEND_AMOUNT - 0.35)
                        end
                    end
                else
                    DF:SetFontColor(summarySquare.timeLeftText, "white")
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

        if (anchor.WidgetsAmount == worldSummary.MaxWidgetsPerRow + 1) then
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
                        WorldQuestTracker.UpdateWorldWidget(widgetShown, widgetShown.questData)
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

        if (not WorldQuestTracker.db.profile.world_map_config.summary_show) then
            worldSummary.HideSummary()
            return
        end

        local bNeedToUpdate = false

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
        ---@type wqt_questdata[]
        worldSummary.ScheduleToUpdate = DF.table.copy({}, questData_AddToWorldMap)

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
end
