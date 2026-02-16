addon.name      = 'MergeTables';
addon.author    = 'Shiyo';
addon.version   = '1.00';
addon.desc      = 'Merges keys between multiple tables. Used with logvendors data only atm';
addon.link      = 'https://github.com/ThornyFFXI/';

require('common');

local function mergetableData()
    local tableData1 = dofile("C:\\Ashita 4\\addons\\mergetables\\tabledata_1.lua")
    local tableData2 = dofile("C:\\Ashita 4\\addons\\mergetables\\tabledata_2.lua")

    local combined = {}

    -- Helper function to add vendor entries
    local function addtableData(source)
        for itemId, vendors in pairs(source) do
            combined[itemId] = combined[itemId] or {}
            for _, vendor in ipairs(vendors) do
                table.insert(combined[itemId], vendor)
            end
        end
    end

    -- Merge both
    addtableData(tableData1)
    addtableData(tableData2)

    -- Optional: save merged output to file
    local output = io.open("C:\\Ashita 4\\addons\\mergetables\\tabledata_combined.lua", "w")
    output:write("local tableData = {\n")

    for itemId, vendors in pairs(combined) do
        output:write(string.format("    [%d] = {\n", itemId))
        for _, v in ipairs(vendors) do
            output:write(string.format(
                "        { Name = %q, Zone = %q, Price = %d },\n",
                v.Name, v.Zone, v.Price or 0
            ))
        end
        output:write("    },\n")
    end

    output:write("}\nreturn tableData\n")
    output:close()

    print("Combined vendor data written to tableData_combined.lua")
end


ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if #args == 0 or (string.lower(args[1]) ~= '/mergetables') then
        return;
    end
    e.blocked = true;

    if (args[2] == 'merge') and (#args > 1) then
        mergetableData()
    end

    if (#args < 3) then
        return;
    end
end);