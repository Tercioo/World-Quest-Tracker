
local addonId, wqtInternal = ...

function WorldQuestTrackerAddon.OpenOptionsPanel()
    local wqt = WorldQuestTrackerAddon
    local DF = DetailsFramework

    if (WorldQuestTrackerOptionsPanel) then
        WorldQuestTrackerOptionsPanel:Show()
        return
    end

    local unpack = unpack

    local languageInfo = {
		language_addonId = addonId,
	}

    local L = DF.Language.GetLanguageTable(addonId)

    --create the options frame
    local optionsFrame = DF:CreateSimplePanel(UIParent, 800, 600, "World Quest Tracker Options", "WorldQuestTrackerOptionsPanel", {RoundedCorners = true})
	optionsFrame:SetFrameStrata("HIGH")
	optionsFrame:ClearAllPoints()
	PixelUtil.SetPoint(optionsFrame, "center", UIParent, "center", 2, 2, 1, 1)

    --this title bar is created by the rounded corners (RoundedCorners = true)
    optionsFrame.TitleBar.Text:SetText("World Quest Tracker Options")

    --create the footer below the options frame

	local statusBar = CreateFrame("frame", "$parentStatusBar", optionsFrame, "BackdropTemplate")
	statusBar:SetPoint("bottomleft", optionsFrame, "bottomleft")
	statusBar:SetPoint("bottomright", optionsFrame, "bottomright")
	statusBar:SetHeight(20)
	statusBar:SetAlpha(0.9)
	statusBar:SetFrameLevel(optionsFrame:GetFrameLevel()+2)
    --DF:ApplyStandardBackdrop(statusBar)
	DF:BuildStatusbarAuthorInfo(statusBar, "An AddOn By Terciob")

    local bottomGradient = DF:CreateTexture(optionsFrame, {gradient = "vertical", fromColor = {0, 0, 0, 0.6}, toColor = "transparent"}, 1, 100, "artwork", {0, 1, 0, 1}, "bottomGradient")
	bottomGradient:SetPoint("bottom-top", statusBar)

	local frameOptions = {
		y_offset = 0,
		button_width = 108,
		button_height = 23,
		button_x = 190,
		button_y = 1,
		button_text_size = 10,
		right_click_y = 5,
		rightbutton_always_close = true,
		close_text_alpha = 0.4,
		container_width_offset = 30,
	}

    local selectedTabIndicatorDefaultColor = {.4, .4, .4}
    local selectedTabIndicatorColor = {1, 1, 0}

	local hookList = {
		OnSelectIndex = function(tabContainer, tabButton)
			if (not tabButton.leftSelectionIndicator) then
				return
			end

			for i = 1, #tabContainer.AllFrames do
                local thisTabButton = tabContainer.AllButtons[i]
				thisTabButton.leftSelectionIndicator:SetColorTexture(unpack(selectedTabIndicatorDefaultColor))
			end

			tabButton.leftSelectionIndicator:SetColorTexture(unpack(selectedTabIndicatorColor))
			tabButton.selectedUnderlineGlow:Hide()
		end,
	}

    --create the tab system which will hold the tabs for each section of the options panel
	local tabContainer = DF:CreateTabContainer(optionsFrame, "WQT Options", "WQTOptionsPanelContainer",
	{
		{name = "FrontPage",				text = "S_OPTTIONS_TAB_GENERAL_SETTINGS"},
		{name = "TrackerConfig",			text = "S_OPTTIONS_TAB_TRACKER_SETTINGS"},
		{name = "WorldMapConfig",	    	text = "S_OPTTIONS_TAB_WORLDMAP_SETTINGS"},
		{name = "ZoneMapConfig",			text = "S_OPTTIONS_TAB_ZONEMAP_SETTINGS"},
		{name = "GroupFinderConfig",		text = "S_OPTTIONS_TAB_GROUPFINDER_SETTINGS"},
		{name = "DragonRacingConfig",		text = "S_OPTTIONS_TAB_DRAGONRACE_SETTINGS"},
		--{name = "RaresConfig",				text = "S_OPTTIONS_TAB_RARES_SETTINGS"},
		--{name = "IgnoredQuestsPanel",		text = "S_OPTTIONS_TAB_IGNOREDQUESTS_SETTINGS"},
	},
	frameOptions, hookList, languageInfo)

    tabContainer:SetPoint("topleft", optionsFrame, "topleft", 5, -10)
    tabContainer:Show()

    local optionsFrameWidth, optionsFrameHeight = optionsFrame:GetSize()
    tabContainer:SetSize(optionsFrameWidth - 5, optionsFrameHeight - 5)

    --this function runs when any setting is changed
	local globalCallback = function()

	end

	--make the tab button's text be aligned to left and fit the button's area
	for index, frame in ipairs(tabContainer.AllFrames) do
		--DF:ApplyStandardBackdrop(frame)
		local frameBackgroundTexture = frame:CreateTexture("$parentBackgroundTexture", "artwork")
		frameBackgroundTexture:SetPoint("topleft", frame, "topleft", 1, -90)
		frameBackgroundTexture:SetPoint("bottomright", frame, "bottomright", -1, 20)
		frameBackgroundTexture:SetColorTexture (0.2317647, 0.2317647, 0.2317647)
		frameBackgroundTexture:SetVertexColor (0.27, 0.27, 0.27)
		frameBackgroundTexture:SetAlpha (0.3)
		--frameBackgroundTexture:Hide()

		--divisor shown above the background (create above)
		local frameBackgroundTextureTopLine = frame:CreateTexture("$parentBackgroundTextureTopLine", "artwork")
		frameBackgroundTextureTopLine:SetPoint("bottomleft", frameBackgroundTexture, "topleft", 0, 0)
		frameBackgroundTextureTopLine:SetPoint("bottomright", frame, "topright", -1, 0)
		frameBackgroundTextureTopLine:SetHeight(1)
		frameBackgroundTextureTopLine:SetColorTexture(0.1215, 0.1176, 0.1294)
		frameBackgroundTextureTopLine:SetAlpha(1)

		frame.titleText.fontsize = 12

		local gradientBelowTheLine = DF:CreateTexture(frame, {gradient = "vertical", fromColor = "transparent", toColor = DF.IsDragonflight() and {0, 0, 0, 0.15} or {0, 0, 0, 0.25}}, 1, 100, "artwork", {0, 1, 0, 1}, "gradientBelowTheLine")
		gradientBelowTheLine:SetPoint("top-bottom", frameBackgroundTextureTopLine)

		local gradientAboveTheLine = DF:CreateTexture(frame, {gradient = "vertical", fromColor = DF.IsDragonflight() and {0, 0, 0, 0.3} or {0, 0, 0, 0.4}, toColor = "transparent"}, 1, 80, "artwork", {0, 1, 0, 1}, "gradientAboveTheLine")
		gradientAboveTheLine:SetPoint("bottom-top", frameBackgroundTextureTopLine)

		local tabButton = tabContainer.AllButtons[index]

		local leftSelectionIndicator = tabButton:CreateTexture(nil, "overlay")

		if (index == 1) then
			leftSelectionIndicator:SetColorTexture(1, 1, 0)
		else
			leftSelectionIndicator:SetColorTexture(.4, .4, .4)
		end
		leftSelectionIndicator:SetPoint("left", tabButton.widget, "left", 2, 0)
		leftSelectionIndicator:SetSize(4, tabButton:GetHeight()-4)
		tabButton.leftSelectionIndicator = leftSelectionIndicator

		local maxTextLength = tabButton:GetWidth() - 7

		local fontString = _G[tabButton:GetName() .. "_Text"]
		fontString:ClearAllPoints()
		fontString:SetPoint("left", leftSelectionIndicator, "right", 2, 0)
		fontString:SetJustifyH("left")
		fontString:SetWidth(maxTextLength)
		fontString:SetHeight(tabButton:GetHeight()+20)
		fontString:SetWordWrap(true)
		fontString:SetText(fontString:GetText())

		local stringWidth = fontString:GetStringWidth()

		--print(stringWidth, maxTextLength, fontString:GetText())

		if (stringWidth > maxTextLength) then
			local fontSize = DF:GetFontSize(fontString)
			DF:SetFontSize(fontString, fontSize-0.5)
		end
	end

    --get each tab's frame and create a local variable to cache it
    local generalSettingsFrame = tabContainer.AllFrames[1]
    local trackerSettingsFrame = tabContainer.AllFrames[2]
    local worldMapSettingsFrame = tabContainer.AllFrames[3]
    local zoneMapSettingsFrame = tabContainer.AllFrames[4]
    local groupFinderSettingsFrame = tabContainer.AllFrames[5]
    local dragonRaceSettingsFrame = tabContainer.AllFrames[6]
    --local raresSettingsFrame = tabContainer.AllFrames[6]
    --local ignoredQuestsSettingsFrame = tabContainer.AllFrames[7]

    local DB = wqt.db
    local WorldQuestTracker = wqt

    --templates
    local options_text_template = DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
    local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
    local options_switch_template = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")
    local options_slider_template = DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE")
    local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

	--~languages
    local onLanguageChangedCallback = function(languageId)
        WQTrackerLanguage.language = languageId
    end
    --addonId, parent, callback, defaultLanguage
    local languageSelectorDropdown = DF.Language.CreateLanguageSelector(addonId, generalSettingsFrame, onLanguageChangedCallback, WQTrackerLanguage.language)
    languageSelectorDropdown:SetPoint("topright", -21, -108)

    --buttons moved from the statusbar
			---------------------------------------------------------
			--statistics button
			local statisticsButton = CreateFrame("button", "WorldQuestTrackerStatisticsButton", generalSettingsFrame, "BackdropTemplate")
			statisticsButton:SetPoint("bottomleft", generalSettingsFrame, "bottomleft", 5, 26)
			WorldQuestTracker.SetupStatusbarButton(statisticsButton, "Statistics")
			if (GameCooltip.InjectQuickTooltip) then
				GameCooltip:InjectQuickTooltip(statisticsButton, "Click to show reward statistics from world quests, timeline and quests available on your other characters.")
			end

            DF:ApplyStandardBackdrop(statisticsButton)
            statisticsButton:SetSize(120, 20)

			statisticsButton:HookScript("OnEnter", WorldQuestTracker.OnEnterStatusbarButton)
			statisticsButton:HookScript("OnLeave", WorldQuestTracker.OnLeaveStatusbarButton)
			statisticsButton:SetScript("OnClick", function()
				WorldQuestTrackerSummaryPanel:Show()
                WorldQuestTrackerSummaryUpPanel:Show()
                WorldQuestTrackerSummaryDownPanel:Show()
				WorldQuestTracker.UpdateSummaryFrame()
				WorldQuestTrackerSummaryUpPanel.CharsQuestsScroll:Refresh()
            end)

			---------------------------------------------------------
			--sort options
			local sortButton = CreateFrame("button", "WorldQuestTrackerSortButton", generalSettingsFrame, "BackdropTemplate")
			WorldQuestTracker.SetupStatusbarButton(sortButton, L["S_MAPBAR_SORTORDER"])
			sortButton:SetPoint("left", statisticsButton, "right", 5, 0)
            DF:ApplyStandardBackdrop(sortButton)
            sortButton:SetSize(120, 20)

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
					WorldQuestTracker.OnEnterStatusbarButton(self)
				end,
				OnLeaveFunc = function(self)
					sortButton.button_mouse_over = false
					WorldQuestTracker.OnLeaveStatusbarButton(self)
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

			GameCooltip:CoolTipInject(sortButton)

            ---------------------------------------------------------
			-- ~filter
			local filterButton = CreateFrame("button", "WorldQuestTrackerFilterButton", generalSettingsFrame, "BackdropTemplate")
			filterButton:SetPoint("left", sortButton, "right", 5, 0)
			WorldQuestTracker.SetupStatusbarButton(filterButton, L["S_MAPBAR_FILTER"])
            DF:ApplyStandardBackdrop(filterButton)
            filterButton:SetSize(120, 20)

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
					WorldQuestTracker.OnEnterStatusbarButton(self)
				end,
				OnLeaveFunc = function(self)
					filterButton.button_mouse_over = false
					WorldQuestTracker.OnLeaveStatusbarButton(self)
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

    local xStart = 5
    local yStart = -100
    local tabFrameHeight = generalSettingsFrame:GetHeight()

    do --General Settings
        local optionsTable = {
            always_boxfirst = true,
            language_addonId = addonId,

            {
                type = "toggle",
                get = function()
                    return DB.profile.map_frame_anchor == "center"
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("map_frame_anchor", WorldQuestTracker.db.profile.map_frame_anchor == "center" and "left" or "center")
                end,
                name = "S_OPTIONS_MAPFRAME_ALIGN",
                desc = "S_OPTIONS_MAPFRAME_ALIGN",
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.hoverover_animations
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("hoverover_animations", not WorldQuestTracker.db.profile.hoverover_animations)

                end,
                name = "S_OPTIONS_ANIMATIONS",
                desc = "S_OPTIONS_ANIMATIONS",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.bar_anchor == "top"
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("bar_anchor", WorldQuestTracker.db.profile.bar_anchor == "bottom" and "top" or "bottom")

                end,
                name = "S_MAPBAR_OPTIONSMENU_STATUSBARANCHOR",
                desc = "S_MAPBAR_OPTIONSMENU_STATUSBARANCHOR",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.show_emissary_info
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("emissary_quest_info", not WorldQuestTracker.db.profile.show_emissary_info)

                end,
                name = "S_OPTIONS_QUEST_EMISSARY",
                desc = "S_OPTIONS_QUEST_EMISSARY",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.flymaster_tracker_enabled
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("oribos_flight_master", WorldQuestTracker.db.profile.flymaster_tracker_enabled)
                end,
                name = "S_OPTIONS_TRACKER_FLIGHTMASTER",
                desc = "S_OPTIONS_TRACKER_FLIGHTMASTER",
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.bar_visible
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("bar_visible", not WorldQuestTracker.db.profile.bar_visible)
                end,
                name = "S_MAPBAR_OPTIONSMENU_STATUSBAR_VISIBILITY",
                desc = "S_MAPBAR_OPTIONSMENU_STATUSBAR_VISIBILITY",
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.use_old_icons
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("use_old_icons", not WorldQuestTracker.db.profile.use_old_icons)
                end,
                name = "S_MAPBAR_OPTIONSMENU_EQUIPMENTICONS",
                desc = "|TInterface\\AddOns\\WorldQuestTracker\\media\\options_visibility_context:" .. 49 .. ":" .. 87 .. ":0:0:256:256:" .. (0) .. ":" .. (87) .. ":" .. (131) .. ":" .. (131+49) .. "|t"
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.sound_enabled
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("sound_enabled", not WorldQuestTracker.db.profile.sound_enabled)
                end,
                name = "S_MAPBAR_OPTIONSMENU_SOUNDENABLED",
                desc = "S_MAPBAR_OPTIONSMENU_SOUNDENABLED",
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.close_blizz_popups.ABANDON_QUEST
                end,
                set = function(self, fixedparam, value)
                    DB.profile.close_blizz_popups.ABANDON_QUEST = value
                end,
                name = "S_OPTTIONS_AUTOACCEPT_ABANDONQUEST",
                desc = "|TInterface\\AddOns\\WorldQuestTracker\\media\\options_visibility_context:" .. 36 .. ":" .. 173 .. ":0:0:256:256:" .. (80) .. ":" .. (253) .. ":" .. (0) .. ":" .. (36) .. "|t"
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.numerate_quests
                end,
                set = function(self, fixedparam, value)
                    DB.profile.numerate_quests = value
                end,
                name = "S_OPTTIONS_NUMERATE_QUEST",
                desc = "|TInterface\\AddOns\\WorldQuestTracker\\media\\options_visibility_context:" .. 30 .. ":" .. 90 .. ":0:0:256:256:" .. (0) .. ":" .. (90) .. ":" .. (100) .. ":" .. (130) .. "|t"
            },

            {type = "blank"},

            {
                type = "label",
                get = function() return "S_OPTIONS_PATHLINE" end,
                text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.path.enabled
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("pathdots", "enabled", value)
                end,
                name = "S_ENABLE",
                desc = "|TInterface\\AddOns\\WorldQuestTracker\\media\\options_visibility_context:" .. 30 .. ":" .. 134 .. ":0:0:256:256:" .. (91) .. ":" .. (225) .. ":" .. (100) .. ":" .. (130) .. "|t"
            },

            {type = "blank"},

            {
                type = "label",
                get = function() return "S_OPTIONS_TALKINGHEADS" end,
                text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.talking_heads_torgast
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("talkinghead", "talking_heads_torgast", not WorldQuestTracker.db.profile.talking_heads_torgast)
                end,
                name = "S_TORGAST",
                desc = "S_TORGAST",
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.talking_heads_dungeon
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("talkinghead", "talking_heads_dungeon", not WorldQuestTracker.db.profile.talking_heads_dungeon)
                end,
                name = "S_DUNGEON",
                desc = "S_DUNGEON",
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.talking_heads_raid
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("talkinghead", "talking_heads_raid", not WorldQuestTracker.db.profile.talking_heads_raid)
                end,
                name = "S_RAID",
                desc = "S_RAID",
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.talking_heads_openworld
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("talkinghead", "talking_heads_openworld", not WorldQuestTracker.db.profile.talking_heads_openworld)
                end,
                name = "S_OPENWORLD",
                desc = "S_OPENWORLD",
            },

            {type = "breakline"},

            {
                type = "label",
                get = function() return "S_OPTIONS_ACCESSIBILITY" end,
                text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.accessibility.use_bounty_ring
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("accessibility", "use_bounty_ring", not WorldQuestTracker.db.profile.accessibility.use_bounty_ring)
                end,
                name = "S_OPTIONS_ACCESSIBILITY_SHOWBOUNTYRING",
                desc = "S_OPTIONS_ACCESSIBILITY_SHOWBOUNTYRING",
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.accessibility.extra_tracking_indicator
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("accessibility", "extra_tracking_indicator", not WorldQuestTracker.db.profile.accessibility.extra_tracking_indicator)
                end,
                name = "S_OPTIONS_ACCESSIBILITY_EXTRATRACKERMARK",
                desc = "S_OPTIONS_ACCESSIBILITY_EXTRATRACKERMARK"
            },

            {type = "blank"},
            {type = "breakline"},

            {
                type = "label",
                get = function() return "S_VISIBILITY" end,
                text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
            },

            {
                type = "toggle",
                get = function()
                    return DB.profile.show_faction_frame
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("show_faction_frame", not WorldQuestTracker.db.profile.show_faction_frame)

                end,
                name = "S_OPTIONS_SHOWFACTIONS",
                desc = "|TInterface\\AddOns\\WorldQuestTracker\\media\\options_visibility_context:" .. 33 .. ":" .. 208 .. ":0:0:256:256:" .. (0) .. ":" .. (208) .. ":" .. (36+30) .. ":" .. (36+30+33) .. "|t",
            },
            {
                type = "toggle",
                get = function()
                    return DB.profile.show_world_shortcuts
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.show_world_shortcuts = not WorldQuestTracker.db.profile.show_world_shortcuts
                    WorldQuestTracker.SetShownWorldShortcuts()
                end,
                name = "S_OPTIONS_SHOW_WORLDSHORTCUT_BUTTON",
                desc = "|TInterface\\AddOns\\WorldQuestTracker\\media\\options_visibility_context:" .. 36 .. ":" .. 80 .. ":0:0:256:256:" .. (0) .. ":" .. (80) .. ":" .. (0) .. ":" .. (36) .. "|t",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.show_timeleft_button
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.show_timeleft_button = not WorldQuestTracker.db.profile.show_timeleft_button
                    WorldQuestTracker.RefreshStatusBarButtons()
                end,
                name = "S_OPTIONS_SHOW_TIMELEFT_BUTTON",
                desc = "|TInterface\\AddOns\\WorldQuestTracker\\media\\options_visibility_context:" .. 30 .. ":" .. 210 .. ":0:0:256:256:" .. (0) .. ":" .. (210) .. ":" .. (37) .. ":" .. (37+30) .. "|t",
            },

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.show_sort_button
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.show_sort_button = not WorldQuestTracker.db.profile.show_sort_button
                    WorldQuestTracker.RefreshStatusBarButtons()
                end,
                name = "S_OPTIONS_SHOW_SORT_BUTTON",
                desc = "|TInterface\\AddOns\\WorldQuestTracker\\media\\options_visibility_context:" .. 30 .. ":" .. 210 .. ":0:0:256:256:" .. (0) .. ":" .. (210) .. ":" .. (37) .. ":" .. (37+30) .. "|t",
            },

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.show_filter_button
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.show_filter_button = not WorldQuestTracker.db.profile.show_filter_button
                    WorldQuestTracker.RefreshStatusBarButtons()
                end,
                name = "S_OPTIONS_SHOW_FILTER_BUTTON",
                desc = "|TInterface\\AddOns\\WorldQuestTracker\\media\\options_visibility_context:" .. 30 .. ":" .. 210 .. ":0:0:256:256:" .. (0) .. ":" .. (210) .. ":" .. (37) .. ":" .. (37+30) .. "|t",
            },

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.show_warband_rep_warning
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.show_warband_rep_warning = not WorldQuestTracker.db.profile.show_warband_rep_warning
                    if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
                        WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)
                    else
                        WorldQuestTracker.UpdateZoneWidgets(true)
                    end
                end,
                name = "S_OPTIONS_SHOW_WARBAND_REP_WARNING",
                desc = "|TInterface\\AddOns\\WorldQuestTracker\\media\\options_visibility_context:" .. (71-45) .. ":" .. (239-213) .. ":0:0:256:256:" .. (213) .. ":" .. (239) .. ":" .. (45) .. ":" .. (71) .. "|t",
            },

            {type = "blank"},

            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.world_summary_alpha end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.world_summary_alpha = value
                    WorldQuestTracker.UpdateZoneSummaryFrame()
                    WorldQuestTracker.RefreshZoneSummaryAlpha()
                end,
                min = 0.5,
                max = 1,
                step = 0.01,
                usedecimals = true,
                thumbscale = 1.8,
                name = "S_OPTIONS_WORLD_SUMMARY_ALPHA",
                desc = "S_OPTIONS_WORLD_SUMMARY_ALPHA",
            },

            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.worldmap_widget_alpha end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.worldmap_widget_alpha = value
                    local bForceUpdate = true
                    if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
                        WorldQuestTracker.UpdateWorldQuestsOnWorldMap(bForceUpdate)
                    else
                        WorldQuestTracker.UpdateZoneWidgets(bForceUpdate)
                    end
                end,
                min = 0.5,
                max = 1,
                step = 0.01,
                usedecimals = true,
                thumbscale = 1.8,
                name = "S_OPTIONS_WORLDMAP_WIDGET_ALPHA",
                desc = "S_OPTIONS_WORLDMAP_WIDGET_ALPHA",
            },

            {type = "blank"},
            {
                type = "label",
                get = function() return "S_SPEEDRUN" end,
                text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.speed_run.auto_accept
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.speed_run.auto_accept = not WorldQuestTracker.db.profile.speed_run.auto_accept
                    WorldQuestTracker.RefreshStatusBarButtons()
                end,
                name = "S_SPEEDRUN_AUTO_ACCEPT",
                desc = "S_SPEEDRUN_AUTO_ACCEPT",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.speed_run.auto_complete
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.speed_run.auto_complete = not WorldQuestTracker.db.profile.speed_run.auto_complete
                    WorldQuestTracker.RefreshStatusBarButtons()
                end,
                name = "S_SPEEDRUN_AUTO_COMPLETE",
                desc = "S_SPEEDRUN_AUTO_COMPLETE",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.speed_run.cancel_cinematic
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.speed_run.cancel_cinematic = not WorldQuestTracker.db.profile.speed_run.cancel_cinematic
                    WorldQuestTracker.RefreshStatusBarButtons()
                end,
                name = "S_SPEEDRUN_CANCEL_CINEMATIC",
                desc = "S_SPEEDRUN_CANCEL_CINEMATIC",
            },



            --

			--map_frame_scale_enabled = false,
			--map_frame_scale_mod = 1,

        }

        optionsTable.always_boxfirst = true
        optionsTable.language_addonId = addonId
        DF:BuildMenu(generalSettingsFrame, optionsTable, xStart, yStart, tabFrameHeight, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, globalCallback)
    end

    do --Tracker Settings
        local optionsTable = {
            always_boxfirst = true,
            language_addonId = addonId,

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.use_tracker
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("use_tracker", value)
                end,
                name = "S_MAPBAR_OPTIONSMENU_QUESTTRACKER",
                desc = "S_MAPBAR_OPTIONSMENU_QUESTTRACKER",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.show_yards_distance
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("show_yards_distance", value)
                    WorldQuestTracker.RefreshTrackerWidgets()
                end,
                name = "S_MAPBAR_OPTIONSMENU_YARDSDISTANCE",
                desc = "S_MAPBAR_OPTIONSMENU_YARDSDISTANCE",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.tracker_only_currentmap
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("tracker_only_currentmap", value)
                    WorldQuestTracker.RefreshTrackerWidgets()
                end,
                name = "S_MAPBAR_OPTIONSMENU_TRACKER_CURRENTZONE",
                desc = "S_MAPBAR_OPTIONSMENU_TRACKER_CURRENTZONE",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.tracker_show_time
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("tracker_show_time", value)
                    WorldQuestTracker.RefreshTrackerWidgets()
                end,
                name = "S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_TITLE",
                desc = "S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_TITLE",
            },

            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.tracker_scale end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("tracker_scale", value)
                end,
                min = 0.6,
                max = 1.5,
                step = 0.01,
                usedecimals = true,
                thumbscale = 1.8,
                name = "S_MAPBAR_OPTIONSMENU_TRACKER_SCALE_NAME",
                desc = "S_MAPBAR_OPTIONSMENU_TRACKER_SCALE_NAME",
            },
            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.tracker_textsize end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("tracker_textsize", value)
                end,
                min = 8,
                max = 15,
                step = 1,
                thumbscale = 1.8,
                name = "S_TEXT_SIZE",
                desc = "S_TEXT_SIZE",
            },
            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.arrow_update_frequence end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("arrow_update_speed", value)
                end,
                min = 0,
                max = 0.1,
                step = 0.001,
                usedecimals = true,
                thumbscale = 1.8,
                name = "S_MAPBAR_OPTIONSMENU_ARROWSPEED",
                desc = "S_MAPBAR_OPTIONSMENU_ARROWSPEED",
            },
            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.tracker_background_alpha end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.tracker_background_alpha = value
                    WorldQuestTracker.RefreshTrackerWidgets()
                end,
                min = 0,
                max = 0.85,
                step = 0.1,
                usedecimals = true,
                thumbscale = 1.8,
                name = "S_TRACKEROPTIONS_BACKGROUNDALPHA",
                desc = "S_TRACKEROPTIONS_BACKGROUNDALPHA",
            },

            {type = "blank"},

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.tracker_attach_to_questlog
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("tracker_attach_to_questlog", value)
                end,
                name = "S_OPTIONS_TRACKER_ATTACH_TO_QUESTLOG",
                desc = "S_OPTIONS_TRACKER_ATTACH_TO_QUESTLOG",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.tracker_is_locked
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("tracker_is_locked", value)
                end,
                name = "S_MAPBAR_OPTIONSMENU_TRACKERMOVABLE_LOCKED",
                desc = "S_MAPBAR_OPTIONSMENU_TRACKERMOVABLE_LOCKED",
            },
            {
                type = "execute",
                func = function()
					WorldQuestTracker.SetSetting("tracker_attach_to_questlog", true)
                    WorldQuestTrackerScreenPanel:ClearAllPoints()
                    WorldQuestTrackerScreenPanel:SetPoint("center", UIParent, "center", 0, 0)

                    local LibWindow = LibStub("LibWindow-1.1")
                    LibWindow.SavePosition(WorldQuestTrackerScreenPanel)
                end,
                name = "S_OPTIONS_TRACKER_RESETPOSITION",
                desc = "S_OPTIONS_TRACKER_RESETPOSITION",
            },
        }

        DF:BuildMenu(trackerSettingsFrame, optionsTable, xStart, yStart, tabFrameHeight, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, globalCallback)
    end

    do --World Map Settings

        local buildWorldMapOrganizeBy = function()
            local languageId = DF.Language.GetLanguageIdForAddonId(addonId)

            local result = {
                {
                    label = DF.Language.GetText(addonId, "S_OPTIONS_WORLD_ORGANIZE_BYMAP"),
                    languageId = languageId,
                    phraseId = "S_OPTIONS_WORLD_ORGANIZE_BYMAP",
                    value = "byzone",
                    onclick = function()
                        WorldQuestTracker.SetSetting("world_map_config", "summary_showby", "byzone")
                    end,
                },
                {
                    label = DF.Language.GetText(addonId, "S_OPTIONS_WORLD_ORGANIZE_BYTYPE"),
                    languageId = languageId,
                    phraseId = "S_OPTIONS_WORLD_ORGANIZE_BYTYPE",
                    value = "bytype",
                    onclick = function()
                        WorldQuestTracker.SetSetting("world_map_config", "summary_showby", "bytype")
                    end,
                },
            }
            return result
        end

        local buildWorldMapAnchorToSide = function()
            local languageId = DF.Language.GetLanguageIdForAddonId(addonId)

            local result = {
                {
                    label = DF.Language.GetText(addonId, "S_OPTIONS_WORLD_ANCHOR_LEFT"),
                    languageId = languageId,
                    phraseId = "S_OPTIONS_WORLD_ANCHOR_LEFT",
                    value = "left",
                    onclick = function()
                        WorldQuestTracker.SetSetting("world_map_config", "summary_anchor", "left")
                    end,
                },
                {
                    label = DF.Language.GetText(addonId, "S_OPTIONS_WORLD_ANCHOR_RIGHT"),
                    languageId = languageId,
                    phraseId = "S_OPTIONS_WORLD_ANCHOR_RIGHT",
                    value = "right",
                    onclick = function()
                        WorldQuestTracker.SetSetting("world_map_config", "summary_anchor", "right")
                    end,
                },
            }
            return result
        end

        local optionsTable = {
            always_boxfirst = true,
            language_addonId = addonId,
            labelbreakline = true, --will place the text in one line and the dropdown in the next line

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.world_map_config.summary_show
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("world_map_config", "summary_show", value)
                end,
                name = "S_WORLDMAP_QUESTSUMMARY",
                desc = "S_WORLDMAP_QUESTSUMMARY",
            },

            {type = "blank"},

            {
                type = "select",
                get = function()
                    return WorldQuestTracker.db.profile.world_map_config.summary_showby end,
                values = function() return buildWorldMapOrganizeBy() end,
                name = "S_OPTIONS_WORLDMAP_ORGANIZEBY",
                desc = "S_OPTIONS_WORLDMAP_ORGANIZEBY",
            },

            {
                type = "select",
                get = function() return WorldQuestTracker.db.profile.world_map_config.summary_anchor end,
                values = function() return buildWorldMapAnchorToSide() end,
                name = "S_OPTIONS_WORLDMAP_ANCHOR_TO",
                desc = "S_OPTIONS_WORLDMAP_ANCHOR_TO",
            },

            {type = "blank"},

            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.world_map_config.summary_widgets_per_row end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.world_map_config.summary_widgets_per_row = value
                    WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
                end,
                min = 1,
                max = 20,
                step = 1,
                thumbscale = 1.8,
                name = "S_OPTIONS_WORLD_ICONSPERROW",
                desc = "S_OPTIONS_WORLD_ICONSPERROW",
            },
            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.world_map_config.summary_scale end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.world_map_config.summary_scale = value
                    WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
                end,
                min = 0.6,
                max = 1.5,
                step = 1,
                thumbscale = 1.8,
                usedecimals = true,
                name = "S_SCALE",
                desc = "S_SCALE",
            },

            {type = "blank"},

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.world_map_config.onmap_show
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("world_map_config", "onmap_show", value)
                end,
                name = "S_WORLDMAP_QUESTLOCATIONS",
                desc = "S_WORLDMAP_QUESTLOCATIONS",
            },
            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.world_map_config.onmap_scale_offset end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.world_map_config.onmap_scale_offset = value
                    WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
                end,
                min = 0.6,
                max = 1.5,
                step = 1,
                thumbscale = 1.8,
                usedecimals = true,
                name = "S_SCALE",
                desc = "S_SCALE",
            },
        }

        DF:BuildMenu(worldMapSettingsFrame, optionsTable, xStart, yStart, tabFrameHeight, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, globalCallback)
    end

    do
        local worldMapPinScaleFrame = CreateFrame("frame", "WorldQuestTrackerWorldMapPinScaleFrameOptions", worldMapSettingsFrame, "BackdropTemplate")
        worldMapPinScaleFrame:SetPoint("topright", WQTOptionsPanelContainerWorldMapConfig, "topright", -5, yStart)
        worldMapPinScaleFrame:SetSize(250, 300)

        local mapPinScaleHeightUsed = 30

        local optionsTable = {
            {
                type = "label",
                get = function() return "S_OPTTIONS_QUESTLOCATIONSCALE_BYWORLDMAP" end,
                text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
            },
        }

        for hubMapID, scale in pairs(WorldQuestTracker.db.profile.world_map_hubscale) do
            local mapInfo = C_Map.GetMapInfo(hubMapID)
            optionsTable[#optionsTable+1] = {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.world_map_hubscale[hubMapID] end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.world_map_hubscale[hubMapID] = value
                    WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
                end,
                min = 0.6,
                max = 1.5,
                step = 1,
                thumbscale = 1.8,
                usedecimals = true,
                name = mapInfo.name,
                desc = "S_SCALE",
            }

            mapPinScaleHeightUsed = mapPinScaleHeightUsed + 20
        end

        optionsTable.always_boxfirst = true
        optionsTable.language_addonId = addonId

        DF:BuildMenu(worldMapPinScaleFrame, optionsTable, xStart, -5, tabFrameHeight, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, globalCallback)

        do
            local worldMapHubEnabledFrame = CreateFrame("frame", "WorldQuestTrackerWorldMapHubEnabledFrameOptions", worldMapSettingsFrame, "BackdropTemplate")
            worldMapHubEnabledFrame:SetPoint("topright", WQTOptionsPanelContainerWorldMapConfig, "topright", -5, yStart)
            worldMapHubEnabledFrame:SetSize(250, 300)

            local optionsTable = {
                {
                    type = "label",
                    get = function() return "S_OPTTIONS_WORLDMAP_HUB_ENABLE" end,
                    text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
                },
            }

            for hubMapID, scale in pairs(WorldQuestTracker.db.profile.world_map_hubenabled) do
                local mapInfo = C_Map.GetMapInfo(hubMapID)
                optionsTable[#optionsTable+1] = {
                    type = "toggle",
                    get = function() return WorldQuestTracker.db.profile.world_map_hubenabled[hubMapID] end,
                    set = function(self, fixedparam, value)
                        WorldQuestTracker.db.profile.world_map_hubenabled[hubMapID] = value
                        WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
                    end,
                    name = mapInfo.name,
                    desc = mapInfo.name,
                }
            end

            optionsTable.always_boxfirst = true
            optionsTable.language_addonId = addonId

            DF:BuildMenu(worldMapHubEnabledFrame, optionsTable, xStart, -mapPinScaleHeightUsed, tabFrameHeight, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, globalCallback)
        end
    end



    do --Zone Map Settings
        local optionsTable = {
            always_boxfirst = true,
            language_addonId = addonId,
            labelbreakline = true, --will place the text in one line and the dropdown in the next line

            { --show zone summary
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.zone_map_config.summary_show
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("use_quest_summary", value)
                end,
                name = "S_MAPBAR_OPTIONSMENU_ZONE_QUESTSUMMARY",
                desc = "S_MAPBAR_OPTIONSMENU_ZONE_QUESTSUMMARY",
            },

            {type = "blank"},

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.show_summary_minimize_button
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("show_summary_minimize_button", value)
                end,
                name = "S_OPTIONS_SHOW_MINIMIZE_BUTTON",
                desc = "S_OPTIONS_SHOW_MINIMIZE_BUTTON",
            },
            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.zone_map_config.quest_summary_scale end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.zone_map_config.quest_summary_scale = value
                    if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
                        WorldQuestTracker.UpdateZoneWidgets(true)
                    end
                end,
                min = 0.6,
                max = 1.5,
                step = 1,
                thumbscale = 1.8,
                usedecimals = true,
                name = "S_SCALE",
                desc = "S_SCALE",
            },

            {type = "blank"},

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.zone_map_config.show_widgets
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("zone_map_config", "show_widgets", value)
                end,
                name = "S_WORLDMAP_QUESTLOCATIONS",
                desc = "S_WORLDMAP_QUESTLOCATIONS",
            },
            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.zone_map_config.scale end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.zone_map_config.scale = value
                    if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
                        WorldQuestTracker.UpdateZoneWidgets(true)
                    end
                end,
                min = 0.6,
                max = 1.5,
                step = 1,
                thumbscale = 1.8,
                usedecimals = true,
                name = "S_SCALE",
                desc = "S_SCALE",
            },

            {type = "blank"},

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.zone_only_tracked
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("zone_only_tracked", value)
                end,
                name = "S_OPTIONS_ZONE_SHOWONLYTRACKED",
                desc = "S_OPTIONS_ZONE_SHOWONLYTRACKED",
            },
        }

        DF:BuildMenu(zoneMapSettingsFrame, optionsTable, xStart, yStart, tabFrameHeight, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, globalCallback)

        --local zonesIgnoredOptionTable = {
        --}
    end

    do --Group Finder Settings

        local buildLeaveGroupOptions = function()
            local languageId = DF.Language.GetLanguageIdForAddonId(addonId)
            local ff = WorldQuestTrackerFinderFrame

            local result = {
                {
                    label = DF.Language.GetText(addonId, "S_GROUPFINDER_LEAVEOPTIONS_IMMEDIATELY"),
                    languageId = languageId,
                    phraseId = "S_GROUPFINDER_LEAVEOPTIONS_IMMEDIATELY",
                    value = "autoleave",
                    onclick = function()
                        ff.SetAutoGroupLeaveFunc(nil, nil, true, "autoleave")
                    end,
                },
                {
                    label = DF.Language.GetText(addonId, "S_GROUPFINDER_LEAVEOPTIONS_DONTLEAVE"),
                    languageId = languageId,
                    phraseId = "S_GROUPFINDER_LEAVEOPTIONS_DONTLEAVE",
                    value = "noleave",
                    onclick = function()
                        ff.SetAutoGroupLeaveFunc(nil, nil, true, "noleave")
                    end,
                },
                {
                    label = DF.Language.GetText(addonId, "S_GROUPFINDER_LEAVEOPTIONS_AFTERX"),
                    languageId = languageId,
                    phraseId = "S_GROUPFINDER_LEAVEOPTIONS_AFTERX",
                    value = "autoleave_delayed",
                    onclick = function()
                        ff.SetAutoGroupLeaveFunc(nil, nil, true, "autoleave_delayed")
                    end,
                },
                {
                    label = DF.Language.GetText(addonId, "S_GROUPFINDER_LEAVEOPTIONS_ASKX"),
                    languageId = languageId,
                    phraseId = "S_GROUPFINDER_LEAVEOPTIONS_ASKX",
                    value = "askleave_delayed",
                    onclick = function()
                        ff.SetAutoGroupLeaveFunc(nil, nil, true, "askleave_delayed")
                    end,
                },
            }
            return result
        end

        local optionsTable = {
            always_boxfirst = true,
            language_addonId = addonId,
            labelbreakline = true, --will place the text in one line and the dropdown in the next line

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.groupfinder.enabled
                end,
                set = function(self, fixedparam, value)
                    local ff = WorldQuestTrackerFinderFrame
                    ff.SetEnabledFunc(nil, nil, value)
                end,
                name = "S_GROUPFINDER_ENABLED",
                desc = "S_GROUPFINDER_ENABLED",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.rarescan.search_group
                end,
                set = function(self, fixedparam, value)
                    local ff = WorldQuestTrackerFinderFrame
                    ff.SetFindGroupForRares(nil, nil, value)
                end,
                name = "S_GROUPFINDER_AUTOOPEN_RARENPC_TARGETED",
                desc = "S_GROUPFINDER_AUTOOPEN_RARENPC_TARGETED",
            },
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.groupfinder.tracker_buttons
                end,
                set = function(self, fixedparam, value)
                    local ff = WorldQuestTrackerFinderFrame
                    ff.SetOTButtonsFunc(nil, nil, value)
                end,
                name = "S_GROUPFINDER_OT_ENABLED",
                desc = "S_GROUPFINDER_OT_ENABLED",
            },

            {type = "blank"},

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.groupfinder.dont_open_in_group
                end,
                set = function(self, fixedparam, value)
                    local ff = WorldQuestTrackerFinderFrame
                    ff.AlreadyInGroupFunc(nil, nil, value)
                end,
                name = "S_OPTIONS_GF_DONT_SHOW_IFGROUP",
                desc = "S_OPTIONS_GF_DONT_SHOW_IFGROUP",
            },

            {type = "blank"},

            {
                type = "select",
                get = function()
                    local groupFinderConfig = WorldQuestTracker.db.profile.groupfinder
                    return groupFinderConfig.autoleave and "autoleave" or groupFinderConfig.autoleave_delayed and "autoleave_delayed" or groupFinderConfig.askleave_delayed and "askleave_delayed" or "noleave"
                end,
                values = function() return buildLeaveGroupOptions() end,
                name = "S_GROUPFINDER_LEAVEOPTIONS",
                desc = "S_GROUPFINDER_LEAVEOPTIONS",
            },
            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.groupfinder.leavetimer end,
                set = function(self, fixedparam, value)
                    local ff = WorldQuestTrackerFinderFrame
                    ff.SetGroupLeaveTimeoutFunc(nil, nil, value)
                end,
                min = 1,
                max = 60,
                step = 1,
                thumbscale = 1.8,
                name = "S_GROUPFINDER_SECONDS",
                desc = "S_GROUPFINDER_SECONDS",
            },

            {type = "breakline"},

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.groupfinder.kfilter.show_button
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.groupfinder.kfilter.show_button = value
                end,
                name = "S_OPTIONS_GF_SHOWOPTIONS_BUTTON",
                desc = "S_OPTIONS_GF_SHOWOPTIONS_BUTTON",
            },
        }

        DF:BuildMenu(groupFinderSettingsFrame, optionsTable, xStart, yStart, tabFrameHeight, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, globalCallback)
    end

    do
        local optionsTable = {
            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.dragon_racing.minimap_enabled
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.dragon_racing.minimap_enabled = value
                    if (not value) then
                        if (WorldQuestTrackerDragonRacingFrame and WorldQuestTrackerDragonRacingFrame:IsShown()) then
                            WorldQuestTrackerDragonRacingFrame:Hide()
                        end
                    end
                end,
                name = "S_OPTTIONS_DRAGONRACE_MINIMAP",
                desc = "S_OPTTIONS_DRAGONRACE_MINIMAP",
            },
            {
                type = "range",
                get = function() return WorldQuestTracker.db.profile.dragon_racing.minimap_scale end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.db.profile.dragon_racing.minimap_scale = value
                    if (WorldQuestTrackerDragonRacingFrame) then
                        WorldQuestTrackerDragonRacingFrame:SetScale(value)
                    end
                end,
                min = 0.65,
                max = 2,
                step = 0.1,
                thumbscale = 1.8,
                usedecimals = true,
                name = "S_SCALE",
                desc = "S_SCALE",
            },

            {
                type = "color",
                get = function()
                    local r, g, b = unpack(WorldQuestTracker.db.profile.dragon_racing.minimap_track_color)
                    return r, g, b
                end,
                set = function(widget, r, g, b)
                    local colorTable = WorldQuestTracker.db.profile.dragon_racing.minimap_track_color
                    colorTable[1], colorTable[2], colorTable[3] = r, g, b
                    if (WorldQuestTrackerDragonRacingFrameMinimapTexture) then
                        WorldQuestTrackerDragonRacingFrameMinimapTexture:SetVertexColor(r, g, b)
                    end
                end,
                name = "S_OPTTIONS_DRAGONRACE_TRACKCOLOR",
                desc = "S_OPTTIONS_DRAGONRACE_TRACKCOLOR",
            },
        }

        optionsTable.always_boxfirst = true
        optionsTable.language_addonId = addonId
        DF:BuildMenu(dragonRaceSettingsFrame, optionsTable, xStart, yStart, tabFrameHeight, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, globalCallback)
    end

    do --Rare Finder Settings
        --[=[
        local optionsTable = {
            always_boxfirst = true,
            language_addonId = addonId,
            labelbreakline = true, --will place the text in one line and the dropdown in the next line

            {
                type = "toggle",
                get = function()
                    return WorldQuestTracker.db.profile.rarescan.playsound
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("use_tracker", "rarescan", "playsound", value)
                end,
                name = "S_RAREFINDER_SOUND_ENABLED",
                desc = "S_RAREFINDER_SOUND_ENABLED",
            },
        }

        DF:BuildMenu(raresSettingsFrame, optionsTable, xStart, yStart, tabFrameHeight, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, globalCallback)
        --]=]
    end
end


