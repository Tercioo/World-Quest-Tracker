
local addonId, wqtInternal = ...

--world quest tracker object
local WorldQuestTracker = WorldQuestTrackerAddon
if (not WorldQuestTracker) then
	return
end

--framework
local DF = _G ["DetailsFramework"]
if (not DF) then
	print("|cFFFFAA00World Quest Tracker: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

--localization
local L = DF.Language.GetLanguageTable(addonId)

local _
local GetQuestsForPlayerByMapID = C_TaskQuest.GetQuestsForPlayerByMapID or C_TaskQuest.GetQuestsOnMap
local isWorldQuest = QuestUtils_IsQuestWorldQuest
local GetNumQuestLogRewardCurrencies = WorldQuestTrackerAddon.GetNumQuestLogRewardCurrencies
local GetQuestLogRewardInfo = GetQuestLogRewardInfo
local GetQuestLogRewardCurrencyInfo = WorldQuestTrackerAddon.GetQuestLogRewardCurrencyInfo
local IsQuestCriteriaForBounty = C_QuestLog.IsQuestCriteriaForBounty

local worldFramePOIs = WorldMapFrame.BorderFrame

local UpdateDebug = false

local ZoneWidgetPool = WorldQuestTracker.ZoneWidgetPool
local VignettePool = WorldQuestTracker.VignettePool

local clear_widget = function(self)
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
	self.flagCriteriaMatchGlow:Hide()
	self.TextureCustom:Hide()
	self.RareOverlay:Hide()
	self.Shadow:Hide()
	self.flagTextShadow:SetText("")
end

WorldQuestTracker.ClearZoneWidget = function(widget)
	clear_widget(widget)
end

local on_show_alpha_animation = function(self)
	self:GetParent():Show()
end

local emptyFunction = function()end

function WorldQuestTracker.CreateZoneWidget(index, name, parent, pinTemplate) --~zone --~zoneicon ~create
	local anchorFrame

	if (pinTemplate) then
		anchorFrame = CreateFrame("button", name .. index .. "Anchor", parent, pinTemplate)
		anchorFrame.dataProvider = WorldQuestTracker.DataProvider
		anchorFrame.worldQuest = true
		anchorFrame.owningMap = WorldQuestTracker.DataProvider:GetMap()
	else
		anchorFrame = CreateFrame("button", name .. index .. "Anchor", parent, WorldQuestTracker.DataProvider:GetPinTemplate())
		anchorFrame.dataProvider = WorldQuestTracker.DataProvider
		anchorFrame.worldQuest = true
		anchorFrame.owningMap = WorldQuestTracker.DataProvider:GetMap()
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
	button:SetScript("OnEnter", function() TaskPOI_OnEnter(button) end)
	button:SetScript("OnLeave", function() TaskPOI_OnLeave(button) end)
	button:SetScript("OnClick", WorldQuestTracker.OnQuestButtonClick)

	button:RegisterForClicks("LeftButtonDown", "MiddleButtonDown", "RightButtonDown")

	--show animation
	button.OnShowAlphaAnimation = DF:CreateAnimationHub(button, on_show_alpha_animation)
	DF:CreateAnimation(button.OnShowAlphaAnimation, "ALPHA", 1, 0.075, 0, 1)

	local supportFrame = CreateFrame("frame", nil, button, "BackdropTemplate")
	supportFrame:SetPoint("center")
	supportFrame:SetSize(20, 20)
	button.SupportFrame = supportFrame

	button.UpdateTooltip = TaskPOI_OnEnter
	--> looks like something is triggering the tooltip to update on tick
	button.UpdateTooltip = TaskPOI_OnEnter
	button.worldQuest = true
	button.ClearWidget = clear_widget

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
			button.OnEnterAnimation = DF:CreateAnimationHub(button, function() end, function() end)
			local anim = WorldQuestTracker:CreateAnimation(button.OnEnterAnimation, "Scale", 1, animaSettings.speed, 1, 1, animaSettings.scaleZone, animaSettings.scaleZone, "center", 0, 0)
			anim:SetEndDelay(60) --this fixes the animation going back to 1 after it finishes
			button.OnEnterAnimation.ScaleAnimation = anim

			button.OnLeaveAnimation = DF:CreateAnimationHub(button, function() end, function() end)
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

				if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
					self.ModifiedScale = self.OriginalScale + animaSettings.scaleZone
					if (self.OnEnterAnimation.ScaleAnimation.SetScaleFrom) then
						self.OnEnterAnimation.ScaleAnimation:SetScaleFrom(self.OriginalScale, self.OriginalScale)
						self.OnEnterAnimation.ScaleAnimation:SetScaleTo(self.ModifiedScale, self.ModifiedScale)
					else
						self.OnEnterAnimation.ScaleAnimation:SetFromScale(self.OriginalScale, self.OriginalScale)
						self.OnEnterAnimation.ScaleAnimation:SetToScale(self.ModifiedScale, self.ModifiedScale)
					end
					self.OnEnterAnimation:Play()

				elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
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
					if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
						if (self.OnLeaveAnimation.ScaleAnimation.SetScaleFrom) then
							self.OnLeaveAnimation.ScaleAnimation:SetScaleFrom(currentScale, currentScale)
							self.OnLeaveAnimation.ScaleAnimation:SetScaleTo(originalScale, originalScale)
						else
							self.OnLeaveAnimation.ScaleAnimation:SetFromScale(currentScale, currentScale)
							self.OnLeaveAnimation.ScaleAnimation:SetToScale(originalScale, originalScale)
						end

					elseif (WorldQuestTrackerAddon.GetCurrentZoneType() == "world") then
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

		button.FactionPulseAnimation = DF:CreateAnimationHub(factionPulseAnimationTexture, function() factionPulseAnimationTexture:Show() end, function() factionPulseAnimationTexture:Hide() end)
		local anim = WorldQuestTracker:CreateAnimation(button.FactionPulseAnimation, "Alpha", 1, .35, 0, .5)
		anim:SetSmoothing("OUT")
		local anim = WorldQuestTracker:CreateAnimation(button.FactionPulseAnimation, "Alpha", 2, .35, .5, 0)
		anim:SetSmoothing("OUT")
		button.FactionPulseAnimation:SetLooping("REPEAT")

	local onFlashTrackAnimation = DF:CreateAnimationHub(smallFlashOnTrack, nil, function(self) self:GetParent():Hide() end)
	onFlashTrackAnimation.FlashTexture = smallFlashOnTrack
	WorldQuestTracker:CreateAnimation(onFlashTrackAnimation, "Alpha", 1, .1, 0, 1)
	WorldQuestTracker:CreateAnimation(onFlashTrackAnimation, "Alpha", 2, .1, 1, 0)

	local buttonFullAnimation = DF:CreateAnimationHub(button)
	WorldQuestTracker:CreateAnimation(buttonFullAnimation, "Scale", 1, .1, 1, 1, 1.03, 1.03)
	WorldQuestTracker:CreateAnimation(buttonFullAnimation, "Scale", 2, .1, 1.03, 1.03, 1, 1)

	local onStartTrackAnimation = DF:CreateAnimationHub(button.IsTrackingGlow, WorldQuestTracker.OnStartClickAnimation)
	onStartTrackAnimation.OnFlashTrackAnimation = onFlashTrackAnimation
	onStartTrackAnimation.ButtonFullAnimation = buttonFullAnimation
	WorldQuestTracker:CreateAnimation(onStartTrackAnimation, "Scale", 1, .1, .9, .9, 1.1, 1.1)
	WorldQuestTracker:CreateAnimation(onStartTrackAnimation, "Scale", 2, .1, 1.2, 1.2, 1, 1)

	local onEndTrackAnimation = DF:CreateAnimationHub(button.IsTrackingGlow, WorldQuestTracker.OnStartClickAnimation, WorldQuestTracker.OnEndClickAnimation)
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
	DF:SetFontSize(button.flagText, 8)

	button.flagTextShadow = supportFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal", 5)
	button.flagTextShadow:SetText("13m")
	button.flagTextShadow:SetPoint("center", button.flagText, "center", 0, 0)
	button.flagTextShadow:SetTextColor(.2, .2, .2, 0.5)
	DF:SetFontSize(button.flagTextShadow, 8)
	DF:SetFontShadow(button.flagTextShadow, "black")
	DF:SetFontOutline(button.flagTextShadow, "OUTLINE")

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

	local criteriaAnimation = DF:CreateAnimationHub(criteriaFrame)
	DF:CreateAnimation(criteriaAnimation, "Scale", 1, .10, 1, 1, 1.1, 1.1)
	DF:CreateAnimation(criteriaAnimation, "Scale", 2, .10, 1.2, 1.2, 1, 1)
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

	return button
end

--cria os widgets no mapa da zona
function WorldQuestTracker.GetOrCreateZoneWidget(index, widgetType)
	if (widgetType == "vignette") then
		local icon = VignettePool[index]

		if (not icon) then
			icon = WorldQuestTracker.CreateZoneWidget(index, "WorldQuestTrackerZoneVignetteWidget", WorldQuestTracker.AnchoringFrame)
			VignettePool[index] = icon
		end

		icon.Texture:Show()
		return icon
	else
		local taskPOI = ZoneWidgetPool[index]

		if (not taskPOI) then
			taskPOI = WorldQuestTracker.CreateZoneWidget(index, "WorldQuestTrackerZonePOIWidget", WorldQuestTracker.AnchoringFrame)
			taskPOI.IsZoneQuestButton = true
			ZoneWidgetPool[index] = taskPOI
		end

		taskPOI.Texture:Show()
		return taskPOI
	end
end

--esconde todos os widgets de zona
function WorldQuestTracker.HideZoneWidgets()
	for i = 1, #ZoneWidgetPool do
		ZoneWidgetPool [i]:Hide()
		ZoneWidgetPool [i].AnchorFrame:Hide()
	end
end

local quest_bugged = {}
local dazaralor_quests = {
	{0.441, 0.322},
	{0.441, 0.362},
	{0.441, 0.402},
	{0.441, 0.442},
	{0.441, 0.482},
	{0.441, 0.522},
}

function WorldQuestTracker.AdjustThatThingInTheBottomLeftCorner()
	--looks like this dropdown is opened by default
	if (_G["DropDownList1MenuBackdrop"] and _G["DropDownList1MenuBackdrop"]:IsShown()) then
		--_G["DropDownList1MenuBackdrop"]:Hide()
	end

	local children = {WorldMapFrame:GetChildren()}
	for i = 1, #children do
		local child = children[i]
		if (type(child) == "table" and child.GetObjectType and child.BountyDropdownButton and child.BountyDropDown and child.Background) then
			child:SetScale(0.6)
			child:ClearAllPoints()
			child:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMLEFT", 11, 35)
			child:SetAlpha(0.834)

			if (not child.WorldQuestTrackerInit) then
				child:SetScript("OnClick", function(self, button)
					--close the dropdown if it's opened
					if (_G["DropDownList1MenuBackdrop"] and _G["DropDownList1MenuBackdrop"]:IsShown()) then
						_G["DropDownList1MenuBackdrop"]:Hide()
						return
					end

					--open the dropdown
					child.BountyDropdownButton:GetScript("OnMouseDown")(child.BountyDropdownButton, button)
				end)

				child.Background:SetBlendMode("ADD")

				--crete a highlight using the same texture as the .Background has
				local highlight = child:CreateTexture(nil, "background")
				highlight:SetAtlas("dragonflight-landingbutton-up")
				highlight:SetPoint("topleft", child, "topleft", -7, 6)
				highlight:SetPoint("bottomright", child, "bottomright", 5, -6)
				highlight:Hide()

				DF:CreateFadeAnimation(highlight, 0.05, 0.05, 0.3, 0)

				child.WorldQuestTrackerInit = true
			end

			child.BountyDropdownButton:Hide()
			break
		end
	end
end

--atualiza as quest do mapa da zona ~updatezone ~zoneupdate
function WorldQuestTracker.UpdateZoneWidgets(forceUpdate)
	--get the map shown in the map frame
	local mapId = WorldQuestTracker.GetCurrentMapAreaID()

	WorldQuestTracker.UpdateZonePOIs(forceUpdate)

	if (WorldQuestTracker.IsWorldQuestHub(mapId)) then
		return WorldQuestTracker.HideZoneWidgets()

	elseif (not WorldQuestTracker.ZoneHaveWorldQuest(mapId)) then
		return WorldQuestTracker.HideZoneWidgets()
	end

	WorldQuestTracker.AdjustThatThingInTheBottomLeftCorner()

	--detect where the fly points are
	local map = WorldQuestTrackerDataProvider:GetMap()

	--[=[ pin templates
		FlightPointPinTemplate
		HereBeDragonsPinsTemplate
		WorldMap_WorldQuestPinTemplate
		MapLinkPinTemplate
		VignettePinTemplate
		StorylineQuestPinTemplate
		AreaPOIPinTemplate
		WorldQuestSpellEffectPinTemplate
		GroupMembersPinTemplate
		QuestBlobPinTemplate
		QuestPinTemplate
		WorldQuestTrackerPathPinTemplate
		DungeonEntrancePinTemplate
		MapHighlightPinTemplate
		FogOfWarPinTemplate
		MapExplorationPinTemplate
		ScenarioBlobPinTemplate
	--]=]

	--[=[ pin members
		zoomedInNudge 1
		endScale 1.2
		zoomedOutNudge 1.25
		startScale 1
		normalizedY 1.4144917726517
		name Azure Archives, Azure Span
		normalizedX 0.16435858607292
		pinFrameLevelType PIN_FRAME_LEVEL_FLIGHT_POINT
		scaleFactor 1
		nudgeTargetFactor 0.015
		Texture table: 000001B027B233D0
		pinFrameLevel PIN_FRAME_LEVEL_FLIGHT_POINT
		pinTemplate FlightPointPinTemplate
		owningMap
		ApplyFrameLevel
		ApplyCurrentPosition
		ApplyCurrentAlpha
		ApplyCurrentScale
		HighlightTexture
		PanAndZoomTo
		CreateSubPin
		ClearNudgeSettings
		DisableInheritedMotionScriptsWarning
		GetFrameLevelType
		GetHighlightType
		GetNudgeSourceZoomedInMagnitude
		GetNudgeSourcePinZoomedInNudgeFactor
		GetNudgeSourceZoomedOutMagnitude
		GetNudgeVector
		GetNudgeFactor
		GetNudgeSourcePinZoomedOutNudgeFactor
		GetNudgeSourceRadius
		GetNudgeTargetFactor
		GetNudgeZoomFactor
		GetMap
		GetGlobalPosition
		GetPosition
		GetZoomedOutNudgeFactor
		GetZoomedInNudgeFactor
		IsIgnoringGlobalPinScale
		IgnoresNudging
		OnMouseEnter
		OnMouseUp
		OnAcquired
		OnLoad
		OnReleased
		OnCanvasPanChanged
		OnCanvasScaleChanged
		OnClick
		OnMouseLeave
		OnMapInsetMouseEnter
		OnMapInsetSizeChanged
		OnMapInsetMouseLeave
		OnMouseDown
		OnCanvasSizeChanged
		PanTo
		SetAlphaStyle
		SetAlphaLimits
		SetIgnoreGlobalPinScale
		SetNudgeTargetFactor
		SetNudgeFactor
		SetNudgeZoomedInFactor
		SetNudgeSourceMagnitude
		SetNudgeSourceRadius
		SetNudgeVector
		SetNudgeZoomedOutFactor
		SetPosition
		SetScaleStyle
		SetScalingLimits
		SetTexture
		UseFrameLevelType
		UseFrameLevelTypeFromRangeTop
	--]=]

	for pin in map:EnumeratePinsByTemplate("DungeonEntrancePinTemplate") do
		pin.Texture:SetAlpha(0.934)
	end

	--for pin in map:EnumeratePinsByTemplate("DelveEntrancePinTemplate") do
		--pin.Texture:SetTexture([[Interface\AddOns\WorldQuestTracker\media\well.png]], nil, nil, "TRILINEAR")
		--pin.Texture:SetAlpha(0.834)
		--pin.Texture:SetScale(0.7)
	--end

	---@class poiinfo : table
	---@field areaPoiID number
	---@field description string
	---@field addPaddingAboveTooltipWidgets boolean
	---@field isAlwaysOnFlightmap boolean
	---@field isPrimaryMapForPOI boolean
	---@field tooltipWidgetSet number
	---@field highlightVignettesOnHover boolean
	---@field name string
	---@field position table
	---@field shouldGlow boolean
	---@field isCurrentEvent boolean
	---@field highlightWorldQuestsOnHover boolean
	---@field atlasName string

	WorldQuestTrackerDataProvider:GetMap():RemoveAllPinsByTemplate("WorldQuestTrackerPOIPinTemplate")
	WorldQuestTracker.HideAllPOIPins()

	--~locked ~poi ~areapoi
    for pin in map:EnumeratePinsByTemplate("AreaPOIPinTemplate") do
        local atlasName = pin.Texture:GetAtlas()
		pin.Texture:SetAlpha(0.934)
        if (atlasName == "worldquest-Capstone-questmarker-epic-Locked") then
			--how to identify the point of interest?
			if (not WorldQuestTracker.db.profile.pins_discovered["worldquest-Capstone-questmarker-epic-Locked"][pin.areaPoiID]) then
				local poiInfo = pin:GetPoiInfo() --table
				local mapData = pin:GetMap() --function

				local poiId = poiInfo.areaPoiID
				local mapId = mapData:GetMapID()
				local position = poiInfo.position
				local mapInfo = C_Map.GetMapInfo(mapId)
				local parentMapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)

				--need check if a waypoint already exists
				local mapPoint = UiMapPoint.CreateFromCoordinates(mapId, position.x, position.y)
				C_Map.SetUserWaypoint(mapPoint)
				local worldPosition = C_Map.GetUserWaypointPositionForMap(parentMapInfo.mapID)
				C_Map.ClearUserWaypoint()

				---@class wqt_poidata
				---@field poiID number
				---@field mapID number
				---@field zoneX number
				---@field zoneY number
				---@field continentID number
				---@field worldX number
				---@field worldY number
				---@field tooltipSetId number

				local pointOfInterestData = {
					["poiID"] = poiId,
					["mapID"] = mapId,
					["zoneX"] = pin.normalizedX,
					["zoneY"] = pin.normalizedY,
					["continentID"] = parentMapInfo.mapID,
					["worldX"] = worldPosition.x,
					["worldY"] = worldPosition.y,
					["tooltipSetId"] = poiInfo.tooltipWidgetSet,
				}

				WorldQuestTracker.db.profile.pins_discovered["worldquest-Capstone-questmarker-epic-Locked"][poiId] = pointOfInterestData
			end

			pin.Texture:SetScale(1.2)
		else
			pin.Texture:SetScale(1)
        end
    end

	for pin in map:EnumeratePinsByTemplate("QuestPinTemplate") do
		pin:SetAlpha(0.923)
	end

	local flightPoints = {}

	for pin in map:EnumeratePinsByTemplate("FlightPointPinTemplate") do
		local x, y = pin:GetPosition()
		flightPoints[#flightPoints + 1] = {x = x, y = y, pin = pin}

		local texture = pin.Texture
		texture:SetAlpha(0.85)

		if (not pin.TextureShadow) then
			pin.TextureShadow = texture:GetParent():CreateTexture(nil, "BACKGROUND")
			pin.TextureShadow:SetAtlas(texture:GetAtlas())
			pin.TextureShadow:SetVertexColor(.2, .2, .2)
			pin.TextureShadow:SetAlpha(0.4)
			pin.TextureShadow:SetPoint("CENTER", texture, "CENTER", 1, -1)
			local width, height = texture:GetSize()
			pin.TextureShadow:SetSize(width, height)
		end

		pin.TextureShadow:SetAlpha(0.4)
	end

	if (WorldMapFrame.mapID) then
		--get the player position in the map
		local playerPosition = C_Map.GetPlayerMapPosition(WorldMapFrame.mapID, "player")

		if (playerPosition) then
			--find the closest flight point to the player position
			local closestFlightPoint
			local closestDist
			for i = 1, #flightPoints do
				local flightPoint = flightPoints[i]
				local distance = DF:GetDistance_Point(playerPosition.x, playerPosition.y, flightPoint.x, flightPoint.y)
				if (not closestDist or distance < closestDist) then
					closestDist = distance
					closestFlightPoint = flightPoint
				end
			end

			if (closestFlightPoint) then
				closestFlightPoint.pin.Texture:SetAlpha(1)
				closestFlightPoint.pin.TextureShadow:SetAlpha(0.924)
			end
		end
	end

	WorldQuestTracker.RefreshStatusBarVisibility()

	local timeNow = GetTime()
	WorldQuestTracker.lastZoneWidgetsUpdate = timeNow --why there's two timers?

	--stop the update if it already updated on this tick
	if (WorldQuestTracker.LastZoneUpdate and WorldQuestTracker.LastZoneUpdate == timeNow) then
		--print(4)
		return
	end

	local taskInfo
	if (mapId == WorldQuestTracker.MapData.ZoneIDs.DALARAN) then
		taskInfo = GetQuestsForPlayerByMapID(mapId) --fix from @legowxelab2z8 from curse
	else
		taskInfo = GetQuestsForPlayerByMapID(mapId, mapId)
	end

	local index = 1

	--stop the animation if it's playing
	if (WorldQuestTracker.IsPlayingLoadAnimation()) then
		WorldQuestTracker.StopLoadingAnimation()
	end

	local filters = WorldQuestTracker.db.profile.filters
	local forceShowBrokenShore = WorldQuestTracker.db.profile.filter_force_show_brokenshore

	wipe(WorldQuestTracker.Cache_ShownQuestOnZoneMap)
	wipe(WorldQuestTracker.Cache_ShownWidgetsOnZoneMap)

	local total_Gold, total_Resources, total_APower, total_Pet = 0, 0, 0, 0
	local scale = WorldQuestTracker.db.profile.zone_map_config.scale

	local questFailed = false
	local showBlizzardWidgets = WorldQuestTracker.Temp_HideZoneWidgets > timeNow
	if (not showBlizzardWidgets) then
		--if not suppresss regular widgets, see if not showing from the profile
		showBlizzardWidgets = not WorldQuestTracker.db.profile.zone_map_config.show_widgets
	end

	wipe(WorldQuestTracker.CurrentZoneQuests)
	wipe(WorldQuestTracker.ShowDefaultWorldQuestPin)

	local bountyQuestId = WorldQuestTracker.GetCurrentBountyQuest()
	local workerQuestIndex = 1
	local bannedQuests = WorldQuestTracker.db.profile.banned_quests

	WorldQuestTracker.CurrentZoneQuestsMapID = mapId

	---@type wqt_questdata[]
	WorldQuestTracker.QuestData_Zone = {}
	---@type table<questid, wqt_questdata>
	WorldQuestTracker.QuestData_WorldHash = {}

	if (taskInfo and #taskInfo > 0) then
		local needAnotherUpdate = false

		for i, info  in ipairs(taskInfo) do
			local questID = info.questID
			if (questID) then
				local isWorldQuest = isWorldQuest(questID)
				if (isWorldQuest) then
					if (HaveQuestData(questID)) then
						local isNotBanned = not bannedQuests[questID]

						local overridedMapId = WorldQuestTracker.MapData.OverrideMapId[mapId] or mapId
						local overridedTaskMapId = WorldQuestTracker.MapData.OverrideMapId[info.mapID] or info.mapID
						local bIsOnSameMap = overridedMapId == overridedTaskMapId

						if (isWorldQuest and isNotBanned and bIsOnSameMap) then
							--local isSuppressed = WorldQuestTracker.DataProvider:IsQuestSuppressed(questID)
							--local passFilters = WorldQuestTracker.DataProvider:DoesWorldQuestInfoPassFilters(info)

							local timeLeft = WorldQuestTracker.GetQuest_TimeLeft(questID)
							if (not timeLeft or timeLeft == 0) then
								timeLeft = 1
							end

							if (timeLeft > 0) then --not isSuppressed and passFilters and timeLeft
								local bCanCache = true
								if (not HaveQuestRewardData(questID)) then
									C_TaskQuest.RequestPreloadRewardData(questID)
									bCanCache = false
									needAnotherUpdate = true
								end

								WorldQuestTracker.CurrentZoneQuests[questID] = true

								local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData(questID, bCanCache)
								if (questID == -1) then
									print("Zone: ",questID,  title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount)
								end

								local filter, order = WorldQuestTracker.GetQuestFilterTypeAndOrder(worldQuestType, gold, rewardName, itemName, isArtifact, stackAmount, numRewardItems, rewardTexture, tagID)
								local passFilter = filters[filter]

								if (not passFilter) then
									if (rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
										passFilter = true

									elseif (worldQuestType == LE_QUEST_TAG_TYPE_FACTION_ASSAULT) then
										passFilter = true

									elseif (WorldQuestTracker.db.profile.filter_always_show_faction_objectives) then
										local isCriteria = IsQuestCriteriaForBounty(questID, bountyQuestId)

										if (isCriteria) then
											passFilter = true
										end
									end

								elseif (WorldQuestTracker.db.profile.zone_only_tracked) then
									if (not WorldQuestTracker.IsQuestBeingTracked(questID)) then
										passFilter = false
									end
								end

								--todo: broken shore is outdated, as well as argus
								if (passFilter or (forceShowBrokenShore and WorldQuestTracker.IsNewEXPZone(mapId))) then
									local widget = WorldQuestTracker.GetOrCreateZoneWidget(index)

									if (widget.questID ~= questID or forceUpdate or not widget.Texture:GetTexture()) then
										local selected = WorldMap_IsWorldQuestEffectivelyTracked(questID)
										local isCriteria = C_QuestLog.IsQuestCriteriaForBounty(questID, bountyQuestId)
										local isSpellTarget = SpellCanTargetQuest() and IsQuestIDValidSpellTarget(questID)

										if (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
											total_Pet = total_Pet + 1
										end

										widget.mapID = mapId
										widget.questID = questID
										widget.numObjectives = info.numObjectives
										widget.questName = title
										widget.Order = order or 1

										--> cache reward amount
										widget.Currency_Gold = gold or 0
										widget.Currency_ArtifactPower = artifactPower or 0
										widget.Currency_Resources = 0

										if (WorldQuestTracker.MapData.ResourceIcons [rewardTexture]) then
											widget.Currency_Resources = numRewardItems or 0
										end

										local xPos, yPos = info.x, info.y

										--dazralon
										if (mapId == 1165) then
											--detect if the quest is a worker quest --0.44248777627945 0.32204276323318
											if (xPos >= 0.43 and xPos <= 0.45) then
												if (yPos >= 0.31 and yPos <= 0.33) then
													local newPos = dazaralor_quests [workerQuestIndex]
													xPos, yPos = newPos[1], newPos[2]
													workerQuestIndex = workerQuestIndex + 1
												end
											end

											widget.PosX = xPos
											widget.PosY = yPos
										else
											widget.PosX = info.x
											widget.PosY = info.y
										end

										local bWarband, bWarbandRep = WorldQuestTracker.GetQuestWarbandInfo(questID, factionID)

										---@type wqt_questdata
										local questData = {
											questID = questID,
											mapID = mapId,
											numObjectives = info.numObjectives,
											questCounter = 1,
											title = title,
											x = widget.PosX,
											y = widget.PosY,
											filter = filter,
											worldQuestType = worldQuestType,
											isCriteria = isCriteria,
											isNew = false,
											timeLeft = timeLeft,
											order = order,
											rarity = rarity,
											isElite = isElite,
											tradeskillLineIndex = tradeskillLineIndex,
											factionID = factionID,
											isWarband = bWarband,
											warbandRep = bWarbandRep,
											tagID = tagID,
											tagName = tagName,
											gold = gold,
											goldFormated = goldFormated,
											rewardName = rewardName,
											rewardTexture = rewardTexture,
											numRewardItems = numRewardItems,
											itemName = itemName,
											itemTexture = itemTexture,
											itemLevel = itemLevel,
											quantity = itemQuantity,
											quality = itemQuality,
											isUsable = isUsable,
											itemID = itemID,
											isArtifact = isArtifact,
											artifactPower = artifactPower,
											isStackable = isStackable,
											stackAmount = stackAmount,
											inProgress = false,
											selected = false,
											isSpellTarget = false,
										}

										WorldQuestTracker.QuestData_Zone[#WorldQuestTracker.QuestData_Zone+1] = questData
										WorldQuestTracker.QuestData_WorldHash[questID] = questData

										WorldQuestTracker.SetupWorldQuestButton(widget, questData)

										widget.AnchorFrame.questID = questID
										widget.AnchorFrame.numObjectives = widget.numObjectives

										local posX, posY = widget.PosX, widget.PosY
										WorldQuestTrackerAddon.DataProvider:GetMap():SetPinPosition(widget.AnchorFrame, posX, posY)

										widget.AnchorFrame:Show()
										widget:SetFrameLevel(WorldQuestTracker.DefaultFrameLevel + floor(random(1, 30)))

										widget:Show()

										table.insert(WorldQuestTracker.Cache_ShownQuestOnZoneMap, questID)
										table.insert(WorldQuestTracker.Cache_ShownWidgetsOnZoneMap, widget)

										widget:SetScale(scale) --affect only zones(not the world map)

										if (gold) then
											total_Gold = total_Gold + gold
										end
										if (numRewardItems and WorldQuestTracker.MapData.ResourceIcons [rewardTexture]) then
											total_Resources = total_Resources + numRewardItems
										end
										if (isArtifact) then
											total_APower = total_APower + artifactPower
										end

										if (showBlizzardWidgets) then
											widget:Hide()
											for _, button in WorldQuestTracker.GetDefaultPinIT() do
												if (button.questID == questID) then
													button:Show()
												end
											end
										else
											widget:Show()
										end

										if (timeLeft == 1) then
											--let the default UI show the icon if the time is mess off
											widget:Hide()
											WorldQuestTracker.ShowDefaultPinForQuest(questID)
										end
									else
										if (showBlizzardWidgets) then
											widget:Hide()
											for _, button in WorldQuestTracker.GetDefaultPinIT() do
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
											table.insert(WorldQuestTracker.Cache_ShownQuestOnZoneMap, questID)
											table.insert(WorldQuestTracker.Cache_ShownWidgetsOnZoneMap, widget)
										end
									end

									index = index + 1

								else
									if (not filter) then
										--> if WTQ didn't identify the quest type, allow the default interface to show this quest
										--> this is a safety measure with bugs or new quest types
										WorldQuestTracker.ShowDefaultPinForQuest(questID)
									end
								end --pass filters

							else
								--show blizzard pin if the quest has an invalid time left
								WorldQuestTracker.ShowDefaultPinForQuest(questID)
							end --time left

						end --is world quest

					else --don't have quest data
						if (WorldQuestTracker.__debug) then
							local questName = C_QuestLog.GetTitleForQuestID(questID)
							WorldQuestTracker:Msg("no HaveQuestData for quest", questID, questName)
						end

						local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info(questID)
						if (title) then
							if (UpdateDebug) then print("NeedUpdate 1") end
							quest_bugged [questID] =(quest_bugged [questID] or 0) + 1

							if (quest_bugged [questID] <= 2) then
								questFailed = true
								C_TaskQuest.RequestPreloadRewardData(questID)
								WorldQuestTracker.ScheduleZoneMapUpdate(1, true)
							end
						end
						--show blizzard pin if the client doesn't have the quest data yet
						WorldQuestTracker.ShowDefaultPinForQuest(questID)
					end
				end --end isWorldQuest
			else
				if (WorldQuestTracker.__debug) then
					local questName = C_QuestLog.GetTitleForQuestID(questID)
					WorldQuestTracker:Msg("questID is nil for taskinfo", questID, questName)
				end

				local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info(questID)
				if (title) then
					if (UpdateDebug) then print("NeedUpdate 2") end
					quest_bugged [title] =(quest_bugged [title] or 0) + 1

					if (quest_bugged [title] <= 2) then
						questFailed = true
						WorldQuestTracker.ScheduleZoneMapUpdate(1, true)
					end
				end
			end --end questID
		end --end foreach taskinfo

		if (needAnotherUpdate) then
			if (UpdateDebug) then print("NeedUpdate 2") end
			WorldQuestTracker.ScheduleZoneMapUpdate(0.5, true)
		end

		if (not WorldQuestTracker.CanCacheQuestData) then
			if (not WorldQuestTracker.PrepareToAllowCachedQuestData) then
				WorldQuestTracker.PrepareToAllowCachedQuestData = C_Timer.NewTimer(10, function()
					WorldQuestTracker.CanCacheQuestData = true
				end)
			end
		end

		if (not questFailed) then
			WorldQuestTracker.HideZoneWidgetsOnNextTick = true
			WorldQuestTracker.LastZoneUpdate = GetTime()
		end
	else
		if (UpdateDebug) then print("NeedUpdate 3") end
		WorldQuestTracker.ScheduleZoneMapUpdate(3)
	end

	for i = index, #ZoneWidgetPool do
		ZoneWidgetPool[i]:Hide()
	end

	if (WorldQuestTracker.WorldMap_GoldIndicator) then
		WorldQuestTracker.WorldMap_GoldIndicator.text = floor(total_Gold / 10000)

		if (total_Resources >= 1000) then
			WorldQuestTracker.WorldMap_ResourceIndicator.text = WorldQuestTracker.ToK(total_Resources)
		else
			WorldQuestTracker.WorldMap_ResourceIndicator.text = total_Resources
		end

		if (total_APower >= 1000) then
			WorldQuestTracker.WorldMap_APowerIndicator.text = WorldQuestTracker.ToK_FormatBigger(total_APower)
		else
			WorldQuestTracker.WorldMap_APowerIndicator.text = total_APower
		end

		--adjust the artifact power icon for each region
		local mapTable = WorldQuestTracker.mapTables[mapId]
		if (mapTable) then
			local mainHub = mapTable.show_on_map
			if (mainHub) then
				local texture
				if (mainHub[WorldQuestTracker.MapData.ZoneIDs.THESHADOWLANDS]) then
					texture = WorldQuestTracker.MapData.ArtifactPowerSummaryIcons.SHADOWLANDS_ARTIFACT

				elseif (mainHub[WorldQuestTracker.MapData.ZoneIDs.KULTIRAS] or mainHub[WorldQuestTracker.MapData.ZoneIDs.ZANDALAR]) then --bfa
					texture = WorldQuestTracker.MapData.ArtifactPowerSummaryIcons.BFA_ARTIFACT

				elseif (mainHub[WorldQuestTracker.MapData.ZoneIDs.BROKENISLES] or mainHub[WorldQuestTracker.MapData.ZoneIDs.ARGUS]) then --legion
					texture = WorldQuestTracker.MapData.ArtifactPowerSummaryIcons.LEGION_ARTIFACT
				end

				if (texture) then
					WorldQuestTracker.WorldMap_APowerIndicatorTexture:SetTexture(texture)
					WorldQuestTracker.WorldMap_APowerIndicatorTexture:SetSize(16, 16)
					WorldQuestTracker.WorldMap_APowerIndicatorTexture:SetTexCoord(0, 1, 0, 1)
				end
			end
		end

		WorldQuestTracker.WorldMap_APowerIndicator.Amount = total_APower
		WorldQuestTracker.WorldMap_PetIndicator.text = total_Pet
	end

	WorldQuestTracker.UpdateZoneSummaryFrame()

	WorldQuestTracker.FinishedUpdate_Zone()
end

--check if the zone has extra data to show like quests, pois, etc
function WorldQuestTracker.UpdateZonePOIs(forceUpdate)
	local mapID = WorldQuestTracker.GetCurrentMapAreaID()
	local extraIcons = WorldQuestTracker.extraIcons[mapID]

	local index = 1

	if (extraIcons) then
		--extraIcons is an array with iconData
		for i = 1, #extraIcons do
			local iconData = extraIcons[i]
			if (iconData.dataType == "vignette") then
				local id = iconData.id
				local allVignetteSerials = C_VignetteInfo.GetVignettes()

				for o = 1, #allVignetteSerials do
					local vignetteSerial = allVignetteSerials[o]
					local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteSerial)

					if (vignetteInfo) then
						if (vignetteInfo.vignetteID == id) then
							local vec2Pos = C_VignetteInfo.GetVignettePosition(vignetteSerial, mapID)
							if (vec2Pos) then
								local widget = WorldQuestTracker.GetOrCreateZoneWidget(index, "vignette")
								index = index + 1

								widget.questID = 0
								widget.PosX = vec2Pos.x
								widget.PosY = vec2Pos.y

								--the zone widget need to be updated here
								WorldQuestTracker.ResetWorldQuestZoneButton(widget)
								widget.Texture:SetAtlas(vignetteInfo.atlasName)

								widget.Texture:SetSize(16, 16)
								widget:SetSize(16, 16)
								widget:SetAlpha(0.8)
								WorldQuestTrackerAddon.DataProvider:GetMap():SetPinPosition(widget.AnchorFrame, widget.PosX, widget.PosY)
								widget:Show()
							end
						end
					end
				end
			--elseif (iconData.dataType == "icon") then
			end
		end
	end
end

--reset the button
function WorldQuestTracker.ResetWorldQuestZoneButton(self)
	self.isArtifact = nil
	self.circleBorder:Hide()
	self.squareBorder:Hide()
	self.flagText:SetText("")
	self.flagTextShadow:SetText("")
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
	self.timeBlipRed:Hide()
	self.timeBlipOrange:Hide()
	self.timeBlipYellow:Hide()
	self.timeBlipGreen:Hide()
	self.blackGradient:Hide()
	self.Shadow:Hide()
	self.TextureCustom:Hide()

	self.BountyRing:Hide()

	self.RareOverlay:Hide()
	self.bgFlag:Hide()

	self.colorBlindTrackerIcon:Hide()

	self.IsRare = nil
	self.RareName = nil
	self.RareSerial = nil
	self.RareTime = nil
	self.RareOwner = nil
	self.QuestType = nil
	self.Amount = nil
end

--this function does not check if the quest reward is in the client cache ~update ~setup ~button
---@param self table
---@param questData wqt_questdata
function WorldQuestTracker.SetupWorldQuestButton(self, questData)
	--if a boolean is passed, this is a quick refresh, just load the questData cached in the button
	if (type(questData) == "boolean") then
		questData = self.questData
	else
		self.questData = questData
	end

	local worldQuestType, rarity, isElite, tradeskillLineIndex, inProgress, selected, isCriteria, isSpellTarget, mapID = questData.worldQuestType, questData.rarity, questData.isElite, questData.tradeskillLineIndex, questData.inProgress, questData.selected, questData.isCriteria, questData.isSpellTarget, questData.mapID
	local title, factionID, tagID, tagName = questData.title, questData.factionID, questData.tagID, questData.tagName
	local bWarband, bWarbandRep = questData.bWarband, questData.bWarbandRep

	local questID = self.questID
	if (not questID) then
		return
	end

	WorldQuestTracker.ResetWorldQuestZoneButton(self)

	self.worldQuestType = worldQuestType
	self.rarity = rarity
	self.isElite = isElite
	self.tradeskillLineIndex = tradeskillLineIndex
	self.inProgress = inProgress
	self.selected = selected
	self.isCriteria = isCriteria
	self.isSpellTarget = isSpellTarget
	self.mapID = mapID
	self.isSelected = selected
	self.isCriteria = isCriteria
	self.isSpellTarget = isSpellTarget

	self.flagText:Show()
	self.blackGradient:Show()
	self.Shadow:Show()

	self.blackGradient:Hide() --don't show the texture of a black gradient below the amount indicator

	if (HaveQuestData(questID)) then
		if (tagID == 268) then --new quests on maw?
			worldQuestType = LE_QUEST_TAG_TYPE_INVASION
			rarity = LE_WORLD_QUEST_QUALITY_RARE
			isElite = true
		end

		--default alpha
		self:SetAlpha(WorldQuestTracker.db.profile.worldmap_widget_alpha)
		self.FactionID = factionID

		if (self.isCriteria) then
			if (WorldQuestTracker.db.profile.accessibility.use_bounty_ring) then
				self.BountyRing:Show()
			end

			self.criteriaIndicator:Show()
			self.criteriaIndicator:SetAlpha(1)
			self.criteriaIndicatorGlow:Show()
			self.criteriaIndicatorGlow:SetAlpha(0.7)
		else
			self.flagCriteriaMatchGlow:Hide()
			self.criteriaIndicator:Hide()
			self.criteriaIndicatorGlow:Hide()
			self.BountyRing:Hide()
		end

		if (bWarband and WorldQuestTracker.db.profile.show_warband_rep_warning) then
			if (not bWarbandRep) then
				self.criteriaIndicator:Show()
				self.criteriaIndicator:SetVertexColor(DF:ParseColors(WorldQuestTracker.db.profile.show_warband_rep_warning_color))
				self.criteriaIndicator:SetAlpha(WorldQuestTracker.db.profile.show_warband_rep_warning_alpha)
				self.Texture:SetDesaturation(WorldQuestTracker.db.profile.show_warband_rep_warning_desaturation)
				self.criteriaIndicatorGlow:Show()
				self.criteriaIndicatorGlow:SetAlpha(0.7)
			else
				self.criteriaIndicator:Hide()
				self.criteriaIndicatorGlow:Hide()
			end
		end

		if (not WorldQuestTracker.db.profile.use_tracker) then
			if (WorldQuestTracker.IsQuestOnObjectiveTracker(questID)) then
				if (rarity == LE_WORLD_QUEST_QUALITY_RARE or rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
					self.IsTrackingRareGlow:Show()
				end
				self.IsTrackingGlow:Show()

				if (WorldQuestTracker.db.profile.accessibility.extra_tracking_indicator) then
					self.colorBlindTrackerIcon:Show()
				end
			end
		else
			if (WorldQuestTracker.IsQuestBeingTracked(questID)) then
				if (rarity == LE_WORLD_QUEST_QUALITY_RARE or rarity == LE_WORLD_QUEST_QUALITY_EPIC) then
					if (mapID ~= suramar_mapId) then
						self.IsTrackingRareGlow:Show()
					end
				end
				self.IsTrackingGlow:Show()
				self:SetAlpha(1)

				if (WorldQuestTracker.db.profile.accessibility.extra_tracking_indicator) then
					self.colorBlindTrackerIcon:Show()
				end
			end
		end

		if (worldQuestType == LE_QUEST_TAG_TYPE_PVP or worldQuestType == LE_QUEST_TAG_TYPE_FACTION_ASSAULT) then
			self.questTypeBlip:Show()
			self.questTypeBlip:SetTexture([[Interface\PVPFrame\Icon-Combat]])
			self.questTypeBlip:SetTexCoord(.05, .95, .05, .95)
			self.questTypeBlip:SetAlpha(1)

		elseif (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
			self.questTypeBlip:Show()
			self.questTypeBlip:SetTexture(WorldQuestTracker.MapData.QuestTypeIcons[WQT_QUESTTYPE_PETBATTLE].icon)
			self.questTypeBlip:SetTexCoord(unpack(WorldQuestTracker.MapData.QuestTypeIcons[WQT_QUESTTYPE_PETBATTLE].coords))
			self.questTypeBlip:SetAlpha(1)
			self.QuestType = QUESTTYPE_PET

		elseif (worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION) then

		elseif (worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON) then

		else
			self.questTypeBlip:Hide()
		end

		-- tempo restante
		local timeLeft = questData.timeLeft
		if (timeLeft < 1) then
			timeLeft = 1
		end

		if (timeLeft and timeLeft > 0) then
			self.TimeLeft = timeLeft

			WorldQuestTracker.SetTimeBlipColor(self, timeLeft)
			local okay = false

			-- gold
			local goldReward, goldFormated = questData.gold, questData.goldFormated
			if (goldReward > 0) then
				local texture = WorldQuestTracker.GetGoldIcon()
				WorldQuestTracker.SetIconTexture(self.Texture, texture, false, false)

				self.Texture:SetSize(16, 16)
				self.IconTexture = texture
				self.IconText = goldFormated
				self.flagText:SetText(goldFormated)
				self.flagTextShadow:SetText(goldFormated)
				self.circleBorder:Show()
				self.QuestType = QUESTTYPE_GOLD
				self.Amount = goldReward

				WorldQuestTracker.UpdateBorder(self)
				okay = true
			end

			-- poder de artefato
			--local artifactXP = GetQuestLogRewardArtifactXP(questID)
			--if ( artifactXP > 0 ) then
				--seta icone de poder de artefato
				--return
			--end


			-- resource
			local rewardName, rewardTexture, numRewardItems = questData.rewardName, questData.rewardTexture, questData.numRewardItems
			if (rewardName and not okay) then
				if (rewardTexture) then
					self.Texture:SetTexture(WorldQuestTracker.MapData.ReplaceIcon [rewardTexture] or rewardTexture)

					self.circleBorder:Show()
					self.Texture:SetSize(16, 16)
					self.IconTexture = rewardTexture
					self.IconText = numRewardItems

					if (WorldQuestTracker.MapData.ResourceIcons [rewardTexture]) then
						self.QuestType = QUESTTYPE_RESOURCE
						self.Amount = numRewardItems
					end

					if (numRewardItems >= 1000) then
						self.flagText:SetText(format("%.1fK", numRewardItems/1000))
						self.flagTextShadow:SetText(format("%.1fK", numRewardItems/1000))
					else
						if (numRewardItems == 1) then
							self.flagText:SetText("")
							self.flagTextShadow:SetText("")
						else
							self.flagText:SetText(numRewardItems)
							self.flagTextShadow:SetText(numRewardItems)
						end
					end

					WorldQuestTracker.UpdateBorder(self)

					if (self:GetHighlightTexture()) then
						self:GetHighlightTexture():SetTexture([[Interface\Store\store-item-highlight]])
						self:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
					end

					okay = true
				end
			end

			-- items
			local itemName, itemTexture, itemLevel, itemQuantity, quality, isUsable, itemID, isArtifact, artifactPower, isStackable = questData.itemName, questData.itemTexture, questData.itemLevel, questData.quantity, questData.quality, questData.isUsable, questData.itemID, questData.isArtifact, questData.artifactPower, questData.isStackable

			local questIDtoDebug = -1
			if (questIDtoDebug == questID) then
				WorldQuestTracker:Msg("=== SetupWorldQuestButton() called ===")
				print("numRewardItems", numRewardItems, "itemQuantity", itemQuantity)
			end

			if (itemName) then
				if (isArtifact) then
					local texture = WorldQuestTracker.GetArtifactPowerIcon(isArtifact, true, questID)
					self.Texture:SetTexture(texture)
					self.Texture:SetSize(16, 16)

					if (artifactPower >= 1000) then
						if (artifactPower > 999999999) then -- 1B
							self.flagText:SetText(WorldQuestTracker.ToK_FormatBigger(artifactPower))
							self.flagTextShadow:SetText(WorldQuestTracker.ToK_FormatBigger(artifactPower))

						elseif (artifactPower > 999999) then -- 1M
							self.flagText:SetText(WorldQuestTracker.ToK_FormatBigger(artifactPower))
							self.flagTextShadow:SetText(WorldQuestTracker.ToK_FormatBigger(artifactPower))

						elseif (artifactPower > 9999) then
							self.flagText:SetText(WorldQuestTracker.ToK(artifactPower))
							self.flagTextShadow:SetText(WorldQuestTracker.ToK(artifactPower))

						else
							self.flagText:SetText(format("%.1fK", artifactPower/1000))
							self.flagTextShadow:SetText(format("%.1fK", artifactPower/1000))
						end
					else
						self.flagText:SetText(artifactPower)
						self.flagTextShadow:SetText(artifactPower)
					end

					self.isArtifact = isArtifact
					self.IconTexture = texture
					self.IconText = artifactPower
					self.QuestType = QUESTTYPE_ARTIFACTPOWER
					self.Amount = artifactPower
				else
					self.Texture:SetSize(16, 16)

					if (WorldQuestTracker.IsRacingQuest(tagID)) then
						--self.Texture:SetAtlas("worldquest-icon-race")
						self.Texture:SetTexture([[Interface\AddOns\WorldQuestTracker\media\icon_racing]])
					else
						self.Texture:SetTexture(itemTexture)
					end

					local color = ""
					if (quality == 4 or quality == 3) then
						color =  WorldQuestTracker.RarityColors [quality]
					end

					local sFlagText = (isStackable and itemQuantity and itemQuantity >= 1 and itemQuantity or false) or(itemLevel and itemLevel > 5 and(color) .. itemLevel) or ""

					if (sFlagText == 1) then
						self.flagText:SetText("")
						self.flagTextShadow:SetText("")
					else
						self.flagText:SetText(sFlagText)
						self.flagTextShadow:SetText(sFlagText)
					end
					self.IconTexture = itemTexture
					self.IconText = self.flagText:GetText()
					self.QuestType = QUESTTYPE_ITEM
				end

				if (self:GetHighlightTexture()) then
					self:GetHighlightTexture():SetTexture([[Interface\Store\store-item-highlight]])
					self:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
				end

				--local conduitType, borderTexture, borderColor, itemLink = WorldQuestTracker.GetConduitQuestData(questID) --shadowlands
				WorldQuestTracker.UpdateBorder(self)
				okay = true
			end

			if (worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE) then
				self.QuestType = QUESTTYPE_PET
			end

			if (not okay) then
				self.Texture:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
				self.circleBorder:Show()
				self.circleBorder:SetTexture("Interface\\AddOns\\WorldQuestTracker\\media\\border_zone_whiteT")
				self.Texture:SetSize(16, 16)

				if (UpdateDebug) then print("NeedUpdate 4") end
				WorldQuestTracker.ScheduleZoneMapUpdate()
			end
		else
		--	local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex = WorldQuestTracker.GetQuest_Info(questID)
		--	print("no time left:", title, timeLeft)
			--self:Hide()
		end
	else
		if (UpdateDebug) then print("NeedUpdate 5") end
		WorldQuestTracker.ScheduleZoneMapUpdate()
	end
end

--agenda uma atualiza��o se algum dado de alguma quest n�o estiver dispon�vel ainda
local do_zonemap_update = function(self)
	if (WorldMapFrame:IsShown()) then
		WorldQuestTracker.UpdateZoneWidgets(self.IsForceUpdate)
	end
end

function WorldQuestTracker.ScheduleZoneMapUpdate(seconds, bForceUpdate)
	if (time() > WorldQuestTracker.MapChangedTime + 4) then
		if (not bForceUpdate) then
			return
		end
	end

	if (WorldQuestTracker.ScheduledZoneUpdate and not WorldQuestTracker.ScheduledZoneUpdate._cancelled) then
		--> if the previous schedule was a force update, make the new schedule be be a force update too
		if (WorldQuestTracker.ScheduledZoneUpdate.IsForceUpdate) then
			bForceUpdate = true
		end
		WorldQuestTracker.ScheduledZoneUpdate:Cancel()
	end

	WorldQuestTracker.ScheduledZoneUpdate = C_Timer.NewTimer(seconds or 1, do_zonemap_update)
	WorldQuestTracker.ScheduledZoneUpdate.IsForceUpdate = bForceUpdate
end




---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> zone summary  ~summaryframe

function WorldQuestTracker.RefreshZoneSummaryAlpha()
	local alpha = WorldQuestTracker.db.profile.world_summary_alpha
	WorldQuestTrackerZoneSummaryFrame:SetAlpha(alpha)
end

local ZoneSumaryFrame = CreateFrame("frame", "WorldQuestTrackerZoneSummaryFrame", worldFramePOIs, "BackdropTemplate")
ZoneSumaryFrame:SetPoint("topleft", worldFramePOIs, "topleft", 2, -380)
ZoneSumaryFrame:SetSize(200, 400)

ZoneSumaryFrame.WidgetHeight = 20
ZoneSumaryFrame.WidgetWidth = 140
ZoneSumaryFrame.WidgetBackdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16}
ZoneSumaryFrame.WidgetBackdropColor = {0, 0, 0, 0}
ZoneSumaryFrame.IconSize = 20
ZoneSumaryFrame.IconTextureSize = 16
ZoneSumaryFrame.IconTimeSize = 20

WorldQuestTracker.ZoneSumaryWidgets = {}

ZoneSumaryFrame.Header = CreateFrame("frame", "WorldQuestTrackerSummaryHeader", ZoneSumaryFrame, "ObjectiveTrackerContainerHeaderTemplate") --ObjectiveTrackerHeaderTemplate
ZoneSumaryFrame.Header:SetAlpha(0)
ZoneSumaryFrame.Header.Title = ZoneSumaryFrame.Header:CreateFontString(nil, "overlay", "GameFontNormal")
ZoneSumaryFrame.Header.Title:SetText("Quest Summary")
ZoneSumaryFrame.Header.Desc = ZoneSumaryFrame.Header:CreateFontString(nil, "overlay", "GameFontNormal")
ZoneSumaryFrame.Header.Desc:SetText("Click to Add to Tracker")
ZoneSumaryFrame.Header.Desc:SetAlpha(.7)
ZoneSumaryFrame.Header:SetPoint("bottomleft", ZoneSumaryFrame, "topleft", 20, 0)

DF:SetFontSize(ZoneSumaryFrame.Header.Title, 10)
DF:SetFontSize(ZoneSumaryFrame.Header.Desc, 8)

ZoneSumaryFrame.Header.Title:SetPoint("topleft", ZoneSumaryFrame.Header, "topleft", -9, -2)
ZoneSumaryFrame.Header.Desc:SetPoint("bottomleft", ZoneSumaryFrame.Header, "bottomleft", -9, 4)
ZoneSumaryFrame.Header.Background:SetWidth(150)
ZoneSumaryFrame.Header.Background:SetHeight(ZoneSumaryFrame.Header.Background:GetHeight()*0.45)
ZoneSumaryFrame.Header.Background:SetTexCoord(0, 1, 0, .45)
ZoneSumaryFrame.Header:Hide()
ZoneSumaryFrame.Header.BlackBackground = ZoneSumaryFrame.Header:CreateTexture(nil, "background")
ZoneSumaryFrame.Header.BlackBackground:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_summaryzoneT]])
ZoneSumaryFrame.Header.BlackBackground:SetAlpha(.8)
ZoneSumaryFrame.Header.BlackBackground:SetSize(150, ZoneSumaryFrame.Header.Background:GetHeight())
ZoneSumaryFrame.Header.BlackBackground:SetPoint("topleft", ZoneSumaryFrame.Header.Background, "topleft", 8, -14)
ZoneSumaryFrame.Header.BlackBackground:SetPoint("bottomright", ZoneSumaryFrame.Header.Background, "bottomright", 0, 0)

---@class wqt_zonesummarywidget : button
---@field Icon frame
---@field Text fontstring
---@field factionIcon texture
---@field timeLeftText fontstring
---@field BlackBackground texture
---@field Highlight texture

function WorldQuestTracker.GetOrCreateZoneSummaryWidget(index, parent, pool)
	if (not pool) then
		pool = WorldQuestTracker.ZoneSumaryWidgets
	end

	local widget = pool[index]
	if (widget) then
		return widget
	end

	parent = parent or ZoneSumaryFrame

	---@type wqt_zonesummarywidget
	local button = CreateFrame("button", "WorldQuestTrackerZoneSummaryFrame_Widget" .. index, parent, "BackdropTemplate")
	button:SetAlpha(WorldQuestTracker.db.profile.world_summary_alpha)

	pool[index] = button

	--button:SetPoint("bottomleft", ZoneSumaryFrame, "bottomleft", 0,((index-1)*(ZoneSumaryFrame.WidgetHeight + 1)) -2) --grow bottom to top
	button:SetPoint("topleft", parent, "topleft", 0,(((index-1) *(parent.WidgetHeight + 1)) -2) * -1) --grow top to bottom
	button:SetSize(parent.WidgetWidth, parent.WidgetHeight)
	button:SetFrameLevel(WorldQuestTracker.DefaultFrameLevel + 1)

	--create a square icon
	local squareIcon = WorldQuestTracker.CreateWorldMapWidget("ZoneWidget", index, button)
	squareIcon.IsWorldQuestButton = false
	--squareIcon.isWorldMapWidget = false --required when updating borders
	squareIcon.IsZoneSummaryQuestButton = true
	squareIcon:SetPoint("left", button, "left", 2, 0)
	squareIcon:SetSize(parent.IconSize, parent.IconSize)
	squareIcon:SetFrameLevel(WorldQuestTracker.DefaultFrameLevel + 2)
	squareIcon.IsZoneSummaryButton = true
	button.Icon = squareIcon

	local buttonIcon = squareIcon
	buttonIcon.commonBorder:SetPoint("bottomright", squareIcon, "bottomright")
	buttonIcon.rareBorder:SetPoint("bottomright", squareIcon, "bottomright")
	buttonIcon.epicBorder:SetPoint("bottomright", squareIcon, "bottomright")
	buttonIcon.invasionBorder:SetPoint("bottomright", squareIcon, "bottomright")
	buttonIcon.trackingBorder:SetPoint("bottomright", squareIcon, "bottomright", 6, -5)

	--background
	local art2 = button:CreateTexture(nil, "artwork")
	art2:SetAllPoints()
	art2:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_summaryzoneT]])
	art2:SetAlpha(0.834)
	button.BlackBackground = art2

	--hover over highlight
	local highlight = button:CreateTexture(nil, "highlight")
	highlight:SetAllPoints()
	highlight:SetTexture([[Interface\AddOns\WorldQuestTracker\media\border_pixel_whiteT.blp]])
	highlight:SetAlpha(.4)
	button.Highlight = highlight

	--resource amount text
	button.Text = DF:CreateLabel(button)
	button.Text:SetPoint("left", buttonIcon, "right", 3, 0)
	DF:SetFontSize(button.Text, 10)
	DF:SetFontColor(button.Text, "orange")

	--faction icon
	local factionIcon = button:CreateTexture(nil, "overlay")
	factionIcon:SetSize(18, 18)
	factionIcon:SetAlpha(.9314)
	factionIcon:SetTexCoord(.1, .9, .1, .9)
	factionIcon:SetPoint("left", buttonIcon, "right", 30, 0)
	button.factionIcon = factionIcon

	--time left text
	local timeLeftText = button:CreateFontString(nil, "overlay", "GameFontNormal")
	timeLeftText:SetPoint("left", buttonIcon, "right", 66, 0)
	button.timeLeftText = timeLeftText

	--transfers the criteria icon from the icon to the button line
	buttonIcon.criteriaIndicator:ClearAllPoints()
	buttonIcon.criteriaIndicator:SetPoint("left", buttonIcon, "right", 54, 0)
	buttonIcon.criteriaIndicator:SetSize(23*.4, 37*.4)

	--animations
	local on_enter_animation = DF:CreateAnimationHub(button, nil, function()
		--button:SetScale(1.1, 1.1)
	end)
	on_enter_animation.Step1 = DF:CreateAnimation(on_enter_animation, "Scale", 1, 0.05, 1, 1, 1.05, 1.05)
	on_enter_animation.Step2 = DF:CreateAnimation(on_enter_animation, "Scale", 2, 0.05, 1.05, 1.05, 1.0, 1.0)
	button.OnEnterAnimation = on_enter_animation

	local on_leave_animation = DF:CreateAnimationHub(button, nil, function()
		--button:SetScale(1.0, 1.0)
	end)
	on_leave_animation.Step1 = DF:CreateAnimation(on_leave_animation, "Scale", 1, 0.1, 1.1, 1.1, 1, 1)
	button.OnLeaveAnimation = on_leave_animation

	local mouseoverHighlight = WorldQuestTracker.AnchoringFrame:CreateTexture(nil, "overlay")
	mouseoverHighlight:SetTexture([[Interface\Worldmap\QuestPoiGlow]])
	mouseoverHighlight:SetSize(80, 80)
	mouseoverHighlight:SetBlendMode("ADD")

	--clicking is disable at the moment
	--[=[
	button:SetScript("OnClick", function(self)
		--WorldQuestTracker.AddQuestToTracker(self.Icon)
		for i = 1, #WorldQuestTracker.Cache_ShownWidgetsOnZoneMap do
			if (WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i].questID == self.Icon.questID) then
				WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i]:GetScript("OnClick")(WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i])
				break
			end
		end
		print("click")
	end)
	--]=]


	button:SetScript("OnEnter", function(self)
		WorldQuestTracker.HaveZoneSummaryHover = self
		self.Icon:GetScript("OnEnter")(self.Icon)
		WorldQuestTracker.HighlightOnZoneMap(self.Icon.questID, 1.2, "orange")

		--procura o icone da quest no mapa e indica ele
		--[=[
		for i = 1, #WorldQuestTracker.Cache_ShownWidgetsOnZoneMap do
			if (WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i].questID == self.Icon.questID) then
				mouseoverHighlight:SetPoint("center", WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i], "center")
				mouseoverHighlight:Show()
				break
			end
		end
		--]=]
	end)

	button:SetScript("OnLeave", function(self)
		self.Icon:GetScript("OnLeave")(self.Icon)
		WorldQuestTracker.HaveZoneSummaryHover = nil

		WorldQuestTracker.HideMapQuestHighlight()

		--mouseoverHighlight:Hide()
	end)

	--disable mouse click
	button:SetMouseClickEnabled(false)
	return button
end



function WorldQuestTracker.ClearZoneSummaryButtons()
	for _, button in ipairs(WorldQuestTracker.ZoneSumaryWidgets) do
		button:Hide()
	end
	WorldQuestTracker.QuestSummaryShown = true
	ZoneSumaryFrame.Header:Hide()
end

function WorldQuestTracker.SetupZoneSummaryButton(summaryWidget, zoneWidget)
	local Icon = summaryWidget.Icon

	Icon.mapID = zoneWidget.mapID
	Icon.questID = zoneWidget.questID
	Icon.numObjectives = zoneWidget.numObjectives

	--setup the world quest button within the summary line
	local widget = Icon
	local isCriteria, isNew, isUsingTracker, timeLeft, artifactPowerIcon = zoneWidget.isCriteria, false, false, zoneWidget.TimeLeft, WorldQuestTracker.MapData.ItemIcons["BFA_ARTIFACT"]
	local questID, numObjectives, mapID = zoneWidget.questID, zoneWidget.numObjectives, zoneWidget.mapID

	if (zoneWidget.isArtifact) then
		artifactPowerIcon = WorldQuestTracker.GetArtifactPowerIcon(zoneWidget.isArtifact, true, questID)
	end

	widget.questData = zoneWidget.questData

	--update the quest icon
	local okay, gold, resource, apower = WorldQuestTracker.UpdateWorldWidget(widget, widget.questData, isUsingTracker)
	widget.texture:SetTexCoord(.1, .9, .1, .9)
	widget:SetAlpha(WorldQuestTracker.db.profile.world_summary_alpha)
	zoneWidget.IconText = widget.IconText

	widget.background:Hide()
	widget.factionBorder:Hide()
	widget.commonBorder:Hide()
	widget.amountText:Hide()
	widget.amountBackground:Hide()
	widget.timeBlipRed:Hide()
	widget.timeBlipOrange:Hide()
	widget.timeBlipYellow:Hide()
	widget.timeBlipGreen:Hide()
	widget.trackingGlowBorder:Hide()

	--set the amount text
	if (okay) then
		summaryWidget.Text:SetText(type(zoneWidget.IconText) == "number" and floor(zoneWidget.IconText) or zoneWidget.IconText)
	else
		summaryWidget.Text:SetText("")
	end

	if (widget.criteriaIndicator:IsShown()) then
		summaryWidget.timeLeftText:SetPoint("left", widget, "right", 66, 0)
		summaryWidget:SetWidth(ZoneSumaryFrame.WidgetWidth)
	else
		summaryWidget.timeLeftText:SetPoint("left", widget, "right", 54, 0)
		summaryWidget:SetWidth(ZoneSumaryFrame.WidgetWidth - 12)
	end

	--set the time left
	local timePriority = WorldQuestTracker.db.profile.sort_time_priority
	local alphaAmount = 0.923

	if (timePriority and timePriority > 0) then
		if (timePriority < 4) then
			timePriority = 4
		end
		timePriority = timePriority * 60 --4 8 12 16 24

		if (timePriority) then
			if (timeLeft <= timePriority) then
				DF:SetFontColor(summaryWidget.timeLeftText, "yellow")
				summaryWidget:SetAlpha(alphaAmount)
				summaryWidget.timeLeftText:SetAlpha(1)
			else
				DF:SetFontColor(summaryWidget.timeLeftText, "white")
				summaryWidget.timeLeftText:SetAlpha(0.8)

				if (WorldQuestTracker.db.profile.alpha_time_priority) then
					summaryWidget:SetAlpha(ALPHA_BLEND_AMOUNT - 0.50) --making quests be faded out by default
				else
					summaryWidget:SetAlpha(alphaAmount)
				end
			end
		else
			DF:SetFontColor(summaryWidget.timeLeftText, "white")
			summaryWidget.timeLeftText:SetAlpha(1)
		end
	else
		DF:SetFontColor(summaryWidget.timeLeftText, "white")
		summaryWidget.timeLeftText:SetAlpha(1)
		summaryWidget:SetAlpha(alphaAmount)
	end

	if (zoneWidget.worldQuestType == LE_QUEST_TAG_TYPE_FACTION_ASSAULT) then
		summaryWidget:SetAlpha(1)
	end

	summaryWidget.timeLeftText:SetText((timeLeft > 1440 and floor(timeLeft/1440) .. "d") or (timeLeft > 60 and floor(timeLeft/60) .. "h") or (timeLeft .. "m"))
	summaryWidget.timeLeftText:SetJustifyH("center")
	summaryWidget.timeLeftText:Show()

	local factionID = widget.FactionID
	if (factionID) then
		local factionTexture = WorldQuestTracker.MapData.FactionIcons[factionID]
		if (factionTexture) then
			--check if this quest is realy giving reputation
			local bAwardReputation = C_QuestLog.DoesQuestAwardReputationWithFaction(questID or 0, factionID or 0)
			if (bAwardReputation) then
				summaryWidget.factionIcon:SetTexture(factionTexture)
			end
		else
			summaryWidget.factionIcon:SetTexture("")
		end
	else
		summaryWidget.factionIcon:SetTexture("")
	end

	summaryWidget:Show()
end

-- ~summary

function WorldQuestTracker.UpdateZoneSummaryToggleButton(canShow)
	if (not WorldQuestTracker.ZoneSummaryToogleButton) then
		local button = CreateFrame("button", nil, ZoneSumaryFrame, "BackdropTemplate")
		button:SetSize(12, 12)
		button:SetAlpha(.60)
		button:SetPoint("bottomleft", ZoneSumaryFrame, "topleft", 2, 2)

		button:SetScript("OnClick", function(self)
			WorldQuestTracker.db.profile.quest_summary_minimized = not WorldQuestTracker.db.profile.quest_summary_minimized
			WorldQuestTracker.UpdateZoneSummaryFrame()
		end)

		WorldQuestTracker.ZoneSummaryToogleButton = button
	end

	local button = WorldQuestTracker.ZoneSummaryToogleButton

	--check if can show the minimize button
	local canShowButton = WorldQuestTracker.db.profile.show_summary_minimize_button
	if (not canShowButton) then
		button:Hide()
		return
	else
		button:Show()
	end

	local isMinimized = WorldQuestTracker.db.profile.quest_summary_minimized

	--change the appearance of the minimize button
	if (not isMinimized) then
		--is showing the summary, not minimized
		button:SetNormalTexture([[Interface\BUTTONS\UI-SpellbookIcon-PrevPage-Up]])
		button:SetPushedTexture([[Interface\BUTTONS\UI-SpellbookIcon-PrevPage-Down]])
		button:SetHighlightTexture([[Interface\BUTTONS\UI-Panel-MinimizeButton-Highlight]])
	else
		--the summary is minimized
		button:SetNormalTexture([[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Up]])
		button:SetPushedTexture([[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Down]])
		button:SetHighlightTexture([[Interface\BUTTONS\UI-Panel-MinimizeButton-Highlight]])
	end

	local normalTexture = button:GetNormalTexture()
	normalTexture:SetTexCoord(.25, .75, .25, .75)
	local pushedTexture = button:GetPushedTexture()
	pushedTexture:SetTexCoord(.25, .75, .28, .75)

	local isZoneMap = WorldQuestTrackerAddon.GetCurrentZoneType() == "zone"

	if (not canShow) then
		button:Hide()
	elseif (canShow and not isZoneMap) then
		button:Hide()
	else
		button:Show()
	end
end

function WorldQuestTracker.CanShowZoneSummaryFrame()
	local canShow = WorldQuestTracker.db.profile.use_quest_summary and WorldQuestTracker.ZoneHaveWorldQuest() and(WorldMapFrame.isMaximized or true)
	if (canShow) then
		if (WorldMapFrame.isMaximized) then
			ZoneSumaryFrame:SetPoint("topleft", worldFramePOIs, "topleft", 2, -380) --380
		else
			ZoneSumaryFrame:SetPoint("topleft", worldFramePOIs, "topleft", 2, -105) --380
		end
		ZoneSumaryFrame:SetScale(WorldQuestTracker.db.profile.zone_map_config.quest_summary_scale)
	end

	WorldQuestTracker.UpdateZoneSummaryToggleButton(canShow)
	return canShow
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

	table.sort(WorldQuestTracker.Cache_ShownWidgetsOnZoneMap, function(t1, t2)
		return t1.Order > t2.Order
	end)

	local lastWidget
	local isSummaryMinimized = WorldQuestTracker.db.profile.quest_summary_minimized

	if (not isSummaryMinimized) then
		for i = 1, #WorldQuestTracker.Cache_ShownWidgetsOnZoneMap do
			local zoneWidget = WorldQuestTracker.Cache_ShownWidgetsOnZoneMap[i]
			local summaryWidget = WorldQuestTracker.GetOrCreateZoneSummaryWidget(index)

			summaryWidget._Twin = zoneWidget
			WorldQuestTracker.SetupZoneSummaryButton(summaryWidget, zoneWidget)
			lastWidget = summaryWidget

			index = index + 1
		end
	end

	--attach the header to the last widget
	if (lastWidget) then
		ZoneSumaryFrame.Header:Show()
		--ZoneSumaryFrame.Header:SetPoint("bottomleft", LastWidget, "topleft", 20, 0)
	end

	WorldQuestTracker.QuestSummaryShown = true
	WorldQuestTracker.RefreshZoneSummaryAlpha()
end




-- ~bounty
local bountyBoard = WorldQuestTracker.GetOverlay("IsWorldQuestCriteriaForSelectedBounty")
if (bountyBoard) then
	hooksecurefunc(bountyBoard, "OnTabClick", function(self, mapID)
		for i = 1, #ZoneWidgetPool do
			local widgetButton = ZoneWidgetPool [i]
			widgetButton.CriteriaAnimation.LastPlay = 0
		end

		if (WorldQuestTrackerAddon.GetCurrentZoneType() == "zone") then
			WorldQuestTracker.UpdateZoneWidgets(true)
		end
	end)

	local UpdateBountyBoard = function(self, mapID)

		do return end

		if (WorldMapFrame.mapID == 905) then --argus
			--the bounty board in argus is above the world quest tracker widgets
			C_Timer.After(0.5, function()
				bountyBoard:ClearAllPoints()
				bountyBoard:SetPoint("bottomright", WorldQuestTrackerToggleQuestsSummaryButton, "bottomright", 0, 45)
			end)
		end

		self:SetAlpha(WQT_WORLDWIDGET_ALPHA + 0.02) -- + 0.06

		local tabs = self.bountyTabPool

		for bountyIndex, bounty in ipairs(self.bounties or {}) do
			local bountyButton
			for button, _ in pairs(tabs.activeObjects) do
				if (button.bountyIndex == bountyIndex) then
					bountyButton = button
					break
				end
			end

			--create wtq amount indicator
			if (bountyButton) then
				if (not bountyButton.objectiveCompletedText) then
					bountyButton.objectiveCompletedText = bountyButton:CreateFontString(nil, "overlay", "GameFontNormal")
					bountyButton.objectiveCompletedText:SetPoint("bottom", bountyButton, "top", 1, 0)
					bountyButton.objectiveCompletedBackground = bountyButton:CreateTexture(nil, "background")
					bountyButton.objectiveCompletedBackground:SetPoint("bottom", bountyButton, "top", 0, -1)
					bountyButton.objectiveCompletedBackground:SetTexture([[Interface\AddOns\WorldQuestTracker\media\background_blackgradientT]])

					--increasing the height for the background to also fill the time left text
					bountyButton.objectiveCompletedBackground:SetSize(42, 26) --default height: 12

					--show the time left for the bounty
					bountyButton.timeLeftText = bountyButton:CreateFontString(nil, "overlay", "GameFontNormal")
					bountyButton.timeLeftText:SetPoint("bottom", bountyButton.objectiveCompletedText, "top", 0, 2)
					bountyButton.timeLeftText.DefaultColor = {bountyButton.timeLeftText:GetTextColor()}

					bountyButton.objectiveCompletedText:Hide()
					bountyButton.objectiveCompletedBackground:Hide()

					local animationHub = WorldQuestTracker:CreateAnimationHub(bountyButton, function() bountyButton.objectiveCompletedText:Show(); bountyButton.objectiveCompletedBackground:Show() end)
					local a = WorldQuestTracker:CreateAnimation(animationHub, "ALPHA", 1, .4, 0, 1)
					a:SetTarget(bountyButton.objectiveCompletedText)
					local b = WorldQuestTracker:CreateAnimation(animationHub, "ALPHA", 1, .4, 0, 0.4)
					b:SetTarget(bountyButton.objectiveCompletedBackground)
					bountyButton.objectiveCompletedAnimation = animationHub

					--create reward preview
					local rewardPreview = WorldQuestTracker:CreateImage(bountyButton, "", 16, 16, "overlay")
					rewardPreview:SetPoint("bottomright", bountyButton, "bottomright", -4, 4)
					rewardPreview:SetMask([[Interface\CHARACTERFRAME\TempPortraitAlphaMaskSmall]])
					local rewardPreviewBorder = WorldQuestTracker:CreateImage(bountyButton, [[Interface\AddOns\WorldQuestTracker\media\border_zone_browT]], 22, 22, "overlay")
					rewardPreviewBorder:SetVertexColor(.9, .9, .8)
					rewardPreviewBorder:SetPoint("center", rewardPreview, "center")

					--artwork is shared with the blizzard art
					rewardPreview:SetDrawLayer("overlay", 4)
					rewardPreviewBorder:SetDrawLayer("overlay", 5)
					--blend
					--rewardPreview:SetAlpha(ALPHA_BLEND_AMOUNT)
					rewardPreviewBorder:SetAlpha(ALPHA_BLEND_AMOUNT)

					bountyButton.RewardPreview = rewardPreview
					bountyButton.rewardPreviewBorder = rewardPreviewBorder
				end

				local numCompleted, numTotal = self:CalculateBountySubObjectives(bounty)

				if (WorldQuestTracker.db.profile.show_emissary_info) then
					if (numCompleted) then
						bountyButton.objectiveCompletedText:SetText(numCompleted .. "/" .. numTotal)
						bountyButton.objectiveCompletedText:SetAlpha(.92)
						bountyButton.objectiveCompletedBackground:SetAlpha(.4)
						bountyButton.RewardPreview:SetAlpha(.96)
						bountyButton.rewardPreviewBorder:SetAlpha(.96)

						if (not bountyButton.objectiveCompletedText:IsShown()) then
							bountyButton.objectiveCompletedAnimation:Play()
						end
					else
						bountyButton.objectiveCompletedText:SetText("")
						bountyButton.objectiveCompletedBackground:SetAlpha(0)
						bountyButton.RewardPreview:SetAlpha(0)
						bountyButton.rewardPreviewBorder:SetAlpha(0)
					end
				else
					bountyButton.objectiveCompletedText:SetText("")
					bountyButton.objectiveCompletedBackground:SetAlpha(0)
					bountyButton.RewardPreview:SetAlpha(0)
					bountyButton.rewardPreviewBorder:SetAlpha(0)
				end

				local bountyQuestID = bounty.questID
				if (bountyQuestID and HaveQuestData(bountyQuestID) and WorldQuestTracker.db.profile.show_emissary_info) then
					local questIndex = C_QuestLog.GetLogIndexForQuestID(bountyQuestID)
					local questInfo = C_QuestLog.GetInfo(questIndex)
					local questID = questInfo.questID

					--local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = C_QuestLog.GetTitleForLogIndex(questIndex)
					--Details:Dump(questInfo)
					local timeLeftMinutes = C_TaskQuest.GetQuestTimeLeftMinutes(questID)


					if (timeLeftMinutes) then
						local inHours = floor(timeLeftMinutes/60)
						bountyButton.timeLeftText:SetText(inHours > 23 and floor(inHours / 24) .. "d" or inHours .. "h")
						if (inHours < 12) then
							bountyButton.timeLeftText:SetTextColor(1, .2, .1)
						elseif (inHours < 24) then
							bountyButton.timeLeftText:SetTextColor(1, .5, .1)
						else
							bountyButton.timeLeftText:SetTextColor(unpack(bountyButton.timeLeftText.DefaultColor))
						end
					else
						bountyButton.timeLeftText:SetText("?")
					end

					if (not HaveQuestRewardData(bountyQuestID)) then
						C_TaskQuest.RequestPreloadRewardData(bountyQuestID)
						WorldQuestTracker.ForceRefreshBountyBoard()
					else

						--the current priority order is: item > currency with biggest amount
						--all emisary quests gives gold and artifact power, some gives 400 gold others give 2000
						--same thing for artifact power

						local itemName, itemTexture, quantity, quality, isUsable, itemID = GetQuestLogRewardInfo(1, bountyQuestID)
						if (itemName) then
							bountyButton.RewardPreview.texture = itemTexture
							bountyButton.Icon:SetTexture(bounty.icon)
						else
							--> currencies
							local currencies = {}

							local numQuestCurrencies = GetNumQuestLogRewardCurrencies(bountyQuestID)
							if (numQuestCurrencies and numQuestCurrencies > 0) then
								local name, texture, numItems, currencyID = GetQuestLogRewardCurrencyInfo(1, bountyQuestID)
								if (name and texture) then
									tinsert(currencies, {name, texture, numItems, 0x1}) --0x1 means is a currency
								end
							end

							local goldReward = WorldQuestTracker.GetQuestReward_Gold(bountyQuestID)
							if (goldReward) then
								local texture, coords = WorldQuestTracker.GetGoldIcon()
								tinsert(currencies, {"gold", texture, goldReward, 0x2}) --0x2 means is gold
							end

							if (currencies [1]) then
								table.sort(currencies, DF.SortOrder3)
								bountyButton.RewardPreview.texture = currencies [1] [2]
								bountyButton.Icon:SetTexture(bounty.icon)
							end
						end

					end
				else
					bountyButton.timeLeftText:SetText("")
					--bountyButton.Icon:SetTexture(nil)
				end

				bountyButton.lastUpdateByWQT = GetTime()
			end
		end

		for button, _ in pairs(tabs.activeObjects) do
			--> check if the button got an update on this execution
			if (not button.lastUpdateByWQT or button.lastUpdateByWQT+1 < GetTime()) then
				--> check if the button was been customized by WQT
				if (button.objectiveCompletedBackground) then
					button.objectiveCompletedText:SetText("")
					button.objectiveCompletedBackground:SetAlpha(0)
				end
			end
		end

	end

	hooksecurefunc(bountyBoard, "RefreshBountyTabs", function(self, mapID)
		UpdateBountyBoard(self, mapID)
		--don't remmember why I added a delay, using a direct call now
		--C_Timer.After(0.1, function() UpdateBountyBoard(self, mapID) end)
	end)

	function WorldQuestTracker.ForceRefreshBountyBoard()
		if (WorldQuestTracker.RefreshBountyBoardTimer and not WorldQuestTracker.RefreshBountyBoardTimer._cancelled) then
			WorldQuestTracker.RefreshBountyBoardTimer:Cancel()
		end

		local bountyBoard = WorldQuestTracker.GetOverlay("IsWorldQuestCriteriaForSelectedBounty")
		if (bountyBoard) then
			WorldQuestTracker.RefreshBountyBoardTimer = C_Timer.NewTimer(1, function() UpdateBountyBoard(bountyBoard, WorldMapFrame.mapID) end)
		end
	end
end

local questTracker_EnumerationXOffset = 1
local zoneMap_EnumerationXOffset = 1

function WorldQuestTracker.UpdateQuestIdentification(self, event)
	if (not WorldQuestTracker.db.profile.numerate_quests) then
		return
	end

	local map = WorldQuestTrackerDataProvider:GetMap()

	do
		--world map quest log, reset widgets
		local questContents = WorldMapFrame.QuestLog.QuestsFrame.Contents
		local children = {questContents:GetChildren()}
		for i = 1, #children do
			local child = children[i]
			if (child.Display) then
				child.Display.Icon:Show()
				if (child.Display.WQTText) then
					child.Display.WQTText:Hide()
				end
			end
		end
	end

	local questIndex = 1

	--world map quest pins, reset widgets and build a table with the quest pins
	local questsOnMapFound = {}
	for pin in map:EnumeratePinsByTemplate("QuestPinTemplate") do
		local questId = pin:GetQuestID()
		if (questId) then
			if (pin.Display) then
				pin.Display.Icon:Show()
				if (pin.Display.WQTText) then
					pin.Display.WQTText:Hide()
				end
			end

			if (pin.style ~= POIButtonUtil.Style.QuestComplete) then
				--get the quest name
				local questTitle = C_QuestLog.GetTitleForQuestID(questId)
				questsOnMapFound[#questsOnMapFound+1] = {questId = questId, pin = pin, questName = questTitle}
			end
		end
	end

	table.sort(questsOnMapFound, function(t1, t2) return t1.questName < t2.questName end)

	local bFoundQuestsOnMap = #questsOnMapFound > 0

	local questsOnTrackerFound = {}
	local questsOnTrackerQuestId_to_Info = {}

    for moduleFrame in pairs (ObjectiveTrackerManager.moduleToContainerMap) do
		if (type(moduleFrame) == "table" and moduleFrame.GetObjectType and moduleFrame:GetObjectType() == "Frame" and moduleFrame:IsShown()) then
			local contentsFrame = moduleFrame.ContentsFrame
        	local children = {contentsFrame:GetChildren()}

			local bHasOneChildren = #children == 1
			local bModuleIsCampaing = moduleFrame == CampaignQuestObjectiveTracker

			for i = 1, #children do
				local child = children[i]
				local poiButton = child.poiButton

				--reset the wqt text
				if (poiButton and poiButton.Display) then
					poiButton.Display.Icon:Show()
					if (poiButton.Display.WQTText) then
						poiButton.Display.WQTText:Hide()
					end
				end

				if (poiButton and child.poiQuestID and child.poiQuestID > 0 and not child.poiIsComplete) then
					local questId = child.poiQuestID
					local questTitle = C_QuestLog.GetTitleForQuestID(questId)

					questsOnTrackerFound[#questsOnTrackerFound+1] = {questId = questId, questName = questTitle, child = child, poiButton = child.poiButton}
					questsOnTrackerQuestId_to_Info[questId] = questsOnTrackerFound[#questsOnTrackerFound]

					if (bModuleIsCampaing and bHasOneChildren) then
						local playerLevel = UnitLevel("player")
						if (playerLevel < 80) then
							QuestUtil.TrackWorldQuest(questId, Enum.QuestWatchType.Automatic)
							C_SuperTrack.SetSuperTrackedQuestID(questId)
						end
					end

					if (not poiButton) then
						local parent = WorldMapFrame.QuestLog.QuestsFrame.Contents
						local parentChilds = {parent:GetChildren()}
						for j = 1, #parentChilds do
							if (parentChilds[j].shouldShowGlow and parentChilds[j].questID == child.questID) then
								poiButton = parentChilds[j]
							end
						end
					end

					if (poiButton) then
						poiButton.Display.Icon:Show()

						if (not poiButton.Display.WQTText) then
							poiButton.Display.WQTText = poiButton.Display:CreateFontString("$parentQuestIndex", "overlay", "GameFontNormal")
							DetailsFramework:SetFontOutline(poiButton.Display.WQTText, "OUTLINE")
							poiButton.Display.WQTText:ClearAllPoints()
							poiButton.Display.WQTText:SetPoint("center", poiButton.Display, "center", 1, 0) --creating on quest tracker at the right side of the screen
							poiButton.Display.WQTText:Hide()
						else
							poiButton.Display.WQTText:Hide()
						end

						if (not bFoundQuestsOnMap and not child.poiIsComplete) then
							poiButton.Display.Icon:Hide()
							poiButton.Display.WQTText:Show()
							poiButton.Display.WQTText:SetText(questIndex)
							questIndex = questIndex + 1
						end
					end
				end
			end
		end
    end

	for i = 1, #questsOnMapFound do
		local questId = questsOnMapFound[i].questId
		local pin = questsOnMapFound[i].pin

		--world map
		if (not pin.Display.WQTText) then
			pin.Display.WQTText = pin.Display:CreateFontString("$parentQuestIndex", "overlay", "GameFontNormal")
			DetailsFramework:SetFontOutline(pin.Display.WQTText, "OUTLINE")
			pin.Display.WQTText:ClearAllPoints()
			pin.Display.WQTText:SetPoint("center", pin.Display, "center", zoneMap_EnumerationXOffset, 0)
		end

		pin.Display.Icon:Hide()
		pin.Display.WQTText:SetText(i)
		pin.Display.WQTText:Show()

		local trackerFrame = questsOnTrackerQuestId_to_Info[questId]
		if (trackerFrame) then
			local poiButton = trackerFrame.poiButton
			if (poiButton) then
				--quest tracker
				if (not poiButton.Display.WQTText) then
					poiButton.Display.WQTText = poiButton.Display:CreateFontString("$parentQuestIndex", "overlay", "GameFontNormal")
					DetailsFramework:SetFontOutline(poiButton.Display.WQTText, "OUTLINE")
					poiButton.Display.WQTText:ClearAllPoints()
					poiButton.Display.WQTText:SetPoint("center", poiButton.Display, "center", questTracker_EnumerationXOffset, 0)
				end
				poiButton.Display.Icon:Hide()
				poiButton.Display.WQTText:SetText(i)
				poiButton.Display.WQTText:Show()
			end
		end

		--quest log on map
		local questContents = WorldMapFrame.QuestLog.QuestsFrame.Contents
		local button = questContents:FindButtonByQuestID(questId)

		if (button) then
			if (not button.Display.WQTText) then
				button.Display.WQTText = button.Display:CreateFontString("$parentQuestIndex", "overlay", "GameFontNormal")
				DetailsFramework:SetFontOutline(button.Display.WQTText, "OUTLINE")
				button.Display.WQTText:ClearAllPoints()
				button.Display.WQTText:SetPoint("center", button.Display, "center", 1, 0)
			end

			button.Display.Icon:Hide()
			button.Display.WQTText:SetText(i)
			button.Display.WQTText:Show()
		end

		questIndex = questIndex + 1
	end
end

local c = CreateFrame("frame")
c:RegisterEvent("QUEST_LOG_UPDATE")
c:SetScript("OnEvent", function()
	C_Timer.After(0, WorldQuestTracker.UpdateQuestIdentification)
end)

local d = CreateFrame("frame")
d:RegisterEvent("CINEMATIC_START")
d:SetScript("OnEvent", function()
	if (WorldQuestTracker.db.profile.speed_run.cancel_cinematic) then
		CinematicFrame_CancelCinematic()
		C_Timer.After(1, function()
			print("Cinematic Skipped")
		end)
	end
end)

QuestFrame:HookScript("OnShow", function()
	local bAutoComplete = WorldQuestTracker.db.profile.speed_run.auto_complete
	if (not bAutoComplete) then
		return
	end

	local progressPanel = QuestFrameProgressPanel
	local completeButton = QuestFrameCompleteButton

	if (completeButton.Text:GetText() == CONTINUE) then
		completeButton:Click()
	end
end)

QuestFrameRewardPanel:HookScript("OnShow", function()
	local bAutoComplete = WorldQuestTracker.db.profile.speed_run.auto_complete
	if (not bAutoComplete) then
		return
	end

	local completeButton = QuestFrameCompleteQuestButton
	if (completeButton:IsShown() and completeButton.Text:GetText() == COMPLETE_QUEST) then
		--check for rewards
		if (QuestInfoRewardsFrame and QuestInfoRewardsFrame:IsShown()) then
			if (QuestInfoRewardsFrameQuestInfoItem1 and QuestInfoRewardsFrameQuestInfoItem1:IsShown()) then
				if (QuestInfoRewardsFrameQuestInfoItem2 and QuestInfoRewardsFrameQuestInfoItem2:IsShown()) then
					QuestInfoRewardsFrameQuestInfoItem1:Click()
				end
			end
		end

		completeButton:Click()
	end
end)

QuestFrameDetailPanel:HookScript("OnShow", function()
	local bAutoAccept = WorldQuestTracker.db.profile.speed_run.auto_accept
	if (not bAutoAccept) then
		return
	end

	local questAcceptButton = QuestFrameAcceptButton
	if (questAcceptButton:IsShown() and questAcceptButton.Text:GetText() == ACCEPT) then
		questAcceptButton:Click()
	end
end)

local npcOptionsCache = {}

local findSkipConversationOption = function(children)
	for i = 1, #children do
		local child = children[i]
		if (child.IsObjectType and child:IsObjectType("Button") and child:IsShown() and child:IsEnabled()) then
			if (child.GetData) then
				local data = child:GetData()
				if (data and type(data) == "table" and data.info and data.info.gossipOptionID) then
					local name = data.info.name
					if (name and type(name) == "string" and name:len() > 2) then
						if (name:find("<") and name:find(">") and name:find("%|c") and name:find("^%|cFF")) then
							child:Click()
							return true
						end
					end
				end
			end
		end
	end
end

--a frame with multiple quests to accept
GossipFrame:HookScript("OnShow", function()
	local bAutoAccept = WorldQuestTracker.db.profile.speed_run.auto_accept
	local bAutoComplete = WorldQuestTracker.db.profile.speed_run.auto_complete

	C_Timer.After(0, function()
		local greetingsFrame = GossipFrame.GreetingPanel
		local scrollBox = GossipFrame.GreetingPanel.ScrollBox
		local scrollTarget = GossipFrame.GreetingPanel.ScrollBox.ScrollTarget
		local children = {scrollTarget:GetChildren()}

		if (bAutoComplete) then
			if (findSkipConversationOption(children)) then
				return
			end
		end

		for i = 1, #children do
			local child = children[i]
			if (child.IsObjectType and child:IsObjectType("Button") and child:IsShown() and child:IsEnabled()) then
				if (child.GetData) then
					local data = child:GetData()
					if (data and type(data) == "table" and data.info and data.info.questID and child.Icon:GetTexture() ~= 5666025) then
						if (data.availableQuestButton and data.info.isComplete) then
							--print("data.availableQuestButton and data.info.questID and data.info.isComplete")

						elseif (data.availableQuestButton and not data.info.isComplete and child.Icon:GetTexture() == 3595324) then
							if (bAutoAccept) then
								--print("auto accepted quest")
								data.availableQuestButton:Click()
							end

						elseif (data.activeQuestButton and not data.info.isComplete) then
							--print("data.activeQuestButton and not data.info.isComplete")
							--data.activeQuestButton:Click()

						elseif (data.activeQuestButton and data.info.isComplete) then
							if (bAutoComplete) then
								--print("auto completed quest")
								data.activeQuestButton:Click()
							end
						end

					elseif (data and type(data) == "table" and data.info and (data.info.icon == 132053 or data.info.icon == 132060)) then
						local children = {child:GetRegions()}
						for j = 1, #children do
							local childRegion = children[j]
							if (childRegion:GetObjectType() == "FontString") then
								local text = childRegion:GetText()
								if (text:find("%(") and text:find("%)") and text:find("%|c")) then
									if (bAutoAccept) then
										if (not npcOptionsCache[text]) then
											child:Click()
											npcOptionsCache[text] = true
											return
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end)
end)