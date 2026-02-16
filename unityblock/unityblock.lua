addon.name      = 'UnityBlock';
addon.author    = 'Shiyo';
addon.version   = '1.0';
addon.desc      = 'Blocks unity chat';
addon.link      = 'https://ashitaxi.com/';

require('common');

ashita.events.register('packet_in', 'packet_in_cb', function (e)
  if (e.id == 0x17) then
    local mode = struct.unpack('B', e.data, 0x04 + 1);
    if T{ 33, 34, 35}:contains(mode) then
      e.blocked = true;
    end
  end
end)