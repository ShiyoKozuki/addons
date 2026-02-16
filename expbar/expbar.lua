addon.name      = 'ExpBar';
addon.author    = 'Shiyo';
addon.version   = '0.1';
addon.desc      = 'Shows experience values';
addon.link      = 'https://github.com/ShiyoKozuki';

require('common');
local chat = require('chat');
local fonts = require('fonts');
local settings = require('settings');

local default_settings = T{
	font = T{
        visible = true,
        font_family = 'Arial',
        font_height = 18,
        color = 0xFFFFFFFF,
        position_x = 1,
        position_y = 1,
		background = T{
			visible = true,
			color = 0x80000000,
		}
    }
};


local expbar = T{
	settings = settings.load(default_settings)
};


ashita.events.register('load', 'load_cb', function ()
    expbar.font = fonts.new(expbar.settings.font);
end);


ashita.events.register('d3d_present', 'present_cb', function ()
local getplayer = AshitaCore:GetMemoryManager():GetPlayer()
local currentExp = getplayer:GetExpCurrent();
local neededExp =  getplayer:GetExpNeeded();
local merits = getplayer:GetMeritPoints();
local currentLimitPoints = getplayer:GetLimitPoints();
local meritsMax = getplayer:GetMeritPointsMax();
local neededLimitPoints = 10000
  
  expbar.font.text = (('EXP %u/%u Merits %u/%u LP %u/%u'):fmt(currentExp,neededExp,merits,meritsMax,currentLimitPoints,neededLimitPoints));  
  expbar.settings.font.position_x = expbar.font:GetPositionX();
  expbar.settings.font.position_y = expbar.font:GetPositionY();
end);

ashita.events.register('unload', 'unload_cb', function ()
    if (expbar.font ~= nil) then
        expbar.font:destroy();
    end
settings.save();
end);