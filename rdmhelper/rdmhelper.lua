addon.name      = 'RDMhelper';
addon.author    = 'Shiyo';
addon.version   = '1.2';
addon.desc      = 'Helps RDMbot';
addon.link      = 'https://ashitaxi.com/';

require('common');
local mActionTimer = 0
local function GetBuffActive(matchBuff)
  local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();    
  for _, buff in pairs(buffs) do
    if buff == matchBuff then
      return true;
    end
  end
  return false;
end

local function GetBuffCount(matchBuff)
  local count = 0;
  local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();    
  for _, buff in pairs(buffs) do
    if buff == matchBuff then
      count = count + 1;
    end
  end
  return count;
end

local mMonitoredBuffs = T{
	refresh = T{
		id = 43,
		command = 'refresh',
	},
};

local mMonitoredSongs =T{
	march = T{
		id = 214,
		command = 'march',
	},
};

local mMonitoredDebuffs = T{
	poison = T{
		id = 3,
		command = 'poisona',
	},
	paralysis = T{
		id = 4,
		command = 'paralyna',
	},
	blindness = T{
		id = 5,
		command = 'blindna'
	},
	silence = T{
		id = 6,
		command = 'silena',
	},
	petrification = T{
		id = 7,
		command = 'stona',
	},
	disease = T{
		id = 8,
		command = 'viruna',
	},
	curse = T{
		id = 9,
		command = 'cursna',
	},
	curse_II = T{
		id = 20,
		command = 'zombie',
	},
	slow = T{
		id = 13,
		command = 'erase',
	},
	doom = T{
		id = 15,
		command = 'cursna',
	},
	sleep = T{
		id = 2,
		command = 'curaga',
	},
	lullaby = T{
		id = 19,
		command = 'curaga',
	},
	elegy = T{
		id = 194,
		command = 'erase',
	},
	bind = T{
		id = 11,
		command = 'erasetwo',
	},
	addle = T{
		id = 21,
		command = 'erasetwo',
	},
	charm = T{
		id = 14,
		command = 'charm',
	},      
};


ashita.events.register('d3d_present', 'present_cb', function ()
    if (os.time() <= mActionTimer) then
        return;
    end
	
    for k,v in pairs(mMonitoredBuffs) do
        if GetBuffActive(v.id) then
            AshitaCore:GetChatManager():QueueCommand(-1, ('/ms sendto Sayaki /rdmhelper %s on'):fmt(v.command));
        else
            AshitaCore:GetChatManager():QueueCommand(-1, ('/ms sendto Sayaki /rdmhelper %s off'):fmt(v.command));
        end
    end
	
    for k,v in pairs(mMonitoredDebuffs) do
        if GetBuffActive(v.id) then
            AshitaCore:GetChatManager():QueueCommand(-1, ('/ms sendto Sayaki /rdmhelper %s on'):fmt(v.command));
        else
            AshitaCore:GetChatManager():QueueCommand(-1, ('/ms sendto Sayaki /rdmhelper %s off'):fmt(v.command));
        end
    end
	    mActionTimer = os.time() + 1;
end);