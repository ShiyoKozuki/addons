addon.author   = 'Thorny';
addon.name     = 'PacketLogger';
addon.desc     = 'Packet Logger';
addon.version  = '0.0';

require ('common');
local outFolder = string.format('%s/logs/packets/', AshitaCore:GetInstallPath());
ashita.fs.create_directory(outFolder);

local function LogPacket(e, outgoing)
    local outFile = outFolder .. 'log.txt';
    local fHandle = io.open(outFile, 'a');
    local time = ashita.time.get_localtime();
    fHandle:write(string.format('[%02d:%02d:%02d:%03d] %s Packet (0x%03X) Injected:%s Blocked:%s\n',
        time.hh, time.mm, time.ss, time.ms,
        outgoing and "Outgoing" or "Incoming", e.id,
        e.injected and "yes" or "no", e.blocked and "yes" or "no"));
    local offset = 0;
    while (offset < e.size) do
        for n = 0,15 do            
            if offset + n == e.size then
                break;
            end
            if n ~= 0 then
                fHandle:write(' ');
            end
            fHandle:write(string.format('0x%02X', struct.unpack('B', e.data, offset+n+1)));
        end
        offset = offset + 16;
        fHandle:write('\n');
    end
    fHandle:write('\n');
    fHandle:close();
end

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if (e.id == 0x38) then
        local id = struct.unpack('L', e.data, 0x04+1);
        if (id == 17670567) then
            LogPacket(e, false);
        end
    end
end);