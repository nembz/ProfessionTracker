local ProfessionTracker = LibStub("AceAddon-3.0"):GetAddon("ProfessionTracker")

function ProfessionTracker:ShowUI()
    local AceGUI = LibStub("AceGUI-3.0")
    
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Profession Tracker")
    frame:SetLayout("Fill")
    frame:SetWidth(1300)
    frame:SetHeight(600)
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    
    -- Allow closing the window with the Escape key
    _G["ProfessionTrackerMainFrame"] = frame.frame
    local isRegistered = false
    for _, name in ipairs(UISpecialFrames) do
        if name == "ProfessionTrackerMainFrame" then isRegistered = true; break end
    end
    if not isRegistered then
        table.insert(UISpecialFrames, "ProfessionTrackerMainFrame")
    end

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Fill")
    tabGroup:SetTabs({
        {text="Currencies", value="currencies"},
        {text="Professions", value="professions"},
        {text="Settings", value="settings"}
    })

    local fontPath = GameFontHighlight:GetFont()
    local TabFont = _G["ProfessionTrackerTabFont"] or CreateFont("ProfessionTrackerTabFont")
    TabFont:SetFont(fontPath, 12, "OUTLINE")

    for _, tab in ipairs(tabGroup.tabs) do
        tab:SetNormalFontObject(TabFont)
        tab:SetHighlightFontObject(TabFont)
        tab:SetDisabledFontObject(TabFont)
    end

    tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
        container:ReleaseChildren()
        GameTooltip:Hide()
        if group == "currencies" then
            self:UpdateCharacterList(container)
        elseif group == "professions" then
            self:UpdateProfessionsList(container)
        elseif group == "settings" then
            self:UpdateSettings(container)
        end
    end)
    
    frame:AddChild(tabGroup)
    tabGroup:SelectTab(self.db.profile.defaultTab or "currencies")
end