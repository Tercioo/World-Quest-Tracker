
local addonId, wqtInternal = ...

--world quest tracker object
local WorldQuestTracker = WorldQuestTrackerAddon
if (not WorldQuestTracker) then
	return
end

--framework
local DF = _G ["DetailsFramework"]
if (not DF) then
	print ("|cFFFFAA00World Quest Tracker: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

--localization
local L = DF.Language.GetLanguageTable(addonId)

local _
local GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID or C_TaskQuest.GetQuestsOnMap
local isWorldQuest = QuestUtils_IsQuestWorldQuest
local GetNumQuestLogRewardCurrencies = WorldQuestTrackerAddon.GetNumQuestLogRewardCurrencies
local GetQuestLogRewardInfo = GetQuestLogRewardInfo
local GetQuestLogRewardCurrencyInfo = WorldQuestTrackerAddon.GetQuestLogRewardCurrencyInfo
local GetQuestLogRewardMoney = GetQuestLogRewardMoney
local GetNumQuestLogRewards = GetNumQuestLogRewards

---return a boolean representing if the quest is a racing world quest
---@param tagID number
---@return boolean
function WorldQuestTracker.IsRacingQuest(tagID)
	if (tagID == 281) then
		return true
	end
	return false
end

local triggerScheduledWidgetUpdate = function(timerObject)
	local widget = timerObject.widget
	local questID = widget.questID

	if (not widget:IsShown()) then
		return
	end

	if (HaveQuestRewardData(questID)) then
		--is a zone widget placed in the world hub
		if (widget.IsWorldZoneQuestButton) then
			WorldQuestTracker.SetupWorldQuestButton(widget, true)

		--is a square button in the world map
		elseif (widget.IsWorldQuestButton) then
			WorldQuestTracker.UpdateWorldWidget(widget, widget.questData)

		--is a zone widget placed in the zone
		elseif (widget.IsZoneQuestButton) then
			WorldQuestTracker.SetupWorldQuestButton(widget, true)

		--is a zone widget placed in the taxi map
		elseif (widget.IsTaxiQuestButton) then
			WorldQuestTracker.SetupWorldQuestButton(widget, true)

		--is a zone widget placed in the zone summary frame
		elseif (widget.IsZoneSummaryButton) then
			WorldQuestTracker.SetupWorldQuestButton(widget, true)
		end
	else
		WorldQuestTracker.CheckQuestRewardDataForWidget(widget, false, true)
	end
end

function WorldQuestTracker.CheckQuestRewardDataForWidget(widget, noScheduleRefresh, noRequestData)
	local questID = widget.questID

	if (not questID) then
		return false
	end

	if (not HaveQuestRewardData(questID)) then
		--if this is from a re-schedule it already requested the data
		if (not noRequestData) then
			--ask que server for the reward data
			C_TaskQuest.RequestPreloadRewardData(questID)
		end

		if (not noScheduleRefresh) then
			local timer = C_Timer.NewTimer(1, triggerScheduledWidgetUpdate)
			timer.widget = widget
			return false, true
		end

		return false
	end

	return true
end

function WorldQuestTracker.HaveDataForQuest (questID)
	local haveQuestData = HaveQuestData(questID)
	local haveQuestRewardData = HaveQuestRewardData(questID)

	if (not haveQuestData) then
		if (WorldQuestTracker.__debug) then
			WorldQuestTracker:Msg("no HaveQuestData(4) for quest", questID)
		end
		return
	end

	if (not haveQuestRewardData) then
		if (WorldQuestTracker.__debug) then
			WorldQuestTracker:Msg("no HaveQuestRewardData(1) for quest", questID)
		end
		return
	end

	return haveQuestData and haveQuestRewardData
end

--return the list of quests on the tracker
function WorldQuestTracker.GetTrackedQuests()
	return WorldQuestTracker.QuestTrackList
end


--does the the zone have world quests?
function WorldQuestTracker.ZoneHaveWorldQuest (mapID)
	--print (WorldQuestTracker.MapData, WorldQuestTracker.MapData.WorldQuestZones)
	return WorldQuestTracker.MapData.WorldQuestZones [mapID or WorldQuestTracker.GetCurrentMapAreaID()]
end

--is a argus zone? - back compatibility with mods
function WorldQuestTracker.IsArgusZone (mapID)
	return WorldQuestTracker.IsNewEXPZone (mapID)
end

--check if the zone is a new zone added
function WorldQuestTracker.IsNewEXPZone (mapID)
	--battle for azeroth
	--if (WorldQuestTracker.MapData.ZoneIDs.NAZJATAR == mapID) then
	--	return true

	--elseif (WorldQuestTracker.MapData.ZoneIDs.MECHAGON == mapID) then
	--	return true
	--end

	--[=[
	--Legion
	if (WorldQuestTracker.MapData.ZoneIDs.ANTORAN == mapID) then
		return true
	elseif (WorldQuestTracker.MapData.ZoneIDs.KROKUUN == mapID) then
		return true
	elseif (WorldQuestTracker.MapData.ZoneIDs.MCCAREE == mapID) then
		return true
	end
	--]=]
end

---return if the quest is a warband quest and if the quest give reputation
---@param questID number
---@param factionID number
---@return boolean, boolean
function WorldQuestTracker.GetQuestWarbandInfo(questID, factionID)
	local bWarband = WorldQuestTracker.MapData.FactionHasWarbandReputation[factionID]
	if (bWarband) then
		if (C_QuestLog.DoesQuestAwardReputationWithFaction(questID or 0, factionID or 0)) then
			return true, true --is warband and give reputation
		end
		return true, false --is warband but don't give reputation
	end
	return false, false --not warband
end

--is the current map zone a world quest hub?
function WorldQuestTracker.IsWorldQuestHub (mapID)
	return WorldQuestTracker.MapData.QuestHubs [mapID]
end

--is the current map a quest hub? (wait why there's two same functions?)
function WorldQuestTracker.IsCurrentMapQuestHub()
	local currentMap = WorldQuestTracker.GetCurrentMapAreaID()
	return WorldQuestTracker.MapData.QuestHubs [currentMap]
end

--return if the zone is a quest hub or if a common zone
function WorldQuestTracker.GetCurrentZoneType()
	if (WorldQuestTracker.ZoneHaveWorldQuest (WorldQuestTracker.GetCurrentMapAreaID())) then
		return "zone"
	elseif (WorldQuestTracker.IsWorldQuestHub (WorldMapFrame.mapID) or WorldQuestTracker.IsCurrentMapQuestHub()) then
		return "world"
	end
end

function WorldQuestTracker.GetMapInfo (uiMapId)
	if (not uiMapId) then
		uiMapId = C_Map.GetBestMapForUnit ("player")
		if (uiMapId) then
			return C_Map.GetMapInfo (uiMapId)
		else
			--print ("C_Map.GetBestMapForUnit ('player1'): returned NIL")
		end
	else
		return C_Map.GetMapInfo (uiMapId)
	end
end

function WorldQuestTracker.GetMapName (uiMapId)
	local mapInfo = C_Map.GetMapInfo (uiMapId)
	if (mapInfo) then
		local mapName = mapInfo and mapInfo.name or "wrong map id"
		return mapName
	else
		return "wrong map id"
	end
end

--verifica se pode mostrar os widgets de broken isles
function WorldQuestTracker.CanShowWorldMapWidgets (noFade)
	if (WorldQuestTracker.IsWorldQuestHub (WorldMapFrame.mapID) or WorldQuestTracker.IsCurrentMapQuestHub()) then
		if (noFade) then
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
		else
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
		end
	else
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
	end
end

--return which are the current bounty quest id selected
function WorldQuestTracker.GetCurrentBountyQuest()
	return WorldQuestTracker.DataProvider.bountyQuestID or 0
end

--return a map table with quest ids as key and true as value
function WorldQuestTracker.GetAllWorldQuests_Ids()
	local allQuests, dataUnavaliable = {}, false
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		local taskInfo = GetQuestsForPlayerByMapID (mapId)
		if (taskInfo and #taskInfo > 0) then
			for i, info  in ipairs (taskInfo) do
				local questID = info.questID
				if (HaveQuestData (questID)) then
					local isWorldQuest = isWorldQuest(questID)
					if (isWorldQuest) then
						allQuests [questID] = true
						if (not HaveQuestRewardData (questID)) then
							C_TaskQuest.RequestPreloadRewardData (questID)
						end
					end
				else
					dataUnavaliable = true
				end
			end
		else
			dataUnavaliable = true
		end
	end

	return allQuests, dataUnavaliable
end

--pega o nome da zona
function WorldQuestTracker.GetZoneName (mapID)
	if (not mapID) then
		return ""
	end

	local mapInfo = WorldQuestTracker.GetMapInfo (mapID)

	return mapInfo and mapInfo.name or ""
end

function WorldQuestTracker.GetConduitQuestData(questID)
	local data = WorldQuestTracker.CachedConduitData[questID]
	if (data) then
		return unpack(data)
	end
end

function WorldQuestTracker.HasCachedQuestData(questID)
	if (WorldQuestTracker.CachedQuestData[questID]) then
		return true
	end
end

local cacheDebug = -1
local questIDtoDebug = -1
local bCacheEnabled = false
function WorldQuestTracker.GetOrLoadQuestData(questID, canCache, dontCatchAP) --func
	if (questIDtoDebug == questID) then
		WorldQuestTracker:Msg("=== GetOrLoadQuestData() called ===")
	end

	local data = WorldQuestTracker.CachedQuestData[questID]
	if (data) then
		if (questIDtoDebug == questID) then
			WorldQuestTracker:Msg("(debug) GetOrLoadQuestData(): quest data was cached")
		end
		if (cacheDebug == questID) then
			print("RESTORING FROM CACHE")
			print(unpack(data))
		end
		return unpack(data)
	end

	local gold, goldFormated = WorldQuestTracker.GetQuestReward_Gold(questID)
	if (questIDtoDebug == questID) then
		WorldQuestTracker:Msg("(debug) GetOrLoadQuestData(): gold:", gold, goldFormated)
	end

	local rewardName, rewardTexture, numRewardItems = WorldQuestTracker.GetQuestReward_Resource(questID)
	if (questIDtoDebug == questID) then
		WorldQuestTracker:Msg("(debug) GetOrLoadQuestData(): rewardName:", rewardName, rewardTexture, numRewardItems)
	end

	local title, factionID, tagID, tagName, worldQuestType, questQuality, isElite, tradeskillLineIndex, arg1, arg2 = WorldQuestTracker.GetQuest_Info(questID)
	if (questIDtoDebug == questID) then
		WorldQuestTracker:Msg("(debug) GetOrLoadQuestData(): info:", title, factionID, tagID, tagName, worldQuestType, questQuality, isElite, tradeskillLineIndex, arg1, arg2)
	end

	local itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount, conduitType, borderTexture, borderColor, itemLink
	if (not dontCatchAP) then
		itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount, conduitType, borderTexture, borderColor, itemLink = WorldQuestTracker.GetQuestReward_Item (questID)
	end
	if (questIDtoDebug == questID) then
		WorldQuestTracker:Msg("(debug) GetOrLoadQuestData(): item:", itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount, conduitType, borderTexture, borderColor)
	end

	local allowDisplayPastCritical = false

	if (WorldQuestTracker.CanCacheQuestData and canCache and bCacheEnabled) then
		if (cacheDebug == questID) then
			print("ADD TO CACHE")
			print(title, factionID, tagID, tagName, worldQuestType, questQuality, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount)
		end
		WorldQuestTracker.CachedQuestData[questID] = {title, factionID, tagID, tagName, worldQuestType, questQuality, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount} --31 indexes
	end

	return title, factionID, tagID, tagName, worldQuestType, questQuality, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount, conduitType, borderTexture, borderColor
end

function WorldQuestTracker.GetCurrentStandingMapAreaID()
	if (C_Map) then
		local mapId = C_Map.GetBestMapForUnit ("player")
		if (mapId) then
			return mapId
		else
			return 0
		end
	else
		return GetCurrentMapAreaID()
	end
end

--return the current map the map is showing
function WorldQuestTracker.GetCurrentMapAreaID()
	--local mapID = WorldQuestTracker.DataProvider:GetMap():GetMapID()
	local mapID = WorldMapFrame.mapID

	if (mapID) then
		return mapID
	else
		if (C_Map) then
			local mapId = C_Map.GetBestMapForUnit ("player")
			if (mapId) then
				return mapId
			else
				return 0
			end
		else
			return GetCurrentMapAreaID()
		end
	end
end

---@param mapID number
---@return boolean
function WorldQuestTracker.DoesMapHasWorldQuests(mapID)
	return WorldQuestTracker.MapData.WorldQuestZones[mapID] and true or false
end

function WorldQuestTracker.PreloadWorldQuestsForQuestHub(questHubMapId)
	if (questHubMapId) then
		--get the zones of this quest hub
		local zones = WorldQuestTracker.mapTables
		for mapID, zoneInfo in pairs(zones) do
			if (zoneInfo.show_on_map[questHubMapId]) then
				WorldQuestTracker.PreloadWorldQuestsForMap(mapID)
			end
		end
	end
end

function WorldQuestTracker.PreloadWorldQuestsForMap(mapID)
	if (WorldQuestTracker.DoesMapHasWorldQuests(mapID)) then
		local taskInfo = GetQuestsForPlayerByMapID(mapID)
		if (taskInfo and #taskInfo > 0) then
			for i, info in ipairs(taskInfo) do
				local questID = info.questID
				local bIsWorldQuest = isWorldQuest(questID)
				if (bIsWorldQuest) then
					if (not HaveQuestData(questID) or not HaveQuestRewardData(questID)) then
						C_Timer.After(RandomFloatInRange(0.1, 2), function()
							C_TaskQuest.RequestPreloadRewardData(questID)
						end)
					end
				end
			end
		end
	end
end

--not in use
function WorldQuestTracker.CanShowQuest(info)
	local canShowQuest = WorldQuestTracker.DataProvider:ShouldShowQuest(info)
	return canShowQuest
end

-- ~filter
function WorldQuestTracker.GetQuestFilterTypeAndOrder(worldQuestType, gold, rewardName, itemName, isArtifact, stackAmount, numRewardItems, rewardTexture, tagID)
	local filter, order

	--[=[
		/run for key, value in pairs (_G) do if type(key) == "string" and key:find ("LE_QUEST_TAG") then print (key, value) end end

		LE_QUEST_TAG_TYPE_PVP = 3
		LE_QUEST_TAG_TYPE_PET_BATTLE = 4
		LE_QUEST_TAG_TYPE_NORMAL = 2
		LE_QUEST_TAG_TYPE_PROFESSION = 1
		LE_QUEST_TAG_TYPE_DUNGEON = 6
		LE_QUEST_TAG_TYPE_RAID = 8
		LE_QUEST_TAG_TYPE_TAG = 0
		LE_QUEST_TAG_TYPE_BOUNTY = 5
		LE_QUEST_TAG_TYPE_INVASION = 7
		LE_QUEST_TAG_TYPE_INVASION_WRAPPER = 11
	--]=]

--debug
	if (worldQuestType == LE_QUEST_TAG_TYPE_NORMAL) then
	--	print (LE_QUEST_TAG_TYPE_NORMAL, gold, rewardName, itemName, isArtifact, stackAmount, numRewardItems, rewardTexture)
	end

	if (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
		return FILTER_TYPE_PET_BATTLES, WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_PETBATTLE]

	elseif (worldQuestType == LE_QUEST_TAG_TYPE_PVP) then
		return FILTER_TYPE_PVP, WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_PVP]


	elseif (worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION) then
		return FILTER_TYPE_PROFESSION, WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_PROFESSION]

	elseif (worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON) then
		filter = FILTER_TYPE_DUNGEON
		order = WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_DUNGEON]
	end

	if (gold and gold > 0) then
		order = WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_GOLD]
		filter = FILTER_TYPE_GOLD
	end

	--print (rewardName, rewardTexture)

	if (rewardName) then
		--print (rewardName, rewardTexture) --reputation token
		--resources
		if (WorldQuestTracker.MapData.ResourceIcons[rewardTexture]) then
			order = WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_RESOURCE]
			filter = FILTER_TYPE_GARRISON_RESOURCE

		--reputation
		elseif (WorldQuestTracker.MapData.ReputationIcons[rewardTexture]) then
			order = WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_REPUTATION]
			filter = FILTER_TYPE_REPUTATION_TOKEN

		--trade skill
		elseif (WorldQuestTracker.MapData.TradeSkillIcons[rewardTexture]) then
			order = WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_TRADE]
			filter = FILTER_TYPE_TRADESKILL
		end
	end

	if (WorldQuestTracker.IsRacingQuest(tagID)) then
		order = WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_RACING] --order = 5
		return FILTER_TYPE_RACING, order
	end

	if (isArtifact) then
		order = WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_APOWER]
		filter = FILTER_TYPE_ARTIFACT_POWER

	elseif (itemName) then
		if (stackAmount > 1) then
			order = WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_TRADE]
			filter = FILTER_TYPE_TRADESKILL
		else
			order = WorldQuestTracker.db.profile.sort_order[WQT_QUESTTYPE_EQUIPMENT]
			filter = FILTER_TYPE_EQUIPMENT
		end
	end

	--> if dungeons are disabled, override the quest type to dungeon
	if (worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON) then
		if (not WorldQuestTracker.db.profile.filters[FILTER_TYPE_DUNGEON]) then
			filter = FILTER_TYPE_DUNGEON
		end
	end

	if (not filter) then
		filter = FILTER_TYPE_GARRISON_RESOURCE
		order = 9
	end

	return filter, order
end


--create a tooltip scanner
local GameTooltipFrame = CreateFrame ("GameTooltip", "WorldQuestTrackerScanTooltip", nil, "GameTooltipTemplate")
local ItemTooltipScan = CreateFrame ("GameTooltip", "WQTItemTooltipScan", UIParent, "InternalEmbeddedItemTooltipTemplate")


	--gold amount
	function WorldQuestTracker.GetQuestReward_Gold (questID)
		local gold = GetQuestLogRewardMoney  (questID) or 0
		local formated
		if (gold > 10000000) then
			formated = gold / 10000 --remove os zeros
			formated = string.format ("%.1fK", formated / 1000)
		else
			formated = floor (gold / 10000)
		end
		return gold, formated
	end

	--resource amount
	function WorldQuestTracker.GetQuestReward_Resource(questID)
		--local a = C_QuestLog.GetQuestRewardCurrencies(questID) --returning an empty table
		--print(type(a))
		--if (next(a)) then
		--	dumpt(a)
		--end

		--local r = C_QuestInfoSystem.GetQuestRewardCurrencies(questID) --?
		--dumpt(r)

		--local p = C_QuestLog.GetQuestRewardCurrencies(questID)
		--dumpt(p)

		--C_Timer.After(3, function()
		--	local p = C_QuestLog.GetQuestRewardCurrencies(questID) --got data after waiting
		--	dumpt(p)
		--end)

		--dumpt(C_QuestLog.GetQuestRewardCurrencyInfo(questID))
		--GetNumQuestRewards
		--print(numQuestCurrencies, C_QuestLog.GetTitleForQuestID(questID))

		---@type number
		local numQuestCurrencies = GetNumQuestLogRewardCurrencies(questID)

		if (numQuestCurrencies == 2) then
			for currencyIndex = 1, numQuestCurrencies do
				--name, texture, baseRewardAmount, currencyID, bonusRewardAmount
				local name, texture, numItems, currencyId, bonusAmount = WorldQuestTracker.GetQuestLogRewardCurrencyInfo(currencyIndex, questID)
				--legion invasion quest
				if (texture and
						(
							(type (texture) == "number" and texture == 132775) or
							(type (texture) == "string" and (texture:find ("inv_datacrystal01") or texture:find ("inv_misc_summonable_boss_token")))
						)
					) then -- [[Interface\Icons\inv_datacrystal01]]

					--BFA invasion quest (this check will force it to get the second reward
				elseif (not WorldQuestTracker.MapData.IgnoredRewardTexures[texture]) then
					return name, texture, numItems, currencyId, bonusAmount
				end
			end
		else
			for currencyIndex = 1, numQuestCurrencies do
				local name, texture, numItems, currencyId, bonusAmount = WorldQuestTracker.GetQuestLogRewardCurrencyInfo(currencyIndex, questID)
				if (name) then
					return name, texture, numItems, currencyId, bonusAmount
				end
			end
		end
	end

	function WorldQuestTracker.GetQuestRewardConduit(questID, itemID)
		if (C_Soulbinds.IsItemConduitByItemInfo(itemID)) then
			local conduitType, borderColor

			for i = 1, 4 do
				local textString = _G ["WQTItemTooltipScanTooltipTextLeft" .. i]
				local text = textString and textString:GetText()
				if (text and text ~= "") then

					--shadowlands
					if (text == CONDUIT_TYPE_POTENCY) then
						conduitType = CONDUIT_TYPE_POTENCY

					elseif (text == CONDUIT_TYPE_FINESSE) then
						conduitType = CONDUIT_TYPE_FINESSE

					elseif (text == CONDUIT_TYPE_ENDURANCE) then
						conduitType = CONDUIT_TYPE_ENDURANCE
					end

					if (conduitType) then
						break
					end
				end
			end

			if (conduitType) then
				if (not borderColor) then
					borderColor = {.9, .9, .9, 1}
				end
				WorldQuestTracker.CachedConduitData[questID] = {conduitType, borderTexture, borderColor, itemLink}
			end

			return conduitType, borderColor
		end
	end

	--pega o premio item da quest
--[=[]]
	[2031] = table {
		["1"] = 'Dragonscale Expedition'
		["2"] = 4687628
		["3"] = 75
		["4"] = 2031
		["5"] = 1
	 }
	 [2109] = table {
		["1"] = 'Iskaara Tuskarr'
		["2"] = 4687629
		["3"] = 75
		["4"] = 2109
		["5"] = 1
	 }
	 [2106] = table {
		["1"] = 'Valdrakken Accord'
		["2"] = 4687630
		["3"] = 75
		["4"] = 2106
		["5"] = 1
	 }
	 --]=]

	--aaaa = {}
	function WorldQuestTracker.GetQuestReward_Item(questID)
		if (not HaveQuestData(questID)) then
			if (WorldQuestTracker.__debug) then
				WorldQuestTracker:Msg("no HaveQuestData(5) for quest", questID)
			end
			return
		end

		local numQuestCurrencies = GetNumQuestLogRewardCurrencies(questID)

		if (numQuestCurrencies == 1) then
			--is artifact power? bfa
			do
				local name, texture, numItems, currencyId, quality = GetQuestLogRewardCurrencyInfo(1, questID)
				if (texture == 1830317 or texture == 2065624) then --azerite textures
					--numItems are now given the amount of azerite (BFA 17-09-2018), no more tooltip scan required
					return name, texture, 0, 1, 1, false, 0, 8, numItems or 0, false, 1
				end
			end

			--is artifact power wow11
			do
				local name, texture, baseRewardAmount, currencyId, bonusRewardAmount = GetQuestLogRewardCurrencyInfo(1, questID)
				if (texture == 2967113) then --resonance crystals
					return name, texture, 0, 1, 1, false, 0, 8, baseRewardAmount or 0, false, 1
				end
			end
		end

		local numQuestRewards = GetNumQuestLogRewards(questID)

		if (numQuestRewards > 0) then
			local itemName, itemTexture, quantity, itemQuality, isUsable, itemID, itemLevel = GetQuestLogRewardInfo(1, questID)
			itemLevel = itemLevel or 0

			if (itemID) then
				local itemName, itemLink, itemRarity, nopItemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice, itemClassID, itemSubClassID = GetItemInfo(itemID)
				local borderTexture
				local borderColor

				if (itemName) then
					EmbeddedItemTooltip_SetItemByQuestReward(ItemTooltipScan, 1, questID) --GetQuestRewardConduit depends on this

					borderTexture = ItemTooltipScan.IconOverlay:IsShown() and ItemTooltipScan.IconOverlay:GetTexture() == 3735314 and 3735314
					if (borderTexture) then
						borderColor = {ItemTooltipScan.IconOverlay:GetVertexColor()}
					end

					local conduitType, conduitBorderColor = WorldQuestTracker.GetQuestRewardConduit(questID, itemID)
					if (conduitType) then
						borderColor = conduitBorderColor
					end

					local icon = WorldQuestTracker.MapData.EquipmentIcons[itemEquipLoc]
					if (not icon and itemClassID == 3 and itemSubClassID == 11) then
						icon = WorldQuestTracker.MapData.EquipmentIcons["Relic"]
					end

					if (icon and not WorldQuestTracker.db.profile.use_old_icons) then
						itemTexture = icon
					end

					local isArtifact, artifactPower = false, 0

					if (not isArtifact) then
						--shadowlands
						if (C_Item.IsAnimaItemByID(itemID)) then
							local animaAmount = itemQuality == 3 and 35 * quantity or itemQuality == 4 and 250 * quantity or 35
							isArtifact = 9
							artifactPower = animaAmount

							--scan for anima (shadowlands)
							for i = 1, 4 do
								local textString = _G ["WQTItemTooltipScanTooltipTextLeft" .. i]
								local text = textString and textString:GetText()
								if (text and text ~= "") then
									text = text:gsub("(|c).*(|r)", "")
									if ((WORLD_QUEST_REWARD_FILTERS_ANIMA and text:find(_G.WORLD_QUEST_REWARD_FILTERS_ANIMA)) or (WORLD_QUEST_REWARD_FILTERS_ANIMA and text:find(_G.WORLD_QUEST_REWARD_FILTERS_ANIMA:lower()) or text:find("анимы"))) then
										local animaAmount = tonumber(text:match("%d+"))
										if (animaAmount) then
											isArtifact = 9
											artifactPower = animaAmount * quantity
											break
										end
									end
								end
							end
						end
					end

					if (isArtifact) then
						return itemName, itemTexture, itemLevel, quantity, itemQuality, isUsable, itemID, 9, artifactPower, itemStackCount > 1, itemStackCount, conduitType or false, borderTexture or "", borderColor or {1, 1, 1, 1}, itemLink
					else
						--Returning an equipment
						return itemName, itemTexture, itemLevel, quantity, itemQuality, isUsable, itemID, false, 0, itemStackCount > 1, itemStackCount, conduitType or false, borderTexture or "", borderColor or {1, 1, 1, 1}, itemLink
					end
				else
					--ainda n�o possui info do item
					return
				end
			else
				--ainda n�o possui info do item
				return
			end
		end
	end
