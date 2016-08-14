
--details! framework
local DF = _G ["DetailsFramework"]
if (not DF) then
	print ("|cFFFFAA00World Quest Tracker: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

local L = LibStub ("AceLocale-3.0"):GetLocale ("WorldQuestTrackerAddon", true)
if (not L) then
	print ("|cFFFFAA00World Quest Tracker|r: Reopen your client to finish updating the addon.|r")
	print ("|cFFFFAA00World Quest Tracker|r: Reopen your client to finish updating the addon.|r")
	print ("|cFFFFAA00World Quest Tracker|r: Reopen your client to finish updating the addon.|r")
	return
end

if (true) then
	--return - nah, not today
end

do
	local color = OBJECTIVE_TRACKER_COLOR ["Header"]
	DF:NewColor ("WQT_QUESTTITLE_INMAP", color.r, color.g, color.b, .8)
	DF:NewColor ("WQT_QUESTTITLE_OUTMAP", 1, .8, .2, .7)
	DF:NewColor ("WQT_QUESTZONE_INMAP", 1, 1, 1, 1)
	DF:NewColor ("WQT_QUESTZONE_OUTMAP", 1, 1, 1, .7)
	DF:NewColor ("WQT_ORANGE_ON_ENTER", 1, 0.847059, 0, 1)
	
	DF:InstallTemplate ("font", "WQT_SUMMARY_TITLE", {color = "orange", size = 12, font = "Friz Quadrata TT"})
end

local GameCooltip = GameCooltip2
local Saturate = Saturate
local floor = floor
local ceil = ceil
local ipairs = ipairs
local SecondsToTime = SecondsToTime
local GetItemInfo = GetItemInfo
local p = math.pi/2
local pi = math.pi
local pipi = math.pi*2
local GetPlayerFacing = GetPlayerFacing
local GetPlayerMapPosition = GetPlayerMapPosition
local GetCurrentMapZone = GetCurrentMapZone
local GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID
local HaveQuestData = HaveQuestData
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

local MapRangeClamped = DF.MapRangeClamped
local FindLookAtRotation = DF.FindLookAtRotation
local GetDistance_Point = DF.GetDistance_Point

local WQT_QUESTTYPE_MAX = 9
local WQT_QUESTTYPE_GOLD = "gold"
local WQT_QUESTTYPE_RESOURCE = "resource"
local WQT_QUESTTYPE_APOWER = "apower"
local WQT_QUESTTYPE_EQUIPMENT = "equipment"
local WQT_QUESTTYPE_TRADE = "trade"
local WQT_QUESTTYPE_DUNGEON = "dungeon"
local WQT_QUESTTYPE_PROFESSION = "profession"
local WQT_QUESTTYPE_PVP = "pvp"
local WQT_QUESTTYPE_PETBATTLE = "petbattle"

local FILTER_TO_QUEST_TYPE ={
	pet_battles = WQT_QUESTTYPE_PETBATTLE,
	pvp = WQT_QUESTTYPE_PVP,
	profession = WQT_QUESTTYPE_PROFESSION,
	dungeon = WQT_QUESTTYPE_DUNGEON,
	gold = WQT_QUESTTYPE_GOLD,
	artifact_power = WQT_QUESTTYPE_APOWER,
	garrison_resource = WQT_QUESTTYPE_RESOURCE,
	equipment = WQT_QUESTTYPE_EQUIPMENT,
	trade_skill = WQT_QUESTTYPE_TRADE,
}
local QUEST_TYPE_TO_FILTER = {
	[WQT_QUESTTYPE_GOLD] = "gold",
	[WQT_QUESTTYPE_RESOURCE] = "garrison_resource",
	[WQT_QUESTTYPE_APOWER] = "artifact_power",
	[WQT_QUESTTYPE_EQUIPMENT] = "equipment",
	[WQT_QUESTTYPE_TRADE] = "trade_skill",
	[WQT_QUESTTYPE_DUNGEON] = "dungeon",
	[WQT_QUESTTYPE_PROFESSION] = "profession",
	[WQT_QUESTTYPE_PVP] = "pvp",
	[WQT_QUESTTYPE_PETBATTLE] = "pet_battles",
}

local WQT_QUERYTYPE_REWARD = "reward"
local WQT_QUERYTYPE_QUEST = "quest"
local WQT_QUERYTYPE_PERIOD = "period"
local WQT_QUERYDB_ACCOUNT = "global"
local WQT_QUERYDB_LOCAL = "character"
local WQT_REWARD_RESOURCE = "resource"
local WQT_REWARD_GOLD = "gold"
local WQT_REWARD_APOWER = "artifact"
local WQT_QUESTS_TOTAL = "total"
local WQT_QUESTS_PERIOD = "quest"
local WQT_DATE_TODAY = 1
local WQT_DATE_YESTERDAY = 2
local WQT_DATE_1WEEK = 3
local WQT_DATE_2WEEK = 4
local WQT_DATE_MONTH = 5

--219978
--world of quets IsQuestFlaggedCompleted (WORLD_QUESTS_AVAILABLE_QUEST_ID) - colocar junto com o level do personagem

local _
local default_config = {
	profile = {
		filters = {
			pet_battles = true,
			pvp = true,
			profession = true,
			dungeon = true,
			gold = true,
			artifact_power = true,
			garrison_resource = true,
			equipment = true,
			trade_skill = true,
		},
		filter_always_show_faction_objectives = true,
		sort_order = {
			[WQT_QUESTTYPE_TRADE] = 9,
			[WQT_QUESTTYPE_APOWER] = 8,
			[WQT_QUESTTYPE_GOLD] = 6,
			[WQT_QUESTTYPE_RESOURCE] = 7,
			[WQT_QUESTTYPE_EQUIPMENT] = 5,
			[WQT_QUESTTYPE_DUNGEON] = 4,
			[WQT_QUESTTYPE_PROFESSION] = 3,
			[WQT_QUESTTYPE_PVP] = 2,
			[WQT_QUESTTYPE_PETBATTLE] = 1,
		},
		quests_tracked = {},
		quests_all_characters = {},
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
		map_lock = false,
		enable_doubletap = false,
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
		show_yards_distance = true,
		player_names = {},
	},
}

local azsuna_mapId = 1015
local highmountain_mapId = 1024
local stormheim_mapId = 1017
local suramar_mapId = 1033
local valsharah_mapId = 1018
local eoa_mapId = 1096

local is_broken_isles_map = {
	[azsuna_mapId] = true,
	[highmountain_mapId] = true,
	[stormheim_mapId] = true,
	[suramar_mapId] = true,
	[valsharah_mapId] = true,
	[eoa_mapId] = true,
}

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

local FILTER_TYPE_PET_BATTLES = "pet_battles"
local FILTER_TYPE_PVP = "pvp"
local FILTER_TYPE_PROFESSION = "profession"
local FILTER_TYPE_DUNGEON = "dungeon"
local FILTER_TYPE_GOLD = "gold"
local FILTER_TYPE_ARTIFACT_POWER = "artifact_power"
local FILTER_TYPE_GARRISON_RESOURCE = "garrison_resource"
local FILTER_TYPE_EQUIPMENT = "equipment"
local FILTER_TYPE_TRADESKILL = "trade_skill"

local WQT_QUEST_NAMES_AND_ICONS = {
	[WQT_QUESTTYPE_APOWER] = {name = L["S_QUESTTYPE_ARTIFACTPOWER"], icon = [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_red_roundT]], coords = {0, 1, 0, 1}},
	[WQT_QUESTTYPE_GOLD] = {name = L["S_QUESTTYPE_GOLD"], icon = [[Interface\GossipFrame\auctioneerGossipIcon]], coords = {0, 1, 0, 1}},
	[WQT_QUESTTYPE_RESOURCE] = {name = L["S_QUESTTYPE_RESOURCE"], icon = [[Interface\AddOns\WorldQuestTracker\media\resource_iconT]], coords = {0, 1, 0, 1}},
	[WQT_QUESTTYPE_EQUIPMENT] = {name = L["S_QUESTTYPE_EQUIPMENT"], icon = [[Interface\PaperDollInfoFrame\UI-EquipmentManager-Toggle]], coords = {0, 1, 0, 1}},
	--[WQT_QUESTTYPE_EQUIPMENT] = {name = "Equipment", icon = [[Interface\PaperDollInfoFrame\PaperDollSidebarTabs]], coords = {4/64, 32/64, 122/256, 155/256}},
	[WQT_QUESTTYPE_DUNGEON] = {name = L["S_QUESTTYPE_DUNGEON"], icon = [[Interface\TARGETINGFRAME\Nameplates]], coords = {41/256, 0/256, 42/128, 80/128}},
	[WQT_QUESTTYPE_PROFESSION] = {name = L["S_QUESTTYPE_PROFESSION"], icon = [[Interface\MINIMAP\TRACKING\Profession]], coords = {2/32, 30/32, 2/32, 30/32}},
	--[WQT_QUESTTYPE_PROFESSION] = {name = "Profession", icon = [[Interface\Garrison\MobileAppIcons]], coords = {256/1024, 384/1024, 0/1024, 128/1024}},
	--[WQT_QUESTTYPE_PVP] = {name = "PvP", icon = [[Interface\PVPFrame\Icon-Combat]], coords = {0, 1, 0, 1}},
	[WQT_QUESTTYPE_PVP] = {name = L["S_QUESTTYPE_PVP"], icon = [[Interface\QUESTFRAME\QuestTypeIcons]], coords = {37/128, 53/128, 19/64, 36/64}},
	[WQT_QUESTTYPE_PETBATTLE] = {name = L["S_QUESTTYPE_PETBATTLE"], icon = [[Interface\MINIMAP\ObjectIconsAtlas]], coords = {172/512, 201/512, 270/512, 301/512}},
	[WQT_QUESTTYPE_TRADE] = {name = L["S_QUESTTYPE_TRADESKILL"], icon = [[Interface\ICONS\INV_Blood of Sargeras]], coords = {5/64, 59/64, 5/64, 59/64}},
}

local WQT_GENERAL_STRINGS_AND_ICONS = {
	["criteria"] = {name = "criteria", icon = [[Interface\AdventureMap\AdventureMap]], coords = {901/1024, 924/1024, 251/1024, 288/1024}}
}

local QUEST_COMMENTS = {
	[42275] = {help = "'Dimensional Anchors' are green crystals on the second floor of the central build."}, --azsuna - not on my watch
	[43963] = {help = "Kill and loot mobs around the quest location."},
	[42108] = {help = "Use the extra button near friendly ghosty npcs."},
	[42080] = {help = "Select eagles and use the extra button. Click on sheeps outside the town."},
	[41701] = {help = "Kill fish inside the water. Walk on outlined garbage."},
}

local calcPerformance = CreateFrame ("frame")
calcPerformance.timeTable = {}
local measurePerformance = function (self, deltaTime)
	if (self.DumpTime) then
		self.DumpTime = self.DumpTime + 1
		if (self.DumpTime == 8) then
			for i = 1, #self.timeTable do
				local v = self.timeTable [i]
				if (v > .02) then
					print ("Load Time:", v, "seconds.")
				end
			end
			self.DumpTime = nil
		end
	end
	self.LatestTick = GetTime()
	tinsert (self.timeTable, 1, deltaTime)
	tremove (self.timeTable, 15)
end
--calcPerformance:SetScript ("OnUpdate", measurePerformance) -- remove this comment to enable the load time display

local TQueue = CreateFrame ("frame")
TQueue.queue = {}
local throttle = function (self, deltaTime)
	for i = 1, 10 do
		local t = tremove (self.queue, 1)
		if (t) then
			local widget, file, coords, color = unpack (t)
			widget:Show()
			if (widget:GetObjectType() == "texture") then
				if (file) then
					widget:SetTexture (file)
				end
				if (coords) then
					widget:SetTexCoord (unpack (coords))
				end
				if (color) then
					widget:SetVertexColor (unpack (color))
				end
			else
				if (widget.fadeInAnimation) then
					--widget.fadeInAnimation:Play()
				end
			end
		else
			TQueue:SetScript ("OnUpdate", nil)
		end
	end
end
function TQueue:AddToQueue (texture, file, coords, color)
	tinsert (TQueue.queue, {texture, file, coords, color})
	if (not TQueue.Running) then
		TQueue:SetScript ("OnUpdate", throttle)
	end
end

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
WorldQuestTracker.JustAddedToTracker = {}
WorldQuestTracker.CurrentMapID = 0
WorldQuestTracker.LastWorldMapClick = 0
WorldQuestTracker.MapSeason = 0
WorldQuestTracker.MapOpenedAt = 0
WorldQuestTracker.QueuedRefresh = 1
WorldQuestTracker.WorldQuestButton_Click = 0

--debug
function WorldQuestTracker.DumpTrackingList()
	local t = WorldQuestTracker.table.dump (WorldQuestTracker.QuestTrackList)
	print (t)
end

hooksecurefunc ("TaskPOI_OnEnter", function (self)
	--WorldMapTooltip:AddLine ("quest ID: " .. self.questID)
	--print (self.questID)
end)
--enddebug

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

local WorldWidgetPool = {}
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
	
	WorldQuestTracker.CreateLoadingIcon()
	
	WQTrackerDBChr = WQTrackerDBChr or {}
	WorldQuestTracker.dbChr = WQTrackerDBChr
	WorldQuestTracker.dbChr.ActiveQuests = WorldQuestTracker.dbChr.ActiveQuests or {}
	
	C_Timer.After (2, function()
		if (WorldQuestTracker.db:GetCurrentProfile() ~= "Default") then
			WorldQuestTracker.db:SetProfile ("Default")
		end
	end)
	
	function WorldQuestTracker:CleanUpJustBeforeGoodbye()
		WorldQuestTracker.AllCharactersQuests_CleanUp()
	end
	WorldQuestTracker.db.RegisterCallback (WorldQuestTracker, "OnDatabaseShutdown", "CleanUpJustBeforeGoodbye") --more info at https://www.youtube.com/watch?v=GXFnT4YJLQo
	
	local save_player_name = function()
		local guid = UnitGUID ("player")
		local name = UnitName ("player")
		local realm = GetRealmName()
		if (guid and name and name ~= "" and realm and realm ~= "") then
			local playerTable = WorldQuestTracker.db.profile.player_names [guid]
			if (not playerTable) then
				playerTable = {}
				WorldQuestTracker.db.profile.player_names [guid] = playerTable
			end
			playerTable.name = name
			playerTable.realm = realm
			playerTable.class = playerTable.class or select (2, UnitClass ("player"))
		end
	end
	C_Timer.After (3, save_player_name)
	C_Timer.After (10, save_player_name)
	
	local canLoad = IsQuestFlaggedCompleted (WORLD_QUESTS_AVAILABLE_QUEST_ID)
	
	local re_ZONE_CHANGED_NEW_AREA = function()
		WorldQuestTracker:ZONE_CHANGED_NEW_AREA()
	end
	function WorldQuestTracker:ZONE_CHANGED_NEW_AREA()
		if (IsInInstance()) then
			WorldQuestTracker:FullTrackerUpdate()
		else
			WorldQuestTracker:FullTrackerUpdate()
			
			if (WorldMapFrame:IsShown()) then
				return WorldQuestTracker:WaitUntilWorldMapIsClose()
			else
				C_Timer.After (.5, WorldQuestTracker.UpdateCurrentStandingZone)
			end
		end
	end
	
	-- ~reward ~questcompleted
	local oneday = 60*60*24
	local days_amount = {
		[WQT_DATE_1WEEK] = 8,
		[WQT_DATE_2WEEK] = 15,
		[WQT_DATE_MONTH] = 30,
	}
	
	function WorldQuestTracker.GetDateString (t)
		if (t == WQT_DATE_TODAY) then
			return date ("%y%m%d")
		elseif (t == WQT_DATE_YESTERDAY) then
			return date ("%y%m%d", time() - oneday)
		elseif (t == WQT_DATE_1WEEK or t == WQT_DATE_2WEEK or t == WQT_DATE_MONTH) then
			local days = days_amount [t]
			local result = {}
			for i = 1, days do
				tinsert (result, date ("%y%m%d", time() - (oneday * (i-1) )))
			end
			return result
		else
			return t
		end
	end
	
	function WorldQuestTracker.GetCharInfo (guid)
		local t = WorldQuestTracker.db.profile.player_names [guid]
		if (t) then
			return t.name, t.realm, t.class
		else
			return "Unknown", "Unknown", "PRIEST"
		end
	end
	
	function WorldQuestTracker.QueryHistory (queryType, dbLevel, arg1, arg2, arg3)
		local db = WorldQuestTracker.db.profile.history
		db = db [queryType]
		db = db [dbLevel]
		
		if (dbLevel == WQT_QUERYDB_LOCAL) then
			db = db [UnitGUID ("player")]
			if (not db) then
				return
			end
		end
		
		if (not arg1) then
			return db
		end
		
		if (queryType == WQT_QUERYTYPE_REWARD) then
			return db [arg1] --arg1 = the reward type (gold, resource, artifact)
			
		elseif (queryType == WQT_QUERYTYPE_QUEST) then
			return db [arg1] --arg1 = the questID
			
		elseif (queryType == WQT_QUERYTYPE_PERIOD) then
			
			local dateString = WorldQuestTracker.GetDateString (arg1)
			
			if (type (dateString) == "table") then --mais de 1 dia
				--quer saber da some total ou quer dia a dia para fazer um gráfico
				local result = {}
				local total = 0
				local dayTable = dateString

				for i = 1, #dayTable do --table com várias strings representando dias
					local day = db [dayTable [i]]
					if (day) then
						if (arg2) then
							total = total + (day [arg2] or 0)
						else
							tinsert (result, {["day"] = dayTable [i], ["table"] = day})
						end
					end
				end
				
				if (arg2) then
					return total
				else
					return result
				end
				
			else --um unico dia
				if (arg2) then --pediu apenas 1 reward
					db = db [dateString] --tabela do dia
					if (db) then
						return db [arg2] --quantidade de recursos
					end
					return
				end
				return db [dateString] --arg1 = data0 / retorna a tabela do dia com todos os rewards
			end
		end
	
	end
	
	-- ~completed ~questdone
	function WorldQuestTracker:QUEST_TURNED_IN (event, questID, XP, gold)

		--> Court of Farondis 42420
		--> The Dreamweavers 42170
		--print (questID)
	
		if (QuestMapFrame_IsQuestWorldQuest (questID)) then
			--print (event, questID, XP, gold)
			--QUEST_TURNED_IN 44300 0 772000
			-- QINFO: 0 nil nil Petrified Axe Haft true 370
			
			WorldQuestTracker.AllCharactersQuests_Remove (questID)

			if (QuestMapFrame_IsQuestWorldQuest (questID)) then --wait, is this inception?
				local title, questType, texture, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, selected, isSpellTarget, timeLeft, isCriteria, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker:GetQuestFullInfo (questID)
				
				--print (title, questType, texture, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex)
				--Retake the Skyhorn 8 Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_redT_round 1828 109 World Quest 3 1 false nil				
				
				--print ("QINFO:", goldFormated, rewardName, numRewardItems, itemName, isArtifact, artifactPower)
				
				local questHistory = WorldQuestTracker.db.profile.history
				
				local guid = UnitGUID ("player")
				local today = date ("%y%m%d") -- YYMMDD
				
				local itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker.GetQuestReward_Item (questID)
				--print ("WQT", itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable)
				--WQT Blood of Sargeras 1417744 110 1 3 true 124124 false 0 true
				
				--quanto de gold recursos e poder de artefato ganho na conta e no personagem (é o total)
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
					
					--trade skill - blood of sargeras
					if (itemID == 124124) then
						_global ["blood"] = (_global ["blood"] or 0) + quantity
						_local ["blood"] = (_local ["blood"] or 0) + quantity
					end
					
					--professions
					--print ("itemID:", itemID)
					if (tradeskillLineIndex) then
						--print ("eh profissao 1", tradeskillLineIndex)
						local tradeskillLineID = tradeskillLineIndex and select (7, GetProfessionInfo(tradeskillLineIndex))
						if (tradeskillLineID) then
							--print ("eh profissao 2", tradeskillLineID)
							if (itemID) then
								--print ("eh profissao 3", itemID)
								_global ["profession"] = _global ["profession"] or {}
								_local ["profession"] = _local ["profession"] or {}
								_global ["profession"] [itemID] = (_global ["profession"] [itemID] or 0) + 1
								_local ["profession"] [itemID] = (_local ["profession"] [itemID] or 0) + 1
								--print ("local global 3", _local ["profession"] [itemID], _global ["profession"] [itemID])
							end
						end
					end
				
				--quais quest ja foram completadas e quantas vezes
				local questDoneHistory = questHistory.quest
					local _global = questDoneHistory.global
					local _local = questDoneHistory.character [guid]
					if (not _local) then
						_local = {}
						questDoneHistory.character [guid] = _local
					end
					_global [questID] = (_global [questID] or 0) + 1
					_local [questID] = (_local [questID] or 0) + 1
					_global ["total"] = (_global ["total"] or 0) + 1
					_local ["total"] = (_local ["total"] or 0) + 1
				
				--estatísticas dia a dia
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
					
					_globalToday ["quest"] = (_globalToday ["quest"] or 0) + 1
					_localToday ["quest"] = (_localToday ["quest"] or 0) + 1
					
					if (itemID == 124124) then
						_globalToday ["blood"] = (_globalToday ["blood"] or 0) + quantity
						_localToday ["blood"] = (_localToday ["blood"] or 0) + quantity
					end
					
					if (tradeskillLineIndex) then
						--print ("eh profissao today 4", tradeskillLineIndex)
						local tradeskillLineID = tradeskillLineIndex and select (7, GetProfessionInfo (tradeskillLineIndex))
						if (tradeskillLineID) then
							--print ("eh profissao today 5", tradeskillLineID)
							if (itemID) then
								--print ("eh profissao today 6", itemID)
								_globalToday ["profession"] = _globalToday ["profession"] or {}
								_localToday ["profession"] = _localToday ["profession"] or {}
								_globalToday ["profession"] [itemID] = (_globalToday ["profession"] [itemID] or 0) + 1
								_localToday ["profession"] [itemID] = (_localToday ["profession"] [itemID] or 0) + 1
								--print ("local global today 6", _localToday ["profession"] [itemID], _globalToday ["profession"] [itemID])
							end
						end
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
	WorldQuestTracker:RegisterEvent ("PLAYER_STARTED_MOVING")
	WorldQuestTracker:RegisterEvent ("PLAYER_STOPPED_MOVING")
	
	C_Timer.After (.5, WorldQuestTracker.ZONE_CHANGED_NEW_AREA)
end

local onStartClickAnimation = function (self)
	self:GetParent():Show()
end
local onEndClickAnimation = function (self)
	self:GetParent():Hide()
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
		self.UpdateTooltip = TaskPOI_OnEnter
		TaskPOI_OnEnter (self)
	end
end
local questButton_OnLeave = function	(self)
	TaskPOI_OnLeave (self)
end

--ao clicar no botão de uma quest na zona ou no world map, colocar para trackear ela
local questButton_OnClick = function (self, button)
	WorldQuestTracker.OnQuestClicked (self, button)
	
	if (WorldQuestTracker.IsQuestBeingTracked (self.questID)) then
		if (self.onEndTrackAnimation:IsPlaying()) then
			self.onEndTrackAnimation:Stop()
		end
		self.onStartTrackAnimation:Play()
	else
		if (self.onStartTrackAnimation) then
			if (self.onStartTrackAnimation:IsPlaying()) then
				self.onStartTrackAnimation:Stop()
			end
			self.onEndTrackAnimation:Play()
		end
	end
	
	if (not self.IsWorldQuestButton) then
		WorldQuestTracker.WorldWidgets_NeedFullRefresh = true
	end
end

--verifica se pode mostrar os widgets de broken isles
function WorldQuestTracker.CanShowWorldMapWidgets (noFade)
	if (WorldMapFrame.mapID == 1007 or GetCurrentMapAreaID() == 1007) then
		if (noFade) then
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
		else
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
		end
	else
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
	end
end
--verifica se pode trocar o mapa e mostrar broken isles ao inves do mapa solicitado
function WorldQuestTracker.CanShowBrokenIsles()
	if (UnitLevel ("player") < 110) then
		return
	elseif (not IsQuestFlaggedCompleted (WORLD_QUESTS_AVAILABLE_QUEST_ID)) then
		return
	end
	return WorldQuestTracker.db.profile.enable_doubletap and not InCombatLockdown() and GetCurrentMapAreaID() ~= MAPID_BROKENISLES and (C_Garrison.IsPlayerInGarrison (LE_GARRISON_TYPE_7_0) or GetCurrentMapAreaID() == MAPID_DALARAN)
end

--todo: replace this with real animations
local zone_widget_rotation = 0
local animFrame, t = CreateFrame ("frame"), 0
local tickAnimation = function (self, deltaTime)
	t = t + deltaTime
	local squareAlphaAmount = Lerp (.7, .95, abs (sin (t*10)))
	local roundAlphaAmount = Lerp (.745, .90, abs (sin (t*30)))

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
			button.IsTrackingGlow:SetRotation (zone_widget_rotation)
		end
	end	
	zone_widget_rotation = (zone_widget_rotation + (deltaTime * 1.25)) % 360
end

function WorldQuestTracker.GetAllWorldQuests_Ids()
	local allQuests, dataUnavaliable = {}, false
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		local taskInfo = GetQuestsForPlayerByMapID (mapId)
		if (taskInfo and #taskInfo > 0) then
			for i, info  in ipairs (taskInfo) do
				local questID = info.questId
				if (HaveQuestData (questID)) then
					local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
					if (isWorldQuest) then
						allQuests [questID] = true
						C_TaskQuest.RequestPreloadRewardData (questID)
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

--http://richard.warburton.it
local function comma_value (n)
	if (not n) then return "0" end
	n = floor (n)
	if (n == 0) then
		return "0"
	end
	local left,num,right = string.match (n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> quest info

local anime_square = function (self, deltaTime)
	if (self.nextTick < 0) then
		self.animeIndex = self.animeIndex + 1
		if (self.animeIndex > 24) then
			self.animeIndex = 1
		end
		self.rareBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_blue_stopmotionT]])
		local line = math.ceil (self.animeIndex / 8)
		local x = ( self.animeIndex - ( (line-1) * 8 ) )  / 8
		self.rareBorder:SetTexCoord (x-0.125, x, 0.125 * (line-1), 0.125 * line)
		
		self.nextTick = .05
	else
		self.nextTick =  self.nextTick - deltaTime
	end
end

function WorldQuestTracker.GetBorderByQuestType (self, rarity, worldQuestType)
	if (worldQuestType == LE_QUEST_TAG_TYPE_PVP) then
		--return "border_zone_browT"
		return "border_zone_redT"
	elseif (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
		return "border_zone_greenT"
	elseif (worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION) then
		return "border_zone_browT"
	elseif (rarity == LE_WORLD_QUEST_QUALITY_COMMON) then
		return "border_zone_whiteT"
	elseif (rarity == LE_WORLD_QUEST_QUALITY_RARE) then
		return "border_zone_blueT"
	elseif (rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
		return "border_zone_pinkT"
	end
end

--atualiza a borda nas squares do world map e no mapa da zona ~border
function WorldQuestTracker.UpdateBorder (self, rarity, worldQuestType)
	if (self.isWorldMapWidget) then
		self.commonBorder:Hide()
		self.rareBorder:Hide()
		self.epicBorder:Hide()
		
		if (WorldQuestTracker.IsQuestBeingTracked (self.questID)) then
			self.borderAnimation:Show()
			--AutoCastShine_AutoCastStart (self.borderAnimation, 1, .7, 0)
			self.trackingBorder:Show()
		else
			self.borderAnimation:Hide()
			self.trackingBorder:Hide()
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
			
			else
				self.commonBorder:SetVertexColor (1, 1, 1)
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
		local borderTextureFile = WorldQuestTracker.GetBorderByQuestType (self, rarity, worldQuestType)
		self.circleBorder:Show()
		self.circleBorder:SetTexture ("Interface\\AddOns\\WorldQuestTracker\\media\\" .. borderTextureFile)
		
		if (rarity == LE_WORLD_QUEST_QUALITY_COMMON) then
			--self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag_commonT]])
			self.bgFlag:Hide()
			--self.glassTransparence:Hide()
			self.blackGradient:SetWidth (40)
			self.flagText:SetPoint ("top", self.bgFlag, "top", 0, -2)

		elseif (rarity == LE_WORLD_QUEST_QUALITY_RARE) then
			self.rareSerpent:Show()
			self.rareSerpent:SetSize (48, 52)
			--self.rareSerpent:SetAtlas ("worldquest-questmarker-dragon")
			self.rareSerpent:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragon_curveT]])
			self.rareGlow:Show()
			self.rareGlow:SetVertexColor (0, 0.36863, 0.74902)
			self.rareGlow:SetSize (48, 52)
			self.rareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragonT]])
			
			self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flagT]])
			self.bgFlag:Show()
			self.flagText:SetPoint ("top", self.bgFlag, "top", 0, -3)
			--self.glassTransparence:Show()
			
		elseif (rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
			self.rareSerpent:Show()
			self.rareSerpent:SetSize (48, 52)
			--self.rareSerpent:SetAtlas ("worldquest-questmarker-dragon")
			self.rareSerpent:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragon_curveT]])
			self.rareGlow:Show()
			self.rareGlow:SetVertexColor (0.58431, 0.07059, 0.78039)
			self.rareGlow:SetSize (48, 52)
			self.rareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragonT]])
			
			self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flagT]])
			self.bgFlag:Show()
			self.flagText:SetPoint ("top", self.bgFlag, "top", 0, -3)
			--self.glassTransparence:Show()
		end
		
	end
	
end

--pega o nome da zona
function WorldQuestTracker.GetZoneName (mapID)
	return GetMapNameByID (mapID)
end

function WorldQuestTracker.SetIconTexture (texture, file, coords, color)
	if (file) then
		texture:SetTexture (file)
	end
	if (coords) then
		texture:SetTexCoord (unpack (coords))
	end
	if (color) then
		texture:SetVertexColor (unpack (color))
	end
	
	--TQueue:AddToQueue (texture, file, coords, color)
end

--seta a cor do blip do tempo de acordo com o tempo restante da quert
function WorldQuestTracker.SetTimeBlipColor (self, timeLeft)
	if (timeLeft < 30) then
		self.timeBlipRed:Show()
		--TQueue:AddToQueue (self.timeBlipRed, false, false, false)
		--blip:SetTexture ([[Interface\COMMON\Indicator-Red]])
		--blip:SetVertexColor (1, 1, 1)
		--blip:SetAlpha (1)
	elseif (timeLeft < 90) then
		self.timeBlipOrange:Show()
		--TQueue:AddToQueue (self.timeBlipOrange, false, false, false)
		--blip:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
		--blip:SetVertexColor (1, .7, 0)
		--blip:SetAlpha (.9)
	elseif (timeLeft < 240) then
		self.timeBlipYellow:Show()
		--TQueue:AddToQueue (self.timeBlipYellow, false, false, false)
		--blip:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
		--blip:SetVertexColor (1, 1, 1)
		--blip:SetAlpha (.8)
	else
		self.timeBlipGreen:Show()
		--TQueue:AddToQueue (self.timeBlipGreen, false, false, false)
		--blip:SetTexture ([[Interface\COMMON\Indicator-Green]])
		--blip:SetVertexColor (1, 1, 1)
		--blip:SetAlpha (.6)
	end
end

--verifica se o item é um item de artefato e pega a quantidade de poder dele
local GameTooltipFrame = CreateFrame ("GameTooltip", "WorldQuestTrackerScanTooltip", nil, "GameTooltipTemplate")
local GameTooltipFrameTextLeft1 = _G ["WorldQuestTrackerScanTooltipTextLeft2"]
local GameTooltipFrameTextLeft2 = _G ["WorldQuestTrackerScanTooltipTextLeft3"]
local GameTooltipFrameTextLeft3 = _G ["WorldQuestTrackerScanTooltipTextLeft4"]

--GameTooltip_ShowCompareItem(GameTooltip);
--EmbeddedItemTooltip_SetItemByQuestReward(self, questLogIndex, questID)
function WorldQuestTracker.RewardRealItemLevel (questID)
	GameTooltipFrame:SetOwner (WorldFrame, "ANCHOR_NONE")
	--GameTooltipFrame:SetHyperlink (itemLink)
	GameTooltipFrame:SetQuestLogItem ("reward", 1, questID)
	local itemLevel = tonumber (GameTooltipFrameTextLeft1:GetText():match ("%d+"))
	return itemLevel or 1
end

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
				local hasUpgrade = WorldQuestTracker.RewardRealItemLevel (questID)
				itemLevel = itemLevel > hasUpgrade and itemLevel or hasUpgrade
				
				if (isArtifact) then
					return itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, true, artifactPower, itemStackCount > 1, itemStackCount
				else
					return itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, false, 0, itemStackCount > 1, itemStackCount
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
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_red_roundT]]
		else
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_redT]]
		end
	elseif (artifactPower >= 120) then
		if (rounded) then
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_yellow_roundT]]
		else	
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_yellowT]]
		end
	else
		if (rounded) then
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blue_roundT]]
		else	
			return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blueT]]
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

--pega a lista de quests que o jogador tem disponível
function WorldQuestTracker.SavedQuestList_GetList()
	return WorldQuestTracker.dbChr.ActiveQuests
end
-- ~saved ~pool ~data
local map_seasons = {}
function WorldQuestTracker.SavedQuestList_IsNew (questID)
	if (WorldQuestTracker.MapSeason == 0) then
		--o mapa esta carregando e não mandou o primeiro evento ainda
		return false
	end

	local ActiveQuests = WorldQuestTracker.SavedQuestList_GetList()
	
	if (ActiveQuests [questID]) then --a quest esta armazenada
		if (map_seasons [questID] == WorldQuestTracker.MapSeason) then
			--a quest já esta na lista porém foi adicionada nesta season do mapa
			return true
		else
			--apenas retornar que não é nova
			return false
		end
	else --a quest não esta na lista
		local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
		if (timeLeft and timeLeft > 0) then
			--adicionar a quest a lista de quets
			ActiveQuests [questID] = time() + (timeLeft*60)
			map_seasons [questID] = WorldQuestTracker.MapSeason
			--retornar que a quest é nova
			return true
		else
			--o tempo da quest expirou.
			return false
		end
	end
end

function WorldQuestTracker.SavedQuestList_CleanUp()
	local ActiveQuests = WorldQuestTracker.SavedQuestList_GetList()
	local now = time()
	for questID, expireAt in pairs (ActiveQuests) do
		if (expireAt < now) then
			ActiveQuests [questID] = nil
		end
	end
end

------------

function WorldQuestTracker.AllCharactersQuests_Add (questID, timeLeft, iconTexture, iconText)
	local guid = UnitGUID ("player")
	local t = WorldQuestTracker.db.profile.quests_all_characters [guid]
	if (not t) then
		t = {}
		WorldQuestTracker.db.profile.quests_all_characters [guid] = t
	end
	
	local questInfo = t [questID]
	if (not questInfo) then
		questInfo = {}
		t [questID] = questInfo
	end
	
	questInfo.expireAt = time() + (timeLeft*60) --timeLeft = minutes left
	questInfo.rewardTexture = iconTexture or ""
	questInfo.rewardAmount = iconText or ""
end

function WorldQuestTracker.AllCharactersQuests_Remove (questID)
	local guid = UnitGUID ("player")
	local t = WorldQuestTracker.db.profile.quests_all_characters [guid]
	
	if (t) then
		t [questID] = nil
	end
end

function WorldQuestTracker.AllCharactersQuests_CleanUp()
	local guid = UnitGUID ("player")
	local t = WorldQuestTracker.db.profile.quests_all_characters [guid]
	
	if (t) then
		local now = time()
		for questID, questInfo in pairs (t) do
			if (questInfo.expireAt < now) then
				t [questID] = nil
			end
		end
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
fadeInAnimation:SetScript ("OnFinished", function()
	worldFramePOIs:SetAlpha (1)
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> world map frame hooks

WorldMapFrame:HookScript ("OnEvent", function (self, event)
	if (event == "WORLD_MAP_UPDATE") then
		if (WorldQuestTracker.CurrentMapID ~= self.mapID) then
			if (WorldQuestTracker.LastWorldMapClick+0.017 > GetTime()) then
				WorldQuestTracker.CurrentMapID = self.mapID
			end
		end
		
		if (WorldQuestTracker.DoubleTapFrame and not InCombatLockdown()) then
			if (self.mapID == MAPID_BROKENISLES) then
				WorldQuestTracker.DoubleTapFrame:Show()
			else
				WorldQuestTracker.DoubleTapFrame:Hide()
			end
		end
	end
end)

--OnTick
WorldMapFrame:HookScript ("OnUpdate", function (self, deltaTime)
	if (WorldQuestTracker.db.profile.map_lock and (GetCurrentMapContinent() == 8 or WorldQuestTracker.WorldQuestButton_Click+30 > GetTime())) then
		if (WorldQuestTracker.CanChangeMap) then
			WorldQuestTracker.CanChangeMap = nil
			WorldQuestTracker.LastMapID = GetCurrentMapAreaID()
		else
			if (WorldQuestTracker.LastMapID ~= GetCurrentMapAreaID() and WorldQuestTracker.LastMapID and not InCombatLockdown()) then
				SetMapByID (WorldQuestTracker.LastMapID)
				WorldQuestTracker.UpdateZoneWidgets()
			end
		end
	end
end)

local currentMap
local deny_auto_switch = function()
	WorldQuestTracker.NoAutoSwitchToWorldMap = true
	currentMap = GetCurrentMapAreaID()
end

--apos o click, verifica se pode mostrar os widgets e permitir que o mapa seja alterado no proximo tick
local allow_map_change = function (...)
	if (currentMap == GetCurrentMapAreaID()) then
		WorldQuestTracker.CanShowWorldMapWidgets (true)
	else
		WorldQuestTracker.CanShowWorldMapWidgets (false)
	end
	WorldQuestTracker.CanChangeMap = true
	WorldQuestTracker.LastMapID = GetCurrentMapAreaID()
	WorldQuestTracker.UpdateZoneWidgets()
	
	if (WorldQuestTracker.LastMapID ~= MAPID_BROKENISLES and WorldQuestTracker.IsPlayingLoadAnimation()) then
		WorldQuestTracker.StopLoadingAnimation()
	end
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
	self.IsTrackingRareGlow:Hide()
	self.SelectedGlow:Hide()
	self.CriteriaMatchGlow:Hide()
	self.SpellTargetGlow:Hide()
	self.rareSerpent:Hide()
	self.rareGlow:Hide()
	self.blackBackground:Hide()
	self.circleBorder:Hide()
	self.squareBorder:Hide()
	self.timeBlipRed:Hide()
	self.timeBlipOrange:Hide()
	self.timeBlipYellow:Hide()
	self.timeBlipGreen:Hide()
	self.bgFlag:Hide()
	self.blackGradient:Hide()
	self.flagText:Hide()
	self.criteriaIndicator:Hide()
	self.criteriaIndicatorGlow:Hide()
	self.questTypeBlip:Hide()
end

-- ~zoneicon
function WorldQuestTracker.CreateZoneWidget (index, name, parent) --~zone
	local button = CreateFrame ("button", name .. index, parent)
	button:SetSize (20, 20)
	
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
	button.highlight:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\highlight_circleT]])
	button.highlight:SetPoint ("center")
	button.highlight:SetSize (16, 16)
	
	button.IsTrackingGlow = button:CreateTexture(button:GetName() .. "IsTrackingGlow", "BACKGROUND", -6)
	button.IsTrackingGlow:SetSize (44, 44)
	button.IsTrackingGlow:SetPoint ("center", button, "center")
	button.IsTrackingGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\glow_yellow_roundT]])
	button.IsTrackingGlow:SetBlendMode ("ADD")
	button.IsTrackingGlow:SetAlpha (1)
	button.IsTrackingGlow:Hide()
	button.IsTrackingGlow:SetDesaturated (nil)
	--testing another texture
	button.IsTrackingGlow:SetTexture ([[Interface\Calendar\EventNotificationGlow]])
	button.IsTrackingGlow:SetSize (36, 36)
	
	button.IsTrackingRareGlow = button:CreateTexture(button:GetName() .. "IsTrackingRareGlow", "BACKGROUND", -6)
	button.IsTrackingRareGlow:SetSize (44, 44)
	button.IsTrackingRareGlow:SetPoint ("center", button, "center")
	button.IsTrackingRareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragon_TrackingT]])
	--button.IsTrackingRareGlow:SetBlendMode ("ADD")
	button.IsTrackingRareGlow:Hide()

	button.Shadow = button:CreateTexture(button:GetName() .. "Shadow", "BACKGROUND", -8)
	button.Shadow:SetSize (24, 24)
	button.Shadow:SetPoint ("center", button, "center")
	button.Shadow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\glow_yellow_roundT]])
	button.Shadow:SetTexture ([[Interface\PETBATTLES\BattleBar-AbilityBadge-Neutral]])
	button.Shadow:SetAlpha (1)
	
	local onStartTrackAnimation = DF:CreateAnimationHub (button.IsTrackingGlow, onStartClickAnimation)
	WorldQuestTracker:CreateAnimation (onStartTrackAnimation, "Scale", 1, .12, .9, .9, 1, 1)
	local onEndTrackAnimation = DF:CreateAnimationHub (button.IsTrackingGlow, onStartClickAnimation, onEndClickAnimation)
	WorldQuestTracker:CreateAnimation (onEndTrackAnimation, "Scale", 1, .5, 1, 1, .1, .1)
	button.onStartTrackAnimation = onStartTrackAnimation
	button.onEndTrackAnimation = onEndTrackAnimation
	
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
		button.flagCriteriaMatchGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag_criteriamatchT]])
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
	button.rareSerpent:SetPoint ("CENTER", 1, -2)
	
	-- é a sombra da serpente no fundo, pode ser na cor azul ou roxa
	button.rareGlow = button:CreateTexture (nil, "background")
	--button.rareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragonT]])
	button.rareGlow:SetPoint ("CENTER", 1, -2)
	button.rareGlow:SetSize (48, 48)
	button.rareGlow:SetAlpha (.85)
	
	--fundo preto
	button.blackBackground = button:CreateTexture (nil, "background")
	button.blackBackground:SetPoint ("center")
	button.blackBackground:Hide()

	--borda circular
	button.circleBorder = button:CreateTexture (nil, "OVERLAY", 1)
	button.circleBorder:SetPoint ("topleft", button, "topleft", -1, 1)
	button.circleBorder:SetPoint ("bottomright", button, "bottomright", 1, -1)
	button.circleBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_white2T]])
	button.circleBorder:SetTexCoord (0, 1, 0, 1)
--	button.circleBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\bordersT]])
--	button.circleBorder:SetTexCoord (80/256, 138/256, 6/64, 64/64)
--	button.circleBorder:SetTexture ([[Interface\Artifacts\Artifacts]])
--	button.circleBorder:SetTexCoord (6/1024, 56/1024, 964/1024, 1013/1024) 
	
	button.glassTransparence = button:CreateTexture (nil, "OVERLAY", 1)
	button.glassTransparence:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_transparency_overlay]])
	button.glassTransparence:SetPoint ("topleft", button, "topleft", -1, 1)
	button.glassTransparence:SetPoint ("bottomright", button, "bottomright", 1, -1)
	button.glassTransparence:SetAlpha (.5)
	button.glassTransparence:Hide()
	
	--borda quadrada
	button.squareBorder = button:CreateTexture (nil, "OVERLAY", 1)
	button.squareBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_whiteT]])
	button.squareBorder:SetPoint ("topleft", button, "topleft", -1, 1)
	button.squareBorder:SetPoint ("bottomright", button, "bottomright", 1, -1)

	--blip do tempo restante
	button.timeBlipRed = button:CreateTexture (nil, "OVERLAY")
	button.timeBlipRed:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipRed:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipRed:SetTexture ([[Interface\COMMON\Indicator-Red]])
	button.timeBlipRed:SetVertexColor (1, 1, 1)
	button.timeBlipRed:SetAlpha (1)
	
	button.timeBlipOrange = button:CreateTexture (nil, "OVERLAY")
	button.timeBlipOrange:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipOrange:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipOrange:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
	button.timeBlipOrange:SetVertexColor (1, .7, 0)
	button.timeBlipOrange:SetAlpha (.9)
	
	button.timeBlipYellow = button:CreateTexture (nil, "OVERLAY")
	button.timeBlipYellow:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipYellow:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipYellow:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
	button.timeBlipYellow:SetVertexColor (1, 1, 1)
	button.timeBlipYellow:SetAlpha (.8)
	
	button.timeBlipGreen = button:CreateTexture (nil, "OVERLAY")
	button.timeBlipGreen:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipGreen:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipGreen:SetTexture ([[Interface\COMMON\Indicator-Green]])
	button.timeBlipGreen:SetVertexColor (1, 1, 1)
	button.timeBlipGreen:SetAlpha (.6)

	--blip do indicador de tipo da quest
	button.questTypeBlip = button:CreateTexture (nil, "OVERLAY", 2)
	button.questTypeBlip:SetPoint ("topright", button, "topright", 3, 1)
	button.questTypeBlip:SetSize (10, 10)
	
	--faixa com o tempo
	button.bgFlag = button:CreateTexture (nil, "OVERLAY", 5)
	button.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flagT]])
	button.bgFlag:SetPoint ("top", button, "bottom", 0, 3)
	button.bgFlag:SetSize (64, 32)
	
	button.blackGradient = button:CreateTexture (nil, "OVERLAY")
	button.blackGradient:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
	button.blackGradient:SetPoint ("top", button.bgFlag, "top", 0, -1)
	button.blackGradient:SetSize (32, 10)
	button.blackGradient:SetAlpha (.7)
	
	--string da flag
	button.flagText = button:CreateFontString (nil, "OVERLAY", "GameFontNormal")
	button.flagText:SetText ("13m")
	button.flagText:SetPoint ("top", button.bgFlag, "top", 0, -2)
	DF:SetFontSize (button.flagText, 8)
	
	local criteriaFrame = CreateFrame ("frame", nil, button)
	local criteriaIndicator = criteriaFrame:CreateTexture (nil, "OVERLAY", 4)
	criteriaIndicator:SetPoint ("bottomleft", button, "bottomleft", -2, -2)
	criteriaIndicator:SetSize (23*.3, 37*.3)
	criteriaIndicator:SetAlpha (.8)
	criteriaIndicator:SetTexture ([[Interface\AdventureMap\AdventureMap]])
	criteriaIndicator:SetTexCoord (901/1024, 924/1024, 251/1024, 288/1024)
	criteriaIndicator:Hide()
	local criteriaIndicatorGlow = criteriaFrame:CreateTexture (nil, "OVERLAY", 3)
	criteriaIndicatorGlow:SetPoint ("center", criteriaIndicator, "center")
	criteriaIndicatorGlow:SetSize (13, 13)
	criteriaIndicatorGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\criteriaIndicatorGlowT]])
	criteriaIndicatorGlow:SetTexCoord (0, 1, 0, 1)
	criteriaIndicatorGlow:Hide()
	
	local criteriaAnimation = DF:CreateAnimationHub (criteriaFrame)
	DF:CreateAnimation (criteriaAnimation, "Scale", 1, .15, 1, 1, 1.1, 1.1)
	DF:CreateAnimation (criteriaAnimation, "Scale", 2, .15, 1.2, 1.2, 1, 1)
	button.CriteriaAnimation = criteriaAnimation
	
	button.Shadow:SetDrawLayer ("BACKGROUND", -8)
	button.blackBackground:SetDrawLayer ("BACKGROUND", -7)
	button.IsTrackingGlow:SetDrawLayer ("BACKGROUND", -6)
	button.Glow:SetDrawLayer ("BACKGROUND", -6)
	button.Texture:SetDrawLayer ("BACKGROUND", -5)
	button.glassTransparence:SetDrawLayer ("BACKGROUND", -4)

	button.IsTrackingRareGlow:SetDrawLayer ("overlay", 0)
	button.circleBorder:SetDrawLayer ("overlay", 1)
	button.squareBorder:SetDrawLayer ("overlay", 1)
	button.rareSerpent:SetDrawLayer ("overlay", 3)
	button.bgFlag:SetDrawLayer ("overlay", 4)
	button.blackGradient:SetDrawLayer ("overlay", 5)
	button.flagText:SetDrawLayer ("overlay", 6)
	criteriaIndicator:SetDrawLayer ("overlay", 6)
	criteriaIndicatorGlow:SetDrawLayer ("overlay", 7)
	button.timeBlipRed:SetDrawLayer ("overlay", 7)
	button.timeBlipOrange:SetDrawLayer ("overlay", 7)
	button.timeBlipYellow:SetDrawLayer ("overlay", 7)
	button.timeBlipGreen:SetDrawLayer ("overlay", 7)
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

--atualiza as quest do mapa da zona ~updatezone ~zoneupdate
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
	
	--parar a animação de loading
	if (WorldQuestTracker.IsPlayingLoadAnimation()) then
		WorldQuestTracker.StopLoadingAnimation()
	end	
	
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

--atualiza o widget da quest no mapa da zona ~setupzone
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
	self.IsTrackingRareGlow:Hide()
	self.rareSerpent:Hide()
	self.rareGlow:Hide()
	self.blackBackground:Hide()
--	self.criteriaIndicator:Hide()
--	self.criteriaIndicatorGlow:Hide()	
	self.questTypeBlip:Hide()
	
	self.isSelected = selected
	self.isCriteria = isCriteria
	self.isSpellTarget = isSpellTarget
	
	self.flagText:Show()
	self.timeBlipRed:Hide()
	self.timeBlipOrange:Hide()
	self.timeBlipYellow:Hide()
	self.timeBlipGreen:Hide()
	self.blackGradient:Show()

	self.Texture:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])

	if (HaveQuestData (questID)) then
		local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
		
		if (self.isCriteria) then
			if (not self.criteriaIndicator:IsShown()) then
				self.CriteriaAnimation:Play()
			end
			self.flagCriteriaMatchGlow:Show()
			self.criteriaIndicator:Show()
			self.criteriaIndicatorGlow:Show()
		else
			self.flagCriteriaMatchGlow:Hide()
			self.criteriaIndicator:Hide()
			self.criteriaIndicatorGlow:Hide()
		end
		
		if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
			if (rarity == LE_WORLD_QUEST_QUALITY_RARE or rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
				self.IsTrackingRareGlow:Show()
			end
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
			WorldQuestTracker.SetTimeBlipColor (self, timeLeft)
			local okay = false
			
			-- gold
			local goldReward, goldFormated = WorldQuestTracker.GetQuestReward_Gold (questID)
			if (goldReward > 0) then
				local texture = WorldQuestTracker.GetGoldIcon()
				
				WorldQuestTracker.SetIconTexture (self.Texture, texture, false, false)
				
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
					
					if (numRewardItems >= 1000) then
						self.flagText:SetText (format ("%.1fK", numRewardItems/1000))
						--self.flagText:SetText (comma_value (numRewardItems))
					else
						self.flagText:SetText (numRewardItems)
					end

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
					
					if (artifactPower >= 1000) then
						self.flagText:SetText (format ("%.1fK", artifactPower/1000))
						--self.flagText:SetText (comma_value (artifactPower))
					else
						self.flagText:SetText (artifactPower)
					end

					self.isArtifact = true
					self.IconTexture = texture
					self.IconText = artifactPower
					self.QuestType = QUESTTYPE_ARTIFACTPOWER
				else
					self.Texture:SetSize (16, 16)
					self.Texture:SetTexture (itemTexture) -- 1387639 slice of bacon
					--self.Texture:SetTexCoord (0, 1, 0, 1)
					if (itemLevel > 600 and itemLevel < 780) then
						itemLevel = 810
					end
					self.flagText:SetText ((isStackable and quantity and quantity >= 1 and quantity or false) or (itemLevel and itemLevel > 5 and itemLevel) or "")
					-- /run local f=CreateFrame("frame");f:SetPoint("center");f:SetSize(100,100);local t=f:CreateTexture(nil,"overlay");t:SetSize(100,100);t:SetPoint("center");t:SetTexture(1387639)
					
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
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, false)
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

--WorldQuestTracker.db.profile.AlertTutorialStep = nil
-- ~tutorial
local re_ShowTutorialAlert = function()
	WorldQuestTracker ["ShowTutorialAlert"]()
end
local hook_AlertCloseButton = function (self) 
	re_ShowTutorialAlert()
end
local wait_ShowTutorialAlert = function()
	WorldQuestTracker.TutorialAlertOnHold = nil
	WorldQuestTracker.ShowTutorialAlert()
end
function WorldQuestTracker.ShowTutorialAlert()
	if (not WorldQuestTracker.db.profile.GotTutorial) then
		return
	end
	
	WorldQuestTracker.db.profile.AlertTutorialStep = WorldQuestTracker.db.profile.AlertTutorialStep or 1
	
	if (WorldQuestTracker.db.profile.AlertTutorialStep == 1) then
	
		if (WorldQuestTracker.TutorialAlertOnHold) then
			return
		end
	
		if (not WorldMapFrame:IsShown() or not IsQuestFlaggedCompleted (WORLD_QUESTS_AVAILABLE_QUEST_ID or 1) or InCombatLockdown()) then
			C_Timer.After (10, wait_ShowTutorialAlert)
			WorldQuestTracker.TutorialAlertOnHold = true
			return
		end
	
		WorldQuestTrackerGoToBIButton:Click()
	
		local alert = CreateFrame ("frame", "WorldQuestTrackerTutorialAlert1", worldFramePOIs, "MicroButtonAlertTemplate")
		alert:SetFrameLevel (302)
		alert.label = L["S_TUTORIAL_CLICKTOTRACK"]
		alert.Text:SetSpacing (4)
		MicroButtonAlert_SetText (alert, alert.label)
		alert:SetPoint ("topleft", worldFramePOIs, "topleft", 64, -270)
		alert.CloseButton:HookScript ("OnClick", hook_AlertCloseButton)
		alert:Show()
		
		WorldQuestTracker.db.profile.AlertTutorialStep = WorldQuestTracker.db.profile.AlertTutorialStep + 1
		
	elseif (WorldQuestTracker.db.profile.AlertTutorialStep == 2) then
		local alert = CreateFrame ("frame", "WorldQuestTrackerTutorialAlert2", worldFramePOIs, "MicroButtonAlertTemplate")
		alert:SetFrameLevel (302)
		alert.label = L["S_TUTORIAL_AUTOWORLDMAP"]
		alert.Text:SetSpacing (4)
		MicroButtonAlert_SetText (alert, alert.label)
		alert:SetPoint ("topleft", worldFramePOIs, "topleft", 263, -383)
		alert.CloseButton:HookScript ("OnClick", hook_AlertCloseButton)
		alert.Arrow:ClearAllPoints()
		alert.Arrow:SetPoint ("topleft", alert, "bottomleft", 10, 0)
		alert:Show()
		
		WorldQuestTracker.db.profile.AlertTutorialStep = WorldQuestTracker.db.profile.AlertTutorialStep + 1
		
	elseif (WorldQuestTracker.db.profile.AlertTutorialStep == 3) then
		local alert = CreateFrame ("frame", "WorldQuestTrackerTutorialAlert3", worldFramePOIs, "MicroButtonAlertTemplate")
		alert:SetFrameLevel (302)
		alert.label = L["S_TUTORIAL_WORLDMAPBUTTON"]
		alert.Text:SetSpacing (4)
		MicroButtonAlert_SetText (alert, alert.label)
		alert:SetPoint ("topleft", worldFramePOIs, "topleft", 522, -403)
		alert.CloseButton:HookScript ("OnClick", hook_AlertCloseButton)
		alert:Show()
		
		WorldQuestTracker.db.profile.AlertTutorialStep = WorldQuestTracker.db.profile.AlertTutorialStep + 1
		
	end
end

--ao abrir ou fechar o mapa
hooksecurefunc ("ToggleWorldMap", function (self)
	
	WorldMapFrame.currentStandingZone = GetCurrentMapAreaID()
	
	if (GameCooltipFrame1 and GameCooltipFrame2) then
		GameCooltipFrame1:SetParent (UIParent)
		GameCooltipFrame2:SetParent (UIParent)
	end
	
	if (WorldMapFrame:IsShown()) then
		animFrame:SetScript ("OnUpdate", tickAnimation)
		WorldQuestTracker.MapSeason = WorldQuestTracker.MapSeason + 1
		WorldQuestTracker.MapOpenedAt = GetTime()
	else
		animFrame:SetScript ("OnUpdate", nil)
		for mapId, configTable in pairs (WorldQuestTracker.mapTables) do --WorldQuestTracker.SetIconTexture
			for i, f in ipairs (configTable.widgets) do
				--f:Hide()
			end
		end
	end
	
	--verifica duplo click
	if (lastMapTap+0.3 > GetTime() and not InCombatLockdown() and WorldQuestTracker.CanShowBrokenIsles()) then
		
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

		if (not WorldMapFrame.firstRun and not InCombatLockdown()) then
			local currentMapId = WorldMapFrame.mapID
			SetMapByID (1015)
			SetMapByID (1018)
			SetMapByID (1024)
			SetMapByID (1017)
			SetMapByID (1033)
			SetMapByID (1096)
			SetMapByID (currentMapId)
			WorldMapFrame.firstRun = true

			--[[
			C_Timer.After (1, function()
				for bountyButton, _ in pairs (WorldMapFrame.UIElementsFrame.BountyBoard.bountyTabPool.activeObjects) do
					bountyButton:HookScript ("OnClick", function()
						if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
							WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, false, false, true)
						end
					end)
				end
			end)
			--]]
			
			local CooltipOnTop_WhenFullScreen = function()
				if (not WorldMapFrame_InWindowedMode()) then
					GameCooltipFrame1:SetParent (WorldMapFrame)
					GameCooltipFrame1:SetFrameLevel (4000)
				end
			end
			
			--go to broken isles button ~worldquestbutton ~worldmapbutton
			local WorldQuestButton = CreateFrame ("button", "WorldQuestTrackerGoToBIButton", WorldMapFrame.UIElementsFrame)
			WorldQuestButton:SetSize (64, 32)
			WorldQuestButton:SetPoint ("right", WorldMapFrame.UIElementsFrame.CloseQuestPanelButton, "left", -2, 0)
			WorldQuestButton.Background = WorldQuestButton:CreateTexture (nil, "background")
			WorldQuestButton.Background:SetSize (64, 32)
			WorldQuestButton.Background:SetAtlas ("MapCornerShadow-Right")
			WorldQuestButton.Background:SetPoint ("bottomright", 2, -1)
			WorldQuestButton:SetNormalTexture ([[Interface\AddOns\WorldQuestTracker\media\world_quest_button]])
			WorldQuestButton:SetPushedTexture ([[Interface\AddOns\WorldQuestTracker\media\world_quest_button_pushed]])
			
			WorldQuestButton.Highlight = WorldQuestButton:CreateTexture (nil, "highlight")
			WorldQuestButton.Highlight:SetTexture ([[Interface\Buttons\UI-Common-MouseHilight]])
			WorldQuestButton.Highlight:SetBlendMode ("ADD")
			WorldQuestButton.Highlight:SetSize (64*1.5, 32*1.5)
			WorldQuestButton.Highlight:SetPoint ("center")
			
			WorldQuestButton:SetScript ("OnClick", function()
				SetMapByID (MAPID_BROKENISLES)
				PlaySound ("igMainMenuOptionCheckBoxOn")
				WorldQuestTracker.WorldQuestButton_Click = GetTime()
			end)
			WorldQuestButton:HookScript ("PreClick", deny_auto_switch)
			WorldQuestButton:HookScript ("PostClick", allow_map_change)
			
			--avisar sobre duplo tap
			WorldQuestTracker.DoubleTapFrame = CreateFrame ("frame", "WorldQuestTrackerDoubleTapFrame", worldFramePOIs)
			WorldQuestTracker.DoubleTapFrame:SetSize (1, 1)
			--WorldQuestTracker.DoubleTapFrame:SetPoint ("bottomleft", worldFramePOIs, "bottomleft", 3, 3)
			WorldQuestTracker.DoubleTapFrame:SetPoint ("bottomleft", WorldMapPOIFrame, "bottomleft", 0, 0)
			
			---------------------------------------------------------
			
			local SummaryFrame = CreateFrame ("frame", "WorldQuestTrackerSummaryPanel", WorldQuestTrackerWorldMapPOI)
			SummaryFrame:SetPoint ("topleft", WorldMapPOIFrame, "topleft", 0, 0)
			SummaryFrame:SetPoint ("bottomright", WorldMapPOIFrame, "bottomright", 0, 0)
			SummaryFrame:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
			SummaryFrame:SetBackdropColor (0, 0, 0, 1)
			SummaryFrame:SetBackdropBorderColor (0, 0, 0, 1)
			SummaryFrame:SetFrameLevel (3500)
			SummaryFrame:EnableMouse (true)
			SummaryFrame:Hide()
			
			SummaryFrame.RightBorder = SummaryFrame:CreateTexture (nil, "overlay")
			SummaryFrame.RightBorder:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-HorizontalShadow]])
			SummaryFrame.RightBorder:SetTexCoord (1, 0, 0, 1)
			SummaryFrame.RightBorder:SetPoint ("topright")
			SummaryFrame.RightBorder:SetPoint ("bottomright")
			SummaryFrame.RightBorder:SetPoint ("topleft")
			SummaryFrame.RightBorder:SetPoint ("bottomleft")
			SummaryFrame.RightBorder:SetWidth (125)
			SummaryFrame.RightBorder:SetDesaturated (true)
			SummaryFrame.RightBorder:SetDrawLayer ("background", -7)
			
			local SummaryFrameUp = CreateFrame ("frame", "WorldQuestTrackerSummaryUpPanel", WorldQuestTrackerWorldMapPOI)
			SummaryFrameUp:SetPoint ("topleft", WorldMapPOIFrame, "topleft", 0, 0)
			SummaryFrameUp:SetPoint ("bottomright", WorldMapPOIFrame, "bottomright", 0, 0)
			SummaryFrameUp:SetFrameLevel (3501)
			SummaryFrameUp:Hide()
			
			local SummaryFrameDown = CreateFrame ("frame", "WorldQuestTrackerSummaryDownPanel", WorldQuestTrackerWorldMapPOI)
			SummaryFrameDown:SetPoint ("topleft", WorldMapPOIFrame, "topleft", 0, 0)
			SummaryFrameDown:SetPoint ("bottomright", WorldMapPOIFrame, "bottomright", 0, 0)
			SummaryFrameDown:SetFrameLevel (3499)
			SummaryFrameDown:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
			SummaryFrameDown:SetBackdropColor (0, 0, 0, 1)
			SummaryFrameDown:SetBackdropBorderColor (0, 0, 0, 1)
			SummaryFrameDown:Hide()
			
			local CloseSummaryPanel = CreateFrame ("button", "WorldQuestTrackerCloseSummaryButton", SummaryFrameUp)
			CloseSummaryPanel:SetSize (64, 32)
			CloseSummaryPanel:SetPoint ("right", WorldMapFrame.UIElementsFrame.CloseQuestPanelButton, "left", -2, 0)
			CloseSummaryPanel.Background = CloseSummaryPanel:CreateTexture (nil, "background")
			CloseSummaryPanel.Background:SetSize (64, 32)
			CloseSummaryPanel.Background:SetAtlas ("MapCornerShadow-Right")
			CloseSummaryPanel.Background:SetPoint ("bottomright", 2, -1)
			CloseSummaryPanel:SetNormalTexture ([[Interface\AddOns\WorldQuestTracker\media\close_summary_button]])
			CloseSummaryPanel:SetPushedTexture ([[Interface\AddOns\WorldQuestTracker\media\close_summary_button_pushed]])
			
			CloseSummaryPanel.Highlight = CloseSummaryPanel:CreateTexture (nil, "highlight")
			CloseSummaryPanel.Highlight:SetTexture ([[Interface\Buttons\UI-Common-MouseHilight]])
			CloseSummaryPanel.Highlight:SetBlendMode ("ADD")
			CloseSummaryPanel.Highlight:SetSize (64*1.5, 32*1.5)
			CloseSummaryPanel.Highlight:SetPoint ("center")
			
			CloseSummaryPanel:SetScript ("OnClick", function()
				SummaryFrame.HideAnimation:Play()
				SummaryFrameUp.HideAnimation:Play()
				SummaryFrameDown.HideAnimation:Play()
			end)			
			
			SummaryFrame:SetScript ("OnMouseDown", function (self, button)
				if (button == "RightButton") then
					--SummaryFrame:Hide()
					--SummaryFrameUp:Hide()
					SummaryFrame.HideAnimation:Play()
					SummaryFrameUp.HideAnimation:Play()
					SummaryFrameDown.HideAnimation:Play()
				end
			end)
			
			local x = 10
			
			local TitleTemplate = DF:GetTemplate ("font", "WQT_SUMMARY_TITLE")
			
			local accountLifeTime = DF:CreateLabel (SummaryFrameUp, L["S_SUMMARYPANEL_LIFETIMESTATISTICS_ACCOUNT"] .. ":", TitleTemplate)
			accountLifeTime:SetPoint (x, -10)
			SummaryFrameUp.AccountLifeTime_Gold = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_GOLD"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_Resources = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_RESOURCE"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_APower = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_QCompleted = DF:CreateLabel (SummaryFrameUp, L["S_QUESTSCOMPLETED"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_Gold:SetPoint (x, -30)
			SummaryFrameUp.AccountLifeTime_Resources:SetPoint (x, -40)
			SummaryFrameUp.AccountLifeTime_APower:SetPoint (x, -50)
			SummaryFrameUp.AccountLifeTime_QCompleted:SetPoint (x, -60)
			local characterLifeTime = DF:CreateLabel (SummaryFrameUp, L["S_SUMMARYPANEL_LIFETIMESTATISTICS_CHARACTER"] .. ":", TitleTemplate)
			characterLifeTime:SetPoint (x, -80)
			SummaryFrameUp.CharacterLifeTime_Gold = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_GOLD"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_Resources = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_RESOURCE"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_APower = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_QCompleted = DF:CreateLabel (SummaryFrameUp, L["S_QUESTSCOMPLETED"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_Gold:SetPoint (x, -100)
			SummaryFrameUp.CharacterLifeTime_Resources:SetPoint (x, -110)
			SummaryFrameUp.CharacterLifeTime_APower:SetPoint (x, -120)
			SummaryFrameUp.CharacterLifeTime_QCompleted:SetPoint (x, -130)
			
			function WorldQuestTracker.UpdateSummaryFrame()
				
				local acctLifeTime = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_REWARD, WQT_QUERYDB_ACCOUNT)
				acctLifeTime = acctLifeTime or {}
				local questsLifeTime = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_QUEST, WQT_QUERYDB_ACCOUNT)
				questsLifeTime = questsLifeTime or {}
				
				SummaryFrameUp.AccountLifeTime_Gold.text = format (L["S_QUESTTYPE_GOLD"] .. ": %s", (acctLifeTime.gold or 0) > 0 and GetCoinTextureString (acctLifeTime.gold) or 0)
				SummaryFrameUp.AccountLifeTime_Resources.text = format (L["S_QUESTTYPE_RESOURCE"] .. ": %s", acctLifeTime.resource or 0)
				SummaryFrameUp.AccountLifeTime_APower.text = format (L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s", acctLifeTime.artifact or 0)
				SummaryFrameUp.AccountLifeTime_QCompleted.text = format (L["S_QUESTSCOMPLETED"] .. ": %s", questsLifeTime.total or 0)
				
				local chrLifeTime = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_REWARD, WQT_QUERYDB_LOCAL)
				chrLifeTime = chrLifeTime or {}
				local questsLifeTime = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_QUEST, WQT_QUERYDB_LOCAL)
				questsLifeTime = questsLifeTime or {}
				
				SummaryFrameUp.CharacterLifeTime_Gold.text = format (L["S_QUESTTYPE_GOLD"] .. ": %s", (chrLifeTime.gold or 0) > 0 and GetCoinTextureString (chrLifeTime.gold) or 0)
				SummaryFrameUp.CharacterLifeTime_Resources.text = format (L["S_QUESTTYPE_RESOURCE"] .. ": %s", chrLifeTime.resource or 0)
				SummaryFrameUp.CharacterLifeTime_APower.text = format (L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s", chrLifeTime.artifact or 0)
				SummaryFrameUp.CharacterLifeTime_QCompleted.text = format (L["S_QUESTSCOMPLETED"] .. ": %s", questsLifeTime.total or 0)
				
			end
			
			----------
			
			SummaryFrameUp.ShowAnimation = DF:CreateAnimationHub (SummaryFrameUp, 
			function() 
				SummaryFrameUp:Show();
				WorldQuestTracker.UpdateSummaryFrame(); 
				SummaryFrameUp.CharsQuestsScroll:Refresh();
			end,
			function()
				SummaryFrameDown.ShowAnimation:Play();
			end)
			DF:CreateAnimation (SummaryFrameUp.ShowAnimation, "Alpha", 1, .15, 0, 1)
			
			SummaryFrame.ShowAnimation = DF:CreateAnimationHub (SummaryFrame, 
				function() 
					SummaryFrame:Show(); 
				end, 
				function() 
					SummaryFrameUp.ShowAnimation:Play(); 
				end)
			DF:CreateAnimation (SummaryFrame.ShowAnimation, "Scale", 1, .1, .1, 1, 1, 1, "left", 0, 0)
			
			SummaryFrame.HideAnimation = DF:CreateAnimationHub (SummaryFrame, _, 
				function() 
					SummaryFrame:Hide() 
				end)
			DF:CreateAnimation (SummaryFrame.HideAnimation, "Scale", 1, .1, 1, 1, .1, 1, "left", 1, 0)
			
			SummaryFrameUp.HideAnimation = DF:CreateAnimationHub (SummaryFrameUp, _, 
				function() 
					SummaryFrameUp:Hide() 
				end)
			DF:CreateAnimation (SummaryFrameUp.HideAnimation, "Alpha", 1, .1, 1, 0)
			
			SummaryFrameDown.ShowAnimation = DF:CreateAnimationHub (SummaryFrameDown,
				function()
					SummaryFrameDown:Show()
				end,
				function()
					SummaryFrameDown:SetAlpha (.7)
				end
			)
			DF:CreateAnimation (SummaryFrameDown.ShowAnimation, "Alpha", 1, 3, 0, .7)
			
			SummaryFrameDown.HideAnimation = DF:CreateAnimationHub (SummaryFrameDown, function()
				SummaryFrameDown.ShowAnimation:Stop()
			end, 
			function()
				SummaryFrameDown:Hide()
			end)
			DF:CreateAnimation (SummaryFrameDown.HideAnimation, "Alpha", 1, .1, 1, 0)
			-----------
			
			local scroll_refresh = function()
				
			end
			
			local AllQuests = WorldQuestTracker.db.profile.quests_all_characters
			local formated_quest_table = {}
			local chrGuid = UnitGUID ("player")
			for guid, questTable in pairs (AllQuests or {}) do
				if (guid ~= chrGuid) then
					tinsert (formated_quest_table, {true, guid})
					for questID, questInfo in pairs (questTable or {}) do
						tinsert (formated_quest_table, {questID, questInfo})
					end
				end
			end
			
			local scroll_line_height = 14
			local scroll_line_amount = 26
			local scroll_width = 195
			
			local line_onenter = function()
				
			end
			local line_onleave = function()
				
			end
			local line_onclick = function()
				
			end
			
			local scroll_createline = function (self, index)
				local line = CreateFrame ("button", "$parentLine" .. index, self)
				line:SetPoint ("topleft", self, "topleft", 0, -((index-1)*(scroll_line_height+1)))
				line:SetSize (scroll_width, scroll_line_height)
				line:SetScript ("OnEnter", line_onenter)
				line:SetScript ("OnLeave", line_onleave)
				line:SetScript ("OnClick", line_onclick)
				
				line:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
				line:SetBackdropColor (0, 0, 0, 0.2)
				
				local icon = line:CreateTexture ("$parentIcon", "overlay")
				icon:SetSize (scroll_line_height, scroll_line_height)
				local name = line:CreateFontString ("$parentName", "overlay", "GameFontNormal")
				DF:SetFontSize (name, 9)
				icon:SetPoint ("left", line, "left", 2, 0)
				name:SetPoint ("left", icon, "right", 2, 0)
				local timeleft = line:CreateFontString ("$parentTimeLeft", "overlay", "GameFontNormal")
				DF:SetFontSize (timeleft, 9)
				timeleft:SetPoint ("right", line, "right", -2, 0)
				line.icon = icon
				line.name = name
				line.timeleft = timeleft
				name:SetHeight (10)
				name:SetJustifyH ("left")
				
				return line
			end
			
			local scroll_refresh = function (self, data, offset, total_lines)
				for i = 1, total_lines do
					local index = i + offset
					local quest = data [index]
					
					if (quest) then
						local line = self:GetLine (i)
						line:SetAlpha (1)
						
						if (quest [1] == true) then
							local name, realm, class = WorldQuestTracker.GetCharInfo (quest [2])
							local color = RAID_CLASS_COLORS [class]
							local name = name .. " - " .. realm
							if (color) then
								name = "|c" .. color.colorStr .. name .. "|r"
							end
							line.name:SetText (name)
							line.timeleft:SetText ("")
							line.name:SetWidth (180)
							line.icon:SetTexture (nil)
						else
							local questInfo = quest [2]
							local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (quest [1])

							local rewardAmount = questInfo.rewardAmount
							if (questInfo.questType == QUESTTYPE_GOLD) then
								rewardAmount = floor (questInfo.rewardAmount / 10000)
							end
							local colorByRarity = ""

							if (rarity  == LE_WORLD_QUEST_QUALITY_EPIC) then
								colorByRarity = "FFC845F9"
							elseif (rarity  == LE_WORLD_QUEST_QUALITY_RARE) then
								colorByRarity = "FF0091F2"
							else
								colorByRarity = "FFFFFFFF"
							end
							
							local timeLeft = ((questInfo.expireAt - time()) / 60) --segundos / 60
							
							line.name:SetText ("|cFFFFDD00[" .. rewardAmount .. "]|r |c" .. colorByRarity.. title .. "|r")
							line.timeleft:SetText (timeLeft > 0 and SecondsToTime (timeLeft * 60) or "|cFFFF5500" .. L["S_SUMMARYPANEL_EXPIRED"] .. "|r")
							line.icon:SetTexture (questInfo.rewardTexture)
							line.name:SetWidth (100)
							
							if (timeLeft <= 0) then
								line:SetAlpha (.5)
							end
						end
					end
				end
			end

			local ScrollTitle = DF:CreateLabel (SummaryFrameUp, L["S_SUMMARYPANEL_OTHERCHARACTERS"] .. ":", TitleTemplate)
			ScrollTitle:SetPoint ("topleft", SummaryFrameUp, "topright", -200, -10)
			
			local CharsQuestsScroll = DF:CreateScrollBox (SummaryFrameUp, "$parentChrQuestsScroll", scroll_refresh, formated_quest_table, scroll_width, 400, scroll_line_amount, scroll_line_height)
			CharsQuestsScroll:SetPoint ("topright", SummaryFrameUp, "topright", -25, -30)
			for i = 1, scroll_line_amount do 
				CharsQuestsScroll:CreateLine (scroll_createline)
			end
			SummaryFrameUp.CharsQuestsScroll = CharsQuestsScroll
			CharsQuestsScroll:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
			CharsQuestsScroll:SetBackdropColor (0, 0, 0, .4)

			-----------
			
			local GF_LineOnEnter = function (self)
				GameCooltip:Preset (2)
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("ButtonsYMod", -2)
				GameCooltip:SetOption ("YSpacingMod", 1)
				GameCooltip:SetOption ("FixedHeight", 95)
				
				local today = self.data.table
				
				local t = WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_GOLD]
				GameCooltip:AddLine (t.name .. ":", today.gold and today.gold > 0 and GetCoinTextureString (today.gold) or 0, 1, "white", "orange")
				GameCooltip:AddIcon (t.icon, 1, 1, 16, 16)
				
				local t = WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_RESOURCE]
				GameCooltip:AddLine (t.name .. ":", comma_value (today.resource or 0), 1, "white", "orange")
				GameCooltip:AddIcon (t.icon, 1, 1, 14, 14)
				
				local t = WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_APOWER]
				GameCooltip:AddLine (t.name .. ":", comma_value (today.artifact or 0), 1, "white", "orange")
				GameCooltip:AddIcon (t.icon, 1, 1, 16, 16)
				
				local t = WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_TRADE]
				GameCooltip:AddLine (t.name .. ":", comma_value (today.blood or 0), 1, "white", "orange")
				GameCooltip:AddIcon (t.icon, 1, 1, 16, 16, unpack (t.coords))
				
				GameCooltip:AddLine (L["S_QUESTSCOMPLETED"] .. ":", today.quest or 0, 1, "white", "orange")
				GameCooltip:AddIcon ([[Interface\GossipFrame\AvailableQuestIcon]], 1, 1, 16, 16)
				
				GameCooltip:ShowCooltip (self)
			end
			local GF_LineOnLeave = function (self)
				GameCooltip:Hide()
			end
			
			local GoldGraphic = DF:CreateGFrame (SummaryFrameUp, 450, 160, 30, GF_LineOnEnter, GF_LineOnLeave, "GoldGraphic", "WorldQuestTrackerGoldGraphic")
			GoldGraphic:SetPoint ("topleft", 10, -248)
			GoldGraphic:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
			GoldGraphic:SetBackdropColor (0, 0, 0, .4)
			
			local GoldGraphicTextBg = CreateFrame ("frame", nil, GoldGraphic)
			GoldGraphicTextBg:SetPoint ("topleft", GoldGraphic, "bottomleft", 0, -2)
			GoldGraphicTextBg:SetPoint ("topright", GoldGraphic, "bottomright", 0, -2)
			GoldGraphicTextBg:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
			GoldGraphicTextBg:SetBackdropColor (0, 0, 0, .4)
			GoldGraphicTextBg:SetHeight (20)
			
			local GoldGraphicTitle = DF:CreateLabel (SummaryFrameUp, L["S_SUMMARYPANEL_LAST15DAYS"] .. ":", TitleTemplate)
			GoldGraphicTitle:SetPoint ("bottomleft", GoldGraphic, "topleft", 0, 2)
			
			local empty_day = {
				["artifact"] = 0,
				["resource"] = 0,
				["quest"] = 0,
				["gold"] = 0,
				["blood"] = 0,
			}
	
			GoldGraphic:SetScript ("OnShow", function (self)
				GoldGraphic:Reset()
				
				local twoWeeks = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_PERIOD, WQT_QUERYDB_ACCOUNT, WQT_DATE_2WEEK)
				local dateString = WorldQuestTracker.GetDateString (WQT_DATE_2WEEK)
				local data = {}
				for i = 1, #dateString do
					local hadTable = false
					for o = 1, #twoWeeks do
						if (twoWeeks[o].day == dateString[i]) then
							local gold = (twoWeeks[o].table.gold and twoWeeks[o].table.gold/10000) or 0
							local resource = twoWeeks[o].table.resource or 0
							local artifact = twoWeeks[o].table.artifact or 0
							local blood = (twoWeeks[o].table.blood and twoWeeks[o].table.blood*300) or 0
							
							local total = gold + resource + artifact + blood

							data [#data+1] = {value = total or 0, text = dateString[i]:gsub ("^%d%d%d%d", ""), table = twoWeeks[o].table}
							hadTable = true
							break
						end
					end
					if (not hadTable) then
						data [#data+1] = {value = 0, text = dateString[i]:gsub ("^%d%d%d%d", ""), table = empty_day}
					end
					
				end
				
				data = DF.table.reverse (data)
				GoldGraphic:UpdateLines (data)
				
				--fix text anchor
				for _, line in ipairs (GoldGraphic._lines) do
					line.timeline:SetPoint ("bottomright", line, "bottomright", -2, -18)
				end
			end)
			
			-----------
			
			local buttons_width = 70
			
			local setup_button = function (button, name)
				button:SetSize (buttons_width, 16)
			
				button.Text = button:CreateFontString (nil, "overlay", "GameFontNormal")
				button.Text:SetText (name)
			
				WorldQuestTracker:SetFontSize (button.Text, 10)
				WorldQuestTracker:SetFontColor (button.Text, "orange")
				button.Text:SetPoint ("center")
				
				local shadow = button:CreateTexture (nil, "background")
				shadow:SetPoint ("center")
				shadow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
				shadow:SetSize (buttons_width+10, 10)
				shadow:SetAlpha (.3)
			end
			
			local button_onenter = function (self)
				WorldQuestTracker:SetFontColor (self.Text, "WQT_ORANGE_ON_ENTER")
			end
			local button_onleave = function (self)
				WorldQuestTracker:SetFontColor (self.Text, "orange")
			end
			
			--reward history / summary
			local rewardButton = CreateFrame ("button", "WorldQuestTrackerRewardHistoryButton", WorldQuestTracker.DoubleTapFrame)
			rewardButton:SetPoint ("bottomleft", WorldQuestTracker.DoubleTapFrame, "bottomleft", 0, 0)
			setup_button (rewardButton, L["S_MAPBAR_SUMMARY"])
			rewardButton:SetScript ("OnClick", function() SummaryFrame.ShowAnimation:Play() end)

			---------------------------------------------------------
			--options button
			local optionsButton = CreateFrame ("button", "WorldQuestTrackerOptionsButton", WorldQuestTracker.DoubleTapFrame)
			optionsButton:SetPoint ("left", rewardButton, "right", 2, 0)
			setup_button (optionsButton, L["S_MAPBAR_OPTIONS"]) --~options
			
			---------------------------------------------------------
			
			--sort options
			local sortButton = CreateFrame ("button", "WorldQuestTrackerSortButton", WorldQuestTracker.DoubleTapFrame)
			sortButton:SetPoint ("left", optionsButton, "right", 2, 0)
			setup_button (sortButton, L["S_MAPBAR_SORTORDER"])
			
			-- ~sort
			local change_sort_mode = function (a, b, questType, _, _, mouseButton)
				local currentIndex = WorldQuestTracker.db.profile.sort_order [questType]
				if (currentIndex < WQT_QUESTTYPE_MAX) then
					for type, order in pairs (WorldQuestTracker.db.profile.sort_order) do
						if (WorldQuestTracker.db.profile.sort_order [type] == currentIndex+1) then
							WorldQuestTracker.db.profile.sort_order [type] = currentIndex
							break
						end
					end
					
					WorldQuestTracker.db.profile.sort_order [questType] = WorldQuestTracker.db.profile.sort_order [questType] + 1
				end
				
				--[[
				WorldQuestTracker.db.profile.sort_order [questType] = WQT_QUESTTYPE_MAX
				if (currentIndex < WQT_QUESTTYPE_MAX) then
					for i = 1, currentIndex-1 do
						if (WorldQuestTracker.db.profile.sort_order [i] > currentIndex) then
							WorldQuestTracker.db.profile.sort_order [i] = WorldQuestTracker.db.profile.sort_order [i] - 1
						end
					end
				end
				--]]
				
				GameCooltip:ExecFunc (sortButton)
				
				--atualiza as quests
				if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
				end
			end
			
			local overlayColor = {.5, .5, .5, 1}
			local BuildSortMenu = function()
				local t = {}
				for type, order in pairs (WorldQuestTracker.db.profile.sort_order) do
					tinsert (t, {type, order})
				end
				table.sort (t, function(a, b) return a[2] > b[2] end)
				
				GameCooltip:Preset (2)
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("FixedWidth", 180)
				
				for i, questType in ipairs (t) do
					local type = questType [1]
					local info = WQT_QUEST_NAMES_AND_ICONS [type]
					local isEnabled = WorldQuestTracker.db.profile.filters [QUEST_TYPE_TO_FILTER [type]]
					if (isEnabled) then
						GameCooltip:AddLine (info.name)
						GameCooltip:AddIcon (info.icon, 1, 1, 16, 16, unpack (info.coords))
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-MicroStream-Yellow]], 1, 2, 16, 16, 0, 1, 1, 0, overlayColor, nil, true)
					else
						GameCooltip:AddLine (info.name, _, _, "silver")
						local l, r, t, b = unpack (info.coords)
						GameCooltip:AddIcon (info.icon, 1, 1, 16, 16, l, r, t, b, _, _, true)
					end
					
					GameCooltip:AddMenu (1, change_sort_mode, type)
				end
			end
			
			sortButton.CoolTip = {
				Type = "menu",
				BuildFunc = BuildSortMenu, --> called when user mouse over the frame
				OnEnterFunc = function (self) 
					sortButton.button_mouse_over = true
					button_onenter (self)
					C_Timer.After (.05, CooltipOnTop_WhenFullScreen)
				end,
				OnLeaveFunc = function (self) 
					sortButton.button_mouse_over = false
					button_onleave (self)
				end,
				FixedValue = "none",
				ShowSpeed = 0.05,
				Options = function()
				end
			}
			
			GameCooltip:CoolTipInject (sortButton, openOnClick)
			
			---------------------------------------------------------
			
			-- ~filter
			local filterButton = CreateFrame ("button", "WorldQuestTrackerFilterButton", WorldQuestTracker.DoubleTapFrame)
			filterButton:SetPoint ("left", sortButton, "right", 2, 0)
			setup_button (filterButton, "Filter")
			
			local filter_quest_type = function (_, _, questType, _, _, mouseButton)
				WorldQuestTracker.db.profile.filters [questType] = not WorldQuestTracker.db.profile.filters [questType]
			
				GameCooltip:ExecFunc (filterButton)
				
				--atualiza as quests
				if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
				end
			end
			
			local toggle_faction_objectives = function()
				WorldQuestTracker.db.profile.filter_always_show_faction_objectives = not WorldQuestTracker.db.profile.filter_always_show_faction_objectives
				GameCooltip:ExecFunc (filterButton)
				
				--atualiza as quests
				if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
				end
			end
			
			local BuildFilterMenu = function()
				GameCooltip:Preset (2)
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("FixedWidth", 180)
				GameCooltip:SetOption ("FixedWidthSub", 200)
				GameCooltip:SetOption ("SubMenuIsTooltip", true)
				GameCooltip:SetOption ("IgnoreArrows", true)

				local t = {}
				for filterType, canShow in pairs (WorldQuestTracker.db.profile.filters) do
					local sortIndex = WorldQuestTracker.db.profile.sort_order [FILTER_TO_QUEST_TYPE [filterType]]
					tinsert (t, {filterType, sortIndex})
				end
				table.sort (t, function(a, b) return a[2] > b[2] end)
				
				for i, filter in ipairs (t) do
					local filterType = filter [1]
					local info = WQT_QUEST_NAMES_AND_ICONS [FILTER_TO_QUEST_TYPE [filterType]]
					local isEnabled = WorldQuestTracker.db.profile.filters [filterType]
					if (isEnabled) then
						GameCooltip:AddLine (info.name)
						GameCooltip:AddIcon (info.icon, 1, 1, 16, 16, unpack (info.coords))
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 2, 16, 16, 0, 1, 0, 1, overlayColor, nil, true)
					else
						GameCooltip:AddLine (info.name, _, _, "silver")
						local l, r, t, b = unpack (info.coords)
						GameCooltip:AddIcon (info.icon, 1, 1, 16, 16, l, r, t, b, _, _, true)
					end
					GameCooltip:AddMenu (1, filter_quest_type, filterType)
				end
				
				GameCooltip:AddLine ("$div")
				local l, r, t, b = unpack (WQT_GENERAL_STRINGS_AND_ICONS.criteria.coords)
				l = 0.8731118125
				
				if (WorldQuestTracker.db.profile.filter_always_show_faction_objectives) then
					GameCooltip:AddLine (L["S_MAPBAR_FILTERMENU_FACTIONOBJECTIVES"])
					GameCooltip:AddLine (L["S_MAPBAR_FILTERMENU_FACTIONOBJECTIVES_DESC"], "", 2)
					GameCooltip:AddIcon (WQT_GENERAL_STRINGS_AND_ICONS.criteria.icon, 1, 1, 23*.54, 37*.40, l, r, t, b)
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 2, 16, 16, 0, 1, 0, 1, overlayColor, nil, true)
				else
					GameCooltip:AddLine (L["S_MAPBAR_FILTERMENU_FACTIONOBJECTIVES"], "", 1, "silver")
					GameCooltip:AddLine (L["S_MAPBAR_FILTERMENU_FACTIONOBJECTIVES_DESC"], "", 2)
					GameCooltip:AddIcon (WQT_GENERAL_STRINGS_AND_ICONS.criteria.icon, 1, 1, 23*.54, 37*.40, l, r, t, b, nil, nil, true)
				end
				GameCooltip:AddMenu (1, toggle_faction_objectives)
			end
			
			filterButton.CoolTip = {
				Type = "menu",
				BuildFunc = BuildFilterMenu, --> called when user mouse over the frame
				OnEnterFunc = function (self) 
					filterButton.button_mouse_over = true
					button_onenter (self)
					C_Timer.After (.05, CooltipOnTop_WhenFullScreen)
				end,
				OnLeaveFunc = function (self) 
					filterButton.button_mouse_over = false
					button_onleave (self)
				end,
				FixedValue = "none",
				ShowSpeed = 0.05,
				Options = function()
				end,
			}
			
			GameCooltip:CoolTipInject (filterButton)
			
			function WorldQuestTracker.ShowHistoryTooltip (self)
				local _
				GameCooltip:Preset (2)
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("ButtonsYMod", -2)
				GameCooltip:SetOption ("YSpacingMod", 3)
				GameCooltip:SetOption ("FixedHeight", 185)
				GameCooltip:AddLine (" ")
				GameCooltip:AddLine (L["S_MAPBAR_SUMMARYMENU_TODAYREWARDS"] .. ":", _, _, _, _, 12)
				
				C_Timer.After (.05, CooltipOnTop_WhenFullScreen)

				--~sumary
				button_onenter (self)
				
				local today = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_PERIOD, WQT_QUERYDB_LOCAL, WQT_DATE_TODAY)
				today = today or {}
				
				GameCooltip:AddLine (L["S_QUESTTYPE_GOLD"] .. ":", today.gold and today.gold > 0 and GetCoinTextureString (today.gold) or 0, 1, "white", "orange")
				local texture, coords = WorldQuestTracker.GetGoldIcon()
				GameCooltip:AddIcon (texture, 1, 1, 16, 16)
				
				GameCooltip:AddLine (L["S_QUESTTYPE_RESOURCE"] .. ":", comma_value (today.resource or 0), 1, "white", "orange")
				GameCooltip:AddIcon ([[Interface\AddOns\WorldQuestTracker\media\resource_iconT]], 1, 1, 14, 14)
				
				local artifactIcon = WorldQuestTracker.GetArtifactPowerIcon (100000, true)
				GameCooltip:AddLine (L["S_QUESTTYPE_ARTIFACTPOWER"] ..":", comma_value (today.artifact or 0), 1, "white", "orange")
				GameCooltip:AddIcon (artifactIcon, 1, 1, 16, 16)
				
				local quests_completed = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_PERIOD, WQT_QUERYDB_LOCAL, WQT_DATE_TODAY, WQT_QUESTS_PERIOD)
				GameCooltip:AddLine (L["S_QUESTSCOMPLETED"] .. ":", quests_completed or 0, 1, "white", "orange")
				GameCooltip:AddIcon ([[Interface\GossipFrame\AvailableQuestIcon]], 1, 1, 16, 16)
				--
				GameCooltip:AddLine (" ")
				GameCooltip:AddLine (L["S_MAPBAR_SUMMARYMENU_ACCOUNTWIDE"] .. ":", _, _, _, _, 12)
				--GameCooltip:AddLine (" ")
				
				local today_account = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_PERIOD, WQT_QUERYDB_ACCOUNT, WQT_DATE_TODAY)-- or {}
				today_account = today_account or {}
				
				GameCooltip:AddLine (L["S_QUESTTYPE_GOLD"] .. ":", today_account.gold and today_account.gold > 0 and GetCoinTextureString (today_account.gold) or 0, 1, "white", "orange")
				local texture, coords = WorldQuestTracker.GetGoldIcon()
				GameCooltip:AddIcon (texture, 1, 1, 16, 16)
				
				GameCooltip:AddLine (L["S_QUESTTYPE_RESOURCE"] .. ":", comma_value (today_account.resource or 0), 1, "white", "orange")
				GameCooltip:AddIcon ([[Interface\AddOns\WorldQuestTracker\media\resource_iconT]], 1, 1, 14, 14)
				
				local artifactIcon = WorldQuestTracker.GetArtifactPowerIcon (100000, true)
				GameCooltip:AddLine (L["S_QUESTTYPE_ARTIFACTPOWER"] ..":", comma_value (today_account.artifact or 0), 1, "white", "orange")
				GameCooltip:AddIcon (artifactIcon, 1, 1, 16, 16)
				
				local quests_completed = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_PERIOD, WQT_QUERYDB_ACCOUNT, WQT_DATE_TODAY, WQT_QUESTS_PERIOD)
				GameCooltip:AddLine (L["S_QUESTSCOMPLETED"] .. ":", quests_completed or 0, 1, "white", "orange")
				GameCooltip:AddIcon ([[Interface\GossipFrame\AvailableQuestIcon]], 1, 1, 16, 16)

				GameCooltip:AddLine (" ", "", 1, "green", _, 10)
				GameCooltip:AddLine (L["S_MAPBAR_SUMMARYMENU_MOREINFO"], "", 1, "green", _, 10)
				
				--WorldQuestTracker.GetCharInfo (guid)
				--lista de outros personagems:
				
				GameCooltip:AddLine (L["S_MAPBAR_SUMMARYMENU_REQUIREATTENTION"] .. ":", "", 2, _, _, 12)
				GameCooltip:AddLine (" ", "", 2, _, _, 12)
				
				local chrGuid = UnitGUID ("player")
				local timeCutOff = time() + (60*60*2.2)
				local subLines = 1
				--[
				for guid, trackTable in pairs (WorldQuestTracker.db.profile.quests_tracked) do
					if (chrGuid ~= guid) then
						local requireAttention = false
						for i, questInfo in ipairs (trackTable) do
							if (timeCutOff > questInfo.expireAt) then
							
								local timeLeft = ((questInfo.expireAt - time()) / 60) --segundos / 60
								
								if (timeLeft > 0) then
									if (not requireAttention) then
										local name, realm, class = WorldQuestTracker.GetCharInfo (guid)
										local color = RAID_CLASS_COLORS [class]
										local name = name .. " - " .. realm
										if (color) then
											name = "|c" .. color.colorStr .. name .. "|r"
										end
										GameCooltip:AddLine (name, "", 2, _, _, 12)
										subLines = subLines + 1
										requireAttention = true
									end
									
									local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questInfo.questID)

									local rewardAmount = questInfo.rewardAmount
									if (questInfo.questType == QUESTTYPE_GOLD) then
										rewardAmount = floor (questInfo.rewardAmount / 10000)
									end
									local colorByRarity = ""

									if (rarity  == LE_WORLD_QUEST_QUALITY_EPIC) then
										colorByRarity = "FFC845F9"
									elseif (rarity  == LE_WORLD_QUEST_QUALITY_RARE) then
										colorByRarity = "FF0091F2"
									else
										colorByRarity = "FFFFFFFF"
									end
									GameCooltip:AddLine ("|cFFFFDD00[" .. rewardAmount .. "]|r |c" .. colorByRarity.. title .. "|r", SecondsToTime (timeLeft * 60), 2, "white", "orange", 10)-- .. "M" --(timeLeft > 60 and 60 or 1)
									GameCooltip:AddIcon (questInfo.rewardTexture, 2, 1)

									subLines = subLines + 1
								end
							end
						end
					end
				end
				--]]
				if (subLines == 1) then
					GameCooltip:AddLine (L["S_MAPBAR_SUMMARYMENU_NOATTENTION"], " ", 2, "gray", _, 10)
					GameCooltip:AddLine (" ", " ", 2)
				else
					GameCooltip:SetOption ("HeighModSub", max (185 - (subLines * 20), 0))
				end

				GameCooltip:SetOption ("SubMenuIsTooltip", true)
				GameCooltip:SetOption ("NoLastSelectedBar", true)
				
				GameCooltip:SetLastSelected ("main", 1)
				
				GameCooltip:SetOwner (rewardButton)
				GameCooltip:Show()
				
				GameCooltip:ShowSub (GameCooltip.Indexes)
			end
			
			local button_onLeave = function (self)
				GameCooltip:Hide()
				button_onleave (self)
			end
			
			--build option menu
			local options_on_click = function (_, _, option, value, _, mouseButton)
			
				WorldQuestTracker.db.profile [option] = value
			
				GameCooltip:ExecFunc (optionsButton)
				
				--atualiza o tracker?

			end
			
			local BuildOptionsMenu = function()
				GameCooltip:Preset (2)
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("FixedWidth", 160)
				
				--
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_YARDSDISTANCE"])
				if (WorldQuestTracker.db.profile.show_yards_distance) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (1, options_on_click, "show_yards_distance", not WorldQuestTracker.db.profile.show_yards_distance)
				
				--
				
			end
			
			optionsButton.CoolTip = {
				Type = "menu",
				BuildFunc = BuildOptionsMenu, --> called when user mouse over the frame
				OnEnterFunc = function (self) 
					optionsButton.button_mouse_over = true
					button_onenter (self)
					C_Timer.After (.05, CooltipOnTop_WhenFullScreen)
				end,
				OnLeaveFunc = function (self) 
					optionsButton.button_mouse_over = false
					button_onleave (self)
				end,
				FixedValue = "none",
				ShowSpeed = 0.05,
				Options = function()
				end
			}
			
			GameCooltip:CoolTipInject (optionsButton)			

			rewardButton:SetScript ("OnEnter", WorldQuestTracker.ShowHistoryTooltip)
			rewardButton:SetScript ("OnLeave", button_onLeave)
			
			--
			
			local doubleTapBackground = WorldQuestTracker.DoubleTapFrame:CreateTexture (nil, "overlay")
			doubleTapBackground:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-HorizontalShadow]])
			doubleTapBackground:SetPoint ("bottomleft", rewardButton, "bottomleft", 0, -1)
			doubleTapBackground:SetPoint ("bottomright", WorldQuestButton, "bottomleft", 0, -1)
			doubleTapBackground:SetTexCoord (0, .5, 0, 1)
			--doubleTapBackground:SetSize (830, 16)
			doubleTapBackground:SetHeight (18)
			
			local checkboxDoubleTap_func = function (self, actorTypeIndex, value) 
				WorldQuestTracker.db.profile.enable_doubletap = value
			end
			local checkboxDoubleTap = DF:CreateSwitch (WorldQuestTracker.DoubleTapFrame, checkboxDoubleTap_func, WorldQuestTracker.db.profile.enable_doubletap, nil, nil, nil, nil, "checkboxDoubleTap1")
			checkboxDoubleTap:SetTemplate (DF:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"))
			checkboxDoubleTap:SetAsCheckBox()
			checkboxDoubleTap:SetSize (16, 16)
			checkboxDoubleTap.tooltip = L["S_MAPBAR_AUTOWORLDMAP_DESC"]
			checkboxDoubleTap:SetPoint ("left", filterButton, "right", 2, 0)
			
			--checkboxDoubleTap:SetValue (WorldQuestTracker.db.profile.enable_doubletap)
			
			--checkboxDoubleTap.widget:SetBackdropColor (1, 0, 0, 0)

			local doubleTapText = DF:CreateLabel (checkboxDoubleTap, L["S_MAPBAR_AUTOWORLDMAP"], 10, "orange", nil, "checkboxDoubleTapLabel", nil, "overlay")
			doubleTapText:SetPoint ("left", checkboxDoubleTap, "right", 2, 0)
			
			--------------
			
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
		-- ~tutorial
		if (not WorldQuestTracker.db.profile.GotTutorial and not WorldQuestTracker.TutorialHoldOn) then
			
			local re_ShowTutorialPanel = function()
				WorldQuestTracker.ShowTutorialPanel()
			end
			
			function WorldQuestTracker.ShowTutorialPanel()
			
				if (not WorldMapFrame:IsShown() or not IsQuestFlaggedCompleted (WORLD_QUESTS_AVAILABLE_QUEST_ID or 1)) then
					WorldQuestTracker.TutorialHoldOn = true
					C_Timer.After (10, re_ShowTutorialPanel)
					return
				end
		
				WorldQuestTracker.TutorialHoldOn = true
		
				local tutorialFrame = CreateFrame ("button", "WorldQuestTrackerTutorial", WorldMapFrame)
				tutorialFrame:SetSize (160, 320)
				tutorialFrame:SetPoint ("left", WorldMapFrame, "left")
				tutorialFrame:SetPoint ("right", WorldMapFrame, "right")
				tutorialFrame:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
				tutorialFrame:SetBackdropColor (0, 0, 0, 1)
				tutorialFrame:SetBackdropBorderColor (0, 0, 0, 1)
				tutorialFrame:SetFrameStrata ("fullscreen")
				
				tutorialFrame:SetScript ("OnClick", function()
					WorldQuestTracker.db.profile.GotTutorial = true
					tutorialFrame:Hide()
					WorldQuestTracker.ShowTutorialAlert()
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
				doubleTap:SetText (L["S_MAPBAR_AUTOWORLDMAP_DESC"])
				doubleTap:SetJustifyH ("left")
				doubleTap:SetTextColor (1, 1, 1)
				local doubleTabTexture = tutorialFrame:CreateTexture (nil, "overlay")
				doubleTabTexture:SetTexture ([[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]])
				doubleTabTexture:SetTexCoord (0, 1, 0, .9)
				doubleTabTexture:SetPoint ("right", doubleTap, "left", -4, 0)
				doubleTabTexture:SetSize (32, 32)
				
				doubleTap:Hide()
				doubleTabTexture:Hide()
				local title = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
				title:SetPoint ("center", extraBg2, "center")
				title:SetText ("World Quest Tracker")
				DF:SetFontSize (title, 24)
				
				local close = DF:CreateButton (tutorialFrame, function()
					WorldQuestTracker.db.profile.GotTutorial = true
					tutorialFrame:Hide()
					WorldQuestTracker.ShowTutorialAlert()
				end, 100, 24, L["S_TUTORIAL_CLOSE"])
				close:SetPoint ("right", extraBg2, "right", -8, 0)
				close:InstallCustomTexture()

				local texture = tutorialFrame:CreateTexture (nil, "border")
				texture:SetSize (120, 120)
				texture:SetPoint ("left", tutorialFrame, "left", 100, 70)
				texture:SetTexture ([[Interface\ICONS\INV_Chest_Mail_RaidHunter_I_01]])
				
				local square = tutorialFrame:CreateTexture (nil, "artwork")
				square:SetPoint ("topleft", texture, "topleft", -8, 8)
				square:SetPoint ("bottomright", texture, "bottomright", 8, -8)
				square:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_whiteT]])
				
				local timeBlip = tutorialFrame:CreateTexture (nil, "overlay", 2)
				timeBlip:SetPoint ("bottomright", texture, "bottomright", 15, -12)
				timeBlip:SetSize (32, 32)
				timeBlip:SetTexture ([[Interface\COMMON\Indicator-Green]])
				timeBlip:SetVertexColor (1, 1, 1)
				timeBlip:SetAlpha (1)
				
				local flag = tutorialFrame:CreateTexture (nil, "overlay")
				flag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flagT]])
				flag:SetPoint ("top", texture, "bottom", 0, 5)
				flag:SetSize (64*2, 32*2)
				
				local amountText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
				amountText:SetPoint ("center", flag, "center", 0, 19)
				DF:SetFontSize (amountText, 20)
				amountText:SetText ("100")
				
				local amountBackground = tutorialFrame:CreateTexture (nil, "overlay")
				amountBackground:SetPoint ("center", amountText, "center", 0, 0)
				amountBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
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
				criteriaIndicatorGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\criteriaIndicatorGlowT]])
				criteriaIndicatorGlow:SetTexCoord (0, 1, 0, 1)
				
				flag:SetDrawLayer ("overlay", 1)
				amountBackground:SetDrawLayer ("overlay", 2)
				amountText:SetDrawLayer ("overlay", 3)
				
				--indicadores de raridade rarity
				local rarity1 = tutorialFrame:CreateTexture (nil, "overlay")
				rarity1:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_whiteT]])
				local rarity2 = tutorialFrame:CreateTexture (nil, "overlay")
				rarity2:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_blueT]])
				local rarity3 = tutorialFrame:CreateTexture (nil, "overlay")
				rarity3:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_pinkT]])
				rarity1:SetPoint ("topright", texture, "topright", 50, 0)
				rarity2:SetPoint ("left", rarity1, "right", 2, 0)
				rarity3:SetPoint ("left", rarity2, "right", 2, 0)
				rarity1:SetSize (24, 24); rarity2:SetSize (rarity1:GetSize()); rarity3:SetSize (rarity1:GetSize());
				local rarityText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
				rarityText:SetPoint ("left", rarity3, "right", 4, 0)
				DF:SetFontSize (rarityText, 12)
				rarityText:SetText (L["S_TUTORIAL_RARITY"])
				
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
				timeText:SetText (L["S_TUTORIAL_TIMELEFT"])
				
				--incador de quantidade
				local flag = tutorialFrame:CreateTexture (nil, "overlay")
				flag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flagT]])
				flag:SetPoint ("topright", texture, "topright", 88, -60)
				flag:SetSize (64*1, 32*1)
				
				local amountText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
				amountText:SetPoint ("center", flag, "center", 0, 10)
				DF:SetFontSize (amountText, 9)
				amountText:SetText ("100")
				
				local amountBackground = tutorialFrame:CreateTexture (nil, "overlay")
				amountBackground:SetPoint ("center", amountText, "center", 0, 0)
				amountBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
				amountBackground:SetSize (32*2, 10*2)
				amountBackground:SetAlpha (.7)
				
				local timeText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
				timeText:SetPoint ("left", flag, "right", 4, 10)
				DF:SetFontSize (timeText, 12)
				timeText:SetText (L["S_TUTORIAL_AMOUNT"])
				
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
				texture3:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blueT]])
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
				textureText:SetText (L["S_TUTORIAL_REWARD"])
				
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
				criteriaIndicatorGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\criteriaIndicatorGlowT]])
				criteriaIndicatorGlow:SetTexCoord (0, 1, 0, 1)

				local faccaoText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
				faccaoText:SetPoint ("left", criteriaIndicator, "right", 6, 0)
				DF:SetFontSize (faccaoText, 12)
				faccaoText:SetText (L["S_TUTORIAL_FACTIONBOUNTY"])
				
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
				factionQuestAmountBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
				factionQuestAmountBackground:SetSize (20, 10)
				factionQuestAmountBackground:SetAlpha (.7)
				factionQuestAmountBackground:SetDrawLayer ("background", 3)
				
				local faccaoAmountText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
				faccaoAmountText:SetPoint ("left", factionFrame, "right", 6, 0)
				DF:SetFontSize (faccaoAmountText, 12)
				faccaoAmountText:SetText (L["S_TUTORIAL_FACTIONBOUNTY_AMOUNTQUESTS"])
				
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
				clickToTrack2:SetText (L["S_TUTORIAL_HOWTOADDTRACKER"])
				
				--disable auto world map
				local checkboxDoubleTap = DF:CreateSwitch (tutorialFrame, function()end, WorldQuestTracker.db.profile.enable_doubletap, nil, nil, nil, nil, "checkboxDoubleTap1")
				checkboxDoubleTap:SetTemplate (DF:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE"))
				checkboxDoubleTap:SetAsCheckBox()
				checkboxDoubleTap:SetSize (24, 24)
				checkboxDoubleTap.tooltip = L["S_MAPBAR_AUTOWORLDMAP_DESC"]
				checkboxDoubleTap:SetPoint ("topright", texture, "topright", 51, -236)
				local doubleTapText = DF:CreateLabel (checkboxDoubleTap, "Auto World Map", 14, "orange", nil, "checkboxDoubleTapLabel", nil, "overlay")
				doubleTapText:SetPoint ("left", checkboxDoubleTap, "right", 2, 0)
				
				local checkboxDoubleTapLabel = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
				checkboxDoubleTapLabel:SetPoint ("left", doubleTapText.widget, "right", 6, 0)
				DF:SetFontSize (checkboxDoubleTapLabel, 12)
				checkboxDoubleTapLabel:SetText (L["S_TUTORIAL_AUTOWORLDMAP2"])
			end
			
			WorldQuestTracker.ShowTutorialPanel()
			
		end

		-- ~tutorial
		WorldQuestTracker.ShowTutorialAlert()
		
	else
		WorldQuestTracker.NoAutoSwitchToWorldMap = nil
	end
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> tracker quest --~tracker

local TRACKER_TITLE_TEXT_SIZE_INMAP = 12
local TRACKER_TITLE_TEXT_SIZE_OUTMAP = 10
local TRACKER_TITLE_TEXTWIDTH_MAX = 185
local TRACKER_ARROW_ALPHA_MAX = 1
local TRACKER_ARROW_ALPHA_MIN = .75
local TRACKER_BACKGROUND_ALPHA_MIN = .35
local TRACKER_BACKGROUND_ALPHA_MAX = .75
local TRACKER_FRAME_ALPHA_INMAP = 1
local TRACKER_FRAME_ALPHA_OUTMAP = .75

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
		--local x, y = 
		
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
			WorldQuestTracker.JustAddedToTracker [questID] = true
		else
			WorldQuestTracker:Msg (L["S_ERROR_NOTLOADEDYET"])
		end
		
		--atualiza os widgets para adicionar a quest no frame do tracker
		WorldQuestTracker.RefreshTrackerWidgets()
	else
		WorldQuestTracker:Msg (L["S_ERROR_NOTIMELEFT"])
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
	
--	local allQuests, isParcial = WorldQuestTracker.GetAllWorldQuests_Ids()
--	if (isParcial) then
--		return C_Timer.After (10, WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker)
--	end
	
	for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
		local quest = WorldQuestTracker.QuestTrackList [i]
		local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (quest.questID)
		
		--print (select (1, C_TaskQuest.GetQuestInfoByQuestID(quest.questID)), ":", timeLeft)
		
		if (quest.expireAt < now or not timeLeft or timeLeft <= 0) then -- or not allQuests [quest.questID]
			--print ("removing", quest.expireAt, now, quest.expireAt < now, select (1, C_TaskQuest.GetQuestInfoByQuestID(quest.questID)))
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
local Sort_currentMapID = 0
local Sort_QuestsOnTracker = function (t1, t2)
	if (t1.mapID == Sort_currentMapID and t2.mapID == Sort_currentMapID) then
		return t1.LastDistance > t2.LastDistance
		--return t1.timeFraction > t2.timeFraction
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
	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		quest.LastDistance = quest.LastDistance or 0
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
minimizeButtonText:SetText (L["S_WORLDQUESTS"])
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
	WorldQuestTrackerFrame:ClearAllPoints()
	
	for i = 1, ObjectiveTrackerFrame:GetNumPoints() do
		local point, relativeTo, relativePoint, xOfs, yOfs = ObjectiveTrackerFrame:GetPoint (i)
		WorldQuestTrackerFrame:SetPoint (point, relativeTo, relativePoint, -10 + xOfs, -WorldQuestTracker.TrackerHeight - 20)
	end
	
	--WorldQuestTrackerFrame:SetPoint ("topleft", ObjectiveTrackerFrame, "topleft", -10, -WorldQuestTracker.TrackerHeight - 20)

	WorldQuestTrackerHeader:ClearAllPoints()
	WorldQuestTrackerHeader:SetPoint ("bottom", WorldQuestTrackerFrame, "top", 0, -20)
end

--quando um widget for clicado, mostrar painel com opção para parar de trackear
local TrackerFrameOnClick = function (self, button)
	--ao clicar em cima de uma quest mostrada no tracker
	--??--
	if (button == "RightButton") then
		WorldQuestTracker.RemoveQuestFromTracker (self.questID)
		---se o worldmap estiver aberto, dar refresh
		if (WorldMapFrame:IsShown()) then
			if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
				--refresh no world map
				WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
			elseif (is_broken_isles_map [GetCurrentMapAreaID()]) then
				--refresh nos widgets
				WorldQuestTracker.UpdateZoneWidgets()
				WorldQuestTracker.WorldWidgets_NeedFullRefresh = true
			end
		else
			WorldQuestTracker.WorldWidgets_NeedFullRefresh = true
		end
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
	
	self.RightBackground:SetAlpha (TRACKER_BACKGROUND_ALPHA_MAX)
	self.Arrow:SetAlpha (TRACKER_ARROW_ALPHA_MAX)
	buildTooltip (self)
end

local TrackerFrameOnLeave = function (self)
	local color = OBJECTIVE_TRACKER_COLOR["Header"]
	self.Title:SetTextColor (color.r, color.g, color.b)
	
	local color = OBJECTIVE_TRACKER_COLOR["Normal"]
	self.Zone:SetTextColor (color.r, color.g, color.b)

	self.RightBackground:SetAlpha (TRACKER_BACKGROUND_ALPHA_MIN)
	self.Arrow:SetAlpha (TRACKER_ARROW_ALPHA_MIN)
	GameTooltip:Hide()
end

--pega um widget já criado ou cria um novo ~trackercreate
function WorldQuestTracker.GetOrCreateTrackerWidget (index)
	if (TrackerWidgetPool [index]) then
		return TrackerWidgetPool [index]
	end
	
	local f = CreateFrame ("button", nil, WorldQuestTrackerFrame_QuestHolder)
	--f:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
	--f:SetBackdropColor (0, 0, 0, .2)
	f:SetSize (235, 30)
	f:SetScript ("OnClick", TrackerFrameOnClick)
	f:SetScript ("OnEnter", TrackerFrameOnEnter)
	f:SetScript ("OnLeave", TrackerFrameOnLeave)
	f:RegisterForClicks ("LeftButtonUp", "RightButtonUp")
	
	f.RightBackground = f:CreateTexture (nil, "background")
	f.RightBackground:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-HorizontalShadow]])
	f.RightBackground:SetTexCoord (1, 61/128, 0, 1)
	f.RightBackground:SetDesaturated (true)
	f.RightBackground:SetPoint ("topright", f, "topright")
	f.RightBackground:SetPoint ("bottomright", f, "bottomright")
	f.RightBackground:SetWidth (200)
	f.RightBackground:SetAlpha (TRACKER_BACKGROUND_ALPHA_MIN)
	
	--f.module = _G ["WORLD_QUEST_TRACKER_MODULE"]
	f.worldQuest = true
	
	f.Title = DF:CreateLabel (f)
	f.Title.textsize = TRACKER_TITLE_TEXT_SIZE_INMAP
	--f.Title = f:CreateFontString (nil, "overlay", "ObjectiveFont")
	f.Title:SetPoint ("topleft", f, "topleft", 10, -1)
	local titleColor = OBJECTIVE_TRACKER_COLOR["Header"]
	f.Title:SetTextColor (titleColor.r, titleColor.g, titleColor.b)
	f.Zone = DF:CreateLabel (f)
	f.Zone.textsize = TRACKER_TITLE_TEXT_SIZE_INMAP
	--f.Zone = f:CreateFontString (nil, "overlay", "ObjectiveFont")
	f.Zone:SetPoint ("topleft", f, "topleft", 10, -17)
	
	f.YardsDistance = f:CreateFontString (nil, "overlay", "GameFontNormal")
	f.YardsDistance:SetPoint ("left", f.Zone.widget, "right", 2, 0)
	f.YardsDistance:SetJustifyH ("left")
	DF:SetFontColor (f.YardsDistance, "white")
	DF:SetFontSize (f.YardsDistance, 12)
	f.YardsDistance:SetAlpha (.5)
	
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
	
	f.Arrow = f:CreateTexture (nil, "overlay")
	f.Arrow:SetPoint ("right", f, "right", 0, 0)
	f.Arrow:SetSize (32, 32)
	f.Arrow:SetAlpha (.6)
	--f.Arrow:SetAlpha (1)
	f.Arrow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\ArrowGridT]])
	
	f.ArrowDistance = f:CreateTexture (nil, "overlay")
	--f.ArrowDistance:SetPoint ("center", f.Arrow, "center", -5, 0)
	f.ArrowDistance:SetPoint ("center", f.Arrow, "center", 0, 0)
	f.ArrowDistance:SetSize (34, 34)
	f.ArrowDistance:SetAlpha (.5)
	f.ArrowDistance:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\ArrowGridTGlow]])

	f.ArrowDistance:SetDrawLayer ("overlay", 4)
	f.Arrow:SetDrawLayer ("overlay", 5)
	
	------------------------
	
	f.AnimationFrame = CreateFrame ("frame", "$parentAnimation", f)
	f.AnimationFrame:SetAllPoints()
	f.AnimationFrame:SetFrameLevel (f:GetFrameLevel()-1)
	f.AnimationFrame:Hide()
	
	local star = f.AnimationFrame:CreateTexture (nil, "overlay")
	star:SetTexture ([[Interface\Cooldown\star4]])
	star:SetSize (168, 168)
	star:SetPoint ("center", f.Icon, "center", 1, -1)
	star:SetBlendMode ("ADD")
	star:Hide()
	
	local flash = f.AnimationFrame:CreateTexture (nil, "overlay")
	flash:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-Alert-Glow]])
	flash:SetTexCoord (0, 400/512, 0, 170/256)
	flash:SetPoint ("topleft", -60, 30)
	flash:SetPoint ("bottomright", 40, -30)
	flash:SetBlendMode ("ADD")
	
	local spark = f.AnimationFrame:CreateTexture (nil, "overlay")
	spark:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-Alert-Glow]])
	spark:SetTexCoord (400/512, 470/512, 0, 70/256)
	spark:SetSize (50, 34)
	spark:SetBlendMode ("ADD")
	spark:SetPoint ("left")
	
	local iconoverlay = f:CreateTexture (nil, "overlay")
	iconoverlay:SetTexture ([[Interface\COMMON\StreamBackground]])
	iconoverlay:SetPoint ("center", f.Icon, "center", 0, 0)
	iconoverlay:Hide()
	--iconoverlay:SetSize (256, 256)
	iconoverlay:SetDrawLayer ("overlay", 7)
	
	--iconoverlay:SetSize (50, 34)
	--iconoverlay:SetBlendMode ("ADD")
	
	
	local StarShowAnimation = DF:CreateAnimationHub (star, function() star:Show() end, function() star:Hide() end)
	DF:CreateAnimation (StarShowAnimation, "alpha", 1, .3, 0, .2)
	DF:CreateAnimation (StarShowAnimation, "rotation", 1, .3, 90)
	DF:CreateAnimation (StarShowAnimation, "scale", 1, .3, 0, 0, 1.2, 1.2)
	DF:CreateAnimation (StarShowAnimation, "alpha", 2, .3, .2, 0)
	DF:CreateAnimation (StarShowAnimation, "rotation", 2, .3, .8)
	DF:CreateAnimation (StarShowAnimation, "scale", 1, .3, 1.2, 1.2, 0, 0)
	
	local FlashAnimation = DF:CreateAnimationHub (flash, function() flash:Show() end, function() flash:Hide() end)
	DF:CreateAnimation (FlashAnimation, "alpha", 1, .05, 0, .3)
	DF:CreateAnimation (FlashAnimation, "alpha", 2, .5, .3, 0)
	
	local SparkAnimation = DF:CreateAnimationHub (spark, function() spark:Show() end, function() spark:Hide() end)
	DF:CreateAnimation (SparkAnimation, "alpha", 1, .2, 0, .1)
	DF:CreateAnimation (SparkAnimation, "translation", 2, .3, 255, 0)
	
	local CircleOverlayAnimation = DF:CreateAnimationHub (iconoverlay, function() iconoverlay:Show() end, function() iconoverlay:Hide() end)
	DF:CreateAnimation (CircleOverlayAnimation, "alpha", 1, .05, 0, 1)
	DF:CreateAnimation (CircleOverlayAnimation, "alpha", 2, .5, 1, 0)
	
	f.AnimationFrame.ShowAnimation = function()
		f.AnimationFrame:Show()
		StarShowAnimation:Play()
		spark:SetPoint ("left", -40, 0)
		SparkAnimation:Play()
		FlashAnimation:Play()
		CircleOverlayAnimation:Play()
	end
	
	------------------------
	
	TrackerWidgetPool [index] = f
	return f
end

local zoneXLength, zoneYLength = 0, 0
local playerIsMoving = true

function WorldQuestTracker:PLAYER_STARTED_MOVING()
	playerIsMoving = true
end
function WorldQuestTracker:PLAYER_STOPPED_MOVING()
	playerIsMoving = false
end

local TrackerOnTick = function (self, deltaTime)
	if (Sort_currentMapID ~= GetCurrentMapAreaID()) then
		self.Arrow:SetAlpha (.3)
		self.Arrow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\ArrowFrozen]])
		self.Arrow:SetTexCoord (0, 1, 0, 1)
		self.ArrowDistance:Hide()
		self.Arrow.Frozen = true
		return
	elseif (self.Arrow.Frozen) then
		self.Arrow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\ArrowGridT]])
		self.ArrowDistance:Show()
		self.Arrow.Frozen = nil
	end
	
	local x, y = GetPlayerMapPosition ("player")
	local questYaw = (FindLookAtRotation (_, x, y, self.questX, self.questY) + p)%pipi
	local playerYaw = GetPlayerFacing()
	local angle = (((questYaw + playerYaw)%pipi)+pi)%pipi
	local imageIndex = 1+(floor (MapRangeClamped (_, 0, pipi, 1, 144, angle)) + 48)%144 --48º quadro é o que aponta para o norte
	local line = ceil (imageIndex / 12)
	local coord = (imageIndex - ((line-1) * 12)) / 12
	self.Arrow:SetTexCoord (coord-0.0833, coord, 0.0833 * (line-1), 0.0833 * line)
	--self.ArrowDistance:SetTexCoord (coord-0.0905, coord-0.0160, 0.0833 * (line-1), 0.0833 * line) -- 0.0763
	self.ArrowDistance:SetTexCoord (coord-0.0833, coord, 0.0833 * (line-1), 0.0833 * line) -- 0.0763
	
	self.NextPositionUpdate = self.NextPositionUpdate - deltaTime
	
	if ((playerIsMoving or self.ForceUpdate) and self.NextPositionUpdate < 0) then
		local distance = GetDistance_Point (_, x, y, self.questX, self.questY)
		local x = zoneXLength * distance
		local y = zoneYLength * distance
		local yards = (x*x + y*y) ^ 0.5
		self.YardsDistance:SetText ("[" .. floor (yards) .. "]")

		distance = abs (distance - 1)
		self.info.LastDistance = distance
		
		distance = Saturate (distance - 0.75) * 4
		local alpha = MapRangeClamped (_, 0, 1, 0, 0.5, distance)
		self.Arrow:SetAlpha (.5 + (alpha))
		self.ArrowDistance:SetVertexColor (distance, distance, distance)
		
		self.NextPositionUpdate = .5
		self.ForceUpdate = nil
	end

end


function WorldQuestTracker.SortTrackerByQuestDistance()
	WorldQuestTracker.ReorderQuestsOnTracker()
	WorldQuestTracker.RefreshTrackerWidgets()
end

--atualiza os widgets e reajusta a ancora
function WorldQuestTracker.RefreshTrackerWidgets()
	--reordena as quests
	WorldQuestTracker.ReorderQuestsOnTracker()
	--atualiza as quest no tracker
	local y = -30
	local nextWidget = 1
	local needSortByDistance = 0
	
	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		--verifica se a quest esta ativa, ela pode ser desativada se o jogador estiver dentro da area da quest
		if (not quest.isDisabled) then
			local widget = WorldQuestTracker.GetOrCreateTrackerWidget (nextWidget)
			widget:ClearAllPoints()
			widget:SetPoint ("topleft", WorldQuestTrackerFrame, "topleft", 0, y)
			widget.questID = quest.questID
			widget.info = quest
			widget.numObjectives = quest.numObjectives
			--widget.id = quest.questID
			
			local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (quest.questID)
			widget.Title:SetText (title)
			while (widget.Title:GetStringWidth() > TRACKER_TITLE_TEXTWIDTH_MAX) do
				title = strsub (title, 1, #title-1)
				widget.Title:SetText (title)
			end
			
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
			
			if (WorldQuestTracker.JustAddedToTracker [quest.questID]) then
				widget.AnimationFrame.ShowAnimation()
				WorldQuestTracker.JustAddedToTracker [quest.questID] = nil
			end
			
			if (Sort_currentMapID == quest.mapID) then
				local x, y = C_TaskQuest.GetQuestLocation (quest.questID, quest.mapID)
				widget.questX, widget.questY = x, y
				
				local curZone, zoneLeft, zoneTop, zoneRight, zoneBottom = GetCurrentMapZone()
				if (zoneLeft) then
					zoneXLength, zoneYLength = zoneLeft - zoneRight, zoneTop - zoneBottom
				end
				
				widget.NextPositionUpdate = -1
				widget.ForceUpdate = true
				
				widget:SetScript ("OnUpdate", TrackerOnTick)
				widget.Arrow:Show()
				widget.ArrowDistance:Show()
				widget.RightBackground:Show()
				widget:SetAlpha (TRACKER_FRAME_ALPHA_INMAP)
				widget.Title.textsize = TRACKER_TITLE_TEXT_SIZE_INMAP
				widget.Zone.textsize = TRACKER_TITLE_TEXT_SIZE_INMAP
				needSortByDistance = needSortByDistance + 1
				
				if (WorldQuestTracker.db.profile.show_yards_distance) then
					widget.YardsDistance:Show()
				else
					widget.YardsDistance:Hide()
				end
				
				--widget.Title.textcolor = "WQT_QUESTTITLE_INMAP"
				--widget.Zone.textcolor = "WQT_QUESTZONE_INMAP"
			else
				widget.Arrow:Hide()
				widget.ArrowDistance:Hide()
				widget.RightBackground:Hide()
				widget:SetAlpha (TRACKER_FRAME_ALPHA_OUTMAP)
				widget.Title.textsize = TRACKER_TITLE_TEXT_SIZE_OUTMAP
				widget.Zone.textsize = TRACKER_TITLE_TEXT_SIZE_OUTMAP
				widget.YardsDistance:SetText ("")
				widget:SetScript ("OnUpdate", nil)
				--widget.Title.textcolor = "WQT_QUESTTITLE_OUTMAP"
				--widget.Zone.textcolor = "WQT_QUESTZONE_OUTMAP"
			end
			
			y = y - 35
			nextWidget = nextWidget + 1
		end
	end
	
	if (IsInInstance()) then
		nextWidget = 1
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
	
	if (WorldQuestTracker.SortingQuestByDistance) then
		WorldQuestTracker.SortingQuestByDistance:Cancel()
		WorldQuestTracker.SortingQuestByDistance = nil
	end
	if (needSortByDistance >= 2 and not IsInInstance()) then
		WorldQuestTracker.SortingQuestByDistance = C_Timer.NewTicker (10, WorldQuestTracker.SortTrackerByQuestDistance)
	end
	
	--esconde os widgets não usados
	for i = nextWidget, #TrackerWidgetPool do
		TrackerWidgetPool [i]:SetScript ("OnUpdate", nil)
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
		if (module.Header:IsShown()) then
			y = y + module.contentsHeight
		end
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
--> taxy map widgets ~taxy ~fly
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

--não esta sendo usado no momento
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
	button:SetWidth (20)
	button:SetAlpha (1)
end
local format_for_taxy_nozoom_tracked = function (button)
	button:ClearWidget()

	button:SetScale (WorldQuestTracker.db.profile.taxy_tracked_scale)
	button:SetWidth (20)
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
	
	if (not WorldQuestTracker.FlyMapHook and FlightMapFrame) then
	
		WorldQuestTracker.Taxy_CurrentShownBlips = WorldQuestTracker.Taxy_CurrentShownBlips or {}
	
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
		checkboxShowAllQuests.tooltip = L["S_FLYMAP_SHOWWORLDQUESTS"]
		checkboxShowAllQuests:SetPoint ("bottomleft", FlightMapFrame.WorldQuestTrackerOptions, "bottomleft", 0, 0)
		local checkboxShowAllQuestsString = DF:CreateLabel (checkboxShowAllQuests, L["S_FLYMAP_SHOWWORLDQUESTS"], 12, "orange", nil, "checkboxShowAllQuestsLabel", nil, "overlay")
		checkboxShowAllQuestsString:SetPoint ("left", checkboxShowAllQuests, "right", 2, 0)
		
		local checkboxShowTrackedOnly_func = function (self, actorTypeIndex, value) 
			WorldQuestTracker.db.profile.taxy_trackedonly = value
		end
		local checkboxShowTrackedOnly = DF:CreateSwitch (FlightMapFrame.WorldQuestTrackerOptions, checkboxShowTrackedOnly_func, WorldQuestTracker.db.profile.taxy_trackedonly, _, _, _, _, "checkboxShowTrackedOnly", _, _, _, _, _, DF:GetTemplate ("switch", "OPTIONS_CHECKBOX_BRIGHT_TEMPLATE"))
		checkboxShowTrackedOnly:SetAsCheckBox()
		checkboxShowTrackedOnly:SetSize (16, 16)
		checkboxShowTrackedOnly.tooltip = L["S_FLYMAP_SHOWTRACKEDONLY_DESC"]
		checkboxShowTrackedOnly:SetPoint ("left", checkboxShowAllQuestsString, "right", 4, 0)
		local checkboxShowTrackedOnlyString = DF:CreateLabel (checkboxShowTrackedOnly, L["S_FLYMAP_SHOWTRACKEDONLY"], 12, "orange", nil, "checkboxShowTrackedOnlyLabel", nil, "overlay")
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
				WorldQuestTracker.Taxy_CurrentShownBlips [pin._WQT_Twin] = nil
				return
			end
			if (isShowingOnlyTracked) then
				if (not WorldQuestTracker.IsQuestBeingTracked (pin.questID) and not hasZoom) then
					pin._WQT_Twin:Hide()
					WorldQuestTracker.Taxy_CurrentShownBlips [pin._WQT_Twin] = nil
					return
				end
			end

			pin._WQT_Twin:Show()
			WorldQuestTracker.Taxy_CurrentShownBlips [pin._WQT_Twin] = true
			
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
	
	if (WorldQuestTracker.Taxy_CurrentShownBlips) then
		for _WQT_Twin, isShown in pairs (WorldQuestTracker.Taxy_CurrentShownBlips) do
			if (_WQT_Twin:IsShown() and not WorldQuestTracker.IsQuestBeingTracked (_WQT_Twin.questID)) then
				_WQT_Twin:Hide()
				WorldQuestTracker.Taxy_CurrentShownBlips [_WQT_Twin] = nil
				--local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (_WQT_Twin.questID)
				--print ("Taxy Hide", title)
			end
		end
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
		worldMapLocationMaxElvUI = {x = 10, y = -468, lineWidth = 330},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = azsuna_widgets,
	},
	[valsharah_mapId] = {
		worldMapLocation = {x = 10, y = -218, lineWidth = 240},
		worldMapLocationMax = {x = 168, y = -284, lineWidth = 340},
		worldMapLocationMaxElvUI = {x = 10, y = -284, lineWidth = 340},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = valsharah_widgets,
	},
	[highmountain_mapId] = {
		worldMapLocation = {x = 10, y = -179, lineWidth = 320},
		worldMapLocationMax = {x = 168, y = -230, lineWidth = 452},
		worldMapLocationMaxElvUI = {x = 10, y = -230, lineWidth = 452},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = highmountain_widgets,
	},
	[stormheim_mapId] = {
		worldMapLocation = {x = 415, y = -235, lineWidth = 277},
		worldMapLocationMax = {x = 747, y = -313, lineWidth = 393},
		worldMapLocationMaxElvUI = {x = 600, y = -313, lineWidth = 393},
		bipAnchor = {side = "left", x = 0, y = -1},
		factionAnchor = {mySide = "right", anchorSide = "left", x = -0, y = 0},
		squarePoints = {mySide = "topright", anchorSide = "bottomright", y = -1, xDirection = -1},
		widgets = stormheim_widgets,
	},
	[suramar_mapId] = {
		worldMapLocation = {x = 327, y = -277, lineWidth = 365},
		worldMapLocationMax = {x = 618, y = -367, lineWidth = 522},
		worldMapLocationMaxElvUI = {x = 471, y = -367, lineWidth = 522},
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
	line:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\line_tiletextureT]], true)
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
	factionQuestAmountBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
	--factionQuestAmountBackground:SetTexCoord (12/512, 74/512, 251/512, 281/512)
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

--cria uma square widget no world map ~world ~createworld
local create_worldmap_square = function (mapName, index)
	local button = CreateFrame ("button", "WorldQuestTrackerWorldMapPOI" .. mapName .. "POI" .. index, worldFramePOIs)
	button:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	button.IsWorldQuestButton = true
	button:SetFrameLevel (302)
	
	button:SetScript ("OnEnter", questButton_OnEnter)
	button:SetScript ("OnLeave", questButton_OnLeave)
	button:SetScript ("OnClick", questButton_OnClick)
	
	local fadeInAnimation = button:CreateAnimationGroup()
	local step1 = fadeInAnimation:CreateAnimation ("Alpha")
	step1:SetOrder (1)
	step1:SetFromAlpha (0)
	step1:SetToAlpha (1)
	step1:SetDuration (0.1)
	button.fadeInAnimation = fadeInAnimation
	
	tinsert (all_widgets, button)
	
	local background = button:CreateTexture (nil, "background", -3)
	background:SetAllPoints()	
	
	local texture = button:CreateTexture (nil, "background", -2)
	texture:SetAllPoints()	
	
	local commonBorder = button:CreateTexture (nil, "artwork", 1)
	commonBorder:SetPoint ("topleft", button, "topleft")
	commonBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_whiteT]])
	commonBorder:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	local rareBorder = button:CreateTexture (nil, "artwork", 1)
	rareBorder:SetPoint ("topleft", button, "topleft")
	rareBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_blueT]])
	rareBorder:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	local epicBorder = button:CreateTexture (nil, "artwork", 1)
	epicBorder:SetPoint ("topleft", button, "topleft")
	epicBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_pinkT]])
	epicBorder:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	local trackingBorder = button:CreateTexture (nil, "artwork", 1)
	trackingBorder:SetPoint ("topleft", button, "topleft")
	trackingBorder:SetTexture ([[Interface\Artifacts\Artifacts]])
	trackingBorder:SetTexCoord (269/1024, 327/1024, 943/1024, 1001/1024)
	trackingBorder:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	
	local borderAnimation = CreateFrame ("frame", "$parentBorderShineAnimation", button, "AutoCastShineTemplate")
	borderAnimation:SetFrameLevel (303)
	borderAnimation:SetPoint ("topleft", 2, -2)
	borderAnimation:SetPoint ("bottomright", -2, 2)
	borderAnimation:SetAlpha (.05)
	borderAnimation:Hide()
	button.borderAnimation = borderAnimation
	
	local shineAnimation = CreateFrame ("frame", "$parentShine", button, "AnimatedShineTemplate")
	shineAnimation:SetFrameLevel (303)
	shineAnimation:SetAllPoints()
	shineAnimation:Hide()
	button.shineAnimation = shineAnimation
	
	local trackingGlowBorder = button:CreateTexture (nil, "overlay", 1)
	trackingGlowBorder:SetPoint ("center", button, "center")
	trackingGlowBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_trackingT]])
	trackingGlowBorder:SetSize (WORLDMAP_SQUARE_SIZE * 1.33, WORLDMAP_SQUARE_SIZE * 1.33)
	trackingGlowBorder:Hide()
	
	trackingGlowBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\glow_yellow_squareT]])
	trackingGlowBorder:SetBlendMode ("ADD")
	--trackingGlowBorder:SetDesaturated (true)
	trackingGlowBorder:SetSize (55, 55)
	trackingGlowBorder:SetAlpha (.6)
	trackingGlowBorder:SetDrawLayer ("BACKGROUND", -5)
	
	local onStartTrackAnimation = DF:CreateAnimationHub (trackingGlowBorder, onStartClickAnimation)
	WorldQuestTracker:CreateAnimation (onStartTrackAnimation, "Scale", 1, .12, .9, .9, 1, 1)
	local onEndTrackAnimation = DF:CreateAnimationHub (trackingGlowBorder, onStartClickAnimation, onEndClickAnimation)
	WorldQuestTracker:CreateAnimation (onEndTrackAnimation, "Scale", 1, .5, 1, 1, .6, .6)
	button.onStartTrackAnimation = onStartTrackAnimation
	button.onEndTrackAnimation = onEndTrackAnimation
	
	local shadow = button:CreateTexture (nil, "BACKGROUND")
	shadow:SetTexture ([[Interface\COMMON\icon-shadow]])
	shadow:SetAlpha (.3)
	local shadow_offset = 8
	shadow:SetPoint ("topleft", -shadow_offset, shadow_offset)
	shadow:SetPoint ("bottomright", shadow_offset, -shadow_offset)
	
	local criteriaFrame = CreateFrame ("frame", nil, button)
	local criteriaIndicator = criteriaFrame:CreateTexture (nil, "OVERLAY", 2)
	criteriaIndicator:SetPoint ("bottomleft", button, "bottomleft", -2, 0)
	criteriaIndicator:SetSize (23*.4, 37*.4)
	criteriaIndicator:SetAlpha (.8)
	criteriaIndicator:SetTexture ([[Interface\AdventureMap\AdventureMap]])
	criteriaIndicator:SetTexCoord (901/1024, 924/1024, 251/1024, 288/1024)
	criteriaIndicator:Hide()
	criteriaFrame.Texture = criteriaIndicator
	local criteriaIndicatorGlow = criteriaFrame:CreateTexture (nil, "OVERLAY", 1)
	criteriaIndicatorGlow:SetPoint ("center", criteriaIndicator, "center")
	criteriaIndicatorGlow:SetSize (18, 18)
	criteriaIndicatorGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\criteriaIndicatorGlowT]])
	criteriaIndicatorGlow:SetTexCoord (0, 1, 0, 1)
	criteriaIndicatorGlow:Hide()
	criteriaFrame.Glow = criteriaIndicatorGlow
	
	local criteriaAnimation = DF:CreateAnimationHub (criteriaFrame)
	DF:CreateAnimation (criteriaAnimation, "Scale", 1, .15, 1, 1, 1.1, 1.1)
	DF:CreateAnimation (criteriaAnimation, "Scale", 2, .15, 1.2, 1.2, 1, 1)
	button.CriteriaAnimation = criteriaAnimation

	commonBorder:Hide()
	rareBorder:Hide()
	epicBorder:Hide()
	trackingBorder:Hide()
	
--	local timeBlip = button:CreateTexture (nil, "overlay", 2)
--	timeBlip:SetPoint ("bottomright", button, "bottomright", 2, -2)
--	timeBlip:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	
	--blip do tempo restante
	button.timeBlipRed = button:CreateTexture (nil, "OVERLAY")
	button.timeBlipRed:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipRed:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipRed:SetTexture ([[Interface\COMMON\Indicator-Red]])
	button.timeBlipRed:SetVertexColor (1, 1, 1)
	button.timeBlipRed:SetAlpha (1)
	
	button.timeBlipOrange = button:CreateTexture (nil, "OVERLAY")
	button.timeBlipOrange:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipOrange:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipOrange:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
	button.timeBlipOrange:SetVertexColor (1, .7, 0)
	button.timeBlipOrange:SetAlpha (.9)
	
	button.timeBlipYellow = button:CreateTexture (nil, "OVERLAY")
	button.timeBlipYellow:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipYellow:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipYellow:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
	button.timeBlipYellow:SetVertexColor (1, 1, 1)
	button.timeBlipYellow:SetAlpha (.8)
	
	button.timeBlipGreen = button:CreateTexture (nil, "OVERLAY")
	button.timeBlipGreen:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipGreen:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipGreen:SetTexture ([[Interface\COMMON\Indicator-Green]])
	button.timeBlipGreen:SetVertexColor (1, 1, 1)
	button.timeBlipGreen:SetAlpha (.6)	
	
	button.questTypeBlip = button:CreateTexture (nil, "OVERLAY", 2)
	button.questTypeBlip:SetPoint ("topright", button, "topright", 2, 1)
	button.questTypeBlip:SetSize (12, 12)
	
	local amountText = button:CreateFontString (nil, "overlay", "GameFontNormal", 1)
	amountText:SetPoint ("top", button, "bottom", 1, 0)
	DF:SetFontSize (amountText, 9)
	
	local amountBackground = button:CreateTexture (nil, "overlay", 0)
	amountBackground:SetPoint ("center", amountText, "center")
	amountBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
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
	
	local new = button:CreateTexture (nil, "overlay")
	--new:SetPoint ("bottom", button, "bottom", 0, -2)
	--new:SetPoint ("bottom", button, "bottom", 0, -5)
	new:SetPoint ("bottom", button, "top", 0, -5)
	new:SetSize (64*.45, 32*.45)
	new:SetAlpha (.75)
	new:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\new]])
	button.newIndicator = new
	
	local newFlashTexture = button:CreateTexture (nil, "overlay")
	newFlashTexture:SetPoint ("bottom", new, "bottom")
	newFlashTexture:SetSize (64*.45, 32*.45)
	newFlashTexture:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\new]])
	newFlashTexture:Hide()
	
	local newFlash = newFlashTexture:CreateAnimationGroup()
	newFlash.In = newFlash:CreateAnimation ("Alpha")
	newFlash.In:SetOrder (1)
	newFlash.In:SetFromAlpha (0)
	newFlash.In:SetToAlpha (1)
	newFlash.In:SetDuration (.3)
	newFlash.On = newFlash:CreateAnimation ("Alpha")
	newFlash.On:SetOrder (2)
	newFlash.On:SetFromAlpha (1)
	newFlash.On:SetToAlpha (1)
	newFlash.On:SetDuration (2)
	newFlash.Out = newFlash:CreateAnimation ("Alpha")
	newFlash.Out:SetOrder (3)
	newFlash.Out:SetFromAlpha (1)
	newFlash.Out:SetToAlpha (0)
	newFlash.Out:SetDuration (10)
	newFlash:SetScript ("OnPlay", function()
		newFlashTexture:Show()
	end)
	newFlash:SetScript ("OnFinished", function()
		newFlashTexture:Hide()
	end)
	button.newFlash = newFlash
	
	shadow:SetDrawLayer ("BACKGROUND", -6)
	trackingGlowBorder:SetDrawLayer ("BACKGROUND", -5)
	--trackingGlowBorder:SetDrawLayer ("overlay", 7)
	background:SetDrawLayer ("background", -3)
	texture:SetDrawLayer ("background", -2)
	commonBorder:SetDrawLayer ("border", 1)
	rareBorder:SetDrawLayer ("border", 1)
	epicBorder:SetDrawLayer ("border", 1)
	trackingBorder:SetDrawLayer ("border", 2)
	amountBackground:SetDrawLayer ("overlay", 0)
	amountText:SetDrawLayer ("overlay", 1)
	criteriaIndicatorGlow:SetDrawLayer ("OVERLAY", 1)
	criteriaIndicator:SetDrawLayer ("OVERLAY", 2)
	newFlashTexture:SetDrawLayer ("OVERLAY", 7)
	new:SetDrawLayer ("OVERLAY", 6)
	
	button.timeBlipRed:SetDrawLayer ("overlay", 2)
	button.timeBlipOrange:SetDrawLayer ("overlay", 2)
	button.timeBlipYellow:SetDrawLayer ("overlay", 2)
	button.timeBlipGreen:SetDrawLayer ("overlay", 2)
	
	highlight:SetDrawLayer ("highlight", 1)
	criteriaHighlight:SetDrawLayer ("highlight", 2)
	
	button.background = background
	button.texture = texture
	button.commonBorder = commonBorder
	button.rareBorder = rareBorder
	button.epicBorder = epicBorder
	button.trackingBorder = trackingBorder
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
	
	if (ElvUI) then
		if (not ElvDB.global.general.smallerWorldMap and not WorldMapFrame_InWindowedMode() and not WorldQuestTracker.InFullScreenMode) then
			--fullscreen
			line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocationMax.x, configTable.worldMapLocationMax.y)
			line:SetWidth (configTable.worldMapLocationMax.lineWidth)
			
		elseif (WorldMapFrameSizeUpButton:IsShown()) then
			--normal size
			line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocation.x, configTable.worldMapLocation.y)
			line:SetWidth (configTable.worldMapLocation.lineWidth)
		elseif (WorldMapFrameSizeDownButton:IsShown()) then
			--centralized
			line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocationMaxElvUI.x, configTable.worldMapLocationMaxElvUI.y)
			line:SetWidth (configTable.worldMapLocationMaxElvUI.lineWidth)
		end
	else
		if (WorldQuestTracker.InWindowMode) then
			line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocation.x, configTable.worldMapLocation.y)
			line:SetWidth (configTable.worldMapLocation.lineWidth)
		else
			line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocationMax.x, configTable.worldMapLocationMax.y)
			line:SetWidth (configTable.worldMapLocationMax.lineWidth)
		end
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
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true) --no cache true
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

local re_check_for_questcompleted = function()
	WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true, true, true)
end

-- ~filter
function WorldQuestTracker.GetQuestFilterTypeAndOrder (worldQuestType, gold, rewardName, itemName, isArtifact, stackAmount)
	local filter, order
	
	if (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
		return FILTER_TYPE_PET_BATTLES, WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_PETBATTLE]
	elseif (worldQuestType == LE_QUEST_TAG_TYPE_PVP) then
		return FILTER_TYPE_PVP, WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_PVP]
	elseif (worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION) then
		return FILTER_TYPE_PROFESSION, WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_PROFESSION]
	elseif (worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON) then
		filter = FILTER_TYPE_DUNGEON
		order = WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_DUNGEON]
	end
	
	if (gold and gold > 0) then
		order = WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_GOLD]
		filter = FILTER_TYPE_GOLD
	elseif (rewardName) then
		order = WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_RESOURCE]
		filter = FILTER_TYPE_GARRISON_RESOURCE
	elseif (isArtifact) then
		order = WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_APOWER]
		filter = FILTER_TYPE_ARTIFACT_POWER
	elseif (itemName) then
		if (stackAmount > 1) then
			order = WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_TRADE]
			filter = FILTER_TYPE_TRADESKILL
		else
			order = WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_EQUIPMENT]
			filter = FILTER_TYPE_EQUIPMENT
		end
	end
	
	return filter, order
end

local quest_bugged = {}

--faz a atualização dos widgets no world map ~world
function WorldQuestTracker.UpdateWorldQuestsOnWorldMap (noCache, showFade, isQuestFlaggedRecheck, forceCriteriaAnimation)

	if (UnitLevel ("player") < 110) then
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
		return
	elseif (not IsQuestFlaggedCompleted (WORLD_QUESTS_AVAILABLE_QUEST_ID)) then
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
		--print ("quest nao completada...")
		if (not isQuestFlaggedRecheck) then
			C_Timer.After (3, re_check_for_questcompleted)
		end
		return
	end
	
	WorldQuestTracker.LastUpdate = GetTime()
	wipe (factionAmountForEachMap)
	
	--mostrar os widgets extras
	for _, widget in ipairs (extra_widgets) do
		widget:Show()
	end
	
--	
	if (WorldQuestTracker.WorldWidgets_NeedFullRefresh) then
		WorldQuestTracker.WorldWidgets_NeedFullRefresh = nil
		noCache = true
	end
	
	local questsAvailable = {}
	local needAnotherUpdate = false
	local filters = WorldQuestTracker.db.profile.filters
	
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		
		questsAvailable [mapId] = {}
		local taskInfo = GetQuestsForPlayerByMapID (mapId)
		
		if (taskInfo and #taskInfo > 0) then
			for i, info in ipairs (taskInfo) do
				local questID = info.questId
				if (HaveQuestData (questID)) then
					local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
					if (isWorldQuest) then
						--gold
						local gold, goldFormated = WorldQuestTracker.GetQuestReward_Gold (questID)
						--class hall resource
						local rewardName, rewardTexture, numRewardItems = WorldQuestTracker.GetQuestReward_Resource (questID)
						--item
						local itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetQuestReward_Item (questID)
						--type
						local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
						
						--print (tradeskillLineIndex)
						--tradeskillLineIndex = usado pra essa função GetProfessionInfo (tradeskillLineIndex)
						--WORLD_QUEST_ICONS_BY_PROFESSION[tradeskillLineID]
						--local tradeskillLineID = tradeskillLineIndex and select(7, GetProfessionInfo(tradeskillLineIndex));
						
						if ((not gold or gold <= 0) and not rewardName and not itemName) then
							needAnotherUpdate = true
						end
						
						local filter, order = WorldQuestTracker.GetQuestFilterTypeAndOrder (worldQuestType, gold, rewardName, itemName, isArtifact, stackAmount)
						order = order or 1
						if (filters [filter]) then
							tinsert (questsAvailable [mapId], {questID, order, info.numObjectives})
						else
							if (WorldQuestTracker.db.profile.filter_always_show_faction_objectives) then
								local isCriteria = WorldMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty (questID)
								if (isCriteria) then
									tinsert (questsAvailable [mapId], {questID, order, info.numObjectives})
								end
							end
						end
					end
				else
					quest_bugged [questID] = (quest_bugged [questID] or 0) + 1
					if (quest_bugged [questID] < 20) then
						needAnotherUpdate = true
					end
				end
			end
			
			table.sort (questsAvailable [mapId], function (t1, t2) return t1[2] < t2[2] end)
		else
			needAnotherUpdate = true
		end
	end
	
--	
	
	local availableQuests = 0

	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		local taskInfo = GetQuestsForPlayerByMapID (mapId)
		local taskIconIndex = 1
		local widgets = configTable.widgets
		
		if (taskInfo and #taskInfo > 0) then
			availableQuests = availableQuests + #taskInfo
			
			--for i, info  in ipairs (taskInfo) do
			for i, quest in ipairs (questsAvailable [mapId]) do
			--print (i, quest)
				--local questID = info.questId
				local questID = quest [1]
				local numObjectives = quest [3]

				if (HaveQuestData (questID)) then
					local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
					if (isWorldQuest) then
					
						C_TaskQuest.RequestPreloadRewardData (questID)
						
						--se é nova
						local isNew = WorldQuestTracker.SavedQuestList_IsNew (questID)
						--isNew = true --debug
						
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
							
								widget.timeBlipRed:Hide()
								widget.timeBlipOrange:Hide()
								widget.timeBlipYellow:Hide()
								widget.timeBlipGreen:Hide()
							
								if (widget.lastQuestID == questID and not noCache) then
									--precisa apenas atualizar o tempo
									WorldQuestTracker.SetTimeBlipColor (widget, timeLeft)
									widget.questID = questID
									widget.mapID = mapId
									
									--WorldQuestTracker.SetIconTexture (widget, false, false, false)
									widget:Show()
									
									if (widget.texture:GetTexture() == nil) then
										WorldQuestTracker.ScheduleWorldMapUpdate()
									end
									
									if (isCriteria) then
										if (not widget.criteriaIndicator:IsShown() or forceCriteriaAnimation) then
											widget.CriteriaAnimation:Play()
										end
										widget.criteriaIndicator:Show()
										widget.criteriaHighlight:Show()
										widget.criteriaIndicatorGlow:Show()
									else
										widget.criteriaIndicator:Hide()
										widget.criteriaHighlight:Hide()
										widget.criteriaIndicatorGlow:Hide()
									end
									
									if (isNew) then
										widget.newIndicator:Show()
										widget.newFlash:Play()
									else
										widget.newIndicator:Hide()
									end
									
									if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
										widget.trackingGlowBorder:Show()
									else
										--widget.trackingGlowBorder:Hide()
									end
									
								else
									--faz uma atualização total do bloco
									widget:Show()
									
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
									--widget.numObjectives = info.numObjectives
									widget.numObjectives = numObjectives
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
									
									if (isNew) then
										widget.newIndicator:Show()
										widget.newFlash:Play()
									else
										widget.newIndicator:Hide()
									end
									
									if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
										widget.trackingGlowBorder:Show()
									else
										widget.trackingGlowBorder:Hide()
									end
									
									WorldQuestTracker.SetTimeBlipColor (widget, timeLeft)
									widget.amountBackground:SetWidth (32)
									
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
										--WorldQuestTracker.SetIconTexture (widget.texture, texture, false, false)
										
										widget.amountText:SetText (goldFormated)
										widget.amountBackground:Show()
										
										widget.IconTexture = texture
										widget.IconText = goldFormated
										widget.QuestType = QUESTTYPE_GOLD
										okey = true
									end
									if (rewardName) then
										widget.texture:SetTexture (rewardTexture)
										--WorldQuestTracker.SetIconTexture (widget.texture, rewardTexture, false, false)
										--widget.texture:SetTexCoord (0, 1, 0, 1)
										if (numRewardItems >= 1000) then
											widget.amountText:SetText (format ("%.1fK", numRewardItems/1000))
											widget.amountBackground:SetWidth (40)
										else
											widget.amountText:SetText (numRewardItems)
										end
										widget.amountBackground:Show()
										
										widget.IconTexture = rewardTexture
										widget.IconText = numRewardItems
										widget.QuestType = QUESTTYPE_RESOURCE
										okey = true
									
									elseif (itemName) then
										if (isArtifact) then
											local artifactIcon = WorldQuestTracker.GetArtifactPowerIcon (artifactPower)
											widget.texture:SetTexture (artifactIcon)
											--WorldQuestTracker.SetIconTexture (widget.texture, artifactIcon, false, false)
											widget.isArtifact = true
											if (artifactPower >= 1000) then
												widget.amountText:SetText (format ("%.1fK", artifactPower/1000))
												widget.amountBackground:SetWidth (36)
											else
												widget.amountText:SetText (artifactPower)
											end
											widget.amountBackground:Show()
											
											local artifactIcon = WorldQuestTracker.GetArtifactPowerIcon (artifactPower, true)
											widget.IconTexture = artifactIcon
											widget.IconText = artifactPower
											widget.QuestType = QUESTTYPE_ARTIFACTPOWER
										else
											widget.texture:SetTexture (itemTexture)
											--WorldQuestTracker.SetIconTexture (widget.texture, itemTexture, false, false)
											--widget.texture:SetTexCoord (0, 1, 0, 1)
											if (itemLevel > 600 and itemLevel < 780) then
												itemLevel = 810
											end
											
											widget.amountText:SetText ((isStackable and quantity and quantity >= 1 and quantity or false) or (itemLevel and itemLevel > 5 and itemLevel) or "")

											if (widget.amountText:GetText() and widget.amountText:GetText() ~= "") then
												widget.amountBackground:Show()
											else
												widget.amountBackground:Hide()
											end
											
											widget.IconTexture = itemTexture
											widget.IconText = widget.amountText:GetText()
											widget.QuestType = QUESTTYPE_ITEM
										end
										
										WorldQuestTracker.AllCharactersQuests_Add (questID, timeLeft, widget.IconTexture, widget.IconText)
										
										okey = true
									
									else
										--unknown quest?
									end
									
									if (not okey) then
										needAnotherUpdate = true
									end
								end
							end

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
			needAnotherUpdate = true
		end
		
		--quantidade de quest para a faccao
		configTable.factionFrame.amount = factionAmountForEachMap [mapId]
	end
	
	if (needAnotherUpdate) then
		if (WorldMapFrame:IsShown()) then
			WorldQuestTracker.ScheduleWorldMapUpdate (1.5)
			WorldQuestTracker.PlayLoadingAnimation()
		end
	else
		if (WorldQuestTracker.QueuedRefresh > 0) then
			WorldQuestTracker.ScheduleWorldMapUpdate (1.5)
			WorldQuestTracker.QueuedRefresh = WorldQuestTracker.QueuedRefresh - 1
		else
			if (WorldQuestTracker.IsPlayingLoadAnimation()) then
				WorldQuestTracker.StopLoadingAnimation()
			end
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
	
	if (ElvUI) then
	
		if (not ElvDB.global.general.smallerWorldMap and not WorldMapFrame_InWindowedMode() and not WorldQuestTracker.InFullScreenMode) then
			--fullscreen
			for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
				configTable.line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocationMax.x, configTable.worldMapLocationMax.y)
				configTable.line:SetWidth (configTable.worldMapLocationMax.lineWidth)
			end
			WorldQuestTracker.InFullScreenMode = true
			WorldQuestTracker.InWindowMode = false
			
		elseif (WorldMapFrameSizeUpButton:IsShown() and not WorldQuestTracker.InWindowMode) then
			--normal size
			for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
				configTable.line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocation.x, configTable.worldMapLocation.y)
				configTable.line:SetWidth (configTable.worldMapLocation.lineWidth)
			end
			WorldQuestTracker.InWindowMode = true
			WorldQuestTracker.InFullScreenMode = false
			
		elseif (WorldMapFrameSizeDownButton:IsShown() and WorldQuestTracker.InWindowMode) then
			--centralized
			for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
				configTable.line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocationMaxElvUI.x, configTable.worldMapLocationMaxElvUI.y)
				configTable.line:SetWidth (configTable.worldMapLocationMaxElvUI.lineWidth)
			end
			WorldQuestTracker.InWindowMode = false
			WorldQuestTracker.InFullScreenMode = false
		end
	else
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
	end
	
	WorldQuestTracker.HideZoneWidgets()
	WorldQuestTracker.SavedQuestList_CleanUp()
	
	calcPerformance.DumpTime = 0
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

function WorldQuestTracker.UpdateLoadingIconAnchor()
	local adjust_anchor = false
	if (GetCVarBool ("questLogOpen")) then
		if (WorldMapFrame_InWindowedMode()) then
			adjust_anchor = true
		end
	end
	
	if (adjust_anchor) then
		WorldQuestTracker.LoadingAnimation:SetPoint ("bottom", WorldMapScrollFrame, "top", 0, -75)
	else
		WorldQuestTracker.LoadingAnimation:SetPoint ("bottom", WorldMapScrollFrame, "top", 0, -75)
	end
end
function WorldQuestTracker.NeedUpdateLoadingIconAnchor()
	if (WorldQuestTracker.LoadingAnimation.FadeIN:IsPlaying()) then
		WorldQuestTracker.UpdateLoadingIconAnchor()
	elseif (WorldQuestTracker.LoadingAnimation.FadeOUT:IsPlaying()) then
		WorldQuestTracker.UpdateLoadingIconAnchor()
	elseif (WorldQuestTracker.LoadingAnimation.Loop:IsPlaying()) then
		WorldQuestTracker.UpdateLoadingIconAnchor()
	end
end
hooksecurefunc ("QuestMapFrame_Open", function()
	WorldQuestTracker.NeedUpdateLoadingIconAnchor()
end)
hooksecurefunc ("QuestMapFrame_Close", function()
	WorldQuestTracker.NeedUpdateLoadingIconAnchor()
end)

--C_Timer.NewTicker (5, function()WorldQuestTracker.PlayLoadingAnimation()end)
function WorldQuestTracker.CreateLoadingIcon()
	local f = CreateFrame ("frame", nil, WorldMapFrame)
	f:SetSize (48, 48)
	f:SetPoint ("bottom", WorldMapScrollFrame, "top", 0, -75) --289/2 = 144
	f:SetFrameLevel (3000)
	
	local animGroup1 = f:CreateAnimationGroup()
	local anim1 = animGroup1:CreateAnimation ("Alpha")
	anim1:SetOrder (1)
	anim1:SetFromAlpha (0)
	anim1:SetToAlpha (1)
	anim1:SetDuration (2)
	f.FadeIN = animGroup1
	
	local animGroup2 = f:CreateAnimationGroup()
	local anim2 = animGroup2:CreateAnimation ("Alpha")
	f.FadeOUT = animGroup2
	anim2:SetOrder (2)
	anim2:SetFromAlpha (1)
	anim2:SetToAlpha (0)
	anim2:SetDuration (4)
	animGroup2:SetScript ("OnFinished", function()
		f:Hide()
	end)
	
	f.Text = f:CreateFontString (nil, "overlay", "GameFontNormal")
	f.Text:SetText ("please wait...")
	f.Text:SetPoint ("left", f, "right", -5, 1)
	f.TextBackground = f:CreateTexture (nil, "background")
	f.TextBackground:SetPoint ("left", f, "right", -20, 0)
	f.TextBackground:SetSize (160, 14)
	f.TextBackground:SetTexture ([[Interface\COMMON\ShadowOverlay-Left]])
	
	f.Text:Hide()
	f.TextBackground:Hide()
	
	f.CircleAnimStatic = CreateFrame ("frame", nil, f)
	f.CircleAnimStatic:SetAllPoints()
	f.CircleAnimStatic.Alpha = f.CircleAnimStatic:CreateTexture (nil, "overlay")
	f.CircleAnimStatic.Alpha:SetTexture ([[Interface\COMMON\StreamFrame]])
	f.CircleAnimStatic.Alpha:SetAllPoints()
	f.CircleAnimStatic.Background = f.CircleAnimStatic:CreateTexture (nil, "background")
	f.CircleAnimStatic.Background:SetTexture ([[Interface\COMMON\StreamBackground]])
	f.CircleAnimStatic.Background:SetAllPoints()
	
	f.CircleAnim = CreateFrame ("frame", nil, f)
	f.CircleAnim:SetAllPoints()
	f.CircleAnim.Spinner = f.CircleAnim:CreateTexture (nil, "artwork")
	f.CircleAnim.Spinner:SetTexture ([[Interface\COMMON\StreamCircle]])
	f.CircleAnim.Spinner:SetVertexColor (.5, 1, .5, 1)
	f.CircleAnim.Spinner:SetAllPoints()
	f.CircleAnim.Spark = f.CircleAnim:CreateTexture (nil, "overlay")
	f.CircleAnim.Spark:SetTexture ([[Interface\COMMON\StreamSpark]])
	f.CircleAnim.Spark:SetAllPoints()

	local animGroup3 = f.CircleAnim:CreateAnimationGroup()
	animGroup3:SetLooping ("Repeat")
	local animLoop = animGroup3:CreateAnimation ("Rotation")
	f.Loop = animGroup3
	animLoop:SetOrder (1)
	animLoop:SetDuration (6)
	animLoop:SetDegrees (-360)
	animLoop:SetTarget (f.CircleAnim)
	
	WorldQuestTracker.LoadingAnimation = f
	WorldQuestTracker.UpdateLoadingIconAnchor()
	
	f:Hide()
end

function WorldQuestTracker.IsPlayingLoadAnimation()
	return WorldQuestTracker.LoadingAnimation.IsPlaying
end
function WorldQuestTracker.PlayLoadingAnimation()
	if (not WorldQuestTracker.IsPlayingLoadAnimation()) then
		WorldQuestTracker.LoadingAnimation:Show()
		WorldQuestTracker.LoadingAnimation.FadeIN:Play()
		WorldQuestTracker.LoadingAnimation.Loop:Play()
		WorldQuestTracker.LoadingAnimation.IsPlaying = true
	end
end
function WorldQuestTracker.StopLoadingAnimation()
	WorldQuestTracker.LoadingAnimation.FadeOUT:Play()
	WorldQuestTracker.LoadingAnimation.IsPlaying = false
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
		self.objectiveCompletedBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
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
	if (WorldMapFrame.mapID == MAPID_BROKENISLES) then
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, false, false, true)
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

-- doq dow endf