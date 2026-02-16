addon.name      = 'CSData';
addon.author    = 'Shiyo';
addon.version   = '1.0.0.0';
addon.desc      = 'Prints out cutscene params data to a log file.';
addon.link      = 'https://ashitaxi.com/';

require('common');
require ('shiyolibs')
require('logmanager');
gLogManager:SetDirectory('CSData');
local chat = require('chat');

-------------------------------------------------------------------------------
-- Globals
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local function WriteAnimationId(mobName, skillId, animationId)
    local filePath = string.format('%slogs//AnimationIDs//AnimationIDs.txt', AshitaCore:GetInstallPath());
    local file = io.open(filePath, 'a');
    file:write(string.format('Mob: %s, Skill ID: %u, Animation ID: %u,\n', mobName, skillId, animationId));
    file:close();
end

local function Message(text)
    local stripped = string.gsub(text, '$H', ''):gsub('$R', '');
    LogManager:Log(5, addon.name, stripped);
    local color = ('\30%c'):format(106);
    local highlighted = color .. string.gsub(text, '$H', '\30\01\30\02');
    highlighted = string.gsub(highlighted, '$R', '\30\01' .. color);
    print(chat.header(addon.name) .. highlighted .. '\30\01');
end


local function GetPosition(index)
    local ent = AshitaCore:GetMemoryManager():GetEntity();
    -- X and Y are flipped on FFXI / Topaz
    return {
        X = ent:GetLocalPositionX(index) or 0,
        Y = ent:GetLocalPositionZ(index) or 0,
        Z = ent:GetLocalPositionY(index) or 0,
        Rot = ent:GetLocalPositionYaw(index) or 0; -- TODO: Doesn't work
    };
end

ashita.events.register('packet_in', 'HandleIncomingPacket', function (e)
    --Check if it's a CS packet..
    local eventId, params, eventType = GetEvent(e)
    local data
    if (eventId ~= nil) then
        data = string.format('Type: %s, EventID: %u', eventType, eventId)
        if (params ~= nil) then
            if (eventType ~= 'MsgID') then
                data = string.format('Type: %s, EventID: %u, Params: %u, %u, %u, %u, %u, %u, %u, %u', eventType, eventId, params[1],params[2],params[3],params[4],params[5],params[6],params[7],params[8] )
            else
                data = string.format('Type: %s, EventID: %u, Params: %u, %u, %u, %u', eventType, eventId, params[1],params[2],params[3],params[4] )
            end
        end
        gLogManager:Log(LogStyle.Message, 'CSData', data);
      end

    --   -- Zurium to give 100k domain points
    --     if e.id == 0x34 then
    --         ashita.bits.pack_be(e.data_modified_raw, 100000, 0x08, 0, 32)
    --     end
  end);

  ashita.events.register('packet_out', 'HandleOutgoingPacket', function (e)
        -- -- Zurium to give 100k domain points
        -- if e.id == 0x5B then
        --     local param1 = struct.unpack('L', e.data, 0x08+1)
        --     print('Param:' .. param1)
        --     ashita.bits.pack_be(e.data_modified_raw, 0x40000000, 0x08, 0, 32)
        -- end
  end)

  ashita.events.register('d3d_present', 'present_cb', function ()
  end)

  ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if #args == 0 or (string.lower(args[1]) ~= '/csdata') then
        return;
    end
    e.blocked = true;

    if (args[2] == 'pos') and (#args > 1) then
        local playerIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
        local pos = GetPosition(playerIndex);
        Message(string.format("X: %.3f, Y: %.3f, Z: %.3f", pos.X, pos.Y, pos.Z)); -- TODO: Rot
    end

    if (args[2] == 'cliplua') and (#args > 1) then
        local playerIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
        local pos = GetPosition(playerIndex);
        local posString = string.format("%.3f %.3f %.3f", pos.X, pos.Y, pos.Z); -- TODO: Rot
        ashita.misc.set_clipboard(posString);
        Message("Current position copied to clipboard!");
        return;
    end
end)