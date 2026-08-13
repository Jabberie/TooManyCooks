local addonName, TMC = ...

TMC:RegisterEncounter(
    "suspiciousStew",
    {
        title =
            "Suspicious Stew",

        npc =
            "Witherbark Cook",

        mapID =
            2512,

        maxIngredients =
            6,

        openingPatterns = {
            "scrounged up what i could",
        },

        openingIsIngredient =
            false,

        ingredients = {

            boar = {
                label =
                    "Salted Split\nBoar",

                patterns = {
                    "fresh boar",
                },
            },

            bread = {
                label =
                    "Stale\nHardtack",

                patterns = {
                    "old bread",
                },
            },

            peppers = {
                label =
                    "Scavenged\nPepperplant",

                patterns = {
                    "add some peppers",
                },
            },

            fish = {
                label =
                    "Lukewarm\nFish Guts",

                patterns = {
                    "fish-like creature",
                },
            },
        },

        normalOrder = {
            "boar",
            "bread",
            "peppers",
            "fish",
        },

        flippedOrder = {
            "fish",
            "peppers",
            "bread",
            "boar",
        },

        npcFailurePatterns = {
            "no no, it tastes wrong",
            "dump this one out",
            "zul'jarra will have ma head",
        },

        npcCompletionPatterns = {
        },

        failureMessagePatterns = {
            "the stew has been spoiled",
        },

        completionMessagePatterns = {
            "a suspicious stew completed",
        },
    }
)