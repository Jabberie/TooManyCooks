local addonName, TMC = ...

TMC.encounters = TMC.encounters or {}

-- ============================================================
-- Encounter registry
-- ============================================================

function TMC:RegisterEncounter(id, data)

    if not id or not data then
        return
    end

    data.id = id

    TMC.encounters[id] = data
end

-- ============================================================
-- Pattern matching
-- ============================================================

function TMC:MatchesAny(message, patterns)

    if not message or not patterns then
        return false
    end

    local msg = message:lower()

    for _, pattern in ipairs(patterns) do

        if msg:find(
            pattern:lower(),
            1,
            true
        )
        then
            return true
        end
    end

    return false
end

-- ============================================================
-- Find encounter by NPC
-- ============================================================

function TMC:GetEncounterByNPC(sender)

    if not sender then
        return nil
    end

    for _, encounter in pairs(self.encounters) do

        if encounter.npc
            and sender:find(
                encounter.npc,
                1,
                true
            )
        then
            return encounter
        end
    end

    return nil
end

-- ============================================================
-- Find encounter by opening dialogue
-- ============================================================

function TMC:GetEncounterByOpening(sender, message)

    if not sender or not message then
        return nil
    end

    for _, encounter in pairs(self.encounters) do

        if encounter.npc
            and sender:find(
                encounter.npc,
                1,
                true
            )
            and self:MatchesAny(
                message,
                encounter.openingPatterns
            )
        then
            return encounter
        end
    end

    return nil
end

-- ============================================================
-- Find ingredient
-- ============================================================

function TMC:GetIngredientFromMessage(encounter, message)

    if not encounter
        or not message
        or not encounter.ingredients
    then
        return nil
    end

    for key, ingredient
        in pairs(encounter.ingredients)
    do

        if self:MatchesAny(
            message,
            ingredient.patterns
        )
        then
            return key
        end
    end

    return nil
end

-- ============================================================
-- Determine whether map has supported content
-- ============================================================

function TMC:IsSupportedMap(mapID)

    if not mapID then
        return false
    end

    for _, encounter in pairs(self.encounters) do

        if encounter.mapID == mapID then
            return true
        end
    end

    return false
end