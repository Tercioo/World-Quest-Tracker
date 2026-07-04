

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

function WorldQuestTracker.InitializeFactions()

    local worldSummary = WorldQuestTracker.WorldSummary

    --Faction selectors operate on the reputation actually awarded by the quest.
    --The quest's primary FactionID alone is not sufficient for quests that award
    --multiple reputations or whose cached faction field is temporarily missing.
    function worldSummary.DoesWidgetAwardFactionReputation(widget, factionID)
        if (not widget or not widget.questID or not factionID) then
            return false
        end

        local awardsReputation = C_QuestLog.DoesQuestAwardReputationWithFaction(widget.questID, factionID)
        if (awardsReputation ~= nil) then
            return awardsReputation
        end

        return widget.FactionID == factionID
    end

    function worldSummary.GetFactionQuestWidgets(factionID)
        local widgets = {}
        local addedQuestIDs = {}

        local function addWidget(widget, requireShown)
            if (not widget or not widget.questID or addedQuestIDs[widget.questID]) then
                return
            end
            if (requireShown and not widget:IsShown()) then
                return
            end
            if (worldSummary.DoesWidgetAwardFactionReputation(widget, factionID)) then
                addedQuestIDs[widget.questID] = true
                table.insert(widgets, widget)
            end
        end

        if (WorldQuestTracker.GetCurrentZoneType() == "zone") then
            for _, widget in ipairs(WorldQuestTracker.Cache_ShownWidgetsOnZoneMap or {}) do
                addWidget(widget, true)
            end
        else
            --Summary widgets cover every quest in the current world/continent hub,
            --including quests whose location pin is temporarily unavailable.
            for _, widget in pairs(worldSummary.ShownQuests or {}) do
                addWidget(widget, false)
            end
            for _, widget in pairs(WorldQuestTracker.WorldMapSmallWidgets or {}) do
                addWidget(widget, true)
            end
        end

        return widgets
    end

    function worldSummary.TrackAllFactionQuests(factionID)
        local questsToTrack = worldSummary.GetFactionQuestWidgets(factionID)
        if (#questsToTrack == 0) then
            return
        end

        C_Timer.NewTicker(.04, function(tickerObject)
            local widget = table.remove(questsToTrack)
            if (not widget) then
                tickerObject:Cancel()
                return
            end

            WorldQuestTracker.CheckAddToTracker(widget, widget, true)
            local questID = widget.questID

            for _, mapWidget in pairs(WorldQuestTracker.WorldMapSmallWidgets or {}) do
                if (mapWidget.questID == questID and mapWidget:IsShown()) then
                    if (mapWidget.onEndTrackAnimation and mapWidget.onEndTrackAnimation:IsPlaying()) then
                        mapWidget.onEndTrackAnimation:Stop()
                    end
                    if (mapWidget.onStartTrackAnimation) then
                        mapWidget.onStartTrackAnimation:Play()
                    end
                    if (mapWidget.AddedToTrackerAnimation and not mapWidget.AddedToTrackerAnimation:IsPlaying()) then
                        mapWidget.AddedToTrackerAnimation:Play()
                    end
                end
            end
        end)
    end

    function worldSummary.UpdateFactionRenown()
        for factionId, factionButton in pairs(worldSummary.FactionAnchor.WidgetsByFactionID) do
            factionButton.AmountQuests = 0
            factionButton.Text:SetText(-1)

            ---@type majorfactiondata
            local majorFactionData = C_MajorFactions.GetMajorFactionData(factionId)
            if majorFactionData then
                factionButton.Text:SetText(majorFactionData.renownLevel or -1)
            end
        end
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
                            factionButton:SetPoint("left", previousFactionButton, "right", repStatusbarWidth+6, 0)
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

                    factionButton.ProgressStatusBar:SetMinMaxValues(barMin, barMax)
                    factionButton.ProgressStatusBar:SetValue(barValue)
                    factionButton.factionName = name

                    ---@type majorfactiondata
                    local majorFactionData = C_MajorFactions.GetMajorFactionData(factionButton.FactionID)

                    if detailsFramework.IsAddonApocalypseWow() then
                        factionButton.Text:SetText(majorFactionData and majorFactionData.renownLevel or -1)
                    end

                    ---@class majorfactiondata : table
                    ---@field renownReputationEarned number
                    ---@field renownTrackLevelEffectID number
                    ---@field expansionID number
                    ---@field renownFanfareSoundKitID number
                    ---@field renownLevel number
                    ---@field uiPriority number
                    ---@field playerCompanionID number
                    ---@field factionID number
                    ---@field bountySetID number
                    ---@field maxLevel number
                    ---@field renownLevelThreshold number
                    ---@field celebrationSoundKit number
                    ---@field name string
                    ---@field description string
                    ---@field unlockDescription string
                    ---@field textureKit string
                    ---@field isUnlocked boolean
                    ---@field useJourneyUnlockToast boolean
                    ---@field highlights table
                    ---@field factionFontColor table

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
        factionAnchor:SetFrameLevel(math.max(worldSummary:GetFrameLevel() + 80, 400))
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

            GameCooltip:AddLine("Click: track all quests awarding this faction reputation", "", 1, "orange", "orange", 9)
            GameCooltip:AddIcon([[Interface\AddOns\WorldQuestTracker\media\ArrowFrozen]], 1, 1, 12, 12, 0.1171, 0.6796, 0.1171, 0.7343)

            GameCooltip:Show()

            if (self.MyObject.OnLeaveAnimation:IsPlaying()) then
                self.MyObject.OnLeaveAnimation:Stop()
            end
            self.MyObject.OnEnterAnimation:Play()

            --play quick flash on squares showing quests of this faction
            for _, summarySquare in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
                if (summarySquare:IsShown() and worldSummary.DoesWidgetAwardFactionReputation(summarySquare, factionID)) then
                    summarySquare.LoopFlash:Play()
                end
            end

            --play quick flash on widgets shown in the world map(quest locations)
            for questCounter, button in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
                if (button:IsShown() and worldSummary.DoesWidgetAwardFactionReputation(button, factionID)) then
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
            for _, summarySquare in ipairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
                if (worldSummary.DoesWidgetAwardFactionReputation(summarySquare, self.MyObject.FactionID)) then
                    summarySquare.LoopFlash:Stop()
                end
            end

            --stop quick flash on widgets shown in the world map(quest locations)
            for questCounter, button in pairs(WorldQuestTracker.WorldMapSmallWidgets) do
                if (worldSummary.DoesWidgetAwardFactionReputation(button, self.MyObject.FactionID)) then
                    button.FactionPulseAnimation:Stop()
                end
            end
        end

        --create buttons, one for each faction, amount of buttons created is around ~42 button
        for factionID, _ in pairs(WorldQuestTracker.MapData.AllFactionIds) do --creates one button for each faction registered
            if (type(factionID) == "number") then
                local factionName = WorldQuestTracker.GetFactionDataByID(factionID)
                if (factionName) then
                    local factionButton = detailsFramework:CreateButton(factionAnchor, worldSummary.OnSelectFaction, 24, 25, "", factionButtonIndex)
                    factionButton.widget:EnableMouse(true)
                    if (factionButton.widget.SetMouseClickEnabled) then
                        factionButton.widget:SetMouseClickEnabled(true)
                    end
                    if (factionButton.widget.SetMouseMotionEnabled) then
                        factionButton.widget:SetMouseMotionEnabled(true)
                    end
                    factionButton.widget:RegisterForClicks("LeftButtonUp")
                    factionButton.widget:SetFrameLevel(factionAnchor:GetFrameLevel() + 1)

                    local progressStatusBar = CreateFrame("statusbar", nil, factionButton.widget)
                    progressStatusBar:SetPoint("topleft", factionButton.widget, "topright", 1, 1)
                    progressStatusBar:SetPoint("bottomleft", factionButton.widget, "bottomright", 1, -1)
                    progressStatusBar:SetWidth(repStatusbarWidth)
                    progressStatusBar:SetOrientation("VERTICAL")
                    factionButton.ProgressStatusBar = progressStatusBar

                    progressStatusBar.Background = progressStatusBar:CreateTexture(nil, "background")
                    progressStatusBar.Background:SetAllPoints()
                    progressStatusBar.Background:SetColorTexture(0.05, 0.05, 0.05, 0.98)

                    progressStatusBar:SetStatusBarTexture([[Interface\AddOns\WorldQuestTracker\media\bar_hyanda_reverse.png]])

                    --animations
                    factionButton.OnEnterAnimation = detailsFramework:CreateAnimationHub(factionButton, function() end, function() end)
                    local anim = WorldQuestTracker:CreateAnimation(factionButton.OnEnterAnimation, "Scale", 1, WQT_ANIMATION_SPEED, 1, 1, 1.1, 1.1, "center", 0, 0)
                    anim:SetEndDelay(60) --this fixes the animation going back to 1 after it finishes

                    factionButton.OnLeaveAnimation = detailsFramework:CreateAnimationHub(factionButton, function() end, function() end)
                    WorldQuestTracker:CreateAnimation(factionButton.OnLeaveAnimation, "Scale", 2, WQT_ANIMATION_SPEED, 1.1, 1.1, 1, 1, "center", 0, 0)

                    --button widgets
                    --factionButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
                    factionButton:HookScript("OnEnter", buttonOnEnter)
                    factionButton:HookScript("OnLeave", buttonOnLeave)

                    factionButton.FactionID = factionID
                    factionButton.AmountQuests = 0
                    factionAnchor.WidgetsByFactionID[factionID] = factionButton
                    factionButton.Index = factionButtonIndex

                    detailsFramework:CreateBorder(factionButton.widget, 0.85, 0, 0)

                    factionButton.OverlayFrame = CreateFrame("frame", nil, factionButton.widget, "BackdropTemplate")
                    factionButton.OverlayFrame:SetFrameLevel(factionButton:GetFrameLevel()+1)
                    factionButton.OverlayFrame:SetAllPoints()
                    factionButton.OverlayFrame:EnableMouse(false)
                    detailsFramework:CreateBorder(factionButton.OverlayFrame, 1, 0, 0)
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

                    paragonRewardIcon.glowAnimation = detailsFramework:CreateAnimationHub(glowTexture, function() end, function() end)
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
                    amountQuestsBackground2:SetSize(12, 12)

                    local amountQuests = factionButton:CreateFontString(nil, "overlay", "GameFontNormal", nil, 4)
                    amountQuests:SetPoint("center", amountQuestsBackground2, "center", 0, 0)
                    amountQuests:SetDrawLayer("overlay", 6)
                    amountQuests:SetAlpha(.98)
                    WorldQuestTracker:SetFontSize(amountQuests, 11)
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
        local factionID = worldSummary.FactionIDs[buttonIndex]
        if (not factionID) then
            return
        end

        PlaySoundFile("Interface\\AddOns\\WorldQuestTracker\\media\\faction_on_click.ogg")

        --Keep the visual faction selection, then add every quest on the current
        --map that actually awards reputation with that faction. Existing tracked
        --quests remain tracked because CheckAddToTracker is called in onlyTrack mode.
        worldSummary.FactionSelected = factionID
        worldSummary.RefreshFactionButtons()
        worldSummary.UpdateFaction()
        worldSummary.TrackAllFactionQuests(factionID)
    end

    --called when pressing a button to select another faction or when the lazy update is finished
    function worldSummary.UpdateFaction()
        for _, summarySquare in pairs(WorldQuestTracker.WorldSummaryQuestsSquares) do
            if (summarySquare:IsShown()) then
                local conduitType, borderTexture, borderColor, itemLink = WorldQuestTracker.GetConduitQuestData(summarySquare.questID)
                WorldQuestTracker.UpdateBorder(summarySquare)

                if (worldSummary.DoesWidgetAwardFactionReputation(summarySquare, worldSummary.FactionSelected)) then
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
end