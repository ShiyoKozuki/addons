addon.name      = 'grouptoskill'
addon.author    = 'Shiyo'
addon.version   = '1.0'
addon.desc      = 'Converts a file of mob_groups to mob_skill_lists.'
addon.link      = ''
-- Make sure to edit skillListId!
require('common')

local skillListId = 1216

local inputFile = [[C:\Ashita 4\addons\grouptoskill\mob_groups_subset.sql]]
local outputFile = [[C:\Server and Notepad Files\FFXI\Topaz\Moos Pserver\sql\mob_skill_lists.sql]]

local mobSkillId = 999

local function runSqlOutput()
    local output = {}
    local currentSkillListId = skillListId

    for line in io.lines(inputFile) do
        local name = line:match("VALUES%s*%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*,%s*'([^']+)'")
        if name then
            local newLine = string.format(
                "INSERT INTO `mob_skill_lists` VALUES ('%s',%d,%d);",
                name,
                currentSkillListId,
                mobSkillId
            )

            print(string.format("Adding: %s -> skillListId %d", name, currentSkillListId))

            table.insert(output, newLine)

            -- increment to next skill list Id
            currentSkillListId = currentSkillListId + 1
        end
    end

    -- ----------------------------------------
    -- Write output
    -- ----------------------------------------
    local f = io.open(outputFile, "a")
    if not f then
        print("ERROR: Failed to open output file!")
        return
    end
    for _, line in ipairs(output) do
        f:write(line .. "\n\n")
    end
    f:close()

    print("Done! Output written to: " .. outputFile)
end

ashita.events.register('load', 'spellToPoolLoad', function()
end)

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if #args == 0 or (string.lower(args[1]) ~= '/grouptoskill') then
        return;
    end
    e.blocked = true;

    if (args[2] == 'run') and (#args > 1) then
        runSqlOutput()
    end
end)
