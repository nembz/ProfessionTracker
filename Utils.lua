local ProfessionTracker = LibStub("AceAddon-3.0"):GetAddon("ProfessionTracker")

function ProfessionTracker:GetColorText(value, threshold, suffix)
    local text = tostring(value) .. (suffix or "")
    if value == 0 then
        return "|cff808080" .. text .. "|r" -- Gray when zero
    elseif value >= threshold then
        return "|cff00ff00" .. text .. "|r" -- Green when complete/high
    else
        return text -- Default (white) when between 0 and threshold
    end
end

function ProfessionTracker:GetClassColoredName(name, className)
    local color = RAID_CLASS_COLORS[className] or {r=1, g=1, b=1}
    return string.format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, name)
end

function ProfessionTracker:IsDMFActive()
    local t = date("*t")
    -- Determine the day of the month for the first Sunday
    -- weekday: 1 is Sunday, 7 is Saturday
    local firstOfMonth = date("*t", time({year=t.year, month=t.month, day=1}))
    local distToSunday = 1 - firstOfMonth.wday
    if distToSunday < 0 then distToSunday = distToSunday + 7 end
    local firstSunday = 1 + distToSunday

    local startTime = time({year=t.year, month=t.month, day=firstSunday, hour=0, min=0})
    local endTime = startTime + (7 * 24 * 3600) -- Lasts exactly 7 days
    local now = time()
    return now >= startTime and now < endTime
end

function ProfessionTracker:AddCol(container, text, width, align)
    local AceGUI = LibStub("AceGUI-3.0")
    local lbl = AceGUI:Create("Label")
    lbl.frame:SetScript("OnEnter", nil)
    lbl.frame:SetScript("OnLeave", nil)
    lbl:SetText(text)
    lbl:SetWidth(width)
    if align then
        lbl:SetJustifyH(align)
    end
    if lbl.label then
        lbl.label:SetWordWrap(false)
    end
    local fontPath, _, fontFlags = GameFontNormal:GetFont()
    lbl:SetFont(fontPath, 11, fontFlags)
    container:AddChild(lbl)
    return lbl
end