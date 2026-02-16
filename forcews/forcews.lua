addon.name      = 'ForceWS'
addon.author    = 'Thorny';
addon.version   = '1.00';
addon.desc      = 'Force widescan';
addon.link	    = 'https://github.com/ThornyFFXI/';

require('common');
local chat = require('chat');


ashita.events.register('command', 'command_cb', function (e)
    if (string.lower(e.command) == '/forcewidescan') then
        local packet = struct.pack('LL', 0, 0);
        AshitaCore:GetPacketManager():AddOutgoingPacket(0xF4, packet:totable());
        print(string.format('%s%s', chat.header('ForceWS'), chat.message('Sending widescan packet..')));
        e.blocked = true;
    end
end);

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if (e.id == 0xF4) then
        print(string.format('%s%s %s%s %s%s',
        chat.message('Mob Index:'),
        chat.color1(2, tostring(struct.unpack('H', e.data, 0x04 + 1))),
        chat.message('Mob Level:'),
        chat.color1(2, tostring(struct.unpack('B', e.data, 0x06 + 1))),
        chat.message('Name:'),
        chat.color1(2, e.size > 0x0C and struct.unpack(string.format('c%u', e.size - 0x0C), e.data, 0x0C + 1) or '???')));
    end
end);