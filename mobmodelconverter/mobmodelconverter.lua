addon.name      = 'MobModelConverter'
addon.author    = 'Shiyo'
addon.version   = '1.0'
addon.desc      = 'Converts mob model from mob_pools to GetLookHair'
addon.link      = ''

require('common')
require ('shiyolibs')
local familyFile = [[C:\Server and Notepad Files\FFXI\Topaz\Moos Pserver\sql\mob_family_system.sql]]
local poolsFile  = [[C:\Server and Notepad Files\FFXI\Topaz\Moos Pserver\sql\mob_pools.sql]]

local outputFile = [[C:\Ashita 4\addons\libs\MobModels.lua]]

local mobModelLookup = {}

local function BuildMobModelLookup(mobModels)
    mobModelLookup = {}

    for ecosystem, mobs in pairs(mobModels) do
        for _, mob in ipairs(mobs) do
            mobModelLookup[mob.modelId] = mobModelLookup[mob.modelId] or {}

            mobModelLookup[mob.modelId][#mobModelLookup[mob.modelId] + 1] = {
                name = mob.name,
                ecosystem = ecosystem,
            }
        end
    end
end

-------------------------------------------------------------------------------
-- Split SQL values
-------------------------------------------------------------------------------

local function SplitSqlValues(input)
    local values = {}
    local current = {}
    local inString = false
    local escaped = false

    for i = 1, #input do
        local char = input:sub(i, i)

        if escaped then
            current[#current + 1] = char
            escaped = false

        elseif char == '\\' and inString then
            current[#current + 1] = char
            escaped = true

        elseif char == "'" then
            inString = not inString
            current[#current + 1] = char

        elseif char == ',' and not inString then
            values[#values + 1] = table.concat(current):match('^%s*(.-)%s*$')
            current = {}

        else
            current[#current + 1] = char
        end
    end

    if #current > 0 then
        values[#values + 1] = table.concat(current):match('^%s*(.-)%s*$')
    end

    -- Remove SQL string quotes
    for i, value in ipairs(values) do
        if value:sub(1, 1) == "'" and value:sub(-1) == "'" then
            value = value:sub(2, -2)
            value = value:gsub("\\'", "'")
            value = value:gsub("\\\\", "\\")
            values[i] = value
        end
    end

    return values
end

-------------------------------------------------------------------------------
-- Extract INSERT values
-------------------------------------------------------------------------------

local function GetInsertValues(line)
    local values = line:match('VALUES%s*%((.*)%)')

    if not values then
        return nil
    end

    return SplitSqlValues(values)
end

-------------------------------------------------------------------------------
-- Convert raw model ID
-------------------------------------------------------------------------------

local function ConvertRawModelId(rawModelId)
    if not rawModelId then
        return nil
    end

    -- Remove optional 0x prefix if present.
    rawModelId = rawModelId:gsub('^0[xX]', '')

    local lowByte = rawModelId:sub(5, 6)
    local highByte = rawModelId:sub(7, 8)

    if #lowByte ~= 2 or #highByte ~= 2 then
        return nil
    end

    local low = tonumber(lowByte, 16)
    local high = tonumber(highByte, 16)

    if not low or not high then
        return nil
    end

    return low + (high * 256)
end

-------------------------------------------------------------------------------
-- Generate ecosystem database
-------------------------------------------------------------------------------

local function BuildMobModelDatabase()

    print('[MobModels] Loading mob families...')

    local families = {}

    for line in io.lines(familyFile) do
        local values = GetInsertValues(line)

        if values then
            local familyId = tonumber(values[1])
            local ecosystem = values[4]

            if familyId and ecosystem then
                families[familyId] = ecosystem
            end
        end
    end

    print(('[MobModels] Loaded %u families.'):format(
        (function()
            local count = 0
            for _ in pairs(families) do count = count + 1 end
            return count
        end)()
    ))

    ---------------------------------------------------------------------------
    -- Load mob pools
    ---------------------------------------------------------------------------

    print('[MobModels] Loading mob pools...')

    local mobModels = {}
    local mobCount = 0

    for line in io.lines(poolsFile) do
        local values = GetInsertValues(line)

        if values then
            local mobName = values[2]
            local familyId = tonumber(values[4])
            local rawModelId = values[5]

            local ecosystem = familyId and families[familyId]

            if mobName and ecosystem and rawModelId then
                local modelId = ConvertRawModelId(rawModelId)

                if modelId then
                    mobModels[ecosystem] = mobModels[ecosystem] or {}

                    mobModels[ecosystem][#mobModels[ecosystem] + 1] = {
                        name = mobName,
                        modelId = modelId,
                    }

                    mobCount = mobCount + 1
                end
            end
        end
    end

    print(('[MobModels] Loaded %u mobs.'):format(mobCount))

    ---------------------------------------------------------------------------
    -- Sort output
    ---------------------------------------------------------------------------

    local ecosystems = {}

    for ecosystem in pairs(mobModels) do
        ecosystems[#ecosystems + 1] = ecosystem
    end

    table.sort(ecosystems)

    for _, ecosystem in ipairs(ecosystems) do
        table.sort(mobModels[ecosystem], function(a, b)
            return a.name < b.name
        end)
    end

    ---------------------------------------------------------------------------
    -- Write Lua file
    ---------------------------------------------------------------------------

    local file = io.open(outputFile, 'w')

    if not file then
        print('[MobModels] ERROR: Could not open output file!')
        return
    end

    file:write('return\nT{\n')

    -- Collect model IDs
    local modelIds = {}

    for ecosystem, mobs in pairs(mobModels) do
        for _, mob in ipairs(mobs) do
            modelIds[mob.modelId] = ecosystem
        end
    end

    -- Sort model IDs
    local sortedIds = {}

    for modelId in pairs(modelIds) do
        sortedIds[#sortedIds + 1] = modelId
    end

    table.sort(sortedIds)

    -- Write output
    for _, modelId in ipairs(sortedIds) do
        file:write(('    [%u] = %q,\n'):format(
            modelId,
            modelIds[modelId]
        ))
    end

    file:write('};\n')

    file:close()

    print('[MobModels] Database generated successfully!')
    BuildMobModelLookup(mobModels)
end

local function GetMobEcosystem(rawModelId)
    if not rawModelId or #rawModelId < 10 then
        return nil
    end

    local lowByte = string.sub(rawModelId, 7, 8)
    local highByte = string.sub(rawModelId, 9, 10)

    local low = tonumber(lowByte, 16)
    local high = tonumber(highByte, 16)

    if not low or not high then
        return nil
    end

    local modelId = low + (high * 256)

    return mobModelLookup[modelId]
end

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if #args == 0 or (string.lower(args[1]) ~= '/mobmodelconverter') then
        return;
    end
    e.blocked = true;

    if #args < 2 then
        print('[MobModelConverter] Usage: /mobmodelconverter run')
        return
    end

    if string.lower(args[2]) == 'run' then
        BuildMobModelDatabase()
    end

    if string.lower(args[2]) == 'getmodel' then
        local myTarget = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(AshitaCore:GetMemoryManager():GetTarget():GetIsSubTargetActive())
        print(GetModelID(myTarget))
    end

    if string.lower(args[2]) == 'geteco' then
        local myTarget = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(AshitaCore:GetMemoryManager():GetTarget():GetIsSubTargetActive())
        if IsMonster(myTarget) then
            local modelId = GetModelID(myTarget)
            print(GetMobEcoSystem(modelId))
        end
    end

end)
