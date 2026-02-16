addon.name      = 'AutoRA';
addon.author    = 'Shiyo';
addon.version   = '1.0';
addon.desc      = 'Auto-matically uses ranged attacks.';
addon.link      = 'https://github.com/ShiyoKozuki';

require('common')
require ('shiyolibs')
local chat = require('chat');
local settings = require('settings'); -- v4's settings lib
local imgui = require('imgui');       -- v4's gui lib
local statusEffect = require('statuseffect')

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local lastPosition
local rangedActive = true
local targetIndex = 0
local TargetDistance
local myIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0)
local engaged
local TP

-------------------------------------------------------------------------------
-- local state
-------------------------------------------------------------------------------
local default_settings = T{
    --[[ this table contains all of your settings with their default values.
    --   it is used to create initial settings and to update existing ones
    --   in case you ever add more values in here
    --]]
    settingsVars = T{
        tpThreshold = 1000,
        engagedToggle = false,
    },
  };
  
  local ar = T {
    --[[ the next line will load your saved settings and populate anything 
    --   that's missing from `default_settings`.
    --]]
    settings = settings.load(default_settings),
    -- just a state variable so we can open an close the UI
    ui = T{
        is_open = T{ false, }, -- this has to be in a table to work with imGUI
    }
  };
  
  local toggle_settings = function()
    ar.ui.is_open[1] = true;
  end
  
  local render_settings_ui = function()
    if (not ar.ui.is_open[1]) then
        -- don't do anything if is_open is false
        return;
    end
  
    local header_color = { 1.0, 0.75, 0.55, 1.0 };
  
    imgui.SetNextWindowContentSize({ 400, 380 }); -- controls the size of the window
  
    if (imgui.Begin(('Autora Settings v%s'):fmt(addon.version), ar.ui.is_open, 0)) then
		imgui.BeginGroup();
  
			local tp_slider_value = T{ ar.settings.settingsVars.tpThreshold };

            -- show the sliders
			imgui.SliderInt('TP Threshold', tp_slider_value, 1, 3000, '%d TP');

            -- read the value from the slider and update the variables
			ar.settings.settingsVars.tpThreshold = tp_slider_value[1];


            if (imgui.Checkbox('Engaged Only', { ar.settings.settingsVars.engagedToggle })) then
                ar.settings.settingsVars.engagedToggle = not ar.settings.settingsVars.engagedToggle;
              end

        imgui.EndGroup();
    end
    imgui.End();
  end

local function GetEngageLogic(engaged, engagedSetting)
    if (engaged and engagedSetting) then
        return true
    elseif (engaged and not engagedSetting) then
        return true
    end
    return false
end

local function print_help(isError)
    -- Print the help header..
    if (isError) then
        print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/' .. addon.name)));
    else
        print(chat.header(addon.name):append(chat.message('Available commands:')));
    end

    local cmds = T{
        { '/autora settings ', 'Opens settings menu.' },
        { '/autora NYI', 'NYI' },
    };

    -- Print the command list..
    cmds:ieach(function (v)
        print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])));
    end);
end

ashita.events.register('d3d_present', 'present_cb', function ()
    engaged = (AshitaCore:GetMemoryManager():GetEntity():GetStatus(myIndex) == 1)
    targetIndex = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(AshitaCore:GetMemoryManager():GetTarget():GetIsSubTargetActive())
    TargetDistance = math.sqrt(AshitaCore:GetMemoryManager():GetEntity():GetDistance(targetIndex))
    TP = AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0)
    render_settings_ui();
end)

ashita.events.register('packet_out', 'AutoRA_HandleOutgoingPacket', function (e)
    local currentSetting = ar.settings.settingsVars
    local tpSetting =  currentSetting.tpThreshold
    local engagedSetting = currentSetting.engagedToggle
    local raEnabled = GetEngageLogic(engaged, engagedSetting)

    if (e.id == 0x15) then
        local myPosition = {
            X = struct.unpack('f', e.data, 0x04 + 1),
            Y = struct.unpack('f', e.data, 0x0C + 1),
            Z = struct.unpack('f', e.data, 0x08 + 1);
        };

        if (type(lastPosition) ~= 'table') or (lastPosition.X ~= myPosition.X) or (lastPosition.Y ~= myPosition.Y) or (lastPosition.Z ~= myPosition.Z) then
            lastPosition = myPosition;
            return; --Player is moving according to server, no ranged
        end

        if (rangedActive) and (targetIndex > 0) and (AshitaCore:GetMemoryManager():GetEntity():GetHPPercent(targetIndex) > 0) and IsMonster(targetIndex) then
            local targetId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);
            if (targetId > 0) and (TargetDistance <= 25) and (TP <= tpSetting) and raEnabled then
                local packet = struct.pack('LLHHHHLLL', 0, targetId, targetIndex, 0x10, 0, 0, 0, 0, 0);
                AshitaCore:GetPacketManager():AddOutgoingPacket(0x1A, packet:totable());
            end
        end
    end
end);

local blockedMessages = T{
    'Cannot attack that target.',
    'You must wait longer to perform that action.',
    'You do not have an appropriate ranged weapon equipped.',
    'You cannot attack target target.'
};
ashita.events.register('text_in', 'AutoRA_HandleText', function (e)
    for _,message in ipairs(blockedMessages) do
        if string.match(e.message, message) then
            e.blocked = true;
            return;
        end
    end
end);

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or args[1] ~= '/autora') then
        return;
    end
    e.blocked = true;
    
    if (#args < 2) then
        return;
    end

    if (args[2] == 'settings') or (args[2] == 'toggles') then
		toggle_settings();
		return
	  end

    if (args[2] == '?') or (args[2] == 'help') then
    print_help(true);
    return
    end
end);

ashita.events.register('unload', 'autora_unload', function ()
	settings.save();
end)