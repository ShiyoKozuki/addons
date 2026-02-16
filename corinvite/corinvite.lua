addon.name      = 'CorInvite';
addon.author    = 'Shiyo';
addon.version   = '2.0.2.0';
addon.desc      = 'Does BLM things';
addon.link      = 'https://ashitaxi.com/';

require('common');
require ('shiyolibs')
statusEffect = require('statuseffect')
local settings = require('settings')

local inviteTimer = 0

ashita.events.register('d3d_present', 'present_cb', function ()
    if not GetBuffActive(statusEffect.CORSAIRS_ROLL) then 
        if (os.time() > inviteTimer) then
            AshitaCore:GetChatManager():QueueCommand(0, ('/pcmd add Farega'))
            inviteTimer = os.time() + 30;
        end
    end
  end);