addon.name      = 'csvconverter'
addon.author    = 'Shiyo'
addon.version   = '1.1'

require('common')
require('logmanager')
gLogManager:SetDirectory('CSVConverter')

local familySqlPath = [[C:\Server and Notepad Files\FFXI\Topaz\Moos Pserver\sql\mob_family_system.sql]]
local poolsSqlPath  = [[C:\Server and Notepad Files\FFXI\Topaz\Moos Pserver\sql\mob_pools.sql]]
local csvPath       = [[C:\Ashita 4\addons\csvconverter\mob_stats.csv]]

-- ==========================================================
-- Maps
-- ==========================================================

local gradeMap = {
    A = 1, B = 2, C = 3, D = 4, E = 5, F = 6
}

local jobMap = {
    WAR = 1, MNK = 2, WHM = 3, BLM = 4, RDM = 5,
    THF = 6, PLD = 7, DRK = 8, BST = 9, BRD = 10,
    RNG = 11, SAM = 12, NIN = 13, DRG = 14, SMN = 15,
    BLU = 16, COR = 17, PUP = 18, DNC = 19, SCH = 20,
    GEO = 21, RUN = 22
}

-- ==========================================================
-- Utility Functions
-- ==========================================================

local function normalize(name)
    name = name:gsub("%b()", "")
    name = name:lower()
    name = name:gsub("%s+", "")
    name = name:gsub("[^%w%-']", "")
    return name
end

-- Proper CSV splitter (handles quotes)
local function splitCSV(line)
    local t = {}
    local field = ""
    local inQuotes = false

    for i = 1, #line do
        local c = line:sub(i,i)

        if c == '"' then
            inQuotes = not inQuotes
        elseif c == ',' and not inQuotes then
            table.insert(t, field)
            field = ""
        else
            field = field .. c
        end
    end

    table.insert(t, field)
    return t
end

-- Proper SQL VALUES splitter (respects quotes)
local function splitSQLValues(str)
    local t = {}
    local field = ""
    local inQuotes = false

    for i = 1, #str do
        local c = str:sub(i,i)

        if c == "'" then
            inQuotes = not inQuotes
            field = field .. c
        elseif c == "," and not inQuotes then
            table.insert(t, field)
            field = ""
        else
            field = field .. c
        end
    end

    table.insert(t, field)
    return t
end

local function parseStat(value)
    if not value or value == "" then
        return nil
    end
    return gradeMap[value] or tonumber(value)
end

-- ==========================================================
-- Load Family IDs
-- ==========================================================

local function loadFamilyIds()
    local nameToId = {}
    local sqlFamilies = {}

    for line in io.lines(familySqlPath) do
        if line:find("INSERT INTO `mob_family_system`") then
            local valuesStr = line:match("VALUES%s*%((.*)%)")
            if valuesStr then
                local values = splitSQLValues(valuesStr)
                local familyId = tonumber(values[1])
                local familyName = values[2]:gsub("'", "")
                local key = normalize(familyName)

                nameToId[key] = familyId
                sqlFamilies[key] = familyName
            end
        end
    end

    return nameToId, sqlFamilies
end

-- ==========================================================
-- Load CSV
-- ==========================================================

local function loadCSV(familyNameToId)

    local statByName = {}
    local statById   = {}
    local csvFamilies = {}

    local file = io.open(csvPath, 'r')
    if not file then
        print('[csvconverter] Could not open CSV file.')
        return statByName, statById, csvFamilies
    end

    for line in file:lines() do
        local d = splitCSV(line)

        if d[1] and d[1] ~= "" and d[1] ~= "Family" then

            local key = normalize(d[1])
            csvFamilies[key] = d[1]

            local stats = {
                parseStat(d[2]),  -- STR
                parseStat(d[3]),  -- DEX
                parseStat(d[4]),  -- VIT
                parseStat(d[5]),  -- AGI
                parseStat(d[6]),  -- INT
                parseStat(d[7]),  -- MND
                parseStat(d[8]),  -- CHR

                parseStat(d[9]),  -- DEF
                parseStat(d[10]), -- EVA

                jobMap[d[12]],    -- mJob
                jobMap[d[13]],    -- sJob

                tonumber(d[11])   -- Delay
            }

            statByName[key] = stats

            if familyNameToId[key] then
                statById[familyNameToId[key]] = stats
            end
        end
    end

    file:close()
    return statByName, statById, csvFamilies
end

-- ==========================================================
-- Update mob_family_system.sql
-- ==========================================================

local function updateFamilySystem(statByName)
    local matchedFamilies = {}

    local lines = {}
    for line in io.lines(familySqlPath) do
        table.insert(lines, line)
    end

    for i, line in ipairs(lines) do
        if line:find("INSERT INTO `mob_family_system`") then

            local valuesStr = line:match("VALUES%s*%((.*)%)")
            if valuesStr then
                local values = splitSQLValues(valuesStr)
                local familyName = normalize(values[2]:gsub("'", ""))

                local stats = statByName[familyName]
                if stats then
                    matchedFamilies[familyName] = true

                    -- STR–CHR (9–15)
                    for x = 1, 7 do
                        if stats[x] then
                            values[8 + x] = stats[x]
                        end
                    end

                    -- DEF → column 17
                    if stats[8] then
                        values[17] = stats[8]
                    end

                    -- EVA → column 19
                    if stats[9] then
                        values[19] = stats[9]
                    end

                    lines[i] = "INSERT INTO `mob_family_system` VALUES (" ..
                        table.concat(values, ",") .. ");"
                end
            end
        end
    end

    local out = io.open(familySqlPath, 'w')
    for _, l in ipairs(lines) do
        out:write(l .. "\n")
    end
    out:close()

    return matchedFamilies
end

-- ==========================================================
-- Update mob_pools.sql
-- ==========================================================

local function updateMobPools(statById)

    local lines = {}
    for line in io.lines(poolsSqlPath) do
        table.insert(lines, line)
    end

    for i, line in ipairs(lines) do
        if line:find("INSERT INTO `mob_pools`") then

            local valuesStr = line:match("VALUES%s*%((.*)%)")
            if valuesStr then
                local values = splitSQLValues(valuesStr)
                local familyId = tonumber(values[4])

                local stats = statById[familyId]
                if stats then
                    if stats[10] then values[6] = stats[10] end -- mJob
                    if stats[11] then values[7] = stats[11] end -- sJob
                    if stats[12] then values[9] = stats[12] end -- Delay

                    lines[i] = "INSERT INTO `mob_pools` VALUES (" ..
                        table.concat(values, ",") .. ");"
                end
            end
        end
    end

    local out = io.open(poolsSqlPath, 'w')
    for _, l in ipairs(lines) do
        out:write(l .. "\n")
    end
    out:close()
end

-- ==========================================================
-- Convert
-- ==========================================================

local function convert()

    gLogManager:Log(LogStyle.Message, 'CSVConverter', 'Starting conversion...')

    local familyNameToId, sqlFamilies = loadFamilyIds()
    local statByName, statById, csvFamilies = loadCSV(familyNameToId)

    local matchedFamilies = updateFamilySystem(statByName)
    updateMobPools(statById)

    -- ==========================================
    -- Logging Missing Families
    -- ==========================================

    gLogManager:Log(LogStyle.Message, 'CSVConverter', '')
    gLogManager:Log(LogStyle.Message, 'CSVConverter', '=== CSV Families Not Found In SQL ===')
    gLogManager:Log(LogStyle.Message, 'CSVConverter', '')

    for key, raw in pairs(csvFamilies) do
        if not sqlFamilies[key] then
            gLogManager:Log(LogStyle.Message, 'CSVConverter', raw)
        end
    end

    gLogManager:Log(LogStyle.Message, 'CSVConverter', '')
    gLogManager:Log(LogStyle.Message, 'CSVConverter', '=== SQL Families Not Found In CSV ===')
    gLogManager:Log(LogStyle.Message, 'CSVConverter', '')

    for key, raw in pairs(sqlFamilies) do
        if not matchedFamilies[key] then
            gLogManager:Log(LogStyle.Message, 'CSVConverter', raw)
        end
    end

    gLogManager:Log(LogStyle.Message, 'CSVConverter', '')
    gLogManager:Log(LogStyle.Message, 'CSVConverter', 'Conversion complete.')
end

ashita.events.register('load', 'load_cb', function()
    convert()
end)