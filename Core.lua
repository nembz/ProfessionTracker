local ProfessionTracker = LibStub("AceAddon-3.0"):NewAddon("ProfessionTracker", "AceConsole-3.0", "AceEvent-3.0")

function ProfessionTracker:OnInitialize()
    local defaults = {
        profile = {
            characters = {},
            hiddenColumns = {},
            hiddenColumnsProf = {},
            hiddenCharacters = {
                currencies = {},
                professions = {}
            },
            sortCol = "Name",
            sortOrder = "asc",
            sortColProf = "Name",
            sortOrderProf = "asc"
        }
    }
    self.db = LibStub("AceDB-3.0"):New("ProfessionTrackerDB", defaults, true)

    self:RegisterChatCommand("pt", function(input)
        if input == "reset" then
            self:ResetData()
        else
            self:ShowUI()
        end
    end)

    self:Print("ProfessionTracker Loaded! Type /pt to open.")
end

function ProfessionTracker:OnEnable()
    -- Update data when the player is fully logged in
    self:UpdatePlayerData()
    self:RegisterEvent("QUEST_TURNED_IN", "UpdatePlayerData")
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE", "UpdatePlayerData")
    self:RegisterEvent("BAG_UPDATE_DELAYED", "UpdatePlayerData")
    self:RegisterEvent("LOOT_CLOSED", "UpdatePlayerData")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "UpdatePlayerData")
end

function ProfessionTracker:ResetData()
    self.db.profile.characters = {}
    self:Print("Data has been reset! Reloading UI...")
    C_UI.Reload()
end