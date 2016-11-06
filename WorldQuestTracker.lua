
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

-- 219978
-- /run SetSuperTrackedQuestID(44033);
-- TaskPOI_OnClick
 
do
	--register things we'll use
	local color = OBJECTIVE_TRACKER_COLOR ["Header"]
	DF:NewColor ("WQT_QUESTTITLE_INMAP", color.r, color.g, color.b, .8)
	DF:NewColor ("WQT_QUESTTITLE_OUTMAP", 1, .8, .2, .7)
	DF:NewColor ("WQT_QUESTZONE_INMAP", 1, 1, 1, 1)
	DF:NewColor ("WQT_QUESTZONE_OUTMAP", 1, 1, 1, .7)
	DF:NewColor ("WQT_ORANGE_ON_ENTER", 1, 0.847059, 0, 1)
	DF:NewColor ("WQT_ORANGE_RESOURCES_AVAILABLE", 1, .7, .2, .85)
	
	DF:InstallTemplate ("font", "WQT_SUMMARY_TITLE", {color = "orange", size = 12, font = "Friz Quadrata TT"})
	DF:InstallTemplate ("font", "WQT_RESOURCES_AVAILABLE", {color = {1, .7, .2, .85}, size = 10, font = "Friz Quadrata TT"})
end

local GameCooltip = GameCooltip2
local Saturate = Saturate
local floor = floor
local ceil = ceil
local ipairs = ipairs
local GetItemInfo = GetItemInfo
local p = math.pi/2
local pi = math.pi
local pipi = math.pi*2
local GetPlayerFacing = GetPlayerFacing
local GetPlayerMapPosition = GetPlayerMapPosition
local GetCurrentMapZone = GetCurrentMapZone
local GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID
local HaveQuestData = HaveQuestData
local QuestMapFrame_IsQuestWorldQuest = QuestMapFrame_IsQuestWorldQuest or QuestUtils_IsQuestWorldQuest
local GetNumQuestLogRewardCurrencies = GetNumQuestLogRewardCurrencies
local GetQuestLogRewardInfo = GetQuestLogRewardInfo
local GetQuestLogRewardCurrencyInfo = GetQuestLogRewardCurrencyInfo
local GetQuestLogRewardMoney = GetQuestLogRewardMoney
--local GetQuestLogIndexByID = GetQuestLogIndexByID
local GetQuestTagInfo = GetQuestTagInfo
local GetNumQuestLogRewards = GetNumQuestLogRewards
local GetQuestInfoByQuestID = C_TaskQuest.GetQuestInfoByQuestID
--local LE_WORLD_QUEST_QUALITY_COMMON = LE_WORLD_QUEST_QUALITY_COMMON
--local LE_WORLD_QUEST_QUALITY_RARE = LE_WORLD_QUEST_QUALITY_RARE
--local LE_WORLD_QUEST_QUALITY_EPIC = LE_WORLD_QUEST_QUALITY_EPIC
local GetQuestTimeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes

local MapRangeClamped = DF.MapRangeClamped
local FindLookAtRotation = DF.FindLookAtRotation
local GetDistance_Point = DF.GetDistance_Point

--importing FindLookAtRotation
if (not FindLookAtRotation) then
	FindLookAtRotation = function (_, x1, y1, x2, y2)
		return atan2 (y2 - y1, x2 - x1) + pi
	end
end

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
		worldmap_widgets = {
			textsize = 9,
			scale = 1,
		},
		zonemap_widgets = {
			scale = 1,
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
		sort_time_priority = false,
		force_sort_by_timeleft = false,
		alpha_time_priority = true,
		show_timeleft = false,
		quests_tracked = {},
		quests_all_characters = {},
		syntheticMapIdList = {
			[1015] = 1, --azsuna
			[1018] = 2, --valsharah
			[1024] = 3, --highmountain
			[1017] = 4, --stormheim
			[1033] = 5, --suramar
			[1096] = 6, --eye of azshara
		},
		taxy_showquests = true,
		taxy_trackedonly = false,
		taxy_tracked_scale = 3,
		arrow_update_frequence = 0.016,
		map_lock = false,
		enable_doubletap = false,
		sound_enabled = true,
		use_tracker = true,
		tracker_is_movable = false,
		tracker_is_locked = false,
		tracker_only_currentmap = false,
		tracker_scale = 1,
		tracker_show_time = false,
		use_quest_summary = false,
		bar_anchor = "bottom",
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
		tomtom = {
			enabled = false,
			uids = {},
			persistent = true,
		},
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

local WORLDMAP_SQUARE_SIZE = 24
local WORLDMAP_SQUARE_TIMEBLIP_SIZE = 14

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
	[eoa_mapId] = true, --eye of azshara
}

local WorldQuestTracker = DF:CreateAddOn ("WorldQuestTrackerAddon", "WQTrackerDB", default_config)
WorldQuestTracker.QuestTrackList = {} --place holder until OnInit is triggered
WorldQuestTracker.AllTaskPOIs = {}
WorldQuestTracker.JustAddedToTracker = {}
WorldQuestTracker.Cache_ShownQuestOnWorldMap = {}
WorldQuestTracker.Cache_ShownQuestOnZoneMap = {}
WorldQuestTracker.Cache_ShownWidgetsOnZoneMap = {}
WorldQuestTracker.WorldMapSupportWidgets = {}
WorldQuestTracker.PartyQuestsPool = {}
WorldQuestTracker.PartySharedQuests = {}
WorldQuestTracker.CurrentMapID = 0
WorldQuestTracker.LastWorldMapClick = 0
WorldQuestTracker.MapSeason = 0
WorldQuestTracker.MapOpenedAt = 0
WorldQuestTracker.QueuedRefresh = 1
WorldQuestTracker.WorldQuestButton_Click = 0
WorldQuestTracker.Temp_HideZoneWidgets = 0
WorldQuestTracker.lastZoneWidgetsUpdate = 0
WorldQuestTracker.lastMapTap = 0
WorldQuestTracker.SoundPitch = math.random (2)
WorldQuestTracker.RarityColors = {
	[3] = "|cff2292FF",
	[4] = "|cffc557FF",
}
WorldQuestTracker.GameLocale = GetLocale()

local LibWindow = LibStub ("LibWindow-1.1")
if (not LibWindow) then
	print ("|cFFFFAA00World Quest Tracker|r: libwindow not found, did you just updated the addon? try reopening the client.|r")
end

WorldQuestTracker.MAPID_DALARAN = 1014
local MAPID_BROKENISLES = 1007
local ARROW_UPDATE_FREQUENCE = 0.016

WorldQuestTracker.QUEST_COMMENTS = {
	[42275] = {help = "'Dimensional Anchors' are green crystals on the second floor of the central build."}, --azsuna - not on my watch
	[43963] = {help = "Kill and loot mobs around the quest location."},
	[42108] = {help = "Use the extra button near friendly ghosty npcs."},
	[42080] = {help = "Select eagles and use the extra button. Click on sheeps outside the town."},
	[41701] = {help = "Kill fish inside the water. Walk on outlined garbage."},
}

WorldQuestTracker.CAVE_QUESTS = {
	[41145] = true,
}

function WorldQuestTracker.CanLinkToChat (object, button)
	if (button == "LeftButton") then
		if (IsShiftKeyDown()) then
			
			local questID = (object.questID) or (object.info and object.info.questID)
			
			if (questID) then
				local questName = GetQuestInfoByQuestID (questID)
				local link = [=[|cffffff00|Hquest:@QUESTID:110|h[@QUESTNAME]|h|r]=]
				link = link:gsub ("@QUESTID", questID)
				link = link:gsub ("@QUESTNAME", questName)

				return ChatEdit_InsertLink (link)
				--print ("|cffffff00|Hquest:41145:110|h[Water of Life]|h|r")
				--SendChatMessage("|cffffff00|Hquest:41145:110|h[Water of Life]|h|r", "SAY", "Common")
				--SendChatMessage("|cffffff00|Hquest:40883:110|h[Fate of the Guard]|h|r", "SAY", "Common");
			end
		end
	end
end

--debug
function WorldQuestTracker.DumpTrackingList()
	local t = WorldQuestTracker.table.dump (WorldQuestTracker.QuestTrackList)
	print (t)
end

hooksecurefunc ("TaskPOI_OnEnter", function (self)
	--WorldMapTooltip:AddLine ("quest ID: " .. self.questID)
	--print (self.questID)
	WorldQuestTracker.CurrentHoverQuest = self.questID
end)
hooksecurefunc ("TaskPOI_OnLeave", function (self)
	WorldQuestTracker.CurrentHoverQuest = nil
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
local eoa_widgets = {}
local WorldWidgetPool = {}

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
	
	--> faz o cliente carregar as quests antes de realmente verificar o tepo restante
	C_Timer.After (3, WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker_Load)
	C_Timer.After (4, WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker_Load)
	C_Timer.After (6, WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker_Load)
	C_Timer.After (10, WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker)
	
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

function WorldQuestTracker.UpdateArrowFrequence()
	ARROW_UPDATE_FREQUENCE = WorldQuestTracker.db.profile.arrow_update_frequence
end

--/run WorldQuestTrackerAddon.db.profile.arrow_update_frequence = .1; WorldQuestTrackerAddon.UpdateArrowFrequence()

function WorldQuestTracker.IsPartyQuest (questID)
	return WorldQuestTracker.PartySharedQuests [questID]
end

-- ~party ~share
local CreatePartySharer = function()

	local COMM_PREFIX = "WQTC"

	local CanShareQuests = function()
		if (UnitLevel ("player") < 110) then
			return
		elseif (not IsQuestFlaggedCompleted (WORLD_QUESTS_AVAILABLE_QUEST_ID)) then
			return
		end
		local inInstance = IsInInstance()
		if (inInstance) then
			return
		end
		if (IsInRaid() or not IsInGroup (LE_PARTY_CATEGORY_HOME)) then
			return
		end
		if (not LibStub ("AceSerializer-3.0")) then
			return
		end
		
		return true
	end
	
	local build_shared_quest_list = function (noMapUpdate)
		--> conta quantas pessoes tem a mesma quest no grupo
		local newList = {}
		local playersAmount = 0
		for guid, questList in pairs (WorldQuestTracker.PartyQuestsPool) do
			playersAmount = playersAmount + 1
			for index, questID in ipairs (questList) do
				newList [questID] = (newList [questID] or 0) + 1
			end
		end
		
		--> remove as quests que possuem menos gente que o total de pessoas no grupo
		local groupMembers = GetNumSubgroupMembers() + 1
		for questID, amountPlayers in pairs (newList) do
			if (amountPlayers < groupMembers) then
				newList [questID] = nil
			end
		end
		
		--> atualiza o container e os widgets
		WorldQuestTracker.PartySharedQuests = newList
		
		if (not noMapUpdate) then
			if (WorldMapFrame and WorldMapFrame:IsShown()) then
				if (WorldMapFrame.mapID == 1007 or GetCurrentMapAreaID() == 1007) then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, false) --noCache, showFade, isQuestFlaggedRecheck, forceCriteriaAnimation
				else
					if (is_broken_isles_map [GetCurrentMapAreaID()]) then
						WorldQuestTracker.UpdateZoneWidgets()
					end
				end
			end
		end
		
		if (WorldQuestTracker.PartyStarIcon) then
			--> compara a quantidade de jogadores que já recebemos os dados com a quantidade de jogadores no grupo
			if (CanShareQuests()) then
				if (playersAmount == groupMembers) then
					WorldQuestTracker.PartyStarIcon:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_party_sharedT]])
					WorldQuestTracker.PartyAmountText:SetText (playersAmount .. "/" .. groupMembers)
					WorldQuestTracker.PartyAmountText:SetTextColor ("orange")
				else
					WorldQuestTracker.PartyStarIcon:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_party_shared_badT]])
					WorldQuestTracker.PartyAmountText:SetText (playersAmount .. "/" .. groupMembers)
					WorldQuestTracker.PartyAmountText:SetTextColor ("orangered")
				end
				WorldQuestTracker.PartyStarIcon:SetDesaturated (false)
			else
				WorldQuestTracker.PartyStarIcon:SetDesaturated (true)
				WorldQuestTracker.PartyAmountText:SetText (0)
				WorldQuestTracker.PartyAmountText:SetTextColor (1, .7, .2, .85)
			end
		end

	end
	
	WorldQuestTracker.UpdatePartySharedQuests = build_shared_quest_list
	
	function WorldQuestTracker:CommReceived (_, data)
		local QuestList = {LibStub ("AceSerializer-3.0"):Deserialize (data)}
		QuestList = QuestList [2]
		
		if (type (QuestList) == "string") then
			if (QuestList == "L") then
				WorldQuestTracker:GROUP_ROSTER_UPDATE()
				return
			end
		end
		
		if (type (QuestList) == "table" and QuestList.GUID) then
			local FromWho = QuestList.GUID
			QuestList.GUID = nil
			
			WorldQuestTracker.PartyQuestsPool [FromWho] = QuestList
			build_shared_quest_list()
		end
	end
	WorldQuestTracker:RegisterComm (COMM_PREFIX, "CommReceived")

	WorldQuestTracker.Sharer_LastSentUpdate = 0
	WorldQuestTracker.Sharer_LastTimer = nil --
	

	
	--> fazendo em uma funcao separada para aplicar um delay antes de envia-las
	local SendQuests = function()
		if (not CanShareQuests()) then
			return
		end
		
		--> pega a lista de quests
		local ActiveQuests = WorldQuestTracker.SavedQuestList_GetList()
		local list_to_send = {}
		
		--monta a tabela para ser enviada
		for questID, expireAt in pairs (ActiveQuests) do
			list_to_send [#list_to_send+1] = questID
		end
		
		list_to_send.GUID = UnitGUID ("player")
		
		local data = LibStub ("AceSerializer-3.0"):Serialize (list_to_send)
		WorldQuestTracker:SendCommMessage (COMM_PREFIX, data, "PARTY")
	end

	local group_changed = function (loggedIn)
		if (CanShareQuests()) then
			if (loggedIn) then
				--> precisa pedir as quests dos demais membros do grupo
				--> pode dar return pois ele vai enviar para si mesmo
				local data = LibStub ("AceSerializer-3.0"):Serialize ("L")
				WorldQuestTracker:SendCommMessage (COMM_PREFIX, data, "PARTY")
				return
			end
			
			--> manda as quests que nos temos para os membros da party
			if (WorldQuestTracker.Sharer_LastSentUpdate+10 < GetTime()) then --ja passou 1 min des do ultimo update
				--> manda as quests depois de 1 segundo
				C_Timer.After (1, SendQuests)
				WorldQuestTracker.Sharer_LastSentUpdate = GetTime()
			else
				--> se não passou ainda os 10 segundos, fazer ele agendar o update
				if (WorldQuestTracker.Sharer_LastTimer) then
					WorldQuestTracker.Sharer_LastTimer:Cancel()
				end
				local nextUpdate = (WorldQuestTracker.Sharer_LastSentUpdate + 10) - GetTime()
				WorldQuestTracker.Sharer_LastTimer = C_Timer.NewTimer (nextUpdate, SendQuests)
			end
		end
	end
	
	function WorldQuestTracker:GROUP_JOINED()
		--> é só quiando o jogador entra no grupo, nao dispara para os demais
		WorldQuestTracker.InGroup = true
		group_changed()
	end
	function WorldQuestTracker:GROUP_LEFT()
		WorldQuestTracker.InGroup = nil
		wipe (WorldQuestTracker.PartySharedQuests)
		
		if (WorldMapFrame and WorldMapFrame:IsShown()) then
			if (WorldMapFrame.mapID == 1007 or GetCurrentMapAreaID() == 1007) then
				WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, false) --noCache, showFade, isQuestFlaggedRecheck, forceCriteriaAnimation
			else
				if (is_broken_isles_map [GetCurrentMapAreaID()]) then
					WorldQuestTracker.UpdateZoneWidgets()
				end
			end
		end
		
		if (WorldQuestTracker.PartyStarIcon) then
			WorldQuestTracker.PartyStarIcon:SetDesaturated (true)
			WorldQuestTracker.PartyAmountText:SetText (0)
			WorldQuestTracker.PartyAmountText:SetTextColor (1, .7, .2, .85)
		end
	end	
	function WorldQuestTracker:GROUP_ROSTER_UPDATE()
		group_changed()
	end
	
	WorldQuestTracker:RegisterEvent ("GROUP_JOINED")
	WorldQuestTracker:RegisterEvent ("GROUP_LEFT")
	WorldQuestTracker:RegisterEvent ("GROUP_ROSTER_UPDATE")
	
	group_changed (true)
end

-- /run WorldQuestTrackerAddon:GetNextResearchNoteTime()
-- /run for a, b in pairs (_G) do if b == "Artifact Research Notes" then print (a,b) end end

--[[ by name?
Artifact Research Notes
Artefaktforschungsnotizen
Notas de investigación de artefactos
Recherches sur les armes prodigieuses
Appunti sulla Ricerca dell'Artefatto
Anotações de Pesquisa de Artefato
--]]

-- 173 shipment ID -- MAGE
-- each class hall has its own containerID for the research
-- /dump C_Garrison.GetLandingPageShipmentInfoByContainerID (173) -- MAGE
-- each 
-- ~research

-- /run for i=1, 500 do local _,texture,_,_,_,_,_, timeleftString=C_Garrison.GetLandingPageShipmentInfoByContainerID(i) if texture==237446 then print ("achour research, timeleft:", timeleftString) end end

function WorldQuestTracker:GetNextResearchNoteTime()
	local looseShipments = C_Garrison.GetLooseShipments (LE_GARRISON_TYPE_7_0)
	if (looseShipments and #looseShipments > 0) then
		for i = 1, #looseShipments do
			local name, texture, _, ready, _, creationTime, duration, timeleftString = C_Garrison.GetLandingPageShipmentInfoByContainerID (looseShipments [i])
			--print (looseShipments [i], name)
			if (name and creationTime and creationTime > 0 and texture == 237446) then
				local elapsedTime = time() - creationTime
				local timeLeft = duration - elapsedTime
				--print ("timeleft: ", timeLeft / 60 / 60)
				return name, timeleftString, timeLeft, elapsedTime, ready
				--print (name, texture, shipmentCapacity, shipmentsReady, shipmentsTotal, creationTime, duration, timeleftString)
			end
		end
	end
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
			if (LibWindow) then
				if (WorldQuestTracker.db:GetCurrentProfile() == "Default") then
					LibWindow.RegisterConfig (WorldQuestTrackerScreenPanel, WorldQuestTracker.db.profile)
					if (WorldQuestTracker.db.profile.tracker_is_movable) then
						LibWindow.RestorePosition (WorldQuestTrackerScreenPanel)
						WorldQuestTrackerScreenPanel.RegisteredForLibWindow = true
					end
				end
			end
		end
	end)

	if (LibWindow) then
		if (WorldQuestTracker.db:GetCurrentProfile() == "Default") then
			LibWindow.RegisterConfig (WorldQuestTrackerScreenPanel, WorldQuestTracker.db.profile)
			if (WorldQuestTracker.db.profile.tracker_is_movable) then
				LibWindow.RestorePosition (WorldQuestTrackerScreenPanel)
				WorldQuestTrackerScreenPanel.RegisteredForLibWindow = true
			end
		end
	end
	
	function WorldQuestTracker:CleanUpJustBeforeGoodbye()
		WorldQuestTracker.AllCharactersQuests_CleanUp()
	end
	WorldQuestTracker.db.RegisterCallback (WorldQuestTracker, "OnDatabaseShutdown", "CleanUpJustBeforeGoodbye") --more info at https://www.youtube.com/watch?v=GXFnT4YJLQo
	
	--
	C_Timer.After (10, CreatePartySharer)
	--
	
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
		--print ("world quest:", questID, QuestMapFrame_IsQuestWorldQuest (questID), XP, gold)
	
		if (QuestMapFrame_IsQuestWorldQuest (questID)) then
			--print (event, questID, XP, gold)
			--QUEST_TURNED_IN 44300 0 772000
			-- QINFO: 0 nil nil Petrified Axe Haft true 370
			
			WorldQuestTracker.AllCharactersQuests_Remove (questID)
			WorldQuestTracker.RemoveQuestFromTracker (questID)
			
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
	C_Timer.After (.5, WorldQuestTracker.UpdateArrowFrequence)
	C_Timer.After (5, WorldQuestTracker.UpdateArrowFrequence)
	C_Timer.After (10, WorldQuestTracker.UpdateArrowFrequence)
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
		WorldQuestTracker.CurrentHoverQuest = self.questID
		self.UpdateTooltip = TaskPOI_OnEnter
		TaskPOI_OnEnter (self)
		
		--if (self.texture:GetTexture() == [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blueT]]) then
			
		--end

	end
end
local questButton_OnLeave = function	(self)
	TaskPOI_OnLeave (self)
	WorldQuestTracker.CurrentHoverQuest = nil
end

--ao clicar no botão de uma quest na zona ou no world map, colocar para trackear ela
-- õnclick ~onclick
local questButton_OnClick = function (self, button)

	if (not self.questID) then
		return
	end
	if (not HaveQuestData (self.questID)) then
		WorldQuestTracker:Msg (L["S_ERROR_NOTLOADEDYET"])
		return
	end
	local timeLeft = C_TaskQuest.GetQuestTimeLeftMinutes (self.questID)
	if (not timeLeft or timeLeft <= 0) then
		WorldQuestTracker:Msg (L["S_ERROR_NOTIMELEFT"])
	end
	
--chat link
	if (WorldQuestTracker.CanLinkToChat (self, button)) then
		return
	end

--isn't using the tracker
	if (not WorldQuestTracker.db.profile.use_tracker or IsShiftKeyDown()) then
		TaskPOI_OnClick (self, button)
		
		if (self.IsZoneQuestButton) then
			WorldQuestTracker.UpdateZoneWidgets()
		else
			WorldQuestTracker.CanShowWorldMapWidgets (true)
		end
		return
	end

--> add the quest to the tracker	
	WorldQuestTracker.OnQuestClicked (self, button)
	
--animations and sounds
	if (WorldQuestTracker.IsQuestBeingTracked (self.questID)) then
		if (self.trackingGlowBorder) then
			self.trackingGlowBorder:Show()
		end
	else
		if (self.trackingGlowBorder) then
			self.trackingGlowBorder:Hide()
		end
	end

--shutdown animation and sound for now
if (true) then return end

	if (WorldQuestTracker.IsQuestBeingTracked (self.questID)) then
		if (self.onEndTrackAnimation:IsPlaying()) then
			self.onEndTrackAnimation:Stop()
		end
		self.onStartTrackAnimation:Play()
		
		if (WorldQuestTracker.db.profile.sound_enabled) then
			if (math.random (5) == 1) then
				PlaySoundFile ("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker1.mp3")
			else
				PlaySoundFile ("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker2.mp3")	
			end
		end
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

--/dump WorldQuestTrackerAddon.GetCurrentZoneType()
function WorldQuestTracker.GetCurrentZoneType()
	if (is_broken_isles_map [GetCurrentMapAreaID()]) then
		return "zone"
	elseif (WorldMapFrame.mapID == 1007 or GetCurrentMapAreaID() == 1007) then
		return "world"
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
	return WorldQuestTracker.db.profile.enable_doubletap and not InCombatLockdown() and GetCurrentMapAreaID() ~= MAPID_BROKENISLES and (C_Garrison.IsPlayerInGarrison (LE_GARRISON_TYPE_7_0) or GetCurrentMapAreaID() == WorldQuestTracker.MAPID_DALARAN)
end

--todo: replace this with real animations
local zone_widget_rotation = 0
local animFrame, t = CreateFrame ("frame"), 0
local tickAnimation = function (self, deltaTime)
	t = t + deltaTime
	local squareAlphaAmount = Lerp (.7, .95, abs (sin (t*10)))
	--print (squareAlphaAmount)
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

local symbol_1K, symbol_10K, symbol_1B
if (GetLocale() == "koKR") then
	symbol_1K, symbol_10K, symbol_1B = "ì²œ", "ë§Œ", "ì–µ"
elseif (GetLocale() == "zhCN") then
	symbol_1K, symbol_10K, symbol_1B = "åƒ", "ä¸‡", "äº¿"
elseif (GetLocale() == "zhTW") then
	symbol_1K, symbol_10K, symbol_1B = "åƒ", "è¬", "å„„"
end

if (symbol_1K) then
	function WorldQuestTracker.ToK (numero)
		if (numero > 99999999) then
			return format ("%.2f", numero/100000000) .. symbol_1B
		elseif (numero > 999999) then
			return format ("%.2f", numero/10000) .. symbol_10K
		elseif (numero > 99999) then
			return floor (numero/10000) .. symbol_10K
		elseif (numero > 9999) then
			return format ("%.1f", (numero/10000)) .. symbol_10K
		elseif (numero > 999) then
			return format ("%.1f", (numero/1000)) .. symbol_1K
		end
		return format ("%.1f", numero)
	end
else
	function WorldQuestTracker.ToK (numero)
		if (numero > 999999) then
			return format ("%.2f", numero/1000000) .. "M"
		elseif (numero > 99999) then
			return floor (numero/1000) .. "K"
		elseif (numero > 999) then
			return format ("%.1f", (numero/1000)) .. "K"
		end
		return format ("%.1f", numero)
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
function WorldQuestTracker.UpdateBorder (self, rarity, worldQuestType, mapID)
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
		
			if (mapID ~= suramar_mapId) then
		
				self.rareSerpent:Show()
				self.rareSerpent:SetSize (48, 52)
				--self.rareSerpent:SetAtlas ("worldquest-questmarker-dragon")
				self.rareSerpent:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragon_curveT]])
				self.rareGlow:Show()
				self.rareGlow:SetVertexColor (0, 0.36863, 0.74902)
				self.rareGlow:SetSize (48, 52)
				self.rareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragonT]])
				
				--se estiver sendo trackeada, trocar o banner
				if (WorldQuestTracker.IsQuestBeingTracked (self.questID)) then
					self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag_criteriamatchT]])
				else
					self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flagT]])
				end

				self.bgFlag:Show()
				self.flagText:SetPoint ("top", self.bgFlag, "top", 0, -3)
				--self.glassTransparence:Show()
			end
			
		elseif (rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
			self.rareSerpent:Show()
			self.rareSerpent:SetSize (48, 52)
			--self.rareSerpent:SetAtlas ("worldquest-questmarker-dragon")
			self.rareSerpent:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragon_curveT]])
			self.rareGlow:Show()
			self.rareGlow:SetVertexColor (0.58431, 0.07059, 0.78039)
			self.rareGlow:SetSize (48, 52)
			self.rareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragonT]])
			
			--se estiver sendo trackeada, trocar o banner
			if (WorldQuestTracker.IsQuestBeingTracked (self.questID)) then
				self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag_criteriamatchT]])
			else
				self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flagT]])
			end
			
			self.bgFlag:Show()
			self.flagText:SetPoint ("top", self.bgFlag, "top", 0, -3)
			--self.glassTransparence:Show()
		end
		
	end
	
end

--pega o nome da zona
function WorldQuestTracker.GetZoneName (mapID)
	if (not mapID) then
		return ""
	end
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

	local bracket_low = 30
	local bracket_medium = 90
	local bracket_high = 240

	local timePriority = WorldQuestTracker.db.profile.sort_time_priority
	if (timePriority) then
		if (timePriority == 4) then
			bracket_low = 120 --2hrs
			bracket_medium = 180 --3hrs
			bracket_high = 240 --4hrs
		elseif (timePriority == 8) then
			bracket_low = 180 --3hrs
			bracket_medium = 360 --6hrs
			bracket_high = 480 --8hrs
		elseif (timePriority == 12) then
			bracket_low = 240 --4hrs
			bracket_medium = 480 --8hrs
			bracket_high = 720 --12hrs
		elseif (timePriority == 16) then
			bracket_low = 480 --8hrs
			bracket_medium = 720 --12hrs
			bracket_high = 960 --16hrs
		elseif (timePriority == 24) then
			bracket_low = 480 --8hrs
			bracket_medium = 720 --12hrs
			bracket_high = 1440 --24hrs
		end
	end

	if (timeLeft < bracket_low) then
		self.timeBlipRed:Show()
		--TQueue:AddToQueue (self.timeBlipRed, false, false, false)
		--blip:SetTexture ([[Interface\COMMON\Indicator-Red]])
		--blip:SetVertexColor (1, 1, 1)
		--blip:SetAlpha (1)
	elseif (timeLeft < bracket_medium) then
		self.timeBlipOrange:Show()
		--TQueue:AddToQueue (self.timeBlipOrange, false, false, false)
		--blip:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
		--blip:SetVertexColor (1, .7, 0)
		--blip:SetAlpha (.9)
	elseif (timeLeft < bracket_high) then
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
local GameTooltipFrameTextLeft4 = _G ["WorldQuestTrackerScanTooltipTextLeft5"]

--GameTooltip_ShowCompareItem(GameTooltip);
--EmbeddedItemTooltip_SetItemByQuestReward(self, questLogIndex, questID)
function WorldQuestTracker.RewardRealItemLevel (questID)
	GameTooltipFrame:SetOwner (WorldFrame, "ANCHOR_NONE")
	--GameTooltipFrame:SetHyperlink (itemLink)
	GameTooltipFrame:SetQuestLogItem ("reward", 1, questID)
	local itemLevel = tonumber (GameTooltipFrameTextLeft1:GetText():match ("%d+"))
	return itemLevel or 1
end

-- ãrtifact ~artifact
function WorldQuestTracker.RewardIsArtifactPower (itemLink)
	GameTooltipFrame:SetOwner (WorldFrame, "ANCHOR_NONE")
	GameTooltipFrame:SetHyperlink (itemLink)

	local text = GameTooltipFrameTextLeft1:GetText()
	if (text and text:match ("|cFFE6CC80")) then
		local power = GameTooltipFrameTextLeft3:GetText()
		if (power) then
			if (WorldQuestTracker.GameLocale == "frFR") then
				power = power:gsub ("%s", ""):gsub ("%p", ""):match ("%d+")
			else
				power = power:gsub ("%p", ""):match ("%d+")
			end
			power = tonumber (power)
			return true, power or 0
		end
	end

	local text2 = GameTooltipFrameTextLeft2:GetText() --thanks @Prejudice182 on curseforge
	if (text2 and text2:match ("|cFFE6CC80")) then
		local power = GameTooltipFrameTextLeft4:GetText()
		if (power) then
			if (WorldQuestTracker.GameLocale == "frFR") then
				power = power:gsub ("%s", ""):gsub ("%p", ""):match ("%d+")
			else
				power = power:gsub ("%p", ""):match ("%d+")
			end
			power = tonumber (power)
			return true, power or 0
		end
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

local ItemTooltipScan = CreateFrame ("GameTooltip", "WQTItemTooltipScan", UIParent, "EmbeddedItemTooltip")
ItemTooltipScan.texts = {
	_G ["WQTItemTooltipScanTooltipTextLeft1"],
	_G ["WQTItemTooltipScanTooltipTextLeft2"],
	_G ["WQTItemTooltipScanTooltipTextLeft3"],
	_G ["WQTItemTooltipScanTooltipTextLeft4"],
}
ItemTooltipScan.patern = ITEM_LEVEL:gsub ("%%d", "(%%d+)") --from LibItemUpgradeInfo-1.0

WorldQuestTracker.EquipIcons = {
	["INVTYPE_HEAD"] = "Interface\\ICONS\\" .. "INV_Helmet_29",
	["INVTYPE_NECK" ] = "Interface\\ICONS\\" .. "INV_Jewelry_Necklace_07",
	["INVTYPE_SHOULDER"] = "Interface\\ICONS\\" .. "INV_Shoulder_25",
	--["INVTYPE_ROBE"] ="INV_Chest_Chain_10", --INVTYPE_CHEST
	["INVTYPE_ROBE"] = "Interface\\ICONS\\" .. "INV_Chest_Cloth_08", --INVTYPE_CHEST
	["INVTYPE_WAIST"] = "Interface\\ICONS\\" .. "INV_Belt_15",
	["INVTYPE_LEGS"] = "Interface\\ICONS\\" .. "INV_Pants_08",
	["INVTYPE_FEET"] = "Interface\\ICONS\\" .. "INV_Boots_Cloth_03",
	["INVTYPE_WRIST"] = "Interface\\ICONS\\" .. "INV_Bracer_07",
	["INVTYPE_HAND"] = "Interface\\ICONS\\" .. "INV_Gauntlets_17",
	["INVTYPE_FINGER"] = "Interface\\ICONS\\" .. "INV_Jewelry_Ring_22",
	--["INVTYPE_TRINKET"] = "Interface\\ICONS\\" .. "INV_Wand_1h_430NightElf_C_01", --"INV_Trinket_HonorHold",
	--["INVTYPE_TRINKET"] = "Interface\\ICONS\\" .. "INV_Jewelry_StormPikeTrinket_01", --"INV_Trinket_HonorHold",
	["INVTYPE_TRINKET"] = "Interface\\ICONS\\" .. "INV_Jewelry_Talisman_07", --"INV_Trinket_HonorHold",
	--["INVTYPE_TRINKET"] = [[Interface\AddOns\WorldQuestTracker\media\icon_trinketT]],
	["INVTYPE_CLOAK"] = "Interface\\ICONS\\" .. "INV_Misc_Cape_19", --INVTYPE_BACK
	--["Relic"] = "Interface\\ICONS\\" .. "INV_Artifact_XP05",
	--["Relic"] = "Interface\\ICONS\\" .. "INV_Enchant_VoidSphere",
	["Relic"] = "Interface\\ICONS\\" .. "inv_misc_enchantedpearlE",
}

--[[

--]]

--pega o premio item da quest
function WorldQuestTracker.GetQuestReward_Item (questID)
	if (not HaveQuestData (questID)) then
		return
	end
	local numQuestRewards = GetNumQuestLogRewards (questID)
	if (numQuestRewards > 0) then
		local itemName, itemTexture, quantity, quality, isUsable, itemID = GetQuestLogRewardInfo (1, questID)
		if (itemID) then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice, itemClassID, itemSubClassID = GetItemInfo (itemID)

			if (itemName) then
				EmbeddedItemTooltip_SetItemByQuestReward (ItemTooltipScan, 1, questID)
				for i = 1, 4 do
					local text = ItemTooltipScan.texts [i]:GetText()
					if (text and text ~= "") then
						local ilvl = tonumber (text:match (ItemTooltipScan.patern))
						if (ilvl) then
							itemLevel = ilvl
							break
						end
					end
				end
			
				local icon = WorldQuestTracker.EquipIcons [itemEquipLoc]
				if (not icon and itemClassID == 3 and itemSubClassID == 11) then
					icon = WorldQuestTracker.EquipIcons ["Relic"]
				end
				
				if (icon) then
					itemTexture = icon
				end
			
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
	if (not HaveQuestData (questID)) then
		return
	end
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
	if (true or artifactPower >= 250) then --forçando sempre o mesmo icone
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
-- ~saved ~pool ~data ~allquests ãll
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

--point of interest frame ~poiframe ~frame ~start
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
-- ~bar ~showbar ~statusbar ~worldmapevent ~event
function WorldQuestTracker.RefreshStatusBar()
	if (WorldQuestTracker.DoubleTapFrame and not InCombatLockdown()) then
		if (GetCurrentMapAreaID() == MAPID_BROKENISLES or is_broken_isles_map [GetCurrentMapAreaID()]) then
			WorldQuestTracker.DoubleTapFrame:Show()
		else
			WorldQuestTracker.DoubleTapFrame:Hide()
		end
	end
end

WorldMapFrame:HookScript ("OnEvent", function (self, event)
	if (event == "WORLD_MAP_UPDATE") then
		if (WorldQuestTracker.CurrentMapID ~= self.mapID) then
			if (WorldQuestTracker.LastWorldMapClick+0.017 > GetTime()) then
				WorldQuestTracker.CurrentMapID = self.mapID
			end
		end
		WorldQuestTracker.RefreshStatusBar()
		
		if (WorldQuestTracker.QuestSummaryShown and not WorldQuestTracker.CanShowZoneSummaryFrame()) then
			WorldQuestTracker.ClearZoneSummaryButtons()
		end
		
		if (WorldQuestTracker.CanShowZoneSummaryFrame()) then -- and not InCombatLockdown()
			WorldMapFrame.UIElementsFrame.BountyBoard:ClearAllPoints()
			WorldMapFrame.UIElementsFrame.BountyBoard:SetPoint ("bottomright", WorldMapFrame.UIElementsFrame, "bottomright", -18, 15)
		end
		
		--se for um mapa qualquer e não for o world map -> esconder os widget do world map
		--fazer a mesma coisa para os widgets das zonas
	end
end)

--OnTick
local OnUpdateDelay = .5
local ActionButton = WorldMapFrame.UIElementsFrame.ActionButton

WorldMapFrame:HookScript ("OnUpdate", function (self, deltaTime)
	
	if (ActionButton and ActionButton:IsShown()) then
		if (ActionButton.SpellButton.Cooldown:GetCooldownDuration() and ActionButton.SpellButton.Cooldown:GetCooldownDuration() > 0) then
			ActionButton:SetAlpha (.2)
		else
			ActionButton:SetAlpha (1)
		end
	end

	if (WorldQuestTracker.CanShowZoneSummaryFrame()) then
		WorldMapFrame.UIElementsFrame.BountyBoard:ClearAllPoints()
		WorldMapFrame.UIElementsFrame.BountyBoard:SetPoint ("bottomright", WorldMapFrame.UIElementsFrame, "bottomright", -18, 15)
		
		if (ActionButton:IsShown()) then
			if (not InCombatLockdown()) then
				WorldMapFrame.UIElementsFrame.ActionButton:ClearAllPoints()
				--WorldMapFrame.UIElementsFrame.ActionButton:SetPoint ("bottomleft", WorldQuestTrackerSummaryHeader, "topleft")
				--WorldMapFrame.UIElementsFrame.ActionButton:SetPoint ("right", WorldMapFrame.UIElementsFrame.BountyBoard, "left", 0, -12) --problemas com protected
				WorldMapFrame.UIElementsFrame.ActionButton:SetPoint ("bottomright", WorldMapFrame.UIElementsFrame, "bottomright", -268, 15)
			else
				ActionButton:SetAlpha (0)
			end
		end

	end
	if (WorldQuestTracker.HaveZoneSummaryHover) then
		WorldMapTooltip:ClearAllPoints()
		WorldMapTooltip:SetPoint ("bottomleft", WorldQuestTracker.HaveZoneSummaryHover, "bottomright", 2, 0) -- + diff
	end
	
	if (OnUpdateDelay < 0) then
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
		
		if (WorldQuestTracker.WorldMapFrameReference) then
			if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
				if (not WorldQuestTracker.WorldMapFrameReference:IsShown()) then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
				end
			else
				if (WorldQuestTracker.WorldMapFrameReference:IsShown()) then
					WorldQuestTracker.HideWorldQuestsOnWorldMap()
				end
			end
		end
		
		OnUpdateDelay = .5
	else
		OnUpdateDelay = OnUpdateDelay - deltaTime
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
		--button:SetScript ("OnClick", questButton_OnClick)
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
	self.partySharedBlip:Hide()
	self.flagCriteriaMatchGlow:Hide()
end

-- ~zoneicon
function WorldQuestTracker.CreateZoneWidget (index, name, parent) --~zone
	local button = CreateFrame ("button", name .. index, parent)
	button:SetSize (20, 20)
	
	button:SetScript ("OnEnter", TaskPOI_OnEnter)
	button:SetScript ("OnLeave", TaskPOI_OnLeave)
	button:SetScript ("OnClick", questButton_OnClick)
	
	local supportFrame = CreateFrame ("frame", nil, button)
	supportFrame:SetPoint ("center")
	supportFrame:SetSize (20, 20)
	button.SupportFrame = supportFrame
	
	button.UpdateTooltip = TaskPOI_OnEnter
	button.worldQuest = true
	button.ClearWidget = clear_widget
	
	button.Texture = supportFrame:CreateTexture (button:GetName() .. "Texture", "BACKGROUND")
	button.Texture:SetPoint ("center", button, "center")
	button.Texture:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
	
	button.Glow = supportFrame:CreateTexture(button:GetName() .. "Glow", "BACKGROUND", -6)
	button.Glow:SetSize (50, 50)
	button.Glow:SetPoint ("center", button, "center")
	button.Glow:SetTexture ([[Interface/WorldMap/UI-QuestPoi-IconGlow]])
	button.Glow:SetBlendMode ("ADD")
	button.Glow:Hide()
	
	button.highlight = supportFrame:CreateTexture (nil, "highlight")
	button.highlight:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\highlight_circleT]])
	button.highlight:SetPoint ("center")
	button.highlight:SetSize (16, 16)
	
	button.IsTrackingGlow = supportFrame:CreateTexture(button:GetName() .. "IsTrackingGlow", "BACKGROUND", -6)
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
	
	button.IsTrackingRareGlow = supportFrame:CreateTexture(button:GetName() .. "IsTrackingRareGlow", "BACKGROUND", -6)
	button.IsTrackingRareGlow:SetSize (44, 44)
	button.IsTrackingRareGlow:SetPoint ("center", button, "center")
	button.IsTrackingRareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragon_TrackingT]])
	--button.IsTrackingRareGlow:SetBlendMode ("ADD")
	button.IsTrackingRareGlow:Hide()

	button.Shadow = supportFrame:CreateTexture(button:GetName() .. "Shadow", "BACKGROUND", -8)
	button.Shadow:SetSize (24, 24)
	button.Shadow:SetPoint ("center", button, "center")
	button.Shadow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\glow_yellow_roundT]])
	button.Shadow:SetTexture ([[Interface\PETBATTLES\BattleBar-AbilityBadge-Neutral]])
	button.Shadow:SetAlpha (1)
	
	local onStartTrackAnimation = DF:CreateAnimationHub (button.IsTrackingGlow, onStartClickAnimation)
	WorldQuestTracker:CreateAnimation (onStartTrackAnimation, "Scale", 1, .10, .9, .9, 1.1, 1.1)
	WorldQuestTracker:CreateAnimation (onStartTrackAnimation, "Scale", 2, .10, 1.2, 1.2, 1, 1)
	
	local onEndTrackAnimation = DF:CreateAnimationHub (button.IsTrackingGlow, onStartClickAnimation, onEndClickAnimation)
	WorldQuestTracker:CreateAnimation (onEndTrackAnimation, "Scale", 1, .5, 1, 1, .1, .1)
	button.onStartTrackAnimation = onStartTrackAnimation
	button.onEndTrackAnimation = onEndTrackAnimation
	
	button.SelectedGlow = supportFrame:CreateTexture (button:GetName() .. "SelectedGlow", "OVERLAY", 2)
	button.SelectedGlow:SetBlendMode ("ADD")
	button.SelectedGlow:SetPoint ("center", button, "center")
	
	button.CriteriaMatchGlow = supportFrame:CreateTexture(button:GetName() .. "CriteriaMatchGlow", "BACKGROUND", -1)
	button.CriteriaMatchGlow:SetAlpha (.6)
	button.CriteriaMatchGlow:SetBlendMode ("ADD")
	button.CriteriaMatchGlow:SetPoint ("center", button, "center")
		local w, h = button.CriteriaMatchGlow:GetSize()
		button.CriteriaMatchGlow:SetAlpha (1)
		button.flagCriteriaMatchGlow = supportFrame:CreateTexture (nil, "background")
		button.flagCriteriaMatchGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag_criteriamatchT]])
		button.flagCriteriaMatchGlow:SetPoint ("top", button, "bottom", 0, 3)
		button.flagCriteriaMatchGlow:SetSize (64, 32)
	
	button.SpellTargetGlow = supportFrame:CreateTexture(button:GetName() .. "SpellTargetGlow", "OVERLAY", 1)
	button.SpellTargetGlow:SetAtlas ("worldquest-questmarker-abilityhighlight", true)
	button.SpellTargetGlow:SetAlpha (.6)
	button.SpellTargetGlow:SetBlendMode ("ADD")
	button.SpellTargetGlow:SetPoint ("center", button, "center")
	
	button.rareSerpent = supportFrame:CreateTexture (button:GetName() .. "RareSerpent", "OVERLAY")
	button.rareSerpent:SetWidth (34 * 1.1)
	button.rareSerpent:SetHeight (34 * 1.1)
	button.rareSerpent:SetPoint ("CENTER", 1, -2)
	
	-- é a sombra da serpente no fundo, pode ser na cor azul ou roxa
	button.rareGlow = supportFrame:CreateTexture (nil, "background")
	--button.rareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragonT]])
	button.rareGlow:SetPoint ("CENTER", 1, -2)
	button.rareGlow:SetSize (48, 48)
	button.rareGlow:SetAlpha (.85)
	
	--fundo preto
	button.blackBackground = supportFrame:CreateTexture (nil, "background")
	button.blackBackground:SetPoint ("center")
	button.blackBackground:Hide()
	
	--borda circular - nao da scala por causa do set point! 
	button.circleBorder = supportFrame:CreateTexture (nil, "OVERLAY")
	button.circleBorder:SetPoint ("topleft", supportFrame, "topleft", -1, 1)
	button.circleBorder:SetPoint ("bottomright", supportFrame, "bottomright", 1, -1)
	button.circleBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_zone_browT]])
	button.circleBorder:SetTexCoord (0, 1, 0, 1)
	--problema das quests de profissão com verde era a circleBorder
	
	button.glassTransparence = supportFrame:CreateTexture (nil, "OVERLAY", 1)
	button.glassTransparence:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_transparency_overlay]])
	button.glassTransparence:SetPoint ("topleft", button, "topleft", -1, 1)
	button.glassTransparence:SetPoint ("bottomright", button, "bottomright", 1, -1)
	button.glassTransparence:SetAlpha (.5)
	button.glassTransparence:Hide()
	
	--borda quadrada
	button.squareBorder = supportFrame:CreateTexture (nil, "OVERLAY", 1)
	button.squareBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_whiteT]])
	button.squareBorder:SetPoint ("topleft", button, "topleft", -1, 1)
	button.squareBorder:SetPoint ("bottomright", button, "bottomright", 1, -1)

	--blip do tempo restante
	button.timeBlipRed = supportFrame:CreateTexture (nil, "OVERLAY")
	button.timeBlipRed:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipRed:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipRed:SetTexture ([[Interface\COMMON\Indicator-Red]])
	button.timeBlipRed:SetVertexColor (1, 1, 1)
	button.timeBlipRed:SetAlpha (1)
	
	button.timeBlipOrange = supportFrame:CreateTexture (nil, "OVERLAY")
	button.timeBlipOrange:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipOrange:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipOrange:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
	button.timeBlipOrange:SetVertexColor (1, .7, 0)
	button.timeBlipOrange:SetAlpha (.9)
	
	button.timeBlipYellow = supportFrame:CreateTexture (nil, "OVERLAY")
	button.timeBlipYellow:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipYellow:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipYellow:SetTexture ([[Interface\COMMON\Indicator-Yellow]])
	button.timeBlipYellow:SetVertexColor (1, 1, 1)
	button.timeBlipYellow:SetAlpha (.8)
	
	button.timeBlipGreen = supportFrame:CreateTexture (nil, "OVERLAY")
	button.timeBlipGreen:SetPoint ("bottomright", button, "bottomright", 4, -4)
	button.timeBlipGreen:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	button.timeBlipGreen:SetTexture ([[Interface\COMMON\Indicator-Green]])
	button.timeBlipGreen:SetVertexColor (1, 1, 1)
	button.timeBlipGreen:SetAlpha (.6)
	
	--blip do indicador de tipo da quest (zone)
	button.questTypeBlip = supportFrame:CreateTexture (nil, "OVERLAY", 2)
	button.questTypeBlip:SetPoint ("topright", button, "topright", 3, 1)
	button.questTypeBlip:SetSize (10, 10)
	button.questTypeBlip:SetAlpha (.8)
	
	--blip do indicador de party share
	button.partySharedBlip = supportFrame:CreateTexture (nil, "OVERLAY", 2)
	button.partySharedBlip:SetPoint ("topleft", button, "topleft", -3, 1)
	button.partySharedBlip:SetSize (10, 10)
	button.partySharedBlip:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_party_sharedT]])
	
	--faixa com o tempo
	button.bgFlag = supportFrame:CreateTexture (nil, "OVERLAY", 5)
	button.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flagT]])
	button.bgFlag:SetPoint ("top", button, "bottom", 0, 3)
	button.bgFlag:SetSize (64, 64)
	
	button.blackGradient = supportFrame:CreateTexture (nil, "OVERLAY")
	button.blackGradient:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
	button.blackGradient:SetPoint ("top", button.bgFlag, "top", 0, -1)
	button.blackGradient:SetSize (32, 10)
	button.blackGradient:SetAlpha (.7)
	
	--string da flag
	button.flagText = supportFrame:CreateFontString (nil, "OVERLAY", "GameFontNormal")
	button.flagText:SetText ("13m")
	button.flagText:SetPoint ("top", button.bgFlag, "top", 0, -2)
	DF:SetFontSize (button.flagText, 8)
	
	local criteriaFrame = CreateFrame ("frame", nil, supportFrame)
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
	button.partySharedBlip:SetDrawLayer ("overlay", 7)

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

--C_Timer.After (2, function()
--	function WorldMap_DoesWorldQuestInfoPassFilters (info, ignoreTypeFilters, ignoreTimeRequirement)
--		print (info, ignoreTypeFilters, ignoreTimeRequirement)
--		return true
--	end
--end)

--atualiza as quest do mapa da zona ~updatezone ~zoneupdate
function WorldQuestTracker.UpdateZoneWidgets()
	
	local mapID = GetCurrentMapAreaID()
	
	if (mapID == MAPID_BROKENISLES or mapID ~= WorldQuestTracker.LastMapID) then
		return WorldQuestTracker.HideZoneWidgets()
	elseif (not WorldQuestTracker.IsBrokenIslesZone (mapID)) then
		return WorldQuestTracker.HideZoneWidgets()
	end
	
	WorldQuestTracker.RefreshStatusBar()
	
	WorldQuestTracker.lastZoneWidgetsUpdate = GetTime()
	
	local taskInfo = GetQuestsForPlayerByMapID (mapID)
	local index = 1
	
	--parar a animação de loading
	if (WorldQuestTracker.IsPlayingLoadAnimation()) then
		WorldQuestTracker.StopLoadingAnimation()
	end	
	
	local filters = WorldQuestTracker.db.profile.filters
	
	wipe (WorldQuestTracker.Cache_ShownQuestOnZoneMap)
	wipe (WorldQuestTracker.Cache_ShownWidgetsOnZoneMap)
	local total_Gold, total_Resources, total_APower = 0, 0, 0
	local scale = WorldQuestTracker.db.profile.zonemap_widgets.scale
	
	if (taskInfo and #taskInfo > 0) then
		for i, info  in ipairs (taskInfo) do
			local questID = info.questId
			if (HaveQuestData (questID)) then
				local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
				if (isWorldQuest) then
					local isSuppressed = WorldMap_IsWorldQuestSuppressed (questID)
					local passFilters = WorldMap_DoesWorldQuestInfoPassFilters (info, true, true) --blizzard filters
					local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
					
					if (not isSuppressed and passFilters and timeLeft > 3) then
						C_TaskQuest.RequestPreloadRewardData (questID)
						
						local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = GetQuestTagInfo (questID)
						
						------ adicionados para fazer o filtro
							--gold
							local gold, goldFormated = WorldQuestTracker.GetQuestReward_Gold (questID)
							--class hall resource
							local rewardName, rewardTexture, numRewardItems = WorldQuestTracker.GetQuestReward_Resource (questID)
							--item
							local itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetQuestReward_Item (questID)
						------
						
						local filter, order = WorldQuestTracker.GetQuestFilterTypeAndOrder (worldQuestType, gold, rewardName, itemName, isArtifact, stackAmount)
						
						local passFilter = filters [filter]
						if (not passFilter) then
							if (rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
								passFilter = true
							elseif (WorldQuestTracker.db.profile.filter_always_show_faction_objectives) then
								local isCriteria = WorldMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty (questID)
								if (isCriteria) then
									passFilter = true
								end
							end
						end

						if (passFilter) then
							local widget = WorldQuestTracker.GetOrCreateZoneWidget (info, index)

							local selected = questID == GetSuperTrackedQuestID()
							local isCriteria = WorldMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty (questID)
							local isSpellTarget = SpellCanTargetQuest() and IsQuestIDValidSpellTarget (questID)
							
							widget.mapID = mapID
							widget.questID = questID
							widget.numObjectives = info.numObjectives
							widget.Order = order or 1

							local inProgress
							WorldQuestTracker.SetupWorldQuestButton (widget, worldQuestType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget, mapID)
							WorldMapPOIFrame_AnchorPOI (widget, info.x, info.y, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.WORLD_QUEST)
							
							tinsert (WorldQuestTracker.Cache_ShownQuestOnZoneMap, questID)
							tinsert (WorldQuestTracker.Cache_ShownWidgetsOnZoneMap, widget)
							
							widget.SupportFrame:SetScale (scale)
							--widget.circleBorder:SetScale (1.3)

							if (gold) then
								total_Gold = total_Gold + gold
							end
							if (numRewardItems) then
								total_Resources = total_Resources + numRewardItems
							end
							if (isArtifact) then
								total_APower = total_APower + artifactPower
							end
							
							if (WorldQuestTracker.Temp_HideZoneWidgets > GetTime()) then
								widget:Hide()
								for _, button in ipairs (WorldQuestTracker.AllTaskPOIs) do
									if (button.questID == questID) then
										button:Show()
									end
								end
							else
								widget:Show()
								for _, button in ipairs (WorldQuestTracker.AllTaskPOIs) do
									if (button.questID == questID) then
										button:Hide()
									end
								end
							end
							
							index = index + 1
						else
							--precisa hidar o widget da UI default
							for i = 1, #WorldQuestTracker.AllTaskPOIs do
								if (WorldQuestTracker.AllTaskPOIs [i].questID == questID) then
									--print ("achou o botao")
									WorldQuestTracker.AllTaskPOIs [i]:Hide()
								end
							end
						end
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
	
	if (WorldQuestTracker.WorldMap_GoldIndicator) then
		WorldQuestTracker.WorldMap_GoldIndicator.text = floor (total_Gold / 10000)
		if (total_Resources >= 1000) then
			WorldQuestTracker.WorldMap_ResourceIndicator.text = WorldQuestTracker.ToK (total_Resources)
		else
			WorldQuestTracker.WorldMap_ResourceIndicator.text = total_Resources
		end
		if (total_APower >= 1000) then
			WorldQuestTracker.WorldMap_APowerIndicator.text = WorldQuestTracker.ToK (total_APower)
		else
			WorldQuestTracker.WorldMap_APowerIndicator.text = total_APower
		end
		WorldQuestTracker.WorldMap_APowerIndicator.Amount = total_APower
	end
	
	WorldQuestTracker.UpdateZoneSummaryFrame()
	
end

WorldMapActionButtonPressed = function()
	WorldQuestTracker.Temp_HideZoneWidgets = GetTime() + 5
	WorldQuestTracker.UpdateZoneWidgets()
	WorldQuestTracker.ScheduleZoneMapUpdate (6)
end
hooksecurefunc ("ClickWorldMapActionButton", function()
	WorldMapActionButtonPressed()
end)

--atualiza o widget da quest no mapa da zona ~setupzone ~updatezone ~zoneupdate
function WorldQuestTracker.SetupWorldQuestButton (self, worldQuestType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget, mapID)
	local questID = self.questID
	if (not questID) then
		return
	end
	
	self.worldQuestType = worldQuestType
	self.rarity = rarity
	self.isElite = isElite
	self.tradeskillLineIndex = tradeskillLineIndex
	self.inProgress = inProgress
	self.selected = selected
	self.isCriteria = isCriteria
	self.isSpellTarget = isSpellTarget
	
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
	self.flagCriteriaMatchGlow:Hide()
	self.questTypeBlip:Hide()
	self.partySharedBlip:Hide()
	
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
			--self.flagCriteriaMatchGlow:Show()
			self.criteriaIndicator:Show()
			self.criteriaIndicatorGlow:Show()
		else
			self.flagCriteriaMatchGlow:Hide()
			self.criteriaIndicator:Hide()
			self.criteriaIndicatorGlow:Hide()
		end
		
		if (not WorldQuestTracker.db.profile.use_tracker) then
			if (WorldQuestTracker.IsQuestOnObjectiveTracker (questID)) then
				if (rarity == LE_WORLD_QUEST_QUALITY_RARE or rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
					self.IsTrackingRareGlow:Show()
				end
				self.IsTrackingGlow:Show()
			end
		else
			if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
				if (rarity == LE_WORLD_QUEST_QUALITY_RARE or rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
					if (mapID ~= suramar_mapId) then
						self.IsTrackingRareGlow:Show()
					end
				end
				self.IsTrackingGlow:Show()
			end
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
		
		--shared quest (zone)
		if (WorldQuestTracker.IsPartyQuest (questID)) then
			self.partySharedBlip:Show()
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
				
				WorldQuestTracker.UpdateBorder (self, rarity, worldQuestType, mapID)
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

					WorldQuestTracker.UpdateBorder (self, rarity, worldQuestType, mapID)
					
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

					local research_nameLoc, research_timeleftString, research_timeLeft, research_elapsedTime = WorldQuestTracker:GetNextResearchNoteTime()
					if (research_timeLeft and research_timeLeft > 60) then
						research_timeLeft = research_timeLeft / 60 --convert in minutes
					end
					
					if (research_timeLeft and research_timeLeft < timeLeft) then
						self.Texture:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blue_roundT]])
					else
						self.Texture:SetTexture (texture)
					end
					
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

					local color = ""
					if (quality == 4 or quality == 3) then
						color =  WorldQuestTracker.RarityColors [quality]
					end
					
					self.flagText:SetText ((isStackable and quantity and quantity >= 1 and quantity or false) or (itemLevel and itemLevel > 5 and (color) .. itemLevel) or "")
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
				
				WorldQuestTracker.UpdateBorder (self, rarity, worldQuestType, mapID)
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
	if (WorldQuestTracker.lastZoneWidgetsUpdate + 20 < GetTime()) then
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
	
	--WorldQuestTracker.db.profile.AlertTutorialStep = 2
	
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
		alert.label = L["S_TUTORIAL_PARTY"]
		alert.Text:SetSpacing (4)
		MicroButtonAlert_SetText (alert, alert.label)
		alert:SetPoint ("topleft", worldFramePOIs, "topleft", 269, -397)
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
		
	elseif (WorldQuestTracker.db.profile.AlertTutorialStep == 4) then
		local alert = CreateFrame ("frame", "WorldQuestTrackerTutorialAlert4", worldFramePOIs, "MicroButtonAlertTemplate")
		alert:SetFrameLevel (302)
		alert.label = "Click on Summary to see statistics and a saved list of quests on other characters."
		alert.Text:SetSpacing (4)
		MicroButtonAlert_SetText (alert, alert.label)
		alert:SetPoint ("topleft", worldFramePOIs, "topleft", 0, -393)
		alert.Arrow:ClearAllPoints()
		alert.Arrow:SetPoint ("topleft", alert, "bottomleft", 10, 0)
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
	if (WorldQuestTracker.lastMapTap+0.3 > GetTime() and not InCombatLockdown() and WorldQuestTracker.CanShowBrokenIsles()) then
		
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
	WorldQuestTracker.lastMapTap = GetTime()
	
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
			
			--> some addon is adding these words on the global namespace.
			--> I trully believe that it's not intended at all, so let's just clear.
			--> it is messing with the framework.
			_G ["left"] = nil
			_G ["right"] = nil
			_G ["topleft"] = nil
			_G ["topright"] = nil

			local CooltipOnTop_WhenFullScreen = function()
				if (not WorldMapFrame_InWindowedMode()) then
					GameCooltipFrame1:SetParent (WorldMapFrame)
					GameCooltipFrame1:SetFrameLevel (4000)
					GameCooltipFrame2:SetParent (WorldMapFrame)
					GameCooltipFrame2:SetFrameLevel (4000)
				end
			end
			
			function WorldQuestTracker.OpenSharePanel()
				if (WorldQuestTrackerSharePanel) then
					WorldQuestTrackerSharePanel:Show()
					return
				end
				
				local f = DF:CreateSimplePanel (UIParent, 460, 90, L["S_SHAREPANEL_TITLE"], "WorldQuestTrackerSharePanel")
				f:SetFrameStrata ("TOOLTIP")
				f:SetPoint ("center", WorldMapScrollFrame, "center")
				
				DF:CreateBorder (f)
				
				local text1 = DF:CreateLabel (f, L["S_SHAREPANEL_THANKS"])
				text1:SetPoint ("center", f, "center", 0, -0)
				text1:SetJustifyH ("center")
				
				local LinkBox = DF:CreateTextEntry (f, function()end, 380, 20, "ExportLinkBox", _, _, DF:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
				LinkBox:SetPoint ("center", f, "center", 0, -30)
				
				f:SetScript ("OnShow", function()
					LinkBox:SetText ([[https://mods.curse.com/addons/wow/world-quest-tracker]])
					C_Timer.After (1, function()
						LinkBox:SetFocus (true)
						LinkBox:HighlightText()
					end)
				end)
				
				f:Hide()
				f:Show()
			end
			
			--go to broken isles button ~worldquestbutton ~worldmapbutton ~worldbutton
			local WorldQuestButton = CreateFrame ("button", "WorldQuestTrackerGoToBIButton", WorldMapFrame.UIElementsFrame)
			WorldQuestButton:SetSize (64, 32)
			WorldQuestButton:SetPoint ("right", WorldMapFrame.UIElementsFrame.CloseQuestPanelButton, "left", -2, 0)
			WorldQuestButton.Background = WorldQuestButton:CreateTexture (nil, "background")
			WorldQuestButton.Background:SetSize (64, 32)
			WorldQuestButton.Background:SetAtlas ("MapCornerShadow-Right")
			WorldQuestButton.Background:SetPoint ("bottomright", 2, -1)
			WorldQuestButton:SetNormalTexture ([[Interface\AddOns\WorldQuestTracker\media\world_quest_button]])
			WorldQuestButton:GetNormalTexture():SetTexCoord (0, 1, 0, .5)
			WorldQuestButton:SetPushedTexture ([[Interface\AddOns\WorldQuestTracker\media\world_quest_button_pushed]])
			WorldQuestButton:GetPushedTexture():SetTexCoord (0, 1, 0, .5)
			
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
			
			-- õptionsfunc ~optionsfunc
			local options_on_click = function (_, _, option, value, value2, mouseButton)
			
				if (option == "world_map_config") then
					WorldQuestTracker.db.profile.worldmap_widgets [value] = value2
					if (value == "textsize") then
						WorldQuestTracker.SetTextSize ("WorldMap", value2)
					elseif (value == "scale") then
						if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
							WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
						end
					end
					return
					
				elseif (option == "zone_map_config") then
					WorldQuestTracker.db.profile.zonemap_widgets [value] = value2
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneWidgets()
					end
					return
				end

				if (option:find ("tomtom")) then
					local option = option:gsub ("tomtom%-", "")
					WorldQuestTracker.db.profile.tomtom [option] = value
					GameCooltip:Hide()
					
					if (option == "enabled") then
						if (value) then
							--adiciona todas as quests to tracker no tomtom
							for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
								local quest = WorldQuestTracker.QuestTrackList [i]
								local questID = quest.questID
								local mapID = quest.mapID
								WorldQuestTracker.AddQuestTomTom (questID, mapID, true)
							end
							WorldQuestTracker.RemoveAllQuestsFromTracker()
						else
							--desligou o tracker do tomtom
							for questID, t in pairs (WorldQuestTracker.db.profile.tomtom.uids) do
								if (type (questID) == "number" and QuestMapFrame_IsQuestWorldQuest (questID)) then
									--procura o botão da quest
									for _, widget in ipairs (all_widgets) do
										if (widget.questID == questID) then
											WorldQuestTracker.AddQuestToTracker (widget)
											TomTom:RemoveWaypoint (t)
											break
										end
									end
								end
							end
							wipe (WorldQuestTracker.db.profile.tomtom.uids)
							WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true, false, false, true)
						end
					end
					
					return
				end
			
				if (option == "share_addon") then
					WorldQuestTracker.OpenSharePanel()
					GameCooltip:Hide()
					return
					
				elseif (option == "tracker_scale") then
					WorldQuestTracker.db.profile [option] = value
					WorldQuestTracker.UpdateTrackerScale()
				
				elseif (option == "clear_quest_cache") then
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
						WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true, true, false, true)
					else
						
					end
					
				elseif (option == "arrow_update_speed") then
					WorldQuestTracker.db.profile.arrow_update_frequence = value
					WorldQuestTracker.UpdateArrowFrequence()
					GameCooltip:Hide()
					return
				
				elseif (option == "untrack_quests") then
					WorldQuestTracker.RemoveAllQuestsFromTracker()
					
					if (TomTom and IsAddOnLoaded ("TomTom")) then
						for questID, t in pairs (WorldQuestTracker.db.profile.tomtom.uids) do
							TomTom:RemoveWaypoint (t)
						end
						wipe (WorldQuestTracker.db.profile.tomtom.uids)
					end
					
					GameCooltip:Hide()
					return
				
				elseif (option == "use_quest_summary") then
					WorldQuestTracker.db.profile [option] = value
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneWidgets()
					end
				else
					WorldQuestTracker.db.profile [option] = value
					if (option == "bar_anchor") then
						WorldQuestTracker:SetStatusBarAnchor()
					end
				end
			
				if (option == "tracker_is_locked") then
					--> só aparece esta opção quando o tracker esta móvel
					if (WorldQuestTracker.db.profile.tracker_is_movable) then
						if (value) then
							--> o tracker agora esta trancado - desliga o mouse
							WorldQuestTrackerScreenPanel:EnableMouse (false)
							--LibWindow.MakeDraggable (WorldQuestTrackerScreenPanel)
						else
							--> o tracker agora está movel - liga o mouse
							WorldQuestTrackerScreenPanel:EnableMouse (true)
							LibWindow.MakeDraggable (WorldQuestTrackerScreenPanel)
						end
					end
				end
				
				if (option == "tracker_is_movable") then
				
					if (not LibWindow) then
						print ("|cFFFFAA00World Quest Tracker|r: libwindow not found, did you just updated the addon? try reopening the client.|r")
					end
				
					if (value) then
						--> o tracker agora é móvel
						--verificar a opção se esta locked
						if (LibWindow and not WorldQuestTrackerScreenPanel.RegisteredForLibWindow) then
							LibWindow.RestorePosition (WorldQuestTrackerScreenPanel)
							WorldQuestTrackerScreenPanel.RegisteredForLibWindow = true
						end
						
						WorldQuestTracker.RefreshAnchor()
						if (not WorldQuestTracker.db.profile.tracker_is_locked) then
							WorldQuestTrackerScreenPanel:EnableMouse (true)
							LibWindow.MakeDraggable (WorldQuestTrackerScreenPanel)
						end
					else
						--> o tracker agora auto alinha com o objective tracker
						WorldQuestTracker.RefreshAnchor()
						WorldQuestTrackerScreenPanel:EnableMouse (false)
					end
				end
			
				if (option ~= "show_timeleft" and option ~= "alpha_time_priority" and option ~= "force_sort_by_timeleft") then
					GameCooltip:ExecFunc (WorldQuestTrackerOptionsButton)
				else
					--> se for do painel de tempo, dar refresh no world map
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
						WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true, true, false, true)
					end
					GameCooltip:Close()
				end
			end			

			--avisar sobre duplo tap 
			-- ~bar ~statusbar
			WorldQuestTracker.DoubleTapFrame = CreateFrame ("frame", "WorldQuestTrackerDoubleTapFrame", worldFramePOIs)
			WorldQuestTracker.DoubleTapFrame:SetHeight (18)
			
			--if (ElvUI and IsAddOnLoaded ("ElvUI")) then
			--	WorldQuestTracker.DoubleTapFrame:SetPoint ("bottomleft", WorldMapScrollFrame, "bottomleft", 0, 0) --thanks @q3fuba on curse forge
			--else
			--	WorldQuestTracker.DoubleTapFrame:SetPoint ("bottomleft", WorldMapFrame, "bottomleft", 0, 0) --thanks @InKahootz on curse forge
			--end

			--> looks like this one fix on elvui and without elvui 
			-- ~point

			--background
			local doubleTapBackground = WorldQuestTracker.DoubleTapFrame:CreateTexture (nil, "overlay")
			doubleTapBackground:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-HorizontalShadow]])
			doubleTapBackground:SetTexCoord (0, .5, 0, 1)
			doubleTapBackground:SetHeight (18)
			
			function WorldQuestTracker:SetStatusBarAnchor (anchor)
				anchor = anchor or WorldQuestTracker.db.profile.bar_anchor
				WorldQuestTracker.db.profile.bar_anchor = anchor
			
				if (anchor == "bottom") then
					WorldQuestTracker.DoubleTapFrame:ClearAllPoints()
					WorldQuestTracker.DoubleTapFrame:SetPoint ("bottomleft", WorldMapScrollFrame, "bottomleft", 0, 0)
					WorldQuestTracker.DoubleTapFrame:SetPoint ("bottomright", WorldMapScrollFrame, "bottomright", 0, 0)
					doubleTapBackground:ClearAllPoints()
					doubleTapBackground:SetPoint ("bottomleft", WorldQuestTracker.DoubleTapFrame, "bottomleft", 0, 0)
					doubleTapBackground:SetPoint ("bottomright", WorldQuestButton, "bottomleft", 0, 0)
					
				elseif (anchor == "top") then
					--top position
					WorldQuestTracker.DoubleTapFrame:ClearAllPoints()
					WorldQuestTracker.DoubleTapFrame:SetPoint ("topleft", WorldMapScrollFrame, "topleft", 0, 0)
					WorldQuestTracker.DoubleTapFrame:SetPoint ("topright", WorldMapScrollFrame, "topright", 0, 0)
					doubleTapBackground:ClearAllPoints()
					doubleTapBackground:SetPoint ("topleft", WorldQuestTracker.DoubleTapFrame, "topleft", 0, 0)
					doubleTapBackground:SetPoint ("topright", WorldQuestTracker.DoubleTapFrame, "topright", 0, 0)
				end
			end
			
			WorldQuestTracker:SetStatusBarAnchor()
			
			---------------------------------------------------------
			
			-- ~shipment ready
			
			--WorldQuestTracker:GetNextResearchNoteTime()
			--local nameLoc, timeleftString, timeLeft, elapsedTime, shipmentsReady = WorldQuestTracker:GetNextResearchNoteTime()
			local shipmentsReadyFrame = CreateFrame ("frame", "WorldQuestTrackerShipmentsReadyFrame", WorldMapFrame.UIElementsFrame)
			shipmentsReadyFrame:SetPoint ("center", WorldQuestTracker.DoubleTapFrame, "center", 0, 0)
			shipmentsReadyFrame:SetPoint ("bottom", WorldQuestTracker.DoubleTapFrame, "top", 0, 10)
			shipmentsReadyFrame:SetSize (280, 20)
			shipmentsReadyFrame.LastAnimation = 0
			
			local shipmentsReadyBackground = shipmentsReadyFrame:CreateTexture (nil, "border")
			shipmentsReadyBackground:SetPoint ("left", shipmentsReadyFrame, "left", -20, 0)
			shipmentsReadyBackground:SetPoint ("right", shipmentsReadyFrame, "right", 20, 0)
			shipmentsReadyBackground:SetHeight (40)
			shipmentsReadyBackground:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-Alert-Background-Mini]])
			
			local shipmentsReadyTexture = shipmentsReadyFrame:CreateTexture (nil, "artwork")
			shipmentsReadyTexture:SetPoint ("left", shipmentsReadyFrame, "left")
			shipmentsReadyTexture:SetTexture (237446)
			shipmentsReadyTexture:SetSize (20, 20)
			shipmentsReadyTexture:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
			local shipmentsReadyText = shipmentsReadyFrame:CreateFontString (nil, "artwork", "GameFontNormal")
			shipmentsReadyText:SetPoint ("left", shipmentsReadyTexture, "right", 2, 0)
			shipmentsReadyFrame.Texture = shipmentsReadyTexture
			shipmentsReadyFrame.Text = shipmentsReadyText
			shipmentsReadyFrame:Hide()
			
			local smallFlash = shipmentsReadyFrame:CreateTexture (nil, "overlay")
			smallFlash:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-Alert-Glow]])
			smallFlash:SetTexCoord (400/512, 470/512, 0, 70/256)
			smallFlash:SetSize (50, 34)
			smallFlash:SetBlendMode ("ADD")
			smallFlash:SetAlpha (.3)
			smallFlash:SetPoint ("left", shipmentsReadyFrame, "left", -30, 0)
			
			local shipmentAnimation = DF:CreateAnimationHub (smallFlash, function() smallFlash:Show() end, function() smallFlash:Hide() end)
			local shipmentAnim1 = DF:CreateAnimation (shipmentAnimation, "translation", 1, .33, 30, 0)
			
			local shipmentAnimation2 = DF:CreateAnimationHub (shipmentsReadyFrame)
			local shipmentAnim1 = DF:CreateAnimation (shipmentAnimation2, "scale", 1, .1, 1, 1, 1.1, 1.1)
			local shipmentAnim2 = DF:CreateAnimation (shipmentAnimation2, "scale", 2, .1, 1.1, 1.1, 1, 1)
			
			function WorldQuestTracker.ShowResearchNoteReady (name)
				shipmentsReadyFrame:Show()
				name = name or "Artifact Research Notes"
				shipmentsReadyFrame.Text:SetText (name .. " " .. (READY or "") .. "!")
				shipmentsReadyFrame:SetWidth (shipmentsReadyFrame.Text:GetStringWidth() + 20)
				if (not shipmentAnimation:IsPlaying() and shipmentsReadyFrame.LastAnimation+30 < GetTime()) then
					shipmentAnimation2:Play()
					shipmentAnimation:Play()
					shipmentsReadyFrame.LastAnimation = GetTime()
				end
			end
			function WorldQuestTracker.HideResearchNoteReady()
				shipmentsReadyFrame:Hide()
			end
			
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
			CloseSummaryPanel:GetNormalTexture():SetTexCoord (0, 1, 0, .5)
			CloseSummaryPanel:SetPushedTexture ([[Interface\AddOns\WorldQuestTracker\media\close_summary_button_pushed]])
			CloseSummaryPanel:GetPushedTexture():SetTexCoord (0, 1, 0, .5)
			
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
			
			local accountLifeTime_Texture = DF:CreateImage (SummaryFrameUp, [[Interface\BUTTONS\AdventureGuideMicrobuttonAlert]], 16, 16, "artwork", {5/32, 27/32, 5/32, 27/32})
			accountLifeTime_Texture:SetPoint (x, -10)
			accountLifeTime_Texture:SetAlpha (.7)
			
			local characterLifeTime_Texture = DF:CreateImage (SummaryFrameUp, [[Interface\BUTTONS\AdventureGuideMicrobuttonAlert]], 16, 16, "artwork", {5/32, 27/32, 5/32, 27/32})
			characterLifeTime_Texture:SetPoint (x, -97)
			characterLifeTime_Texture:SetAlpha (.7)
			
			local graphicTime_Texture = DF:CreateImage (SummaryFrameUp, [[Interface\BUTTONS\AdventureGuideMicrobuttonAlert]], 16, 16, "artwork", {5/32, 27/32, 5/32, 27/32})
			graphicTime_Texture:SetPoint (x, -228)
			graphicTime_Texture:SetAlpha (.7)
			
			local otherCharacters_Texture = DF:CreateImage (SummaryFrameUp, [[Interface\BUTTONS\AdventureGuideMicrobuttonAlert]], 16, 16, "artwork", {5/32, 27/32, 5/32, 27/32})
			otherCharacters_Texture:SetPoint ("topleft", SummaryFrameUp, "topright", -220, -10)
			otherCharacters_Texture:SetAlpha (.7)			

			local accountLifeTime = DF:CreateLabel (SummaryFrameUp, L["S_SUMMARYPANEL_LIFETIMESTATISTICS_ACCOUNT"] .. ":", TitleTemplate)
			accountLifeTime:SetPoint ("left", accountLifeTime_Texture, "right", 2, 1)
			SummaryFrameUp.AccountLifeTime_Gold = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_GOLD"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_Resources = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_RESOURCE"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_APower = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_QCompleted = DF:CreateLabel (SummaryFrameUp, L["S_QUESTSCOMPLETED"] .. ": %s")
			SummaryFrameUp.AccountLifeTime_Gold:SetPoint (x, -30)
			SummaryFrameUp.AccountLifeTime_Resources:SetPoint (x, -45)
			SummaryFrameUp.AccountLifeTime_APower:SetPoint (x, -60)
			SummaryFrameUp.AccountLifeTime_QCompleted:SetPoint (x, -75)
			
			local characterLifeTime = DF:CreateLabel (SummaryFrameUp, L["S_SUMMARYPANEL_LIFETIMESTATISTICS_CHARACTER"] .. ":", TitleTemplate)
			characterLifeTime:SetPoint ("left", characterLifeTime_Texture, "right", 2, 1)
			SummaryFrameUp.CharacterLifeTime_Gold = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_GOLD"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_Resources = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_RESOURCE"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_APower = DF:CreateLabel (SummaryFrameUp, L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_QCompleted = DF:CreateLabel (SummaryFrameUp, L["S_QUESTSCOMPLETED"] .. ": %s")
			SummaryFrameUp.CharacterLifeTime_Gold:SetPoint (x, -120)
			SummaryFrameUp.CharacterLifeTime_Resources:SetPoint (x, -135)
			SummaryFrameUp.CharacterLifeTime_APower:SetPoint (x, -150)
			SummaryFrameUp.CharacterLifeTime_QCompleted:SetPoint (x, -165)
			
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
					SummaryFrame:Show()
					if (WorldQuestTracker.db.profile.sound_enabled) then
						if (math.random (5) == 1) then
							PlaySoundFile ("Interface\\AddOns\\WorldQuestTracker\\media\\swap_panels1.mp3")
						else
							PlaySoundFile ("Interface\\AddOns\\WorldQuestTracker\\media\\swap_panels2.mp3")	
						end
					end
				end, 
				function() 
					SummaryFrameUp.ShowAnimation:Play()
				end)
			DF:CreateAnimation (SummaryFrame.ShowAnimation, "Scale", 1, .1, .1, 1, 1, 1, "left", 0, 0)
			
			SummaryFrame.HideAnimation = DF:CreateAnimationHub (SummaryFrame, function()
				PlaySound ("igMainMenuOptionCheckBoxOn")
			end, 
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
					tinsert (formated_quest_table, {"blank"})
					tinsert (formated_quest_table, {true, guid})
					tinsert (formated_quest_table, {"blank"})
					for questID, questInfo in pairs (questTable or {}) do
						tinsert (formated_quest_table, {questID, questInfo})
					end
				end
			end
			
			local scroll_line_height = 14
			local scroll_line_amount = 26
			local scroll_width = 195
			
			local line_onenter = function (self)
				if (self.questID) then
					self.numObjectives = 10
					self.UpdateTooltip = TaskPOI_OnEnter
					TaskPOI_OnEnter (self)
					self:SetBackdropColor (.5, .50, .50, 0.75)
				end
			end
			local line_onleave = function (self)
				TaskPOI_OnLeave (self)
				self:SetBackdropColor (0, 0, 0, 0.2)
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
						line.questID = nil
						if (quest [1] == "blank") then
							line.name:SetText ("")
							line.timeleft:SetText ("")
							line.icon:SetTexture (nil)
							
						elseif (quest [1] == true) then
							local name, realm, class = WorldQuestTracker.GetCharInfo (quest [2])
							local color = RAID_CLASS_COLORS [class]
							local name = name .. " - " .. realm
							if (color) then
								name = "|c" .. color.colorStr .. name .. "|r"
							end
							line.name:SetText (name)
							line.timeleft:SetText ("")
							line.name:SetWidth (180)
							
							if (class) then
								line.icon:SetTexture ([[Interface\WORLDSTATEFRAME\Icons-Classes]])
								line.icon:SetTexCoord (unpack (CLASS_ICON_TCOORDS [class]))
							else
								line.icon:SetTexture (nil)
							end
						else
							local questInfo = quest [2]
							local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (quest [1])

							title = title or L["S_UNKNOWNQUEST"]
							
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
							local color
							if (timeLeft > 120) then
								color = "FFFFFFFF"
							elseif (timeLeft > 45) then
								color = "FFFFAA22"
							else
								color = "FFFF3322"
							end
							line.name:SetText ("|cFFFFDD00[" .. rewardAmount .. "]|r |c" .. colorByRarity .. title .. "|r")
							line.timeleft:SetText (timeLeft > 0 and "|c" .. color .. SecondsToTime (timeLeft * 60) .. "|r" or "|cFFFF5500" .. L["S_SUMMARYPANEL_EXPIRED"] .. "|r")
							if (type (questInfo.rewardTexture) == "string" and questInfo.rewardTexture:find ("icon_artifactpower")) then
								--forçando sempre mostrar icone vermelho
								line.icon:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blueT]])
							else
								line.icon:SetTexture (questInfo.rewardTexture)
							end
							
							line.icon:SetTexCoord (5/64, 59/64, 5/64, 59/64)
							line.name:SetWidth (100)
							
							if (timeLeft <= 0) then
								line:SetAlpha (.5)
							end
							
							line.questID = quest [1]
						end
					end
				end
			end

			local ScrollTitle = DF:CreateLabel (SummaryFrameUp, L["S_SUMMARYPANEL_OTHERCHARACTERS"] .. ":", TitleTemplate)
			ScrollTitle:SetPoint ("left", otherCharacters_Texture, "right", 2, 1)
			
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

			-- ~gframe
			local GoldGraphic = DF:CreateGFrame (SummaryFrameUp, 422, 160, 28, GF_LineOnEnter, GF_LineOnLeave, "GoldGraphic", "WorldQuestTrackerGoldGraphic")
			GoldGraphic:SetPoint ("topleft", 40, -248)
			GoldGraphic:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
			GoldGraphic:SetBackdropColor (0, 0, 0, .6)
			
			local GoldGraphicTextBg = CreateFrame ("frame", nil, GoldGraphic)
			GoldGraphicTextBg:SetPoint ("topleft", GoldGraphic, "bottomleft", 0, -2)
			GoldGraphicTextBg:SetPoint ("topright", GoldGraphic, "bottomright", 0, -2)
			GoldGraphicTextBg:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
			GoldGraphicTextBg:SetBackdropColor (0, 0, 0, .4)
			GoldGraphicTextBg:SetHeight (20)
			--DF:CreateBorder (GoldGraphic, .4, .2, .05)
			
			local leftLine = DF:CreateImage (GoldGraphic)
			leftLine:SetColorTexture (1, 1, 1, .35)
			leftLine:SetSize (1, 160)
			leftLine:SetPoint ("topleft", GoldGraphic, "topleft", -1, 0)
			leftLine:SetPoint ("bottomleft", GoldGraphic, "bottomleft", -1, -20)
			
			local bottomLine = DF:CreateImage (GoldGraphic)
			bottomLine:SetColorTexture (1, 1, 1, .35)
			bottomLine:SetSize (422, 1)
			bottomLine:SetPoint ("bottomleft", GoldGraphic, "bottomleft", -35, -2)
			bottomLine:SetPoint ("bottomright", GoldGraphic, "bottomright", 0, -2)
			
			GoldGraphic.AmountIndicators = {}
			for i = 0, 5 do
				local text = DF:CreateLabel (GoldGraphic, "")
				text:SetPoint ("topright", GoldGraphic, "topleft", -4, -(i*32) - 2)
				text.align = "right"
				text.textcolor = "silver"
				tinsert (GoldGraphic.AmountIndicators, text)
				local line = DF:CreateImage (GoldGraphic)
				line:SetColorTexture (1, 1, 1, .05)
				line:SetSize (420, 1)
				line:SetPoint (0, -(i*32))
			end
			
			local GoldGraphicTitle = DF:CreateLabel (SummaryFrameUp, L["S_SUMMARYPANEL_LAST15DAYS"] .. ":", TitleTemplate)
			--GoldGraphicTitle:SetPoint ("bottomleft", GoldGraphic, "topleft", 0, 6)
			GoldGraphicTitle:SetPoint ("left", graphicTime_Texture, "right", 2, 1)
			
			local GraphicDataToUse = 1
			local OnSelectGraphic = function (_, _, value)
				GraphicDataToUse = value
				SummaryFrameUp.RefreshGraphic()
			end
			
			local class = select (2, UnitClass ("player"))
			local color = RAID_CLASS_COLORS [class] and RAID_CLASS_COLORS [class].colorStr or "FFFFFFFF"
			local graphic_options = {
				{label = L["S_OVERALL"] .. " [|cFFC0C0C0" .. L["S_MAPBAR_SUMMARYMENU_ACCOUNTWIDE"] .. "|r]", value = 1, onclick = OnSelectGraphic,
				icon = [[Interface\GossipFrame\BankerGossipIcon]], iconsize = {14, 14}}, --texcoord = {3/32, 29/32, 3/32, 29/32}
				{label = L["S_QUESTTYPE_GOLD"] .. " [|cFFC0C0C0" .. L["S_MAPBAR_SUMMARYMENU_ACCOUNTWIDE"] .. "|r]", value = 2, onclick = OnSelectGraphic,
				icon = WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_GOLD].icon, iconsize = {14, 14}},
				{label = L["S_QUESTTYPE_RESOURCE"] .. " [|c" .. color .. UnitName ("player") .. "|r]", value = 3, onclick = OnSelectGraphic,
				icon = WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_RESOURCE].icon, iconsize = {14, 14}},
				{label = L["S_QUESTTYPE_ARTIFACTPOWER"] .. " [|c" .. color .. UnitName ("player") .. "|r]", value = 4, onclick = OnSelectGraphic,
				icon = WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_APOWER].icon, iconsize = {14, 14}}
			}
			local graphic_options_func = function()
				return graphic_options
			end
			
			local dropdown_diff = DF:CreateDropDown (SummaryFrameUp, graphic_options_func, 1, 180, 20, "dropdown_graphic", _, DF:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
			dropdown_diff:SetPoint ("left", GoldGraphicTitle, "right", 4, 0)

			local empty_day = {
				["artifact"] = 0,
				["resource"] = 0,
				["quest"] = 0,
				["gold"] = 0,
				["blood"] = 0,
			}
	
			SummaryFrameUp.RefreshGraphic = function()
				GoldGraphic:Reset()

				local twoWeeks
				local dateString
				
				if (GraphicDataToUse == 1 or GraphicDataToUse == 2) then --account overall
					twoWeeks = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_PERIOD, WQT_QUERYDB_ACCOUNT, WQT_DATE_2WEEK)
					dateString = WorldQuestTracker.GetDateString (WQT_DATE_2WEEK)
				elseif (GraphicDataToUse == 3 or GraphicDataToUse == 4) then
					twoWeeks = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_PERIOD, WQT_QUERYDB_LOCAL, WQT_DATE_2WEEK)
					dateString = WorldQuestTracker.GetDateString (WQT_DATE_2WEEK)
				end
				
				local data = {}
				for i = 1, #dateString do
					local hadTable = false
					for o = 1, #twoWeeks do
						if (twoWeeks[o].day == dateString[i]) then
							if (GraphicDataToUse == 1) then
								local gold = (twoWeeks[o].table.gold and twoWeeks[o].table.gold/10000) or 0
								local resource = twoWeeks[o].table.resource or 0
								local artifact = twoWeeks[o].table.artifact or 0
								local blood = (twoWeeks[o].table.blood and twoWeeks[o].table.blood*300) or 0
								
								local total = gold + resource + artifact + blood

								data [#data+1] = {value = total or 0, text = dateString[i]:gsub ("^%d%d%d%d", ""), table = twoWeeks[o].table}
								hadTable = true
								
							elseif (GraphicDataToUse == 2) then
								local gold = (twoWeeks[o].table.gold and twoWeeks[o].table.gold/10000) or 0
								data [#data+1] = {value = gold, text = dateString[i]:gsub ("^%d%d%d%d", ""), table = twoWeeks[o].table}
								hadTable = true
								
							elseif (GraphicDataToUse == 3) then
								local resource = twoWeeks[o].table.resource or 0
								data [#data+1] = {value = resource, text = dateString[i]:gsub ("^%d%d%d%d", ""), table = twoWeeks[o].table}
								hadTable = true
								
							elseif (GraphicDataToUse == 4) then
								local artifact = twoWeeks[o].table.artifact or 0
								data [#data+1] = {value = artifact, text = dateString[i]:gsub ("^%d%d%d%d", ""), table = twoWeeks[o].table}
								hadTable = true
							end
							break
						end
					end
					if (not hadTable) then
						data [#data+1] = {value = 0, text = dateString[i]:gsub ("^%d%d%d%d", ""), table = empty_day}
					end
					
				end
				
				data = DF.table.reverse (data)
				GoldGraphic:UpdateLines (data)
				
				for i = 1, 5 do
					local text = GoldGraphic.AmountIndicators [i]
					local percent = 20 * abs (i - 6)
					local total = GoldGraphic.MaxValue / 100 * percent
					text.text = WorldQuestTracker.ToK (total)
				end
				
				--customize text anchor
				for _, line in ipairs (GoldGraphic._lines) do
					line.timeline:SetPoint ("bottomright", line, "bottomright", -2, -18)
				end
			end
	
			GoldGraphic:SetScript ("OnShow", function (self)
				SummaryFrameUp.RefreshGraphic()
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
				
				GameCooltip:ExecFunc (sortButton)
				
				--atualiza as quests
				if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
				end
			end
			
			local change_sort_timeleft_mode = function (_, _, amount)
				if (WorldQuestTracker.db.profile.sort_time_priority == amount) then
					WorldQuestTracker.db.profile.sort_time_priority = false
				else
					WorldQuestTracker.db.profile.sort_time_priority = amount
				end
				
				GameCooltip:Hide()
				
				--atualiza as quests
				
				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
				elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
					WorldQuestTracker.UpdateZoneWidgets()
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
			setup_button (filterButton, L["S_MAPBAR_FILTER"])
			
			local filter_quest_type = function (_, _, questType, _, _, mouseButton)
				WorldQuestTracker.db.profile.filters [questType] = not WorldQuestTracker.db.profile.filters [questType]
			
				GameCooltip:ExecFunc (filterButton)
				
				--atualiza as quests
				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
				elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
					WorldQuestTracker.UpdateZoneWidgets()
				end				
			end
			
			local toggle_faction_objectives = function()
				WorldQuestTracker.db.profile.filter_always_show_faction_objectives = not WorldQuestTracker.db.profile.filter_always_show_faction_objectives
				GameCooltip:ExecFunc (filterButton)
				
				--atualiza as quests
				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
				elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
					WorldQuestTracker.UpdateZoneWidgets()
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
			
			---------------------------------------------------------
			-- ~time left
			
			local timeLeftButton = CreateFrame ("button", "WorldQuestTrackerTimeLeftButton", WorldQuestTracker.DoubleTapFrame)
			timeLeftButton:SetPoint ("left", filterButton, "right", 2, 0)
			setup_button (timeLeftButton, L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_TITLE"])
			
			
			local BuildTimeLeftMenu = function()
				GameCooltip:Preset (2)
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("FixedWidth", 180)
				GameCooltip:SetOption ("FixedWidthSub", 200)
				GameCooltip:SetOption ("SubMenuIsTooltip", true)
				GameCooltip:SetOption ("IgnoreArrows", true)
				
				GameCooltip:AddLine (format (L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"], 4))
				GameCooltip:AddMenu (1, change_sort_timeleft_mode, 4)
				if (WorldQuestTracker.db.profile.sort_time_priority == 4) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				
				GameCooltip:AddLine (format (L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"], 8), "", 1)
				GameCooltip:AddMenu (1, change_sort_timeleft_mode, 8)
				if (WorldQuestTracker.db.profile.sort_time_priority == 8) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				
				GameCooltip:AddLine (format (L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"], 12), "", 1)
				GameCooltip:AddMenu (1, change_sort_timeleft_mode, 12)
				if (WorldQuestTracker.db.profile.sort_time_priority == 12) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end

				GameCooltip:AddLine (format (L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"], 16), "", 1)
				GameCooltip:AddMenu (1, change_sort_timeleft_mode, 16)
				if (WorldQuestTracker.db.profile.sort_time_priority == 16) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				
				GameCooltip:AddLine (format (L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_OPTION"], 24), "", 1)
				GameCooltip:AddMenu (1, change_sort_timeleft_mode, 24)
				if (WorldQuestTracker.db.profile.sort_time_priority == 24) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				
				GameCooltip:AddLine ("$div", nil, 1, nil, -5, -11)

				GameCooltip:AddLine (L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_SHOWTEXT"], "", 1)
				GameCooltip:AddMenu (1, options_on_click, "show_timeleft", not WorldQuestTracker.db.profile.show_timeleft)
				if (WorldQuestTracker.db.profile.show_timeleft) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				
				GameCooltip:AddLine (L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_FADE"], "", 1)
				GameCooltip:AddMenu (1, options_on_click, "alpha_time_priority", not WorldQuestTracker.db.profile.alpha_time_priority)
				if (WorldQuestTracker.db.profile.alpha_time_priority) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				
				GameCooltip:AddLine (L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_SORTBYTIME"], "", 1)
				GameCooltip:AddMenu (1, options_on_click, "force_sort_by_timeleft", not WorldQuestTracker.db.profile.force_sort_by_timeleft)
				if (WorldQuestTracker.db.profile.force_sort_by_timeleft) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				
			end
			
			timeLeftButton.CoolTip = {
				Type = "menu",
				BuildFunc = BuildTimeLeftMenu, --> called when user mouse over the frame
				OnEnterFunc = function (self) 
					timeLeftButton.button_mouse_over = true
					button_onenter (self)
					C_Timer.After (.05, CooltipOnTop_WhenFullScreen)
				end,
				OnLeaveFunc = function (self) 
					timeLeftButton.button_mouse_over = false
					button_onleave (self)
				end,
				FixedValue = "none",
				ShowSpeed = 0.05,
				Options = function()
				end,
			}
			
			GameCooltip:CoolTipInject (timeLeftButton)			
			
			---------------------------------------------------------
			
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
			
			local BuildOptionsMenu = function() -- õptions ~options
				GameCooltip:Preset (2)
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("FixedWidth", 160)
				
				local IconSize = 14
				
				--all tracker options
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_TRACKERCONFIG"])
				GameCooltip:AddIcon ([[Interface\AddOns\WorldQuestTracker\media\ArrowGridT]], 1, 1, IconSize, IconSize, 944/1024, 993/1024, 272/1024, 324/1024)
				
				--use quest tracker
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_QUESTTRACKER"], "", 2)
				if (WorldQuestTracker.db.profile.use_tracker) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (2, options_on_click, "use_tracker", not WorldQuestTracker.db.profile.use_tracker)
				--
				GameCooltip:AddLine ("$div", nil, 2, nil, -5, -11)
				--
				
				GameCooltip:AddLine (format (L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"], "1.0"), "", 2)
				GameCooltip:AddMenu (2, options_on_click, "tracker_scale", 1)
				GameCooltip:AddLine (format (L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"], "1.1"), "", 2)
				GameCooltip:AddMenu (2, options_on_click, "tracker_scale", 1.1)
				GameCooltip:AddLine (format (L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"], "1.2"), "", 2)
				GameCooltip:AddMenu (2, options_on_click, "tracker_scale", 1.2)
				GameCooltip:AddLine (format (L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"], "1.3"), "", 2)
				GameCooltip:AddMenu (2, options_on_click, "tracker_scale", 1.3)
				
				--
				GameCooltip:AddLine ("$div", nil, 2, nil, -5, -11)
				--
				
				-- tracker movable
				--automatic
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_TRACKERMOVABLE_AUTO"], "", 2)
				if (not WorldQuestTracker.db.profile.tracker_is_movable) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (2, options_on_click, "tracker_is_movable", false)
				--manual
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_TRACKERMOVABLE_CUSTOM"], "", 2)
				if (WorldQuestTracker.db.profile.tracker_is_movable) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (2, options_on_click, "tracker_is_movable", true)
				
				if (WorldQuestTracker.db.profile.tracker_is_movable) then
					GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_TRACKERMOVABLE_LOCKED"], "", 2)
				else
					GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_TRACKERMOVABLE_LOCKED"], "", 2, "gray")
				end
				if (WorldQuestTracker.db.profile.tracker_is_locked) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (2, options_on_click, "tracker_is_locked", not WorldQuestTracker.db.profile.tracker_is_locked)
				
				--				
				GameCooltip:AddLine ("$div", nil, 2, nil, -5, -11)
				--
				
				--show yards distance on the tracker
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_YARDSDISTANCE"], "", 2)
				if (WorldQuestTracker.db.profile.show_yards_distance) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (2, options_on_click, "show_yards_distance", not WorldQuestTracker.db.profile.show_yards_distance)				
				
				--only show quests on the current zone
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_TRACKER_CURRENTZONE"], "", 2)
				if (WorldQuestTracker.db.profile.tracker_only_currentmap) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (2, options_on_click, "tracker_only_currentmap", not WorldQuestTracker.db.profile.tracker_only_currentmap)

				GameCooltip:AddLine (L["S_MAPBAR_SORTORDER_TIMELEFTPRIORITY_TITLE"], "", 2)
				if (WorldQuestTracker.db.profile.tracker_show_time) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (2, options_on_click, "tracker_show_time", not WorldQuestTracker.db.profile.tracker_show_time)

				--

				--World Map Config
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_WORLDMAPCONFIG"])
				GameCooltip:AddIcon ([[Interface\Worldmap\UI-World-Icon]], 1, 1, IconSize, IconSize)
				
				GameCooltip:AddLine ("Small Text Size", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "world_map_config", "textsize", 9)
				GameCooltip:AddLine ("Medium Text Size", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "world_map_config", "textsize",  10)
				GameCooltip:AddLine ("Large Text Size", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "world_map_config", "textsize",  11)
				
				GameCooltip:AddLine ("$div", nil, 2, nil, -7, -14)
				
				GameCooltip:AddLine ("Scale - Small", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "world_map_config", "scale", 1)
				GameCooltip:AddLine ("Scale - Medium", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "world_map_config", "scale",  1.2)
				GameCooltip:AddLine ("Scale - Big", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "world_map_config", "scale",  1.4)
				GameCooltip:AddLine ("Scale - Very Big", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "world_map_config", "scale",  1.6)
				
				--Zone Map Config
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_ZONEMAPCONFIG"])
				GameCooltip:AddIcon ([[Interface\Worldmap\WorldMap-Icon]], 1, 1, IconSize, IconSize)
				
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_ZONE_QUESTSUMMARY"], "", 2)
				if (WorldQuestTracker.db.profile.use_quest_summary) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (2, options_on_click, "use_quest_summary", not WorldQuestTracker.db.profile.use_quest_summary)
				
				GameCooltip:AddLine ("$div", nil, 2, nil, -7, -14)
				
				GameCooltip:AddLine ("Small Quest Icons", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "zone_map_config", "scale", 1)
				GameCooltip:AddLine ("Medium Quest Icons", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "zone_map_config", "scale",  1.15)
				GameCooltip:AddLine ("Large Quest Icons", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "zone_map_config", "scale",  1.23)
				GameCooltip:AddLine ("Very Large Quest Icons", "", 2)
				GameCooltip:AddMenu (2, options_on_click, "zone_map_config", "scale",  1.35)

				GameCooltip:AddLine ("$div")

				--
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_SOUNDENABLED"])
				if (WorldQuestTracker.db.profile.sound_enabled) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (1, options_on_click, "sound_enabled", not WorldQuestTracker.db.profile.sound_enabled)
				--
				GameCooltip:AddLine (L["S_MAPBAR_AUTOWORLDMAP"])
				if (WorldQuestTracker.db.profile.enable_doubletap) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (1, options_on_click, "enable_doubletap", not WorldQuestTracker.db.profile.enable_doubletap)
				--
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_STATUSBARANCHOR"])
				if (WorldQuestTracker.db.profile.bar_anchor == "top") then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (1, options_on_click, "bar_anchor", WorldQuestTracker.db.profile.bar_anchor == "bottom" and "top" or "bottom")
				--

				GameCooltip:AddLine ("$div")
				--
				
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_ARROWSPEED"])
				GameCooltip:AddIcon ([[Interface\AddOns\WorldQuestTracker\media\ArrowFrozen]], 1, 1, IconSize, IconSize, .15, .8, .15, .80)
				
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_ARROWSPEED_REALTIME"], "", 2)
				GameCooltip:AddMenu (2, options_on_click, "arrow_update_speed", 0.016)
				if (WorldQuestTracker.db.profile.arrow_update_frequence < 0.017) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_ARROWSPEED_HIGH"], "", 2)
				GameCooltip:AddMenu (2, options_on_click, "arrow_update_speed", 0.03)
				if (WorldQuestTracker.db.profile.arrow_update_frequence < 0.032 and WorldQuestTracker.db.profile.arrow_update_frequence > 0.029) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_ARROWSPEED_MEDIUM"], "", 2)
				GameCooltip:AddMenu (2, options_on_click, "arrow_update_speed", 0.075)
				if (WorldQuestTracker.db.profile.arrow_update_frequence < 0.076 and WorldQuestTracker.db.profile.arrow_update_frequence > 0.074) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_ARROWSPEED_SLOW"], "", 2)
				GameCooltip:AddMenu (2, options_on_click, "arrow_update_speed", 0.1)
				if (WorldQuestTracker.db.profile.arrow_update_frequence < 0.11 and WorldQuestTracker.db.profile.arrow_update_frequence > 0.099) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				
				--
				if (TomTom and IsAddOnLoaded ("TomTom")) then
					GameCooltip:AddLine ("$div")
					
					GameCooltip:AddLine ("TomTom")
					GameCooltip:AddIcon ([[Interface\AddOns\TomTom\Images\Arrow.blp]], 1, 1, 16, 14, 0, 56/512, 0, 43/512, "lightgreen")
					
					GameCooltip:AddLine (L["S_ENABLED"], "", 2)
					GameCooltip:AddMenu (2, options_on_click, "tomtom-enabled", not WorldQuestTracker.db.profile.tomtom.enabled)
					if (WorldQuestTracker.db.profile.tomtom.enabled) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					
					GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_TOMTOM_WPPERSISTENT"], "", 2)
					GameCooltip:AddMenu (2, options_on_click, "tomtom-persistent", not WorldQuestTracker.db.profile.tomtom.persistent)
					if (WorldQuestTracker.db.profile.tomtom.persistent) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
				end
				--
				
				GameCooltip:AddLine ("$div")
				
				--
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_REFRESH"])
				GameCooltip:AddMenu (1, options_on_click, "clear_quest_cache", true)
				GameCooltip:AddIcon ([[Interface\GLUES\CharacterSelect\CharacterUndelete]], 1, 1, IconSize, IconSize, .2, .8, .2, .8)
				--
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_UNTRACKQUESTS"])
				GameCooltip:AddMenu (1, options_on_click, "untrack_quests", true)
				GameCooltip:AddIcon ([[Interface\BUTTONS\UI-GROUPLOOT-PASS-HIGHLIGHT]], 1, 1, IconSize, IconSize)
				
				--
				
				--/dump InterfaceOptionsSocialPanelEnableTwitter.Logo:GetSize()
				
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_SHARE"])
				GameCooltip:AddIcon ("Interface\\FriendsFrame\\WowshareTextures.BLP", nil, 1, 14, 11, 122/256, 138/256, 167/256, 180/256)
				GameCooltip:AddMenu (1, options_on_click, "share_addon", true)
				--
				
				GameCooltip:SetOption ("IconBlendMode", "ADD")
				GameCooltip:SetOption ("SubFollowButton", true)

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
			
			--[[
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
			-]]
			--------------
			
			local ResourceFontTemplate = DF:GetTemplate ("font", "WQT_RESOURCES_AVAILABLE")	

			--> party members ~party
			
			local partyFrame = CreateFrame ("frame", nil, WorldQuestTracker.DoubleTapFrame)
			partyFrame:SetSize (80, 20)
			partyFrame:SetPoint ("left", filterButton, "right", 10, 0)

			local BuildPartyTooltipMenu = function (self)
				GameCooltip:Preset (2)
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("FixedWidth", 260)
				
				local name = UnitName ("player")
				local playersWith = {name}
				local playersWithout = {}
				local groupMembers = GetNumSubgroupMembers()
				
				for i = 1, groupMembers do
					local GUID = UnitGUID ("party" .. i)
					local name = UnitName ("party" .. i)
					
					if (WorldQuestTracker.PartyQuestsPool [GUID]) then
						tinsert (playersWith, name)
					else
						tinsert (playersWithout, name)
					end
				end
				
				--GameCooltip:AddLine ("With a little help from my friends", "", 1, {.9, .9, .9}, nil, 12)
				--GameCooltip:AddLine (" ")
				
				GameCooltip:AddLine (L["S_PARTY_PLAYERSWITH"], "", 1, {.7, .7, 1})
				for _, name in ipairs (playersWith) do
					GameCooltip:AddLine ("- " .. name, "", 1, {.95, .95, 1})
				end
				
				GameCooltip:AddLine (L["S_PARTY_PLAYERSWITHOUT"], "", 1, {1, .5, .5})
				for _, name in ipairs (playersWithout) do
					GameCooltip:AddLine ("- " .. name, "", 1, {1, .95, .95})
				end
				
				GameCooltip:AddLine (" ")
				
				GameCooltip:AddLine (L["S_PARTY_DESC1"], nil, 1, {.75, .75, .85})
				GameCooltip:AddIcon ([[Interface\AddOns\WorldQuestTracker\media\icon_party_sharedT]], 1, 1, 16, 16)
				
				GameCooltip:AddLine (L["S_PARTY_DESC2"], nil, 1, {.85, .75, .75})
				GameCooltip:AddIcon ([[Interface\AddOns\WorldQuestTracker\media\icon_party_shared_badT]], 1, 1, 16, 16)
			end
			
			partyFrame.CoolTip = {
				Type = "tooltip",
				BuildFunc = BuildPartyTooltipMenu, --> called when user mouse over the frame
				OnEnterFunc = function (self) 
					optionsButton.button_mouse_over = true
					--button_onenter (self)
					C_Timer.After (.05, CooltipOnTop_WhenFullScreen)
				end,
				OnLeaveFunc = function (self) 
					optionsButton.button_mouse_over = false
					--button_onleave (self)
				end,
				FixedValue = "none",
				ShowSpeed = 0.05,
				Options = function()
				end
			}	
			GameCooltip:CoolTipInject (partyFrame)
			
			local partyStarIcon = partyFrame:CreateTexture (nil, "overlay")
			partyStarIcon:SetPoint ("left", filterButton, "right", 10, 0)
			partyStarIcon:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_party_sharedT]])
			partyStarIcon:SetSize (48*.3, 48*.3)
			partyStarIcon:SetAlpha (.8)
			partyStarIcon:SetDesaturated (true)
			WorldQuestTracker.PartyStarIcon = partyStarIcon
			
			local shadow = partyFrame:CreateTexture (nil, "background")
			shadow:SetPoint ("left", partyStarIcon, "left", -6, 0)
			shadow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
			shadow:SetSize (88, 12)
			shadow:SetAlpha (.3)
			
			--local partyText = DF:CreateLabel (partyFrame, L["S_PARTY"] .. ":", ResourceFontTemplate)
			local partyText = DF:CreateLabel (partyFrame, "" .. "", ResourceFontTemplate)
			partyText:SetPoint ("left", partyStarIcon, "right", 2, 0)
			
			local partyTextAmount = DF:CreateLabel (partyFrame, "0", ResourceFontTemplate)
			partyTextAmount:SetPoint ("left", partyText, "right", 2, 0)
			WorldQuestTracker.PartyAmountText = partyTextAmount
			
			if (WorldQuestTracker.UpdatePartySharedQuests) then
				WorldQuestTracker.UpdatePartySharedQuests (true)
			end
			
			
			
			-----------
			--recursos disponíveis
			local xOffset = 35
			
			-- ~resources ~recursos
			local resource_GoldIcon = DF:CreateImage (WorldQuestTracker.DoubleTapFrame, [[Interface\AddOns\WorldQuestTracker\media\icons_resourcesT]], 16, 16, "overlay", {64/128, 96/128, 0, .25})
			resource_GoldIcon:SetDrawLayer ("overlay", 7)
			resource_GoldIcon:SetAlpha (.78)
			local resource_GoldText = DF:CreateLabel (WorldQuestTracker.DoubleTapFrame, "", ResourceFontTemplate)
			
			
			local resource_ResourcesIcon = DF:CreateImage (WorldQuestTracker.DoubleTapFrame, [[Interface\AddOns\WorldQuestTracker\media\icons_resourcesT]], 16, 16, "overlay", {0, 32/128, 0, .25})
			resource_ResourcesIcon:SetDrawLayer ("overlay", 7)
			resource_ResourcesIcon:SetAlpha (.78)
			local resource_ResourcesText = DF:CreateLabel (WorldQuestTracker.DoubleTapFrame, "", ResourceFontTemplate)
			
			
			local resource_APowerIcon = DF:CreateImage (WorldQuestTracker.DoubleTapFrame, [[Interface\AddOns\WorldQuestTracker\media\icons_resourcesT]], 16, 16, "overlay", {32/128, 64/128, 0, .25})
			resource_APowerIcon:SetDrawLayer ("overlay", 7)
			resource_APowerIcon:SetAlpha (.78)
			local resource_APowerText = DF:CreateLabel (WorldQuestTracker.DoubleTapFrame, "", ResourceFontTemplate)
			
			
			--ordem das anchors - cada widget ocupa 55 pixels: 0 55 110
			--[=[
			resource_GoldIcon:SetPoint ("left", filterButton, "right", 100 + xOffset, 0)
			resource_APowerIcon:SetPoint ("left", filterButton, "right", 210 + xOffset, 0)
			resource_ResourcesIcon:SetPoint ("left", filterButton, "right", 155 + xOffset, 0)
			
			resource_APowerText:SetPoint ("left", resource_APowerIcon, "right", 2, 0)
			resource_ResourcesText:SetPoint ("left", resource_ResourcesIcon, "right", 2, 0)
			resource_GoldText:SetPoint ("left", resource_GoldIcon, "right", 2, 0)
			--]=]
			
			partyStarIcon:ClearAllPoints()
			partyTextAmount:ClearAllPoints()
			partyTextAmount:SetPoint ("bottomright", WorldQuestButton, "bottomleft", -10, 2)
			partyStarIcon:SetPoint ("right", partyTextAmount.widget, "left", -2, 0)
			shadow:SetSize (40, 12)
			partyFrame:ClearAllPoints()
			partyFrame:SetPoint ("left", partyStarIcon, "left", -2, 0)
			partyFrame:SetWidth (38)
			
			--resource_APowerText:SetPoint ("bottomright", WorldQuestButton, "bottomleft", -10, 2)
			resource_APowerText:SetPoint ("right", partyStarIcon, "left", -10, 0)
			resource_APowerIcon:SetPoint ("right", resource_APowerText, "left", -2, 0)
			resource_ResourcesText:SetPoint ("right", resource_APowerIcon, "left", -10, 0)
			resource_ResourcesIcon:SetPoint ("right", resource_ResourcesText, "left", -2, 0)
			resource_GoldText:SetPoint ("right", resource_ResourcesIcon, "left", -10, 0)
			resource_GoldIcon:SetPoint ("right", resource_GoldText, "left", -2, 0)
			
			--[=[
			partyStarIcon:ClearAllPoints()
			partyTextAmount:ClearAllPoints()
			partyTextAmount:SetPoint ("right", resource_GoldIcon.widget, "left", -10, 0)
			partyStarIcon:SetPoint ("right", partyTextAmount.widget, "left", -2, 0)
			shadow:SetSize (40, 12)
			--]=]
			--------

			WorldQuestTracker.WorldMap_GoldIndicator = resource_GoldText
			WorldQuestTracker.WorldMap_ResourceIndicator = resource_ResourcesText
			WorldQuestTracker.WorldMap_APowerIndicator = resource_APowerText

			-- ~trackall
			local TrackAllFromType = function (self)
				local mapID
				if (mapType == "zone") then
					mapID = GetCurrentMapAreaID()
				end
			
				local mapType = WorldQuestTrackerAddon.GetCurrentZoneType()
				if (mapType == "zone") then
					local qType = self.QuestType
					if (qType == "gold") then
						qType = QUESTTYPE_GOLD
					elseif (qType == "resource") then
						qType = QUESTTYPE_RESOURCE
					elseif (qType == "apower") then
						qType = QUESTTYPE_ARTIFACTPOWER
					end

					local widgets = WorldQuestTracker.Cache_ShownWidgetsOnZoneMap
					for _, widget in ipairs (widgets) do
						if (widget.QuestType == qType) then
							WorldQuestTracker.AddQuestToTracker (widget)
							if (widget.onEndTrackAnimation:IsPlaying()) then
								widget.onEndTrackAnimation:Stop()
							end
							widget.onStartTrackAnimation:Play()
						end
					end

					if (WorldQuestTracker.db.profile.sound_enabled) then
						if (math.random (2) == 1) then
							PlaySoundFile ("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker_mass1.mp3")
						else
							PlaySoundFile ("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker_mass2.mp3")
						end
					end
					WorldQuestTracker.UpdateZoneWidgets()
				end
				
				if (mapType == "world") then
					local questType = self.QuestType
					local questsAvailable = WorldQuestTracker.Cache_ShownQuestOnWorldMap [questType]

					if (questsAvailable) then
						for i = 1, #questsAvailable do
							local questID = questsAvailable [i]
							--> track this quest
							local widget = WorldQuestTracker.GetWorldWidgetForQuest (questID)
							
							if (widget) then
								WorldQuestTracker.AddQuestToTracker (widget)
								if (widget.onEndTrackAnimation:IsPlaying()) then
									widget.onEndTrackAnimation:Stop()
								end
								widget.onStartTrackAnimation:Play()
							end
						end
						
						if (WorldQuestTracker.db.profile.sound_enabled) then
							if (math.random (2) == 1) then
								PlaySoundFile ("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker_mass1.mp3")
							else
								PlaySoundFile ("Interface\\AddOns\\WorldQuestTracker\\media\\quest_added_to_tracker_mass2.mp3")
							end
						end
						WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true, false)
					end
				end
			end
			
			local resource_GoldFrame = CreateFrame ("button", nil, WorldQuestTracker.DoubleTapFrame)
			resource_GoldFrame.QuestType = WQT_QUESTTYPE_GOLD
			resource_GoldFrame:SetScript ("OnClick", TrackAllFromType)
			
			local resource_ResourcesFrame = CreateFrame ("button", nil, WorldQuestTracker.DoubleTapFrame)
			resource_ResourcesFrame.QuestType = WQT_QUESTTYPE_RESOURCE
			resource_ResourcesFrame:SetScript ("OnClick", TrackAllFromType)
			
			local resource_APowerFrame = CreateFrame ("button", nil, WorldQuestTracker.DoubleTapFrame)
			resource_APowerFrame.QuestType = WQT_QUESTTYPE_APOWER
			resource_APowerFrame:SetScript ("OnClick", TrackAllFromType)
			
			local shadow = WorldQuestTracker.DoubleTapFrame:CreateTexture (nil, "background")
			shadow:SetPoint ("left", resource_GoldIcon.widget, "left", 2, 0)
			shadow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
			shadow:SetSize (58, 10)
			shadow:SetAlpha (.3)
			local shadow = WorldQuestTracker.DoubleTapFrame:CreateTexture (nil, "background")
			shadow:SetPoint ("left", resource_ResourcesIcon.widget, "left", 2, 0)
			shadow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
			shadow:SetSize (58, 10)
			shadow:SetAlpha (.3)
			local shadow = WorldQuestTracker.DoubleTapFrame:CreateTexture (nil, "background")
			shadow:SetPoint ("left", resource_APowerIcon.widget, "left", 2, 0)
			shadow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
			shadow:SetSize (58, 10)
			shadow:SetAlpha (.3)
			
			resource_GoldFrame:SetSize (55, 20)
			resource_ResourcesFrame:SetSize (55, 20)
			resource_APowerFrame:SetSize (55, 20)
			
			resource_GoldFrame:SetPoint ("left", resource_GoldIcon.widget, "left", -2, 0)
			resource_ResourcesFrame:SetPoint ("left", resource_ResourcesIcon.widget, "left", -2, 0)
			resource_APowerFrame:SetPoint ("left", resource_APowerIcon.widget, "left", -2, 0)
			
			resource_GoldFrame:SetScript ("OnEnter", function (self)
				resource_GoldText.textcolor = "WQT_ORANGE_ON_ENTER"

				GameCooltip:Preset (2)
				GameCooltip:SetType ("tooltip")
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("FixedWidth", 220)
				
				GameCooltip:AddLine (L["S_QUESTTYPE_GOLD"])
				GameCooltip:AddIcon (WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_GOLD].icon, 1, 1, 20, 20)
				
				GameCooltip:AddLine ("", "", 1, "green", _, 10)
				GameCooltip:AddLine (format (L["S_MAPBAR_RESOURCES_TOOLTIP_TRACKALL"], L["S_QUESTTYPE_GOLD"]), "", 1, "green", _, 10)
				
				GameCooltip:SetOwner (self)
				GameCooltip:Show(self)
				CooltipOnTop_WhenFullScreen()
			end)
			
			resource_ResourcesFrame:SetScript ("OnEnter", function (self)
				resource_ResourcesText.textcolor = "WQT_ORANGE_ON_ENTER"
				
				GameCooltip:Preset (2)
				GameCooltip:SetType ("tooltip")
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("FixedWidth", 220)
				
				GameCooltip:AddLine (L["S_QUESTTYPE_RESOURCE"])
				GameCooltip:AddIcon (WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_RESOURCE].icon, 1, 1, 20, 20)
				
				GameCooltip:AddLine ("", "", 1, "green", _, 10)
				GameCooltip:AddLine (format (L["S_MAPBAR_RESOURCES_TOOLTIP_TRACKALL"], L["S_QUESTTYPE_RESOURCE"]), "", 1, "green", _, 10)
				
				GameCooltip:SetOwner (self)
				GameCooltip:Show(self)
				CooltipOnTop_WhenFullScreen()
			end)
			
			resource_APowerFrame:SetScript ("OnEnter", function (self)
				resource_APowerText.textcolor = "WQT_ORANGE_ON_ENTER"
				
				GameCooltip:Preset (2)
				GameCooltip:SetType ("tooltipbar")
				GameCooltip:SetOption ("TextSize", 10)
				GameCooltip:SetOption ("FixedWidth", 220)
				GameCooltip:SetOption ("StatusBarTexture", [[Interface\RaidFrame\Raid-Bar-Hp-Fill]])
				
				GameCooltip:AddLine (L["S_QUESTTYPE_ARTIFACTPOWER"])
				GameCooltip:AddIcon (WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_APOWER].icon, 1, 1, 20, 20)
				
				local itemID, altItemID, name, icon, totalXP, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetEquippedArtifactInfo()
				if (itemID and WorldQuestTracker.WorldMap_APowerIndicator.Amount) then
					local numPointsAvailableToSpend, xp, xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP (pointsSpent, totalXP)
					local Available_APower = WorldQuestTracker.WorldMap_APowerIndicator.Amount / xpForNextPoint * 100
					local diff = xpForNextPoint - xp
					local Diff_APower = WorldQuestTracker.WorldMap_APowerIndicator.Amount / diff * 100
					GameCooltip:AddLine (L["S_APOWER_AVAILABLE"], L["S_APOWER_NEXTLEVEL"], 1, 1, 1, 1, 1, 1, 1, 1, 1, nil, nil, "OUTLINE")
					
					--GameCooltip:AddStatusBar (math.min (Available_APower, 100), 1, 0.9019, 0.7999, 0.5999, .85, true, {value = 100, color = {.3, .3, .3, 1}, specialSpark = false, texture = [[Interface\WorldStateFrame\WORLDSTATEFINALSCORE-HIGHLIGHT]]})
					GameCooltip:AddStatusBar (math.min (Diff_APower, 100), 1, 0.9019, 0.7999, 0.5999, .85, true, {value = 100, color = {.3, .3, .3, 1}, specialSpark = false, texture = [[Interface\WorldStateFrame\WORLDSTATEFINALSCORE-HIGHLIGHT]]})
					--GameCooltip:AddLine (comma_value (WorldQuestTracker.WorldMap_APowerIndicator.Amount), comma_value (xpForNextPoint), 1, "white", "white")
					GameCooltip:AddLine (comma_value (WorldQuestTracker.WorldMap_APowerIndicator.Amount), comma_value (diff), 1, "white", "white")
					--statusbarValue, frame, ColorR, ColorG, ColorB, ColorA, statusbarGlow, backgroundBar, barTexture
					--print (xp, xpForNextPoint)
				end
				
				local nameLoc, timeleftString, timeLeft, elapsedTime = WorldQuestTracker:GetNextResearchNoteTime()
				if (timeleftString) then
					GameCooltip:AddLine (nameLoc, timeleftString, 1, "white", _, 10)
					GameCooltip:AddIcon (237446, 1, 1, 18, 18, 5/64, 59/64, 5/64, 59/64)
				end
				
				local str = "|TInterface\\AddOns\\WorldQuestTracker\\media\\icon_artifactpower_blueT:0|t"
				GameCooltip:AddLine (format (L["S_APOWER_DOWNVALUE"], str), "", 1, "white", _, 10)
				
				GameCooltip:AddLine ("", "", 1, "green", _, 10)
				GameCooltip:AddLine (format (L["S_MAPBAR_RESOURCES_TOOLTIP_TRACKALL"], L["S_QUESTTYPE_ARTIFACTPOWER"]), "", 1, "green", _, 10)
				GameCooltip:SetOption ("LeftTextHeight", 22)
				GameCooltip:SetOwner (self)
				GameCooltip:Show(self)
				
				CooltipOnTop_WhenFullScreen()
				
--WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_GOLD].icon
--WQT_QUEST_NAMES_AND_ICONS [WQT_QUESTTYPE_RESOURCE].icon
			end)
			
			local resource_IconsOnLeave = function (self)
				GameCooltip:Hide()
				resource_GoldText.textcolor = "WQT_ORANGE_RESOURCES_AVAILABLE"
				resource_ResourcesText.textcolor = "WQT_ORANGE_RESOURCES_AVAILABLE"
				resource_APowerText.textcolor = "WQT_ORANGE_RESOURCES_AVAILABLE"
			end
			
			resource_GoldFrame:SetScript ("OnLeave", resource_IconsOnLeave)
			resource_ResourcesFrame:SetScript ("OnLeave", resource_IconsOnLeave)
			resource_APowerFrame:SetScript ("OnLeave", resource_IconsOnLeave)
			
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
			--print ("eh pra hidar...")
		end

		-- ~tutorial
		--WorldQuestTracker.db.profile.GotTutorial = nil
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
				tutorialFrame:SetSize (160, 350)
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
				
				local partyStarBlip = tutorialFrame:CreateTexture (nil, "overlay", 2)
				partyStarBlip:SetPoint ("topleft", texture, "topleft", -18, 20)
				partyStarBlip:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_party_sharedT]])
				partyStarBlip:SetSize (48*.8, 48*.8)
				--partyStarBlip:SetDrawLayer ("background", 3)
				
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
				
				--indicator de party
				local partyStar = tutorialFrame:CreateTexture (nil, "background")
				partyStar:SetPoint ("topright", texture, "topright", 51, -236)
				partyStar:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_party_sharedT]])
				partyStar:SetSize (48*.5, 48*.5)
				partyStar:SetDrawLayer ("background", 3)
				
				local partyStar2 = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
				partyStar2:SetPoint ("left", partyStar, "right", 6, 0)
				DF:SetFontSize (partyStar2, 12)
				partyStar2:SetText ("A blue star indicates all party members have this quest as well (if they have world quest tracker installed).")
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
--> zone summary

local ZoneSumaryFrame = CreateFrame ("frame", "WorldQuestTrackerZoneSummaryFrame", worldFramePOIs)
ZoneSumaryFrame:SetPoint ("bottomleft", WorldMapScrollFrame, "bottomleft", 0, 19)
ZoneSumaryFrame:SetSize (1, 1)

ZoneSumaryFrame.WidgetHeight = 18
ZoneSumaryFrame.WidgetWidth = 130
ZoneSumaryFrame.WidgetBackdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16}
ZoneSumaryFrame.WidgetBackdropColor = {0, 0, 0, 0}
ZoneSumaryFrame.IconSize = 18
ZoneSumaryFrame.IconTextureSize = 14
ZoneSumaryFrame.IconTimeSize = 18

WorldQuestTracker.ZoneSumaryWidgets = {}

ZoneSumaryFrame.Header = CreateFrame ("frame", "WorldQuestTrackerSummaryHeader", ZoneSumaryFrame, "ObjectiveTrackerHeaderTemplate")
ZoneSumaryFrame.Header.Title = ZoneSumaryFrame.Header:CreateFontString (nil, "overlay", "GameFontNormal")
ZoneSumaryFrame.Header.Title:SetText ("Quest Summary")
ZoneSumaryFrame.Header.Desc = ZoneSumaryFrame.Header:CreateFontString (nil, "overlay", "GameFontNormal")
ZoneSumaryFrame.Header.Desc:SetText ("Click to Add to Tracker")
ZoneSumaryFrame.Header.Desc:SetAlpha (.7)
DF:SetFontSize (ZoneSumaryFrame.Header.Title, 10)
DF:SetFontSize (ZoneSumaryFrame.Header.Desc, 8)
ZoneSumaryFrame.Header.Title:SetPoint ("topleft", ZoneSumaryFrame.Header, "topleft", -9, -2)
ZoneSumaryFrame.Header.Desc:SetPoint ("bottomleft", ZoneSumaryFrame.Header, "bottomleft", -9, 4)
ZoneSumaryFrame.Header.Background:SetWidth (150)
ZoneSumaryFrame.Header.Background:SetHeight (ZoneSumaryFrame.Header.Background:GetHeight()*0.45)
ZoneSumaryFrame.Header.Background:SetTexCoord (0, 1, 0, .45)
ZoneSumaryFrame.Header:Hide()
ZoneSumaryFrame.Header.BlackBackground = ZoneSumaryFrame.Header:CreateTexture (nil, "background")
ZoneSumaryFrame.Header.BlackBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_summaryzoneT]])
ZoneSumaryFrame.Header.BlackBackground:SetAlpha (.8)
ZoneSumaryFrame.Header.BlackBackground:SetSize (150, ZoneSumaryFrame.Header.Background:GetHeight())
ZoneSumaryFrame.Header.BlackBackground:SetPoint ("topleft", ZoneSumaryFrame.Header.Background, "topleft", 8, -14)
ZoneSumaryFrame.Header.BlackBackground:SetPoint ("bottomright", ZoneSumaryFrame.Header.Background, "bottomright", 0, 0)

local GetOrCreateZoneSummaryWidget = function (index)

	local widget = WorldQuestTracker.ZoneSumaryWidgets [index]
	if (widget) then
		return widget
	end
	
	local button = CreateFrame ("button", "WorldQuestTrackerZoneSummaryFrame_Widget" .. index, ZoneSumaryFrame)
	button:SetPoint ("bottomleft", ZoneSumaryFrame, "bottomleft", 0, ((index-1)* (ZoneSumaryFrame.WidgetHeight + 1)) -2)
	button:SetSize (ZoneSumaryFrame.WidgetWidth, ZoneSumaryFrame.WidgetHeight)
	button:SetFrameLevel (worldFramePOIs:GetFrameLevel()+1)
	--button:SetBackdrop (ZoneSumaryFrame.WidgetBackdrop)
	--button:SetBackdropColor (unpack (ZoneSumaryFrame.WidgetBackdropColor))
	
	local buttonIcon = WorldQuestTracker.CreateZoneWidget (index, "WorldQuestTrackerZoneSummaryFrame_WidgetIcon", button)
	buttonIcon:SetPoint ("left", button, "left", 2, 0)
	buttonIcon:SetSize (ZoneSumaryFrame.IconSize, ZoneSumaryFrame.IconSize)
	--buttonIcon:SetFrameStrata ("DIALOG")
	buttonIcon:SetFrameLevel (worldFramePOIs:GetFrameLevel()+2)
	button.Icon = buttonIcon
	
	local art = button:CreateTexture (nil, "border")
	art:SetAllPoints()
	art:SetTexture ([[Interface\ARCHEOLOGY\ArchaeologyParts]])
	art:SetTexCoord (73/512, 320/512, 15/256, 65/256)
	art:SetAlpha (1)
	
	local art2 = button:CreateTexture (nil, "artwork")
	art2:SetAllPoints()
	art2:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_summaryzoneT]])
	art2:SetAlpha (.4)
	button.BlackBackground = art2
	
	local highlight = button:CreateTexture (nil, "highlight")
	highlight:SetAllPoints()
	highlight:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_pixel_whiteT.blp]])
	highlight:SetAlpha (.2)
	button.Highlight = highlight
	
	--border lines
	local lineUp = button:CreateTexture (nil, "overlay")
	lineUp:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_pixel_whiteT.blp]])
	lineUp:SetPoint ("bottomleft", button, "topleft", 0, -1)
	lineUp:SetPoint ("bottomright", button, "topright", 0, -1)
	lineUp:SetHeight (1)
	lineUp:SetVertexColor (0, 0, 0)
	lineUp:SetAlpha (.3)
	
	--border lines
	local lineDown = button:CreateTexture (nil, "overlay")
	lineDown:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_pixel_whiteT.blp]])
	lineDown:SetPoint ("topleft", button, "bottomleft", 0, 1)
	lineDown:SetPoint ("topright", button, "bottomright", 0, 1)
	lineDown:SetHeight (1)
	lineDown:SetVertexColor (0, 0, 0)
	lineDown:SetAlpha (.3)
	button.LineDown = lineDown
	button.LineUp = lineUp
	--

	local x = 30
	buttonIcon.timeBlipRed:ClearAllPoints()
	buttonIcon.timeBlipRed:SetPoint ("left", buttonIcon, "right", x, 0)
	buttonIcon.timeBlipRed:SetSize (ZoneSumaryFrame.IconTimeSize, ZoneSumaryFrame.IconTimeSize)
	buttonIcon.timeBlipRed:SetAlpha (1)
	buttonIcon.timeBlipOrange:ClearAllPoints()
	buttonIcon.timeBlipOrange:SetPoint ("left", buttonIcon, "right", x, 0)
	buttonIcon.timeBlipOrange:SetSize (ZoneSumaryFrame.IconTimeSize, ZoneSumaryFrame.IconTimeSize)
	buttonIcon.timeBlipOrange:SetAlpha (.8)
	buttonIcon.timeBlipYellow:ClearAllPoints()
	buttonIcon.timeBlipYellow:SetPoint ("left", buttonIcon, "right", x, 0)
	buttonIcon.timeBlipYellow:SetSize (ZoneSumaryFrame.IconTimeSize, ZoneSumaryFrame.IconTimeSize)
	buttonIcon.timeBlipYellow:SetAlpha (.6)
	buttonIcon.timeBlipGreen:ClearAllPoints()
	buttonIcon.timeBlipGreen:SetPoint ("left", buttonIcon, "right", x, 0)
	buttonIcon.timeBlipGreen:SetSize (ZoneSumaryFrame.IconTimeSize, ZoneSumaryFrame.IconTimeSize)
	buttonIcon.timeBlipGreen:SetAlpha (.3)
	--
	buttonIcon.criteriaIndicator:ClearAllPoints()
	buttonIcon.criteriaIndicator:SetPoint ("left", buttonIcon, "right", 50, 0)
	buttonIcon.criteriaIndicator:SetSize (23*.4, 37*.4)
	--
	button.Text = DF:CreateLabel (button)
	button.Text:SetPoint ("left", buttonIcon, "right", 3, 0)
	DF:SetFontSize (button.Text, 10)
	DF:SetFontColor (button.Text, "orange")
	--
	
	button.OnTracker = button:CreateTexture (nil, "overlay")
	button.OnTracker:SetPoint ("left", buttonIcon, "right", 65, 0)
	button.OnTracker:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\ArrowFrozen]])
	button.OnTracker:SetAlpha (.75)
	button.OnTracker:SetSize (16, 16)
	button.OnTracker:SetTexCoord (.15, .8, .15, .80)
	
	--
	--animations
	local on_enter_animation = DF:CreateAnimationHub (button, nil, function()
		--button:SetScale (1.1, 1.1)
	end)
	on_enter_animation.Step1 = DF:CreateAnimation (on_enter_animation, "scale", 1, 0.05, 1, 1, 1.05, 1.05)
	on_enter_animation.Step2 = DF:CreateAnimation (on_enter_animation, "scale", 2, 0.05, 1.05, 1.05, 1.0, 1.0)
	button.OnEnterAnimation = on_enter_animation
	
	local on_leave_animation = DF:CreateAnimationHub (button, nil, function()
		--button:SetScale (1.0, 1.0)
	end)
	on_leave_animation.Step1 = DF:CreateAnimation (on_leave_animation, "scale", 1, 0.1, 1.1, 1.1, 1, 1)
	button.OnLeaveAnimation = on_leave_animation
	
	local mouseoverHighlight = WorldMapPOIFrame:CreateTexture (nil, "overlay")
	mouseoverHighlight:SetTexture ([[Interface\Worldmap\QuestPoiGlow]])
	mouseoverHighlight:SetSize (80, 80)
	mouseoverHighlight:SetBlendMode ("ADD")
	
	button:SetScript ("OnClick", function (self)
		--WorldQuestTracker.AddQuestToTracker (self.Icon)
		for i = 1, #WorldQuestTracker.Cache_ShownWidgetsOnZoneMap do
			if (WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i].questID == self.Icon.questID) then
				WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i]:GetScript ("OnClick")(WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i])
				break
			end
		end
	end)
	
	button:SetScript ("OnEnter", function (self)
		--print ("enter", self:GetScale())
		--self.OnEnterAnimation.Step1:SetFromScale (self.OnEnterAnimation.Step1:GetScale())
		--self.OnLeaveAnimation:Stop()
		--self.OnEnterAnimation:Play()
		--WorldQuestTracker.HaveZoneSummaryHover = self._Twin
		WorldQuestTracker.HaveZoneSummaryHover = self
		self.Icon:GetScript ("OnEnter")(self.Icon)
		WorldMapTooltip:SetPoint ("bottomleft", WorldQuestTracker.HaveZoneSummaryHover, "bottomright", 2, 0)
		
		--GameCooltip:Hide()
		--procura o icone da quest no mapa e indica ele
		for i = 1, #WorldQuestTracker.Cache_ShownWidgetsOnZoneMap do
			if (WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i].questID == self.Icon.questID) then
				mouseoverHighlight:SetPoint ("center", WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i], "center")
				mouseoverHighlight:Show()
				break
			end
		end

	end)
	button:SetScript ("OnLeave", function (self)
		--print ("enter", self:GetScale())
		--self.OnLeaveAnimation.Step1:SetFromScale (self.OnLeaveAnimation.Step1:GetScale())
		--self.OnEnterAnimation:Stop()
		--self.OnLeaveAnimation:Play()
		self.Icon:GetScript ("OnLeave")(self.Icon)
		WorldQuestTracker.HaveZoneSummaryHover = nil
		mouseoverHighlight:Hide()
	end)
	
	WorldQuestTracker.ZoneSumaryWidgets [index] = button
	return button
end

function WorldQuestTracker.ClearZoneSummaryButtons()
	for _, button in ipairs (WorldQuestTracker.ZoneSumaryWidgets) do
		button:Hide()
	end
	WorldQuestTracker.QuestSummaryShown = true
	ZoneSumaryFrame.Header:Hide()
end

function WorldQuestTracker.SetupZoneSummaryButton (summaryWidget, zoneWidget)
	local Icon = summaryWidget.Icon
	
	Icon.mapID = zoneWidget.mapID
	Icon.questID = zoneWidget.questID
	Icon.numObjectives = zoneWidget.numObjectives
	
	WorldQuestTracker.SetupWorldQuestButton (Icon, zoneWidget.worldQuestType, zoneWidget.rarity, zoneWidget.isElite, zoneWidget.tradeskillLineIndex, zoneWidget.inProgress, zoneWidget.selected, zoneWidget.isCriteria, zoneWidget.isSpellTarget)
	
	--Icon.Shadow:Hide()
	Icon.blackGradient:Hide()
	Icon.rareSerpent:Hide()
	Icon.rareGlow:Hide()
	Icon.bgFlag:Hide()
	Icon.IsTrackingRareGlow:Hide()
	Icon.flagCriteriaMatchGlow:Hide()
	Icon.flagText:Hide()
	
	Icon.IsTrackingGlow:SetSize (30, 30)
	Icon.IsTrackingGlow:Hide()
	Icon.criteriaIndicatorGlow:Hide()
	
	Icon.Texture:SetSize (ZoneSumaryFrame.IconTextureSize, ZoneSumaryFrame.IconTextureSize)
	Icon.Texture:SetAlpha (.75)
	Icon.circleBorder:SetAlpha (.75)
	
	if (zoneWidget.rarity == LE_WORLD_QUEST_QUALITY_COMMON) then
		summaryWidget.LineUp:SetAlpha (.3)
		summaryWidget.LineDown:SetAlpha (.3)
		summaryWidget.LineUp:SetVertexColor (0, 0, 0)
		summaryWidget.LineDown:SetVertexColor (0, 0, 0)
	elseif (zoneWidget.rarity == LE_WORLD_QUEST_QUALITY_RARE) then
		local color = BAG_ITEM_QUALITY_COLORS [LE_ITEM_QUALITY_RARE]
		summaryWidget.LineUp:SetAlpha (.8)
		summaryWidget.LineDown:SetAlpha (.8)
		summaryWidget.LineUp:SetVertexColor (color.r, color.g, color.b)
		summaryWidget.LineDown:SetVertexColor (color.r, color.g, color.b)
	elseif (zoneWidget.rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
		local color = BAG_ITEM_QUALITY_COLORS [LE_ITEM_QUALITY_EPIC]
		summaryWidget.LineUp:SetAlpha (.8)
		summaryWidget.LineDown:SetAlpha (.8)
		summaryWidget.LineUp:SetVertexColor (color.r, color.g, color.b)
		summaryWidget.LineDown:SetVertexColor (color.r, color.g, color.b)
	end
	
	Icon.flagText:SetText (zoneWidget.IconText)
	summaryWidget.Text:SetText (zoneWidget.IconText)

	summaryWidget.BlackBackground:SetAlpha (.4)
	summaryWidget.Highlight:SetAlpha (.2)
	
	summaryWidget:Show()
end

function WorldQuestTracker.CanShowZoneSummaryFrame()
	return WorldQuestTracker.db.profile.use_quest_summary and is_broken_isles_map [GetCurrentMapAreaID()] and not WorldMapFrame_InWindowedMode()
end

function WorldQuestTracker.UpdateZoneSummaryFrame()
	if (not WorldQuestTracker.CanShowZoneSummaryFrame()) then
		if (WorldQuestTracker.QuestSummaryShown) then
			WorldQuestTracker.ClearZoneSummaryButtons()
		end
		return
	end
	
	local index = 1
	WorldQuestTracker.ClearZoneSummaryButtons()
	
	table.sort (WorldQuestTracker.Cache_ShownWidgetsOnZoneMap, function (t1, t2)
		return t1.Order < t2.Order
	end)
	
	local LastWidget
	for i = 1, #WorldQuestTracker.Cache_ShownWidgetsOnZoneMap do
		local zoneWidget = WorldQuestTracker.Cache_ShownWidgetsOnZoneMap [i]
		local summaryWidget = GetOrCreateZoneSummaryWidget (index)
		summaryWidget._Twin = zoneWidget
		WorldQuestTracker.SetupZoneSummaryButton (summaryWidget, zoneWidget)
		LastWidget = summaryWidget
		
		if (WorldQuestTracker.IsQuestBeingTracked (zoneWidget.questID)) then
			summaryWidget.OnTracker:Show()
		else
			summaryWidget.OnTracker:Hide()
		end
		
		index = index + 1
	end
	
	if (LastWidget) then
		ZoneSumaryFrame.Header:Show()
		ZoneSumaryFrame.Header:SetPoint ("bottomleft", LastWidget, "topleft", 20, 0)
	end
	
	WorldQuestTracker.QuestSummaryShown = true
end

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

--tomtom track options
--persistent
--minimap
--world
--crazy
--cleardistance
--arrivaldistance

function WorldQuestTracker.AddQuestTomTom (questID, mapID, noRemove)
	local x, y = C_TaskQuest.GetQuestLocation (questID, mapID)
	local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
	local alreadyExists = TomTom:WaypointMFExists (mapID, nil, x, y, title)
	
	if (alreadyExists and WorldQuestTracker.db.profile.tomtom.uids [questID]) then
		if (noRemove) then
			return
		end
		TomTom:RemoveWaypoint (WorldQuestTracker.db.profile.tomtom.uids [questID])
		WorldQuestTracker.db.profile.tomtom.uids [questID] = nil
		return
	end
	
	if (not alreadyExists) then
		local uid = TomTom:AddMFWaypoint (mapID, nil, x, y, {title=title, persistent=WorldQuestTracker.db.profile.tomtom.persistent})
		WorldQuestTracker.db.profile.tomtom.uids [questID] = uid
	end
	return
end

--adiciona uma quest ao tracker
function WorldQuestTracker.AddQuestToTracker (self)
	local questID = self.questID
	
	if (not HaveQuestData (questID)) then
		WorldQuestTracker:Msg (L["S_ERROR_NOTLOADEDYET"])
		return
	end
	
	if (WorldQuestTracker.db.profile.tomtom.enabled and TomTom and IsAddOnLoaded ("TomTom")) then
		return WorldQuestTracker.AddQuestTomTom (self.questID, self.mapID)
	end
	
	if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
		return
	end
	
	local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
	if (timeLeft and timeLeft > 0) then
		local mapID = self.mapID
		local iconTexture = self.IconTexture
		local iconText = self.IconText
		local questType = self.QuestType
		local numObjectives = self.numObjectives
		
--		if (type (iconText) == "string") then --no good
--			iconText = iconText:gsub ("|c%x?%x?%x?%x?%x?%x?%x?%x?", "")
--			iconText = iconText:gsub ("|r", "")
--			iconText = tonumber (iconText)
--		end
--removing this, the reward amount can now be a number or a string, we cannot check for amount without checking first if is a number (on tracker only)
		
		if (iconTexture) then
			tinsert (WorldQuestTracker.QuestTrackList, {
				questID = questID, 
				mapID = mapID, 
				mapIDSynthetic = WorldQuestTracker.db.profile.syntheticMapIdList [mapID] or 0,
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

--remove todas as quests do tracker
function WorldQuestTracker.RemoveAllQuestsFromTracker()
	for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
		local quest = WorldQuestTracker.QuestTrackList [i]
		local questID = quest.questID
		local widget = WorldQuestTracker.GetWorldWidgetForQuest (questID)
		if (widget) then
			if (widget.onStartTrackAnimation:IsPlaying()) then
				widget.onStartTrackAnimation:Stop()
			end
			widget.onEndTrackAnimation:Play()
		end
		--remove da tabela
		tremove (WorldQuestTracker.QuestTrackList, i)
	end
	
	WorldQuestTracker.RefreshTrackerWidgets()
	
	if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
	elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
		WorldQuestTracker.UpdateZoneWidgets()
	end
end

--o cliente não tem o tempo restante da quest na primeira execução
function WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker_Load()
	for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
		local quest = WorldQuestTracker.QuestTrackList [i]
		--if (HaveQuestData (quest.questID)) then
			local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (quest.questID)
		--end
	end
end

--verifica o tempo restante de cada quest no tracker e a remove se o tempo estiver terminado
function WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker()
	local now = time()
	local gotRemoval
	
	for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
		local quest = WorldQuestTracker.QuestTrackList [i]
		local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (quest.questID)
		
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

--parent frame na UIParent ~trackerframe
--esse frame é quem vai ser anexado ao tracker da blizzard
--this is the main frame for the quest tracker, every thing on the tracker is parent of this frame
-- ~trackerframe
local WorldQuestTrackerFrame = CreateFrame ("frame", "WorldQuestTrackerScreenPanel", UIParent)
WorldQuestTrackerFrame:SetSize (235, 500)
WorldQuestTrackerFrame:SetFrameStrata ("LOW") --thanks @p3lim on curseforge

--debug tracker size
--WorldQuestTrackerFrame:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})


local WorldQuestTrackerFrame_QuestHolder = CreateFrame ("frame", "WorldQuestTrackerScreenPanel_QuestHolder", WorldQuestTrackerFrame)
WorldQuestTrackerFrame_QuestHolder:SetAllPoints()

function WorldQuestTracker.UpdateTrackerScale()
	WorldQuestTrackerFrame:SetScale (WorldQuestTracker.db.profile.tracker_scale)
	--WorldQuestTrackerFrame_QuestHolder:SetScale (WorldQuestTracker.db.profile.tracker_scale) --aumenta só as quests sem mexer no cabeçalho
end

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
		minimizeButtonText:SetText ("World Quest Tracker")
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

--move anything
C_Timer.After (10, function()
	if (MAOptions) then
		MAOptions:HookScript ("OnUpdate", function()
			WorldQuestTracker.RefreshAnchor()
		end)

		--ObjectiveTrackerFrameMover:CreateTexture("AA", "overlay")
		--AA:SetAllPoints()
		--AA:SetColorTexture (1, 1, 1, .3)
	end
end)

--da refresh na ancora do screen panel
--enUS - refresh the track positioning on the player screen
function WorldQuestTracker.RefreshAnchor()

	if (not WorldQuestTracker.db.profile.tracker_is_movable) then
		WorldQuestTrackerScreenPanel:ClearAllPoints()

		for i = 1, ObjectiveTrackerFrame:GetNumPoints() do
			local point, relativeTo, relativePoint, xOfs, yOfs = ObjectiveTrackerFrame:GetPoint (i)
			
			--note: we're probably missing something here, when the frame anchors to MoveAnything frame 'ObjectiveTrackerFrameMover', 
			--it automatically anchors to MinimapCluster frame.
			--so the solution we've found was to get the screen position of the MoveAnything frame and anchor our frame to UIParent.
			
			--if (relativeTo:GetName() == "ObjectiveTrackerFrameMover") then
			if (IsAddOnLoaded("MoveAnything") and relativeTo and (relativeTo:GetName() == "ObjectiveTrackerFrameMover")) then -- (check if MA is lodaded - thanks @liquidbase on WoWUI)
				local top, left = ObjectiveTrackerFrameMover:GetTop(), ObjectiveTrackerFrameMover:GetLeft()
				WorldQuestTrackerScreenPanel:SetPoint ("top", UIParent, "top", 0, (yOfs - WorldQuestTracker.TrackerHeight - 20) - abs (top-GetScreenHeight()))
				WorldQuestTrackerScreenPanel:SetPoint ("left", UIParent, "left", -10 + xOfs + left, 0)
			else
				WorldQuestTrackerScreenPanel:SetPoint (point, relativeTo, relativePoint, -10 + xOfs, yOfs - WorldQuestTracker.TrackerHeight - 20)
			end
			
			--print where the frame is setting its potision
			--print ("SETTING POS ON:", point, relativeTo:GetName(), relativePoint, -10 + xOfs, yOfs - WorldQuestTracker.TrackerHeight - 20)
		end

		--print where the frame was anchored, weird thing happens if we set the anchor to a MoveAnything frame
		--local point, relativeTo, relativePoint, xOfs, yOfs = WorldQuestTrackerScreenPanel:GetPoint (1)
		--print ("SETTED AT", point, relativeTo:GetName(), relativePoint, xOfs, yOfs)

		WorldQuestTrackerHeader:ClearAllPoints()
		WorldQuestTrackerHeader:SetPoint ("bottom", WorldQuestTrackerFrame, "top", 0, -20)
	else
		--> se estiver destrancado, ativar o mouse
		if (not WorldQuestTracker.db.profile.tracker_is_locked and WorldQuestTrackerScreenPanel.RegisteredForLibWindow) then
			WorldQuestTrackerScreenPanel:EnableMouse (true)
			LibWindow.MakeDraggable (WorldQuestTrackerScreenPanel)
		else
			WorldQuestTrackerScreenPanel:EnableMouse (false)
		end
		
		WorldQuestTrackerHeader:ClearAllPoints()
		WorldQuestTrackerHeader:SetPoint ("bottom", WorldQuestTrackerFrame, "top", 0, -20)
	end
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
	else
		WorldQuestTracker.CanLinkToChat (self, button)
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
	
	self.HasOverHover = true
end

local TrackerFrameOnLeave = function (self)
	local color = OBJECTIVE_TRACKER_COLOR["Header"]
	self.Title:SetTextColor (color.r, color.g, color.b)
	
	local color = OBJECTIVE_TRACKER_COLOR["Normal"]
	self.Zone:SetTextColor (color.r, color.g, color.b)

	self.RightBackground:SetAlpha (TRACKER_BACKGROUND_ALPHA_MIN)
	self.Arrow:SetAlpha (TRACKER_ARROW_ALPHA_MIN)
	GameTooltip:Hide()
	
	self.HasOverHover = nil
	self.QuestInfomation.text = ""
end

local TrackerIconButtonOnEnter = function (self)
	
end
local TrackerIconButtonOnLeave = function (self)
	
end
local TrackerIconButtonOnClick = function (self, button)
	if (self.questID == GetSuperTrackedQuestID()) then
		WorldQuestTracker.SuperTracked = nil
		QuestSuperTracking_ChooseClosestQuest()
		return
	end
	
	if (HaveQuestData (self.questID)) then
		SetSuperTrackedQuestID (self.questID)
		WorldQuestTracker.RefreshTrackerWidgets()
		WorldQuestTracker.SuperTracked = self.questID
	end
end

local UpdateSuperQuestTracker = function()
	if (WorldQuestTracker.SuperTracked and HaveQuestData (WorldQuestTracker.SuperTracked)) then
		--verifica se a quest esta sendo mostrada no tracker
		for i = 1, #TrackerWidgetPool do
			if (TrackerWidgetPool[i]:IsShown() and TrackerWidgetPool[i].questID == WorldQuestTracker.SuperTracked) then
				SetSuperTrackedQuestID (WorldQuestTracker.SuperTracked)
				return
			end
		end
		WorldQuestTracker.SuperTracked = nil
	end
end

hooksecurefunc ("QuestSuperTracking_ChooseClosestQuest", function()
	if (WorldQuestTracker.SuperTracked) then
		C_Timer.After (.02, UpdateSuperQuestTracker)
	end
end)

local TrackerIconButtonOnMouseDown = function (self, button)
	self.Icon:SetPoint ("topleft", self:GetParent(), "topleft", -12, -3)
end
local TrackerIconButtonOnMouseUp = function (self, button)
	self.Icon:SetPoint ("topleft", self:GetParent(), "topleft", -13, -2)
end

--pega um widget já criado ou cria um novo ~trackercreate ~trackerwidget
function WorldQuestTracker.GetOrCreateTrackerWidget (index)
	if (TrackerWidgetPool [index]) then
		return TrackerWidgetPool [index]
	end
	
	local f = CreateFrame ("button", "WorldQuestTracker_Tracker" .. index, WorldQuestTrackerFrame_QuestHolder)
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
	
	f.QuestInfomation = DF:CreateLabel (f)
	f.QuestInfomation:SetPoint ("topleft", f, "topright", 2, 0)
	
	f.YardsDistance = f:CreateFontString (nil, "overlay", "GameFontNormal")
	f.YardsDistance:SetPoint ("left", f.Zone.widget, "right", 2, 0)
	f.YardsDistance:SetJustifyH ("left")
	DF:SetFontColor (f.YardsDistance, "white")
	DF:SetFontSize (f.YardsDistance, 12)
	f.YardsDistance:SetAlpha (.5)
	
	f.TimeLeft = f:CreateFontString (nil, "overlay", "GameFontNormal")
	f.TimeLeft:SetPoint ("left", f.YardsDistance, "right", 2, 0)
	f.TimeLeft:SetJustifyH ("left")
	DF:SetFontColor (f.TimeLeft, "white")
	DF:SetFontSize (f.TimeLeft, 12)
	f.TimeLeft:SetAlpha (.5)
	
	f.Icon = f:CreateTexture (nil, "artwork")
	f.Icon:SetPoint ("topleft", f, "topleft", -13, -2)
	f.Icon:SetSize (16, 16)
	
	local IconButton = CreateFrame ("button", "$parentIconButton", f)
	IconButton:SetSize (18, 18)
	IconButton:SetPoint ("center", f.Icon, "center")
	IconButton:SetScript ("OnEnter", TrackerIconButtonOnEnter)
	IconButton:SetScript ("OnLeave", TrackerIconButtonOnLeave)
	IconButton:SetScript ("OnClick", TrackerIconButtonOnClick)
	IconButton:SetScript ("OnMouseDown", TrackerIconButtonOnMouseDown)
	IconButton:SetScript ("OnMouseUp", TrackerIconButtonOnMouseUp)
	IconButton.Icon = f.Icon
	f.IconButton = IconButton
--
	f.Circle = f:CreateTexture (nil, "overlay")
	f.Circle:SetTexture ([[Interface\Transmogrify\Transmogrify]])
	f.Circle:SetTexCoord (381/512, 405/512, 93/512, 117/512)
	f.Circle:SetSize (18, 18)
	--f.Circle:SetPoint ("center", f.Icon, "center")
	f.Circle:SetPoint ("topleft", f, "topleft", -14, -1)
	f.Circle:SetDesaturated (true)
	f.Circle:SetAlpha (.7)
	
	f.RewardAmount = f:CreateFontString (nil, "overlay", "ObjectiveFont")
	f.RewardAmount:SetTextColor (titleColor.r, titleColor.g, titleColor.b)
	f.RewardAmount:SetPoint ("top", f.Circle, "bottom", 0, -2)
	DF:SetFontSize (f.RewardAmount, 10)	
	
	f.Shadow = f:CreateTexture (nil, "BACKGROUND")
	f.Shadow:SetSize (26, 26)
	f.Shadow:SetPoint ("center", f.Circle, "center")
	f.Shadow:SetTexture ([[Interface\PETBATTLES\BattleBar-AbilityBadge-Neutral]])
	f.Shadow:SetAlpha (.3)
	f.Shadow:SetDrawLayer ("BACKGROUND", -5)
	
	f.SuperTracked = f:CreateTexture (nil, "background")
	f.SuperTracked:SetPoint ("center", f.Circle, "center")
	f.SuperTracked:SetAlpha (1)
	f.SuperTracked:SetTexture ([[Interface\Worldmap\UI-QuestPoi-IconGlow]])
	f.SuperTracked:SetBlendMode ("ADD")
	f.SuperTracked:SetSize (42, 42)
	f.SuperTracked:SetDrawLayer ("BACKGROUND", -6)
	f.SuperTracked:Hide()
	
	local highlight = IconButton:CreateTexture (nil, "highlight")
	highlight:SetPoint ("center", f.Circle, "center")
	highlight:SetAlpha (1)
	highlight:SetTexture ([[Interface\Worldmap\UI-QuestPoi-NumberIcons]])
	--highlight:SetTexCoord (167/256, 185/256, 103/256, 121/256) --low light
	highlight:SetTexCoord (167/256, 185/256, 231/256, 249/256)
	highlight:SetBlendMode ("ADD")
	highlight:SetSize (14, 14)
	
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

-- ~trackertick ~trackeronupdate ~tick ~onupdate ~ontick õntick õnupdate
local TrackerOnTick = function (self, deltaTime)
	if (self.NextPositionUpdate < 0) then
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
	end
	
	local x, y = GetPlayerMapPosition ("player")
	
	if (self.NextArrowUpdate < 0) then
		local questYaw = (FindLookAtRotation (_, x, y, self.questX, self.questY) + p)%pipi
		local playerYaw = GetPlayerFacing()
		local angle = (((questYaw + playerYaw)%pipi)+pi)%pipi
		local imageIndex = 1+(floor (MapRangeClamped (_, 0, pipi, 1, 144, angle)) + 48)%144 --48º quadro é o que aponta para o norte
		local line = ceil (imageIndex / 12)
		local coord = (imageIndex - ((line-1) * 12)) / 12
		self.Arrow:SetTexCoord (coord-0.0833, coord, 0.0833 * (line-1), 0.0833 * line)
		--self.ArrowDistance:SetTexCoord (coord-0.0905, coord-0.0160, 0.0833 * (line-1), 0.0833 * line) -- 0.0763
		self.ArrowDistance:SetTexCoord (coord-0.0833, coord, 0.0833 * (line-1), 0.0833 * line) -- 0.0763
		
		self.NextArrowUpdate = ARROW_UPDATE_FREQUENCE
	else
		self.NextArrowUpdate = self.NextArrowUpdate - deltaTime
	end
	
	self.NextPositionUpdate = self.NextPositionUpdate - deltaTime
	
	if ((playerIsMoving or self.ForceUpdate) and self.NextPositionUpdate < 0) then
		local distance = GetDistance_Point (_, x, y, self.questX, self.questY)
		local x = zoneXLength * distance
		local y = zoneYLength * distance
		local yards = (x*x + y*y) ^ 0.5
		self.YardsDistance:SetText ("[|cFFC0C0C0" .. floor (yards) .. "|r]")

		distance = abs (distance - 1)
		self.info.LastDistance = distance
		
		distance = Saturate (distance - 0.75) * 4
		local alpha = MapRangeClamped (_, 0, 1, 0, 0.5, distance)
		self.Arrow:SetAlpha (.5 + (alpha))
		self.ArrowDistance:SetVertexColor (distance, distance, distance)
		
		self.NextPositionUpdate = .5
		self.ForceUpdate = nil
		
		if (self.HasOverHover) then
			if (IsAltKeyDown()) then
				self.QuestInfomation.text = "ID: " .. self.questID .. "\nMapID: " .. self.info.mapID .. "\nTimeLeft: " .. self.info.timeLeft .. "\nType: " .. self.info.questType .. "\nNumObjetives: " .. self.info.numObjectives
			else
				self.QuestInfomation.text = ""
			end
		end
	end
	
	self.NextTimeUpdate = self.NextTimeUpdate - deltaTime
	
	if (self.NextTimeUpdate < 0) then
		if (HaveQuestData (self.questID)) then
			local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (self.questID)
			if (timeLeft and timeLeft > 0) then
				local timeLeft2 =  WorldQuestTracker.GetQuest_TimeLeft (self.questID, true)
				--local str = timeLeft > 1440 and floor (timeLeft/1440) .. "d" or timeLeft > 60 and floor (timeLeft/60) .. "h" or timeLeft .. "m"
				local color = "FFC0C0C0"
				if (timeLeft < 30) then
					color = "FFFF2200"
				elseif (timeLeft < 60) then
					color = "FFFF9900"
				end
				self.TimeLeft:SetText ("[|c" .. color .. timeLeft2 .. "|r]")
			else
				self.TimeLeft:SetText ("[0m]")
			end
		end
		self.NextTimeUpdate = 60
	end

end

local TrackerOnTick_TimeLeft = function (self, deltaTime)
	self.NextTimeUpdate = self.NextTimeUpdate - deltaTime
	
	if (self.NextTimeUpdate < 0) then
		if (HaveQuestData (self.questID)) then
			local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (self.questID)
			if (timeLeft and timeLeft > 0) then
				local timeLeft2 =  WorldQuestTracker.GetQuest_TimeLeft (self.questID, true)
				--local str = timeLeft > 1440 and floor (timeLeft/1440) .. "d" or timeLeft > 60 and floor (timeLeft/60) .. "h" or timeLeft .. "m"
				local color = "FFC0C0C0"
				if (timeLeft < 30) then
					color = "FFFF2200"
				elseif (timeLeft < 60) then
					color = "FFFF9900"
				end
				self.TimeLeft:SetText ("[|c" .. color .. timeLeft2 .. "|r]")
			else
				self.TimeLeft:SetText ("[0m]")
			end
		end
		self.NextTimeUpdate = 60
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
	local onlyCurrentMap = WorldQuestTracker.db.profile.tracker_only_currentmap
	
	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		--verifica se a quest esta ativa, ela pode ser desativada se o jogador estiver dentro da area da quest
		if (HaveQuestData (quest.questID)) then
			local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (quest.questID)
			
			if (not quest.isDisabled and title and (not onlyCurrentMap or (onlyCurrentMap and Sort_currentMapID == quest.mapID))) then
				local widget = WorldQuestTracker.GetOrCreateTrackerWidget (nextWidget)
				widget:ClearAllPoints()
				widget:SetPoint ("topleft", WorldQuestTrackerFrame, "topleft", 0, y)
				widget.questID = quest.questID
				widget.info = quest
				widget.numObjectives = quest.numObjectives
				--widget.id = quest.questID
				
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
				widget.IconButton.questID = quest.questID
				
				if (GetSuperTrackedQuestID() == quest.questID) then
					widget.SuperTracked:Show()
					widget.Circle:SetDesaturated (false)
				else
					widget.SuperTracked:Hide()
					widget.Circle:SetDesaturated (true)
				end
				
				if (type (quest.rewardAmount) == "number" and quest.rewardAmount >= 1000) then --erro compare number witrh string
					widget.RewardAmount:SetText (WorldQuestTracker.ToK (quest.rewardAmount))
				else
					widget.RewardAmount:SetText (quest.rewardAmount)
				end
				
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
					widget.NextArrowUpdate = -1
					widget.NextTimeUpdate = -1
					
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
						DF:SetFontSize (widget.TimeLeft, TRACKER_TITLE_TEXT_SIZE_INMAP)
						widget.YardsDistance:Show()
					else
						widget.YardsDistance:Hide()
					end
					
					if (WorldQuestTracker.db.profile.tracker_show_time) then
						widget.TimeLeft:Show()
					else
						widget.TimeLeft:Hide()
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
					
					if (WorldQuestTracker.db.profile.tracker_show_time) then
						widget.TimeLeft:Show()
						DF:SetFontSize (widget.TimeLeft, TRACKER_TITLE_TEXT_SIZE_OUTMAP)
						widget.NextTimeUpdate = -1
						widget:SetScript ("OnUpdate", TrackerOnTick_TimeLeft)
					else
						widget.TimeLeft:Hide()
					end
				end
				
				y = y - 35
				nextWidget = nextWidget + 1
			end
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
		WorldQuestTracker.UpdateTrackerScale()
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

local TrackerAnimation_OnAccept = CreateFrame ("frame", nil, UIParent)
TrackerAnimation_OnAccept:SetSize (235, 30)
TrackerAnimation_OnAccept.Title = DF:CreateLabel (TrackerAnimation_OnAccept)
TrackerAnimation_OnAccept.Title.textsize = TRACKER_TITLE_TEXT_SIZE_INMAP
TrackerAnimation_OnAccept.Title:SetPoint ("topleft", TrackerAnimation_OnAccept, "topleft", 10, -1)
local titleColor = OBJECTIVE_TRACKER_COLOR["Header"]
TrackerAnimation_OnAccept.Title:SetTextColor (titleColor.r, titleColor.g, titleColor.b)
TrackerAnimation_OnAccept.Zone = DF:CreateLabel (TrackerAnimation_OnAccept)
TrackerAnimation_OnAccept.Zone.textsize = TRACKER_TITLE_TEXT_SIZE_INMAP
TrackerAnimation_OnAccept.Zone:SetPoint ("topleft", TrackerAnimation_OnAccept, "topleft", 10, -17)
TrackerAnimation_OnAccept.Icon = TrackerAnimation_OnAccept:CreateTexture (nil, "artwork")
TrackerAnimation_OnAccept.Icon:SetPoint ("topleft", TrackerAnimation_OnAccept, "topleft", -13, -2)
TrackerAnimation_OnAccept.Icon:SetSize (16, 16)
TrackerAnimation_OnAccept.RewardAmount = TrackerAnimation_OnAccept:CreateFontString (nil, "overlay", "ObjectiveFont")
TrackerAnimation_OnAccept.RewardAmount:SetTextColor (titleColor.r, titleColor.g, titleColor.b)
TrackerAnimation_OnAccept.RewardAmount:SetPoint ("top", TrackerAnimation_OnAccept.Icon, "bottom", 0, -2)
DF:SetFontSize (TrackerAnimation_OnAccept.RewardAmount, 10)
TrackerAnimation_OnAccept:Hide()

TrackerAnimation_OnAccept.FlashTexture = TrackerAnimation_OnAccept:CreateTexture (nil, "background")
TrackerAnimation_OnAccept.FlashTexture:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-Alert-Glow]])
TrackerAnimation_OnAccept.FlashTexture:SetTexCoord (0, 400/512, 0, 168/256)
TrackerAnimation_OnAccept.FlashTexture:SetBlendMode ("ADD")
TrackerAnimation_OnAccept.FlashTexture:SetPoint ("topleft", -60, 40)
TrackerAnimation_OnAccept.FlashTexture:SetPoint ("bottomright", 40, -35)

local TrackerAnimation_OnAccept_MoveAnimation = DF:CreateAnimationHub (TrackerAnimation_OnAccept, function (self)
	-- 3 movement started
		--seta textos e texturas
		local quest = self.QuestObject
		local widget = self.WidgetObject
		TrackerAnimation_OnAccept.Title.text = widget.Title.text
		TrackerAnimation_OnAccept.Zone.text = widget.Zone.text
		if (quest.questType == QUESTTYPE_ARTIFACTPOWER) then
			TrackerAnimation_OnAccept.Icon:SetMask (nil)
		else
			TrackerAnimation_OnAccept.Icon:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
		end
		TrackerAnimation_OnAccept.Icon:SetTexture (quest.rewardTexture)
		TrackerAnimation_OnAccept.RewardAmount:SetText (widget.RewardAmount:GetText())	
	end, 
	function (self) 
	-- 4 movement end
		TrackerAnimation_OnAccept:Hide()
	end)
local ScreenWidth = -(floor (GetScreenWidth() / 2) - 200)
TrackerAnimation_OnAccept_MoveAnimation.Translation = DF:CreateAnimation (TrackerAnimation_OnAccept_MoveAnimation, "translation", 1, 2, ScreenWidth, 270)
DF:CreateAnimation (TrackerAnimation_OnAccept_MoveAnimation, "alpha", 1, 1.6, 1, 0)
--DF:CreateAnimation (TrackerAnimation_OnAccept_MoveAnimation, "scale", 1, 1.6, 1, 1, 0, 0)

local TrackerAnimation_OnAccept_FlashAnimation = DF:CreateAnimationHub (TrackerAnimation_OnAccept.FlashTexture, 
	function (self) 
		-- 1 Playing Flash
		TrackerAnimation_OnAccept.Title.text = ""
		TrackerAnimation_OnAccept.Zone.text = ""
		TrackerAnimation_OnAccept.Icon:SetTexture (nil)
		TrackerAnimation_OnAccept.RewardAmount:SetText ("")
		TrackerAnimation_OnAccept:Show()
		TrackerAnimation_OnAccept.FlashTexture:Show()
		TrackerAnimation_OnAccept:SetPoint ("topleft", self.WidgetObject, "topleft", 0, 0)
	end, 
	function (self) 
		-- 2 Flash Finished
		local quest = self.QuestObject
		local widget = self.WidgetObject
		
		self.QuestObject.isDisabled = true
		self.QuestObject.enteringZone = nil
		
		local top = widget:GetTop()
		local distance = GetScreenHeight() - top - 150
		TrackerAnimation_OnAccept_MoveAnimation.Translation:SetOffset (ScreenWidth, distance)
		TrackerAnimation_OnAccept_MoveAnimation:Play()
		
		TrackerAnimation_OnAccept.FlashTexture:Hide()
		WorldQuestTracker.UpdateQuestsInArea()
	end)
DF:CreateAnimation (TrackerAnimation_OnAccept_FlashAnimation, "alpha", 1, 0.15, 0, .68)
DF:CreateAnimation (TrackerAnimation_OnAccept_FlashAnimation, "scale", 1, 0.1, .1, .1, 1, 1, "center")
DF:CreateAnimation (TrackerAnimation_OnAccept_FlashAnimation, "alpha", 2, 0.15, .68, 0)

local get_widget_from_questID = function (questID)
	for i = 1, #TrackerWidgetPool do
		if (TrackerWidgetPool[i].questID == questID) then
			return TrackerWidgetPool[i]
		end
	end
end

--quando o tracker da interface atualizar, atualizar tbm o nosso tracker
--verifica se o jogador esta na area da quest
function WorldQuestTracker.UpdateQuestsInArea()
	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		if (HaveQuestData (quest.questID)) then
			local questIndex = GetQuestLogIndexByID (quest.questID)
			local isInArea, isOnMap, numObjectives = GetTaskInfo (quest.questID)
			if ((questIndex and questIndex ~= 0) or isInArea) then
				--desativa pois o jogo ja deve estar mostrando a quest
				if (not quest.isDisabled and not quest.enteringZone) then
					local widget = get_widget_from_questID (quest.questID)
					if (widget and not WorldQuestTracker.IsQuestOnObjectiveTracker (widget.Title:GetText())) then
						--acabou de aceitar a quest
						quest.enteringZone = true
						TrackerAnimation_OnAccept:Show()
						TrackerAnimation_OnAccept_MoveAnimation.QuestObject = quest
						TrackerAnimation_OnAccept_FlashAnimation.QuestObject = quest
						
						TrackerAnimation_OnAccept_MoveAnimation.WidgetObject = widget
						TrackerAnimation_OnAccept_FlashAnimation.WidgetObject = widget
						
						TrackerAnimation_OnAccept_FlashAnimation:Play()
					else
						quest.isDisabled = true
					end
				end
				--quest.isDisabled = true
			else
				quest.isDisabled = nil
			end
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

-- ~blizzard objective tracker
function WorldQuestTracker.IsQuestOnObjectiveTracker (quest)
	local tracker = ObjectiveTrackerFrame
	
	if (not tracker.initialized) then
		return
	end
	
	local CheckByType = type (quest)
	
	for i = 1, #tracker.MODULES do
		local module = tracker.MODULES [i]
		for blockName, usedBlock in pairs (module.usedBlocks) do
		
			local questID = usedBlock.id
			if (questID) then
				if (CheckByType == "string") then
					if (HaveQuestData (questID)) then
						local thisQuestName = GetQuestInfoByQuestID (questID)
						if (thisQuestName and thisQuestName == quest) then
							return true
						end
					end
				elseif (CheckByType == "number") then
					if (quest == questID) then
						return true
					end
				end
			end
		end
	end
end

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
	button:SetScale (1.3)
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

--this function format quest pins on the taxy map (I know, taxy is with I: taxi)
local format_for_taxy_nozoom_all = function (button)
	button:ClearWidget()

	button:SetScale (WorldQuestTracker.db.profile.taxy_tracked_scale + 0.5)
	button:SetWidth (20)
	button:SetAlpha (.75)
	
	button.circleBorder:Show()
	
	if (WorldQuestTracker.IsQuestBeingTracked (button.questID)) then
		button:SetAlpha (1)
		button.IsTrackingGlow:Show()
		button.IsTrackingGlow:SetAlpha (.5)
	end
end

WorldQuestTracker.TaxyZoneWidgets = {}

function WorldQuestTracker:TAXIMAP_OPENED()
	
	if (not WorldQuestTracker.FlyMapHook and FlightMapFrame) then

		for dataProvider, isInstalled in pairs (FlightMapFrame.dataProviders) do
			if (dataProvider.DoesWorldQuestInfoPassFilters) then
				C_Timer.After (1, function() dataProvider.RefreshAllData (dataProvider) end)
				C_Timer.After (2, function() dataProvider.RefreshAllData (dataProvider) end)
				break
			end
		end

		WorldQuestTracker.Taxy_CurrentShownBlips = WorldQuestTracker.Taxy_CurrentShownBlips or {}
	
		_G ["left"] = nil
		_G ["right"] = nil
		_G ["topleft"] = nil
		_G ["topright"] = nil
	
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
		
		if (not WorldQuestTracker.db.profile.TutorialTaxyMap) then
			local alert = CreateFrame ("frame", "WorldQuestTrackerTaxyTutorial", checkboxShowTrackedOnly.widget, "MicroButtonAlertTemplate")
			alert:SetFrameLevel (302)
			alert.label = "Options are here, show all quests or only those being tracked"
			alert.Text:SetSpacing (4)
			MicroButtonAlert_SetText (alert, alert.label)
			alert:SetPoint ("bottom", checkboxShowTrackedOnly.widget, "top", 0, 30)
			alert:Show()
			WorldQuestTracker.db.profile.TutorialTaxyMap = true
		end
	
		local filters = WorldQuestTracker.db.profile.filters
		
		--hooksecurefunc (FlightMapFrame, "SetPinPosition", function (self, pin, normalizedX, normalizedY, insetIndex)
		hooksecurefunc (FlightMapFrame, "ApplyPinPosition", function (self, pin, normalizedX, normalizedY, insetIndex)
			--print ("setting pin poisition")
			if (not pin.questID or not QuestMapFrame_IsQuestWorldQuest (pin.questID)) then
				--print (self.questID)
				--print (pin._WQT_Twin and pin._WQT_Twin.questID)
				--print (pin.Icon, self.Icon)
				if (pin.Icon and pin.Icon:GetTexture() == 1455734) then
					--pin.Icon:SetTexture ([[Interface\TAXIFRAME\UI-Taxi-Icon-Highlight]])
					if (not pin.Icon.ExtraShadow) then
						pin.Icon:SetDrawLayer ("overlay")
						pin.Icon.ExtraShadow = pin:CreateTexture (nil, "background")
						pin.Icon.ExtraShadow:SetSize (19, 19)
						pin.Icon.ExtraShadow:SetTexture (1455734)
						pin.Icon.ExtraShadow:SetTexCoord (4/128, 71/128, 36/512, 108/512)
						pin.Icon.ExtraShadow:SetPoint ("center")
					end
				end
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
				--pin._WQT_Twin:SetScript ("OnEnter", pin:GetScript ("OnEnter"))
				pin._WQT_Twin:SetScript ("OnEnter", function (self)
					--> the tooltip should get the scale from the taxi map pin
					pin:GetScript ("OnEnter")(pin)
					pin._WQT_Twin.Texture:SetBlendMode ("ADD")
				end)
				
				pin._WQT_Twin:SetScript ("OnLeave", function()
					pin:GetScript ("OnLeave")(pin)
					pin._WQT_Twin.Texture:SetBlendMode ("BLEND")
				end)

				tinsert (WorldQuestTracker.TaxyZoneWidgets, pin._WQT_Twin)
			end
			
			local isShowingQuests = WorldQuestTracker.db.profile.taxy_showquests
			local isShowingOnlyTracked = WorldQuestTracker.db.profile.taxy_trackedonly
			local hasZoom = WorldQuestTracker.TaxyFrameHasZoom()
			
			--não esta mostrando as quests e o mapa não tem zoom
			if (not isShowingQuests and not hasZoom) then
				pin._WQT_Twin:Hide()
				WorldQuestTracker.Taxy_CurrentShownBlips [pin._WQT_Twin] = nil
				pin._WQT_Twin.questID = nil
				pin._WQT_Twin.LastUpdate = nil
				return
			end
			
			--esta mostrando apenas quests que estão sendo trackeadas
			if (isShowingOnlyTracked) then
				if ((not WorldQuestTracker.IsQuestBeingTracked (pin.questID) and not WorldQuestTracker.IsQuestOnObjectiveTracker (pin.questID)) and not hasZoom) then
					pin._WQT_Twin:Hide()
					WorldQuestTracker.Taxy_CurrentShownBlips [pin._WQT_Twin] = nil
					pin._WQT_Twin.questID = nil
					pin._WQT_Twin.LastUpdate = nil
					return
				end
			end

			pin._WQT_Twin:Show()
			WorldQuestTracker.Taxy_CurrentShownBlips [pin._WQT_Twin] = true
			
			local title, questType, texture, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, selected, isSpellTarget, timeLeft, isCriteria, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker:GetQuestFullInfo (pin.questID)
			
			--não mostrar quests que foram filtradas
			local filter = WorldQuestTracker.GetQuestFilterTypeAndOrder (worldQuestType, gold, rewardName, itemName, isArtifact, quantity)
			if (not filters [filter] and rarity ~= LE_WORLD_QUEST_QUALITY_EPIC) then
				pin._WQT_Twin:Hide()
				WorldQuestTracker.Taxy_CurrentShownBlips [pin._WQT_Twin] = nil
				pin._WQT_Twin.questID = nil
				pin._WQT_Twin.LastUpdate = nil
				return
			end

			local inProgress, questIDChanged
			
			if (pin._WQT_Twin.questID ~= pin.questID) then
				questIDChanged = true
			end
			pin._WQT_Twin.questID = pin.questID
			pin._WQT_Twin.numObjectives = pin.numObjectives
			local mapID, zoneID = C_TaskQuest.GetQuestZoneID (pin.questID)
			pin._WQT_Twin.mapID = zoneID
			
			--FlightMapFrame:ZoomOut()
			if (not hasZoom) then
				--não tem zoom
				if (isShowingOnlyTracked) then
					if (questIDChanged or pin._WQT_Twin.zoomState or not pin._WQT_Twin.LastUpdate or pin._WQT_Twin.LastUpdate+20 < GetTime()) then
						WorldQuestTracker.SetupWorldQuestButton (pin._WQT_Twin, questType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget)
						format_for_taxy_nozoom_tracked (pin._WQT_Twin)
						pin._WQT_Twin.LastUpdate = GetTime()
						pin._WQT_Twin.zoomState = nil
						--print ("UPDATED")
					end
				else
					if (questIDChanged or pin._WQT_Twin.zoomState or not pin._WQT_Twin.LastUpdate or pin._WQT_Twin.LastUpdate+20 < GetTime()) then
						WorldQuestTracker.SetupWorldQuestButton (pin._WQT_Twin, questType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget)
						format_for_taxy_nozoom_all (pin._WQT_Twin)
						pin._WQT_Twin.LastUpdate = GetTime()
						pin._WQT_Twin.zoomState = nil
						--print ("atualizando", GetTime())
					end
				end
			else
				--tem zoom
				if (questIDChanged or not pin._WQT_Twin.zoomState or not pin._WQT_Twin.LastUpdate or pin._WQT_Twin.LastUpdate+20 < GetTime()) then
					WorldQuestTracker.SetupWorldQuestButton (pin._WQT_Twin, questType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget)
					format_for_taxy_zoom_allquests (pin._WQT_Twin)
					pin._WQT_Twin.LastUpdate = GetTime()
					pin._WQT_Twin.zoomState = true
					--print ("UPDATED")
				end
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
	for _, widget in ipairs (WorldQuestTracker.TaxyZoneWidgets) do
		widget.LastUpdate = nil
		widget.questID = nil
	end
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
		
		Anchor_X = 0.01,
		Anchor_Y = 0.59,
		GrowRight = true,
	},
	[valsharah_mapId] = {
		worldMapLocation = {x = 10, y = -218, lineWidth = 240},
		worldMapLocationMax = {x = 168, y = -284, lineWidth = 340},
		worldMapLocationMaxElvUI = {x = 10, y = -284, lineWidth = 340},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = valsharah_widgets,
		
		Anchor_X = 0.01,
		Anchor_Y = 0.37,
		GrowRight = true,
	},
	[highmountain_mapId] = {
		worldMapLocation = {x = 10, y = -179, lineWidth = 320},
		worldMapLocationMax = {x = 168, y = -230, lineWidth = 452},
		worldMapLocationMaxElvUI = {x = 10, y = -230, lineWidth = 452},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = highmountain_widgets,

		Anchor_X = 0.01,
		Anchor_Y = 0.22,
		GrowRight = true,
	},
	[stormheim_mapId] = {
		worldMapLocation = {x = 415, y = -235, lineWidth = 277},
		worldMapLocationMax = {x = 747, y = -313, lineWidth = 393},
		worldMapLocationMaxElvUI = {x = 600, y = -313, lineWidth = 393},
		bipAnchor = {side = "left", x = 0, y = -1},
		factionAnchor = {mySide = "right", anchorSide = "left", x = -0, y = 0},
		squarePoints = {mySide = "topright", anchorSide = "bottomright", y = -1, xDirection = -1},
		widgets = stormheim_widgets,
		
		Anchor_X = 0.99,
		Anchor_Y = 0.32,
	},
	[suramar_mapId] = {
		worldMapLocation = {x = 327, y = -277, lineWidth = 365},
		worldMapLocationMax = {x = 618, y = -367, lineWidth = 522},
		worldMapLocationMaxElvUI = {x = 471, y = -367, lineWidth = 522},
		bipAnchor = {side = "left", x = 0, y = -1},
		factionAnchor = {mySide = "right", anchorSide = "left", x = -0, y = 0},
		squarePoints = {mySide = "topright", anchorSide = "bottomright", y = -1, xDirection = -1},
		widgets = suramar_widgets,
		
		Anchor_X = 0.99,
		Anchor_Y = 0.45,
	},
	[eoa_mapId] = {
		worldMapLocation = {x = 325, y = -460, lineWidth = 50},
		worldMapLocationMax = {x = 614, y = -633, lineWidth = 50},
		worldMapLocationMaxElvUI = {x = 461, y = -633, lineWidth = 50},
		bipAnchor = {side = "left", x = 0, y = -1},
		factionAnchor = {mySide = "right", anchorSide = "left", x = -0, y = 0},
		squarePoints = {mySide = "topright", anchorSide = "bottomright", y = -1, xDirection = -1},
		widgets = eoa_widgets,
		
		Anchor_X = 0.5,
		Anchor_Y = 0.8,
		GrowRight = true,
	},
	[WorldQuestTracker.MAPID_DALARAN] = {
		worldMapLocation = {x = 325, y = -460, lineWidth = 50},
		worldMapLocationMax = {x = 614, y = -633, lineWidth = 50},
		worldMapLocationMaxElvUI = {x = 461, y = -633, lineWidth = 50},
		bipAnchor = {side = "left", x = 0, y = -1},
		factionAnchor = {mySide = "right", anchorSide = "left", x = -0, y = 0},
		squarePoints = {mySide = "topright", anchorSide = "bottomright", y = -1, xDirection = -1},
		widgets = eoa_widgets,
		
		Anchor_X = 0.48,
		Anchor_Y = 0.62,
		GrowRight = true,
	}
}

--esconde todos os widgets do world map
function WorldQuestTracker.HideWorldQuestsOnWorldMap()
	for _, widget in ipairs (all_widgets) do --quadrados das quests
		widget:Hide()
		widget.isArtifact = nil
		widget.questID = nil
	end
	for _, widget in ipairs (extra_widgets) do --linhas e bolas de facções
		widget:Hide()
	end
end

--	/run WorldQuestTrackerAddon.SetTextSize ("WorldMap", 10)
function WorldQuestTracker.SetTextSize (MapType, Size)
	if (not WorldQuestTracker.db) then
		C_Timer.After (2, function() WorldQuestTracker.SetTextSize ("WorldMap") end)
	end
	if (MapType == "WorldMap") then
		Size = Size or WorldQuestTracker.db.profile.worldmap_widgets.textsize
		WorldQuestTracker.db.profile.worldmap_widgets.textsize = Size
		local ShadowSizeH, ShadowSizeV = 32, 11
		if (Size == 10) then
			ShadowSizeH, ShadowSizeV = 36, 13
		elseif (Size == 11) then
			ShadowSizeH, ShadowSizeV = 40, 14
		end
		--
		for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
			for _, widget in ipairs (configTable.widgets) do
				DF:SetFontSize (widget.amountText, Size)
				widget.amountBackground:SetSize (ShadowSizeH, ShadowSizeV)
			end
		end
		return
	end
	if (MapType == "ZoneMap") then
		
		return
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
	
	WorldQuestTracker.WorldMapSupportWidgets [mapId] = {line, blip, factionIcon, factionIconBorder, factionQuestAmount, factionQuestAmountBackground, factionHighlight}
	
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
	WorldQuestTracker:CreateAnimation (onStartTrackAnimation, "Scale", 1, .12, .9, .9, 1.1, 1.1)
	WorldQuestTracker:CreateAnimation (onStartTrackAnimation, "Scale", 2, .12, 1.2, 1.2, 1, 1)
	
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
	
	--> shared on party (world map)
	button.partySharedBlip = button:CreateTexture (nil, "OVERLAY", 2)
	button.partySharedBlip:SetPoint ("topleft", button, "topleft", -4, 4)
	button.partySharedBlip:SetSize (12, 12)
	button.partySharedBlip:SetAlpha (.85)
	button.partySharedBlip:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_party_sharedT]])
	
	local amountText = button:CreateFontString (nil, "overlay", "GameFontNormal", 1)
	amountText:SetPoint ("top", button, "bottom", 1, 0)
	DF:SetFontSize (amountText, 9)
	
	local timeLeftText = button:CreateFontString (nil, "overlay", "GameFontNormal", 1)
	timeLeftText:SetPoint ("top", amountText, "bottom", 0, -2)
	DF:SetFontSize (timeLeftText, 10)
	DF:SetFontColor (timeLeftText, {.9, .8, .2})
	DF:SetFontColor (timeLeftText, {.9, .9, .9})
	--
	local timeLeftBackground = button:CreateTexture (nil, "background", 0)
	timeLeftBackground:SetPoint ("center", timeLeftText, "center")
	timeLeftBackground:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
	timeLeftBackground:SetSize (32, 10)
	timeLeftBackground:SetAlpha (.60)
	
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
	new:SetTexCoord (0, 1, 0, .5)
	button.newIndicator = new
	
	local newFlashTexture = button:CreateTexture (nil, "overlay")
	newFlashTexture:SetPoint ("bottom", new, "bottom")
	newFlashTexture:SetSize (64*.45, 32*.45)
	newFlashTexture:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\new]])
	newFlashTexture:SetTexCoord (0, 1, 0, .5)
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
	button.timeLeftText = timeLeftText
	button.timeLeftBackground = timeLeftBackground
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

local schedule_blip_creation = function (timerObject)
	local configTable, line, mapName = timerObject.configTable, timerObject.line, timerObject.mapName
	
	local x = 2
	for i = 1, 20 do
		local button = create_worldmap_square (mapName, i)
		button:SetPoint (configTable.squarePoints.mySide, line, configTable.squarePoints.anchorSide, x*configTable.squarePoints.xDirection, configTable.squarePoints.y)
		button:Hide()
		x = x + WORLDMAP_SQUARE_SIZE + 1
		tinsert (configTable.widgets, button)
	end
end

WorldQuestTracker.QUEST_POI_FRAME_WIDTH = 1
WorldQuestTracker.QUEST_POI_FRAME_HEIGHT = 1
WorldQuestTracker.NextWorldMapWidget = 1
WorldQuestTracker.WorldMapSquares = {}

function WorldQuestTracker.UpdateAllWorldMapAnchors()
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		local x, y = configTable.Anchor_X, configTable.Anchor_Y
		WorldQuestTracker.UpdateWorldMapAnchors (x, y, configTable.MapAnchor)
		
		local mapName = GetMapNameByID (mapId)
		configTable.MapAnchor.Title:SetText (mapName)
		
		configTable.MapAnchor.Title:ClearAllPoints()
		configTable.MapAnchor.Title:Show()
		if (configTable.GrowRight) then
			configTable.MapAnchor.Title:SetPoint ("bottomleft", configTable.MapAnchor, "topleft", 0, 0)
			configTable.MapAnchor.Title:SetJustifyH ("left")
		else
			configTable.MapAnchor.Title:SetPoint ("bottomright", configTable.MapAnchor, "topright", 0, 0)
			configTable.MapAnchor.Title:SetJustifyH ("right")
		end
		
		configTable.factionFrame:Show()
	end
end

function WorldQuestTracker.UpdateWorldMapAnchors (x, y, frame)
	if (WorldMapFrame_InWindowedMode()) then
		WorldQuestTracker.QUEST_POI_FRAME_WIDTH = WorldMapDetailFrame:GetWidth() * WORLDMAP_WINDOWED_SIZE
		WorldQuestTracker.QUEST_POI_FRAME_HEIGHT = WorldMapDetailFrame:GetHeight() * WORLDMAP_WINDOWED_SIZE
	else
		WorldQuestTracker.QUEST_POI_FRAME_WIDTH = WorldMapDetailFrame:GetWidth() * WORLDMAP_FULLMAP_SIZE
		WorldQuestTracker.QUEST_POI_FRAME_HEIGHT = WorldMapDetailFrame:GetHeight() * WORLDMAP_FULLMAP_SIZE
	end
	
	local posX = x * WorldQuestTracker.QUEST_POI_FRAME_WIDTH
	local posY = y * WorldQuestTracker.QUEST_POI_FRAME_HEIGHT
	
	frame:ClearAllPoints()
	frame:SetPoint ("TOPLEFT", WorldMapPOIFrame, "TOPLEFT", posX, -posY)
end

function WorldQuestTracker.GetWorldMapWidget (configTable)
	local widget = WorldQuestTracker.WorldMapSquares [WorldQuestTracker.NextWorldMapWidget]
	widget:Show()
	widget:ClearAllPoints()
	
	tinsert (configTable.widgets, widget)
	
	if (configTable.GrowRight) then
		if (configTable.LastWidget) then
			widget:SetPoint ("topleft", configTable.LastWidget, "topright", 1, 0)
		else
			widget:SetPoint ("topleft", configTable.MapAnchor, "topright", 0, 0)
		end
	else
		if (configTable.LastWidget) then
			widget:SetPoint ("topright", configTable.LastWidget, "topleft", -1, 0)
		else
			widget:SetPoint ("topright", configTable.MapAnchor, "topleft", 0, 0)
		end
	end
	
	configTable.LastWidget = widget
	WorldQuestTracker.NextWorldMapWidget = WorldQuestTracker.NextWorldMapWidget + 1
	
	widget:SetScale (WorldQuestTracker.db.profile.worldmap_widgets.scale)
	
	return widget
end

function WorldQuestTracker.ClearWorldMapWidgets()
	for i = 1, 120 do
		local widget = WorldQuestTracker.WorldMapSquares [i]
		widget:ClearAllPoints()
		widget:Hide()
	end
	
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		table.wipe (configTable.widgets)
		configTable.LastWidget = nil
	end
	
	WorldQuestTracker.NextWorldMapWidget = 1
end

local create_world_widgets = function()
	
	--cria 7 ancoras (5 mapas 1 eye of azshara 1 dalaran)
	--os quadrados serão ancorados a estas ancoras
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		local anchor = CreateFrame ("frame", nil, worldFramePOIs)
		anchor:SetSize (1, 1)
		local x, y = configTable.Anchor_X, configTable.Anchor_Y
		configTable.MapAnchor = anchor
		
		WorldQuestTracker.UpdateWorldMapAnchors (x, y, anchor)
		
		local anchorText = anchor:CreateFontString (nil, "artwork", "GameFontNormal")
		anchorText:SetPoint ("bottomleft", anchor, "topleft", 0, 0)
		anchor.Title = anchorText
		
		local factionFrame = CreateFrame ("frame", "WorldQuestTrackerFactionFrame" .. mapId, worldFramePOIs)
		tinsert (faction_frames, factionFrame)
		factionFrame:SetSize (20, 20)
		configTable.factionFrame = factionFrame
		
		tinsert (all_widgets, factionFrame)
		tinsert (all_widgets, anchorText)
	end
	
	for i = 1, 120 do
		local button = create_worldmap_square ("WorldQuestTrackerWMButton", i)
		button:Hide()
		tinsert (WorldQuestTracker.WorldMapSquares, button)
	end
	
	WorldQuestTracker.WorldMapFrameReference = WorldQuestTracker.WorldMapSquares [1]
	
	--configTable.widgets
	
	if (true) then
		return
	end

	local n = .1
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		local mapName = GetMapNameByID (mapId)
		local line, blip, factionFrame = create_worldmap_line (configTable.worldMapLocation.lineWidth, mapId)
		
		if (ElvUI and ElvDB and IsAddOnLoaded ("ElvUI") and ElvDB.global and ElvDB.global.general) then
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
		
--		local create_timer = C_Timer.NewTimer (n, schedule_blip_creation)
--		create_timer.configTable = configTable
--		create_timer.line = line
--		create_timer.mapName = mapName

--[	
		local x = 2
		for i = 1, 20 do
			local button = create_worldmap_square (mapName, i)
			button:SetPoint (configTable.squarePoints.mySide, line, configTable.squarePoints.anchorSide, x*configTable.squarePoints.xDirection, configTable.squarePoints.y)
			button:Hide()
			x = x + WORLDMAP_SQUARE_SIZE + 1
			tinsert (configTable.widgets, button)
		end
--]]
		n = n + .1
	end
	
	C_Timer.After (2, function() WorldQuestTracker.SetTextSize ("WorldMap") end)
	
	--print ("criado!")
end
--C_Timer.After (1, create_world_widgets)
create_world_widgets()

if (false and IsAddOnLoaded ("ElvUI")) then
	C_Timer.After (2, function()
		for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
			local line = configTable.line
			
			if (ElvUI and ElvDB and IsAddOnLoaded ("ElvUI") and ElvDB.global and ElvDB.global.general) then
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
		end
	end)
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
	
	--> if dungeons are disabled, override the quest type to dungeon
	if (worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON) then
		if (not WorldQuestTracker.db.profile.filters [FILTER_TYPE_DUNGEON]) then
			filter = FILTER_TYPE_DUNGEON
		end
	end
	
	return filter, order
end

local quest_bugged = {}

function WorldQuestTracker.GetWorldWidgetForQuest (questID)
	for i = 1, #all_widgets do
		local widget = all_widgets [i]
		if (widget:IsShown() and widget.questID == questID) then
			return widget
		end
	end
end

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
		
	--elseif () then
	--	return
	end
	
	WorldQuestTracker.RefreshStatusBar()
	
	WorldQuestTracker.ClearZoneSummaryButtons()
	
	WorldQuestTracker.LastUpdate = GetTime()
	wipe (factionAmountForEachMap)
	
	--mostrar os widgets extras
--	for _, widget in ipairs (extra_widgets) do
--		widget:Show()
--	end
	
	--limpa todos os widgets no world map
	WorldQuestTracker.ClearWorldMapWidgets()
	
--	
	if (WorldQuestTracker.WorldWidgets_NeedFullRefresh) then
		WorldQuestTracker.WorldWidgets_NeedFullRefresh = nil
		noCache = true
	end
	
	local questsAvailable = {}
	local needAnotherUpdate = false
	local filters = WorldQuestTracker.db.profile.filters
	local timePriority = WorldQuestTracker.db.profile.sort_time_priority and WorldQuestTracker.db.profile.sort_time_priority * 60 --4 8 12 16 24
	local showTimeLeftText = WorldQuestTracker.db.profile.show_timeleft
	
	local sortByTimeLeft = WorldQuestTracker.db.profile.force_sort_by_timeleft
	
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		
		questsAvailable [mapId] = {}
		local taskInfo = GetQuestsForPlayerByMapID (mapId)
		local shownQuests = 0
		
		if (taskInfo and #taskInfo > 0) then
			for i, info in ipairs (taskInfo) do
				local questID = info.questId
				if (HaveQuestData (questID)) then
					local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
					if (isWorldQuest) then
						local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
						if (timeLeft and timeLeft > 0) then
							
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
							
							--~sort
							local filter, order = WorldQuestTracker.GetQuestFilterTypeAndOrder (worldQuestType, gold, rewardName, itemName, isArtifact, stackAmount)
							order = order or 1
							
							if (sortByTimeLeft) then
								order = abs (timeLeft - 10000)
							elseif (timePriority) then --timePriority já multiplicado por 60
								if (timeLeft < timePriority) then
									order = abs (timeLeft - 1000)
								end
							end
							
							if (filters [filter] or rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
								tinsert (questsAvailable [mapId], {questID, order, info.numObjectives})
								shownQuests = shownQuests + 1
							else
								if (WorldQuestTracker.db.profile.filter_always_show_faction_objectives) then
									local isCriteria = WorldMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty (questID)
									if (isCriteria) then
										tinsert (questsAvailable [mapId], {questID, order, info.numObjectives})
										shownQuests = shownQuests + 1
									end
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
			
			if (shownQuests == 0) then
				--hidar os widgets extras mque pertencem a zone sem quests
				--for o = 1, #WorldQuestTracker.WorldMapSupportWidgets [mapId] do
				--	WorldQuestTracker.WorldMapSupportWidgets [mapId] [o]:Hide()
				--end
			end
		else
			if (not taskInfo) then
				needAnotherUpdate = true
			elseif (#taskInfo == 0) then
				--hidar os widgets extras mque pertencem a zone sem quests
				--if (WorldQuestTracker.WorldMapSupportWidgets [mapId]) then
				--	for o = 1, #WorldQuestTracker.WorldMapSupportWidgets [mapId] do
				--		WorldQuestTracker.WorldMapSupportWidgets [mapId] [o]:Hide()
				--	end
				--end
			end
		end
	end
	
--	
	
	local availableQuests = 0
	local total_Gold = 0
	local total_Resources = 0
	local total_APower = 0
	
	local isUsingTracker = WorldQuestTracker.db.profile.use_tracker
	local timePriority = WorldQuestTracker.db.profile.sort_time_priority
	local UseTimePriorityAlpha = WorldQuestTracker.db.profile.alpha_time_priority
	if (timePriority) then
		if (timePriority == 4) then
			timePriority = 60*4
		elseif (timePriority == 8) then
			timePriority = 60*8
		elseif (timePriority == 12) then
			timePriority = 60*12
		elseif (timePriority == 16) then
			timePriority = 60*16
		elseif (timePriority == 24) then
			timePriority = 60*24
		end
	end
	
	wipe (WorldQuestTracker.Cache_ShownQuestOnWorldMap)
	WorldQuestTracker.Cache_ShownQuestOnWorldMap [WQT_QUESTTYPE_GOLD] = {}
	WorldQuestTracker.Cache_ShownQuestOnWorldMap [WQT_QUESTTYPE_RESOURCE] = {}
	WorldQuestTracker.Cache_ShownQuestOnWorldMap [WQT_QUESTTYPE_APOWER] = {}
	
	local research_nameLoc, research_timeleftString, research_timeLeft, research_elapsedTime, shipmentsReady = WorldQuestTracker:GetNextResearchNoteTime()
	if (research_timeLeft and research_timeLeft > 60) then
		research_timeLeft = research_timeLeft / 60 --convert in minutes
	end
	local hasArtifactUnderpower
	if (shipmentsReady and shipmentsReady > 0) then
		--> already loaded?
		if (WorldQuestTracker.ShowResearchNoteReady) then
			WorldQuestTracker.ShowResearchNoteReady (research_nameLoc)
		end
	else
		if (WorldQuestTracker.HideResearchNoteReady) then
			WorldQuestTracker.HideResearchNoteReady()
		end
	end
	
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
						
							--local widget = widgets [taskIconIndex]
							local widget = WorldQuestTracker.GetWorldMapWidget (configTable)
							
							if (not widget) then
								--se não tiver o widget, o jogador abriu o mapa muito rapidamente
								if (WorldMapFrame:IsShown()) then
									WorldQuestTracker.ScheduleWorldMapUpdate (1.5)
									WorldQuestTracker.PlayLoadingAnimation()
								end
								return
							end
							
							if (timePriority and UseTimePriorityAlpha) then
								if (timeLeft < timePriority) then
									widget:SetAlpha (1)
								else
									widget:SetAlpha (.4)
								end
							else
								widget:SetAlpha (1)
							end
							
							if (widget) then
							
								widget.timeBlipRed:Hide()
								widget.timeBlipOrange:Hide()
								widget.timeBlipYellow:Hide()
								widget.timeBlipGreen:Hide()
								widget.partySharedBlip:Hide()
							
								if (showTimeLeftText) then
									widget.timeLeftText:Show()
									widget.timeLeftBackground:Show()
									widget.timeLeftText:SetText (timeLeft > 1440 and floor (timeLeft/1440) .. "d" or timeLeft > 60 and floor (timeLeft/60) .. "h" or timeLeft .. "m")
								else
									widget.timeLeftBackground:Hide()
									widget.timeLeftText:Hide()
								end
							
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
									
									if (not isUsingTracker) then
										if (WorldQuestTracker.IsQuestOnObjectiveTracker (questID)) then
											widget.trackingGlowBorder:Show()
										else
											widget.trackingGlowBorder:Hide()
										end
									else
										if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
											widget.trackingGlowBorder:Show()
										else
											--widget.trackingGlowBorder:Hide()
										end
									end									
									
									if (widget.QuestType == QUESTTYPE_ARTIFACTPOWER) then
										total_APower = total_APower + widget.Amount
										tinsert (WorldQuestTracker.Cache_ShownQuestOnWorldMap [WQT_QUESTTYPE_APOWER], questID)
									elseif (widget.QuestType == QUESTTYPE_GOLD) then
										total_Gold = total_Gold + widget.Amount
										tinsert (WorldQuestTracker.Cache_ShownQuestOnWorldMap [WQT_QUESTTYPE_GOLD], questID)
									elseif (widget.QuestType == QUESTTYPE_RESOURCE) then
										total_Resources = total_Resources + widget.Amount
										tinsert (WorldQuestTracker.Cache_ShownQuestOnWorldMap [WQT_QUESTTYPE_RESOURCE], questID)
									end
									
									--party shared (world)
									if (WorldQuestTracker.IsPartyQuest (questID)) then
										widget.partySharedBlip:Show()
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
									widget.Amount = 0
									
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
									
									if (not isUsingTracker) then
										if (WorldQuestTracker.IsQuestOnObjectiveTracker (questID)) then
											widget.trackingGlowBorder:Show()
										else
											widget.trackingGlowBorder:Hide()
										end
									else
										if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
											widget.trackingGlowBorder:Show()
										else
											widget.trackingGlowBorder:Hide()
										end
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
										
									elseif (worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON) then
										widget.questTypeBlip:Show()
										widget.questTypeBlip:SetTexture ([[Interface\Scenarios\ScenarioIcon-Boss]])
										widget.questTypeBlip:SetTexCoord (0, 1, 0, 1)
										widget.questTypeBlip:SetAlpha (.80)
										
									else
										widget.questTypeBlip:Hide()
									end
									
									--party shared (world)
									if (WorldQuestTracker.IsPartyQuest (questID)) then
										widget.partySharedBlip:Show()
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
										widget.Amount = gold
										total_Gold = total_Gold + gold
										tinsert (WorldQuestTracker.Cache_ShownQuestOnWorldMap [WQT_QUESTTYPE_GOLD], questID)
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
										widget.Amount = numRewardItems
										total_Resources = total_Resources + numRewardItems
										tinsert (WorldQuestTracker.Cache_ShownQuestOnWorldMap [WQT_QUESTTYPE_RESOURCE], questID)
										okey = true
									
									elseif (itemName) then
										if (isArtifact) then
											local artifactIcon = WorldQuestTracker.GetArtifactPowerIcon (artifactPower)
											
											if (research_timeLeft and research_timeLeft < timeLeft) then
												widget.texture:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blueT]])
												hasArtifactUnderpower = true
											else
												widget.texture:SetTexture (artifactIcon)
											end
											
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
											widget.Amount = artifactPower
											tinsert (WorldQuestTracker.Cache_ShownQuestOnWorldMap [WQT_QUESTTYPE_APOWER], questID)
											total_APower = total_APower + artifactPower
										else
											widget.texture:SetTexture (itemTexture)
											--WorldQuestTracker.SetIconTexture (widget.texture, itemTexture, false, false)
											--widget.texture:SetTexCoord (0, 1, 0, 1)
											if (itemLevel > 600 and itemLevel < 780) then
												itemLevel = 810
											end
											
											local color = ""
											if (quality == 4 or quality == 3) then
												color =  WorldQuestTracker.RarityColors [quality]
											end
											widget.amountText:SetText ((isStackable and quantity and quantity >= 1 and quantity or false) or (itemLevel and itemLevel > 5 and (color) .. itemLevel) or "")

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
			
--			for i = taskIconIndex, 20 do
--				widgets[i]:Hide()
--			end
		else
			if (not taskInfo) then
				needAnotherUpdate = true
			else
--				for i = taskIconIndex, 20 do
--					widgets[i]:Hide()
--				end
			end
		end
		
		--quantidade de quest para a faccao
		configTable.factionFrame.amount = factionAmountForEachMap [mapId]
	end
	
	if (WorldQuestTracker.WorldMap_GoldIndicator) then
		WorldQuestTracker.WorldMap_GoldIndicator.text = floor (total_Gold / 10000)
		WorldQuestTracker.WorldMap_ResourceIndicator.text = WorldQuestTracker.ToK (total_Resources)
		WorldQuestTracker.WorldMap_APowerIndicator.text = WorldQuestTracker.ToK (total_APower)
		WorldQuestTracker.WorldMap_APowerIndicator.Amount = total_APower
		
		if (hasArtifactUnderpower) then
			WorldQuestTracker.WorldMap_APowerIndicator.textcolor = "darkorange"
		end
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
	
	--> update na ancora caso foi de window mode para fullscreen
	WorldQuestTracker.UpdateAllWorldMapAnchors()
	
	
	--factions - desativado por causa do novo metodo de ancora
	
	--[=[
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
	--]=]
	
	
	--[[
	if (ElvUI and ElvDB and IsAddOnLoaded ("ElvUI") and ElvDB.global and ElvDB.global.general) then
	
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
	--]]
	
	WorldQuestTracker.HideZoneWidgets()
	WorldQuestTracker.SavedQuestList_CleanUp()
	
	calcPerformance.DumpTime = 0
end

--quando clicar no botão de por o world map em fullscreen ou window mode, reajustar a posição dos widgets
WorldMapFrameSizeDownButton:HookScript ("OnClick", function() --window mode
	if (WorldQuestTracker.UpdateWorldQuestsOnWorldMap) then
		if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
			WorldQuestTracker.RefreshStatusBar()
			C_Timer.After (1, WorldQuestTracker.RefreshStatusBar)
		end
	end
end)
WorldMapFrameSizeUpButton:HookScript ("OnClick", function() --full screen
	if (WorldQuestTracker.UpdateWorldQuestsOnWorldMap) then
		if (GetCurrentMapAreaID() == MAPID_BROKENISLES) then
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
			C_Timer.After (1, WorldQuestTracker.RefreshStatusBar)
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

--> do not switch the map if we are in the world map
--world quest tracker is replacing the function "FindBestMapForSelectedBounty"
--if you need to use this function, call directly from the mixin: WorldMapBountyBoardMixin.FindBestMapForSelectedBounty
--or WorldQuestTrackerAddon.FindBestMapForSelectedBounty_Original()

WorldQuestTracker.FindBestMapForSelectedBounty_Original = WorldMapFrame.UIElementsFrame.BountyBoard.FindBestMapForSelectedBounty
WorldMapFrame.UIElementsFrame.BountyBoard.FindBestMapForSelectedBounty = function()end

hooksecurefunc (WorldMapFrame.UIElementsFrame.BountyBoard, "OnTabClick", function (...)
	if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
		WorldQuestTracker.FindBestMapForSelectedBounty_Original (...)
		WorldQuestTracker.LastMapID = GetCurrentMapAreaID()
		C_Timer.After (1, WorldQuestTracker.UpdateZoneWidgets)
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