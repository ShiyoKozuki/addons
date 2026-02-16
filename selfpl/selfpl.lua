addon.name      = 'SelfPL';
addon.author    = 'Shiyo';
addon.version   = '0.1';
addon.desc      = 'Makes Kozumi able to PL me';
addon.link      = 'https://ashitaxi.com/';

require('common');
local mActionTimer = 0
local castFinished = 0
local mIsRunning = false
local hasHate = false
local RAStatusBolts = false
local AutoWS = false
local AutoFood = true
local AutoVoke = true
local PLvlMode = true


local StatusBolts = T{
  acid = T{
    timer = 0,
	duration = 60,
	wearmessage = 'Defense Down effect effect wears off.'
  }
};

local function HasItemInInventory(itemId)
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

local function GetAbilityRecast(abilityId)
  for i = 0,31,1
  do
    if (AshitaCore:GetMemoryManager():GetRecast():GetAbilityTimerId(i) == abilityId) then
      return AshitaCore:GetMemoryManager():GetRecast():GetAbilityTimer(i);
    end
  end
  return 1;
end

local function GetBuffActive(matchBuff)
  local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();    
  for _, buff in pairs(buffs) do
    if buff == matchBuff then
      return true;
    end
  end
  return false;
end

local function CheckJobLevels(spell)
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

local function TryCastSpell(spell, target)
  local spellResource = AshitaCore:GetResourceManager():GetSpellByName(spell, 0);
  if (AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(spellResource.Index) == 0) then
    AshitaCore:GetChatManager():QueueCommand(0, ('/ma "%s" %u'):fmt(spellResource.Name[1], AshitaCore:GetMemoryManager():GetEntity():GetServerId(target)));
    mActionTimer = os.time() + (spellResource.CastTime / 4) + 3;
	castFinished = os.time() + (spellResource.CastTime / 4) + 1
    return true;
  end
  return false;
end

local function TryUseAbility(ability, target)
  local abilityResource = AshitaCore:GetResourceManager():GetAbilityByName(ability, 0);
  if (GetAbilityRecast(abilityResource.RecastTimerId) == 0) then
    AshitaCore:GetChatManager():QueueCommand(0, ('/ja "%s" %u'):fmt(abilityResource.Name[1], AshitaCore:GetMemoryManager():GetEntity():GetServerId(target)));
    mActionTimer = os.time() + 1;
     return true;
  end
  return false;
end

local function TryUseItem(item, target)
  local itemResource = AshitaCore:GetResourceManager():GetItemByName(item , 0);
  if HasItemInInventory(itemResource.Id) then
    AshitaCore:GetChatManager():QueueCommand(0, ('/item "%s" %u'):fmt(itemResource.Name[1], AshitaCore:GetMemoryManager():GetEntity():GetServerId(target)));
    mActionTimer = os.time() + (itemResource.CastTime / 4) + 3;
	castFinished = os.time() + (itemResource.CastTime / 4) + 1
    return true;
  end
  return false;
end

local function CancelBuff(buffId)
  local packet = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
  packet[5] = buffId % 256;
  packet[6] = math.floor(buffId / 256);
  AshitaCore:GetPacketManager():AddOutgoingPacket(0xF1, packet);
end

local function CheckIfStand(mp)
  local myIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
  local myStatus = AshitaCore:GetMemoryManager():GetEntity():GetStatus(myIndex);
  local myMp = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0);
  if (myStatus == 33 and myMp > mp) then
    AshitaCore:GetChatManager():QueueCommand(1, '/heal');
    mActionTimer = os.time() + 1;
    return true;
  end
  return false;
end

local function GetMemberHpByName(name)
  for i = 0,5,1
  do
    local memberIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(i);
    if (memberIndex ~= 0) then
      if (AshitaCore:GetMemoryManager():GetParty():GetMemberName(i) == name) then
        return AshitaCore:GetMemoryManager():GetParty():GetMemberHP(i);
      end
    end
  end
  return 0;
end

local function GetPlayerIndex(name)
  for i = 0,5,1
  do
    local memberIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(i);
      if (memberIndex ~= 0) then
        if (AshitaCore:GetMemoryManager():GetParty():GetMemberName(i) == name) then
          return memberIndex;
        end
    end
  end
  for i = 1280,1791,1
  do
    local entityId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(i);
      if (entityId ~= 0) then
        if (AshitaCore:GetMemoryManager():GetEntity():GetName(i) == name) then
          return i;
        end
    end
  end
  return 0;
end

local function ProcessMovement()
    if (os.time() <= castFinished ) then
        return;
    end
	
	local miyuIndex = GetPlayerIndex('Shiyo');
	if miyuIndex == 0 then
		miyuIndex = GetPlayerIndex('Miyu');
	end
		if miyuIndex == 0 then 
			if (mIsRunning) then
				AshitaCore:GetMemoryManager():GetAutoFollow():SetIsAutoRunning(0);
				mIsRunning = false
			end
			return 
		end
	local myIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0)
	local playerPosX = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(miyuIndex);
	local playerPosY = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(miyuIndex);
	local myPosX = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionX(myIndex);
	local myPosY = AshitaCore:GetMemoryManager():GetEntity():GetLocalPositionY(myIndex);
	local xDiff = playerPosX - myPosX;
	local yDiff = playerPosY - myPosY;
	local xDiffTwo =  myPosX - playerPosX;
	local yDiffTwo =  myPosY - playerPosY;
	local distance =  math.sqrt((xDiff ^ 2) + (yDiff ^ 2));
    if (distance > 30)  then
        if (os.time() > mActionTimer) then
          AshitaCore:GetChatManager():QueueCommand(0, ('/p Help! Im too far away and stuck!'))
          mActionTimer = os.time() + 5;
        end
	elseif (distance > 11.3) then
		if (os.time() > mActionTimer) then
		  mActionTimer = os.time() + 1;
		end
	  AshitaCore:GetMemoryManager():GetAutoFollow():SetFollowDeltaX(xDiff);
	  AshitaCore:GetMemoryManager():GetAutoFollow():SetFollowDeltaY(yDiff);
	  AshitaCore:GetMemoryManager():GetAutoFollow():SetIsAutoRunning(1);
	  mIsRunning = true
	elseif (distance < 11.0) then
		if (os.time() > mActionTimer) then
	  mActionTimer = os.time() + 1;
		end
	  AshitaCore:GetMemoryManager():GetAutoFollow():SetFollowDeltaX(xDiffTwo);
	  AshitaCore:GetMemoryManager():GetAutoFollow():SetFollowDeltaY(yDiffTwo);
	  AshitaCore:GetMemoryManager():GetAutoFollow():SetIsAutoRunning(1);
	 mIsRunning = true
	else
	  AshitaCore:GetMemoryManager():GetAutoFollow():SetIsAutoRunning(0);
	  mIsRunning = false
	end
end

local function ProcessActions()
    --Stop if we are mid action
    if (os.time() <= mActionTimer) then
        return;
    end
    
    --Evaluate healing state..
    local myIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0)
    local currentlyHealing = (AshitaCore:GetMemoryManager():GetEntity():GetStatus(myIndex) == 33)
    local MP = AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0)
    local MPP = AshitaCore:GetMemoryManager():GetParty():GetMemberMPPercent(0)
	local miyuIndex = GetPlayerIndex('Shiyo');
	local shiyoEngaged = (AshitaCore:GetMemoryManager():GetEntity():GetStatus(miyuIndex) == 1);
	local enemyIndex = AshitaCore:GetMemoryManager():GetEntity():GetTargetedIndex(miyuIndex)
	local enemyId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(enemyIndex)
	local kitoriEngaged = (AshitaCore:GetMemoryManager():GetEntity():GetStatus(myIndex) == 1);
	local HP = AshitaCore:GetMemoryManager():GetParty():GetMemberHP(0)
	local HPP = AshitaCore:GetMemoryManager():GetParty():GetMemberHPPercent(0)
    local TP = AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0)
	local mJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
	local sJob = AshitaCore:GetMemoryManager():GetPlayer():GetSubJob();
	local mJobLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
	local sJobLevel = AshitaCore:GetMemoryManager():GetPlayer():GetSubJobLevel();
	--Remove statuses off self
	if GetBuffActive(9) or GetBuffActive(15) then  -- Curse and Doom 
		if TryUseItem('Holy Water', myIndex) then
            return
        end
	end
	if mJob == 13 or sJob == 13 then --Check if Ninja main or sub
		if GetBuffActive(66) then
			if GetBuffActive(6) then --Remove Silence before casting shadows
				if TryUseItem('Echo Drops', myIndex) then
					return
				end
			end
			if CheckJobLevels('utsusemi: ichi') and (TryCastSpell('utsusemi: ichi', myIndex)) then --Cast Ichi if at 1 shadow
				return;
			elseif CheckJobLevels('utsusemi: ni') and (TryCastSpell('utsusemi: ni', myIndex))  then--Cast ni if at 1 shadow and ichi is on cd
				return;				
			end
		end
		if GetBuffActive(66) == false and GetBuffActive(444) == false and GetBuffActive(445) == false then
			if GetBuffActive(6) then --Remove Silence before casting shadows
				if TryUseItem('Echo Drops', myIndex) then
					return
				end
			end
			if CheckJobLevels('utsusemi: ni') and (TryCastSpell('utsusemi: ni', myIndex))  then --Cast ni if at no shadows
				return;
			elseif CheckJobLevels('utsusemi: ichi') and (TryCastSpell('utsusemi: ichi', myIndex)) then	--Cast ichi if ni is down
				return;	
			end
		end
	end
	if PLvlMode then
		if HPP <= 50 and HPP > 0 then
			AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kozumi /ma "Cure II" Shiyo');
		elseif HPP <= 75 and HPP > 0 then
			AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kozumi /ma "Cure" Shiyo');
		end 
		if GetBuffActive(5) then 
			AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kozumi /ma "Blindna" Shiyo');
		end
		if GetBuffActive(3) then 
			AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kozumi /ma "Poisona" Shiyo');
		end
		if GetBuffActive(4) then 
			AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kozumi /ma "Paralyna" Shiyo');
		end
		if GetBuffActive(31) then 
			AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kozumi /ma "Viruna" Shiyo');
		end
	elseif PLvlMode == false then
		if GetBuffActive(5) then  -- Blindness
			if TryUseItem('Eye Drops', myIndex) then
				return
			end
		end
		if GetBuffActive(3) then  -- Poison
			if TryUseItem('Antidote', myIndex) then
				return
			end
		end
	end
		-- Keep up stances/buffs with durations longer than recast
		if GetBuffActive(33) == false then
			if TryUseAbility('Hasso', myIndex) then 
				return
			end
		end
	if (kitoriEngaged) then
		-- Provoke
		if AutoVoke then
			if TryUseAbility('Provoke', enemyIndex) then
				return
			end
		end
		--Keep up Food
		local foodBuffId = 251 
		if AutoFood then
			if GetBuffActive(foodBuffId) == false then 
				if TryUseItem('Sausage', myIndex) then
					return
				end
			end
		end
		--Buffs with durations longer than recast
		if GetBuffActive(405) == false then
			if TryUseAbility('retaliation', myIndex) then --Lowers movement speed so we don't want to cast it out of combat
				return
			end
		end
		--Keep up limited duration buffs
		if TryUseAbility('berserk', myIndex) then 
			return
		end
		if TryUseAbility('aggressor', myIndex) then
			return
		end
		--Use offensive JA's
		if TryUseAbility('jump', enemyIndex) then
			return
		end
	--WS at 1k+ TP
	if AutoWS then
		if (TP >= 1000) then
			if TryUseAbility('Warcry', myIndex) then
				return
			end
			AshitaCore:GetChatManager():QueueCommand(0, ('/ws "Tachi: Enpi" %u'):fmt(AshitaCore:GetMemoryManager():GetEntity():GetServerId(enemyIndex)));
				mActionTimer = os.time() + 1;
		end
	end
		if RAStatusBolts then --RA until status bolt procs, repeat once it fades
			for key, value in pairs(StatusBolts) do
				if (os.time() > value.timer) then
					AshitaCore:GetChatManager():QueueCommand(0, ('/ra %u'):fmt(AshitaCore:GetMemoryManager():GetEntity():GetServerId(enemyIndex)));
					return;
				end
			end
		end
	end
	--Engage Shiyo's target
	if (shiyoEngaged) then
		if (kitoriEngaged) then
			return;
		end
        AshitaCore:GetChatManager():QueueCommand(0, ('/attack %u'):fmt(AshitaCore:GetMemoryManager():GetEntity():GetServerId(enemyIndex)));
		hasHate = false
		mActionTimer = os.time() + 2;
	end
end

ashita.events.register('text_in', 'text_in_cb', function (e)
	if (string.match(e.message, 'misses Kitori')) or (string.match(e.message, 'hits Kitori for'))  then
		hasHate = true
    end
    for key, value in pairs(StatusBolts) do
		  if (string.match(e.message, 'Additional effect: Defense Down.')) then
			value.timer = os.time() + value.duration;
		  end
		  if (string.match(e.message, value.wearmessage)) then
			value.timer = os.time() - 1;
		  end
    end
end);





ashita.events.register('d3d_present', 'present_cb', function ()
   -- ProcessMovement();
    ProcessActions();
	
end);