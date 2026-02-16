addon.name      = 'SpellAnimation';
addon.author    = 'Shiyo';
addon.version   = '1.0.0.0';
addon.desc      = 'Prints out spell animation IDs';
addon.link      = 'https://ashitaxi.com/';

require('common');
require ('shiyolibs')
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

ashita.events.register('packet_in', 'HandleIncomingPacket', function (e)
    --Check if it's an action packet..
    if (e.id == 0x28) then
      local actionPacket = ParseActionPacket(e);
        -- Spell finsh
        if (actionPacket.Type == 4) then
            for _,target in ipairs(actionPacket.Targets) do
                for _,action in ipairs(target.Actions) do
                    print(action.Animation) -- Spell animation ID
                end
            end
        end
      end
  end);

  ashita.events.register('d3d_present', 'present_cb', function ()
  end)