addon.name      = 'finditem';
addon.author    = 'Shiyo';
addon.version   = '1.0';
addon.desc      = 'Help you find items';
addon.link      = 'https://github.com/ShiyoKozuki';

require('common');
local chat = require('chat');
local fonts = require('fonts');
local settings = require('settings');
local inventory = AshitaCore:GetMemoryManager():GetInventory()
local resources = AshitaCore:GetMemoryManager()

local default_settings = T{
	font = T{
        visible = true,
        font_family = 'Arial',
        font_height = 30,
        color = 0xFFFFFFFF,
        position_x = 1,
        position_y = 1,
		background = T{
			visible = true,
			color = 0x80000000,
		}
    }
};

local finditem = T{
	settings = settings.load(default_settings)
};

local Storages =T{
	inventory = T{
		id = 0,
		storage = 'inventory',
	},
	safe = T{
		id = 1,
		storage = 'safe',
	},
	storage = T{
		id = 2,
		storage = 'storage',
	},
	temporary = T{
		id = 3,
		storage = 'temporary',
	},
	locker = T{
		id = 4,
		storage = 'locker',
	},
	satchel = T{
		id = 5,
		storage = 'satchel',
	},
	sack = T{
		id = 6,
		storage = 'sack',
	},
	case = T{
		id = 7,
		storage = 'case',
	},
	wardrobe = T{
		id = 8,
		storage = 'wardrobe',
	},
	safe2 = T{
		id = 9,
		storage = 'safe 2',
	},
	wardrobe2 = T{
		id = 10,
		storage = 'wardrobe 2',
	},
	wardrobe3 = T{
		id = 11,
		storage = 'wardrobe 3',
	},
	wardrobe4 = T{
		id = 12,
		storage = 'wardrobe 4',
	},
};

local function search(searchString, useDescription) 

    local found = { };
    local result = { };

    
    for k,v in ipairs(STORAGES) do
        local foundCount = 1;
        for j = 0, inventory:GetContainerMax(v.id), 1 do
            local itemEntry = inventory:GetItem(v.id, j);
            if (itemEntry.Id ~= 0 and itemEntry.Id ~= 65535) then
                local item = resources:GetItemById(itemEntry.Id);
                
                if (item ~= nil) then
                    if (find(item, cleanString, useDescription)) then
                        quantity = 1;
                        if (itemEntry.Count ~= nil and item.StackSize > 1) then
                            quantity = itemEntry.Count;
                        end
                    
                        if result[k] == nil then 
                            result[k] = { }; 
                            found[k] = { };
                        end
                        
                        if found[k][itemEntry.Id] == nil then
                            found[k][itemEntry.Id] = foundCount;
                            result[k][foundCount] = { name = item.Name[config.language], count = 0 };
                            foundCount = foundCount + 1;
                        end
                                                                                                
                        result[k][found[k][itemEntry.Id]].count = result[k][found[k][itemEntry.Id]].count + quantity;
                    end
                    
                    if find(item, 'storage slip ', false) then
                        storageSlips[#storageSlips + 1] = {item, itemEntry};
                    end
                end
            end
        end
    end
    
    local total = 0;
    for k,v in ipairs(STORAGES) do
        if result[k] ~= nil then
            storageID, storageName = getStorage(k);
            for _,item in ipairs(result[k]) do
                quantity = '';
                if item.count > 1 then 
                    quantity = string.format('[%d]', item.count)
                end
                printf('%s: %s %s', storageName, item.name, quantity);
                total = total + item.count;
            end
        end
    end
    printf('\30\08Found %d matching items.', total);
end



ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or args[1] ~= '/find') then
        return;
    end
    e.blocked = true;
    
    if (args[1]:lower() == '/find' and #args <= 2) then
        search(args[2]:lower(), false);
        return true;
    elseif (args[1]:lower() == '/findmore' and #args <= 2) then
        search(args[2]:lower(), true);
        return true;
    elseif (args[1]:lower() == '/finddupes' and #args <= 1) then 
        printdupes();
        return true;
    elseif (args[1]:lower() == '/findslips' and #args <= 2) then 
        if #args >= 2 then
            searchslip = tonumber(args[2]:lower());
            if not searchslip then
                printf('\30\08Please enter a valid storage slip between %i and %i, inclusive.', MINSLIP, MAXSLIP);
                return false;
            else
                printslips(searchslip);
                return true;
            end
        else
            printslips(0);
        end
    end;
    return false;
end );
ashita.events.register('unload', 'unload_cb', function ()
    if (finditem.font ~= nil) then
        finditem.font:destroy();
    end
settings.save();
end);