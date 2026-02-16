addon.name      = 'LatentChecker';
addon.author    = 'Thorny';
addon.version   = '1.0';
addon.desc      = 'Manages Ashitacast variables.';
addon.link      = 'https://ashitaxi.com/';

require('common')

local containers = {
    Inventory = 0,
    Safe = 1,
    Storage = 2,
    Temporary = 3,
    Locker = 4,
    Satchel = 5,
    Sack = 6,
    Case = 7,
    Wardrobe = 8,
    Safe2 = 9,
    Wardrobe2 = 10,
    Wardrobe3 = 11,
    Wardrobe4 = 12
};

local wsTrialIds = T{18097,16735,18146,16952,17507,16892,16793,17654,18144,17456,17527,17933,17616,17815,17773,18492,18753,18851,18589,17742,18003,17744,18944,17956,18034,18719,18443,18426,18120,18590,17743,18720,18754,19102,18592,17509,17793,18005,18378,17699,17207,17451,18053,18217,17275,17944,17827,17589,21066,20749,16607};

local function GetContainerName(containerIndex)
	for name,index in pairs(containers) do
	  if (index == containerIndex) then
	    return name;
	  end
	end
	return 'Unknown';
end

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or string.lower(args[1]) ~= '/lc') then
        return;
    end
	
    e.blocked = true;
    if (#args < 2) then
        return;
    end
	
	if (string.lower(args[2]) == 'show') then
		for container = 0,12,1 do
			for index = 1,80,1 do
				local containerItem = AshitaCore:GetMemoryManager():GetInventory():GetContainerItem(container, index);
				if containerItem ~= nil and wsTrialIds:contains(containerItem.Id) then
					local itemResource = AshitaCore:GetResourceManager():GetItemById(containerItem.Id);
					local value = struct.unpack('H', containerItem.Extra);
					print(('%s(%s): %u WS points'):fmt(itemResource.Name[1], GetContainerName(container), value));
				end
			end            
		end
	end
end)