addon.name      = 'spellToPool'
addon.author    = 'Shiyo'
addon.version   = '1.0'
addon.desc      = 'Converts mob_spell_list entries to mob_pools.'
addon.link      = ''
-- Make sure to edit listIdStart and listIdEnd or it'll run on the entire mob_pools file!
require('common')

local poolSql = [[C:\Server and Notepad Files\FFXI\Topaz\Moos Pserver\sql\mob_pools.sql]]
local spellListSql = [[C:\Server and Notepad Files\FFXI\Topaz\Moos Pserver\sql\mob_spell_lists.sql]]
local listIdStart = 1028
local listIdEnd = 1068

local function getColumnIndex(sqlFile, columnName)
    local inTable = false
    local index = 0

    for line in io.lines(sqlFile) do
        if line:find("CREATE TABLE `mob_pools`") then
            inTable = true
        elseif inTable then
            local col = line:match("^%s*`([^`]+)`")

            if col then
                index = index + 1
                if col == columnName then
                    return index
                end
            end

            -- stop at end of table
            if line:find("^%)") then
                break
            end
        end
    end

    return nil
end

local function runSqlOutput()
    local spellMap = {}

    local SPELLLIST_INDEX = getColumnIndex(poolSql, "spellList")

    if not SPELLLIST_INDEX then
        print("ERROR: Could not find spellList column!")
        return
    end

    -- ----------------------------------------
    -- Step 1: Read mob_spell_lists.sql
    -- ----------------------------------------
    for line in io.lines(spellListSql) do
        local name, id = line:match("VALUES%s*%(%s*'([^']+)'%s*,%s*(%d+)")
        if name and id then
            id = tonumber(id)

            if id >= listIdStart and id <= listIdEnd then
                spellMap[name] = id
                print(string.format("Updating: [%s] -> [%d]", name, id))
            end
        end
    end

    -- ----------------------------------------
    -- Step 2: Process mob_pools.sql
    -- ----------------------------------------
    local output = {}

    for line in io.lines(poolSql) do
        if line:find("INSERT INTO `mob_pools` VALUES") then

            -- extract values inside (...)
            local values = line:match("VALUES%s*%((.*)%)")
            if values then
                local parts = {}

                -- split on commas (simple version)
                for part in values:gmatch("([^,]+)") do
                    table.insert(parts, part)
                end

                -- name is 2nd column
                local name = parts[2] and parts[2]:match("'([^']+)'")

                if name and spellMap[name] then
                    local spellId = spellMap[name]

                    parts[SPELLLIST_INDEX] = tostring(spellId)

                    -- rebuild line
                    line = "INSERT INTO `mob_pools` VALUES (" .. table.concat(parts, ",") .. ");"
                end
            end
        end

        table.insert(output, line)
    end

    -- ----------------------------------------
    -- Step 3: Write output
    -- ----------------------------------------
    local f = io.open(poolSql, "w")
    if not f then
        print("ERROR: Failed to open output file!")
        return
    end
    for _, line in ipairs(output) do
        f:write(line .. "\n")
    end
    f:close()

    print("Done! Output written to: " .. poolSql)
end

ashita.events.register('load', 'spellToPoolLoad', function()
end)

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if #args == 0 or (string.lower(args[1]) ~= '/spelltopool') then
        return;
    end
    e.blocked = true;

    if (args[2] == 'run') and (#args > 1) then
        runSqlOutput()
    end
end)
