---@diagnostic disable: lowercase-global
local statusEffect = require('statuseffect')
local job = require('job')

hpTemps = T{ 'Dusty Potion', 'Lucid Potion I', 'Lucid Potion II', 'Lucid Potion III', 'Dusty Elixir', 'Lucid Elixir I', 'Lucid Elixir II', 'Healing Mist', 'Healing Powder', 'Megalixir' }
mpTemps = T{ 'Lucid Ether I', 'Lucid Ether II', 'Lucid Ether III', 'Dusty Elixir', 'Lucid Elixir I', 'Lucid Elixir II', 'Mana Mist', 'Mana Powder', 'Megalixir' }
dpsTemps = T{ 'Braver\'s Drink', 'Berserker\'s Tonic', 'Spy\'s Drink', 'Monarch\'s Drink', 'Stalwart\'s Tonic' }
wingTemps = T{ 'Dusty Wing', 'Daedalus Wing', 'Lucid Wings I',  }

local function GetShortFlags(entityIndex)
    -- if shortFlags is 0x10, entity is a monster
    -- if shortflags is 0x01 entity is the player running that instance
    -- if shortflags is 0x0D its a party member
    -- if shortflags is 0x09 it's a player not in party
    -- if fullflags is 4366 its a trust npc
    local fullFlags = AshitaCore:GetMemoryManager():GetEntity():GetSpawnFlags(entityIndex);
    return bit.band(fullFlags, 0xFF);
end

function GetItemByName(item)
    local itemResource = AshitaCore:GetResourceManager():GetItemByName(item , 0);
    if (itemResource ~= nil) then
        return itemResource.Id
    end
end

function HasItemInEquippableInventory(itemId)
    local containers = {0, 8, 10, 11, 12, 13, 14, 15, 16} -- Containers to iterate through
    for _, containerId in ipairs(containers) do
        for slot = 1, 80 do
            local item = AshitaCore:GetMemoryManager():GetInventory():GetContainerItem(containerId, slot)
            if (item ~= nil) and (item.Id == itemId) then
                return true
            end
        end
    end
    return false
end

function HasItem(itemId)
    for i = 1,80,1 do
        local item = AshitaCore:GetMemoryManager():GetInventory():GetContainerItem(0, i);
        if (item ~= nil) and (item.Id == itemId) then
            return true;
        end
        item = AshitaCore:GetMemoryManager():GetInventory():GetContainerItem(3, i);
        if (item ~= nil) and (item.Id == itemId) then
            return true;
        end
    end
    return false;
end

function TryUseItem(item, target)
    local itemResource = AshitaCore:GetResourceManager():GetItemByName(item , 0);
    if HasItem(itemResource.Id) then
        AshitaCore:GetChatManager():QueueCommand(0, ('/item "%s" %u'):fmt(itemResource.Name[1], AshitaCore:GetMemoryManager():GetEntity():GetServerId(target)));
        mActionTimer = os.time() + (itemResource.CastTime / 4) + 3;
        castFinished = os.time() + (itemResource.CastTime / 4) + 1
        return true;
    end
    return false;
end

function TryUseHealingItem(EntityIndex)
    for _,v in pairs(hpTemps) do
      if TryUseItem(v, EntityIndex) then
        return true;
      end
    end
    return false;
end

function GetAbilityRecast(abilityId)
    for i = 0,31,1
    do
        if (AshitaCore:GetMemoryManager():GetRecast():GetAbilityTimerId(i) == abilityId) then
        return AshitaCore:GetMemoryManager():GetRecast():GetAbilityTimer(i);
        end
    end
    return 1;
end

function GetBuffActive(matchBuff)
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();    
    for _, buff in pairs(buffs) do
        if buff == matchBuff then
        return true;
        end
    end
    return false;
end

function GetAnyBuffActive(buffs)
    for _,buff in pairs(buffs) do
        if (GetBuffActive(buff)) then
        return true;
        end
    end
    return false;
end

local partybuffsptr = ashita.memory.find('FFXiMain.dll', 0, 'B93C0000008D7004BF????????F3A5', 9, 0);
partybuffsptr  = ashita.memory.read_uint32(partybuffsptr);

function GetMemberBuffs(memberIndex)
    local party = AshitaCore:GetMemoryManager():GetParty()
    if (memberIndex == AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0)) then
        local buffs = T{};
        local myBuffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
        for _,buff in pairs(myBuffs) do
            if buff ~= -1 then
                buffs:append(buff);
            end
        end
        return buffs; 
    end

    local memberServerId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(memberIndex);
    local memberBuffs = T{};
    if (memberServerId > 0) then
        for memberIndex = 0,4 do
            local memberPtr = partybuffsptr + (0x30 * memberIndex);
            local playerId = ashita.memory.read_uint32(memberPtr);
            if (playerId == memberServerId) then
                for buffIndex = 0,31 do
                    local highBits = ashita.memory.read_uint8(memberPtr + 8 + (math.floor(buffIndex / 4)));
                    local fMod = math.fmod(buffIndex, 4) * 2;
                    highBits = bit.lshift(bit.band(bit.rshift(highBits, fMod), 0x03), 8);
                    local lowBits = ashita.memory.read_uint8(memberPtr + 16 + buffIndex);
                    local buff = highBits + lowBits;
                    if buff ~= 255 then
                        memberBuffs:append(buff);
                    end
                end
            end
        end
    end
    return memberBuffs;
end

function CheckJobLevels(spell)
    local mJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
    local sJob = AshitaCore:GetMemoryManager():GetPlayer():GetSubJob();
    local mJobLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    local sJobLevel = AshitaCore:GetMemoryManager():GetPlayer():GetSubJobLevel();
    local resource = AshitaCore:GetResourceManager():GetSpellByName(spell, 0);
    if (resource.LevelRequired[mJob + 1] > 0) and (resource.LevelRequired[mJob + 1] <= mJobLevel) then
        return true;
    elseif (resource.LevelRequired[sJob + 1] > 0) and (resource.LevelRequired[sJob + 1] <= sJobLevel) then
        return true;
    else
        return false;
    end
end

function TryCastSpell(spell, target)
    local spellResource = AshitaCore:GetResourceManager():GetSpellByName(spell, 0);
    if (AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spellResource.Index) == 0) then
        AshitaCore:GetChatManager():QueueCommand(0, ('/ma "%s" %u'):fmt(spellResource.Name[1], AshitaCore:GetMemoryManager():GetEntity():GetServerId(target)));
        mActionTimer = os.time() + (spellResource.CastTime / 4) + 3;
        castFinished = os.time() + (spellResource.CastTime / 4) + 1
        return true;
    end
    return false;
end

local SCH_550_JP_GIFT = false;

function GetStratagemCount()
    for x = 0, 31 do
        local id = AshitaCore:GetMemoryManager():GetRecast():GetAbilityTimerId(x);
        local timer = AshitaCore:GetMemoryManager():GetRecast():GetAbilityTimer(x);
        if (id == 231) then
            -- Determine the players SCH level..
            local player = AshitaCore:GetMemoryManager():GetPlayer();
            local lvl = player:GetSubJobLevel();
            if (player:GetMainJob() == 20) then
                lvl = player:GetMainJobLevel();
            end

            -- Adjust the timer offset by the players level..
            local val = 48;
            if (lvl < 30) then
                val = 240;
            elseif (lvl < 50) then
                val = 120;
            elseif (lvl < 70)then
                val = 80;
            elseif (lvl < 90) then
                val = 60;
            end

            -- Calculate the stratagems amount..
            local stratagems = 0;
            if lvl == 99 and SCH_550_JP_GIFT then
                val = 33;
                stratagems = math.floor((165 - (timer / 60)) / val);
            else
                stratagems = math.floor((240 - (timer / 60)) / val);
            end
            return stratagems;
        end
    end
    return 0;
end

function TryUseAbility(ability, target)
    local abilityResource = AshitaCore:GetResourceManager():GetAbilityByName(ability, 0);
    if not AshitaCore:GetMemoryManager():GetPlayer():HasAbility(abilityResource.Id) then
        return false;
    end
    if GetBuffActive(16) then -- Amnesia
        return false
    end

    if (abilityResource.RecastTimerId == 231) then
        if (GetStratagemCount() == 0) then
            return false;
        end
    elseif GetAbilityRecast(abilityResource.RecastTimerId) ~= 0 then
        return false;
    end

    AshitaCore:GetChatManager():QueueCommand(0, ('/ja "%s" %u'):fmt(abilityResource.Name[1], AshitaCore:GetMemoryManager():GetEntity():GetServerId(target)));
    mActionTimer = os.time() + 1;
    return true;
end

function IsAbiityReady(ability)
    local abilityResource = AshitaCore:GetResourceManager():GetAbilityByName(ability, 0);
    if not AshitaCore:GetMemoryManager():GetPlayer():HasAbility(abilityResource.Id) then
        return false;
    end
    if GetBuffActive(16) then -- Amnesia
        return false
    end

    if (abilityResource.RecastTimerId == 231) then
        if (GetStratagemCount() == 0) then
            return false;
        end
    elseif GetAbilityRecast(abilityResource.RecastTimerId) ~= 0 then
        return false;
    end
    return true;
end

function CancelBuff(buffId)
    if GetBuffActive(buffId) then
        local packet = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
        packet[5] = buffId % 256;
        packet[6] = math.floor(buffId / 256);
        AshitaCore:GetPacketManager():AddOutgoingPacket(0xF1, packet);
    end
end

function CancelUtsu()
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
    for _,buff in pairs(buffs) do
      if (buff == 66) then
        CancelBuff(66);
      elseif (buff == 444) then
        CancelBuff(444);
      elseif (buff == 445) then
        CancelBuff(445);
      elseif (buff == 446) then
        CancelBuff(446);
      end
    end
end

function CheckIfStand(mp)
    local MyIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    local myStatus = AshitaCore:GetMemoryManager():GetEntity():GetStatus(MyIndex);
    local myMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMPPercent(0);
    if (myStatus == 33 and myMp >= mp) then
        AshitaCore:GetChatManager():QueueCommand(1, '/heal');
        mActionTimer = os.time() + 1;
        return true;
    end
    return false;
end

function GetMemberHpByName(name)
    for i = 0,5,1 do
        local memberIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(i);
        if (memberIndex ~= 0) then
        if (AshitaCore:GetMemoryManager():GetParty():GetMemberName(i) == name) then
            return AshitaCore:GetMemoryManager():GetParty():GetMemberHPPercent(i);
        end
        end
    end
    return 0;
end

function GetMemberHppByName(name)
    for i = 0,5,1
    do
        local memberIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(i);
        if (memberIndex ~= 0) then
            if (AshitaCore:GetMemoryManager():GetParty():GetMemberName(i) == name) then
                return AshitaCore:GetMemoryManager():GetParty():GetMemberHPPercent(i);
            end
        end
    end
    return 0;
end

function GetMemberMpByName(name)
    for i = 0,5,1
    do
        local memberIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(i);
        if (memberIndex ~= 0) then
        if (AshitaCore:GetMemoryManager():GetParty():GetMemberName(i) == name) then
            return AshitaCore:GetMemoryManager():GetParty():GetMemberMPPercent(i);
        end
        end
    end
    return 0;
end

function GetMemberTP(name)
    for i = 0,5,1
    do
        local memberIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(i);
        if (memberIndex ~= 0) then
        if (AshitaCore:GetMemoryManager():GetParty():GetMemberName(i) == name) then
            return AshitaCore:GetMemoryManager():GetParty():GetMemberTP(i)
        end
        end
    end
    return 0;
end

function GetPlayerIndex(name, testIndex)
    local ppEntity = AshitaCore:GetMemoryManager():GetEntity();
    local ppParty = AshitaCore:GetMemoryManager():GetParty();

    --Check stored index first so you don't have to keep searching..
    if testIndex then
        local renderBytes = ppEntity:GetRenderFlags0(testIndex);
        if (bit.band(renderBytes, 0x200) ~= 0) and (bit.band(renderBytes, 0x4000) == 0) then
            if ppEntity:GetName(testIndex) == name then
                return testIndex;
            end
        end
    end

    local myZone = ppParty:GetMemberZone(0);

    --Check party first since it's less calculation..
    for i = 0,5 do
        if ppParty:GetMemberName(i) == name then
            if ppParty:GetMemberZone(i) == myZone then
                local index = ppParty:GetMemberTargetIndex(i);
                local renderBytes = ppEntity:GetRenderFlags0(index);
                if (bit.band(renderBytes, 0x200) ~= 0) and (bit.band(renderBytes, 0x4000) == 0) then
                    return index;
                else
                    return 0;
                end        
            else
                return 0;
            end
        end
    end

    --Check entity array..
    for i = 0x400,0x700 do
        local renderBytes = ppEntity:GetRenderFlags0(i);
        if (bit.band(renderBytes, 0x200) ~= 0) and (bit.band(renderBytes, 0x4000) == 0) then
            if ppEntity:GetName(i) == name then
                return i;
            end
        end
    end

    return 0;
end

function GetPartyMemberIndex(partyIndex)
    local ppParty = AshitaCore:GetMemoryManager():GetParty();
    local myZone = ppParty:GetMemberZone(0);
    if ppParty:GetMemberZone(partyIndex) == myZone then
        local index = ppParty:GetMemberTargetIndex(partyIndex);
        local renderBytes = AshitaCore:GetMemoryManager():GetEntity():GetRenderFlags0(index);
        if (bit.band(renderBytes, 0x200) ~= 0) and (bit.band(renderBytes, 0x4000) == 0) then
            return index;
        end
    end
    return 0;
end

local idMap = T{};
function GetNameFromId(id)
    local name = idMap[id];
    if name then
        return name;
    end
    
    local entMgr = AshitaCore:GetMemoryManager():GetEntity();
    
    --Check entity array..
    for i = 0x400,0x700 do
        if entMgr:GetServerId(i) == id then
            local name = entMgr:GetName(i);
            idMap[id] = name;
            return name;
        end
    end
end

function TryKeepUpSSBlink(blinkToggle, ssToggle)
    local MyIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    if not GetBuffActive(statusEffect.BLINK) then
        if blinkToggle then
            if CheckJobLevels('Blink') then
                if (CheckIfStand(100)) then
                    return;
                end
                if (TryCastSpell('Blink', MyIndex)) then
                 return;
                end
            end
        end
    end
    if not GetBuffActive(statusEffect.STONESKIN) then
        if ssToggle then
            if CheckJobLevels('Stoneskin') then
                if (CheckIfStand(100)) then
                    return;
                end
                if (TryCastSpell('Stoneskin', MyIndex)) then
                    return;
                end
            end
        end
    end
end

function GetBuffsByPartyIndex(partyIndex)
    if (partyIndex == 0) then
        local buffs = T{};
        local myBuffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
        for _,buff in pairs(myBuffs) do
            if buff ~= -1 then
                buffs:append(buff);
            end
        end
        return buffs; 
    end

    if (partyIndex < 0) or (partyIndex > 5) then
        return T{};
    end

    local party = AshitaCore:GetMemoryManager():GetParty()
    local memberId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(partyIndex);
    if (memberId == 0) then
        return T{};
    end

    for i = 0,4,1 do
        if (party:GetStatusIconsServerId(i) == memberId) then
            local icons_lo = party:GetStatusIcons(i);
            local icons_hi = party:GetStatusIconsBitMask(i);
            local buffs = T{};

            for j = 0,31,1 do
                local high_bits;
                if j < 16 then
                    high_bits = bit.lshift(bit.band(bit.rshift(icons_hi, 2 * j), 3), 8);
                else
                    local buffer = math.floor(icons_hi / 0xFFFFFFFF);
                    high_bits = bit.lshift(bit.band(bit.rshift(buffer, 2 * (j - 16)), 3), 8);
                end
                local buffId = icons_lo[j+1] + high_bits;
                if (buffId ~= 255) then
                    buffs[#buffs + 1] = buffId;
                end
            end

            return buffs;
        end
    end

    return T{};
end

function GetBuffsByTargetIndex(targetIndex)
    local party = AshitaCore:GetMemoryManager():GetParty()
    if (targetIndex == AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0)) then
        local buffs = T{};
        local myBuffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
        for _,buff in pairs(myBuffs) do
            if buff ~= -1 then
                buffs:append(buff);
            end
        end
        return buffs; 
    end

    if (targetIndex == 0) then
        return T{};
    end

    for i = 0,4,1 do
        if (party:GetStatusIconsTargetIndex(i) == targetIndex) then
            local icons_lo = party:GetStatusIcons(i);
            local icons_hi = party:GetStatusIconsBitMask(i);
            local buffs = T{};

            for j = 0,31,1 do
                local high_bits;
                if j < 16 then
                    high_bits = bit.lshift(bit.band(bit.rshift(icons_hi, 2 * j), 3), 8);
                else
                    local buffer = math.floor(icons_hi / 0xFFFFFFFF);
                    high_bits = bit.lshift(bit.band(bit.rshift(buffer, 2 * (j - 16)), 3), 8);
                end
                local buffId = icons_lo[j+1] + high_bits;
                if (buffId ~= 255) then
                    buffs[#buffs + 1] = buffId;
                end
            end

            return buffs;
        end
    end

    return T{};
end

function HasStatusEffectByTargetIndex(target, effect)
    local buffs = GetBuffsByTargetIndex(target)
    if buffs:contains(effect) then
        return true
    end
    return false
end

function TryCastNa()
    local naList = {
        { statusEffect.PETRIFICATION, 'Stona'},
        { statusEffect.DEFENSE_DOWN, 'Erase'},
        { statusEffect.MAGIC_DEF_DOWN, 'Erase'},
        { statusEffect.MAX_HP_DOWN, 'Erase'},
        { statusEffect.SLOW, 'Erase'},
        { statusEffect.ELEGY, 'Erase'},
		{ statusEffect.PARALYSIS, 'Paralyna'},
		{ statusEffect.SILENCE, 'Silena'},
		{ statusEffect.CURSE_I, 'Cursna'},
        { statusEffect.DOOM, 'Cursna'},
        { statusEffect.BLINDNESS, 'Blindna'},
        { statusEffect.POISON, 'Poisona'},
		{ statusEffect.VIRUS, 'Viruna'},
        { statusEffect.PLAGUE, 'Viruna'},
        { statusEffect.BIO, 'Erase'},
        { statusEffect.WEIGHT, 'Erase'},
        { statusEffect.ATTACK_DOWN, 'Erase'},
        { statusEffect.MAX_MP_DOWN, 'Erase'},
        { statusEffect.SLEEP_I, 'Cure'},
        { statusEffect.SLEEP_II, 'Cure'},
        { statusEffect.LULLABY, 'Cure'},
        { statusEffect.ACCURACY_DOWN, 'Erase'},
        { statusEffect.REQUIEM, 'Erase'},
	}
	-- for i = 1, 4 do
    for i = 0, 5 do
		local targetIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(i);
		if (targetIndex ~= 0) and (IsCharmed(targetIndex) == false) then
			local playerName = AshitaCore:GetMemoryManager():GetParty():GetMemberName(i)
			if (playerName ~= 'Miyu') then
                local spell = ''
                -- Use -na spell for corresponding status effect
                for v,effect in pairs(naList) do
                    if HasStatusEffectByTargetIndex(targetIndex,effect[1]) then
                        spell = effect[2]
                        if not IsInCastRange(targetIndex) then
                            if (os.time() > mChatTimer) and (IsInVisionRange(targetIndex)) then
                                local TargetName = AshitaCore:GetMemoryManager():GetEntity():GetName(targetIndex)
                                AshitaCore:GetChatManager():QueueCommand(0, ('/p %s is too far away to na!'):fmt(TargetName))
                                mChatTimer = os.time() + 5;
                                return false
                            end
                        end
                        if (CheckIfStand(50)) then
                            return true
                        end
                        if (IsCharmed(targetIndex) == false) then
                            if CheckJobLevels(spell) and (TryCastSpell(spell, targetIndex)) then
                                return true
                            end
                        end
                    end
                end
			end
		end
	end
    return false
end

function TryCastNaMiyu()
    local naList = {
        { statusEffect.PETRIFICATION, 'Stona'},
        { statusEffect.DEFENSE_DOWN, 'Erase'}, 
        { statusEffect.MAGIC_DEF_DOWN, 'Erase'},
        { statusEffect.MAX_HP_DOWN, 'Erase'},
        { statusEffect.SLOW, 'Erase'},
        { statusEffect.ELEGY, 'Erase'},
        { statusEffect.PARALYSIS, 'Paralyna'},
        { statusEffect.SILENCE, 'Silena'},
        { statusEffect.CURSE_I, 'Cursna'},
        { statusEffect.DOOM, 'Cursna'},
        { statusEffect.VIRUS, 'Viruna'},
        { statusEffect.PLAGUE, 'Viruna'},
        { statusEffect.BIO, 'Erase'},
        { statusEffect.WEIGHT, 'Erase'},
        { statusEffect.ATTACK_DOWN, 'Erase'},
        { statusEffect.MAX_MP_DOWN, 'Erase'},
		{ statusEffect.ENMITY_DOWN, 'Erase'},
        { statusEffect.SLEEP_I, 'Cure'},
        { statusEffect.SLEEP_II, 'Cure'},
        { statusEffect.LULLABY, 'Cure'},
        { statusEffect.ACCURACY_DOWN, 'Erase'},
        { statusEffect.REQUIEM, 'Erase'},
    }
    local miyuIndex = GetPlayerIndex('Miyu')
    -- Use -na spell for corresponding status effect
	local spell = ''
    for i,effect in pairs(naList) do
        if HasStatusEffectByTargetIndex(miyuIndex,effect[1]) then
            spell = effect[2]
            if not IsInCastRange(miyuIndex) then
                if (os.time() > mChatTimer) and (IsInVisionRange(miyuIndex)) then
                    local TargetName = AshitaCore:GetMemoryManager():GetEntity():GetName(miyuIndex)
                    AshitaCore:GetChatManager():QueueCommand(0, ('/p %s is too far away to na!'):fmt(TargetName))
                    mChatTimer = os.time() + 5;
                end
                return false
            end
            if (CheckIfStand(50)) then
                return true
            end
            if (IsCharmed(miyuIndex) == false) then
                if CheckJobLevels(spell) and (TryCastSpell(spell, miyuIndex)) then
                    return true
                end
            end
        end
    end
	return false
end

function GetTargetValue(index)
    local ent = AshitaCore:GetMemoryManager():GetEntity();
    if ent:GetRawEntity(index) == nil then
      return 0;
    end
    local renderflags = ent:GetRenderFlags0(index);
    if bit.band(renderflags, 0x200) ~= 0x200 or bit.band(renderflags, 0x4000) ~= 0 then
      return 0;
    end
    local value = 1;
    if ent:GetStatus(index) == 1 then
      value = value + 20;
    end
    local nameValue = mobValues[ent:GetName(index)];
    if nameValue == nil then
      nameValue = 0;
    end
value = value + nameValue;
   local distance = GetDistanceToIndex(index);
   if (distance > 20.5) then
    return 0;
   else
    value = value + ((40 - distance) * 1);
   end
    return value;
end

function ValidateEntity(index)
    local ent = AshitaCore:GetMemoryManager():GetEntity();
    if ent:GetRawEntity(index) == nil then
        return false;
    end
    
    local renderflags = ent:GetRenderFlags0(index);
    if bit.band(renderflags, 0x200) ~= 0x200 or bit.band(renderflags, 0x4000) ~= 0 then
        return false;
    end
    
    --Do you want things that aren't engaged..?
    if ent:GetStatus(index) ~= 1 then
        return false;
    end

    --Cheaper to use the squared value already in memory(20 yalms squared = 400.  adjust if needed.)
    if ent:GetDistance(index) > 400.0 then
        return false;
    end
    
    return true;
end

function GetNumberOfEntities()
    local count = 0;
    for i = 1,1023,1 do
        if ValidateEntity(i) then
            count = count + 1;
        end
    end
    return count;
end

function GetAdditonalEntities(entityIndex)
    for i = 1,1023,1 do
        if ValidateEntity(i) and (entityIndex ~= i) then
            return i
        end
    end
    return false
end

mobValues = {
    ['Greater Colibri'] = 8,
    ['Wivre'] = 4,
}

local function GetTargetValue(index)
    local ent = AshitaCore:GetMemoryManager():GetEntity();
    if ent:GetRawEntity(index) == nil then
        return 0;
    end
    local renderflags = ent:GetRenderFlags0(index);
    if bit.band(renderflags, 0x200) ~= 0x200 or bit.band(renderflags, 0x4000) ~= 0 then
        return 0;
    end
    local value = 1;
    if ent:GetStatus(index) == 1 then
        value = value + 20;
    end
    local nameValue = mobValues[ent:GetName(index)];
    if nameValue == nil then
        nameValue = 0;
    end
    value = value + nameValue;
    local distance = GetDistanceToIndex(index);
    if distance > 40 then
        return 0;
    else
        value = value + ((40 - distance) * 1);
    end
    return value;
  end

function FindEntity()
    local BestEntity = {
      index = 0;
      value = 0;
    };
    for i = 1,1023,1 do
        local value = GetTargetValue(i);
        if value > BestEntity.value then
            BestEntity.value = value;
            BestEntity.index = i;
            return BestEntity.index;
        end
    end
end

function GetModelID(entityIndex)
    local modelId = GetAshitaCore():GetMemoryManager():GetEntity():GetLookHair(entityIndex) 
    return modelId
end

local thTable = {};

function GetTHLevel(entityIndex)
    local val = thTable[entityIndex];
    if val == nil then
        return 0
    end
    return val
end

local printBuffsCustomPacketTimer = os.time()
function PrintBuffs(entityIndex)
    local buffs = GetEntitiesBuffs(entityIndex)

    if next(buffs) == nil then
        -- print("No buffs found for this entity.")
        return
    end

    if (os.time() > printBuffsCustomPacketTimer) then
        for index, buff in ipairs(buffs) do
            print(string.format("Buff #%d - Id: %u, Power: %u, Expiration: %.2f seconds", 
                index, buff.Id, buff.Power, buff.Expiration - os.clock()))
                printBuffsCustomPacketTimer = os.time() + 10
        end
    end
end

buffTable = {};
function GetEntitiesBuffs(entityIndex)
    local buffs = buffTable[entityIndex];
    if buffs == nil then
        return T{};  -- Return an empty table if no buffs are found
    end
    return buffs;
end

-- Accepts a single buffId or a table of buffIds
function GetEntitiesBuffsById(entityIndex, buffIds)
    local buffs = GetEntitiesBuffs(entityIndex)
    if not buffs then
        return false
    end

    -- Normalize to table
    if type(buffIds) ~= 'table' then
        buffIds = { buffIds }
    end

    for _, buff in ipairs(buffs) do
        for _, id in ipairs(buffIds) do
            if buff.Id == id then
                return true
            end
        end
    end

    return false
end

function HandleStatusEffectsPacket(e)
    -- Parse Subtype
    local subType = struct.unpack('L', e.data, 0x04 + 1) -- Subtype
    if subType ~= 1 then
        --print("Unexpected Subtype:", subType)
        return
    end

    -- Parse Entity Information
    local mobId = struct.unpack('L', e.data, 0x08 + 1)    -- Entity ID (uint32)
    local mobIndex = struct.unpack('H', e.data, 0x0C + 1) -- Entity targid (uint16)
    local thLevel = struct.unpack('H', e.data, 0x0E + 1)  -- Treasure Hunter Level (uint16)

    -- Store TH Level
    thTable[mobIndex] = thLevel
    --print(string.format("Mob ID: %d, Mob Index: %d, TH Level: %d", mobId, mobIndex, thLevel))

    -- Parse Status Effects
    local offset = 0x10 -- Start of status effects
    local buffs = {}

    while offset + 8 <= e.size do
        local statusId = struct.unpack('H', e.data, offset + 1)         -- Status ID (uint16)
        local power = struct.unpack('H', e.data, offset + 3)            -- Power (uint16)
        local remainingTimeMs = struct.unpack('L', e.data, offset + 5)  -- Remaining Time (uint32)
        local expiration = os.clock() + (remainingTimeMs / 1000)        -- Convert to seconds
        
        -- Add the parsed buff to the list
        table.insert(buffs, {
            Id = statusId,
            Power = power,
            Expiration = expiration
        })

        -- Print debug information
        --print(string.format("Buff ID: %d, Power: %d, Remaining Time (s): %.2f", statusId, power, remainingTimeMs / 1000))

        -- Move to the next buff (8 bytes per entry)
        offset = offset + 8
    end

    -- Store Buffs
    buffTable[mobIndex] = buffs
    --print(string.format("Stored %d buffs for mob index %d", #buffs, mobIndex))
end

local trustProgression = {
    melee = 0,
    ranged = 0,
    tank = 0,
    caster = 0,
    healer = 0,
    support = 0
}

openTrustProgressionUI = false
function HandleTrustProgressionPacket(e)
    local zone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);

    trustProgression.melee = struct.unpack('!L', e.data, 0x08)
    trustProgression.ranged = struct.unpack('!L', e.data, 0x0C)
    trustProgression.tank = struct.unpack('!L', e.data, 0x10)
    trustProgression.caster = struct.unpack('!L', e.data, 0x14)
    trustProgression.healer = struct.unpack('!L', e.data, 0x18)
    trustProgression.support = struct.unpack('!L', e.data, 0x1C)

    if (zone == 244) then -- Upper Jeuno
        openTrustProgressionUI = true
    end

    -- print(string.format('Melee: %d', trustProgression.melee))
    -- print(string.format('Ranged: %d', trustProgression.ranged))
    -- print(string.format('Tank: %d', trustProgression.tank))
    -- print(string.format('Caster: %d', trustProgression.caster))
    -- print(string.format('Healer: %d', trustProgression.healer))
    -- print(string.format('Support: %d', trustProgression.support))
    -- print("Incoming trust progression packet - edit HandleTrustProgressionPacket in shiyolibs to remove this message!")

    -- Block the packet as it's not used by the client.
    e.blocked = true
end

function HandleAnotherNewPacket(e)
end

local packetHandlers = { -- Should be global? (remove local)
    [1] = HandleStatusEffectsPacket,
    [2] = HandleTrustProgressionPacket,
    [3] = HandleAnotherNewPacket,
};

ashita.events.register('packet_in', 'custom_packet_cb', function(e)
    if (e.id == 0xFF) then
        local subType = struct.unpack('L', e.data, 0x04+1);
        local handler = packetHandlers[subType];
        if type(handler) == 'function' then
            handler(e);
        end
        e.blocked = true;
    end
end);

-- For Flags
-- local offset = 0x0C;
-- local buffs = T{};
-- while (offset < e.size) do
--     buffs:append({
--         Id = struct.unpack('H', e.data, offset+1),
--         Power = struct.unpack('H', e.data, offset+3),
--         Expiration = os.clock() + (struct.unpack('L', e.data, offset+5) / 1000),
--         Flags = struct.unpack('L', e.data, offset+9),
--     });
--     offset = offset + 12;
-- end

function GetTrustProgressionData()
    return trustProgression
end

function GetWeaponStyle()
    local twoHandedSkills = T{ 4, 6, 7, 8, 10, 12 };
    local oneHandedSkills = T{ 2, 3, 5, 9, 11 };
    local equip = gData.GetEquipment()
    local mainHandSkill = 0;
    if equip.Main and equip.Main.Resource then
        mainHandSkill = equip.Main.Resource.Skill;
    end
    if mainHandSkill == 1 then
        return 'H2H';
    elseif twoHandedSkills:contains(mainHandSkill) then
        return '2H';
    elseif oneHandedSkills:contains(mainHandSkill) then
        local offHandSkill = 0;
        if equip.Sub and equip.Sub.Resource then
            offHandSkill = equip.Sub.Resource.Skill;
        end
        if oneHandedSkills:contains(offHandSkill) then
            return 'DW'
        else
            return 'SHIELD'
        end
    else
        return 'Unknown';
    end
end

function GetWeaponType()
    local equip = gData.GetEquipment()
    local mainHandSkill = 0;
    if equip.Main and equip.Main.Resource then
        mainHandSkill = equip.Main.Resource.Skill;
    end
    local skills = T{
        {2, 'DAGGER'},
        {3, 'SWORD'},
        {4, 'GREAT SWORD'},
        {5, 'AXE'},
        {6, 'GREAT AXE'},
        {7, 'SCYTHE'},
        {8, 'POLEARM'},
        {9, 'KATANA'},
        {10, 'GREAT KATANA'},
        {11, 'CLUB'},
        {12, 'STAFF'},
    }
    for _, combatSkills in pairs (skills) do
        if (mainHandSkill == combatSkills[1]) then
            return combatSkills[2]
        end
    end
end

function GetRangedWeaponType()
    local skills = T{
        [25] = 'ARCHERY',
        [26] = 'MARKSMANSHIP',
        [27] = 'THROWING'
    };
    local equip = gData.GetEquipment()
    if equip.Range and equip.Range.Resource then
        return skills[equip.Range.Resource.Skill];
    end
end

-- Daytime: 6:00 - 18:00
-- Nighttime: 18:00 - 6:00
-- Dusk to Dawn: 17:00 - 7:00
function IsDayTime()
    local environment = gData.GetEnvironment()
    if (environment.Time >= 6) or (environment.Time <= 18) then
        return true
    end
    return false
end

function IsNightTime()
    local environment = gData.GetEnvironment()
    if (environment.Time >= 18) or (environment.Time <= 6) then
        return true
    end
    return false
end

function IsDuskToDawn()
    local environment = gData.GetEnvironment()
    if (environment.Time >= 17) or (environment.Time <= 7) then
        return true
    end
    return false
end

function GetRegion()
    local zone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    if zone > 45 and zone < 80 then
      return 'ToAU'
    elseif zone > 79 and zone < 100 then
      return 'WoTG'
    elseif T{136, 137, 138, 164, 171, 175}:contains(zone) then
      return 'WoTG'
    elseif zone > 184 and zone < 189 then
      return 'Dynamis'
    elseif zone > 38 and zone < 43 then
      return 'Dynamis'
    elseif zone > 133 and zone < 136 then
      return 'Dynamis'
    elseif T{177, 178, 180, 181, 130}:contains(zone) then
      return 'Sky'
    elseif zone > 32 and zone < 39 then
      return 'Sea'
    else
      return 'Zilart'
    end
end

function HasTwoHourActive()
    if GetAnyBuffActive({44, 46, 47, 48, 49, 50, 51, 52, 54, 55, 126, 163, 166, 376, 377, 490, 491, 494, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505, 507, 508, 509, 513, 522  }) then
        return true
    end

    return false
end

function IsInAssault()
    local zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    local assaultZone = {
        [55] = true,
        [56] = true,
        [60] = true,
        [63] = true,
        [64] = true,
        [66] = true,
        [67] = true,
        [69] = true,
        [73] = true,
        [74] = true,
        [75] = true,
        [76] = true,
        [77] = true,
        [78] = true,
    }

    return assaultZone[zoneId]
end

local zonesWithMounts = {
    [2] = true,
    [4] = true,
    [5] = true,
    [7] = true,
    [24] = true,
    [25] = true,
    [51] = true,
    [52] = true,
    [61] = true,
    [70] = true,
    [79] = true,
    [81] = true,
    [82] = true,
    [83] = true,
    [84] = true,
    [88] = true,
    [89] = true,
    [90] = true,
    [91] = true,
    [95] = true,
    [96] = true,
    [97] = true,
    [98] = true,
    [100] = true,
    [101] = true,
    [102] = true,
    [103] = true,
    [104] = true,
    [105] = true,
    [106] = true,
    [107] = true,
    [108] = true,
    [109] = true,
    [110] = true,
    [111] = true,
    [112] = true,
    [113] = true,
    [114] = true,
    [115] = true,
    [116] = true,
    [117] = true,
    [118] = true,
    [119] = true,
    [120] = true,
    [121] = true,
    [123] = true,
    [124] = true,
    [125] = true,
    [126] = true,
    [127] = true,
    [128] = true,
    [136] = true,
    [137] = true,
    [182] = true,
    [260] = true,
    [261] = true,
    [262] = true,
    [263] = true,
    [265] = true,
    [266] = true,
    [267] = true
}

function canUseMount(zoneId)
    return zonesWithMounts[zoneId]
end

local WeaponskillGorgets =
T{
    [1] = T{ Gorget = 'Flame Gorget', Weaponskills = T{
        'Arching Arrow', 'Ascetic\'s Fury', 'Asuran Fists', 'Atonement', 'Blade: Shun', 'Burning Blade', 'Camlan\'s Torment', 'Decimation', 'Detonator', 
        'Drakesbane', 'Dulling Arrow', 'Empyreal Arrow', 'Final Heaven', 'Flaming Arrow', 'Full Swing', 'Garland of Bliss', 'Heavy Shot', 
        'Hexa Strike', 'Hot Shot', 'Insurgency', 'Knight\'s of Round', 'Last Stand', 'Mandalic Stab', 'Mistral Axe', 'Metatron Torment', 'Realmrazer', 
        'Red Lotus Blade', 'Scourge', 'Shijin Spiral', 'Sniper Shot', 'Spinning Attack', 'Spinning Axe', 'Tachi: Kagero', 'Tachi: Kasha', 'Upheaval', 
        'Wheeling Thrust' }
    },
    [2] = T{ Gorget = 'Soil Gorget', Weaponskills = T{
        'Aeolian Edge', 'Asuran Fists', 'Avalanche Axe', 'Blade: Ei', 'Blade: Ku', 'Blade: Retsu', 'Blade: Ten', 'Calamity', 'Catastrophe', 
        'Crescent Moon', 'Dancing Edge', 'Entropy', 'Evisceration', 'Exenterator', 'Expiacion', 'Fast Blade', 'Hard Slash', 'Impulse Drive', 
        'Iron Tempest', 'King\'s Justice', 'Leaden Salute', 'Mercy Stroke', 'Nightmare Scythe', 'Omniscience', 'Primal Rend', 'Pyrrhic Kleos', 
        'Rampage', 'Requiescat', 'Resolution', 'Retribution', 'Savage Blade', 'Seraph Blade', 'Shattersoul', 'Shining Blade', 'Sickle Moon', 
        'Slice', 'Spinning Axe', 'Spinning Scythe', 'Spiral Hell', 'Stardiver', 'Stringing Pummel', 'Sturmwind', 'Swift Blade', 'Tachi: Enpi', 
        'Tachi: Jinpu', 'Tachi: Rana', 'Trueflight', 'Viper Bite', 'Vorpal Blade', 'Vorpal Scythe', 'Wasp Sting' }
    },
    [3] = T{ Gorget = 'Aqua Gorget', Weaponskills = T{
        'Atonement', 'Blade: Teki', 'Brainshaker', 'Circle Blade', 'Cross Reaper', 'Dark Harvest', 'Entropy', 'Quietus', 'Death Blossom', 
        'Decimation', 'Expiacion', 'Full Break', 'Garland of Bliss', 'Gate of Tartarus', 'Gust Slash', 'Ground Strike', 'Last Stand', 
        'Mordant Rime', 'Namas Arrow', 'Piercing Arrow', 'Pyrrhic Kleos', 'Rudra\'s Storm', 'Primal Rend', 'Raging Rush', 'Retribution', 
        'Ruinator', 'Shadow of Death', 'Shadowstitch', 'Shadowstrike', 'Shark Bite', 'Shattersoul', 'Shoulder Tackle', 'Sidewinder', 'Slug Shot', 
        'Smash Axe', 'Spinning Slash', 'Spinning Scythe', 'Spiral Hell', 'Split Shot', 'Starburst', 'Steel Cyclone', 'Sturmwind', 'Sunburst', 
        'Tachi: Koki', 'Tachi: Rana', 'Trueflight', 'Vidofnir', 'Vorpal Thrust' }
    },
    [4] = T{ Gorget = 'Breeze Gorget', Weaponskills = T{
        'Aeolian Edge', 'Asuran Fists', 'Avalanche Axe', 'Blade: Jin', 'Blade: Kamu', 'Blade: Metsu', 'Blade: To', 'Camlan\'s Torment', 'Corona', 
        'Cyclone', 'Dancing Edge', 'Death Blossom', 'Dragon Kick', 'Earth Crusher', 'Exenterator', 'Expiacion', 'Gale Axe', 'Ground Strike', 
        'Gust Slash', 'King\'s Justice', 'Mordant Rime', 'Raging Axe', 'Randgrith', 'Red Lotus Blade', 'Resolution', 'Ruinator', 'Savage Blade', 
        'Shark Bite', 'Shell Crusher', 'Sidewinder', 'Slug Shot', 'Spinning Slash', 'Steel Cyclone', 'Stingray', 'Tachi: Jinpu', 'Tachi: Kasha', 
        'Tachi: Yukikaze', 'Tornado Kick', 'True Strike', 'Victory Smite', 'Vidofnir' }
    },
    [5] = T{ Gorget = 'Snow Gorget', Weaponskills = T{
        'Blade: To', 'Blast Arrow', 'Blast Shot', 'Cross Reaper', 'Death Blossom', 'Expiacion', 'Freezebite', 'Frostbite', 'Full Break', 
        'Gate of Tartarus', 'Ginsenk', 'Guillotine', 'Quietus', 'Impulse Drive', 'Last Stand', 'Mordant Rime', 'Namas Arrow', 'Piercing Arrow', 
        'Raging Rush', 'Shadow of Death', 'Shattersoul', 'Skullbreaker', 'Smash Axe', 'Spiral Hell', 'Steel Cyclone', 'Tachi: Gekko', 
        'Tachi: Hobaku', 'Tachi: Jinpu', 'Tachi: Koki', 'Tachi: Rana', 'Tachi: Yukikaze', 'Tornado Kick', 'Vidofnir' }
    },
    [6] = T{ Gorget = 'Thunder Gorget', Weaponskills = T{
        'Aeolian Edge', 'Apex Arrow', 'Armor Break', 'Avalanche Axe', 'Black Halo', 'Blade: Chi', 'Blade: Jin', 'Blade: Ku', 'Blade: Metsu', 
        'Blast Shot', 'Camlan\'s Torment', 'Circle Blade', 'Corona', 'Cyclone', 'Death Blossom', 'Dragon Kick', 'Earth Crusher', 'Exenterator', 
        'Freezebite', 'Gale Axe', 'Ground Strike', 'Gust Slash', 'King\'s Justice', 'Mordant Rime', 'Raging Axe', 'Randgrith', 'Resolution', 
        'Ruinator', 'Savage Blade', 'Shark Bite', 'Shining Blade', 'Shoulder Tackle', 'Sidewinder', 'Sickle Moon', 'Slice', 'Spinning Attack', 
        'Spinning Axe', 'Spinning Scythe', 'Stingray', 'Swift Blade', 'Tachi: Gotetsu', 'Tachi: Goten', 'Tachi: Hobaku', 'Tachi: Koki', 
        'Tachi: Shoha', 'Thunder Thrust', 'Tornado Kick', 'True Strike', 'Victory Smite', 'Vidofnir', 'Vorpal Blade', 'Vorpal Scythe', 
        'Weapon Break' }
    },
    [7] = T{ Gorget = 'Light Gorget', Weaponskills = T{
        'Apex Arrow', 'Arching Arrow', 'Ascetic\'s Fury', 'Atonement', 'Blade: Chi', 'Blade: Ku', 'Blade: Retsu', 'Blade: Ten', 'Blast Shot', 
        'Camlan\'s Torment', 'Decimation', 'Detonator', 'Double Thrust', 'Drakesbane', 'Dulling Arrow', 'Empyreal Arrow', 'Evisceration', 'Final Heaven', 
        'Flaming Arrow', 'Garland of Bliss', 'Heavy Shot', 'Hexa Strike', 'Hot Shot', 'Howling Fist', 'Insurgency', 'Knight\'s of Round', 'Leaden Salute', 
        'Last Stand', 'Mandalic Stab', 'Mistral Axe', 'Omniscience', 'Piercing Arrow', 'Power Slash', 'Realmrazer', 'Red Lotus Blade', 'Requiescat', 
        'Resolution', 'Seraph Blade', 'Shadow of Death', 'Shark Bite', 'Shattersoul', 'Sidewinder', 'Slav Shot', 'Spiral Hell', 'Spinning Slash', 
        'Spinning Scythe', 'Stardiver', 'Tachi: Enpi', 'Tachi: Gekko', 'Tachi: Hobaku', 'Tachi: Jinpu', 'Tachi: Kasha', 'Tachi: Rana', 
        'Tachi: Shoha', 'Trueflight', 'Vorpal Thrust', 'Wheeling Thrust' }
    },
    [8] = T{ Gorget = 'Shadow Gorget', Weaponskills = T{
        'Aeolian Edge', 'Arching Arrow', 'Ascetic\'s Fury', 'Atonement', 'Blade: Chi', 'Blade: Ei', 'Blade: Ku', 'Blade: Jin', 'Blade: Metsu', 
        'Blast Arrow', 'Blast Shot', 'Brainshaker', 'Circle Blade', 'Cross Reaper', 'Dark Harvest', 'Decimation', 'Detonator', 'Double Thrust', 
        'Drakesbane', 'Dulling Arrow', 'Empyreal Arrow', 'Entropy', 'Evisceration', 'Exenterator', 'Fast Blade', 'Final Heaven', 'Flaming Arrow', 
        'Full Swing', 'Garland of Bliss', 'Gust Slash', 'Heavy Shot', 'Hexa Strike', 'Hot Shot', 'Howling Fist', 'Insurgency', 'Ken\'s Edge', 
        'Leaden Salute', 'Last Stand', 'Mandalic Stab', 'Mercy Stroke', 'Requiescat', 'Resolution', 'Seraph Blade', 'Shadow of Death', 
        'Shark Bite', 'Shattersoul', 'Sidewinder', 'Sniper Shot', 'Spiral Hell', 'Spinning Slash', 'Spinning Scythe', 'Swift Blade', 
        'Tachi: Enpi', 'Tachi: Jinpu', 'Tachi: Kasha', 'Tachi: Rana', 'Tachi: Shoha', 'Upheaval' }
    }
}

function GetMatchingGorget(weaponskillName)
    for _,v in pairs(WeaponskillGorgets) do
        if v.Weaponskills:contains(weaponskillName) then
            if (v.Gorget ~= nil) then
                if HasItemInEquippableInventory(GetItemByName(v.Gorget)) then
                    return v.Gorget;
                end
            end
        end
    end

    return 'Unknown'
end

function CheckWSGorget()
    -- Handle ele gorgets
    local action = gData.GetAction()
    for _,v in pairs(WeaponskillGorgets) do
        if (v.Weaponskills:contains(action.Name)) then
            if HasItemInEquippableInventory(GetItemByName(GetMatchingGorget(action.Name))) then
                gFunc.Equip('Neck', GetMatchingGorget(action.Name))
            end
        end
    end
end

function JseEarringCheck()
    local earringData =
    {
        { Job = job.SMN, Earring = 'Conjurer\'s Earring' },
        { Job = job.DRG, Earring = 'Drake Earring' },
        { Job = job.PLD, Earring = 'Guardian Earring' },
        { Job = job.MNK, Earring = 'Kampfer Earring' },
        { Job = job.WHM, Earring = 'Medicine Earring' },
        { Job = job.BRD, Earring = 'Minstrel\'s Earring' },
        { Job = job.THF, Earring = 'Rogue\'s Earring' },
        { Job = job.SAM, Earring = 'Ronin Earring' },
        { Job = job.NIN, Earring = 'Shinobi Earring' },
        { Job = job.DRK, Earring = 'Slayer\'s Earring' },
        { Job = job.WAR, Earring = 'Soldier\'s Earring' },
        { Job = job.BLM, Earring = 'Sorcerer\'s Earring' },
    }

    local mJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob()
    local HPP = AshitaCore:GetMemoryManager():GetParty():GetMemberHPPercent(0)
    local TP = AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0)

    for _, jse in ipairs(earringData) do
        if
            (HPP <= 25) and
            (TP <= 1000) and
            (mJob == jse.Job)
        then
            if HasItemInEquippableInventory(GetItemByName(jse.Earring)) then
                gFunc.Equip('Ear2', jse.Earring)
            end
        end
    end
end

function BatEarringsCheck()
	if GetBuffActive(5) then 
		gFunc.Equip('Ear1', 'Bat Earring')
		gFunc.Equip('Ear2', 'Bat Earring')
	end
end

function TempestBeltCheck()
        local environment = gData.GetEnvironment()
    if (environment.WeatherElement == 'Wind') and HasItemInEquippableInventory(GetItemByName('Tempest Belt')) then
        gFunc.Equip('Waist', 'Tempest Belt')
    end
end

function FatalityBeltCheck()
    if HasTwoHourActive() and HasItemInEquippableInventory(GetItemByName('Fatality Belt')) then
        gFunc.Equip('Waist', 'Tempest Belt')
    end
end


local ElementalObiTable = 
{
    Fire    = 'Karin Obi',
    Ice     = 'Hyorin Obi',
    Wind    = 'Furin Obi',
    Earth   = 'Dorin Obi',
    Thunder = 'Rairin Obi',
    Water   = 'Suirin Obi',
    Light   = 'Korin Obi',
    Dark    = 'Anrin Obi'
}

function EquipElementalObi(element)
    local obi = ElementalObiTable[element]
    if (obi ~= nil) then
        local environment = gData.GetEnvironment()
        if (environment.WeatherElement == element) or (environment.DayElement == element) then
            if HasItemInEquippableInventory(GetItemByName(obi)) then
                gFunc.Equip('Waist', obi)
            end
        end
    end
end

function ObiCheck()
    local action = gData.GetAction();
    local environment = gData.GetEnvironment()
    if (environment.WeatherElement == action.Element) or (environment.DayElement == action.Element) then
        if HasItemInEquippableInventory(GetItemByName('Hachirin-no-Obi')) then
            gFunc.Equip('Waist', 'Hachirin-no-Obi');
        else
            EquipElementalObi(action.Element)
        end
    end
end

function SandstormCheck()
    local environment = gData.GetEnvironment()
    if (environment.WeatherElement == 'Earth') and HasItemInEquippableInventory(GetItemByName('Desert Boots')) then
        gFunc.Equip('Feet', 'Desert Boots')
    end
end

function ParadeGorgetCheck()
    local zone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    local hpp = AshitaCore:GetMemoryManager():GetParty():GetMemberHPPercent(0);
    local mpp = AshitaCore:GetMemoryManager():GetParty():GetMemberMPPercent(0)

    if not canUseMount(zone) then
        if (hpp > 85) and (mpp <= 75) then
            gFunc.Equip('Neck', 'Parade Gorget')
        end
    end
end

function HerculesRingCheck()
    local hpp = AshitaCore:GetMemoryManager():GetParty():GetMemberHPPercent(0);

    if (hpp <= 50) then
        gFunc.Equip('Ring2', 'Hercules\' Ring')
    end
end

function EarthRingCheck(ring)
    -- Unused now that I have Nasatya's
    -- local action = gData.GetAction()
    -- if (ring == nil) then
    --     ring = 'Ring1'
    -- end
    -- if
    --     (getDayElement() ~= 'Earth')
    --     and HasItemInEquippableInventory(GetItemByName('Earth Ring'))
    -- then
    --     gFunc.Equip(ring, 'Earth Ring')
    -- end
end

function WaterRingCheck(ring)
    local action = gData.GetAction()
    if (ring == nil) then
        ring = 'Ring1'
    end
    if
        (getDayElement() ~= 'Water')
        and (action.Skill == 'Healing Magic')
        and HasItemInEquippableInventory(GetItemByName('Water Ring'))
    then
        gFunc.Equip(ring, 'Water Ring')
    end
end

function UggyPendantCheck()
    local myMpp = AshitaCore:GetMemoryManager():GetParty():GetMemberMPPercent(0)
    if (myMpp <= 50) and HasItemInEquippableInventory(GetItemByName('Uggalepih Pendant')) then
        gFunc.Equip('Neck', 'Uggalepih Pendant')
    end
end

function FenrirsEarringCheck(isRanged)
    if isRanged then
        if IsNightTime() and HasItemInEquippableInventory(GetItemByName('Fenrir\'s Earring')) then
            gFunc.Equip('Ear1', 'Fenrir\'s Earring')
        end
    else
        if not IsNightTime() and HasItemInEquippableInventory(GetItemByName('Fenrir\'s Earring')) then
            gFunc.Equip('Ear1', 'Fenrir\'s Earring')
        end
    end
end

function AketonCheck()
    local currentZone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    if (currentZone >= 238 and currentZone <= 242) and HasItemInEquippableInventory(GetItemByName('Federation Aketon')) then
        gFunc.Equip('Body', 'Federation Aketon')
    end
end

function FlagellantCheck()
    if GetBuffActive(statusEffect.PARALYSIS) and HasItemInEquippableInventory(GetItemByName('Flagellant\'s Rope')) then
		gFunc.Equip('Waist', 'Flagellant\'s Rope')
	end
end

function OpoNeckCheck()
    if GetBuffActive(statusEffect.SLEEP_I) and HasItemInEquippableInventory(GetItemByName('Opo-Opo Necklace')) then
		gFunc.Equip('Neck', 'Opo-Opo Necklace')
	end
end

function RacingSilksCheck()
    if GetBuffActive(statusEffect.MOUNTED) and HasItemInEquippableInventory(GetItemByName('Purple Race Silks')) then
        gFunc.Equip('Body', 'Purple Race Silks')
    end
end

function ArguteLoafersCheck()
    local action = gData.GetAction();
    local environment = gData.GetEnvironment()
    if (environment.WeatherElement == action.Element) and
     GetAnyBuffActive({statusEffect.CELERITY, statusEffect.ALACRITY})
     and HasItemInEquippableInventory(GetItemByName('Argute Loafers')) then
        gFunc.Equip('Feet', 'Argute Loafers');
    end
end

function BrachyuraCheck()
    if (os.clock() < proShellIncoming) and HasItemInEquippableInventory(GetItemByName('Brachyura Earring')) then
        gFunc.Equip('Ear1', 'Brachyura Earring')
    end
end

function UnregisterBrachryuaCheck()
    ashita.events.unregister('packet_in', 'brachyura_packet_cb');
end

function RepublicCircletCheck()
    local region = GetRegion()
    if (region == 'Zilart') then
        gFunc.Equip('Head', 'Republic Circlet')
    end
end

function ResentmentCapeCheck()
    if (region == 'Zilart') then
        gFunc.Equip('Back', 'Resentment Cape');
    end
end

function ImperialRingCheck(ring)
    if (ring == nil) then
        ring = 'Ring2'
    end
    if IsInAssault() then
        gFunc.Equip(ring, 'Imperial Ring');
    end
end

function StormRingCheck(ring)
    if (ring == nil) then
        ring = 'Ring2'
    end
    if IsInAssault() then
        gFunc.Equip(ring, 'Storm Ring');
    end
end

function IsPartyMemberInRange(index)
    local ptMgr = AshitaCore:GetMemoryManager():GetParty();
    for i = 0,5 do
        if (ptMgr:GetMemberIsActive(i)) then
            local memberIndex = ptMgr:GetMemberTargetIndex(i);
            if (index == memberIndex) then
                local distance = AshitaCore:GetMemoryManager():GetEntity():GetDistance(index);
                return math.sqrt(distance) < 10;
            end
       end
   end
   return false;
 end

proShellIncoming = 0;
function RegisterBrachyuraCheck()
    ashita.events.register('packet_in', 'brachyura_packet_cb', function (e)
        if (e.id == 0x028) then
            local packet = ParseActionPacket(e);
            local myId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);

            -- Check for Prot / Shell being cast on me
            for _,target in pairs(packet.Targets) do
                if (target.Id == myId) then
                    for _,action in pairs(target.Actions) do
                        if (packet.Type == 8) then
                            for v = 43, 52 do -- Prot and Shell
                                if (action.Param == v) then
                                    proShellIncoming = os.clock() + 8; -- How long to keep the earring equipped for
                                end
                            end
                        end
                    end
                end

                -- Check for allies casting Protectra / Shellra
                if (packet.Type == 8) then
                    if IsPartyMemberInRange(packet.UserIndex) then
                        for _,action in pairs(target.Actions) do
                            for v = 125, 134 do -- Protectra and Shellra
                                if (action.Param == v) then
                                    proShellIncoming = os.clock() + 8; -- How long to keep the earring equipped for
                                end
                            end
                        end
                    end
                end     
            end
        end
    end);
end

function CheckCurrentMP(mp)
    local myMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);
    if myMp > mp then
      return true
    end
    return false
end

function CancelUtsu()
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
    for _,buff in pairs(buffs) do
      if (buff == 66) then
        CancelBuff(66);
      elseif (buff == 444) then
        CancelBuff(444);
      elseif (buff == 445) then
        CancelBuff(445);
      elseif (buff == 446) then
        CancelBuff(446);
      end
    end
end

function GetGrimoireType()
	local action = gData.GetAction();
  if GetBuffActive(statusEffect.LIGHT_ARTS) or GetBuffActive(statusEffect.ADDENDUM_WHITE) then
    return 'White Magic';
  elseif GetBuffActive(statusEffect.DARK_ARTS) or GetBuffActive(statusEffect.ADDENDUM_BLACK) then
    return 'Black Magic';
  else
    return 'None';
  end
end


function LightArts()
    if GetAnyBuffActive({358, 401}) then
        return true
    end
    return false
end

function DarkArts()
    if GetAnyBuffActive({359, 402}) then
        return true
    end
    return false
end

function SublimationCheck()
  local level = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel()
  if (level < 59) then -- So Helm isn't constantly displaced
    return false
  end
	if GetBuffActive(187) == false or GetBuffActive(188) == true then -- Sublimation not ticking or Sublimation fully charged 
		return true
	else
		return false
	end
end

function getDayElement()
    local environment = gData.GetEnvironment()
    return environment.DayElement
end

function BroadcastToggles()
end

function IsCCed()
    local ccEffects = T{ statusEffect.TERROR, statusEffect.STUN, statusEffect.PETRIFICATION }
    return GetAnyBuffActive(ccEffects)
end

function RunTowardEntity(index)
    local MyIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    local entityPosX = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(index);
    local entityPosY = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(index);
    local myPosX = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(MyIndex);
    local myPosY = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(MyIndex);
    local xDiff = entityPosX - myPosX;
    local yDiff = entityPosY - myPosY;
    if (CheckIfStand(50)) then
        return true
    end
    AshitaCore:GetMemoryManager():GetAutoFollow():SetFollowDeltaX(xDiff);
    AshitaCore:GetMemoryManager():GetAutoFollow():SetFollowDeltaY(yDiff);
    AshitaCore:GetMemoryManager():GetAutoFollow():SetIsAutoRunning(1);
end

function RunAwayFromEntity(index)
    local MyIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    local entityPosX = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(index);
    local entityPosY = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(index);
    local myPosX = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(MyIndex);
    local myPosY = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(MyIndex);
    local xDiff = myPosX - entityPosX;
    local yDiff = myPosY - entityPosY;
    if (CheckIfStand(50)) then
        return true
    end
    AshitaCore:GetMemoryManager():GetAutoFollow():SetFollowDeltaX(xDiff);
    AshitaCore:GetMemoryManager():GetAutoFollow():SetFollowDeltaY(yDiff);
    AshitaCore:GetMemoryManager():GetAutoFollow():SetIsAutoRunning(1);
end

function DistanceEntityToPoint(index, x, y)
    local entityPosX = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(index);
    local entityPosY = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(index);
    local squared = ((entityPosX - x) ^ 2) + ((entityPosY - y) ^ 2);
    return math.sqrt(squared);
end

function RunToPoint(x, y, distance)
    local MyIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    local myPosX = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(MyIndex);
    local myPosY = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(MyIndex);
    local xDiff = x - myPosX;
    local yDiff = y - myPosY;
    local ptDistance = math.sqrt((xDiff ^ 2) + (yDiff ^ 2));
    if (ptDistance > distance) then
        if (CheckIfStand(50)) then
			return true
		end
    AshitaCore:GetMemoryManager():GetAutoFollow():SetFollowDeltaX(xDiff);
    AshitaCore:GetMemoryManager():GetAutoFollow():SetFollowDeltaY(yDiff);
    AshitaCore:GetMemoryManager():GetAutoFollow():SetIsAutoRunning(1);
    else
    AshitaCore:GetMemoryManager():GetAutoFollow():SetIsAutoRunning(0);
    end
end

function GetClaimStatus(EntityIndex)
    if AshitaCore:GetMemoryManager():GetEntity():GetClaimStatus(EntityIndex) == 0 then
       return false
   else
       return true
   end
end

function GetDistanceSquared(pt1, pt2)
   local xDiff = pt2.x - pt1.x;
   local yDiff = pt2.y - pt1.y;
   return (xDiff ^ 2) + (yDiff ^ 2);
end

function GetDistanceBetweenIndices(index, index2)
    local pt1 = {
        x = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(index);
        y = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(index);
    };
    local pt2 = {
        x = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(index2);
        y = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(index2);
    };
    return math.sqrt(GetDistanceSquared(pt1, pt2));
end

function GetDistanceToPlayer(playerName)
    local targetIndex = GetPlayerIndex(playerName);
    return math.sqrt(AshitaCore:GetMemoryManager():GetEntity():GetDistance(targetIndex));
end

function GetDistanceToIndex(index)
    local myIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0)
    return GetDistanceBetweenIndices(index, myIndex);
end

 function StopRunning()
	return AshitaCore:GetMemoryManager():GetAutoFollow():SetIsAutoRunning(0);
end

 function GetCampPos()
	local MyIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
	CampX = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(MyIndex)
	CampY = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(MyIndex)
	return CampX, CampY
end

function DoWeaponSkill(ws, target)
    if IsMonster(target) then
        AshitaCore:GetChatManager():QueueCommand(0, ('/ws "%s" %u'):fmt(ws, AshitaCore:GetMemoryManager():GetEntity():GetServerId(target)));
        mActionTimer = os.time() + 1;
        CloseSC = false
    end
end

function AutoRAToggle(toggle)
    if not autoRa and toggle then
        AshitaCore:GetChatManager():QueueCommand(-1, ('/addon load autora'));
        autoRa = true
    elseif autoRa and not toggle then
        AshitaCore:GetChatManager():QueueCommand(-1, ('/addon unload autora'));
        autoRa = false
    end
end

function IsPetAlive()
    local myIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    local petIndex = AshitaCore:GetMemoryManager():GetEntity():GetPetTargetIndex(myIndex);
    if (petIndex == 0) or AshitaCore:GetMemoryManager():GetEntity():GetHPPercent(petIndex) == 0 then
        return false
    end
    return true
end
-- TODO: Return true and fix bots with this function
function KeepUpJuice()
    local MyIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0)
    if GetBuffActive(statusEffect.REFRESH) == false then
        if TryUseItem('Pineapple Juice', MyIndex) then
            return -- add true
        end
    end
    -- return false
end

function KeepUpEnspell()
    local MyIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0)
    if GetAnyBuffActive({94, 95, 96, 97, 98, 99}) == false then
        if CheckJobLevels('Enblizzard') and (TryCastSpell('Enblizzard', MyIndex)) then
            return;
        elseif CheckJobLevels('Enthunder') and (TryCastSpell('Enthunder', MyIndex)) then
            return;
        elseif CheckJobLevels('Enfire') and (TryCastSpell('Enfire', MyIndex)) then
            return;
        elseif CheckJobLevels('Enaero') and (TryCastSpell('Enaero', MyIndex)) then
            return;
        elseif CheckJobLevels('Enwater') and (TryCastSpell('Enwater', MyIndex)) then
            return;
        elseif CheckJobLevels('Enstone') and (TryCastSpell('Enstone', MyIndex)) then
            return;
        end
    end
end

function IsPlayerLoaded(MyIndex)
    for i = 1,4,1 do
        local memberName = GetPartyMemberIndex(i)
        if (os.time() > mChatTimer) and (IsInVisionRange(memberName) == false) then
            AshitaCore:GetChatManager():QueueCommand(0, ('/p A player is not loaded or in another zone.'))
            mChatTimer = os.time() + 90;
            return true
        end
    end
    return false
end

function SendSpellMsg(target, spell)
    AshitaCore:GetChatManager():QueueCommand(-1, ('/ms sendto %s /ma "%s" Kitori'):fmt(target, spell));
end

function IsInCastRange(target) -- Needs to be "if not IsInCastRange(Target)" to work properly
    local TargetDistance = math.sqrt(AshitaCore:GetMemoryManager():GetEntity():GetDistance(target))
    if (TargetDistance > 20.4) and (TargetDistance < 50) then
        return false
    end
    return true
end

function IsInVisionRange(target)
    if (target ~= 0) then
        return true
    end
    return false
end

function HasDot()
	if GetAnyBuffActive({3, 23, 128, 129, 130, 131, 132, 133, 134, 135, 186, 187, 192, 540}) then
		return true
	end
	return false
end

function IsCharmed(targetIndex)
    local RenderFlag = AshitaCore:GetMemoryManager():GetEntity():GetRenderFlags3(targetIndex)
    if (bit.band(RenderFlag, 0x2000) ~= 0) then
        return true
    end
    return false
end

function IsDead(name)
    if (name ~= nil) then
        local hpp = GetMemberHppByName(name)
        if (hpp < 1) then
            return true
        end
    else
        local myHP = AshitaCore:GetMemoryManager():GetParty():GetMemberHP(0);
        if (myHP < 1) then
            return true
        end
    end
    return false
end

function UtsusemiActive(entityIndex)
    if (HasStatusEffectByTargetIndex(entityIndex,statusEffect.COPY_IMAGE) == false) and (HasStatusEffectByTargetIndex(entityIndex,statusEffect.COPY_IMAGE_2) == false) and
    (HasStatusEffectByTargetIndex(entityIndex,statusEffect.COPY_IMAGE_3) == false) and (HasStatusEffectByTargetIndex(entityIndex,statusEffect.COPY_IMAGE_4) == false) then
        return false
    end
    return true
end

function IsAsleep(entityIndex)
    if HasStatusEffectByTargetIndex(entityIndex, statusEffect.SLEEP_I) or HasStatusEffectByTargetIndex(entityIndex, statusEffect.SLEEP_II) or
    HasStatusEffectByTargetIndex(entityIndex, statusEffect.LULLABY) then
        return true
    end
    return false
end

function IsZombie(entityIndex)
    if HasStatusEffectByTargetIndex(entityIndex, statusEffect.CURSE_II) then
        return true
    end
    return false
end

function IsMonster(entityIndex)
    if (GetShortFlags(entityIndex) == 0x10) then
        return true
    end
  return false
end

function IsTrust(entityIndex)
    local fullFlags = AshitaCore:GetMemoryManager():GetEntity():GetSpawnFlags(entityIndex);
    return fullFlags == 4366
end

function ParamToName(param)
    local weaponskill = AshitaCore:GetResourceManager():GetAbilityById(param);
    if weaponskill then
      return weaponskill.Name[1];
    else
      return 'Unknown';
    end
end
-- i.e: if (ParamToName(actionParam) == 'Swift Blade') then

function ResolveIndex(valueTable)
  if (valueTable.Index == nil) or (AshitaCore:GetMemoryManager():GetEntity():GetName(valueTable.Index) ~= valueTable.name) then
    valueTable.Index = GetPlayerIndex(valueTable.name);
  end
  return valueTable.Index;
end

function GetIndexFromId(serverId)
    local index = bit.band(serverId, 0x7FF);
    local entMgr = AshitaCore:GetMemoryManager():GetEntity();
    if (entMgr:GetServerId(index) == serverId) then
        return index;
    end
    for i = 1,2303 do
        if entMgr:GetServerId(i) == serverId then
            return i;
        end
    end
    return 0;
end

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
    actionPacket.UserIndex = GetIndexFromId(actionPacket.UserId);
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
        target.Index = GetIndexFromId(target.Id);
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

function GetEvent(e)
    local eventId, eventParams, eventType;
    if (e.id == 0x32) or (e.id == 0x33) then
        eventId = struct.unpack('H', e.data, 0x0C + 1);
        eventType = 'Start'
        if (e.id == 0x33) then        
            eventParams = T{};
            for i = 1,8 do
                eventParams[i] = struct.unpack('L', e.data, 0x4C + (i * 4) + 1);
            end
        end
    elseif (e.id == 0x34) then
        eventId = struct.unpack('H', e.data, 0x2C + 1);
        eventType = 'Start'
        eventParams = T{};
        for i = 1,8 do
            eventParams[i] = struct.unpack('L', e.data, 0x04 + (i * 4) + 1);
        end
    elseif (e.id == 0x00A) and (struct.unpack('H', e.data, 0x64 + 1) ~= 0) then
        eventId = struct.unpack('H', e.data, 0x64 + 1);
        eventType = 'Start'
    elseif (e.id == 0x5C) then -- Event update
        eventId = 0
        eventType = 'Update'
        eventParams = T{};
        for i = 1,8 do
            eventParams[i] = struct.unpack('I', e.data, (0x04 * i) + 1);
        end
    elseif (e.id == 0x2A) then -- Zone text msgID
        eventId = bit.band(struct.unpack('H', e.data, 0x1A + 1), 0x7FFF);
        eventType = 'MsgID'
        eventParams = T{};
        for i = 1,4 do
            eventParams[i] = struct.unpack('L', e.data, (i * 4) + 0x04 + 0x01);
        end
    end
    return eventId, eventParams, eventType;
end

function InjectRangedAttackPacket()
    local targetIndex;
    local targetId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);
    if (targetIndex > 0) and (targetId > 0) then
        local packet = struct.pack('LLHHHHLLL', 0, targetId, targetIndex, 0x10, 0, 0, 0, 0, 0);
        AshitaCore:GetPacketManager():AddOutgoingPacket(0x1A, packet:totable());
    end
end

function ResistSetCheck()
    if (varhelper.GetCycle('Resist') ~= 'None') then
        gFunc.EquipSet(varhelper.GetCycle('Resist'))
    end
end

--[[ 
Unsure if I broke this. Before changing this is how it was for PLD
function ResistSetCheck()
    if (varhelper.GetCycle('Resist') ~= 'None') then
        gFunc.EquipSet('Resist_' .. varhelper.GetCycle('Resist'))
    end
end
]]

-- Global Commands
function CheckGlobalCommands(args)
    if (args[1] == 'disable') then
        local isDisabled = false;
        for i = 1,16 do
            if gState.Disabled[i] == true then
                isDisabled = true;
            end
        end
        if isDisabled then
            AshitaCore:GetChatManager():QueueCommand(-1, '/lac enable')
        else
            AshitaCore:GetChatManager():QueueCommand(-1, '/lac disable')
        end
    end

	if (args[1] == 'tp') then
		varhelper.AdvanceCycle('TPVariant')
		gFunc.Message('TP Set: ' .. varhelper.GetCycle('TPVariant'))
	end

	if (args[1] == 'idle') then
		varhelper.AdvanceCycle('IdleVariant')
		gFunc.Message('Idle Set: ' .. varhelper.GetCycle('IdleVariant'))
	end

	if (args[1] == 'pdt') then
		varhelper.AdvanceToggle('PDT')
        if varhelper.GetToggle('PDT') then
            gFunc.LockSet(sets.PDT, 3)
            gFunc.Message('PDT Set enabled!')
        else
            gFunc.Message('PDT Set disabled!')
        end
	end
	if (args[1] == 'mdt') then
		varhelper.AdvanceToggle('MDT')
        if varhelper.GetToggle('MDT') then
            gFunc.LockSet(sets.MDT, 3)
            gFunc.Message('MDT Set enabled!')
        else
            gFunc.Message('MDT Set disabled!')
        end
	end
	if (args[1] == 'eva') then
		varhelper.AdvanceToggle('EVA')
        if varhelper.GetToggle('EVA') then
            gFunc.LockSet(sets.EVA, 3)
            gFunc.Message('EVA Set enabled!')
        else
            gFunc.Message('EVA Set disabled!')
        end
	end
end

-- Interface / Menu checks to hide addons
local pGameMenu = ashita.memory.find('FFXiMain.dll', 0, "8B480C85C974??8B510885D274??3B05", 16, 0);
local pEventSystem = ashita.memory.find('FFXiMain.dll', 0, "A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3", 0, 0);
local pInterfaceHidden = ashita.memory.find('FFXiMain.dll', 0, "8B4424046A016A0050B9????????E8????????F6D81BC040C3", 0, 0);
local function GetMenuName()
    local subPointer = ashita.memory.read_uint32(pGameMenu);
    local subValue = ashita.memory.read_uint32(subPointer);
    if (subValue == 0) then
        return '';
    end
    local menuHeader = ashita.memory.read_uint32(subValue + 4);
    local menuName = ashita.memory.read_string(menuHeader + 0x46, 16);
    return string.gsub(menuName, '\x00', '');
end

local function GetEventSystemActive()
    if (pEventSystem == 0) then
        return false;
    end
    local ptr = ashita.memory.read_uint32(pEventSystem + 1);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr) == 1);

end

local function GetInterfaceHidden()
    if (pEventSystem == 0) then
        return false;
    end
    local ptr = ashita.memory.read_uint32(pInterfaceHidden + 10);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr + 0xB4) == 1);
end

local hideMenus = T{
    ['menu    map0    '] = true,
    ['menu    mapv2   '] = true,
    ['menu    mapv3   '] = true,
    ['menu    mapframe'] = true,
    ['menu    scanlist'] = true,
    ['menu    maplist '] = true,
    ['menu    equip   '] = true,
    ['menu    inventor'] = true,
    ['menu    itemctrl'] = true,
    ['menu    magic   '] = true,
    ['menu    magselec'] = true,
    ['menu    abiselec'] = true,
    ['menu    ability '] = true,
    ['menu    mount   '] = true,
    ['menu    menuwind'] = true,
    ['menu    cmbmenu '] = true,
    ['menu    cmbhlst '] = true,
    ['menu    mgcmenu '] = true,
    ['menu    link5   '] = true,
    ['menu    cnqfram '] = true,
    ['menu    socialme'] = true,
    ['menu    missionm'] = true,
    ['menu    miss00  '] = true,
    ['menu    quest00 '] = true,
    ['menu    evitem  '] = true,
    ['menu    mogcont '] = true,
    ['menu    bank    '] = true,
    ['menu    itmsortw'] = true,
    ['menu    itmsort2'] = true,
    ['menu    bazaar  '] = true,
    ['menu    shop    '] = true,
    ['menu    shopbuy '] = true,
    ['menu    shopsell'] = true,
    ['menu    comment '] = true,
    ['menu    mcrmenu '] = true,
    ['menu    mcrselec'] = true,
    ['menu    mcrselop'] = true,
    ['menu    mcres20 '] = true,
    ['menu    mcresmn '] = true,
    ['menu    statcom2'] = true,
    ['menu    inspect '] = true,
    ['menu    fulllog '] = true,
    ['menu    loot    '] = true,
    ['menu    lootope '] = true,
    ['menu    mogdoor '] = true,
    ['menu    myroom  '] = true,
    ['menu    mogext  '] = true,
    ['menu    storage '] = true,
    ['menu    storage2'] = true,
    ['menu    mogpost '] = true,
    ['menu    jobchang'] = true,
    ['menu    jobcselu'] = true,
    ['menu    post1   '] = true,
    ['menu    stringdl'] = true,
    ['menu    auc1    '] = true,
    ['menu    auc2    '] = true,
    ['menu    auc3    '] = true,
    ['menu    auchisto'] = true,
    ['menu    moneyctr'] = true,
    ['menu    aucweapo'] = true,
    ['menu    aucarmor'] = true,
    ['menu    aucmagic'] = true,
    ['menu    aucmater'] = true,
    ['menu    aucfood '] = true,
    ['menu    aucmeals'] = true,
    ['menu    auclist '] = true,
    ['menu    aucitem '] = true,
    ['menu    aucammo '] = true,
    ['menu    comyn   '] = true,
    ['menu    trade   '] = true,
    ['menu    handover'] = true,
    ['menu    iuse    '] = true,
    ['menu    sortyn  '] = true,
    ['menu    scresult'] = true,
    ['menu    scoption'] = true,
    ['menu    party3  '] = true,
    ['menu    partywin'] = true,
    ['menu    fulllog' ] = true,
    ['menu    cnqframe'] = true,
    ['menu    configwi'] = true,
    ['menu    conf2win'] = true,
    ['menu    cfilter'] = true,
    ['menu    conftxtc'] = true,
    ['menu    cconf5m'] = true,
    ['menu    conf3win'] = true,
    ['menu    conf6win'] = true,
    ['menu    conf12wi'] = true,
    ['menu    conf13wi'] = true,
    ['menu    fxfilter'] = true,
    ['menu    conf7'   ] = true,
    ['menu    conf4'   ] = true,
    ['menu    merit1'  ] = true,
    ['menu    merit2'  ] = true,
    ['menu    meritcat'] = true,
    ['menu    merit2ca'] = true,
    ['menu    jbpcat'  ] = true,
    ['menu    inline'  ] = true,
};

isZoning = (AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0) == 0);

ashita.events.register('packet_in', 'zoning_packet_cb', function (e)
   if e.id == 0x00B then
       isZoning = true;
   elseif e.id == 0x00A then
       isZoning = false;
   end
end);

function ShouldHideUI()
    -- Not logged in
    if (AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0) == 0) then
        return true;
    end

    if (GetEventSystemActive()) then
        return true;
    end

    if hideMenus[GetMenuName()] then
        return true;
    end

    if (GetInterfaceHidden()) then
        return true;
    end

    if (isZoning) then
        return true
    end

    return false;
end

-- Moves items around inventory, unused, untested
local function MoveItem(originContainer, originIndex, destinationContainer, count, destinationIndex)
    if not count then
        count = 1;
    end
    if not destinationIndex then
        destinationIndex = 81;
    end

    local packet = struct.pack('LLBBBB', 0, count, originContainer, destinationContainer, originIndex, destinationIndex);
    AshitaCore:GetPacketManager():AddOutgoingPacket(0x29, packet:totable());
end