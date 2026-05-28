local ProfessionTracker = LibStub("AceAddon-3.0"):GetAddon("ProfessionTracker")

function ProfessionTracker:ShowUI()
    local AceGUI = LibStub("AceGUI-3.0")
    
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Profession Tracker")
    frame:SetLayout("Fill")
    frame:SetWidth(1300)
    frame:SetHeight(600)
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    
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
    tabGroup:SelectTab("currencies")
end

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

    table.sort(sortedChars, function(a, b)
        local field = sortMap[sortCol] or "name"
        local valA = a.data[field] or ""
        local valB = b.data[field] or ""

        if valA == valB then
            return a.key < b.key -- Stable fallback
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

function ProfessionTracker:UpdateProfessionsList(container)
    local AceGUI = LibStub("AceGUI-3.0")
    container:ReleaseChildren()
    container:SetLayout("Fill")

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    container:AddChild(scroll)

    -- 0. Calculate Dynamic Widths via Weighted Scaling
    local currentWidth = scroll.content:GetWidth()
    local totalWidth = math.max(1200, (currentWidth or 0)) - 40
    local isDMF = self:IsDMFActive()
    
    -- Define relative weights for each column based on expected content length
    local baseHeaders = {"Name", "Realm", "Profession", "Moxie", "Skill", "Tool", "Acc.", "Knowledge", "Treatise", "Treasures", "Weekly", "Gathering", "Concentration", "DMF"}
    local baseWeights = {1.0, 0.9, 1.0, 0.5, 0.6, 0.5, 0.5, 1.1, 0.7, 0.7, 0.6, 0.6, 1.0, 0.6}

    local headers, weights = {}, {}
    local totalWeight = 0
    for i, h in ipairs(baseHeaders) do
        if not self.db.profile.hiddenColumnsProf[h] then
            table.insert(headers, h)
            table.insert(weights, baseWeights[i])
            totalWeight = totalWeight + baseWeights[i]
        end
    end

    local colWidths = {}
    for i, title in ipairs(headers) do
        colWidths[title] = math.floor((weights[i] / totalWeight) * totalWidth)
    end

    -- 1. Prepare and Sort Data
    local sortCol = self.db.profile.sortColProf or "Name"
    local sortOrder = self.db.profile.sortOrderProf or "asc"
    local sortedProfs = {}

    for charKey, data in pairs(self.db.profile.characters) do
        if not self.db.profile.hiddenCharacters.professions[charKey] then
            local charHasProf = false
            for i = 1, 2 do
                local p = "p" .. i
                if data[p.."Name"] and data[p.."Name"] ~= "None" then
                    table.insert(sortedProfs, {
                        key = charKey, data = data, profName = data[p.."Name"],
                        rank = data[p.."Rank"] or 0, max = data[p.."Max"] or 0,
                        moxie = data[p.."Moxie"] or 0, spent = data[p.."Spent"] or 0,
                        unspent = data[p.."Unspent"] or 0, total = data[p.."Total"] or 0,
                        maxK = data[p.."MaxK"] or 0, treatise = data[p.."Treatise"],
                        hasTreatise = data[p.."HasTreatise"], treatiseName = data[p.."TreatiseName"],
                        treasures = data[p.."Treasures"] or 0, treasureDetails = data[p.."TreasureDetails"],
                        maxTreasures = data[p.."MaxTreasures"] or 0, concentration = data[p.."Conc"] or 0,
                        dmf = data[p.."Dmf"], hasDmf = data[p.."HasDmf"],
                        lastUpdate = data.lastUpdate, tool = data[p.."Tool"] or 0,
                        acc = data[p.."Acc"] or 0, toolName = data[p.."ToolName"],
                        accNames = data[p.."AccNames"], weekly = data[p.."Weekly"],
                        hasWeekly = data[p.."HasWeekly"], weeklyName = data[p.."WeeklyName"],
                        gathering = data[p.."Gathering"] or 0, maxGathering = data[p.."MaxGathering"] or 0,
                        gatheringDetails = data[p.."GatheringDetails"]
                    })
                    charHasProf = true
                end
            end
            if not charHasProf then
                table.insert(sortedProfs, { key = charKey, data = data, profName = "None", rank = 0, max = 0, moxie = 0, spent = 0, unspent = 0, total = 0, maxK = 0, treatise = false, hasTreatise = false, weekly = false, hasWeekly = false, treasures = 0, maxTreasures = 0, gathering = 0, maxGathering = 0, lastUpdate = data.lastUpdate })
            end
        end
    end

    local sortMap = {
        ["Name"] = "name",
        ["Realm"] = "realm",
        ["Profession"] = "profName",
        ["Moxie"] = "moxie",
        ["Skill"] = "rank",
        ["Tool"] = "tool",
        ["Acc."] = "acc",
        ["Knowledge"] = "total",
        ["Treatise"] = "treatise",
        ["Treasures"] = "treasures",
        ["Weekly"] = "weekly",
        ["Gathering"] = "gathering",
        ["Concentration"] = "concentration",
        ["DMF"] = "dmf"
    }

    table.sort(sortedProfs, function(a, b)
        local field = sortMap[sortCol] or "name"
        local valA = (field == "name" or field == "realm") and a.data[field] or a[field]
        local valB = (field == "name" or field == "realm") and b.data[field] or b[field]
        valA = valA or ""
        valB = valB or ""

        if valA == valB then
            if field ~= "name" and a.data.name ~= b.data.name then
                return a.data.name < b.data.name
            end
            return a.profName < b.profName
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

    for i, title in ipairs(headers) do
        local label = AceGUI:Create("InteractiveLabel")
        local headerText = title
        if sortCol == title then
            headerText = headerText .. (sortOrder == "asc" and " (Asc)" or " (Desc)")
        end
        label:SetText(headerText)
            label:SetWidth(colWidths[title])
        if label.label then label.label:SetWordWrap(false) end
        if i > 3 then
            label:SetJustifyH("CENTER")
        end
        local fontPath, _, fontFlags = GameFontHighlight:GetFont()
        label:SetFont(fontPath, 12, "OUTLINE")
        label:SetColor(0.5, 0.5, 0.5) 

        label:SetCallback("OnClick", function()
            if self.db.profile.sortColProf == title then
                self.db.profile.sortOrderProf = (self.db.profile.sortOrderProf == "asc") and "desc" or "asc"
            else
                self.db.profile.sortColProf = title
                self.db.profile.sortOrderProf = "asc"
            end
            self:UpdateProfessionsList(container)
        end)

        header:AddChild(label)
    end

    -- 3. Build Rows
    for rowIdx, entry in ipairs(sortedProfs) do
        local data = entry.data
        local charKey = entry.key

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

        -- Name & Realm
        if not self.db.profile.hiddenColumnsProf["Name"] then
            local displayName = self:GetClassColoredName(data.name or charKey, data.class)
            self:AddCol(row, displayName, colWidths["Name"])
        end
        if not self.db.profile.hiddenColumnsProf["Realm"] then
            self:AddCol(row, data.realm or "Unknown", colWidths["Realm"])
        end

        -- Profession
        local profConfig = self.ProfessionData[entry.profName]
        if not self.db.profile.hiddenColumnsProf["Profession"] then
            local profDisplayName = entry.profName
            if profConfig and profConfig.color then
                local r, g, b = unpack(profConfig.color)
                profDisplayName = string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, entry.profName)
            end
            self:AddCol(row, profDisplayName, colWidths["Profession"])
        end

        -- Moxie (Artisan's Acuity/Mettle)
        if not self.db.profile.hiddenColumnsProf["Moxie"] then
            local moxieText = self:GetColorText(entry.moxie or 0, 600)
            self:AddCol(row, moxieText, colWidths["Moxie"], "CENTER")
        end

        -- Skill (Combined current/max)
        if not self.db.profile.hiddenColumnsProf["Skill"] then
            local skillText = self:GetColorText(entry.rank, entry.max, "/" .. entry.max)
            self:AddCol(row, skillText, colWidths["Skill"], "CENTER")
        end

        -- Tool (unchanged)
        if not self.db.profile.hiddenColumnsProf["Tool"] then
            local toolText = "-"
            if profConfig and profConfig.epicTool then
                toolText = self:GetColorText(entry.tool, 1, "/1")
                local lbl = self:AddCol(row, toolText, colWidths["Tool"], "CENTER")
                if entry.toolName and entry.toolName ~= "" then
                    lbl.frame:SetScript("OnEnter", function(frame)
                        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                        GameTooltip:SetText("|cffffd100Equipped Tool|r")
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cffa335ee" .. entry.toolName .. "|r")
                        GameTooltip:Show()
                    end)
                    lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            else
                self:AddCol(row, toolText, colWidths["Tool"], "CENTER")
            end
        end

        -- Accessories (unchanged)
        if not self.db.profile.hiddenColumnsProf["Acc."] then
            local accText = "-"
            if profConfig and profConfig.epicAccessories and #profConfig.epicAccessories > 0 then
                accText = self:GetColorText(entry.acc, 2, "/2")
                local lbl = self:AddCol(row, accText, colWidths["Acc."], "CENTER")
                if entry.accNames and entry.accNames ~= "" then
                    lbl.frame:SetScript("OnEnter", function(frame)
                        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                        GameTooltip:SetText("|cffffd100Equipped Accessories|r")
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cffa335ee" .. entry.accNames .. "|r")
                        GameTooltip:Show()
                    end)
                    lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            else
                self:AddCol(row, accText, colWidths["Acc."], "CENTER")
            end
        end

        -- Knowledge (Spent (Unspent Available) / Capacity)
        if not self.db.profile.hiddenColumnsProf["Knowledge"] then
            local spent, unspent, capacity = tonumber(entry.spent) or 0, tonumber(entry.unspent) or 0, tonumber(entry.maxK) or 0
            local baseColor = "" 
            if spent == 0 then
                baseColor = "|cff808080" 
            elseif capacity > 0 and (spent + unspent) >= capacity then
                baseColor = "|cff00ff00" 
            end
            local unspentStr = ""
            if unspent > 0 then
                unspentStr = string.format(" |cffffff00(%d)|r%s", unspent, baseColor)
            end
            local kText = string.format("%s%d%s / %d|r", baseColor, spent, unspentStr, capacity)
            self:AddCol(row, kText, colWidths["Knowledge"], "CENTER")
        end

        -- Treatise
        if not self.db.profile.hiddenColumnsProf["Treatise"] then
            local treatiseText = "-"
            if entry.hasTreatise then
                local val = entry.treatise and 1 or 0
                treatiseText = self:GetColorText(val, 1, "/1")
                local lbl = self:AddCol(row, treatiseText, colWidths["Treatise"], "CENTER")
                if entry.treatiseName and entry.treatiseName ~= "" then
                    lbl.frame:SetScript("OnEnter", function(frame)
                        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                        GameTooltip:SetText("|cffffd100Weekly Treatise|r")
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cffa335ee" .. entry.treatiseName .. "|r")
                        GameTooltip:Show()
                    end)
                    lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            else
                self:AddCol(row, treatiseText, colWidths["Treatise"], "CENTER")
            end
        end

        -- Treasures
        if not self.db.profile.hiddenColumnsProf["Treasures"] then
            local treasureText = "-"
            if entry.maxTreasures > 0 then
                treasureText = self:GetColorText(entry.treasures, entry.maxTreasures, "/" .. entry.maxTreasures)
                local lbl = self:AddCol(row, treasureText, colWidths["Treasures"], "CENTER")
                if entry.treasureDetails and entry.treasureDetails ~= "" then
                    lbl.frame:SetScript("OnEnter", function(frame)
                        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                        GameTooltip:SetText("|cffffd100Profession Treasures|r")
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(entry.treasureDetails)
                        GameTooltip:Show()
                    end)
                    lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            else
                self:AddCol(row, treasureText, colWidths["Treasures"], "CENTER")
            end
        end

        -- Weekly Quest
        if not self.db.profile.hiddenColumnsProf["Weekly"] then
            local weeklyText = "-"
            if entry.hasWeekly then
                local val = entry.weekly and 1 or 0
                weeklyText = self:GetColorText(val, 1, "/1")
                local lbl = self:AddCol(row, weeklyText, colWidths["Weekly"], "CENTER")
                if entry.weeklyName and entry.weeklyName ~= "" then
                    lbl.frame:SetScript("OnEnter", function(frame)
                        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                        GameTooltip:SetText("|cffffd100Weekly Profession Quest|r")
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cffa335ee" .. entry.weeklyName .. "|r")
                        GameTooltip:Show()
                    end)
                    lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            else
                self:AddCol(row, weeklyText, colWidths["Weekly"], "CENTER")
            end
        end

        -- Gathering Progress
        if not self.db.profile.hiddenColumnsProf["Gathering"] then
            local gatheringText = ""
            if entry.maxGathering > 0 then
                gatheringText = self:GetColorText(entry.gathering, entry.maxGathering, "/" .. entry.maxGathering)
                local lbl = self:AddCol(row, gatheringText, colWidths["Gathering"], "CENTER")
                if entry.gatheringDetails and entry.gatheringDetails ~= "" then
                    lbl.frame:SetScript("OnEnter", function(frame)
                        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                        GameTooltip:SetText("|cffffd100Weekly Gathering Progress|r")
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(entry.gatheringDetails)
                        GameTooltip:Show()
                    end)
                    lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            else
                self:AddCol(row, gatheringText, colWidths["Gathering"], "CENTER")
            end
        end

        -- Concentration (with live estimation and tooltip)
        if not self.db.profile.hiddenColumnsProf["Concentration"] then
            if profConfig and profConfig.concentration and profConfig.concentration.currencyId > 0 then
                local currentTime = time()
                local elapsed = currentTime - (entry.lastUpdate or currentTime)
                local recharged = math.floor(elapsed / 360) 
                local estimated = math.min(1000, entry.concentration + recharged)
                local concText = self:GetColorText(estimated, 900, "/1000")
                local lbl = self:AddCol(row, concText, colWidths["Concentration"], "CENTER")
                lbl.frame:SetScript("OnEnter", function(frame)
                    local needed = 1000 - estimated
                    local timeToMaxStr = "Full"
                    if needed > 0 then
                        local seconds = needed * 360
                        local hours = math.floor(seconds / 3600)
                        local mins = math.floor((seconds % 3600) / 60)
                        timeToMaxStr = string.format("%dh %dm", hours, mins)
                    end
                    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Concentration Details", 1, 1, 1)
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddDoubleLine("Saved:", entry.concentration, 1, 1, 1, 1, 1, 1)
                    GameTooltip:AddDoubleLine("Estimated:", estimated, 1, 1, 1, 1, 1, 1)
                    GameTooltip:AddDoubleLine("Time to Max:", timeToMaxStr, 1, 1, 1, 1, 1, 1)
                    GameTooltip:AddDoubleLine("Last Saved:", date("%Y-%m-%d %H:%M:%S", entry.lastUpdate), 0.5, 0.5, 0.5, 0.5, 0.5, 0.5)
                    GameTooltip:Show()
                end)
                lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
            else
                self:AddCol(row, "-", colWidths["Concentration"], "CENTER")
            end
        end

        -- Darkmoon Faire
        if not self.db.profile.hiddenColumnsProf["DMF"] then
            local dmfText = "-"
            if entry.hasDmf then
                if isDMF then
                    local val = entry.dmf and 1 or 0
                    dmfText = self:GetColorText(val, 1, "/1")
                    self:AddCol(row, dmfText, colWidths["DMF"], "CENTER")
                else
                    dmfText = "|cff808080Closed|r"
                    local lbl = self:AddCol(row, dmfText, colWidths["DMF"], "CENTER")
                    lbl.frame:SetScript("OnEnter", function(frame)
                        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                        GameTooltip:SetText("|cffffd100Darkmoon Faire|r")
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("The Darkmoon Faire is currently closed.", 1, 1, 1)
                        GameTooltip:AddLine("It opens on the first Sunday of every month.", 0.5, 0.5, 0.5)
                        GameTooltip:Show()
                    end)
                    lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            else
                self:AddCol(row, dmfText, colWidths["DMF"], "CENTER")
            end
        end
    end

    scroll:DoLayout()
end

function ProfessionTracker:UpdateSettings(container)
    local AceGUI = LibStub("AceGUI-3.0")
    container:ReleaseChildren()
    container:SetLayout("Fill")

    -- Create a main scroll frame to prevent window overflow
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    container:AddChild(scroll)

    local headers = {"Name", "Realm", "Weekly Shards", "Owned Shards", "Unalloyed Abundance", "Fused Vit."}

    -- 1. CURRENCIES MASTER GROUP
    local currencyMainGroup = AceGUI:Create("InlineGroup")
    currencyMainGroup:SetTitle("Currencies Tab Settings")
    currencyMainGroup:SetLayout("Flow")
    currencyMainGroup:SetFullWidth(true)
    scroll:AddChild(currencyMainGroup)

    -- Nested: Column Visibility
    local columnGroup = AceGUI:Create("InlineGroup")
    columnGroup:SetTitle("Currencies: Column Visibility")
    columnGroup:SetLayout("Flow")
    columnGroup:SetFullWidth(true)
    currencyMainGroup:AddChild(columnGroup)

    local desc = AceGUI:Create("Label")
    desc.frame:SetScript("OnEnter", nil)
    desc.frame:SetScript("OnLeave", nil)
    desc:SetText("Select which columns you want to display in the Currencies tab:")
    local fontPath, _, fontFlags = GameFontHighlight:GetFont()
    desc:SetFont(fontPath, 13, "OUTLINE")
    desc:SetFullWidth(true)
    columnGroup:AddChild(desc)

    for _, title in ipairs(headers) do
        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel(title)
        cb:SetWidth(180) -- Fixed width allows them to flow into columns
        cb:SetValue(not self.db.profile.hiddenColumns[title])
        cb:SetCallback("OnValueChanged", function(_, _, value)
            self.db.profile.hiddenColumns[title] = not value
        end)
        columnGroup:AddChild(cb)
    end

    -- Nested: Character Visibility (Specific to Currencies)
    local charGroup = AceGUI:Create("InlineGroup")
    charGroup:SetTitle("Currencies: Character Visibility")
    charGroup:SetLayout("Flow")
    charGroup:SetFullWidth(true)
    currencyMainGroup:AddChild(charGroup)

    -- Utility Buttons for Currencies
    local curBtnGroup = AceGUI:Create("SimpleGroup")
    curBtnGroup:SetLayout("Flow")
    curBtnGroup:SetFullWidth(true)
    charGroup:AddChild(curBtnGroup)

    local curShowBtn = AceGUI:Create("Button")
    curShowBtn:SetText("Show All")
    curShowBtn:SetWidth(120)
    curShowBtn:SetCallback("OnClick", function()
        wipe(self.db.profile.hiddenCharacters.currencies)
        self:UpdateSettings(container)
    end)
    curBtnGroup:AddChild(curShowBtn)

    local curHideBtn = AceGUI:Create("Button")
    curHideBtn:SetText("Hide All")
    curHideBtn:SetWidth(120)
    curHideBtn:SetCallback("OnClick", function()
        for key in pairs(self.db.profile.characters) do
            self.db.profile.hiddenCharacters.currencies[key] = true
        end
        self:UpdateSettings(container)
    end)
    curBtnGroup:AddChild(curHideBtn)

    -- Character list group (now grows naturally within the main scroll)
    local curCharList = AceGUI:Create("SimpleGroup")
    curCharList:SetLayout("Flow")
    curCharList:SetFullWidth(true)
    charGroup:AddChild(curCharList)

    for charKey, data in pairs(self.db.profile.characters) do
        local cb = AceGUI:Create("CheckBox")
        local coloredName = self:GetClassColoredName(data.name or "Unknown", data.class)
        cb:SetLabel(string.format("%s - %s", coloredName, data.realm or "Unknown"))
        cb:SetWidth(200)
        cb:SetValue(not self.db.profile.hiddenCharacters.currencies[charKey])
        cb:SetCallback("OnValueChanged", function(_, _, value)
            self.db.profile.hiddenCharacters.currencies[charKey] = not value
        end)
        curCharList:AddChild(cb)
    end

    -- 2. PROFESSIONS MASTER GROUP
    local profMainGroup = AceGUI:Create("InlineGroup")
    profMainGroup:SetTitle("Professions Tab Settings")
    profMainGroup:SetLayout("Flow")
    profMainGroup:SetFullWidth(true)
    scroll:AddChild(profMainGroup)

    -- Nested: Column Visibility
    local profColumnGroup = AceGUI:Create("InlineGroup")
    profColumnGroup:SetTitle("Professions: Column Visibility")
    profColumnGroup:SetLayout("Flow")
    profColumnGroup:SetFullWidth(true)
    profMainGroup:AddChild(profColumnGroup)

    local pDesc = AceGUI:Create("Label")
    pDesc.frame:SetScript("OnEnter", nil)
    pDesc.frame:SetScript("OnLeave", nil)
    pDesc:SetText("Select which columns you want to display in the Professions tab:")
    pDesc:SetFont(fontPath, 13, "OUTLINE")
    pDesc:SetFullWidth(true)
    profColumnGroup:AddChild(pDesc)

    local pHeaders = {"Name", "Realm", "Profession", "Moxie", "Skill", "Tool", "Acc.", "Knowledge", "Treatise", "Treasures", "Weekly", "Gathering", "Concentration", "DMF"}
    for _, title in ipairs(pHeaders) do
        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel(title)
        cb:SetWidth(150)
        cb:SetValue(not self.db.profile.hiddenColumnsProf[title])
        cb:SetCallback("OnValueChanged", function(_, _, value)
            self.db.profile.hiddenColumnsProf[title] = not value
        end)
        profColumnGroup:AddChild(cb)
    end

    local gatherCharGroup = AceGUI:Create("InlineGroup")
    gatherCharGroup:SetTitle("Professions: Character Visibility")
    gatherCharGroup:SetLayout("Flow")
    gatherCharGroup:SetFullWidth(true)
    profMainGroup:AddChild(gatherCharGroup)

    -- Utility Buttons for Gathering
    local gatBtnGroup = AceGUI:Create("SimpleGroup")
    gatBtnGroup:SetLayout("Flow")
    gatBtnGroup:SetFullWidth(true)
    gatherCharGroup:AddChild(gatBtnGroup)

    local gatShowBtn = AceGUI:Create("Button")
    gatShowBtn:SetText("Show All")
    gatShowBtn:SetWidth(120)
    gatShowBtn:SetCallback("OnClick", function()
        wipe(self.db.profile.hiddenCharacters.professions)
        self:UpdateSettings(container)
    end)
    gatBtnGroup:AddChild(gatShowBtn)

    local gatHideBtn = AceGUI:Create("Button")
    gatHideBtn:SetText("Hide All")
    gatHideBtn:SetWidth(120)
    gatHideBtn:SetCallback("OnClick", function()
        for key in pairs(self.db.profile.characters) do
            self.db.profile.hiddenCharacters.professions[key] = true
        end
        self:UpdateSettings(container)
    end)
    gatBtnGroup:AddChild(gatHideBtn)

    local gatCharList = AceGUI:Create("SimpleGroup")
    gatCharList:SetLayout("Flow")
    gatCharList:SetFullWidth(true)
    gatherCharGroup:AddChild(gatCharList)

    for charKey, data in pairs(self.db.profile.characters) do
        local cb = AceGUI:Create("CheckBox")
        local coloredName = self:GetClassColoredName(data.name or "Unknown", data.class)
        cb:SetLabel(string.format("%s - %s", coloredName, data.realm or "Unknown"))
        cb:SetWidth(200)
        cb:SetValue(not self.db.profile.hiddenCharacters.professions[charKey])
        cb:SetCallback("OnValueChanged", function(_, _, value)
            self.db.profile.hiddenCharacters.professions[charKey] = not value
        end)
        gatCharList:AddChild(cb)
    end

    scroll:DoLayout()
end