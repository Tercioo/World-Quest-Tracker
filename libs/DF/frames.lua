
---@class detailsframework
local detailsFramework = _G.DetailsFramework
if (not detailsFramework or not DetailsFrameworkCanLoad) then
	return
end

local CreateFrame = CreateFrame
local GetScreenWidth = GetScreenWidth
local GetScreenHeight = GetScreenHeight
local defaultRed, defaultGreen, defaultBlue = detailsFramework:GetDefaultBackdropColor()
--local defaultColorTable = {defaultRed, defaultGreen, defaultBlue, 1}
local defaultColorTable = {0.98, 0.98, 0.98, 1}
local defaultBorderColorTable = {0.1, 0.1, 0.1, 1}

---@type edgenames[]
local cornerNames = {"TopLeft", "TopRight", "BottomLeft", "BottomRight"}

---@param self df_roundedpanel
---@param textures cornertextures
---@param width number|nil
---@param height number|nil
---@param xOffset number|nil
---@param yOffset number|nil
---@param bIsBorder boolean|nil
local setCornerPoints = function(self, textures, width, height, xOffset, yOffset, bIsBorder)
    for cornerName, thisTexture in pairs(textures) do
        thisTexture:SetSize(width or 16, height or 16)
        thisTexture:SetTexture(self.options.corner_texture)

        --set the mask
        if (not thisTexture.MaskTexture and bIsBorder) then
            thisTexture.MaskTexture = self:CreateMaskTexture(nil, "background")
            thisTexture.MaskTexture:SetSize(74, 64)
            thisTexture:AddMaskTexture(thisTexture.MaskTexture)
            thisTexture.MaskTexture:SetTexture([[Interface\Azerite\AzeriteGoldRingRank2]]) --1940690
            --thisTexture.MaskTexture:Hide()
        end

        xOffset = xOffset or 0
        yOffset = yOffset or 0

        --todo: adjust the other corners setpoint offset
        --todo (done): use mask when the alpha is below 0.98, disable the mask when the alpha is above 0.98

        if (cornerName == "TopLeft") then
            thisTexture:SetTexCoord(0, 0.5, 0, 0.5)
            thisTexture:SetPoint(cornerName, self, cornerName, -xOffset, yOffset)
            if (thisTexture.MaskTexture) then
                thisTexture.MaskTexture:SetPoint(cornerName, self, cornerName, -18-xOffset, 16+yOffset)
            end

        elseif (cornerName == "TopRight") then
            thisTexture:SetTexCoord(0.5, 1, 0, 0.5)
            thisTexture:SetPoint(cornerName, self, cornerName, xOffset, yOffset)
            if (thisTexture.MaskTexture) then
                thisTexture.MaskTexture:SetPoint(cornerName, self, cornerName, -18+xOffset, 16+yOffset)
            end

        elseif (cornerName == "BottomLeft") then
            thisTexture:SetTexCoord(0, 0.5, 0.5, 1)
            thisTexture:SetPoint(cornerName, self, cornerName, -xOffset, -yOffset)
            if (thisTexture.MaskTexture) then
                thisTexture.MaskTexture:SetPoint(cornerName, self, cornerName, -18-xOffset, 16-yOffset)
            end

        elseif (cornerName == "BottomRight") then
            thisTexture:SetTexCoord(0.5, 1, 0.5, 1)
            thisTexture:SetPoint(cornerName, self, cornerName, xOffset, -yOffset)
            if (thisTexture.MaskTexture) then
                thisTexture.MaskTexture:SetPoint(cornerName, self, cornerName, -18+xOffset, 16-yOffset)
            end
        end
    end
end

detailsFramework.RoundedCornerPanelMixin = {
    RoundedCornerConstructor = function(self)
        self.CornerTextures = {}
        self.CenterTextures = {}
        self.BorderCornerTextures = {}
        self.BorderEdgeTextures = {}

        self.cornerRoundness = 0

        for i = 1, #cornerNames do
            ---@type texture
            local newCornerTexture = self:CreateTexture(nil, "border", nil, 0)
            self.CornerTextures[cornerNames[i]] = newCornerTexture
            self[cornerNames[i]] = newCornerTexture
        end

        --create the top texture which connects the top corners with a horizontal line
        ---@type texture
        local topHorizontalEdge = self:CreateTexture(nil, "border", nil, 0)
        topHorizontalEdge:SetPoint("topleft", self.CornerTextures["TopLeft"], "topright", 0, 0)
        topHorizontalEdge:SetPoint("bottomleft", self.CornerTextures["TopLeft"], "bottomright", 0, 0)
        topHorizontalEdge:SetPoint("topright", self.CornerTextures["TopRight"], "topleft", 0, 0)
        topHorizontalEdge:SetPoint("bottomright", self.CornerTextures["TopRight"], "bottomleft", 0, 0)
        topHorizontalEdge:SetColorTexture(unpack(defaultColorTable))

        --create the bottom texture which connects the bottom corners with a horizontal line
        ---@type texture
        local bottomHorizontalEdge = self:CreateTexture(nil, "border", nil, 0)
        bottomHorizontalEdge:SetPoint("topleft", self.CornerTextures["BottomLeft"], "topright", 0, 0)
        bottomHorizontalEdge:SetPoint("bottomleft", self.CornerTextures["BottomLeft"], "bottomright", 0, 0)
        bottomHorizontalEdge:SetPoint("topright", self.CornerTextures["BottomRight"], "topleft", 0, 0)
        bottomHorizontalEdge:SetPoint("bottomright", self.CornerTextures["BottomRight"], "bottomleft", 0, 0)
        bottomHorizontalEdge:SetColorTexture(unpack(defaultColorTable))

        --create the center block which connects the bottom left of the topleft corner with the top right of the bottom right corner
        ---@type texture
        local centerBlock = self:CreateTexture(nil, "border", nil, 0)
        centerBlock:SetPoint("topleft", self.CornerTextures["TopLeft"], "bottomleft", 0, 0)
        centerBlock:SetPoint("bottomleft", self.CornerTextures["BottomLeft"], "topleft", 0, 0)
        --centerBlock:SetPoint("topright", self.CornerTextures["BottomRight"], "topright", 0, 0)
        --centerBlock:SetPoint("bottomright", self.CornerTextures["BottomRight"], "topright", 0, 0)
        centerBlock:SetPoint("topright", self.CornerTextures["TopRight"], "bottomright", 0, 0)
        centerBlock:SetPoint("bottomright", self.CornerTextures["BottomRight"], "topright", 0, 0)
        centerBlock:SetColorTexture(unpack(defaultColorTable))

        self.CenterTextures[#self.CenterTextures+1] = topHorizontalEdge
        self.CenterTextures[#self.CenterTextures+1] = bottomHorizontalEdge
        self.CenterTextures[#self.CenterTextures+1] = centerBlock

        self.TopHorizontalEdge = topHorizontalEdge
        self.BottomHorizontalEdge = bottomHorizontalEdge
        self.CenterBlock = centerBlock

        ---@type width
        local width = self.options.width
        ---@type height
        local height = self.options.height

        self:SetSize(width, height)

        --fill the corner and edge textures table
        setCornerPoints(self, self.CornerTextures)
    end,

    ---get the highest frame level of the rounded panel and its children
    ---@param self df_roundedpanel
    ---@return framelevel
    GetMaxFrameLevel = function(self)
        ---@type framelevel
        local maxFrameLevel = 0
        local children = {self:GetChildren()}

        for i = 1, #children do
            local thisChild = children[i]
            ---@cast thisChild frame
            if (thisChild:GetFrameLevel() > maxFrameLevel) then
                maxFrameLevel = thisChild:GetFrameLevel()
            end
        end

        return maxFrameLevel
    end,

    ---create a frame placed at the top side of the rounded panel, this frame has a member called 'Text' which is a fontstring for the title
    ---@param self df_roundedpanel
    ---@return df_roundedpanel
    CreateTitleBar = function(self)
        ---@type df_roundedpanel
        local titleBar = detailsFramework:CreateRoundedPanel(self, "$parentTitleBar", {width = self.options.width - 6, height = 16})
        titleBar:SetPoint("top", self, "top", 0, -4)
        titleBar:SetRoundness(5)
        titleBar:SetFrameLevel(9500)
        titleBar.bIsTitleBar = true
        self.TitleBar = titleBar
        self.bHasTitleBar = true

        local textFontString = titleBar:CreateFontString("$parentText", "overlay", "GameFontNormal")
        textFontString:SetPoint("center", titleBar, "center", 0, 0)
        titleBar.Text = textFontString

        local closeButton = detailsFramework:CreateCloseButton(titleBar, "$parentCloseButton")
        closeButton:SetPoint("right", titleBar, "right", -3, 0)
		closeButton:SetSize(10, 10)
		closeButton:SetAlpha(0.3)
        closeButton:SetScript("OnClick", function(self)
            self:GetParent():GetParent():Hide()
        end)
        detailsFramework:SetButtonTexture(closeButton, "common-search-clearbutton")

        return titleBar
    end,

    ---return the width and height of the corner textures
    ---@param self df_roundedpanel
    ---@return number, number
    GetCornerSize = function(self)
        return self.CornerTextures["TopLeft"]:GetSize()
    end,

    ---set how rounded the corners should be
    ---@param self df_roundedpanel
    ---@param roundness number
    SetRoundness = function(self, roundness)
        self.cornerRoundness = roundness
        self:OnSizeChanged()
    end,

    ---adjust the size of the corner textures and the border edge textures
    ---@param self df_roundedpanel
    OnSizeChanged = function(self)
        --if the frame has a titlebar, need to adjust the size of the titlebar
        if (self.bHasTitleBar) then
            self.TitleBar:SetWidth(self:GetWidth() - 14)
        end

        --if the frame height is below 32, need to recalculate the size of the corners
        ---@type height
        local frameHeight = self:GetHeight()

        if (frameHeight < 32) then
            local newCornerSize = frameHeight / 2

            --set the new size of the corners on all corner textures
            for _, thisTexture in pairs(self.CornerTextures) do
                thisTexture:SetSize(newCornerSize - (self.cornerRoundness - 2), newCornerSize)
            end

            --check if the frame has border and set the size of the border corners as well
            if (self.bHasBorder) then
                for _, thisTexture in pairs(self.BorderCornerTextures) do
                    thisTexture:SetSize(newCornerSize-2, newCornerSize+2)
                end

                --hide the left and right edges as the corner textures already is enough to fill the frame
                self.BorderEdgeTextures["Left"]:Hide()
                self.BorderEdgeTextures["Right"]:Hide()

                local horizontalEdgesNewSize = self:CalculateBorderEdgeSize("horizontal")
                self.BorderEdgeTextures["Top"]:SetSize(horizontalEdgesNewSize + (self.options.horizontal_border_size_offset or 0), 1)
                self.BorderEdgeTextures["Bottom"]:SetSize(horizontalEdgesNewSize + (self.options.horizontal_border_size_offset or 0), 1)
            end

            self.CenterBlock:Hide()
        else
            if (self.bHasBorder) then
                self.BorderEdgeTextures["Left"]:Show()
                self.BorderEdgeTextures["Right"]:Show()
            end

            ---@type width, height
            local cornerWidth, cornerHeight = 16, 16

            self.CenterBlock:Show()

            for _, thisTexture in pairs(self.CornerTextures) do
                thisTexture:SetSize(cornerWidth-self.cornerRoundness, cornerHeight-self.cornerRoundness)
            end

            if (self.bHasBorder) then
                for _, thisTexture in pairs(self.BorderCornerTextures) do
                    thisTexture:SetSize(cornerWidth-self.cornerRoundness, cornerHeight-self.cornerRoundness)
                    thisTexture.MaskTexture:SetSize(74-(self.cornerRoundness*0.75), 64-self.cornerRoundness)
                end

                local horizontalEdgesNewSize = self:CalculateBorderEdgeSize("horizontal")
                self.BorderEdgeTextures["Top"]:SetSize(horizontalEdgesNewSize, 1)
                self.BorderEdgeTextures["Bottom"]:SetSize(horizontalEdgesNewSize, 1)

                local verticalEdgesNewSize = self:CalculateBorderEdgeSize("vertical")
                self.BorderEdgeTextures["Left"]:SetSize(1, verticalEdgesNewSize)
                self.BorderEdgeTextures["Right"]:SetSize(1, verticalEdgesNewSize)
            end
        end
    end,

    ---get the size of the edge texture
    ---@param self df_roundedpanel
    ---@param alignment "vertical"|"horizontal"
    ---@return number edgeSize
    CalculateBorderEdgeSize = function(self, alignment)
        ---@type string
        local borderCornerName = next(self.BorderCornerTextures)
        if (not borderCornerName) then
            return 0
        end

        ---@type texture
        local borderTexture = self.BorderCornerTextures[borderCornerName]

        alignment = alignment:lower()

        if (alignment == "vertical") then
            return self:GetHeight() - (borderTexture:GetHeight() * 2) + 2

        elseif (alignment == "horizontal") then
            return self:GetWidth() - (borderTexture:GetWidth() * 2) + 2
        end

        error("df_roundedpanel:CalculateBorderEdgeSize(self, alignment) alignment must be 'vertical' or 'horizontal'")
    end,

    ---@param self df_roundedpanel
    CreateBorder = function(self)
        local r, g, b, a = 0, 0, 0, 0.8

        --create the corner edges
        for i = 1, #cornerNames do
            ---@type texture
            local newBorderTexture = self:CreateTexture(nil, "background", nil, 0)
            self.BorderCornerTextures[cornerNames[i]] = newBorderTexture
            newBorderTexture:SetColorTexture(unpack(defaultColorTable))
            newBorderTexture:SetVertexColor(r, g, b, a)
            self[cornerNames[i] .. "Border"] = newBorderTexture
        end

        setCornerPoints(self, self.BorderCornerTextures, 16, 16, 1, 1, true)

        --create the top, left, bottom and right edges, the edge has 1pixel width and connects the corners
        ---@type texture
        local topEdge = self:CreateTexture(nil, "background", nil, 0)
        topEdge:SetPoint("bottom", self, "top", 0, 0)
        self.BorderEdgeTextures["Top"] = topEdge

        ---@type texture
        local leftEdge = self:CreateTexture(nil, "background", nil, 0)
        leftEdge:SetPoint("right", self, "left", 0, 0)
        self.BorderEdgeTextures["Left"] = leftEdge

        ---@type texture
        local bottomEdge = self:CreateTexture(nil, "background", nil, 0)
        bottomEdge:SetPoint("top", self, "bottom", 0, 0)
        self.BorderEdgeTextures["Bottom"] = bottomEdge

        ---@type texture
        local rightEdge = self:CreateTexture(nil, "background", nil, 0)
        rightEdge:SetPoint("left", self, "right", 0, 0)
        self.BorderEdgeTextures["Right"] = rightEdge

        ---@type width
        local horizontalEdgeSize = self:CalculateBorderEdgeSize("horizontal")
        ---@type height
        local verticalEdgeSize = self:CalculateBorderEdgeSize("vertical")

        --set the edges size
        topEdge:SetSize(horizontalEdgeSize, 1)
        leftEdge:SetSize(1, verticalEdgeSize)
        bottomEdge:SetSize(horizontalEdgeSize, 1)
        rightEdge:SetSize(1, verticalEdgeSize)

        for edgeName, thisTexture in pairs(self.BorderEdgeTextures) do
            ---@cast thisTexture texture
            thisTexture:SetColorTexture(unpack(defaultColorTable))
            thisTexture:SetVertexColor(r, g, b, a)
        end

        self.TopEdgeBorder = topEdge
        self.BottomEdgeBorder = bottomEdge
        self.LeftEdgeBorder = leftEdge
        self.RightEdgeBorder = rightEdge

        self.bHasBorder = true
    end,

    ---@param self df_roundedpanel
    ---@param red any
    ---@param green number|nil
    ---@param blue number|nil
    ---@param alpha number|nil
    SetTitleBarColor = function(self, red, green, blue, alpha)
        if (self.bHasTitleBar) then
            red, green, blue, alpha = detailsFramework:ParseColors(red, green, blue, alpha)
            self.TitleBar:SetColor(red, green, blue, alpha)
        end
    end,

    ---@param self df_roundedpanel
    ---@param red any
    ---@param green number|nil
    ---@param blue number|nil
    ---@param alpha number|nil
    SetBorderCornerColor = function(self, red, green, blue, alpha)
        if (not self.bHasBorder) then
            self:CreateBorder()
        end

        red, green, blue, alpha = detailsFramework:ParseColors(red, green, blue, alpha)

        for _, thisTexture in pairs(self.BorderCornerTextures) do
            thisTexture:SetVertexColor(red, green, blue, alpha)
        end

        for _, thisTexture in pairs(self.BorderEdgeTextures) do
            thisTexture:SetVertexColor(red, green, blue, alpha)
        end
    end,

    ---@param self df_roundedpanel
    ---@param red any
    ---@param green number|nil
    ---@param blue number|nil
    ---@param alpha number|nil
    SetColor = function(self, red, green, blue, alpha)
        red, green, blue, alpha = detailsFramework:ParseColors(red, green, blue, alpha)

        for _, thisTexture in pairs(self.CornerTextures) do
            thisTexture:SetVertexColor(red, green, blue, alpha)
        end

        for _, thisTexture in pairs(self.CenterTextures) do
            thisTexture:SetVertexColor(red, green, blue, alpha)
        end

        if (self.bHasBorder) then
            if (alpha < 0.98) then
                --if using borders, the two border textures overlaps making the alpha be darker than it should
                for _, thisTexture in pairs(self.BorderCornerTextures) do
                    thisTexture.MaskTexture:Show()
                end
            else
                for _, thisTexture in pairs(self.BorderCornerTextures) do
                    thisTexture.MaskTexture:Hide()
                end
            end
        end
    end,
}

local defaultOptions = {
    width = 200,
    height = 200,
    use_titlebar = false,
    use_scalebar = false,
    title = "",
    scale = 1,
    roundness = 0,
    color = defaultColorTable,
    border_color = defaultColorTable,
    corner_texture = [[Interface\CHARACTERFRAME\TempPortraitAlphaMaskSmall]],
}

local defaultPreset = {
    border_color = {.1, .1, .1, 0.834},
    color = {defaultRed, defaultGreen, defaultBlue},
    roundness = 3,
}

---create a regular panel with rounded corner
---@param parent frame
---@param name string|nil
---@param optionsTable table|nil
---@return df_roundedpanel
function detailsFramework:CreateRoundedPanel(parent, name, optionsTable)
    ---@type df_roundedpanel
    local newRoundedPanel = CreateFrame("frame", name, parent, "BackdropTemplate")
    newRoundedPanel:EnableMouse(true)
    newRoundedPanel.__dftype = "df_roundedpanel"
    newRoundedPanel.__rcorners = true

    detailsFramework:Mixin(newRoundedPanel, detailsFramework.RoundedCornerPanelMixin)
    detailsFramework:Mixin(newRoundedPanel, detailsFramework.OptionsFunctions)
    newRoundedPanel:BuildOptionsTable(defaultOptions, optionsTable or {})
    newRoundedPanel:RoundedCornerConstructor()
    newRoundedPanel:SetScript("OnSizeChanged", newRoundedPanel.OnSizeChanged)

    if (newRoundedPanel.options.use_titlebar) then
        ---@type df_roundedpanel
        local titleBar = detailsFramework:CreateRoundedPanel(newRoundedPanel, "$parentTitleBar", {height = 26})
        titleBar:SetPoint("top", newRoundedPanel, "top", 0, -7)
        newRoundedPanel.TitleBar = titleBar
        titleBar:SetRoundness(5)
        newRoundedPanel.bHasTitleBar = true
    end

    if (newRoundedPanel.options.use_scalebar) then
        detailsFramework:CreateScaleBar(newRoundedPanel.TitleBar or newRoundedPanel, newRoundedPanel.options)
        newRoundedPanel:SetScale(newRoundedPanel.options.scale)
    end

    newRoundedPanel:SetRoundness(newRoundedPanel.options.roundness)
    newRoundedPanel:SetColor(newRoundedPanel.options.color)
    newRoundedPanel:SetBorderCornerColor(newRoundedPanel.options.border_color)

    return newRoundedPanel
end

local applyPreset = function(frame, preset)
    if (preset.border_color) then
        frame:SetBorderCornerColor(preset.border_color)
    end

    if (preset.color) then
        frame:SetColor(preset.color)
    end

    if (preset.roundness) then
        frame:SetRoundness(preset.roundness)
    else
        frame:SetRoundness(1)
    end

    if (preset.use_titlebar) then
        frame:CreateTitleBar()
    end
end

---set a frame to have rounded corners following the settings passed by the preset table
---@param frame frame
---@param preset df_roundedpanel_preset?
function detailsFramework:AddRoundedCornersToFrame(frame, preset)
    frame = frame and frame.widget or frame
    assert(frame and frame.GetObjectType and frame.SetPoint, "AddRoundedCornersToFrame(frame): frame must be a frame object.")

    if (frame.__rcorners) then
        return
    end

    if (frame.GetBackdropBorderColor) then
        local red, green, blue, alpha = frame:GetBackdropBorderColor()
        if (alpha and alpha > 0) then
            detailsFramework:MsgWarning("AddRoundedCornersToFrame() applyed to a frame with a backdrop border.")
            detailsFramework:Msg(debugstack(2, 1, 0))
        end
    end

    ---@cast frame +df_roundedcornermixin
    detailsFramework:Mixin(frame, detailsFramework.RoundedCornerPanelMixin)

    if (not frame["BuildOptionsTable"]) then
        ---@cast frame +df_optionsmixin
        detailsFramework:Mixin(frame, detailsFramework.OptionsFunctions)
    end

    frame:BuildOptionsTable(defaultOptions, {})

    frame.options.width = frame:GetWidth()
    frame.options.height = frame:GetHeight()

    frame:RoundedCornerConstructor()
    frame:HookScript("OnSizeChanged", frame.OnSizeChanged)

    frame.__rcorners = true

    --handle preset
    if (preset and type(preset) == "table") then
        frame.options.horizontal_border_size_offset = preset.horizontal_border_size_offset
        applyPreset(frame, preset)
    else
        applyPreset(frame, defaultPreset)
    end
end

---test case:
C_Timer.After(1, function()

    if true then return end

    local DF = DetailsFramework

    local parent = UIParent
    local name = "NewRoundedCornerFrame"
    local optionsTable = {
        use_titlebar = true,
        use_scalebar = true,
        title = "Test",
        scale = 1.0,
    }

    ---@type df_roundedpanel
    local frame = _G[name] or DF:CreateRoundedPanel(parent, name, optionsTable)
    frame:SetSize(800, 600)
    frame:SetPoint("center", parent, "center", 0, 0)

    frame:SetColor(.1, .1, .1, 1)
    frame:SetTitleBarColor(.2, .2, .2, .5)
    frame:SetBorderCornerColor(.2, .2, .2, .5)
    frame:SetRoundness(0)

    local radiusSlider = DF:CreateSlider(frame, 120, 14, 0, 15, 1, frame.cornerRoundness, false, "RadiusBar", nil, nil, DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE"))
    radiusSlider:SetHook("OnValueChange", function(self, fixedValue, value)
        value = floor(value)
        if (frame.cornerRoundness == value) then
            return
        end
        frame:SetRoundness(value)
    end)

    local radiusText = frame:CreateFontString(nil, "overlay", "GameFontNormal")
    radiusText:SetText("Radius:")
    radiusText:SetPoint("bottomleft", radiusSlider.widget, "topleft", 0, 0)
    radiusSlider:SetPoint(10, -100)
end)



--[=[
    Snap System
    ------------
    Window-snapping behavior between movable frames, similar to UI editors.

    A snap group is created with detailsFramework:CreateSnapGroup(groupName, profileTable, options).
    Frames registered into the same group can snap to each other; frames in different groups never do.

    Public API (see the mixin further down for full docs):
        local snapGroup = detailsFramework:CreateSnapGroup("groupName", profileTable, options)
        snapGroup:RegisterFrame(frame[, id])
        snapGroup:UnregisterFrame(frame)
        snapGroup:Unsnap(frame)
        snapGroup:SetProfileTable(newTable)
        snapGroup:SetOptionsTable(newOptionsTable)
        snapGroup:Reset()

    Behavior summary:
        - The frame must already be movable; RegisterFrame wraps its existing OnDragStart/OnDragStop.
        - While dragging, edges within options.snap_distance of another group frame trigger a live
          glow preview on the two connecting edges (closest candidate wins, with hysteresis so it
          does not jitter).
        - On drop over a valid candidate the frames are anchored together (ClearAllPoints + SetPoint),
          forming a persistent chain. Dragging any member of a chain moves the whole cluster.
        - Snapped relationships and cluster positions persist to profileTable[groupName].
        - Links are only broken by the explicit Unsnap()/UnregisterFrame()/Reset() API.
--]=]

--constants
--the four snappable sides mapped to the side they connect to on the other frame.
--sides are stored lowercase so they can be passed straight to frame:SetPoint without conversion.
local SNAP_OPPOSITE = {left = "right", right = "left", top = "bottom", bottom = "top"}
--which axis each side lives on; the gap between connecting edges is measured along this axis.
local SNAP_AXIS = {left = "x", right = "x", top = "y", bottom = "y"}

--default options for a snap group; merged with the caller's overrides on creation / SetOptionsTable().
--keys use snake_case because this table is exposed to the addon profile as user configuration.
local SNAP_DEFAULT_OPTIONS = {
    snap_distance = 12,         --max screen-pixel gap between two edges to be treated as a snap candidate
    perpendicular_align = true, --when true, also align the perpendicular edges if they are within snap_distance
    hysteresis = 4,             --a new candidate must be this many pixels closer than the current one to replace it
    update_interval = 0.015,    --seconds between proximity scans while dragging (throttle, avoids per-frame cost)
    glow_thickness = 3,         --thickness in pixels of the edge highlight
    glow_color = {1, 0.82, 0, 0.9},
    enabled_sides = {left = true, right = true, top = true, bottom = true},
}

--builds a fresh options table: a deep-ish copy of the defaults with the caller overrides applied on top.
local snapMergeOptions = function(overrides)
    local options = {}

    for key, value in pairs(SNAP_DEFAULT_OPTIONS) do
        if (type(value) == "table") then
            local copy = {}
            for innerKey, innerValue in pairs(value) do
                copy[innerKey] = innerValue
            end
            options[key] = copy
        else
            options[key] = value
        end
    end

    if (overrides) then
        for key, value in pairs(overrides) do
            options[key] = value
        end
    end

    return options
end

--returns the frame bounds in absolute screen pixels (effective scale applied) as left, bottom, right, top.
--converting to screen pixels lets frames living under parents with different scales be compared directly.
local snapGetScreenRect = function(frame)
    local left = frame:GetLeft()
    local bottom = frame:GetBottom()

    if (not left or not bottom) then
        return nil
    end

    local scale = frame:GetEffectiveScale()
    left = left * scale
    bottom = bottom * scale

    local width = frame:GetWidth() * scale
    local height = frame:GetHeight() * scale
    return left, bottom, left + width, bottom + height
end

--lazily builds (or returns) the 4 edge-highlight textures used to preview a snap on a frame.
--the textures are parented to the frame so they inherit its scale and strata automatically.
local snapGetGlowTextures = function(frame)
    if (frame.__snapGlow) then
        return frame.__snapGlow
    end

    local glow = {}
    for side in pairs(SNAP_OPPOSITE) do
        local texture = frame:CreateTexture(nil, "overlay")
        texture:SetColorTexture(1, 1, 1, 1)
        texture:Hide()
        glow[side] = texture
    end

    frame.__snapGlow = glow
    return glow
end

--shows the highlight texture for a single side (positioned along that edge) and hides the other three.
local snapShowGlow = function(frame, side, options)
    local glow = snapGetGlowTextures(frame)
    local thickness = options.glow_thickness
    local color = options.glow_color

    for thisSide, texture in pairs(glow) do
        if (thisSide == side) then
            texture:ClearAllPoints()
            if (thisSide == "left") then
                texture:SetPoint("topleft", frame, "topleft", 0, 0)
                texture:SetPoint("bottomleft", frame, "bottomleft", 0, 0)
                texture:SetWidth(thickness)

            elseif (thisSide == "right") then
                texture:SetPoint("topright", frame, "topright", 0, 0)
                texture:SetPoint("bottomright", frame, "bottomright", 0, 0)
                texture:SetWidth(thickness)

            elseif (thisSide == "top") then
                texture:SetPoint("topleft", frame, "topleft", 0, 0)
                texture:SetPoint("topright", frame, "topright", 0, 0)
                texture:SetHeight(thickness)

            elseif (thisSide == "bottom") then
                texture:SetPoint("bottomleft", frame, "bottomleft", 0, 0)
                texture:SetPoint("bottomright", frame, "bottomright", 0, 0)
                texture:SetHeight(thickness)
            end

            texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
            texture:Show()
        else
            texture:Hide()
        end
    end
end

--hides every highlight texture on a frame (called when there is no candidate or after a drop).
local snapHideGlow = function(frame)
    if (frame.__snapGlow) then
        for side, texture in pairs(frame.__snapGlow) do
            texture:Hide()
        end
    end
end

--evaluates one side pairing: the dragged frame's `side` edge connecting to the other frame's
--opposite edge. returns the gap (screen pixels) between the two connecting edges, or nil when the
--frames do not overlap enough on the perpendicular axis to be facing each other.
--rects are passed as (left, bottom, right, top) in screen pixels.
local snapEvaluatePair = function(draggedLeft, draggedBottom, draggedRight, draggedTop, otherLeft, otherBottom, otherRight, otherTop, side, snapDistance)
    local axis = SNAP_AXIS[side]
    local gap, perpendicularOverlap

    if (axis == "x") then
        --left/right pairings connect along x: measure the horizontal gap between the connecting edges
        if (side == "left") then
            gap = math.abs(draggedLeft - otherRight)       --dragged left edge meets other right edge
        else
            gap = math.abs(draggedRight - otherLeft)       --dragged right edge meets other left edge
        end
        --the perpendicular axis is vertical: how much the two frames share vertically
        perpendicularOverlap = math.min(draggedTop, otherTop) - math.max(draggedBottom, otherBottom)

    else
        --top/bottom pairings connect along y: measure the vertical gap between the connecting edges
        if (side == "bottom") then
            gap = math.abs(draggedBottom - otherTop)       --dragged bottom edge meets other top edge
        else
            gap = math.abs(draggedTop - otherBottom)       --dragged top edge meets other bottom edge
        end
        --the perpendicular axis is horizontal
        perpendicularOverlap = math.min(draggedRight, otherRight) - math.max(draggedLeft, otherLeft)
    end

    --require the frames to be roughly facing each other. a small negative overlap is tolerated
    --(within snapDistance) so frames approaching corner-first still register as candidates.
    if (perpendicularOverlap < -snapDistance) then
        return nil
    end

    return gap
end

--scans every other frame in the group for the closest valid snap candidate to draggedFrame.
--frames belonging to draggedFrame's own cluster are skipped (a frame cannot snap onto its own chain).
--returns a candidate table {targetFrame, targetData, side, theirSide, gap} or nil.
local snapFindCandidate = function(group, draggedFrame)
    local options = group.options
    local snapDistance = options.snap_distance
    local enabledSides = options.enabled_sides

    local draggedLeft, draggedBottom, draggedRight, draggedTop = snapGetScreenRect(draggedFrame)
    if (not draggedLeft) then
        return nil
    end

    --frames that belong to the cluster currently being dragged are invalid targets
    local clusterLookup = group.__dragClusterLookup

    local best, bestGap
    local frames = group.registeredFrames
    for i = 1, #frames do
        local frameData = frames[i]
        local otherFrame = frameData.Frame
        if (otherFrame ~= draggedFrame and otherFrame:IsVisible() and not (clusterLookup and clusterLookup[otherFrame])) then
            local otherLeft, otherBottom, otherRight, otherTop = snapGetScreenRect(otherFrame)
            if (otherLeft) then
                for side in pairs(SNAP_OPPOSITE) do
                    if (enabledSides[side]) then
                        local gap = snapEvaluatePair(draggedLeft, draggedBottom, draggedRight, draggedTop, otherLeft, otherBottom, otherRight, otherTop, side, snapDistance)
                        if (gap and gap <= snapDistance and (not bestGap or gap < bestGap)) then
                            bestGap = gap
                            best = best or {}
                            best.TargetFrame = otherFrame
                            best.targetData = frameData
                            best.side = side
                            best.theirSide = SNAP_OPPOSITE[side]
                            best.gap = gap
                        end
                    end
                end
            end
        end
    end
    return best
end

--updates the live snap preview while dragging: resolves the nearest candidate, applies hysteresis so
--the chosen edges stay stable instead of flickering, and moves the edge glow to the connecting edges
--of both frames. clears the preview immediately when no candidate exists.
local snapUpdatePreview = function(group, draggedFrame)
    local newCandidate = snapFindCandidate(group, draggedFrame)
    local current = group.currentCandidate

    if (newCandidate) then
        if (current and current.TargetFrame == newCandidate.TargetFrame and current.side == newCandidate.side) then
            --same pairing as last frame: just refresh the measured gap, the glow is already in place
            current.gap = newCandidate.gap
            return
        end

        if (current and newCandidate.gap >= current.gap - group.options.hysteresis) then
            --a different pairing exists but is not meaningfully closer, keep the current preview stable
            return
        end

        --switch the preview to the new (closer) candidate
        if (current) then
            snapHideGlow(draggedFrame)
            snapHideGlow(current.TargetFrame)
        end

        snapShowGlow(draggedFrame, newCandidate.side, group.options)
        snapShowGlow(newCandidate.TargetFrame, newCandidate.theirSide, group.options)

        group.currentCandidate = newCandidate

    elseif (current) then
        --no candidate anymore: remove the preview right away
        snapHideGlow(draggedFrame)
        snapHideGlow(current.TargetFrame)
        group.currentCandidate = nil
    end
end

--walks the snap-link graph starting from frameData and returns a flat list of every frameData in the
--same cluster, plus a lookup table {frame = frameData}. used to move clusters as a unit and to
--forbid a frame from snapping onto a frame already in its own chain.
local snapCollectCluster = function(frameData)
    local list = {}
    local lookup = {}
    local queue = {frameData}
    lookup[frameData.Frame] = frameData

    while (#queue > 0) do
        local current = table.remove(queue)
        list[#list+1] = current
        for side, link in pairs(current.links) do
            if (not lookup[link.Target]) then
                lookup[link.Target] = link.targetData
                queue[#queue+1] = link.targetData
            end
        end
    end

    return list, lookup
end

--detaches a frame from whatever it is anchored to and re-pins it to UIParent at the exact same
--on-screen spot, so it can act as the absolute-positioned root of its cluster.
local snapMakeAbsolute = function(frame)
    local left, bottom = frame:GetLeft(), frame:GetBottom()
    if (not left) then
        return
    end

    --convert the frame's own-space left/bottom into UIParent space so the SetPoint is pixel-exact
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    frame:ClearAllPoints()
    frame:SetPoint("bottomleft", UIParent, "bottomleft", left * scale, bottom * scale)
end

--re-applies the SetPoint chain for an entire cluster as a spanning tree rooted at rootData.
--the root keeps an absolute point to UIParent; every other member is anchored to the neighbour it
--was first reached from. links that would close a cycle are ignored for anchoring, which guarantees
--there are never recursive or broken point chains.
local snapRebuildCluster = function(rootData)
    local rootFrame = rootData.Frame

    --the root holds the cluster's absolute position; make sure it is not anchored to a member
    snapMakeAbsolute(rootFrame)
    rootData.isRoot = true

    local visited = {[rootFrame] = true}
    local queue = {rootData}

    while (#queue > 0) do
        local parentData = table.remove(queue, 1)
        local parentFrame = parentData.Frame

        for side, link in pairs(parentData.links) do
            local childData = link.targetData
            local childFrame = link.Target

            if (not visited[childFrame]) then
                visited[childFrame] = true

                --find the child's own link pointing back at this parent and use it to anchor the child
                for childSide, childLink in pairs(childData.links) do
                    if (childLink.Target == parentFrame) then
                        childFrame:ClearAllPoints()
                        childFrame:SetPoint(childLink.mySide, parentFrame, childLink.theirSide, childLink.offsetX, childLink.offsetY)
                        break
                    end
                end

                childData.isRoot = false
                queue[#queue+1] = childData
            end
        end
    end
end

--returns the current root frameData of frameData's cluster, falling back to frameData itself when
--none of the members is flagged as root (e.g. right after links were cut).
local snapGetRoot = function(frameData)
    local list = snapCollectCluster(frameData)
    for i = 1, #list do
        if (list[i].isRoot) then
            return list[i]
        end
    end
    return frameData
end

--computes the (offsetX, offsetY) offset for draggedFrame:SetPoint(side, targetFrame, theirSide, offsetX, offsetY).
--the connecting (primary) axis is always flush (offset 0). the perpendicular axis preserves the
--drop-time position, unless options.perpendicular_align is set and a perpendicular pair of edges is
--within snap_distance, in which case those edges are aligned flush instead.
local snapComputeOffset = function(draggedFrame, targetFrame, side, options)
    local draggedLeft, draggedBottom, draggedRight, draggedTop = snapGetScreenRect(draggedFrame)
    local otherLeft, otherBottom, otherRight, otherTop = snapGetScreenRect(targetFrame)
    local snapDistance = options.snap_distance
    --offsets passed to SetPoint live in the dragged frame's own coordinate space, so screen-pixel
    --deltas are divided by its effective scale to convert them back.
    local scale = draggedFrame:GetEffectiveScale()
    local offsetX, offsetY = 0, 0

    if (SNAP_AXIS[side] == "x") then
        --connecting axis is x (flush, offsetX = 0); resolve the vertical (perpendicular) offset
        local draggedHalfHeight = (draggedTop - draggedBottom) / 2
        local draggedMidY = (draggedBottom + draggedTop) / 2
        local targetMidY = (otherBottom + otherTop) / 2
        local screenDeltaY = draggedMidY - targetMidY        --default: preserve current vertical position

        if (options.perpendicular_align) then
            if (math.abs(draggedTop - otherTop) <= snapDistance) then
                screenDeltaY = otherTop - targetMidY - draggedHalfHeight        --align the top edges
            elseif (math.abs(draggedBottom - otherBottom) <= snapDistance) then
                screenDeltaY = otherBottom - targetMidY + draggedHalfHeight     --align the bottom edges
            end
        end

        offsetY = screenDeltaY / scale
    else
        --connecting axis is y (flush, offsetY = 0); resolve the horizontal (perpendicular) offset
        local draggedHalfWidth = (draggedRight - draggedLeft) / 2
        local draggedMidX = (draggedLeft + draggedRight) / 2
        local targetMidX = (otherLeft + otherRight) / 2
        local screenDeltaX = draggedMidX - targetMidX        --default: preserve current horizontal position

        if (options.perpendicular_align) then
            if (math.abs(draggedLeft - otherLeft) <= snapDistance) then
                screenDeltaX = otherLeft - targetMidX + draggedHalfWidth        --align the left edges
            elseif (math.abs(draggedRight - otherRight) <= snapDistance) then
                screenDeltaX = otherRight - targetMidX - draggedHalfWidth       --align the right edges
            end
        end

        offsetX = screenDeltaX / scale
    end

    return offsetX, offsetY
end

---@class snaplink : table a directed snap relationship: frame:SetPoint(mySide, Target, theirSide, offsetX, offsetY)
---@field Target frame the frame on the other end of the link
---@field targetData snapframedata the registration data of the target frame
---@field mySide string the side of the owning frame used as the anchor point
---@field theirSide string the side of the target frame the owning frame anchors to
---@field offsetX number x offset of the SetPoint, in the owning frame's coordinate space
---@field offsetY number y offset of the SetPoint, in the owning frame's coordinate space

---@class snapframedata : table the per-frame registration record stored by a snap group
---@field Frame frame the registered frame
---@field id string the stable identifier (frame name or explicit id) used for persistence
---@field links table<string, snaplink> directed snap links keyed by the owning frame's side
---@field isRoot boolean true when this frame holds its cluster's absolute UIParent anchor
---@field group snapgroup the owning snap group
---@field OrigOnDragStart function|nil the frame's OnDragStart script captured before wrapping
---@field OrigOnDragStop function|nil the frame's OnDragStop script captured before wrapping

---@class snapcandidate : table a resolved snap target evaluated while dragging
---@field TargetFrame frame the frame the dragged frame would snap to
---@field targetData snapframedata the registration data of the target frame
---@field side string the dragged frame's side that would connect
---@field theirSide string the target frame's side that would connect
---@field gap number the screen-pixel gap between the two connecting edges

---@class snapgroup : table an isolated snap group created by detailsFramework:CreateSnapGroup()
---@field groupName string identifies the group and keys its data inside profileTable
---@field profileTable table|nil saved-variables table for persistence (data at profileTable[groupName])
---@field options table the active options (snap defaults merged with caller overrides)
---@field registeredFrames snapframedata[] every frame currently registered into the group
---@field framesByObject table<frame, snapframedata> registration lookup keyed by frame object
---@field framesById table<string, snapframedata> registration lookup keyed by persistent id
---@field currentCandidate snapcandidate|nil the snap candidate currently being previewed, if any
---@field UpdateFrame frame drives the throttled proximity scan while a drag is active
---@field __dragFrameData snapframedata|nil the frame being dragged right now, if any
---@field __dragClusterLookup table|nil lookup of the cluster being dragged (excluded from candidates)
---@field __dragElapsed number time accumulator for throttling the proximity scan
---@field RegisterFrame fun(self: snapgroup, frame: frame, id: string?)
---@field UnregisterFrame fun(self: snapgroup, frame: frame)
---@field Unsnap fun(self: snapgroup, frame: frame)
---@field RemoveLink fun(self: snapgroup, frameData: snapframedata, side: string): snapframedata|nil
---@field SetProfileTable fun(self: snapgroup, newTable: table)
---@field SetOptionsTable fun(self: snapgroup, newOptionsTable: table?)
---@field Reset fun(self: snapgroup)
---@field OnFrameDragStart fun(self: snapgroup, frameData: snapframedata, ...: any)
---@field OnFrameDragStop fun(self: snapgroup, frameData: snapframedata, ...: any)
---@field OnDragUpdate fun(self: snapgroup, deltaTime: number)
---@field Snap fun(self: snapgroup, frameData: snapframedata, candidate: snapcandidate)
---@field SavePersistent fun(self: snapgroup)
---@field TryRestore fun(self: snapgroup)

--the mixin holding every public (and a few internal) snap group methods; applied to each group
--instance returned by detailsFramework:CreateSnapGroup().
local snapGroupMixin = {
    ---registers a frame into the group so it can snap to (and be snapped by) other group frames.
    ---the frame must already be movable (set up via RegisterForDrag/SetMovable); its existing
    ---OnDragStart/OnDragStop scripts are wrapped, not replaced.
    ---@param self snapgroup
    ---@param frame frame the frame (or a DetailsFramework widget wrapping one) to register
    ---@param id string|nil stable identifier; required only when the frame has no name
    RegisterFrame = function(self, frame, id)
        frame = frame.widget or frame
        --resolve the persistent identifier: frame name first, then the explicit id, else error
        id = frame:GetName() or id
        assert(id, "snapGroup:RegisterFrame(frame[, id]): the frame has no name, an 'id' must be provided.")

        if (self.framesByObject[frame]) then
            return
        end

        if (frame.IsMovable and not frame:IsMovable()) then
            detailsFramework:MsgWarning("CreateSnapGroup: RegisterFrame() received a frame that is not movable; snapping needs the frame to be draggable.")
        end

        ---@type snapframedata
        local frameData = {
            Frame = frame,
            id = id,
            links = {},     --directed snap links keyed by this frame's side -> {Target, targetData, mySide, theirSide, offsetX, offsetY}
            isRoot = true,  --a lone frame is the root of its own (single member) cluster
            group = self,
        }

        self.framesByObject[frame] = frameData
        self.framesById[id] = frameData
        self.registeredFrames[#self.registeredFrames+1] = frameData

        --wrap the frame's current drag scripts so existing behavior is preserved
        frameData.OrigOnDragStart = frame:GetScript("OnDragStart")
        frameData.OrigOnDragStop = frame:GetScript("OnDragStop")

        frame:SetScript("OnDragStart", function(_, ...)
            self:OnFrameDragStart(frameData, ...)
        end)

        frame:SetScript("OnDragStop", function(_, ...)
            self:OnFrameDragStop(frameData, ...)
        end)

        --a newly registered frame may complete a relationship described by the saved profile
        self:TryRestore()
    end,

    ---removes a frame from the group: cuts its snap links, restores its original drag scripts and
    ---hides any leftover glow. The rest of its former cluster stays intact.
    ---@param self snapgroup
    ---@param frame frame
    UnregisterFrame = function(self, frame)
        frame = frame.widget or frame
        local frameData = self.framesByObject[frame]
        if (not frameData) then
            return
        end

        --cutting all links keeps the remaining cluster members validly anchored
        self:Unsnap(frame)

        --restore whatever drag scripts the frame had before it was registered
        frame:SetScript("OnDragStart", frameData.OrigOnDragStart)
        frame:SetScript("OnDragStop", frameData.OrigOnDragStop)
        snapHideGlow(frame)

        self.framesByObject[frame] = nil
        self.framesById[frameData.id] = nil

        for i = #self.registeredFrames, 1, -1 do
            if (self.registeredFrames[i] == frameData) then
                table.remove(self.registeredFrames, i)
                break
            end
        end
    end,

    ---breaks every snap link of a frame, leaving it free-standing at its current position.
    ---this is the only way (besides UnregisterFrame/Reset) to detach a snapped frame.
    ---@param self snapgroup
    ---@param frame frame
    Unsnap = function(self, frame)
        frame = frame.widget or frame

        local frameData = self.framesByObject[frame]
        if (not frameData) then
            return
        end

        --remember the neighbours before cutting so their clusters can be rebuilt afterwards
        local neighbours = {}
        for side, link in pairs(frameData.links) do
            neighbours[#neighbours+1] = link.targetData
        end

        --cut every link on this frame (both directions are removed by RemoveLink)
        for side in pairs(frameData.links) do
            self:RemoveLink(frameData, side)
        end

        --this frame now stands alone
        snapMakeAbsolute(frame)
        frameData.isRoot = true

        --each former neighbour may now head its own cluster; rebuild from a fresh root
        for i = 1, #neighbours do
            local neighbourData = neighbours[i]
            if (self.framesByObject[neighbourData.Frame]) then
                snapRebuildCluster(snapGetRoot(neighbourData))
            end
        end

        self:SavePersistent()
    end,

    ---removes a single directed link (and its reciprocal) from frameData on the given side.
    ---internal helper; returns the frameData that was on the other end of the link, if any.
    ---@param self snapgroup
    ---@param frameData snapframedata
    ---@param side string
    ---@return snapframedata|nil
    RemoveLink = function(self, frameData, side)
        local link = frameData.links[side]
        if (not link) then
            return nil
        end

        local otherData = link.targetData
        frameData.links[side] = nil

        --remove the matching reciprocal link stored on the other frame
        for otherSide, otherLink in pairs(otherData.links) do
            if (otherLink.Target == frameData.Frame) then
                otherData.links[otherSide] = nil
            end
        end

        return otherData
    end,

    ---swaps the group's profile table at runtime and re-attempts a restore from it.
    ---@param self snapgroup
    ---@param newTable table
    SetProfileTable = function(self, newTable)
        self.profileTable = newTable
        self:TryRestore()
    end,

    ---swaps the group's options at runtime; the new table is merged on top of the defaults.
    ---@param self snapgroup
    ---@param newOptionsTable table|nil
    SetOptionsTable = function(self, newOptionsTable)
        self.options = snapMergeOptions(newOptionsTable)
    end,

    ---tears the group down to a blank, reusable state: unregisters every frame, drops the profile
    ---and options references and clears the current preview. The data already written into the old
    ---profile table is left untouched (the caller owns it). Use this on addon profile switches.
    ---@param self snapgroup
    Reset = function(self)
        for i = #self.registeredFrames, 1, -1 do
            self:UnregisterFrame(self.registeredFrames[i].Frame)
        end

        table.wipe(self.framesByObject)
        table.wipe(self.framesById)
        table.wipe(self.registeredFrames)
        self.profileTable = nil
        self.options = snapMergeOptions(nil)
        self.currentCandidate = nil
        self.__dragFrameData = nil
        self.__dragClusterLookup = nil
        self.UpdateFrame:Hide()
    end,

    ---wrapped OnDragStart handler. Starts moving the frame (or its whole cluster) and kicks off the
    ---throttled proximity scan. Internal — installed by RegisterFrame.
    ---@param self snapgroup
    ---@param frameData snapframedata
    OnFrameDragStart = function(self, frameData, ...)
        local frame = frameData.Frame
        --discover the cluster being grabbed: it must move as a unit and be excluded from candidates
        local clusterList, clusterLookup = snapCollectCluster(frameData)
        self.__dragFrameData = frameData
        self.__dragClusterLookup = clusterLookup
        self.currentCandidate = nil

        if (#clusterList > 1) then
            --multi-frame cluster: make the grabbed frame the temporary root so the whole tree is
            --SetPoint-chained to it, then StartMoving it -> the entire cluster follows the cursor.
            snapRebuildCluster(frameData)
            frame:StartMoving()

        else
            --solo frame: run its own original OnDragStart (StartMoving plus any custom state)
            if (frameData.OrigOnDragStart) then
                frameData.OrigOnDragStart(frame, ...)
            else
                frame:StartMoving()
            end
        end

        --begin the throttled proximity scan (the OnUpdate script is installed on the group's updateFrame)
        self.__dragElapsed = 0
        self.UpdateFrame:Show()
    end,

    ---wrapped OnDragStop handler. Stops the movement, then either applies the previewed snap or
    ---leaves the frame free-standing at its dropped position. Internal — installed by RegisterFrame.
    ---@param self snapgroup
    ---@param frameData snapframedata
    OnFrameDragStop = function(self, frameData, ...)
        local frame = frameData.Frame
        self.UpdateFrame:Hide()

        --stop the movement through the same path that started it
        local clusterList = snapCollectCluster(frameData)
        if (#clusterList > 1) then
            frame:StopMovingOrSizing()
        else
            if (frameData.OrigOnDragStop) then
                frameData.OrigOnDragStop(frame, ...)
            else
                frame:StopMovingOrSizing()
            end
        end

        local candidate = self.currentCandidate

        --clear the preview glow regardless of the outcome
        snapHideGlow(frame)
        if (candidate) then
            snapHideGlow(candidate.TargetFrame)
        end

        self.currentCandidate = nil
        self.__dragFrameData = nil
        self.__dragClusterLookup = nil

        if (candidate) then
            --a valid candidate was being previewed: anchor the frames together
            self:Snap(frameData, candidate)
        else
            --no candidate: the grabbed frame is the temp root of its cluster; normalize it to an
            --absolute UIParent anchor at the dropped position and re-chain its cluster.
            snapRebuildCluster(frameData)
        end

        self:SavePersistent()
    end,

    ---throttled per-frame proximity scan, driven by the group's updateFrame OnUpdate while dragging.
    ---Internal.
    ---@param self snapgroup
    ---@param deltaTime number
    OnDragUpdate = function(self, deltaTime)
        local frameData = self.__dragFrameData
        if (not frameData) then
            return
        end

        self.__dragElapsed = (self.__dragElapsed or 0) + deltaTime
        if (self.__dragElapsed < self.options.update_interval) then
            return
        end

        self.__dragElapsed = 0
        snapUpdatePreview(self, frameData.Frame)
    end,

    ---anchors frameData to a resolved snap candidate, merging the two clusters into one chain.
    ---Internal — called by OnFrameDragStop when a valid preview exists on drop.
    ---@param self snapgroup
    ---@param frameData snapframedata
    ---@param candidate snapcandidate
    Snap = function(self, frameData, candidate)
        local draggedFrame = frameData.Frame
        local targetData = candidate.targetData
        local targetFrame = candidate.TargetFrame
        local side = candidate.side
        local theirSide = candidate.theirSide

        --capture the target side's existing root BEFORE adding the link; it stays the merged
        --cluster's root, so the target's chain (and on-screen position) is the stable anchor.
        local rootData = snapGetRoot(targetData)

        --drop any link already occupying the sides about to be reused, to avoid conflicting points
        local orphanA = self:RemoveLink(frameData, side)
        local orphanB = self:RemoveLink(targetData, theirSide)

        --compute the anchor offset and store the link in both directions (reciprocal offsets negate)
        local offsetX, offsetY = snapComputeOffset(draggedFrame, targetFrame, side, self.options)
        frameData.links[side] = {
            Target = targetFrame, targetData = targetData,
            mySide = side, theirSide = theirSide, offsetX = offsetX, offsetY = offsetY,
        }
        targetData.links[theirSide] = {
            Target = draggedFrame, targetData = frameData,
            mySide = theirSide, theirSide = side, offsetX = -offsetX, offsetY = -offsetY,
        }

        --rebuild the merged cluster as a spanning tree rooted at the target side's root
        snapRebuildCluster(rootData)

        --any frame orphaned by a replaced link becomes (or rejoins) its own valid cluster
        if (orphanA) then
            snapRebuildCluster(snapGetRoot(orphanA))
        end
        if (orphanB) then
            snapRebuildCluster(snapGetRoot(orphanB))
        end
    end,

    ---writes the group's current snap links and cluster-root positions into profileTable[groupName].
    ---Internal — called after every structural change. No-op when the group has no profile table.
    ---@param self snapgroup
    SavePersistent = function(self)
        if (not self.profileTable) then
            return
        end

        --everything for this group lives under one key so a single table can host many groups
        local data = {}
        self.profileTable[self.groupName] = data

        local frames = self.registeredFrames
        for i = 1, #frames do
            local frameData = frames[i]
            local entry = {links = {}}

            for side, link in pairs(frameData.links) do
                entry.links[side] = {
                    targetId = link.targetData.id,
                    mySide = link.mySide, theirSide = link.theirSide,
                    offsetX = link.offsetX, offsetY = link.offsetY,
                }
            end

            --cluster roots also persist their absolute screen position so the cluster reappears in place
            if (frameData.isRoot) then
                local frame = frameData.Frame
                local left, bottom = frame:GetLeft(), frame:GetBottom()
                if (left) then
                    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
                    entry.point = {x = left * scale, y = bottom * scale}
                end
            end

            data[frameData.id] = entry
        end
    end,

    ---rebuilds snap links and cluster positions from the profile table. Safe to call repeatedly:
    ---it only creates links whose two frames are both registered, so it can be re-run as more
    ---frames register (RegisterFrame calls it automatically). The addon may also call it explicitly
    ---once all of its frames have been registered.
    ---@param self snapgroup
    TryRestore = function(self)
        if (not self.profileTable) then
            return
        end

        local data = self.profileTable[self.groupName]
        if (not data) then
            return
        end

        --recreate links, but only between frames that are both currently registered
        for id, entry in pairs(data) do
            local frameData = self.framesById[id]
            if (frameData and entry.links) then
                for side, savedLink in pairs(entry.links) do
                    local targetData = self.framesById[savedLink.targetId]
                    if (targetData and not frameData.links[side]) then
                        frameData.links[side] = {
                            Target = targetData.Frame, targetData = targetData,
                            mySide = savedLink.mySide, theirSide = savedLink.theirSide,
                            offsetX = savedLink.offsetX, offsetY = savedLink.offsetY,
                        }
                    end
                end
            end
        end

        --place each saved root at its stored position, then rebuild its cluster so children chain off it
        for id, entry in pairs(data) do
            local frameData = self.framesById[id]
            if (frameData and entry.point) then
                local frame = frameData.Frame
                local scale = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
                frame:ClearAllPoints()
                frame:SetPoint("bottomleft", UIParent, "bottomleft", entry.point.x * scale, entry.point.y * scale)
                frameData.isRoot = true
                snapRebuildCluster(frameData)
            end
        end
    end,
}

---creates a new snap group. Frames registered into the same group can snap to each other; frames
---in different groups never interact. Each call returns an isolated instance (DetailsFramework
---mixin pattern), so create as many groups as the addon needs.
---@param groupName string identifies the group; also the key the group's data is stored under inside profileTable
---@param profileTable table|nil saved-variables table for persistence; this group's data lives at profileTable[groupName]
---@param options table|nil overrides merged on top of the snap defaults (snap_distance, perpendicular_align, hysteresis, ...)
---@return snapgroup
function detailsFramework:CreateSnapGroup(groupName, profileTable, options)
    assert(type(groupName) == "string", "detailsFramework:CreateSnapGroup(groupName): groupName must be a string.")

    ---@type snapgroup
    ---@diagnostic disable-next-line: missing-fields
    local snapGroup = {}
    snapGroup.groupName = groupName
    snapGroup.profileTable = profileTable
    snapGroup.options = snapMergeOptions(options)
    snapGroup.registeredFrames = {}
    snapGroup.framesByObject = {}
    snapGroup.framesById = {}
    snapGroup.currentCandidate = nil
    snapGroup.__dragElapsed = 0

    --a dedicated frame drives the throttled proximity scan; shown only while a drag is in progress
    snapGroup.UpdateFrame = CreateFrame("frame", nil, UIParent)
    snapGroup.UpdateFrame:Hide()
    snapGroup.UpdateFrame:SetScript("OnUpdate", function(_, deltaTime)
        snapGroup:OnDragUpdate(deltaTime)
    end)

    detailsFramework:Mixin(snapGroup, snapGroupMixin)

    --if a profile table was supplied, restore whatever relationships it already describes
    snapGroup:TryRestore()

    return snapGroup
end

--[=[
    minimal working example: two draggable frames that snap to each other.
    guarded by the EXAMPLE_ENABLED constant so it stays inert in production; flip it to true to try it live.

    drag one frame near the other's edge -> the two touching edges glow; release to snap them into a
    chain. moving either frame afterwards moves the whole cluster together. snapGroup:Unsnap(frame)
    detaches a frame again.
--]=]
--constants
local EXAMPLE_ENABLED = false

C_Timer.After(1, function()
    if (not EXAMPLE_ENABLED) then
        return
    end

    --create a snap group with an in-memory profile table; in real usage pass the addon's saved vars
    local exampleProfile = {}
    local snapGroup = detailsFramework:CreateSnapGroup("SnapExample", exampleProfile, {snap_distance = 16})

    --builds one demo frame, makes it draggable and registers it into the snap group above.
    local createDemoFrame = function(name, red, green, blue)
        local frame = CreateFrame("frame", name, UIParent, "BackdropTemplate")
        frame:SetSize(160, 120)
        frame:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]]})
        frame:SetBackdropColor(red, green, blue, 1)

        --the frame must already be draggable before being registered; RegisterFrame wraps these hooks
        detailsFramework:MakeDraggable(frame)
        snapGroup:RegisterFrame(frame)
        return frame
    end

    local frameA = createDemoFrame("DFSnapExampleA", 0.2, 0.4, 0.7)
    local frameB = createDemoFrame("DFSnapExampleB", 0.7, 0.3, 0.2)
    
    frameA:SetPoint("center", UIParent, "center", -120, 0)
    frameB:SetPoint("center", UIParent, "center", 120, 0)
end)

--[=[
    Optimization strategies (already applied / easy to extend):
        - Proximity scans run only while a drag is active and are throttled by options.update_interval,
          never every frame and never when idle.
        - Each scan is group-scoped: it iterates only the frames registered in that group, not a
          full-screen sweep. Splitting frames into several smaller groups further cuts the cost.
        - Edge math uses simple O(1) distance/overlap comparisons per side; no allocations in the hot
          path except the single reused candidate table.
        - Hysteresis (options.hysteresis) keeps the chosen candidate stable, avoiding repeated glow
          texture re-anchoring while the cursor hovers between two edges.
        - For very large groups, a spatial bucket / grid index over frame centers could replace the
          linear scan in snapFindCandidate without changing the public API.

    Extending later:
        - Corner snapping: add diagonal pairings (e.g. TOPLEFT<->TOPLEFT) in SNAP_OPPOSITE/SNAP_AXIS
          and a matching branch in snapEvaluatePair; the preview/anchor pipeline is already generic.
        - Grid snapping: add an optional virtual grid target to snapFindCandidate (snap edges to the
          nearest grid line when no frame candidate is closer), reusing snapComputeOffset for the math.
        - Same-side aligned snapping is already covered by options.perpendicular_align.
--]=]

