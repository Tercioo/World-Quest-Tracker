
local addonId, wqtInternal = ...
local detailsFramework = DetailsFramework
local _
local WorldQuestTracker = WorldQuestTrackerAddon

--localization
local L = detailsFramework.Language.GetLanguageTable(addonId)

local thisTooltip = CreateFrame("GameTooltip", "WorldQuestTrackerGameTooltip", UIParent, "GameTooltipTemplate")
--replicating the keys and values from the xml
thisTooltip.supportsItemComparison = true
thisTooltip.ItemTooltip = CreateFrame("GameTooltip", "WorldQuestTrackerGameTooltipItemTooltip", thisTooltip, "InternalEmbeddedItemTooltipTemplate")
thisTooltip.ItemTooltip:SetSize(100, 100)
thisTooltip.ItemTooltip:SetPoint("BOTTOMLEFT", thisTooltip, "BOTTOMLEFT", 10, 13)
thisTooltip.ItemTooltip.yspacing = 13

Mixin(thisTooltip, GameTooltipDataMixin)
thisTooltip:OnLoad()
thisTooltip:SetScript("OnShow", thisTooltip.OnShow)
thisTooltip:SetScript("OnUpdate", thisTooltip.OnUpdate)


--thisTooltip.ItemTooltip <- "InternalEmbeddedItemTooltipTemplate"
--thisTooltip.ItemTooltip = CreateFrame("GameTooltip", "WorldQuestTrackerGameTooltipItemTooltip", thisTooltip, "EmbeddedItemTooltip")
--thisTooltip.ItemTooltip:SetOwner(thisTooltip, "ANCHOR_NONE")
--thisTooltip:SetScale(0.7)

local WQT_ShoppingTooltip1 = CreateFrame("GameTooltip", "WQT_ShoppingTooltip1", UIParent, "ShoppingTooltipTemplate")
WQT_ShoppingTooltip1:SetClampedToScreen(true)
WQT_ShoppingTooltip1:SetFrameStrata("TOOLTIP")
WQT_ShoppingTooltip1:Hide()

local WQT_ShoppingTooltip2 = CreateFrame("GameTooltip", "WQT_ShoppingTooltip2", UIParent, "ShoppingTooltipTemplate")
WQT_ShoppingTooltip2:SetClampedToScreen(true)
WQT_ShoppingTooltip2:SetFrameStrata("TOOLTIP")
WQT_ShoppingTooltip2:Hide()

thisTooltip.ItemTooltip.Tooltip.shoppingTooltips = {WQT_ShoppingTooltip1, WQT_ShoppingTooltip2}
thisTooltip.ItemTooltip.Tooltip.shoppingTooltips = { ItemRefShoppingTooltip1, ItemRefShoppingTooltip2 };
--thisTooltip.Tooltip.shoppingTooltips = { WQT_ShoppingTooltip1, WQT_ShoppingTooltip2 };
thisTooltip.shoppingTooltips = { ItemRefShoppingTooltip1, ItemRefShoppingTooltip2 };
--local gc = GameCooltip

local getBestQualityItemRewardIndex = function(questID)
	local index, rewardType
	local bestQuality = -1
	local numQuestRewards = GetNumQuestLogRewards(questID) --safe
	for i = 1, numQuestRewards do
		local itemName, itemTexture, quantity, quality, isUsable, itemID = GetQuestLogRewardInfo(i, questID) --safe
		if quality > bestQuality then
			index = i
			bestQuality = quality
			rewardType = "reward"
		end
	end
	local numQuestChoices = GetNumQuestLogChoices(questID)
	for i = 1, numQuestChoices do
		local itemName, itemTexture, quantity, quality, isUsable, itemID = GetQuestLogChoiceInfo(i, questID)
		if quality > bestQuality then
			index = i
			bestQuality = quality
			rewardType = "choice"
		end
	end
	return index, rewardType
end

local rewardFuncFromScratch = function(tooltip, questID, style)
	local isWarModeDesired = C_PvP.IsWarModeDesired()
	local questHasWarModeBonus = C_QuestLog.QuestCanHaveWarModeBonus(questID)
	local hasAnySingleLineRewards = false

	local numQuestRewards = GetNumQuestLogRewards(questID) --safe
	if numQuestRewards > 0 then --safe
		--[[
			id 255906
			hyperlink "[Galactic Warmonger's Chestguard]"
		]]
		--dumpt(C_TooltipInfo.GetQuestLogItem("reward", 1, questID))
		--[[
["dataInstanceID"] = 14313,
["type"] = 0,
["isAzeriteEmpoweredItem"] = false,
["isAzeriteItem"] = false,
["id"] = 255906,
["hyperlink"] = "[Galactic Warmonger's Chestguard]",
["isCorruptedItem"] = false,
["lines"] =  {
   [1] =  {
      ["leftColor"] =  {
         ["b"] = 0.8666667342186,
         ["GetHSL"] = function,
         ["g"] = 0.43921571969986,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 22,
      ["leftText"] = "Galactic Warmonger's Chestguard",
      ["quality"] = 3,
   },
   [2] =  {
      ["leftColor"] =  {
         ["b"] = 1,
         ["GetHSL"] = function,
         ["g"] = 1,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 35,
      ["leftText"] = "Rare",
   },
   [3] =  {
      ["leftColor"] =  {
         ["b"] = 0,
         ["GetHSL"] = function,
         ["g"] = 0.82352948188782,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 31,
      ["itemLevel"] = 224,
      ["leftText"] = "Item Level 224",
   },
   [4] =  {
      ["leftText"] = "Upgrade Level: Adventurer 2/6",
      ["maxLevel"] = 6,
      ["currentLevel"] = 2,
      ["leftColor"] =  {
         ["b"] = 0,
         ["GetHSL"] = function,
         ["g"] = 0.82352948188782,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["trackStringID"] = 971,
      ["type"] = 32,
   },
   [5] =  {
      ["leftColor"] =  {
         ["b"] = 1,
         ["GetHSL"] = function,
         ["g"] = 1,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 20,
      ["bonding"] = 6,
      ["leftText"] = "Binds when picked up",
   },
   [6] =  {
      ["rightText"] = "Mail",
      ["leftText"] = "Chest",
      ["isValidItemType"] = true,
      ["leftColor"] =  {
         ["b"] = 1,
         ["GetHSL"] = function,
         ["g"] = 1,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["isValidInvSlot"] = true,
      ["type"] = 21,
      ["rightColor"] =  {
         ["b"] = 1,
         ["GetHSL"] = function,
         ["g"] = 1,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
   },
   [7] =  {
      ["leftColor"] =  {
         ["b"] = 1,
         ["GetHSL"] = function,
         ["g"] = 1,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 0,
      ["leftText"] = "144 Armor",
   },
   [8] =  {
      ["leftColor"] =  {
         ["b"] = 1,
         ["GetHSL"] = function,
         ["g"] = 1,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 0,
      ["leftText"] = "+68 Agility",
   },
   [9] =  {
      ["leftColor"] =  {
         ["b"] = 1,
         ["GetHSL"] = function,
         ["g"] = 1,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 0,
      ["leftText"] = "+781 Stamina",
   },
   [10] =  {
      ["leftColor"] =  {
         ["b"] = 0,
         ["GetHSL"] = function,
         ["g"] = 1,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 0,
      ["leftText"] = "+53 Haste",
   },
   [11] =  {
      ["leftColor"] =  {
         ["b"] = 0,
         ["GetHSL"] = function,
         ["g"] = 1,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 0,
      ["leftText"] = "+58 Versatility",
   },
   [12] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["leftText"] = "+68 Intellect",
   },
   [13] =  {
      ["leftColor"] =  {
         ["b"] = 0,
         ["GetHSL"] = function,
         ["g"] = 0.82352948188782,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 1,
      ["leftText"] = " ",
   },
   [14] =  {
      ["leftColor"] =  {
         ["b"] = 0,
         ["GetHSL"] = function,
         ["g"] = 0.82352948188782,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 0,
      ["leftText"] = "Warmonger's Chainmail (0/8)",
   },
   [15] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["leftText"] = "  Galactic Warmonger's Chestguard",
   },
   [16] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["leftText"] = "  Galactic Warmonger's Greaves",
   },
   [17] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["leftText"] = "  Galactic Warmonger's Grips",
   },
   [18] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["leftText"] = "  Galactic Warmonger's Helm",
   },
   [19] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["leftText"] = "  Galactic Warmonger's Leggings",
   },
   [20] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["leftText"] = "  Galactic Warmonger's Epaulets",
   },
   [21] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["leftText"] = "  Galactic Warmonger's Cinch",
   },
   [22] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["leftText"] = "  Galactic Warmonger's Armguards",
   },
   [23] =  {
      ["leftColor"] =  {
         ["b"] = 0,
         ["GetHSL"] = function,
         ["g"] = 0.82352948188782,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 1,
      ["leftText"] = " ",
   },
   [24] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["wrapText"] = true,
      ["leftText"] = "(2) Set: Versatility increased by 6% while in War Mode.",
   },
   [25] =  {
      ["leftColor"] =  {
         ["b"] = 0.50196081399918,
         ["GetHSL"] = function,
         ["g"] = 0.50196081399918,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0.50196081399918,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 42,
      ["wrapText"] = true,
      ["leftText"] = "(4) Set: Increases your Agility by 7% and your Stamina by 10% while in War Mode.",
   },
   [26] =  {
      ["leftColor"] =  {
         ["b"] = 0,
         ["GetHSL"] = function,
         ["g"] = 0.82352948188782,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 1,
      ["leftText"] = " ",
   },
   [27] =  {
      ["leftColor"] =  {
         ["b"] = 0,
         ["GetHSL"] = function,
         ["g"] = 1,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 0,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 0,
      ["leftText"] = "Equip: Increases item level to a minimum of 263 in Arenas and Battlegrounds.",
   },
   [28] =  {
      ["leftColor"] =  {
         ["b"] = 0,
         ["GetHSL"] = function,
         ["g"] = 0.82352948188782,
         ["GetRGBA"] = function,
         ["IsRGBEqualTo"] = function,
         ["SetRGB"] = function,
         ["GetRGB"] = function,
         ["OnLoad"] = function,
         ["GenerateHexColorMarkup"] = function,
         ["WrapTextInColorCode"] = function,
         ["GenerateHexColor"] = function,
         ["IsEqualTo"] = function,
         ["r"] = 1,
         ["GenerateHexColorNoAlpha"] = function,
         ["SetRGBA"] = function,
         ["GetRGBAsBytes"] = function,
         ["GetRGBAAsBytes"] = function,
      },
      ["type"] = 1,
      ["leftText"] = " ",
   },
},
		
		]]


		

		--local itemIndex, rewardType = getBestQualityItemRewardIndex(questID) --safe
		local questLogItem = C_TooltipInfo.GetQuestLogItem("reward", 1, questID)

		--tooltip:SetQuestLogItem("reward", 1, questID)
		tooltip:SetHyperlink(questLogItem.hyperlink)
		if TooltipUtil.ShouldDoItemComparison(tooltip) then
			GameTooltip_ShowCompareItem(tooltip)
		end
	end
	--do return end

	--xp (safe)
	local totalXp, baseXp = GetQuestLogRewardXP(questID)
	if baseXp > 0 then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_EXPERIENCE_FORMAT:format(baseXp), HIGHLIGHT_FONT_COLOR) --safe
		if (isWarModeDesired and questHasWarModeBonus) then
			tooltip:AddLine(WAR_MODE_BONUS_PERCENTAGE_XP_FORMAT:format(C_PvP.GetWarModeRewardBonus())) --safe
		end
		hasAnySingleLineRewards = true
	end

    --artifact power (safe)
	local artifactXP = GetQuestLogRewardArtifactXP(questID)
	if artifactXP > 0 then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_ARTIFACT_XP_FORMAT:format(artifactXP), HIGHLIGHT_FONT_COLOR) --safe
		hasAnySingleLineRewards = true
	end

	--favor (safe)
	local favor = C_QuestInfoSystem.GetQuestLogRewardFavor(questID, style.clampFavorToCycleCap) --safe
	if favor > 0 then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_HOUSING_FAVOR_FORMAT:format(favor, HOUSING_DASHBOARD_REWARD_ESTATE_XP), HIGHLIGHT_FONT_COLOR) --safe
		hasAnySingleLineRewards = true
	end

	--currency (not safe)
	local mainRewardIsFirstTimeReputationBonus = false
	local secondaryRewardsContainFirstTimeRepBonus = false
	if not style.atLeastShowAzerite then
		--not safe: "QuestUtils_AddQuestCurrencyRewardsToTooltip"
		local numAddedQuestCurrencies, usingCurrencyContainer, primaryCurrencyRewardInfo = QuestUtils_AddQuestCurrencyRewardsToTooltip(questID, tooltip, tooltip.ItemTooltip)
		if ( numAddedQuestCurrencies > 0 ) then
			hasAnySingleLineRewards = not usingCurrencyContainer or numAddedQuestCurrencies > 1
		end

		if primaryCurrencyRewardInfo then
			--not safe: "FlagsUtil.IsSet"
			local isFirstTimeReward = primaryCurrencyRewardInfo.questRewardContextFlags and FlagsUtil.IsSet(primaryCurrencyRewardInfo.questRewardContextFlags, Enum.QuestRewardContextFlags.FirstCompletionBonus)
			mainRewardIsFirstTimeReputationBonus = isFirstTimeReward and (C_CurrencyInfo.GetFactionGrantedByCurrency(primaryCurrencyRewardInfo.currencyID) ~= nil) or false
		elseif C_QuestLog.QuestContainsFirstTimeRepBonusForPlayer(questID) then --safe
			secondaryRewardsContainFirstTimeRepBonus = true
		end
	end

	--honor (safe)
	local honorAmount = GetQuestLogRewardHonor(questID) --safe
	if ( honorAmount > 0 ) then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT:format("Interface\\ICONS\\Achievement_LegionPVPTier4", honorAmount, HONOR), HIGHLIGHT_FONT_COLOR) --safe
		hasAnySingleLineRewards = true
	end

	--money (safe)
	local money = GetQuestLogRewardMoney(questID) --safe
	if ( money > 0 ) then
        tooltip:AddLine(MONEY .. ": " .. GetMoneyString(money), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		--SetTooltipMoney(tooltip, money, nil) --not safe
		if (isWarModeDesired and C_QuestLog.IsWorldQuest(questID) and questHasWarModeBonus) then
			tooltip:AddLine(WAR_MODE_BONUS_PERCENTAGE_FORMAT:format(C_PvP.GetWarModeRewardBonus()))
		end
		hasAnySingleLineRewards = true
	end

	--items (not safe)
	local showRetrievingData = false
	local numQuestRewards = GetNumQuestLogRewards(questID) --safe
	if numQuestRewards > 0 and (not style.prioritizeCurrencyOverItem or C_QuestInfoSystem.HasQuestRewardCurrencies(questID)) then --safe
		if style.fullItemDescription then
			-- we want to do a full item description
			local itemIndex, rewardType = getBestQualityItemRewardIndex(questID) --safe
			--tooltip:SetQuestLogItem("reward", 1, questID)

			-- check for item compare input of flag
			if not showRetrievingData then
				local shouldCompare = true
				--if TooltipUtil.ShouldDoItemComparison(tooltip.ItemTooltip.Tooltip) then --not safe
				if shouldCompare then
					GameTooltip_ShowCompareItem(tooltip.ItemTooltip.Tooltip, tooltip.BackdropFrame) --I'm not sure if is safe
				else
					for i, shoppingTooltip in ipairs(tooltip.ItemTooltip.Tooltip.shoppingTooltips) do
						shoppingTooltip:Hide();
					end
				end
			end
		else
			-- we want to do an abbreviated item description
			local name, texture, numItems, quality, isUsable, itemId = GetQuestLogRewardInfo(1, questID) --safe
			local text
			if numItems > 1 then
				text = string.format(BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT, texture, HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(numItems), name)
			elseif texture and name then
				text = string.format(BONUS_OBJECTIVE_REWARD_FORMAT, texture, name)
			end
			if text then
				local colorData = ColorManager.GetColorDataForItemQuality(quality) --safe
				if colorData then
					tooltip:AddLine(text, colorData.r, colorData.g, colorData.b)
				else
					tooltip:AddLine(text)
				end
			end
		end
	end
end


local isWorldMapHooked = false
local showTooltip = function(self, questInfo, style, xOffset, yOffset)
	if not isWorldMapHooked then
		WorldMapFrame:HookScript("OnHide", function() thisTooltip:Hide() end)
		isWorldMapHooked = true
	end

	---@cast self wqt_zonewidget
	local questID = self.questID
	if (not questID) then
		return
	end
	local worldQuestType = self.worldQuestType

	--local title, factionID, tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, allowDisplayPastCritical, gold, goldFormated, rewardName, rewardTexture, numRewardItems, itemName, itemTexture, itemLevel, itemQuantity, itemQuality, isUsable, itemID, isArtifact, artifactPower, isStackable, stackAmount = WorldQuestTracker.GetOrLoadQuestData(questID, bCanCache)

	local gameTooltip = thisTooltip
	gameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	gameTooltip:ClearLines()
	if (gameTooltip.ItemTooltip) then
		gameTooltip.ItemTooltip:Hide()
	end

	--blizzard
	if (not HaveQuestData(questID)) then
		GameTooltip_SetTitle(gameTooltip, RETRIEVING_DATA, RED_FONT_COLOR);
		GameTooltip_SetTooltipWaitingForData(gameTooltip, true);
		gameTooltip:Show();
		return;
	end

	local widgetSetAdded = false;
	local widgetSetID = C_TaskQuest.GetQuestUIWidgetSetByType(questID, Enum.MapIconUIWidgetSetType.Tooltip);
	local isThreat = C_QuestLog.IsThreatQuest(questID);

    --quest title
	local title, factionID, capped = C_TaskQuest.GetQuestInfoByQuestID(questID);
	title = title or UNKNOWN
    local tagInfo = C_QuestLog.GetQuestTagInfo(questID);
    local quality = tagInfo and tagInfo.quality or Enum.WorldQuestQuality.Common;
    local colorData = ColorManager.GetColorDataForWorldQuestQuality(quality)
    if colorData then
        GameTooltip_SetTitle(gameTooltip, title, colorData.color);
    else
        GameTooltip_SetTitle(gameTooltip, title);
    end

    --if C_QuestLog.IsAccountQuest(questID) then
    --    GameTooltip_AddColoredLine(GameTooltip, ACCOUNT_QUEST_LABEL, ACCOUNT_WIDE_FONT_COLOR);
    --end

    --quest type
    if worldQuestType then
        QuestUtils_AddQuestTypeToTooltip(gameTooltip, questID, NORMAL_FONT_COLOR);
    end

    --faction
    local factionData = factionID and C_Reputation.GetFactionDataByID(factionID);
    if factionData then
        local questAwardsReputationWithFaction = C_QuestLog.DoesQuestAwardReputationWithFaction(questID, factionID);
        local reputationYieldsRewards = (not capped) or C_Reputation.IsFactionParagonForCurrentPlayer(factionID);
        if questAwardsReputationWithFaction and reputationYieldsRewards then
            gameTooltip:AddLine(factionData.name);
        else
            gameTooltip:AddLine(factionData.name, GRAY_FONT_COLOR:GetRGB());
        end
    end

    GameTooltip_AddQuestTimeToTooltip(gameTooltip, questID);

	--quest progress
	local numObjectives = self.numObjectives or C_QuestLog.GetNumQuestObjectives(questID);
	for objectiveIndex = 1, numObjectives do
		local objectiveText, objectiveType, finished, numFulfilled, numRequired = GetQuestObjectiveInfo(questID, objectiveIndex, false);
		local showObjective = not (finished and isThreat);
		--if showObjective then
			--if self.shouldShowObjectivesAsStatusBar then
			if objectiveType == "progressbar" and showObjective then
				local percentText = nil
				if (type(numRequired) == "number" and numRequired > 0 and type(numFulfilled) == "number") then
					local percent = math.floor((numFulfilled / numRequired) * 100)
					percentText = PERCENTAGE_STRING:format(percent)
				end

				if (objectiveText and #objectiveText > 0 and percentText) then
					gameTooltip:AddLine(QUEST_DASH .. objectiveText .. " (" .. percentText .. ")", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
				elseif (objectiveText and #objectiveText > 0) then
					gameTooltip:AddLine(QUEST_DASH .. objectiveText, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
				elseif (percentText) then
					gameTooltip:AddLine(QUEST_DASH .. percentText, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
				end
			end

			if objectiveText and (#objectiveText > 0) and objectiveType ~= "progressbar" then
				local color = finished and GRAY_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
				gameTooltip:AddLine(QUEST_DASH .. objectiveText, color.r, color.g, color.b, true);
			end
		--end
	end

	--GameTooltip:Show();
	--do return end

    --blizz
    local xpAmount = GetQuestLogRewardXP(questID) --return number  > 0
    local numRewards = GetNumQuestLogRewards(questID) --return number  > 0
    local moneyAmount = GetQuestLogRewardMoney(questID) --return number  > 0 
    local artifactXP = GetQuestLogRewardArtifactXP(questID) --return number  > 0
    local honorAmount = GetQuestLogRewardHonor(questID) --return number  > 0
    local hasCurrencies = C_QuestInfoSystem.HasQuestRewardCurrencies(questID) --boolean
    local hasSpells = C_QuestInfoSystem.HasQuestRewardSpells(questID) --boolean
    local favorAmount = C_QuestInfoSystem.GetQuestLogRewardFavor(questID) --return unknown

	if (xpAmount > 0 or  moneyAmount > 0 or artifactXP > 0 or numRewards > 0 or honorAmount > 0 or hasCurrencies or hasSpells or favorAmount > 0) then
		if gameTooltip.ItemTooltip then
			gameTooltip.ItemTooltip:Hide();
		end

        local style = TOOLTIP_QUEST_REWARDS_STYLE_DEFAULT
		GameTooltip_AddBlankLinesToTooltip(gameTooltip, style.prefixBlankLineCount);

		if style.headerText and style.headerColor then
			GameTooltip_AddColoredLine(gameTooltip, style.headerText, style.headerColor, style.wrapHeaderText);
		end
		GameTooltip_AddBlankLinesToTooltip(gameTooltip, style.postHeaderBlankLineCount);

		--local hasAnySingleLineRewards, showRetrievingData = rewardFunction(GameTooltip, questID, style);
		local hasAnySingleLineRewards, showRetrievingData = rewardFuncFromScratch(gameTooltip, questID, style)

		if hasAnySingleLineRewards and gameTooltip.ItemTooltip and gameTooltip.ItemTooltip:IsShown() then
			GameTooltip_AddBlankLinesToTooltip(gameTooltip, 1);
			if showRetrievingData then
				GameTooltip_AddColoredLine(gameTooltip, RETRIEVING_DATA, RED_FONT_COLOR);
			end
		end

		GameTooltip_SetTooltipWaitingForData(gameTooltip, showRetrievingData);
	end


	gameTooltip:Show()

	do return end

		C_Timer.After(0, function()
			--print("tooltip:")
			--DetailsFramework:DebugVisibility(GameTooltip)
			--print("ItemTooltip:")

			gameTooltip.ItemTooltip:Show()

			local questLogIndex = gameTooltip.ItemTooltip.questLogIndex
			local questID = gameTooltip.ItemTooltip.questID
			local rewardType = gameTooltip.ItemTooltip.rewardType

			gameTooltip.ItemTooltip.Tooltip:SetOwner(gameTooltip.ItemTooltip, "ANCHOR_NONE");

			local itemName, itemTexture, quantity, quality, isUsable, itemID = GetQuestLogRewardInfo(questLogIndex, questID);

			gameTooltip.ItemTooltip.Icon:SetTexture(itemTexture);

			gameTooltip.ItemTooltip.itemTextureSet = (itemTexture ~= nil);

			gameTooltip.ItemTooltip.Tooltip:SetPoint("TOPLEFT", gameTooltip.ItemTooltip.Icon, "TOPRIGHT", 0, 10);

			gameTooltip.ItemTooltip:SetSize(200, 200)
			gameTooltip.ItemTooltip:Show()

			GameCooltip:Preset(1)

			GameCooltip:AddLine(itemName)
			GameCooltip:AddIcon(itemTexture)

			GameCooltip:SetHost(WorldQuestTrackerGameTooltip, "topleft", "bottomleft", 0, -5)
			GameCooltip:ShowCooltip()

			--GameTooltip.ItemTooltip.Tooltip:SetQuestLogItem(rewardType, questLogIndex, questID, showCollectionText);	

			--DetailsFramework:DebugVisibility(GameTooltip.ItemTooltip)
		end)
    --GameTooltip.ItemTooltip:Show()
    --WQT_ShoppingTooltip1:Show()
    --WQT_ShoppingTooltip2:Show()

    --[=[
    C_Timer.After(0.1, function()
        print("item tooltip:")
        detailsFramework:DebugVisibility(GameTooltip.ItemTooltip)
        GameTooltip.ItemTooltip:SetSize(200, 400)
        GameTooltip.ItemTooltip:SetPoint("topleft", GameTooltip, "topright", 10, 0)
        print("shopping tooltip 1:")
        detailsFramework:DebugVisibility(WQT_ShoppingTooltip1)
        WQT_ShoppingTooltip1:SetSize(200, 400)
        WQT_ShoppingTooltip1:SetPoint("topleft", GameTooltip, "topright", 10, 0)
        print("shopping tooltip 2:")
        detailsFramework:DebugVisibility(WQT_ShoppingTooltip2)
        WQT_ShoppingTooltip2:SetSize(200, 400)
        WQT_ShoppingTooltip2:SetPoint("topleft", WQT_ShoppingTooltip1, "topright", 10, 0)
    --]=]

    --GameTooltip.ItemTooltip:Show()
    --WQT_ShoppingTooltip1:Show()
    --WQT_ShoppingTooltip2:Show()
    --end)

end

WorldQuestTracker.ShowQuestTooltip = showTooltip

WorldQuestTracker.HideQuestTooltip = function(button)
	WQT_ShoppingTooltip1:Hide()
	WQT_ShoppingTooltip2:Hide()
	thisTooltip:Hide()

	GameCooltip:Hide()
end


hooksecurefunc(_G, "EmbeddedItemTooltip_SetItemByQuestReward", function(ItemTooltip, questLogIndex, questID, rewardType, showCollectionText)
	--print("--- HOOK ----")
	--print(ItemTooltip:GetName(), ItemTooltip:GetParent():GetName(), questLogIndex, questID, rewardType, showCollectionText)

	ItemTooltip.questID = questID
	ItemTooltip.questLogIndex = questLogIndex
	ItemTooltip.rewardType = rewardType




	local itemName, itemTexture, quantity, quality, isUsable, itemID = GetQuestLogRewardInfo(questLogIndex, questID);

	--print(itemName, itemTexture, quantity, quality, isUsable, itemID)

	--print("IsSHown::::: ", ItemTooltip:IsShown())


end)










--copy of QuestUtils_AddQuestRewardsToTooltip
--with some modifications for world quests to avoid taints
local rewardFunction = function(tooltip, questID, style)
	local hasAnySingleLineRewards = false;
	local isWarModeDesired = C_PvP.IsWarModeDesired();
	local questHasWarModeBonus = C_QuestLog.QuestCanHaveWarModeBonus(questID);

	-- xp
	local totalXp, baseXp = GetQuestLogRewardXP(questID);
	if ( baseXp > 0 ) then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_EXPERIENCE_FORMAT:format(baseXp), HIGHLIGHT_FONT_COLOR);
		if (isWarModeDesired and questHasWarModeBonus) then
			tooltip:AddLine(WAR_MODE_BONUS_PERCENTAGE_XP_FORMAT:format(C_PvP.GetWarModeRewardBonus()));
		end
		hasAnySingleLineRewards = true;
	end

    --artifact power
	local artifactXP = GetQuestLogRewardArtifactXP(questID);
	if ( artifactXP > 0 ) then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_ARTIFACT_XP_FORMAT:format(artifactXP), HIGHLIGHT_FONT_COLOR);
		hasAnySingleLineRewards = true;
	end

	-- favor
	local favor = C_QuestInfoSystem.GetQuestLogRewardFavor(questID, style.clampFavorToCycleCap);
	if ( favor > 0 ) then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_HOUSING_FAVOR_FORMAT:format(favor, HOUSING_DASHBOARD_REWARD_ESTATE_XP), HIGHLIGHT_FONT_COLOR);
		hasAnySingleLineRewards = true;
	end

	-- currency
	local mainRewardIsFirstTimeReputationBonus = false;
	local secondaryRewardsContainFirstTimeRepBonus = false;
	if not style.atLeastShowAzerite then
		local numAddedQuestCurrencies, usingCurrencyContainer, primaryCurrencyRewardInfo = QuestUtils_AddQuestCurrencyRewardsToTooltip(questID, tooltip, tooltip.ItemTooltip);
		if ( numAddedQuestCurrencies > 0 ) then
			hasAnySingleLineRewards = not usingCurrencyContainer or numAddedQuestCurrencies > 1;
		end

		if primaryCurrencyRewardInfo then
			local isFirstTimeReward = primaryCurrencyRewardInfo.questRewardContextFlags and FlagsUtil.IsSet(primaryCurrencyRewardInfo.questRewardContextFlags, Enum.QuestRewardContextFlags.FirstCompletionBonus);
			mainRewardIsFirstTimeReputationBonus = isFirstTimeReward and (C_CurrencyInfo.GetFactionGrantedByCurrency(primaryCurrencyRewardInfo.currencyID) ~= nil) or false;
		elseif C_QuestLog.QuestContainsFirstTimeRepBonusForPlayer(questID) then
			secondaryRewardsContainFirstTimeRepBonus = true;
		end
	end

	-- honor
	local honorAmount = GetQuestLogRewardHonor(questID);
	if ( honorAmount > 0 ) then
		GameTooltip_AddColoredLine(tooltip, BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT:format("Interface\\ICONS\\Achievement_LegionPVPTier4", honorAmount, HONOR), HIGHLIGHT_FONT_COLOR);
		hasAnySingleLineRewards = true;
	end

	-- money
	local money = GetQuestLogRewardMoney(questID);
	if ( money > 0 ) then
        tooltip:AddLine(MONEY .. ": " .. GetMoneyString(money), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		--SetTooltipMoney(tooltip, money, nil); --avoid money frame taint
		if (isWarModeDesired and QuestUtils_IsQuestWorldQuest(questID) and questHasWarModeBonus) then
			tooltip:AddLine(WAR_MODE_BONUS_PERCENTAGE_FORMAT:format(C_PvP.GetWarModeRewardBonus()));
		end
		hasAnySingleLineRewards = true;
	end

	-- items
	local showRetrievingData = false;
	if true then
		local numQuestRewards = GetNumQuestLogRewards(questID);
		if numQuestRewards > 0 and (not style.prioritizeCurrencyOverItem or C_QuestInfoSystem.HasQuestRewardCurrencies(questID)) then
			if style.fullItemDescription then
				-- we want to do a full item description
				local itemIndex, rewardType = getBestQualityItemRewardIndex(questID);  -- Only support one item reward currently

				tooltip:SetQuestLogItem("reward", 1, questID)

				--print(tooltip.ItemTooltip, itemIndex, questID, rewardType, style.showCollectionText)
				--if not EmbeddedItemTooltip_SetItemByQuestReward(tooltip.ItemTooltip, itemIndex, questID, rewardType, style.showCollectionText) then
				--	showRetrievingData = true; --it is getting added!
				--end

				--tooltip.ItemTooltip:SetParent(tooltip)
				--tooltip.ItemTooltip:Show()
				--tooltip.ItemTooltip:ClearAllPoints()
				--tooltip.ItemTooltip:SetPoint("topleft", tooltip, "bottomleft", 0, -10)
				--print(tooltip.ItemTooltip:IsShown())
				--print("p", tooltip.ItemTooltip:GetParent():IsShown())
				--print("parent name", tooltip.ItemTooltip:GetParent():GetName())
				--print("t", tooltip.ItemTooltip.Tooltip:IsShown())

				--print("IS:", tooltip == tooltip.ItemTooltip.Tooltip)
				--tooltip.ItemTooltip.Tooltip.shoppingTooltips[1]:Show()
				--tooltip.ItemTooltip.Tooltip.shoppingTooltips[2]:Show()



				-- check for item compare input of flag
				if not showRetrievingData then
					if TooltipUtil.ShouldDoItemComparison(tooltip.ItemTooltip.Tooltip) then
						GameTooltip_ShowCompareItem(tooltip.ItemTooltip.Tooltip, tooltip.BackdropFrame);
					else
						for i, shoppingTooltip in ipairs(tooltip.ItemTooltip.Tooltip.shoppingTooltips) do
							shoppingTooltip:Hide();
						end
					end
					--print("WQT_ShoppingTooltip1", WQT_ShoppingTooltip1:IsShown())
					--print("WQT_ShoppingTooltip2", WQT_ShoppingTooltip2:IsShown())
				end
			else
				-- we want to do an abbreviated item description
				local name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(1, questID);
				local text;
				if numItems > 1 then
					text = string.format(BONUS_OBJECTIVE_REWARD_WITH_COUNT_FORMAT, texture, HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(numItems), name);
				elseif texture and name then
					text = string.format(BONUS_OBJECTIVE_REWARD_FORMAT, texture, name);
				end
				if text then
					local colorData = ColorManager.GetColorDataForItemQuality(quality);
					if colorData then
						tooltip:AddLine(text, colorData.r, colorData.g, colorData.b);
					else
						tooltip:AddLine(text);
					end
				end
			end
		end
	end

	-- spells
	if not tooltip.ItemTooltip:IsShown() and EmbeddedItemTooltip_SetSpellByFirstQuestReward(tooltip.ItemTooltip, questID) then
		showRetrievingData = true;
	end

	-- atLeastShowAzerite: show azerite if nothing else is awarded
	-- and in the case of double azerite, only show the currency container one
	if style.atLeastShowAzerite and not hasAnySingleLineRewards and not tooltip.ItemTooltip:IsShown() then
		local numAddedQuestCurrencies, usingCurrencyContainer = QuestUtils_AddQuestCurrencyRewardsToTooltip(questID, tooltip, tooltip.ItemTooltip);
		if ( numAddedQuestCurrencies > 0 ) then
			hasAnySingleLineRewards = not usingCurrencyContainer or numAddedQuestCurrencies > 1;
			if usingCurrencyContainer and numAddedQuestCurrencies > 1 then
				EmbeddedItemTooltip_Clear(tooltip.ItemTooltip);
				EmbeddedItemTooltip_Hide(tooltip.ItemTooltip);
				tooltip:Show();
			end
		end
	end

	if style.showFirstTimeRepRewardNotice and (mainRewardIsFirstTimeReputationBonus or secondaryRewardsContainFirstTimeRepBonus) then
		local bestTooltipForLine = tooltip.ItemTooltip:IsShown() and tooltip.ItemTooltip.Tooltip or tooltip;
		GameTooltip_AddBlankLineToTooltip(bestTooltipForLine);

		local wrapText = false;
		local noticeText = mainRewardIsFirstTimeReputationBonus and QUEST_REWARDS_IS_ONE_TIME_REP_BONUS or QUEST_REWARDS_CONTAINS_ONE_TIME_REP_BONUS;
		GameTooltip_AddColoredLine(bestTooltipForLine, noticeText, QUEST_REWARD_CONTEXT_FONT_COLOR, wrapText);

		if bestTooltipForLine == tooltip.ItemTooltip.Tooltip then
			tooltip.ItemTooltip.Tooltip:Show();
		end
	end

	return hasAnySingleLineRewards, showRetrievingData;
end
