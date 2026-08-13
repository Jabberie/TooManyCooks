local addonName, TMC = ...

-- ============================================================
-- UI constants
-- ============================================================

local DEFAULT_X = 0
local DEFAULT_Y = 100

local BOX_WIDTH = 95
local BOX_HEIGHT = 54
local BOX_GAP = 10

local SIDE_PADDING = 10
local HEADER_HEIGHT = 30
local BOTTOM_PADDING = 8

-- ============================================================
-- UI state
-- ============================================================

TMC.ui = nil
TMC.title = nil
TMC.progress = nil
TMC.flipButton = nil
TMC.closeButton = nil
TMC.boxes = TMC.boxes or {}

TMC.isFlipped = false
TMC.activeIngredient = nil

-- ============================================================
-- Forward declarations
-- ============================================================

local CreateUI
local RebuildBoxes
local UpdateBoxPositions

-- ============================================================
-- Frame sizing
-- ============================================================

local function UpdateFrameSize()

    if not TMC.ui
        or not TMC.currentEncounter
    then
        return
    end

    local count =
        #TMC.currentEncounter.normalOrder

    local width =
        (SIDE_PADDING * 2)
        + (count * BOX_WIDTH)
        + ((count - 1) * BOX_GAP)

    local height =
        HEADER_HEIGHT
        + BOX_HEIGHT
        + BOTTOM_PADDING
        + 8

    TMC.ui:SetSize(
        width,
        height
    )
end

-- ============================================================
-- Create main UI
-- ============================================================

CreateUI = function()

    if TMC.ui then
        return
    end

    local ui = CreateFrame(
        "Frame",
        "TooManyCooksFrame",
        UIParent,
        "BackdropTemplate"
    )

    TMC.ui = ui

    ui:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        DEFAULT_X,
        DEFAULT_Y
    )

    ui:SetMovable(true)
    ui:SetClampedToScreen(true)

    ui:SetBackdrop({
        bgFile =
            "Interface\\Buttons\\WHITE8X8",

        edgeFile =
            "Interface\\Buttons\\WHITE8X8",

        edgeSize = 1,
    })

    ui:SetBackdropColor(
        0,
        0,
        0,
        0.70
    )

    ui:SetBackdropBorderColor(
        0.2,
        0.2,
        0.2,
        1
    )

    -- --------------------------------------------------------
    -- Dragging
    -- --------------------------------------------------------

    ui:RegisterForDrag(
        "LeftButton"
    )

    ui:SetScript(
        "OnDragStart",
        function(self)

            if self:IsMouseEnabled() then
                self:StartMoving()
            end
        end
    )

    ui:SetScript(
        "OnDragStop",
        function(self)

            self:StopMovingOrSizing()
        end
    )

    -- --------------------------------------------------------
    -- Right-click close
    -- --------------------------------------------------------

    ui:SetScript(
        "OnMouseUp",
        function(self, button)

            if button == "RightButton" then
                TMC:HidePanel()
            end
        end
    )

    ui:SetScript(
        "OnHide",
        function(self)

            self:EnableMouse(false)
        end
    )

    ui:SetScript(
        "OnShow",
        function(self)

            self:EnableMouse(true)
        end
    )

    -- --------------------------------------------------------
    -- Title
    -- --------------------------------------------------------

    local title = ui:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
    )

    TMC.title = title

    title:SetPoint(
        "TOPLEFT",
        ui,
        "TOPLEFT",
        10,
        -9
    )

    title:SetText(
        "Too Many Cooks"
    )

    title:SetTextColor(
        1,
        0.82,
        0
    )

    -- --------------------------------------------------------
    -- Close button
    -- --------------------------------------------------------

    local closeButton = CreateFrame(
        "Button",
        nil,
        ui,
        "UIPanelCloseButton"
    )

    TMC.closeButton =
        closeButton

    closeButton:SetSize(
        24,
        24
    )

    closeButton:SetPoint(
        "TOPRIGHT",
        ui,
        "TOPRIGHT",
        1,
        1
    )

    closeButton:SetScript(
        "OnClick",
        function()

            TMC:HidePanel()
        end
    )

    -- --------------------------------------------------------
    -- Progress
    -- --------------------------------------------------------

    local progress = ui:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )

    TMC.progress =
        progress

    progress:SetPoint(
        "RIGHT",
        closeButton,
        "LEFT",
        -5,
        0
    )

    progress:SetText(
        "0 / 0"
    )

    -- --------------------------------------------------------
    -- Flip button
    -- --------------------------------------------------------

    local flipButton = CreateFrame(
        "Button",
        nil,
        ui,
        "UIPanelButtonTemplate"
    )

    TMC.flipButton =
        flipButton

    flipButton:SetSize(
        48,
        20
    )

    flipButton:SetPoint(
        "RIGHT",
        progress,
        "LEFT",
        -8,
        0
    )

    flipButton:SetText(
        "FLIP"
    )

    flipButton:SetScript(
        "OnClick",
        function()

            TMC.isFlipped =
                not TMC.isFlipped

            UpdateBoxPositions()
        end
    )

    flipButton:SetScript(
        "OnEnter",
        function(self)

            GameTooltip:SetOwner(
                self,
                "ANCHOR_TOP"
            )

            GameTooltip:SetText(
                "Flip Ingredient Layout"
            )

            GameTooltip:AddLine(
                "Mirrors the ingredient boxes.",
                1,
                1,
                1
            )

            GameTooltip:Show()
        end
    )

    flipButton:SetScript(
        "OnLeave",
        function()

            GameTooltip:Hide()
        end
    )

    ui:EnableMouse(false)
    ui:Hide()
end

-- ============================================================
-- Remove old ingredient boxes
-- ============================================================

local function ClearBoxes()

    for _, box
        in pairs(TMC.boxes)
    do

        box:Hide()
        box:SetParent(nil)
    end

    wipe(TMC.boxes)
end

-- ============================================================
-- Build active encounter boxes
-- ============================================================

RebuildBoxes = function()

    CreateUI()

    ClearBoxes()

    if not TMC.currentEncounter then
        return
    end

    for key, ingredient
        in pairs(
            TMC.currentEncounter.ingredients
        )
    do

        local box = CreateFrame(
            "Frame",
            nil,
            TMC.ui,
            "BackdropTemplate"
        )

        box:SetSize(
            BOX_WIDTH,
            BOX_HEIGHT
        )

        box:EnableMouse(false)

        box:SetBackdrop({
            bgFile =
                "Interface\\Buttons\\WHITE8X8",

            edgeFile =
                "Interface\\Buttons\\WHITE8X8",

            edgeSize = 3,
        })

        box:SetBackdropColor(
            0.08,
            0.08,
            0.08,
            0.9
        )

        box:SetBackdropBorderColor(
            0.35,
            0.35,
            0.35,
            1
        )

        local text =
            box:CreateFontString(
                nil,
                "OVERLAY",
                "GameFontNormal"
            )

        text:SetPoint("CENTER")

        text:SetJustifyH(
            "CENTER"
        )

        text:SetJustifyV(
            "MIDDLE"
        )

        text:SetText(
            ingredient.label
        )

        TMC.boxes[key] =
            box
    end

    UpdateFrameSize()
    UpdateBoxPositions()
end

-- ============================================================
-- Position boxes
-- ============================================================

UpdateBoxPositions = function()

    if not TMC.ui
        or not TMC.currentEncounter
    then
        return
    end

    local order

    if TMC.isFlipped then

        order =
            TMC.currentEncounter.flippedOrder

    else

        order =
            TMC.currentEncounter.normalOrder
    end

    for i, key
        in ipairs(order)
    do

        local box =
            TMC.boxes[key]

        if box then

            box:ClearAllPoints()

            box:SetPoint(
                "BOTTOMLEFT",
                TMC.ui,
                "BOTTOMLEFT",
                SIDE_PADDING
                    + ((i - 1)
                    * (BOX_WIDTH + BOX_GAP)),
                BOTTOM_PADDING
            )

            box:Show()
        end
    end
end

-- ============================================================
-- Public UI functions
-- ============================================================

function TMC:PrepareUI()

    CreateUI()

    if not self.currentEncounter then
        return
    end

    self.title:SetText(
        self.currentEncounter.title
    )

    self.progress:SetText(
        "0 / "
        .. self.currentEncounter.maxIngredients
    )

    RebuildBoxes()

    self:ClearHighlight()
end

function TMC:ShowPanel()

    if not self.inSupportedArea then
        return
    end

    CreateUI()

    self.ui:EnableMouse(true)
    self.ui:Show()
end

function TMC:HidePanel()

    if not self.ui then
        return
    end

    self.ui:EnableMouse(false)
    self.ui:Hide()
end

function TMC:ClearHighlight()

    self.activeIngredient =
        nil

    if not self.ui then
        return
    end

    for _, box
        in pairs(self.boxes)
    do

        box:SetBackdropColor(
            0.08,
            0.08,
            0.08,
            0.9
        )

        box:SetBackdropBorderColor(
            0.35,
            0.35,
            0.35,
            1
        )
    end
end

function TMC:HighlightIngredient(key)

    if not self.currentEncounter then
        return
    end

    local box =
        self.boxes[key]

    if not box then
        return
    end

    if not self.ui:IsShown() then
        self:ShowPanel()
    end

    box:SetBackdropColor(
        0.9,
        0.7,
        0.05,
        0.9
    )

    box:SetBackdropBorderColor(
        1,
        1,
        0,
        1
    )

    self.activeIngredient =
        key
end

function TMC:UpdateProgress()

    if not self.progress
        or not self.currentEncounter
    then
        return
    end

    self.progress:SetText(
        self.count
        .. " / "
        .. self.currentEncounter.maxIngredients
    )
end

function TMC:FlipLayout()

    self.isFlipped =
        not self.isFlipped

    UpdateBoxPositions()
end