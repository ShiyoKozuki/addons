require('common');
-- Edit settings
AshitaCore:GetChatManager():QueueCommand(-1, '/sl others on');
AshitaCore:GetChatManager():QueueCommand(-1, '/sl self off');
AshitaCore:GetChatManager():QueueCommand(-1, '/fps 2');

-- Delayed commands to load addons so the game knows char name to pick settings file for etc
local function delayed_setup()
	print('-- running delayed setup commands.. --');
	AshitaCore:GetChatManager():QueueCommand(-1, '/load crossbar');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load luashitacast');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load mobdb');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load blusets');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load blucheck');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load points');
    -- addon settings
    AshitaCore:GetChatManager():QueueCommand(-1, '/sl addc Ohafumi Face 12');
	AshitaCore:GetChatManager():QueueCommand(-1, '/blusets delay 2.5');
	print('-- done --');
end

delayed_setup:once(10);