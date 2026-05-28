local ProfessionTracker = LibStub("AceAddon-3.0"):GetAddon("ProfessionTracker")

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
    local baseHeaders = {"Name", "Realm", "Profession", "Expansion", "Moxie", "Skill", "Tool", "Acc.", "Knowledge", "Treatise", "Treasures", "Weekly", "Gathering", "Concentration", "DMF"}
    local baseWeights = {1.0, 0.9, 1.0, 0.8, 0.5, 0.6, 0.5, 0.5, 1.1, 0.7, 0.7, 0.6, 0.6, 1.0, 0.6}

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
            if data.professions then -- Check for the new 'professions' table
                for pName, expDataList in pairs(data.professions) do
                    for expKey, expData in pairs(expDataList) do
                        -- Only add if this expansion is active in settings
                        if self.db.profile.activeExpansions[expKey] then
                            table.insert(sortedProfs, {
                                key = charKey,
                                data = data, -- Base character data
                                profName = pName,
                                expansionKey = expKey, -- Store expansion key
                                expansionName = ProfessionTracker.Expansions[expKey], -- Store display name
                                expData = expData, -- The actual profession data for this expansion
                                lastUpdate = data.lastUpdate -- Last update from characterData
                            })
                        end
                    end
                end
            end
        end
    end

    local sortMap = {
        ["Name"] = "name",
        ["Realm"] = "realm",
        ["Profession"] = "profName",
        ["Expansion"] = "expansionName",
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
    
    -- Helper to get the actual value for sorting, considering the new nested structure
    local function getSortValue(entry, field)
        if field == "name" or field == "realm" then return entry.data[field] end
        if field == "profName" or field == "expansionName" then return entry[field] end
        return entry.expData[field]
    end

    -- Optimization: Pre-calculate sort values once per row
    local sortField = sortMap[sortCol] or "name"
    for _, entry in ipairs(sortedProfs) do
        entry.sortVal = getSortValue(entry, sortField)
    end

    table.sort(sortedProfs, function(a, b)
        local valA, valB = a.sortVal or "", b.sortVal or ""

        if valA == valB then
            if sortField ~= "name" and a.data.name ~= b.data.name then
                return a.data.name < b.data.name
            end
            if sortField ~= "profName" and a.profName ~= b.profName then
                return a.profName < b.profName
            end
            return a.expansionName < b.expansionName -- Secondary sort by expansion
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

    local leftAlignedColumns = { ["Name"] = true, ["Realm"] = true, ["Profession"] = true }

    for i, title in ipairs(headers) do
        local label = AceGUI:Create("InteractiveLabel")
        local headerText = title
        if sortCol == title then
            headerText = headerText .. (sortOrder == "asc" and " (Asc)" or " (Desc)")
        end
        label:SetText(headerText)
            label:SetWidth(colWidths[title])
        if label.label then label.label:SetWordWrap(false) end
        if not leftAlignedColumns[title] then
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
        local expData = entry.expData -- The expansion-specific data

        local row = AceGUI:Create("SimpleGroup")
        row:SetLayout("Flow")
        row:SetFullWidth(true)
        scroll:AddChild(row)

        -- Handle empty profession slots
        if entry.profName == "None" then row:SetAlpha(0.5) end

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
            local displayName = self:GetClassColoredName(data.name or entry.key, data.class)
            self:AddCol(row, displayName, colWidths["Name"])
        end
        if not self.db.profile.hiddenColumnsProf["Realm"] then
            self:AddCol(row, data.realm or "Unknown", colWidths["Realm"])
        end

        -- Profession
        local profConfig = self.ProfessionData[entry.profName]
        if not self.db.profile.hiddenColumnsProf["Profession"] then
            local profDisplayName = entry.profName
            if profConfig and profConfig[entry.expansionKey] and profConfig[entry.expansionKey].color then
                local r, g, b = unpack(profConfig[entry.expansionKey].color)
                profDisplayName = string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, entry.profName)
            end
            self:AddCol(row, profDisplayName, colWidths["Profession"])
        end

        -- Expansion
        if not self.db.profile.hiddenColumnsProf["Expansion"] then
            self:AddCol(row, entry.expansionName or "N/A", colWidths["Expansion"], "CENTER")
        end

        -- Moxie, Skill, etc.
        if not self.db.profile.hiddenColumnsProf["Moxie"] then
            self:AddCol(row, self:GetColorText(expData.moxie or 0, 600), colWidths["Moxie"], "CENTER")
        end

        if not self.db.profile.hiddenColumnsProf["Skill"] then
            self:AddCol(row, self:GetColorText(expData.rank, expData.max, "/" .. (expData.max or 0)), colWidths["Skill"], "CENTER")
        end

        -- Tool & Accessories with Tooltips
        if not self.db.profile.hiddenColumnsProf["Tool"] then
            local toolText = "-"
            local currentExpProfConfig = profConfig[entry.expansionKey] -- Already checked profConfig exists
            if currentExpProfConfig and currentExpProfConfig.epicTool then
                local toolName = currentExpProfConfig.epicTool.name
                local isEquipped = (expData.tool == 1)
                toolText = self:GetColorText(expData.tool, 1, "/1")
                local lbl = self:AddCol(row, toolText, colWidths["Tool"], "CENTER")
                if toolName and toolName ~= "" then
                    lbl.frame:SetScript("OnEnter", function(frame)
                        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                        GameTooltip:SetText("|cffffd100Profession Tool|r")
                        GameTooltip:AddLine(" ")
                        local status = isEquipped and "|cff00ff00[Equipped]|r" or "|cff808080[Not Equipped]|r"
                        GameTooltip:AddLine(string.format("%s %s", status, "|cffa335ee" .. toolName .. "|r"))
                        GameTooltip:Show()
                    end)
                    lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            else
                self:AddCol(row, toolText, colWidths["Tool"], "CENTER")
            end
        end

        if not self.db.profile.hiddenColumnsProf["Acc."] then
            local accText = "-"
            local currentExpProfConfig = profConfig[entry.expansionKey] -- Already checked profConfig exists
            if currentExpProfConfig and currentExpProfConfig.epicAccessories and #currentExpProfConfig.epicAccessories > 0 then
                local maxAcc = #currentExpProfConfig.epicAccessories
                accText = self:GetColorText(expData.acc, maxAcc, "/" .. maxAcc)
                local lbl = self:AddCol(row, accText, colWidths["Acc."], "CENTER")
                lbl.frame:SetScript("OnEnter", function(frame)
                    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
                    GameTooltip:SetText("|cffffd100Profession Accessories|r")
                    GameTooltip:AddLine(" ")
                    local equippedAccIDsMap = {}
                    for _, id in ipairs(expData.equippedAccIDs or {}) do equippedAccIDsMap[id] = true end
                    for _, accDef in ipairs(currentExpProfConfig.epicAccessories) do
                        local isEquipped = equippedAccIDsMap[accDef.id]
                        local status = isEquipped and "|cff00ff00[Equipped]|r" or "|cff808080[Not Equipped]|r"
                        GameTooltip:AddLine(string.format("%s %s", status, "|cffa335ee" .. accDef.name .. "|r"))
                    end
                    GameTooltip:Show()
                end)
                lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
            else
                self:AddCol(row, accText, colWidths["Acc."], "CENTER")
            end
        end

        -- Knowledge
        if not self.db.profile.hiddenColumnsProf["Knowledge"] then
            local spent, unspent, capacity = tonumber(expData.spent) or 0, tonumber(expData.unspent) or 0, tonumber(expData.maxK) or 0
            local baseColor = (spent == 0) and "|cff808080" or (capacity > 0 and (spent + unspent) >= capacity and "|cff00ff00" or "")
            local unspentStr = (unspent > 0) and string.format(" |cffffff00(%d)|r%s", unspent, baseColor) or ""
            self:AddCol(row, string.format("%s%d%s / %d|r", baseColor, spent, unspentStr, capacity), colWidths["Knowledge"], "CENTER")
        end

        -- Quests, Treasures, Concentration, DMF (standard AddCol logic)
        if not self.db.profile.hiddenColumnsProf["Treatise"] then
            local val = expData.hasTreatise and (expData.treatise and 1 or 0) or nil
            local lbl = self:AddCol(row, val and self:GetColorText(val, 1, "/1") or "-", colWidths["Treatise"], "CENTER")
            if val and expData.treatiseName ~= "" then
                lbl.frame:SetScript("OnEnter", function(f) GameTooltip:SetOwner(f, "ANCHOR_RIGHT"); GameTooltip:SetText("|cffffd100Weekly Treatise|r"); GameTooltip:AddLine(" "); GameTooltip:AddLine("|cffa335ee" .. expData.treatiseName .. "|r"); GameTooltip:Show() end)
                lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
        end

        if not self.db.profile.hiddenColumnsProf["Treasures"] then
            local lbl = self:AddCol(row, (expData.maxTreasures > 0) and self:GetColorText(expData.treasures, expData.maxTreasures, "/" .. expData.maxTreasures) or "-", colWidths["Treasures"], "CENTER")
            if expData.treasureDetails ~= "" then
                lbl.frame:SetScript("OnEnter", function(f) GameTooltip:SetOwner(f, "ANCHOR_RIGHT"); GameTooltip:SetText("|cffffd100Profession Treasures|r"); GameTooltip:AddLine(" "); GameTooltip:AddLine(expData.treasureDetails); GameTooltip:Show() end)
                lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
        end

        if not self.db.profile.hiddenColumnsProf["Weekly"] then
            local val = expData.hasWeekly and (expData.weekly and 1 or 0) or nil
            local lbl = self:AddCol(row, val and self:GetColorText(val, 1, "/1") or "-", colWidths["Weekly"], "CENTER")
            if val and expData.weeklyName ~= "" then
                lbl.frame:SetScript("OnEnter", function(f) GameTooltip:SetOwner(f, "ANCHOR_RIGHT"); GameTooltip:SetText("|cffffd100Weekly Profession Quest|r"); GameTooltip:AddLine(" "); GameTooltip:AddLine("|cffa335ee" .. expData.weeklyName .. "|r"); GameTooltip:Show() end)
                lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
        end

        if not self.db.profile.hiddenColumnsProf["Gathering"] then
            local lbl = self:AddCol(row, (expData.maxGathering > 0) and self:GetColorText(expData.gathering, expData.maxGathering, "/" .. expData.maxGathering) or "", colWidths["Gathering"], "CENTER")
            if expData.gatheringDetails ~= "" then
                lbl.frame:SetScript("OnEnter", function(f) GameTooltip:SetOwner(f, "ANCHOR_RIGHT"); GameTooltip:SetText("|cffffd100Weekly Gathering Progress|r"); GameTooltip:AddLine(" "); GameTooltip:AddLine(expData.gatheringDetails); GameTooltip:Show() end)
                lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
        end

        if not self.db.profile.hiddenColumnsProf["Concentration"] then
            local curProfConf = profConfig and profConfig[entry.expansionKey]
            if curProfConf and curProfConf.concentration and curProfConf.concentration.currencyId > 0 then
                local currentTime = time()
                local elapsed = currentTime - (entry.lastUpdate or currentTime)
                local estimated = math.min(1000, (expData.concentration or 0) + math.floor(elapsed / 360))
                local lbl = self:AddCol(row, self:GetColorText(estimated, 900, "/1000"), colWidths["Concentration"], "CENTER")
                lbl.frame:SetScript("OnEnter", function(frame)
                    local needed = 1000 - estimated
                    local timeToMaxStr = needed > 0 and string.format("%dh %dm", math.floor((needed * 360) / 3600), math.floor(((needed * 360) % 3600) / 60)) or "Full"
                    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT"); GameTooltip:SetText("Concentration Details", 1, 1, 1); GameTooltip:AddLine(" ")
                    GameTooltip:AddDoubleLine("Saved:", expData.concentration, 1, 1, 1, 1, 1, 1); GameTooltip:AddDoubleLine("Estimated:", estimated, 1, 1, 1, 1, 1, 1)
                    GameTooltip:AddDoubleLine("Time to Max:", timeToMaxStr, 1, 1, 1, 1, 1, 1); GameTooltip:AddDoubleLine("Last Saved:", date("%Y-%m-%d %H:%M:%S", entry.lastUpdate), 0.5, 0.5, 0.5, 0.5, 0.5, 0.5); GameTooltip:Show()
                end)
                lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
            else self:AddCol(row, "-", colWidths["Concentration"], "CENTER") end
        end

        if not self.db.profile.hiddenColumnsProf["DMF"] then
            if expData.hasDmf then
                if isDMF then self:AddCol(row, self:GetColorText(expData.dmf and 1 or 0, 1, "/1"), colWidths["DMF"], "CENTER")
                else local lbl = self:AddCol(row, "|cff808080Closed|r", colWidths["DMF"], "CENTER")
                    lbl.frame:SetScript("OnEnter", function(f) GameTooltip:SetOwner(f, "ANCHOR_RIGHT"); GameTooltip:SetText("|cffffd100Darkmoon Faire|r"); GameTooltip:AddLine(" "); GameTooltip:AddLine("The Darkmoon Faire is currently closed.", 1, 1, 1); GameTooltip:Show() end)
                    lbl.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
                end
            else self:AddCol(row, "-", colWidths["DMF"], "CENTER") end
        end
    end
    scroll:DoLayout()
end