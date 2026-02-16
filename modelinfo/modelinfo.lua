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

addon.name      = 'modelinfo';
addon.author    = 'atom0s';
addon.version   = '1.0';
addon.desc      = 'Displays your current targets model information.';
addon.link      = 'https://ashitaxi.com/';

require('common');
local chat = require('chat');
local fonts = require('fonts');

-- Addon Variables
local modelinfo = T{
    font = nil,
    font_settings = T{
        visible = true,
        font_family = 'Consolas',
        font_height = 14,
        color = 0xFFFFFFFF,
        bold = true,
        padding = 10,
        position_x = 100,
        position_y = 250,
        background = T{
            visible = true,
            color = 0x80000000,
        }
    },
};

--[[
* event: load
* desc : Event called when the addon is being loaded.
--]]
ashita.events.register('load', 'load_cb', function ()
    modelinfo.font = fonts.new(modelinfo.font_settings);
    modelinfo.font:register('left_click_up', 'minfo_lclick', function (e)
        if (not modelinfo.font:hit_test(e.x, e.y)) then
            return;
        end

        local t = GetEntity(AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0));
        if (t == nil) then return; end

        local str = '0x' .. struct.pack('HbbHHHHHHHH',
            0, -- Size, but not recoverable..
            t.Look.Hair, t.Race,
            t.Look.Head, t.Look.Body, t.Look.Hands, t.Look.Legs, t.Look.Feet,
            t.Look.Main, t.Look.Sub, t.Look.Ranged
        ):tohex():gsub(' ', '');

        ashita.misc.set_clipboard(str);
        print(chat.header(addon.name):append(chat.message('Copied to clipboard.')));
    end);
    modelinfo.font:register('right_click_up', 'minfo_rclick', function (e)
        if (not modelinfo.font:hit_test(e.x, e.y)) then
            return;
        end

        local t = GetEntity(AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0));
        if (t == nil) then return; end

        local str = ([[
            Size : %f
            Race : 0x%02X
            Hair : 0x%02X
            Head : 0x%04X
            Body : 0x%04X
           Hands : 0x%04X
            Legs : 0x%04X
            Feet : 0x%04X
            Main : 0x%04X
             Sub : 0x%04X
          Ranged : 0x%04X]]):fmt(
                  t.ModelSize,
                  t.Race,
                  t.Look.Hair,
                  t.Look.Head,
                  t.Look.Body,
                  t.Look.Hands,
                  t.Look.Legs,
                  t.Look.Feet,
                  t.Look.Main,
                  t.Look.Sub,
                  t.Look.Ranged
              );

        ashita.misc.set_clipboard(str);
        print(chat.header(addon.name):append(chat.message('Copied to clipboard.')));
    end);
end);

--[[
* event: unload
* desc : Event called when the addon is being unloaded.
--]]
ashita.events.register('unload', 'unload_cb', function ()
    if (modelinfo.font ~= nil) then
        modelinfo.font:destroy();
        modelinfo.font = nil;
    end
end);

--[[
* event: d3d_present
* desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register('d3d_present', 'present_cb', function ()
    if (modelinfo.font == nil) then
        return;
    end

    local t = GetEntity(AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0));
    if (t == nil) then
        modelinfo.font.text = '';
        return;
    end

    modelinfo.font.text = ([[
  Size : %f
  Race : 0x%02X
  Hair : 0x%02X
  Head : 0x%04X
  Body : 0x%04X
 Hands : 0x%04X
  Legs : 0x%04X
  Feet : 0x%04X
  Main : 0x%04X
   Sub : 0x%04X
Ranged : 0x%04X]]):fmt(
        t.ModelSize,
        t.Race,
        t.Look.Hair,
        t.Look.Head,
        t.Look.Body,
        t.Look.Hands,
        t.Look.Legs,
        t.Look.Feet,
        t.Look.Main,
        t.Look.Sub,
        t.Look.Ranged
    );
end);