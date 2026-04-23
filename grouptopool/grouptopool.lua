addon.name      = 'grouptopool'
addon.author    = 'Shiyo'
addon.version   = '1.0'
addon.desc      = 'Converts a file of mob_groups to mob_pools.'
addon.link      = ''
-- Make sure to edit skillListId!
require('common')

local groupsFile   = [[C:\Ashita 4\addons\grouptopool\mob_groups_subset.sql]]
local poolsFile    = [[C:\Server and Notepad Files\FFXI\Topaz\Moos Pserver\sql\mob_pools.sql]]

local mobSkillId = 999

local function runSqlOutput(mainJob, subJob)
    mainJob = tonumber(mainJob)
    subJob = tonumber(subJob)

    if not mainJob or not subJob then
        print("ERROR: Invalid job IDs!")
        return
    end

    -- ----------------------------------------
    -- Collect names from mob_groups_subset
    -- ----------------------------------------
    local names = {}

    for line in io.lines(groupsFile) do
        local name = line:match("VALUES%s*%([^,]+,[^,]+,[^,]+,'([^']+)'")
        if name then
            names[name] = true
        end
    end

    -- ----------------------------------------
    -- Read and modify mob_pools
    -- ----------------------------------------
    local output = {}

    for line in io.lines(poolsFile) do
        local name = line:match("VALUES%s*%(%d+,'([^']+)'")

        if name and names[name] then
            local valuesStr = line:match("VALUES%s*%((.+)%)")
            local values = {}

            for v in valuesStr:gmatch("([^,]+)") do
                v = v:gsub("^%s+", ""):gsub("%s+$", "")
                table.insert(values, v)
            end

            -- Replace mJob / sJob (columns 6 & 7)
            values[6] = tostring(mainJob)
            values[7] = tostring(subJob)

            local newLine = "INSERT INTO `mob_pools` VALUES (" .. table.concat(values, ",") .. ");"

            print(string.format("Updated: %s -> %d/%d", name, mainJob, subJob))

            table.insert(output, newLine)
        else
            table.insert(output, line)
        end
    end

    -- ----------------------------------------
    -- Write output
    -- ----------------------------------------
    local f = io.open(poolsFile, "w")
    if not f then
        print("ERROR: Failed to open output file!")
        return
    end

    for _, l in ipairs(output) do
        f:write(l .. "\n")
    end

    f:close()

    print("Done! mob_pools updated.")
end

ashita.events.register('load', 'grouptopoolLoad', function()
end)

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if #args == 0 or (string.lower(args[1]) ~= '/grouptopool') then
        return;
    end
    e.blocked = true;

    if (args[2] == 'run') and (#args >= 4) then
        runSqlOutput(args[3], args[4])
    end
end)
