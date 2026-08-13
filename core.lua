local addonName, TMC = ...

-- ============================================================
-- Runtime state
-- ============================================================

TMC.inSupportedArea =
    false

TMC.currentEncounter =
    nil

TMC.count =
    0

-- ============================================================
-- Event frame
-- ============================================================

local eventFrame =
    CreateFrame("Frame")

TMC.eventFrame =
    eventFrame

-- Only location events stay permanently registered.
eventFrame:RegisterEvent(
    "PLAYER_ENTERING_WORLD"
)

eventFrame:RegisterEvent(
    "ZONE_CHANGED"
)

eventFrame:RegisterEvent(
    "ZONE_CHANGED_NEW_AREA"
)

-- ============================================================
-- Area state
-- ============================================================

local function IsCurrentlySupported()

    local mapID =
        C_Map.GetBestMapForUnit(
            "player"
        )

    return TMC:IsSupportedMap(
        mapID
    )
end

-- ============================================================
-- Dynamic encounter events
-- ============================================================

local function EnableEncounterEvents()

    eventFrame:RegisterEvent(
        "CHAT_MSG_MONSTER_SAY"
    )

    eventFrame:RegisterEvent(
        "CHAT_MSG_SYSTEM"
    )

    eventFrame:RegisterEvent(
        "CHAT_MSG_LOOT"
    )
end

local function DisableEncounterEvents()

    eventFrame:UnregisterEvent(
        "CHAT_MSG_MONSTER_SAY"
    )

    eventFrame:UnregisterEvent(
        "CHAT_MSG_SYSTEM"
    )

    eventFrame:UnregisterEvent(
        "CHAT_MSG_LOOT"
    )
end

local function UpdateAreaState()

    TMC.inSupportedArea =
        IsCurrentlySupported()

    if TMC.inSupportedArea then

        EnableEncounterEvents()

        return
    end

    DisableEncounterEvents()

    TMC.currentEncounter =
        nil

    TMC.count =
        0

    TMC:ClearHighlight()
    TMC:HidePanel()
end

-- ============================================================
-- Encounter lifecycle
-- ============================================================

function TMC:ActivateEncounter(encounter)

    if not encounter then
        return
    end

    self.currentEncounter =
        encounter

    self.count =
        0

    self:PrepareUI()
end

function TMC:ResetEncounter()

    self.count =
        0

    self:ClearHighlight()
    self:UpdateProgress()
end

function TMC:CompleteEncounter()

    self:HidePanel()

    self.count =
        0

    self:ClearHighlight()

    self.currentEncounter =
        nil
end

function TMC:FailEncounter()

    self:HidePanel()

    self.count =
        0

    self:ClearHighlight()

    self.currentEncounter =
        nil
end

-- ============================================================
-- Ingredient request
-- ============================================================

local function ProcessIngredient(
    encounter,
    message
)

    local key =
        TMC:GetIngredientFromMessage(
            encounter,
            message
        )

    if not key then
        return false
    end

    TMC.count =
        TMC.count + 1

    if TMC.count >
        encounter.maxIngredients
    then

        TMC.count =
            encounter.maxIngredients
    end

    TMC:HighlightIngredient(
        key
    )

    TMC:UpdateProgress()

    return true
end

-- ============================================================
-- Recover after reload / missed opening
-- ============================================================

local function RecoverEncounter(
    encounter,
    message
)

    if TMC.currentEncounter then
        return true
    end

    local key =
        TMC:GetIngredientFromMessage(
            encounter,
            message
        )

    if not key then
        return false
    end

    TMC:ActivateEncounter(
        encounter
    )

    return true
end

-- ============================================================
-- NPC processing
-- ============================================================

local function ProcessNPCMessage(
    message,
    sender
)

    if not message
        or not sender
    then
        return
    end

    local encounter =
        TMC:GetEncounterByNPC(
            sender
        )

    if not encounter then
        return
    end

    -- --------------------------------------------------------
    -- Clear previous selection whenever a supported cook speaks.
    -- This makes identical consecutive requests noticeable.
    -- --------------------------------------------------------

    TMC:ClearHighlight()

    -- --------------------------------------------------------
    -- Opening dialogue
    -- --------------------------------------------------------

    local opening =
        TMC:MatchesAny(
            message,
            encounter.openingPatterns
        )

    if opening then

        TMC:ActivateEncounter(
            encounter
        )

        TMC:ShowPanel()

        if not encounter.openingIsIngredient then
            return
        end
    end

    -- --------------------------------------------------------
    -- Failure fallback
    -- --------------------------------------------------------

    if TMC:MatchesAny(
        message,
        encounter.npcFailurePatterns
    )
    then

        TMC:FailEncounter()

        return
    end

    -- --------------------------------------------------------
    -- Completion fallback
    -- --------------------------------------------------------

    if TMC:MatchesAny(
        message,
        encounter.npcCompletionPatterns
    )
    then

        TMC:CompleteEncounter()

        return
    end

    -- --------------------------------------------------------
    -- Reload recovery
    -- --------------------------------------------------------

    if not TMC.currentEncounter then

        RecoverEncounter(
            encounter,
            message
        )
    end

    if not TMC.currentEncounter then
        return
    end

    -- Prevent another supported NPC from modifying
    -- an already-active encounter.
    if TMC.currentEncounter.id
        ~= encounter.id
    then
        return
    end

    -- --------------------------------------------------------
    -- Ingredient instruction
    -- --------------------------------------------------------

    ProcessIngredient(
        encounter,
        message
    )
end

-- ============================================================
-- System / loot processing
-- ============================================================

local function ProcessGameMessage(message)

    if not message
        or not TMC.currentEncounter
    then
        return
    end

    local encounter =
        TMC.currentEncounter

    if TMC:MatchesAny(
        message,
        encounter.failureMessagePatterns
    )
    then

        TMC:FailEncounter()

        return
    end

    if TMC:MatchesAny(
        message,
        encounter.completionMessagePatterns
    )
    then

        TMC:CompleteEncounter()

        return
    end
end

-- ============================================================
-- Event handler
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
        -- Location
        -- ----------------------------------------------------

        if event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED"
        or event == "ZONE_CHANGED_NEW_AREA"
        then

            UpdateAreaState()

            return
        end

        if not TMC.inSupportedArea then
            return
        end

        -- ----------------------------------------------------
        -- NPC speech
        -- ----------------------------------------------------

        if event ==
            "CHAT_MSG_MONSTER_SAY"
        then

            ProcessNPCMessage(
                message,
                sender
            )

            return
        end

        -- ----------------------------------------------------
        -- System / creation messages
        -- ----------------------------------------------------

        if event == "CHAT_MSG_SYSTEM"
        or event == "CHAT_MSG_LOOT"
        then

            ProcessGameMessage(
                message
            )

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
        -- Hide
        -- ----------------------------------------------------

        if msg == "hide" then

            TMC:HidePanel()

            return
        end

        -- ----------------------------------------------------
        -- Flip
        -- ----------------------------------------------------

        if msg == "flip" then

            TMC:FlipLayout()

            return
        end

        -- ----------------------------------------------------
        -- Reset
        -- ----------------------------------------------------

        if msg == "reset" then

            TMC:ResetEncounter()

            print(
                "|cff00ff00TooManyCooks:|r Reset."
            )

            return
        end

        -- ----------------------------------------------------
        -- Failure test
        -- ----------------------------------------------------

        if msg == "test fail" then

            TMC:FailEncounter()

            return
        end

        -- ----------------------------------------------------
        -- Completion test
        -- ----------------------------------------------------

        if msg == "test complete" then

            TMC:CompleteEncounter()

            return
        end

        -- ----------------------------------------------------
        -- Show Suspicious Stew
        -- ----------------------------------------------------

        if msg == "show stew"
        or msg == "show"
        then

            local encounter =
                TMC.encounters.suspiciousStew

            TMC:ActivateEncounter(
                encounter
            )

            TMC:ShowPanel()

            return
        end

        -- ----------------------------------------------------
        -- Show Pungent Concoction
        -- ----------------------------------------------------

        if msg == "show pungent" then

            local encounter =
                TMC.encounters.acceptableApprentice

            TMC:ActivateEncounter(
                encounter
            )

            TMC:ShowPanel()

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
                tostring(
                    TMC.inSupportedArea
                )
            )

            print(
                "UI created:",
                tostring(
                    TMC.ui ~= nil
                )
            )

            print(
                "UI shown:",
                tostring(
                    TMC.ui
                    and TMC.ui:IsShown()
                )
            )

            print(
                "Encounter:",
                TMC.currentEncounter
                    and TMC.currentEncounter.title
                    or "None"
            )

            if TMC.currentEncounter then

                print(
                    "Progress:",
                    TMC.count
                    .. " / "
                    .. TMC.currentEncounter.maxIngredients
                )
            end

            return
        end

        -- ----------------------------------------------------
        -- Help
        -- ----------------------------------------------------

        print(
            "|cff00ff00TooManyCooks commands:|r"
        )

        print("/tmc show")
        print("/tmc show pungent")
        print("/tmc hide")
        print("/tmc flip")
        print("/tmc reset")
        print("/tmc status")
        print("/tmc test fail")
        print("/tmc test complete")
    end

print(
    "|cff00ff00TooManyCooks loaded.|r"
)