addon.name      = 'EntitySpawns';
addon.author    = 'Shiyo';
addon.version   = '1.0.0.0';
addon.desc      = 'Prints out entity spawns data to a log file.';
addon.link      = 'https://ashitaxi.com/';

require('common');
require ('shiyolibs')
require('logmanager');
gLogManager:SetDirectory('EntitySpawns');
local chat = require('chat');

ashita.events.register('load', 'load_cb', function()
    RegisterEntitySpawnPositions()
end)

ashita.events.register('unload', 'unload_cb', function()
    UnregisterEntitySpawnPositions()
end)

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if #args == 0 or (string.lower(args[1]) ~= '/entityspawns') then
        return;
    end
    e.blocked = true;

    if (args[2] == 'save') and (#args > 1) then
        local positionIds = GetEntitySpawnPositions()

        if next(positionIds) == nil then
            print(chat.header("EntitySpawns") ..
                chat.error("No points saved."))
            return
        end

        for id, data in pairs(positionIds) do
            local name2 = data.Name:gsub("(%l)(%u)", "%1 %2")
            local name1 = name2:gsub(" ", "_")
            local x = data.X
            local y = data.Y
            local z = data.Z
            local data = string.format("INSERT INTO `mob_spawn_points` VALUES (%d,'%s','%s',32,%.3f,%.3f,%.3f,160);", id, name1, name2, x, y, z)
            -- Should be formatted like: INSERT INTO `mob_spawn_points` VALUES (17522877,'Iron_CraniumV2','Iron Cranium',32,-530,-0.5,-650,160);
            gLogManager:Log(LogStyle.Message, 'EntitySpawns', data);
        end
    end
end) 