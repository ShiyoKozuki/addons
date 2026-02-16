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

addon.name      = 'ModelSearch'
addon.author    = 'Thorny';
addon.version   = '1.00';
addon.desc      = 'FIND MODELS';
addon.link	    = 'https://github.com/ThornyFFXI/';

require('common');
local imgui = require('imgui');
local interface = {
    Header = { 1.0, 0.75, 0.55, 1.0 },
    Index = { 1 },
};
local softMax = 900;
local slotData = {
    ['Race'] = { Minimum=1, Maximum=8 },
    ['Face'] = { Minimum=0, Maximum=15 },
    ['Head'] = { Minimum=0, Maximum=4095 },
    ['Body'] = { Minimum=8192, Maximum=12287 },
    ['Hands'] = { Minimum=12288, Maximum=16383 },
    ['Legs'] = { Minimum=16384, Maximum=20479 },
    ['Feet'] = { Minimum=20480, Maximum=24575 },
    ['Main'] = { Minimum=24576, Maximum=28671 },
    ['Sub'] = { Minimum=28672, Maximum=32767 },
    ['Ranged'] = { Minimum=32768, Maximum=36863 },
};



local function GetModels(index)
    local ent = AshitaCore:GetMemoryManager():GetEntity();
    local renderFlags = ent:GetRenderFlags0(index);
    if (bit.band(renderFlags, 0x200) == 0) then
        return;
    end
    if (bit.band(renderFlags, 0x4000) ~= 0) then
        return;
    end
    local models = {
        { Name='Race', Value=ent:GetRace(index) },
        { Name='Face', Value=ent:GetLookHair(index) },
        { Name='Head', Value=ent:GetLookHead(index) },
        { Name='Body', Value=ent:GetLookBody(index) },
        { Name='Hands', Value=ent:GetLookHands(index) },
        { Name='Legs', Value=ent:GetLookLegs(index) },
        { Name='Feet', Value=ent:GetLookFeet(index) },
        { Name='Main', Value=ent:GetLookMain(index) },
        { Name='Sub', Value=ent:GetLookSub(index) },
        { Name='Ranged', Value=ent:GetLookRanged(index) },
    };
    return models;
end

local ModelSetters = {
    ['Race'] = AshitaCore:GetMemoryManager():GetEntity().SetRace,
    ['Face'] = AshitaCore:GetMemoryManager():GetEntity().SetLookHair,
    ['Head'] = AshitaCore:GetMemoryManager():GetEntity().SetLookHead,
    ['Body'] = AshitaCore:GetMemoryManager():GetEntity().SetLookBody,
    ['Hands'] = AshitaCore:GetMemoryManager():GetEntity().SetLookHands,
    ['Legs'] = AshitaCore:GetMemoryManager():GetEntity().SetLookLegs,
    ['Feet'] = AshitaCore:GetMemoryManager():GetEntity().SetLookFeet,
    ['Main'] = AshitaCore:GetMemoryManager():GetEntity().SetLookMain,
    ['Sub'] = AshitaCore:GetMemoryManager():GetEntity().SetLookSub,
    ['Ranged'] = AshitaCore:GetMemoryManager():GetEntity().SetLookRanged,
};

local function SetModels(index, models)
    local entity = AshitaCore:GetMemoryManager():GetEntity();
    for _,entry in ipairs(models) do
        ModelSetters[entry.Name](entity, index, entry.Value);
    end
    entity:SetModelUpdateFlags(index, 1);
end

local function RenderInterface()
    if (imgui.Begin('ModelSearch_Interface', { true }, ImGuiWindowFlags_AlwaysAutoResize)) then
        
        imgui.TextColored(interface.Header, 'Player Index');
        imgui.SliderInt('##ModelSearch_Player_Index',  interface.Index, 1, 0x8FF, '%d', ImGuiSliderFlags_AlwaysClamp);
        imgui.SameLine();
        if (imgui.Button('Self')) then
            interface.Index[1] = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
        end
        imgui.SameLine();
        if (imgui.Button('Target')) then
            local targetMgr = AshitaCore:GetMemoryManager():GetTarget();
            local target = targetMgr:GetTargetIndex(targetMgr:GetIsSubTargetActive());
            if (target > 0) then
                interface.Index[1] = target;
            end
        end

        local models = GetModels(interface.Index[1]);
        if (models == nil) then
            imgui.TextColored(interface.Header, 'Models could not be observed.');
        else
            local changed = false;

            for _,model in ipairs(models) do
                local data = slotData[model.Name];
                local buffer = { model.Value - data.Minimum };
                local max = math.min(data.Maximum - data.Minimum, softMax);
                imgui.TextColored(interface.Header, model.Name);
                imgui.SliderInt('##ModelSearch_Model_Value_' .. model.Name, buffer, 0, max, '%d', ImGuiSliderFlags_AlwaysClamp);
                imgui.SameLine();
                if (imgui.Button('+##ModelSearch_Model_Value_Increase_' .. model.Name)) then
                    buffer[1] = buffer[1] + 1;
                    if (buffer[1] > max) then
                        buffer[1] = max;
                    end
                end
                imgui.SameLine();
                if (imgui.Button('-##ModelSearch_Model_Value_Decrease_' .. model.Name)) then
                    buffer[1] = buffer[1] - 1;
                    if buffer[1] < 0 then
                        buffer[1] = 0;
                    end
                end
                buffer[1] = buffer[1] + data.Minimum;
                imgui.SameLine();
                imgui.Text(string.format('%u', buffer[1]));
                if (buffer[1] ~= model.Value) then
                    model.Value = buffer[1];
                    changed = true;
                end
            end

            if (changed) then
                SetModels(interface.Index[1], models);
            end
        end
        
        imgui.TextColored(interface.Header, 'Model ID:');
        local entity = AshitaCore:GetMemoryManager():GetEntity():GetRawEntity(interface.Index[1]);
        if (entity == nil) then
            imgui.TextColored(interface.Header, 'Entity struct not found.');
        else
            local look = entity.Look;

            local output = string.format('0x%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X',
            bit.band(look.Hair, 0xFF),
            bit.rshift(bit.band(look.Hair, 0xFF00), 8),
            bit.band(look.Head, 0xFF),
            bit.rshift(bit.band(look.Head, 0xFF00), 8),
            bit.band(look.Body, 0xFF),
            bit.rshift(bit.band(look.Body, 0xFF00), 8),
            bit.band(look.Hands, 0xFF),
            bit.rshift(bit.band(look.Hands, 0xFF00), 8),
            bit.band(look.Legs, 0xFF),
            bit.rshift(bit.band(look.Legs, 0xFF00), 8),
            bit.band(look.Feet, 0xFF),
            bit.rshift(bit.band(look.Feet, 0xFF00), 8),
            bit.band(look.Main, 0xFF),
            bit.rshift(bit.band(look.Main, 0xFF00), 8),
            bit.band(look.Sub, 0xFF),
            bit.rshift(bit.band(look.Sub, 0xFF00), 8),
            bit.band(look.Ranged, 0xFF),
            bit.rshift(bit.band(look.Ranged, 0xFF00), 8),
            look.Unknown0000[1],
            look.Unknown0000[2]);
            imgui.Text(output);
        end

        imgui.End();
    end
end

ashita.events.register('d3d_present', 'HandleRender', function ()
    RenderInterface();
end);