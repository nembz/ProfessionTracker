local ProfessionTracker = LibStub("AceAddon-3.0"):NewAddon("ProfessionTracker", "AceConsole-3.0", "AceEvent-3.0")
local icon = LibStub("LibDBIcon-1.0", true)

function ProfessionTracker:OnInitialize()
    local defaults = {
        profile = {
            characters = {},
            hiddenColumns = {},
            hiddenColumnsProf = {},
            minimap = {
                hide = false,
            },
            hiddenCharacters = {
                currencies = {},
                professions = {}
            },
            sortCol = "Name",
            sortOrder = "asc",
            sortColProf = "Name",
            sortOrderProf = "asc",
            activeExpansions = { -- New default setting for expansion visibility
                ["Midnight"] = true,
            }
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

    -- Initialize Minimap Icon via DataBroker
    local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("ProfessionTracker", {
        type = "launcher",
        text = "ProfessionTracker",
        icon = "Interface\\Addons\\ProfessionTracker\\Icons\\Logo.png",
        OnClick = function(clickedframe, button)
            if button == "LeftButton" then
                self:ShowUI()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("ProfessionTracker")
            tooltip:AddLine("|cffeda55fLeft-Click|r to open the tracker.", 0.2, 1, 0.2)
        end,
    })

    if icon then
        icon:Register("ProfessionTracker", LDB, self.db.profile.minimap)
    end
end

-- Simple throttle to prevent excessive data scanning
function ProfessionTracker:ThrottledUpdate()
    if self.updateTimer then return end
    self.updateTimer = C_Timer.After(2, function()
        self:UpdatePlayerData()
        self.updateTimer = nil
    end)
end

function ProfessionTracker:OnEnable()
    -- Update data when the player is fully logged in
    self:UpdatePlayerData()
    -- Use throttled update for high-frequency events
    self:RegisterEvent("QUEST_TURNED_IN", "ThrottledUpdate")
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE", "ThrottledUpdate")
    self:RegisterEvent("BAG_UPDATE_DELAYED", "ThrottledUpdate")
    self:RegisterEvent("LOOT_CLOSED", "ThrottledUpdate")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "ThrottledUpdate")
end

function ProfessionTracker:ResetData()
    self.db.profile.characters = {}
    self:Print("Data has been reset! Reloading UI...")
    C_UI.Reload()
end