addon.name      = 'DeathTracker';
addon.author    = 'Shiyo';
addon.version   = '1.0.0.0';
addon.desc      = 'Tracks mob deaths(i.e. DRK unlock quest)';
addon.link      = 'https://ashitaxi.com/';

require('common')
require ('shiyolibs')
local chat = require('chat');
local settings = require('settings'); -- v4's settings lib
local imgui = require('imgui');       -- v4's gui lib
local statusEffect = require('statuseffect')
local TwoHours = require('twohours')
local deathTracker = 0

ashita.events.register('text_in', 'text_in_cb', function (e)
	if (string.match(e.message, 'falls to the ground.')) or (string.match(e.message, 'defeats the')) then
        deathTracker = deathTracker +1
        AshitaCore:GetChatManager():QueueCommand(0, ('/echo Enemies Killed: %s'):fmt(deathTracker))
	end
end)

ashita.events.register('d3d_present', 'present_cb', function ()
end)