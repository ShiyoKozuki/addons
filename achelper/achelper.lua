addon.name      = 'ACHelper';
addon.author    = 'Thorny';
addon.version   = '1.0';
addon.desc      = 'Manages Ashitacast variables.';
addon.link      = 'https://ashitaxi.com/';

require('common');
local chat = require('chat');
local fonts = require('fonts');
local settings = require('settings');

local default_settings = T{
    namecolor = 'FFFFFFFF',
	valuecolor = 'FF00FF00',
	font = T{
        visible = true,
        font_family = 'Arial',
        font_height = 12,
        color = 0xFFFFFFFF,
        position_x = 1,
        position_y = 1,
		background = T{
			visible = true,
			color = 0x80000000,
		}
    }
};

local achelper = T{
	settings = settings.load(default_settings)
};
local toggles = T{
};


ashita.events.register('load', 'load_cb', function ()
    achelper.font = fonts.new(achelper.settings.font);
end);

ashita.events.register('d3d_present', 'present_cb', function ()
	local outText = 'AcHelper';
	if (toggles ~= nil) then
		for key, value in pairs(toggles) do
			outText = outText .. ('\n|c%s|%s: |c%s|%s|r '):fmt(achelper.settings.namecolor, value.name, achelper.settings.valuecolor, value.values[value.index]);
		end
	end
	achelper.font.text = outText;
end);

ashita.events.register('unload', 'unload_cb', function ()
    if (achelper.font ~= nil) then
        achelper.font:destroy();
    end
end);

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or args[1] ~= '/achelper') then
        return;
    end
    e.blocked = true;
    if (#args < 2) then
        return;
    end
	
	if (args[2] == 'clear') then
		for key, value in pairs(toggles) do
			toggles[key] = nil;
		end
		
		print('Tables cleared.');
		return;
	end
	
	if (args[2] == 'init') then
		if (#args < 4) then
			return
		end
		
		local tableName = args[3];
		toggles[tableName] = T{
		  index = 1,
		  name = tableName,
		  count = #args - 3,
		  values = T {},
		};
	    for i = 4,#args,1 do
			toggles[tableName].values[i - 3] = args[i];
		end
		
		AshitaCore:GetChatManager():QueueCommand(-1, ('/ac setvar "%s" "%s"'):fmt(tableName, toggles[tableName].values[1]));
		print(('Initialized Table: %s(%d values)'):fmt(tableName, #toggles[tableName].values));		
		return
	end
			  

	for key, value in pairs(toggles) do
		if (args[2] == value.name) then
			value.index = value.index + 1;
			if (value.index > value.count) then
				value.index = 1;
			end
			AshitaCore:GetChatManager():QueueCommand(-1, ('/ac setvar "%s" "%s"'):fmt(value.name, value.values[value.index]));
		end
	end
end)