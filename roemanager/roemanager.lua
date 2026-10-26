addon.name      = 'RoeManager';
addon.author    = 'Shiyo';
addon.version   = '1.0.0.0';
addon.desc      = 'Manages and automatically flags records of eminence quests';
addon.link      = 'https://ashitaxi.com/';

require('common');
require ('shiyolibs')
require('logmanager');
local chat = require('chat');
local imgui = require('imgui');       -- v4's gui lib
local settings = require('settings')
local statusEffect = require('statuseffect')
local job = require('job')
local ROE = require('RoE')

-- TODO: UI for auto setting ones (Use below code)
-- TODO: Slash (/) command to set the RoE by Id so you can /mss it
-- Dailies missing from DAT:
    -- DAILY_VANQUISH_MULTIPLE = 4082,
    -- DAILY_BUFF_ALLIES = 4083,
    -- DAILY_HEAL_500 = 4084,

local function FlagROE()
    local roeList =
    T{
        ['Daily'] = T{
            ROE.DAILY_VANQUISH_MULTIPLE,
            ROE.DAILY_BUFF_ALLIES,
            ROE.DAILY_HEAL_500,
        },
        ['Unity'] = T{
            ROE.UNITY_COMMUNIQUE,
            ROE.UNITY_COMRADE,
            ROE.UNITY_VANQUISH_MULTIPLE_E,
            ROE.UNITY_VANQUISH_WITH_LEADER_E,
        },
    }

    for category, roeIds in pairs(roeList) do
        if category == 'Daily' then
            for _, roeId in ipairs(roeIds) do
                local packet = struct.pack('LHH', 0, roeId, 0)
                AshitaCore:GetPacketManager():AddOutgoingPacket(0x10C, packet:totable())
                coroutine.sleep(2)
            end
        end
    end
end

ashita.events.register('packet_out', 'roe_outgoing', function (e)
    if (e.id == 0x15) then
        if (e.id == 0x111) then
            Player.CurrentROE = {};
            local id = ashita.bits.unpack_be(e.data_raw, 0x100, 0, 12);
            local progress = ashita.bits.unpack_be(e.data_raw, 0x100, 12, 20);
            Player.CurrentROE[1] = { Id = id, Progress = progress };
            for i = 2,31 do
                id = ashita.bits.unpack_be(e.data_raw, (i * 4) - 4, 0, 12);
                progress = ashita.bits.unpack_be(e.data_raw, (i * 4) - 4, 12, 20);
                Player.CurrentROE[i] = { Id = id, Progress = progress };
            end
        elseif (e.id == 0x112) then
            if Player.CompletedROE == nil then
                Player.CompletedROE = {};
            end
            local offset = 1024 * struct.unpack('H', e.data, 0x84 + 1);
            for i = 0,1023 do
                if (ashita.bits.unpack_be(e.data_raw, 4, i, 1) == 1) then
                    Player.CompletedROE[offset + i] = true;
                else
                    Player.CompletedROE[offset + 1] = nil;
                end
            end
        end
    end
end)

ashita.events.register('d3d_present', 'present_cb', function()
end)