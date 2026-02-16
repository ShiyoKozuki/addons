require('common');
-- Edit settings
AshitaCore:GetChatManager():QueueCommand(-1, '/ms followme off');
AshitaCore:GetChatManager():QueueCommand(-1, '/sl others on');
AshitaCore:GetChatManager():QueueCommand(-1, '/sl self off');
AshitaCore:GetChatManager():QueueCommand(-1, '/fps 2');

-- Delayed commands to load addons so the game knows char name to pick settings file for etc
local function delayed_setup()
	print('-- running delayed setup commands.. --');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load luashitacast');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load mobdb');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load blucheck');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load statustimers');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load toggles');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load simplelog');
	AshitaCore:GetChatManager():QueueCommand(-1, '/trigger LS /winfocus *nextalpha');
	print('-- done --');
end

delayed_setup:once(10);