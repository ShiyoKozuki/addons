addon.name      = 'Parse Action Packet';
addon.author    = 'Shiyo';
addon.version   = '1.0';
addon.desc      = 'Prints action packets for items.';
addon.link      = 'https://ashitaxi.com/';

require('common');
local chat = require('chat');

local bitData;
local bitOffset;
local function UnpackBits(length)
    local value = ashita.bits.unpack_be(bitData, 0, bitOffset, length);
    bitOffset = bitOffset + length;
    return value;
end
function ParseActionPacket(e)
    local actionPacket = T{};
    bitData = e.data_raw;
    bitOffset = 40;
    actionPacket.UserId = UnpackBits(32);
    local targetCount = UnpackBits(6);
    --Unknown 4 bits
    bitOffset = bitOffset + 4;
    actionPacket.Type = UnpackBits(4);
    actionPacket.Id = UnpackBits(32);
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

-- Spells
ashita.events.register('packet_in', 'HandleIncomingPacket', function (e)
    --Check if it's an action packet..
    if (e.id == 0x28) then
        local actionPacket = ParseActionPacket(e);
        if actionPacket.UserId == AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0) then
            -- Magic start
            if (actionPacket.Type == 8) then
                local spellId = actionPacket.Targets[1].Actions[1].Param
                local spellResource = AshitaCore:GetResourceManager():GetSpellById(spellId);
                if spellResource then
                    print(string.format('I started casting %s.', spellResource.Name[1]));
                else
                    print('I started casting a unknown spell.');          
                end
            -- Spell finish
            elseif (actionPacket.Type == 4) then
                local spellId = actionPacket.Id;
                local spellResource = AshitaCore:GetResourceManager():GetSpellById(spellId);
                if spellResource then
                    print(string.format('I finished casting %s.', spellResource.Name[1]));
                else
                    print('I finished casting an unknown spell');          
                end
                if actionPacket.Targets[1].Actions[1].Message == 85 then
                    print('Resisted your spell!')
                end
            end
        end
    end
end);

-- Item use
-- ashita.events.register('packet_in', 'HandleIncomingPacket', function (e)
--     --Check if it's an action packet..
--     if (e.id == 0x28) then
--         local actionPacket = ParseActionPacket(e);
--         if actionPacket.UserId == AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0) then
--             --Item start
--             if (actionPacket.Type == 9) then
--                 local itemId = actionPacket.Targets[1].Actions[1].Param
--                 local itemResource = AshitaCore:GetResourceManager():GetItemById(itemId);
--                 if itemResource then
--                     print(string.format('I started using an %s.', itemResource.Name[1]));
--                 else
--                     print('I started using an unknown item.');          
--                 end
--             --Item finish
--             elseif (actionPacket.Type == 5) then
--                 local itemId = actionPacket.Id;
--                 local itemResource = AshitaCore:GetResourceManager():GetItemById(itemId);
--                 if itemResource then
--                     print(string.format('I finished using an %s.', itemResource.Name[1]));
--                 else
--                     print('I finished using an unknown item.');          
--                 end
--             end
--         end
--     end
-- end);