local ProfessionTracker = LibStub("AceAddon-3.0"):GetAddon("ProfessionTracker")

function ProfessionTracker:UpdateSettings(container)
    local AceGUI = LibStub("AceGUI-3.0")
    container:ReleaseChildren()
    container:SetLayout("Fill")

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    container:AddChild(scroll)

    -- 0. GENERAL SETTINGS
    local generalGroup = AceGUI:Create("InlineGroup")
    generalGroup:SetTitle("General Settings")
    generalGroup:SetLayout("Flow")
    generalGroup:SetFullWidth(true)
    scroll:AddChild(generalGroup)

    local minimapCb = AceGUI:Create("CheckBox")
    minimapCb:SetLabel("Show Minimap Icon")
    minimapCb:SetValue(not self.db.profile.minimap.hide)
    minimapCb:SetCallback("OnValueChanged", function(_, _, value)
        self.db.profile.minimap.hide = not value
        local icon = LibStub("LibDBIcon-1.0", true)
        if icon then if value then icon:Show("ProfessionTracker") else icon:Hide("ProfessionTracker") end end
    end)
    generalGroup:AddChild(minimapCb)

    -- 1. CURRENCIES SETTINGS
    local currencyMainGroup = AceGUI:Create("InlineGroup")
    currencyMainGroup:SetTitle("Currencies Tab Settings")
    currencyMainGroup:SetLayout("Flow")
    currencyMainGroup:SetFullWidth(true)
    scroll:AddChild(currencyMainGroup)

    local headers = {"Name", "Realm", "Weekly Shards", "Owned Shards", "Unalloyed Abundance", "Fused Vit."}
    for _, title in ipairs(headers) do
        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel(title); cb:SetWidth(180)
        cb:SetValue(not self.db.profile.hiddenColumns[title])
        cb:SetCallback("OnValueChanged", function(_, _, val) self.db.profile.hiddenColumns[title] = not val end)
        currencyMainGroup:AddChild(cb)
    end

    -- Currencies: Character Visibility
    local curCharGroup = AceGUI:Create("InlineGroup")
    curCharGroup:SetTitle("Currencies: Character Visibility")
    curCharGroup:SetLayout("Flow")
    curCharGroup:SetFullWidth(true)
    currencyMainGroup:AddChild(curCharGroup)

    local curShowBtn = AceGUI:Create("Button")
    curShowBtn:SetText("Show All"); curShowBtn:SetWidth(120)
    curShowBtn:SetCallback("OnClick", function() wipe(self.db.profile.hiddenCharacters.currencies); self:UpdateSettings(container) end)
    curCharGroup:AddChild(curShowBtn)

    local curHideBtn = AceGUI:Create("Button")
    curHideBtn:SetText("Hide All"); curHideBtn:SetWidth(120)
    curHideBtn:SetCallback("OnClick", function() for key in pairs(self.db.profile.characters) do self.db.profile.hiddenCharacters.currencies[key] = true end; self:UpdateSettings(container) end)
    curCharGroup:AddChild(curHideBtn)

    for charKey, data in pairs(self.db.profile.characters) do
        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel(string.format("%s - %s", self:GetClassColoredName(data.name or "Unknown", data.class), data.realm or "Unknown"))
        cb:SetWidth(200); cb:SetValue(not self.db.profile.hiddenCharacters.currencies[charKey])
        cb:SetCallback("OnValueChanged", function(_, _, val) self.db.profile.hiddenCharacters.currencies[charKey] = not val end)
        curCharGroup:AddChild(cb)
    end

    -- 2. PROFESSIONS SETTINGS
    local profMainGroup = AceGUI:Create("InlineGroup")
    profMainGroup:SetTitle("Professions Tab Settings")
    profMainGroup:SetLayout("Flow")
    profMainGroup:SetFullWidth(true)
    scroll:AddChild(profMainGroup)

    -- Professions: Column Visibility
    local pHeaders = {"Name", "Realm", "Profession", "Expansion", "Moxie", "Skill", "Tool", "Acc.", "Knowledge", "Treatise", "Treasures", "Weekly", "Gathering", "Concentration", "DMF"}
    for _, title in ipairs(pHeaders) do
        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel(title); cb:SetWidth(150)
        cb:SetValue(not self.db.profile.hiddenColumnsProf[title])
        cb:SetCallback("OnValueChanged", function(_, _, val) self.db.profile.hiddenColumnsProf[title] = not val end)
        profMainGroup:AddChild(cb)
    end

    -- Professions: Expansion Visibility
    local expVisibilityGroup = AceGUI:Create("InlineGroup")
    expVisibilityGroup:SetTitle("Expansion Visibility")
    expVisibilityGroup:SetLayout("Flow")
    expVisibilityGroup:SetFullWidth(true)
    profMainGroup:AddChild(expVisibilityGroup)

    for expKey, expName in pairs(ProfessionTracker.Expansions) do
        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel(expName); cb:SetWidth(200)
        cb:SetValue(self.db.profile.activeExpansions[expKey] or false)
        cb:SetCallback("OnValueChanged", function(_, _, val) self.db.profile.activeExpansions[expKey] = val end)
        expVisibilityGroup:AddChild(cb)
    end

    -- Professions: Character Visibility
    local profCharGroup = AceGUI:Create("InlineGroup")
    profCharGroup:SetTitle("Professions: Character Visibility")
    profCharGroup:SetLayout("Flow")
    profCharGroup:SetFullWidth(true)
    profMainGroup:AddChild(profCharGroup)

    local profShowBtn = AceGUI:Create("Button")
    profShowBtn:SetText("Show All"); profShowBtn:SetWidth(120)
    profShowBtn:SetCallback("OnClick", function() wipe(self.db.profile.hiddenCharacters.professions); self:UpdateSettings(container) end)
    profCharGroup:AddChild(profShowBtn)

    local profHideBtn = AceGUI:Create("Button")
    profHideBtn:SetText("Hide All"); profHideBtn:SetWidth(120)
    profHideBtn:SetCallback("OnClick", function() for key in pairs(self.db.profile.characters) do self.db.profile.hiddenCharacters.professions[key] = true end; self:UpdateSettings(container) end)
    profCharGroup:AddChild(profHideBtn)

    for charKey, data in pairs(self.db.profile.characters) do
        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel(string.format("%s - %s", self:GetClassColoredName(data.name or "Unknown", data.class), data.realm or "Unknown"))
        cb:SetWidth(200); cb:SetValue(not self.db.profile.hiddenCharacters.professions[charKey])
        cb:SetCallback("OnValueChanged", function(_, _, val) self.db.profile.hiddenCharacters.professions[charKey] = not val end)
        profCharGroup:AddChild(cb)
    end

    scroll:DoLayout()
end