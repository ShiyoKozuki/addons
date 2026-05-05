addon.name      = 'Runner'
addon.author    = 'Thorny and Shiyo'
addon.version   = '1.0'
addon.desc      = 'Adds positions to a lua table that can be put onto clipboard'
addon.link      = ''
require('common')
local chat = require('chat')
local buffer = T{};

local function AddPoint(min, max, chance)
    local myIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    if not myIndex then return end

    local entMgr = AshitaCore:GetMemoryManager():GetEntity();

    local point = T{
        X = entMgr:GetLocalPositionX(myIndex),
        Y = entMgr:GetLocalPositionZ(myIndex),
        Z = entMgr:GetLocalPositionY(myIndex),
    };

    min = tonumber(min)
    max = tonumber(max)
    chance = tonumber(chance)

    if min and max then
        point.wait = { min, max }
        if chance then
            point.wait.chance = chance
        end
    end

    buffer:append(point)

    if min and max then
        print(chat.header("Runner") ..
            chat.message(string.format("Point added with wait. [X:%.2f, Y:%.2f] Z:%.2f Wait: %d-%d%s", point.X, point.Y, point.Z, min, max, chance and string.format(", Chance: %d%%", chance) or "")))
    else
        print(chat.header("Runner") ..
            chat.message(string.format("Point added. [X:%.2f, Y:%.2f] Z:%.2f", point.X, point.Y, point.Z)))
    end
end

local function ClearPoints()
    buffer = T{};
    print(chat.header("Runner") .. chat.message("Cleared points."));
end

local function ClipLua()
    local output = T{};
    output:append("{");

    for _, entry in ipairs(buffer) do
        if entry.wait then
            if entry.wait.chance then
                output:append(string.format(
                    "    { X=%.2f, Y=%.2f, Z=%.2f, wait = { %d, %d, chance = %d } },",
                    entry.X, entry.Y, entry.Z,
                    entry.wait[1], entry.wait[2], entry.wait.chance
                ));
            else
                output:append(string.format(
                    "    { X=%.2f, Y=%.2f, Z=%.2f, wait = { %d, %d } },",
                    entry.X, entry.Y, entry.Z,
                    entry.wait[1], entry.wait[2]
                ));
            end
        else
            output:append(string.format(
                "    { X=%.2f, Y=%.2f, Z=%.2f },",
                entry.X, entry.Y, entry.Z
            ));
        end
    end

    output:append("}");
    ashita.misc.set_clipboard(table.concat(output, '\n'));

    if #buffer > 0 then
        print(chat.header("Runner") ..
            chat.message("Clipboarded lua."))
    else
        print(chat.header("Runner") ..
            chat.error("No points saved."))
    end
end

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if #args == 0 or (string.lower(args[1]) ~= '/runner') then
        return;
    end
    e.blocked = true;

    if (args[2] == 'addpoint') then
        if (#args >= 5) then
            local min = args[3]
            local max = args[4]
            local chance = args[5]

            AddPoint(min, max, chance)
        elseif (#args >= 4) then
            local min = args[3]
            local max = args[4]

            AddPoint(min, max)
        else
            AddPoint()
        end
    end

    if (args[2] == 'clearpoints') then
        ClearPoints()
    end

    if (args[2] == 'cliplua') then
        ClipLua()
    end
end)
