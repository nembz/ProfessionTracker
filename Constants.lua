local ProfessionTracker = LibStub("AceAddon-3.0"):GetAddon("ProfessionTracker")

ProfessionTracker.Expansions = {
    ["Midnight"] = "Midnight",
}

ProfessionTracker.ProfessionData = {
    ["Alchemy"] = {
        name = "Alchemy",
        -- You can wrap expansion-specific data in a sub-table
        ["Midnight"] = {
            skillLineID = 2906, 
            moxieId = 3256,
            knowledgePointsID = 3011,
            epicTool = { id = 259205, name = "Gilded Alchemist's Mixing Rod" },
            epicAccessories = {
                { id = 267052, name = "Thalassian Alchemy Coveralls" },
                { id = 244812, name = "Thalassian Alchemist's Mixcap" },
            },
            treasureMapQuests = {
                {questId = 93528, name = "Lightbloomed Spore Sample"},
                {questId = 93529, name = "Aged Cruor"},
            },
            color = {1, 0.5, 1},
            treatise = {questId = 95127, itemId = 245755},
            darkmoon = {questId = 29506},
            concentration = {currencyId = 3161},
            weekly = {questId = 93690, name="Alchemy Services Requested"},
            gathering = {}
        },
    },
    ["Blacksmithing"] = {
        name = "Blacksmithing",
        ["Midnight"] = {
            skillLineID = 2907,
            moxieId = 3257,
            knowledgePointsID = 3012,
            epicTool = { id = 246537, name = "Sunforged Blacksmith's Hammer" },
            epicAccessories = {
                { id = 244813, name = "Thalassian Ironbender's Regalia" },
                { id = 259230, name = "Sunforged Blacksmith's Tolbox" },
            },
            treasureMapQuests = {
                {questId = 93530, name = "Thalassian Whestone"},
                {questId = 93531, name = "Infused Quenching Oil"},
            },
            color = {0.8, 0.8, 0.8},
            treatise = {questId = 95128, itemId = 245763},
            darkmoon = {questId = 29508},
            concentration = {currencyId = 3162},
            weekly = {questId = 93691, name="Blacksmithing Services Requested"},
            gathering = {}
        }
    },
    ["Enchanting"] = {
        name = "Enchanting",
        ["Midnight"] = {
            skillLineID = 2909,
            moxieId = 3258,
            knowledgePointsID = 3013,
            epicTool = { id = 244177, name = "Runed Dazzling Thorium Rod" },
            epicAccessories = {
                { id = 246527, name = "Attuned Thalassian Rune-Prism" },
                { id = 267056, name = "Thalassian Enchanter's Bonnet" },
            },
            treasureMapQuests = {
                {questId = 93532, name = "Voidstorm Ashes"},
                {questId = 93533, name = "Lost Thalassian Vellum"},
            },
            color = {0.63, 0.21, 0.94},
            treatise = {questId = 95129, itemId = 245759},
            darkmoon = {questId = 29510},
            concentration = {currencyId = 3163},
            weekly = {questId = {93699, 93698, 93697}, name="Enchanting trainer quest"},
            gathering = {questId = { 95048, 95049, 95050, 95051, 95052, 95053 }, name="Gathered while disenchanting"},
        }
    },
    ["Engineering"] = {
        name = "Engineering",
        ["Midnight"] = {
            skillLineID = 2910,
            moxieId = 3259,
            knowledgePointsID = 3014,
            epicTool = { id = 259183, name = "Turbo-Junker's Multitool v9" },
            epicAccessories = {
                { id = 244810, name = "Thalassian Scrapmaster's Gauntlets" },
                { id = 259171, name = "Head-Mounted Beam Bummer" },
            },
            treasureMapQuests = {
                {questId = 93534, name = "Dance Gear"},
                {questId = 93535, name = "Dawn Capacitor"},
            },
            color = {0.9, 0.8, 0},
            treatise = {questId = 95138, itemId = 245809},
            darkmoon = {questId = 29511},
            concentration = {currencyId = 3164},
            weekly = {questId = 93692, name="Engineering Services Requested"},
            gathering = {}
        }
    },
    ["Herbalism"] = {
        name = "Herbalism",
        ["Midnight"] = {
            skillLineID = 2831,
            moxieId = 3260,
            knowledgePointsID = 3020,
            epicTool = { id = 246533, name = "Sunforged Sickle" },
            epicAccessories = {
                { id = 244807, name = "Thalassian Herbtender's Cradle" },
                { id = 267060, name = "Thalassian Herbalist's Cowl" },
            },
            treasureMapQuests = {},
            color = {0.3, 0.9, 0.3},
            treatise = {questId = 95130, itemId = 245761},
            darkmoon = {questId = 29514},
            concentration = {},
            weekly = {questId = { 93700, 93701, 93702, 93703, 93704 }, name="Trainer quests"},
            gathering = {questId = { 81425, 81426, 81427, 81428, 81429, 81430 }, name="Gathered while herbalism"},
        }
    },
    ["Inscription"] = {
        name = "Inscription",
        ["Midnight"] = {
            skillLineID = 2913,
            moxieId = 3261,
            knowledgePointsID = 3015,
            epicTool = { id = 259209, name = "Gilded Sin'dorei Quill" },
            epicAccessories = {
                { id = 246525, name = "Thalassian Scribe's Crystalline Lens" },
                { id = 246524, name = "Flawless Text Scrutinizers" },
            },
            treasureMapQuests = {
                {questId = 93536, name = "Brilliant Phoenix Ink"},
                {questId = 93537, name = "Loa-Blessed Rune"},
            },
            color = {1, 0.8, 0},
            treatise = {questId = 95131, itemId = 245757},
            darkmoon = {questId = 29515},
            concentration = {currencyId = 3165},
            weekly = {questId = 93693, name="Inscription Services Requested"},
            gathering = {}
        }
    },
    ["Jewelcrafting"] = {
        name = "Jewelcrafting",
        ["Midnight"] = {
            skillLineID = 2914,
            moxieId = 3262,
            knowledgePointsID = 3016,
            epicTool = { id = 259181, name = "Giga-Gem Grippers" },
            epicAccessories = {
                { id = 244814, name = "Thalassian Gemshaper's Grand Cover" },
                { id = 246526, name = "Mage-Eye Precision Loupes" },
            },
            treasureMapQuests = {
                {questId = 93538, name = "Void-Touched Eversong Diamond Fragments"},
                {questId = 93539, name = "Harandar Stone Sample"},
            },
            color = {0, 1, 1},
            treatise = {questId = 95133, itemId = 245760},
            darkmoon = {questId = 29516},
            concentration = {currencyId = 3166},
            weekly = {questId = 93694, name="Jewelcrafting Services Requested"},
            gathering = {}
        }
    },
    ["Leatherworking"] = {
        name = "Leatherworking",
        ["Midnight"] = {
            skillLineID = 2915,
            moxieId = 3263,
            knowledgePointsID = 3017,
            epicTool = { id = 246536, name = "Sunforged Leatherworker's Knife" },
            epicAccessories = {
                { id = 259232, name = "Sunforged Leatherworker's Toolset" },
                { id = 244811, name = "Thalassian Mana Oil" },
            },
            treasureMapQuests = {
                {questId = 93540, name = "Amani Tanning Oil"},
                {questId = 93541, name = "Harandar Stone Sample"},
            },
            color = {0.8, 0.6, 0.2},
            treatise = {questId = 95134, itemId = 245758},
            darkmoon = {questId = 29517},
            concentration = {currencyId = 3167},
            weekly = {questId = 93695, name="Leatherworking Services Requested"},
            gathering = {}
        }
    },
    ["Mining"] = {
        name = "Mining",
        ["Midnight"] = {
            skillLineID = 2834,
            moxieId = 3264,
            knowledgePointsID = 3019,
            epicTool = { id = 246534, name = "Sunforged Pickaxe" },
            epicAccessories = {
                { id = 259173, name = "Rock Bonkin' Hardhat" },
                { id = 259175, name = "Heavy-Duty Rock Assister" },
            },
            treasureMapQuests = {},
            color = {0.6, 0.6, 0.6},
            treatise = {questId = 95135, itemId = 245762},
            darkmoon = {questId = 29518},
            concentration = {},
            weekly = {questId = { 93705, 93706, 93707, 93708, 93709 }, name="Trainer quests"},
            gathering = {questId = { 88673, 88674, 88675, 88676, 88677, 88678 }, name="Gathered while mining"},
        }
    },
    ["Skinning"] = {
        name = "Skinning",
        ["Midnight"] = {
            skillLineID = 2835,
            moxieId = 3265,
            knowledgePointsID = 3021,
            epicTool = { id = 246535, name = "Sunforged Skinning Knife" },
            epicAccessories = {
                { id = 244808, name = "Thalassian Wildseeker's Workbag" },
                { id = 244809, name = "Thalassian Wildseeker's Stridercap" },
            },
            treasureMapQuests = {},
            color = {0.8, 0.5, 0.3},
            treatise = {questId = 95136, itemId = 250360},
            darkmoon = {questId = 29519},
            concentration = {},
            weekly = {questId = { 93710, 93711, 93712, 93713, 93714 }, name="Trainer quests"},
            gathering = {questId = { 88534, 88549, 88536, 88537, 88530, 88529 }, name="Gathered while skinning"},
        }
    },
    ["Tailoring"] = {
        name = "Tailoring",
        ["Midnight"] = {
            skillLineID = 2918,
            moxieId = 3266,
            knowledgePointsID = 3018,
            epicTool = { id = 259177, name = "Self-Sharpening Sin'dorei Snippers" },
            epicAccessories = {
                { id = 267062, name = "Thalassian Tailor's Threads" },
                { id = 259234, name = "Sunforged Needle Set" },
            },
            treasureMapQuests = {
                {questId = 93542, name = "Embroidered Memento"},
                {questId = 93543, name = "Finely Woven Lynx Collar"},
            },
            color = {0.6, 0.3, 0.8},
            treatise = {questId = 95137, itemId = 245756},
            darkmoon = {questId = 29520},
            concentration = {currencyId = 3168},
            weekly = {questId = 93696, name="Tailoring Services Requested"},
            gathering = {}
        }
    },
}