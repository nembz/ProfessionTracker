local ProfessionTracker = LibStub("AceAddon-3.0"):GetAddon("ProfessionTracker")

function ProfessionTracker:UpdateCharacterList(container)
    local AceGUI = LibStub("AceGUI-3.0")
    container:ReleaseChildren()
    container:SetLayout("Fill")

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    container:AddChild(scroll)

    -- 0. Calculate Dynamic Widths
    local currentWidth = scroll.content:GetWidth()
    local totalWidth = ((currentWidth and currentWidth > 0) and currentWidth or 1200) - 40
    local headers = {"Name", "Realm", "Weekly Shards", "Owned Shards", "Unalloyed Abundance", "Fused Vit."}
    local visibleCount = 0
    local colWidths = {}

    for _, title in ipairs(headers) do
        if not self.db.profile.hiddenColumns[title] then visibleCount = visibleCount + 1 end
    end
    
    local colWidth = math.floor(totalWidth / (visibleCount > 0 and visibleCount or 1))
    for _, title in ipairs(headers) do colWidths[title] = colWidth end

    -- 1. Prepare and Sort Data
    local sortCol = self.db.profile.sortCol or "Name"
    local sortOrder = self.db.profile.sortOrder or "asc"
    local sortedChars = {}

    for charKey, data in pairs(self.db.profile.characters) do
        if not self.db.profile.hiddenCharacters.currencies[charKey] then
            table.insert(sortedChars, { key = charKey, data = data })
        end
    end

    local sortMap = {
        ["Name"] = "name",
        ["Realm"] = "realm",
        ["Weekly Shards"] = "weeklyShards",
        ["Owned Shards"] = "shards",
        ["Unalloyed Abundance"] = "abundance",
        ["Fused Vit."] = "vitality"
    }

    -- Optimization: Pre-calculate sort values once per row
    local sortField = sortMap[sortCol] or "name"
    for _, entry in ipairs(sortedChars) do
        entry.sortVal = entry.data[sortField] or ""
    end

    table.sort(sortedChars, function(a, b)
        local valA, valB = a.sortVal, b.sortVal

        if valA == valB then
            return a.key < b.key -- Stable fallback for identical sort values
        end

        if sortOrder == "asc" then
            return valA < valB
        else
            return valA > valB
        end
    end)

    -- 2. Build Headers
    local header = AceGUI:Create("SimpleGroup")
    header:SetLayout("Flow")
    header:SetFullWidth(true)
    scroll:AddChild(header)

    if header.bg then
        header.bg:Hide()
    end

    for _, title in ipairs(headers) do
        if not self.db.profile.hiddenColumns[title] then
            local label = AceGUI:Create("InteractiveLabel")
            local headerText = title
            if sortCol == title then
                headerText = headerText .. (sortOrder == "asc" and " (Asc)" or " (Desc)")
            end
            label:SetText(headerText)
            label:SetWidth(colWidth)
            if label.label then label.label:SetWordWrap(false) end
            if title ~= "Name" and title ~= "Realm" then
                label:SetJustifyH("CENTER")
            end
            local fontPath, _, fontFlags = GameFontHighlight:GetFont()
            label:SetFont(fontPath, 12, "OUTLINE")
            label:SetColor(0.5, 0.5, 0.5) 

            label:SetCallback("OnClick", function()
                if self.db.profile.sortCol == title then
                    self.db.profile.sortOrder = (self.db.profile.sortOrder == "asc") and "desc" or "asc"
                else
                    self.db.profile.sortCol = title
                    self.db.profile.sortOrder = "asc"
                end
                self:UpdateCharacterList(container)
            end)

            header:AddChild(label)
        end
    end

    -- 3. Build Rows
    for rowIdx, charEntry in ipairs(sortedChars) do
        local data = charEntry.data
        local charKey = charEntry.key

        local row = AceGUI:Create("SimpleGroup")
        row:SetLayout("Flow")
        row:SetFullWidth(true)
        scroll:AddChild(row)

        if not row.bg then
            row.bg = row.frame:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
        end

        if rowIdx % 2 == 0 then
            row.bg:SetColorTexture(1, 1, 1, 0.05)
            row.bg:Show()
        else
            row.bg:Hide()
        end

        if not self.db.profile.hiddenColumns["Name"] then
            local displayName = self:GetClassColoredName(data.name or charKey, data.class)
            self:AddCol(row, displayName, colWidths["Name"])
        end

        if not self.db.profile.hiddenColumns["Realm"] then
            self:AddCol(row, data.realm or "Unknown", colWidths["Realm"])
        end

        if not self.db.profile.hiddenColumns["Weekly Shards"] then
            local weeklyText = self:GetColorText(data.weeklyShards, 8, "/8")
            self:AddCol(row, weeklyText, colWidths["Weekly Shards"], "CENTER")
        end

        if not self.db.profile.hiddenColumns["Owned Shards"] then
            local shardText = self:GetColorText(data.shards, 8, "/8")
            self:AddCol(row, shardText, colWidths["Owned Shards"], "CENTER") 
        end

        if not self.db.profile.hiddenColumns["Unalloyed Abundance"] then
            local abundText = self:GetColorText(data.abundance, 800)
            self:AddCol(row, abundText, colWidths["Unalloyed Abundance"], "CENTER")
        end
        
        if not self.db.profile.hiddenColumns["Fused Vit."] then
            local vitText = self:GetColorText(data.vitality, 20)
            self:AddCol(row, vitText, colWidths["Fused Vit."], "CENTER")
        end
    end

    scroll:DoLayout()
end