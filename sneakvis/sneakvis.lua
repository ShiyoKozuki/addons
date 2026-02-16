--[[
* Addons - Copyright (c) 2021 Ashita Development Team
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

addon.name      = 'sneakvis';
addon.author    = 'Thorny';
addon.version   = '1.0';
addon.desc      = 'Cancels sneak and invisible when someone casts them on you while they are already active.';
addon.link      = 'https://ashitaxi.com/';

require('common');

local function GetBuffActive(matchBuff)
  local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();    
  for _, buff in pairs(buffs) do
    if buff == matchBuff then
      return true;
    end
  end
  return false;
end

local function ParseActionPacket(e)
    local bitData;
    local bitOffset;
    local function UnpackBits(length)
        local value = ashita.bits.unpack_be(bitData, 0, bitOffset, length);
        bitOffset = bitOffset + length;
        return value;
    end
    
    local actionPacket = T{};
    bitData = e.data_raw;
    bitOffset = 40;
    actionPacket.UserId = UnpackBits(32);
    local targetCount = UnpackBits(6);
    --Unknown 4 bits
    bitOffset = bitOffset + 4;
    actionPacket.ActionType = UnpackBits(4);
    actionPacket.ActionId = UnpackBits(16);
    bitOffset = bitOffset + 16;
    --Unknown 32 bits
    bitOffset = bitOffset + 32;

    actionPacket.Targets = T{};
    for i = 1,targetCount do
        local target = T{};
        target.Id = UnpackBits(32);
        local actionCount = UnpackBits(4);
        target.Actions = T{};
        for j = 1,actionCount do
            local action = {};
            action.Reaction = UnpackBits(5);
            action.Animation = UnpackBits(12);
            action.SpecialEffect = UnpackBits(7);
            action.Knockback = UnpackBits(3);
            action.Param = UnpackBits(17);
            action.Message = UnpackBits(10);
            action.Flags = UnpackBits(31);

            local hasAdditionalEffect = (UnpackBits(1) == 1);
            if hasAdditionalEffect then
                local additionalEffect = {};
                additionalEffect.Damage = UnpackBits(10);
                additionalEffect.Param = UnpackBits(17);
                additionalEffect.Message = UnpackBits(10);
                action.AdditionalEffect = additionalEffect;
            end

            local hasSpikesEffect = (UnpackBits(1) == 1);
            if hasSpikesEffect then
                local spikesEffect = {};
                spikesEffect.Damage = UnpackBits(10);
                spikesEffect.Param = UnpackBits(14);
                spikesEffect.Message = UnpackBits(10);
                action.SpikesEffect = spikesEffect;
            end

            target.Actions:append(action);
        end
        actionPacket.Targets:append(target);
    end
    
    return actionPacket;
end

local function CancelBuff(id)
    local packet = { 0x00, 0x00, 0x00, 0x00, bit.band(id, 0xFF), bit.rshift(id, 8), 0x00, 0x00 };
    AshitaCore:GetPacketManager():AddOutgoingPacket(0xF1, packet);
end
    

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if (e.id == 0x028) then
        local packet = ParseActionPacket(e);
        local myId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
        for _,target in pairs(packet.Targets) do
            if target.Id == myId then
                for _,action in pairs(target.Actions) do
                    if packet.ActionType == 8 then
                        if (action.Param == 136) and packet.UserId ~= myId and GetBuffActive(69) then
                            CancelBuff(69);
                        elseif action.Param == 137 and GetBuffActive(71) then
                            CancelBuff(71);
                        elseif action.Param == 318 and GetBuffActive(71) then
                            CancelBuff(71);
                        end
                    elseif packet.ActionType == 9 then       
                        if (action.Param == 4165) and GetBuffActive(71) then
                            CancelBuff(71);
                        end                    
                    end
                end
            end
        end
	end
end);