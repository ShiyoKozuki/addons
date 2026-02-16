addon.name      = 'InventoryPrint';
addon.author    = 'Shiyo';
addon.version   = '1.0';
addon.desc      = 'Prints all the items in all your inventory slots to a .txt file.';
addon.link      = 'https://github.com/ShiyoKozuki';

require('common');
require ('shiyolibs')
require('logmanager');
gLogManager:SetDirectory('InventoryPrint');

local function WriteInventoryItem(containerId, slot, itemId, itemName)
    local filePath = string.format('%slogs//InventoryPrint//InventoryPrint.txt', AshitaCore:GetInstallPath());
    local file = io.open(filePath, 'a');
    if not file then
        print('Failed to open InventoryPrint.txt for writing.');
        return;
    end
    file:write(string.format('Container: %u, Slot: %u, Item: %s (ID: %u)\n', containerId, slot, itemName or 'Unknown', itemId));
    file:close();
end

function DumpAllItemsToFile()
    local inventoryManager = AshitaCore:GetMemoryManager():GetInventory();
    local resManager = AshitaCore:GetResourceManager();

    for containerId = 0, 16 do
        -- Skip temp items container
        if containerId ~= 3 then
            for slot = 1, 80 do
                local item = inventoryManager:GetContainerItem(containerId, slot);
                if (item ~= nil and item.Id ~= 0) then
                    local itemData = resManager:GetItemById(item.Id);
                    local itemName = itemData and itemData.Name[1] or 'Unknown';
                    WriteInventoryItem(containerId, slot, item.Id, itemName);
                end
            end
        end
    end

    print('InventoryPrint complete! Saved to logs/InventoryPrint/InventoryPrint.txt');
end



ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or args[1] ~= '/inventoryprint') then
        return;
    end
    e.blocked = true;
    
    if (#args < 2) then
        return;
    end

    if (args[2] == 'print') then
		DumpAllItemsToFile()
		return
	  end
end);