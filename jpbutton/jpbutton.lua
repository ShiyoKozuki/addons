--[[
* Addons - Copyright (c) 2023 Ashita Development Team
* Contact: https://www.ashitaxi.com/
* Contact: https://discord.gg/Ashita
*
* This file is part of Ashita.
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.
--]]

addon.name      = 'jpbutton';
addon.author    = 'atom0s';
addon.version   = '1.1';
addon.desc      = 'Enables the Job Points button without needing to meet the requirements.';
addon.link      = 'https://ashitaxi.com/';

require('common');
local chat = require('chat');
local ffi = require('ffi');

-- jpbutton Variables
local jpbutton = T{
    backups = T{
        p1 = nil,
        p2 = nil,
    },
    pointers = T{
        p1 = nil,
        p2 = nil,
    },
    gc = nil,
};

--[[
* event: load
* desc : Event called when the addon is being loaded.
--]]
ashita.events.register('load', 'load_cb', function ()
    -- Find the required pointers..
    jpbutton.pointers.p1 = ashita.memory.find('FFXiMain.dll', 0, '74??F6000174??803D????????6373??8B4E086A086A05E8', 0x00, 0x00);
    if (jpbutton.pointers.p1 == 0) then
        error(chat.header(addon.name):append(chat.error('Error: Failed to locate required pointer. (p1)')));
        return;
    end

    jpbutton.pointers.p2 = ashita.memory.find('FFXiMain.dll', 0, '3C630F93C0C2040032C0C20400', 0x00, 0x00);
    if (jpbutton.pointers.p2 == 0) then
        error(chat.header(addon.name):append(chat.error('Error: Failed to locate required pointer. (p2)')));
        return;
    end

    -- Backup the patch data..
    jpbutton.backups.p1 = ashita.memory.read_array(jpbutton.pointers.p1, 0x02);
    jpbutton.backups.p2 = ashita.memory.read_array(jpbutton.pointers.p2, 0x05);

    -- Patch the functions..
    ashita.memory.write_array(jpbutton.pointers.p1, { 0xEB, 0x1A });
    ashita.memory.write_array(jpbutton.pointers.p2, { 0xB0, 0x01, 0x90, 0x90, 0x90 });

    print(chat.header(addon.name):append(chat.message('Functions patched; Job Points button enabled!')));
end);

-- Create a cleanup object to restore the pointers when the addon is unloaded..
jpbutton.gc = ffi.new('uint8_t*');
ffi.gc(jpbutton.gc, function ()
    if (jpbutton.pointers.p1 ~= 0 and jpbutton.backups.p1 ~= nil) then
        ashita.memory.write_array(jpbutton.pointers.p1, jpbutton.backups.p1);
    end

    jpbutton.backups.p1 = nil;
    jpbutton.pointers.p1 = 0;

    if (jpbutton.pointers.p2 ~= 0 and jpbutton.backups.p2 ~= nil) then
        ashita.memory.write_array(jpbutton.pointers.p2, jpbutton.backups.p2);
    end

    jpbutton.backups.p2 = nil;
    jpbutton.pointers.p2 = 0;
end);