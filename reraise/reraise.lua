addon.name      = 'reraise';
addon.author    = 'Shiyo';
addon.version   = '1.0.0.4';
addon.desc      = 'Reminds you to keep up RR';
addon.link      = 'https://ashitaxi.com/';

require('common');
require ('shiyolibs')
statusEffect = require('statuseffect')
local settings = require('settings')
job = require('job')
local statusEffect = require('statuseffect')
local mChatTimer = 0

local pEventSystem = ashita.memory.find('FFXiMain.dll', 0, "A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3", 0, 0);

 -- False = not in CS
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

ashita.events.register('d3d_present', 'present_cb', function ()
    local mJob = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob()
    local sJob = AshitaCore:GetMemoryManager():GetPlayer():GetSubJob()
	local mJobLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel()
	local sJobLevel = AshitaCore:GetMemoryManager():GetPlayer():GetSubJobLevel()
    local currentZone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);

    -- Check if in a City
    if (currentZone >= 230 and currentZone <= 252) then
        return
    end
    local cityZones = T{ 26, 48, 50, 53, 80, 87, 94, 256, 257, 280, 281, 284 };
    if (cityZones:contains(currentZone)) then
        return;
    end

    -- Check if in a CS
    if GetEventSystemActive() then
        return
    end

    if not GetBuffActive(statusEffect.RERAISE) then
         -- Check for main job
        if (mJob == job.WHM or mJob == job.SCH) then
            if (mJobLevel >= 35) then
                if (os.time() > mChatTimer) then
                    AshitaCore:GetChatManager():QueueCommand(0, ('/p I don\'t have reraise active!'))
                    mChatTimer = os.time() + 30;
                end
            end
        end

        -- Check for sub job
        if (sJob == job.WHM or sJob == job.SCH) then
            if (sJobLevel >= 35) then
                if (os.time() > mChatTimer) then
                    AshitaCore:GetChatManager():QueueCommand(0, ('/p I don\'t have reraise active!'))
                    mChatTimer = os.time() + 30;
                end
            end
        end
    end
  end);