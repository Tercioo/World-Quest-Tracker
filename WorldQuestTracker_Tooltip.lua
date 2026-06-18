
local addonId, wqtInternal = ...
local detailsFramework = DetailsFramework
local _
local WorldQuestTracker = WorldQuestTrackerAddon

--localization
local L = detailsFramework.Language.GetLanguageTable(addonId)

local thisTooltip = CreateFrame("GameTooltip", "WorldQuestTrackerGameTooltip", UIParent, "GameTooltipTemplate")
--replicating the keys and values from the xml
thisTooltip.supportsItemComparison = true
thisTooltip.ItemTooltip = CreateFrame("Frame", "WorldQuestTrackerGameTooltipItemTooltip", thisTooltip, "InternalEmbeddedItemTooltipTemplate")
thisTooltip.ItemTooltip:Hide()
thisTooltip.ItemTooltip:SetSize(100, 100)
thisTooltip.ItemTooltip:SetPoint("BOTTOMLEFT", thisTooltip, "BOTTOMLEFT", 10, 13)
thisTooltip.ItemTooltip.yspacing = 13
if (thisTooltip.ItemTooltip.Tooltip) then
	thisTooltip.ItemTooltip.Tooltip.supportsItemComparison = true
end

Mixin(thisTooltip, GameTooltipDataMixin)
thisTooltip:OnLoad()
thisTooltip:SetScript("OnShow", thisTooltip.OnShow)
thisTooltip:SetScript("OnUpdate", thisTooltip.OnUpdate)

local WQT_ShoppingTooltip1 = CreateFrame("GameTooltip", "WQT_ShoppingTooltip1", UIParent, "ShoppingTooltipTemplate")
WQT_ShoppingTooltip1:SetClampedToScreen(true)
WQT_ShoppingTooltip1:SetFrameStrata("TOOLTIP")
WQT_ShoppingTooltip1:Hide()

local WQT_ShoppingTooltip2 = CreateFrame("GameTooltip", "WQT_ShoppingTooltip2", UIParent, "ShoppingTooltipTemplate")
WQT_ShoppingTooltip2:SetClampedToScreen(true)
WQT_ShoppingTooltip2:SetFrameStrata("TOOLTIP")
WQT_ShoppingTooltip2:Hide()

thisTooltip.shoppingTooltips = {WQT_ShoppingTooltip1, WQT_ShoppingTooltip2}
local wirePrivateShoppingTooltips = function()
	if (thisTooltip.ItemTooltip and thisTooltip.ItemTooltip.Tooltip) then
		thisTooltip.ItemTooltip.Tooltip.supportsItemComparison = true
		thisTooltip.ItemTooltip.Tooltip.shoppingTooltips = {WQT_ShoppingTooltip1, WQT_ShoppingTooltip2}
	end
end
wirePrivateShoppingTooltips()
C_Timer.After(0, wirePrivateShoppingTooltips)
--local gc = GameCooltip

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
		WorldMapFrame:HookScript("OnHide", function() thisTooltip:Hide() end)
		isWorldMapHooked = true
	end

	---@cast self wqt_zonewidget
	local questID = self.questID
	if (not questID) then
		return
	end
	local worldQuestType = self.worldQuestType

	--local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData(questID, bCanCache)

	local gameTooltip = thisTooltip
	gameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	gameTooltip:ClearLines()
	if (gameTooltip.ItemTooltip) then
		gameTooltip.ItemTooltip:Hide()
	end

	--blizzard
	if (not HaveQuestData(questID)) then
		GameTooltip_SetTitle(gameTooltip, RETRIEVING_DATA, RED_FONT_COLOR);
		GameTooltip_SetTooltipWaitingForData(gameTooltip, true);
		gameTooltip:Show();
		return;
	end

	local widgetSetID = C_TaskQuest.GetQuestUIWidgetSetByType(questID, Enum.MapIconUIWidgetSetType.Tooltip);
	local isThreat = C_QuestLog.IsThreatQuest(questID);

    --quest title
	local title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID(questID);
	title = title or UNKNOWN
    local tagInfo = C_QuestLog.GetQuestTagInfo(questID);
    local quality = tagInfo and tagInfo.quality or Enum.WorldQuestQuality.Common;
    local colorData = ColorManager.GetColorDataForWorldQuestQuality(quality)
    if colorData then
        GameTooltip_SetTitle(gameTooltip, title, colorData.color);
    else
        GameTooltip_SetTitle(gameTooltip, title);
    end

    --if C_QuestLog.IsAccountQuest(questID) then
    --    GameTooltip_AddColoredLine(GameTooltip, ACCOUNT_QUEST_LABEL, ACCOUNT_WIDE_FONT_COLOR);
    --end

    --quest type
    if worldQuestType then
        QuestUtils_AddQuestTypeToTooltip(gameTooltip, questID, NORMAL_FONT_COLOR);
    end

    --faction
    local factionData = factionID and C_Reputation.GetFactionDataByID(factionID);
    if factionData then
        local questAwardsReputationWithFaction = C_QuestLog.DoesQuestAwardReputationWithFaction(questID, factionID);
        local reputationYieldsRewards = (not capped) or C_Reputation.IsFactionParagonForCurrentPlayer(factionID);
        if questAwardsReputationWithFaction and reputationYieldsRewards then
            gameTooltip:AddLine(factionData.name);
        else
            gameTooltip:AddLine(factionData.name, GRAY_FONT_COLOR:GetRGB());
        end
    end

    GameTooltip_AddQuestTimeToTooltip(gameTooltip, questID);

	--quest progress
	local numObjectives = self.numObjectives or C_QuestLog.GetNumQuestObjectives(questID);
	for objectiveIndex = 1, numObjectives do
		local objectiveText, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, objectiveIndex, false);
		local showObjective = not (finished and isThreat);
		--if showObjective then
			--if self.shouldShowObjectivesAsStatusBar then
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
				local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
				gameTooltip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
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

	if (safePositive(xpAmount) or safePositive(moneyAmount) or safePositive(artifactXP) or safePositive(numRewards) or safePositive(honorAmount) or safeBoolean(hasCurrencies) or safeBoolean(hasSpells) or safePositive(favorAmount)) then
		local style = TOOLTIP_QUEST_REWARDS_STYLE_DEFAULT
		local rewardsOkay, showRetrievingData

		if (QuestUtils_AddQuestRewardsToTooltip) then
			rewardsOkay = true
			GameTooltip_AddBlankLinesToTooltip(gameTooltip, style.prefixBlankLineCount);
			if style.headerText and style.headerColor then
				GameTooltip_AddColoredLine(gameTooltip, style.headerText, style.headerColor, style.wrapHeaderText);
			end
			GameTooltip_AddBlankLinesToTooltip(gameTooltip, style.postHeaderBlankLineCount);

			local hasAnySingleLineRewards
			hasAnySingleLineRewards, showRetrievingData = QuestUtils_AddQuestRewardsToTooltip(gameTooltip, questID, style)
		elseif (GameTooltip_AddQuestRewardsToTooltip) then
			rewardsOkay = true
			local hasAnySingleLineRewards
			hasAnySingleLineRewards, showRetrievingData = GameTooltip_AddQuestRewardsToTooltip(gameTooltip, questID, style)
		end

		if (not rewardsOkay) then
			showRetrievingData = true
			GameTooltip_AddColoredLine(gameTooltip, RETRIEVING_DATA, RED_FONT_COLOR);
		end

		GameTooltip_SetTooltipWaitingForData(gameTooltip, showRetrievingData);
	end


	gameTooltip:Show()
end

WorldQuestTracker.ShowQuestTooltip = showTooltip

WorldQuestTracker.ShowWorldQuestTooltip = function(button, ...)
	if (not button or not button.questID) then
		return
	end

	WorldQuestTracker.CurrentHoverQuest = button.questID
	return showTooltip(button, ...)
end

WorldQuestTracker.HideQuestTooltip = function(button)
	WQT_ShoppingTooltip1:Hide()
	WQT_ShoppingTooltip2:Hide()
	thisTooltip:Hide()

	GameCooltip:Hide()
end

WorldQuestTracker.HideWorldQuestTooltip = WorldQuestTracker.HideQuestTooltip


hooksecurefunc(_G, "EmbeddedItemTooltip_SetItemByQuestReward", function(ItemTooltip, questLogIndex, questID, rewardType, showCollectionText)
	--print("--- HOOK ----")
	--print(ItemTooltip:GetName(), ItemTooltip:GetParent():GetName(), questLogIndex, questID, rewardType, showCollectionText)

	if ItemTooltip ~= thisTooltip.ItemTooltip then
		return
	end

	ItemTooltip.questID = questID
	ItemTooltip.questLogIndex = questLogIndex
	ItemTooltip.rewardType = rewardType

	--print("IsSHown::::: ", ItemTooltip:IsShown())
end)
