addon.name      = 'Toggles';
addon.author    = 'Shiyo';
addon.version   = '1.0';
addon.desc      = 'Toggles for QOL';
addon.link      = 'https://ashitaxi.com/';

require('common');
local chat = require('chat');
local fonts = require('fonts');
local settings = require('settings');
local MsFollow = false
local WepLock = true
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
    if (#args > 0) and string.lower(args[1]) == '/MsFollow' then
		if MsFollow then
			AshitaCore:GetChatManager():QueueCommand(1, '/ms send  /ms follow off');
			AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto yukiko /addon load yukibot');
			AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto sayaki /addon load rdmbot');
			MsFollow = false;
		else
			AshitaCore:GetChatManager():QueueCommand(1, '/ms send  /ms follow on');
			AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto yukiko /addon unload yukibot');
			AshitaCore:GetChatManager():QueueCommand(1, '/ms sendto sayaki /addon unload rdmbot');
			MsFollow = true;
        end
    end

    if (#args > 0) and string.lower(args[1]) == '/weplock' then
		if WepLock then
			WepLock = false;
		else
			WepLock = true;
        end
    end
	
    if (#args > 0) and string.lower(args[1]) == '/disable' then
		if LacDisabled then
			LacDisabled = false;
		else
			LacDisabled = true;
        end
    end
end);

ashita.events.register('d3d_present', 'present_cb', function ()
	toggles.font.text  = 'Wep Lock: ' .. BoolText(WepLock)  .. '\n' .. 'MsFollow Me: ' .. BoolText(FollowMe) .. '\n' .. 'MsFollow: ' .. BoolText(MsFollow) .. '\n' .. 'Gear Lock: ' .. BoolText(LacDisabled);
	toggles.settings.font.position_x = toggles.font:GetPositionX();
	toggles.settings.font.position_y = toggles.font:GetPositionY();
  toggles.font.visible = true;
end);

ashita.events.register('unload', 'unload_cb', function ()
    if (toggles.font ~= nil) then
        toggles.font:destroy();
    end
settings.save();
end);