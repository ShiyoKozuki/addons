addon.name      = 'logvendors';
addon.author    = 'Thorny';
addon.version   = '1.1';
addon.desc      = 'Logs vendor data (supports multiple vendors per item)';
addon.link      = 'https://ashitaxi.com/';

require('common');
local chat = require('chat');

-- Table to store vendor data
local VendorLog = T{}

local function Message(text)
    local stripped = string.gsub(text, '$H', ''):gsub('$R', '');
    LogManager:Log(5, addon.name, stripped);
    local color = ('\30%c'):format(106);
    local highlighted = color .. string.gsub(text, '$H', '\30\01\30\02');
    highlighted = string.gsub(highlighted, '$R', '\30\01' .. color);
    print(chat.header(addon.name) .. highlighted .. '\30\01');
end

local function AddVendorData(npc)
    local zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    local zoneName = AshitaCore:GetResourceManager():GetString('zones.names', zoneId)
    if not npc or not npc.Stock then
        return
    end

    for itemId, data in pairs(npc.Stock) do
        local entry = {
            Name      = npc.Name,
            Zone      = zoneName,
            Pos  = {
                X = npc.Pos.X,
                Y = npc.Pos.Y,
                Z = npc.Pos.Z
            },
            Stock     = data.Stock or 0,
            Price     = data.Cost or 0
        }

        -- Initialize as list if not present
        if not VendorLog[itemId] then
            VendorLog[itemId] = T{}
        end

        -- Avoid duplicates (same NPC selling same item)
        local alreadyLogged = false
        for _, v in ipairs(VendorLog[itemId]) do
            if v.Name == entry.Name and v.Zone == entry.Zone then
                alreadyLogged = true
                break
            end
        end

        if not alreadyLogged then
            table.insert(VendorLog[itemId], entry)
            Message(string.format("Successfully recorded %d from %s.", itemId, entry.Name))
        end
    end
end

local lastNPC;

ashita.events.register('packet_out', 'HandleOutgoingPacket', function (e)
    if (e.id == 0x01A) then
        -- Talk packet
        if struct.unpack('H', e.data, 0x0A + 1) == 0 then
            local id = struct.unpack('L', e.data, 0x04 + 1);
            local index = struct.unpack('H', e.data, 0x08 + 1);
            local entity = AshitaCore:GetMemoryManager():GetEntity():GetRawEntity(index);
            if entity then
                lastNPC = {
                    Id = id,
                    Index = index,
                    Name = entity.Name,
                    Pos = {
                        X = entity.Movement.LocalPosition.X,
                        Y = entity.Movement.LocalPosition.Y,
                        Z = entity.Movement.LocalPosition.Z,
                    },
                    Stock = T{}
                };
            end
        end
    end
end);

ashita.events.register('packet_in', 'HandleIncomingPacket', function (e)
    -- Standard vendor
    if (e.id == 0x3C) then
        if lastNPC and lastNPC.Stock then
            local max = (e.size - 8) / 12;
            local offset = 8;
            for i = 1, max do
                local id = struct.unpack('H', e.data, offset + 4 + 1);
                local cost = struct.unpack('L', e.data, offset + 1);
                local index = struct.unpack('B', e.data, offset + 6 + 1);
                lastNPC.Stock[id] = { Cost = cost, Index = index };
                offset = offset + 12;
            end
            AddVendorData(lastNPC);
        end
    end

    -- Guild vendor
    if (e.id == 0x83) then
        if lastNPC and lastNPC.Stock then
            local count = struct.unpack('B', e.data, 0xF4 + 1);
            for i = 1, count do
                local offset = 4 + ((i - 1) * 8);
                local id = struct.unpack('H', e.data, offset + 1);
                local stock = struct.unpack('B', e.data, offset + 1 + 1);
                local cost = struct.unpack('L', e.data, offset + 4 + 1);
                lastNPC.Stock[id] = { Cost = cost, Stock = stock, Index = i };
            end
            AddVendorData(lastNPC);
        end
    end
end);

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if #args == 0 or (string.lower(args[1]) ~= '/logvendors') then
        return;
    end
    e.blocked = true;

    if (args[2] == 'cliplua') then
        local output = "local vendorData = {\n"
        for itemId, vendorList in pairs(VendorLog) do
            output = output .. string.format("    [%u] = {\n", itemId)
            for _, info in ipairs(vendorList) do
                output = output .. string.format(
                    "        { Name = %q, Zone = %q, Pos = { X = %.3f, Y = %.3f, Z = %.3f}, Stock = %u, Price = %u },\n",
                    info.Name,
                    info.Zone,
                    info.Pos.X, info.Pos.Z, info.Pos.Y,
                    info.Stock,
                    info.Price
                )
            end
            output = output .. "    },\n"
        end
        output = output .. "}"

        ashita.misc.set_clipboard(output)
        Message(string.format("Copied %u unique item entries to clipboard.", table.count(VendorLog)))
    end
end);