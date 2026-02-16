addon.name      = 'Toggles';
addon.author    = 'Shiyo';
addon.version   = '1.0';
addon.desc      = 'Toggles for QOL';
addon.link      = 'https://ashitaxi.com/';

require('common');
local chat = require('chat');
local fonts = require('fonts');
local settings = require('settings');
local FollowMe = false
local MSKozumi = false
local WepLock = true
local THFBot = false
local BLMBot = false
local RNGBot = false
local KozumiBot = false
local LacDisabled = false

local function BoolText(val)
  if (val) then
    return '|cFF00FF00|Enabled|r';
  else
    return '|cFFFF0000|Disabled|r';
  end
end

local default_settings = T{
	font = T{
        visible = true,
        font_family = 'Arial',
        font_height = 20,
        color = 0xFFFFFFFF,
        position_x = 1,
        position_y = 1,
		background = T{
			visible = true,
			color = 0x80000000,
		}
    }
};

local toggles = T{
	settings = settings.load(default_settings)
};

ashita.events.register('load', 'load_cb', function ()
    toggles.font = fonts.new(toggles.settings.font);
end);

ashita.events.register('command', 'command_cb', function (e)
  local args = e.command:args();

  -- Toggle Kozumi Following
  if (#args > 0) and string.lower(args[1]) == '/mskozumi' then
  if MSKozumi then
    AshitaCore:GetChatManager():QueueCommand(1, '/ms send /echo Kozumi follow off.');
    AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kozumi /ms follow off');
    MSKozumi = false;
  else
    AshitaCore:GetChatManager():QueueCommand(1, '/ms send /echo Kozumi follow on.');
    AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kozumi /ms follow on');
    MSKozumi = true;
      end
  end

  -- Toggle Follow
  if (#args > 0) and string.lower(args[1]) == '/msfollow' then
  if FollowMe then
    AshitaCore:GetChatManager():QueueCommand(1, '/ms followme off');
    FollowMe = false;
  else
    AshitaCore:GetChatManager():QueueCommand(1, '/ms followme on');
    FollowMe = true;
      end
  end

  -- Lock Weapons
  if (#args > 0) and string.lower(args[1]) == '/weplock' then 
  if WepLock then
    WepLock = false;
  else
    WepLock = true;
      end
  end

  -- Disable LAC
  if (#args > 0) and string.lower(args[1]) == '/disable' then 
  if LacDisabled then
    LacDisabled = false;
  else
    LacDisabled = true;
      end
  end
  -- Load KozumiBot
  if (#args > 0) and string.lower(args[1]) == '/kozumibot' then
    if KozumiBot then
      AshitaCore:GetChatManager():QueueCommand(1, '/ms send /echo KozumiBot off.');
      AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto Kozumi /addon unload KozumiBot');
      KozumiBot = false;
    else
      AshitaCore:GetChatManager():QueueCommand(1, '/ms send /echo KozumiBot on.');
      AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto Kozumi /addon load KozumiBot');
      KozumiBot = true;
        end
    end
  -- Load THFBot
  if (#args > 0) and string.lower(args[1]) == '/thfbot' then
    if THFBot then
      AshitaCore:GetChatManager():QueueCommand(1, '/ms send /echo THFBot off.');
      AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kitori /addon unload THFBot');
      THFBot = false;
    else
      AshitaCore:GetChatManager():QueueCommand(1, '/ms send /echo THFBot on.');
      AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kitori /addon load THFBot');
      THFBot = true;
        end
    end
  -- Load BLMBot
  if (#args > 0) and string.lower(args[1]) == '/blmbot' then
    if BLMBot then
      AshitaCore:GetChatManager():QueueCommand(1, '/ms send /echo BLMBot off.');
      AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kitori /addon unload BLMBot');
      BLMBot = false;
    else
      AshitaCore:GetChatManager():QueueCommand(1, '/ms send /echo BLMBot on.');
      AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kitori /addon load BLMBot');
      BLMBot = true;
      end
    end
    -- Load RNGBot
    if (#args > 0) and string.lower(args[1]) == '/rngbot' then
      if RNGBot then
        AshitaCore:GetChatManager():QueueCommand(1, '/ms send /echo RNGBot off.');
        AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kitori /addon unload RNGBot');
        RNGBot = false;
      else
        AshitaCore:GetChatManager():QueueCommand(1, '/ms send /echo RNGBot on.');
        AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto kitori /addon load RNGBot');
        RNGBot = true;
        end
      end
end);

ashita.events.register('d3d_present', 'present_cb', function ()
	-- toggles.font.text  = 'Wep Lock: ' .. BoolText(WepLock)  .. '\n' .. 'Follow Me: ' .. BoolText(FollowMe) .. '\n' .. 'MSKozumi: ' .. BoolText(MSKozumi) .. '\n' .. 'Gear Lock: ' .. BoolText(LacDisabled);
	-- toggles.settings.font.position_x = toggles.font:GetPositionX();
	-- toggles.settings.font.position_y = toggles.font:GetPositionY();
  -- toggles.font.visible = true;
end);

ashita.events.register('unload', 'unload_cb', function ()
    if (toggles.font ~= nil) then
        toggles.font:destroy();
    end
settings.save();
end);