addon.name      = 'nomount';
addon.author    = 'Thorny';
addon.version   = '1.0';
addon.desc      = 'Blocks default mount music.';
addon.link      = 'https://ashitaxi.com/';

require('common');
local ffi = require('ffi');

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    -- Packet: Zone In
    if (e.id == 0x00A) then
        local ptr = ffi.cast('uint16_t*', e.data_modified_raw);
        local defaultDaytime = ptr[0x56/2];
        ptr[0x5E/2] = defaultDaytime;
    end

    -- Packet: Music Update
    if (e.id == 0x5F) then
        local song = struct.unpack('H', e.data, 0x06 + 1);
        if (song == 84) then
            e.blocked = true;
        end
    end
end);