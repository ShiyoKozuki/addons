addon.name      = 'Find';
addon.author    = 'Thorny';
addon.version   = '1.1';
addon.desc      = 'Counts items on character.';
addon.link      = 'https://ashitaxi.com/';

require('common');
local chat = require('chat');
local STORAGES = {
    [1] = { id=0, name='Inventory' },
    [2] = { id=1, name='Safe' },
    [3] = { id=2, name='Storage' },
    [4] = { id=3, name='Temporary' },
    [5] = { id=4, name='Locker' },
    [6] = { id=5, name='Satchel' },
    [7] = { id=6, name='Sack' },
    [8] = { id=7, name='Case' },
    [9] = { id=8, name='Wardrobe' },
    [10]= { id=9, name='Safe 2' },
    [11]= { id=10, name='Wardrobe 2' },
    [12]= { id=11, name='Wardrobe 3' },
    [13]= { id=12, name='Wardrobe 4' }
};

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or args[1] ~= '/find') then
        return;
    end
    e.blocked = true;
    if (#args < 2) then
        return;
    end
	
	local searchTerm = string.lower(args[2]);
	local results = T{};
	
	for _,value in ipairs(STORAGES) do
		for i = 1,80,1 do
		  local containerItem = AshitaCore:GetMemoryManager():GetInventory():GetContainerItem(value.id, i);
		  if containerItem ~= nil and containerItem.Count > 0 and containerItem.Id > 0 then
		    local containerResource = AshitaCore:GetResourceManager():GetItemById(containerItem.Id);
			if containerResource ~= nil and string.match(string.lower(containerResource.Name[1]), searchTerm) then
			  if results[containerResource.Id] == nil then
			    results[containerResource.Id] = {
				  [1] = T{
				    number = containerItem.Count,
					container = value.name
				  }
				}
			  else
			    local count = #results[containerResource.Id];
				count = count + 1;
				results[containerResource.Id][count] = T{
				    number = containerItem.Count,
					container = value.name
				};
			  end
			end
		  end
		end
	end

	for key, value in pairs(results) do
		local resource = AshitaCore:GetResourceManager():GetItemById(key);
		local totalCount = 0;
		for _, entry in ipairs(value) do
		  local output = chat.header(addon.name):append(chat.message('Found '));
		
		  if (entry.number == 1) then
			output = output:append(chat.color1(2, ('a %s'):fmt(resource.LogNameSingular[1])));
		  else
		    output = output:append(chat.color1(2, ('%d %s'):fmt(entry.number, resource.LogNamePlural[1])));
		  end
		  output = output:append(chat.message((' in ')):append(chat.color1(2, entry.container)):append(chat.message('.')));
		  print(output);
		  totalCount = totalCount + entry.number;
		end
		
		if (totalCount > 1) then
		    print(chat.header(addon.name):append(chat.message('Found a total of ')):append(chat.color1(2, ('%d %s'):fmt(totalCount, resource.LogNamePlural[1]))):append(chat.message('.')));
		end
	end
end)