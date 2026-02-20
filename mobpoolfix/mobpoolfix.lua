addon.name      = 'mobpoolfix'
addon.author    = 'Shiyo'
addon.version   = '1.0'
addon.desc      = 'Safely fixes mob_pools family mismatches.'
addon.link      = ''

require('common')

local dbPath = [[C:\Server and Notepad Files\FFXI\Topaz\Moos Pserver\sql\mob_pools.sql]]

-- oldFamily, mJob, sJob, newFamily
local rules = {
    {110, 5, 5, 646},
    {203, 4, 6, 647},
    {227, 4, 4, 648},
    {56,  1, 5, 649},
    {258, 4, 5, 650},
    {70,  1, 5, 651},
}

local function processFile()

    local lines = {}
    for line in io.lines(dbPath) do
        table.insert(lines, line)
    end

    local updated = 0

    for i, line in ipairs(lines) do
        if line:find("^INSERT INTO `mob_pools`") then

            -- Capture prefix, values block, and suffix
            local prefix, valuesStr, suffix =
                line:match("^(INSERT INTO `mob_pools` VALUES %()(.*)(%);.*)$")

            if valuesStr then

                -- Extract just first 15 columns safely
                local columns = {}
                local current = ""
                local inString = false

                for c in valuesStr:gmatch(".") do
                    if c == "'" then
                        inString = not inString
                        current = current .. c
                    elseif c == "," and not inString then
                        table.insert(columns, current)
                        current = ""
                    else
                        current = current .. c
                    end
                end
                table.insert(columns, current)

                if #columns >= 15 then

                    local familyid = tonumber(columns[4])
                    local mJob     = tonumber(columns[6])
                    local sJob     = tonumber(columns[7])
                    local mobType  = tonumber(columns[15])

                    if mobType == 0 then
                        for _, r in ipairs(rules) do
                            if familyid == r[1] and
                               mJob == r[2] and
                               sJob == r[3] then

                                columns[4] = tostring(r[4])
                                updated = updated + 1
                                break
                            end
                        end
                    end

                    -- Reassemble EXACT same structure
                    lines[i] = prefix .. table.concat(columns, ",") .. suffix
                end
            end
        end
    end

    -- Backup once
    os.rename(dbPath, dbPath .. ".backup")

    local out = io.open(dbPath, 'w')
    for _, l in ipairs(lines) do
        out:write(l .. "\n")
    end
    out:close()

    print(string.format('[mobpoolfix] Updated %d mob pools safely.', updated))
end

ashita.events.register('load', 'mobpoolfix_load', function()
    processFile()
end)