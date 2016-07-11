
--details! framework
local DF = _G ["DetailsFramework"]
if (not DF) then
	print ("|cFFFFAA00Plater: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

--219978
--world of quets IsQuestFlaggedCompleted (43341) - colocar junto com o level do personagem


local _
local default_config = {
	profile = {
		quests_tracked = {},
		syntheticMapIdList = {
			[1015] = 1, --azsuna
			[1018] = 2, --valsharah
			[1024] = 3, --highmountain
			[1017] = 4, --stormheim
			[1033] = 5, --suramar
		},
		taxy_showquests = true,
		taxy_trackedonly = false,
		taxy_tracked_scale = 3,
		auto_worldmap = true,
		enable_doubletap = true,
		history = {
			reward = {
				global = {},
				character = {},
			},
			quest = {
				global = {},
				character = {},
			},
			period = {
				global = {},
				character = {},
			},
		},
	},
}

local azsuna_mapId = 1015
local highmountain_mapId = 1024
local stormheim_mapId = 1017
local suramar_mapId = 1033
local valsharah_mapId = 1018
local eoa_mapId = 1096

local MAPID_BROKENISLES = 1007
local MAPID_DALARAN = 1014
local MAPID_AZSUNA = 1015
local MAPID_VALSHARAH = 1018
local MAPID_STORMHEIM = 1017
local MAPID_SURAMAR = 1033
local MAPID_HIGHMOUNTAIN = 1024

local QUESTTYPE_GOLD = 0x1
local QUESTTYPE_RESOURCE = 0x2
local QUESTTYPE_ITEM = 0x4
local QUESTTYPE_ARTIFACTPOWER = 0x8

local BROKEN_ISLES_ZONES = {
	[azsuna_mapId] = true, --azsuna
	[valsharah_mapId] = true, --valsharah
	[highmountain_mapId] = true, --highmountain
	[stormheim_mapId] = true, --stormheim
	[suramar_mapId] = true, --suramar
}

local WorldQuestTracker = DF:CreateAddOn ("WorldQuestTrackerAddon", "WQTrackerDB", default_config)
WorldQuestTracker.QuestTrackList = {} --place holder until OnInit is triggered
WorldQuestTracker.AllTaskPOIs = {}
WorldQuestTracker.CurrentMapID = 0
WorldQuestTracker.LastWorldMapClick = 0

local GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID
local HaveQuestData = HaveQuestData
local ipairs = ipairs
local QuestMapFrame_IsQuestWorldQuest = QuestMapFrame_IsQuestWorldQuest
local GetNumQuestLogRewardCurrencies = GetNumQuestLogRewardCurrencies
local GetQuestLogRewardInfo = GetQuestLogRewardInfo
local GetQuestLogRewardCurrencyInfo = GetQuestLogRewardCurrencyInfo
local GetQuestLogRewardMoney = GetQuestLogRewardMoney
local GetQuestLogIndexByID = GetQuestLogIndexByID
local GetQuestTagInfo = GetQuestTagInfo
local GetNumQuestLogRewards = GetNumQuestLogRewards
local GetQuestInfoByQuestID = C_TaskQuest.GetQuestInfoByQuestID
local LE_WORLD_QUEST_QUALITY_COMMON = LE_WORLD_QUEST_QUALITY_COMMON
local LE_WORLD_QUEST_QUALITY_RARE = LE_WORLD_QUEST_QUALITY_RARE
local LE_WORLD_QUEST_QUALITY_EPIC = LE_WORLD_QUEST_QUALITY_EPIC
local GetQuestTimeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes
local WORLD_QUESTS_TIME_CRITICAL_MINUTES = WORLD_QUESTS_TIME_CRITICAL_MINUTES
local SecondsToTime = SecondsToTime
local GetItemInfo = GetItemInfo

local all_widgets = {}
local extra_widgets = {}
local faction_frames = {}

local azsuna_widgets = {}
local highmountain_widgets = {}
local stormheim_widgets = {}
local suramar_widgets = {}
local valsharah_widgets = {}

local WORLDMAP_SQUARE_SIZE = 24
local WORLDMAP_SQUARE_TIMEBLIP_SIZE = 12
local WORLDMAP_SQUARE_TEXT_SIZE = 9

local LOCK_MAP = true

local WorldWidgetPool = {}
local POISize = 20

local lastZoneWidgetsUpdate = 0
local lastMapTap = 0

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> initialize the addon

local reGetTrackerList = function()
	C_Timer.After (.2, WorldQuestTracker.GetTrackedQuestsOnDB)
end
function WorldQuestTracker.GetTrackedQuestsOnDB()
	local GUID = UnitGUID ("player")
	if (not GUID) then
		reGetTrackerList()
		WorldQuestTracker.QuestTrackList = {}
		return
	end
	local questList = WorldQuestTracker.db.profile.quests_tracked [GUID]
	if (not questList) then
		questList = {}
		WorldQuestTracker.db.profile.quests_tracked [GUID] = questList
	end
	WorldQuestTracker.QuestTrackList = questList
	WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker()
	WorldQuestTracker.RefreshTrackerWidgets()
end
function WorldQuestTracker.GetTrackedQuests()
	return WorldQuestTracker.QuestTrackList
end

function WorldQuestTracker:UpdateCurrentStandingZone()
	if (WorldMapFrame:IsShown()) then
		return
	end

	if (WorldQuestTracker.ScheduledMapFrameShownCheck and not WorldQuestTracker.ScheduledMapFrameShownCheck._cancelled) then
		WorldQuestTracker.ScheduledMapFrameShownCheck:Cancel()
	end
	
	local mapID = GetCurrentMapAreaID()	
	if (mapID == 1080 or mapID == 1072) then
		mapID = 1024
	end
	WorldMapFrame.currentStandingZone = mapID
	WorldQuestTracker:FullTrackerUpdate()
end
function WorldQuestTracker:WaitUntilWorldMapIsClose()
	if (WorldQuestTracker.ScheduledMapFrameShownCheck and not WorldQuestTracker.ScheduledMapFrameShownCheck._cancelled) then
		WorldQuestTracker.ScheduledMapFrameShownCheck:Cancel()
	end
	WorldQuestTracker.ScheduledMapFrameShownCheck = C_Timer.NewTicker (1, WorldQuestTracker.UpdateCurrentStandingZone)
end

function WorldQuestTracker:OnInit()
	WorldQuestTracker.InitAt = GetTime()
	WorldQuestTracker.LastMapID = GetCurrentMapAreaID()
	WorldQuestTracker.GetTrackedQuestsOnDB()
	
	WQTrackerDBChr = WQTrackerDBChr or {}
	WorldQuestTracker.dbChr = WQTrackerDBChr
	
	local canLoad = IsQuestFlaggedCompleted (43341)
	
	function WorldQuestTracker:ZONE_CHANGED_NEW_AREA()
		if (IsInInstance()) then
			WorldQuestTrackerScreenPanel:Hide()
		else
			WorldQuestTrackerScreenPanel:Show()
			WorldQuestTrackerScreenPanel:SetSize (235, 500)
			WorldQuestTracker:FullTrackerUpdate()
			
			if (WorldMapFrame:IsShown()) then
				return WorldQuestTracker:WaitUntilWorldMapIsClose()
			else
				C_Timer.After (.5, WorldQuestTracker.UpdateCurrentStandingZone)
			end
		end
	end
	
	function WorldQuestTracker:QUEST_TURNED_IN (event, questID, XP, gold)
		if (QuestMapFrame_IsQuestWorldQuest (questID)) then
			--print (event, questID, XP, gold)
			--QUEST_TURNED_IN 44300 0 772000
			
			-- QINFO: 0 nil nil Petrified Axe Haft true 370
			
			if (QuestMapFrame_IsQuestWorldQuest (questID)) then
				local title, questType, texture, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, selected, isSpellTarget, timeLeft, isCriteria, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker:GetQuestFullInfo (questID)
				--print ("QINFO:", goldFormated, rewardName, numRewardItems, itemName, isArtifact, artifactPower)
				
				local questHistory = WorldQuestTracker.db.profile.history

				local guid = UnitGUID ("player")
				local today = date ("%y%m%d") -- YYMMDD
				
				local rewardHistory = questHistory.reward
					local _global = rewardHistory.global
					local _local = rewardHistory.character [guid]
					if (not _local) then
						_local = {}
						rewardHistory.character [guid] = _local
					end
					
					if (gold and gold > 0) then
						_global ["gold"] = _global ["gold"] or 0
						_local ["gold"] = _local ["gold"] or 0
						_global ["gold"] = _global ["gold"] + gold
						_local ["gold"] = _local ["gold"] + gold
						
						--print ("Gold added:", _global ["gold"], _local ["gold"])
					end
					if (isArtifact) then
						_global ["artifact"] = _global ["artifact"] or 0
						_local ["artifact"] = _local ["artifact"] or 0
						_global ["artifact"] = _global ["artifact"] + artifactPower
						_local ["artifact"] = _local ["artifact"] + artifactPower
						
						--print ("Artifact added:", _global ["artifact"], _local ["artifact"])
					end
					if (rewardName) then --class hall resource
						_global ["resource"] = _global ["resource"] or 0
						_local ["resource"] = _local ["resource"] or 0
						_global ["resource"] = _global ["resource"] + numRewardItems
						_local ["resource"] = _local ["resource"] + numRewardItems
						
						--print ("Resource added:", _global ["resource"], _local ["resource"])
					end
					
				local questDoneHistory = questHistory.quest
					local _global = questDoneHistory.global
					local _local = questDoneHistory.character [guid]
					if (not _local) then
						_local = {}
						questDoneHistory.character [guid] = _local
					end
					_global [questID] = (_global [questID] or 0) + 1
					_local [questID] = (_local [questID] or 0) + 1
					
				local periodHistory = questHistory.period
					local _global = periodHistory.global
					local _local = periodHistory.character [guid]
					if (not _local) then
						_local = {}
						periodHistory.character [guid] = _local
					end
					
					local _globalToday = _global [today]
					local _localToday = _local [today]
					if (not _globalToday) then
						_globalToday = {}
						_global [today] = _globalToday
					end
					if (not _localToday) then
						_localToday = {}
						_local [today] = _localToday
					end

					if (gold and gold > 0) then
						_globalToday ["gold"] = _globalToday ["gold"] or 0
						_localToday ["gold"] = _localToday ["gold"] or 0
						_globalToday ["gold"] = _globalToday ["gold"] + gold
						_localToday ["gold"] = _localToday ["gold"] + gold
					end
					if (isArtifact) then
						_globalToday ["artifact"] = _globalToday ["artifact"] or 0
						_localToday ["artifact"] = _localToday ["artifact"] or 0
						_globalToday ["artifact"] = _globalToday ["artifact"] + artifactPower
						_localToday ["artifact"] = _localToday ["artifact"] + artifactPower
					end
					if (rewardName) then --class hall resource
						_globalToday ["resource"] = _globalToday ["resource"] or 0
						_localToday ["resource"] = _localToday ["resource"] or 0
						_globalToday ["resource"] = _globalToday ["resource"] + numRewardItems
						_localToday ["resource"] = _localToday ["resource"] + numRewardItems
					end
				
			end
		end
	end
	function WorldQuestTracker:QUEST_LOOT_RECEIVED (event, questID, item, amount, ...)
		--print ("LOOT", questID, item, amount, ...)
		if (QuestMapFrame_IsQuestWorldQuest (questID)) then
		--	local title, questType, texture, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, selected, isSpellTarget, timeLeft, isCriteria, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker:GetQuestFullInfo (questID)
		--	print ("QINFO:", goldFormated, rewardName, numRewardItems, itemName, isArtifact, artifactPower)
		end
	end
	
	WorldQuestTracker:RegisterEvent ("TAXIMAP_OPENED")
	WorldQuestTracker:RegisterEvent ("TAXIMAP_CLOSED")
	WorldQuestTracker:RegisterEvent ("ZONE_CHANGED_NEW_AREA")
	WorldQuestTracker:RegisterEvent ("QUEST_TURNED_IN")
	WorldQuestTracker:RegisterEvent ("QUEST_LOOT_RECEIVED")
	
	C_Timer.After (.5, WorldQuestTracker.ZONE_CHANGED_NEW_AREA)
end



--o mapa é uma zona de broken isles?
function WorldQuestTracker.IsBrokenIslesZone (mapID)
	return BROKEN_ISLES_ZONES [mapID]
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> addon wide functions

--onenter das squares no world map
local questButton_OnEnter = function (self)
	if (self.questID) then
		TaskPOI_OnEnter (self)
	end
end
local questButton_OnLeave = function	(self)
	TaskPOI_OnLeave (self)
end

--ao clicar no botão de uma quest na zona ou no world map, colocar para trackear ela
local questButton_OnClick = function (self, button)
	WorldQuestTracker.OnQuestClicked (self, button)
end

--verifica se pode mostrar os widgets de broken isles
function WorldQuestTracker.CanShowWorldMapWidgets()
	if (WorldMapFrame.mapID == 1007) then
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
	else
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
	end
end
--verifica se pode trocar o mapa e mostrar broken isles ao inves do mapa solicitado
function WorldQuestTracker.CanShowBrokenIsles()
	return WorldQuestTracker.db.profile.enable_doubletap and GetCurrentMapAreaID() ~= MAPID_BROKENISLES and (C_Garrison.IsPlayerInGarrison (LE_GARRISON_TYPE_7_0) or GetCurrentMapAreaID() == MAPID_DALARAN)
end

--todo: replace this with real animations
local animFrame, t = CreateFrame ("frame"), 0
local tickAnimation = function (self, deltaTime)
	t = t + deltaTime
	local squareAlphaAmount = Lerp (.5, .8, abs (sin (t*10)))
	local roundAlphaAmount = Lerp (.5, .8, abs (sin (t*5)))

	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		for index, button in ipairs (configTable.widgets) do
			if (button.trackingGlowBorder:IsShown()) then
				button.trackingGlowBorder:SetAlpha (squareAlphaAmount)
			end
		end
	end
	
	for index, button in ipairs (WorldWidgetPool) do
		if (button.IsTrackingGlow:IsShown()) then
			button.IsTrackingGlow:SetAlpha (roundAlphaAmount)
		end
	end	
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> quest info

local anime_square = function (self, deltaTime)
	if (self.nextTick < 0) then
		self.animeIndex = self.animeIndex + 1
		if (self.animeIndex > 24) then
			self.animeIndex = 1
		end
		self.rareBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_blue_stopmotion]])
		local line = math.ceil (self.animeIndex / 8)
		local x = ( self.animeIndex - ( (line-1) * 8 ) )  / 8
		self.rareBorder:SetTexCoord (x-0.125, x, 0.125 * (line-1), 0.125 * line)
		
		self.nextTick = .05
	else
		self.nextTick =  self.nextTick - deltaTime
	end
end

--atualiza a borda nas squares do world map e no mapa da zona
function WorldQuestTracker.UpdateBorder (self, rarity, worldQuestType)
	if (self.isWorldMapWidget) then
		self.commonBorder:Hide()
		self.rareBorder:Hide()
		self.epicBorder:Hide()
		
		if (WorldQuestTracker.IsQuestBeingTracked (self.questID)) then
			self.borderAnimation:Show()
			AutoCastShine_AutoCastStart (self.borderAnimation, 1, 1, 1)
		else
			self.borderAnimation:Hide()
		end
		
		local coords = WorldQuestTracker.GetBorderCoords (rarity)
		if (rarity == LE_WORLD_QUEST_QUALITY_COMMON) then
			if (self.isArtifact) then
				self.commonBorder:Show()
				--self.squareBorder:SetTexCoord (unpack (coords))
				--self.squareBorder:SetVertexColor (230/255, 204/255, 128/255)
				--self.squareBorder:SetVertexColor (1, 1, 1)
			else
				self.commonBorder:Show()
				--self.squareBorder:SetTexCoord (unpack (coords))
				--self.squareBorder:SetVertexColor (1, 1, 1)
			end
			
			if (worldQuestType == LE_QUEST_TAG_TYPE_PVP) then
				self.commonBorder:SetVertexColor (1, .7, .2)
				
			elseif (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
				self.commonBorder:SetVertexColor (.4, 1, .4)
				
			elseif (worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION) then
				
			end
			
		elseif (rarity == LE_WORLD_QUEST_QUALITY_RARE) then
			--self.squareBorder:SetTexCoord (unpack (coords))
			--self.squareBorder:SetVertexColor (1, 1, 1)
			self.rareBorder:Show()
			--self.nextTick = .1
			--self.animeIndex = 1
			--self:SetScript ("OnUpdate", anime_square)
			
			--AutoCastShine_AutoCastStart (self.borderAnimation, .3, .3, 1)
			
			--AnimatedShine_Start (self, 1, 1, 0);
			
		elseif (rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
			--self.squareBorder:SetTexCoord (unpack (coords))
			--self.squareBorder:SetVertexColor (1, 1, 1)
			self.epicBorder:Show()
		end

	else
		if (rarity == LE_WORLD_QUEST_QUALITY_COMMON) then
			if (self.squareBorder:IsShown()) then
				if (self.isArtifact) then
					self.squareBorder:SetVertexColor (230/255, 204/255, 128/255)
				else
					self.squareBorder:SetVertexColor (.9, .9, .9)
				end
			end
			if (self.circleBorder:IsShown()) then
				self.circleBorder:SetVertexColor (.9, .9, .9)
			end
			
			self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag_common]])
			self.bgFlag:Hide()
			--self.bgFlag:Show()
			self.bgFlagText:SetWidth (40)

		elseif (rarity == LE_WORLD_QUEST_QUALITY_RARE) then
			if (self.squareBorder:IsShown()) then
				self.squareBorder:SetVertexColor (0, 0.56863, 0.94902)
			end
			self.squareBorder:Hide()
			self.circleBorder:Show()
			if (self.circleBorder:IsShown()) then
				self.circleBorder:SetVertexColor (0, 0.56863, 0.94902)
			end
			
			self.rareSerpent:Show()
			self.rareSerpent:SetAtlas ("worldquest-questmarker-dragon")
			self.rareGlow:Show()
			self.rareGlow:SetVertexColor (0, 0.56863, 0.94902)
			self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag]])
			self.bgFlag:Show()
			
		elseif (rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
			if (self.squareBorder:IsShown()) then
				self.squareBorder:SetVertexColor (0.78431, 0.27059, 0.98039)
			end
			self.squareBorder:Hide()
			self.circleBorder:Show()
			if (self.circleBorder:IsShown()) then
				self.circleBorder:SetVertexColor (0.78431, 0.27059, 0.98039)
			end
			
			self.rareSerpent:Show()
			self.rareSerpent:SetAtlas ("worldquest-questmarker-dragon")
			self.rareGlow:Show()
			self.rareGlow:SetVertexColor (0.78431, 0.27059, 0.98039)
			self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag]])
			self.bgFlag:Show()
		end
		
		if (worldQuestType == LE_QUEST_TAG_TYPE_PVP) then
			self.circleBorder:SetVertexColor (1, .7, .2)
			
		elseif (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
			self.circleBorder:SetVertexColor (.4, 1, .4)
			
		elseif (worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION) then
			
		end
	end

end

--pega o nome da zona
function WorldQuestTracker.GetZoneName (mapID)
	return GetMapNameByID (mapID)
end

--seta a cor do blip do tempo de acordo com o tempo restante da quert
function WorldQuestTracker.SetTimeBlipColor (blip, timeLeft)
	if (timeLeft < 30) then
		blip:SetTexture ([[Interface\COMMON\Indicator-Red]])
		blip:SetVertexColor (1, 1, 1)
		blip:SetAlpha (1)
	elseif (timeLeft < 90) then
		blip:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
		blip:SetVertexColor (1, .7, 0)
		blip:SetAlpha (.9)
	elseif (timeLeft < 240) then
		blip:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
		blip:SetVertexColor (1, 1, 1)
		blip:SetAlpha (.8)
	else
		blip:SetTexture ([[Interface\COMMON\Indicator-Green]])
		blip:SetVertexColor (1, 1, 1)
		blip:SetAlpha (.6)
	end
end

--verifica se o item é um item de artefato e pega a quantidade de poder dele
local GameTooltipFrame = CreateFrame ("GameTooltip", "WorldQuestTrackerScanTooltip", nil, "GameTooltipTemplate")
local GameTooltipFrameTextLeft1 = _G ["WorldQuestTrackerScanTooltipTextLeft2"]
local GameTooltipFrameTextLeft2 = _G ["WorldQuestTrackerScanTooltipTextLeft3"]
local GameTooltipFrameTextLeft3 = _G ["WorldQuestTrackerScanTooltipTextLeft4"]



function WorldQuestTracker.RewardIsArtifactPower (itemLink)
	GameTooltipFrame:SetOwner (WorldFrame, "ANCHOR_NONE")
	GameTooltipFrame:SetHyperlink (itemLink)
	local text = GameTooltipFrameTextLeft1:GetText()
	if (text:match ("|cFFE6CC80")) then
		--local power = GameTooltipFrameTextLeft3:GetText():match ("%d.-%s") or 0 - problemas com pontuação
		local power = GameTooltipFrameTextLeft3:GetText():gsub ("%p", ""):match ("%d+")

		power = tonumber (power)
		return true, power or 0
	end
end

--pega a quantidade de gold da quest
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

--pega a quantidade de recursos para a order hall
function WorldQuestTracker.GetQuestReward_Resource (questID)
	local numQuestCurrencies = GetNumQuestLogRewardCurrencies (questID)
	for i = 1, numQuestCurrencies do
		local name, texture, numItems = GetQuestLogRewardCurrencyInfo (i, questID)
		return name, texture, numItems
	end
end

--pega o premio item da quest
function WorldQuestTracker.GetQuestReward_Item (questID)
	local numQuestRewards = GetNumQuestLogRewards (questID)
	if (numQuestRewards > 0) then
		local itemName, itemTexture, quantity, quality, isUsable, itemID = GetQuestLogRewardInfo (1, questID)
		if (itemID) then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo (itemID)
			if (itemName) then
				local isArtifact, artifactPower = WorldQuestTracker.RewardIsArtifactPower (itemLink)
				if (isArtifact) then
					return itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, true, artifactPower, itemStackCount > 1
				else
					return itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, false, 0, itemStackCount > 1
				end
			else
				--ainda não possui info do item
				return
			end
		else
			--ainda não possui info do item
			return
		end
	end
end

--formata o tempo restante que a quest tem
local D_HOURS = "%dH"
local D_DAYS = "%dD"
function WorldQuestTracker.GetQuest_TimeLeft (questID, formated)
	local timeLeftMinutes = GetQuestTimeLeftMinutes (questID)
	if (formated) then
		local timeString
		if ( timeLeftMinutes <= WORLD_QUESTS_TIME_CRITICAL_MINUTES ) then
			timeString = SecondsToTime (timeLeftMinutes * 60)
		elseif timeLeftMinutes <= 60 + WORLD_QUESTS_TIME_CRITICAL_MINUTES then
			timeString = SecondsToTime ((timeLeftMinutes - WORLD_QUESTS_TIME_CRITICAL_MINUTES) * 60)
		elseif timeLeftMinutes < 24 * 60 + WORLD_QUESTS_TIME_CRITICAL_MINUTES then
			timeString = D_HOURS:format(math.floor(timeLeftMinutes - WORLD_QUESTS_TIME_CRITICAL_MINUTES) / 60)
		else
			timeString = D_DAYS:format(math.floor(timeLeftMinutes - WORLD_QUESTS_TIME_CRITICAL_MINUTES) / 1440)
		end
		
		return timeString
	else
		return timeLeftMinutes
	end
end

--pega os dados da quest
function WorldQuestTracker.GetQuest_Info (questID)
	local title, factionID = GetQuestInfoByQuestID (questID)
	local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = GetQuestTagInfo (questID)
	return title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex
end

--pega o icone para as quest que dao goild
local goldCoords = {0, 1, 0, 1}
function WorldQuestTracker.GetGoldIcon()
	return [[Interface\GossipFrame\auctioneerGossipIcon]], goldCoords
end

--pega o icone para as quests que dao poder de artefato
function WorldQuestTracker.GetArtifactPowerIcon (artifactPower, rounded)
	if (artifactPower >= 250) then
		if (rounded) then
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_red_round]]
		else
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_red]]
		end
	elseif (artifactPower >= 120) then
		if (rounded) then
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_yellow_round]]
		else	
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_yellow]]
		end
	else
		if (rounded) then
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blue_round]]
		else	
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blue]]
		end
	end
end

--pega os coordenadas para a textura da borda
-- não é mais usado!
local rarity_border_common = {150/512, 206/512, 158/512, 214/512}
local rarity_border_rare = {10/512, 66/512, 158/512, 214/512}
local rarity_border_epic = {80/512, 136/512, 158/512, 214/512}

function WorldQuestTracker.GetBorderCoords (rarity)
	if (rarity == LE_WORLD_QUEST_QUALITY_COMMON) then
		return rarity_border_common
	elseif (rarity == LE_WORLD_QUEST_QUALITY_RARE) then
		return rarity_border_rare
	elseif (rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
		return rarity_border_epic
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> build up our standing frame

--point of interest frame
local worldFramePOIs = CreateFrame ("frame", "WorldQuestTrackerWorldMapPOI", WorldMapFrame)
worldFramePOIs:SetAllPoints()
worldFramePOIs:SetFrameLevel (301)
local fadeInAnimation = worldFramePOIs:CreateAnimationGroup()
local step1 = fadeInAnimation:CreateAnimation ("Alpha")
step1:SetOrder (1)
step1:SetFromAlpha (0)
step1:SetToAlpha (1)
step1:SetDuration (0.3)
worldFramePOIs.fadeInAnimation = fadeInAnimation

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> world map frame hooks

WorldMapFrame:HookScript ("OnEvent", function (self, event)
	if (event == "WORLD_MAP_UPDATE") then
		if (WorldQuestTracker.CurrentMapID ~= self.mapID) then
			if (WorldQuestTracker.LastWorldMapClick+0.017 > GetTime()) then
				WorldQuestTracker.CurrentMapID = self.mapID
			end
		end
		
		if (WorldQuestTracker.DoubleTapFrame) then
			if (self.mapID == MAPID_BROKENISLES) then
				WorldQuestTracker.DoubleTapFrame:Show()
			else
				WorldQuestTracker.DoubleTapFrame:Hide()
			end
		end
	end
end)

--se o mapa mudar automaticamente, voltar para o mapa atual
WorldMapFrame:HookScript ("OnUpdate", function (self, deltaTime)
	if (LOCK_MAP and GetCurrentMapContinent() == 8) then
		if (WorldQuestTracker.CanChangeMap) then
			WorldQuestTracker.CanChangeMap = nil
			WorldQuestTracker.LastMapID = GetCurrentMapAreaID()
		else
			if (WorldQuestTracker.LastMapID ~= GetCurrentMapAreaID() and WorldQuestTracker.LastMapID) then
				SetMapByID (WorldQuestTracker.LastMapID)
				WorldQuestTracker.UpdateZoneWidgets()
			end
		end
	end
end)

--quando clicar para ir para dalaran ele vai ativar o automap e não vai entrar no mapa de dalaran
--desativar o auto switch quando o click for manual
local deny_auto_switch = function()
	WorldQuestTracker.NoAutoSwitchToWorldMap = true
end
 
--apos o click, verifica se pode mostrar os widgets e permitir que o mapa seja alterado no proximo tick
local allow_map_change = function (...)
	WorldQuestTracker.CanShowWorldMapWidgets()
	WorldQuestTracker.CanChangeMap = true
	WorldQuestTracker.LastMapID = GetCurrentMapAreaID()
	WorldQuestTracker.UpdateZoneWidgets()
end

WorldMapButton:HookScript ("PreClick", deny_auto_switch)
WorldMapButton:HookScript ("PostClick", allow_map_change)

hooksecurefunc ("WorldMap_CreatePOI", function (index, isObjectIcon, atlasIcon)
	local POI = _G [ "WorldMapFramePOI"..index]
	if (POI) then
		POI:HookScript ("PreClick", deny_auto_switch)
		POI:HookScript ("PostClick", allow_map_change)
	end
end)

--troca a função de click dos botões de quest no mapa da zona
hooksecurefunc ("WorldMap_GetOrCreateTaskPOI", function (index)
	local button = _G ["WorldMapFrameTaskPOI" .. index]
	if (button:GetScript ("OnClick") ~= questButton_OnClick) then
		button:SetScript ("OnClick", questButton_OnClick)
		tinsert (WorldQuestTracker.AllTaskPOIs, button)
	end
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> zone map widgets

local clear_widget = function (self)
	self.Glow:Hide()
	self.highlight:Hide()
	self.IsTrackingGlow:Hide()
	self.SelectedGlow:Hide()
	self.CriteriaMatchGlow:Hide()
	self.SpellTargetGlow:Hide()
	self.rareSerpent:Hide()
	self.rareGlow:Hide()
	self.blackBackground:Hide()
	self.circleBorder:Hide()
	self.squareBorder:Hide()
	self.timeBlip:Hide()
	self.bgFlag:Hide()
	self.bgFlagText:Hide()
	self.flagText:Hide()
	self.criteriaIndicator:Hide()
	self.criteriaIndicatorGlow:Hide()
	self.questTypeBlip:Hide()
end

function WorldQuestTracker.CreateZoneWidget (index, name, parent)
	local button = CreateFrame ("button", name .. index, parent)
	button:SetSize (POISize, POISize)
	
	button:SetScript ("OnEnter", TaskPOI_OnEnter)
	button:SetScript ("OnLeave", TaskPOI_OnLeave)
	button:SetScript ("OnClick", questButton_OnClick)
	
	button.UpdateTooltip = TaskPOI_OnEnter
	button.worldQuest = true
	button.ClearWidget = clear_widget
	
	button.Texture = button:CreateTexture (button:GetName() .. "Texture", "BACKGROUND")
	button.Texture:SetPoint ("center", button, "center")
	button.Texture:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
	
	button.Glow = button:CreateTexture(button:GetName() .. "Glow", "BACKGROUND", -6)
	button.Glow:SetSize (50, 50)
	button.Glow:SetPoint ("center", button, "center")
	button.Glow:SetTexture ([[Interface/WorldMap/UI-QuestPoi-IconGlow]])
	button.Glow:SetBlendMode ("ADD")
	button.Glow:Hide()
	
	button.highlight = button:CreateTexture (nil, "highlight")
	button.highlight:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\highlight_circle]])
	button.highlight:SetPoint ("center")
	button.highlight:SetSize (16, 16)
	
	button.IsTrackingGlow = button:CreateTexture(button:GetName() .. "IsTrackingGlow", "BACKGROUND", -6)
	button.IsTrackingGlow:SetSize (46, 46)
	button.IsTrackingGlow:SetPoint ("center", button, "center")
	button.IsTrackingGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\glow_yellow_round]])
	button.IsTrackingGlow:SetBlendMode ("ADD")
	button.IsTrackingGlow:SetAlpha (1)
	button.IsTrackingGlow:Hide()
	button.IsTrackingGlow:SetDesaturated (nil)
	
	button.SelectedGlow = button:CreateTexture (button:GetName() .. "SelectedGlow", "OVERLAY", 2)
	button.SelectedGlow:SetBlendMode ("ADD")
	button.SelectedGlow:SetPoint ("center", button, "center")
	
	button.CriteriaMatchGlow = button:CreateTexture(button:GetName() .. "CriteriaMatchGlow", "BACKGROUND", -1)
	button.CriteriaMatchGlow:SetAlpha (.6)
	button.CriteriaMatchGlow:SetBlendMode ("ADD")
	button.CriteriaMatchGlow:SetPoint ("center", button, "center")
		local w, h = button.CriteriaMatchGlow:GetSize()
		button.CriteriaMatchGlow:SetAlpha (1)
		button.flagCriteriaMatchGlow = button:CreateTexture (nil, "background")
		button.flagCriteriaMatchGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag_criteriamatch]])
		button.flagCriteriaMatchGlow:SetPoint ("top", self, "bottom", 0, 3)
		button.flagCriteriaMatchGlow:SetSize (64, 32)
	
	button.SpellTargetGlow = button:CreateTexture(button:GetName() .. "SpellTargetGlow", "OVERLAY", 1)
	button.SpellTargetGlow:SetAtlas ("worldquest-questmarker-abilityhighlight", true)
	button.SpellTargetGlow:SetAlpha (.6)
	button.SpellTargetGlow:SetBlendMode ("ADD")
	button.SpellTargetGlow:SetPoint ("center", button, "center")

	button.rareSerpent = button:CreateTexture (button:GetName() .. "RareSerpent", "OVERLAY")
	button.rareSerpent:SetWidth (34 * 1.1)
	button.rareSerpent:SetHeight (34 * 1.1)
	button.rareSerpent:SetPoint ("CENTER", 0, -1)
	
	-- é a sombra da serpente no fundo, pode ser na cor azul ou roxa
	button.rareGlow = button:CreateTexture (nil, "background")
	button.rareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
	button.rareGlow:SetTexCoord (155/512, 194/512, 17/512, 55/512)
	button.rareGlow:SetPoint ("center", button, "center")
	button.rareGlow:SetSize (48, 48)
	button.rareGlow:SetAlpha (.85)
	
	--fundo preto
	button.blackBackground = button:CreateTexture (nil, "background")
	button.blackBackground:SetPoint ("center")
	button.blackBackground:Hide()

	--borda circular
	button.circleBorder = button:CreateTexture (nil, "OVERLAY", 1)
	button.circleBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
	button.circleBorder:SetTexCoord (80/512, 138/512, 6/512, 64/512)
	button.circleBorder:SetPoint ("topleft", button, "topleft", -1, 1)
	button.circleBorder:SetPoint ("bottomright", button, "bottomright", 1, -1)

	--borda quadrada
	button.squareBorder = button:CreateTexture (nil, "OVERLAY", 1)
	button.squareBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
	button.squareBorder:SetTexCoord (8/512, 68/512, 6/512, 66/512)
	button.squareBorder:SetPoint ("topleft", button, "topleft", -1, 1)
	button.squareBorder:SetPoint ("bottomright", button, "bottomright", 1, -1)

	--blip do tempo restante
	button.timeBlip = button:CreateTexture (nil, "OVERLAY", 2)
	button.timeBlip:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlip:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	
	--blip do indicador de tipo da quest
	button.questTypeBlip = button:CreateTexture (nil, "OVERLAY", 2)
	button.questTypeBlip:SetPoint ("topright", button, "topright", 3, 1)
	button.questTypeBlip:SetSize (10, 10)
	
	--faixa com o tempo
	button.bgFlag = button:CreateTexture (nil, "OVERLAY", 5)
	button.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag]])
	button.bgFlag:SetPoint ("top", button, "bottom", 0, 3)
	button.bgFlag:SetSize (64, 32)
	
	button.bgFlagText = button:CreateTexture (nil, "OVERLAY")
	button.bgFlagText:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradient]])
	button.bgFlagText:SetPoint ("top", button.bgFlag, "top", 0, -3)
	button.bgFlagText:SetSize (32, 10)
	button.bgFlagText:SetAlpha (.7)
	
	--string da flag
	button.flagText = button:CreateFontString (nil, "OVERLAY", "GameFontNormal")
	button.flagText:SetText ("13m")
	button.flagText:SetPoint ("top", button.bgFlag, "top", 0, -3)
	DF:SetFontSize (button.flagText, 8)
	
	local criteriaIndicator = button:CreateTexture (nil, "OVERLAY", 4)
	criteriaIndicator:SetPoint ("bottomleft", button, "bottomleft", -2, -2)
	criteriaIndicator:SetSize (23*.3, 37*.3)
	criteriaIndicator:SetAlpha (.8)
	criteriaIndicator:SetTexture ([[Interface\AdventureMap\AdventureMap]])
	criteriaIndicator:SetTexCoord (901/1024, 924/1024, 251/1024, 288/1024)
	criteriaIndicator:Hide()
	local criteriaIndicatorGlow = button:CreateTexture (nil, "OVERLAY", 3)
	criteriaIndicatorGlow:SetPoint ("center", criteriaIndicator, "center")
	criteriaIndicatorGlow:SetSize (13, 13)
	criteriaIndicatorGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\criteriaIndicatorGlow]])
	criteriaIndicatorGlow:SetTexCoord (0, 1, 0, 1)
	criteriaIndicatorGlow:Hide()
	
	button.blackBackground:SetDrawLayer ("BACKGROUND", -7)
	button.IsTrackingGlow:SetDrawLayer ("BACKGROUND", -6)
	button.Glow:SetDrawLayer ("BACKGROUND", -6)
	button.Texture:SetDrawLayer ("BACKGROUND", -5)

	button.circleBorder:SetDrawLayer ("overlay", 1)
	button.squareBorder:SetDrawLayer ("overlay", 1)
	button.rareSerpent:SetDrawLayer ("overlay", 3)
	button.bgFlag:SetDrawLayer ("overlay", 4)
	button.bgFlagText:SetDrawLayer ("overlay", 5)
	button.flagText:SetDrawLayer ("overlay", 6)
	criteriaIndicator:SetDrawLayer ("overlay", 6)
	criteriaIndicatorGlow:SetDrawLayer ("overlay", 7)
	button.timeBlip:SetDrawLayer ("overlay", 7)
	button.questTypeBlip:SetDrawLayer ("overlay", 7)

	button.criteriaIndicator = criteriaIndicator
	button.criteriaIndicatorGlow = criteriaIndicatorGlow
	
	button.bgFlag:Hide()
	
	return button
end

--cria os widgets no mapa da zona
function WorldQuestTracker.GetOrCreateZoneWidget (info, index)
	local taskPOI = WorldWidgetPool [index]
	
	if (not taskPOI) then
		taskPOI = WorldQuestTracker.CreateZoneWidget (index, "WorldQuestTrackerZonePOIWidget", WorldMapPOIFrame)
		taskPOI.IsZoneQuestButton = true
		WorldWidgetPool [index] = taskPOI
	end

	return taskPOI
end

--esconde todos os widgets de zona
function WorldQuestTracker.HideZoneWidgets()
	for i = 1, #WorldWidgetPool do
		WorldWidgetPool [i]:Hide()
	end
end

--atualiza as quest do mapa da zona
function WorldQuestTracker.UpdateZoneWidgets()
	
	local mapID = GetCurrentMapAreaID()
	
	if (mapID == MAPID_BROKENISLES or mapID ~= WorldQuestTracker.LastMapID) then
		return WorldQuestTracker.HideZoneWidgets()
	elseif (not WorldQuestTracker.IsBrokenIslesZone (mapID)) then
		return WorldQuestTracker.HideZoneWidgets()
	end
	
	lastZoneWidgetsUpdate = GetTime()
	
	local taskInfo = GetQuestsForPlayerByMapID (mapID)
	local index = 1
	
	if (taskInfo and #taskInfo > 0) then
		for i, info  in ipairs (taskInfo) do
			local questID = info.questId
			if (HaveQuestData (questID)) then
				local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
				if (isWorldQuest) then
					local isSuppressed = WorldMap_IsWorldQuestSuppressed (questID)
					local passFilters = WorldMap_DoesWorldQuestInfoPassFilters (info, true, true)
					local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
					
					if (not isSuppressed and passFilters and timeLeft > 3) then
						C_TaskQuest.RequestPreloadRewardData (questID)
						
						local widget = WorldQuestTracker.GetOrCreateZoneWidget (info, index)
						
						local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = GetQuestTagInfo (questID)
						local selected = questID == GetSuperTrackedQuestID()
						local isCriteria = WorldMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty (questID)
						local isSpellTarget = SpellCanTargetQuest() and IsQuestIDValidSpellTarget (questID)
						
						widget.mapID = mapID
						widget.questID = questID
						widget.numObjectives = info.numObjectives

						local inProgress
						
						WorldQuestTracker.SetupWorldQuestButton (widget, worldQuestType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget)
						WorldMapPOIFrame_AnchorPOI (widget, info.x, info.y, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.WORLD_QUEST)

						widget:Show()
						
						for _, button in ipairs (WorldQuestTracker.AllTaskPOIs) do
							if (button.questID == questID) then
								button:Hide()
							end
						end
						
						index = index + 1
					end
				end
			else
				WorldQuestTracker.ScheduleZoneMapUpdate()
			end
		end
	else
		WorldQuestTracker.ScheduleZoneMapUpdate (3)
	end
	
	for i = index, #WorldWidgetPool do
		WorldWidgetPool [i]:Hide()
	end
	
end

--atualiza o widget da quest no mapa da zona
function WorldQuestTracker.SetupWorldQuestButton (self, worldQuestType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget)

	local questID = self.questID
	if (not questID) then
		return
	end
	
	self.isArtifact = nil
	self.circleBorder:Hide()
	self.squareBorder:Hide()
	self.flagText:SetText ("")
	self.Glow:Hide()
	self.SelectedGlow:Hide()
	self.CriteriaMatchGlow:Hide()
	self.SpellTargetGlow:Hide()
	self.IsTrackingGlow:Hide()
	self.rareSerpent:Hide()
	self.rareGlow:Hide()
	self.blackBackground:Hide()
	self.criteriaIndicator:Hide()
	self.criteriaIndicatorGlow:Hide()	
	self.questTypeBlip:Hide()
	
	self.isSelected = selected
	self.isCriteria = isCriteria
	self.isSpellTarget = isSpellTarget
	
	self.flagText:Show()
	self.timeBlip:Show()
	self.bgFlagText:Show()

	self.Texture:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])

	if (HaveQuestData (questID)) then
		local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
		
		if (self.isCriteria) then
			self.flagCriteriaMatchGlow:Show()
			self.criteriaIndicator:Show()
			self.criteriaIndicatorGlow:Show()
		else
			self.flagCriteriaMatchGlow:Hide()
			self.criteriaIndicator:Hide()
			self.criteriaIndicatorGlow:Hide()
		end
		
		if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
			self.IsTrackingGlow:Show()
		end
		
		if (worldQuestType == LE_QUEST_TAG_TYPE_PVP) then
			self.questTypeBlip:Show()
			self.questTypeBlip:SetTexture ([[Interface\PVPFrame\Icon-Combat]])
			self.questTypeBlip:SetTexCoord (0, 1, 0, 1)
			self.questTypeBlip:SetAlpha (1)
			--self.questTypeBlip:SetTexture ([[Interface\PVPFrame\Icons\prestige-icon-2]])
			--self.questTypeBlip:SetTexture ([[Interface\PvPRankBadges\PvPRank01]])
		elseif (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
			self.questTypeBlip:Show()
			self.questTypeBlip:SetTexture ([[Interface\MINIMAP\ObjectIconsAtlas]])
			self.questTypeBlip:SetTexCoord (172/512, 201/512, 273/512, 301/512)
			self.questTypeBlip:SetAlpha (1)
			
		elseif (worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION) then
		
			
		elseif (worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON) then
			
		else
			self.questTypeBlip:Hide()
		end
		
		-- tempo restante
		local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
		if (timeLeft and timeLeft > 0) then
			WorldQuestTracker.SetTimeBlipColor (self.timeBlip, timeLeft)
			local okay = false
			
			-- gold
			local goldReward, goldFormated = WorldQuestTracker.GetQuestReward_Gold (questID)
			if (goldReward > 0) then
				local texture = WorldQuestTracker.GetGoldIcon()
				
				self.Texture:SetTexture (texture)
				--self.Texture:SetTexCoord (0, 1, 0, 1)
				self.Texture:SetSize (16, 16)
				self.IconTexture = texture
				self.IconText = goldFormated
				self.flagText:SetText (goldFormated)
				self.circleBorder:Show()
				self.QuestType = QUESTTYPE_GOLD
				
				WorldQuestTracker.UpdateBorder (self, rarity, worldQuestType)
				okay = true
			end
			
			-- poder de artefato
			local artifactXP = GetQuestLogRewardArtifactXP(questID)
			if ( artifactXP > 0 ) then
				--seta icone de poder de artefato
				--return
			end
			
			-- class hall resource
			local name, texture, numRewardItems = WorldQuestTracker.GetQuestReward_Resource (questID)
			if (name) then
				if (texture) then
					self.Texture:SetTexture (texture)
					--self.Texture:SetTexCoord (0, 1, 0, 1)
					--self.squareBorder:Show()
					self.circleBorder:Show()
					self.Texture:SetSize (16, 16)
					self.IconTexture = texture
					self.IconText = numRewardItems
					self.QuestType = QUESTTYPE_RESOURCE
					self.flagText:SetText (numRewardItems)
					
					WorldQuestTracker.UpdateBorder (self, rarity, worldQuestType)
					
					if (self:GetHighlightTexture()) then
						self:GetHighlightTexture():SetTexture ([[Interface\Store\store-item-highlight]])
						self:GetHighlightTexture():SetTexCoord (0, 1, 0, 1)
					end
					okay = true
				end
			end

			-- items
			local itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker.GetQuestReward_Item (questID)
			if (itemName) then
				if (isArtifact) then
					local texture = WorldQuestTracker.GetArtifactPowerIcon (artifactPower, true) --
					self.Texture:SetSize (16, 16)
					self.Texture:SetMask (nil)
					self.Texture:SetTexture (texture)
					
					self.flagText:SetText (artifactPower)
					self.isArtifact = true
					self.IconTexture = texture
					self.IconText = artifactPower
					self.QuestType = QUESTTYPE_ARTIFACTPOWER
				else
					self.Texture:SetSize (16, 16)
					self.Texture:SetTexture (itemTexture)
					--self.Texture:SetTexCoord (0, 1, 0, 1)
					if (itemLevel > 600 and itemLevel < 780) then
						itemLevel = 810
					end
					self.flagText:SetText ((isStackable and quantity and quantity >= 1 and quantity or false) or (itemLevel and itemLevel > 5 and itemLevel .. "+") or "")
					
					self.IconTexture = itemTexture
					self.IconText = self.flagText:GetText()
					self.QuestType = QUESTTYPE_ITEM
				end

				if (self:GetHighlightTexture()) then
					self:GetHighlightTexture():SetTexture ([[Interface\Store\store-item-highlight]])
					self:GetHighlightTexture():SetTexCoord (0, 1, 0, 1)
				end

				--self.squareBorder:Show()
				self.circleBorder:Show()
				
				WorldQuestTracker.UpdateBorder (self, rarity, worldQuestType)
				okay = true
			end
			
			if (not okay) then
				WorldQuestTracker.ScheduleZoneMapUpdate()
			end
		end
		
	else
		WorldQuestTracker.ScheduleZoneMapUpdate()
	end
end

--agenda uma atualização se algum dado de alguma quest não estiver disponível ainda
local do_zonemap_update = function()
	WorldQuestTracker.UpdateZoneWidgets()
end
function WorldQuestTracker.ScheduleZoneMapUpdate (seconds)
	if (WorldQuestTracker.ScheduledZoneUpdate and not WorldQuestTracker.ScheduledZoneUpdate._cancelled) then
		WorldQuestTracker.ScheduledZoneUpdate:Cancel()
	end
	WorldQuestTracker.ScheduledZoneUpdate = C_Timer.NewTimer (seconds or 1, do_zonemap_update)
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> map automatization

--muda o mapa para o world map de broken isles
hooksecurefunc ("WorldMap_UpdateQuestBonusObjectives", function (self, event)
	if (WorldMapFrame:IsShown() and not WorldQuestTracker.NoAutoSwitchToWorldMap) then
		if (WorldQuestTracker.CanShowBrokenIsles()) then
			SetMapByID (MAPID_BROKENISLES)
			WorldQuestTracker.CanChangeMap = true
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
		end
	end
	
	--depois de ter executa o update, vamos hidar todos os widgets default e criar os nossos
	if (GetCurrentMapAreaID() ~= MAPID_BROKENISLES) then
		--roda nosso custom update e cria nossos proprios widgets
		WorldQuestTracker.UpdateZoneWidgets()
	end
end)

--update tick
--desativa toda a atualização das quests no codigo da interface
--esta causando problemas com protected, mesmo colocando pra ser uma função aleatoria
--_G ["WorldMap_UpdateQuestBonusObjectives"] = math.random
function oie ()
	if (lastZoneWidgetsUpdate + 20 < GetTime()) then
		WorldQuestTracker.UpdateZoneWidgets()
	end
end

--ao abrir ou fechar o mapa
hooksecurefunc ("ToggleWorldMap", function (self)
	
	WorldMapFrame.currentStandingZone = GetCurrentMapAreaID()
	
	if (WorldMapFrame:IsShown()) then
		animFrame:SetScript ("OnUpdate", tickAnimation)
	else
		animFrame:SetScript ("OnUpdate", nil)
	end
	
	--verifica duplo click
	if (lastMapTap+0.3 > GetTime()) then
		
		--SetMapToCurrentZone()
		SetMapByID (GetCurrentMapAreaID())

		if (not WorldMapFrame:IsShown()) then
			WorldQuestTracker.NoAutoSwitchToWorldMap = true
			WorldMapFrame.mapID = GetCurrentMapAreaID()
			WorldQuestTracker.LastMapID = GetCurrentMapAreaID()
			WorldQuestTracker.CanChangeMap = true
			ToggleWorldMap()
			WorldQuestTracker.CanShowWorldMapWidgets()
		else
			if (WorldQuestTracker.LastMapID ~= GetCurrentMapAreaID()) then
				WorldQuestTracker.NoAutoSwitchToWorldMap = true
				WorldMapFrame.mapID = GetCurrentMapAreaID()
				WorldQuestTracker.LastMapID = GetCurrentMapAreaID()
				WorldQuestTracker.CanChangeMap = true
				ToggleWorldMap()
				WorldQuestTracker.CanShowWorldMapWidgets()
			end
		end
		return
	end
	lastMapTap = GetTime()
	
	WorldQuestTracker.LastMapID = WorldMapFrame.mapID
	
	if (WorldMapFrame:IsShown()) then
		--é a primeira vez que é mostrado?
		if (not WorldMapFrame.firstRun) then
			local currentMapId = WorldMapFrame.mapID
			SetMapByID (1015)
			SetMapByID (1018)
			SetMapByID (1024)
			SetMapByID (1017)
			SetMapByID (1033)
			SetMapByID (1096)
			SetMapByID (currentMapId)
			WorldMapFrame.firstRun = true
			
			--avisar sobre duplo tap
			WorldQuestTracker.DoubleTapFrame = CreateFrame ("frame", "WorldQuestTrackerDoubleTapFrame", worldFramePOIs)
			WorldQuestTracker.DoubleTapFrame:SetSize (1, 1)
			WorldQuestTracker.DoubleTapFrame:SetPoint ("bottomleft", worldFramePOIs, "bottomleft", 3, 3)
			local doubleTapBackground = WorldQuestTracker.DoubleTapFrame:CreateTexture (nil, "overlay")
			doubleTapBackground:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-HorizontalShadow]])
			doubleTapBackground:SetPoint ("bottomleft", WorldQuestTracker.DoubleTapFrame, "bottomleft", 0, 0)
			doubleTapBackground:SetSize (430, 16)
			
			local checkboxDoubleTap_func = function (self, actorTypeIndex, value) 
				WorldQuestTracker.db.profile.enable_doubletap = value
			end
			local checkboxDoubleTap = DF:CreateSwitch (WorldQuestTracker.DoubleTapFrame, checkboxDoubleTap_func, WorldQuestTracker.db.profile.enable_doubletap, nil, nil, nil, nil, "checkboxDoubleTap1")
			checkboxDoubleTap:SetTemplate (DF:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"))
			checkboxDoubleTap:SetAsCheckBox()
			checkboxDoubleTap:SetSize (16, 16)
			checkboxDoubleTap.tooltip = "When in Dalaran or Class Hall, pressing 'M' goes directly to Broken Isles map.\n\nDouble tap 'M' goes to the map you are standing in."
			checkboxDoubleTap:SetPoint ("bottomleft", WorldQuestTracker.DoubleTapFrame, "bottomleft", 0, 0)
			
			--checkboxDoubleTap:SetValue (WorldQuestTracker.db.profile.enable_doubletap)
			--C_Timer.NewTicker (1, function() print (checkboxDoubleTap:GetBackdropColor()) end)
			--checkboxDoubleTap.widget:SetBackdropColor (1, 0, 0, 0)

			local doubleTapText = DF:CreateLabel (checkboxDoubleTap, "Auto World Map", 12, "orange", nil, "checkboxDoubleTapLabel", nil, "overlay")
			doubleTapText:SetPoint ("left", checkboxDoubleTap, "right", 2, 0)
			
			--animação
			worldFramePOIs:SetScript ("OnShow", function()
				worldFramePOIs.fadeInAnimation:Play()
			end)
		end
	
		--esta dentro de dalaran?
		if (WorldQuestTracker.CanShowBrokenIsles()) then
			SetMapByID (MAPID_BROKENISLES)
			WorldQuestTracker.CanChangeMap = true
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
			
		elseif (WorldMapFrame.mapID == MAPID_BROKENISLES) then
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
			
		else
			WorldQuestTracker.HideWorldQuestsOnWorldMap()
		end

		--WorldQuestTracker.db.profile.GotTutorial = nil
		if (not WorldQuestTracker.db.profile.GotTutorial) then
			local tutorialFrame = CreateFrame ("button", "WorldQuestTrackerTutorial", WorldMapFrame)
			tutorialFrame:SetSize (160, 280)
			tutorialFrame:SetPoint ("left", WorldMapFrame, "left")
			tutorialFrame:SetPoint ("right", WorldMapFrame, "right")
			tutorialFrame:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
			tutorialFrame:SetBackdropColor (0, 0, 0, 1)
			tutorialFrame:SetBackdropBorderColor (0, 0, 0, 1)
			tutorialFrame:SetFrameStrata ("fullscreen")
			
			tutorialFrame:SetScript ("OnClick", function()
				WorldQuestTracker.db.profile.GotTutorial = true
				tutorialFrame:Hide()
			end)
			
			local upLine = tutorialFrame:CreateTexture (nil, "overlay")
			local downLine = tutorialFrame:CreateTexture (nil, "overlay")
			upLine:SetColorTexture (1, 1, 1)
			upLine:SetHeight (1)
			upLine:SetPoint ("topleft", tutorialFrame, "topleft")
			upLine:SetPoint ("topright", tutorialFrame, "topright")
			downLine:SetColorTexture (1, 1, 1)
			downLine:SetHeight (1)
			downLine:SetPoint ("bottomleft", tutorialFrame, "bottomleft")
			downLine:SetPoint ("bottomright", tutorialFrame, "bottomright")
			
			local extraBg = tutorialFrame:CreateTexture (nil, "background")
			extraBg:SetAllPoints()
			extraBg:SetColorTexture (0, 0, 0, 0.3)
			local extraBg2 = tutorialFrame:CreateTexture (nil, "background")
			extraBg2:SetPoint ("topleft", tutorialFrame, "bottomleft")
			extraBg2:SetPoint ("topright", tutorialFrame, "bottomright")
			extraBg2:SetHeight (36)
			extraBg2:SetColorTexture (0, 0, 0, 1)
			local downLine2 = tutorialFrame:CreateTexture (nil, "overlay")
			downLine2:SetColorTexture (1, 1, 1)
			downLine2:SetHeight (1)
			downLine2:SetPoint ("bottomleft", extraBg2, "bottomleft")
			downLine2:SetPoint ("bottomright", extraBg2, "bottomright")
			local doubleTap = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			doubleTap:SetPoint ("left", extraBg2, "left", 246, 2)
			DF:SetFontSize (doubleTap, 12)
			doubleTap:SetText ("On Dalaran and Order Hall, Broken Isles map is shown when pressing 'M'\nDouble tap 'M' to show the regular zone map instead")
			doubleTap:SetJustifyH ("left")
			doubleTap:SetTextColor (1, 1, 1)
			local doubleTabTexture = tutorialFrame:CreateTexture (nil, "overlay")
			doubleTabTexture:SetTexture ([[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]])
			doubleTabTexture:SetTexCoord (0, 1, 0, .9)
			doubleTabTexture:SetPoint ("right", doubleTap, "left", -4, 0)
			doubleTabTexture:SetSize (32, 32)
			
			local texture = tutorialFrame:CreateTexture (nil, "border")
			texture:SetSize (120, 120)
			texture:SetPoint ("left", tutorialFrame, "left", 100, 50)
			texture:SetTexture ([[Interface\ICONS\INV_Chest_Mail_RaidHunter_I_01]])
			
			local square = tutorialFrame:CreateTexture (nil, "artwork")
			square:SetPoint ("topleft", texture, "topleft", -8, 8)
			square:SetPoint ("bottomright", texture, "bottomright", 8, -8)
			square:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_white]])
			
			local timeBlip = tutorialFrame:CreateTexture (nil, "overlay", 2)
			timeBlip:SetPoint ("bottomright", texture, "bottomright", 15, -12)
			timeBlip:SetSize (32, 32)
			timeBlip:SetTexture ([[Interface\COMMON\Indicator-Green]])
			timeBlip:SetVertexColor (1, 1, 1)
			timeBlip:SetAlpha (1)
			
			local flag = tutorialFrame:CreateTexture (nil, "overlay")
			flag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag]])
			flag:SetPoint ("top", texture, "bottom", 0, 5)
			flag:SetSize (64*2, 32*2)
			
			local amountText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			amountText:SetPoint ("center", flag, "center", 0, 19)
			DF:SetFontSize (amountText, 20)
			amountText:SetText ("100")
			
			local amountBackground = tutorialFrame:CreateTexture (nil, "overlay")
			amountBackground:SetPoint ("center", amountText, "center", 0, 0)
			amountBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
			amountBackground:SetTexCoord (12/512, 74/512, 251/512, 281/512)
			amountBackground:SetSize (32*2, 10*2)
			amountBackground:SetAlpha (.7)

			local criteriaIndicator = tutorialFrame:CreateTexture (nil, "OVERLAY", 2)
			criteriaIndicator:SetPoint ("bottomleft", texture, "bottomleft", 0, -6)
			criteriaIndicator:SetSize (23*.8, 37*.8)
			criteriaIndicator:SetAlpha (.8)
			criteriaIndicator:SetTexture ([[Interface\AdventureMap\AdventureMap]])
			criteriaIndicator:SetTexCoord (901/1024, 924/1024, 251/1024, 288/1024)
			local criteriaIndicatorGlow = tutorialFrame:CreateTexture (nil, "OVERLAY", 1)
			criteriaIndicatorGlow:SetPoint ("center", criteriaIndicator, "center")
			criteriaIndicatorGlow:SetSize (32, 32)
			criteriaIndicatorGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\criteriaIndicatorGlow]])
			criteriaIndicatorGlow:SetTexCoord (0, 1, 0, 1)
			
			flag:SetDrawLayer ("overlay", 1)
			amountBackground:SetDrawLayer ("overlay", 2)
			amountText:SetDrawLayer ("overlay", 3)
			
			--indicadores de raridade rarity
			local rarity1 = tutorialFrame:CreateTexture (nil, "overlay")
			rarity1:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_white]])
			local rarity2 = tutorialFrame:CreateTexture (nil, "overlay")
			rarity2:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_blue]])
			local rarity3 = tutorialFrame:CreateTexture (nil, "overlay")
			rarity3:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_pink]])
			rarity1:SetPoint ("topright", texture, "topright", 50, 0)
			rarity2:SetPoint ("left", rarity1, "right", 2, 0)
			rarity3:SetPoint ("left", rarity2, "right", 2, 0)
			rarity1:SetSize (24, 24); rarity2:SetSize (rarity1:GetSize()); rarity3:SetSize (rarity1:GetSize());
			local rarityText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			rarityText:SetPoint ("left", rarity3, "right", 4, 0)
			DF:SetFontSize (rarityText, 12)
			rarityText:SetText ("indicates the rarity (common, rare, epic)")
			
			--indicadores de tempo
			local time1 = tutorialFrame:CreateTexture (nil, "overlay")
			time1:SetPoint ("topright", texture, "topright", 50, -30)
			time1:SetSize (24, 24)
			time1:SetTexture ([[Interface\COMMON\Indicator-Green]])
			local time2 = tutorialFrame:CreateTexture (nil, "overlay")
			time2:SetPoint ("left", time1, "right", 2, 0)
			time2:SetSize (24, 24)
			time2:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
			local time3 = tutorialFrame:CreateTexture (nil, "overlay")
			time3:SetPoint ("left", time2, "right", 2, 0)
			time3:SetSize (24, 24)
			time3:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
			time3:SetVertexColor (1, .7, 0)
			local time4 = tutorialFrame:CreateTexture (nil, "overlay")
			time4:SetPoint ("left", time3, "right", 2, 0)
			time4:SetSize (24, 24)
			time4:SetTexture ([[Interface\COMMON\Indicator-Red]])
			local timeText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			timeText:SetPoint ("left", time4, "right", 4, 2)
			DF:SetFontSize (timeText, 12)
			timeText:SetText ("indicates the time left (+4 hours, +90 minutes, +30 minutes, less than 30 minutes)")
			
			--incador de quantidade
			local flag = tutorialFrame:CreateTexture (nil, "overlay")
			flag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag]])
			flag:SetPoint ("topright", texture, "topright", 88, -60)
			flag:SetSize (64*1, 32*1)
			
			local amountText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			amountText:SetPoint ("center", flag, "center", 0, 10)
			DF:SetFontSize (amountText, 9)
			amountText:SetText ("100")
			
			local amountBackground = tutorialFrame:CreateTexture (nil, "overlay")
			amountBackground:SetPoint ("center", amountText, "center", 0, 0)
			amountBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
			amountBackground:SetTexCoord (12/512, 74/512, 251/512, 281/512)
			amountBackground:SetSize (32*2, 10*2)
			amountBackground:SetAlpha (.7)
			
			local timeText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			timeText:SetPoint ("left", flag, "right", 4, 10)
			DF:SetFontSize (timeText, 12)
			timeText:SetText ("indicates the amount to receive")
			
			--indicadores de recompensa
			local texture1 = tutorialFrame:CreateTexture (nil, "overlay")
			texture1:SetSize (24, 24)
			texture1:SetPoint ("topright", texture, "topright", 50, -90)
			texture1:SetTexture ([[Interface\ICONS\INV_Chest_RaidShaman_I_01]])
			local texture2 = tutorialFrame:CreateTexture (nil, "overlay")
			texture2:SetSize (24, 24)
			texture2:SetPoint ("left", texture1, "right", 2, 0)
			texture2:SetTexture ([[Interface\GossipFrame\auctioneerGossipIcon]])
			local texture3 = tutorialFrame:CreateTexture (nil, "overlay")
			texture3:SetSize (24, 24)
			texture3:SetPoint ("left", texture2, "right", 2, 0)
			texture3:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blue]])
			local texture4 = tutorialFrame:CreateTexture (nil, "overlay")
			texture4:SetSize (24, 24)
			texture4:SetPoint ("left", texture3, "right", 2, 0)
			texture4:SetTexture ([[Interface\Icons\inv_orderhall_orderresources]])
			local texture5 = tutorialFrame:CreateTexture (nil, "overlay")
			texture5:SetSize (24, 24)
			texture5:SetPoint ("left", texture4, "right", 2, 0)
			texture5:SetTexture (1417744)
			
			local textureText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			textureText:SetPoint ("left", texture5, "right", 6, 0)
			DF:SetFontSize (textureText, 12)
			textureText:SetText ("indicates the reward (equipment, gold, artifact power, resources, reagents)")
			
			--indicador de facção
			local criteriaIndicator = tutorialFrame:CreateTexture (nil, "OVERLAY", 2)
			criteriaIndicator:SetPoint ("topright", texture, "topright", 48, -122)
			criteriaIndicator:SetSize (23*.8, 37*.8)
			criteriaIndicator:SetAlpha (.8)
			criteriaIndicator:SetTexture ([[Interface\AdventureMap\AdventureMap]])
			criteriaIndicator:SetTexCoord (901/1024, 924/1024, 251/1024, 288/1024)
			local criteriaIndicatorGlow = tutorialFrame:CreateTexture (nil, "OVERLAY", 1)
			criteriaIndicatorGlow:SetPoint ("center", criteriaIndicator, "center")
			criteriaIndicatorGlow:SetSize (18, 18)
			criteriaIndicatorGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\criteriaIndicatorGlow]])
			criteriaIndicatorGlow:SetTexCoord (0, 1, 0, 1)

			local faccaoText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			faccaoText:SetPoint ("left", criteriaIndicator, "right", 6, 0)
			DF:SetFontSize (faccaoText, 12)
			faccaoText:SetText ("indicates the quest counts towards the selected faction.")
			
			--indicator de quantas questes ha para a facção
			local factionFrame = CreateFrame ("frame", nil, tutorialFrame)
			factionFrame:SetSize (20, 20)
			factionFrame:SetPoint ("topright", texture, "topright", 50, -162)
			
			local factionIcon = factionFrame:CreateTexture (nil, "background")
			factionIcon:SetSize (18, 18)
			factionIcon:SetPoint ("center", factionFrame, "center")
			factionIcon:SetDrawLayer ("background", -2)
			
			local factionHighlight = factionFrame:CreateTexture (nil, "background")
			factionHighlight:SetSize (36, 36)
			factionHighlight:SetTexture ([[Interface\QUESTFRAME\WorldQuest]])
			factionHighlight:SetTexCoord (0.546875, 0.62109375, 0.6875, 0.984375)
			factionHighlight:SetDrawLayer ("background", -3)
			factionHighlight:SetPoint ("center", factionFrame, "center")

			local factionIconBorder = factionFrame:CreateTexture (nil, "artwork", 0)
			factionIconBorder:SetSize (20, 20)
			factionIconBorder:SetPoint ("center", factionFrame, "center")
			factionIconBorder:SetTexture ([[Interface\COMMON\GoldRing]])
			
			local factionQuestAmount = factionFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			factionQuestAmount:SetPoint ("center", factionFrame, "center")
			factionQuestAmount:SetText ("4")
			
			local factionQuestAmountBackground = factionFrame:CreateTexture (nil, "background")
			factionQuestAmountBackground:SetPoint ("center", factionFrame, "center")
			factionQuestAmountBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
			factionQuestAmountBackground:SetTexCoord (12/512, 74/512, 251/512, 281/512)
			factionQuestAmountBackground:SetSize (20, 10)
			factionQuestAmountBackground:SetAlpha (.7)
			factionQuestAmountBackground:SetDrawLayer ("background", 3)
			
			local faccaoAmountText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			faccaoAmountText:SetPoint ("left", factionFrame, "right", 6, 0)
			DF:SetFontSize (faccaoAmountText, 12)
			faccaoAmountText:SetText ("indicates how many quest are on the map for the selected faction.")
			
			--click para colocar no tracker
			local clickToTrack = factionFrame:CreateTexture (nil, "background")
			clickToTrack:SetPoint ("topright", texture, "topright", 51, -192)
			clickToTrack:SetTexture ([[Interface\TUTORIALFRAME\UI-TUTORIAL-FRAME]])
			clickToTrack:SetTexCoord (15/512, 63/512, 231/512, 306/512)
			clickToTrack:SetSize (48*.5, 75*.5)
			clickToTrack:SetDrawLayer ("background", 3)
			
			local clickToTrack2 = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			clickToTrack2:SetPoint ("left", clickToTrack, "right", 6, 0)
			DF:SetFontSize (clickToTrack2, 12)
			clickToTrack2:SetText ("Left click to track a quest. On the tracker, you may |cFFFFFFFFright click|r to untrack it.")
			
		end
	else
		WorldQuestTracker.NoAutoSwitchToWorldMap = nil
	end
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> tracker quest

--verifica se a quest ja esta na lista de track
function WorldQuestTracker.IsQuestBeingTracked (questID)
	for _, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		if (quest.questID == questID) then
			return true
		end
	end
	return
end

--adiciona uma quest ao tracker
function WorldQuestTracker.AddQuestToTracker (self)
	local questID = self.questID
	local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
	if (timeLeft and timeLeft > 0) then
		local mapID = self.mapID
		local iconTexture = self.IconTexture
		local iconText = self.IconText
		local questType = self.QuestType
		local numObjectives = self.numObjectives
		
		if (iconTexture) then
			tinsert (WorldQuestTracker.QuestTrackList, {
				questID = questID, 
				mapID = mapID, 
				mapIDSynthetic = WorldQuestTracker.db.profile.syntheticMapIdList [mapID], 
				timeAdded = time(), 
				timeFraction = GetTime(), 
				timeLeft = timeLeft, 
				expireAt = time() + (timeLeft*60), 
				rewardTexture = iconTexture, 
				rewardAmount = iconText, 
				index = #WorldQuestTracker.QuestTrackList,
				questType = questType,
				numObjectives = numObjectives,
			})
		else
			WorldQuestTracker:Msg ("This quest isn't loaded yet, please wait few seconds.")
		end
		
		--atualiza os widgets para adicionar a quest no frame do tracker
		WorldQuestTracker.RefreshTrackerWidgets()
	else
		WorldQuestTracker:Msg ("This quest has no time left.")
	end
end

--remove uma quest que ja esta no tracker
--quando o addon iniciar e fazer a primeira chacagem de quests desatualizadas, mandar noUpdate = true
function WorldQuestTracker.RemoveQuestFromTracker (questID, noUpdate)
	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		if (quest.questID == questID) then
			--remove da tabela
			tremove (WorldQuestTracker.QuestTrackList, index)
			--atualiza os widgets para remover a quest do frame do tracker
			if (not noUpdate) then
				WorldQuestTracker.RefreshTrackerWidgets()
			end
			return true
		end
	end
end

--verifica o tempo restante de cada quest no tracker e a remove se o tempo estiver terminado
function WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker()
	local now = time()
	local gotRemoval
	for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
		local quest = WorldQuestTracker.QuestTrackList [i]
		if (quest.expireAt < now) then
			WorldQuestTracker.RemoveQuestFromTracker (quest.questID, true)
			gotRemoval = true
		end
	end
	if (gotRemoval) then
		WorldQuestTracker.RefreshTrackerWidgets()
	end
end

--ao clicar em um botão de uma quest no world map ou no mapa da zona
function WorldQuestTracker.OnQuestClicked (self, button)
	--button é o frame que foi precionado
	local questID = self.questID
	local mapID = self.mapID
	
	--verifica se a quest ja esta sendo monitorada
	local myQuests = WorldQuestTracker.GetTrackedQuests()
	if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
		--remover a quest do track
		WorldQuestTracker.RemoveQuestFromTracker (questID)
	else
		--adicionar a quest ao track
		WorldQuestTracker.AddQuestToTracker (self)
	end
	if (self.IsZoneQuestButton) then
		WorldQuestTracker.UpdateZoneWidgets()
	elseif (self.IsWorldQuestButton) then
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
	end
end

--organiza as quest para as quests do mapa atual serem jogadas para cima
local Sort_currentMapID
local Sort_QuestsOnTracker = function (t1, t2)
	if (t1.mapID == Sort_currentMapID and t2.mapID == Sort_currentMapID) then
		return t1.timeFraction > t2.timeFraction
	elseif (t1.mapID == Sort_currentMapID) then
		return true
	elseif (t2.mapID == Sort_currentMapID) then
		return false
	else
		if (t1.mapIDSynthetic == t2.mapIDSynthetic) then
			return t1.timeFraction > t2.timeFraction
		else
			return t1.mapIDSynthetic > t2.mapIDSynthetic
		end
	end
end

--poe as quests em ordem de acordo com o mapa atual do jogador?
function WorldQuestTracker.ReorderQuestsOnTracker()
	--joga as quests do mapa atual pra cima
	Sort_currentMapID = WorldMapFrame.currentStandingZone or GetCurrentMapAreaID()
	if (Sort_currentMapID == 1080 or Sort_currentMapID == 1072) then
		--Thunder Totem or Trueshot Lodge
		Sort_currentMapID = 1024
	end
	table.sort (WorldQuestTracker.QuestTrackList, Sort_QuestsOnTracker)
end

--parent frame na UIParent
--esse frame é quem vai ser anexado ao tracker da blizzard
local WorldQuestTrackerFrame = CreateFrame ("frame", "WorldQuestTrackerScreenPanel", UIParent)
WorldQuestTrackerFrame:SetSize (235, 500)

local WorldQuestTrackerFrame_QuestHolder = CreateFrame ("frame", "WorldQuestTrackerScreenPanel_QuestHolder", WorldQuestTrackerFrame)
WorldQuestTrackerFrame_QuestHolder:SetAllPoints()

--cria o header
local WorldQuestTrackerHeader = CreateFrame ("frame", "WorldQuestTrackerQuestsHeader", WorldQuestTrackerFrame, "ObjectiveTrackerHeaderTemplate") -- "ObjectiveTrackerHeaderTemplate"
WorldQuestTrackerHeader.Text:SetText ("World Quest Tracker")
local minimizeButton = CreateFrame ("button", "WorldQuestTrackerQuestsHeaderMinimizeButton", WorldQuestTrackerFrame)
local minimizeButtonText = minimizeButton:CreateFontString (nil, "overlay", "GameFontNormal")
minimizeButtonText:SetText ("World Quests")
minimizeButtonText:SetPoint ("right", minimizeButton, "left", -3, 1)
minimizeButtonText:Hide()

WorldQuestTrackerFrame.MinimizeButton = minimizeButton
minimizeButton:SetSize (16, 16)
minimizeButton:SetPoint ("topright", WorldQuestTrackerHeader, "topright", 0, -4)
minimizeButton:SetScript ("OnClick", function()
	if (WorldQuestTrackerFrame.collapsed) then
		WorldQuestTrackerFrame.collapsed = false
		minimizeButton:GetNormalTexture():SetTexCoord (0, 0.5, 0.5, 1)
		minimizeButton:GetPushedTexture():SetTexCoord (0.5, 1, 0.5, 1)
		WorldQuestTrackerFrame_QuestHolder:Show()
		WorldQuestTrackerHeader:Show()
		minimizeButtonText:Hide()
	else
		WorldQuestTrackerFrame.collapsed = true
		minimizeButton:GetNormalTexture():SetTexCoord (0, 0.5, 0, 0.5)
		minimizeButton:GetPushedTexture():SetTexCoord (0.5, 1, 0, 0.5)
		WorldQuestTrackerFrame_QuestHolder:Hide()
		WorldQuestTrackerHeader:Hide()
		minimizeButtonText:Show()
	end
end)
minimizeButton:SetNormalTexture ([[Interface\Buttons\UI-Panel-QuestHideButton]])
minimizeButton:GetNormalTexture():SetTexCoord (0, 0.5, 0.5, 1)
minimizeButton:SetPushedTexture ([[Interface\Buttons\UI-Panel-QuestHideButton]])
minimizeButton:GetPushedTexture():SetTexCoord (0.5, 1, 0.5, 1)
minimizeButton:SetHighlightTexture ([[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]])
minimizeButton:SetDisabledTexture ([[Interface\Buttons\UI-Panel-QuestHideButton-disabled]])

--armazena todos os widgets
local TrackerWidgetPool = {}
--inicializa a variavel que armazena o tamanho do quest frame
WorldQuestTracker.TrackerHeight = 0

--da refresh na ancora do screen panel
function WorldQuestTracker.RefreshAnchor()
	WorldQuestTrackerFrame:SetPoint ("topleft", ObjectiveTrackerFrame, "topleft", -10, -WorldQuestTracker.TrackerHeight - 20)
	WorldQuestTrackerHeader:SetPoint ("bottom", WorldQuestTrackerFrame, "top", 0, -20)
end

--quando um widget for clicado, mostrar painel com opção para parar de trackear
local TrackerFrameOnClick = function (self, button)
	--ao clicar em cima de uma quest mostrada no tracker
	--??--
	if (button == "RightButton") then
		WorldQuestTracker.RemoveQuestFromTracker (self.questID)
	end
end

local buildTooltip = function (self)
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint ("TOPRIGHT", self, "TOPLEFT", -20, 0)
	GameTooltip:SetOwner (self, "ANCHOR_PRESERVE")
	local questID = self.questID
	
	if ( not HaveQuestData (questID) ) then
		GameTooltip:SetText (RETRIEVING_DATA, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
		GameTooltip:Show()
		return
	end

	local title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID (questID)

	local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = GetQuestTagInfo (questID)
	local color = WORLD_QUEST_QUALITY_COLORS [rarity]
	GameTooltip:SetText (title, color.r, color.g, color.b)

	--belongs to what faction
	if (factionID) then
		local factionName = GetFactionInfoByID (factionID)
		if (factionName) then
			if (capped) then
				GameTooltip:AddLine (factionName, GRAY_FONT_COLOR:GetRGB())
			else
				GameTooltip:AddLine (factionName, 0.4, 0.733, 1.0)
			end
			GameTooltip:AddLine (" ")
		end
	end

	--time left
	local timeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes (questID)
	if (timeLeftMinutes) then
		local color = NORMAL_FONT_COLOR
		local timeString
		if (timeLeftMinutes <= WORLD_QUESTS_TIME_CRITICAL_MINUTES) then
			color = RED_FONT_COLOR
			timeString = SecondsToTime (timeLeftMinutes * 60)
		elseif (timeLeftMinutes <= 60 + WORLD_QUESTS_TIME_CRITICAL_MINUTES) then
			timeString = SecondsToTime ((timeLeftMinutes - WORLD_QUESTS_TIME_CRITICAL_MINUTES) * 60)
		elseif (timeLeftMinutes < 24 * 60 + WORLD_QUESTS_TIME_CRITICAL_MINUTES) then
			timeString = D_HOURS:format (math.floor(timeLeftMinutes - WORLD_QUESTS_TIME_CRITICAL_MINUTES) / 60)
		else
			local days = math.floor(timeLeftMinutes - WORLD_QUESTS_TIME_CRITICAL_MINUTES) / 1440
			local hours = math.floor(timeLeftMinutes - WORLD_QUESTS_TIME_CRITICAL_MINUTES) / 60
			timeString = D_DAYS:format (days) .. " " .. D_HOURS:format (hours - (floor (days)*24))
		end
		GameTooltip:AddLine (BONUS_OBJECTIVE_TIME_LEFT:format (timeString), color.r, color.g, color.b)
	end

	--all objectives
	for objectiveIndex = 1, self.numObjectives do
		local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(questID, objectiveIndex, false);
		if ( objectiveText and #objectiveText > 0 ) then
			local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
			GameTooltip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
		end
	end
	
	--percentage bar
	local percent = C_TaskQuest.GetQuestProgressBarInfo (questID)
	if ( percent ) then
		GameTooltip_InsertFrame(GameTooltip, WorldMapTaskTooltipStatusBar);
		WorldMapTaskTooltipStatusBar.Bar:SetValue(percent);
		WorldMapTaskTooltipStatusBar.Bar.Label:SetFormattedText(PERCENTAGE_STRING, percent);
	end

	-- rewards
	if ( GetQuestLogRewardXP(questID) > 0 or GetNumQuestLogRewardCurrencies(questID) > 0 or GetNumQuestLogRewards(questID) > 0 or GetQuestLogRewardMoney(questID) > 0 or GetQuestLogRewardArtifactXP(questID) > 0 ) then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(QUEST_REWARDS, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
		local hasAnySingleLineRewards = false;
		-- xp
		local xp = GetQuestLogRewardXP(questID);
		if ( xp > 0 ) then
			GameTooltip:AddLine(BONUS_OBJECTIVE_EXPERIENCE_FORMAT:format(xp), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			hasAnySingleLineRewards = true;
		end
		-- money
		local money = GetQuestLogRewardMoney(questID);
		if ( money > 0 ) then
			SetTooltipMoney(GameTooltip, money, nil);
			hasAnySingleLineRewards = true;
		end	
		local artifactXP = GetQuestLogRewardArtifactXP(questID);
		if ( artifactXP > 0 ) then
			GameTooltip:AddLine(BONUS_OBJECTIVE_ARTIFACT_XP_FORMAT:format(artifactXP), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			hasAnySingleLineRewards = true;
		end
		-- currency		
		local numQuestCurrencies = GetNumQuestLogRewardCurrencies(questID);
		for i = 1, numQuestCurrencies do
			local name, texture, numItems = GetQuestLogRewardCurrencyInfo(i, questID);
			local text = BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT:format(texture, numItems, name);
			GameTooltip:AddLine(text, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			hasAnySingleLineRewards = true;
		end
		-- items
		local numQuestRewards = GetNumQuestLogRewards (questID)
		for i = 1, numQuestRewards do
			local name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(i, questID);
			local text;
			if ( numItems > 1 ) then
				text = string.format(BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT, texture, numItems, name);
			elseif( texture and name ) then
				text = string.format(BONUS_OBJECTIVE_REWARD_FORMAT, texture, name);			
			end
			if( text ) then
				local color = ITEM_QUALITY_COLORS[quality];
				GameTooltip:AddLine(text, color.r, color.g, color.b);
			end
		end
		
	end	

	GameTooltip:Show()
--	if (GameTooltip.ItemTooltip) then
--		GameTooltip:SetHeight (GameTooltip:GetHeight() + GameTooltip.ItemTooltip:GetHeight())
--	end
end

local TrackerFrameOnEnter = function (self)
	local color = OBJECTIVE_TRACKER_COLOR["HeaderHighlight"]
	self.Title:SetTextColor (color.r, color.g, color.b)

	local color = OBJECTIVE_TRACKER_COLOR["NormalHighlight"]
	self.Zone:SetTextColor (color.r, color.g, color.b)
	
	--WorldMapTooltip:SetParent (UIParent)
	--WorldMapCompareTooltip1:SetParent (UIParent)
	--WorldMapCompareTooltip2:SetParent (UIParent)
	--TaskPOI_OnEnter(self)
	
	buildTooltip (self)
end

local TrackerFrameOnLeave = function (self)
	local color = OBJECTIVE_TRACKER_COLOR["Header"]
	self.Title:SetTextColor (color.r, color.g, color.b)
	
	local color = OBJECTIVE_TRACKER_COLOR["Normal"]
	self.Zone:SetTextColor (color.r, color.g, color.b)

	--WorldMapTooltip:SetParent (WorldMapFrame)
	--WorldMapCompareTooltip1:SetParent (WorldMapFrame)
	--WorldMapCompareTooltip2:SetParent (WorldMapFrame)
	
	--TaskPOI_OnLeave(self)
	GameTooltip:Hide()
end

--pega um widget já criado ou cria um novo
function WorldQuestTracker.GetOrCreateTrackerWidget (index)
	if (TrackerWidgetPool [index]) then
		return TrackerWidgetPool [index]
	end
	
	local f = CreateFrame ("button", nil, WorldQuestTrackerFrame_QuestHolder)
	f:SetSize (235, 40)
	f:SetScript ("OnClick", TrackerFrameOnClick)
	f:SetScript ("OnEnter", TrackerFrameOnEnter)
	f:SetScript ("OnLeave", TrackerFrameOnLeave)
	f:RegisterForClicks ("LeftButtonUp", "RightButtonUp")
	--f.module = _G ["WORLD_QUEST_TRACKER_MODULE"]
	f.worldQuest = true
	f.Title = f:CreateFontString (nil, "overlay", "ObjectiveFont")
	f.Title:SetPoint ("topleft", f, "topleft", 10, -1)
	local titleColor = OBJECTIVE_TRACKER_COLOR["Header"]
	f.Title:SetTextColor (titleColor.r, titleColor.g, titleColor.b)
	f.Zone = f:CreateFontString (nil, "overlay", "ObjectiveFont")
	f.Zone:SetPoint ("topleft", f, "topleft", 10, -17)
	f.Icon = f:CreateTexture (nil, "artwork")
	f.Icon:SetPoint ("topleft", f, "topleft", -13, -2)
	f.Icon:SetSize (16, 16)
	f.RewardAmount = f:CreateFontString (nil, "overlay", "ObjectiveFont")
	f.RewardAmount:SetTextColor (titleColor.r, titleColor.g, titleColor.b)
	f.RewardAmount:SetPoint ("top", f.Icon, "bottom", 0, -2)
	DF:SetFontSize (f.RewardAmount, 10)
	
	f.Circle = f:CreateTexture (nil, "overlay")
	--f.Circle:SetTexture ([[Interface\Store\Services]])
	--f.Circle:SetTexCoord (395/1024, 446/1024, 945/1024, 997/1024)
	f.Circle:SetTexture ([[Interface\Transmogrify\Transmogrify]])
	f.Circle:SetTexCoord (381/512, 405/512, 93/512, 117/512)
	f.Circle:SetSize (18, 18)
	f.Circle:SetPoint ("center", f.Icon, "center")
	f.Circle:SetDesaturated (true)
	f.Circle:SetAlpha (.7)
	
	TrackerWidgetPool [index] = f
	return f
end

--atualiza os widgets e reajusta a ancora
function WorldQuestTracker.RefreshTrackerWidgets()
	--reordena as quests
	WorldQuestTracker.ReorderQuestsOnTracker()
	
	--atualiza as quest no tracker
	local y = -30
	local nextWidget = 1
	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		--verifica se a quest esta ativa, ela pode ser desativada se o jogador estiver dentro da area da quest
		if (not quest.isDisabled) then
			local widget = WorldQuestTracker.GetOrCreateTrackerWidget (nextWidget)
			widget:ClearAllPoints()
			widget:SetPoint ("topleft", WorldQuestTrackerFrame, "topleft", 0, y)
			widget.questID = quest.questID
			widget.numObjectives = quest.numObjectives
			--widget.id = quest.questID
			
			local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (quest.questID)
			
			widget.Title:SetText (title)
			local color = OBJECTIVE_TRACKER_COLOR["Header"]
			widget.Title:SetTextColor (color.r, color.g, color.b)
			
			widget.Zone:SetText ("- " .. WorldQuestTracker.GetZoneName (quest.mapID))
			local color = OBJECTIVE_TRACKER_COLOR["Normal"]
			widget.Zone:SetTextColor (color.r, color.g, color.b)
			
			if (quest.questType == QUESTTYPE_ARTIFACTPOWER) then
				widget.Icon:SetMask (nil)
			else
				widget.Icon:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
			end
			widget.Icon:SetTexture (quest.rewardTexture)
			
			widget.RewardAmount:SetText (quest.rewardAmount)
			
			widget:Show()
			
			y = y - 35
			nextWidget = nextWidget + 1
		end
	end

	--se não há nenhuma quest sendo mostrada, hidar o cabeçalho
	if (nextWidget == 1) then
		WorldQuestTrackerHeader:Hide()
		minimizeButton:Hide()
	else
		if (not WorldQuestTrackerFrame.collapsed) then
			WorldQuestTrackerHeader:Show()
		end
		minimizeButton:Show()
	end
	
	--se tiver um header do default da blizzard, hidar o nosso header ou renomear?
	
	--esconde os widgets não usados
	for i = nextWidget, #TrackerWidgetPool do
		TrackerWidgetPool [i]:Hide()
	end
	
	WorldQuestTracker.RefreshAnchor()
end

--quando o tracker da interface atualizar, atualizar tbm o nosso tracker
--verifica se o jogador esta na area da questa
function WorldQuestTracker.UpdateQuestsInArea()
	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		local questIndex = GetQuestLogIndexByID (quest.questID)
		local isInArea, isOnMap, numObjectives = GetTaskInfo (quest.questID)
		if ((questIndex and questIndex ~= 0) or isInArea) then
			--desativa pois o jogo ja deve estar mostrando a quest
			quest.isDisabled = true
		else
			quest.isDisabled = nil
		end
	end
	WorldQuestTracker.RefreshTrackerWidgets()
end

--ao completar uma world quest remover a quest do tracker e da refresh nos widgets
hooksecurefunc ("BonusObjectiveTracker_OnTaskCompleted", function (questID, xp, money)
	for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
		if (WorldQuestTracker.QuestTrackList[i].questID == questID) then
			tremove (WorldQuestTracker.QuestTrackList, i)
			WorldQuestTracker.RefreshTrackerWidgets()
			break
		end
	end
end)

--dispara quando o tracker da interface é atualizado, precisa dar refresh na nossa ancora
local On_ObjectiveTracker_Update = function()
	local tracker = ObjectiveTrackerFrame
	
	if (not tracker.initialized) then
		return
	end

	WorldQuestTracker.UpdateQuestsInArea()
	
	--pega a altura do tracker de quests
	local y = 0
	for i = 1, #tracker.MODULES do
		local module = tracker.MODULES [i]
		y = y + module.contentsHeight
	end
	
	--usado na função da ancora
	if (ObjectiveTrackerFrame.collapsed) then
		WorldQuestTracker.TrackerHeight = 20
	else
		WorldQuestTracker.TrackerHeight = y
	end
	
	-- atualiza a ancora do nosso tracker
	WorldQuestTracker.RefreshAnchor()
	
end

--quando houver uma atualização no quest tracker, atualizar as ancores do nosso tracker
hooksecurefunc ("ObjectiveTracker_Update", function (reason, id)
	On_ObjectiveTracker_Update()
end)
--quando o jogador clicar no botão de minizar o quest tracker, atualizar as ancores do nosso tracker
ObjectiveTrackerFrame.HeaderMenu.MinimizeButton:HookScript ("OnClick", function()
	On_ObjectiveTracker_Update()
end)

function WorldQuestTracker:FullTrackerUpdate()
	On_ObjectiveTracker_Update()
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> taxy map widgets
local taxyMapWidgets = {}

--
--WorldQuestTracker.db.profile.taxy_trackedonly

--fazer os blips para o mapa sem zoom
--fazer os blips deseparecerem quando o mapa tiver zoom
--quando pasasr o mouse no blip, mostrar qual quest que é
--quando dar zoom mostrar o icone do reward no lugar da exclamação

function WorldQuestTracker:GetQuestFullInfo (questID)
	--info
	local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
	--tempo restante
	local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
	--se é da faction selecionada
	local isCriteria = WorldMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty (questID)
	local selected = questID == GetSuperTrackedQuestID()
	local isSpellTarget = SpellCanTargetQuest() and IsQuestIDValidSpellTarget (questID)
	
	--gold
	local gold, goldFormated = WorldQuestTracker.GetQuestReward_Gold (questID)
	--class hall resource
	local rewardName, rewardTexture, numRewardItems = WorldQuestTracker.GetQuestReward_Resource (questID)
	--item
	local itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker.GetQuestReward_Item (questID)
	local questType = 0x0
	local texture
	
	if (gold > 0) then
		questType = QUESTTYPE_GOLD
		texture = WorldQuestTracker.GetGoldIcon()
	end
	
	if (rewardName) then
		questType = QUESTTYPE_RESOURCE
		texture = rewardTexture
	end
	
	if (itemName) then
		if (isArtifact) then
			questType = QUESTTYPE_ARTIFACTPOWER
			local artifactIcon = WorldQuestTracker.GetArtifactPowerIcon (artifactPower)
			texture = artifactIcon .. "_round"
		else
			questType = QUESTTYPE_ITEM
			texture = itemTexture
		end
	end
	
	return title, questType, texture, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, selected, isSpellTarget, timeLeft, isCriteria, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable
end

function WorldQuestTracker:GetAllWorldQuests_Info()
	local result = {}
	SetMapByID (MAPID_BROKENISLES)
	local total = 0
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		local taskInfo = GetQuestsForPlayerByMapID (mapId)
		if (taskInfo and #taskInfo > 0) then
			for i, info  in ipairs (taskInfo) do
				local questID = info.questId
				if (HaveQuestData (questID)) then
					local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
					if (isWorldQuest) then
						C_TaskQuest.RequestPreloadRewardData (questID)
						result [mapId] = result [mapId] or {}
						tinsert (result [mapId], info)
						total = total + 1
					end
				end
			end
		end
	end

	return result					
end

local get_or_create_taxy_blip = function (index)
	local blip = taxyMapWidgets [index]
	if (blip) then
		return blip
	end
	
	local f = CreateFrame ("button", "WorldQuestTrackerTaxyMapBlip" .. index, FlightMapFrame.ScrollContainer)
	f:SetSize (16, 16)
	f.Texture = f:CreateTexture (nil, "artwork")
	f.Texture:SetPoint ("center")
	f.Texture:SetTexture ([[Interface\Buttons\CancelButton-Up]])
	f.Texture:SetSize (16, 16)
	tinsert (taxyMapWidgets, f)
	
	return f
end

function WorldQuestTracker.TaxyFrameHasZoom()
	return not FlightMapFrame.ScrollContainer:IsZoomedOut()
end

local TaxyPOIIndex, TaxyPOIContainer = 1, {}
function WorldQuestTracker:GetOrCreateTaxyPOI (parent)
	local button = WorldQuestTracker.CreateZoneWidget (TaxyPOIIndex, "WorldQuestTrackerTaxyPOI", parent)
	tinsert (TaxyPOIContainer, button)
	TaxyPOIIndex = TaxyPOIIndex + 1
	return button
end

local onTaxyWidgetClick = function (self, button)
	--se tiver zoom, tratar o clique como qualquer outro
	if (WorldQuestTracker.TaxyFrameHasZoom()) then
		WorldQuestTracker.OnQuestClicked (self, button)
	else
		--se não tiver zoom, ver se a quest esta sendo trackeada
		if (not WorldQuestTracker.IsQuestBeingTracked (self.questID)) then
			--se não estiver, adicionar ela ao tracker
			WorldQuestTracker.OnQuestClicked (self, button)
		else
			--se ela ja estaver sendo trackeada, verificar se foi clique com o botao direito
			if (button == "RightButton") then
				WorldQuestTracker.OnQuestClicked (self, button)
			end
		end
	end
end
local format_for_taxy_zoom_allquests = function (button)
	button:SetScale (1.3	)
	button:SetWidth (POISize)
	button:SetAlpha (1)
end
local format_for_taxy_nozoom_tracked = function (button)
	button:ClearWidget()

	button:SetScale (WorldQuestTracker.db.profile.taxy_tracked_scale)
	button:SetWidth (POISize)
	button:SetAlpha (1)
	
	button.circleBorder:Show()
	
	button.IsTrackingGlow:Show()
	button.IsTrackingGlow:SetAlpha (.4)
end
local format_for_taxy_nozoom_allquests = function (button)
	button:ClearWidget()

	button.Texture:SetMask (nil)
	button.Texture:SetTexture ([[Interface\GossipFrame\AvailableQuestIcon]])
	button.Texture:Show()
	button:SetScale (4)
	button:SetWidth (8)
	button:SetAlpha (.80)
	
	button.blackBackground:Show()
	button.blackBackground:SetSize (28, 42)
	button.blackBackground:SetTexture ([[Interface\PETBATTLES\PETBATTLEHUD]])
	button.blackBackground:SetTexCoord (795/1024, 900/1024, 347/512, 447/512)
	button.blackBackground:SetDesaturated (true)
	button.blackBackground:SetAlpha (.45)
end

function WorldQuestTracker:TAXIMAP_OPENED()

	if (not WorldQuestTracker.FlyMapHook) then
	
		--tracking options
		FlightMapFrame.WorldQuestTrackerOptions = CreateFrame ("frame", "WorldQuestTrackerTaxyMapFrame", FlightMapFrame.BorderFrame)
		FlightMapFrame.WorldQuestTrackerOptions:SetSize (1, 1)
		FlightMapFrame.WorldQuestTrackerOptions:SetPoint ("bottomleft", FlightMapFrame.BorderFrame, "bottomleft", 3, 3)
		local doubleTapBackground = FlightMapFrame.WorldQuestTrackerOptions:CreateTexture (nil, "overlay")
		doubleTapBackground:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-HorizontalShadow]])
		doubleTapBackground:SetPoint ("bottomleft", FlightMapFrame.WorldQuestTrackerOptions, "bottomleft", 0, 0)
		doubleTapBackground:SetSize (630, 18)
		
		local checkboxShowAllQuests_func = function (self, actorTypeIndex, value) 
			WorldQuestTracker.db.profile.taxy_showquests = value
		end
		local checkboxShowAllQuests = DF:CreateSwitch (FlightMapFrame.WorldQuestTrackerOptions, checkboxShowAllQuests_func, WorldQuestTracker.db.profile.taxy_showquests, _, _, _, _, "checkboxShowAllQuests", _, _, _, _, _, DF:GetTemplate ("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
		checkboxShowAllQuests:SetAsCheckBox()
		checkboxShowAllQuests:SetSize (16, 16)
		checkboxShowAllQuests.tooltip = "Show world quests"
		checkboxShowAllQuests:SetPoint ("bottomleft", FlightMapFrame.WorldQuestTrackerOptions, "bottomleft", 0, 0)
		local checkboxShowAllQuestsString = DF:CreateLabel (checkboxShowAllQuests, "Show World Quests", 12, "orange", nil, "checkboxShowAllQuestsLabel", nil, "overlay")
		checkboxShowAllQuestsString:SetPoint ("left", checkboxShowAllQuests, "right", 2, 0)
		
		local checkboxShowTrackedOnly_func = function (self, actorTypeIndex, value) 
			WorldQuestTracker.db.profile.taxy_trackedonly = value
		end
		local checkboxShowTrackedOnly = DF:CreateSwitch (FlightMapFrame.WorldQuestTrackerOptions, checkboxShowTrackedOnly_func, WorldQuestTracker.db.profile.taxy_trackedonly, _, _, _, _, "checkboxShowTrackedOnly", _, _, _, _, _, DF:GetTemplate ("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
		checkboxShowTrackedOnly:SetAsCheckBox()
		checkboxShowTrackedOnly:SetSize (16, 16)
		checkboxShowTrackedOnly.tooltip = "Show only quests being tracked"
		checkboxShowTrackedOnly:SetPoint ("left", checkboxShowAllQuestsString, "right", 4, 0)
		local checkboxShowTrackedOnlyString = DF:CreateLabel (checkboxShowTrackedOnly, "Only Tracked", 12, "orange", nil, "checkboxShowTrackedOnlyLabel", nil, "overlay")
		checkboxShowTrackedOnlyString:SetPoint ("left", checkboxShowTrackedOnly, "right", 2, 0)
	
		hooksecurefunc (FlightMapFrame, "SetPinPosition", function (self, pin, normalizedX, normalizedY, insetIndex)
			if (not pin.questID) then
				return
			end
			if (not pin._WQT_Twin) then
				pin._WQT_Twin = WorldQuestTracker:GetOrCreateTaxyPOI (pin:GetParent())
				pin._WQT_Twin:RegisterForClicks ("LeftButtonUp", "RightButtonUp")
				pin._WQT_Twin:SetFrameStrata (pin:GetFrameStrata())
				pin._WQT_Twin:SetFrameLevel (pin:GetFrameLevel()+100)
				pin._WQT_Twin:SetScale (1.3)
				pin._WQT_Twin:SetScript ("OnClick", onTaxyWidgetClick)
				pin._WQT_Twin:SetPoint ("center", pin, "center")
				--mixin
				for member, func in pairs (pin) do
					if (type (func) == "function") then
						pin._WQT_Twin [member] = func
					end
				end
				--override scripts
				pin._WQT_Twin:SetScript ("OnEnter", pin:GetScript ("OnEnter"))
				pin._WQT_Twin:SetScript ("OnLeave", pin:GetScript ("OnLeave"))
			end
			
			local isShowingQuests = WorldQuestTracker.db.profile.taxy_showquests
			local isShowingOnlyTracked = WorldQuestTracker.db.profile.taxy_trackedonly
			local hasZoom = WorldQuestTracker.TaxyFrameHasZoom()
			
			if (not isShowingQuests and not hasZoom) then
				pin._WQT_Twin:Hide()
				return
			end
			if (isShowingOnlyTracked) then
				if (not WorldQuestTracker.IsQuestBeingTracked (pin.questID) and not hasZoom) then
					pin._WQT_Twin:Hide()
					return
				end
			end

			pin._WQT_Twin:Show()
			
			local title, questType, texture, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, selected, isSpellTarget, timeLeft, isCriteria, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker:GetQuestFullInfo (pin.questID)
			local inProgress
			pin._WQT_Twin.questID = pin.questID
			pin._WQT_Twin.numObjectives = pin.numObjectives
			local mapID, zoneID = C_TaskQuest.GetQuestZoneID (pin.questID)
			pin._WQT_Twin.mapID = zoneID
			
			if (not hasZoom) then
				--não tem zoom
				if (isShowingOnlyTracked) then
					WorldQuestTracker.SetupWorldQuestButton (pin._WQT_Twin, questType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget)
					format_for_taxy_nozoom_tracked (pin._WQT_Twin)
				else
					format_for_taxy_nozoom_allquests (pin._WQT_Twin)
				end
			else
				--tem zoom
				WorldQuestTracker.SetupWorldQuestButton (pin._WQT_Twin, questType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget)
				format_for_taxy_zoom_allquests (pin._WQT_Twin)
			end
		end)
		WorldQuestTracker.FlyMapHook = true
	end
end

function WorldQuestTracker:TAXIMAP_CLOSED()
	
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> world map widgets

--se a janela do world map esta em modo janela
WorldQuestTracker.InWindowMode = WorldMapFrame_InWindowedMode()
WorldQuestTracker.LastUpdate = 0

--store the amount os quests for each faction on each map
local factionAmountForEachMap = {}

--tabela de configuração
WorldQuestTracker.mapTables = {
	[azsuna_mapId] = {
		worldMapLocation = {x = 10, y = -345, lineWidth = 233},
		worldMapLocationMax = {x = 168, y = -468, lineWidth = 330},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = azsuna_widgets,
	},
	[valsharah_mapId] = {
		worldMapLocation = {x = 10, y = -218, lineWidth = 240},
		worldMapLocationMax = {x = 168, y = -284, lineWidth = 340},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = valsharah_widgets,
	},
	[highmountain_mapId] = {
		worldMapLocation = {x = 10, y = -179, lineWidth = 320},
		worldMapLocationMax = {x = 168, y = -230, lineWidth = 452},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = highmountain_widgets,
	},
	[stormheim_mapId] = {
		worldMapLocation = {x = 415, y = -235, lineWidth = 277},
		worldMapLocationMax = {x = 747, y = -313, lineWidth = 393},
		bipAnchor = {side = "left", x = 0, y = -1},
		factionAnchor = {mySide = "right", anchorSide = "left", x = -0, y = 0},
		squarePoints = {mySide = "topright", anchorSide = "bottomright", y = -1, xDirection = -1},
		widgets = stormheim_widgets,
	},
	[suramar_mapId] = {
		worldMapLocation = {x = 327, y = -277, lineWidth = 365},
		worldMapLocationMax = {x = 618, y = -367, lineWidth = 522},
		bipAnchor = {side = "left", x = 0, y = -1},
		factionAnchor = {mySide = "right", anchorSide = "left", x = -0, y = 0},
		squarePoints = {mySide = "topright", anchorSide = "bottomright", y = -1, xDirection = -1},
		widgets = suramar_widgets,
	},
}

--esconde todos os widgets do world map
function WorldQuestTracker.HideWorldQuestsOnWorldMap()
	for _, widget in ipairs (all_widgets) do
		widget:Hide()
		widget.isArtifact = nil
		widget.questID = nil
	end
	for _, widget in ipairs (extra_widgets) do
		widget:Hide()
	end
end

--cria as linhas que servem de apoio para as quests no world map
local create_worldmap_line = function (lineWidth, mapId)
	local line = worldFramePOIs:CreateTexture (nil, "artwork", 2)
	line:SetSize (lineWidth, 2)
	line:SetHorizTile (true)
	line:SetAlpha (0.5)
	line:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\line_tiletexture]], true)
	local blip = worldFramePOIs:CreateTexture (nil, "overlay", 3)
	blip:SetTexture ([[Interface\Scenarios\ScenarioIcon-Combat]], true)
	
	local factionFrame = CreateFrame ("frame", "WorldQuestTrackerFactionFrame" .. mapId, worldFramePOIs)
	tinsert (faction_frames, factionFrame)
	factionFrame:SetSize (20, 20)
	
	local factionIcon = factionFrame:CreateTexture (nil, "background")
	factionIcon:SetSize (18, 18)
	factionIcon:SetPoint ("center", factionFrame, "center")
	factionIcon:SetDrawLayer ("background", -2)
	
	local factionHighlight = factionFrame:CreateTexture (nil, "background")
	factionHighlight:SetSize (36, 36)
	factionHighlight:SetTexture ([[Interface\QUESTFRAME\WorldQuest]])
	factionHighlight:SetTexCoord (0.546875, 0.62109375, 0.6875, 0.984375)
	factionHighlight:SetDrawLayer ("background", -3)
	factionHighlight:SetPoint ("center", factionFrame, "center")

	local factionIconBorder = factionFrame:CreateTexture (nil, "artwork", 0)
	factionIconBorder:SetSize (20, 20)
	factionIconBorder:SetPoint ("center", factionFrame, "center")
	factionIconBorder:SetTexture ([[Interface\COMMON\GoldRing]])
	
	local factionQuestAmount = factionFrame:CreateFontString (nil, "overlay", "GameFontNormal")
	factionQuestAmount:SetPoint ("center", factionFrame, "center")
	factionQuestAmount:SetText ("")
	
	local factionQuestAmountBackground = factionFrame:CreateTexture (nil, "background")
	factionQuestAmountBackground:SetPoint ("center", factionFrame, "center")
	factionQuestAmountBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
	factionQuestAmountBackground:SetTexCoord (12/512, 74/512, 251/512, 281/512)
	factionQuestAmountBackground:SetSize (20, 10)
	factionQuestAmountBackground:SetAlpha (.7)
	factionQuestAmountBackground:SetDrawLayer ("background", 3)
	
	factionFrame.icon = factionIcon
	factionFrame.text = factionQuestAmount
	factionFrame.background = factionQuestAmountBackground
	factionFrame.border = factionIconBorder
	factionFrame.highlight = factionHighlight
	
	tinsert (extra_widgets, line)
	tinsert (extra_widgets, blip)
	tinsert (extra_widgets, factionIcon)
	tinsert (extra_widgets, factionIconBorder)
	tinsert (extra_widgets, factionQuestAmount)
	tinsert (extra_widgets, factionQuestAmountBackground)
	tinsert (extra_widgets, factionHighlight)
	return line, blip, factionFrame
end

--cria uma square widget no world map
local create_worldmap_square = function (mapName, index)
	local button = CreateFrame ("button", "WorldQuestTrackerWorldMapPOI" .. mapName .. "POI" .. index, worldFramePOIs)
	button:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	button.IsWorldQuestButton = true
	button:SetFrameLevel (302)
	
	button:SetScript ("OnEnter", questButton_OnEnter)
	button:SetScript ("OnLeave", questButton_OnLeave)
	button:SetScript ("OnClick", questButton_OnClick)
	
	tinsert (all_widgets, button)
	
	local background = button:CreateTexture (nil, "background", -3)
	background:SetAllPoints()	
	
	local texture = button:CreateTexture (nil, "background", -2)
	texture:SetAllPoints()	
	
	local commonBorder = button:CreateTexture (nil, "artwork", 1)
	commonBorder:SetPoint ("topleft", button, "topleft")
	commonBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_white]])
	commonBorder:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	local rareBorder = button:CreateTexture (nil, "artwork", 1)
	rareBorder:SetPoint ("topleft", button, "topleft")
	rareBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_blue]])
	rareBorder:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	local epicBorder = button:CreateTexture (nil, "artwork", 1)
	epicBorder:SetPoint ("topleft", button, "topleft")
	epicBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_pink]])
	epicBorder:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	
	local borderAnimation = CreateFrame ("frame", "$parentBorderShineAnimation", button, "AutoCastShineTemplate")
	borderAnimation:SetFrameLevel (303)
	borderAnimation:SetPoint ("topleft", 2, -2)
	borderAnimation:SetPoint ("bottomright", -2, 2)
	borderAnimation:SetAlpha (.15)
	borderAnimation:Hide()
	button.borderAnimation = borderAnimation
	
	local shineAnimation = CreateFrame ("frame", "$parentShine", button, "AnimatedShineTemplate")
	shineAnimation:SetFrameLevel (303)
	shineAnimation:SetAllPoints()
	shineAnimation:Hide()
	button.shineAnimation = shineAnimation
	
	local trackingGlowBorder = button:CreateTexture (nil, "overlay", 1)
	trackingGlowBorder:SetPoint ("center", button, "center")
	trackingGlowBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_tracking]])
	trackingGlowBorder:SetSize (WORLDMAP_SQUARE_SIZE * 1.33, WORLDMAP_SQUARE_SIZE * 1.33)
	trackingGlowBorder:Hide()
	
	trackingGlowBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\glow_yellow_square]])
	trackingGlowBorder:SetBlendMode ("ADD")
	--trackingGlowBorder:SetDesaturated (true)
	trackingGlowBorder:SetSize (55, 55)
	trackingGlowBorder:SetAlpha (.6)
	trackingGlowBorder:SetDrawLayer ("BACKGROUND", -5)
	
	local criteriaIndicator = button:CreateTexture (nil, "OVERLAY", 2)
	criteriaIndicator:SetPoint ("bottomleft", button, "bottomleft", -2, 0)
	criteriaIndicator:SetSize (23*.4, 37*.4)
	criteriaIndicator:SetAlpha (.8)
	criteriaIndicator:SetTexture ([[Interface\AdventureMap\AdventureMap]])
	criteriaIndicator:SetTexCoord (901/1024, 924/1024, 251/1024, 288/1024)
	criteriaIndicator:Hide()
	local criteriaIndicatorGlow = button:CreateTexture (nil, "OVERLAY", 1)
	criteriaIndicatorGlow:SetPoint ("center", criteriaIndicator, "center")
	criteriaIndicatorGlow:SetSize (18, 18)
	criteriaIndicatorGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\criteriaIndicatorGlow]])
	criteriaIndicatorGlow:SetTexCoord (0, 1, 0, 1)
	criteriaIndicatorGlow:Hide()

	commonBorder:Hide()
	rareBorder:Hide()
	epicBorder:Hide()
	
	local timeBlip = button:CreateTexture (nil, "overlay", 2)
	timeBlip:SetPoint ("bottomright", button, "bottomright", 2, -2)
	timeBlip:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	
	button.questTypeBlip = button:CreateTexture (nil, "OVERLAY", 2)
	button.questTypeBlip:SetPoint ("topright", button, "topright", 2, 1)
	button.questTypeBlip:SetSize (12, 12)
	
	local amountText = button:CreateFontString (nil, "overlay", "GameFontNormal", 1)
	amountText:SetPoint ("top", button, "bottom", 1, 0)
	DF:SetFontSize (amountText, WORLDMAP_SQUARE_TEXT_SIZE)
	
	local amountBackground = button:CreateTexture (nil, "overlay", 0)
	amountBackground:SetPoint ("center", amountText, "center")
	amountBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
	amountBackground:SetTexCoord (12/512, 74/512, 251/512, 281/512)
	amountBackground:SetSize (32, 10)
	amountBackground:SetAlpha (.7)
	
	local highlight = button:CreateTexture (nil, "highlight")
	highlight:SetAllPoints()
	highlight:SetTexCoord (10/64, 54/64, 10/64, 54/64)
	highlight:SetTexture ([[Interface\Store\store-item-highlight]])
	
	local criteriaHighlight = button:CreateTexture (nil, "highlight")
	criteriaHighlight:SetPoint ("bottomleft", button, "bottomleft", -2, 0)
	criteriaHighlight:SetSize (23*.4, 37*.4)
	criteriaHighlight:SetAlpha (.8)
	criteriaHighlight:SetTexture ([[Interface\AdventureMap\AdventureMap]])
	criteriaHighlight:SetTexCoord (901/1024, 924/1024, 251/1024, 288/1024)
	
	trackingGlowBorder:SetDrawLayer ("BACKGROUND", -5)
	--trackingGlowBorder:SetDrawLayer ("overlay", 7)
	background:SetDrawLayer ("background", -3)
	texture:SetDrawLayer ("background", -2)
	commonBorder:SetDrawLayer ("border", 1)
	rareBorder:SetDrawLayer ("border", 1)
	epicBorder:SetDrawLayer ("border", 1)
	amountBackground:SetDrawLayer ("overlay", 0)
	amountText:SetDrawLayer ("overlay", 1)
	criteriaIndicatorGlow:SetDrawLayer ("OVERLAY", 1)
	criteriaIndicator:SetDrawLayer ("OVERLAY", 2)
	timeBlip:SetDrawLayer ("overlay", 2)
	highlight:SetDrawLayer ("highlight", 1)
	criteriaHighlight:SetDrawLayer ("highlight", 2)
	
	button.background = background
	button.texture = texture
	button.commonBorder = commonBorder
	button.rareBorder = rareBorder
	button.epicBorder = epicBorder
	button.trackingGlowBorder = trackingGlowBorder
	
	button.timeBlip = timeBlip
	button.amountText = amountText
	button.amountBackground = amountBackground
	button.criteriaIndicator = criteriaIndicator
	button.criteriaHighlight = criteriaHighlight
	button.criteriaIndicatorGlow = criteriaIndicatorGlow
	button.isWorldMapWidget = true
	
	return button
end

--cria os widgets do world map
--esta criando logo na leitura do addon
for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
	local mapName = GetMapNameByID (mapId)
	local line, blip, factionFrame = create_worldmap_line (configTable.worldMapLocation.lineWidth, mapId)
	if (WorldQuestTracker.InWindowMode) then
		line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocation.x, configTable.worldMapLocation.y)
		line:SetWidth (configTable.worldMapLocation.lineWidth)
	else
		line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocationMax.x, configTable.worldMapLocationMax.y)
		line:SetWidth (configTable.worldMapLocationMax.lineWidth)
	end
	blip:SetPoint ("center", line, configTable.bipAnchor.side, configTable.bipAnchor.x, configTable.bipAnchor.y)
	factionFrame:SetPoint (configTable.factionAnchor.mySide, blip, configTable.factionAnchor.anchorSide, configTable.factionAnchor.x, configTable.factionAnchor.y)
	configTable.factionFrame = factionFrame
	configTable.line = line
	
	local x = 2
	for i = 1, 20 do
		local button = create_worldmap_square (mapName, i)
		button:SetPoint (configTable.squarePoints.mySide, line, configTable.squarePoints.anchorSide, x*configTable.squarePoints.xDirection, configTable.squarePoints.y)
		x = x + WORLDMAP_SQUARE_SIZE + 1
		tinsert (configTable.widgets, button)
	end
end

--agenda uma atualização nos widgets do world map caso os dados das quests estejam indisponíveis
local do_worldmap_update = function()
	if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
	else
		if (WorldQuestTracker.ScheduledWorldUpdate and not WorldQuestTracker.ScheduledWorldUpdate._cancelled) then
			WorldQuestTracker.ScheduledWorldUpdate:Cancel()
		end
	end
end
function WorldQuestTracker.ScheduleWorldMapUpdate (seconds)
	if (WorldQuestTracker.ScheduledWorldUpdate and not WorldQuestTracker.ScheduledWorldUpdate._cancelled) then
		WorldQuestTracker.ScheduledWorldUpdate:Cancel()
	end
	WorldQuestTracker.ScheduledWorldUpdate = C_Timer.NewTimer (seconds or 1, do_worldmap_update)
end

--faz a atualização dos widgets no world map
function WorldQuestTracker.UpdateWorldQuestsOnWorldMap (noCache, showFade)
	
	--do not update more then once per tick
	if (WorldQuestTracker.LastUpdate+0.017 > GetTime()) then
		return
	elseif (UnitLevel ("player") < 110 or not IsQuestFlaggedCompleted (43341)) then
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
		return
	end
	
	WorldQuestTracker.LastUpdate = GetTime()
	wipe (factionAmountForEachMap)
	
	--mostrar os widgets extras
	for _, widget in ipairs (extra_widgets) do
		widget:Show()
	end
	
	local needAnotherUpdate = false
	local availableQuests = 0

	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		local taskInfo = GetQuestsForPlayerByMapID (mapId)
		local taskIconIndex = 1
		local widgets = configTable.widgets
		
		if (taskInfo and #taskInfo > 0) then
			availableQuests = availableQuests + #taskInfo
			
			for i, info  in ipairs (taskInfo) do
				local questID = info.questId
				if (HaveQuestData (questID)) then
					local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
					if (isWorldQuest) then
					
						C_TaskQuest.RequestPreloadRewardData (questID)

						--info
						local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
						--tempo restante
						local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
						
						if (timeLeft and timeLeft > 0) then
							local isCriteria = WorldMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty (questID)
							if (isCriteria) then
								factionAmountForEachMap [mapId] = (factionAmountForEachMap [mapId] or 0) + 1
							end
						
							local widget = widgets [taskIconIndex]
							if (widget) then
								if (widget.lastQuestID == questID and not noCache) then
									--precisa apenas atualizar o tempo
									
									WorldQuestTracker.SetTimeBlipColor (widget.timeBlip, timeLeft)
									widget.questID = questID
									widget.mapID = mapId
									widget:Show()
									if (widget.texture:GetTexture() == nil) then
										WorldQuestTracker.ScheduleWorldMapUpdate()
									end
									
									if (isCriteria) then
										widget.criteriaIndicator:Show()
										widget.criteriaHighlight:Show()
										widget.criteriaIndicatorGlow:Show()
									else
										widget.criteriaIndicator:Hide()
										widget.criteriaHighlight:Hide()
										widget.criteriaIndicatorGlow:Hide()
									end
									
									if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
										widget.trackingGlowBorder:Show()
									else
										widget.trackingGlowBorder:Hide()
									end
									
								else
									--faz uma atualização total do bloco
									
									--gold
									local gold, goldFormated = WorldQuestTracker.GetQuestReward_Gold (questID)
									--class hall resource
									local rewardName, rewardTexture, numRewardItems = WorldQuestTracker.GetQuestReward_Resource (questID)
									--item
									local itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker.GetQuestReward_Item (questID)
									
									--atualiza o widget
									widget.isArtifact = nil
									widget.questID = questID
									widget.lastQuestID = questID
									widget.worldQuest = true
									widget.numObjectives = info.numObjectives
									widget.amountText:SetText ("")
									widget.amountBackground:Hide()
									widget.mapID = mapId
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
									
									if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
										widget.trackingGlowBorder:Show()
									else
										widget.trackingGlowBorder:Hide()
									end
									
									WorldQuestTracker.SetTimeBlipColor (widget.timeBlip, timeLeft)
									
									if (worldQuestType == LE_QUEST_TAG_TYPE_PVP) then
										widget.questTypeBlip:Show()
										widget.questTypeBlip:SetTexture ([[Interface\PVPFrame\Icon-Combat]])
										widget.questTypeBlip:SetTexCoord (0, 1, 0, 1)
										widget.questTypeBlip:SetAlpha (.74)
										
									elseif (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
										widget.questTypeBlip:Show()
										widget.questTypeBlip:SetTexture ([[Interface\MINIMAP\ObjectIconsAtlas]])
										widget.questTypeBlip:SetTexCoord (172/512, 201/512, 273/512, 301/512)
										widget.questTypeBlip:SetAlpha (.85)
									else
										widget.questTypeBlip:Hide()
									end
									
									local okey = false
									
									if (gold > 0) then
										local texture, coords = WorldQuestTracker.GetGoldIcon()
										widget.texture:SetTexture (texture)
										widget.amountText:SetText (goldFormated)
										widget.amountBackground:Show()
										
										widget.IconTexture = texture
										widget.IconText = goldFormated
										widget.QuestType = QUESTTYPE_GOLD
										okey = true
									end
									if (rewardName) then
										widget.texture:SetTexture (rewardTexture)
										--widget.texture:SetTexCoord (0, 1, 0, 1)
										widget.amountText:SetText (numRewardItems)
										widget.amountBackground:Show()
										
										widget.IconTexture = rewardTexture
										widget.IconText = numRewardItems
										widget.QuestType = QUESTTYPE_RESOURCE
										okey = true
									
									elseif (itemName) then
										if (isArtifact) then
											local artifactIcon = WorldQuestTracker.GetArtifactPowerIcon (artifactPower)
											widget.texture:SetTexture (artifactIcon)
											widget.isArtifact = true
											widget.amountText:SetText (artifactPower)
											widget.amountBackground:Show()
											
											widget.IconTexture = artifactIcon .. "_round"
											widget.IconText = artifactPower
											widget.QuestType = QUESTTYPE_ARTIFACTPOWER
										else
											widget.texture:SetTexture (itemTexture)
											--widget.texture:SetTexCoord (0, 1, 0, 1)
											if (itemLevel > 600 and itemLevel < 780) then
												itemLevel = 810
											end
											
											widget.amountText:SetText ((isStackable and quantity and quantity >= 1 and quantity or false) or (itemLevel and itemLevel > 5 and itemLevel .. "+") or "")

											if (widget.amountText:GetText() and widget.amountText:GetText() ~= "") then
												widget.amountBackground:Show()
											else
												widget.amountBackground:Hide()
											end
											
											widget.IconTexture = itemTexture
											widget.IconText = widget.amountText:GetText()
											widget.QuestType = QUESTTYPE_ITEM
										end
										okey = true
									end
									if (not okey) then
										needAnotherUpdate = true
									end
								end
							end
							
							widget:Show()
							WorldQuestTracker.UpdateBorder (widget, rarity, worldQuestType)
							taskIconIndex = taskIconIndex + 1
						end
					end
				else
					--nao tem os dados da quest ainda
					needAnotherUpdate = true
				end
			end
			
			for i = taskIconIndex, 20 do
				widgets[i]:Hide()
			end
		else
			if (not taskInfo) then
				--não tem task info
				needAnotherUpdate = true
			elseif (#taskInfo == 0) then
				--nao tem os dados do mapa
				needAnotherUpdate = true
			end
		end
		
		--quantidade de quest para a faccao
		configTable.factionFrame.amount = factionAmountForEachMap [mapId]
	end
	
	if (needAnotherUpdate) then
		if (WorldMapFrame:IsShown()) then
			WorldQuestTracker.ScheduleWorldMapUpdate (1.5)
		end
	end
	if (showFade) then
		worldFramePOIs.fadeInAnimation:Play()
	end
	if (availableQuests == 0 and (WorldQuestTracker.InitAt or 0) + 10 > GetTime()) then
		WorldQuestTracker.ScheduleWorldMapUpdate()
	end
	
	--factions
	local BountyBoard = WorldMapFrame.UIElementsFrame.BountyBoard
	local selectedBountyIndex = BountyBoard.selectedBountyIndex
	for _, factionFrame in ipairs (faction_frames) do
		factionFrame:SetAlpha (.65)
		factionFrame.icon:SetDesaturated (true)
		factionFrame.icon:SetVertexColor (.5, .5, .5)
		factionFrame.background:Hide()
		factionFrame.highlight:Hide()
		factionFrame.enabled = false
	end
--	for tab, _ in pairs (BountyBoard.bountyTabPool.activeObjects) do
	for bountyIndex, bounty in ipairs (BountyBoard.bounties) do
		if (bountyIndex == selectedBountyIndex) then
			for _, factionFrame in ipairs (faction_frames) do
				factionFrame.icon:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
				factionFrame.icon:SetTexture (bounty.icon)
				factionFrame.text:SetText (factionFrame.amount)
				
				if (factionFrame.amount and factionFrame.amount > 0) then
					factionFrame:SetAlpha (1)
					factionFrame.icon:SetDesaturated (false)
					factionFrame.icon:SetVertexColor (1, 1, 1)
					factionFrame.background:Show()
					factionFrame.highlight:Show()
					factionFrame.enabled = true
				else
					factionFrame:SetAlpha (.65)
					factionFrame.icon:SetDesaturated (true)
					factionFrame.icon:SetVertexColor (.5, .5, .5)
					factionFrame.background:Hide()
					factionFrame.highlight:Hide()
					factionFrame.enabled = false
				end
			end
		end
	end
	
	C_Timer.After (0.5, WorldQuestTracker.UpdateFactionAlpha)
	
	if (WorldMapFrame_InWindowedMode() and not WorldQuestTracker.InWindowMode) then
		for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
			configTable.line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocation.x, configTable.worldMapLocation.y)
			configTable.line:SetWidth (configTable.worldMapLocation.lineWidth)
		end
		
		WorldQuestTracker.InWindowMode = true
	elseif (not WorldMapFrame_InWindowedMode() and WorldQuestTracker.InWindowMode) then
		
		for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
			configTable.line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocationMax.x, configTable.worldMapLocationMax.y)
			configTable.line:SetWidth (configTable.worldMapLocationMax.lineWidth)
		end
		
		WorldQuestTracker.InWindowMode = false
	end
	
	WorldQuestTracker.HideZoneWidgets()
	
end

--quando clicar no botão de por o world map em fullscreen ou window mode, reajustar a posição dos widgets
WorldMapFrameSizeDownButton:HookScript ("OnClick", function() --window mode
	if (WorldQuestTracker.UpdateWorldQuestsOnWorldMap) then
		if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
		end
	end
end)
WorldMapFrameSizeUpButton:HookScript ("OnClick", function() --full screen
	if (WorldQuestTracker.UpdateWorldQuestsOnWorldMap) then
		if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
		end
	end
end)

--atualiza a quantidade de alpha nos widgets que mostram quantas quests ha para a facção
function WorldQuestTracker.UpdateFactionAlpha()
	for _, factionFrame in ipairs (faction_frames) do
		if (factionFrame.enabled) then
			factionFrame:SetAlpha (1)
		else
			factionFrame:SetAlpha (.65)
		end
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> faction bounty

--coloca a quantidade de quests completas para cada facção em cima do icone da facção
function WorldQuestTracker.SetBountyAmountCompleted (self, numCompleted, numTotal)
	if (not self.objectiveCompletedText) then
		self.objectiveCompletedText = self:CreateFontString (nil, "overlay", "GameFontNormal")
		self.objectiveCompletedText:SetPoint ("bottom", self, "top", 1, 0)
		self.objectiveCompletedBackground = self:CreateTexture (nil, "background")
		self.objectiveCompletedBackground:SetPoint ("bottom", self, "top", 0, -1)
		self.objectiveCompletedBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
		self.objectiveCompletedBackground:SetTexCoord (12/512, 74/512, 251/512, 281/512)
		self.objectiveCompletedBackground:SetSize (42, 12)
	end
	if (numCompleted) then
		self.objectiveCompletedText:SetText (numCompleted .. "/" .. numTotal)
		self.objectiveCompletedBackground:SetAlpha (.4)
	else
		self.objectiveCompletedText:SetText ("")
		self.objectiveCompletedBackground:SetAlpha (0)
	end
end

--quando selecionar uma facção, atualizar todas as quests no world map para que seja atualiza a quiantidade de quests que ha em cada mapa para esta facçao
hooksecurefunc (WorldMapFrame.UIElementsFrame.BountyBoard, "SetSelectedBountyIndex", function (self)
	if (WorldMapFrame.mapID == 1007) then
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, false)
	end
end)

hooksecurefunc (WorldMapFrame.UIElementsFrame.BountyBoard, "AnchorBountyTab", function (self, tab)
	local bountyData = self.bounties [tab.bountyIndex]
	if (bountyData) then
		local numCompleted, numTotal = self:CalculateBountySubObjectives (bountyData)
		if (numCompleted and numTotal) then
			WorldQuestTracker.SetBountyAmountCompleted (tab, numCompleted, numTotal)
		end
	else
		WorldQuestTracker.SetBountyAmountCompleted (tab, false)
	end
end)

-- doq dow