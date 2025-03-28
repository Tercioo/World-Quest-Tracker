
local addonId, wqtInternal = ...
--new 8.1.5 C_TaskQuest.GetQuestTimeLeftSeconds

hooksecurefunc (WorldQuestDataProviderMixin, "RefreshAllData", function (self, fromOnShow)
	--is triggering each 0.5 seconds
	--print ("WorldQuestDataProviderMixin.RefreshAllData", "fromOnShow", fromOnShow)
end)

hooksecurefunc (WorldQuestPinMixin, "RefreshVisuals", function (pin)
	--print ("WorldQuestDataProviderMixin.RefreshVisuals", "pin id:", pin.questID)
end)



--details! framework
local DF = _G ["DetailsFramework"]
if (not DF) then
	print ("|cFFFFAA00World Quest Tracker: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

local L = DF.Language.GetLanguageTable(addonId)

if (true) then
	--return - nah, not today
end

local WorldQuestTracker = WorldQuestTrackerAddon
local ff = WorldQuestTrackerFinderFrame
local rf = WorldQuestTrackerRareFrame

local HaveQuestData = HaveQuestData
local isWorldQuest = QuestUtils_IsQuestWorldQuest
local GetQuestInfoByQuestID = C_TaskQuest.GetQuestInfoByQuestID
local GetQuestTimeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes
local GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID or C_TaskQuest.GetQuestsOnMap

local _

WorldQuestTracker.QuestTrackList = {} --place holder until OnInit is triggered
WorldQuestTracker.AllTaskPOIs = {}
WorldQuestTracker.JustAddedToTracker = {}
WorldQuestTracker.Cache_ShownQuestOnWorldMap = {}
WorldQuestTracker.Cache_ShownQuestOnZoneMap = {}
WorldQuestTracker.Cache_ShownWidgetsOnZoneMap = {}
WorldQuestTracker.WorldMapSupportWidgets = {}
WorldQuestTracker.PartyQuestsPool = {}
WorldQuestTracker.CurrentZoneQuests = {}
WorldQuestTracker.CachedQuestData = {}
WorldQuestTracker.CachedConduitData = {}
WorldQuestTracker.CurrentMapID = 0
WorldQuestTracker.LastWorldMapClick = 0
WorldQuestTracker.MapSeason = 0
WorldQuestTracker.MapOpenedAt = 0
WorldQuestTracker.WorldQuestButton_Click = 0
WorldQuestTracker.Temp_HideZoneWidgets = 0
WorldQuestTracker.lastZoneWidgetsUpdate = 0
WorldQuestTracker.lastMapTap = 0
WorldQuestTracker.LastGFSearch = 0
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



local WorldMapScrollFrame = WorldMapFrame.ScrollContainer

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

	--> faz o cliente carregar as quests antes de realmente verificar o tempo restante

	if (not WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker_Load) then

		print ("WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker_Load MISSING")
		return

	end

	C_Timer.After (3, WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker_Load)
	C_Timer.After (4, WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker_Load)
	C_Timer.After (6, WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker_Load)
	C_Timer.After (10, WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker)

	WorldQuestTracker.RefreshTrackerWidgets()
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

WorldQuestTracker.ExtraMapTextures = {}

function WorldQuestTracker.UpdateExtraMapTextures()
	local mapID = WorldQuestTracker.GetCurrentMapAreaID()
	for texturePath, textureInfo in pairs (WorldQuestTracker.ExtraMapTextures) do
		if (textureInfo.MapID == mapID) then
			textureInfo.Pin:Show()
		else
			textureInfo.Pin:Hide()
		end
	end

	--alternative way to deal with it:
	--[=[
	local map = WorldQuestTrackerDataProvider:GetMap()
	for pin in map:EnumeratePinsByTemplate("WorldQuestTrackerWorldMapPinTemplate") do
		if (pin.MapTextureInfo.MapID ~= WorldMapFrame.mapID) then
			pin.Texture:Hide()
		else
			pin.Texture:Show()
		end
	end
	--]=]
end

---@param mapID number the mapID to show the texture, if the map does not match, the texture won't be shown
---@param texturePath any
---@param x number the x position of the texture
---@param y number the y position of the texture
---@param width number
---@param height number
---@param onClickMapID number the mapID to switch when the texture is clicked
function WorldQuestTracker.AddExtraMapTexture(mapID, texturePath, x, y, width, height, onClickMapID)
	local mapTextureInfo = WorldQuestTracker.ExtraMapTextures[texturePath]
	if (not mapTextureInfo) then
		width = width * 4
		height = height * 4

		local pin = WorldQuestTrackerDataProvider:GetMap():AcquirePin("WorldQuestTrackerExtraMapTextureTemplate", "questPin")
		pin:SetPosition(x, y)
		pin:SetSize(width, height)

		local texture = pin:CreateTexture(nil, "overlay")
		texture:SetTexture(texturePath)
		texture:SetSize(width, height)
		texture:SetPoint("topleft", pin, "topleft", 0, 0)
		texture:SetAlpha(0.834)
		pin.Child = texture

		local textureHighlight = pin:CreateTexture(nil, "overlay")
		textureHighlight:SetTexture(texturePath)
		textureHighlight:SetSize(width, height)
		textureHighlight:SetPoint("topleft", pin, "topleft", 0, 0)
		textureHighlight:SetAlpha(0.15)
		textureHighlight:SetVertexColor(1, 0.7, 0)
		textureHighlight:SetBlendMode("ADD")
		textureHighlight:Hide()

		pin:SetScript("OnEnter", function()
			textureHighlight:Show()
		end)

		pin:SetScript("OnLeave", function()
			textureHighlight:Hide()
		end)

		pin:SetScript("OnMouseUp", function()
			WorldMapFrame:SetMapID(onClickMapID)
			WorldQuestTracker.UpdateZoneWidgets(true)
		end)

		mapTextureInfo = {
			MapID = mapID,
			Texture = texture,
			Pin = pin
		}

		pin.MapTextureInfo = mapTextureInfo
		WorldQuestTracker.ExtraMapTextures[texturePath] = mapTextureInfo

		--debug
		--print("WorldQuestTracker.AddExtraMapTexture", texturePath, x, y, width, height)
		--print(texture, pin, mapTextureInfo)
		--DetailsFramework:DebugVisibility(texture)
		--DetailsFramework:DebugVisibility(pin)
	end
end

function WorldQuestTracker:OnInit()
	do
		local languageCurrentVersion = 1
		if (not WQTrackerLanguage) then
			WQTrackerLanguage = {
				language = GetLocale(),
				version = languageCurrentVersion,
			}
		end

		if (WQTrackerLanguage.version < languageCurrentVersion) then
			--do stuff in the future
		end

		DF.Language.SetCurrentLanguage(addonId, WQTrackerLanguage.language)
	end

	for hubMapID, defaultScale in pairs(WorldQuestTracker.MapData.HubMapIconsScale) do
		if (not WorldQuestTracker.db.profile.world_map_hubscale[hubMapID]) then
			WorldQuestTracker.db.profile.world_map_hubscale[hubMapID] = defaultScale
		end
		if (WorldQuestTracker.db.profile.world_map_hubenabled[hubMapID] == nil) then
			WorldQuestTracker.db.profile.world_map_hubenabled[hubMapID] = true
		end
	end

    hooksecurefunc(_G, "StaticPopup_Show", function(token)
		if (token == "ABANDON_QUEST") then
			if (WorldQuestTracker.db.profile.close_blizz_popups.ABANDON_QUEST) then
				---@diagnostic disable-next-line: undefined-global
				StaticPopup1Button1:Click()
			end
		end
	end)

	WorldQuestTracker.InitAt = GetTime()
	WorldQuestTracker.LastMapID = WorldQuestTracker.GetCurrentMapAreaID()

	WorldQuestTracker.CreateLoadingIcon()

	C_Timer.After (.5, WorldQuestTracker.InitializeWorldWidgets)

	WQTrackerDBChr = WQTrackerDBChr or {}
	WorldQuestTracker.dbChr = WQTrackerDBChr
	WorldQuestTracker.dbChr.ActiveQuests = WorldQuestTracker.dbChr.ActiveQuests or {}

	local SharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
	SharedMedia:Register("statusbar", "Iskar Serenity", [[Interface\AddOns\WorldQuestTracker\media\bar_serenity]])

	C_Timer.After (5, function()
		WorldQuestTracker.InitiateFlyMasterTracker()
	end)

	if (WorldQuestTracker.db:GetCurrentProfile() ~= "Default") then
		WorldQuestTracker.db:SetProfile("Default")
	end

	WorldQuestTracker.TrackerFrameOnInit()
	WorldQuestTracker.GetTrackedQuestsOnDB()

	C_Timer.After(2, function()
		-- ~review disabling scale since it have some issues for some users
		WorldQuestTracker.db.profile.map_frame_scale_enabled = false
		--this options is deprecated, switching it to false for all users
		WorldQuestTracker.db.profile.disable_world_map_widgets = false
	end)

	WorldQuestTracker.TomTomUIDs = {}

	if (LibWindow) then
		if (WorldQuestTracker.db:GetCurrentProfile() == "Default") then
			if (not WorldQuestTrackerFinderFrame.IsRegistered) then
				WorldQuestTracker.RegisterGroupFinderFrameOnLibWindow()
			end
		end
	end

	if (WorldQuestTracker.db.profile.raredetected and WorldQuestTracker.MapData.RaresToScan) then
		for npcId, _ in pairs (WorldQuestTracker.db.profile.raredetected) do
			WorldQuestTracker.MapData.RaresToScan [npcId] = true
		end
	end

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

	WorldQuestTracker.MapChangedTime = time()-1

	C_Timer.After (3, save_player_name)
	C_Timer.After (10, save_player_name)

	local canLoad = C_QuestLog.IsQuestFlaggedCompleted(WORLD_QUESTS_AVAILABLE_QUEST_ID)

	local re_ZONE_CHANGED_NEW_AREA = function()
		WorldQuestTracker:ZONE_CHANGED_NEW_AREA()
	end

	function WorldQuestTracker.FinishedUpdate_Zone()
		return true
	end
	function WorldQuestTracker.FinishedUpdate_World()
		return true
	end

	function WorldQuestTracker.IsInvasionPoint()
		if (ff:IsShown()) then
			return
		end

		local mapInfo = WorldQuestTracker.GetMapInfo()
		local mapFileName = mapInfo and mapInfo.name

		--> we are using where the map file name which always start with "InvasionPoint"
		--> this makes easy to localize group between different languages on the group finder
		--> this won't work with greater invasions which aren't scenarios

		if (mapFileName and mapFileName:find ("InvasionPoint")) then
			--the player is inside a invasion
			local invasionName = C_Scenario.GetInfo()
			if (invasionName) then
				--> is search for invasions enabled?
				if (WorldQuestTracker.db.profile.groupfinder.invasion_points) then
					--> can queue?
					if (not IsInGroup() and not QueueStatusMinimapButton:IsShown()) then
						local callback = nil
						local ENNameFromMapFileName = mapFileName:gsub ("InvasionPoint", "")
						if (ENNameFromMapFileName and WorldQuestTracker.db.profile.rarescan.always_use_english) then
							WorldQuestTracker.FindGroupForCustom ("Invasion Point: " .. (ENNameFromMapFileName or ""), invasionName, L["S_GROUPFINDER_ACTIONS_SEARCH"], "Doing Invasion Point " .. invasionName .. ". Group created with World Quest Tracker #EN Invasion Point: " .. (ENNameFromMapFileName or "") .. " ", 0, callback)
						else
							WorldQuestTracker.FindGroupForCustom (invasionName, invasionName, L["S_GROUPFINDER_ACTIONS_SEARCH"], "Doing Invasion Point " .. invasionName .. ". Group created with World Quest Tracker #EN Invasion Point: " .. (ENNameFromMapFileName or "") .. " ", 0, callback)
						end
					else
						WorldQuestTracker:Msg (L["S_GROUPFINDER_QUEUEBUSY2"])
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

		if (WorldQuestTracker.DoesMapHasWorldQuests(WorldMapFrame.mapID)) then
			WorldQuestTracker.PreloadWorldQuestsForMap(WorldMapFrame.mapID)
		end

		WorldQuestTracker.UpdateExtraMapTextures()

		local mapInfo = WorldQuestTracker.GetMapInfo()
		local mapFileName = mapInfo and mapInfo.name

		if (not mapFileName) then
			C_Timer.After (3, WorldQuestTracker.IsInvasionPoint)
		else
			WorldQuestTracker.IsInvasionPoint()
			--> trigger once more since on some clientes MapInfo() is having a delay on update the correct map
			C_Timer.After (1, WorldQuestTracker.IsInvasionPoint)
			C_Timer.After (2, WorldQuestTracker.IsInvasionPoint)
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
				--quer saber da some total ou quer dia a dia para fazer um gr�fico
				local result = {}
				local total = 0
				local dayTable = dateString

				for i = 1, #dayTable do --table com v�rias strings representando dias
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
	function WorldQuestTracker:QUEST_TURNED_IN(event, questID, XP, gold)
		if (isWorldQuest(questID)) then
			WorldQuestTracker.AllCharactersQuests_Remove(questID)
			WorldQuestTracker.RemoveQuestFromTracker(questID)

			--FlashClientIcon()

			WorldQuestTracker.RemoveQuestFromCache(questID)

			if (isWorldQuest(questID)) then --wait, is this inception?
				local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData (questID)
				local questHistory = WorldQuestTracker.db.profile.history

				--check if the map is opened in the player screen
				if (WorldMapFrame and WorldMapFrame:IsShown()) then
					C_Timer.After(1, function()
						--update quest on current map shown
						if (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
							WorldQuestTracker.UpdateWorldQuestsOnWorldMap(true)

						elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
							WorldQuestTracker.UpdateZoneWidgets()
						end
					end)
				end



				local guid = UnitGUID("player")
				local today = date("%y%m%d") --YYMMDD

				local itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker.GetQuestReward_Item (questID)

				--store reward amount
				local rewardHistory = questHistory.reward
					local _global = rewardHistory.global
					local _local = rewardHistory.character[guid]
					if (not _local) then
						_local = {}
						rewardHistory.character[guid] = _local
					end

					if (gold and gold > 0) then
						_global["gold"] = _global["gold"] or 0
						_local["gold"] = _local["gold"] or 0
						_global["gold"] = _global["gold"] + gold
						_local["gold"] = _local["gold"] + gold

						--print ("Gold added:", _global["gold"], _local["gold"])
					end

					if (isArtifact) then
						_global["artifact"] = _global["artifact"] or 0
						_local["artifact"] = _local["artifact"] or 0
						_global["artifact"] = _global["artifact"] + artifactPower
						_local["artifact"] = _local["artifact"] + artifactPower

						--print ("Artifact added:", _global["artifact"], _local["artifact"])
					end

					if (rewardName) then --class hall resource
						_global["resource"] = _global["resource"] or 0
						_local["resource"] = _local["resource"] or 0
						_global["resource"] = _global["resource"] + numRewardItems
						_local["resource"] = _local["resource"] + numRewardItems

						--print ("Resource added:", _global["resource"], _local["resource"])
					end

					--trade skill - blood of sargeras
					if (itemID == 124124) then
						_global["blood"] = (_global["blood"] or 0) + quantity
						_local["blood"] = (_local["blood"] or 0) + quantity
					end

					--professions
					if (tradeskillLineIndex) then
						local tradeskillLineID = tradeskillLineIndex and select (7, GetProfessionInfo(tradeskillLineIndex))
						if (tradeskillLineID) then
							if (itemID) then
								--print ("eh profissao 3", itemID)
								_global["profession"] = _global["profession"] or {}
								_local["profession"] = _local["profession"] or {}
								_global["profession"][itemID] = (_global["profession"][itemID] or 0) + 1
								_local["profession"][itemID] = (_local["profession"][itemID] or 0) + 1
								--print ("local global 3", _local["profession"][itemID], _global["profession"][itemID])
							end
						end
					end

				--quais quest ja foram completadas e quantas vezes
				local questDoneHistory = questHistory.quest
					local _global = questDoneHistory.global
					local _local = questDoneHistory.character[guid]
					if (not _local) then
						_local = {}
						questDoneHistory.character[guid] = _local
					end
					_global[questID] = (_global[questID] or 0) + 1
					_local[questID] = (_local[questID] or 0) + 1
					_global["total"] = (_global["total"] or 0) + 1
					_local["total"] = (_local["total"] or 0) + 1

				--estat�sticas dia a dia
				local periodHistory = questHistory.period
					local _global = periodHistory.global
					local _local = periodHistory.character[guid]
					if (not _local) then
						_local = {}
						periodHistory.character[guid] = _local
					end

					local _globalToday = _global[today]
					local _localToday = _local[today]
					if (not _globalToday) then
						_globalToday = {}
						_global[today] = _globalToday
					end
					if (not _localToday) then
						_localToday = {}
						_local[today] = _localToday
					end

					_globalToday["quest"] = (_globalToday["quest"] or 0) + 1
					_localToday["quest"] = (_localToday["quest"] or 0) + 1

					if (itemID == 124124) then
						_globalToday["blood"] = (_globalToday["blood"] or 0) + quantity
						_localToday["blood"] = (_localToday["blood"] or 0) + quantity
					end

					if (tradeskillLineIndex) then
						--print ("eh profissao today 4", tradeskillLineIndex)
						local tradeskillLineID = tradeskillLineIndex and select (7, GetProfessionInfo (tradeskillLineIndex))
						if (tradeskillLineID) then
							--print ("eh profissao today 5", tradeskillLineID)
							if (itemID) then
								--print ("eh profissao today 6", itemID)
								_globalToday["profession"] = _globalToday["profession"] or {}
								_localToday["profession"] = _localToday["profession"] or {}
								_globalToday["profession"][itemID] = (_globalToday["profession"][itemID] or 0) + 1
								_localToday["profession"][itemID] = (_localToday["profession"][itemID] or 0) + 1
								--print ("local global today 6", _localToday["profession"][itemID], _globalToday["profession"][itemID])
							end
						end
					end

					if (gold and gold > 0) then
						_globalToday["gold"] = _globalToday["gold"] or 0
						_localToday["gold"] = _localToday["gold"] or 0
						_globalToday["gold"] = _globalToday["gold"] + gold
						_localToday["gold"] = _localToday["gold"] + gold
					end
					if (isArtifact) then
						_globalToday["artifact"] = _globalToday["artifact"] or 0
						_localToday["artifact"] = _localToday["artifact"] or 0
						_globalToday["artifact"] = _globalToday["artifact"] + artifactPower
						_localToday["artifact"] = _localToday["artifact"] + artifactPower
					end
					if (rewardName) then --class hall resource
						_globalToday["resource"] = _globalToday["resource"] or 0
						_localToday["resource"] = _localToday["resource"] or 0
						_globalToday["resource"] = _globalToday["resource"] + numRewardItems
						_localToday["resource"] = _localToday["resource"] + numRewardItems
					end

			end
		end
	end

	function WorldQuestTracker:QUEST_LOOT_RECEIVED(event, questID, item, amount, ...)
		if (isWorldQuest(questID)) then
		--	local title, questType, texture, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, selected, isSpellTarget, timeLeft, isCriteria, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker:GetQuestFullInfo (questID)
		--	print ("QINFO:", goldFormated, rewardName, numRewardItems, itemName, isArtifact, artifactPower)
		end
	end

	WorldQuestTracker:RegisterEvent("TAXIMAP_OPENED")
	WorldQuestTracker:RegisterEvent("TAXIMAP_CLOSED")
	WorldQuestTracker:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	WorldQuestTracker:RegisterEvent("QUEST_TURNED_IN")
	WorldQuestTracker:RegisterEvent("QUEST_LOOT_RECEIVED")
	WorldQuestTracker:RegisterEvent("PLAYER_STARTED_MOVING")
	WorldQuestTracker:RegisterEvent("PLAYER_STOPPED_MOVING")

	C_Timer.After(.5, WorldQuestTracker.ZONE_CHANGED_NEW_AREA)
	C_Timer.After(.5, WorldQuestTracker.UpdateArrowFrequence)
	C_Timer.After(5, WorldQuestTracker.UpdateArrowFrequence)
	C_Timer.After(10, WorldQuestTracker.UpdateArrowFrequence)
end

local onStartClickAnimation = function(self)
	self:GetParent():Show()
end

local onEndClickAnimation = function(self)
	self:GetParent():Hide()
end


	--format the quest time left
	local D_HOURS = "%dH"
	local D_DAYS = "%dD"

	function WorldQuestTracker.GetQuest_TimeLeft(questID, formated)
		local timeLeftMinutes = GetQuestTimeLeftMinutes(questID)
		if (timeLeftMinutes) then
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
		else
			--since 20/12/2018 time left sometimes is returning nil
			return 60
		end
	end

	--pega os dados da quest
	function WorldQuestTracker.GetQuest_Info(questID)
		if (not HaveQuestData(questID)) then
			if (WorldQuestTracker.__debug) then
				WorldQuestTracker:Msg("no HaveQuestData(1) for quest", questID)
			end
			return
		end

		local title, factionID = GetQuestInfoByQuestID(questID)

		local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
		if (not tagInfo) then
			if (WorldQuestTracker.__debug) then
				WorldQuestTracker:Msg("no tagInfo(3) for quest", questID)
			end
			return
		end

		local tagID = tagInfo.tagID
		local tagName = tagInfo.tagName
		local worldQuestType = tagInfo.worldQuestType
		local rarity = tagInfo.quality
		local isElite = tagInfo.isElite

		return title, factionID, tagID, tagName, worldQuestType, rarity, isElite
	end

	--pega o icone para as quest que dao gold
	local goldCoords = {0, 1, 0, 1}
	function WorldQuestTracker.GetGoldIcon()
		return [[Interface\AddOns\WorldQuestTracker\media\icon_gold]], goldCoords
	end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--saved quests on other characters

	--pega a lista de quests que o jogador tem dispon�vel
	function WorldQuestTracker.SavedQuestList_GetList()
		if (type(WorldQuestTracker.dbChr) ~= "table") then
			WorldQuestTracker:Msg("WorldQuestTracker.SavedQuestList_GetList failed: invalid dbChr, type: ", type(WorldQuestTracker.dbChr))
			return
		end
		return WorldQuestTracker.dbChr.ActiveQuests
	end
	-- ~saved ~pool ~data ~allquests �ll
	local map_seasons = {}
	function WorldQuestTracker.SavedQuestList_IsNew (questID)
		if (WorldQuestTracker.MapSeason == 0) then
			--o mapa esta carregando e n�o mandou o primeiro evento ainda
			return false
		end

		local ActiveQuests = WorldQuestTracker.SavedQuestList_GetList()

		if (ActiveQuests [questID]) then --a quest esta armazenada
			if (map_seasons [questID] == WorldQuestTracker.MapSeason) then
				--a quest j� esta na lista por�m foi adicionada nesta season do mapa
				return true
			else
				--apenas retornar que n�o � nova
				return false
			end
		else --a quest n�o esta na lista
			local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
			if (timeLeft and timeLeft > 0) then
				--adicionar a quest a lista de quets
				ActiveQuests [questID] = time() + (timeLeft*60)
				map_seasons [questID] = WorldQuestTracker.MapSeason
				--retornar que a quest � nova
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
--local worldFramePOIs = CreateFrame ("frame", "WorldQuestTrackerWorldMapPOI", WorldMapFrame.BorderFrame)
local worldFramePOIs = CreateFrame ("frame", "WorldQuestTrackerWorldMapPOI", WorldMapFrame.ScrollContainer, "BackdropTemplate")
worldFramePOIs:SetAllPoints()
worldFramePOIs:SetFrameLevel(6701)
local fadeInAnimation = worldFramePOIs:CreateAnimationGroup()
local step1 = fadeInAnimation:CreateAnimation ("Alpha")
step1:SetOrder (1)
step1:SetFromAlpha (0)
step1:SetToAlpha (1)
step1:SetDuration (0.3)
worldFramePOIs.fadeInAnimation = fadeInAnimation
fadeInAnimation:SetScript("OnFinished", function()
	worldFramePOIs:SetAlpha(1)
end)

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> tutorials

--WorldQuestTracker.db.profile.TutorialPopupID = nil
-- ~tutorial
local re_ShowTutorialAlert = function()
	WorldQuestTracker ["ShowTutorialAlert"]()
end
local hook_AlertCloseButton = function(self)
	re_ShowTutorialAlert()
end
local wait_ShowTutorialAlert = function()
	WorldQuestTracker.TutorialAlertOnHold = nil
	WorldQuestTracker.ShowTutorialAlert()
end

function WorldQuestTracker.ShowTutorialAlert()
	if (true) then
		--disabled tutorials for 9.0.1, due to "MicroButtonAlertTemplate" being nil, need to replace with the new animation
		return
	end

	WorldQuestTracker.db.profile.TutorialPopupID = WorldQuestTracker.db.profile.TutorialPopupID or 1

	--WorldQuestTracker.db.profile.TutorialPopupID = 3

	if (WorldQuestTracker.db.profile.TutorialPopupID == 1) then

		if (WorldQuestTracker.TutorialAlertOnHold) then
			return
		end

		if (not WorldMapFrame:IsShown() or not C_QuestLog.IsQuestFlaggedCompleted (WORLD_QUESTS_AVAILABLE_QUEST_ID or 1) or InCombatLockdown()) then
			C_Timer.After (10, wait_ShowTutorialAlert)
			WorldQuestTracker.TutorialAlertOnHold = true
			return
		end

		WorldMapFrame:SetMapID (WorldQuestTracker.MapData.ZoneIDs.KULTIRAS)
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
		return

	elseif (WorldQuestTracker.db.profile.TutorialPopupID == 2) then

		--C_Timer.After (.5, tutorial_two)
		return

	elseif (WorldQuestTracker.db.profile.TutorialPopupID == 3) then

		--C_Timer.After (.5, tutorial_three)
		return

	elseif (WorldQuestTracker.db.profile.TutorialPopupID == 4) then

		--C_Timer.After (.5, tutorial_four)
		return

	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--loading icon


function WorldQuestTracker.UpdateLoadingIconAnchor()
	local adjust_anchor = false
	if (GetCVarBool ("questLogOpen")) then
		if (not WorldMapFrame.isMaximized) then
			adjust_anchor = true
		end
	end

	if (adjust_anchor) then
		WorldQuestTracker.LoadingAnimation:SetPoint("bottom", WorldMapScrollFrame, "top", 0, -75)
	else
		WorldQuestTracker.LoadingAnimation:SetPoint("bottom", WorldMapScrollFrame, "top", 0, -75)
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

function WorldQuestTracker.CreateLoadingIcon()
	local f = CreateFrame ("frame", nil, WorldMapFrame, "BackdropTemplate")
	f:SetSize(48, 48)
	f:SetPoint("bottom", WorldMapScrollFrame, "top", 0, -75) --289/2 = 144
	f:SetFrameLevel(3000)

	local animGroup1 = f:CreateAnimationGroup()
	local anim1 = animGroup1:CreateAnimation ("Alpha")
	anim1:SetOrder (1)
	anim1:SetFromAlpha (0)
	anim1:SetToAlpha (0.834)
	anim1:SetDuration (2)
	f.FadeIN = animGroup1

	local animGroup2 = f:CreateAnimationGroup()
	local anim2 = animGroup2:CreateAnimation ("Alpha")
	f.FadeOUT = animGroup2
	anim2:SetOrder (2)
	anim2:SetFromAlpha (0.834)
	anim2:SetToAlpha (0)
	anim2:SetDuration (4)
	animGroup2:SetScript("OnFinished", function()
		f:Hide()
		WorldQuestTracker.LoadingAnimation.IsPlaying = false
	end)

	f.Text = f:CreateFontString (nil, "overlay", "GameFontNormal")
	f.Text:SetText ("please wait...")
	f.Text:SetPoint("left", f, "right", -5, 1)
	f.TextBackground = f:CreateTexture(nil, "background")
	f.TextBackground:SetPoint("left", f, "right", -20, 0)
	f.TextBackground:SetSize(160, 14)
	f.TextBackground:SetTexture([[Interface\COMMON\ShadowOverlay-Left]])

	f.Text:Hide()
	f.TextBackground:Hide()

	f.CircleAnimStatic = CreateFrame ("frame", nil, f, "BackdropTemplate")
	f.CircleAnimStatic:SetAllPoints()
	f.CircleAnimStatic.Alpha = f.CircleAnimStatic:CreateTexture(nil, "overlay")
	f.CircleAnimStatic.Alpha:SetTexture([[Interface\COMMON\StreamFrame]])
	f.CircleAnimStatic.Alpha:SetAllPoints()
	f.CircleAnimStatic.Background = f.CircleAnimStatic:CreateTexture(nil, "background")
	f.CircleAnimStatic.Background:SetTexture([[Interface\COMMON\StreamBackground]])
	f.CircleAnimStatic.Background:SetAllPoints()

	f.CircleAnim = CreateFrame ("frame", nil, f, "BackdropTemplate")
	f.CircleAnim:SetAllPoints()
	f.CircleAnim.Spinner = f.CircleAnim:CreateTexture(nil, "artwork")
	f.CircleAnim.Spinner:SetTexture([[Interface\COMMON\StreamCircle]])
	f.CircleAnim.Spinner:SetVertexColor(.5, 1, .5, 1)
	f.CircleAnim.Spinner:SetAllPoints()
	f.CircleAnim.Spark = f.CircleAnim:CreateTexture(nil, "overlay")
	f.CircleAnim.Spark:SetTexture([[Interface\COMMON\StreamSpark]])
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
	do return end
	if (not WorldQuestTracker.IsPlayingLoadAnimation()) then
		WorldQuestTracker.LoadingAnimation:Show()
		WorldQuestTracker.LoadingAnimation.FadeIN:Play()
		WorldQuestTracker.LoadingAnimation.Loop:Play()
		WorldQuestTracker.LoadingAnimation.IsPlaying = true
	end
end

function WorldQuestTracker.StopLoadingAnimation()
	WorldQuestTracker.LoadingAnimation.FadeOUT:Play()
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> slash commands

SLASH_WQTRACKER1 = "/wqt"
SLASH_WQTRACKER2 = "/worldquesttracker"

function SlashCmdList.WQTRACKER (msg, editbox)

	if (msg == "reinstall") then
		local b = CreateFrame("button", "WQTResetConfigButton", UIParent)
		DetailsFramework:ApplyStandardBackdrop(b)
		tinsert(UISpecialFrames, "WQTResetConfigButton")

		b:SetSize(250, 40)
		b:SetText ("REINSTALL")
		b:SetScript("OnClick", function()
			WQTrackerDB = {}
			WQTrackerDBChr = {}
			ReloadUI()
		end)
		b:SetPoint("center", UIParent, "center", 0, 0)

	elseif (msg == "options") then
		if (not WorldQuestTracker.SetupStatusbarButton) then
			WorldQuestTracker:Msg(L["S_SLASH_OPENMAP_FIRST"])
			return
		end
		WorldQuestTracker.OpenOptionsPanel()

	elseif (msg == "test") then
		local playerLevel = UnitLevel("player")
		if (playerLevel < 51) then
			WorldQuestTracker:Msg("Character level too low for shadowlands, minimum is 51 for alts.")
		end

		local bastionQuests = GetQuestsForPlayerByMapID(1533, 1533)
		WorldQuestTracker:Msg("Finding quests on Bastion Map")
		if (bastionQuests and type(bastionQuests) == "table") then
			WorldQuestTracker:Msg("Found quests, amount:", #bastionQuests)
		else
			WorldQuestTracker:Msg("Blizzard's GetQuestsOnMap() returned invalid data.")
		end

	elseif (msg == "debug") then
		WorldQuestTracker.__debug = not WorldQuestTracker.__debug
		if (WorldQuestTracker.__debug) then
			WorldQuestTracker:Msg("debug is now enabled.")
		else
			WorldQuestTracker:Msg("debug is disabled.")
		end

	elseif (msg == "statusbar") then
		WorldQuestTracker.db.profile.bar_visible = true
		WorldQuestTracker.RefreshStatusBarVisibility()
		return

	elseif (msg == "info") then
		--local widget = GetMouseFocus()
        ---@type uiobject[]
        local uiObjects = GetMouseFoci()

		if (uiObjects and uiObjects[1]) then
			local widget = uiObjects[1]

			local info = {}

			--quest info
			tinsert (info, "Name: " .. (widget.GetName and widget:GetName() or "-No Name-"))

			if (widget.questID) then
				local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData (widget.questID)
				tinsert (info, "QuestID: " .. widget.questID .. " Quest Name: " .. (title or "-No Name-"))
			else
				tinsert (info, "QuestID: no questID found")
			end

			--flags
			tinsert (info, "Is Rounded 'Zone' World: " .. (widget.IsWorldZoneQuestButton and "true" or "false"))
			tinsert (info, "Is Zone Summary: " .. (widget.IsZoneSummaryQuestButton and "true" or "false"))
			tinsert (info, "")


			--is on tracker
			tinsert (info, "Is on Tracker: " .. (WorldQuestTracker.IsQuestBeingTracked (widget.questID) and "true" or "false"))

			--zone caches
			tinsert (info, "Is in Zone QuestID Cache: " .. (WorldQuestTracker.CurrentZoneQuests [widget.questID or 0] and "true" or "false"))

			local inZoneWidgetsCache = false
			for _, cachedElement in ipairs (WorldQuestTracker.Cache_ShownWidgetsOnZoneMap) do
				if (cachedElement == widget) then
					inZoneWidgetsCache = true
				end
			end

			tinsert (info, "Is in Zone Widget Cache: " .. (inZoneWidgetsCache and "true" or "false"))

			--world caches
			local inWorldWidgetsCache = false
			for _, cachedElement in pairs (WorldQuestTracker.WorldMapSmallWidgets) do
				if (cachedElement == widget) then
					inWorldWidgetsCache = true
				end
			end
			tinsert (info, "Is in World Widget Cache: " .. (inWorldWidgetsCache and "true" or "false"))

			--pin data provider
			tinsert (info, "")

			local map = WorldQuestTrackerDataProvider:GetMap()

			local dataProviderPinInUse = false
			for pin in map:EnumeratePinsByTemplate ("WorldQuestTrackerWorldMapPinTemplate") do
				if (pin.Child == widget) then
					dataProviderPinInUse = true
				end
			end
			tinsert (info, "Pin Data Provider Widget has a Pin: " .. (dataProviderPinInUse and "true" or "false"))

			local dataProviderValidParenting1 = false
			local dataProviderValidParenting2 = false
			for _, cachedElement in pairs (WorldQuestTracker.WorldMapSmallWidgets) do
				local pin = cachedElement:GetParent()
				if (pin) then
					if (pin.Child == cachedElement) then
						dataProviderValidParenting1 = true
					end
					if (pin:IsShown()) then
						dataProviderValidParenting2 = true
					end
				end
			end

			tinsert (info, "Pin Data Provider Valid Parent: " .. (dataProviderValidParenting1 and "true" or "false"))
			tinsert (info, "Pin Data Provider Is Shown: " .. (dataProviderValidParenting2 and "true" or "false"))

			--parent data
			tinsert (info, "")

			local parent = widget:GetParent()
			if (parent) then
				tinsert (info, "Parent: " .. (parent.GetName and parent:GetName() or "-No Name-"))
				tinsert (info, "Parent Is Shown: " .. (parent:IsShown() and "true" or "false"))

			else
				tinsert (info, "Parent: -no parent-")
			end

			--anchor
			tinsert (info, "")
			for i = 1, widget:GetNumPoints() do
				local a, b, c, e, d = widget:GetPoint (i)
				tinsert (info, "Point: " .. (type (a) == "table" and (a:GetName() or "-no name-") or a))
				tinsert (info, "Point: " .. (type (b) == "table" and (b:GetName() or "-no name-") or b))
				tinsert (info, "Point: " .. (type (c) == "table" and (c:GetName() or "-no name-") or c))
				tinsert (info, "Point: " .. (type (d) == "table" and (d:GetName() or "-no name-") or d))
				tinsert (info, "Point: " .. (type (e) == "table" and (e:GetName() or "-no name-") or e))
			end


			Details:DumpTable (info)

		end

	else
		WorldQuestTracker:Msg("version:", WQT_VERSION)

		if (not WorldQuestTracker.SetupStatusbarButton) then
			WorldQuestTracker:Msg(L["S_SLASH_OPENMAP_FIRST"])
			return
		end
		WorldQuestTracker.OpenOptionsPanel()
	end
end

--all quests are with red circle for invasion quests
--need to fill the factions of Shadowlands
--need to test the group finder

--old and simple alerts frame, all globals has been renamed to avoid conflicts
local g_visibleMicroButtonAlerts = {};
local g_acknowledgedMicroButtonAlerts = {};

--Micro Button alerts
function MicroButtonAlert_SetText2(self, text)
	self.Text:SetText(text or "");
end

function MicroButtonAlert_OnLoad2(self)
	if self.MicroButton then
		self:SetParent(self.MicroButton);
		self:SetFrameStrata("DIALOG");
	end
	self.Text:SetSpacing(4);
	MicroButtonAlert_SetText2(self, self.label);
end

function MicroButtonAlert_OnShow2(self)
	self:SetHeight(self.Text:GetHeight() + 42);
	if ( self.tutorialIndex and GetCVarBitfield("closedInfoFrames", self.tutorialIndex) ) then
		self:Hide();
	end
end

function MicroButtonAlert_OnAcknowledged2(self)
	g_acknowledgedMicroButtonAlerts[self] = true;
end

function MicroButtonAlert_OnHide2(self)
	g_visibleMicroButtonAlerts[self] = nil;
	MainMenuMicroButton_UpdateAlertsEnabled(self);
end


----------------------------------------------------------------------------------------------------------------------------------------------------------------

--[=[ --user posted on discord
local TalkingHeadFrame = _G.TalkingHeadFrame
if TalkingHeadFrame then
    hooksecurefunc(_G["TalkingHeadFrame"], "PlayCurrent", function()
        TalkingHeadFrame:Hide()
    end)
    hooksecurefunc(_G["TalkingHeadFrame"], "Reset", function()
        TalkingHeadFrame:Hide()
    end)
end
]=]

local talkingHeadSuppressFrame = CreateFrame("frame")
talkingHeadSuppressFrame:RegisterEvent("TALKINGHEAD_REQUESTED")
talkingHeadSuppressFrame:SetScript("OnEvent", function (self, event, arg1)
	if (event == "TALKINGHEAD_REQUESTED") then
		--get where the player is
		local _, zoneType = GetInstanceInfo()

		--check if the zone type is enbaled under the options panel
		if (zoneType == "none") then
			if (not WorldQuestTracker.db.profile.talking_heads_openworld) then
				return
			end

		elseif (zoneType == "party") then
			if (not WorldQuestTracker.db.profile.talking_heads_dungeon) then
				return
			end

		elseif (zoneType == "raid") then
			if (not WorldQuestTracker.db.profile.talking_heads_raid) then
				return
			end

		elseif (zoneType == "scenario") then
			if (not WorldQuestTracker.db.profile.talking_heads_torgast) then
				return
			end
		end

		--if the player already heard the talking head, close it
		local displayInfo, cameraID, vo, duration, lineNumber, numLines, name, text, isNewTalkingHead = C_TalkingHead.GetCurrentLineInfo()
		if (WorldQuestTracker.db.profile.talking_heads_heard[vo]) then
			_G.TalkingHeadFrame:CloseImmediately()
		else
			if (vo) then
				WorldQuestTracker.db.profile.talking_heads_heard[vo] = true
			end
		end
	end
end)


----------------------------------------------------------------------------------------------------------------------------------------------------------------

function WorldQuestTracker.InitiateFlyMasterTracker()
	--get the location
	--/dump C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
	--flymaster npc location
	local flymasterX = 0.60903662443161 -- -1906.8000488281
	local flymasterY = 0.6869769692421 -- 1210.3000488281
	--korthia portal location
	local korthiaPortalX = 0.35661220550537 --0.31601178646088
	local korthiaPortalY = 0.30656772851944 --0.24368673563004
	--zereth
	local zerethPortalX = 0.49530583620071
	local zerethPortalY = 0.2653232216835

	--upper oribos map id
	local secondFloormapId = 1671
	local isFlymasterTrakcerEnabled = false

	local currentPlayerX = 0
	local currentPlayerY = 0

	local oribosFlyMasterFrame = CreateFrame("frame", "WorldQuestTrackerOribosFlyMasterFrame", UIParent, "BackdropTemplate")
	oribosFlyMasterFrame:SetPoint("center", "UIParent", "center", 0, 0)
	oribosFlyMasterFrame:SetSize(136, 60)
	DetailsFramework:ApplyStandardBackdrop(oribosFlyMasterFrame)
	oribosFlyMasterFrame:Hide()

	oribosFlyMasterFrame:RegisterEvent("PLAYER_STARTED_MOVING")
	oribosFlyMasterFrame:RegisterEvent("PLAYER_STOPPED_MOVING")

	local playerIsMoving = false

	oribosFlyMasterFrame:SetScript("OnEvent", function(self, event)
		if (event == "PLAYER_STARTED_MOVING") then
			playerIsMoving = true

		elseif (event == "PLAYER_STOPPED_MOVING") then
			playerIsMoving = false
		end
	end)

	if (not IsPlayerMoving()) then
		oribosFlyMasterFrame:SetAlpha(0)
		oribosFlyMasterFrame:EnableMouse(false)
	end

	oribosFlyMasterFrame.statusBar = CreateFrame("frame", "WorldQuestTrackerOribosFlyMasterFrameStatusBar", oribosFlyMasterFrame, "BackdropTemplate")
	oribosFlyMasterFrame.statusBar:SetPoint("bottomleft", oribosFlyMasterFrame, "bottomleft", 0, 0)
	oribosFlyMasterFrame.statusBar:SetPoint("bottomright", oribosFlyMasterFrame, "bottomright", 0, 0)
	oribosFlyMasterFrame.statusBar:SetHeight(12)
	DetailsFramework:ApplyStandardBackdrop(oribosFlyMasterFrame.statusBar)

	oribosFlyMasterFrame.FlightMasterIcon = oribosFlyMasterFrame:CreateTexture(nil, "overlay")
	oribosFlyMasterFrame.FlightMasterIcon:SetPoint("topleft", oribosFlyMasterFrame, "topleft", 35, -3)
	oribosFlyMasterFrame.FlightMasterIcon:SetSize(16, 16)
	oribosFlyMasterFrame.FlightMasterIcon:SetAlpha(0.7)
	oribosFlyMasterFrame.FlightMasterIcon:SetTexture([[Interface\TAXIFRAME\UI-Taxi-Icon-White]])

	oribosFlyMasterFrame.KorthiaIcon = oribosFlyMasterFrame:CreateTexture(nil, "overlay")
	oribosFlyMasterFrame.KorthiaIcon:SetPoint("topleft", oribosFlyMasterFrame.FlightMasterIcon, "topright", 15, 0)
	oribosFlyMasterFrame.KorthiaIcon:SetSize(16, 16)
	oribosFlyMasterFrame.KorthiaIcon:SetAlpha(0.7)
	oribosFlyMasterFrame.KorthiaIcon:SetBlendMode("ADD")
	oribosFlyMasterFrame.KorthiaIcon:SetTexture([[Interface\AddOns\WorldQuestTracker\media\korthia_portal_icon]])

	oribosFlyMasterFrame.ZerethIcon = oribosFlyMasterFrame:CreateTexture(nil, "overlay")
	oribosFlyMasterFrame.ZerethIcon:SetPoint("topleft", oribosFlyMasterFrame.KorthiaIcon, "topright", 15, 0)
	oribosFlyMasterFrame.ZerethIcon:SetSize(16, 16)
	oribosFlyMasterFrame.ZerethIcon:SetAlpha(0.7)
	oribosFlyMasterFrame.ZerethIcon:SetBlendMode("ADD")
	oribosFlyMasterFrame.ZerethIcon:SetTexture([[Interface\AddOns\WorldQuestTracker\media\zereth_portal_icon]])

	oribosFlyMasterFrame.Arrow = oribosFlyMasterFrame:CreateTexture(nil, "overlay")
	oribosFlyMasterFrame.Arrow:SetPoint("top", oribosFlyMasterFrame.FlightMasterIcon, "bottom", 6, 1)
	oribosFlyMasterFrame.Arrow:SetSize(32, 32)
	oribosFlyMasterFrame.Arrow:SetAlpha(1)
	oribosFlyMasterFrame.Arrow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\ArrowGridT]])

	oribosFlyMasterFrame.KorthiaArrow = oribosFlyMasterFrame:CreateTexture(nil, "overlay")
	oribosFlyMasterFrame.KorthiaArrow:SetPoint("topleft", oribosFlyMasterFrame.Arrow, "topright", 0, 0)
	oribosFlyMasterFrame.KorthiaArrow:SetSize(32, 32)
	oribosFlyMasterFrame.KorthiaArrow:SetAlpha(1)
	oribosFlyMasterFrame.KorthiaArrow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\ArrowGridT]])

	oribosFlyMasterFrame.ZerethArrow = oribosFlyMasterFrame:CreateTexture(nil, "overlay")
	oribosFlyMasterFrame.ZerethArrow:SetPoint("topleft", oribosFlyMasterFrame.KorthiaArrow, "topright", 0, 0)
	oribosFlyMasterFrame.ZerethArrow:SetSize(32, 32)
	oribosFlyMasterFrame.ZerethArrow:SetAlpha(1)
	oribosFlyMasterFrame.ZerethArrow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\ArrowGridT]])

	local onCloseButton = function()
		oribosFlyMasterFrame:Hide()
		WorldQuestTracker.db.profile.flymaster_tracker_enabled = false
	end
	oribosFlyMasterFrame.CloseButton = DF:CreateButton(oribosFlyMasterFrame, onCloseButton, 20, 20, "X", -1, nil, nil, nil, nil, nil, DF:GetTemplate ("button", "WQT_NEWS_BUTTON"), DF:GetTemplate ("font", "WQT_TOGGLEQUEST_TEXT"))
	oribosFlyMasterFrame.CloseButton:SetPoint("topleft", oribosFlyMasterFrame, "topleft", 1, -1)
	oribosFlyMasterFrame.CloseButton:SetSize(20, 20)
	oribosFlyMasterFrame.CloseButton:SetAlpha(.2)

	oribosFlyMasterFrame.CloseButton.have_tooltip = "Disable this window, can be enabled again in the World Quest Tracker options."

	oribosFlyMasterFrame.Title = DF:CreateLabel(oribosFlyMasterFrame.statusBar, "World Quest Tracker")
	oribosFlyMasterFrame.Title:SetPoint("bottom", oribosFlyMasterFrame, "bottom", 0, 1)
	oribosFlyMasterFrame.Title.align =  "|"
	oribosFlyMasterFrame.Title.textcolor = {.8, .8, .8, .35}

	local trackerOnTick = function(self, deltaTime)
		--update the player position
		local mapPosition = C_Map.GetPlayerMapPosition(WorldQuestTracker.GetCurrentStandingMapAreaID(), "player")
		if (not mapPosition) then
			return
		end
		currentPlayerX, currentPlayerY = mapPosition.x, mapPosition.y

		--> update flight master arrow
			local questYaw = (DF.FindLookAtRotation(_, currentPlayerX, currentPlayerY, flymasterX, flymasterY) + (math.pi/2)) % (math.pi*2)
			local playerYaw = GetPlayerFacing() or 0
			local angle = (((questYaw + playerYaw)%(math.pi*2))+math.pi)%(math.pi*2)
			local imageIndex = 1+(floor(DF.MapRangeClamped(_, 0, (math.pi*2), 1, 144, angle)) + 48)%144 --48� quadro � o que aponta para o norte
			local line = ceil(imageIndex / 12)
			local coord = (imageIndex - ((line-1) * 12)) / 12
			self.Arrow:SetTexCoord(coord-0.0833, coord, 0.0833 * (line-1), 0.0833 * line)

			if (playerIsMoving) then
				if (oribosFlyMasterFrame:GetAlpha() < 1) then
					local alphaAmount = oribosFlyMasterFrame:GetAlpha() + (deltaTime*7)
					alphaAmount = Saturate(alphaAmount)
					oribosFlyMasterFrame:SetAlpha(alphaAmount)
				end
				oribosFlyMasterFrame:EnableMouse(true)
			else
				if (oribosFlyMasterFrame:GetAlpha() > 0) then
					oribosFlyMasterFrame:SetAlpha(Saturate(oribosFlyMasterFrame:GetAlpha() - deltaTime/5))
				else
					oribosFlyMasterFrame:EnableMouse(false)
				end
			end

		--> update korthia arrow
			local questYaw = (DF.FindLookAtRotation (_, currentPlayerX, currentPlayerY, korthiaPortalX, korthiaPortalY) + (math.pi/2)) % (math.pi*2)
			local playerYaw = GetPlayerFacing() or 0
			local angle = (((questYaw + playerYaw)%(math.pi*2))+math.pi)%(math.pi*2)
			local imageIndex = 1+(floor(DF.MapRangeClamped(_, 0, (math.pi*2), 1, 144, angle)) + 48)%144 --48� quadro � o que aponta para o norte
			local line = ceil (imageIndex / 12)
			local coord = (imageIndex - ((line-1) * 12)) / 12
			self.KorthiaArrow:SetTexCoord(coord-0.0833, coord, 0.0833 * (line-1), 0.0833 * line)

		--> update zereth arrow
			local questYaw = (DF.FindLookAtRotation (_, currentPlayerX, currentPlayerY, zerethPortalX, zerethPortalY) + (math.pi/2)) % (math.pi*2)
			local playerYaw = GetPlayerFacing() or 0
			local angle = (((questYaw + playerYaw)%(math.pi*2))+math.pi)%(math.pi*2)
			local imageIndex = 1+(floor(DF.MapRangeClamped(_, 0, (math.pi*2), 1, 144, angle)) + 48)%144 --48� quadro � o que aponta para o norte
			local line = ceil (imageIndex / 12)
			local coord = (imageIndex - ((line-1) * 12)) / 12
			self.ZerethArrow:SetTexCoord(coord-0.0833, coord, 0.0833 * (line-1), 0.0833 * line)


		if (UnitOnTaxi("player")) then
			oribosFlyMasterFrame.disableFlymasterTracker()
			return
		end
	end

	local LibWindow = LibStub("LibWindow-1.1")
	LibWindow.RegisterConfig(oribosFlyMasterFrame, WorldQuestTracker.db.profile.flymaster_tracker_frame_pos)
	LibWindow.MakeDraggable(oribosFlyMasterFrame)
	LibWindow.RestorePosition(oribosFlyMasterFrame)
	oribosFlyMasterFrame:EnableMouse(true)

	local enableFlymasterTracker = function()
		if (WorldQuestTracker.db.profile.flymaster_tracker_enabled) then
			oribosFlyMasterFrame:Show()
			oribosFlyMasterFrame:SetScript("OnUpdate", trackerOnTick)
			isFlymasterTrakcerEnabled = true

			if (not IsPlayerMoving()) then
				oribosFlyMasterFrame:SetAlpha(0)
				oribosFlyMasterFrame:EnableMouse(false)
			end
		end
	end
	oribosFlyMasterFrame.enableFlymasterTracker = enableFlymasterTracker

	local disableFlymasterTracker = function()
		oribosFlyMasterFrame:Hide()
		oribosFlyMasterFrame:SetScript("OnUpdate", nil)
		isFlymasterTrakcerEnabled = false
	end
	oribosFlyMasterFrame.disableFlymasterTracker = disableFlymasterTracker

	local checkIfIsInOribosSecondFloor = function()
		local currentMapId = C_Map.GetBestMapForUnit("player")
		if (currentMapId == secondFloormapId) then
			if (not UnitOnTaxi("player")) then
				if (not isFlymasterTrakcerEnabled) then
					enableFlymasterTracker()
				end
			end
		else
			if (isFlymasterTrakcerEnabled) then
				disableFlymasterTracker()
			end
		end
	end

	local oribosFlyMasterEventFrame = CreateFrame("frame", "WorldQuestTrackerOribosFlyMasterEventFrame")
	oribosFlyMasterEventFrame:SetScript("OnEvent", function(self, event, ...)
		C_Timer.After(1, checkIfIsInOribosSecondFloor)
	end)
	oribosFlyMasterEventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
	oribosFlyMasterEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

	C_Timer.After(0.1, checkIfIsInOribosSecondFloor)
end


----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> faction bounty

--function WorldMapMixin:AddOverlayFrame(templateName, templateType, anchorPoint, relativeTo, relativePoint, offsetX, offsetY)
--this return the bounty board frame, just check if templatename is "WorldMapBountyBoardTemplate"
--[=[
hooksecurefunc (WorldMapFrame, "AddOverlayFrame", function (...)
	print ("Hi ya", ...)
end)


--coloca a quantidade de quests completas para cada fac��o em cima do icone da fac��o
function WorldQuestTracker.SetBountyAmountCompleted (self, numCompleted, numTotal)
	if (not self.objectiveCompletedText) then
		self.objectiveCompletedText = self:CreateFontString (nil, "overlay", "GameFontNormal")
		self.objectiveCompletedText:SetPoint("bottom", self, "top", 1, 0)
		self.objectiveCompletedBackground = self:CreateTexture(nil, "background")
		self.objectiveCompletedBackground:SetPoint("bottom", self, "top", 0, -1)
		self.objectiveCompletedBackground:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
		self.objectiveCompletedBackground:SetSize(42, 12)
	end
	if (numCompleted) then
		self.objectiveCompletedText:SetText (numCompleted .. "/" .. numTotal)
		self.objectiveCompletedBackground:SetAlpha(.4)
	else
		self.objectiveCompletedText:SetText ("")
		self.objectiveCompletedBackground:SetAlpha(0)
	end
end

--quando selecionar uma fac��o, atualizar todas as quests no world map para que seja atualiza a quiantidade de quests que ha em cada mapa para esta fac�ao
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
		WorldQuestTracker.LastMapID = WorldQuestTracker.GetCurrentMapAreaID()
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
--]=]
