
local detailsFramework = DetailsFramework
if (not detailsFramework or not DetailsFrameworkCanLoad) then
	return
end

local threeSixty = math.pi * 2

local normalizeAngle = function(angle)
    angle = angle % threeSixty
    if angle < 0 then
        angle = angle + threeSixty
    end
    return angle
end

local GetCursorPositionOnUI = function()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetScale()
    return x / scale, y / scale
end

---@class wheelmenuoption
---@field text string?
---@field icon string|number?
---@field onClick fun(option: wheelmenuoption, menu: wheelmenuframe)?
---@field value any

---@class wheelmenuframe : frame
---@field Options wheelmenuoption[]
---@field OptionButtons button[]
---@field OuterRadius number
---@field InnerRadius number
---@field OptionRadius number
---@field OptionButtonWidth number
---@field OptionButtonHeight number
---@field FirstOptionAngle number
---@field HoveredIndex number?
local WheelMenuMixin = {}

function WheelMenuMixin:LayoutOptions()
    local optionCount = #self.Options
    if optionCount == 0 then
        return
    end

    local sliceAngle = threeSixty / optionCount
    local firstOptionAngle = self.FirstOptionAngle or (math.pi * 0.5)
    for index = 1, optionCount do
        local button = self.OptionButtons[index]
        if button then
            local angle = normalizeAngle(firstOptionAngle + (index - 1) * sliceAngle)
            local x = math.cos(angle) * self.OptionRadius
            local y = math.sin(angle) * self.OptionRadius
            button:ClearAllPoints()
            button:SetPoint("CENTER", self, "CENTER", x, y)
            button.SectorStartAngle = normalizeAngle(angle - sliceAngle * 0.5)
            button.SectorEndAngle = normalizeAngle(angle + sliceAngle * 0.5)
            button:Show()
        end
    end

    for index = optionCount + 1, #self.OptionButtons do
        local button = self.OptionButtons[index]
        if button then
            button.Option = nil
            button:Hide()
        end
    end
end

function WheelMenuMixin:SetHoveredIndex(index)
    if self.HoveredIndex == index then
        return
    end

    if self.HoveredIndex and self.OptionButtons[self.HoveredIndex] then
        local oldButton = self.OptionButtons[self.HoveredIndex]
        oldButton:SetBackdropColor(0, 0, 0, 0.7)
        oldButton:SetBackdropBorderColor(0, 0, 0, 0.35)
    end

    self.HoveredIndex = index

    if index and self.OptionButtons[index] then
        local newButton = self.OptionButtons[index]
        newButton:SetBackdropColor(0.15, 0.45, 0.9, 0.9)
        newButton:SetBackdropBorderColor(0.5, 0.8, 1, 0.9)
    end
end

function WheelMenuMixin:GetOptionIndexFromCursor(cursorX, cursorY)
    local optionCount = #self.Options
    if optionCount < 1 then
        return
    end

    local centerX, centerY = self:GetCenter()
    local deltaX = cursorX - centerX
    local deltaY = cursorY - centerY
    local distanceSquared = deltaX * deltaX + deltaY * deltaY

    if distanceSquared < (self.InnerRadius * self.InnerRadius) then
        return
    end
    if distanceSquared > (self.OuterRadius * self.OuterRadius) then
        return
    end

    local angle = normalizeAngle(math.atan2(deltaY, deltaX))
    local sliceAngle = threeSixty / optionCount
    local firstOptionAngle = self.FirstOptionAngle or (math.pi * 0.5)
    local adjustedAngle = normalizeAngle(angle - firstOptionAngle + sliceAngle * 0.5)
    local index = math.floor(adjustedAngle / sliceAngle) + 1
    if index < 1 then
        index = 1
    elseif index > optionCount then
        index = optionCount
    end

    return index
end

function WheelMenuMixin:GetNearestButtonFromCursor(cursorX, cursorY)
    local index = self:GetOptionIndexFromCursor(cursorX, cursorY)
    if not index then
        return
    end
    return self.OptionButtons[index], index
end

function WheelMenuMixin:RefreshHoverFromCursor()
    local mouseX, mouseY = detailsFramework:GetCursorPosition()
    local _, hoveredIndex = self:GetNearestButtonFromCursor(mouseX, mouseY)
    self:SetHoveredIndex(hoveredIndex)
end

function WheelMenuMixin:ConfirmHoveredOption()
    local index = self.HoveredIndex
    if not index then
        return
    end

    local option = self.Options[index]
    if option and option.onClick then
        option.onClick(option, self)
    end
end

---@param options wheelmenuoption[]
function WheelMenuMixin:SetOptions(options)
    self.Options = options or {}

    for index = 1, #self.Options do
        local option = self.Options[index]
        local button = self.OptionButtons[index]
        if not button then
            button = CreateFrame("button", nil, self, "BackdropTemplate")
            button:SetSize(self.OptionButtonWidth, self.OptionButtonHeight)
            button:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            button:SetBackdropColor(0, 0, 0, 0.7)
            button:SetBackdropBorderColor(0, 0, 0, 0.35)

            button.Icon = button:CreateTexture(nil, "ARTWORK")
            button.Icon:SetSize(16, 16)
            button.Icon:SetPoint("LEFT", button, "LEFT", 4, 0)

            button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            button.Text:SetPoint("LEFT", button.Icon, "RIGHT", 4, 0)
            button.Text:SetPoint("RIGHT", button, "RIGHT", -4, 0)
            button.Text:SetJustifyH("LEFT")

            button:SetScript("OnClick", function(clickedButton)
                local clickedOption = clickedButton.Option
                if clickedOption and clickedOption.onClick then
                    clickedOption.onClick(clickedOption, self)
                end
            end)

            self.OptionButtons[index] = button
        end

        button.Option = option
        button.Text:SetText(option.text or ("Option " .. index))
        if option.icon then
            button.Icon:SetTexture(option.icon)
            button.Icon:Show()
        else
            button.Icon:SetTexture(nil)
            button.Icon:Hide()
        end
        button:Show()
    end

    self:SetHoveredIndex(nil)
    self:LayoutOptions()
end

function WheelMenuMixin:OpenAtCursor()
    local mouseX, mouseY = detailsFramework:GetCursorPosition()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", mouseX, mouseY)
    self:SetHoveredIndex(nil)
    self:Show()
    self:SetScript("OnUpdate", function(menu)
        menu:RefreshHoverFromCursor()
    end)
end

function WheelMenuMixin:CloseMenu()
    self:SetScript("OnUpdate", nil)
    self:SetHoveredIndex(nil)
    self:Hide()
end

---@param name string?
---@param parent frame?
---@param wheelOptions wheelmenuoption[]?
---@param config table?
---@return wheelmenuframe
function detailsFramework:CreateWheelMenu(parent, name, wheelOptions, config)
    parent = parent or UIParent
    config = config or {}
    wheelOptions = wheelOptions or {}

    local innerRadius = config.innerRadius or 42
    local outerRadius = config.outerRadius or 170
    local optionRadius = config.optionRadius or math.floor((outerRadius + innerRadius) * 0.5)
    local optionButtonWidth = config.optionButtonWidth or 122
    local optionButtonHeight = config.optionButtonHeight or 24

    ---@type wheelmenuframe
    ---@diagnostic disable-next-line: assign-type-mismatch
    local menu = CreateFrame("Frame", name, parent, "BackdropTemplate")
    menu:SetFrameStrata(config.frameStrata or "FULLSCREEN")
    menu:SetFrameLevel(config.frameLevel or 120)
    menu:SetSize(outerRadius * 2, outerRadius * 2)
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    menu:Hide()

    menu.OuterRadius = outerRadius
    menu.InnerRadius = innerRadius
    menu.OptionRadius = optionRadius
    menu.OptionButtonWidth = optionButtonWidth
    menu.OptionButtonHeight = optionButtonHeight
    menu.FirstOptionAngle = config.firstOptionAngle or (math.pi * 0.5)
    menu.Options = {}
    menu.OptionButtons = {}
    menu.HoveredIndex = nil

    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    menu:SetBackdropColor(0, 0, 0, 0.5)
    menu:SetBackdropBorderColor(0, 0, 0, 0.65)

    menu.InnerDisc = CreateFrame("Frame", nil, menu, "BackdropTemplate")
    menu.InnerDisc:SetPoint("CENTER", menu, "CENTER", 0, 0)
    menu.InnerDisc:SetSize(innerRadius * 2, innerRadius * 2)
    menu.InnerDisc:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    menu.InnerDisc:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    menu.InnerDisc:SetBackdropBorderColor(0, 0, 0, 0.8)

    menu.CenterText = menu.InnerDisc:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    menu.CenterText:SetPoint("CENTER")
    menu.CenterText:SetText(config.centerText or "Menu")

    Mixin(menu, WheelMenuMixin)

    menu:SetScript("OnMouseUp", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            self:ConfirmHoveredOption()
            self:CloseMenu()
        elseif mouseButton == "RightButton" then
            self:CloseMenu()
        end
    end)

    menu:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    return menu
end
