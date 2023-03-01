
local addonId, wqtInternal = ...

function WorldQuestTrackerAddon.OpenOptionsPanel()
    local wqt = WorldQuestTrackerAddon
    local DF = DetailsFramework

    if (WorldQuestTrackerOptionsPanel) then
        WorldQuestTrackerOptionsPanel:Show()
        return
    end

    local languageInfo = {
		language_addonId = addonId,
	}

    --create the options frame
    local optionsFrame = DF:CreateSimplePanel(UIParent, 800, 600, "World Quest Tracker Options", "WorldQuestTrackerOptionsPanel")
	optionsFrame.Title:SetAlpha(.75)
	optionsFrame:SetFrameStrata("HIGH")
	DF:ApplyStandardBackdrop(optionsFrame)
	optionsFrame:ClearAllPoints()
	PixelUtil.SetPoint(optionsFrame, "center", UIParent, "center", 2, 2, 1, 1)

    --create the footer below the options frame
	local statusBar = CreateFrame("frame", "$parentStatusBar", optionsFrame, "BackdropTemplate")
	statusBar:SetPoint("bottomleft", optionsFrame, "bottomleft")
	statusBar:SetPoint("bottomright", optionsFrame, "bottomright")
	statusBar:SetHeight(20)
	statusBar:SetAlpha(0.9)
	statusBar:SetFrameLevel(optionsFrame:GetFrameLevel()+2)
    DF:ApplyStandardBackdrop(statusBar)
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
		{name = "FrontPage",				title = "S_OPTTIONS_TAB_GENERAL_SETTINGS"},
		{name = "TrackerConfig",			title = "S_OPTTIONS_TAB_TRACKER_SETTINGS"},
		{name = "WorldMapConfig",	    	title = "S_OPTTIONS_TAB_WORLDMAP_SETTINGS"},
		{name = "ZoneMapConfig",			title = "S_OPTTIONS_TAB_ZONEMAP_SETTINGS"},
		{name = "GroupFinderConfig",		title = "S_OPTTIONS_TAB_GROUPFINDER_SETTINGS"},
		--{name = "RaresConfig",				title = "S_OPTTIONS_TAB_RARES_SETTINGS"},
		--{name = "IgnoredQuestsPanel",		title = "S_OPTTIONS_TAB_IGNOREDQUESTS_SETTINGS"},
	},
	frameOptions, hookList, languageInfo)

    --this function runs when any setting is changed
	local globalCallback = function()

	end

	--make the tab button's text be aligned to left and fit the button's area
	for index, frame in ipairs(tabContainer.AllFrames) do
		--DF:ApplyStandardBackdrop(frame)
		local frameBackgroundTexture = frame:CreateTexture(nil, "artwork")
		frameBackgroundTexture:SetPoint("topleft", frame, "topleft", 1, -140)
		frameBackgroundTexture:SetPoint("bottomright", frame, "bottomright", -1, 20)
		frameBackgroundTexture:SetColorTexture (0.2317647, 0.2317647, 0.2317647)
		frameBackgroundTexture:SetVertexColor (0.27, 0.27, 0.27)
		frameBackgroundTexture:SetAlpha (0.3)
		--frameBackgroundTexture:Hide()

		--divisor shown above the background (create above)
		local frameBackgroundTextureTopLine = frame:CreateTexture(nil, "artwork")
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
                    return DB.profile.map_frame_anchor
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
                    return DB.profile.show_faction_frame
                end,
                set = function(self, fixedparam, value)
                    WorldQuestTracker.SetSetting("show_faction_frame", not WorldQuestTracker.db.profile.show_faction_frame)

                end,
                name = "S_OPTIONS_SHOWFACTIONS",
                desc = "S_OPTIONS_SHOWFACTIONS",
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
                desc = "S_MAPBAR_OPTIONSMENU_EQUIPMENTICONS",
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
                desc = "S_ENABLE",
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

            {type = "blank"},

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

    do --Zone Map Settings
        local optionsTable = {
            always_boxfirst = true,
            language_addonId = addonId,
            labelbreakline = true, --will place the text in one line and the dropdown in the next line

            {
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
        }

        DF:BuildMenu(groupFinderSettingsFrame, optionsTable, xStart, yStart, tabFrameHeight, false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template, globalCallback)
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


