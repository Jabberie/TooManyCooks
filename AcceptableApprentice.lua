local addonName, TMC = ...

TMC:RegisterEncounter(
    "acceptableApprentice",
    {
        title =
            "Acceptable Apprentice",

        npc =
            "Ofi the Sly",

        mapID =
            2512,

        maxIngredients =
            5,

        -- This opening line is also ingredient #1.
        openingPatterns = {
            "let's start with some of dem fish guts",
        },

        openingIsIngredient =
            true,

        ingredients = {

            fish = {
                label =
                    "Fish Guts",

                patterns = {
                    "fish guts",
                    "dollop of guts",
                },
            },

            scales = {
                label =
                    "Scales",

                patterns = {
                    "add some scales",
                },
            },

            pearl = {
                label =
                    "Pearl Dust",

                patterns = {
                    "pearl dust",
                },
            },
        },

        -- Actual physical placement.
        normalOrder = {
            "fish",
            "scales",
            "pearl",
        },

        flippedOrder = {
            "pearl",
            "scales",
            "fish",
        },

        npcFailurePatterns = {
            -- Add if we discover specific failure dialogue.
        },

        npcCompletionPatterns = {
            "now dat is a wickedly offensive brew",
        },

        failureMessagePatterns = {
        },

        completionMessagePatterns = {
            "pungent concoction",
        },
    }
)