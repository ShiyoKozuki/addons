addon.name      = 'mapblock';
addon.author    = 'Thorny';
addon.version   = '1.0';
addon.desc      = 'Blocks map helper icons.';
addon.link      = 'https://ashitaxi.com/';

require('common');

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if (e.id == 0x063) then    
        local packet = e.data:bytes();
        if (packet[0x04 + 1] == 6) then
            e.blocked = true;
        end
    end
end);