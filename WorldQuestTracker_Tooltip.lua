
local addonId, wqtInternal = ...
local detailsFramework = DetailsFramework
local _
local WorldQuestTracker = WorldQuestTrackerAddon

--localization
local L = detailsFramework.Language.GetLanguageTable(addonId)

-- Use GameTooltip directly so that third-party addons (AllTheThings, Pawn, etc.)
-- that hook GameTooltip receive item/quest data as normal.
local gameTooltip = GameTooltip

local isSecretValue = function(value)
	if not issecretvalue then
		return false
	end
	local okay, isSecret = pcall(issecretvalue, value)
	return okay and isSecret
end

local safeNumber = function(value, fallback)
	if isSecretValue(value) then
		return fallback
	end
	return type(value) == "number" and value or fallback
end

local safePositive = function(value)
	return safeNumber(value, 0) > 0
end

local safeBoolean = function(value)
	if isSecretValue(value) then
		return false
	end
	return value and true or false
end

local isWorldMapHooked = false
local showTooltip = function(self, questInfo, style, xOffset, yOffset)
	if not isWorldMapHooked then
		WorldMapFrame:HookScript("OnHide", function() gameTooltip:Hide() end)
		isWorldMapHooked = true
	end

	---@cast self wqt_zonewidget
	local questID = self.questID
	if (not questID) then
		return
	end
	local worldQuestType = self.worldQuestType

	gameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	gameTooltip:ClearLines()
	if (gameTooltip.ItemTooltip) then
		gameTooltip.ItemTooltip:Hide()
	end

	if (not HaveQuestData(questID)) then
		GameTooltip_SetTitle(gameTooltip, RETRIEVING_DATA, RED_FONT_COLOR)
		GameTooltip_SetTooltipWaitingForData(gameTooltip, true)
		gameTooltip:Show()
		return
	end

	local widgetSetID = C_TaskQuest.GetQuestUIWidgetSetByType(questID, Enum.MapIconUIWidgetSetType.Tooltip)
	local isThreat = C_QuestLog.IsThreatQuest(questID)

	-- quest title
	local title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID(questID)
	title = title or UNKNOWN
	local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
	local quality = tagInfo and tagInfo.quality or Enum.WorldQuestQuality.Common
	local colorData = ColorManager.GetColorDataForWorldQuestQuality(quality)
	if colorData then
		GameTooltip_SetTitle(gameTooltip, title, colorData.color)
	else
		GameTooltip_SetTitle(gameTooltip, title)
	end

	-- quest type
	if worldQuestType then
		QuestUtils_AddQuestTypeToTooltip(gameTooltip, questID, NORMAL_FONT_COLOR)
	end

	-- faction name: gray when capped and not paragon-eligible
	local factionData = factionID and C_Reputation.GetFactionDataByID(factionID)
	if factionData then
		local questAwardsRep = C_QuestLog.DoesQuestAwardReputationWithFaction(questID, factionID)
		local reputationYieldsRewards = (not capped) or C_Reputation.IsFactionParagonForCurrentPlayer(factionID)
		if questAwardsRep and reputationYieldsRewards then
			gameTooltip:AddLine(factionData.name)
		else
			gameTooltip:AddLine(factionData.name, GRAY_FONT_COLOR:GetRGB())
		end

		-- Paragon box pending: one-time reward available to collect
		if C_Reputation.GetFactionParagonInfo then
			local _, _, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID)
			if hasRewardPending then
				GameTooltip_AddColoredLine(gameTooltip, PARAGON_REPUTATION_REWARD_PENDING, YELLOW_FONT_COLOR)
			end
		end
	end

	-- Show the same availability notice as Blizzard when this quest still grants
	-- its one-time Warband reputation bonus. GetQuestWarbandInfo checks the quest's
	-- current reputation award state, so the line disappears after the bonus is used.
	local _, bWarbandRep = WorldQuestTracker.GetQuestWarbandInfo(questID, factionID)
	if bWarbandRep then
		local warbandBonusText = L["S_TOOLTIP_WARBAND_REP_BONUS"]
		if (not warbandBonusText or warbandBonusText == "S_TOOLTIP_WARBAND_REP_BONUS") then
			warbandBonusText = "Awards a one-time Warband reputation bonus"
		end

		local warbandColor = ACCOUNT_WIDE_FONT_COLOR or BLUE_FONT_COLOR or HIGHLIGHT_FONT_COLOR
		GameTooltip_AddColoredLine(gameTooltip, warbandBonusText, warbandColor, true)
	end

	GameTooltip_AddQuestTimeToTooltip(gameTooltip, questID)

	-- quest progress
	local numObjectives = self.numObjectives or C_QuestLog.GetNumQuestObjectives(questID)
	for objectiveIndex = 1, numObjectives do
		local objectiveText, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, objectiveIndex, false)
		local showObjective = not (finished and isThreat)

		if objectiveType == "progressbar" and showObjective then
			local percentText = nil
			if (type(numRequired) == "number" and numRequired > 0 and type(numFulfilled) == "number") then
				local percent = math.floor((numFulfilled / numRequired) * 100)
				percentText = PERCENTAGE_STRING:format(percent)
			end

			if (objectiveText and #objectiveText > 0 and percentText) then
				gameTooltip:AddLine(QUEST_DASH .. objectiveText .. " (" .. percentText .. ")", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
			elseif (objectiveText and #objectiveText > 0) then
				gameTooltip:AddLine(QUEST_DASH .. objectiveText, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
			elseif (percentText) then
				gameTooltip:AddLine(QUEST_DASH .. percentText, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
			end
		end

		if objectiveText and (#objectiveText > 0) and objectiveType ~= "progressbar" then
			local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR
			gameTooltip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true)
		end
	end

	-- rewards
	local xpAmount     = GetQuestLogRewardXP(questID)
	local numRewards   = GetNumQuestLogRewards(questID)
	local moneyAmount  = GetQuestLogRewardMoney(questID)
	local artifactXP   = GetQuestLogRewardArtifactXP(questID)
	local honorAmount  = GetQuestLogRewardHonor(questID)
	local hasCurrencies = C_QuestInfoSystem.HasQuestRewardCurrencies(questID)
	local hasSpells    = C_QuestInfoSystem.HasQuestRewardSpells(questID)
	local favorAmount  = C_QuestInfoSystem.GetQuestLogRewardFavor(questID)

	if (safePositive(xpAmount) or safePositive(moneyAmount) or safePositive(artifactXP) or safePositive(numRewards) or safePositive(honorAmount) or safeBoolean(hasCurrencies) or safeBoolean(hasSpells) or safePositive(favorAmount)) then
		local rewardStyle = TOOLTIP_QUEST_REWARDS_STYLE_DEFAULT
		local rewardsOkay, showRetrievingData

		if (QuestUtils_AddQuestRewardsToTooltip) then
			rewardsOkay = true
			GameTooltip_AddBlankLinesToTooltip(gameTooltip, rewardStyle.prefixBlankLineCount)
			if rewardStyle.headerText and rewardStyle.headerColor then
				GameTooltip_AddColoredLine(gameTooltip, rewardStyle.headerText, rewardStyle.headerColor, rewardStyle.wrapHeaderText)
			end
			GameTooltip_AddBlankLinesToTooltip(gameTooltip, rewardStyle.postHeaderBlankLineCount)
			local hasAnySingleLineRewards
			hasAnySingleLineRewards, showRetrievingData = QuestUtils_AddQuestRewardsToTooltip(gameTooltip, questID, rewardStyle)
		elseif (GameTooltip_AddQuestRewardsToTooltip) then
			rewardsOkay = true
			local hasAnySingleLineRewards
			hasAnySingleLineRewards, showRetrievingData = GameTooltip_AddQuestRewardsToTooltip(gameTooltip, questID, rewardStyle)
		end

		if (not rewardsOkay) then
			showRetrievingData = true
			GameTooltip_AddColoredLine(gameTooltip, RETRIEVING_DATA, RED_FONT_COLOR)
		end

		GameTooltip_SetTooltipWaitingForData(gameTooltip, showRetrievingData)
	end

	-- All content added — show once, after everything is built.
	-- ATT and Pawn fire via their GameTooltip hooks naturally from QuestUtils_AddQuestRewardsToTooltip.
	gameTooltip:Show()

	-- Fire any WQT-registered post-show hooks.
	if (WorldQuestTracker.TooltipPostHooks) then
		for _, hookFn in ipairs(WorldQuestTracker.TooltipPostHooks) do
			local ok, err = pcall(hookFn, gameTooltip, questID, self)
			if (not ok) then
				print("|cFFFF4444[WQT]|r Tooltip hook error:", err)
			end
		end
	end
end

--- Public API: register a function to run after every WQT world-quest tooltip is shown.
-- fn(tooltip, questID, widget) — tooltip is GameTooltip, questID is the quest,
-- widget is the WQT map button that was hovered.
WorldQuestTracker.TooltipPostHooks = WorldQuestTracker.TooltipPostHooks or {}

function WorldQuestTracker.RegisterTooltipHook(fn)
	if (type(fn) ~= "function") then return end
	table.insert(WorldQuestTracker.TooltipPostHooks, fn)
end

--- Exposed for backwards compat — now just GameTooltip.
WorldQuestTracker.TooltipFrame = gameTooltip

WorldQuestTracker.ShowQuestTooltip = showTooltip

WorldQuestTracker.ShowWorldQuestTooltip = function(button, ...)
	if (not button or not button.questID) then
		return
	end
	WorldQuestTracker.CurrentHoverQuest = button.questID
	return showTooltip(button, ...)
end

WorldQuestTracker.HideQuestTooltip = function(button)
	gameTooltip:Hide()
	GameCooltip:Hide()
end

WorldQuestTracker.HideWorldQuestTooltip = WorldQuestTracker.HideQuestTooltip
