addon.name      = 'MobAnimation';
addon.author    = 'Shiyo';
addon.version   = '1.0.0.0';
addon.desc      = 'Prints out mob animation IDs to a log file.';
addon.link      = 'https://ashitaxi.com/';

require('common');
require ('shiyolibs')
require('logmanager');
gLogManager:SetDirectory('AnimationIDs');
local chat = require('chat');
local imgui = require('imgui');       -- v4's gui lib
local settings = require('settings')
local statusEffect = require('statuseffect')
local job = require('job')

-------------------------------------------------------------------------------
-- Globals
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local function WriteAnimationId(mobName, skillId, animationId)
    local filePath = string.format('%slogs//AnimationIDs//AnimationIDs.txt', AshitaCore:GetInstallPath());
    local file = io.open(filePath, 'a');
    file:write(string.format('Mob: %s, Skill ID: %u, Animation ID: %u,\n', mobName, skillId, animationId));
    file:close();
end

ashita.events.register('packet_in', 'HandleIncomingPacket', function (e)
    --Check if it's an action packet..
    if (e.id == 0x28) then
      local actionPacket = ParseActionPacket(e);
        -- Mob Animation finish
        if (actionPacket.Type == 11) or (actionPacket.Type == 13) then
            for _,target in ipairs(actionPacket.Targets) do
                for _,action in ipairs(target.Actions) do
                    local mobName = AshitaCore:GetMemoryManager():GetEntity():GetName(actionPacket.UserIndex)
                    --WriteAnimationId(mobName, actionPacket.Id, action.Animation)
                    local data = string.format('Mob: %s, Skill: %u, Animation: %u, Msg: %u, Knock: %u', mobName, actionPacket.Id, action.Animation, action.Message, action.Knockback)
                    gLogManager:Log(LogStyle.Message, 'MobAnimation', data);
                end
            end
        end
      end
  end);

  ashita.events.register('d3d_present', 'present_cb', function ()
    -- local pGameMenu = ashita.memory.find('FFXiMain.dll', 0, "8B480C85C974??8B510885D274??3B05", 16, 0);
    -- local pEventSystem = ashita.memory.find('FFXiMain.dll', 0, "A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3", 0, 0);
    -- local pInterfaceHidden = ashita.memory.find('FFXiMain.dll', 0, "8B4424046A016A0050B9????????E8????????F6D81BC040C3", 0, 0);
    -- local function GetMenuName()
    --     local subPointer = ashita.memory.read_uint32(pGameMenu);
    --     local subValue = ashita.memory.read_uint32(subPointer);
    --     if (subValue == 0) then
    --         return '';
    --     end
    --     local menuHeader = ashita.memory.read_uint32(subValue + 4);
    --     local menuName = ashita.memory.read_string(menuHeader + 0x46, 16);
    --     return string.gsub(menuName, '\x00', '');
    -- end
    -- local menus = GetMenuName()
    --print(menus)
  end)