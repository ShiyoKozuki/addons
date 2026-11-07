addon.name      = 'RoEManager';
addon.author    = 'Shiyo';
addon.version   = '1.0.1.0';
addon.desc      = 'Manages and automatically flags records of eminence quests.';
addon.link      = 'https://ashitaxi.com/';

require('common');
require ('shiyolibs')
require('logmanager');
local chat = require('chat');
local imgui = require('imgui');       -- v4's gui lib
local settings = require('settings')
local statusEffect = require('statuseffect')
local job = require('job')
local ROE = require('RoE')


chat = require('chat');
chat.header('RoEManager')

local Player = {}
Player.CurrentROE = {};
Player.CompletedROE = {};

local fullContent = T{};
do
    for id,name in pairs(ROE) do
        fullContent:append({ Id=id, Name=name})
    end
end

local activeContent;
local selectedROE;
local filterText = { '' };

local dailyCheckDone = false
local nextDailyCheck = 0

-- Dailies missing from DAT:
    -- DAILY_VANQUISH_MULTIPLE = 4082,
    -- DAILY_BUFF_ALLIES = 4083,
    -- DAILY_HEAL_500 = 4084,

local function FlagRoe(id)
    if Player.CurrentROE == nil then return end

    local roeFlagged = false

    for i = 2, 31 do
        local roe = Player.CurrentROE[i]

        if roe ~= nil then
            if id ==  roe.Id then
                roeFlagged = true
                break
            end
        end
    end

    if not roeFlagged then
        local packet = struct.pack('LHH', 0, id, 0)
        AshitaCore:GetPacketManager():AddOutgoingPacket(0x10C, packet:totable())
        print(chat.header("RoEManager") .. chat.message(string.format("RoE #%d Set!", id)))
    else
        print(chat.header("RoEManager") .. chat.message(string.format("RoE #%d is already set.", id)))
    end
end

local function UnflagFlagRoe(id)
    if Player.CurrentROE == nil then return end

    local roeFlagged = false

    for i = 2, 31 do
        local roe = Player.CurrentROE[i]

        if roe ~= nil then
            if id ==  roe.Id then
                roeFlagged = true
                break
            end
        end
    end

    if roeFlagged then
        local packet = struct.pack('LHH', 0, id, 0)
        AshitaCore:GetPacketManager():AddOutgoingPacket(0x10D, packet:totable())
        print(chat.header("RoEManager") .. chat.message(string.format("RoE #%d Unset!", id)))
    else
        print(chat.header("RoEManager") .. chat.message(string.format("RoE #%d is not set.", id)))
    end
end

local default_settings = T{
    --[[ this table contains all of your settings with their default values.
    --   it is used to create initial settings and to update existing ones
    --   in case you ever add more values in here
    --   SETTINGS WILL NOT BE SAVED IF NOT PUT IN HERE!
    --]]
    roeManager_Flags = T{ 
        autFlagList = T{},
    },
}

local roeManager = T{
    --[[ the next line will load your saved settings and populate anything 
    --   that's missing from `default_settings`.
    --]]
    settings = settings.load(default_settings),
    -- just a state variable so we can open an close the UI
    -- tables need to go here or they wont be updated!
    ui = T{
        is_open = T{ false, }, -- this has to be in a table to work with imGUI
        showAutoFlagWindow = T{ false, },
    }
}

local toggle_settings = function()
    roeManager.ui.is_open[1] = true;
end

local render_settings_ui = function()
	if (not roeManager.ui.is_open[1]) then
		-- don't do anything if is_open is false
		return;
	end

	local header_color = { 1.0, 0.75, 0.55, 1.0 };
    local settingsChanged = false
  
	-- imgui.SetNextWindowContentSize({ 430, 710 }); -- controls the size of the window

    if (imgui.Begin(('RoE Manager Settings v%s'):fmt(addon.version), roeManager.ui.is_open, ImGuiWindowFlags_AlwaysAutoResize)) then
        if imgui.InputText('Search', filterText, 256) then
            activeContent = nil;
        end

        if activeContent == nil then
            activeContent = T{};
            local filter = string.lower(filterText[1]);
            for _,entry in ipairs(fullContent) do
                if string.find(string.lower(entry.Name), filter, 1, true) then
                    activeContent:append(entry);
                end
            end
        end

        imgui.BeginChild('roe', { 300, 220 });
        for _,entry in ipairs(activeContent) do
            if imgui.Selectable(entry.Name, selectedROE and (selectedROE.Id == entry.Id)) then
                selectedROE = entry;
            end
        end
        imgui.EndChild();

        -- Buttons
        -- Flag
        if imgui.Button("Flag") and selectedROE then
            FlagRoe(selectedROE.Id)
        end

        imgui.SameLine(0, 30)

        if imgui.Button("Flag (Multisend)") and selectedROE then
            AshitaCore:GetChatManager():QueueCommand(0, ('/mss /rma flag %s'):fmt(selectedROE.Id));
        end

        -- Unflag
        if imgui.Button("Unflag") and selectedROE then
            UnflagFlagRoe(selectedROE.Id)
        end

        imgui.SameLine(0, 16)

        if imgui.Button("Unflag (Multisend)") and selectedROE then
            AshitaCore:GetChatManager():QueueCommand(0, ('/mss /rma unflag %s'):fmt(selectedROE.Id));
        end

        -- Autoflag list (Dailies unity etc)
        if imgui.Button("Autoflag") then
            roeManager.ui.showAutoFlagWindow[1] = not roeManager.ui.showAutoFlagWindow[1]
        end

        imgui.SameLine(0, 16)

        local remaining = math.max(0, os.difftime(nextDailyCheck, os.time()))
        local hours = math.floor(remaining / 3600)
        local minutes = math.floor((remaining % 3600) / 60)
        local seconds = math.floor(remaining % 60)

        -- Timer for when dailies will be autoflagged
        imgui.TextColored({ 1.0, 0.0, 0.0, 1.0 }, string.format('Next daily check: %s (%02d:%02d:%02d)', os.date('%I:%M %p', nextDailyCheck), hours, minutes, seconds))

        -- Extra Windows
        if roeManager.ui.showAutoFlagWindow[1] then
            if imgui.Begin('Autoflag Window', roeManager.ui.showAutoFlagWindow, ImGuiWindowFlags_AlwaysAutoResize) then

            -- Auto Flag
            imgui.BeginGroup()

            imgui.Text('Auto Flag')

            local autoFlagData =
            T{
                ['Daily'] = T{
                    [4082] =  'Vanquish Multple Enemies (D)',
                    [4083] =  'Buff Allies (D)',
                    [4084] =  'Heal for 500+ HP (D)',
                },

                ['Unity'] = T{
                    ['Communique'] = T{
                        [3000] = 'Unity Communique A (UC)',
                        [3009] = 'Unity Communique B (UC)',
                        [3018] = 'Unity Communique C (UC)',
                        [3027] = 'Unity Communique D (UC)',
                        [3036] = 'Unity Communique E (UC)',
                        [3045] = 'Unity Communique F (UC)',
                    },

                    ['Comrade'] = T{
                        [3001] = 'Home Point Comrade A (UC)',
                        [3019] = 'Home Point Comrade C (UC)',
                        [3037] = 'Home Point Comrade E (UC)',
                    },

                    ['Vanquish Enemies'] = T{
                        [3002] = 'Vanquish Multiple Enemies A (UC)',
                        [3011] = 'Vanquish Multiple Enemies B (UC)',
                        [3020] = 'Vanquish Multiple Enemies C (UC)',
                        [3029] = 'Vanquish Multiple Enemies D (UC)',
                        [3038] = 'Vanquish Multiple Enemies E (UC)',
                        [3047] = 'Vanquish Multiple Enemies F (UC)',
                    },

                    ['Van. Enemies w. Unity Leader'] = {
                        [3055] = 'Van. Enemies w. Unity Leader A (UC)',
                        [3056] = 'Van. Enemies w. Unity Leader B (UC)',
                        [3057] = 'Van. Enemies w. Unity Leader C (UC)',
                        [3058] = 'Van. Enemies w. Unity Leader D (UC)',
                        [3059] = 'Van. Enemies w. Unity Leader E (UC)',
                        [3060] = 'Van. Enemies w. Unity Leader F (UC)',
                    }
                },
            }

            if imgui.Button('Save Autoflag List') then
                settings.save()
                roeManager.ui.showAutoFlagWindow[1] = false
            end

            if imgui.Button('Select All ##AutoFlag') then
                for category, roeList in pairs(autoFlagData) do
                    for id, name in pairs(roeList) do
                        if type(id) == 'number' then
                            roeManager.settings.roeManager_Flags[id] = true
                        else
                            for roeId, roeName in pairs(name) do
                                roeManager.settings.roeManager_Flags[roeId] = true
                            end
                        end
                    end
                end

                settingsChanged = true
            end

            if imgui.Button('Deselect All ##AutoFlag') then
                for category, roeList in pairs(autoFlagData) do
                    for id, name in pairs(roeList) do
                        if type(id) == 'number' then
                            roeManager.settings.roeManager_Flags[id] = false
                        else
                            for roeId, roeName in pairs(name) do
                                roeManager.settings.roeManager_Flags[roeId] = false
                            end
                        end
                    end
                end

                settingsChanged = true
            end

            if imgui.BeginChild('AutoFlagList', { 250, 650 }, ImGuiChildFlags_Borders) then

                for category, roeList in pairs(autoFlagData) do

                    if imgui.CollapsingHeader(category) then

                        -- Handle categories with nested subcategories.
                        for id, name in pairs(roeList) do

                            if type(id) == 'number' then
                                local current = roeManager.settings.roeManager_Flags[id] or false

                                if imgui.Checkbox(name .. '##' .. id, { current }) then
                                    roeManager.settings.roeManager_Flags[id] = not current
                                    settingsChanged = true
                                end
                            else
                                if imgui.TreeNode(id) then

                                    for roeId, roeName in pairs(name) do
                                        local current = roeManager.settings.roeManager_Flags[roeId] or false

                                        if imgui.Checkbox(roeName .. '##' .. roeId, { current }) then
                                            roeManager.settings.roeManager_Flags[roeId] = not current
                                            settingsChanged = true
                                        end
                                    end

                                    imgui.TreePop()
                                end
                            end
                        end
                    end
                end

                imgui.EndChild()
            end

            imgui.EndGroup()
            
            end
            imgui.End()
        end

        imgui.End();

        if settingsChanged then
            settings.save()
        end
    end
end

local function FlagRoeDailies()
    for roeId, enabled in pairs(roeManager.settings.roeManager_Flags) do
        if enabled then
            local numericId = tonumber(roeId)

            if numericId then

                if Player.CurrentROE == nil then return end

                local roeFlagged = false

                for i = 2, 31 do
                    local roe = Player.CurrentROE[i]

                    if roe ~= nil then
                        if numericId ==  roe.Id then
                            roeFlagged = true
                            break
                        end
                    end
                end

                if not roeFlagged then
                    local packet = struct.pack('LHH', 0, numericId, 0)
                    AshitaCore:GetPacketManager():AddOutgoingPacket(0x10C, packet:totable())
                    coroutine.sleep(3)
                end
            end
        end
    end

    local now = os.time()
    local today = os.date('*t', now)

    today.hour = 11
    today.min = 0
    today.sec = 0

    nextDailyCheck = os.time(today)

    -- If 11 AM has already passed, schedule for tomorrow.
    if nextDailyCheck <= now then
        nextDailyCheck = nextDailyCheck + 86400
    end

    dailyCheckDone = true
end

ashita.events.register('packet_in', 'roe_incoming', function (e)
    if (e.id == 0x111) then -- Flag / Unflagging RoE packet
        Player.CurrentROE = {};
        local id = ashita.bits.unpack_be(e.data_raw, 0x100, 0, 12);
        local progress = ashita.bits.unpack_be(e.data_raw, 0x100, 12, 20);
        Player.CurrentROE[1] = { Id = id, Progress = progress };
        for i = 2,31 do
            id = ashita.bits.unpack_be(e.data_raw, (i * 4) - 4, 0, 12);
            progress = ashita.bits.unpack_be(e.data_raw, (i * 4) - 4, 12, 20);
            Player.CurrentROE[i] = { Id = id, Progress = progress };
        end
    elseif (e.id == 0x112) then -- Zoning Packet
        if Player.CompletedROE == nil then
            Player.CompletedROE = {};
        end
        local offset = 1024 * struct.unpack('H', e.data, 0x84 + 1);
        for i = 0,1023 do
            if (ashita.bits.unpack_be(e.data_raw, 4, i, 1) == 1) then
                Player.CompletedROE[offset + i] = true;
            else
                Player.CompletedROE[offset + 1] = nil;
            end
        end

        if os.time() > nextDailyCheck then
            FlagRoeDailies()
        end
    end
end)

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or (args[1] ~= '/rma' and args[1] ~= '/roemanager')) then
        return
    end

    e.blocked = true;

    if (#args < 2) then
        return;
    end

    if (args[2] == 'settings') or (args[2] == 'open') or (args[2] == 'help') or (args[2] == '?') then
		toggle_settings();
		return
    end

    if (#args < 3) then
        return;
    end

    if string.lower(args[2]) == 'flag' or string.lower(args[2]) == 'add' or string.lower(args[2]) == 'set' then
        local id = tonumber(args[3])

        if id == nil then
            print(chat.header("RoEManager") .. chat.message("RoE must be a number."))
            return
        end

        FlagRoe(id)
        return
    end

    if string.lower(args[2]) == 'unflag' or string.lower(args[2]) == 'delete' or string.lower(args[2]) == 'del' or string.lower(args[2]) == 'unset' then
        local id = tonumber(args[3])

        if id == nil then
            print(chat.header("RoEManager") .. chat.message("RoE must be a number."))
            return
        end

        UnflagFlagRoe(id)
        return
    end
end)

ashita.events.register('d3d_present', 'd3d_present', function ()
    if (isZoning) then 
        roeManager.ui.is_open[1] = false; -- Close settings gui
        return
    end

    if dailyCheckDone then
        print(chat.header("RoEManager") .. chat.message("All selected dailies flagged!"))
        dailyCheckDone = false
    end
    
    render_settings_ui();
end);

ashita.events.register('unload', 'roe_manager_unload', function ()
	--this line is important, it saves your settings when the addon unloads
	settings.save();
  end)