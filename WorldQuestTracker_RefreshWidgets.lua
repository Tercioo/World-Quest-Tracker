
local addonId, wqtInternal = ...

--world quest tracker object
local WorldQuestTracker = WorldQuestTrackerAddon
if (not WorldQuestTracker) then
	return
end

--framework
local detailsFramework = _G ["DetailsFramework"]
if (not detailsFramework) then
	print("|cFFFFAA00World Quest Tracker: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

--localization
local L = detailsFramework.Language.GetLanguageTable(addonId)

local worldSquareBackdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1.8, bgFile = [[Interface\TARGETINGFRAME\UI-TargetingFrame-LevelBackground]], tile = true, tileSize = 16}
local worldFramePOIs = WorldQuestTrackerWorldMapPOI
local emptyFunction = function()end

local haveQuestData = HaveQuestData
local haveQuestRewardData = HaveQuestRewardData

-- ~update the squares on the world map, this is called when the world map is open and when the map shows a world quest hub
---@param widget table
---@param questData wqt_questdata
---@param bIsUsingTracker boolean?
---@param isZoneSummaryWidget boolean?
function WorldQuestTracker.UpdateSquareWidget(widget, questData, bIsUsingTracker, isZoneSummaryWidget)
	local questID = questData.questID
	local numObjectives = questData.numObjectives
	local mapID = questData.mapID
	local isCriteria = questData.isCriteria
	local isNew = questData.isNew
	local timeLeft = questData.timeLeft
	local artifactPowerIcon = questData.rewardTexture
	local title = questData.title
	local factionID = questData.factionID
	local tagID = questData.tagID
	local worldQuestType = questData.worldQuestType
	local rarity = questData.rarity
	local isElite = questData.isElite
	local tradeskillLineIndex = questData.tradeskillLineIndex
	local allowDisplayPastCritical = false
	local gold = questData.gold
	local goldFormated = questData.goldFormated
	local rewardName = questData.rewardName
	local rewardTexture = questData.rewardTexture
	local numRewardItems = questData.numRewardItems
	local itemName = questData.itemName
	local itemTexture = questData.itemTexture
	local itemLevel = questData.itemLevel
	local quantity = questData.quantity
	local quality = questData.quality
	local isUsable = questData.isUsable
	local itemID = questData.itemID
	local isArtifact = questData.isArtifact
	local artifactPower = questData.artifactPower
	local isStackable = questData.isStackable
	local stackAmount = questData.stackAmount
	local bWarband = questData.bWarband
	local bWarbandRep = questData.bWarbandRep

	if (bIsUsingTracker == nil) then
		bIsUsingTracker = WorldQuestTracker.db.profile.use_tracker
	end

	local bCanCache = true

	if (not haveQuestData) then
		if (WorldQuestTracker.__debug) then
			WorldQuestTracker:Msg("no HaveQuestData(6) for quest", questID)
		end
	end

	if (not haveQuestRewardData) then
		if (WorldQuestTracker.__debug) then
			WorldQuestTracker:Msg("no HaveQuestRewardData(2) for quest", questID)
		end
		C_TaskQuest.RequestPreloadRewardData(questID)
		bCanCache = false
	end

	widget.questID = questID
	widget.lastQuestID = questID
	widget.worldQuest = true
	widget.numObjectives = numObjectives
	widget.mapID = mapID
	widget.Amount = 0
	widget.FactionID = factionID
	widget.Rarity = rarity
	widget.WorldQuestType = worldQuestType
	widget.IsCriteria = isCriteria
	widget.TimeLeft = timeLeft
	widget.isArtifact = false

	local bAwardReputation = C_QuestLog.DoesQuestAwardReputationWithFaction(questID or 0, factionID or 0)
	if (not bAwardReputation) then
		widget.FactionID = nil
		factionID = nil
	end

	if (isArtifact) then
		artifactPowerIcon = WorldQuestTracker.GetArtifactPowerIcon(isArtifact, true, questID)
		widget.isArtifact = isArtifact
		widget.ArtifactPowerIcon = artifactPowerIcon
	end

	widget.amountText:SetText("")
	widget.amountBackground:Hide()
	widget.timeLeftBackground:Hide()

	widget.IconTexture = nil
	widget.IconText = nil
	widget.QuestType = nil

	if (isCriteria) then
		widget.criteriaIndicator:Show()
		widget.criteriaHighlight:Show()
		widget.criteriaIndicatorGlow:Show()
	else
		widget.criteriaIndicator:Hide()
		widget.criteriaHighlight:Hide()
		widget.criteriaIndicatorGlow:Hide()
	end

	if (bWarband and WorldQuestTracker.db.profile.show_warband_rep_warning) then
		if (not bWarbandRep) then
			widget.criteriaIndicator:Show()
			widget.criteriaIndicator:SetVertexColor(detailsFramework:ParseColors(WorldQuestTracker.db.profile.show_warband_rep_warning_color))
			widget.criteriaIndicator:SetAlpha(WorldQuestTracker.db.profile.show_warband_rep_warning_alpha)
			widget.texture:SetDesaturation(WorldQuestTracker.db.profile.show_warband_rep_warning_desaturation)
			widget.criteriaIndicatorGlow:Show()
			widget.criteriaIndicatorGlow:SetAlpha(0.7)
		else
			widget.criteriaIndicator:Hide()
			widget.criteriaIndicatorGlow:Hide()
			widget.texture:SetDesaturation(0)
		end
	end

	if (isNew) then
		widget.newIndicator:Show()
		widget.newFlash:Play()
	else
		widget.newIndicator:Hide()
	end

	if (not bIsUsingTracker) then
		if (WorldQuestTracker.IsQuestOnObjectiveTracker(questID)) then
			widget.trackingGlowBorder:Show()
		else
			widget.trackingGlowBorder:Hide()
		end
	else
		if (WorldQuestTracker.IsQuestBeingTracked(questID)) then
			widget.trackingGlowBorder:Show()
			widget.trackingGlowInside:Show()
			widget:SetAlpha(1)
		else
			widget.trackingGlowBorder:Hide()
			widget.trackingGlowInside:Hide()
			widget:SetAlpha(WorldQuestTracker.db.profile.world_summary_alpha)
		end
	end

	widget.timeBlipRed:Hide()
	widget.timeBlipOrange:Hide()
	widget.timeBlipYellow:Hide()
	widget.timeBlipGreen:Hide()

	if (not WorldQuestTracker.db.profile.show_timeleft) then
		WorldQuestTracker.SetTimeBlipColor(widget, timeLeft)
	end

	if (widget.FactionPulseAnimation and widget.FactionPulseAnimation:IsPlaying()) then
		widget.FactionPulseAnimation:Stop()
	end

	widget.amountBackground:SetWidth(32)

	if (worldQuestType == LE_QUEST_TAG_TYPE_PVP) then
		widget.questTypeBlip:Show()
		widget.questTypeBlip:SetTexture([[Interface\PVPFrame\Icon-Combat]])
		widget.questTypeBlip:SetTexCoord(0, 1, 0, 1)
		widget.questTypeBlip:SetAlpha(.98)

	elseif (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
		widget.questTypeBlip:Show()
		--widget.questTypeBlip:SetTexture([[Interface\MINIMAP\ObjectIconsAtlas]])
		widget.questTypeBlip:SetTexture(WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_PETBATTLE].icon)
		widget.questTypeBlip:SetTexCoord(unpack(WorldQuestTracker.MapData.QuestTypeIcons [WQT_QUESTTYPE_PETBATTLE].coords))
		widget.questTypeBlip:SetAlpha(.98)

	elseif (worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON) then
		widget.questTypeBlip:Show()
		widget.questTypeBlip:SetTexture([[Interface\Scenarios\ScenarioIcon-Boss]])
		widget.questTypeBlip:SetTexCoord(0, 1, 0, 1)
		widget.questTypeBlip:SetAlpha(.98)

	elseif (rarity == LE_WORLD_QUEST_QUALITY_RARE and isElite) then
		--it is always adding the star of rare quests, but some rare quests aren't elite
		--now it's using the old blue border, so the blue star can be used only for rare elite quests
		widget.questTypeBlip:Show()
		widget.questTypeBlip:SetTexture([[Interface\AddOns\WorldQuestTracker\media\icon_star]])
		widget.questTypeBlip:SetTexCoord(6/32, 26/32, 5/32, 27/32)
		widget.questTypeBlip:SetAlpha(.894)

	elseif (worldQuestType == LE_QUEST_TAG_TYPE_FACTION_ASSAULT) then --LE_QUEST_TAG_TYPE_INVASION(legion)
		if (UnitFactionGroup("player") == "Alliance") then
			widget.questTypeBlip:SetTexture([[Interface\COMMON\icon-alliance]])
			widget.questTypeBlip:SetTexCoord(20/64, 46/64, 14/64, 48/64)

		elseif (UnitFactionGroup("player") == "Horde") then
			widget.questTypeBlip:SetTexture([[Interface\COMMON\icon-horde]])
			widget.questTypeBlip:SetTexCoord(17/64, 49/64, 15/64, 47/64)
		end

		widget.questTypeBlip:Show()
		widget.questTypeBlip:SetAlpha(1)
	else
		widget.questTypeBlip:Hide()
	end

	local okay, amountGold, amountAPower, amountResources = false, 0, 0, 0

	if (gold > 0) then
		local texture, coords = WorldQuestTracker.GetGoldIcon()
		if tagID == 295 then
			texture = [[Interface\AddOns\WorldQuestTracker\media\preyicon.png]]
		end
		WorldQuestTracker.SetIconTexture(widget.texture, texture, false, false)

		widget.texture:SetTexture(texture)
		--widget.texture:SetTexture("") --debug border

		widget.amountText:SetText(goldFormated)
		widget.amountBackground:Show()

		widget.IconTexture = texture
		widget.IconText = goldFormated
		widget.QuestType = QUESTTYPE_GOLD
		widget.Amount = gold
		amountGold = gold

		if (not widget.IsZoneSummaryQuestButton) then
			detailsFramework.table.addunique(WorldQuestTracker.Cache_ShownQuestOnWorldMap[WQT_QUESTTYPE_GOLD], questID)
		end

		okay = true
	end

	if (rewardName and not okay) then
		widget.texture:SetTexture(WorldQuestTracker.MapData.ReplaceIcon[rewardTexture] or rewardTexture)

		if (numRewardItems >= 1000) then
			widget.amountText:SetText(format("%.1fK", numRewardItems/1000))
			widget.amountBackground:SetWidth(40)
		else
			widget.amountText:SetText(numRewardItems)
		end

		widget.amountBackground:Show()

		widget.IconTexture = rewardTexture
		widget.IconText = numRewardItems
		widget.Amount = numRewardItems

		if (WorldQuestTracker.MapData.ResourceIcons[rewardTexture]) then
			amountResources = numRewardItems
			widget.QuestType = QUESTTYPE_RESOURCE

			if (not widget.IsZoneSummaryQuestButton) then
				detailsFramework.table.addunique(WorldQuestTracker.Cache_ShownQuestOnWorldMap[WQT_QUESTTYPE_RESOURCE], questID)
			end
		else
			amountResources = 0
		end

		okay = true
		--print(title, rewardTexture) --show the quest name and the texture ID
	end

	if (itemName) then
		if (widget.isArtifact) then
			local artifactIcon = widget.ArtifactPowerIcon

			widget.texture:SetTexture(artifactIcon)

			if (artifactPower >= 1000) then
				if (artifactPower > 999999) then
					widget.amountText:SetText(WorldQuestTracker.ToK(artifactPower))
					local text = widget.amountText:GetText()
					text = text:gsub("%.0", "")
					widget.amountText:SetText(text)

				elseif (artifactPower > 9999) then
					widget.amountText:SetText(WorldQuestTracker.ToK(artifactPower))

				else
					widget.amountText:SetText(format("%.1fK", artifactPower/1000))
				end

				widget.amountBackground:SetWidth(36)
			else
				widget.amountText:SetText(artifactPower)
			end

			widget.amountBackground:Show()

			local artifactIcon = artifactPowerIcon
			widget.IconTexture = artifactIcon
			widget.IconText = artifactPower
			widget.QuestType = QUESTTYPE_ARTIFACTPOWER
			widget.Amount = artifactPower

			if (not widget.IsZoneSummaryQuestButton) then
				detailsFramework.table.addunique(WorldQuestTracker.Cache_ShownQuestOnWorldMap [WQT_QUESTTYPE_APOWER], questID)
			end

			amountAPower = artifactPower
		else
			if (WorldQuestTracker.IsRacingQuest(tagID)) then
				--widget.texture:SetAtlas("worldquest-icon-race")
				widget.texture:SetTexture([[Interface\AddOns\WorldQuestTracker\media\icon_racing]])
			else
				widget.texture:SetTexture(itemTexture)
			end

			local color = ""
			if (quality == 4 or quality == 3) then
				color =  WorldQuestTracker.RarityColors [quality]
			end
			widget.amountText:SetText((isStackable and quantity and quantity >= 1 and quantity or false) or(itemLevel and itemLevel > 5 and(color) .. itemLevel) or "")

			if (widget.amountText:GetText() and widget.amountText:GetText() ~= "") then
				widget.amountBackground:Show()
			else
				widget.amountBackground:Hide()
			end

			widget.IconTexture = itemTexture
			widget.IconText = widget.amountText:GetText()
			widget.QuestType = QUESTTYPE_ITEM
		end

		WorldQuestTracker.AllCharactersQuests_Add(questID, timeLeft, widget.IconTexture, widget.IconText)
		okay = true
	end

	if (okay) then
		local conduitType, borderTexture, borderColor, itemLink = WorldQuestTracker.GetConduitQuestData(questID)
		WorldQuestTracker.UpdateBorder(widget)
	else
		widget.texture:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
		widget.amountText:SetText("")
		widget.IconText = ""
	end

	return okay, amountGold, amountResources, amountAPower
end