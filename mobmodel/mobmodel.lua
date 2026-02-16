--[[
* MIT License
* 
* Copyright (c) 2023 Thorny 
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
]]--

addon.name      = 'MobModel'
addon.author    = 'Thorny';
addon.version   = '1.00';
addon.desc      = 'FIND MODELS';
addon.link	    = 'https://github.com/ThornyFFXI/';

require('common');
local chat = require('chat');
local imgui = require('imgui');
local interface = {
    Header = { 1.0, 0.75, 0.55, 1.0 },
    Index = { 1 },
};
local modelData = {};

local function RenderInterface()
    if (imgui.Begin('MobModel_Interface', { true }, ImGuiWindowFlags_AlwaysAutoResize)) then
        local targetMgr = AshitaCore:GetMemoryManager():GetTarget();
        local target = targetMgr:GetTargetIndex(targetMgr:GetIsSubTargetActive());
        imgui.TextColored(interface.Header, 'Target');
        if (target == 0) then
            imgui.Text('N/A');
        else
            imgui.Text(string.format('%s[%u]', AshitaCore:GetMemoryManager():GetEntity():GetName(target), target));
            imgui.TextColored(interface.Header, 'Model ID:');
            local modelString = modelData[target];
            if modelString == nil then
                imgui.TextColored(interface.Header, 'Model data not found.');
            else
                imgui.Text(modelString);
                if (imgui.Button('Copy to Clipboard')) then
                    ashita.misc.set_clipboard(modelString);
                    print(chat.header('MobModel') .. chat.message('Copied ') .. chat.color1(2, modelString) .. chat.message(' to clipboard.'));
                end
            end
        end
        imgui.End();
    end
end

ashita.events.register('d3d_present', 'HandleRender', function ()
    RenderInterface();
end);

ashita.events.register('packet_in', 'ModelSearch_HandleIncomingPacket', function (e)
    if (e.id == 0x00A) then
        modelData = {};
    end

    if (e.id == 0x0E) then
        local type = struct.unpack('B', e.data, 0x30 + 1);
        if (type == 1) or (type == 5) then
            local index = struct.unpack('H', e.data, 0x08 + 1);
            local flags = struct.unpack('B', e.data, 0x0A + 1);
            if (bit.band(flags, 8) == 8) or (flags == 0x57) then
                -- Maybe if (bit.band(flags, 0x10) == 0x10) then ?
                local lookString = '0x';
                for i = 0x30,0x43 do
                    lookString = lookString .. string.format('%02X', struct.unpack('B', e.data, i + 1));
                end
                modelData[index] = lookString;
            end
        else
            local index = struct.unpack('H', e.data, 0x08 + 1);
            local lookString = '0x';
            for i = 0x30,0x33 do
                lookString = lookString .. string.format('%02X', struct.unpack('B', e.data, i + 1));
            end
            for i = 1,16 do
                lookString = lookString .. '00';
            end
            modelData[index] = lookString;
        end
    end
end);