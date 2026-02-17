require('common');
-- Load or unload addons / plugins

-- Delayed commands
local function delayed_setup()
	print('-- running delayed setup commands.. --');
	-- Load or unload addons / plugins
	AshitaCore:GetChatManager():QueueCommand(-1, '/load shorthand');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load inventorycounter');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load achelper');
	AshitaCore:GetChatManager():QueueCommand(-1, '/sl others on');
	-- Chatmode party has to be delayed or it won't work
	AshitaCore:GetChatManager():QueueCommand(-1, '/chatmode party');
	print('-- done --');
end

delayed_setup:once(10);