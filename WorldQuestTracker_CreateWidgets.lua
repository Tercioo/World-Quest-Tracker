
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


---@class wqt_worldmapsquarebutton : button
---@field QuestType number
---@field FactionID number
---@field mapID number
---@field Rarity number
---@field Amount number
---@field lastUpdate number
---@field TimeLeft number
---@field WorldQuestType number
---@field WidgetID number
---@field WidgetAnchorID number
---@field numObjectives number
---@field Order number
---@field X number
---@field OnEnterAnimationScaleDiff number
---@field WidgetOrder number
---@field Y number
---@field lastQuestID number
---@field questID number
---@field IconText string
---@field IconTexture string
---@field IsWorldQuestButton boolean
---@field isWorldMapWidget boolean
---@field worldQuest boolean
---@field IsCriteria boolean
---@field backdropInfo table
---@field questData table
---@field onStartTrackAnimation animationgroup
---@field OnShowAnimation animationgroup
---@field amountBackground texture
---@field commonBorder texture
---@field questTypeBlip texture
---@field HighlightSaturated texture
---@field criteriaHighlight texture
---@field overlayBorder2 texture
---@field criteriaIndicator texture
---@field BottomEdge texture
---@field DefaultPin button
---@field TopLeftCorner texture
---@field fadeInAnimation animationgroup
---@field LoopFlash animationgroup
---@field timeBlipYellow texture
---@field factionBorder texture
---@field miscBorder texture
---@field Center texture
---@field BottomLeftCorner texture
---@field trackingBorder texture
---@field newIndicator texture
---@field background texture
---@field epicBorder texture
---@field borderAnimation frame
---@field invasionBorder texture
---@field OnLeaveAnimation animationgroup
---@field Anchor frame
---@field CurrentAnchor frame
---@field timeLeftBackground texture
---@field OnEnterAnimation animationgroup
---@field TopRightCorner texture
---@field overlayBorder texture
---@field onEndTrackAnimation animationgroup
---@field QuickFlash animationgroup
---@field BottomRightCorner texture
---@field newFlash animationgroup
---@field amountText fontstring
---@field criteriaIndicatorGlow texture
---@field rareBorder texture
---@field RightEdge texture
---@field timeBlipOrange texture
---@field timeBlipRed texture
---@field LeftEdge texture
---@field TopEdge texture
---@field texture texture
---@field CriteriaAnimation animationgroup
---@field FlashTexture texture
---@field trackingGlowBorder texture
---@field timeLeftText fontstring
---@field timeBlipGreen texture
---@field trackingGlowInside texture
---@field AddedToTrackerAnimation animationgroup
---@field ClearBackdrop fun()
---@field OnLegendPinMouseLeave fun()
---@field SetupPieceVisuals fun()
---@field GetBackdropBorderColor fun()
---@field GetBackdropColor fun()
---@field HasBackdropInfo fun()
---@field OnBackdropSizeChanged fun()
---@field SetBorderBlendMode fun()
---@field GetBackdrop fun()
---@field GetEdgeSize fun()
---@field ApplyBackdrop fun()
---@field OnLegendPinMouseEnter fun()
---@field SetupTextureCoordinates fun()
---@field OnBackdropLoaded fun()

--cria uma square widget no world map ~world ~createworld ~createworldwidget
--index and name are only for the glogal name
function WorldQuestTracker.CreateWorldMapSquareButton(mapName, index, parent)
	local button = CreateFrame("button", "WorldQuestTrackerWorldMapPOI" .. mapName .. "POI" .. index, parent or worldFramePOIs, "BackdropTemplate")
	---@cast button wqt_worldmapsquarebutton
	button:SetSize(WorldQuestTracker.Constants.WorldMapSquareSize, WorldQuestTracker.Constants.WorldMapSquareSize)
	button.IsWorldQuestButton = true
	button:SetFrameLevel(302)
	button:SetBackdrop(worldSquareBackdrop)
	button:SetBackdropColor(.1, .1, .1, .6)
	button.OnLegendPinMouseEnter = emptyFunction
	button.OnLegendPinMouseLeave = emptyFunction

	button:SetScript("OnEnter", WorldQuestTracker.TaskPOI_OnEnterFunc)
	button:SetScript("OnLeave", WorldQuestTracker.TaskPOI_OnLeaveFunc)
	button:SetScript("OnClick", WorldQuestTracker.OnQuestButtonClick)

	button:RegisterForClicks("LeftButtonDown", "MiddleButtonDown", "RightButtonDown")

	local fadeInAnimation = button:CreateAnimationGroup()
	local step1 = fadeInAnimation:CreateAnimation("Alpha")
	step1:SetOrder(1)
	step1:SetFromAlpha(0)
	step1:SetToAlpha(1)
	step1:SetDuration(0.1)
	button.fadeInAnimation = fadeInAnimation

	local background = button:CreateTexture(nil, "background", nil, -3)
	background:SetAllPoints()

	local texture = button:CreateTexture(nil, "background", nil, -2)
	--texture:SetAllPoints()
	texture:SetPoint("topleft", 1, -1)
	texture:SetPoint("bottomright", -1, 1)

	--borders
	local commonBorder = button:CreateTexture(nil, "artwork", nil, 1)
	commonBorder:SetPoint("topleft", button, "topleft")
	commonBorder:SetTexture([[Interface\AddOns\WorldQuestTracker\media\border_whiteT]])
	commonBorder:SetSize(WorldQuestTracker.Constants.WorldMapSquareSize, WorldQuestTracker.Constants.WorldMapSquareSize)

	local miscBorder = button:CreateTexture(nil, "artwork", nil, 1)
	miscBorder:SetPoint("topleft", button, "topleft")
	miscBorder:SetTexture([[Interface\AddOns\WorldQuestTracker\media\border_whiteT]])
	miscBorder:SetSize(WorldQuestTracker.Constants.WorldMapSquareSize, WorldQuestTracker.Constants.WorldMapSquareSize)

	local rareBorder = button:CreateTexture(nil, "artwork", nil, 1)
	rareBorder:SetPoint("topleft", button, "topleft", -1, 1)
	rareBorder:SetTexture([[Interface\AddOns\WorldQuestTracker\media\border_blueT]])
	rareBorder:SetSize(WorldQuestTracker.Constants.WorldMapSquareSize+2, WorldQuestTracker.Constants.WorldMapSquareSize+2)

	local epicBorder = button:CreateTexture(nil, "artwork", nil, 1)
	epicBorder:SetPoint("topleft", button, "topleft", -1, 1)
	epicBorder:SetTexture([[Interface\AddOns\WorldQuestTracker\media\border_pinkT]])
	epicBorder:SetSize(WorldQuestTracker.Constants.WorldMapSquareSize + 2, WorldQuestTracker.Constants.WorldMapSquareSize + 2)

	local invasionBorder = button:CreateTexture(nil, "artwork", nil, 1)
	invasionBorder:SetPoint("topleft", button, "topleft", -1, 1)
	invasionBorder:SetTexture([[Interface\AddOns\WorldQuestTracker\media\border_redT]])
	invasionBorder:SetSize(WorldQuestTracker.Constants.WorldMapSquareSize + 2, WorldQuestTracker.Constants.WorldMapSquareSize + 2)
	invasionBorder:Hide()

	local trackingBorder = button:CreateTexture(nil, "artwork", nil, 1)
	trackingBorder:SetPoint("topleft", button, "topleft", -5, 5)
	trackingBorder:SetTexture([[Interface\Artifacts\Artifacts]])
	trackingBorder:SetTexCoord(491/1024, 569/1024, 76/1024, 153/1024)
	trackingBorder:SetBlendMode("ADD")
	trackingBorder:SetVertexColor(unpack(WorldQuestTracker.ColorPalette.orange))
	trackingBorder:SetSize(WorldQuestTracker.Constants.WorldMapSquareSize+10, WorldQuestTracker.Constants.WorldMapSquareSize+10)

	local factionBorder = button:CreateTexture(nil, "artwork", nil, 1)
	factionBorder:SetPoint("center")
	factionBorder:SetTexture([[Interface\Artifacts\Artifacts]])
	factionBorder:SetTexCoord(137/1024, 195/1024, 920/1024, 978/1024)
	factionBorder:Hide()
	factionBorder:SetAlpha(1)
	factionBorder:SetSize(WorldQuestTracker.Constants.WorldMapSquareSize+2, WorldQuestTracker.Constants.WorldMapSquareSize+2)

	local overlayBorder = button:CreateTexture(nil, "overlay", nil, 5)
	local overlayBorder2 = button:CreateTexture(nil, "overlay", nil, 6)
	overlayBorder:SetDrawLayer("overlay", 5)
	overlayBorder2:SetDrawLayer("overlay", 6)
	overlayBorder:SetTexture([[Interface\Soulbinds\SoulbindsConduitIconBorder]])
	overlayBorder2:SetTexture([[Interface\Soulbinds\SoulbindsConduitIconBorder]])
	overlayBorder:SetTexCoord(0/256, 66/256, 0, 0.5)
	overlayBorder2:SetTexCoord(67/256, 132/256, 0, 0.5)

	overlayBorder:Hide()
	overlayBorder2:Hide()
	overlayBorder:SetPoint("topleft", 0, 0)
	overlayBorder:SetPoint("bottomright", 0, 0)
	overlayBorder2:SetPoint("topleft", 0, 0)
	overlayBorder2:SetPoint("bottomright", 0, 0)

	local borderAnimation = CreateFrame("frame", "$parentBorderShineAnimation", button, "AnimatedShineTemplate")
	borderAnimation:SetFrameLevel(303)
	borderAnimation:SetPoint("topleft", 2, -2)
	borderAnimation:SetPoint("bottomright", -2, 2)
	borderAnimation:SetAlpha(.05)
	borderAnimation:Hide()
	button.borderAnimation = borderAnimation

	--create the on enter/leave scale mini animation

		--animations
		local animaSettings = {
			scaleMax = 1.1,
			speed = WQT_ANIMATION_SPEED,
		}
		do
			button.OnEnterAnimation = detailsFramework:CreateAnimationHub(button, function() end, function() end)
			local anim = WorldQuestTracker:CreateAnimation(button.OnEnterAnimation, "Scale", 1, animaSettings.speed, 1, 1, animaSettings.scaleMax, animaSettings.scaleMax, "center", 0, 0)
			anim:SetEndDelay(60) --this fixes the animation going back to 1 after it finishes
			--anim:SetSmoothing("IN_OUT")
			anim:SetSmoothing("IN") --looks like OUT smooth has some problems in the PTR
			button.OnEnterAnimation.ScaleAnimation = anim

			button.OnLeaveAnimation = detailsFramework:CreateAnimationHub(button, function() end, function() end)
			local anim = WorldQuestTracker:CreateAnimation(button.OnLeaveAnimation, "Scale", 2, animaSettings.speed, animaSettings.scaleMax, animaSettings.scaleMax, 1, 1, "center", 0, 0)
			--anim:SetSmoothing("IN_OUT")
			anim:SetSmoothing("IN")
			button.OnLeaveAnimation.ScaleAnimation = anim

			button.OnEnterAnimationScaleDiff = WQT_ANIMATION_SPEED
		end

	WorldQuestTracker.CreateStartTrackingAnimation(button, nil, 5)

	local trackingGlowInside = button:CreateTexture(nil, "overlay", nil, 1)
	trackingGlowInside:SetPoint("center", button, "center")
	trackingGlowInside:SetColorTexture(1, 1, 1, .03)
	trackingGlowInside:SetSize(WorldQuestTracker.Constants.WorldMapSquareSize * 0.8, WorldQuestTracker.Constants.WorldMapSquareSize * 0.8)
	trackingGlowInside:Hide()

	local trackingGlowBorder = button:CreateTexture(nil, "overlay", nil, 1)
	trackingGlowBorder:SetPoint("center", button, "center")
	trackingGlowBorder:SetTexture([[Interface\AddOns\WorldQuestTracker\media\glow_yellow_squareT]])
	trackingGlowBorder:SetBlendMode("ADD")
	trackingGlowBorder:SetSize(55, 55)
	trackingGlowBorder:SetAlpha(1)
	trackingGlowBorder:SetDrawLayer("BACKGROUND", -5)
	trackingGlowBorder:Hide()

	local flashTexture = button:CreateTexture(nil, "overlay")
	flashTexture:SetDrawLayer("overlay", 7)
	flashTexture:Hide()
	flashTexture:SetColorTexture(1, 1, 1)
	flashTexture:SetPoint("topleft", 1, -1)
	flashTexture:SetPoint("bottomright", -1, 1)
	button.FlashTexture = flashTexture

	button.QuickFlash = detailsFramework:CreateAnimationHub(flashTexture, function() flashTexture:Show() end, function() flashTexture:Hide() end)
	local anim = WorldQuestTracker:CreateAnimation(button.QuickFlash, "Alpha", 1, .15, 0, 1)
	anim:SetSmoothing("IN_OUT")
	local anim = WorldQuestTracker:CreateAnimation(button.QuickFlash, "Alpha", 2, .15, 1, 0)
	anim:SetSmoothing("IN_OUT")

	button.LoopFlash = detailsFramework:CreateAnimationHub(flashTexture, function() flashTexture:Show() end, function() flashTexture:Hide() end)
	local anim = WorldQuestTracker:CreateAnimation(button.LoopFlash, "Alpha", 1, .35, 0, .5)
	anim:SetSmoothing("IN_OUT")
	local anim = WorldQuestTracker:CreateAnimation(button.LoopFlash, "Alpha", 2, .35, .5, 0)
	anim:SetSmoothing("IN_OUT")
	button.LoopFlash:SetLooping("REPEAT")

	local smallFlashOnTrack = button:CreateTexture(nil, "overlay", nil, 7)
	smallFlashOnTrack:Hide()
	smallFlashOnTrack:SetColorTexture(1, 1, 1)
	smallFlashOnTrack:SetAllPoints()

	local onFlashTrackAnimation = detailsFramework:CreateAnimationHub(smallFlashOnTrack, nil, function(self) self:GetParent():Hide() end)
	onFlashTrackAnimation.FlashTexture = smallFlashOnTrack
	WorldQuestTracker:CreateAnimation(onFlashTrackAnimation, "Alpha", 1, .15, 0, 1)
	WorldQuestTracker:CreateAnimation(onFlashTrackAnimation, "Alpha", 2, .15, 1, 0)

	local onStartTrackAnimation = detailsFramework:CreateAnimationHub(trackingGlowBorder, WorldQuestTracker.OnStartClickAnimation)
	onStartTrackAnimation.OnFlashTrackAnimation = onFlashTrackAnimation
	WorldQuestTracker:CreateAnimation(onStartTrackAnimation, "Scale", 1, .1, .9, .9, 1.1, 1.1)
	WorldQuestTracker:CreateAnimation(onStartTrackAnimation, "Scale", 2, .1, 1.2, 1.2, 1, 1)

	local onEndTrackAnimation = detailsFramework:CreateAnimationHub(trackingGlowBorder, WorldQuestTracker.OnStartClickAnimation, WorldQuestTracker.OnEndClickAnimation)
	WorldQuestTracker:CreateAnimation(onEndTrackAnimation, "Scale", 1, .5, 1, 1, .6, .6)
	button.onStartTrackAnimation = onStartTrackAnimation
	button.onEndTrackAnimation = onEndTrackAnimation

	local onShowAnimation = detailsFramework:CreateAnimationHub(button) --, WorldQuestTracker.OnStartClickAnimation, WorldQuestTracker.OnEndClickAnimation
	WorldQuestTracker:CreateAnimation(onShowAnimation, "Scale", 1, .1, 1, 1, 1.2, 1.2)
	WorldQuestTracker:CreateAnimation(onShowAnimation, "Scale", 2, .1, 1.1, 1.1, 1, 1)
	WorldQuestTracker:CreateAnimation(onShowAnimation, "Alpha", 1, .1, 0, .5)
	WorldQuestTracker:CreateAnimation(onShowAnimation, "Alpha", 2, .1, .5, 1)
	button.OnShowAnimation = onShowAnimation

	local criteriaFrame = CreateFrame("frame", nil, button, "BackdropTemplate")
	local criteriaIndicator = criteriaFrame:CreateTexture(nil, "OVERLAY", nil, 2)
	criteriaIndicator:SetPoint("topleft", button, "topleft", 1, -1)
	criteriaIndicator:SetSize(28*.32, 34*.32) --original sizes: 23 37
	criteriaIndicator:SetAlpha(.933)
	criteriaIndicator:SetTexture(WorldQuestTracker.MapData.GeneralIcons.CRITERIA.icon)
	criteriaIndicator:SetTexCoord(unpack(WorldQuestTracker.MapData.GeneralIcons.CRITERIA.coords))
	criteriaIndicator:Hide()

	criteriaFrame.Texture = criteriaIndicator
	local criteriaIndicatorGlow = criteriaFrame:CreateTexture(nil, "OVERLAY", nil, 1)
	criteriaIndicatorGlow:SetPoint("center", criteriaIndicator, "center")
	criteriaIndicatorGlow:SetSize(16, 16)
	criteriaIndicatorGlow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\criteriaIndicatorGlowT]])
	criteriaIndicatorGlow:SetTexCoord(0, 1, 0, 1)
	criteriaIndicatorGlow:SetVertexColor(1, .8, 0, 0)
	criteriaIndicatorGlow:Hide()
	criteriaFrame.Glow = criteriaIndicatorGlow

	local criteriaAnimation = detailsFramework:CreateAnimationHub(criteriaFrame)
	detailsFramework:CreateAnimation(criteriaAnimation, "Scale", 1, .15, 1, 1, 1.1, 1.1)
	detailsFramework:CreateAnimation(criteriaAnimation, "Scale", 2, .15, 1.2, 1.2, 1, 1)
	button.CriteriaAnimation = criteriaAnimation

	local criteriaHighlight = button:CreateTexture(nil, "highlight")
	criteriaHighlight:SetPoint("center", criteriaIndicator, "center")
	criteriaHighlight:SetSize(28*.32, 36*.32)
	criteriaHighlight:SetAlpha(.8)
	criteriaHighlight:SetTexture(WorldQuestTracker.MapData.GeneralIcons.CRITERIA.icon)
	criteriaHighlight:SetTexCoord(unpack(WorldQuestTracker.MapData.GeneralIcons.CRITERIA.coords))

	commonBorder:Hide()
	miscBorder:Hide()
	rareBorder:Hide()
	epicBorder:Hide()
	trackingBorder:Hide()

	--blip do tempo restante
	button.timeBlipRed = button:CreateTexture(nil, "OVERLAY")
	button.timeBlipRed:SetPoint("bottomright", button, "bottomright", 4, -4)
	button.timeBlipRed:SetSize(WorldQuestTracker.Constants.TimeBlipSize, WorldQuestTracker.Constants.TimeBlipSize)
	button.timeBlipRed:SetTexture([[Interface\COMMON\Indicator-Red]])
	button.timeBlipRed:SetVertexColor(1, 1, 1)
	button.timeBlipRed:SetAlpha(1)

	button.timeBlipOrange = button:CreateTexture(nil, "OVERLAY")
	button.timeBlipOrange:SetPoint("bottomright", button, "bottomright", 4, -4)
	button.timeBlipOrange:SetSize(WorldQuestTracker.Constants.TimeBlipSize, WorldQuestTracker.Constants.TimeBlipSize)
	button.timeBlipOrange:SetTexture([[Interface\COMMON\Indicator-Yellow]])
	button.timeBlipOrange:SetVertexColor(1, .7, 0)
	button.timeBlipOrange:SetAlpha(.95)

	button.timeBlipYellow = button:CreateTexture(nil, "OVERLAY")
	button.timeBlipYellow:SetPoint("bottomright", button, "bottomright", 4, -4)
	button.timeBlipYellow:SetSize(WorldQuestTracker.Constants.TimeBlipSize, WorldQuestTracker.Constants.TimeBlipSize)
	button.timeBlipYellow:SetTexture([[Interface\COMMON\Indicator-Yellow]])
	button.timeBlipYellow:SetVertexColor(1, 1, 1)
	button.timeBlipYellow:SetAlpha(.9)

	button.timeBlipGreen = button:CreateTexture(nil, "OVERLAY")
	button.timeBlipGreen:SetPoint("bottomright", button, "bottomright", 4, -4)
	button.timeBlipGreen:SetSize(WorldQuestTracker.Constants.TimeBlipSize, WorldQuestTracker.Constants.TimeBlipSize)
	button.timeBlipGreen:SetTexture([[Interface\COMMON\Indicator-Green]])
	button.timeBlipGreen:SetVertexColor(1, 1, 1)
	button.timeBlipGreen:SetAlpha(.6)

	button.questTypeBlip = button:CreateTexture(nil, "OVERLAY")
	button.questTypeBlip:SetPoint("topright", button, "topright", 2, 4)
	button.questTypeBlip:SetSize(12, 12)
	button.questTypeBlip:SetDrawLayer("overlay", 7)

	local amountText = button:CreateFontString(nil, "overlay", "GameFontNormal", 1)
	amountText:SetPoint("bottom", button, "bottom", 1, -10)
	detailsFramework:SetFontSize(amountText, 9)

	local timeLeftText = button:CreateFontString(nil, "overlay", "GameFontNormal", 1)
	timeLeftText:SetPoint("bottom", button, "bottom", 0, 1)
	timeLeftText:SetJustifyH("center")
	detailsFramework:SetFontOutline(timeLeftText, true)
	detailsFramework:SetFontSize(timeLeftText, 9)
	detailsFramework:SetFontColor(timeLeftText, {1, 1, 0})
	--
	local timeLeftBackground = button:CreateTexture(nil, "background", nil, 0)
	timeLeftBackground:SetPoint("center", timeLeftText, "center")
	timeLeftBackground:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
	timeLeftBackground:SetSize(32, 10)
	timeLeftBackground:SetAlpha(.60)
	timeLeftBackground:SetAlpha(0)

	local amountBackground = button:CreateTexture(nil, "overlay", nil, 0)
	amountBackground:SetPoint("center", amountText, "center")
	amountBackground:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
	amountBackground:SetSize(32, 12)
	amountBackground:SetAlpha(.9)

	local highlight = button:CreateTexture(nil, "highlight")
	highlight:SetPoint("topleft", 2, -2)
	highlight:SetPoint("bottomright", -2, 2)
	highlight:SetAlpha(.2)
	highlight:SetTexture([[Interface\AddOns\WorldQuestTracker\media\square_highlight]])

	local highlight_saturate = button:CreateTexture(nil, "highlight")
	highlight_saturate:SetPoint("topleft")
	highlight_saturate:SetPoint("bottomright")
	highlight_saturate:SetAlpha(.45)
	highlight_saturate:SetBlendMode("ADD")
	button.HighlightSaturated = highlight_saturate

	local new = button:CreateTexture(nil, "overlay")
	new:SetPoint("bottom", button, "bottom", 0, -3)
	new:SetSize(64*.45, 32*.45)
	new:SetAlpha(.4)
	new:SetTexture([[Interface\AddOns\WorldQuestTracker\media\new]])
	new:SetTexCoord(0, 1, 0, .5)
	button.newIndicator = new

	local newFlashTexture = button:CreateTexture(nil, "overlay")
	newFlashTexture:SetPoint("bottom", new, "bottom")
	newFlashTexture:SetSize(64*.45, 32*.45)
	newFlashTexture:SetTexture([[Interface\AddOns\WorldQuestTracker\media\new]])
	newFlashTexture:SetTexCoord(0, 1, 0, .5)
	newFlashTexture:Hide()

	local newFlash = newFlashTexture:CreateAnimationGroup()
	newFlash.In = newFlash:CreateAnimation("Alpha")
	newFlash.In:SetOrder(1)
	newFlash.In:SetFromAlpha(0)
	newFlash.In:SetToAlpha(1)
	newFlash.In:SetDuration(.3)
	newFlash.On = newFlash:CreateAnimation("Alpha")
	newFlash.On:SetOrder(2)
	newFlash.On:SetFromAlpha(1)
	newFlash.On:SetToAlpha(1)
	newFlash.On:SetDuration(2)
	newFlash.Out = newFlash:CreateAnimation("Alpha")
	newFlash.Out:SetOrder(3)
	newFlash.Out:SetFromAlpha(1)
	newFlash.Out:SetToAlpha(0)
	newFlash.Out:SetDuration(2)
	newFlash:SetScript("OnPlay", function()
		newFlashTexture:Show()
	end)
	newFlash:SetScript("OnFinished", function()
		newFlashTexture:Hide()
		button.newIndicator:Hide()
	end)
	button.newFlash = newFlash

	--shadow:SetDrawLayer("BACKGROUND", -6)
	trackingGlowBorder:SetDrawLayer("BACKGROUND", -5)
	background:SetDrawLayer("background", -3)
	texture:SetDrawLayer("background", 2)

	commonBorder:SetDrawLayer("border", 1)
	miscBorder:SetDrawLayer("border", 1)
	rareBorder:SetDrawLayer("border", 1)
	epicBorder:SetDrawLayer("border", 1)
	trackingBorder:SetDrawLayer("border", 2)
	amountBackground:SetDrawLayer("overlay", 0)
	amountText:SetDrawLayer("overlay", 1)
	criteriaIndicatorGlow:SetDrawLayer("OVERLAY", 1)
	criteriaIndicator:SetDrawLayer("OVERLAY", 2)
	newFlashTexture:SetDrawLayer("OVERLAY", 7)
	new:SetDrawLayer("OVERLAY", 6)
	trackingGlowInside:SetDrawLayer("OVERLAY", 7)
	factionBorder:SetDrawLayer("OVERLAY", 6)

	button.timeBlipRed:SetDrawLayer("overlay", 2)
	button.timeBlipOrange:SetDrawLayer("overlay", 2)
	button.timeBlipYellow:SetDrawLayer("overlay", 2)
	button.timeBlipGreen:SetDrawLayer("overlay", 2)

	highlight:SetDrawLayer("highlight", 1)
	criteriaHighlight:SetDrawLayer("highlight", 2)

	button.background = background
	button.texture = texture
	button.commonBorder = commonBorder
	button.miscBorder = miscBorder
	button.rareBorder = rareBorder
	button.epicBorder = epicBorder
	button.invasionBorder = invasionBorder
	button.trackingBorder = trackingBorder
	button.trackingGlowBorder = trackingGlowBorder
	button.factionBorder = factionBorder
	button.overlayBorder = overlayBorder
	button.overlayBorder2 = overlayBorder2

	button.trackingGlowInside = trackingGlowInside

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



local emptyFunction = function()end

---@class wqt_zonewidget : button
---@field worldQuestType number
---@field Currency_Gold number
---@field Currency_Resources number
---@field mapID number
---@field OriginalFrameLevel number
---@field Amount number
---@field numObjectives number
---@field IconText number
---@field rarity number
---@field QuestType number
---@field Currency_ArtifactPower number
---@field TimeLeft number
---@field FactionID number
---@field questID number
---@field Order number
---@field PosY number
---@field PosX number
---@field IconTexture string
---@field questName string
---@field worldQuest boolean
---@field isCriteria boolean
---@field inProgress boolean
---@field selected boolean
---@field isElite boolean
---@field isSpellTarget boolean
---@field IsZoneQuestButton boolean
---@field isSelected boolean
---@field questData table
---@field blackGradient texture
---@field rareGlow texture
---@field AnchorFrame button
---@field CriteriaAnimation animationgroup
---@field rareSerpent texture
---@field IsTrackingGlow texture
---@field RareOverlay button
---@field colorBlindTrackerIcon texture
---@field overlayBorder2 texture
---@field timeBlipRed texture
---@field IsTrackingRareGlow texture
---@field questTypeBlip texture
---@field timeBlipGreen texture
---@field timeBlipYellow texture
---@field TextureCustom texture
---@field AddedToTrackerAnimation animationgroup
---@field criteriaIndicator texture
---@field miscBorder texture
---@field blackBackground texture
---@field SpellTargetGlow texture
---@field flagTextShadow fontstring
---@field flagText fontstring
---@field highlight texture
---@field SelectedGlow texture
---@field onEndTrackAnimation animationgroup
---@field CriteriaMatchGlow texture
---@field timeBlipOrange texture
---@field onStartTrackAnimation animationgroup
---@field Shadow texture
---@field squareBorder texture
---@field BountyRing texture
---@field bgFlag texture
---@field criteriaIndicatorGlow texture
---@field OnEnterAnimation animationgroup
---@field flagCriteriaMatchGlow texture
---@field overlayBorder texture
---@field circleBorder texture
---@field FactionPulseAnimation animationgroup
---@field OnLeaveAnimation animationgroup
---@field SupportFrame frame
---@field Texture texture
---@field OnShowAlphaAnimation animationgroup
---@field OnLegendPinMouseLeave fun()
---@field ApplyBackdrop fun()
---@field GetBackdropColor fun()
---@field OnBackdropLoaded fun()
---@field SetupTextureCoordinates fun()
---@field SetupPieceVisuals fun()
---@field SetBackdrop fun()
---@field GetEdgeSize fun()
---@field UpdateTooltip fun()
---@field GetBackdrop fun()
---@field OnBackdropSizeChanged fun()
---@field SetBackdropColor fun()
---@field SetBorderBlendMode fun()
---@field GetBackdropBorderColor fun()
---@field ClearWidget fun()
---@field OnLegendPinMouseEnter fun()
---@field ClearBackdrop fun()
---@field SetBackdropBorderColor fun()
---@field HasBackdropInfo fun()


local on_show_alpha_animation = function(self)
	self:GetParent():Show()
end

function WorldQuestTracker.CreateZoneWidget(index, name, parent, pinTemplate) --~zone --~zoneicon ~create
	local anchorFrame --has its mouse disabled on apocalypse

	if (pinTemplate) then
		anchorFrame = CreateFrame("button", name .. index .. "Anchor", parent, pinTemplate)
		anchorFrame.dataProvider = WorldQuestTracker.GetBlizzardProvider()
		anchorFrame.worldQuest = true
		anchorFrame.owningMap = WorldQuestTracker.GetBlizzardProvider():GetMap()
	else
		anchorFrame = CreateFrame("button", name .. index .. "Anchor", parent, WorldQuestTracker.GetBlizzardProvider():GetPinTemplate())
		anchorFrame.dataProvider = WorldQuestTracker.GetBlizzardProvider()
		anchorFrame.worldQuest = true
		anchorFrame.owningMap = WorldQuestTracker.GetBlizzardProvider():GetMap()
	end

	if (anchorFrame.Glow) then
		anchorFrame.Glow:Hide()
	end

	local button = CreateFrame("button", name .. index, parent, "BackdropTemplate")

	button.OnLegendPinMouseEnter = emptyFunction
	button.OnLegendPinMouseLeave = emptyFunction

	button:SetPoint("center", anchorFrame, "center", 0, 0)
	button.AnchorFrame = anchorFrame
	button:SetSize(20, 20)
	button:SetScript("OnEnter", function()
		if (button.questID and type(button.questID) == "number" and button.questID >= 2) then
			WorldQuestTracker.ShowQuestTooltip(button)
		end
	end)
	button:SetScript("OnLeave", function() WorldQuestTracker.HideQuestTooltip(button) --[[TaskPOI_OnLeave(button)]] end)
	button:SetScript("OnClick", WorldQuestTracker.OnQuestButtonClick)

	button:RegisterForClicks("LeftButtonDown", "MiddleButtonDown", "RightButtonDown")

	--show animation
	button.OnShowAlphaAnimation = detailsFramework:CreateAnimationHub(button, on_show_alpha_animation)
	detailsFramework:CreateAnimation(button.OnShowAlphaAnimation, "ALPHA", 1, 0.075, 0, 1)

	local supportFrame = CreateFrame("frame", nil, button, "BackdropTemplate")
	supportFrame:SetPoint("center")
	supportFrame:SetSize(20, 20)
	button.SupportFrame = supportFrame

	--> looks like something is triggering the tooltip to update on tick
	button.UpdateTooltip = function()
		if (button.questID) then
			WorldQuestTracker.ShowQuestTooltip(button)
		end
	end
	button.worldQuest = true
	button.ClearWidget = WorldQuestTracker.ClearZoneWidget

	button.RareOverlay = CreateFrame("button", button:GetName() .. "RareOverlay", button, "BackdropTemplate")  --deprecated
	button.RareOverlay:EnableMouse(false) --disable the button
	--button.RareOverlay:SetAllPoints()
	--button.RareOverlay:RegisterForClicks("LeftButtonDown", "RightButtonDown")
	button.RareOverlay:Hide()

	button.Texture = supportFrame:CreateTexture(button:GetName() .. "Texture", "BACKGROUND")
	button.Texture:SetPoint("center", button, "center")
	button.Texture:SetMask([[Interface\CharacterFrame\TempPortraitAlphaMask]])

	button.TextureCustom = supportFrame:CreateTexture(button:GetName() .. "TextureCustom", "BACKGROUND")
	button.TextureCustom:SetPoint("center", button, "center")
	button.TextureCustom:Hide()

	button.highlight = supportFrame:CreateTexture(nil, "highlight")
	button.highlight:SetTexture([[Interface\AddOns\WorldQuestTracker\media\highlight_circleT]])
	button.highlight:SetPoint("center")
	button.highlight:SetSize(16, 16)
	button.highlight:SetAlpha(0.35)
	button.highlight:Hide()

	button.IsTrackingGlow = supportFrame:CreateTexture(button:GetName() .. "IsTrackingGlow", "BACKGROUND", nil, -6)
	button.IsTrackingGlow:SetPoint("center", button, "center")
	button.IsTrackingGlow:SetTexture([[Interface\Calendar\EventNotificationGlow]])
	button.IsTrackingGlow:SetBlendMode("ADD")
	button.IsTrackingGlow:SetVertexColor(unpack(WorldQuestTracker.ColorPalette.orange))
	button.IsTrackingGlow:SetSize(31, 31)
	button.IsTrackingGlow:Hide()

	button.IsTrackingRareGlow = supportFrame:CreateTexture(button:GetName() .. "IsTrackingRareGlow", "BACKGROUND", nil, -6)
	button.IsTrackingRareGlow:SetSize(44*0.7, 44*0.7)
	button.IsTrackingRareGlow:SetPoint("center", button, "center")
	button.IsTrackingRareGlow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\rare_dragon_TrackingT]])
	--button.IsTrackingRareGlow:SetBlendMode("ADD")
	button.IsTrackingRareGlow:Hide()

	button.Shadow = supportFrame:CreateTexture(button:GetName() .. "Shadow", "BACKGROUND", nil, -8)
	button.Shadow:SetSize(24, 24)
	button.Shadow:SetPoint("center", button, "center")
	button.Shadow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\glow_yellow_roundT]])
	button.Shadow:SetTexture([[Interface\PETBATTLES\BattleBar-AbilityBadge-Neutral]])
	button.Shadow:SetAlpha(1)

	--create the on enter/leave scale mini animation

		--animations
		local animaSettings = {
			scaleZone = 0.10, --used when the widget is placed in a zone map
			scaleWorld = 0.10, --used when the widget is placed in the world
			speed = WQT_ANIMATION_SPEED,
		}

		do
			button.OnEnterAnimation = detailsFramework:CreateAnimationHub(button, function() end, function() end)
			local anim = WorldQuestTracker:CreateAnimation(button.OnEnterAnimation, "Scale", 1, animaSettings.speed, 1, 1, animaSettings.scaleZone, animaSettings.scaleZone, "center", 0, 0)
			anim:SetEndDelay(60) --this fixes the animation going back to 1 after it finishes
			button.OnEnterAnimation.ScaleAnimation = anim

			button.OnLeaveAnimation = detailsFramework:CreateAnimationHub(button, function() end, function() end)
			local anim = WorldQuestTracker:CreateAnimation(button.OnLeaveAnimation, "Scale", 2, animaSettings.speed, animaSettings.scaleZone, animaSettings.scaleZone, 1, 1, "center", 0, 0)
			button.OnLeaveAnimation.ScaleAnimation = anim
		end

		button:HookScript("OnEnter", function(self)
			button.OriginalFrameLevel = button:GetFrameLevel()
			button:SetFrameLevel(button.OriginalFrameLevel + 50)

			if (self.OnEnterAnimation) then
				if (not WorldQuestTracker.db.profile.hoverover_animations) then
					return
				end

				if (self.OnLeaveAnimation:IsPlaying()) then
					self.OnLeaveAnimation:Stop()
				end

				self.OriginalScale = self:GetScale()

				if (WorldQuestTracker.GetCurrentZoneType() == "zone") then
					self.ModifiedScale = self.OriginalScale + animaSettings.scaleZone
					if (self.OnEnterAnimation.ScaleAnimation.SetScaleFrom) then
						self.OnEnterAnimation.ScaleAnimation:SetScaleFrom(self.OriginalScale, self.OriginalScale)
						self.OnEnterAnimation.ScaleAnimation:SetScaleTo(self.ModifiedScale, self.ModifiedScale)
					else
						self.OnEnterAnimation.ScaleAnimation:SetFromScale(self.OriginalScale, self.OriginalScale)
						self.OnEnterAnimation.ScaleAnimation:SetToScale(self.ModifiedScale, self.ModifiedScale)
					end
					self.OnEnterAnimation:Play()

				elseif (WorldQuestTracker.GetCurrentZoneType() == "world") then
					self.ModifiedScale = 1 + animaSettings.scaleWorld
					if (self.OnEnterAnimation.ScaleAnimation.SetScaleFrom) then
						self.OnEnterAnimation.ScaleAnimation:SetScaleFrom(1, 1)
						self.OnEnterAnimation.ScaleAnimation:SetScaleTo(self.ModifiedScale, self.ModifiedScale)
					else
						self.OnEnterAnimation.ScaleAnimation:SetFromScale(1, 1)
						self.OnEnterAnimation.ScaleAnimation:SetToScale(self.ModifiedScale, self.ModifiedScale)
					end
					self.OnEnterAnimation:Play()
				end
			end
		end)

		button:HookScript("OnLeave", function(self)
			if (button.OriginalFrameLevel) then
				button:SetFrameLevel(button.OriginalFrameLevel)
			end

			if (self.OnLeaveAnimation) then
				if (not WorldQuestTracker.db.profile.hoverover_animations) then
					return
				end

				if (self.OnEnterAnimation:IsPlaying()) then
					self.OnEnterAnimation:Stop()
				end

				local currentScale = self.ModifiedScale
				local originalScale = self.OriginalScale

				if (currentScale and originalScale) then
					if (WorldQuestTracker.GetCurrentZoneType() == "zone") then
						if (self.OnLeaveAnimation.ScaleAnimation.SetScaleFrom) then
							self.OnLeaveAnimation.ScaleAnimation:SetScaleFrom(currentScale, currentScale)
							self.OnLeaveAnimation.ScaleAnimation:SetScaleTo(originalScale, originalScale)
						else
							self.OnLeaveAnimation.ScaleAnimation:SetFromScale(currentScale, currentScale)
							self.OnLeaveAnimation.ScaleAnimation:SetToScale(originalScale, originalScale)
						end

					elseif (WorldQuestTracker.GetCurrentZoneType() == "world") then
						if (self.OnLeaveAnimation.ScaleAnimation.SetScaleFrom) then
							self.OnLeaveAnimation.ScaleAnimation:SetScaleFrom(currentScale, currentScale)
							self.OnLeaveAnimation.ScaleAnimation:SetScaleTo(1, 1)
						else
							self.OnLeaveAnimation.ScaleAnimation:SetFromScale(currentScale, currentScale)
							self.OnLeaveAnimation.ScaleAnimation:SetToScale(1, 1)
						end
					end
				end

				self.OnLeaveAnimation:Play()
			end
		end)

	WorldQuestTracker.CreateStartTrackingAnimation(button, nil, 5)

	local smallFlashOnTrack = supportFrame:CreateTexture(nil, "overlay", nil, 7)
	smallFlashOnTrack:Hide()
	smallFlashOnTrack:SetTexture([[Interface\CHARACTERFRAME\TempPortraitAlphaMask]])
	smallFlashOnTrack:SetAllPoints()

	--make the highlight for faction indicator
		local factionPulseAnimationTexture = button:CreateTexture(nil, "background", nil, 6)
		factionPulseAnimationTexture:SetPoint("center", button, "center")
		factionPulseAnimationTexture:SetTexture([[Interface\CHARACTERFRAME\TempPortraitAlphaMaskSmall]])
		factionPulseAnimationTexture:SetSize(WorldQuestTracker.Constants.WorldMapSquareSize * 1.3, WorldQuestTracker.Constants.WorldMapSquareSize * 1.3)
		factionPulseAnimationTexture:Hide()

		button.FactionPulseAnimation = detailsFramework:CreateAnimationHub(factionPulseAnimationTexture, function() factionPulseAnimationTexture:Show() end, function() factionPulseAnimationTexture:Hide() end)
		local anim = WorldQuestTracker:CreateAnimation(button.FactionPulseAnimation, "Alpha", 1, .35, 0, .5)
		anim:SetSmoothing("OUT")
		local anim = WorldQuestTracker:CreateAnimation(button.FactionPulseAnimation, "Alpha", 2, .35, .5, 0)
		anim:SetSmoothing("OUT")
		button.FactionPulseAnimation:SetLooping("REPEAT")

	local onFlashTrackAnimation = detailsFramework:CreateAnimationHub(smallFlashOnTrack, nil, function(self) self:GetParent():Hide() end)
	onFlashTrackAnimation.FlashTexture = smallFlashOnTrack
	WorldQuestTracker:CreateAnimation(onFlashTrackAnimation, "Alpha", 1, .1, 0, 1)
	WorldQuestTracker:CreateAnimation(onFlashTrackAnimation, "Alpha", 2, .1, 1, 0)

	local buttonFullAnimation = detailsFramework:CreateAnimationHub(button)
	WorldQuestTracker:CreateAnimation(buttonFullAnimation, "Scale", 1, .1, 1, 1, 1.03, 1.03)
	WorldQuestTracker:CreateAnimation(buttonFullAnimation, "Scale", 2, .1, 1.03, 1.03, 1, 1)

	local onStartTrackAnimation = detailsFramework:CreateAnimationHub(button.IsTrackingGlow, WorldQuestTracker.OnStartClickAnimation)
	onStartTrackAnimation.OnFlashTrackAnimation = onFlashTrackAnimation
	onStartTrackAnimation.ButtonFullAnimation = buttonFullAnimation
	WorldQuestTracker:CreateAnimation(onStartTrackAnimation, "Scale", 1, .1, .9, .9, 1.1, 1.1)
	WorldQuestTracker:CreateAnimation(onStartTrackAnimation, "Scale", 2, .1, 1.2, 1.2, 1, 1)

	local onEndTrackAnimation = detailsFramework:CreateAnimationHub(button.IsTrackingGlow, WorldQuestTracker.OnStartClickAnimation, WorldQuestTracker.OnEndClickAnimation)
	WorldQuestTracker:CreateAnimation(onEndTrackAnimation, "Scale", 1, .5, 1, 1, .1, .1)
	WorldQuestTracker:CreateAnimation(onEndTrackAnimation, "Alpha", 1, .3, 1, 0)
	button.onStartTrackAnimation = onStartTrackAnimation
	button.onEndTrackAnimation = onEndTrackAnimation

	button.SelectedGlow = supportFrame:CreateTexture(button:GetName() .. "SelectedGlow", "OVERLAY", nil, 2)
	button.SelectedGlow:SetBlendMode("ADD")
	button.SelectedGlow:SetPoint("center", button, "center")

	button.CriteriaMatchGlow = supportFrame:CreateTexture(button:GetName() .. "CriteriaMatchGlow", "BACKGROUND", nil, -1)
	button.CriteriaMatchGlow:SetAlpha(.6)
	button.CriteriaMatchGlow:SetBlendMode("ADD")
	button.CriteriaMatchGlow:SetPoint("center", button, "center")
		local w, h = button.CriteriaMatchGlow:GetSize()
		button.CriteriaMatchGlow:SetAlpha(1)
		button.flagCriteriaMatchGlow = supportFrame:CreateTexture(nil, "background")
		button.flagCriteriaMatchGlow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\icon_flag_criteriamatchT]])
		button.flagCriteriaMatchGlow:SetPoint("top", button, "bottom", 0, 3)
		button.flagCriteriaMatchGlow:SetSize(64, 32)

	button.SpellTargetGlow = supportFrame:CreateTexture(button:GetName() .. "SpellTargetGlow", "OVERLAY", nil, 1)
	button.SpellTargetGlow:SetAtlas("worldquest-questmarker-abilityhighlight", true)
	button.SpellTargetGlow:SetAlpha(.6)
	button.SpellTargetGlow:SetBlendMode("ADD")
	button.SpellTargetGlow:SetPoint("center", button, "center")

	button.rareSerpent = supportFrame:CreateTexture(button:GetName() .. "RareSerpent", "OVERLAY")
	button.rareSerpent:SetWidth(34 * 1.1)
	button.rareSerpent:SetHeight(34 * 1.1)
	button.rareSerpent:SetPoint("CENTER", 1, -1)

	-- � a sombra da serpente no fundo, pode ser na cor azul ou roxa
	button.rareGlow = supportFrame:CreateTexture(nil, "background")
	button.rareGlow:SetPoint("CENTER", 1, -2)
	button.rareGlow:SetSize(48, 48)
	button.rareGlow:SetAlpha(.85)

	--fundo preto
	button.blackBackground = supportFrame:CreateTexture(nil, "background")
	button.blackBackground:SetPoint("center")
	button.blackBackground:Hide()

	--borda circular - nao da scala por causa do set point!
	button.circleBorder = supportFrame:CreateTexture(nil, "OVERLAY")
	button.circleBorder:SetPoint("topleft", supportFrame, "topleft", -1, 1)
	button.circleBorder:SetPoint("bottomright", supportFrame, "bottomright", 1, -1)
	button.circleBorder:SetTexture([[Interface\AddOns\WorldQuestTracker\media\border_zone_browT]])
	button.circleBorder:SetTexCoord(0, 1, 0, 1)
	--problema das quests de profiss�o com verde era a circleBorder

	--borda quadrada
	button.squareBorder = supportFrame:CreateTexture(nil, "OVERLAY", nil, 1)
	button.squareBorder:SetTexture([[Interface\AddOns\WorldQuestTracker\media\border_whiteT]])
	button.squareBorder:SetPoint("topleft", button, "topleft", -1, 1)
	button.squareBorder:SetPoint("bottomright", button, "bottomright", 1, -1)

	button.miscBorder = supportFrame:CreateTexture(nil, "OVERLAY", nil, 1)
	button.miscBorder:SetTexture([[Interface\AddOns\WorldQuestTracker\media\border_zone_browT]])
	button.miscBorder:SetPoint("topleft", button, "topleft", -1, 1)
	button.miscBorder:SetPoint("bottomright", button, "bottomright", 1, -1)

	--blip do tempo restante
	button.timeBlipRed = supportFrame:CreateTexture(nil, "OVERLAY")
	button.timeBlipRed:SetPoint("bottomright", button, "bottomright", 4, -4)
	button.timeBlipRed:SetSize(WorldQuestTracker.Constants.TimeBlipSize, WorldQuestTracker.Constants.TimeBlipSize)
	button.timeBlipRed:SetTexture([[Interface\COMMON\Indicator-Red]])
	button.timeBlipRed:SetVertexColor(1, 1, 1)
	button.timeBlipRed:SetAlpha(1)

	button.timeBlipOrange = supportFrame:CreateTexture(nil, "OVERLAY")
	button.timeBlipOrange:SetPoint("bottomright", button, "bottomright", 4, -4)
	button.timeBlipOrange:SetSize(WorldQuestTracker.Constants.TimeBlipSize, WorldQuestTracker.Constants.TimeBlipSize)
	button.timeBlipOrange:SetTexture([[Interface\COMMON\Indicator-Yellow]])
	button.timeBlipOrange:SetVertexColor(1, .7, 0)
	button.timeBlipOrange:SetAlpha(.9)

	button.timeBlipYellow = supportFrame:CreateTexture(nil, "OVERLAY")
	button.timeBlipYellow:SetPoint("bottomright", button, "bottomright", 4, -4)
	button.timeBlipYellow:SetSize(WorldQuestTracker.Constants.TimeBlipSize, WorldQuestTracker.Constants.TimeBlipSize)
	button.timeBlipYellow:SetTexture([[Interface\COMMON\Indicator-Yellow]])
	button.timeBlipYellow:SetVertexColor(1, 1, 1)
	button.timeBlipYellow:SetAlpha(.8)

	button.timeBlipGreen = supportFrame:CreateTexture(nil, "OVERLAY")
	button.timeBlipGreen:SetPoint("bottomright", button, "bottomright", 4, -4)
	button.timeBlipGreen:SetSize(WorldQuestTracker.Constants.TimeBlipSize, WorldQuestTracker.Constants.TimeBlipSize)
	button.timeBlipGreen:SetTexture([[Interface\COMMON\Indicator-Green]])
	button.timeBlipGreen:SetVertexColor(1, 1, 1)
	button.timeBlipGreen:SetAlpha(.6)

	--blip do indicador de tipo da quest(zone)
	button.questTypeBlip = supportFrame:CreateTexture(nil, "OVERLAY", nil, 2)
	button.questTypeBlip:SetPoint("topright", button, "topright", 3, 1)
	button.questTypeBlip:SetSize(10, 10)
	button.questTypeBlip:SetAlpha(.8)

	--faixa com o tempo
	button.bgFlag = supportFrame:CreateTexture(nil, "OVERLAY", nil, 5)
	button.bgFlag:SetTexture([[Interface\AddOns\WorldQuestTracker\media\icon_flagT]])
	button.bgFlag:SetPoint("top", button, "bottom", 0, 3)
	button.bgFlag:SetSize(64, 64)

	button.blackGradient = supportFrame:CreateTexture(nil, "OVERLAY")
	button.blackGradient:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])
	button.blackGradient:SetPoint("top", button.bgFlag, "top", 0, -1)
	button.blackGradient:SetSize(32, 10)
	button.blackGradient:SetAlpha(.7)

	--string da flag
	button.flagText = supportFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal", 6)
	button.flagText:SetText("13m")
	button.flagText:SetPoint("top", button.bgFlag, "top", 0, -2)
	detailsFramework:SetFontSize(button.flagText, 8)

	button.flagTextShadow = supportFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal", 5)
	button.flagTextShadow:SetText("13m")
	button.flagTextShadow:SetPoint("center", button.flagText, "center", 0, 0)
	button.flagTextShadow:SetTextColor(.2, .2, .2, 0.5)
	detailsFramework:SetFontSize(button.flagTextShadow, 8)
	detailsFramework:SetFontShadow(button.flagTextShadow, "black")
	detailsFramework:SetFontOutline(button.flagTextShadow, "OUTLINE")

	local criteriaFrame = CreateFrame("frame", nil, supportFrame, "BackdropTemplate")
	local criteriaIndicator = criteriaFrame:CreateTexture(nil, "OVERLAY", nil, 4)
	criteriaIndicator:SetPoint("bottomleft", button, "bottomleft", -2, -2)
	criteriaIndicator:SetSize(23*.3, 34*.3)  --original sizes: 23 37
	criteriaIndicator:SetAlpha(.8)
	criteriaIndicator:SetTexture(WorldQuestTracker.MapData.GeneralIcons.CRITERIA.icon)
	criteriaIndicator:SetTexCoord(unpack(WorldQuestTracker.MapData.GeneralIcons.CRITERIA.coords))
	criteriaIndicator:Hide()

	local criteriaIndicatorGlow = criteriaFrame:CreateTexture(nil, "OVERLAY", nil, 3)
	criteriaIndicatorGlow:SetPoint("center", criteriaIndicator, "center")
	criteriaIndicatorGlow:SetSize(13, 13)
	criteriaIndicatorGlow:SetTexture([[Interface\AddOns\WorldQuestTracker\media\criteriaIndicatorGlowT]])
	criteriaIndicatorGlow:SetTexCoord(0, 1, 0, 1)
	criteriaIndicatorGlow:Hide()

	local bountyRingPadding = 5
	local bountyRing = supportFrame:CreateTexture(nil, "overlay")
	bountyRing:SetPoint("topleft", button.circleBorder, "topleft", 0, 0)
	bountyRing:SetPoint("bottomright", button.circleBorder, "bottomright", 0, 0)
	--bountyRing:SetPoint("topleft", supportFrame, "topleft", -2.5, 2.5)
	--bountyRing:SetPoint("bottomright", supportFrame, "bottomright", 2.5, -2.5)
	bountyRing:SetAtlas("worldquest-emissary-ring")
	bountyRing:SetAlpha(0.92)
	bountyRing:Hide()
	button.BountyRing = bountyRing

	local criteriaAnimation = detailsFramework:CreateAnimationHub(criteriaFrame)
	detailsFramework:CreateAnimation(criteriaAnimation, "Scale", 1, .10, 1, 1, 1.1, 1.1)
	detailsFramework:CreateAnimation(criteriaAnimation, "Scale", 2, .10, 1.2, 1.2, 1, 1)
	criteriaAnimation.LastPlay = 0
	button.CriteriaAnimation = criteriaAnimation

	local colorBlindTrackerIcon = supportFrame:CreateTexture(nil, "overlay")
	colorBlindTrackerIcon:SetTexture([[Interface\WORLDSTATEFRAME\ColumnIcon-FlagCapture2]])
	colorBlindTrackerIcon:SetSize(24, 24)
	colorBlindTrackerIcon:SetPoint("bottom", button, "top", 0, -5)
	colorBlindTrackerIcon:SetVertexColor(1, .2, .2)
	colorBlindTrackerIcon:Hide()
	button.colorBlindTrackerIcon = colorBlindTrackerIcon

	local overlayBorder = supportFrame:CreateTexture(nil, "overlay", nil, 5)
	local overlayBorder2 = supportFrame:CreateTexture(nil, "overlay", nil, 6)
	overlayBorder:SetDrawLayer("overlay", 5)
	overlayBorder2:SetDrawLayer("overlay", 6)
	overlayBorder:SetTexture([[Interface\Soulbinds\SoulbindsConduitIconBorder]])
	overlayBorder2:SetTexture([[Interface\Soulbinds\SoulbindsConduitIconBorder]])
	overlayBorder:SetTexCoord(0/256, 66/256, 0, 0.5)
	overlayBorder2:SetTexCoord(67/256, 132/256, 0, 0.5)
	overlayBorder:SetPoint("topleft", 0, 0)
	overlayBorder:SetPoint("bottomright", 0, 0)
	overlayBorder2:SetPoint("topleft", 0, 0)
	overlayBorder2:SetPoint("bottomright", 0, 0)
	overlayBorder:Hide()
	overlayBorder2:Hide()

	supportFrame.overlayBorder = overlayBorder
	supportFrame.overlayBorder2 = overlayBorder2
	button.overlayBorder = overlayBorder
	button.overlayBorder2 = overlayBorder2

	button.Shadow:SetDrawLayer("BACKGROUND", -8)
	button.blackBackground:SetDrawLayer("BACKGROUND", -7)
	button.IsTrackingGlow:SetDrawLayer("BACKGROUND", -6)
	button.Texture:SetDrawLayer("BACKGROUND", -5)

	button.IsTrackingRareGlow:SetDrawLayer("overlay", 0)
	button.circleBorder:SetDrawLayer("overlay", 1)
	button.miscBorder:SetDrawLayer("overlay", 1)

	bountyRing:SetDrawLayer("overlay", 7)
	button.squareBorder:SetDrawLayer("overlay", 1)

	button.rareSerpent:SetDrawLayer("overlay", 3)
	button.rareSerpent:SetDrawLayer("BACKGROUND", -6)
	button.rareGlow:SetDrawLayer("BACKGROUND", -7)

	button.bgFlag:SetDrawLayer("overlay", 4)
	button.blackGradient:SetDrawLayer("overlay", 5)
	button.flagText:SetDrawLayer("overlay", 6)
	criteriaIndicator:SetDrawLayer("overlay", 6)
	criteriaIndicatorGlow:SetDrawLayer("overlay", 7)
	button.timeBlipRed:SetDrawLayer("overlay", 7)
	button.timeBlipOrange:SetDrawLayer("overlay", 7)
	button.timeBlipYellow:SetDrawLayer("overlay", 7)
	button.timeBlipGreen:SetDrawLayer("overlay", 7)
	button.questTypeBlip:SetDrawLayer("overlay", 7)

	button.criteriaIndicator = criteriaIndicator
	button.criteriaIndicatorGlow = criteriaIndicatorGlow

	button.bgFlag:Hide()

	if detailsFramework.IsAddonApocalypseWow() then
		--button:EnableMouse(false)
		button:SetMouseMotionEnabled(false)
		anchorFrame:EnableMouse(false)
	end

	return button
end
