require('common');

-- Chatmode
local function delayed_setup()
	print('-- running delayed setup commands.. --');
	AshitaCore:GetChatManager():QueueCommand(-1, '/chatmode party');
	AshitaCore:GetChatManager():QueueCommand(-1, '/sl others on');
	AshitaCore:GetChatManager():QueueCommand(-1, '/fps 2');
	AshitaCore:GetChatManager():QueueCommand(-1, '/lw profile kitori');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load luashitacast');
	AshitaCore:GetChatManager():QueueCommand(-1, '/addon load points');
	AshitaCore:GetChatManager():QueueCommand(-1, '/load parkour');
	AshitaCore:GetChatManager():QueueCommand(-1, '/trigger LS /winfocus *nextalpha');
	print('-- done --');
end

delayed_setup:once(10);
