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

--localization
local L = DF.Language.GetLanguageTable(addonId)

local ff = WorldQuestTrackerFinderFrame

local _

local p = math.pi/2
local pi = math.pi
local pipi = math.pi*2
local GetPlayerFacing = GetPlayerFacing

local GetNumQuestLogRewardCurrencies = WorldQuestTrackerAddon.GetNumQuestLogRewardCurrencies
local GetQuestLogRewardInfo = GetQuestLogRewardInfo
local GetQuestLogRewardCurrencyInfo = WorldQuestTrackerAddon.GetQuestLogRewardCurrencyInfo
local GetQuestLogRewardMoney = GetQuestLogRewardMoney
local GetNumQuestLogRewards = GetNumQuestLogRewards
local GetQuestInfoByQuestID = C_TaskQuest.GetQuestInfoByQuestID

local MapRangeClamped = DF.MapRangeClamped
local FindLookAtRotation = DF.FindLookAtRotation
local GetDistance_Point = DF.GetDistance_Point

local LibWindow = LibStub ("LibWindow-1.1")

-- [12.0.1] issecretvalue(v) is the new global Lua function that returns true if a value
-- is an opaque "secret" returned by a restricted API. It is safe to call on any value.
-- We wrap it in a helper so call sites are concise and we gracefully handle builds
-- where the function hasn't been introduced yet (PTR/Classic cross-build safety).
local function isSV(v)
	return issecretvalue and issecretvalue(v)
end

-- Helper: returns true only when a value is both non-secret AND numerically > 0.
-- Use this everywhere a reward quantity is compared or iterated.
local function safeGT0(value)
	if isSV(value) then return false end
	return value and value > 0
end

-- Helper: iterate a secret-capable count.  Returns 0 if the count is secret.
local function safeCount(value)
	if isSV(value) then return 0 end
	return value or 0
end

if (not LibWindow) then
	print ("|cFFFFAA00World Quest Tracker|r: libwindow not found, did you just updated the addon? try reopening the client.|r")
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--> tracker quest --~tracker

local TRACKER_TITLE_TEXT_SIZE_INMAP = 12
local TRACKER_TITLE_TEXT_SIZE_OUTMAP = 10
local TRACKER_TITLE_TEXTWIDTH_MAX = 160
local TRACKER_ARROW_ALPHA_MAX = 1
local TRACKER_ARROW_ALPHA_MIN = .75
local TRACKER_BACKGROUND_ALPHA_MIN = 0
local TRACKER_BACKGROUND_ALPHA_MAX = 1
local TRACKER_FRAME_ALPHA_INMAP = 1
local TRACKER_FRAME_ALPHA_OUTMAP = .75

local worldFramePOIs = WorldQuestTrackerWorldMapPOI

--verifica se a quest ja esta na lista de track
function WorldQuestTracker.IsQuestBeingTracked (questID)
	for _, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		if (quest.questID == questID) then
			return true
		end
	end
	return
end

function WorldQuestTracker.SetTomTomQuestToTrack(questID)
	local uid = WorldQuestTracker.TomTomUIDs[questID]
	if (uid) then
		TomTom:SetCrazyArrow(uid, TomTom.profile.arrow.arrival, uid.title)
		TomTom:ShowHideCrazyArrow()
	end
end

function WorldQuestTracker.AddQuestTomTom (questID, mapID, noRemove)
	local x, y = C_TaskQuest.GetQuestLocation (questID, mapID)
	local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)

	local alreadyExists = TomTom:WaypointExists (mapID, x, y, title)

	if (alreadyExists and WorldQuestTracker.TomTomUIDs [questID]) then
		if (noRemove) then
			return
		end
		TomTom:RemoveWaypoint (WorldQuestTracker.TomTomUIDs [questID])
		WorldQuestTracker.TomTomUIDs [questID] = nil
		return
	end

	if (not alreadyExists) then
		local uid = TomTom:AddWaypoint (mapID, x, y, {title = title, persistent=false})
		WorldQuestTracker.TomTomUIDs [questID] = uid
	end

	return
end

--adiciona uma quest ao tracker
function WorldQuestTracker.AddQuestToTracker(self, questID, mapID)

	questID = self.questID or questID

	if (not HaveQuestData (questID)) then
		WorldQuestTracker:Msg (L["S_ERROR_NOTLOADEDYET"])
		return
	end

	if (WorldQuestTracker.IsQuestBeingTracked (questID)) then
		return
	end

	if (WorldQuestTracker.db.profile.tomtom.enabled and TomTom and C_AddOns.IsAddOnLoaded("TomTom")) then
		WorldQuestTracker.AddQuestTomTom (self.questID, self.mapID or mapID)
	end

	local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
	if (timeLeft and timeLeft > 0) then
		local mapID = self.mapID
		local iconTexture = self.IconTexture
		local iconText = self.IconText
		local questType = self.QuestType
		local numObjectives = self.numObjectives

		local conduitType, _, conduitBorderColor = WorldQuestTracker.GetConduitQuestData(questID)

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
				conduitType = conduitType,
				conduitBorderColor = conduitBorderColor,
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
function WorldQuestTracker.RemoveQuestFromTracker (questID, noUpdate)
	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		if (quest.questID == questID) then
			tremove (WorldQuestTracker.QuestTrackList, index)
			if (not noUpdate) then
				WorldQuestTracker.RefreshTrackerWidgets()
			end
			return true
		end
	end
end

--remove todas as quests do tracker
function WorldQuestTracker.RemoveAllQuestsFromTracker()
	local isShowingWorld = WorldQuestTrackerAddon.GetCurrentZoneType() == "world"

	for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
		local quest = WorldQuestTracker.QuestTrackList [i]
		tremove (WorldQuestTracker.QuestTrackList, i)
		local questID = quest.questID

		if (isShowingWorld) then
			for _, widget in pairs (WorldQuestTracker.WorldMapSmallWidgets) do
				if (widget:IsShown() and widget.questID == questID) then
					widget.onEndTrackAnimation:Play()
				end
			end
			for _, summarySquare in pairs (WorldQuestTracker.WorldSummaryQuestsSquares) do
				if (summarySquare:IsShown() and summarySquare.questID == questID) then
					summarySquare.onEndTrackAnimation:Play()
				end
			end
		else
			for _, widget in pairs (WorldQuestTracker.ZoneWidgetPool) do
				if (widget:IsShown() and widget.questID == questID) then
					widget.onEndTrackAnimation:Play()
				end
			end
		end
	end

	WorldQuestTracker.RefreshTrackerWidgets()
end

function WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker_Load()
	for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
		local quest = WorldQuestTracker.QuestTrackList [i]
		local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (quest.questID)
	end
end

function WorldQuestTracker.CheckTimeLeftOnQuestsFromTracker()
	local now = time()
	local gotRemoval

	for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
		local quest = WorldQuestTracker.QuestTrackList [i]
		local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (quest.questID)

		if (quest.expireAt < now or not timeLeft or timeLeft <= 0) then
			WorldQuestTracker.RemoveQuestFromTracker (quest.questID, true)
			gotRemoval = true
		end
	end
	if (gotRemoval) then
		WorldQuestTracker.RefreshTrackerWidgets()
	end
end


local Sort_currentMapID = 0
local Sort_QuestsOnTracker = function(t1, t2)
	if (t1.mapID == Sort_currentMapID and t2.mapID == Sort_currentMapID) then
		return t1.LastDistance > t2.LastDistance
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

function WorldQuestTracker.ReorderQuestsOnTracker()
	Sort_currentMapID = WorldQuestTracker.GetCurrentStandingMapAreaID()

	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		quest.LastDistance = quest.LastDistance or 0
	end
	table.sort (WorldQuestTracker.QuestTrackList, Sort_QuestsOnTracker)
end

--~trackerframe
local WorldQuestTrackerFrame_ScreenPanel = CreateFrame("frame", "WorldQuestTrackerScreenPanel", UIParent, "BackdropTemplate")
WorldQuestTrackerFrame_ScreenPanel:SetSize(235, 500)
WorldQuestTrackerFrame_ScreenPanel:SetFrameStrata("LOW")

function WorldQuestTracker.TrackerFrameOnInit()
	LibWindow.RegisterConfig(WorldQuestTrackerScreenPanel, WorldQuestTracker.db.profile)
	WorldQuestTrackerScreenPanel.RegisteredForLibWindow = true
	LibWindow.MakeDraggable(WorldQuestTrackerScreenPanel)

	if (not WorldQuestTracker.db.profile.tracker_attach_to_questlog) then
		LibWindow.RestorePosition(WorldQuestTrackerScreenPanel)
	end

	WorldQuestTracker.RefreshTrackerAnchor()
end

local WorldQuestTrackerFrame_QuestHolder = CreateFrame ("frame", "WorldQuestTrackerScreenPanel_QuestHolder", WorldQuestTrackerFrame_ScreenPanel, "BackdropTemplate")
WorldQuestTrackerFrame_QuestHolder:SetAllPoints()
WorldQuestTrackerFrame_QuestHolder:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
WorldQuestTrackerFrame_QuestHolder.MoveMeLabel = WorldQuestTracker:CreateLabel (WorldQuestTrackerFrame_QuestHolder, "== Move Me ==")

local lock_window = function()
	WorldQuestTracker.db.profile.tracker_is_locked = true
	WorldQuestTracker.RefreshTrackerAnchor()
end
WorldQuestTrackerFrame_QuestHolder.LockButton = WorldQuestTracker:CreateButton (WorldQuestTrackerFrame_QuestHolder, lock_window, 120, 24, "Lock Window", nil, nil, nil, nil, "WorldQuestTrackerLockTrackerButton", nil, WorldQuestTracker:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))

WorldQuestTrackerFrame_QuestHolder.MoveMeLabel:SetPoint("center", 0, 3)
WorldQuestTrackerFrame_QuestHolder.LockButton:SetPoint("center", 0, -16)
WorldQuestTrackerFrame_QuestHolder.MoveMeLabel:Hide()
WorldQuestTrackerFrame_QuestHolder.LockButton:Hide()

function WorldQuestTracker.UpdateTrackerScale()
	WorldQuestTrackerFrame_ScreenPanel:SetScale (WorldQuestTracker.db.profile.tracker_scale)
end

local WorldQuestTrackerHeader = CreateFrame ("frame", "WorldQuestTrackerQuestsHeader", WorldQuestTrackerFrame_ScreenPanel, "ObjectiveTrackerContainerHeaderTemplate")
WorldQuestTrackerHeader.Text:SetText ("World Quest Tracker")
local minimizeButton = CreateFrame ("button", "WorldQuestTrackerQuestsHeaderMinimizeButton", WorldQuestTrackerFrame_ScreenPanel, "BackdropTemplate")
local minimizeButtonText = minimizeButton:CreateFontString (nil, "overlay", "GameFontNormal")

WorldQuestTrackerHeader.MinimizeButton:Hide()

minimizeButtonText:SetText (L["S_WORLDQUESTS"])
minimizeButtonText:SetPoint("right", minimizeButton, "left", -3, 1)
minimizeButtonText:Hide()

WorldQuestTrackerFrame_ScreenPanel.MinimizeButton = minimizeButton
minimizeButton:SetSize(16, 16)
minimizeButton:SetPoint("topright", WorldQuestTrackerHeader, "topright", 0, -4)
minimizeButton:SetScript("OnClick", function()
	if (WorldQuestTrackerFrame_ScreenPanel.collapsed) then
		WorldQuestTrackerFrame_ScreenPanel.collapsed = false
		minimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0.5, 1)
		minimizeButton:GetPushedTexture():SetTexCoord(0.5, 1, 0.5, 1)
		WorldQuestTrackerFrame_QuestHolder:Show()
		WorldQuestTrackerHeader:Show()
		minimizeButtonText:Hide()
	else
		WorldQuestTrackerFrame_ScreenPanel.collapsed = true
		minimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5)
		minimizeButton:GetPushedTexture():SetTexCoord(0.5, 1, 0, 0.5)
		WorldQuestTrackerFrame_QuestHolder:Hide()
		WorldQuestTrackerHeader:Hide()
		minimizeButtonText:Show()
		minimizeButtonText:SetText ("World Quest Tracker")
	end
end)

minimizeButton:SetNormalTexture ([[Interface\Buttons\UI-Panel-QuestHideButton]])
minimizeButton:GetNormalTexture():SetTexCoord(0, 0.5, 0.5, 1)
minimizeButton:SetPushedTexture ([[Interface\Buttons\UI-Panel-QuestHideButton]])
minimizeButton:GetPushedTexture():SetTexCoord(0.5, 1, 0.5, 1)
minimizeButton:SetHighlightTexture ([[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]])
minimizeButton:SetDisabledTexture ([[Interface\Buttons\UI-Panel-QuestHideButton-disabled]])

local TrackerWidgetPool = {}
WorldQuestTracker.TrackerHeight = 0

function WorldQuestTracker.RefreshTrackerAnchor()
	if (not WorldQuestTracker.db.profile.use_tracker) then
		WorldQuestTrackerScreenPanel:Hide()
		return
	end

	if (WorldQuestTracker.db.profile.tracker_attach_to_questlog) then

		local questLogParts = {
			ObjectiveTrackerFrame.Header,
			ScenarioObjectiveTracker,
			UIWidgetObjectiveTracker,
			CampaignQuestObjectiveTracker,
			QuestObjectiveTracker,
			AdventureObjectiveTracker,
			AchievementObjectiveTracker,
			MonthlyActivitiesObjectiveTracker,
			ProfessionsRecipeTracker,
			BonusObjectiveTracker,
			WorldQuestObjectiveTracker,
		}

		local totalHeight = 0
		for _, part in ipairs(questLogParts) do
			if (part and part:IsShown()) then
				totalHeight = totalHeight + part:GetHeight()
			end
		end

		WorldQuestTrackerScreenPanel:EnableMouse(false)
		WorldQuestTrackerScreenPanel:ClearAllPoints()
		WorldQuestTrackerScreenPanel:SetPoint("topleft", ObjectiveTrackerFrame, "topleft", 7, -totalHeight - WorldQuestTrackerHeader:GetHeight() - 5)

		WorldQuestTrackerHeader:ClearAllPoints()
		WorldQuestTrackerHeader:SetPoint("topright", ObjectiveTrackerFrame, "topright", 0, -totalHeight - WorldQuestTrackerHeader:GetHeight() - 5)

		WorldQuestTrackerHeader:ClearAllPoints()
		WorldQuestTrackerHeader:SetPoint("top", WorldQuestTrackerScreenPanel, "top", 0, 0)

		WorldQuestTrackerFrame_QuestHolder.LockButton:Hide()
		WorldQuestTrackerFrame_QuestHolder.MoveMeLabel:Hide()
		WorldQuestTrackerFrame_QuestHolder:SetBackdrop(nil)

		WorldQuestTrackerScreenPanel:Show()
	else
		if (not WorldQuestTracker.db.profile.tracker_is_locked) then
			WorldQuestTrackerScreenPanel:EnableMouse(true)
			WorldQuestTrackerFrame_QuestHolder:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
			WorldQuestTrackerFrame_QuestHolder:SetBackdropColor(0, 0, 0, 0.75)
			WorldQuestTrackerFrame_QuestHolder.LockButton:Show()
			WorldQuestTrackerFrame_QuestHolder.MoveMeLabel:Show()
		else
			WorldQuestTrackerScreenPanel:EnableMouse(false)
			WorldQuestTrackerFrame_QuestHolder.LockButton:Hide()
			WorldQuestTrackerFrame_QuestHolder.MoveMeLabel:Hide()
			WorldQuestTrackerFrame_QuestHolder:SetBackdrop(nil)
		end

		-- Guard: LibWindow.RestorePosition will crash (indexing nil window data) if
		-- called before LibWindow.RegisterConfig has run for this frame.
		-- TrackerFrameOnInit() performs that registration, but RefreshTrackerAnchor
		-- can be triggered earlier via the ObjectiveTrackerManager hook chain.
		-- Only call RestorePosition once the frame is actually registered.
		if (WorldQuestTrackerScreenPanel.RegisteredForLibWindow) then
			LibWindow.RestorePosition(WorldQuestTrackerScreenPanel)
		end

		WorldQuestTrackerHeader:ClearAllPoints()
		WorldQuestTrackerHeader:SetPoint("bottom", WorldQuestTrackerFrame_ScreenPanel, "top", 0, -20)

		WorldQuestTrackerScreenPanel:Show()
	end
end

local TrackerIconButtonOnClick = function(self, button)
	if (button == "MiddleButton") then
		if (WorldQuestTracker.db.profile.groupfinder.enabled) then
			WorldQuestTracker.FindGroupForQuest (self.questID)
			return
		end

		if (WorldQuestGroupFinderAddon) then
			WorldQuestGroupFinder.HandleBlockClick (self.questID)
			return
		end
	end

	if (self.questID == C_SuperTrack.GetSuperTrackedQuestID()) then
		WorldQuestTracker.SuperTracked = nil
		C_SuperTrack.SetSuperTrackedQuestID(0)
		C_SuperTrack.ClearSuperTrackedContent()
		C_SuperTrack.IsSuperTrackingMapPin()
		return
	end

	if (HaveQuestData (self.questID)) then
		WorldQuestTracker.SelectSingleQuestInBlizzardWQTracker(self.questID)
		WorldQuestTracker.RefreshTrackerWidgets()
		WorldQuestTracker.SuperTracked = self.questID
	end
end

local TrackerFrameOnClick = function(self, button)
	if (button == "RightButton") then
		WorldQuestTracker.RemoveQuestFromTracker (self.questID)
		if (WorldMapFrame:IsShown()) then
			if (WorldQuestTracker.IsCurrentMapQuestHub()) then
				WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
			elseif (WorldQuestTracker.ZoneHaveWorldQuest()) then
				WorldQuestTracker.UpdateZoneWidgets (true)
				WorldQuestTracker.WorldWidgets_NeedFullRefresh = true
			end
		else
			WorldQuestTracker.WorldWidgets_NeedFullRefresh = true
		end
	else
		if (button == "MiddleButton") then
			if (WorldQuestTracker.db.profile.groupfinder.enabled) then
				WorldQuestTracker.FindGroupForQuest (self.questID)
				return
			end

			if (WorldQuestGroupFinderAddon) then
				WorldQuestGroupFinder.HandleBlockClick (self.questID)
				return
			end
		end

		TrackerIconButtonOnClick(self, "leftbutton")
		WorldQuestTracker.CanLinkToChat(self, button)
	end
end


local buildTooltip = function(self)
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -20, 0)
	GameTooltip:SetOwner (self, "ANCHOR_PRESERVE")
	local questID = self.questID

	if ( not HaveQuestData (questID) ) then
		GameTooltip:SetText (RETRIEVING_DATA, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
		GameTooltip:Show()
		return
	end

	local title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID (questID)
	local tagInfo = C_QuestLog.GetQuestTagInfo(questID)

	if (not tagInfo and WorldQuestTracker.__debug) then
		WorldQuestTracker:Msg("no tagInfo(2) for quest", questID)
	end

	local color = WORLD_QUEST_QUALITY_COLORS [tagInfo and tagInfo.quality or LE_WORLD_QUEST_QUALITY_COMMON]
	GameTooltip:SetText (title, color.r, color.g, color.b)

	if (factionID) then
		local factionName = WorldQuestTracker.GetFactionDataByID (factionID)
		if (factionName) then
			if (capped) then
				GameTooltip:AddLine (factionName, GRAY_FONT_COLOR:GetRGB())
			else
				GameTooltip:AddLine (factionName, 0.4, 0.733, 1.0)
			end
			GameTooltip:AddLine (" ")
		end
	end

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

	for objectiveIndex = 1, self.numObjectives do
		local objectiveText, objectiveType, finished = GetQuestObjectiveInfo(questID, objectiveIndex, false);
		if ( objectiveText and #objectiveText > 0 ) then
			local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
			GameTooltip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
		end
	end

	local percent = C_TaskQuest.GetQuestProgressBarInfo (questID)
	-- percent may be a secret value; only act on it if it's a real number.
	-- [12.0.1] GetQuestProgressBarInfo returns a secret when restricted.
	-- We skip the bar entirely rather than displaying garbage.

	-- rewards
	-- [12.0.1] All GetQuestLogReward* functions can now return secret values when called
	-- from an insecure context or during a restricted encounter.  Every numeric result
	-- must be checked with isSV() / safeGT0() before use to avoid Lua errors and to
	-- avoid leaking restricted information.
	local xp = GetQuestLogRewardXP(questID)
	local money = GetQuestLogRewardMoney(questID)
	local artifactXP = GetQuestLogRewardArtifactXP(questID)
	local numQuestCurrencies = GetNumQuestLogRewardCurrencies(questID)
	local numQuestRewards = GetNumQuestLogRewards(questID)

	local hasRewards = safeGT0(xp) or safeGT0(money) or safeGT0(artifactXP)
	                   or safeGT0(numQuestCurrencies) or safeGT0(numQuestRewards)

	if hasRewards then
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(QUEST_REWARDS, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
		local hasAnySingleLineRewards = false;

		-- xp
		if safeGT0(xp) then
			GameTooltip:AddLine(BONUS_OBJECTIVE_EXPERIENCE_FORMAT:format(xp), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			hasAnySingleLineRewards = true;
		end

		-- money
		if safeGT0(money) then
			-- [12.0.1] SetTooltipMoney is still available but the money value may be a
			-- secret. Passing a secret value into SetTooltipMoney causes a Lua error.
			-- Wrap in pcall as a safety net; the value has already been confirmed non-secret
			-- by safeGT0, but pcall protects against future API tightening.
			pcall(SetTooltipMoney, GameTooltip, money, nil);
			hasAnySingleLineRewards = true;
		end

		-- artifact xp
		if safeGT0(artifactXP) then
			GameTooltip:AddLine(BONUS_OBJECTIVE_ARTIFACT_XP_FORMAT:format(artifactXP), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			hasAnySingleLineRewards = true;
		end

		-- currency rewards
		-- [12.0.1] The count returned by GetNumQuestLogRewardCurrencies is secret-capable.
		-- safeCount() returns 0 for secrets so the loop is simply skipped.
		for i = 1, safeCount(numQuestCurrencies) do
			local name, texture, numItems = GetQuestLogRewardCurrencyInfo(i, questID);
			-- numItems itself may be secret when the game restricts reward amounts.
			if name and texture and numItems and not isSV(numItems) then
				local text = BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT:format(texture, numItems, name);
				GameTooltip:AddLine(text, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
				hasAnySingleLineRewards = true;
			end
		end

		-- item rewards
		for i = 1, safeCount(numQuestRewards) do
			local name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(i, questID);
			-- [12.0.1] numItems may be secret even when name/texture are available.
			if name and texture then
				local safeNumItems = (numItems and not isSV(numItems)) and numItems or nil
				local text;
				if safeNumItems and safeNumItems > 1 then
					text = string.format(BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT, texture, safeNumItems, name);
				else
					text = string.format(BONUS_OBJECTIVE_REWARD_FORMAT, texture, name);
				end
				if text then
					local color = quality and ITEM_QUALITY_COLORS[quality];
					if color then
						GameTooltip:AddLine(text, color.r, color.g, color.b);
					end
				end
			end
		end
	end

	GameTooltip:Show()
end
WorldQuestTracker.BuildTooltip = buildTooltip

local TrackerFrameOnEnter = function(self)
	local color = OBJECTIVE_TRACKER_COLOR["HeaderHighlight"]
	self.Title:SetTextColor (color.r, color.g, color.b)

	local color = OBJECTIVE_TRACKER_COLOR["NormalHighlight"]
	self.Zone:SetTextColor (color.r, color.g, color.b)

	self.RightBackground:SetAlpha(TRACKER_BACKGROUND_ALPHA_MAX)
	self.Arrow:SetAlpha(TRACKER_ARROW_ALPHA_MAX)
	buildTooltip (self)

	self.HasOverHover = true
end

local TrackerFrameOnLeave = function(self)
	local color = OBJECTIVE_TRACKER_COLOR["Header"]
	self.Title:SetTextColor (color.r, color.g, color.b)

	local color = OBJECTIVE_TRACKER_COLOR["Normal"]
	self.Zone:SetTextColor (color.r, color.g, color.b)

	self.RightBackground:SetAlpha(TRACKER_BACKGROUND_ALPHA_MIN)
	self.Arrow:SetAlpha(TRACKER_ARROW_ALPHA_MIN)
	GameTooltip:Hide()

	self.HasOverHover = nil
	self.QuestInfomation.text = ""
end

local TrackerIconButtonOnEnter = function(self)
end
local TrackerIconButtonOnLeave = function(self)
end


--~arrow
	function WorldQuestTracker.SelectSingleQuestInBlizzardWQTracker (questID)
		QuestUtil.TrackWorldQuest(questID, Enum.QuestWatchType.Automatic)
		C_SuperTrack.SetSuperTrackedQuestID(questID)
	end

local TrackerIconButtonOnMouseDown = function(self, button)
	self.Icon:SetPoint("topleft", self:GetParent(), "topleft", -12, -3)
end
local TrackerIconButtonOnMouseUp = function(self, button)
	self.Icon:SetPoint("topleft", self:GetParent(), "topleft", -13, -2)
end


function WorldQuestTracker.GetOrCreateTrackerWidget (index)
	if (TrackerWidgetPool [index]) then
		return TrackerWidgetPool [index]
	end

	local f = CreateFrame ("button", "WorldQuestTracker_Tracker" .. index, WorldQuestTrackerFrame_QuestHolder, "BackdropTemplate")
	f:SetSize(235, 30)
	f:SetScript("OnClick", TrackerFrameOnClick)
	f:SetScript("OnEnter", TrackerFrameOnEnter)
	f:SetScript("OnLeave", TrackerFrameOnLeave)
	f:RegisterForClicks("LeftButtonDown", "MiddleButtonDown", "RightButtonDown")

	f.RightBackground = f:CreateTexture(nil, "background")
	f.RightBackground:SetTexture([[Interface\ACHIEVEMENTFRAME\UI-Achievement-HorizontalShadow]])
	f.RightBackground:SetTexCoord(1, 61/128, 0, 1)
	f.RightBackground:SetDesaturated (true)
	f.RightBackground:SetPoint("topright", f, "topright")
	f.RightBackground:SetPoint("bottomright", f, "bottomright")
	f.RightBackground:SetWidth (200)
	f.RightBackground:SetAlpha(TRACKER_BACKGROUND_ALPHA_MIN)

	f.worldQuest = true

	f.Title = DF:CreateLabel (f)
	f.Title.textsize = TRACKER_TITLE_TEXT_SIZE_INMAP
	f.Title:SetPoint("topleft", f, "topleft", 10, -1)
	local titleColor = OBJECTIVE_TRACKER_COLOR["Header"]
	f.Title:SetTextColor (titleColor.r, titleColor.g, titleColor.b)
	f.Zone = DF:CreateLabel (f)
	f.Zone.textsize = TRACKER_TITLE_TEXT_SIZE_INMAP
	f.Zone:SetPoint("topleft", f, "topleft", 10, -17)

	f.QuestInfomation = DF:CreateLabel (f)
	f.QuestInfomation:SetPoint("topright", f, "topleft", -10, 50)

	f.YardsDistance = f:CreateFontString (nil, "overlay", "GameFontNormal")
	f.YardsDistance:SetPoint("left", f.Zone.widget, "right", 2, 0)
	f.YardsDistance:SetJustifyH ("left")
	DF:SetFontColor (f.YardsDistance, "white")
	DF:SetFontSize (f.YardsDistance, 12)
	f.YardsDistance:SetAlpha(.5)

	f.TimeLeft = f:CreateFontString (nil, "overlay", "GameFontNormal")
	f.TimeLeft:SetPoint("left", f.YardsDistance, "right", 2, 0)
	f.TimeLeft:SetJustifyH ("left")
	DF:SetFontColor (f.TimeLeft, "white")
	DF:SetFontSize (f.TimeLeft, 12)
	f.TimeLeft:SetAlpha(.5)

	f.Icon = f:CreateTexture(nil, "artwork")
	f.Icon:SetPoint("topleft", f, "topleft", -13, -2)
	f.Icon:SetSize(16, 16)
	f.Icon:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])

	local IconButton = CreateFrame ("button", "$parentIconButton", f, "BackdropTemplate")
	IconButton:SetSize(18, 18)
	IconButton:SetPoint("center", f.Icon, "center")
	IconButton:SetScript("OnEnter", TrackerIconButtonOnEnter)
	IconButton:SetScript("OnLeave", TrackerIconButtonOnLeave)
	IconButton:SetScript("OnClick", TrackerIconButtonOnClick)
	IconButton:SetScript("OnMouseDown", TrackerIconButtonOnMouseDown)
	IconButton:SetScript("OnMouseUp", TrackerIconButtonOnMouseUp)
	IconButton:RegisterForClicks("LeftButtonDown", "MiddleButtonDown")
	IconButton.Icon = f.Icon
	f.IconButton = IconButton

	f.Circle = f:CreateTexture(nil, "overlay")
	f.Circle:SetAtlas("transmog-nav-slot-selected")
	f.Circle:SetSize(22, 22)
	f.Circle:SetPoint("topleft", f, "topleft", -16, 0)
	f.Circle:SetDesaturated (true)
	f.Circle:SetAlpha(.7)

	f.RewardAmount = f:CreateFontString (nil, "overlay", "ObjectiveFont")
	f.RewardAmount:SetTextColor (titleColor.r, titleColor.g, titleColor.b)
	f.RewardAmount:SetPoint("top", f.Circle, "bottom", 1, 3)
	DF:SetFontSize (f.RewardAmount, 10)

	f.BackgroupTexture = f:CreateTexture(nil, "background")
	f.BackgroupTexture:SetPoint("topleft", f, "topleft", -25, 2)
	f.BackgroupTexture:SetPoint("bottomright", f, "bottomright", 20, -2)
	f.BackgroupTexture:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT.blp]])
	f.BackgroupTexture:SetVertexColor(0, 0, 0, .5)

	local overlayBorder = f:CreateTexture(nil, "overlay", nil, 5)
	local overlayBorder2 = f:CreateTexture(nil, "overlay", nil, 6)
	overlayBorder:SetDrawLayer("overlay", 5)
	overlayBorder2:SetDrawLayer("overlay", 6)
	overlayBorder:SetTexture([[Interface\Soulbinds\SoulbindsConduitIconBorder]])
	overlayBorder2:SetTexture([[Interface\Soulbinds\SoulbindsConduitIconBorder]])
	overlayBorder:SetTexCoord(0/256, 66/256, 0, 0.5)
	overlayBorder2:SetTexCoord(67/256, 132/256, 0, 0.5)
	overlayBorder:SetPoint("topleft", f.Circle, "topleft", 0, 0)
	overlayBorder:SetPoint("bottomright", f.Circle, "bottomright", 0, 0)
	overlayBorder2:SetPoint("topleft", f.Circle, "topleft", 0, 0)
	overlayBorder2:SetPoint("bottomright", f.Circle, "bottomright", 0, 0)
	overlayBorder:Hide()
	overlayBorder2:Hide()
	f.overlayBorder = overlayBorder
	f.overlayBorder2 = overlayBorder2

	f.Shadow = f:CreateTexture(nil, "BACKGROUND")
	f.Shadow:SetSize(26, 26)
	f.Shadow:SetPoint("center", f.Circle, "center")
	f.Shadow:SetTexture([[Interface\PETBATTLES\BattleBar-AbilityBadge-Neutral]])
	f.Shadow:SetAlpha(.3)
	f.Shadow:SetDrawLayer("BACKGROUND", -5)

	f.SuperTracked = f:CreateTexture(nil, "background")
	f.SuperTracked:SetPoint("center", f.Circle, "center")
	f.SuperTracked:SetAlpha(1)
	f.SuperTracked:SetTexture([[Interface\Worldmap\UI-QuestPoi-IconGlow]])
	f.SuperTracked:SetBlendMode("ADD")
	f.SuperTracked:SetSize(42, 42)
	f.SuperTracked:SetDrawLayer("BACKGROUND", -6)
	f.SuperTracked:Hide()

	local highlight = IconButton:CreateTexture(nil, "highlight")
	highlight:SetPoint("center", f.Circle, "center")
	highlight:SetAlpha(1)
	highlight:SetTexture([[Interface\Worldmap\UI-QuestPoi-NumberIcons]])
	highlight:SetTexCoord(167/256, 185/256, 231/256, 249/256)
	highlight:SetBlendMode("ADD")
	highlight:SetSize(14, 14)

	f.SuperTrackButton = CreateFrame("button", nil, f)
	f.SuperTrackButton:SetPoint("right", f, "right", 2, 0)
	f.SuperTrackButton:SetSize(18, 24)
	f.SuperTrackButton:SetAlpha(.5)
	f.SuperTrackButton.Icon = f.SuperTrackButton:CreateTexture(nil, "overlay")
	f.SuperTrackButton.Icon:SetAllPoints()
	f.SuperTrackButton.Icon:SetAtlas("Navigation-Tracked-Icon", true)

	f.Arrow = f:CreateTexture(nil, "overlay")
	f.Arrow:SetPoint("right", f.SuperTrackButton, "left", 0, 0)
	f.Arrow:SetSize(32, 32)
	f.Arrow:SetAlpha(.6)
	f.Arrow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\ArrowGridT]])

	f.ArrowDistance = f:CreateTexture(nil, "overlay")
	f.ArrowDistance:SetPoint("center", f.Arrow, "center", 0, 0)
	f.ArrowDistance:SetSize(34, 34)
	f.ArrowDistance:SetAlpha(.5)
	f.ArrowDistance:SetTexture([[Interface\AddOns\WorldQuestTracker\media\ArrowGridTGlow]])
	f.ArrowDistance:SetDrawLayer("overlay", 4)
	f.Arrow:SetDrawLayer("overlay", 5)

	f.SuperTrackButton:SetScript("OnClick", function(self, button)
		TrackerIconButtonOnClick(f, button)
	end)

	f.SuperTrackButton:SetScript("OnEnter", function()
		f.SuperTrackButton:SetAlpha(1)
	end)
	f.SuperTrackButton:SetScript("OnLeave", function()
		if (not f.SuperTracked:IsShown()) then
			f.SuperTrackButton:SetAlpha(.3)
		end
	end)

	f.TomTomTrackerIcon = CreateFrame("button", nil, f)
	f.TomTomTrackerIcon:SetPoint("right", f.Arrow, "left", -6, 0)
	f.TomTomTrackerIcon:SetSize(24, 24)
	f.TomTomTrackerIcon:SetAlpha(.5)
	f.TomTomTrackerIcon.Icon = f.TomTomTrackerIcon:CreateTexture(nil, "overlay")
	f.TomTomTrackerIcon.Icon:SetAllPoints()
	f.TomTomTrackerIcon.Icon:SetTexture([[Interface\AddOns\TomTom\Images\StaticArrow]])
	f.TomTomTrackerIcon:SetScript("OnClick", function()
		WorldQuestTracker.AddQuestTomTom (f.questID, f.questMapID, true)
		WorldQuestTracker.SetTomTomQuestToTrack(f.questID)
	end)
	f.TomTomTrackerIcon:SetScript("OnEnter", function()
		f.TomTomTrackerIcon:SetAlpha(1)
	end)
	f.TomTomTrackerIcon:SetScript("OnLeave", function()
		f.TomTomTrackerIcon:SetAlpha(.5)
	end)

	------------------------

	f.AnimationFrame = CreateFrame ("frame", "$parentAnimation", f, "BackdropTemplate")
	f.AnimationFrame:SetAllPoints()
	f.AnimationFrame:SetFrameLevel(f:GetFrameLevel()-1)
	f.AnimationFrame:Hide()

	local star = f.AnimationFrame:CreateTexture(nil, "overlay")
	star:SetTexture([[Interface\Cooldown\star4]])
	star:SetSize(168, 168)
	star:SetPoint("center", f.Icon, "center", 1, -1)
	star:SetBlendMode("ADD")
	star:Hide()

	local flash = f.AnimationFrame:CreateTexture(nil, "overlay")
	flash:SetTexture([[Interface\ACHIEVEMENTFRAME\UI-Achievement-Alert-Glow]])
	flash:SetTexCoord(0, 400/512, 0, 170/256)
	flash:SetPoint("topleft", -60, 30)
	flash:SetPoint("bottomright", 40, -30)
	flash:SetBlendMode("ADD")

	local spark = f.AnimationFrame:CreateTexture(nil, "overlay")
	spark:SetTexture([[Interface\ACHIEVEMENTFRAME\UI-Achievement-Alert-Glow]])
	spark:SetTexCoord(400/512, 470/512, 0, 70/256)
	spark:SetSize(50, 34)
	spark:SetBlendMode("ADD")
	spark:SetPoint("left")

	local iconoverlay = f:CreateTexture(nil, "overlay")
	iconoverlay:SetTexture([[Interface\COMMON\StreamBackground]])
	iconoverlay:SetPoint("center", f.Icon, "center", 0, 0)
	iconoverlay:Hide()
	iconoverlay:SetDrawLayer("overlay", 7)

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
		spark:SetPoint("left", -40, 0)
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

local nextPlayerPositionUpdateCooldown = -1
local currentPlayerX = 0
local currentPlayerY = 0

-- ~trackertick ~trackeronupdate ~tick ~onupdate ~ontick
local TrackerOnTick = function(self, deltaTime)
	if (self.NextPositionUpdate < 0) then
		if (Sort_currentMapID ~= WorldQuestTracker.GetCurrentStandingMapAreaID()) then
			self.Arrow:SetAlpha(.3)
			self.Arrow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\ArrowFrozen]])
			self.Arrow:SetTexCoord(0, 1, 0, 1)
			self.ArrowDistance:Hide()
			self.Arrow.Frozen = true
			return
		elseif (self.Arrow.Frozen) then
			self.Arrow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\ArrowGridT]])
			self.ArrowDistance:Show()
			self.Arrow.Frozen = nil
		end
	end

	if (nextPlayerPositionUpdateCooldown < 0) then
		nextPlayerPositionUpdateCooldown = 1

		local mapPosition = C_Map.GetPlayerMapPosition(WorldQuestTracker.GetCurrentStandingMapAreaID(), "player")
		if (not mapPosition) then
			return
		end
		currentPlayerX, currentPlayerY = mapPosition.x, mapPosition.y
	else
		nextPlayerPositionUpdateCooldown = nextPlayerPositionUpdateCooldown - deltaTime
	end

	if (self.NextArrowUpdate < 0) then
		local questYaw = (FindLookAtRotation (_, currentPlayerX, currentPlayerY, self.questX, self.questY) + p)%pipi
		local playerYaw = GetPlayerFacing() or 0
		local angle = (((questYaw + playerYaw)%pipi)+pi)%pipi
		local imageIndex = 1+(floor (MapRangeClamped (_, 0, pipi, 1, 144, angle)) + 48)%144
		local line = ceil (imageIndex / 12)
		local coord = (imageIndex - ((line-1) * 12)) / 12
		self.Arrow:SetTexCoord(coord-0.0833, coord, 0.0833 * (line-1), 0.0833 * line)
		self.ArrowDistance:SetTexCoord(coord-0.0833, coord, 0.0833 * (line-1), 0.0833 * line)

		self.NextArrowUpdate = ARROW_UPDATE_FREQUENCE
	else
		self.NextArrowUpdate = self.NextArrowUpdate - deltaTime
	end

	self.NextPositionUpdate = self.NextPositionUpdate - deltaTime

	if ((playerIsMoving or self.ForceUpdate) and self.NextPositionUpdate < 0) then
		local distance = GetDistance_Point(_, currentPlayerX, currentPlayerY, self.questX, self.questY)

		-- [12.0.1] CalculateDistance() was a Blizzard global helper that computed
		-- map-coordinate distances in yards using internal zone size data.  It was
		-- removed in the 12.0 SpellScript/InstanceEncounter deprecation sweep because
		-- it relied on restricted combat math.  We now replicate its formula using
		-- the zone pixel dimensions already retrieved via HereBeDragons:GetZoneSize(),
		-- stored in the upvalues zoneXLength / zoneYLength.
		-- Original: CalculateDistance(x1,y1,x2,y2) → yards
		-- Replacement: scale the unitless map-coord delta by zone dimensions in yards.
		local dx = (self.questX - currentPlayerX) * zoneXLength
		local dy = (self.questY - currentPlayerY) * zoneYLength
		local yards = floor((dx*dx + dy*dy)^0.5)

		local yardsText
		if (yards > 1000) then
			yardsText = format("%.2f", yards / 1000) .. "km"
		else
			yardsText = yards .. "yds"
		end
		self.YardsDistance:SetText ("[|cFFC0C0C0" .. yardsText .. "|r]")

		distance = abs (distance - 1)
		self.info.LastDistance = distance

		distance = Saturate (distance - 0.75) * 4
		local alpha = MapRangeClamped (_, 0, 1, 0, 0.5, distance)
		self.Arrow:SetAlpha(.5 + (alpha))
		self.ArrowDistance:SetVertexColor(distance, distance, distance)

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

local TrackerOnTick_TimeLeft = function(self, deltaTime)
	self.NextTimeUpdate = self.NextTimeUpdate - deltaTime

	if (self.NextTimeUpdate < 0) then
		if (HaveQuestData (self.questID)) then
			local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (self.questID)
			if (timeLeft and timeLeft > 0) then
				local timeLeft2 =  WorldQuestTracker.GetQuest_TimeLeft (self.questID, true)
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


function WorldQuestTracker.RefreshTrackerWidgets()
	if (WorldQuestTracker.LastTrackerRefresh and WorldQuestTracker.LastTrackerRefresh+0.2 > GetTime()) then
		return
	end
	WorldQuestTracker.LastTrackerRefresh = GetTime()

	WorldQuestTracker.ReorderQuestsOnTracker()

	local y = -30
	local nextWidget = 1
	local needSortByDistance = 0
	local onlyCurrentMap = WorldQuestTracker.db.profile.tracker_only_currentmap
	local currentMap = WorldQuestTracker.GetCurrentStandingMapAreaID()

	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		if (HaveQuestData(quest.questID)) then
			local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info(quest.questID)

			if (quest.mapID == WorldQuestTracker.MapData.ZoneIDs.ZANDALAR or quest.mapID == WorldQuestTracker.MapData.ZoneIDs.KULTIRAS) then
				if (WorldQuestTracker.CurrentZoneQuests [quest.questID] and WorldQuestTracker.CurrentZoneQuestsMapID == currentMap) then
					quest.mapID = currentMap
				end
			end

			if (not quest.isDisabled and title and (not onlyCurrentMap or (onlyCurrentMap and Sort_currentMapID == quest.mapID))) then
				local widget = WorldQuestTracker.GetOrCreateTrackerWidget(nextWidget)
				widget:ClearAllPoints()
				widget:SetPoint("topleft", WorldQuestTrackerFrame_ScreenPanel, "topleft", 0, y-10)
				widget.questID = quest.questID
				widget.questMapID = quest.mapID
				widget.info = quest
				widget.numObjectives = quest.numObjectives
				widget.SuperTrackButton.questID = quest.questID

				widget.BackgroupTexture:SetVertexColor (0, 0, 0, WorldQuestTracker.db.profile.tracker_background_alpha)

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

				widget.Icon:SetTexture(quest.rewardTexture)
				widget.IconButton.questID = quest.questID

				local conduitType = quest.conduitType
				local conduitBorderColor = quest.conduitBorderColor or {1, 1, 1, 1}

				if (conduitType) then
					widget.overlayBorder:Show()
					widget.overlayBorder2:Show()
					widget.overlayBorder:SetVertexColor(unpack(conduitBorderColor))
				else
					widget.overlayBorder:Hide()
					widget.overlayBorder2:Hide()
				end

				-- [12.0.1] WorldMap_IsWorldQuestEffectivelyTracked was renamed to
				-- C_QuestLog.IsWorldQuestWatched in 12.0 as part of the API namespace
				-- consolidation. We try the new name first and fall back to the old one
				-- for any build that still has it, so this file works across both.
				local isTracked = false
				if C_QuestLog.IsWorldQuestWatched then
					isTracked = C_QuestLog.IsWorldQuestWatched(quest.questID)
				elseif WorldMap_IsWorldQuestEffectivelyTracked then
					isTracked = WorldMap_IsWorldQuestEffectivelyTracked(quest.questID)
				end

				if isTracked then
					widget.SuperTracked:Show()
					widget.SuperTrackButton:SetAlpha(1)
					widget.Circle:SetDesaturated (false)
				else
					widget.SuperTracked:Hide()
					widget.SuperTrackButton:SetAlpha(0.25)
					widget.Circle:SetDesaturated (true)
				end

				if (type (quest.rewardAmount) == "number" and quest.rewardAmount >= 1000) then
					widget.RewardAmount:SetText (WorldQuestTracker.ToK (quest.rewardAmount))
				else
					widget.RewardAmount:SetText (quest.rewardAmount)
				end

				if (WorldQuestTracker.db.profile.tomtom.enabled) then
					widget.TomTomTrackerIcon:Show()
				else
					widget.TomTomTrackerIcon:Hide()
				end

				widget:Show()

				WorldQuestTracker.db.profile.TutorialTracker = WorldQuestTracker.db.profile.TutorialTracker or 1

				if (WorldQuestTracker.db.profile.TutorialTracker == 1) then
					WorldQuestTracker.db.profile.TutorialTracker = WorldQuestTracker.db.profile.TutorialTracker + 1
				end

				if (WorldQuestTracker.JustAddedToTracker [quest.questID]) then
					widget.AnimationFrame.ShowAnimation()
					WorldQuestTracker.JustAddedToTracker [quest.questID] = nil
				end

				if (Sort_currentMapID == quest.mapID) then
					local x, y = C_TaskQuest.GetQuestLocation (quest.questID, quest.mapID)
					widget.questX, widget.questY = x or 0, y or 0

					local HereBeDragons = LibStub ("HereBeDragons-2.0")
					zoneXLength, zoneYLength = HereBeDragons:GetZoneSize (quest.mapID)

					widget.NextPositionUpdate = -1
					widget.NextArrowUpdate = -1
					widget.NextTimeUpdate = -1

					widget.ForceUpdate = true

					widget:SetScript("OnUpdate", TrackerOnTick)
					widget.Arrow:Show()
					widget.ArrowDistance:Show()
					widget.RightBackground:Show()
					widget:SetAlpha(TRACKER_FRAME_ALPHA_INMAP)
					widget.Title.textsize = WorldQuestTracker.db.profile.tracker_textsize
					widget.Zone.textsize = WorldQuestTracker.db.profile.tracker_textsize
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
				else
					widget.Arrow:Hide()
					widget.ArrowDistance:Hide()
					widget.RightBackground:Hide()
					widget:SetAlpha(TRACKER_FRAME_ALPHA_OUTMAP)
					widget.Title.textsize = TRACKER_TITLE_TEXT_SIZE_OUTMAP
					widget.Zone.textsize = TRACKER_TITLE_TEXT_SIZE_OUTMAP
					widget.YardsDistance:SetText ("")
					widget:SetScript("OnUpdate", nil)

					if (WorldQuestTracker.db.profile.tracker_show_time) then
						widget.TimeLeft:Show()
						DF:SetFontSize (widget.TimeLeft, TRACKER_TITLE_TEXT_SIZE_OUTMAP)
						widget.NextTimeUpdate = -1
						widget:SetScript("OnUpdate", TrackerOnTick_TimeLeft)
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

	if (nextWidget == 1) then
		WorldQuestTrackerHeader:Hide()
		minimizeButton:Hide()
	else
		if (not WorldQuestTrackerFrame_ScreenPanel.collapsed) then
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

	for i = nextWidget, #TrackerWidgetPool do
		TrackerWidgetPool [i]:SetScript("OnUpdate", nil)
		TrackerWidgetPool [i]:Hide()
	end

	WorldQuestTracker.RefreshTrackerAnchor()
end



local TrackerAnimation_OnAccept = CreateFrame ("frame", nil, UIParent, "BackdropTemplate")
TrackerAnimation_OnAccept:SetSize(235, 30)
TrackerAnimation_OnAccept.Title = DF:CreateLabel (TrackerAnimation_OnAccept)
TrackerAnimation_OnAccept.Title.textsize = TRACKER_TITLE_TEXT_SIZE_INMAP
TrackerAnimation_OnAccept.Title:SetPoint("topleft", TrackerAnimation_OnAccept, "topleft", 10, -1)
local titleColor = OBJECTIVE_TRACKER_COLOR["Header"]
TrackerAnimation_OnAccept.Title:SetTextColor (titleColor.r, titleColor.g, titleColor.b)
TrackerAnimation_OnAccept.Zone = DF:CreateLabel (TrackerAnimation_OnAccept)
TrackerAnimation_OnAccept.Zone.textsize = TRACKER_TITLE_TEXT_SIZE_INMAP
TrackerAnimation_OnAccept.Zone:SetPoint("topleft", TrackerAnimation_OnAccept, "topleft", 10, -17)
TrackerAnimation_OnAccept.Icon = TrackerAnimation_OnAccept:CreateTexture(nil, "artwork")
TrackerAnimation_OnAccept.Icon:SetPoint("topleft", TrackerAnimation_OnAccept, "topleft", -13, -2)
TrackerAnimation_OnAccept.Icon:SetSize(16, 16)
TrackerAnimation_OnAccept.RewardAmount = TrackerAnimation_OnAccept:CreateFontString (nil, "overlay", "ObjectiveFont")
TrackerAnimation_OnAccept.RewardAmount:SetTextColor (titleColor.r, titleColor.g, titleColor.b)
TrackerAnimation_OnAccept.RewardAmount:SetPoint("top", TrackerAnimation_OnAccept.Icon, "bottom", 0, -2)
DF:SetFontSize (TrackerAnimation_OnAccept.RewardAmount, 10)
TrackerAnimation_OnAccept:Hide()

TrackerAnimation_OnAccept.FlashTexture = TrackerAnimation_OnAccept:CreateTexture(nil, "background")
TrackerAnimation_OnAccept.FlashTexture:SetTexture([[Interface\ACHIEVEMENTFRAME\UI-Achievement-Alert-Glow]])
TrackerAnimation_OnAccept.FlashTexture:SetTexCoord(0, 400/512, 0, 168/256)
TrackerAnimation_OnAccept.FlashTexture:SetBlendMode("ADD")
TrackerAnimation_OnAccept.FlashTexture:SetPoint("topleft", -60, 40)
TrackerAnimation_OnAccept.FlashTexture:SetPoint("bottomright", 40, -35)

local TrackerAnimation_OnAccept_MoveAnimation = DF:CreateAnimationHub (TrackerAnimation_OnAccept, function (self)
		local quest = self.QuestObject
		local widget = self.WidgetObject
		TrackerAnimation_OnAccept.Title.text = widget.Title.text
		TrackerAnimation_OnAccept.Zone.text = widget.Zone.text
		if (quest.questType == QUESTTYPE_ARTIFACTPOWER) then
			TrackerAnimation_OnAccept.Icon:SetMask (nil)
		else
			TrackerAnimation_OnAccept.Icon:SetMask ([[Interface\CharacterFrame\TempPortraitAlphaMask]])
		end
		TrackerAnimation_OnAccept.Icon:SetTexture(quest.rewardTexture)
		TrackerAnimation_OnAccept.RewardAmount:SetText (widget.RewardAmount:GetText())
	end,
	function (self)
		TrackerAnimation_OnAccept:Hide()
	end)
local ScreenWidth = -(floor (GetScreenWidth() / 2) - 200)
TrackerAnimation_OnAccept_MoveAnimation.Translation = DF:CreateAnimation (TrackerAnimation_OnAccept_MoveAnimation, "translation", 1, 2, ScreenWidth, 270)
DF:CreateAnimation (TrackerAnimation_OnAccept_MoveAnimation, "alpha", 1, 1.6, 1, 0)

local TrackerAnimation_OnAccept_FlashAnimation = DF:CreateAnimationHub (TrackerAnimation_OnAccept.FlashTexture,
	function (self)
		TrackerAnimation_OnAccept.Title.text = ""
		TrackerAnimation_OnAccept.Zone.text = ""
		TrackerAnimation_OnAccept.Icon:SetTexture(nil)
		TrackerAnimation_OnAccept.RewardAmount:SetText ("")
		TrackerAnimation_OnAccept:Show()
		TrackerAnimation_OnAccept.FlashTexture:Show()
		TrackerAnimation_OnAccept:SetPoint("topleft", self.WidgetObject, "topleft", 0, 0)
	end,
	function (self)
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

local get_widget_from_questID = function(questID)
	for i = 1, #TrackerWidgetPool do
		if (TrackerWidgetPool[i].questID == questID) then
			return TrackerWidgetPool[i]
		end
	end
end

function WorldQuestTracker.UpdateQuestsInArea()
	for index, quest in ipairs (WorldQuestTracker.QuestTrackList) do
		if (HaveQuestData (quest.questID)) then
			-- [12.0.1] The original code referenced a bare `isInArea` variable that was
			-- never defined in this file — it was likely an upvalue from a deleted block or
			-- a global that no longer exists.  The intent was to detect whether the player
			-- has physically entered the quest's objective area (i.e. the Blizzard tracker
			-- is now showing the quest because the player is inside its bounds).
			-- We replace it with the documented C_QuestLog API: IsOnQuest returns true
			-- when the quest is active AND its objectives are currently in range, which
			-- is the correct modern equivalent.
			local isInArea = C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(quest.questID)

			if (isInArea) then
				if (not quest.isDisabled and not quest.enteringZone) then
					local widget = get_widget_from_questID (quest.questID)
					if (widget and not WorldQuestTracker.IsQuestOnObjectiveTracker (widget.Title:GetText())) then
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
			else
				quest.isDisabled = nil
			end
		end
	end
	WorldQuestTracker.RefreshTrackerWidgets()
end


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

local latestTrackerPositionUpdate = GetTime()
local bHasScheduledSizeUpdate = false

local onObjectiveTrackerChanges = function()
	if (ObjectiveTrackerFrame:IsCollapsed()) then
		return
	end

	local objectiveTrackerHeight = 0
    for moduleFrame in pairs (ObjectiveTrackerManager.moduleToContainerMap) do
		if (type(moduleFrame) == "table" and moduleFrame.GetObjectType and moduleFrame:GetObjectType() == "Frame" and moduleFrame:IsShown()) then
        	objectiveTrackerHeight = objectiveTrackerHeight + moduleFrame:GetHeight()
		end
    end
	WorldQuestTracker.TrackerHeight = objectiveTrackerHeight + 50

	WorldQuestTracker.RefreshTrackerAnchor()

	if (not bHasScheduledSizeUpdate) then
		C_Timer.After(0, WorldQuestTracker.OnObjectiveTrackerChanges)
		bHasScheduledSizeUpdate = true
	end
end

function WorldQuestTracker.OnObjectiveTrackerChanges()
	if (GetTime() == latestTrackerPositionUpdate) then
		return
	end

	latestTrackerPositionUpdate = GetTime()
	onObjectiveTrackerChanges()
	bHasScheduledSizeUpdate = false
end

if (ObjectiveTrackerManager) then
	hooksecurefunc(ObjectiveTrackerManager, "ReleaseFrame", onObjectiveTrackerChanges)
	hooksecurefunc(ObjectiveTrackerManager, "AcquireFrame", onObjectiveTrackerChanges)

	ObjectiveTrackerFrame.Header.MinimizeButton:HookScript("OnClick", function()
		if (ObjectiveTrackerFrame:IsCollapsed()) then
			WorldQuestTracker.TrackerHeight = 35
			WorldQuestTracker.RefreshTrackerAnchor()
		end
	end)
else
	C_Timer.After(0, function()
		hooksecurefunc(ObjectiveTrackerManager, "ReleaseFrame", onObjectiveTrackerChanges)
		hooksecurefunc(ObjectiveTrackerManager, "AcquireFrame", onObjectiveTrackerChanges)
	end)
end

-- [12.0.1] BonusObjectiveTracker.OnQuestTurnedIn no longer exists as a hookable method
-- in 12.0 — BonusObjectiveTracker was deprecated and absorbed into the consolidated
-- objective tracker system.  The QUEST_TURNED_IN event (already handled globally in
-- the core file) is the correct replacement.  We keep the event-based handler below
-- and add a nil-guard on BonusObjectiveTracker so the file does not error on load.
if BonusObjectiveTracker and BonusObjectiveTracker.OnQuestTurnedIn then
	-- Pre-12.0 path: hook was valid.
	hooksecurefunc(BonusObjectiveTracker, "OnQuestTurnedIn", function(self, questID)
		for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
			if (WorldQuestTracker.QuestTrackList[i].questID == questID) then
				local questRemoved = tremove(WorldQuestTracker.QuestTrackList, i)
				WorldQuestTracker.RefreshTrackerWidgets()
				onObjectiveTrackerChanges()
				break
			end
		end
	end)
end

-- 12.0 path: QUEST_TURNED_IN is the reliable replacement.
local questEventFrame = CreateFrame("frame")
questEventFrame:RegisterEvent("QUEST_TURNED_IN")
questEventFrame:SetScript("OnEvent", function(self, event, questID, ...)
	if questID then
		-- Remove the quest from our tracker list if it is present.
		for i = #WorldQuestTracker.QuestTrackList, 1, -1 do
			if (WorldQuestTracker.QuestTrackList[i].questID == questID) then
				tremove(WorldQuestTracker.QuestTrackList, i)
				WorldQuestTracker.RefreshTrackerWidgets()
				break
			end
		end
	end
	C_Timer.After(0, onObjectiveTrackerChanges)
end)

hooksecurefunc(C_SuperTrack, "SetSuperTrackedQuestID", function()
	C_Timer.After(0, onObjectiveTrackerChanges)
end)

hooksecurefunc(QuestUtil, "TrackWorldQuest", function()
	C_Timer.After(0, onObjectiveTrackerChanges)
end)

hooksecurefunc(QuestUtil, "UntrackWorldQuest", function()
	C_Timer.After(0, onObjectiveTrackerChanges)
end)


local bHooked = false
local On_ObjectiveTracker_Update = function()
	local blizzObjectiveTracker = ObjectiveTrackerFrame
	if (not blizzObjectiveTracker.init) then
		return
	end

	WorldQuestTracker.UpdateQuestsInArea()

	if (not bHooked) then
		bHooked = true
	end

	WorldQuestTracker.RefreshTrackerAnchor()
end

hooksecurefunc(ObjectiveTrackerManager, "UpdateAll", function()
	On_ObjectiveTracker_Update()
end)
hooksecurefunc(ObjectiveTrackerManager, "UpdateModule", function()
	On_ObjectiveTracker_Update()
end)

ObjectiveTrackerFrame.Header.MinimizeButton:HookScript("OnClick", function()
	On_ObjectiveTracker_Update()
end)

function WorldQuestTracker:FullTrackerUpdate()
	On_ObjectiveTracker_Update()
end
