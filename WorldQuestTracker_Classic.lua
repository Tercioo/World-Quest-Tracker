local addonName = ...

WorldQuestTracker = WorldQuestTracker or {}
local WQT = WorldQuestTracker

WQT.addonName = addonName or "WorldQuestTracker"
WQT.version = "v12.0.7.556-Custom-MultiClient"
WQT.isClassicCompatibilityMode = true
WQT.isSupportedClient = false
WQT.QuestTrackList = WQT.QuestTrackList or {}
WQT.CurrentZoneQuests = WQT.CurrentZoneQuests or {}

local function GetClientLabel()
    local interfaceVersion = select(4, GetBuildInfo()) or 0

    if interfaceVersion >= 50000 and interfaceVersion < 60000 then
        return "Mists of Pandaria Classic"
    elseif interfaceVersion >= 38000 and interfaceVersion < 39000 then
        return "Wrath/Titan Classic"
    elseif interfaceVersion >= 20000 and interfaceVersion < 30000 then
        return "Burning Crusade Classic"
    elseif interfaceVersion >= 10000 and interfaceVersion < 20000 then
        return "Classic Era"
    end

    return "Classic"
end
local function ShowCompatibilityMessage()
    local label = GetClientLabel()
    print("|cFFFFAA00World Quest Tracker:|r " .. label .. " does not provide the Retail World Quest system. The addon loaded in compatibility mode and Retail map modules were not started.")
end

function WQT:IsSupportedGameClient()
    return false
end

function WQT:IsCompatibilityMode()
    return true
end

function WQT:Msg(message)
    if message then
        print("|cFFFFAA00World Quest Tracker:|r " .. tostring(message))
    else
        ShowCompatibilityMessage()
    end
end

function WQT:OpenOptions()
    ShowCompatibilityMessage()
end

function WQT:ShowOptions()
    ShowCompatibilityMessage()
end

SLASH_WORLDQUESTTRACKER1 = "/wqt"
SLASH_WORLDQUESTTRACKER2 = "/worldquesttracker"
SlashCmdList.WORLDQUESTTRACKER = ShowCompatibilityMessage
