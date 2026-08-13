local addonName = ...

-- ============================================================
-- Constants
-- ============================================================

local SUPPORTED_MAP_ID = 2512
local MAX_INGREDIENTS = 6

-- Default panel position.
local DEFAULT_X = 0
local DEFAULT_Y = 100

-- ============================================================
-- Runtime state
-- ============================================================

local inSupportedArea = false
local currentEncounter = nil
local count = 0
local activeIngredient = nil
local isFlipped = false

-- UI is created lazily.
local ui = nil
local title = nil
local progress = nil
local flipButton = nil
local closeButton = nil
local boxes = {}

-- ============================================================
-- Encounter definitions
-- ============================================================

local encounters = {
    suspiciousStew = {
        title = "Suspicious Stew",

        -- First intro line identifies the encounter
        -- and now immediately shows the panel.
        openingPattern = "scrounged up what i could",

        ingredients = {
            fish = {
                label = "Lukewarm\nFish Guts",
                pattern = "fish-like creature",
            },

            boar = {
                label = "Salted Split\nBoar",
                pattern = "fresh boar",
            },

            bread = {
                label = "Stale\nHardtack",
                pattern = "old bread",
            },

            peppers = {
                label = "Scavenged\nPepperplant",
                pattern = "add some peppers",
            },
        },

        -- Physical order when standing in front.
        normalOrder = {
            "boar",
            "bread",
            "peppers",
            "fish",
        },

        -- Mirrored order when standing behind.
        flippedOrder = {
            "fish",
            "peppers",
            "bread",
            "boar",
        },
    },
}

-- ============================================================
-- Event controller
-- ============================================================

local eventFrame = CreateFrame("Frame")

-- Only lightweight location events remain globally registered.
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- ============================================================
-- Forward declarations
-- ============================================================

local CreateUI
local ShowPanel
local HidePanel
local UpdateBoxPositions
local ClearHighlight
local ResetEncounter
local CompleteEncounter
local ActivateEncounter
local ProcessCookMessage
local UpdateAreaState

-- ============================================================
-- Area detection
-- ============================================================

local function IsInSupportedArea()
    local mapID = C_Map.GetBestMapForUnit("player")
    return mapID == SUPPORTED_MAP_ID
end

-- ============================================================
-- UI creation
-- ============================================================

CreateUI = function()

    if ui then
        return
    end

    -- --------------------------------------------------------
    -- Main frame
    -- --------------------------------------------------------

    ui = CreateFrame(
        "Frame",
        "TooManyCooksFrame",
        UIParent,
        "BackdropTemplate"
    )

    ui:SetSize(430, 100)

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
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
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
    -- Dragging / right-click close
    -- --------------------------------------------------------

    ui:RegisterForDrag("LeftButton")

    ui:SetScript(
        "OnDragStart",
        function(self)

            if not self:IsMouseEnabled() then
                return
            end

            self:StartMoving()
        end
    )

    ui:SetScript(
        "OnDragStop",
        function(self)
            self:StopMovingOrSizing()
        end
    )

    ui:SetScript(
        "OnMouseUp",
        function(self, button)

            if button == "RightButton" then
                HidePanel()
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
    -- Header title
    -- --------------------------------------------------------

    title = ui:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
    )

    title:SetPoint(
        "TOPLEFT",
        ui,
        "TOPLEFT",
        10,
        -9
    )

    title:SetText("Suspicious Stew")

    title:SetTextColor(
        1,
        0.82,
        0
    )

    -- --------------------------------------------------------
    -- Close button
    -- --------------------------------------------------------

    closeButton = CreateFrame(
        "Button",
        nil,
        ui,
        "UIPanelCloseButton"
    )

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
            HidePanel()
        end
    )

    -- --------------------------------------------------------
    -- Progress
    -- --------------------------------------------------------

    progress = ui:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )

    progress:SetPoint(
        "RIGHT",
        closeButton,
        "LEFT",
        -5,
        0
    )

    progress:SetText(
        "0 / " .. MAX_INGREDIENTS
    )

    -- --------------------------------------------------------
    -- Flip button
    -- --------------------------------------------------------

    flipButton = CreateFrame(
        "Button",
        nil,
        ui,
        "UIPanelButtonTemplate"
    )

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

    flipButton:SetText("FLIP")

    flipButton:SetScript(
        "OnClick",
        function()

            isFlipped = not isFlipped

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

    -- --------------------------------------------------------
    -- Ingredient boxes
    -- --------------------------------------------------------

    local ingredientDefinitions =
        encounters.suspiciousStew.ingredients

    for key, data in pairs(ingredientDefinitions) do

        local box = CreateFrame(
            "Frame",
            nil,
            ui,
            "BackdropTemplate"
        )

        box:SetSize(
            95,
            54
        )

        -- Display-only.
        box:EnableMouse(false)

        box:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
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

        local text = box:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormal"
        )

        text:SetPoint(
            "CENTER",
            box,
            "CENTER",
            0,
            0
        )

        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")
        text:SetText(data.label)

        boxes[key] = box
    end

    UpdateBoxPositions()

    -- Newly-created UI starts inactive.
    ui:EnableMouse(false)
    ui:Hide()
end

-- ============================================================
-- Show / hide
-- ============================================================

ShowPanel = function()

    if not inSupportedArea then
        return
    end

    CreateUI()

    ui:EnableMouse(true)
    ui:Show()
end

HidePanel = function()

    if not ui then
        return
    end

    ui:EnableMouse(false)
    ui:Hide()
end

-- ============================================================
-- Layout
-- ============================================================

UpdateBoxPositions = function()

    if not ui then
        return
    end

    local encounter =
        currentEncounter
        or encounters.suspiciousStew

    local order

    if isFlipped then
        order = encounter.flippedOrder
    else
        order = encounter.normalOrder
    end

    for i, key in ipairs(order) do

        local box = boxes[key]

        if box then

            box:ClearAllPoints()

            box:SetPoint(
                "BOTTOMLEFT",
                ui,
                "BOTTOMLEFT",
                10 + ((i - 1) * 105),
                8
            )
        end
    end
end

-- ============================================================
-- Highlight handling
-- ============================================================

ClearHighlight = function()

    if not ui then
        activeIngredient = nil
        return
    end

    for _, box in pairs(boxes) do

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

    activeIngredient = nil
end

local function HighlightIngredient(key)

    CreateUI()

    local box = boxes[key]

    if not box then
        return
    end

    if not ui:IsShown() then
        ShowPanel()
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

    activeIngredient = key

    count = count + 1

    if count > MAX_INGREDIENTS then
        count = MAX_INGREDIENTS
    end

    progress:SetText(
        count ..
        " / " ..
        MAX_INGREDIENTS
    )
end

-- ============================================================
-- Reset
-- ============================================================

ResetEncounter = function()

    count = 0
    activeIngredient = nil

    if progress then

        progress:SetText(
            "0 / " ..
            MAX_INGREDIENTS
        )
    end

    ClearHighlight()
end

-- ============================================================
-- Completion
-- ============================================================

CompleteEncounter = function()

    HidePanel()

    ResetEncounter()

    currentEncounter = nil
end

-- ============================================================
-- Failure
-- ============================================================

local function FailEncounter()

    HidePanel()

    ResetEncounter()

    currentEncounter = nil
end

-- ============================================================
-- Encounter activation
-- ============================================================

ActivateEncounter = function(encounter)

    currentEncounter =
        encounter

    ResetEncounter()

    if title then
        title:SetText(
            encounter.title
        )
    end

    UpdateBoxPositions()
end

-- ============================================================
-- Detect opening line
-- ============================================================

local function DetectEncounter(message)

    local msg =
        message:lower()

    for _, encounter in pairs(encounters) do

        if msg:find(
            encounter.openingPattern,
            1,
            true
        )
        then

            ActivateEncounter(
                encounter
            )

            -- Show immediately on the first gossip line.
            ShowPanel()

            return true
        end
    end

    return false
end

-- ============================================================
-- Reload / missed-opening recovery
-- ============================================================

local function RecoverEncounterFromIngredient(message)

    if currentEncounter then
        return true
    end

    local msg =
        message:lower()

    local encounter =
        encounters.suspiciousStew

    for _, data in pairs(
        encounter.ingredients
    )
    do

        if msg:find(
            data.pattern,
            1,
            true
        )
        then

            ActivateEncounter(
                encounter
            )

            return true
        end
    end

    return false
end

-- ============================================================
-- Cook message processing
-- ============================================================

ProcessCookMessage = function(message)

    local msg =
        message:lower()

    -- --------------------------------------------------------
    -- Opening line
    -- --------------------------------------------------------

    if DetectEncounter(message) then
        return
    end

    -- --------------------------------------------------------
    -- Failure / restart fallback
    -- --------------------------------------------------------

    if msg:find(
        "no no, it tastes wrong",
        1,
        true
    )
    or msg:find(
        "dump this one out",
        1,
        true
    )
    or msg:find(
        "zul'jarra will have ma head",
        1,
        true
    )
    then

        FailEncounter()

        return
    end

    -- --------------------------------------------------------
    -- Recover after reload if required
    -- --------------------------------------------------------

    if not currentEncounter then

        RecoverEncounterFromIngredient(
            message
        )
    end

    if not currentEncounter then
        return
    end

    -- --------------------------------------------------------
    -- Ingredient request
    -- --------------------------------------------------------

    for key, data in pairs(
        currentEncounter.ingredients
    )
    do

        if msg:find(
            data.pattern,
            1,
            true
        )
        then

            HighlightIngredient(
                key
            )

            return
        end
    end
end

-- ============================================================
-- Enable encounter listeners
-- ============================================================

local function EnableAreaEvents()

    if eventFrame:IsEventRegistered(
        "CHAT_MSG_MONSTER_SAY"
    )
    then
        return
    end

    eventFrame:RegisterEvent(
        "CHAT_MSG_MONSTER_SAY"
    )

    eventFrame:RegisterEvent(
        "CHAT_MSG_SYSTEM"
    )
end

-- ============================================================
-- Disable encounter listeners
-- ============================================================

local function DisableAreaEvents()

    eventFrame:UnregisterEvent(
        "CHAT_MSG_MONSTER_SAY"
    )

    eventFrame:UnregisterEvent(
        "CHAT_MSG_SYSTEM"
    )
end

-- ============================================================
-- Area state
-- ============================================================

UpdateAreaState = function()

    inSupportedArea =
        IsInSupportedArea()

    if inSupportedArea then

        EnableAreaEvents()

        return
    end

    DisableAreaEvents()

    currentEncounter = nil

    ResetEncounter()

    HidePanel()
end

-- ============================================================
-- Main event handler
-- ============================================================

eventFrame:SetScript(
    "OnEvent",
    function(
        self,
        event,
        message,
        sender
    )

        -- ----------------------------------------------------
        -- World / zone state
        -- ----------------------------------------------------

        if event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_NEW_AREA"
        then

            UpdateAreaState()

            return
        end

        -- ----------------------------------------------------
        -- NPC speech
        -- ----------------------------------------------------

        if event == "CHAT_MSG_MONSTER_SAY" then

            if not inSupportedArea then
                return
            end

            if not sender
                or not sender:find(
                    "Witherbark Cook",
                    1,
                    true
                )
            then
                return
            end

            -- Clear the previous highlight whenever the Cook
            -- speaks. This makes repeated requests obvious.
            ClearHighlight()

            ProcessCookMessage(
                message
            )

            return
        end

        -- ----------------------------------------------------
        -- System messages
        -- ----------------------------------------------------

        if event == "CHAT_MSG_SYSTEM" then

            if not inSupportedArea then
                return
            end

            if not message then
                return
            end

            local msg =
                message:lower()

            -- ------------------------------------------------
            -- Successful completion
            -- ------------------------------------------------

            if msg:find(
                "a suspicious stew completed",
                1,
                true
            )
            then

                CompleteEncounter()

                return
            end

            -- ------------------------------------------------
            -- Failed / spoiled stew
            -- ------------------------------------------------

            if msg:find(
                "the stew has been spoiled",
                1,
                true
            )
            then

                FailEncounter()

                return
            end

            return
        end
    end
)

-- ============================================================
-- Slash commands
-- ============================================================

SLASH_TOOMANYCOOKS1 =
    "/tmc"

SlashCmdList["TOOMANYCOOKS"] =
    function(msg)

        msg =
            strtrim(
                msg:lower()
            )

        -- ----------------------------------------------------
        -- Show
        -- ----------------------------------------------------

        if msg == "show" then

            if not inSupportedArea then

                print(
                    "|cffff9900TooManyCooks:|r Not in a supported area."
                )

                return
            end

            ActivateEncounter(
                encounters.suspiciousStew
            )

            CreateUI()

            title:SetText(
                currentEncounter.title
            )

            ShowPanel()

            return
        end

        -- ----------------------------------------------------
        -- Hide
        -- ----------------------------------------------------

        if msg == "hide" then

            HidePanel()

            return
        end

        -- ----------------------------------------------------
        -- Reset
        -- ----------------------------------------------------

        if msg == "reset" then

            ResetEncounter()

            print(
                "|cff00ff00TooManyCooks:|r Reset."
            )

            return
        end

        -- ----------------------------------------------------
        -- Flip
        -- ----------------------------------------------------

        if msg == "flip" then

            isFlipped =
                not isFlipped

            UpdateBoxPositions()

            return
        end

        -- ----------------------------------------------------
        -- Clear
        -- ----------------------------------------------------

        if msg == "clear" then

            ClearHighlight()

            return
        end

        -- ----------------------------------------------------
        -- Ingredient tests
        -- ----------------------------------------------------

        if msg == "test fish"
        or msg == "test boar"
        or msg == "test bread"
        or msg == "test peppers"
        then

            if not inSupportedArea then

                print(
                    "|cffff9900TooManyCooks:|r Tests only run inside the supported area."
                )

                return
            end

            ActivateEncounter(
                encounters.suspiciousStew
            )

            local key =
                msg:match(
                    "^test%s+(%S+)$"
                )

            ClearHighlight()

            HighlightIngredient(
                key
            )

            return
        end

        -- ----------------------------------------------------
        -- Completion test
        -- ----------------------------------------------------

        if msg == "test complete" then

            CompleteEncounter()

            return
        end

        -- ----------------------------------------------------
        -- Status
        -- ----------------------------------------------------

        if msg == "status" then

            local mapID =
                C_Map.GetBestMapForUnit(
                    "player"
                )

            print(
                "|cff00ff00TooManyCooks:|r"
            )

            print(
                "Map ID:",
                tostring(mapID)
            )

            print(
                "Supported area:",
                tostring(inSupportedArea)
            )

            print(
                "UI created:",
                tostring(ui ~= nil)
            )

            print(
                "UI shown:",
                tostring(
                    ui and ui:IsShown()
                )
            )

            print(
                "Encounter:",
                currentEncounter
                    and currentEncounter.title
                    or "None"
            )

            print(
                "Progress:",
                count ..
                " / " ..
                MAX_INGREDIENTS
            )

            return
        end

        -- ----------------------------------------------------
        -- Help
        -- ----------------------------------------------------

        print(
            "|cff00ff00TooManyCooks commands:|r"
        )

        print("/tmc show")
        print("/tmc hide")
        print("/tmc reset")
        print("/tmc clear")
        print("/tmc flip")
        print("/tmc status")
        print("/tmc test fish")
        print("/tmc test boar")
        print("/tmc test bread")
        print("/tmc test peppers")
        print("/tmc test complete")
    end

print(
    "|cff00ff00TooManyCooks loaded.|r"
)