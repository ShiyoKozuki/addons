addon.name      = 'Currency';
addon.author    = 'Thorny';
addon.version   = '1.0';
addon.desc      = 'Displays current allied notes.';
addon.link      = 'https://ashitaxi.com/';

require('common');
local chat = require('chat');
local fonts = require('fonts');
local settings = require('settings');

local FontSettings = T{
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
};
local FontObject = nil;
local CurrentNotes = 0;
local Timer = 0;

ashita.events.register('load', 'load_cb', function ()
	FontObject = fonts.new(FontSettings);	
end);

ashita.events.register('d3d_present', 'currency_present_cb', function ()
	FontObject.text = ('Allied Notes: %u'):fmt(CurrentNotes);
	if (os.clock() > Timer) then
		local packet = { 0x00, 0x00, 0x00, 0x00 };
		AshitaCore:GetPacketManager():AddOutgoingPacket(0x10F, packet);
		Timer = os.clock() + 5;
	end
end);

ashita.events.register('unload', 'unload_cb', function ()
    if (FontObject ~= nil) then
        FontObject:destroy();
    end
settings.save();
end);

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if (e.id == 0x113) then
		CurrentNotes = struct.unpack('l', e.data, 0xA4 + 1);
	end
end);