addon.name      = 'MobExtData';
addon.author    = 'Shiyo';
addon.version   = '1.0.0.0';
addon.desc      = 'Prints out mob animation IDs to a log file.';
addon.link      = 'https://ashitaxi.com/';

require('common');
require ('shiyolibs')
require('logmanager');
gLogManager:SetDirectory('AnimationIDs');
local chat = require('chat');
local imgui = require('imgui');       -- v4's gui lib
local settings = require('settings')
local statusEffect = require('statuseffect')
local job = require('job')

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

ashita.events.register('packet_in', 'HandleIncomingPacket', function (e)
    if (e.id == 0xFF) then
        local mobId = struct.unpack('L', e.data, 0x04+1);
        local mobIndex = struct.unpack('H', e.data, 0x08+1);
        local thLevel = struct.unpack('H', e.data, 0x0A+1);
    
        local offset = 0x0C;
        local buffs = T{};
        while (offset < e.size) do
            buffs:append({
                Id = struct.unpack('H', e.data, offset+1),
                Power = struct.unpack('H', e.data, offset+3),
                Expiration = os.clock() + (struct.unpack('L', e.data, offset+5) / 1000),
            });
            offset = offset + 8;
        end
    
        --Block it since client won't use it and may not like it..
        e.blocked = true;
    end
  end);

  ashita.events.register('d3d_present', 'present_cb', function ()
  end)