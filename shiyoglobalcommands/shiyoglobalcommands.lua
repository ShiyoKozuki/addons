---@diagnostic disable: lowercase-global
addon.name      = 'ShiyoGlobalCommands';
addon.author    = 'Shiyo';
addon.version   = '2.0.10.0';
addon.desc      = 'Does melee DD and tank things';
addon.link      = 'https://ashitaxi.com/';
require('common')
require ('shiyolibs')
job = require('job')
local chat = require('chat');
local settings = require('settings'); -- v4's settings lib
local imgui = require('imgui');       -- v4's gui lib
local statusEffect = require('statuseffect')
local TwoHours = require('twohours')
-------------------------------------------------------------------------------
-- Globals
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

ashita.events.register('text_in', 'text_in_cb', function (e)
end);

ashita.events.register('command', 'command_cb', function (e)
end);

ashita.events.register('packet_in', 'HandleIncomingPacket', function (e)
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    RegisterGlobalCommands()
end);

ashita.events.register('unload', 'fancy_unload', function ()
end)