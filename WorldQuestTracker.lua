
--details! framework
local DF = _G ["DetailsFramework"]
if (not DF) then
	print ("|cFFFFAA00Plater: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

local _
local default_config = {
	profile = {
		
	},
}

local WorldQuestTracker = DF:CreateAddOn ("WorldQuestTrackerAddon", "WQTrackerDB", default_config)

function WorldQuestTracker:OnInit()
	WorldQuestTracker.InitAt = GetTime()
	WorldQuestTracker.LastMapID = GetCurrentMapAreaID()
end

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

local MAPID_BROKENISLES = 1007
local MAPID_DALARAN = 1014

function WorldQuestTracker.UpdateBorder (self, rarity)
	if (self.isWorldMapWidget) then
		self.commonBorder:Hide()
		self.rareBorder:Hide()
		self.epicBorder:Hide()
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
		elseif (rarity == LE_WORLD_QUEST_QUALITY_RARE) then
			--self.squareBorder:SetTexCoord (unpack (coords))
			--self.squareBorder:SetVertexColor (1, 1, 1)
			self.rareBorder:Show()
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

		elseif (rarity == LE_WORLD_QUEST_QUALITY_RARE) then
			if (self.squareBorder:IsShown()) then
				self.squareBorder:SetVertexColor (0, 0.56863, 0.94902)
			end
			self.squareBorder:Hide()
			self.circleBorder:Show()
			if (self.circleBorder:IsShown()) then
				self.circleBorder:SetVertexColor (0, 0.56863, 0.94902)
			end
			
			self.Underlay:Show()
			self.rareGlow:Show()
			self.rareGlow:SetVertexColor (0, 0.56863, 0.94902)
			self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag]])
			
		elseif (rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
			if (self.squareBorder:IsShown()) then
				self.squareBorder:SetVertexColor (0.78431, 0.27059, 0.98039)
			end
			self.squareBorder:Hide()
			self.circleBorder:Show()
			if (self.circleBorder:IsShown()) then
				self.circleBorder:SetVertexColor (0.78431, 0.27059, 0.98039)
			end
			
			self.Underlay:Show()
			self.rareGlow:Show()
			self.rareGlow:SetVertexColor (0.78431, 0.27059, 0.98039)
			self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag]])
		end
	end

end

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

local can_show_worldmap_widgets = function()
	if (WorldMapFrame.mapID == 1007) then
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
	else
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
	end
end

--o uso da cpu vem de setar o mapa global quando abrir o mapa em dalaran

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

local SWITCH_TO_WORLD_ON_DALARAN = true
local LOCK_MAP = true

--point of interest frame
local worldFramePOIs = CreateFrame ("frame", "WorldQuestTrackerWorldMapPOI", WorldMapFrame)
--local worldFramePOIs = CreateFrame ("frame", "WorldQuestTrackerWorldMapPOI", UIParent)
--worldFramePOIs:SetFrameStrata ("FULLSCREEN")
worldFramePOIs:SetAllPoints()
--worldFramePOIs:SetPoint ("topleft", WorldMapFrame, "topleft")
--worldFramePOIs:SetPoint ("bottomright", WorldMapFrame, "bottomright")
worldFramePOIs:SetFrameLevel (301)
local fadeInAnimation = worldFramePOIs:CreateAnimationGroup()
local step1 = fadeInAnimation:CreateAnimation ("Alpha")
step1:SetOrder (1)
step1:SetFromAlpha (0)
step1:SetToAlpha (1)
step1:SetDuration (0.3)
worldFramePOIs.fadeInAnimation = fadeInAnimation

worldFramePOIs:SetScript ("OnShow", function()
	worldFramePOIs.fadeInAnimation:Play()
end)

WorldQuestTracker.CurrentMapID = 0
WorldQuestTracker.LastWorldMapClick = 0

hooksecurefunc ("SetMapToCurrentZone", function()
	
end)

WorldMapFrame:HookScript ("OnEvent", function (self, event)
	if (event == "WORLD_MAP_UPDATE") then
		if (WorldQuestTracker.CurrentMapID ~= self.mapID) then
			if (WorldQuestTracker.LastWorldMapClick+0.017 > GetTime()) then
				WorldQuestTracker.CurrentMapID = self.mapID
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
local allow_map_change = function()
	can_show_worldmap_widgets()
	WorldQuestTracker.CanChangeMap = true
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

WorldMapFrame:HookScript ("OnUpdate", function (self, deltaTime)
	if (LOCK_MAP and GetCurrentMapContinent() == 8) then
		if (WorldQuestTracker.CanChangeMap) then
			WorldQuestTracker.CanChangeMap = nil
			WorldQuestTracker.LastMapID = GetCurrentMapAreaID()
		else
			if (WorldQuestTracker.LastMapID ~= GetCurrentMapAreaID()) then
				SetMapByID (WorldQuestTracker.LastMapID)
			end
		end
	end
end)

hooksecurefunc ("WorldMap_UpdateQuestBonusObjectives", function (self, event)
	if (WorldMapFrame:IsShown() and not WorldQuestTracker.NoAutoSwitchToWorldMap) then
		if (GetCurrentMapAreaID() == MAPID_DALARAN and SWITCH_TO_WORLD_ON_DALARAN) then
			SetMapByID (MAPID_BROKENISLES)
			WorldQuestTracker.CanChangeMap = true
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
		end
	end
end)
hooksecurefunc ("ToggleWorldMap", function (self)

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
		end
	
		--esta dentro de dalaran?
		if (GetCurrentMapAreaID() == MAPID_DALARAN and SWITCH_TO_WORLD_ON_DALARAN) then
			SetMapByID (MAPID_BROKENISLES)
			WorldQuestTracker.CanChangeMap = true
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
			
		elseif (WorldMapFrame.mapID == MAPID_BROKENISLES) then
			WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
			
		else
			WorldQuestTracker.HideWorldQuestsOnWorldMap()
		end

		if (not WorldQuestTracker.db.profile.GotTutorial) then
			local tutorialFrame = CreateFrame ("button", "WorldQuestTrackerTutorial", WorldMapFrame)
			tutorialFrame:SetSize (160, 190)
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
			
			local texture = tutorialFrame:CreateTexture (nil, "border")
			texture:SetSize (120, 120)
			texture:SetPoint ("left", tutorialFrame, "left", 100, 10)
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
			local faccao = tutorialFrame:CreateTexture (nil, "overlay")
			faccao:SetSize (28, 28)
			faccao:SetPoint ("topright", texture, "topright", 50, -120)
			faccao:SetTexture ([[Interface\QUESTFRAME\WorldQuest]])
			faccao:SetTexCoord (0.546875, 0.62109375, 0.6875, 0.984375)
			local faccaoText = tutorialFrame:CreateFontString (nil, "overlay", "GameFontNormal")
			faccaoText:SetPoint ("left", faccao, "right", 6, 0)
			DF:SetFontSize (faccaoText, 12)
			faccaoText:SetText ("indicates the quest counts towards the selected faction.")
		end
	else
		WorldQuestTracker.NoAutoSwitchToWorldMap = nil
	end
end)

--onenter onleave
local questButton_OnEnter = function (self)
	if (self.questID) then
		TaskPOI_OnEnter (self)
	end
end
local questButton_OnLeave = function	(self)
	TaskPOI_OnLeave (self)
end

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

--anchor line
local create_worldmap_line = function (lineWidth, mapId)
	local line = worldFramePOIs:CreateTexture (nil, "artwork", 2)
	--Interface\TAXIFRAME\UI-Taxi-Line
	line:SetSize (lineWidth, 2)
	line:SetHorizTile (true)
	line:SetAlpha (0.5)
	--line:SetColorTexture (0, 0, 0, 0.3)
	--line:SetTexture ([[Interface\TAXIFRAME\UI-Taxi-Line]], true)
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

local create_worldmap_square = function (mapName, index)
	local button = CreateFrame ("button", "WorldQuestTrackerWorldMapPOI " .. mapName .. "POI" .. index, worldFramePOIs)
	button:SetSize (WORLDMAP_SQUARE_SIZE, WORLDMAP_SQUARE_SIZE)
	
	button:SetScript ("OnEnter", questButton_OnEnter)
	button:SetScript ("OnLeave", questButton_OnLeave)
	tinsert (all_widgets, button)
	
	local background = button:CreateTexture (nil, "background", -3)
	background:SetAllPoints()	
	
	local texture = button:CreateTexture (nil, "background", -2)
	texture:SetAllPoints()	
	
--	local squareBorder = button:CreateTexture (nil, "artwork", 1)
--	squareBorder:SetAllPoints()
--	squareBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
--	squareBorder:Hide()

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
	commonBorder:Hide()
	rareBorder:Hide()
	epicBorder:Hide()
	
	local timeBlip = button:CreateTexture (nil, "overlay", 2)
	timeBlip:SetPoint ("bottomright", button, "bottomright", 2, -2)
	timeBlip:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
	
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
	
	button.background = background
	button.texture = texture
	button.commonBorder = commonBorder
	button.rareBorder = rareBorder
	button.epicBorder = epicBorder
	
	button.timeBlip = timeBlip
	button.amountText = amountText
	button.amountBackground = amountBackground
	button.isWorldMapWidget = true
	
	return button
end

local azsuna_mapId = 1015
local highmountain_mapId = 1024
local stormheim_mapId = 1017
local suramar_mapId = 1033
local valsharah_mapId = 1018
local eoa_mapId = 1096

local mapTable = {
	[azsuna_mapId] = {
		--worldMapLocation = {x = 10, y = -336, lineWidth = 260},
		worldMapLocation = {x = 10, y = -345, lineWidth = 233},
		worldMapLocationMax = {x = 168, y = -468, lineWidth = 330},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = azsuna_widgets,
	},
	[valsharah_mapId] = {
		--worldMapLocation = {x = 10, y = -234, lineWidth = 260},
		worldMapLocation = {x = 10, y = -218, lineWidth = 240},
		worldMapLocationMax = {x = 168, y = -284, lineWidth = 340},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = valsharah_widgets,
	},
	[highmountain_mapId] = {
		--worldMapLocation = {x = 10, y = -164, lineWidth = 330},
		worldMapLocation = {x = 10, y = -179, lineWidth = 320},
		worldMapLocationMax = {x = 168, y = -230, lineWidth = 452},
		bipAnchor = {side = "right", x = 0, y = -1},
		factionAnchor = {mySide = "left", anchorSide = "right", x = 0, y = 0},
		squarePoints = {mySide = "topleft", anchorSide = "bottomleft", y = -1, xDirection = 1},
		widgets = highmountain_widgets,
	},
	[stormheim_mapId] = {
		--worldMapLocation = {x = 382, y = -212, lineWidth = 300},
		worldMapLocation = {x = 415, y = -235, lineWidth = 277},
		worldMapLocationMax = {x = 747, y = -313, lineWidth = 393},
		bipAnchor = {side = "left", x = 0, y = -1},
		factionAnchor = {mySide = "right", anchorSide = "left", x = -0, y = 0},
		squarePoints = {mySide = "topright", anchorSide = "bottomright", y = -1, xDirection = -1},
		widgets = stormheim_widgets,
	},
	[suramar_mapId] = {
		--worldMapLocation = {x = 322, y = -273, lineWidth = 360},
		worldMapLocation = {x = 327, y = -277, lineWidth = 365},
		worldMapLocationMax = {x = 618, y = -367, lineWidth = 522},
		bipAnchor = {side = "left", x = 0, y = -1},
		factionAnchor = {mySide = "right", anchorSide = "left", x = -0, y = 0},
		squarePoints = {mySide = "topright", anchorSide = "bottomright", y = -1, xDirection = -1},
		widgets = suramar_widgets,
	},
}

--create widgets

WorldQuestTracker.InWindowMode = WorldMapFrame_InWindowedMode()

for mapId, configTable in pairs (mapTable) do
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

local GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID
local HaveQuestData = HaveQuestData
local ipairs = ipairs
local QuestMapFrame_IsQuestWorldQuest = QuestMapFrame_IsQuestWorldQuest

local do_worldmap_update = function()
	WorldQuestTracker.UpdateWorldQuestsOnWorldMap (true)
end
function WorldQuestTracker.ScheduleWorldMapUpdate (seconds)
	if (WorldQuestTracker.ScheduledWorldUpdate and not WorldQuestTracker.ScheduledWorldUpdate._cancelled) then
		WorldQuestTracker.ScheduledWorldUpdate:Cancel()
	end
	WorldQuestTracker.ScheduledWorldUpdate = C_Timer.NewTimer (seconds or 1, do_worldmap_update)
end

WorldQuestTracker.LastUpdate = 0
local factions = {}
local factionAmountForEachMap = {}

function WorldQuestTracker.UpdateWorldQuestsOnWorldMap (noCache, showFade)
	
	if (WorldQuestTracker.LastUpdate+0.017 > GetTime()) then
		return
	end
	
	if (UnitLevel ("player") < 110) then
		WorldQuestTracker.HideWorldQuestsOnWorldMap()
		return
	end
	
	WorldQuestTracker.LastUpdate = GetTime()
	wipe (factions)
	wipe (factionAmountForEachMap)
	--mostrar os widgets extras
	for _, widget in ipairs (extra_widgets) do
		widget:Show()
	end
	
	local needAnotherUpdate = false
	local availableQuests = 0

	for mapId, configTable in pairs (mapTable) do
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
									
									widget:Show()
									if (widget.texture:GetTexture() == nil) then
										WorldQuestTracker.ScheduleWorldMapUpdate()
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
									
									WorldQuestTracker.SetTimeBlipColor (widget.timeBlip, timeLeft)
									
									local okey = false
								
									if (gold > 0) then
										local texture, coords = WorldQuestTracker.GetGoldIcon()
										widget.texture:SetTexture (texture)
										widget.amountText:SetText (goldFormated)
										widget.amountBackground:Show()
										okey = true
									end
									if (rewardName) then
										widget.texture:SetTexture (rewardTexture)
										--widget.texture:SetTexCoord (0, 1, 0, 1)
										widget.amountText:SetText (numRewardItems)
										widget.amountBackground:Show()
										okey = true
									
									elseif (itemName) then
										if (isArtifact) then
											widget.texture:SetTexture (WorldQuestTracker.GetArtifactPowerIcon (artifactPower))
											widget.isArtifact = true
											widget.amountText:SetText (artifactPower)
											widget.amountBackground:Show()
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
										end
										okey = true
									end
									if (not okey) then
										needAnotherUpdate = true
									end
								end
							end
							
							widget:Show()
							WorldQuestTracker.UpdateBorder (widget, rarity)
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
	
	--print (WorldMapFrame_InWindowedMode() , not WorldQuestTracker.InWindowMode)
	
	if (WorldMapFrame_InWindowedMode() and not WorldQuestTracker.InWindowMode) then
		for mapId, configTable in pairs (mapTable) do
			configTable.line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocation.x, configTable.worldMapLocation.y)
			configTable.line:SetWidth (configTable.worldMapLocation.lineWidth)
		end
		
		WorldQuestTracker.InWindowMode = true
	elseif (not WorldMapFrame_InWindowedMode() and WorldQuestTracker.InWindowMode) then
		
		for mapId, configTable in pairs (mapTable) do
			configTable.line:SetPoint ("topleft", worldFramePOIs, "topleft", configTable.worldMapLocationMax.x, configTable.worldMapLocationMax.y)
			configTable.line:SetWidth (configTable.worldMapLocationMax.lineWidth)
		end
		
		WorldQuestTracker.InWindowMode = false
	end
	
--	configTable.factionQuestAmountBackground:Hide()
--	configTable.factionIcon:SetDesaturated (true)
	
end

WorldMapFrameSizeDownButton:HookScript ("OnClick", function()
	if (WorldQuestTracker.UpdateWorldQuestsOnWorldMap) then
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
	end
end)
WorldMapFrameSizeUpButton:HookScript ("OnClick", function()
	if (WorldQuestTracker.UpdateWorldQuestsOnWorldMap) then
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, true)
	end
end)

function WorldQuestTracker.UpdateFactionAlpha()
	for _, factionFrame in ipairs (faction_frames) do
		if (factionFrame.enabled) then
			factionFrame:SetAlpha (1)
		else
			factionFrame:SetAlpha (.65)
		end
	end
end

hooksecurefunc ("WorldMap_SetupWorldQuestButton", function (self, worldQuestType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget)

	-- self = taskPOI

	local questID = self.questID
	if (not questID) then
		return
	end
	
	self.isArtifact = nil
	
	if (not self.cusmotizeWidgets) then
		self.Underlay:SetDrawLayer ("overlay", 3)
		local w, h = self.Underlay:GetSize()
		self.Underlay:SetSize (w*1.1, h*1.1)
		
		if (self.CriteriaMatchGlow) then
			local w, h = self.CriteriaMatchGlow:GetSize()
			self.CriteriaMatchGlow:SetAlpha (1)
			self.flagCriteriaMatchGlow = self:CreateTexture (nil, "background")
			self.flagCriteriaMatchGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag_criteriamatch]])
			self.flagCriteriaMatchGlow:SetPoint ("top", self, "bottom", 0, 3)
			self.flagCriteriaMatchGlow:SetSize (64, 32)
		end
		
		self.rareGlow = self:CreateTexture (nil, "background")
		self.rareGlow:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
		self.rareGlow:SetTexCoord (155/512, 194/512, 17/512, 55/512)
		self.rareGlow:SetPoint ("center", self, "center")
		self.rareGlow:SetSize (48, 48)
		self.rareGlow:SetAlpha (.85)
		
		--fundo preto
		self.blackBackground = self:CreateTexture (nil, "background")
		self.blackBackground:SetColorTexture (0, 0, 0, 1)
		self.blackBackground:SetPoint ("topleft", self, "topleft")
		self.blackBackground:SetPoint ("bottomright", self, "bottomright")
		self.blackBackground:SetDrawLayer ("background", 3)
		self.blackBackground:Hide()

		--borda circular
		self.circleBorder = self:CreateTexture (nil, "overlay")
		self.circleBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
		self.circleBorder:SetTexCoord (80/512, 138/512, 6/512, 64/512)
		self.circleBorder:SetPoint ("topleft", self, "topleft", -1, 1)
		self.circleBorder:SetPoint ("bottomright", self, "bottomright", 1, -1)
		self.circleBorder:SetDrawLayer ("overlay", 1)
		
		--borda quadrada
		self.squareBorder = self:CreateTexture (nil, "overlay")
		self.squareBorder:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\borders]])
		self.squareBorder:SetTexCoord (8/512, 68/512, 6/512, 66/512)
		self.squareBorder:SetPoint ("topleft", self, "topleft", -1, 1)
		self.squareBorder:SetPoint ("bottomright", self, "bottomright", 1, -1)
		self.squareBorder:SetDrawLayer ("overlay", 1)
		
		--blip do tempo restante
		self.timeBlip = self:CreateTexture (nil, "overlay", 2)
		self.timeBlip:SetPoint ("bottomright", self, "bottomright", 4, -4)
		self.timeBlip:SetSize (WORLDMAP_SQUARE_TIMEBLIP_SIZE, WORLDMAP_SQUARE_TIMEBLIP_SIZE)
		self.timeBlip:SetDrawLayer ("overlay", 7)
		
		--faixa com o tempo
		self.bgFlag = self:CreateTexture (nil, "overlay")
		self.bgFlag:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\icon_flag]])
		--self.bgFlag:SetTexCoord (0/512, 75/512, 82/512, 107/512)
		--self.bgFlag:SetPoint ("center", self, "center")
		self.bgFlag:SetPoint ("top", self, "bottom", 0, 3)
		self.bgFlag:SetSize (64, 32)
		self.bgFlag:SetDrawLayer ("overlay", 4)
		
		self.bgFlagText = self:CreateTexture (nil, "overlay")
		self.bgFlagText:SetTexture ([[Interface\AddOns\WorldQuestTracker\media\background_blackgradient]])
		self.bgFlagText:SetDrawLayer ("overlay", 5)
		self.bgFlagText:SetPoint ("top", self.bgFlag, "top", 0, -3)
		self.bgFlagText:SetSize (32, 10)
		self.bgFlagText:SetAlpha (.7)
		
		--string da flag
		self.flagText = self:CreateFontString (nil, "overlay", "GameFontNormal")
		self.flagText:SetText ("13m")
		--self.flagText:SetPoint ("top", self, "bottom", 0, 0)
		self.flagText:SetPoint ("top", self.bgFlag, "top", 0, -3)
		self.flagText:SetDrawLayer ("overlay", 6)
		DF:SetFontSize (self.flagText, 8)
		--DF:SetFontColor (self.flagText, "white")
		--DF:SetFontOutline (self.flagText, true)
		
		self.cusmotizeWidgets = true
	end
	
	self.circleBorder:Hide()
	self.squareBorder:Hide()
	self.rareGlow:Hide()
	self.flagText:SetText ("")

	if (self.flagCriteriaMatchGlow) then
		if (self.CriteriaMatchGlow:IsShown()) then
			--print (self.CriteriaMatchGlow:GetTexture(), self.CriteriaMatchGlow:GetTexCoord())
			self.flagCriteriaMatchGlow:Show()
		else
			self.flagCriteriaMatchGlow:Hide()
		end
	end

	if (HaveQuestData (questID)) then
		local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info (questID)
		
		local color = WORLD_QUEST_QUALITY_COLORS [rarity]
		
		-- tempo restante
		local timeLeft = WorldQuestTracker.GetQuest_TimeLeft (questID)
		if (timeLeft and timeLeft > 0) then
			WorldQuestTracker.SetTimeBlipColor (self.timeBlip, timeLeft)

			-- gold
			local goldReward, goldFormated = WorldQuestTracker.GetQuestReward_Gold (questID)
			if (goldReward > 0) then
				--seta o icone com dimdim
				local texture, coords = WorldQuestTracker.GetGoldIcon()
				
				self.Texture:SetTexture (texture)
				self.Texture:SetTexCoord (unpack (coords))
				self.Texture:SetSize (16, 16)
				
				self.flagText:SetText (goldFormated)
				
				self.circleBorder:Show()
				WorldQuestTracker.UpdateBorder (self, rarity)
				return
			end
			
			-- poder de artefato
			local artifactXP = GetQuestLogRewardArtifactXP(questID)
			if ( artifactXP > 0 ) then
				--print ("quest de artefato", artifactXP)
				--seta icone de poder de artefato
				--return
			end
			
			-- class hall resource
			local name, texture, numRewardItems = WorldQuestTracker.GetQuestReward_Resource (questID)
			if (name) then
				if (texture) then
					self.Texture:SetTexture (texture)
					self.Texture:SetTexCoord (0, 1, 0, 1)
					self.squareBorder:Show()
					self.Texture:SetSize (16, 16)
					WorldQuestTracker.UpdateBorder (self, rarity)
					
					self.flagText:SetText (numRewardItems)
					
					self:GetHighlightTexture():SetTexture ([[Interface\Store\store-item-highlight]])
					self:GetHighlightTexture():SetTexCoord (0, 1, 0, 1)
				end
				return
			end

			-- items
			local itemName, itemTexture, itemLevel, quantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = WorldQuestTracker.GetQuestReward_Item (questID)
			if (itemName) then
				if (isArtifact) then
					local texture = WorldQuestTracker.GetArtifactPowerIcon (artifactPower)
					self.Texture:SetTexture (texture)
					self.Texture:SetTexCoord (5/64, 59/64, 5/64, 59/64)
					self.flagText:SetText (artifactPower)
					self.isArtifact = true
				else
					self.Texture:SetTexture (itemTexture)
					self.Texture:SetTexCoord (0, 1, 0, 1)
					
					if (itemLevel > 600 and itemLevel < 780) then
						itemLevel = 810
					end
					self.flagText:SetText ((isStackable and quantity and quantity >= 1 and quantity or false) or (itemLevel and itemLevel > 5 and itemLevel .. "+") or "")
				end

				self:GetHighlightTexture():SetTexture ([[Interface\Store\store-item-highlight]])
				self:GetHighlightTexture():SetTexCoord (0, 1, 0, 1)

				self.squareBorder:Show()
				self.Texture:SetSize (16, 16)
				WorldQuestTracker.UpdateBorder (self, rarity)
				return
			end
		end
		
	else
		--não tem quest data
	end
	
end)

local GameTooltipFrame = CreateFrame ("GameTooltip", "WorldQuestTrackerScanTooltip", nil, "GameTooltipTemplate")
local GameTooltipFrameTextLeft1 = _G ["WorldQuestTrackerScanTooltipTextLeft2"]
local GameTooltipFrameTextLeft2 = _G ["WorldQuestTrackerScanTooltipTextLeft3"]
local GameTooltipFrameTextLeft3 = _G ["WorldQuestTrackerScanTooltipTextLeft4"]

function WorldQuestTracker.RewardIsArtifactPower (itemLink)
	GameTooltipFrame:SetOwner (WorldFrame, "ANCHOR_NONE")
	GameTooltipFrame:SetHyperlink (itemLink)
	local text = GameTooltipFrameTextLeft1:GetText()
	if (text:match ("|cFFE6CC80")) then
		local power = GameTooltipFrameTextLeft3:GetText():match ("%d.-%s") or 0
		power = tonumber (power)
		return true, power
	end
end

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

function WorldQuestTracker.GetQuestReward_Resource (questID)
	local numQuestCurrencies = GetNumQuestLogRewardCurrencies (questID)
	for i = 1, numQuestCurrencies do
		local name, texture, numItems = GetQuestLogRewardCurrencyInfo (i, questID)
		return name, texture, numItems
	end
end

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

function WorldQuestTracker.GetQuest_Info (questID)
	local title, factionID = GetQuestInfoByQuestID (questID)
	local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = GetQuestTagInfo (questID)
	return title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex
end

local goldCoords = {0, 1, 0, 1}
function WorldQuestTracker.GetGoldIcon()
	return [[Interface\GossipFrame\auctioneerGossipIcon]], goldCoords
end

function WorldQuestTracker.GetArtifactPowerIcon (artifactPower)
	if (artifactPower >= 250) then
		return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_red]]
	elseif (artifactPower >= 120) then
		return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_yellow]]
	else
		return [[Interface\AddOns\WorldQuestTracker\media\icon_artifactpower_blue]]
	end
end

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
	--self.objectiveCompletedText:SetTextColor (Lerp (3, 0, numCompleted / numTotal), Lerp (0, 2, numCompleted / numTotal), 0)
end

hooksecurefunc (WorldMapFrame.UIElementsFrame.BountyBoard, "SetSelectedBountyIndex", function (self)
	if (WorldMapFrame.mapID == 1007) then
		WorldQuestTracker.UpdateWorldQuestsOnWorldMap (false, false)
	end
end)

--DONE - mostra os numeros de quantas questes foram feitas no dia para cada reputação
hooksecurefunc (WorldMapFrame.UIElementsFrame.BountyBoard, "RefreshBountyTabs", function (self)
--self é o BountyBoard
	local bountyData = self.bounties [self.selectedBountyIndex] -- self.bounties é a tabela com as 3 icones das facções
	
	--> abriu o mapa em uma região aonde não é mostrado as bounties.
	if (not bountyData) then
		return
	end
	local questIndex = GetQuestLogIndexByID (bountyData.questID)
	
	--o numero maximo de objectivvos para uma bounty é 7
	for bountyTab, _ in pairs (self.bountyTabPool.activeObjects) do
		local bountyData = self.bounties [bountyTab.bountyIndex]
		if (bountyData) then
			local numCompleted, numTotal = self:CalculateBountySubObjectives (bountyData)
			if (numCompleted and numTotal) then
				WorldQuestTracker.SetBountyAmountCompleted (bountyTab, numCompleted, numTotal)
			end
		else
			WorldQuestTracker.SetBountyAmountCompleted (bountyTab, false)
		end
	end
end)

-- doq dow