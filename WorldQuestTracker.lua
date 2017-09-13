hooksecurefunc ("WorldMap_ResetPOI", function (...)
	---print (...)
end)

--/dump BrokenIslesArgusButton:IsProtected()

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
	DF:NewColor ("WQT_ORANGE_YELLOW_RARE_TITTLE", 1, 0.677059, 0.05, 1)
	
	DF:InstallTemplate ("font", "WQT_SUMMARY_TITLE", {color = "orange", size = 12, font = "Friz Quadrata TT"})
	DF:InstallTemplate ("font", "WQT_RESOURCES_AVAILABLE", {color = {1, .7, .2, .85}, size = 10, font = "Friz Quadrata TT"})
	DF:InstallTemplate ("font", "WQT_GROUPFINDER_BIG", {color = {1, .7, .2, .85}, size = 11, font = "Friz Quadrata TT"})
	DF:InstallTemplate ("font", "WQT_GROUPFINDER_SMALL", {color = {1, .9, .1, .85}, size = 10, font = "Friz Quadrata TT"})
	DF:InstallTemplate ("font", "WQT_GROUPFINDER_TRANSPARENT", {color = {1, 1, 1, .2}, size = 10, font = "Friz Quadrata TT"})
	DF:InstallTemplate ("font", "WQT_TOGGLEQUEST_TEXT", {color = {0.811, 0.626, .109}, size = 10, font = "Friz Quadrata TT"})
	
	DF:InstallTemplate ("button", "WQT_GROUPFINDER_BUTTON", {
		backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true},
		backdropcolor = {.2, .2, .2, 1},
		backdropbordercolor = {0, 0, 0, 1},
		width = 20,
		height = 20,
		enabled_backdropcolor = {.2, .2, .2, 1},
		disabled_backdropcolor = {.2, .2, .2, 1},
		onenterbordercolor = {0, 0, 0, 1},
	})
	
end

local GameCooltip = GameCooltip2
--local Saturate = Saturate
local floor = floor
--local ceil = ceil
--local ipairs = ipairs
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
		
		groupfinder = {
			enabled = true,
			invasion_points = true,
			tracker_buttons = true,
			autoleave = false,
			autoleave_delayed = false,
			askleave_delayed = true,
			noleave = false,
			leavetimer = 30,
			noafk = true,
			noafk_ticks = 5,
			nopvp = false,
			frame = {},
			tutorial = 0,
		},

		rarescan = {
			show_icons = true,
			alerts_anywhere = false,
			join_channel = false,
			search_group = true,
			recently_spotted = {},
			recently_killed = {},
			name_cache = {},
			playsound = true,
			playsound_volume = 2,
			use_master = true,
			always_use_english = true,
		},
		
		disable_world_map_widgets = false,
		worldmap_widgets = {
			textsize = 9,
			scale = 1,
		},
		zonemap_widgets = {
			scale = 1,
		},
		filter_always_show_faction_objectives = true,
		filter_force_show_brokenshore = true,
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
		zone_only_tracked = false,
		bar_anchor = "bottom",
		use_old_icons = false,
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

--zones which aren't quest hubs
local zones_with_worldquests = {
	[azsuna_mapId] = true,
	[highmountain_mapId] = true,
	[stormheim_mapId] = true,
	[suramar_mapId] = true,
	[valsharah_mapId] = true,
	[eoa_mapId] = true,
	[1014] = true, --dalaran
	[1021] = true, --broken shore
	
	--> argus zones
	[1171] = true, --antoran
	[1135] = true, --krokuun
	[1170] = true, --mccree
}

--patch 7.3
local is_argus_map = {
	[1171] = true, --antoran
	[1135] = true, --krokuun
	[1170] = true, --mccree
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
	[WQT_QUESTTYPE_PETBATTLE] = {name = L["S_QUESTTYPE_PETBATTLE"], icon = [[Interface\MINIMAP\ObjectIconsAtlas]], coords = {219/512, 246/512, 478/512, 502/512}},
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
WorldQuestTracker.CurrentZoneQuests = {}
WorldQuestTracker.CachedQuestData = {}
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
WorldQuestTracker.COMM_PREFIX = "WQTC"

local LibWindow = LibStub ("LibWindow-1.1")
if (not LibWindow) then
	print ("|cFFFFAA00World Quest Tracker|r: libwindow not found, did you just updated the addon? try reopening the client.|r")
end

WorldQuestTracker.MAPID_DALARAN = 1014
WorldQuestTracker.MAPID_ARGUS = 1184
WorldQuestTracker.MAPID_BROKENISLES = 1007
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

function WorldQuestTracker.ColorScaleByPercent (percent_scaled)
	local r, g
	percent_scaled = percent_scaled * 100
	if (percent_scaled < 50) then
		r = 255
	else
		r = math.floor ( 255 - (percent_scaled * 2 - 100) * 255 / 100)
	end
	
	if (percent_scaled > 50) then
		g = 255
	else
		g = math.floor ( (percent_scaled * 2) * 255 / 100)
	end
	
	return r, g
end

hooksecurefunc ("TaskPOI_OnEnter", function (self)
	--WorldMapTooltip:AddLine ("quest ID: " .. self.questID)
	--print (self.questID)
	WorldQuestTracker.CurrentHoverQuest = self.questID
	if (self.Texture and self.IsZoneQuestButton) then
		self.Texture:SetBlendMode ("ADD")
	end
end)

hooksecurefunc ("TaskPOI_OnLeave", function (self)
	WorldQuestTracker.CurrentHoverQuest = nil
	if (self.Texture and self.IsZoneQuestButton) then
		self.Texture:SetBlendMode ("BLEND")
	end
end)

function WorldQuestTracker.RareWidgetOnEnter (self)
	local parent = self:GetParent()
	
	if (parent.IsRare) then
		local t = time() - parent.RareTime
		local timeColor = abs ((t/3600)-1)
		timeColor = Saturate (timeColor)
		local colorR, colorG = WorldQuestTracker.ColorScaleByPercent (timeColor)
		
		GameCooltip:Preset (2)
		GameCooltip:SetOwner (self)
		
		GameCooltip:SetOption ("ButtonsYMod", -2)
		GameCooltip:SetOption ("YSpacingMod", -2)
		GameCooltip:SetOption ("IgnoreButtonAutoHeight", true)
		GameCooltip:SetOption ("TextSize", 10)
		GameCooltip:SetOption ("FixedWidth", false)
		
		GameCooltip:AddLine (parent.RareName, "", 1, "WQT_ORANGE_YELLOW_RARE_TITTLE", nil, 11)
		GameCooltip:AddLine (L["S_RAREFINDER_TOOLTIP_SPOTTEDBY"] .. ": ", "" .. (parent.RareOwner or ""))
		GameCooltip:AddLine ("" .. floor (t/60) .. ":" .. format ("%02.f", t%60) .. " " .. L["S_RAREFINDER_TOOLTIP_TIMEAGO"] .. "", "", 1, {colorR/255, colorG/255, 0})
		
		GameCooltip:Show()
		GameTooltip:Hide()
		
		if (not WorldMapFrame_InWindowedMode()) then
			GameCooltipFrame1:SetParent (WorldMapFrame)
			GameCooltipFrame1:SetFrameLevel (4000)
		end
		
		parent.TextureCustom:SetBlendMode ("ADD")
	end
	
end

function WorldQuestTracker.RareWidgetOnLeave (self)
	GameCooltip:Hide()
	if (not WorldMapFrame_InWindowedMode()) then
		GameCooltipFrame1:SetParent (UIParent)
	end
	self:GetParent().TextureCustom:SetBlendMode ("BLEND")
end


--enddebug

local all_widgets = {}
local extra_widgets = {}
local faction_frames = {}

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

function WorldQuestTracker.IsPartyQuest (questID)
	return WorldQuestTracker.PartySharedQuests [questID]
end

-- ~party ~share
local CreatePartySharer = function()
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
				if (WorldQuestTracker.IsWorldQuestHub (WorldMapFrame.mapID) or WorldQuestTracker.IsCurrentMapQuestHub()) then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, false) --noCache, showFade, isQuestFlaggedRecheck, forceCriteriaAnimation
				else
					if (WorldQuestTracker.ZoneHaveWorldQuest()) then
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
	--WorldQuestTracker:RegisterComm (WorldQuestTracker.COMM_PREFIX, "CommReceived")

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
		WorldQuestTracker:SendCommMessage (WorldQuestTracker.COMM_PREFIX, data, "PARTY")
	end

	local group_changed = function (loggedIn)
		if (CanShareQuests()) then
			if (loggedIn) then
				--> precisa pedir as quests dos demais membros do grupo
				--> pode dar return pois ele vai enviar para si mesmo
				local data = LibStub ("AceSerializer-3.0"):Serialize ("L")
				WorldQuestTracker:SendCommMessage (WorldQuestTracker.COMM_PREFIX, data, "PARTY")
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
			if (WorldQuestTracker.IsWorldQuestHub (WorldMapFrame.mapID) or WorldQuestTracker.IsCurrentMapQuestHub()) then
				WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, false) --noCache, showFade, isQuestFlaggedRecheck, forceCriteriaAnimation
			else
				if (WorldQuestTracker.ZoneHaveWorldQuest()) then
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

--isnt' baing used on 7.3, should be removed?
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

function WorldQuestTracker.Debug (message, color)
	if (WorldQuestTracker.debug) then
		if (color == 1) then
			print ("|cFFFFFF44[WQT]|r", "|cFFDDDDDD(debug)|r", "|cFFFF8800" .. message .. "|r")
		elseif (color == 2) then
			print ("|cFFFFFF44[WQT]|r", "|cFFDDDDDD(debug)|r", "|cFFFFFF00" .. message .. "|r")
		else
			print ("|cFFFFFF44[WQT]|r", "|cFFDDDDDD(debug)|r", message)
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
	
	local SharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
	SharedMedia:Register ("statusbar", "Iskar Serenity", [[Interface\AddOns\WorldQuestTracker\media\bar_serenity]])
	
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
	--C_Timer.After (10, CreatePartySharer) --disabled for now
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
	C_Timer.After (11, WorldQuestTracker.RequestRares)
	C_Timer.After (12, WorldQuestTracker.CheckForOldRareFinderData)
	
	local canLoad = IsQuestFlaggedCompleted (WORLD_QUESTS_AVAILABLE_QUEST_ID)
	
	local re_ZONE_CHANGED_NEW_AREA = function()
		WorldQuestTracker:ZONE_CHANGED_NEW_AREA()
	end
	
	function WorldQuestTracker.IsInvasionPoint()
		local mapFileName = GetMapInfo()
		--> we are using where the map file name which always start with "InvasionPoint"
		--> this makes easy to localize group between different languages on the group finder
		--> this won't work with greater invasions which aren't scenarios
		if (mapFileName and mapFileName:find ("InvasionPoint")) then
			--the player is inside a invasion
			local invasionName = C_Scenario.GetInfo()
			if (invasionName) then
				--> can queue?
				if (not IsInGroup() and not QueueStatusMinimapButton:IsShown()) then
					--> is search for invasions enabled?
					if (WorldQuestTracker.db.profile.groupfinder.invasion_points) then
						--WorldQuestTracker.FindGroupForCustom (mapFileName, invasionName, "click to search for groups")
						local callback = nil
						local ENNameFromMapFileName = mapFileName:gsub ("InvasionPoint", "")
						if (ENNameFromMapFileName and WorldQuestTracker.db.profile.rarescan.always_use_english) then
							WorldQuestTracker.FindGroupForCustom ("Invasion Point: " .. (ENNameFromMapFileName or ""), invasionName, L["S_GROUPFINDER_ACTIONS_SEARCH"], "Doing Invasion Point " .. invasionName .. ". Group created with World Quest Tracker #EN Invasion Point: " .. (ENNameFromMapFileName or "") .. " ", callback)
						else
							WorldQuestTracker.FindGroupForCustom (invasionName, invasionName, L["S_GROUPFINDER_ACTIONS_SEARCH"], "Doing Invasion Point " .. invasionName .. ". Group created with World Quest Tracker #EN Invasion Point: " .. (ENNameFromMapFileName or "") .. " ", callback)
						end
					end
				end					
			end
		end
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
		
		local mapFileName = GetMapInfo()
		if (not mapFileName) then
			C_Timer.After (3, WorldQuestTracker.IsInvasionPoint)
		else
			WorldQuestTracker.IsInvasionPoint()
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

--does the the zone have world quests?
function WorldQuestTracker.ZoneHaveWorldQuest (mapID)
	return zones_with_worldquests [mapID or GetCurrentMapAreaID()]
end

--is a argus zone?
function WorldQuestTracker.IsArgusZone (mapID)
	return is_argus_map [mapID]
end

--is the current map zone a world quest hub?
function WorldQuestTracker.IsWorldQuestHub (mapID)
	return mapID == WorldQuestTracker.MAPID_ARGUS or mapID == WorldQuestTracker.MAPID_BROKENISLES
end
function WorldQuestTracker.IsCurrentMapQuestHub()
	local currentMap = GetCurrentMapAreaID()
	return currentMap == WorldQuestTracker.MAPID_BROKENISLES or currentMap == WorldQuestTracker.MAPID_ARGUS
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

--> ~comm
--> ~rare ~finder ~groupfinder

--finder frame
local ff = CreateFrame ("frame", nil, UIParent)
ff:SetSize (240, 100)
ff:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
ff:SetBackdropColor (0, 0, 0, 1)
ff:SetBackdropBorderColor (0, 0, 0, 1)
ff:SetPoint ("center")
ff:EnableMouse (true)
ff:SetMovable (true)
ff:Hide()

-- /run WorldQuestTrackerAddon.debug = true;

--> rare finder frame
local rf = CreateFrame ("frame", nil, UIParent)
rf:RegisterEvent ("VIGNETTE_ADDED")
rf:RegisterEvent ("PLAYER_TARGET_CHANGED")

rf.RecentlySpotted = {}
rf.LastPartyRareShared = 0
rf.FullRareListSendCooldown = 0
rf.CommGlobalCooldown = 0
rf.RareSpottedSendCooldown = {}
rf.MinimapScanCooldown = {}

rf.RaresToScan = {
	[126338] = true, --wrathlord yarez
	[126852] = true, --wrangler kravos
	[122958] = true, --blistermaw
	[127288] = true, --houndmaster kerrax
	[126912] = true, --skreeg the devourer
	[126867] = true, --venomtail skyfin
	[126862] = true, --baruut the bloodthirsty
	[127703] = true, --doomcaster suprax
	[126900] = true, --instructor tarahna
	[126860] = true, --kaara the pale
	[126419] = true, --naroua
	[126898] = true, --sabuul
	[126208] = true, --varga
	[127705] = true, --mother rosula
	[127706] = true, --rezira the seer
	[123464] = true, --sister subversia
	[127700] = true, --squadron commander vishax
	[127581] = true, --the many faced devourer
	[126887] = true, --ataxon
	[126338] = true, --wrath lord yarez
	[127090] = true, --admiral relvar
	[120393] = true, --siegemaster voraan
	[127096] = true, --all seer xanarian
	[126199] = true, --vrax-thul
	[127376] = true, --chief alchemist munculus
	[127300] = true, --void warden valsuran
	[125820] = true, --imp mother laglath
	[125388] = true, --vagath the betrayed
	[123689] = true, --talestra the vile
	[127118] = true, --worldsplitter skuul
	[124804] = true, --tereck the selector
	[125479] = true, --tar spitter
	[122911] = true, --commander vecaya
	[125824] = true, --khazaduum
	[122912] = true, --commander sathrenael
	[124775] = true, --commander endaxis
	[127704] = true, --soultender videx
	[126040] = true, --puscilla
	[127291] = true, --watcher aival
	[127090] = true, --admiral relvar
	[122999] = true, --garzoth
	[122947] = true, --mistress ilthendra
	[127581] = true, --the many faced devourer
	[126115] = true, --venorn
	[126254] = true, --lieutenant xakaar
	[127084] = true, --commander texlaz
	[126946] = true, --inquisitor vethroz
	[126865] = true, --vigilant thanos
	[126869] = true, --captain faruq
	[126896] = true, --herald of chaos
	[126899] = true, --jedhin champion vorusk
	[125497] = true, --overseer ysorna
	[126910] = true, --commander xethgar
	[126913] = true, --slithon the last
	[122838] = true, --shadowcaster voruun
	[126815] = true, --soultwisted monstrosity
	[126864] = true, --feasel the muffin thief
	[126866] = true, --vigilant kuro
	[126868] = true, --turek the lucid
	[126885] = true, --umbraliss
	[126889] = true, --sorolis the ill fated
	[124440] = true, --overseer ybeda
	[125498] = true, --overseer ymorna
	[126908] = true, --zultan the numerous	
}

--> greater invasion point
rf.InvasionBosses = {
	[124625] = true, --mistress alluradel
	[124514] = true, --matron folnuna
	[124555] = true, --sotanathor
	[124492] = true, --occularus
	[124592] = true, --inquisitor meto
	[124719] = true, --pit lord vilemus
}
	
--> filling the list, getting the thingies from here: http://www.wowhead.com/achievement=12078/commander-of-argus#comments
rf.RaresLocations = {
	[126852] = {x = 55.7, y = 59.9}, --wrangler kravos
	[122958] = {x = 61.7, y = 37.2}, --blistermaw
	[127288] = {x = 63.1, y = 25.2}, --houndmaster kerrax
	[126912] = {x = 49.7, y = 9.9}, --skreeg the devourer
	[126867] = {x = 33.7, y = 47.5}, --venomtail skyfin
	[126862] = {x = 43.8, y = 60.2}, --baruut the bloodthirsty
	[127703] = {x = 58.50, y = 11.75}, --doomcaster suprax
	[126900] = {x = 61.4, y = 50.2}, --instructor tarahna
	[126860] = {x = 38.7, y = 55.8}, --kaara the pale
	[126419] = {x = 70.5, y = 33.7}, --naroua
	[126898] = {x = 44.2, y = 49.8}, --sabuul
	[126208] = {x = 64.3, y = 48.2}, --varga
	[127705] = {x = 65.5, y = 26.6}, --mother rosula
	[127706] = {x = 0, y = 0}, --rezira the seer (no coords?)
	[123464] = {x = 53.4, y = 30.9}, --sister subversia
	[127700] = {x = 77.4, y = 74.9}, --squadron commander vishax
	[126887] = {x = 30.3, y = 40.4}, --ataxon
	[126338] = {x = 61.9, y = 64.3}, --wrath lord yarez
	[120393] = {x = 58.0, y = 74.8}, --siegemaster voraan
	[127096] = {x = 75.6, y = 56.5}, --all seer xanarian
	[126199] = {x = 53.1, y = 35.8}, --vrax-thul
	[127376] = {x = 60.9, y = 22.9}, --chief alchemist munculus
	[127300] = {x = 55.7, y = 21.9}, --void warden valsuran
	[125820] = {x = 41.7, y = 70.2}, --imp mother laglath
	[125388] = {x = 60.8, y = 20.8}, --vagath the betrayed
	[123689] = {x = 55.5, y = 80.2}, --talestra the vile
	[127118] = {x = 50.9, y = 55.3}, --worldsplitter skuul
	[124804] = {x = 69.6, y = 57.5}, --tereck the selector
	[125479] = {x = 69.7, y = 80.5}, --tar spitter
	[122911] = {x = 	42.0, y = 57.1}, --commander vecaya
	[125824] = {x = 50.3, y = 17.3}, --khazaduum
	[122912] = {x = 33.0, y = 76.0}, --commander sathrenael
	[124775] = {x = 44.5, y = 58.7}, --commander endaxis
	[127704] = {x = 0, y = 0}, --soultender videx (no coords?)
	[126040] = {x = 65.6, y = 26.6}, --puscilla
	[127291] = {x = 52.7, y = 29.5}, --watcher aival
	[127090] = {x = 73.2, y = 70.8}, --admiral relvar
	[122999] = {x = 56.2, y = 45.5}, --garzoth
	[122947] = {x = 57.4, y = 32.9}, --mistress ilthendra
	[127581] = {x = 54.7, y = 39.1}, --the many faced devourer
	[126115] = {x = 62.9, y = 57.2}, --venorn
	[126254] = {x = 62.4, y = 53.8}, --lieutenant xakaar
	[127084] = {x = 80.5, y = 62.8}, --commander texlaz
	[126946] = {x = 61.1, y = 45.7}, --inquisitor vethroz
	[126865] = {x = 36.3, y = 23.6}, --vigilant thanos
	[126869] = {x = 27.2, y = 29.8}, --captain faruq
	[126896] = {x = 35.5, y = 58.7}, --herald of chaos
	[126899] = {x = 48.5, y = 40.9}, --jedhin champion vorusk
	[125497] = {x = 58.0, y = 30.9}, --overseer ysorna
	[126910] = {x = 56.8, y = 14.5}, --commander xethgar
	[126913] = {x = 49.5, y = 52.8}, --slithon the last
	[122838] = {x = 44.6, y = 71.6}, --shadowcaster voruun
	[126815] = {x = 65.3, y = 67.5}, --soultwisted monstrosity
	[126864] = {x = 41.3, y = 11.6}, --feasel the muffin thief
	[126866] = {x = 63.8, y = 64.6}, --vigilant kuro
	[126868] = {x = 39.2, y = 66.6}, --turek the lucid
	[126885] = {x = 35.2, y = 37.2}, --umbraliss
	[126889] = {x = 70.4, y = 46.7}, --sorolis the ill fated
	[124440] = {x = 59.2, y = 37.7}, --overseer ybeda
	[125498] = {x = 60.4, y = 29.7}, --overseer ymorna
	[126908] = {x = 64.0, y = 29.5}, --zultan the numerous	
}

--quest ids from here: https://docs.google.com/spreadsheets/d/1XkHTaTiiBC-4NHvBzAtqbRMOrOy6B9Silg17g4eSqlM/edit?usp=sharing
rf.RaresQuestIDs = {
	[126338] = 48814, --wrathlord yarez
	[126852] = 48695, --wrangler kravos
	[122958] = 49183, --blistermaw
	[127288] = 48821, --houndmaster kerrax
	[126912] = 48721, --skreeg the devourer
	[126867] = 48705, --venomtail skyfin
	[126862] = 48700, --baruut the bloodthirsty
	[127703] = 48968, --doomcaster suprax
	[126900] = 48718, --instructor tarahna
	[126860] = 48697, --kaara the pale
	[126419] = 48667, --naroua
	[126898] = 48712, --sabuul
	[126208] = 48812, --varga
	[127705] = 48970, --mother rosula
	[127706] = 48971, --rezira the seer
	[123464] = 48565, --sister subversia
	[127700] = 48967, --squadron commander vishax
	[127581] = 48966, --the many faced devourer
	[126887] = 48709, --ataxon
	[126338] = 48814, --wrath-lord yarez
	[127090] = 48817, --admiral relvar
	[120393] = 48627, --siegemaster voraan
	[127096] = 48818, --all seer xanarian
	[126199] = 48810, --vrax-thul
	[127376] = 48865, --chief alchemist munculus
	[127300] = 48824, --void warden valsuran
	[125820] = 48666, --imp mother laglath
	[125388] = 48629, --vagath the betrayed
	[123689] = 48628, --talestra the vile
	[127118] = 48820, --worldsplitter skuul
	[124804] = 48664, --tereck the selector
	[125479] = 48665, --tar spitter
	[122911] = 48563, --commander vecaya
	[125824] = 48561, --khazaduum
	[122912] = 48562, --commander sathrenael
	[124775] = 48564, --commander endaxis
	[127704] = 48969, --soultender videx
	[126040] = 48809, --puscilla
	[127291] = 48822, --watcher aival
	[122999] = 49241, --garzoth
	[122947] = 49240, --mistress ilthendra
	[126115] = 48811, --venorn
	[126254] = 48813, --lieutenant xakaar
	[127084] = 48816, --commander texlaz
	[126946] = 48815, --inquisitor vethroz
	[126865] = 48703, --vigilant thanos
	[126869] = 48707, --captain faruq
	[126896] = 48711, --herald of chaos
	[126899] = 48713, --jedhin champion vorusk
	[125497] = 48716, --overseer ysorna
	[126910] = 48720, --commander xethgar
	[126913] = 48936, --slithon the last
	[122838] = 48692, --shadowcaster voruun
	[126815] = 48693, --soultwisted monstrosity
	[126864] = 48702, --feasel the muffin thief
	[126866] = 48704, --vigilant kuro
	[126868] = 48706, --turek the lucid
	[126885] = 48708, --umbraliss
	[126889] = 48710, --sorolis the ill fated
	[124440] = 48714, --overseer ybeda
	[125498] = 48717, --overseer ymorna
	[126908] = 48719, --zultan the numerous	
}

rf.RaresENNames = {
	[126338] = "wrath-lord yarez",
	[126852] = "wrangler kravos",
	[122958] = "blistermaw",
	[127288] = "houndmaster kerrax",
	[126912] = "skreeg the devourer",
	[126867] = "venomtail skyfin",
	[126862] = "baruut the bloodthirsty",
	[127703] = "doomcaster suprax",
	[126900] = "instructor tarahna",
	[126860] = "kaara the pale",
	[126419] = "naroua",
	[126898] = "sabuul",
	[126208] = "varga",
	[127705] = "mother rosula",
	[127706] = "rezira the seer",
	[123464] = "sister subversia",
	[127700] = "squadron commander vishax",
	[127581] = "the many faced devourer",
	[126887] = "ataxon",
	[127090] = "admiral rel'var",
	[120393] = "siegemaster voraan",
	[127096] = "all-seer xanarian",
	[126199] = "vrax'thul",
	[127376] = "chief alchemist munculus",
	[127300] = "void warden valsuran",
	[125820] = "imp mother laglath",
	[125388] = "vagath the betrayed",
	[123689] = "talestra the vile",
	[127118] = "worldsplitter skuul",
	[124804] = "tereck the selector",
	[125479] = "tar spitter",
	[122911] = "commander vecaya",
	[125824] = "khazaduum",
	[122912] = "commander sathrenael",
	[124775] = "commander endaxis",
	[127704] = "soultender videx",
	[126040] = "puscilla",
	[127291] = "watcher aival",
	[127090] = "admiral relvar",
	[122999] = "gar'zoth",
	[122947] = "mistress il'thendra",
	[127581] = "the many faced devourer",
	[126115] = "ven'orn",
	[126254] = "lieutenant xakaar",
	[127084] = "commander texlaz",
	[126946] = "inquisitor vethroz",
	[126865] = "vigilant thanos",
	[126869] = "captain faruq",
	[126896] = "herald of chaos",
	[126899] = "jed'hin champion vorusk",
	[125497] = "overseer y'sorna",
	[126910] = "commander xethgar",
	[126913] = "slithon the last",
	[122838] = "shadowcaster voruun",
	[126815] = "soultwisted monstrosity",
	[126864] = "feasel the muffin thief",
	[126866] = "vigilant kuro",
	[126868] = "turek the lucid",
	[126885] = "umbraliss",
	[126889] = "sorolis the ill-fated",
	[124440] = "overseer y'beda",
	[125498] = "overseer y'morna",
	[126908] = "zul'tan the numerous",
	
	--world bosses
	[124625] = "mistress alluradel",
	[124514] = "matron folnuna",
	[124555] = "sotanathor",
	[124492] = "occularus",
	[124592] = "inquisitor meto",
	[124719] = "pit lord vilemus",
}

rf.COMM_IDS = {
	RARE_SPOTTED = "RS",
	RARE_REQUEST = "RR",
	RARE_LIST = "RL",
}

--> enum spotted comm indexes
rf.COMM_RARE_SPOTTED = {
	
	WHOSPOTTED = 2,
	SOURCECHANNEL = 3,
	RARENAME = 4,
	RARESERIAL = 5,
	MAPID = 6,
	PLAYERX = 7,
	PLAYERY = 8,
	ISRELIABLE = 9,
	LOCALTIME = 10,
}

--> enum rare list received comm indexes
rf.COMM_RARE_LIST = {
	--[1] PREFIX (always)
	WHOSENT = 2,
	RARELIST = 3,
	SOURCECHANNEL = 4,
}

--> enum raretable indexes
rf.RARETABLE = {
	TIMESPOTTED = 1;
	MAPID = 2;
	PLAYERX = 3;
	PLAYERY = 4;
	RARESERIAL = 5;
	RARENAME = 6;
	WHOSPOTTED = 7;
	SERVERTIME = 8;
}



function WorldQuestTracker.RequestRares()
	if (IsInGuild()) then
		if (WorldQuestTracker.db.profile.rarescan.show_icons) then
			local data = LibStub ("AceSerializer-3.0"):Serialize ({rf.COMM_IDS.RARE_REQUEST, UnitName ("player")})
			WorldQuestTracker:SendCommMessage (WorldQuestTracker.COMM_PREFIX, data, "GUILD")
			WorldQuestTracker.Debug ("RequestRares() > requested list of rares COMM_IDS.RARE_REQUEST")
		end
	end
end

function rf.SendRareList (channel)
	--> check if the list is in cooldown
	if (rf.FullRareListSendCooldown + 10 > time()) then
		WorldQuestTracker.Debug ("SendRareList () > cound't send full rare list: cooldown.")
		return
	end

	--> if this has been called from C_Timer, the param will be the ticker object
	if (type (channel) == "table") then
		channel = "GUILD"
	else
		channel = channel or "GUILD"
	end
	
	--> make sure the player is in a local group
	if (channel == "PARTY") then
		if (not IsInGroup (LE_PARTY_CATEGORY_HOME)) then
			WorldQuestTracker.Debug ("SendRareList () > player not in a home party, aborting rare sharing in the group.")
			return
		end
		
		--> if the player is in a raid, send the comm on the raid channel instead
		if (IsInRaid (LE_PARTY_CATEGORY_HOME)) then
			WorldQuestTracker.Debug ("SendRareList () > player is in raid, sending comm on RAID channel.")
			channel = "RAID"
		end
	end
	
	--> make sure the player is in a guild
	if (channel == "GUILD") then
		if (not IsInGuild()) then
			return
		end
	end

	--> build the list to be shared
	local data = LibStub ("AceSerializer-3.0"):Serialize ({rf.COMM_IDS.RARE_LIST, UnitName ("player"), WorldQuestTracker.db.profile.rarescan.recently_spotted, channel})
	WorldQuestTracker:SendCommMessage (WorldQuestTracker.COMM_PREFIX, data, channel)
	rf.FullRareListSendCooldown = time()
	WorldQuestTracker.Debug ("SendRareList () > sent list of rares > COMM_IDS.RARE_LIST on channel " .. (channel or "invalid channel"))
end

--/run WorldQuestTrackerAddon.debug = true;

function rf.ShareInWorldQuestParty()
	--> check if is realy in a world quest group
	if (IsInGroup (LE_PARTY_CATEGORY_HOME)) then
		if (time() > rf.LastPartyRareShared + 30) then
			rf.SendRareList ("PARTY")
			rf.LastPartyRareShared = time()
			WorldQuestTracker.Debug ("ShareInWorldQuestParty() > group updated, sending rare list to the party")
		end
	end
end

function rf.ScheduleGroupShareRares()
	if (rf.ShareRaresTimer_Party and not rf.ShareRaresTimer_Party._cancelled) then
		rf.ShareRaresTimer_Party:Cancel()
	end
	rf.ShareRaresTimer_Party = C_Timer.NewTimer (3, rf.ShareInWorldQuestParty)
end

function rf.ValidateCommData (validData, commType)
	if (commType == rf.COMM_IDS.RARE_SPOTTED) then
		if (not validData [2] or type (validData[2]) ~= "string") then --whoSpotted
			WorldQuestTracker.Debug ("ValidateCommData() > received invalid data on comm ID RARE_SPOTTED: [2]")
			return
		elseif (not validData [3] or type (validData[3]) ~= "string") then --sourceChannel
			WorldQuestTracker.Debug ("ValidateCommData() > received invalid data on comm ID RARE_SPOTTED: [3]")
			return
		elseif (not validData [4] or type (validData[4]) ~= "string") then --rareName
			WorldQuestTracker.Debug ("ValidateCommData() > received invalid data on comm ID RARE_SPOTTED: [4]")
			return
		elseif (not validData [5] or type (validData[5]) ~= "string") then --rareSerial
			WorldQuestTracker.Debug ("ValidateCommData() > received invalid data on comm ID RARE_SPOTTED: [5]")
			return
		elseif (not validData [6] or type (validData[6]) ~= "number") then --mapID
			WorldQuestTracker.Debug ("ValidateCommData() > received invalid data on comm ID RARE_SPOTTED: [6]")
			return
		elseif (not validData [7] or type (validData[7]) ~= "number") then --playerX
			WorldQuestTracker.Debug ("ValidateCommData() > received invalid data on comm ID RARE_SPOTTED: [7]")
			return
		elseif (not validData [8] or type (validData[8]) ~= "number") then --playerY
			WorldQuestTracker.Debug ("ValidateCommData() > received invalid data on comm ID RARE_SPOTTED: [8]")
			return
		end
	
		return true
	end
	
	if (commType == rf.COMM_IDS.RARE_LIST) then
		if (not validData [2] or type (validData[2]) ~= "string") then --whoSent
			WorldQuestTracker.Debug ("ValidateCommData() > received invalid data on comm ID RARE_LIST: [2]")
			return
		elseif (not validData [3] or type (validData[3]) ~= "table") then --theList
			WorldQuestTracker.Debug ("ValidateCommData() > received invalid data on comm ID RARE_LIST: [3]")
			return
		elseif (not validData [4] or type (validData[4]) ~= "string") then --channel
			WorldQuestTracker.Debug ("ValidateCommData() > received invalid data on comm ID RARE_LIST: [4]")
			return
		end
		
		return true
	end
end

function rf.HasValidTime (timeReceived)
	local currentTime = time()
	if (timeReceived+2400 < currentTime or currentTime+3600 < timeReceived) then
		return false
	end
	return true
end

--/run WorldQuestTrackerAddon.debug = true;
--WorldQuestTracker.debug = true;

function WorldQuestTracker:CommReceived (_, data)
	local dataReceived = {LibStub ("AceSerializer-3.0"):Deserialize (data)}

	if (dataReceived [1]) then
		local validData = dataReceived [2]
		
		local prefix = validData [1]
		
		if (prefix == rf.COMM_IDS.RARE_SPOTTED) then
			
			--> reliable from clicking on a rare or a rare spotted on the minimap
			--> not relible from party/raid sending to guild
			--> not reliable from party/raid spotted
			
			if (not rf.ValidateCommData (validData, rf.COMM_IDS.RARE_SPOTTED)) then
				return
			end
			
			local whoSpotted = validData [rf.COMM_RARE_SPOTTED.WHOSPOTTED]
			local sourceChannel = validData [rf.COMM_RARE_SPOTTED.SOURCECHANNEL]
			local rareName = validData [rf.COMM_RARE_SPOTTED.RARENAME]
			local rareSerial = validData [rf.COMM_RARE_SPOTTED.RARESERIAL]
			local mapID = validData [rf.COMM_RARE_SPOTTED.MAPID]
			local playerX = validData [rf.COMM_RARE_SPOTTED.PLAYERX]
			local playerY = validData [rf.COMM_RARE_SPOTTED.PLAYERY]
			local isReliable = validData [rf.COMM_RARE_SPOTTED.ISRELIABLE]
			local localTime = validData [rf.COMM_RARE_SPOTTED.LOCALTIME]
			
			--> local time is a new index, lock the spotted rare within a 1 hour timezone
			if (localTime and type (localTime) == "number") then
				if (not rf.HasValidTime (localTime)) then
					WorldQuestTracker.Debug ("CommReceived() > received a rare with an invalid time COMM_IDS.RARE_SPOTTED from " .. (whoSpotted or "invalid whoSpotted") .. " on " .. (sourceChannel or "invalid sourceChannel"), 2)
					return
				end
			end
			
			if (not localTime) then
				return
			end
			
			WorldQuestTracker.Debug ("CommReceived() > received spot COMM_IDS.RARE_SPOTTED from " .. (whoSpotted or "invalid whoSpotted") .. " on " .. (sourceChannel or "invalid sourceChannel"))
			rf.RareSpotted (whoSpotted, sourceChannel, rareName, rareSerial, mapID, playerX, playerY, isReliable, localTime)
			
		elseif (prefix == rf.COMM_IDS.RARE_REQUEST) then
			--> check if the request didn't came from the owner
			local whoRequested = validData [2]
			if (whoRequested == UnitName ("player")) then
				return
			end
			
			--> check if a timer already exists
			if (rf.ShareRaresTimer_Guild and not rf.ShareRaresTimer_Guild._cancelled) then
				return
			end
			
			--> assign a random timer to share, with that only 1 person of the guild will share
			rf.ShareRaresTimer_Guild = C_Timer.NewTimer (math.random (15), rf.SendRareList)
			WorldQuestTracker.Debug ("CommReceived() > received request COMM_IDS.RARE_REQUEST from " .. (whoRequested or "invalid whoRequested"))
			
		elseif (prefix == rf.COMM_IDS.RARE_LIST) then
			--> if received from someone else, cancel our share timer
			if (rf.ShareRaresTimer_Guild and not rf.ShareRaresTimer_Guild._cancelled) then
				rf.ShareRaresTimer_Guild:Cancel()
				rf.ShareRaresTimer_Guild = nil
			end
			
			if (not rf.ValidateCommData (validData, rf.COMM_IDS.RARE_LIST)) then
				return
			end
			
			--> add the rares to our list
			local whoSent = validData [rf.COMM_RARE_LIST.WHOSENT]
			local fromChannel = validData [rf.COMM_RARE_LIST.SOURCECHANNEL]
			
			WorldQuestTracker.Debug ("CommReceived() > received list COMM_IDS.RARE_LIST from " .. (whoSent or "invalid whoSent") .. " on " .. fromChannel)
			
			--> ignore if who sent is the player
			if (whoSent == UnitName ("player")) then
				WorldQuestTracker.Debug ("CommReceived() > the list is from the player it self, ignoring.")
				return
			end
			
			local rareList = validData [rf.COMM_RARE_LIST.RARELIST]
			
			--> list of rare spotted on the player that received the list
			local localList = WorldQuestTracker.db.profile.rarescan.recently_spotted
			
			local newRares, justUpdated = 0, 0
			
			--> iterate on the list received
			for npcId, receivedRareTable in pairs (rareList) do
				--> add to the name cache
				WorldQuestTracker.db.profile.rarescan.name_cache [receivedRareTable [rf.RARETABLE.RARENAME]] = npcId

				if (rf.HasValidTime (receivedRareTable [rf.RARETABLE.TIMESPOTTED])) then --> -40 min or +60 min
					--> check if rare already is in the player rare list
					local localRareTable = localList [npcId]
					if (localRareTable) then
						--> already exists
						if (receivedRareTable [rf.RARETABLE.TIMESPOTTED] > localRareTable [rf.RARETABLE.TIMESPOTTED] and (localRareTable [rf.RARETABLE.TIMESPOTTED]+900 > receivedRareTable [rf.RARETABLE.TIMESPOTTED])) then
							--> update the timer
							localRareTable [rf.RARETABLE.TIMESPOTTED] = receivedRareTable [rf.RARETABLE.TIMESPOTTED]
							localRareTable [rf.RARETABLE.WHOSPOTTED] = receivedRareTable [rf.RARETABLE.WHOSPOTTED]
							justUpdated = justUpdated + 1
						end
					else
						--> the local player doesn't have this rare - only accept if the rare has spotted up to 30min ago
						if (receivedRareTable [rf.RARETABLE.TIMESPOTTED] + 1800 > time()) then
							--> add it to the list if the rare was spotted up to 20 min ago
							localList [npcId] = receivedRareTable
							newRares = newRares + 1
							
							--> if the player doesn't have the rare and he received it from a party, broadcast the rare to his guild as a rare spotted
							if (IsInGuild() and (fromChannel == "PARTY" or fromChannel == "RAID")) then
								--> don't share if both players are in the same guild
								local guildName = GetGuildInfo (whoSent)
								if (guildName ~= GetGuildInfo ("player")) then
								
									--adding cooldown here won't share more than 1 rare
									
									--if (rf.CommGlobalCooldown + 10 > time()) then
									--	WorldQuestTracker.Debug ("CommReceived() > received a new rare from group, cannot share with the guild: comm on cooldown.", 1)
									--else
										local timeSpotted, mapID,  playerX, playerY, rareSerial, rareName, whoSpotted, serverTime = unpack (receivedRareTable)
										--> sending with the timesSpotted from the user who shared the rare location
										local data = LibStub ("AceSerializer-3.0"):Serialize ({rf.COMM_IDS.RARE_SPOTTED, whoSpotted, "GUILD", rareName, rareSerial, mapID, playerX, playerY, false, timeSpotted})
										WorldQuestTracker:SendCommMessage (WorldQuestTracker.COMM_PREFIX, data, "GUILD")
										WorldQuestTracker.Debug ("CommReceived() > received a new rare from group, shared within the guild.", 2)
										--rf.CommGlobalCooldown = time()
									--end
								end
							end
						else
							--print ("rare ignored:", receivedRareTable [rf.RARETABLE.RARENAME], receivedRareTable [rf.RARETABLE.TIMESPOTTED] - time())
						end
					end
				else
					--print ("rare ignored !HasValidTime():", receivedRareTable [rf.RARETABLE.RARENAME], receivedRareTable [rf.RARETABLE.TIMESPOTTED] - time())
				end
			end
			
			WorldQuestTracker.Debug ("CommReceived() > added: " .. newRares .. " updated: " .. justUpdated)
		end
	end
end
WorldQuestTracker:RegisterComm (WorldQuestTracker.COMM_PREFIX, "CommReceived")

function rf.GetMyNpcKilledList()
	local t = WorldQuestTracker.db.profile.rarescan.recently_killed
	local chrGUID = UnitGUID ("player")
	
	if (not chrGUID) then
		return
	end
	
	if (t [chrGUID]) then
		return t [chrGUID]
	else
		t [chrGUID] = {}
		return t [chrGUID]
	end
end

function rf.RareSpotted (whoSpotted, sourceChannel, rareName, rareSerial, mapID, playerX, playerY, isReliable, localTime)
	local npcId = WorldQuestTracker:GetNpcIdFromGuid (rareSerial)
	
	--> add to the name cache
	WorldQuestTracker.db.profile.rarescan.name_cache [rareName] = npcId
	
	--> announce on chat
	if (not rf.RecentlySpotted [npcId] or rf.RecentlySpotted [npcId] + 800 < time()) then
		--print ("|cFFFF9900WQT|r: rare '|cFFFFFF00" .. rareName .. "|r' spotted.")
		rf.RecentlySpotted [npcId] = time()
	end
	
	--> add to the rare table
	local rareTable = WorldQuestTracker.db.profile.rarescan.recently_spotted [npcId]
	if (not rareTable) then
		--> do not have any reference of this rare, add a new table
		rareTable = {isReliable and time() or (localTime or time()), mapID, playerX, playerY, rareSerial, rareName, whoSpotted, GetServerTime()}
		WorldQuestTracker.db.profile.rarescan.recently_spotted [npcId] = rareTable
		WorldQuestTracker.Debug ("RareSpotted() > added new npc: " .. rareName)
	else
		--> already have this rare, just update the time that has been spotted
		rareTable [rf.RARETABLE.TIMESPOTTED] = isReliable and time() or (localTime or time())
		rareTable [rf.RARETABLE.WHOSPOTTED] = whoSpotted
		rareTable [rf.RARETABLE.SERVERTIME] = GetServerTime()
		
		if (isReliable) then
			rareTable [rf.RARETABLE.PLAYERX] = playerX
			rareTable [rf.RARETABLE.PLAYERY] = playerY
		end
		WorldQuestTracker.Debug ("RareSpotted() > npc updated: " .. rareName)
	end
	
	if (time() > rf.CommGlobalCooldown+10) then
		--> if the rare information came from the party or raid, share the info with the guild
		if (sourceChannel == "PARTY" or sourceChannel == "RAID") then
			if (IsInGuild()) then
				local guildName1 = GetGuildInfo (whoSpotted)
				local guildName2 = GetGuildInfo ("player")
				
				WorldQuestTracker.Debug ("RareSpotted() > sourceChannel is group, trying to share with the guild.", guildName1 ~= guildName2)
				
				if (guildName1 ~= guildName2) then
					local data = LibStub ("AceSerializer-3.0"):Serialize ({rf.COMM_IDS.RARE_SPOTTED, whoSpotted, "GUILD", rareName, rareSerial, mapID, playerX, playerY, isReliable, localTime})
					--> check cooldown for this rare
					rf.RareSpottedSendCooldown [npcId] = rf.RareSpottedSendCooldown [npcId] or 0
					if (rf.RareSpottedSendCooldown [npcId] + 10 > time()) then
						WorldQuestTracker.Debug ("RareSpotted() > cound't send rare to guild: send is on cooldown.", 1)
						return
					end

					WorldQuestTracker:SendCommMessage (WorldQuestTracker.COMM_PREFIX, data, "GUILD")
					WorldQuestTracker.Debug ("RareSpotted() > successfully sent a rare from a group to player guild.", 2)
					rf.CommGlobalCooldown = time()
				end
			end
		
		--> if the information came from the guild, share with the group
		elseif (sourceChannel == "GUILD") then
			if (IsInGroup (LE_PARTY_CATEGORY_HOME) or IsInRaid (LE_PARTY_CATEGORY_HOME)) then
				--> do not want to share inside a dungeon, battleground or raid instance
				if (not IsInInstance()) then
					local channel = IsInRaid (LE_PARTY_CATEGORY_HOME) and "RAID" or "PARTY"
					local data = LibStub ("AceSerializer-3.0"):Serialize ({rf.COMM_IDS.RARE_SPOTTED, whoSpotted, channel, rareName, rareSerial, mapID, playerX, playerY, isReliable, localTime})
					WorldQuestTracker:SendCommMessage (WorldQuestTracker.COMM_PREFIX, data, channel)
					rf.CommGlobalCooldown = time()
				end
			end
		end
	else
		WorldQuestTracker.Debug ("RareSpotted() > cound't send rare: comm is on cooldown.", 1)
	end
end

function rf.IsRareAWorldQuest (rareName)
	--> get the cache of widgets currently shown on map
	local cache = WorldQuestTracker.Cache_ShownWidgetsOnZoneMap
	local isWorldQuest = false
	
	--> do the iteration
	for i = 1, #cache do 
		local widget = cache [i]
		if (widget.questName == rareName) then
			return true
		end
	end
end

--/run WorldQuestTrackerAddon.debug = true;

function rf.IsTargetARare()
	if (UnitExists ("target")) then
		local serial = UnitGUID ("target")
		local npcId = WorldQuestTracker:GetNpcIdFromGuid (serial)
		if (npcId) then
			--> check if is a non registered rare
			if (not rf.RaresToScan [npcId]) then
				if (WorldQuestTracker.IsArgusZone (GetCurrentMapAreaID())) then
					local unitClassification = UnitClassification ("target")
					if (unitClassification == "rareelite") then
						print ("|cFFFF9900[WQT]|r " .. L["S_RAREFINDER_NPC_NOTREGISTERED"] .. ":", UnitName ("target"), "NpcID:", npcId)
					end
				end
			end
			
			--> is a rare npc?
			if (rf.RaresToScan [npcId]) then
				--> check is the npc is flagged as rare
				local unitClassification = UnitClassification ("target")
				if (unitClassification == "rareelite") then --
					--> send comm
					local x, y = GetPlayerMapPosition ("player")
					local map = GetCurrentMapAreaID()
					local rareName = UnitName ("target")
					local data = LibStub ("AceSerializer-3.0"):Serialize ({rf.COMM_IDS.RARE_SPOTTED, UnitName ("player"), "GUILD", rareName, serial, map, x, y, true, time()})
					
					if (IsInGuild()) then
						--> check cooldown for this rare
						rf.RareSpottedSendCooldown [npcId] = rf.RareSpottedSendCooldown [npcId] or 0
						if (rf.RareSpottedSendCooldown [npcId] + 10 > time()) then
							WorldQuestTracker.Debug ("IsTargetARare() > cound't send rare spotted: cooldown.", 1)
							return
						end
						
						WorldQuestTracker:SendCommMessage (WorldQuestTracker.COMM_PREFIX, data, "GUILD")
						
						if (IsInGroup (LE_PARTY_CATEGORY_HOME) or IsInRaid (LE_PARTY_CATEGORY_HOME)) then
							WorldQuestTracker:SendCommMessage (WorldQuestTracker.COMM_PREFIX, data, IsInRaid (LE_PARTY_CATEGORY_HOME) and "RAID" or "PARTY")
							WorldQuestTracker.Debug ("IsTargetARare() > sent to the group as well.", 2)
						end
						
						rf.RareSpottedSendCooldown [npcId] = time()
					end
					
					--> add to the name cache
					WorldQuestTracker.db.profile.rarescan.name_cache [rareName] = npcId
					
					--
					rf:RegisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")
					rf.LastRareSerial = serial
					rf.LastRareName = rareName
					
					--find group or create a group for this rare
					if (not ff:IsShown() and not IsInGroup() and not QueueStatusMinimapButton:IsShown()) then --> is already searching?
						--> is search for group enabled?
						if (WorldQuestTracker.db.profile.rarescan.search_group) then
							--> check if the rare isn't a world quest
							local isWorldQuest = rf.IsRareAWorldQuest (rareName)
							if (not isWorldQuest) then
								local callback = nil
								--WorldQuestTracker.FindGroupForCustom (rareName, rareName, L["S_GROUPFINDER_ACTIONS_SEARCH_RARENPC"], "Doing rare encounter against " .. rareName .. ". Group create with World Quest Tracker #NPCID" .. npcId .. "#ENUS " .. (rf.RaresENNames [npcId] or "") .. " ", callback)
								local EnglishRareName = rf.RaresENNames [npcId]
								if (EnglishRareName and WorldQuestTracker.db.profile.rarescan.always_use_english) then
									WorldQuestTracker.FindGroupForCustom (EnglishRareName, rareName, L["S_GROUPFINDER_ACTIONS_SEARCH_RARENPC"], "Doing rare encounter against " .. rareName .. ". Group created with World Quest Tracker #NPCID" .. npcId .. "#LOC " .. (rareName or "") .. " ", callback)
								else
									WorldQuestTracker.FindGroupForCustom (rareName, rareName, L["S_GROUPFINDER_ACTIONS_SEARCH_RARENPC"], "Doing rare encounter against " .. rareName .. ". Group created with World Quest Tracker #NPCID" .. npcId .. "#LOC " .. (EnglishRareName or "") .. " ", callback)
								end
							end
						end
					end
				else
					WorldQuestTracker.Debug ("IsTargetARare() > unit isn't rareelite classification.")
				end
			else
				if (rf.InvasionBosses [npcId]) then
					--already searching?
					if (not ff:IsShown() and not IsInGroup() and not QueueStatusMinimapButton:IsShown()) then
						--> search for a group?
						if (WorldQuestTracker.db.profile.rarescan.search_group) then
							--> check if the rare isn't a world quest
							local rareName = UnitName ("target")
							local callback= nil
							
							local EnglishRareName = rf.RaresENNames [npcId]
							if (EnglishRareName and WorldQuestTracker.db.profile.rarescan.always_use_english) then
								WorldQuestTracker.FindGroupForCustom (EnglishRareName, rareName, L["S_GROUPFINDER_ACTIONS_SEARCH"], "Doing Argus World Boss against " .. rareName .. " Group created with World Quest Tracker #NPCID" .. npcId .. "#LOC " .. (rareName or "") .. " ", callback)
								WorldQuestTracker.Debug ("IsTargetARare() > invasion boss detected and using english name.")
							else
								WorldQuestTracker.FindGroupForCustom (rareName, rareName, L["S_GROUPFINDER_ACTIONS_SEARCH"], "Doing Invasion Point boss encounter against " .. rareName .. " Group created with World Quest Tracker #NPCID" .. npcId, callback)
								WorldQuestTracker.Debug ("IsTargetARare() > invasion boss detected and cannot english name.")
							end
						end
					end
				end
			end
		else
			WorldQuestTracker.Debug ("IsTargetARare() > invalid npcId.")
		end
	end
end

rf:SetScript ("OnEvent", function (self, event, ...)
	if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		local _, token, hidding, who_serial, who_name, who_flags, who_flags2, alvo_serial, alvo_name, alvo_flags, alvo_flags2 = ...
		if (token == "UNIT_DIED") then
			if (alvo_serial == rf.LastRareSerial) then
				--> current rare got killed
				rf.LastRareSerial = nil
				rf.LastRareName = nil
				rf:UnregisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")

				--> check if the group finder window is shown with the mob we just killed
				if (ff:IsShown()) then
					if (ff.Label1.text == alvo_name) then
						ff.HideMainFrame()
					end
				end
				
				--> ask to leave the group
				if (ff.Label1.text == alvo_name and ff.SearchCustom) then
					ff.WorldQuestFinished (0, true)
				end
				
				local killed = rf.GetMyNpcKilledList()
				if (not killed) then
					return
				else
					local npcId = WorldQuestTracker:GetNpcIdFromGuid (alvo_serial)
					if (npcId) then
						local resetTime = time() + GetQuestResetTime()
						killed [npcId] = resetTime
					end
				end
			end
		end
		
	elseif (event == "PLAYER_TARGET_CHANGED") then
		rf.IsTargetARare()
		
	elseif (event == "VIGNETTE_ADDED") then
		if (WorldQuestTracker.IsArgusZone (GetCurrentMapAreaID())) then
			rf.ScanMinimapForRares()
		end
	end
end)

WorldQuestTracker.RareWidgets = {}
function WorldQuestTracker.UpdateRareIcons (index, mapID)
	if (not WorldQuestTracker.db.profile.rarescan.show_icons) then
		return
	end
	
	local alreadyKilled = rf.GetMyNpcKilledList()
	if (not alreadyKilled) then
		--> player serial or database not available at the moment
		return
	end
	
	for npcId, rareTable in pairs (WorldQuestTracker.db.profile.rarescan.recently_spotted) do
		local timeSpotted = rareTable [rf.RARETABLE.TIMESPOTTED]
		if (timeSpotted + 3600 > time() and not alreadyKilled [npcId]) then
			local questCompleted = false
			local npcQuestCompletedID = rf.RaresQuestIDs [npcId]
			if (npcQuestCompletedID and IsQuestFlaggedCompleted (npcQuestCompletedID)) then
				questCompleted = true
			end

			local rareMapID = rareTable [rf.RARETABLE.MAPID]
			if (rareMapID == mapID and not questCompleted) then
			
				local rareName = rareTable [rf.RARETABLE.RARENAME]
			
				--> check if the rare isn't part of a world quest
				local isWorldQuest = rf.IsRareAWorldQuest (rareName)
				if (not isWorldQuest) then
				
					local positionX = rareTable [rf.RARETABLE.PLAYERX]
					local positionY = rareTable [rf.RARETABLE.PLAYERY]
					local rareSerial = rareTable [rf.RARETABLE.RARESERIAL]
					local rareOwner = rareTable [rf.RARETABLE.WHOSPOTTED]
					
					local widget = WorldQuestTracker.GetOrCreateZoneWidget (nil, index)
					WorldQuestTracker.ResetWorldQuestZoneButton (widget)
					index = index + 1
					
					widget.mapID = mapID
					widget.questID = 0
					widget.numObjectives = 0
					widget.Order = 0
					widget.IsRare = true
					widget.RareName = rareName
					widget.RareSerial = rareSerial
					widget.RareTime = timeSpotted
					widget.RareOwner = rareOwner
					
					widget.RareOverlay:Show()
					
					--widget.Texture:SetTexture ([[Interface\Scenarios\ScenarioIcon-Boss]])
					widget.TextureCustom:SetTexture ([[Interface\MINIMAP\ObjectIconsAtlas]])
					widget.TextureCustom:SetTexCoord (423/512, 447/512, 344/512, 367/512)
					widget.TextureCustom:SetSize (16, 16)
					widget.TextureCustom:Show()
					
					widget.Texture:Hide()
					
					local npcId = WorldQuestTracker:GetNpcIdFromGuid (rareSerial)
					local position = rf.RaresLocations [npcId]
					
					if (position and position.x ~= 0) then
						positionX = position.x/100;
						positionY = position.y/100;
					end
					
					WorldMapPOIFrame_AnchorPOI (widget, positionX, positionY, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.WORLD_QUEST)
					widget:Show()
					widget:SetFrameLevel (1400 + floor (random (1, 30)))
				end
			end
		end
	end
end

-- /dump WorldQuestTrackerAddon.db.profile.rarescan.recently_killed
function WorldQuestTracker.CheckForOldRareFinderData()
	--> check for daily reset timers
	local now = time()
	local t = WorldQuestTracker.db.profile.rarescan.recently_killed
	
	for playerSerial, timeTable in pairs (t) do
		--> is a valid player guid and table?
		if (type (playerSerial) == "string" and type (timeTable) == "table") then
			for npcId, timeLeft in pairs (timeTable) do
				if (timeLeft < now) then
					timeTable [npcId] = nil
					WorldQuestTracker.Debug ("CheckForOldRareFinderData > daily reset: " .. npcId)
				end
			end
		end
	end
	
	--> check for outdated spotted rares
	for npcId, rareTable in pairs (WorldQuestTracker.db.profile.rarescan.recently_spotted) do
		if (rareTable [rf.RARETABLE.TIMESPOTTED] + 3600 < now) then
			--> remove the npc from the list
			WorldQuestTracker.db.profile.rarescan.recently_spotted [npcId] = nil
			WorldQuestTracker.Debug ("CheckForOldRareFinderData > outdated entry removed: " .. rareTable [6] .. " ID: " .. npcId)
		end
	end
end

C_Timer.NewTicker (60, function (ticker)
	if (WorldQuestTracker.db and WorldQuestTracker.db.profile) then
		WorldQuestTracker.CheckForOldRareFinderData()
	end
end)

function rf.ScanMinimapForRares()
	if (not IsInGuild()) then
		return
	end
	for i = 1, C_Vignettes.GetNumVignettes() do
		local serial = C_Vignettes.GetVignetteGUID (i)
		if (serial) then
			local _, _, name, objectIcon = C_Vignettes.GetVignetteInfoFromInstanceID (serial)
			if (objectIcon and (objectIcon == 41 or objectIcon == 4733)) then
				local npcId = WorldQuestTracker.db.profile.rarescan.name_cache [name]
				if (npcId and rf.RaresToScan [npcId]) then
					if (not rf.MinimapScanCooldown [npcId] or rf.MinimapScanCooldown [npcId]+10 < time()) then
					
						--> make sure the spotted minimap rare isn't the player target
						local targetSerial = UnitGUID ("target") or ""
						local targetNpcId = WorldQuestTracker:GetNpcIdFromGuid (targetSerial)

						if (npcId ~= targetNpcId) then
							local x, y = GetPlayerMapPosition ("player")
							local map = GetCurrentMapAreaID()
							local rareName = name
							serial = "Creature-0-0000-0000-00000-" .. npcId .. "-0000000000"
							
							local data = LibStub ("AceSerializer-3.0"):Serialize ({rf.COMM_IDS.RARE_SPOTTED, UnitName ("player"), "GUILD", rareName, serial, map, x, y, true, time()})
							
							WorldQuestTracker:SendCommMessage (WorldQuestTracker.COMM_PREFIX, data, "GUILD")
							
							if (WorldQuestTracker.db.profile.rarescan.playsound) then
								PlaySoundFile ("Interface\\AddOns\\WorldQuestTracker\\media\\rare_found" .. WorldQuestTracker.db.profile.rarescan.playsound_volume .. ".ogg", WorldQuestTracker.db.profile.rarescan.use_master and "Master" or "SFX")
							end
							
							rf.MinimapScanCooldown [npcId] = time()
							
							WorldQuestTracker.Debug ("ScanMinimapForRares > added npc from minimap: " .. rareName .. " ID: " .. npcId)
						end
					end
				end
			end
		end
	end
end

--[=
	--~group
	--> the main frame
	
	ff.TickFrame = CreateFrame ("frame", nil, UIParent)
	
	--> titlebar
	ff.TitleBar = CreateFrame ("frame", "$parentTitleBar", ff)
	ff.TitleBar:SetPoint ("topleft", ff, "topleft", 2, -3)
	ff.TitleBar:SetPoint ("topright", ff, "topright", -2, -3)
	ff.TitleBar:SetHeight (20)
	ff.TitleBar:EnableMouse (false)
	ff.TitleBar:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	ff.TitleBar:SetBackdropColor (.2, .2, .2, 1)
	ff.TitleBar:SetBackdropBorderColor (0, 0, 0, .5)
	
	--close button
	ff.Close = CreateFrame ("button", "$parentCloseButton", ff)
	ff.Close:SetPoint ("right", ff.TitleBar, "right", -2, 0)
	ff.Close:SetSize (16, 16)
	ff.Close:SetNormalTexture (DF.folder .. "icons")
	ff.Close:SetHighlightTexture (DF.folder .. "icons")
	ff.Close:SetPushedTexture (DF.folder .. "icons")
	ff.Close:GetNormalTexture():SetTexCoord (0, 16/128, 0, 1)
	ff.Close:GetHighlightTexture():SetTexCoord (0, 16/128, 0, 1)
	ff.Close:GetPushedTexture():SetTexCoord (0, 16/128, 0, 1)
	ff.Close:SetAlpha (0.7)
	ff.Close:SetScript ("OnClick", function() ff.HideMainFrame() end)
	
	--gear button
	ff.Options = CreateFrame ("button", "$parentOptionsButton", ff)
	ff.Options:SetPoint ("right", ff.Close, "left", -2, 0)
	ff.Options:SetSize (16, 16)
	ff.Options:SetNormalTexture (DF.folder .. "icons")
	ff.Options:SetHighlightTexture (DF.folder .. "icons")
	ff.Options:SetPushedTexture (DF.folder .. "icons")
	ff.Options:GetNormalTexture():SetTexCoord (48/128, 64/128, 0, 1)
	ff.Options:GetHighlightTexture():SetTexCoord (48/128, 64/128, 0, 1)
	ff.Options:GetPushedTexture():SetTexCoord (48/128, 64/128, 0, 1)
	ff.Options:SetAlpha (0.7)
	
	--do the menu with cooltip injection
	ff.Options.SetEnabledFunc = function (_, _, value)
		WorldQuestTracker.db.profile.groupfinder.enabled = value
		if (value) then
			--check if is doing a world quest and popup the gump
			
		else
			--hide the current doing world quest
			--ff.ResetMembers()
			--ff.ResetInteractionButton()
			--ff.HideMainFrame()
		end
		
		GameCooltip:Hide()
	end
	
	ff.Options.SetAvoidPVPFunc = function (_, _, value)
		WorldQuestTracker.db.profile.groupfinder.nopvp = value
		GameCooltip:Hide()
	end
	
	ff.Options.SetNoAFKFunc = function (_, _, value)
		WorldQuestTracker.db.profile.groupfinder.noafk = value
		GameCooltip:Hide()
	end
	
	ff.Options.SetFindGroupForRares = function (_, _, value)
		WorldQuestTracker.db.profile.rarescan.search_group = value
		GameCooltip:Hide()
	end
	
	ff.Options.SetFindInvasionPoints = function (_, _, value)
		WorldQuestTracker.db.profile.groupfinder.invasion_points = value
		GameCooltip:Hide()
	end

	ff.Options.SetOTButtonsFunc = function (_, _, value)
		WorldQuestTracker.db.profile.groupfinder.tracker_buttons = value
		if (value) then
			--enabled
			WorldQuestTracker:FullTrackerUpdate()
		else
			--disabled
			for block, button in pairs (ff.BQuestTrackerUsedWidgets) do
				ff.RemoveButtonFromBBlock (block)
			end
		end
		GameCooltip:Hide()
	end
	
	ff.Options.SetAutoGroupLeaveFunc = function (_, _, value, key)
		WorldQuestTracker.db.profile.groupfinder.autoleave = false
		WorldQuestTracker.db.profile.groupfinder.autoleave_delayed = false
		WorldQuestTracker.db.profile.groupfinder.askleave_delayed = false
		WorldQuestTracker.db.profile.groupfinder.noleave = false
		
		WorldQuestTracker.db.profile.groupfinder [key] = true
		
		GameCooltip:Hide()
	end
	ff.Options.SetGroupLeaveTimeoutFunc = function (_, _, value)
		WorldQuestTracker.db.profile.groupfinder.leavetimer = value
		if (WorldQuestTracker.db.profile.groupfinder.autoleave) then
			WorldQuestTracker.db.profile.groupfinder.autoleave = false
			WorldQuestTracker.db.profile.groupfinder.askleave_delayed = true
		end
		GameCooltip:Hide()
	end
	
	ff.Options.BuildMenuFunc = function()
		GameCooltip:Preset (2)
		GameCooltip:SetOption ("TextSize", 10)
		GameCooltip:SetOption ("FixedWidth", 180)
		
		--enabled
		GameCooltip:AddLine (L["S_GROUPFINDER_ENABLED"])
		if (WorldQuestTracker.db.profile.groupfinder.enabled) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (1, ff.Options.SetEnabledFunc, not WorldQuestTracker.db.profile.groupfinder.enabled)
		
		--find group for rares
		GameCooltip:AddLine (L["S_GROUPFINDER_AUTOOPEN_RARENPC_TARGETED"])
		if (WorldQuestTracker.db.profile.rarescan.search_group) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (1, ff.Options.SetFindGroupForRares, not WorldQuestTracker.db.profile.rarescan.search_group)		
		
		--find invasion points
		GameCooltip:AddLine (L["S_GROUPFINDER_INVASION_ENABLED"])
		if (WorldQuestTracker.db.profile.groupfinder.invasion_points) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (1, ff.Options.SetFindInvasionPoints, not WorldQuestTracker.db.profile.groupfinder.invasion_points)
		
		
		--uses buttons on the quest tracker
		GameCooltip:AddLine (L["S_GROUPFINDER_OT_ENABLED"])
		if (WorldQuestTracker.db.profile.groupfinder.tracker_buttons) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (1, ff.Options.SetOTButtonsFunc, not WorldQuestTracker.db.profile.groupfinder.tracker_buttons)

		--
		GameCooltip:AddLine ("$div", nil, 1, nil, -5, -11)
		--
		
		GameCooltip:AddLine (L["S_GROUPFINDER_LEAVEOPTIONS"])
		GameCooltip:AddIcon ([[Interface\BUTTONS\UI-GROUPLOOT-PASS-DOWN]], 1, 1, IconSize, IconSize)
		
		--leave group
		GameCooltip:AddLine (L["S_GROUPFINDER_LEAVEOPTIONS_IMMEDIATELY"], "", 2)
		if (WorldQuestTracker.db.profile.groupfinder.autoleave) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (2, ff.Options.SetAutoGroupLeaveFunc, not WorldQuestTracker.db.profile.groupfinder.autoleave, "autoleave")
		
		GameCooltip:AddLine (L["S_GROUPFINDER_LEAVEOPTIONS_AFTERX"], "", 2)
		if (WorldQuestTracker.db.profile.groupfinder.autoleave_delayed) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (2, ff.Options.SetAutoGroupLeaveFunc, not WorldQuestTracker.db.profile.groupfinder.autoleave_delayed, "autoleave_delayed")
		
		GameCooltip:AddLine (L["S_GROUPFINDER_LEAVEOPTIONS_ASKX"], "", 2)
		if (WorldQuestTracker.db.profile.groupfinder.askleave_delayed) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (2, ff.Options.SetAutoGroupLeaveFunc, not WorldQuestTracker.db.profile.groupfinder.askleave_delayed, "askleave_delayed")
		
		GameCooltip:AddLine (L["S_GROUPFINDER_LEAVEOPTIONS_DONTLEAVE"], "", 2)
		if (WorldQuestTracker.db.profile.groupfinder.noleave) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (2, ff.Options.SetAutoGroupLeaveFunc, not WorldQuestTracker.db.profile.groupfinder.noleave, "noleave")
		
		--
		GameCooltip:AddLine ("$div", nil, 2, nil, -5, -11)
		--ask to leave with timeout
		GameCooltip:AddLine ("10 " .. L["S_GROUPFINDER_SECONDS"], "", 2)
		if (WorldQuestTracker.db.profile.groupfinder.leavetimer == 10) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (2, ff.Options.SetGroupLeaveTimeoutFunc, 10)
		
		GameCooltip:AddLine ("15 " .. L["S_GROUPFINDER_SECONDS"], "", 2)
		if (WorldQuestTracker.db.profile.groupfinder.leavetimer == 15) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (2, ff.Options.SetGroupLeaveTimeoutFunc, 15)
		
		GameCooltip:AddLine ("20 " .. L["S_GROUPFINDER_SECONDS"], "", 2)
		if (WorldQuestTracker.db.profile.groupfinder.leavetimer == 20) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (2, ff.Options.SetGroupLeaveTimeoutFunc, 20)
		
		GameCooltip:AddLine ("30 " .. L["S_GROUPFINDER_SECONDS"], "", 2)
		if (WorldQuestTracker.db.profile.groupfinder.leavetimer == 30) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (2, ff.Options.SetGroupLeaveTimeoutFunc, 30)
		
		GameCooltip:AddLine ("60 " .. L["S_GROUPFINDER_SECONDS"], "", 2)
		if (WorldQuestTracker.db.profile.groupfinder.leavetimer == 60) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (2, ff.Options.SetGroupLeaveTimeoutFunc, 60)
		
		GameCooltip:AddLine ("$div", nil, 1, nil, -5, -11)
		
		--no pvp realms
		GameCooltip:AddLine (L["S_GROUPFINDER_NOPVP"])
		if (WorldQuestTracker.db.profile.groupfinder.nopvp) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (1, ff.Options.SetAvoidPVPFunc, not WorldQuestTracker.db.profile.groupfinder.nopvp)
		
		--kick afk players
		GameCooltip:AddLine ("Kick AFKs")
		if (WorldQuestTracker.db.profile.groupfinder.noafk) then
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
		else
			GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
		end
		GameCooltip:AddMenu (1, ff.Options.SetNoAFKFunc, not WorldQuestTracker.db.profile.groupfinder.noafk)
		
	end
	
	ff.Options.CoolTip = {
		Type = "menu",
		BuildFunc = ff.Options.BuildMenuFunc,
		OnEnterFunc = function (self) end,
		OnLeaveFunc = function (self) end,
		FixedValue = "none",
		ShowSpeed = 0.05,
		Options = {
			["FixedWidth"] = 300,
		},
	}
	
	GameCooltip:CoolTipInject (ff.Options)
	
	--> illustrate the clickable box
	ff.ClickArea = CreateFrame ("frame", nil, ff)
	ff.ClickArea:SetPoint ("topleft", ff.TitleBar, "bottomleft", 0, -1)
	ff.ClickArea:SetPoint ("topright", ff.TitleBar, "bottomright", 0, -1)
	ff.ClickArea:SetHeight (74)
	ff.ClickArea:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	ff.ClickArea:SetBackdropColor (.2, .2, .2, .4)
	ff.ClickArea:SetBackdropBorderColor (0, 0, 0, .5)
	ff.ClickArea:EnableMouse (false)
	ff.ClickArea:SetFrameLevel (ff:GetFrameLevel()+1)
	
	--> interaction button
	local interactionButton = CreateFrame ("button", nil, ff)
	interactionButton:SetPoint ("topleft", ff, "topleft", 0, -20)
	interactionButton:SetPoint ("bottomright", ff, "bottomright", 0, 0)
	interactionButton:SetFrameLevel (ff:GetFrameLevel()+2)
	interactionButton:RegisterForClicks ("RightButtonDown", "LeftButtonDown")
	
	local secondaryInteractionButton = CreateFrame ("button", nil, ff)
	secondaryInteractionButton:SetPoint ("bottomright", ff, "bottomright", -5, 4)
	secondaryInteractionButton:SetWidth (100)
	secondaryInteractionButton:SetHeight (18)
	secondaryInteractionButton:SetFrameLevel (ff:GetFrameLevel()+4)
	secondaryInteractionButton:RegisterForClicks ("RightButtonDown", "LeftButtonDown")
	secondaryInteractionButton:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
	secondaryInteractionButton:SetBackdropColor (.2, .2, .2, 1)
	secondaryInteractionButton:SetBackdropBorderColor (0, 0, 0, 1)
	secondaryInteractionButton.ButtonText = DF:CreateLabel (secondaryInteractionButton, "placeholder", DF:GetTemplate ("font", "WQT_GROUPFINDER_SMALL"))
	secondaryInteractionButton.ButtonText:SetPoint ("CENTER", secondaryInteractionButton, "CENTER", 0, 0)
	secondaryInteractionButton:Hide()

	--title
	ff.Title = ff.TitleBar:CreateFontString ("$parentTitle", "overlay", "GameFontNormal")
	ff.Title:SetPoint ("center", ff.TitleBar, "center")
	ff.Title:SetTextColor (.8, .8, .8, 1)
	ff.Title:SetText ("World Quest Tracker")
	
	ff.AnchorFrame = CreateFrame ("frame", nil, ff)
	ff.AnchorFrame:SetAllPoints()
	ff.AnchorFrame:SetFrameLevel (ff:GetFrameLevel()+3)
	
	--> label 1
	ff.Label1 = DF:CreateLabel (ff.AnchorFrame, " ", DF:GetTemplate ("font", "WQT_GROUPFINDER_BIG"))
	ff.Label1:SetPoint (5, -30)
	
	--> label 2
	ff.Label2 = DF:CreateLabel (ff.AnchorFrame, " ", DF:GetTemplate ("font", "WQT_GROUPFINDER_SMALL"))
	ff.Label2:SetPoint (5, -47)
	
	--> label 3
	ff.Label3 = DF:CreateLabel (ff.AnchorFrame, L["S_GROUPFINDER_RIGHTCLICKCLOSE"], DF:GetTemplate ("font", "WQT_GROUPFINDER_TRANSPARENT"))
	ff.Label3:SetPoint ("bottomleft", ff, "bottomleft", 5, 4)
	
	--> progress bar
	ff.ProgressBar = DF:CreateBar (ff.AnchorFrame, nil, 230, 16, 50)
	ff.ProgressBar:SetPoint (5, -60)
	ff.ProgressBar.fontsize = 11
	ff.ProgressBar.fontface = "Accidental Presidency"
	ff.ProgressBar.fontcolor = "darkorange"
	ff.ProgressBar.color = "gray"	
	ff.ProgressBar:EnableMouse (false)
	
	function ff.ShowSecondaryInteractionButton (actionID, text)
		--> reset the button
		secondaryInteractionButton.ToSearch = nil
		secondaryInteractionButton.ToCreate = nil
		
		--> setup new variables
		secondaryInteractionButton.ButtonText:SetText (text)
		
		if (actionID == ff.actions.ACTIONTYPE_GROUP_SEARCH) then
			secondaryInteractionButton.ToSearch = true
			
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_CREATE) then
			secondaryInteractionButton.ToCreate = true
		end
		
		--> show it
		secondaryInteractionButton:Show()
	end
	
	function ff.HideSecondaryInteractionButton()
		secondaryInteractionButton:Hide()
	end
	
	--> feedback
	--[=
		ff.FeedbackFrame = CreateFrame ("button", nil, ff)
		ff.FeedbackFrame:SetPoint ("topleft", ff, "bottomleft", 0, -2)
		ff.FeedbackFrame:SetPoint ("topright", ff, "bottomright", 0, -2)
		ff.FeedbackFrame:SetHeight (16)
		ff.FeedbackFrame:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
		ff.FeedbackFrame:SetBackdropColor (.2, .2, .2, 1)
		ff.FeedbackFrame:SetBackdropBorderColor (.1, .10, .10, 1)
		
		ff.FeedbackEntry = DF:CreateTextEntry (ff.FeedbackFrame, function()end, 120, 20, nil, _, nil, nil)
		ff.FeedbackEntry:SetAllPoints()
		ff.FeedbackEntry:SetText ([[https://wow.curseforge.com/projects/world-quest-tracker/issues/464]])
		ff.FeedbackEntry:Hide()
		
		ff.FeedbackFrame:SetScript ("OnClick", function()
			ff.FeedbackEntry:Show()
			ff.FeedbackEntry:SetFocus (true)
			ff.FeedbackEntry:HighlightText()
			
			C_Timer.After (1, function()
				ff.FeedbackEntry:SetFocus (true)
				ff.FeedbackEntry:HighlightText()
			end)
			
			C_Timer.After (20, function()
				ff.FeedbackFrame:Hide()
			end)
		end)
		
		DF:InstallTemplate ("font", "WQT_GROUPFINDER_FEEDBACK", {color = {1, .9, .4, .85}, size = 9, font = "Friz Quadrata TT"})
		ff.FeedbackFrame.Text = DF:CreateLabel (ff.FeedbackFrame, "Under Development - Send Feedback", DF:GetTemplate ("font", "WQT_GROUPFINDER_FEEDBACK"))
		ff.FeedbackFrame.Text:SetPoint ("center", ff.FeedbackFrame, "center")
		
		ff.FeedbackFrame:Hide()
	--]=]
	--[[
	quotes:
	-middle clicking the tracked quest will start a search for that quest
	
	/dump LFGListInviteDialog
	resultID=4,
	informational=true,
	
	--]]
	-- end of the feedback code
	
	ff.BQuestTrackerFreeWidgets = {}
	ff.BQuestTrackerUsedWidgets = {}
	
	ff.actions = {
		ACTIONTYPE_GROUP_SEARCH = 1,
		ACTIONTYPE_GROUP_CREATE = 2,
		ACTIONTYPE_GROUP_RELIST = 3,
		ACTIONTYPE_GROUP_APPLY = 4,
		ACTIONTYPE_GROUP_WAIT = 5,
		ACTIONTYPE_GROUP_SEARCHING = 6,
		ACTIONTYPE_GROUP_LEAVE = 7,
		ACTIONTYPE_GROUP_UNLIST = 8,
		ACTIONTYPE_GROUP_UNAPPLY = 9,
		ACTIONTYPE_GROUP_KICK = 10,
		ACTIONTYPE_GROUP_SEARCHANOTHER = 11,
		ACTIONTYPE_GROUP_SEARCHCUSTOM = 12,
	}
	
	--http://www.wowhead.com/quest=43179/the-kirin-tor-of-dalaran#comments:id=2429524
	--http://www.wowhead.com/search?q=Supplies+Needed
	ff.IgnoreList = {
		[43325] = true,--race
		[43753] = true,--race
		[43764] = true,--race
		[43769] = true,--race
		[43774] = true,--race
		[45047] = true,--wind
		[45046] = true,--wind
		[45048] = true,--wind
		[45047] = true,--wind
		[45049] = true,--wind
		[45071] = true,--barrel
		[45068] = true,--barrel
		[45069] = true,--barrel
		[45070] = true,--barrel
		[45072] = true,--barrel
		[43327] = true,--fly
		[43777] = true,--fly
		[43771] = true,--fly
		[43766] = true,--fly
		[43755] = true,--fly
		[43756] = true, --enigmatic
		[43772] = true, --enigmatic
		[43767] = true, --enigmatic
		[43778] = true, --enigmatic
		[43328] = true, --enigmatic
		[41327] = true, --supplies-needed-stormscales
		[41224] = true, --supplies-needed-foxflower
		[41293] = true, --supplies-needed-dreamleaf
		[41288] = true, --supplies-needed-aethril
		[41339] = true, --supplies-needed-stonehide-leather
		[41318] = true, --supplies-needed-felslate
		[41351] = true, --supplies-needed-stonehide-leather
		[41345] = true, --supplies-needed-stormscales
		[41207] = true, --supplies-needed-leystone
		[41303] = true, --supplies-needed-starlight-roses
		[41237] = true, --supplies-needed-stonehide-leather
		[41298] = true, --supplies-needed-fjarnskaggl
		[41317] = true, --supplies-needed-leystone
		[41315] = true, --supplies-needed-leystone
		[41316] = true, --supplies-needed-leystone
		
		[48338] = true, --supplies-needed-astral-glory
		[48337] = true, --supplies-needed-astral-glory
		[48360] = true, --supplies-needed-fiendish leather
		[48358] = true, --supplies-needed-empyrium
		[48349] = true, --supplies-needed-empyrium
		[48374] = true, --supplies-needed-lightweave-cloth
		
		--other quests
		[45988] = true, --ancient bones broken shore
		[45379] = true, --tresure master rope broken shore
		[43943] = true, --army training suramar
		[45791] = true, --war materiel broken shore
		[48097] = true, --gatekeeper's cunning macaree
	}
	
	ff.cannot_group_quest = {
		[LE_QUEST_TAG_TYPE_PET_BATTLE] = true,
	}
	
	function WorldQuestTracker.RegisterGroupFinderFrameOnLibWindow()
		LibWindow.RegisterConfig  (ff, WorldQuestTracker.db.profile.groupfinder.frame)
		LibWindow.MakeDraggable (ff)
		LibWindow.RestorePosition (ff)
		ff.IsRegistered = true

		local texture = LibStub:GetLibrary ("LibSharedMedia-3.0"):Fetch ("statusbar", "Iskar Serenity")
		ff.ProgressBar.timer_texture:SetTexture (texture)
		ff.ProgressBar.background:SetTexture (texture)
	end
	
	--> register needed events
	function ff.RegisterEvents()
		ff:RegisterEvent ("QUEST_ACCEPTED")
		ff:RegisterEvent ("QUEST_TURNED_IN")
		ff:RegisterEvent ("GROUP_ROSTER_UPDATE")
		ff:RegisterEvent ("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS")
		ff:RegisterEvent ("GROUP_INVITE_CONFIRMATION")
	end
	function ff.UnregisterEvents()
		ff:UnregisterEvent ("QUEST_ACCEPTED")
		ff:UnregisterEvent ("QUEST_TURNED_IN")
		ff:UnregisterEvent ("GROUP_ROSTER_UPDATE")
		ff:UnregisterEvent ("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS")
		ff:UnregisterEvent ("GROUP_INVITE_CONFIRMATION")
	end
	
	ff.RegisterEvents()
	
	--> members
	ff.IsInWQGroup = false
	ff.GroupMembers = 0
	
	function ff.ShowMainFrame()
		ff.SetCheckIfIsInArea (true)
		ff:Show()
	end
	function ff.HideMainFrame()
		--print (debugstack())
		ff.SetCheckIfIsInArea (false)
		
		if (interactionButton.LeaveTimer) then
			interactionButton.LeaveTimer:Cancel()
			interactionButton.LeaveTimer = nil
		end
		
		ff:Hide()
	end
	
	function ff.SetApplyTimeout (timeout)
		--> cancel previous timer if exists
		if (ff.TimeoutTimer) then
			ff.TimeoutTimer:Cancel()
		end
		
		--> create a new timer
		ff.TimeoutTimer = C_Timer.NewTimer (timeout, ff.GroupApplyTimeout)
		
		--> and set the time on the statusbar
		ff.ProgressBar:SetTimer (timeout)
	end
	
	function ff.GroupApplyTimeout()
		--> clear the timer
		ff.TimeoutTimer = nil
		
		--> found a group? if not need to create a new one
		if (not IsInGroup() and not LFGListInviteDialog:IsShown()) then
		
			--> need to check if there is applycations
			local activeApplications = C_LFGList.GetNumApplications()
			
			if (activeApplies and activeApplies > 0) then
				--> need to undo applications apply before create a new group
				ff.SetAction (ff.actions.ACTIONTYPE_GROUP_UNAPPLY, L["S_GROUPFINDER_ACTIONS_CANCEL_APPLICATIONS"])
			else
				--> request an action
				ff.SetAction (ff.actions.ACTIONTYPE_GROUP_CREATE)
			end

			--> and shutdown the group checker
			--ff.SetCheckIfIsInGroup (false)
		else
			--> found group, good to go
			if (IsInGroup()) then
				ff.IsInWQGroup = true
				ff.GroupMembers = GetNumGroupMembers (LE_PARTY_CATEGORY_HOME) + 1
			else
				ff.QueueGroupUpdate = true
			end
			
			--> hide the main frame
			ff.HideMainFrame()
		end
	end
	
	function ff.LeaveTimerTimeout()
		--> clear the timer
		interactionButton.LeaveTimer = nil
		
		--> if is leave after time
		if (WorldQuestTracker.db.profile.groupfinder.autoleave_delayed) then
			if (IsInGroup()) then
				LeaveParty()
			end
		end
		
		--> hide the main frame
		ff.HideMainFrame()
	end
	
	--
		--quando a lideranã passa para o jogador vindo de um player que estava offline
		--muitas vezes nao esta acontecendo nadad ao tentar crita um grupo
	--
	
	function ff.SetAction (actionID, message, ...)
	
		--> show the frame
		ff.ShowMainFrame()
		ff.ProgressBar:Hide()
		ff.HideSecondaryInteractionButton()
		
		ff.Label3:Show()
		
		--> reset the button state
		ff.ClearInteractionButtonActions()

		--> deal with each request action
		if (actionID == ff.actions.ACTIONTYPE_GROUP_SEARCH) then
			interactionButton.ToSearch = true
			ff.SetCurrentActionText (L["S_GROUPFINDER_ACTIONS_SEARCH"])
			
			ff.ShowSecondaryInteractionButton (ff.actions.ACTIONTYPE_GROUP_CREATE, L["S_GROUPFINDER_ACTIONS_CREATE_DIRECT"])
			
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_SEARCHING) then
			ff.SetCurrentActionText (L["S_GROUPFINDER_ACTIONS_SEARCHING"])
			ff.ProgressBar:SetTimer (2)
			ff.ProgressBar:Show()
			
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_UNAPPLY) then
			interactionButton.ToUnapply = true
			ff.SetCurrentActionText (message or L["S_GROUPFINDER_ACTIONS_UNAPPLY1"])
			ff.ShowSecondaryInteractionButton (ff.actions.ACTIONTYPE_GROUP_SEARCH, L["S_GROUPFINDER_ACTIONS_RETRYSEARCH"])
			
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_CREATE) then
			interactionButton.ToCreate = true
			ff.SetCurrentActionText (L["S_GROUPFINDER_ACTIONS_CREATE"])
			ff.ShowSecondaryInteractionButton (ff.actions.ACTIONTYPE_GROUP_SEARCH, L["S_GROUPFINDER_ACTIONS_RETRYSEARCH"])
			--ff.Label3:Hide()
			
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_UNLIST) then
			interactionButton.ToUnlist = true
			ff.SetCurrentActionText (L["S_GROUPFINDER_ACTIONS_UNLIST"])
			
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_RELIST) then
			interactionButton.ToCreate = true
			ff.SetCurrentActionText (L["S_GROUPFINDER_ACTIONS_SEARCHMORE"])
			
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_APPLY) then
			interactionButton.ToApply = true
			ff.SetCurrentActionText (message)
			ff.ProgressBar:Show()
			
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_LEAVE) then
			interactionButton.ToLeave = true
			
			if (WorldQuestTracker.db.profile.groupfinder.autoleave_delayed) then
				ff.SetCurrentActionText (L["S_GROUPFINDER_ACTIONS_LEAVINGIN"])
				
			elseif (WorldQuestTracker.db.profile.groupfinder.askleave_delayed) then
				ff.SetCurrentActionText (L["S_GROUPFINDER_ACTIONS_LEAVEASK"])
			end
			
			ff.ProgressBar:SetTimer (WorldQuestTracker.db.profile.groupfinder.leavetimer)
			if (interactionButton.LeaveTimer) then
				interactionButton.LeaveTimer:Cancel()
			end
			interactionButton.LeaveTimer = C_Timer.NewTimer (WorldQuestTracker.db.profile.groupfinder.leavetimer, ff.LeaveTimerTimeout)
			ff.ProgressBar:Show()
			ff.SetCheckIfIsInGroup (true)
		
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_KICK) then
			ff.SetCurrentActionText (message)
			interactionButton.ToKick = true
			local UnitID, GUID = ...
			ff.KickTargetUnitID = UnitID
			ff.KickTargetGUID = GUID
			interactionButton.ToKick = true
		
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_WAIT) then
			ff.SetCurrentActionText (message or L["S_GROUPFINDER_ACTIONS_WAITING"])
			interactionButton.ToApply = nil
			local waitTime, callBack = ...
			if (waitTime) then
				ff.ProgressBar:SetTimer (waitTime)
				if (callBack) then
					C_Timer.After (waitTime, callBack)
				end
			end
			ff.ProgressBar:Show()
		
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_SEARCHCUSTOM) then
			ff.SetCurrentActionText (message)
			interactionButton.ToSearchCustom = true
			ff.SearchCustom = true
			ff.ShowSecondaryInteractionButton (ff.actions.ACTIONTYPE_GROUP_CREATE, L["S_GROUPFINDER_ACTIONS_CREATE_DIRECT"])
		
		elseif (actionID == ff.actions.ACTIONTYPE_GROUP_SEARCHANOTHER) then
			ff.SetCurrentActionText (message or L["S_GROUPFINDER_ACTIONS_SEARCHOTHER"])
			interactionButton.ToSearchAnother = true

		end
	end
	
	function ff.OnBBlockButtonPress (self, button)
		if (self.questID) then
			ff.FindGroupForQuest (self.questID, true)
		end
	end
	
	function ff.OnBBlockButtonEnter (self)
		GameTooltip:SetOwner (self, "ANCHOR_LEFT")
		GameTooltip:AddLine (L["S_GROUPFINDER_ACTIONS_SEARCH_TOOLTIP"])
		GameTooltip:Show()
	end
	
	function ff.OnBBlockButtonLeave (self)
		GameTooltip:Hide()
	end
	
	function ff.UpdateButtonAnchorOnBBlock (block, button)
		button:ClearAllPoints()
		
		--> detect other addons to avoid placing our icons over other addons icons
		if (WorldQuestGroupFinderAddon) then --todo: add the world quest assistant addon here too
			--button:SetPoint ("right", block.TrackedQuest, "left", -2, 0)
			button:SetPoint ("topright", block, "topright", 11, -17)
		else
			--check if there's a quest button
			if (block.rightButton and block.rightButton:IsShown()) then
				button:SetPoint ("right", block.rightButton, "left", -2, 0)
			else
				button:SetPoint ("topright", block, "topright", 10, 0)
			end
		end
		
		button:SetParent (block)
		button:SetFrameStrata ("HIGH")
		button:Show()
	end
	
	--> need to place a button somewhere to search for a group in case the player closes the panel
	function ff.AddButtonToBBlock (block, questID)
		local button = tremove (ff.BQuestTrackerFreeWidgets)
		if (not button) then
			button = CreateFrame ("button", nil, UIParent)
			button:SetFrameStrata ("FULLSCREEN")
			button:SetSize (30, 30)
			
			button:SetNormalTexture ([[Interface\BUTTONS\UI-SquareButton-Up]])
			button:SetPushedTexture ([[Interface\BUTTONS\UI-SquareButton-Down]])
			button:SetHighlightTexture ([[Interface\BUTTONS\UI-Common-MouseHilight]])
			
			local icon = button:CreateTexture (nil, "OVERLAY")
			icon:SetAtlas ("socialqueuing-icon-eye")
			icon:SetSize (13, 13)
			
			--icon:SetSize (22, 22)
			--icon:SetTexture ([[Interface\FriendsFrame\PlusManz-PlusManz]])
			--icon:SetPoint ("center", button, "center")
			
			icon:SetPoint ("center", button, "center", -1, 0)
			
			button:SetScript ("OnClick", ff.OnBBlockButtonPress)
			button:SetScript ("OnEnter", ff.OnBBlockButtonEnter)
			button:SetScript ("OnLeave", ff.OnBBlockButtonLeave)
		end
		
		ff.UpdateButtonAnchorOnBBlock (block, button)
		
		ff.BQuestTrackerUsedWidgets [block] = button
		button.questID = questID
		
	end
	
	function ff.RemoveButtonFromBBlock (block)
		tinsert (ff.BQuestTrackerFreeWidgets, ff.BQuestTrackerUsedWidgets [block])
		ff.BQuestTrackerUsedWidgets [block]:ClearAllPoints()
		ff.BQuestTrackerUsedWidgets [block]:Hide()
		ff.BQuestTrackerUsedWidgets [block] = nil
	end
	
	function ff.HandleBTrackerBlock (questID, block)
		if (not ff.BQuestTrackerUsedWidgets [block]) then
			if (type (questID) == "number" and HaveQuestData (questID) and QuestMapFrame_IsQuestWorldQuest (questID)) then
				local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
				if (not ff.cannot_group_quest [worldQuestType] and not ff.IgnoreList [questID]) then			
					--> give a button for this block
					ff.AddButtonToBBlock (block, questID)
				end
			end
		else
			local isInArea, isOnMap, numObjectives = GetTaskInfo (questID) -- or not isInArea
			if (type (questID) ~= "number" or not HaveQuestData (questID) or not QuestMapFrame_IsQuestWorldQuest (questID)) then
				--> remove the button from this block
				ff.RemoveButtonFromBBlock (block)
			else
				--> just update the questID
				ff.BQuestTrackerUsedWidgets [block].questID = questID
				--> update the anchor
				ff.UpdateButtonAnchorOnBBlock (block, ff.BQuestTrackerUsedWidgets [block])
			end
		end
	end
	
	function ff.GroupDone()
		--> hide the frame
		ff.HideMainFrame()
		--> leave the group
		if (IsInGroup()) then
			if (WorldQuestTracker.db.profile.groupfinder.autoleave) then
				LeaveParty()
			else
				--> show timer to leave the group
				ff.SetAction (ff.actions.ACTIONTYPE_GROUP_LEAVE)
			end
		end
		
		--> shutdown ontick script
		ff.ShutdownOnTickScript (true)
	end
	
	function ff.WorldQuestFinished (questID, fromCustomSeearch)
		if (interactionButton.HadInteraction) then
			if (fromCustomSearch) then
				ff.GroupDone()
			else
				if (interactionButton.questID == questID) then
					ff.GroupDone()
				end
			end
		end
	end
	
	function ff.SetQuestTitle (questName)
		ff.Label1.text = questName
	end
	
	function ff.SetCurrentActionText (actionText)
		ff.Label2.text = actionText
	end
	
	function ff.ResetMembers()
		ff.IsInWQGroup = false
		ff.GroupMembers = 0
	end
	
	function ff.ResetInteractionButton()
		ff.ClearInteractionButtonActions()
		
		interactionButton.questName = ""
		interactionButton.questID = 0
		
		if (interactionButton.LeaveTimer) then
			interactionButton.LeaveTimer:Cancel()
		end
		
		ff.HideSecondaryInteractionButton()
	end
	
	function ff.OnTick (self, deltaTime)
		if (ff.CheckIfInGroup) then
			if (IsInGroup()) then
				ff.HideMainFrame()
				ff.SetCheckIfIsInGroup (false)
			end
		end
		
		if (not ff.SearchCustom) then
		
			if (ff.CheckCurrentQuestArea) then
				ff.CheckCurrentQuestArea_Timer = ff.CheckCurrentQuestArea_Timer + deltaTime
				
				if (ff.CheckCurrentQuestArea_Timer > 2) then
					local isInArea, isOnMap, numObjectives = GetTaskInfo (interactionButton.questID)
					if (not isInArea) then
						ff.SetCheckIfIsInArea (false)
						ff.HideMainFrame()
					end
					ff.CheckCurrentQuestArea_Timer = 0
				end
			end

			if (ff.CheckForAFKs) then
				ff.CheckForAFKs_Timer = ff.CheckForAFKs_Timer + deltaTime
				
				if (ff.CheckForAFKs_Timer > 5) then
					--> check if we are in the quest and not in raid, just to make sure
					local isInArea, isOnMap, numObjectives = GetTaskInfo (interactionButton.questID)
					if (isInArea and not IsInRaid()) then
						--> do the check
						local mySelf = UnitGUID ("player")
						local selfX, selfY = UnitPosition ("player")
						
						for i = 1, GetNumGroupMembers() do
							local GUID = UnitGUID ("party" .. i)
							if (GUID and GUID ~= mySelf) then
								local unitTable = ff.AFKCheckList [GUID]
								if (not unitTable) then
									ff.AFKCheckList [GUID] = {
										tick = 0,
										name = UnitName ("party" .. i),
										x = 0,
										y = 0,
										faraway = 0,
									}
									unitTable = ff.AFKCheckList [GUID]
								end
								
								--local x, y = GetPlayerMapPosition ("party" .. i)
								local x, y, posZ, instanceID = UnitPosition ("party" .. i)
								x = x or 0
								y = y or 0
								
								--> check location for afk
								if (x ~= unitTable.x or y ~= unitTable.y or UnitHealth ("party" .. i) < UnitHealthMax ("party" .. i)) then
									unitTable.tick = 0
									unitTable.x = x
									unitTable.y = y
								else
									unitTable.tick = unitTable.tick + 1
									if (unitTable.tick > WorldQuestTracker.db.profile.groupfinder.noafk_ticks) then
										--print ("[debug] found a afk player, not moving or taking damage for 30 seconds", UnitName ("party" .. i))
										ff.SetAction (ff.actions.ACTIONTYPE_GROUP_KICK, "click to kick an AFK player", "party" .. i, GUID)
										break
									end
								end
								
								--> check location for distance
								if (selfX and selfX ~= 0 and DF.GetDistance_Point) then
									local distance = DF:GetDistance_Point (selfX, selfY, x, y)
									if (distance > 500) then
										unitTable.faraway = unitTable.faraway + 1
										if (unitTable.faraway > WorldQuestTracker.db.profile.groupfinder.noafk_ticks) then
											--print ("[debug] found a player too far away, sqrt > 500 yards:", distance, UnitName ("party" .. i))
											ff.SetAction (ff.actions.ACTIONTYPE_GROUP_KICK, "click to kick an AFK player", "party" .. i, GUID)
											unitTable.faraway = 0
											break
										end
									else
										unitTable.faraway = 0
									end
								end
							end
						end
					end
					
					ff.CheckForAFKs_Timer = 0
				end
			end
		end
	end
	
	function ff.ShutdownOnTickScript (force)
		if (force) then
			ff.CheckIfInGroup = nil
			ff.CheckCurrentQuestArea = nil
			ff.CheckForAFKs = nil
			ff.TickFrame:SetScript ("OnUpdate", nil)
			return
		end
		if (	not ff.CheckIfInGroup and 
			not ff.CheckCurrentQuestArea and 
			not ff.CheckForAFKs
		) then
			ff.TickFrame:SetScript ("OnUpdate", nil)
		end
	end
	
	function ff.SetCheckIfIsInGroup (state)
		if (state) then
			ff.CheckIfInGroup = true
			ff.TickFrame:SetScript ("OnUpdate", ff.OnTick)
		else
			ff.CheckIfInGroup = nil
			ff.ShutdownOnTickScript()
		end
	end
	
	function ff.SetCheckIfIsInArea (state)
		if (state) then
			ff.CheckCurrentQuestArea = true
			ff.TickFrame:SetScript ("OnUpdate", ff.OnTick)
			ff.CheckCurrentQuestArea_Timer = 0
		else
			ff.CheckCurrentQuestArea = nil
			ff.ShutdownOnTickScript()
		end
	end
	
	function ff.SetCheckIfTrackingAFKs (state)
		if (state) then
			ff.CheckForAFKs = true
			ff.CheckForAFKs_Timer = 0
			ff.TickFrame:SetScript ("OnUpdate", ff.OnTick)
		else
			ff.CheckForAFKs = nil
			ff.ShutdownOnTickScript()
		end
	end
	
	function ff.ClearInteractionButtonActions()
		interactionButton.ToApply = nil
		interactionButton.ToCreate = nil
		interactionButton.ToSearch = nil
		interactionButton.ToLeave = nil
		interactionButton.ToUnlist = nil
		interactionButton.ToUnapply = nil
		interactionButton.ToKick = nil
		interactionButton.ToSearchAnother = nil
		interactionButton.ToSearchCustom = nil
		
	end
	
	function ff.IsPVPRealm (desc)
		if (desc:find ("@PVP") or desc:find ("#PVP")) then
			return true
		end
	end
	
	function ff.SearchCompleted() --~searchfinished
		--C_LFGList.GetSearchResultInfo (applicationID)
		
		local active, activityID, iLevel, name, comment, voiceChat, expiration, autoAccept = C_LFGList.GetActiveEntryInfo()
		if (active) then
			--> the player group is listing, need request to get out
			--> we can do this automatically, but is best request an interaction
			ff.SetAction (ff.actions.ACTIONTYPE_GROUP_UNLIST)
			return
		end
		
		ff.ClearInteractionButtonActions()
		
		local numResults, resultIDTable = C_LFGList.GetSearchResults()
		interactionButton.GroupsToApply = interactionButton.GroupsToApply or {}
		wipe (interactionButton.GroupsToApply)
		interactionButton.GroupsToApply.n = 1
		
		local t = {}
		
		for index, resultID in pairs (resultIDTable) do
			--no filters but, pve players shouldn't queue on pvp servers?
			
			local id, activityID, name, desc, voiceChat, ilvl, honorLevel, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName, members, isAuto = C_LFGList.GetSearchResultInfo (resultID)
			
			--print (members) --is always an int?
			--print ("resultado:", name, interactionButton.questName)
			
			if (isAuto and not isDelisted and ilvl <= GetAverageItemLevel()) then -- and members < 5 -- and name == interactionButton.questName
				local isPVP = ff.IsPVPRealm (desc)
				if (not WorldQuestTracker.db.profile.groupfinder.nopvp) then
					tinsert (t, {resultID, (numBNetFriends or 0) + (numCharFriends or 0) + (numGuildMates or 0), members or 0, isPVP and 0 or 1})
				else
					if (not isPVP) then
						tinsert (t, {resultID, (numBNetFriends or 0) + (numCharFriends or 0) + (numGuildMates or 0), members or 0, isPVP and 0 or 1})
					end
				end
			end
			
			--ApplyToGroup(resultID, comment, tankOK, healerOK, damageOK)
			--print (index, resultID)
			--C_LFGList.ApplyToGroup (resultID, "WorldQuestTrackerInvite-" .. self.questName, UnitGetAvailableRoles ("player"))
		end
		
		table.sort (t,  function(t1, t2) return t1[3] > t2[3] end) --more people first
		table.sort (t,  function(t1, t2) return t1[2] > t2[2] end) --more friends first
		table.sort (t,  function(t1, t2) return t1[4] > t2[4] end) --pvp status first
		
		for i = 1, #t do
			tinsert (interactionButton.GroupsToApply, t[i][1])
		end
		
		if (#interactionButton.GroupsToApply > 0) then
			local amt = #interactionButton.GroupsToApply
			if (amt > 1) then
				ff.SetAction (ff.actions.ACTIONTYPE_GROUP_APPLY, format (L["S_GROUPFINDER_RESULTS_FOUND"], #interactionButton.GroupsToApply))
			else
				ff.SetAction (ff.actions.ACTIONTYPE_GROUP_APPLY, L["S_GROUPFINDER_RESULTS_FOUND1"])
			end
			
			interactionButton.ApplyLeft = #interactionButton.GroupsToApply
		else
			--> no group found
			ff.SetAction (ff.actions.ACTIONTYPE_GROUP_CREATE)
			if (ff.SearchCallback) then
				ff.SearchCallback ("NO_GROUP_FOUND")
			end
		end
	end
	
	function ff.CheckValidClick (self, button)
		if (button == "RightButton") then
			ff.HideMainFrame()
			return
		end
		
		if (GetLFGMode (1) or GetLFGMode (3)) then --dungeon and raid finder
			print ("nop, you are in queue...")
			print ("World Quest Tracker: ", L["S_GROUPFINDER_QUEUEBUSY"])
			ff.HideMainFrame()
			return
		end
		
		for i = 1, 5 do --bg / wont work with ashran
			local status, mapName, teamSize, registeredMatch, suspendedQueue, queueType, gameType, role = GetBattlefieldStatus (i)
			if (queueType and status ~= "none") then
				print ("World Quest Tracker: ", L["S_GROUPFINDER_QUEUEBUSY"])
				ff.HideMainFrame()
				return
			end
		end
		
		if (not self.ToSearch and not self.ToUnlist and not self.ToLeave and not self.ToCreate and not self.ToApply and not self.ToKick and not self.ToUnapply and not self.ToSearchAnother and not self.ToSearchCustom) then
			--print ("No actions scheduled!")
			return
		end
		
		return true
	end
	
	function ff.StartSearchForCustom()
		local terms = LFGListSearchPanel_ParseSearchTerms (interactionButton.questName)
		C_LFGList.Search (6, terms) --ignora os filtros
		C_Timer.After (2, ff.SearchCompleted)
	end
	
	function ff.StartSearch()
		C_LFGList.Search (1, LFGListSearchPanel_ParseSearchTerms (interactionButton.questName)) --ignora os filtros
		C_Timer.After (2, ff.SearchCompleted)
	end
	
	function ff.CreateNewListing (questID, questName, AddToDesc)
		local pvpType = GetZonePVPInfo()
		local pvpTag
		if (pvpType == "contested") then
			pvpTag = "#PVP"
		else
			pvpTag = ""
		end

		local groupDesc
		if (questID == 0) then
			groupDesc = (ff.SearchCustomGroupDesc or "") .. "#ID" .. questID .. pvpTag
		else
			groupDesc = "Doing world quest " .. questName .. ". Group created with World Quest Tracker. #ID" .. questID .. pvpTag .. (AddToDesc or "")
		end

		local itemLevelRequired = 0
		local honorLevelRequired = 0
		local isAutoAccept = true
		local isPrivate = false
		
		if (questID == 0) then
			C_LFGList.CreateListing (16, questName, itemLevelRequired, honorLevelRequired, "", groupDesc, isAutoAccept, isPrivate)
		else
			C_LFGList.CreateListing (C_LFGList.GetActivityIDForQuestID (questID) or 469, "", itemLevelRequired, honorLevelRequired, "", groupDesc, isAutoAccept, isPrivate, questID)
		end
		
		--> if is an epic quest, converto to raid
		local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
		if (rarity == LE_WORLD_QUEST_QUALITY_EPIC or questID == 0) then
			C_Timer.After (2, function() ConvertToRaid(); end)
		end

		ff.IsInWQGroup = true
		ff.GroupMembers = 1
		
		ff.HideMainFrame()
	end
	
	secondaryInteractionButton:SetScript ("OnClick", function (self, button)
		--> is a valid click?
		if (not ff.CheckValidClick (self, button)) then
			return
		end
		
		--> disable the main interaction button, the actions below should set the new state
		ff.ClearInteractionButtonActions()
		
		--> hide the secondary button
		ff.HideSecondaryInteractionButton()
		
		--> parse the action
		if (self.ToSearch) then
			if (not ff.SearchCustom) then
				ff.StartSearch()
			else
				ff.StartSearchForCustom()
			end
			
			self.ToSearch = nil
			ff.SetAction (ff.actions.ACTIONTYPE_GROUP_SEARCHING)
			
		elseif (self.ToCreate) then
			self.ToCreate = nil
			interactionButton.ToSearch = nil
			interactionButton.HadInteraction = true
			ff.CreateNewListing (interactionButton.questID, interactionButton.questName)
		end
	end)
	
	interactionButton:SetScript ("OnClick", function (self, button)
	
		if (not ff.CheckValidClick (self, button)) then
			return
		end
		
		---C_LFGList.GetLanguageSearchFilter()
		--print (self.questName)
		--Message: Usage: C_LFGList.Search(categoryID, searchTerms [, filter, preferredFilters, languageFilter])
		--LFGListSearchPanel_ParseSearchTerms = coloca dentro de uma tabela
		
--		print ("Search", self.ToSearch, "Unlist", self.ToUnlist, "Leave", self.ToLeave, "Create", self.ToCreate, "Apply", self.ToApply, "Kick", self.ToKick, "UnApply", self.ToUnapply)
		
		if (self.ToSearch) then
			ff.StartSearch()
			interactionButton.ToSearch = nil
			self.HadInteraction = true
			ff.SetAction (ff.actions.ACTIONTYPE_GROUP_SEARCHING)

		elseif (self.ToSearchAnother) then
			--> get the current leader, so we don't apply to the same group again
			for i = 1, GetNumGroupMembers() do 
				if (UnitIsGroupLeader ("party" .. i)) then
					ff.PreviousLeader = UnitName ("party" .. i)
					break
				end
			end
			--> leave the group
			ff.IsInWQGroup = false
			LeaveParty()
			ff.StartSearch()
			self.ToSearchAnother = nil
			self.HadInteraction = true
			ff.SetAction (ff.actions.ACTIONTYPE_GROUP_SEARCHING)
		
		elseif (self.ToSearchCustom) then
			ff.StartSearchForCustom()
			interactionButton.ToSearchCustom = nil
			self.HadInteraction = true
			ff.SetAction (ff.actions.ACTIONTYPE_GROUP_SEARCHING)
		
		elseif (self.ToUnlist) then
			C_LFGList.RemoveListing()
			--> call search completed once it can only enter on Unlist state from there
			ff.SetAction (ff.actions.ACTIONTYPE_GROUP_WAIT, L["S_GROUPFINDER_ACTIONS_UNLISTING"], 1.2, ff.SearchCompleted)
			self.ToUnlist = nil
		
		elseif (self.ToKick) then
			local GUID = UnitGUID (ff.KickTargetUnitID)
			if (GUID and ff.KickTargetGUID == GUID) then
				UninviteUnit (ff.KickTargetUnitID)
			end
			ff.HideMainFrame()
			self.ToKick = nil
		
		elseif (self.ToLeave) then
			LeaveParty()
			ff.HideMainFrame()
			ff.ResetInteractionButton()
			ff.ShutdownOnTickScript (true)
			return
		
		elseif (self.ToUnapply) then
			
			local numApplications = C_LFGList.GetNumApplications() --Returns the number of groups the player has applied for.
			local applications = C_LFGList.GetApplications() --Returns a table with the groups the player has applied for
			--groupID, status, unknown, timeRemaining, role = C_LFGList.GetApplicationInfo(groupID)

			if (numApplications > 0) then
				local groupID, status, unknown, timeRemaining, role = C_LFGList.GetApplicationInfo (applications [numApplications])
				if (status == "invited") then
					C_LFGList.DeclineInvite (applications [numApplications])
				else
					C_LFGList.CancelApplication (applications [numApplications])
				end
			end
			
			if (numApplications == 1) then
				ff.SetAction (ff.actions.ACTIONTYPE_GROUP_WAIT, L["S_GROUPFINDER_ACTIONS_CANCELING"], 1, ff.GroupApplyTimeout)
				self.ToUnapply = nil
			else
				ff.SetAction (ff.actions.ACTIONTYPE_GROUP_UNAPPLY, format (L["S_GROUPFINDER_RESULTS_UNAPPLY"], numApplications-1))
			end
			
			self.HadInteraction = true
			
		elseif (self.ToCreate) then
			local questID = self.questID
			local questName = self.questName
			
			ff.CreateNewListing (questID, questName)
			
			self.ToCreate = nil
			self.HadInteraction = true

		elseif (self.ToApply) then	
			self.HadInteraction = true
			
			local id, activityID, name, desc, voiceChat, ilvl, honorLevel, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName, members, isAuto = C_LFGList.GetSearchResultInfo (interactionButton.GroupsToApply [interactionButton.GroupsToApply.n])
			local isPreviousLeader = ff.PreviousLeader and ((ff.PreviousLeader == leaderName) or (leaderName:find (ff.PreviousLeader)))
			
			if (isAuto and not isDelisted and ilvl <= GetAverageItemLevel() and not isPreviousLeader) then -- and members < 5 --name == interactionButton.questName and
				--print ("Applying:", interactionButton.GroupsToApply [interactionButton.GroupsToApply.n], "WorldQuestTrackerInvite-" .. self.questName, UnitGetAvailableRoles ("player"))

				--Usage: ApplyToGroup(resultID, comment, tankOK, healerOK, damageOK)
				local id, name, description, icon, role, primaryStat = GetSpecializationInfo (GetSpecialization())

				C_LFGList.ApplyToGroup (interactionButton.GroupsToApply [interactionButton.GroupsToApply.n], "WQTInvite-" .. self.questName, role == "TANK", role == "HEALER", role == "DAMAGER")
				--print (interactionButton.GroupsToApply.n, interactionButton.GroupsToApply [interactionButton.GroupsToApply.n], role == "TANK", role == "HEALER", role == "DAMAGER")
				
				--> set the timeout
				ff.SetApplyTimeout (4)
				
				interactionButton.ApplyLeft = interactionButton.ApplyLeft - 1
				if (interactionButton.ApplyLeft > 0) then
					if (interactionButton.ApplyLeft > 1) then
						ff.SetAction (ff.actions.ACTIONTYPE_GROUP_APPLY, format (L["S_GROUPFINDER_RESULTS_APPLYING"], interactionButton.ApplyLeft))
					else
						ff.SetAction (ff.actions.ACTIONTYPE_GROUP_APPLY, L["S_GROUPFINDER_RESULTS_APPLYING1"])
					end
				else
					ff.SetAction (ff.actions.ACTIONTYPE_GROUP_WAIT)
				end
				
				ff.SetCheckIfIsInGroup (true)
				
			end
			
			interactionButton.GroupsToApply.n = interactionButton.GroupsToApply.n + 1
			
			if (interactionButton.GroupsToApply.n > #interactionButton.GroupsToApply) then
			
				if (true) then --debug
--					self.ToApply = nil
--					ff.SetAction (ff.actions.ACTIONTYPE_GROUP_UNAPPLY, "click to cancel applications...")
--					return
				end
			
				ff.SetApplyTimeout (4)
				ff.SetAction (ff.actions.ACTIONTYPE_GROUP_WAIT)
				return
			end
		end
	end)

	function WorldQuestTracker.FindGroupForQuest (questID)
		ff.FindGroupForQuest (questID)
	end
	
	function WorldQuestTracker.FindGroupForCustom (searchString, customTitle, customDesc, customGroupDescription, callback)
		ff.FindGroupForQuest (searchString, nil, true, customTitle, customDesc, customGroupDescription, callback)
	end
	
	function ff.FindGroupForQuest (questID, fromOTButton, isSearchOnCustom, customTitle, customDesc, customGroupDescription, callback)
		--> reset the search type
		ff.SearchCustom = nil
		ff.SearchCustomGroupDesc = nil
		ff.SearchCallback = nil
		
		if (callback) then
			ff.SearchCallback = callback
		end
		
		if (isSearchOnCustom) then
			ff.NewWorldQuestEngaged (nil, nil, questID, customTitle, customDesc, customGroupDescription)
			return
		end
	
		if (fromOTButton and IsInGroup() and ff.IsInWQGroup) then
			--> player already doing the quest
			ff.SetAction (ff.actions.ACTIONTYPE_GROUP_SEARCHANOTHER)
			return
		end
		
		if ((not IsInGroup() and not IsInRaid()) or (IsInGroup() and GetNumGroupMembers() == 1) or (IsInGroup() and not IsInRaid() and not ff.IsInWQGroup)) then --> causou problemas de ? - precisa de um aviso case esteja em grupo
			local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
			if (not ff.cannot_group_quest [worldQuestType] and not ff.IgnoreList [questID]) then
				ff.NewWorldQuestEngaged (title, questID)
			end
		end
	end
	
	function ff.NewWorldQuestEngaged (questName, questID, isSearchOnCustom, customTitle, customDesc, customGroupDescription)
		--> reset the gump
		ff.ShutdownOnTickScript (true)
		ff.ResetInteractionButton()
		ff.ResetMembers()
		
		--> update the interactive button to current quest
		interactionButton.questName = questName or isSearchOnCustom
		interactionButton.questID = questID or 0
		interactionButton.HadInteraction = nil
		
		ff.AFKCheckList = ff.AFKCheckList or {}
		wipe (ff.AFKCheckList)
		
		if (not isSearchOnCustom) then
			--> normal search for quests
			ff.SetQuestTitle (questName .. " (" .. questID .. ")")
			ff.SetAction (ff.actions.ACTIONTYPE_GROUP_SEARCH)
			
		else
			--> custom searchs
			ff.SearchCustomGroupDesc = customGroupDescription
			ff.SetQuestTitle (customTitle or isSearchOnCustom)
			ff.SetAction (ff.actions.ACTIONTYPE_GROUP_SEARCHCUSTOM, customDesc)
		end
		
		ff.HasLeadership = false
		
		--> show the main frame
		if (not ff.IsRegistered) then
			WorldQuestTracker.RegisterGroupFinderFrameOnLibWindow()
		end
	end	
	
	function ff.DelayedCheckForDisband()
		--> everyone from player group could be gone, check if the quest is valid and if still  doing it
		if (interactionButton.questID) then
			local isInArea, isOnMap, numObjectives = GetTaskInfo (interactionButton.questID)
			if (isInArea and not IsQuestFlaggedCompleted (interactionButton.questID)) then
				--> just to make sure there's no group listed on the group finder
				--> it should be false since the player isn't in group
				local active, activityID, iLevel, name, comment, voiceChat, expiration, autoAccept = C_LFGList.GetActiveEntryInfo()
				if (not active) then
					--> everything at this point should be already set
					--> just query the player if want another group
					ff.SetAction (ff.actions.ACTIONTYPE_GROUP_SEARCH)
				end
			end
		end
	end
	
	ff:SetScript ("OnShow", function (self)
		if (WorldQuestTracker.db.profile.groupfinder.tutorial == 0) then
			local alert = CreateFrame ("frame", "WorldQuestTrackerGroupFinderTutorialAlert1", ff, "MicroButtonAlertTemplate")
			alert:SetFrameLevel (302)
			alert.label = L["S_GROUPFINDER_TUTORIAL1"]
			alert.Text:SetSpacing (4)
			MicroButtonAlert_SetText (alert, alert.label)
			alert:SetPoint ("topleft", ff, "topleft", 10, 110)
			alert.CloseButton:HookScript ("OnClick", function()
				
			end)
			alert:Show()
			WorldQuestTracker.db.profile.groupfinder.tutorial = WorldQuestTracker.db.profile.groupfinder.tutorial + 1
		end
	end)
	
	ff:SetScript ("OnEvent", function (self, event, arg1, questID, arg3)
	
		--is this feature enable?
		if (not WorldQuestTracker.db.profile.groupfinder.enabled) then
			return
		end
		
		if (event == "QUEST_ACCEPTED") then
			--> get quest data
			local isInArea, isOnMap, numObjectives = GetTaskInfo (questID)
			local title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID (questID)
			
			-->  do the regular checks
			if (isInArea and HaveQuestData (questID)) then
				local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
				if (isWorldQuest) then
					ff.FindGroupForQuest (questID)
				end
			end 
		
		elseif (event == "QUEST_TURNED_IN") then
			questID = arg1
			local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
			--print ("quest finished", questID, "is world:", isWorldQuest, "is last:", interactionButton.questID == questID)
			if (isWorldQuest) then
				ff.WorldQuestFinished (questID)
			end
		
		elseif (event == "LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS" or event == "GROUP_INVITE_CONFIRMATION") then
			--> hide annoying alerts
			if (ff.IsInWQGroup) then
				StaticPopup_Hide ("LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS")
				StaticPopup_Hide ("LFG_LIST_AUTO_ACCEPT_CONVERT_TO_RAID")
				StaticPopup_Hide ("GROUP_INVITE_CONFIRMATION")
				--print ("popup ignored")
			end
			--for d,_ in pairs(StaticPopupDialogs)do if (StaticPopup_FindVisible(d)) then print (d) end end
		
		elseif (event == "GROUP_ROSTER_UPDATE") then
			--> is in a world quest group
			if (ff.IsInWQGroup) then
				--> player left the group
				if (not IsInGroup()) then
					ff.IsInWQGroup = false
					ff.PreviousLeader = nil
					C_Timer.After (2, ff.DelayedCheckForDisband)
				else
					--> check if lost a member
					if (ff.GroupMembers > GetNumGroupMembers (LE_PARTY_CATEGORY_HOME) + 1) then
						--> is the leader?
						if (UnitIsGroupLeader ("player")) then
							--> is the player still doing this quest?
							local isInArea, isOnMap, numObjectives = GetTaskInfo (interactionButton.questID)
							if (isInArea) then
								--> is the quest not completed?
								if (not IsQuestFlaggedCompleted (interactionButton.questID)) then
									--> is the group not listed?
									local active, activityID, iLevel, name, comment, voiceChat, expiration, autoAccept = C_LFGList.GetActiveEntryInfo()
									if (not active) then
										ff.SetAction (ff.actions.ACTIONTYPE_GROUP_RELIST)
									end
								end
							end
						end
					end
					
					if (UnitIsGroupLeader ("player") and not ff.HasLeadership) then
						ff.HasLeadership = true
						if (WorldQuestTracker.db.profile.groupfinder.noafk) then
							ff.SetCheckIfTrackingAFKs (true)
						end
						
					elseif (ff.HasLeadership and not UnitIsGroupLeader ("player")) then
						ff.HasLeadership = false
						ff.SetCheckIfTrackingAFKs (false)
					end
					
					ff.GroupMembers = GetNumGroupMembers (LE_PARTY_CATEGORY_HOME) + 1
					
					--> tell the rare finder the group has been modified
					rf.ScheduleGroupShareRares()
				end
			else
				if (ff.QueueGroupUpdate) then
					ff.QueueGroupUpdate = nil
					
					if (IsInGroup()) then
						ff.IsInWQGroup = true
						ff.GroupMembers = GetNumGroupMembers (LE_PARTY_CATEGORY_HOME) + 1
						
						--> player entered in a group
						
					end
				end
			end
		end
	end)
--]=]



--ao clicar no botão de uma quest na zona ou no world map, colocar para trackear ela
-- õnclick ~onclick ~click
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

	--was middle button and our group finder is enabled
	if (button == "MiddleButton" and WorldQuestTracker.db.profile.groupfinder.enabled) then
		WorldQuestTracker.FindGroupForQuest (self.questID)
		return
	end
	
	--middle click without our group finder enabled, check for other addons
	if (button == "MiddleButton" and WorldQuestGroupFinderAddon) then
		WorldQuestGroupFinder.HandleBlockClick (self.questID)
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
--if (true) then return end

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
	if (WorldQuestTracker.ZoneHaveWorldQuest (GetCurrentMapAreaID())) then
		return "zone"
	elseif (WorldQuestTracker.IsWorldQuestHub (WorldMapFrame.mapID) or WorldQuestTracker.IsCurrentMapQuestHub()) then
		return "world"
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
		--local taskInfo = GetQuestsForPlayerByMapID (mapId, 1007)
		local taskInfo = GetQuestsForPlayerByMapID (mapId)
		if (taskInfo and #taskInfo > 0) then
			for i, info  in ipairs (taskInfo) do
				local questID = info.questId
				if (HaveQuestData (questID)) then
					local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
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
			--return format ("%.2f", numero/100000000) .. symbol_1B
			return format ("%.2f", numero/100000000) .. symbol_1B
		elseif (numero > 999999) then
			--print ("--", numero, format ("%d", numero/10000))
			return format ("%d", numero/10000) .. symbol_10K
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
			return format ("%.0f", numero/1000000) .. "M"
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
		if (worldQuestType == LE_QUEST_TAG_TYPE_INVASION) then
			return "border_zone_legionT"
		else
			return "border_zone_whiteT"
		end
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
		self.invasionBorder:Hide()
		
		if (WorldQuestTracker.IsQuestBeingTracked (self.questID)) then
			self.borderAnimation:Show()
			--AutoCastShine_AutoCastStart (self.borderAnimation, 1, .7, 0)
			self.trackingBorder:Show()
		else
			self.borderAnimation:Hide()
			self.trackingBorder:Hide()
		end
		
		self.shineAnimation:Hide()
		AnimatedShine_Stop (self)
		
		local coords = WorldQuestTracker.GetBorderCoords (rarity)
		if (rarity == LE_WORLD_QUEST_QUALITY_COMMON and worldQuestType ~= LE_QUEST_TAG_TYPE_INVASION) then
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

			self.shineAnimation:Show()
			--self.borderAnimation:Show()
			--AutoCastShine_AutoCastStart (self.borderAnimation, .3, .3, 1)
			AnimatedShine_Start (self, 1, 1, 1);
			
		elseif (worldQuestType == LE_QUEST_TAG_TYPE_INVASION) then
			self.invasionBorder:Show()
			
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
				self.rareSerpent:SetSize (48*0.7, 52*0.7)
				self.rareSerpent:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragon_curveT]])
				
				self.rareGlow:Show()
				self.rareGlow:SetVertexColor (0, 0.36863, 0.74902)
				self.rareGlow:SetSize (48*0.7, 52*0.7)
				self.rareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\rare_dragonT]])
				
				--se estiver sendo trackeada, trocar o banner
				if (WorldQuestTracker.IsQuestBeingTracked (self.questID)) then
					self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag_criteriamatchT]])
				else
					self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flagT]])
				end

				--self.bgFlag:Show()
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
	
	local Text = GameTooltipFrameTextLeft1:GetText() or GameTooltipFrameTextLeft2:GetText() or ""
	local itemLevel = tonumber (Text:match ("%d+"))
	
	return itemLevel or 1
end

-- ãrtifact ~artifact
function WorldQuestTracker.RewardIsArtifactPowerAsian (itemLink) -- thanks @yuk6196 on curseforge

	GameTooltipFrame:SetOwner (WorldFrame, "ANCHOR_NONE")
	GameTooltipFrame:SetHyperlink (itemLink)
	local text = GameTooltipFrameTextLeft1:GetText()

	if (text and text:match ("|cFFE6CC80")) then
		local power = GameTooltipFrameTextLeft3:GetText()
		if (power) then
			local n = tonumber (power:match ("[%d.]+"))
			if (power:find (SECOND_NUMBER)) then
				n = n * 10000
			elseif (power:find (THIRD_NUMBER)) then
				n = n * 100000000
			elseif (power:find (FOURTH_NUMBER)) then
				n = n * 1000000000000
			end
			return true, n or 0
		end
	end

	local text2 = GameTooltipFrameTextLeft2:GetText()
	if (text2 and text2:match ("|cFFE6CC80")) then
		local power = GameTooltipFrameTextLeft4:GetText()
		if (power) then
			local n = tonumber (power:match ("[%d.]+"))
			if (power:find (SECOND_NUMBER)) then
				n = n * 10000
			elseif (power:find (THIRD_NUMBER)) then
				n = n * 100000000
			elseif (power:find (FOURTH_NUMBER)) then
				n = n * 1000000000000
			end
			return true, n or 0
		end
	end
end

function WorldQuestTracker.RewardIsArtifactPowerGerman (itemLink) -- thanks @Superanuki on curseforge

	local w1, w2, w3, w4 = "Millionen", "Million", "%d+,%d+", "([^,]+),([^,]+)" --works for German

	if (WorldQuestTracker.GameLocale == "ptBR") then
		w1, w2, w3, w4 = "milh", "milh", "%d+.%d+", "([^,]+).([^,]+)"
	elseif (WorldQuestTracker.GameLocale == "frFR") then
		w1, w2, w3, w4 = "million", "million", "%d+,%d+", "([^,]+),([^,]+)"
	end

	GameTooltipFrame:SetOwner (WorldFrame, "ANCHOR_NONE")
	GameTooltipFrame:SetHyperlink (itemLink)
	local text = GameTooltipFrameTextLeft1:GetText()
	
	if (text and text:match ("|cFFE6CC80")) then
		local power = GameTooltipFrameTextLeft3:GetText()
		if (power) then
			if (power:find (w1) or power:find (w2)) then

				local n=power:match(w3)
				if n then 
					local one,two=n:match(w4) n=one.."."..two 
				end
				n = tonumber (n)
				if (not n) then
					n = power:match (" %d+ ") --thanks @Arwarld_ on curseforge - ticket #427
					n = tonumber (n)
					n=n..".0"
					n = tonumber (n)
				end
				
				if (n) then
					n = n * 1000000
					return true, n or 0
				end
			end
			
			if (WorldQuestTracker.GameLocale == "frFR") then
				power = power:gsub ("%s", ""):gsub ("%p", ""):match ("%d+")
			else
				power = power:gsub ("%p", ""):match ("%d+")
			end
			
			power = tonumber (power)
			return true, power or 0
		end
	end
	
	local text2 = GameTooltipFrameTextLeft2:GetText()
	if (text2 and text2:match ("|cFFE6CC80")) then
		local power = GameTooltipFrameTextLeft4:GetText()
		if (power) then
		
			if (power:find (w1) or power:find (w2)) then
				local n=power:match(w3)
				
				if n then 
					local one,two=n:match(w4) n=one.."."..two 
				end
				n = tonumber (n)
				if (not n) then
					n = power:match (" %d+ ")
					n = tonumber (n)
					n=n..".0"
					n = tonumber (n)
				end
				
				if (n) then
					n = n * 1000000
					return true, n or 0
				end
			end
			
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

function WorldQuestTracker.RewardIsArtifactPower (itemLink)

	--if (WorldQuestTracker.GameLocale == "koKR") then
	if (WorldQuestTracker.GameLocale == "koKR" or WorldQuestTracker.GameLocale == "zhTW" or WorldQuestTracker.GameLocale == "zhCN") then
		return WorldQuestTracker.RewardIsArtifactPowerAsian (itemLink)
	
	elseif (WorldQuestTracker.GameLocale == "deDE" or WorldQuestTracker.GameLocale == "ptBR" or WorldQuestTracker.GameLocale == "frFR") then
		return WorldQuestTracker.RewardIsArtifactPowerGerman (itemLink)
	end

	GameTooltipFrame:SetOwner (WorldFrame, "ANCHOR_NONE")
	GameTooltipFrame:SetHyperlink (itemLink)

	local text = GameTooltipFrameTextLeft1:GetText()
	if (text and text:match ("|cFFE6CC80")) then
		local power = GameTooltipFrameTextLeft3:GetText()
		if (power) then
		
			if (power:find (SECOND_NUMBER)) then
				local n = power:match (" %d+%.%d+ ")
				n = tonumber (n)
				if (not n) then
					n = power:match (" %d+ ")
					n = tonumber (n)
				end
				if (n) then
					n = n * 1000000
					return true, n or 0
				end
			end

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
		
			if (power:find (SECOND_NUMBER)) then
				local n = power:match (" %d+%.%d+ ")
				n = tonumber (n)
				if (not n) then
					n = power:match (" %d+ ")
					n = tonumber (n)
				end
				if (n) then
					n = n * 1000000
					return true, n or 0
				end
			end
		
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
	if (numQuestCurrencies == 2) then
		for i = 1, numQuestCurrencies do
			local name, texture, numItems = GetQuestLogRewardCurrencyInfo (i, questID)
			--legion invasion quest
			if (texture and 
				(
					(type (texture) == "number" and texture == 132775) or
					(type (texture) == "string" and (texture:find ("inv_datacrystal01") or texture:find ("inv_misc_summonable_boss_token")))
				)   
			) then -- [[Interface\Icons\inv_datacrystal01]]
			else
				return name, texture, numItems
			end
		end
	else
		for i = 1, numQuestCurrencies do
			local name, texture, numItems = GetQuestLogRewardCurrencyInfo (i, questID)
			return name, texture, numItems
		end
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
				
				if (icon and not WorldQuestTracker.db.profile.use_old_icons) then
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
		if (WorldQuestTracker.IsWorldQuestHub (GetCurrentMapAreaID()) or WorldQuestTracker.ZoneHaveWorldQuest (GetCurrentMapAreaID())) then
			WorldQuestTracker.DoubleTapFrame:Show()
			WorldQuestTracker.DoubleTapFrame:SetParent (WorldQuestTrackerWorldMapPOI)
			WorldQuestTracker.DoubleTapFrame:SetFrameStrata ((WorldMapFrame:GetFrameStrata()=="FULLSCREEN" and "FULLSCREEN") or "DIALOG") --thanks @humfras on curseforge
			WorldQuestTracker.DoubleTapFrame:SetFrameLevel (5000)
			--WorldQuestTracker.Debug ("is a map with worldquests: showing statusbar", WorldQuestTracker.DoubleTapFrame:IsShown(), WorldQuestTracker.DoubleTapFrame:GetParent():GetName())
		else
			WorldQuestTracker.DoubleTapFrame:Hide()
			--WorldQuestTracker.Debug ("hiding the statusbar")
		end
	end
end

WorldMapFrame:HookScript ("OnEvent", function (self, event)
	if (event == "WORLD_MAP_UPDATE") then
	
		--print ("WQT: world_map_update event")
		--if (true) then return end
	
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
		
		if (not zones_with_worldquests [self.mapID]) then --not calling the function just to make this faster
			if (WorldWidgetPool[1] and WorldWidgetPool[1]:IsShown()) then
				WorldQuestTracker.HideZoneWidgets()
			end
			if (WorldQuestTrackerToggleQuestsButton) then
				WorldQuestTrackerToggleQuestsButton:Show()
			end
		else
			if (WorldQuestTrackerToggleQuestsButton) then
				WorldQuestTrackerToggleQuestsButton:Hide()
			end
		end
		--se for um mapa qualquer e não for o world map -> esconder os widget do world map
		--fazer a mesma coisa para os widgets das zonas
		
		
		
		
	end
end)

--OnTick
local OnUpdateDelay = .5
local ActionButton = WorldMapFrame.UIElementsFrame.ActionButton

WorldMapFrame:HookScript ("OnUpdate", function (self, deltaTime)
	
	--[[
	if (ActionButton and ActionButton:IsShown()) then
		if (ActionButton.SpellButton.Cooldown:GetCooldownDuration() and ActionButton.SpellButton.Cooldown:GetCooldownDuration() > 0) then
			ActionButton:SetAlpha (.2)
		else
			ActionButton:SetAlpha (1)
		end
	end
	--]]

	--> hide blizzard widgets on the zone map (if scheduled)
	if (WorldQuestTracker.HideZoneWidgetsOnNextTick and not (WorldQuestTracker.Temp_HideZoneWidgets > GetTime())) then
		for i = 1, #WorldQuestTracker.AllTaskPOIs do
			if (WorldQuestTracker.CurrentZoneQuests [WorldQuestTracker.AllTaskPOIs [i].questID]) then
				WorldQuestTracker.AllTaskPOIs [i]:Hide()
			end
		end
		WorldQuestTracker.HideZoneWidgetsOnNextTick = false
	end
	
	if (WorldQuestTracker.CanShowZoneSummaryFrame()) then
		WorldMapFrame.UIElementsFrame.BountyBoard:ClearAllPoints()
		WorldMapFrame.UIElementsFrame.BountyBoard:SetPoint ("bottomright", WorldMapFrame.UIElementsFrame, "bottomright", -18, 15)
		
		--[[ --only in fullscreen
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
		--]]

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
	WorldQuestTracker.UpdateZoneWidgets (true)
	
	if (WorldQuestTracker.LastMapID ~= MAPID_BROKENISLES and WorldQuestTracker.IsPlayingLoadAnimation()) then
		WorldQuestTracker.StopLoadingAnimation()
	end
end
WorldMapButton:HookScript ("PreClick", deny_auto_switch)
WorldMapButton:HookScript ("PostClick", allow_map_change)

if (BrokenIslesArgusButton) then
	--> at the current PTR state, goes directly to argus map
	BrokenIslesArgusButton:HookScript ("OnClick", function (self)
		allow_map_change()
	end)
	--> argus map zone use an overlaied button for each of its three zones
	MacAreeButton:HookScript ("OnClick", function (self)
		allow_map_change()
	end)
	AntoranWastesButton:HookScript ("OnClick", function (self)
		allow_map_change()
	end)
	KrokuunButton:HookScript ("OnClick", function (self)
		allow_map_change()
	end)
end

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
	self.TextureCustom:Hide()
	self.RareOverlay:Hide()
end

-- ~zoneicon
function WorldQuestTracker.CreateZoneWidget (index, name, parent) --~zone
	local button = CreateFrame ("button", name .. index, parent)
	button:SetSize (20, 20)
	
	button:SetScript ("OnEnter", TaskPOI_OnEnter)
	button:SetScript ("OnLeave", TaskPOI_OnLeave)
	button:SetScript ("OnClick", questButton_OnClick)
	
	button:RegisterForClicks ("LeftButtonDown", "MiddleButtonDown", "RightButtonDown")
	
	local supportFrame = CreateFrame ("frame", nil, button)
	supportFrame:SetPoint ("center")
	supportFrame:SetSize (20, 20)
	button.SupportFrame = supportFrame
	
	button.UpdateTooltip = TaskPOI_OnEnter
	button.worldQuest = true
	button.ClearWidget = clear_widget
	
	button.RareOverlay = CreateFrame ("frame", button:GetName() .. "RareOverlay", button)
	button.RareOverlay:SetAllPoints()
	button.RareOverlay:SetScript ("OnEnter", WorldQuestTracker.RareWidgetOnEnter)
	button.RareOverlay:SetScript ("OnLeave", WorldQuestTracker.RareWidgetOnLeave)
	button.RareOverlay:Hide()
	
	button.Texture = supportFrame:CreateTexture (button:GetName() .. "Texture", "BACKGROUND")
	button.Texture:SetPoint ("center", button, "center")
	button.Texture:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
	
	button.TextureCustom = supportFrame:CreateTexture (button:GetName() .. "TextureCustom", "BACKGROUND")
	button.TextureCustom:SetPoint ("center", button, "center")
	button.TextureCustom:Hide()
	
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
	button.highlight:Hide()
	
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
	button.IsTrackingRareGlow:SetSize (44*0.7, 44*0.7)
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
	button.rareSerpent:SetPoint ("CENTER", 1, 0)
	
	-- é a sombra da serpente no fundo, pode ser na cor azul ou roxa
	button.rareGlow = supportFrame:CreateTexture (nil, "background")
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
	button.rareSerpent:SetDrawLayer ("BACKGROUND", -6)
	button.rareGlow:SetDrawLayer ("BACKGROUND", -7)
	
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

	taskPOI.Texture:Show()
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

function WorldQuestTracker.IsASubLevel()
	local level, x1 = GetCurrentMapDungeonLevel()
	--[[
	if (level and level >  0 and x1) then
		x1 = floor (x1)
		--vindicar antoran
		if (level == 5 and floor (x1) == 8479) then
			return true
		end
		
		--vindicar krokuun
		if (level == 1 and floor (x1) == 1302) then
			return true
		end
		
		--vindicar mccree
		if (level == 3 and floor (x1) == 9689) then
			return true
		end
	end
	--]]
	
	if (level and level > 0 and x1 and level < 8) then
		return true
	end
end

function WorldQuestTracker.GetOrLoadQuestData (questID, canCache)
	local data = WorldQuestTracker.CachedQuestData [questID]
	if (data) then
		return unpack (data)
	end

	local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical = GetQuestTagInfo (questID)
	local gold, goldFormated = WorldQuestTracker.GetQuestReward_Gold (questID)
	local rewardName, rewardTexture, numRewardItems = WorldQuestTracker.GetQuestReward_Resource (questID)
	local itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetQuestReward_Item (questID)
	local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
	
	if (WorldQuestTracker.CanCacheQuestData and canCache) then
		WorldQuestTracker.CachedQuestData [questID] = {title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount}
	end
	
	return title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount
end

function WorldQuestTracker.UpdateZoneWidgetAnchors()
	for i = 1, #WorldQuestTracker.Cache_ShownWidgetsOnZoneMap do
		local widget = WorldQuestTracker.Cache_ShownWidgetsOnZoneMap [i]
		WorldMapPOIFrame_AnchorPOI (widget, widget.PosX, widget.PosY, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.WORLD_QUEST)
	end
end

WorldMapScrollFrame:HookScript ("OnMouseWheel", function (self, delta)
	--> update widget anchors if the map is a world quest zone
	if (WorldQuestTracker.ZoneHaveWorldQuest()) then
		WorldQuestTracker.UpdateZoneWidgetAnchors()
	end
end)

--atualiza as quest do mapa da zona ~updatezone ~zoneupdate
function WorldQuestTracker.UpdateZoneWidgets (forceUpdate)
	
	local mapID = GetCurrentMapAreaID()
	
	if (WorldQuestTracker.IsWorldQuestHub (mapID) or (mapID ~= WorldQuestTracker.LastMapID and not WorldQuestTracker.IsArgusZone (mapID))) then
		return WorldQuestTracker.HideZoneWidgets()
		
	elseif (not WorldQuestTracker.ZoneHaveWorldQuest (mapID)) then
		return WorldQuestTracker.HideZoneWidgets()
		
	elseif (WorldQuestTracker.IsASubLevel()) then
		return WorldQuestTracker.HideZoneWidgets()
	end
	
	WorldQuestTracker.RefreshStatusBar()
	
	WorldQuestTracker.lastZoneWidgetsUpdate = GetTime() --why there's two timers?
	
	--stop the update if it already updated on this tick
	if (WorldQuestTracker.LastZoneUpdate and WorldQuestTracker.LastZoneUpdate == GetTime()) then
		return
	end
	
	--local taskInfo = GetQuestsForPlayerByMapID (mapID, 1007)
	local taskInfo
	if (mapID == WorldQuestTracker.MAPID_DALARAN) then
		--taskInfo = GetQuestsForPlayerByMapID (mapID, 1007)
		taskInfo = GetQuestsForPlayerByMapID (mapID) --fix from @legowxelab2z8 from curse
	else
		taskInfo = GetQuestsForPlayerByMapID (mapID, mapID)
	end
	
	local index = 1

	--parar a animação de loading
	if (WorldQuestTracker.IsPlayingLoadAnimation()) then
		WorldQuestTracker.StopLoadingAnimation()
	end	
	
	local filters = WorldQuestTracker.db.profile.filters
	local forceShowBrokenShore = WorldQuestTracker.db.profile.filter_force_show_brokenshore
	
	wipe (WorldQuestTracker.Cache_ShownQuestOnZoneMap)
	wipe (WorldQuestTracker.Cache_ShownWidgetsOnZoneMap)
	local total_Gold, total_Resources, total_APower = 0, 0, 0
	local scale = WorldQuestTracker.db.profile.zonemap_widgets.scale
	
	local questFailed = false
	local showBlizzardWidgets = WorldQuestTracker.Temp_HideZoneWidgets > GetTime()
	wipe (WorldQuestTracker.CurrentZoneQuests)
	
	if (taskInfo and #taskInfo > 0) then
	
		local needAnotherUpdate = false
	
		for i, info  in ipairs (taskInfo) do
			local questID = info.questId

			if (HaveQuestData (questID)) then
				local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
				if (isWorldQuest) then

					local isSuppressed = WorldMap_IsWorldQuestSuppressed (questID)
					local passFilters = WorldMap_DoesWorldQuestInfoPassFilters (info, true, true) --blizzard filters
					local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
					
					if (timeLeft == 0) then
						timeLeft = 1
					end
					
					if (not isSuppressed and passFilters and timeLeft and timeLeft > 0) then
						
						local can_cache = true
						if (not HaveQuestRewardData (questID)) then
							C_TaskQuest.RequestPreloadRewardData (questID)
							can_cache = false
							needAnotherUpdate = true
						end
						
						WorldQuestTracker.CurrentZoneQuests [questID] = true
						
						local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData (questID, can_cache)
						local filter, order = WorldQuestTracker.GetQuestFilterTypeAndOrder (worldQuestType, gold, rewardName, itemName, isArtifact, stackAmount, numRewardItems, rewardTexture)
						
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
						elseif (WorldQuestTracker.db.profile.zone_only_tracked) then
							if (not WorldQuestTracker.IsQuestBeingTracked (questID)) then
								passFilter = false
							end
						end

						if (passFilter or (forceShowBrokenShore and WorldQuestTracker.IsArgusZone (mapID))) then
							local widget = WorldQuestTracker.GetOrCreateZoneWidget (info, index)
							if (widget.questID ~= questID or forceUpdate or not widget.Texture:GetTexture()) then
								local selected = questID == GetSuperTrackedQuestID()
								local isCriteria = WorldMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty (questID)
								local isSpellTarget = SpellCanTargetQuest() and IsQuestIDValidSpellTarget (questID)
								
								widget.mapID = mapID
								widget.questID = questID
								widget.numObjectives = info.numObjectives
								widget.questName = title
								widget.Order = order or 1
								
								--> cache reward amount
								widget.Currency_Gold = gold or 0
								widget.Currency_ArtifactPower = artifactPower or 0
								widget.Currency_Resources = numRewardItems or 0
								
								widget.PosX = info.x
								widget.PosY = info.y

								local inProgress
								WorldQuestTracker.SetupWorldQuestButton (widget, worldQuestType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget, mapID)
								WorldMapPOIFrame_AnchorPOI (widget, info.x, info.y, WORLD_MAP_POI_FRAME_LEVEL_OFFSETS.WORLD_QUEST)
								widget:SetFrameLevel (1500 + floor (random (1, 30)))
								widget:Show()

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
								
								if (showBlizzardWidgets) then
									widget:Hide()
									for _, button in ipairs (WorldQuestTracker.AllTaskPOIs) do
										if (button.questID == questID) then
											button:Show()
										end
									end
								else
									widget:Show()
								end
							else
								if (showBlizzardWidgets) then
									widget:Hide()
									for _, button in ipairs (WorldQuestTracker.AllTaskPOIs) do
										if (button.questID == questID) then
											button:Show()
										end
									end
								else
									widget:Show()
									
									--> sum totals for the statusbar
									if (widget.Currency_Gold) then
										total_Gold = total_Gold + widget.Currency_Gold
									end
									if (widget.Currency_Resources) then
										total_Resources = total_Resources + widget.Currency_Resources
									end
									if (widget.Currency_ArtifactPower) then
										total_APower = total_APower + widget.Currency_ArtifactPower
									end
									
									--> add the widget to cache tables
									tinsert (WorldQuestTracker.Cache_ShownQuestOnZoneMap, questID)
									tinsert (WorldQuestTracker.Cache_ShownWidgetsOnZoneMap, widget)
								end
							end
							
							index = index + 1
						else
							--
						end
					end
				end
			else
				questFailed = true
				WorldQuestTracker.ScheduleZoneMapUpdate (1, true)
			end
		end
		
		if (needAnotherUpdate) then
			WorldQuestTracker.ScheduleZoneMapUpdate (0.5, true)
		end
		
		if (not WorldQuestTracker.CanCacheQuestData) then
			if (not WorldQuestTracker.PrepareToAllowCachedQuestData) then
				WorldQuestTracker.PrepareToAllowCachedQuestData = C_Timer.NewTimer (10, function()
					WorldQuestTracker.CanCacheQuestData = true
				end)
			end
		end
		
		if (not questFailed) then
			WorldQuestTracker.HideZoneWidgetsOnNextTick = true
			WorldQuestTracker.LastZoneUpdate = GetTime()
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
	
	WorldQuestTracker.UpdateRareIcons (index, mapID)
	
end

WorldMapActionButtonPressed = function()
	WorldQuestTracker.Temp_HideZoneWidgets = GetTime() + 5
	WorldQuestTracker.UpdateZoneWidgets (true)
	WorldQuestTracker.ScheduleZoneMapUpdate (6)
end
hooksecurefunc ("ClickWorldMapActionButton", function()
	WorldMapActionButtonPressed()
end)

--atualiza o widget da quest no mapa da zona ~setupzone ~updatezone ~zoneupdate

function WorldQuestTracker.ResetWorldQuestZoneButton (self)
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
	
	self.criteriaIndicator:Hide()
	self.criteriaIndicatorGlow:Hide()
	
	self.flagCriteriaMatchGlow:Hide()
	self.questTypeBlip:Hide()
	self.partySharedBlip:Hide()
	self.timeBlipRed:Hide()
	self.timeBlipOrange:Hide()
	self.timeBlipYellow:Hide()
	self.timeBlipGreen:Hide()
	self.blackGradient:Hide()
	self.Shadow:Hide()
	self.TextureCustom:Hide()
	
	self.RareOverlay:Hide()
	self.bgFlag:Hide()
	
	self.IsRare = nil
	self.RareName = nil
	self.RareSerial = nil	
	self.RareTime = nil
	self.RareOwner = nil
end

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
	
	WorldQuestTracker.ResetWorldQuestZoneButton (self)
	
	self.isSelected = selected
	self.isCriteria = isCriteria
	self.isSpellTarget = isSpellTarget
	
	self.flagText:Show()
	self.blackGradient:Show()
	self.Shadow:Show()

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
			--self.questTypeBlip:SetTexCoord (172/512, 201/512, 273/512, 301/512)
			self.questTypeBlip:SetTexCoord (219/512, 246/512, 478/512, 502/512) -- left right    top botton  --7.2.5
			self.questTypeBlip:SetTexCoord (387/512, 414/512, 378/512, 403/512) -- left right    top botton  --7.3
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
			if (name and not okay) then
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
					--self.Texture:SetMask (nil)
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
					
					--if (artifactPower >= 1000) then
					--	self.flagText:SetText (format ("%.1fK", artifactPower/1000))
						--self.flagText:SetText (comma_value (artifactPower))
					--else
					--	self.flagText:SetText (artifactPower)
					--end
					
					if (artifactPower >= 1000) then
						if (artifactPower > 999999) then -- 1M
							self.flagText:SetText (WorldQuestTracker.ToK (artifactPower))
						elseif (artifactPower > 9999) then
							self.flagText:SetText (WorldQuestTracker.ToK (artifactPower))
						else
							self.flagText:SetText (format ("%.1fK", artifactPower/1000))
						end
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
		else
		--	local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
		--	print ("no time left:", title, timeLeft)
		end
		
	else
		WorldQuestTracker.ScheduleZoneMapUpdate()
	end
end

--agenda uma atualização se algum dado de alguma quest não estiver disponível ainda
local do_zonemap_update = function (self)
	WorldQuestTracker.UpdateZoneWidgets (self.IsForceUpdate)
end
function WorldQuestTracker.ScheduleZoneMapUpdate (seconds, isForceUpdate)
	if (WorldQuestTracker.ScheduledZoneUpdate and not WorldQuestTracker.ScheduledZoneUpdate._cancelled) then
		--> if the previous schedule was a force update, make the new schedule be be a force update too
		if (WorldQuestTracker.ScheduledZoneUpdate.IsForceUpdate) then
			isForceUpdate = true
		end
		WorldQuestTracker.ScheduledZoneUpdate:Cancel()
	end
	WorldQuestTracker.ScheduledZoneUpdate = C_Timer.NewTimer (seconds or 1, do_zonemap_update)
	WorldQuestTracker.ScheduledZoneUpdate.IsForceUpdate = isForceUpdate
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> map automatization

--muda o mapa para o world map de broken isles
hooksecurefunc ("WorldMap_UpdateQuestBonusObjectives", function (self, event)

--	print ("WQT: updating bonus objetives")
--	if (true) then return end

	if (WorldMapFrame:IsShown() and not WorldQuestTracker.NoAutoSwitchToWorldMap) then
		if (WorldQuestTracker.CanShowBrokenIsles()) then
			SetMapByID (MAPID_BROKENISLES)
			WorldQuestTracker.CanChangeMap = true
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, false)
		end
	end
	
	--depois de ter executa o update, vamos hidar todos os widgets default e criar os nossos
	if (WorldQuestTracker.ZoneHaveWorldQuest (mapID)) then
		--roda nosso custom update e cria nossos proprios widgets
		WorldQuestTracker.UpdateZoneWidgets()
	end
end)

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

--ao abrir ou fechar o mapa ~toggle
hooksecurefunc ("ToggleWorldMap", function (self)
	if (true) then
		--return
	end
	
	WorldMapFrame.currentStandingZone = GetCurrentMapAreaID()
	
	if (GameCooltipFrame1 and GameCooltipFrame2) then
		GameCooltipFrame1:SetParent (UIParent)
		GameCooltipFrame2:SetParent (UIParent)
	end
	
	if (WorldMapFrame:IsShown()) then
		--animFrame:SetScript ("OnUpdate", tickAnimation)
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
				--PlaySound ("igMainMenuOptionCheckBoxOn")
				WorldQuestTracker.WorldQuestButton_Click = GetTime()
			end)
			WorldQuestButton:HookScript ("PreClick", deny_auto_switch)
			WorldQuestButton:HookScript ("PostClick", allow_map_change)

			local ToggleQuestsButton = CreateFrame ("button", "WorldQuestTrackerToggleQuestsButton", WorldMapFrame.UIElementsFrame)
			ToggleQuestsButton:SetSize (98, 20)
			ToggleQuestsButton:SetFrameLevel (1025)
			ToggleQuestsButton:SetPoint ("bottomleft", WorldQuestButton, "topleft", 0, 1)
			ToggleQuestsButton.Background = ToggleQuestsButton:CreateTexture (nil, "background")
			ToggleQuestsButton.Background:SetSize (98, 20)
			ToggleQuestsButton.Background:SetAtlas ("MapCornerShadow-Right")
			ToggleQuestsButton.Background:SetPoint ("bottomright", 2, -1)
			ToggleQuestsButton:SetNormalTexture ([[Interface\AddOns\WorldQuestTracker\media\toggle_quest_button]])
			ToggleQuestsButton:GetNormalTexture():SetTexCoord (0, 0.7890625, 0, .5)
			ToggleQuestsButton:SetPushedTexture ([[Interface\AddOns\WorldQuestTracker\media\toggle_quest_button_pushed]])
			ToggleQuestsButton:GetPushedTexture():SetTexCoord (0, 0.7890625, 0, .5)
			ToggleQuestsButton.TextLabel = DF:CreateLabel (ToggleQuestsButton, L["S_WORLDMAP_TOOGLEQUESTS"], DF:GetTemplate ("font", "WQT_TOGGLEQUEST_TEXT"))
			ToggleQuestsButton.TextLabel:SetPoint ("center", ToggleQuestsButton, "center")
			
			ToggleQuestsButton:SetScript ("OnClick", function()
				WorldQuestTracker.db.profile.disable_world_map_widgets = not WorldQuestTracker.db.profile.disable_world_map_widgets
				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
					WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
				end
			end)
			ToggleQuestsButton:SetScript ("OnMouseDown", function()
				ToggleQuestsButton.TextLabel:SetPoint ("center", ToggleQuestsButton, "center", -1, -1)
			end)
			ToggleQuestsButton:SetScript ("OnMouseUp", function()
				ToggleQuestsButton.TextLabel:SetPoint ("center", ToggleQuestsButton, "center")
			end)
			
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
					elseif (value == "disable_world_map_widgets") then
						WorldQuestTracker.db.profile.disable_world_map_widgets = value2
						if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
							WorldQuestTracker.UpdateWorldQuestsOnWorldMap()
							GameCooltip:Close()
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
				
				if (option == "rarescan") then
					WorldQuestTracker.db.profile.rarescan [value] = value2
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneWidgets()
					end
					GameCooltip:Close()
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
					
					elseif (option == "use_old_icons") then
						if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
							WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true, true, false, true)
						else
							WorldQuestTracker.UpdateZoneWidgets()
						end
					end
				end
				
				if (option == "zone_only_tracked") then
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						WorldQuestTracker.UpdateZoneWidgets()
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
			
			-- ~point

			--background
			local doubleTapBackground = WorldQuestTracker.DoubleTapFrame:CreateTexture (nil, "overlay")
			doubleTapBackground:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-HorizontalShadow]])
			doubleTapBackground:SetTexCoord (0, .5, 0, 1)
			doubleTapBackground:SetHeight (18)
			WorldQuestTracker.DoubleTapFrame.Background = doubleTapBackground
			
--			/dump WorldQuestTrackerDoubleTapFrame.Background:GetSize()
			--/run WorldQuestTrackerDoubleTapFrame:SetFrameLevel (5000)
			
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
				SummaryFrameUp.AccountLifeTime_Resources.text = format (L["S_QUESTTYPE_RESOURCE"] .. ": %s", WorldQuestTracker.ToK (acctLifeTime.resource or 0))
				SummaryFrameUp.AccountLifeTime_APower.text = format (L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s", WorldQuestTracker.ToK (acctLifeTime.artifact or 0))
				SummaryFrameUp.AccountLifeTime_QCompleted.text = format (L["S_QUESTSCOMPLETED"] .. ": %s", comma_value (questsLifeTime.total or 0))
				
				local chrLifeTime = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_REWARD, WQT_QUERYDB_LOCAL)
				chrLifeTime = chrLifeTime or {}
				local questsLifeTime = WorldQuestTracker.QueryHistory (WQT_QUERYTYPE_QUEST, WQT_QUERYDB_LOCAL)
				questsLifeTime = questsLifeTime or {}
				
				SummaryFrameUp.CharacterLifeTime_Gold.text = format (L["S_QUESTTYPE_GOLD"] .. ": %s", (chrLifeTime.gold or 0) > 0 and GetCoinTextureString (chrLifeTime.gold) or 0)
				SummaryFrameUp.CharacterLifeTime_Resources.text = format (L["S_QUESTTYPE_RESOURCE"] .. ": %s", WorldQuestTracker.ToK (chrLifeTime.resource or 0))
				SummaryFrameUp.CharacterLifeTime_APower.text = format (L["S_QUESTTYPE_ARTIFACTPOWER"] .. ": %s", WorldQuestTracker.ToK (chrLifeTime.artifact or 0))
				SummaryFrameUp.CharacterLifeTime_QCompleted.text = format (L["S_QUESTSCOMPLETED"] .. ": %s", comma_value (questsLifeTime.total or 0))
				
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
				--PlaySound ("igMainMenuOptionCheckBoxOn")
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
					twoWeeks = twoWeeks or {}
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
				if (WorldQuestTracker.IsWorldQuestHub (GetCurrentMapAreaID())) then
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
			
			local toggle_brokenshore_bypass = function()
				WorldQuestTracker.db.profile.filter_force_show_brokenshore = not WorldQuestTracker.db.profile.filter_force_show_brokenshore
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
				GameCooltip:AddLine ("$div")
				
				if (WorldQuestTracker.db.profile.filter_force_show_brokenshore) then
					GameCooltip:AddLine ("Ignore Argus")
					GameCooltip:AddLine ("World quets on Argus map will always be shown.", "", 2)
					GameCooltip:AddIcon ([[Interface\ICONS\70_inscription_vantus_rune_tomb]], 1, 1, 23*.54, 37*.40, 0, 1, 0, 1)
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 2, 16, 16, 0, 1, 0, 1, overlayColor, nil, true)
				else
					GameCooltip:AddLine ("Ignore Argus", "", 1, "silver")
					GameCooltip:AddLine ("World quets on Argus map will always be shown.", "", 2)
					GameCooltip:AddIcon (WQT_GENERAL_STRINGS_AND_ICONS.criteria.icon, 1, 1, 23*.54, 37*.40, l, r, t, b, nil, nil, true)
				end
				GameCooltip:AddMenu (1, toggle_brokenshore_bypass)
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
				
				GameCooltip:AddLine (format (L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"], "0.8"), "", 2)
				GameCooltip:AddMenu (2, options_on_click, "tracker_scale", 0.8)				
				GameCooltip:AddLine (format (L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"], "1.0"), "", 2)
				GameCooltip:AddMenu (2, options_on_click, "tracker_scale", 1)
				GameCooltip:AddLine (format (L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"], "1.1"), "", 2)
				GameCooltip:AddMenu (2, options_on_click, "tracker_scale", 1.1)
				GameCooltip:AddLine (format (L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"], "1.2"), "", 2)
				GameCooltip:AddMenu (2, options_on_click, "tracker_scale", 1.2)
				GameCooltip:AddLine (format (L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"], "1.3"), "", 2)
				GameCooltip:AddMenu (2, options_on_click, "tracker_scale", 1.3)
				GameCooltip:AddLine (format (L["S_MAPBAR_OPTIONSMENU_TRACKER_SCALE"], "1.5"), "", 2)
				GameCooltip:AddMenu (2, options_on_click, "tracker_scale", 1.5)
				
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

				GameCooltip:AddLine ("Disable Icons on World Map", "", 2)
				if (WorldQuestTracker.db.profile.disable_world_map_widgets) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (2, options_on_click, "world_map_config", "disable_world_map_widgets", not WorldQuestTracker.db.profile.disable_world_map_widgets)
				GameCooltip:AddLine ("$div", nil, 2, nil, -7, -14)
				
				
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
				
				GameCooltip:AddLine ("$div", nil, 2, nil, -7, -14)
				
				GameCooltip:AddLine ("Only Tracked", "", 2)
				if (WorldQuestTracker.db.profile.zone_only_tracked) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (2, options_on_click, "zone_only_tracked", not WorldQuestTracker.db.profile.zone_only_tracked)
				
				do
					--group finder config
					GameCooltip:AddLine (L["S_GROUPFINDER_TITLE"])
					GameCooltip:AddIcon ([[Interface\LFGFRAME\BattlenetWorking1]], 1, 1, IconSize, IconSize, .22, .78, .22, .78)
					
					--enabled
					GameCooltip:AddLine (L["S_GROUPFINDER_ENABLED"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.enabled) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetEnabledFunc, not WorldQuestTracker.db.profile.groupfinder.enabled)
					
					--find group for rares
					GameCooltip:AddLine (L["S_GROUPFINDER_AUTOOPEN_RARENPC_TARGETED"], "", 2)
					if (WorldQuestTracker.db.profile.rarescan.search_group) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetFindGroupForRares, not WorldQuestTracker.db.profile.rarescan.search_group)						
					
					--find invasion points
					GameCooltip:AddLine (L["S_GROUPFINDER_INVASION_ENABLED"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.invasion_points) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetFindInvasionPoints, not WorldQuestTracker.db.profile.groupfinder.invasion_points)					
					
					
					--uses buttons on the quest tracker
					GameCooltip:AddLine (L["S_GROUPFINDER_OT_ENABLED"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.tracker_buttons) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetOTButtonsFunc, not WorldQuestTracker.db.profile.groupfinder.tracker_buttons)					
					
					--
					--GameCooltip:AddLine ("$div", nil, 1, nil, -5, -11)
					--
					GameCooltip:AddLine ("$div", nil, 2, nil, -7, -14)
					--GameCooltip:AddLine ("Leave Group")
					--GameCooltip:AddIcon ([[Interface\AddOns\WorldQuestTracker\media\ArrowGridT]], 1, 1, IconSize, IconSize, 944/1024, 993/1024, 272/1024, 324/1024)
					
					--leave group
					GameCooltip:AddLine (L["S_GROUPFINDER_LEAVEOPTIONS_IMMEDIATELY"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.autoleave) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetAutoGroupLeaveFunc, not WorldQuestTracker.db.profile.groupfinder.autoleave, "autoleave")
					
					GameCooltip:AddLine (L["S_GROUPFINDER_LEAVEOPTIONS_AFTERX"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.autoleave_delayed) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetAutoGroupLeaveFunc, not WorldQuestTracker.db.profile.groupfinder.autoleave_delayed, "autoleave_delayed")
					
					GameCooltip:AddLine (L["S_GROUPFINDER_LEAVEOPTIONS_ASKX"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.askleave_delayed) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetAutoGroupLeaveFunc, not WorldQuestTracker.db.profile.groupfinder.askleave_delayed, "askleave_delayed")
					
					GameCooltip:AddLine (L["S_GROUPFINDER_LEAVEOPTIONS_DONTLEAVE"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.noleave) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetAutoGroupLeaveFunc, not WorldQuestTracker.db.profile.groupfinder.noleave, "noleave")					
					
					--
					GameCooltip:AddLine ("$div", nil, 2, nil, -5, -11)
					--ask to leave with timeout
					GameCooltip:AddLine ("10 " .. L["S_GROUPFINDER_SECONDS"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.leavetimer == 10) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetGroupLeaveTimeoutFunc, 10)
					
					GameCooltip:AddLine ("15 " .. L["S_GROUPFINDER_SECONDS"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.leavetimer == 15) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetGroupLeaveTimeoutFunc, 15)
					
					GameCooltip:AddLine ("20 " .. L["S_GROUPFINDER_SECONDS"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.leavetimer == 20) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetGroupLeaveTimeoutFunc, 20)
					
					GameCooltip:AddLine ("30 " .. L["S_GROUPFINDER_SECONDS"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.leavetimer == 30) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetGroupLeaveTimeoutFunc, 30)
					
					GameCooltip:AddLine ("60 " .. L["S_GROUPFINDER_SECONDS"], "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.leavetimer == 60) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetGroupLeaveTimeoutFunc, 60)
					
					GameCooltip:AddLine ("$div", nil, 2, nil, -5, -11)
					
					--no pvp realms
					GameCooltip:AddLine ("Avoid PVP Servers", "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.nopvp) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetAvoidPVPFunc, not WorldQuestTracker.db.profile.groupfinder.nopvp)					
					
					--kick afk players
					GameCooltip:AddLine ("Kick AFKs", "", 2)
					if (WorldQuestTracker.db.profile.groupfinder.noafk) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, ff.Options.SetNoAFKFunc, not WorldQuestTracker.db.profile.groupfinder.noafk)					
				end
				
				--rare finder
					GameCooltip:AddLine (L["S_RAREFINDER_TITLE"])
					GameCooltip:AddIcon ([[Interface\Collections\Collections]], 1, 1, IconSize, IconSize, 101/512, 116/512, 12/512, 26/512)

					--enabled
					GameCooltip:AddLine (L["S_RAREFINDER_OPTIONS_SHOWICONS"], "", 2)
					if (WorldQuestTracker.db.profile.rarescan.show_icons) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, options_on_click, "rarescan", "show_icons", not WorldQuestTracker.db.profile.rarescan.show_icons)	

					--english only
					GameCooltip:AddLine (L["S_RAREFINDER_OPTIONS_ENGLISHSEARCH"], "", 2)
					if (WorldQuestTracker.db.profile.rarescan.always_use_english) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, options_on_click, "rarescan", "always_use_english", not WorldQuestTracker.db.profile.rarescan.always_use_english)	
					
					GameCooltip:AddLine ("$div", nil, 2, nil, -5, -11)
					
					--play audion on spot a rare
					GameCooltip:AddLine ("Play Sound Alert", "", 2)
					if (WorldQuestTracker.db.profile.rarescan.playsound) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, options_on_click, "rarescan", "playsound", not WorldQuestTracker.db.profile.rarescan.playsound)
					
					GameCooltip:AddLine ("Volume: 100%", "", 2)
					if (WorldQuestTracker.db.profile.rarescan.playsound_volume == 1) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, options_on_click, "rarescan", "playsound_volume", 1)
					
					GameCooltip:AddLine ("Volume: 50%", "", 2)
					if (WorldQuestTracker.db.profile.rarescan.playsound_volume == 2) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, options_on_click, "rarescan", "playsound_volume", 2)

					GameCooltip:AddLine ("Volume: 30%", "", 2)
					if (WorldQuestTracker.db.profile.rarescan.playsound_volume == 3) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, options_on_click, "rarescan", "playsound_volume", 3)
					
					GameCooltip:AddLine ("Play Even When Sound Effects Are Disabled", "", 2)
					if (WorldQuestTracker.db.profile.rarescan.use_master) then
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 2, 1, 16, 16)
					else
						GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 2, 1, 16, 16, .4, .6, .4, .6)
					end
					GameCooltip:AddMenu (2, options_on_click, "rarescan", "use_master", not WorldQuestTracker.db.profile.rarescan.use_master)

				-- other options
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
				GameCooltip:AddLine (L["S_MAPBAR_OPTIONSMENU_EQUIPMENTICONS"])
				if (WorldQuestTracker.db.profile.use_old_icons) then
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-CheckBox-Check]], 1, 1, 16, 16)
				else
					GameCooltip:AddIcon ([[Interface\BUTTONS\UI-AutoCastableOverlay]], 1, 1, 16, 16, .4, .6, .4, .6)
				end
				GameCooltip:AddMenu (1, options_on_click, "use_old_icons", not WorldQuestTracker.db.profile.use_old_icons)
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
			partyFrame:Hide()

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
				
					--7.2 need to get the artifact tier
					local artifactItemID, _, _, _, artifactTotalXP, artifactPointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
					--then request the xp details
					local numPointsAvailableToSpend, xp, xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP (pointsSpent, totalXP, artifactTier)

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
			
		elseif (WorldQuestTracker.IsWorldQuestHub (WorldMapFrame.mapID)) then
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
			
		else
			WorldQuestTracker.HideWorldQuestsOnWorldMap()
			--print ("eh pra hidar...")
			
			--is zone map?
			if (WorldQuestTracker.ZoneHaveWorldQuest (WorldMapFrame.mapID)) then
				--roda nosso custom update e cria nossos proprios widgets
				WorldQuestTracker.UpdateZoneWidgets (true)
				C_Timer.After (1.35, function()
					if (WorldQuestTracker.ZoneHaveWorldQuest (WorldMapFrame.mapID)) then
						WorldQuestTracker.UpdateZoneWidgets (true)
					end
				end)
			end
			
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

	local x = 75
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
	summaryWidget.Text:SetText (type (zoneWidget.IconText) == "number" and WorldQuestTracker.ToK (zoneWidget.IconText) or zoneWidget.IconText)

	summaryWidget.BlackBackground:SetAlpha (.4)
	summaryWidget.Highlight:SetAlpha (.2)
	
	summaryWidget:Show()
end

function WorldQuestTracker.CanShowZoneSummaryFrame()
	return WorldQuestTracker.db.profile.use_quest_summary and WorldQuestTracker.ZoneHaveWorldQuest() and not WorldMapFrame_InWindowedMode()
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
			if (WorldQuestTracker.IsCurrentMapQuestHub()) then
				--refresh no world map
				WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
			elseif (WorldQuestTracker.ZoneHaveWorldQuest()) then
				--refresh nos widgets
				WorldQuestTracker.UpdateZoneWidgets()
				WorldQuestTracker.WorldWidgets_NeedFullRefresh = true
			end
		else
			WorldQuestTracker.WorldWidgets_NeedFullRefresh = true
		end
	else
		if (button == "MiddleButton") then
			--was middle button and our group finder is enabled
			if (WorldQuestTracker.db.profile.groupfinder.enabled) then
				WorldQuestTracker.FindGroupForQuest (self.questID)
				return
			end
			
			--middle click without our group finder enabled, check for other addons
			if (WorldQuestGroupFinderAddon) then
				WorldQuestGroupFinder.HandleBlockClick (self.questID)
				return
			end
		end
	
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
	if (button == "MiddleButton") then
		--was middle button and our group finder is enabled
		if (WorldQuestTracker.db.profile.groupfinder.enabled) then
			WorldQuestTracker.FindGroupForQuest (self.questID)
			return
		end
		
		--middle click without our group finder enabled, check for other addons
		if (WorldQuestGroupFinderAddon) then
			WorldQuestGroupFinder.HandleBlockClick (self.questID)
			return
		end
	end

	if (self.questID == GetSuperTrackedQuestID()) then
		WorldQuestTracker.SuperTracked = nil
		QuestSuperTracking_ChooseClosestQuest()
		return
	end
	
	if (HaveQuestData (self.questID)) then
		WorldQuestTracker.SelectSingleQuestInBlizzardWQTracker (self.questID) --thanks @ilintar on CurseForge
		--SetSuperTrackedQuestID (self.questID)
		WorldQuestTracker.RefreshTrackerWidgets()
		WorldQuestTracker.SuperTracked = self.questID
	end
end

-- ãrrow ~arrow

--from the user @ilintar on CurseForge
--Doing that instead of just SetSuperTrackedQuestID(questID) will make the arrow stay. The code also ensures that only the selected world quest is present in the Blizzard window, as to not make it cluttered.
	function WorldQuestTracker.SelectSingleQuestInBlizzardWQTracker (questID)
		for i = 1, GetNumWorldQuestWatches() do
			local watchedWorldQuestID = GetWorldQuestWatchInfo(i);
			if (watchedWorldQuestID) then
				BonusObjectiveTracker_UntrackWorldQuest(watchedWorldQuestID)
			end
		end
		BonusObjectiveTracker_TrackWorldQuest(questID, true)
		SetSuperTrackedQuestID (questID)
	end
--

--> overwriting this was causing taint issues	
--[=[
--rewrite QuestSuperTracking_IsSuperTrackedQuestValid to avoid conflict with World Quest Tracker
function QuestSuperTracking_IsSuperTrackedQuestValid()
	local trackedQuestID = GetSuperTrackedQuestID();
	if trackedQuestID == 0 then
		return false;
	end

	if GetQuestLogIndexByID(trackedQuestID) == 0 then
		-- Might be a tracked world quest that isn't in our log yet (blizzard)
		-- adding here if the quest is tracked by World Quest Tracker (tercio)
		if (QuestUtils_IsQuestWorldQuest(trackedQuestID) and WorldQuestTracker.SuperTracked == trackedQuestID) then
			return true
		end
		if QuestUtils_IsQuestWorldQuest(trackedQuestID) and IsWorldQuestWatched(trackedQuestID) then
			return C_TaskQuest.IsActive(trackedQuestID);
		end
		return false;
	end

	return true;
end
--]=]

--> thise functions isn't being used at the moment
--[=[
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
--]=]
--[=[
hooksecurefunc ("QuestSuperTracking_ChooseClosestQuest", function()
	if (WorldQuestTracker.SuperTracked) then
		--delay increased from 20ms to 200ms to avoid lag spikes
		C_Timer.After (.2, UpdateSuperQuestTracker)
	end
end)
--]=]


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
	f:RegisterForClicks ("LeftButtonDown", "MiddleButtonDown", "RightButtonDown")
	
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
	f.Icon:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
	
	local IconButton = CreateFrame ("button", "$parentIconButton", f)
	IconButton:SetSize (18, 18)
	IconButton:SetPoint ("center", f.Icon, "center")
	IconButton:SetScript ("OnEnter", TrackerIconButtonOnEnter)
	IconButton:SetScript ("OnLeave", TrackerIconButtonOnLeave)
	IconButton:SetScript ("OnClick", TrackerIconButtonOnClick)
	IconButton:SetScript ("OnMouseDown", TrackerIconButtonOnMouseDown)
	IconButton:SetScript ("OnMouseUp", TrackerIconButtonOnMouseUp)
	IconButton:RegisterForClicks ("LeftButtonDown", "MiddleButtonDown")
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

	if (WorldQuestTracker.LastTrackerRefresh and WorldQuestTracker.LastTrackerRefresh+0.2 > GetTime()) then
		return
	end
	WorldQuestTracker.LastTrackerRefresh = GetTime()

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
				
				--> the widget will always have the mask enabled
				--if (quest.questType == QUESTTYPE_ARTIFACTPOWER) then
					--widget.Icon:SetMask (nil)
					--widget.Icon:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
				--else
					--widget.Icon:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
				--end
				
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
					widget.questX, widget.questY = x or 0, y or 0
					
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
			
			if (WorldQuestTracker.db.profile.groupfinder.tracker_buttons) then
				for questID, block in pairs (module.usedBlocks) do
					ff.HandleBTrackerBlock (questID, block)
				end
			end
			
			--> is a module for world quests?
			--if (module.DefaultHeaderText == TRACKER_HEADER_WORLD_QUESTS) then
				--> which blocks are active showing a world quest
			--		if (type (questID) == "number" and HaveQuestData (questID) and QuestMapFrame_IsQuestWorldQuest (questID)) then
			
			--		end
			--	end
			--end

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
	
		--local taskInfo = GetQuestsForPlayerByMapID (mapId, 1007)
		local taskInfo = GetQuestsForPlayerByMapID (mapId)
		
		if (taskInfo and #taskInfo > 0) then
			for i, info  in ipairs (taskInfo) do
				local questID = info.questId
				if (HaveQuestData (questID)) then
					local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
					if (isWorldQuest) then
						if (not HaveQuestRewardData (questID)) then
							C_TaskQuest.RequestPreloadRewardData (questID)
						end
						
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

function WorldQuestTracker.UpdatePinAfterZoom (timerObject)
	local pin = timerObject.Pin
	pin._UpdateTimer = nil
	pin:SetAlpha (1)
	pin:Show()
end

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
		
		hooksecurefunc (FlightMapFrame.ScrollContainer, "ZoomIn", function()
			WorldQuestTracker.FlightMapZoomAt = GetTime()
		end)
		hooksecurefunc (FlightMapFrame.ScrollContainer, "ZoomOut", function()
			WorldQuestTracker.FlightMapZoomAt = GetTime()
		end)
		
		hooksecurefunc (FlightMapFrame, "ApplyPinPosition", function (self, pin, normalizedX, normalizedY, insetIndex)
			--print ("setting pin poisition")
			
			if (not pin.questID or not QuestMapFrame_IsQuestWorldQuest (pin.questID)) then
				--print (self.questID)
				--print (pin._WQT_Twin and pin._WQT_Twin.questID)
				--print (pin.Icon, self.Icon)
				
				--[=[
				if (pin.HookScript) then
					pin:HookScript ("OnEnter", function()
						print ("====================================")
						for a, b in pairs (pin) do
							print (a, b)
						end
						print ("====================================")
						print (pin.Texture:GetTexture())
					end)
				end
				--]=]
				
				--> invasion point
				if (pin.Texture and pin.Texture:GetTexture() == 1121272) then
					pin:SetAlpha (1)
					pin:Show()
					
					if (not pin._UpdateTimer) then
						pin._UpdateTimer = C_Timer.NewTimer (1, WorldQuestTracker.UpdatePinAfterZoom)
						pin._UpdateTimer.Pin = pin
					end
					
					--if (WorldQuestTracker.FlightMapZoomAt and WorldQuestTracker.FlightMapZoomAt + 1 > GetTime()) then
					--	if (not pin._UpdateTimer) then
					--		pin._UpdateTimer = C_Timer.NewTimer (1, WorldQuestTracker.UpdatePinAfterZoom)
					--		pin._UpdateTimer.Pin = pin
					--	end
					--end
				end
				
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
			local filter = WorldQuestTracker.GetQuestFilterTypeAndOrder (worldQuestType, gold, rewardName, itemName, isArtifact, quantity, numRewardItems, rewardTexture)
			
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
					pin._WQT_Twin:SetScale (2.2)
					pin:SetAlpha (0)
					pin.TimeLowFrame:SetAlpha (0)
					pin.Underlay:SetAlpha (0)
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
		widgets = {},
		Anchor_X = 0.01,
		Anchor_Y = 0.52,
		GrowRight = true,
		show_on_map = WorldQuestTracker.MAPID_BROKENISLES,
	},
	[valsharah_mapId] = {
		widgets = {},
		Anchor_X = 0.01,
		Anchor_Y = 0.37,
		GrowRight = true,
		show_on_map = WorldQuestTracker.MAPID_BROKENISLES,
	},
	[highmountain_mapId] = {
		widgets = {},
		Anchor_X = 0.01,
		Anchor_Y = 0.20,
		GrowRight = true,
		show_on_map = WorldQuestTracker.MAPID_BROKENISLES,
	},
	[stormheim_mapId] = {
		widgets = {},
		Anchor_X = 0.99,
		Anchor_Y = 0.37,
		show_on_map = WorldQuestTracker.MAPID_BROKENISLES,
	},
	[suramar_mapId] = {
		widgets = {},
		Anchor_X = 0.99,
		Anchor_Y = 0.52,
		show_on_map = WorldQuestTracker.MAPID_BROKENISLES,
	},
	[1021] = { --broken shore
		widgets = {},
		Anchor_X = 0.99,
		Anchor_Y = 0.67,
		show_on_map = WorldQuestTracker.MAPID_BROKENISLES,
	},	
	[eoa_mapId] = {
		widgets = {},
		Anchor_X = 0.5,
		Anchor_Y = 0.8,
		GrowRight = true,
		show_on_map = WorldQuestTracker.MAPID_BROKENISLES,
	},
	[WorldQuestTracker.MAPID_DALARAN] = {
		widgets = {},
		Anchor_X = 0.47,
		Anchor_Y = 0.62,
		GrowRight = true,
		show_on_map = WorldQuestTracker.MAPID_BROKENISLES,
	},
	
	[1170] = { --mccree
		widgets = {},
		Anchor_X = 0.01,
		Anchor_Y = 0.20,
		show_on_map = WorldQuestTracker.MAPID_ARGUS,
		GrowRight = true,
	},	
	[1171] = { --antoran
		widgets = {},
		Anchor_X = 0.01,
		Anchor_Y = 0.37,
		show_on_map = WorldQuestTracker.MAPID_ARGUS,
		GrowRight = true,
	},	
	[1135] = { --krokuun
		widgets = {},
		Anchor_X = 0.01,
		Anchor_Y = 0.52,
		show_on_map = WorldQuestTracker.MAPID_ARGUS,
		GrowRight = true,
	},
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

--cria uma square widget no world map ~world ~createworld ~createworldwidget
local create_worldmap_square = function (mapName, index)
	local button = CreateFrame ("button", "WorldQuestTrackerWorldMapPOI" .. mapName .. "POI" .. index, worldFramePOIs)
	button:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	button.IsWorldQuestButton = true
	button:SetFrameLevel (302)
	
	button:SetScript ("OnEnter", questButton_OnEnter)
	button:SetScript ("OnLeave", questButton_OnLeave)
	button:SetScript ("OnClick", questButton_OnClick)
	
	button:RegisterForClicks ("LeftButtonDown", "MiddleButtonDown", "RightButtonDown")
	
--	local groupButton = CreateFrame ("button", "WorldQuestTrackerWorldMapPOI" .. mapName .. "POI" .. index .. "LFG", button, "QuestObjectiveFindGroupButtonTemplate")
--	groupButton:SetPoint ("bottomright", button, "bottomright")
--	groupButton:SetSize (10, 10)
--	button.GroupButton = groupButton
	
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
	
	local invasionBorder = button:CreateTexture (nil, "artwork", 1)
	invasionBorder:SetPoint ("topleft", button, "topleft")
	invasionBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\border_legionT]])
	invasionBorder:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	
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
	--shineAnimation:SetAllPoints()
	shineAnimation:SetPoint ("topleft", 4, -2)
	shineAnimation:SetPoint ("bottomright", 0, 1)
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
	button.invasionBorder = invasionBorder
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

WorldQuestTracker.QUEST_POI_FRAME_WIDTH = 1
WorldQuestTracker.QUEST_POI_FRAME_HEIGHT = 1
WorldQuestTracker.NextWorldMapWidget = 1
WorldQuestTracker.WorldMapSquares = {}

--> anchor for world quests hub, this is only shown on world maps
function WorldQuestTracker.UpdateAllWorldMapAnchors (worldMapID)
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
	
		if (configTable.show_on_map == worldMapID) then
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
			
			configTable.MapAnchor:Show()
			configTable.factionFrame:Show()
		else
			configTable.MapAnchor:Hide()
			configTable.factionFrame:Hide()
		end
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

function WorldQuestTracker.GetWorldMapWidget (configTable, showTimeLeftText)
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
			if (configTable.WidgetNumber == 21) then --21 disabling this feature due to argus be in the map
				if (showTimeLeftText) then
					widget:SetPoint ("topright", configTable.MapAnchor, "topleft", 0, -50)
				else
					widget:SetPoint ("topright", configTable.MapAnchor, "topleft", 0, -40)
				end
			else
				widget:SetPoint ("topright", configTable.LastWidget, "topleft", -1, 0)
			end
		else
			widget:SetPoint ("topright", configTable.MapAnchor, "topleft", 0, 0)
		end
	end
	
	widget:SetAlpha (.75)
	
	configTable.LastWidget = widget
	configTable.WidgetNumber = configTable.WidgetNumber + 1
	
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
		configTable.WidgetNumber = 1
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
end

create_world_widgets()

--agenda uma atualização nos widgets do world map caso os dados das quests estejam indisponíveis
local do_worldmap_update = function()
	if (WorldQuestTracker.IsWorldQuestHub (GetCurrentMapAreaID())) then
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
function WorldQuestTracker.GetQuestFilterTypeAndOrder (worldQuestType, gold, rewardName, itemName, isArtifact, stackAmount, numRewardItems, rewardTexture)
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
	end	
	
--	if (type (rewardTexture) == "number") then
--		print (rewardName, rewardTexture)
--	end
--	Legionfall War Supplies 1017868
	
	-- check if this is a order hall resource
	-- = to string since legionfall resource icons is number
	--if (rewardName and (type (rewardTexture) == "string" and rewardTexture:find ("inv_orderhall_orderresources"))) then
	--1397630 = order hall resource icon - since 7.2.5 is a number
	
	-- and ((type(rewardTexture) == "string" and rewardTexture:find("inv_orderhall_orderresources")) or (type(rewardTexture) == "number" and rewardTexture == 1397630))
	
	if (rewardName) then
		if (rewardTexture == 1397630) then --order hall resources (legion)
			order = WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_RESOURCE]
			filter = FILTER_TYPE_GARRISON_RESOURCE
		elseif (rewardTexture == 1064188) then --veiled argunite (legion)
			order = WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_TRADE]
			filter = FILTER_TYPE_TRADESKILL
		elseif (rewardTexture == 399041) then --argus waystone (legion)
			order = WorldQuestTracker.db.profile.sort_order [WQT_QUESTTYPE_TRADE]
			filter = FILTER_TYPE_TRADESKILL
		end
	end	
	
	if (isArtifact) then
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

-- ~world
function WorldQuestTracker.UpdateWorldQuestsOnWorldMap (noCache, showFade, isQuestFlaggedRecheck, forceCriteriaAnimation)

	--print (debugstack())
	
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
		
	elseif (WorldQuestTracker.db.profile.disable_world_map_widgets) then
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
		return
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
	local forceShowBrokenShore = WorldQuestTracker.db.profile.filter_force_show_brokenshore

	local sortByTimeLeft = WorldQuestTracker.db.profile.force_sort_by_timeleft
	local worldMapID = GetCurrentMapAreaID()

	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
	
		questsAvailable [mapId] = {}

		local taskInfo = GetQuestsForPlayerByMapID (mapId, mapId) --, WorldQuestTracker.MAPID_ARGUS
		
		local shownQuests = 0

		if (taskInfo and #taskInfo > 0 and configTable.show_on_map == worldMapID) then
		
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
							--if (numRewardItems and numRewardItems > 1) then
							--	print (rewardName, rewardTexture, numRewardItems)
							--end
							
							local filter, order = WorldQuestTracker.GetQuestFilterTypeAndOrder (worldQuestType, gold, rewardName, itemName, isArtifact, stackAmount, numRewardItems, rewardTexture)
							order = order or 1
							
							if (sortByTimeLeft) then
								order = abs (timeLeft - 10000)
							elseif (timePriority) then --timePriority já multiplicado por 60
								if (timeLeft < timePriority) then
									order = abs (timeLeft - 1000)
								end
							end

							if (filters [filter] or rarity == LE_WORLD_QUEST_QUALITY_EPIC or (forceShowBrokenShore and WorldQuestTracker.IsArgusZone (mapId))) then --force show broken shore questsmapId == 1021
								tinsert (questsAvailable [mapId], {questID, order, info.numObjectives})
								shownQuests = shownQuests + 1
								
							elseif (WorldQuestTracker.db.profile.filter_always_show_faction_objectives) then
									local isCriteria = WorldMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty (questID)
									if (isCriteria) then
										tinsert (questsAvailable [mapId], {questID, order, info.numObjectives})
										shownQuests = shownQuests + 1
									end
								--end
							else
								--if (mapId == 1033) then
								--	print ("DENIED:", i, title, filter)
								--end
							end
						else
						--	local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
						--	print ("no time left:", title, timeLeft)
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
	
	local worldMapID = GetCurrentMapAreaID()
	
	for mapId, configTable in pairs (WorldQuestTracker.mapTables) do
		--local taskInfo = GetQuestsForPlayerByMapID (mapId, 1007)
		local taskInfo = GetQuestsForPlayerByMapID (mapId, mapId)
		local taskIconIndex = 1
		local widgets = configTable.widgets
		
		if (taskInfo and #taskInfo > 0) then
			availableQuests = availableQuests + #taskInfo
		
			for i, quest in ipairs (questsAvailable [mapId]) do
				
				local questID = quest [1]
				local numObjectives = quest [3]
				
				if (HaveQuestData (questID)) then
					local isWorldQuest = QuestMapFrame_IsQuestWorldQuest (questID)
					
					if (isWorldQuest) then
						if (not HaveQuestRewardData (questID)) then
							C_TaskQuest.RequestPreloadRewardData (questID)
						end
						
						--se é nova
						local isNew = WorldQuestTracker.SavedQuestList_IsNew (questID)
						--isNew = true --debug
						
						--info
						local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
						
						--tempo restante
						local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
						if (timeLeft == 0) then
							timeLeft = 1
						end

						if (timeLeft and timeLeft > 0) then
							local isCriteria = WorldMapFrame.UIElementsFrame.BountyBoard:IsWorldQuestCriteriaForSelectedBounty (questID)
							if (isCriteria) then
								factionAmountForEachMap [mapId] = (factionAmountForEachMap [mapId] or 0) + 1
							end
						
							--local widget = widgets [taskIconIndex]
							local widget = WorldQuestTracker.GetWorldMapWidget (configTable, showTimeLeftText)
							
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
										--widget.questTypeBlip:SetTexCoord (172/512, 201/512, 273/512, 301/512)
										widget.questTypeBlip:SetTexCoord (219/512, 246/512, 478/512, 502/512) -- left right    top botton --7.2.5
										widget.questTypeBlip:SetTexCoord (387/512, 414/512, 378/512, 403/512) -- left right    top botton --7.3
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
									
									if (rewardName and not okey) then
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
									end
									
									if (itemName) then
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
												if (artifactPower > 999999) then
													--widget.amountText:SetText (format ("%.1fM", artifactPower/1000000))
													widget.amountText:SetText (WorldQuestTracker.ToK (artifactPower))
													
												elseif (artifactPower > 9999) then
													--widget.amountText:SetText (format ("%.0fK", artifactPower/1000))
													widget.amountText:SetText (WorldQuestTracker.ToK (artifactPower))
												else
													widget.amountText:SetText (format ("%.1fK", artifactPower/1000))
												end
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
	
	--> need update the anchors for windowed and fullscreen modes, plus need to show and hide for different worlds
	WorldQuestTracker.UpdateAllWorldMapAnchors (worldMapID)

	WorldQuestTracker.HideZoneWidgets()
	WorldQuestTracker.SavedQuestList_CleanUp()
	
	calcPerformance.DumpTime = 0
end

--quando clicar no botão de por o world map em fullscreen ou window mode, reajustar a posição dos widgets
if (WorldMapFrameSizeDownButton) then
	WorldMapFrameSizeDownButton:HookScript ("OnClick", function() --window mode
		if (WorldQuestTracker.UpdateWorldQuestsOnWorldMap) then
			if (WorldQuestTracker.IsCurrentMapQuestHub()) then
				WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
				WorldQuestTracker.RefreshStatusBar()
				C_Timer.After (1, WorldQuestTracker.RefreshStatusBar)
			end
		end
	end)
	
elseif (MinimizeButton) then
	MinimizeButton:HookScript ("OnClick", function() --window mode
		if (WorldQuestTracker.UpdateWorldQuestsOnWorldMap) then
			if (WorldQuestTracker.IsCurrentMapQuestHub()) then
				WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
				WorldQuestTracker.RefreshStatusBar()
				C_Timer.After (1, WorldQuestTracker.RefreshStatusBar)
			end
		end
	end)
end

if (WorldMapFrameSizeUpButton) then
	WorldMapFrameSizeUpButton:HookScript ("OnClick", function() --full screen
		if (WorldQuestTracker.UpdateWorldQuestsOnWorldMap) then
			if (WorldQuestTracker.IsCurrentMapQuestHub()) then
				WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
				C_Timer.After (1, WorldQuestTracker.RefreshStatusBar)
			end
		end
	end)

elseif (MaximizeButton) then
	MaximizeButton:HookScript ("OnClick", function() --full screen
		if (WorldQuestTracker.UpdateWorldQuestsOnWorldMap) then
			if (WorldQuestTracker.IsCurrentMapQuestHub()) then
				WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
				C_Timer.After (1, WorldQuestTracker.RefreshStatusBar)
			end
		end
	end)
end

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
	if (WorldQuestTracker.IsWorldQuestHub (WorldMapFrame.mapID)) then
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
		WorldQuestTracker.ScheduleZoneMapUpdate (0.5, true)
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


-- stop auto complete doq dow endf thena