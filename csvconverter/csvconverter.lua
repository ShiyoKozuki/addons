addon.name      = 'csvconverter'
addon.author    = 'Shiyo'
addon.version   = '1.0'

require('common')
require('logmanager')
gLogManager:SetDirectory('CSVConverter')

local sqlPath = [[C:\Server and Notepad Files\FFXI\Topaz\Moos Pserver\sql\mob_family_system.sql]]
local csvPath = [[C:\Ashita 4\addons\csvconverter\mob_stats.csv]]

-- Columns to modify
local statIndexes = {
    STR = 9,
    DEX = 10,
    VIT = 11,
    AGI = 12,
    INT = 13,
    MND = 14,
    CHR = 15,
    DEF = 17,
    EVA = 19
}

local function splitCSV(line)
    local t = {}
    for v in string.gmatch(line, '([^,]+)') do
        v = v:gsub('^%s+', ''):gsub('%s+$', '')
        table.insert(t, v)
    end
    return t
end

local function splitSQLValues(str)
    local t = {}
    for v in string.gmatch(str, "([^,]+)") do
        table.insert(t, v)
    end
    return t
end

local gradeMap = {
    A = 1,
    B = 2,
    C = 3,
    D = 4,
    E = 5,
    F = 6
}

local function normalize(name)
    -- Remove anything in parentheses
    name = name:gsub("%b()", "")

    -- Lowercase
    name = name:lower()

    -- Remove spaces only
    name = name:gsub("%s+", "")

    -- Remove everything except letters, numbers, hyphen, apostrophe
    name = name:gsub("[^%w%-']", "")

    return name
end

local function convert()

    local statMap = {}
    local csvFamilies = {}
    local matchedFamilies = {}
    local sqlFamilies = {}

    local csvFile = io.open(csvPath, 'r')
    if not csvFile then
        print('[csvconverter] Could not open CSV.')
        return
    end

    for line in csvFile:lines() do
        local d = splitCSV(line)

        if d[1] and d[1] ~= "" and d[1] ~= "Mob Family" and not d[1]:find("PLEASE") then

            local familyRaw = d[1]
            local family = normalize(familyRaw)

            csvFamilies[family] = familyRaw

            statMap[family] = {
                gradeMap[d[2]] or tonumber(d[2]) or 3,
                gradeMap[d[3]] or tonumber(d[3]) or 3,
                gradeMap[d[4]] or tonumber(d[4]) or 3,
                gradeMap[d[5]] or tonumber(d[5]) or 3,
                gradeMap[d[6]] or tonumber(d[6]) or 3,
                gradeMap[d[7]] or tonumber(d[7]) or 3,
                gradeMap[d[8]] or tonumber(d[8]) or 3,
                tonumber(d[9])  or 3,
                tonumber(d[10]) or 3
            }
        end
    end

    csvFile:close()

    local lines = {}
    for line in io.lines(sqlPath) do
        table.insert(lines, line)
    end

    for i, line in ipairs(lines) do
        if line:find("INSERT INTO `mob_family_system`") then

            -- Extract and strip comment first
            local comment = line:match("%-%-.*") or ""
            local cleanLine = line:gsub("%-%-.*$", "")

            -- Now safely extract values
            local valuesStr = cleanLine:match("VALUES%s*%((.*)%)")

            if valuesStr then
                local values = splitSQLValues(valuesStr)

                local familyRaw = values[2]:gsub("'", "")
                local key = normalize(familyRaw)

                sqlFamilies[key] = familyRaw

                local stats = statMap[key]

                if stats then
                    matchedFamilies[key] = true

                    values[9]  = stats[1]
                    values[10] = stats[2]
                    values[11] = stats[3]
                    values[12] = stats[4]
                    values[13] = stats[5]
                    values[14] = stats[6]
                    values[15] = stats[7]
                    values[17] = stats[8]
                    values[19] = stats[9]

                    local newValues = table.concat(values, ",")
                    lines[i] = "INSERT INTO `mob_family_system` VALUES (" ..
                        newValues .. "); " .. comment
                end
            end
        end
    end

    -- Write updated SQL
    local out = io.open(sqlPath, 'w')
    for _, l in ipairs(lines) do
        out:write(l .. "\n")
    end
    out:close()

    -- Generate log using logmanager directory
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
    gLogManager:Log(LogStyle.Message, 'CSVConverter', 'CSV conversion complete.')
end

ashita.events.register('load', 'load_cb', function()
    convert()
end)