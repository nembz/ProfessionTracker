local ProfessionTracker = LibStub("AceAddon-3.0"):GetAddon("ProfessionTracker")

-- Session cache for trait node IDs to avoid expensive re-scanning of tree structures
local traitNodeCache = {} -- skillLineID -> {nodeID, ...} (stores node IDs for a given skill line)

-- Helper to retrieve Knowledge points using hardcoded SkillLineIDs from constants
-- Now takes an expansionKey argument to retrieve expansion-specific data
local function GetKnowledge(profName, expansionKey) -- Main function to get all knowledge-related data
    local profConfig = ProfessionTracker.ProfessionData[profName]
    if not profConfig then return {} end

    local config = profConfig[expansionKey]
    local res = {
        spent = 0, unspent = 0, moxie = 0, totalEarned = 0, capacity = 0,
        treatiseCompleted = false, hasTreatise = false, treatiseName = "",
        treasuresFound = 0, maxTreasures = 0, treasureStr = "",
        concentration = 0,
        dmfCompleted = false, hasDmf = false,
        weeklyCompleted = false, hasWeekly = false, weeklyName = "",
        gatheringFound = 0, maxGathering = 0, gatheringStr = ""
    }

    if not config or not config.skillLineID then return res end -- Exit early if no config for this expansion
    local skillLineID = config.skillLineID -- Get the skillLineID once

    local function _CheckTreatise(config, res)
    if config.treatise and config.treatise.questId then
        res.hasTreatise = true
        res.treatiseCompleted = C_QuestLog.IsQuestFlaggedCompleted(config.treatise.questId)
        res.treatiseName = config.treatise.itemId and C_Item.GetItemNameByID(config.treatise.itemId) or ""
    end
    end
    _CheckTreatise(config, res)

    local function _CheckTreasures(config, res)
    local treasureDetails = {}
    res.maxTreasures = (config.treasureMapQuests and #config.treasureMapQuests) or 0
    if config.treasureMapQuests then
        for i, entry in ipairs(config.treasureMapQuests) do
            local qID, title
            if type(entry) == "table" then
                qID = entry.questId
                title = entry.name
            else
                qID = entry
            end

            local completed = C_QuestLog.IsQuestFlaggedCompleted(qID)
            if not title or title == "" then
                title = C_QuestLog.GetTitleForQuestID(qID) or ("Treasure #" .. i)
            end

            local status = completed and "|cff00ff00[Done]|r" or "|cffff0000[Missing]|r"
            table.insert(treasureDetails, string.format("%s |cffa335ee%s|r", status, title))
            if completed then
                res.treasuresFound = res.treasuresFound + 1
            end
        end
    end
    res.treasureStr = table.concat(treasureDetails, "\n") -- Store formatted treasure details
    end
    _CheckTreasures(config, res)

    local function _CheckDarkmoonFaire(config, res)
    if config.darkmoon and config.darkmoon.questId then
        res.hasDmf = true
        res.dmfCompleted = C_QuestLog.IsQuestFlaggedCompleted(config.darkmoon.questId)
    end
    end
    _CheckDarkmoonFaire(config, res)

    local function _CheckConcentration(config, res)
    if config.concentration and config.concentration.currencyId and config.concentration.currencyId > 0 then
        local currInfo = C_CurrencyInfo.GetCurrencyInfo(config.concentration.currencyId)
        if currInfo then
            res.concentration = currInfo.quantity or 0
        end
    end
    end
    _CheckConcentration(config, res)

    local function _GetUnspentKnowledgeAndMoxie(skillLineID, config, res)
    local profCurrencyInfo = C_ProfSpecs.GetCurrencyInfoForSkillLine(skillLineID)
    if profCurrencyInfo and profCurrencyInfo.numAvailable then
        res.unspent = profCurrencyInfo.numAvailable
    elseif config.knowledgePointsID and config.knowledgePointsID > 0 then
        local kInfo = C_CurrencyInfo.GetCurrencyInfo(config.knowledgePointsID)
        res.unspent = (kInfo and kInfo.quantity) or 0
    end

    if config.moxieId and config.moxieId > 0 then
        local moxieInfo = C_CurrencyInfo.GetCurrencyInfo(config.moxieId)
        res.moxie = (moxieInfo and moxieInfo.quantity) or 0
    end
    end
    _GetUnspentKnowledgeAndMoxie(skillLineID, config, res)

    local function _GetSpentKnowledge(skillLineID, configID, res)
    -- Populate node cache if it doesn't exist for this profession
    if configID and configID > 0 then
        -- Populate node cache if it doesn't exist for this profession
        if not traitNodeCache[skillLineID] then
            traitNodeCache[skillLineID] = {}
            local configInfo = C_Traits.GetConfigInfo(configID)
            if configInfo and configInfo.treeIDs then
                for _, treeID in ipairs(configInfo.treeIDs) do
                    local nodes = C_Traits.GetTreeNodes(treeID)
                    if nodes then
                        for _, nodeID in ipairs(nodes) do
                            table.insert(traitNodeCache[skillLineID], nodeID)
                        end
                    end
                end
            end
        end

        -- Scan cached nodes
        for _, nodeID in ipairs(traitNodeCache[skillLineID]) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            if nodeInfo and nodeInfo.maxRanks and nodeInfo.maxRanks > 1 then
                local nodeSpent = math.max(0, (nodeInfo.currentRank or 1) - 1)
                local nodeMax = (nodeInfo.maxRanks or 1) - 1
                if nodeMax > 0 then
                    res.spent = res.spent + nodeSpent
                    res.capacity = res.capacity + nodeMax
                end
            end
        end
    end
    end
    _GetSpentKnowledge(skillLineID, C_ProfSpecs.GetConfigIDForSkillLine(skillLineID), res)

    local function _CheckWeeklyQuest(config, res)
    res.weeklyName = config.weekly and config.weekly.name or ""
    if config.weekly and config.weekly.questId then
        res.hasWeekly = true
        if type(config.weekly.questId) == "table" then
            for _, qID in ipairs(config.weekly.questId) do
                -- Only mark as completed if at least one quest in the table is done
                if C_QuestLog.IsQuestFlaggedCompleted(qID) then
                    res.weeklyCompleted = true
                    break
                end
            end
        else
            res.weeklyCompleted = C_QuestLog.IsQuestFlaggedCompleted(config.weekly.questId)
        end
    end
    end
    _CheckWeeklyQuest(config, res)

    local function _CheckGatheringProgress(config, res)
    local gatheringDetails = {}
    res.maxGathering = (config.gathering and config.gathering.questId and #config.gathering.questId) or 0
    if config.gathering and config.gathering.questId then
        for i, qID in ipairs(config.gathering.questId) do
            local completed = C_QuestLog.IsQuestFlaggedCompleted(qID)
            local title = C_QuestLog.GetTitleForQuestID(qID) or ("Item #" .. i)
            local status = completed and "|cff00ff00[Done]|r" or "|cffff0000[Missing]|r"
            table.insert(gatheringDetails, string.format("%s |cffa335ee%s|r", status, title))
            if completed then
                res.gatheringFound = res.gatheringFound + 1
            end
        end
    end
    res.gatheringStr = table.concat(gatheringDetails, "\n")
    _CheckGatheringProgress(config, res)
    end
    res.totalEarned = res.spent + res.unspent
    return res
end

-- Updated to handle expansion specific tools/accessories
local function GetEquipmentStatus(profName, expansionKey)
    local res = { tool = 0, acc = 0, toolName = "", equippedAccIDs = {} }
    local profConfig = ProfessionTracker.ProfessionData[profName]
    if not profConfig then return res end

    local config = profConfig[expansionKey]
    if not config then return res end

    -- Helper to get the most reliable Base Item ID from a slot
    local function GetBaseID(slot)
        local itemID = GetInventoryItemID("player", slot)
        if not itemID or itemID == 0 then
            local link = GetInventoryItemLink("player", slot)
            itemID = link and link:match("item:(%d+)")
        end
        return tonumber(itemID) or 0
    end

    -- Check all profession tool slots (20 and 23)
    if config.epicTool and config.epicTool.id then
        for _, slotID in ipairs({20, 23}) do
            if GetBaseID(slotID) == config.epicTool.id then
                res.tool = 1
                res.toolName = config.epicTool.name
                break
            end
        end
    end

    -- Check all profession accessory slots (21, 22, 24, 25)
    if config.epicAccessories and #config.epicAccessories > 0 then
        local accessoryMap = {}
        for _, acc in ipairs(config.epicAccessories) do
            local id = tonumber(acc.id)
            accessoryMap[id] = true
        end

        for _, slotID in ipairs({21, 22, 24, 25}) do
            local itemID = GetBaseID(slotID)
            if itemID > 0 and accessoryMap[itemID] then
                res.acc = res.acc + 1
                table.insert(res.equippedAccIDs, itemID)
            end
        end
    end
    return res
end

function ProfessionTracker:UpdatePlayerData()
    if not self.db.profile.characters then
        self.db.profile.characters = {}
    end

    local _, classFileName = UnitClass("player")
    local name = UnitName("player")
    local realm = GetRealmName()
    local charKey = name .. "-" .. realm
    
    local shardInfo = C_CurrencyInfo.GetCurrencyInfo(3376) -- Shard of Dundun
    local abundanceInfo = C_CurrencyInfo.GetCurrencyInfo(3377) -- Unalloyed Abundance
    
    local shards = shardInfo and shardInfo.quantity or 0
    local weeklyShards = shardInfo and shardInfo.quantityEarnedThisWeek or 0
    local abundance = abundanceInfo and abundanceInfo.quantity or 0

    -- Scan Primary Professions
    local profIndices = { GetProfessions() }
    local characterData = {
        name = name,
        class = classFileName,
        realm = realm,
        shards = shards,
        weeklyShards = weeklyShards,
        abundance = abundance,
        vitality = GetItemCount(245345),
        lastUpdate = time(),
        professions = {} -- New structure for multi-expansion storage
    }

    for i = 1, 2 do
        local index = profIndices[i]
        if index then
            local pName, _, rank, max = GetProfessionInfo(index)
            characterData.professions[pName] = {}

            for expKey, expName in pairs(ProfessionTracker.Expansions) do
                local k = GetKnowledge(pName, expKey)
                local eq = GetEquipmentStatus(pName, expKey)

                characterData.professions[pName][expKey] = {
                    spent = k.spent, unspent = k.unspent, moxie = k.moxie, total = k.totalEarned, maxK = k.capacity,
                    treatise = k.treatiseCompleted, hasTreatise = k.hasTreatise, treatiseName = k.treatiseName,
                    treasures = k.treasuresFound, treasureDetails = k.treasureStr, maxTreasures = k.maxTreasures,
                    concentration = k.concentration, dmf = k.dmfCompleted, hasDmf = k.hasDmf,
                    weekly = k.weeklyCompleted, hasWeekly = k.hasWeekly, weeklyName = k.weeklyName,
                    gathering = k.gatheringFound, maxGathering = k.maxGathering, gatheringDetails = k.gatheringStr,
                    tool = eq.tool, acc = eq.acc, toolName = eq.toolName, equippedAccIDs = eq.equippedAccIDs,
                    rank = rank, max = max
                }
            end
        else
            for expKey, _ in pairs(ProfessionTracker.Expansions) do
                characterData.professions["None" .. i] = characterData.professions["None" .. i] or {}
                characterData.professions["None" .. i][expKey] = { name = "None", rank = 0, max = 0 }
            end
        end
    end

    self.db.profile.characters[charKey] = characterData
end