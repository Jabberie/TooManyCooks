local addonName, TMC = ...

TMC:RegisterEncounter(
    "artificingAggression",
    {
        title =
            "Artificing Aggression",

        npc =
            "Decimus",

        mapID =
            2405,

        maxIngredients =
            6,

        openingPatterns = {
            "this is a delicate art",
        },

        openingIsIngredient =
            false,

        ingredients = {

            brazier = {
                label =
                    "Void Brazier",

                patterns = {
                    "heat the blade with flames from the void brazier",
                },
            },

            boneDust = {
                label =
                    "Behemoth\nBone Dust",

                patterns = {
                    "scatter behemoth bone dust over the void-burning blade",
                },
            },

            crystal = {
                label =
                    "Crystallized Void",

                patterns = {
                    "use the crystalized void to enhance the blade's edge",
                },
            },

            repository = {
                label =
                    "Void Repository",

                patterns = {
                    "extract power from that void repository",
                },
            },
        },

        normalOrder = {
            "brazier",
            "boneDust",
            "crystal",
            "repository",
        },

        flippedOrder = {
            "repository",
            "crystal",
            "boneDust",
            "brazier",
        },

        npcFailurePatterns = {
        },

        npcCompletionPatterns = {
        },

        failureMessagePatterns = {
        },

        completionMessagePatterns = {
            "artificing aggression completed",
        },
    }
)