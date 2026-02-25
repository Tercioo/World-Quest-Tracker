
local addonId, wqtInternal = ...
local detailsFramework = DetailsFramework
local _
local WorldQuestTracker = WorldQuestTrackerAddon

--localization
local L = detailsFramework.Language.GetLanguageTable(addonId)

local thisTooltip = CreateFrame("GameTooltip", "WorldQuestTrackerGameTooltip", nil, "GameTooltipTemplate")
thisTooltip.ItemTooltip = CreateFrame("GameTooltip", "WorldQuestTrackerGameTooltipItemTooltip", thisTooltip, "InternalEmbeddedItemTooltipTemplate")
thisTooltip.ItemTooltip:SetOwner(thisTooltip, "ANCHOR_NONE")

local WQT_ShoppingTooltip1 = CreateFrame("GameTooltip", "WQT_ShoppingTooltip1", UIParent, "ShoppingTooltipTemplate")
WQT_ShoppingTooltip1:Hide()
WQT_ShoppingTooltip1:SetFrameStrata("TOOLTIP")
WQT_ShoppingTooltip1:SetClampedToScreen(true)

local WQT_ShoppingTooltip2 = CreateFrame("GameTooltip", "WQT_ShoppingTooltip2", UIParent, "ShoppingTooltipTemplate")
WQT_ShoppingTooltip2:Hide()
WQT_ShoppingTooltip2:SetFrameStrata("TOOLTIP")
WQT_ShoppingTooltip2:SetClampedToScreen(true)

thisTooltip.ItemTooltip.Tooltip.shoppingTooltips = {WQT_ShoppingTooltip1, WQT_ShoppingTooltip2}
--thisTooltip.Tooltip.shoppingTooltips = { WQT_ShoppingTooltip1, WQT_ShoppingTooltip2 };

--copy of QuestUtils_AddQuestRewardsToTooltip
--with some modifications for world quests to avoid taints
local rewardFunction = function(tooltip, questID, style)
	local hasAnySingleLineRewards = false;
	local isWarModeDesired = C_PvP.IsWarModeDesired();
	local questHasWarModeBonus = C_QuestLog.QuestCanHaveWarModeBonus(questID);

	-- xp
	local totalXp, baseXp = GetQuestLogRewardXP(questID);
	if ( baseXp > 0 ) then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_EXPERIENCE_FORMAT:format(baseXp), HIGHLIGHT_FONT_COLOR);
		if (isWarModeDesired and questHasWarModeBonus) then
			tooltip:AddLine(WAR_MODE_BONUS_PERCENTAGE_XP_FORMAT:format(C_PvP.GetWarModeRewardBonus()));
		end
		hasAnySingleLineRewards = true;
	end

    --artifact power
	local artifactXP = GetQuestLogRewardArtifactXP(questID);
	if ( artifactXP > 0 ) then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_ARTIFACT_XP_FORMAT:format(artifactXP), HIGHLIGHT_FONT_COLOR);
		hasAnySingleLineRewards = true;
	end

	-- favor
	local favor = C_QuestInfoSystem.GetQuestLogRewardFavor(questID, style.clampFavorToCycleCap);
	if ( favor > 0 ) then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_HOUSING_FAVOR_FORMAT:format(favor, HOUSING_DASHBOARD_REWARD_ESTATE_XP), HIGHLIGHT_FONT_COLOR);
		hasAnySingleLineRewards = true;
	end

	-- currency
	local mainRewardIsFirstTimeReputationBonus = false;
	local secondaryRewardsContainFirstTimeRepBonus = false;
	if not style.atLeastShowAzerite then
		local numAddedQuestCurrencies, usingCurrencyContainer, primaryCurrencyRewardInfo = QuestUtils_AddQuestCurrencyRewardsToTooltip(questID, tooltip, tooltip.ItemTooltip);
		if ( numAddedQuestCurrencies > 0 ) then
			hasAnySingleLineRewards = not usingCurrencyContainer or numAddedQuestCurrencies > 1;
		end

		if primaryCurrencyRewardInfo then
			local isFirstTimeReward = primaryCurrencyRewardInfo.questRewardContextFlags and FlagsUtil.IsSet(primaryCurrencyRewardInfo.questRewardContextFlags, Enum.QuestRewardContextFlags.FirstCompletionBonus);
			mainRewardIsFirstTimeReputationBonus = isFirstTimeReward and (C_CurrencyInfo.GetFactionGrantedByCurrency(primaryCurrencyRewardInfo.currencyID) ~= nil) or false;
		elseif C_QuestLog.QuestContainsFirstTimeRepBonusForPlayer(questID) then
			secondaryRewardsContainFirstTimeRepBonus = true;
		end
	end

	-- honor
	local honorAmount = GetQuestLogRewardHonor(questID);
	if ( honorAmount > 0 ) then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT:format("Interface\\ICONS\\Achievement_LegionPVPTier4", honorAmount, HONOR), HIGHLIGHT_FONT_COLOR);
		hasAnySingleLineRewards = true;
	end

	-- money
	local money = GetQuestLogRewardMoney(questID);
	if ( money > 0 ) then
        tooltip:AddLine(MONEY .. ": " .. GetMoneyString(money), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		--SetTooltipMoney(tooltip, money, nil); --avoid money frame taint
		if (isWarModeDesired and QuestUtils_IsQuestWorldQuest(questID) and questHasWarModeBonus) then
			tooltip:AddLine(WAR_MODE_BONUS_PERCENTAGE_FORMAT:format(C_PvP.GetWarModeRewardBonus()));
		end
		hasAnySingleLineRewards = true;
	end

	-- items
	local showRetrievingData = false;
	local numQuestRewards = GetNumQuestLogRewards(questID);
	if numQuestRewards > 0 and (not style.prioritizeCurrencyOverItem or C_QuestInfoSystem.HasQuestRewardCurrencies(questID)) then
		if style.fullItemDescription then
			-- we want to do a full item description
			local itemIndex, rewardType = QuestUtils_GetBestQualityItemRewardIndex(questID);  -- Only support one item reward currently
			if not EmbeddedItemTooltip_SetItemByQuestReward(tooltip.ItemTooltip, itemIndex, questID, rewardType, style.showCollectionText) then
				showRetrievingData = true;
			end
			-- check for item compare input of flag
			if not showRetrievingData then
				if TooltipUtil.ShouldDoItemComparison(tooltip.ItemTooltip.Tooltip) then
					GameTooltip_ShowCompareItem(tooltip.ItemTooltip.Tooltip, tooltip.BackdropFrame);
				else
					for i, shoppingTooltip in ipairs(tooltip.ItemTooltip.Tooltip.shoppingTooltips) do
						shoppingTooltip:Hide();
					end
				end
			end
		else
			-- we want to do an abbreviated item description
			local name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(1, questID);
			local text;
			if numItems > 1 then
				text = string.format(BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT, texture, HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(numItems), name);
			elseif texture and name then
				text = string.format(BONUS_OBJECTIVE_REWARD_FORMAT, texture, name);
			end
			if text then
				local colorData = ColorManager.GetColorDataForItemQuality(quality);
				if colorData then
					tooltip:AddLine(text, colorData.r, colorData.g, colorData.b);
				else
					tooltip:AddLine(text);
				end
			end
		end
	end

	-- spells
	if not tooltip.ItemTooltip:IsShown() and EmbeddedItemTooltip_SetSpellByFirstQuestReward(tooltip.ItemTooltip, questID) then
		showRetrievingData = true;
	end

	-- atLeastShowAzerite: show azerite if nothing else is awarded
	-- and in the case of double azerite, only show the currency container one
	if style.atLeastShowAzerite and not hasAnySingleLineRewards and not tooltip.ItemTooltip:IsShown() then
		local numAddedQuestCurrencies, usingCurrencyContainer = QuestUtils_AddQuestCurrencyRewardsToTooltip(questID, tooltip, tooltip.ItemTooltip);
		if ( numAddedQuestCurrencies > 0 ) then
			hasAnySingleLineRewards = not usingCurrencyContainer or numAddedQuestCurrencies > 1;
			if usingCurrencyContainer and numAddedQuestCurrencies > 1 then
				EmbeddedItemTooltip_Clear(tooltip.ItemTooltip);
				EmbeddedItemTooltip_Hide(tooltip.ItemTooltip);
				tooltip:Show();
			end
		end
	end

	if style.showFirstTimeRepRewardNotice and (mainRewardIsFirstTimeReputationBonus or secondaryRewardsContainFirstTimeRepBonus) then
		local bestTooltipForLine = tooltip.ItemTooltip:IsShown() and tooltip.ItemTooltip.Tooltip or tooltip;
		GameTooltip_AddBlankLineToTooltip(bestTooltipForLine);

		local wrapText = false;
		local noticeText = mainRewardIsFirstTimeReputationBonus and QUEST_REWARDS_IS_ONE_TIME_REP_BONUS or QUEST_REWARDS_CONTAINS_ONE_TIME_REP_BONUS;
		GameTooltip_AddColoredLine(bestTooltipForLine, noticeText, QUEST_REWARD_CONTEXT_FONT_COLOR, wrapText);

		if bestTooltipForLine == tooltip.ItemTooltip.Tooltip then
			tooltip.ItemTooltip.Tooltip:Show();
		end
	end

	return hasAnySingleLineRewards, showRetrievingData;
end


local showTooltip = function(self, questInfo, style, xOffset, yOffset)
    if not detailsFramework.IsAddonApocalypseWow() then
        TaskPOI_OnEnter(self)
        return
    end

    ---@cast self wqt_zonewidget
    local questID = self.questID
    local worldQuestType = self.worldQuestType

    --local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData(questID, bCanCache)

    --local GameTooltip = thisTooltip

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

    --blizzard
	if (not HaveQuestData(questID)) then
		GameTooltip_SetTitle(GameTooltip, RETRIEVING_DATA, RED_FONT_COLOR);
		GameTooltip_SetTooltipWaitingForData(GameTooltip, true);
		GameTooltip:Show();
		return;
	end

	local widgetSetAdded = false;
	local widgetSetID = C_TaskQuest.GetQuestUIWidgetSetByType(questID, Enum.MapIconUIWidgetSetType.Tooltip);
	local isThreat = C_QuestLog.IsThreatQuest(questID);

    --quest title
	local title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID(questID);
	title = title or UNKNOWN
    local tagInfo = C_QuestLog.GetQuestTagInfo(questID);
    local quality = tagInfo and tagInfo.quality or Enum.WorldQuestQuality.Common;
    local colorData = ColorManager.GetColorDataForWorldQuestQuality(quality)
    if colorData then
        GameTooltip_SetTitle(GameTooltip, title, colorData.color);
    else
        GameTooltip_SetTitle(GameTooltip, title);
    end

    --if C_QuestLog.IsAccountQuest(questID) then
    --    GameTooltip_AddColoredLine(GameTooltip, ACCOUNT_QUEST_LABEL, ACCOUNT_WIDE_FONT_COLOR);
    --end

    --quest type
    if worldQuestType then
        QuestUtils_AddQuestTypeToTooltip(GameTooltip, questID, NORMAL_FONT_COLOR);
    end

    --faction
    local factionData = factionID and C_Reputation.GetFactionDataByID(factionID);
    if factionData then
        local questAwardsReputationWithFaction = C_QuestLog.DoesQuestAwardReputationWithFaction(questID, factionID);
        local reputationYieldsRewards = (not capped) or C_Reputation.IsFactionParagonForCurrentPlayer(factionID);
        if questAwardsReputationWithFaction and reputationYieldsRewards then
            GameTooltip:AddLine(factionData.name);
        else
            GameTooltip:AddLine(factionData.name, GRAY_FONT_COLOR:GetRGB());
        end
    end

    GameTooltip_AddQuestTimeToTooltip(GameTooltip, questID);

    --quest progress
    local numObjectives = self.numObjectives or C_QuestLog.GetNumQuestObjectives(questID);
    for objectiveIndex = 1, numObjectives do
        local objectiveText, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, objectiveIndex, false);
        local showObjective = not (finished and isThreat);
        --if showObjective then
            --if self.shouldShowObjectivesAsStatusBar then
            if objectiveType == "progressbar" then
                local percent = math.floor((numFulfilled/numRequired) * 100);
                GameTooltip_ShowProgressBar(GameTooltip, 0, numRequired, numFulfilled, PERCENTAGE_STRING:format(percent));
            end

            if objectiveText and (#objectiveText > 0) then
                local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
                GameTooltip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
            end
        --end
    end

    --blizz
    local xpAmount = GetQuestLogRewardXP(questID) --return number  > 0
    local numRewards = GetNumQuestLogRewards(questID) --return number  > 0
    local moneyAmount = GetQuestLogRewardMoney(questID) --return number  > 0 
    local artifactXP = GetQuestLogRewardArtifactXP(questID) --return number  > 0
    local honorAmount = GetQuestLogRewardHonor(questID) --return number  > 0
    local hasCurrencies = C_QuestInfoSystem.HasQuestRewardCurrencies(questID) --boolean
    local hasSpells = C_QuestInfoSystem.HasQuestRewardSpells(questID) --boolean
    local favorAmount = C_QuestInfoSystem.GetQuestLogRewardFavor(questID) --return unknown

	if (xpAmount > 0 or numRewards > 0 or moneyAmount > 0 or artifactXP > 0 or honorAmount > 0 or hasCurrencies or hasSpells or favorAmount > 0) then
		if GameTooltip.ItemTooltip then
			GameTooltip.ItemTooltip:Hide();
		end

        local style = TOOLTIP_QUEST_REWARDS_STYLE_DEFAULT
		GameTooltip_AddBlankLinesToTooltip(GameTooltip, style.prefixBlankLineCount);

		if style.headerText and style.headerColor then
			GameTooltip_AddColoredLine(GameTooltip, style.headerText, style.headerColor, style.wrapHeaderText);
		end
		GameTooltip_AddBlankLinesToTooltip(GameTooltip, style.postHeaderBlankLineCount);

		local hasAnySingleLineRewards, showRetrievingData = rewardFunction(GameTooltip, questID, style);

		if hasAnySingleLineRewards and GameTooltip.ItemTooltip and GameTooltip.ItemTooltip:IsShown() then
			GameTooltip_AddBlankLinesToTooltip(GameTooltip, 1);
			if showRetrievingData then
				GameTooltip_AddColoredLine(GameTooltip, RETRIEVING_DATA, RED_FONT_COLOR);
			end
		end

		GameTooltip_SetTooltipWaitingForData(GameTooltip, showRetrievingData);
	end


    GameTooltip:Show();
    --GameTooltip.ItemTooltip:Show()
    --WQT_ShoppingTooltip1:Show()
    --WQT_ShoppingTooltip2:Show()

    --[=[
    C_Timer.After(0.1, function()
        print("item tooltip:")
        detailsFramework:DebugVisibility(GameTooltip.ItemTooltip)
        GameTooltip.ItemTooltip:SetSize(200, 400)
        GameTooltip.ItemTooltip:SetPoint("topleft", GameTooltip, "topright", 10, 0)
        print("shopping tooltip 1:")
        detailsFramework:DebugVisibility(WQT_ShoppingTooltip1)
        WQT_ShoppingTooltip1:SetSize(200, 400)
        WQT_ShoppingTooltip1:SetPoint("topleft", GameTooltip, "topright", 10, 0)
        print("shopping tooltip 2:")
        detailsFramework:DebugVisibility(WQT_ShoppingTooltip2)
        WQT_ShoppingTooltip2:SetSize(200, 400)
        WQT_ShoppingTooltip2:SetPoint("topleft", WQT_ShoppingTooltip1, "topright", 10, 0)
    --]=]

    --GameTooltip.ItemTooltip:Show()
    --WQT_ShoppingTooltip1:Show()
    --WQT_ShoppingTooltip2:Show()
    --end)

end

WorldQuestTracker.ShowQuestTooltip = showTooltip