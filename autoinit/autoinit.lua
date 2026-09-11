--[[
* Addons - Copyright (c) 2024 Ashita Development Team
* Contact: https://www.ashitaxi.com/
* Contact: https://discord.gg/Ashita
*
* This file is part of Ashita.
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.
--]]

addon.name      = 'autoinit';
addon.author    = 'atom0s';
addon.version   = '1.0';
addon.desc      = 'Logs into and configures a character.';
addon.link      = 'https://ashitaxi.com/';

require 'common';
require 'win32types';

local chat  = require 'chat';
local ffi   = require 'ffi';
require('config')

ffi.cdef[[
    typedef int32_t (__cdecl* get_config_value_t)(int32_t);
    typedef int32_t (__cdecl* set_config_value_t)(int32_t, int32_t);
    typedef int32_t (__fastcall* get_config_entry_t)(int32_t, int32_t, int32_t);
    typedef int32_t (__cdecl* set_auto_offline_t)(int32_t);

    // Configuration Value Entry Definition
    typedef struct FsConfigSubject {
        uintptr_t   VTable;         /* The configuration entry VTable pointer. */
        uint32_t    m_configKey;    /* The configuration entry key. */
        int32_t     m_configValue;  /* The configuration entry value. */
        uint32_t    m_configType;   /* The configuration entry type. */
        char        m_polName[8];   /* The configuration entry PlayOnline name. */
        int32_t     m_minVal;       /* The configuration entry minimum value.  */
        int32_t     m_maxVal;       /* The configuration entry maximum value. (-1 if not used.) */
        int32_t     m_defVal;       /* The configuration entry default value. (Used when not able to clamp a value within min/max.) */
        uintptr_t   m_callbackList; /* The configuration entry callback linked list object. */
        int32_t     m_configProc;   /* The configuration entry flags. (0x01 means the value will force-update even if the value already matches.) */
    } FsConfigSubject;

    // CTkObject
    typedef struct CTkObject {
        int16_t             m_RecKind;
        int16_t             m_RecSub1;
    } CTkObject;

    // CTkMenuPrimitive
    typedef struct CTkMenuPrimitive {
        void*               vtbl;
        CTkObject           m_BaseObj;
        void*               m_pParentMCD;
        uint8_t             m_InputEnable;
        uint8_t             unknown000D;
        uint16_t            m_SaveCursol;
        uint8_t             m_Reposition;
        uint8_t             unknown0011[3];
    } CTkMenuPrimitive;

    // IwLicenceMenu
    typedef struct IwLicenceMenu {
        CTkMenuPrimitive    prim;
        int32_t             m_msg;
        int32_t             m_select;
        int32_t             m_IsEnd;
    } IwLicenceMenu;

    // IwLobbyMenu
    typedef struct IwLobbyMenu {
        CTkMenuPrimitive    prim;
        int32_t             m_firstf;
        int32_t             m_select;
        int32_t             m_IsEnd;
    } IwLobbyMenu;

    // IwSelectMenu
    typedef struct IwSelectMenu {
        CTkMenuPrimitive    prim;
        int32_t             m_select;
        int32_t             m_oldselect;
        int32_t             m_IsEnd;
    } IwSelectMenu;

    // IwYesNoMenu
    typedef struct IwYesNoMenu {
        CTkMenuPrimitive    prim;
        int32_t             m_select;
        int32_t             m_msg;
        int32_t             m_errcode;
        char                m_string[16];
        int32_t             m_IsEnd;
    } IwYesNoMenu;
]];

local autologin = T{
    enabled = false,
    slot = -1,
    ptrs = T{
        license     = 0,
        lobby       = 0,
        select      = 0,
        selectidx   = 0,
        yesno       = 0,
        main_sys    = 0,
    },
};

local config = T{
    get     = nil,
    set     = nil,
    this    = nil,
    info    = nil,
    offline = nil,
};

local initialized = false;
local function SendCommand(command, mode)
    if not mode then
        mode = -1;
    end
    AshitaCore:GetChatManager():QueueCommand(mode, command);
end
local function SetConfig(id, val)
    config.set(id, val);
    if (id == 65) then
        config.offline(val);
    end
end
local function TryInit()
    local main_sys = autologin.ptrs.main_sys;
    local ptr = ashita.memory.read_uint32(main_sys + 0x02);
    local off = ashita.memory.read_uint32(main_sys + 0x0C);
    local ptr = ashita.memory.read_uint32(ptr) + off - 4;
    local count = ashita.memory.read_uint32(ptr);
    if count == 0 then
        return false;
    end

    local sizeOfEntry = 140;
    local foundCommands = false;
    local active = T{};
    for i = 1,count do
        local offset = ((i - 1) * sizeOfEntry) + ptr + 4;
        local worldId = ashita.memory.read_uint16(offset + 6);
        local status = ashita.memory.read_uint16(offset + 8);
        local name = ashita.memory.read_string(offset + 12, 16):trimend('\x00');
        local server = ashita.memory.read_string(offset + 28, 16):trimend('\x00');
        local key = string.format('%s.%s', server, name);
        if (CONFIG.AUTO_CHARACTERS[key]) then
            autologin.slot = i-1;
        end
        
        local initData = CONFIG.LOGIN_COMMANDS[key];
        if initData then
            foundCommands = true;
            for _,command in ipairs(initData) do
                SendCommand(command);
            end
            if (initData.Commands) then
                for _,command in ipairs(initData.Commands) do
                    SendCommand(command);
                end
            end
            if (initData.Function) then
                initData.Function();
            end
        end

        if ((status == 1) and (worldId > 0)) then
            active:append(i-1);
        end
    end

    if not foundCommands then
        if type(CONFIG.DEFAULT_FUNCTION) == 'function' then
            CONFIG.DEFAULT_FUNCTION();
        end
    end

    if #active == 0 then
        autologin.slot = -2;
    end

    if #active == 1 then
        autologin.slot = active[1];
    end

    initialized = true;
    SetConfig(65, 0);
    return true;
end

local function TryPosition()
    local main_sys = autologin.ptrs.main_sys;
    local ptr = ashita.memory.read_uint32(main_sys + 0x02);
    local off = ashita.memory.read_uint32(main_sys + 0x0C);
    local ptr = ashita.memory.read_uint32(ptr) + off - 4;
    local count = ashita.memory.read_uint32(ptr);
    if count == 0 then
        return false;
    end

    local sizeOfEntry = 140;
    for i = 1,count do
        local offset = ((i - 1) * sizeOfEntry) + ptr + 4;
        local name = ashita.memory.read_string(offset + 12, 16):trimend('\x00');
        local server = ashita.memory.read_string(offset + 28, 16):trimend('\x00');
        local key = string.format('%s.%s', server, name);
        local initData = CONFIG.LOGIN_COMMANDS[key];
        if initData then
            for _,command in ipairs(initData) do
                if string.sub(command, 1, 5) == '/move' then
                    SendCommand(command);
                end
            end
            if (initData.Commands) then
                for _,command in ipairs(initData.Commands) do
                    if string.sub(command, 1, 5) == '/move' then
                        SendCommand(command);
                    end
                end
            end
            if (initData.Function) then
                initData.Function();
            end
        end
    end
end

local function get_menu_obj(ptr, t)
    if (ptr == 0) then return nil; end
    ptr = ashita.memory.read_uint32(ptr);
    if (ptr == 0) then return nil; end
    return ffi.cast(t:append('*'), ashita.memory.read_uint32(ptr));
end
local function get_menu_name()
    local ptr = AshitaCore:GetPointerManager():Get('menu');
    if (ptr == 0) then return nil; end
    ptr = ashita.memory.read_uint32(ptr);
    if (ptr == 0) then return nil; end
    ptr = ashita.memory.read_uint32(ptr);
    if (ptr == 0) then return nil; end
    ptr = ashita.memory.read_uint32(ptr + 0x04);
    if (ptr == 0) then return nil; end
    return ashita.memory.read_string(ptr + 0x46, 16);
end


local function do_login()
    local function step()
        local menu_names = T{
            'menu    ptc8lice',
            'menu    loby2win',
            'menu    dbnamese',
            'menu    ptc6yesn',
        };

        local name = get_menu_name();
        if (name == nil) then
            return;
        end
        name = name:trim();

        if (not menu_names:contains(name)) then
            return;
        end

        -- Handle the license agreement window..
        if (name:eq('menu    ptc8lice', true)) then
            g_pIwLicenceMenu = get_menu_obj(autologin.ptrs.license, 'IwLicenceMenu');
            if (g_pIwLicenceMenu ~= nil) then
                g_pIwLicenceMenu.m_select   = 0;
                g_pIwLicenceMenu.m_IsEnd    = 1;
            end
        end

        -- Handle the main menu..
        if (name:eq('menu    loby2win', true)) then
            if (not initialized) and (not TryInit()) then
                return;
            end
            g_pIwLobbyMenu = get_menu_obj(autologin.ptrs.lobby, 'IwLobbyMenu');
            if (g_pIwLobbyMenu ~= nil) then
                if (autologin.slot == -2) then
                    autologin.enabled = false;
                    return;
                end

                g_pIwLobbyMenu.m_select = 0;
                g_pIwLobbyMenu.m_IsEnd  = 1;
            end
        end

        -- Handle the character selection list..
        if (name:eq('menu    dbnamese', true)) then
            if (autologin.slot == -1) then
                autologin.enabled = false;
                return;
            end

            g_pIwSelectMenu = get_menu_obj(autologin.ptrs.select, 'IwSelectMenu');
            if (g_pIwSelectMenu ~= nil) then
                local ptr = ashita.memory.read_uint32(autologin.ptrs.selectidx);
                if (ptr) then
                    ashita.memory.write_uint32(ptr, autologin.slot);
                end
                g_pIwSelectMenu.m_select    = autologin.slot;
                g_pIwSelectMenu.m_oldselect = autologin.slot;
                g_pIwSelectMenu.m_IsEnd     = 1;
            end
        end

        -- Handle the character selection confirmation window..
        if (name:eq('menu    ptc6yesn', true)) then
            g_pIwYesNoMenu = get_menu_obj(autologin.ptrs.yesno, 'IwYesNoMenu');
            if (g_pIwYesNoMenu ~= nil) then
                g_pIwYesNoMenu.m_select = 0;
                g_pIwYesNoMenu.m_IsEnd  = 1;

                autologin.enabled = false;
            end
        end
    end

    while (autologin.enabled) do
        coroutine.yield();
        step();
    end
end

local executed = false;
ashita.events.register('load', 'load_cb', function (e)
    autologin.ptrs.license  = ashita.memory.find(0, 0, '895E1C895E14896E1889??????????EB??89??????????68', 0x0B, 0);
    autologin.ptrs.lobby    = ashita.memory.find(0, 0, '89412C8B15????????897C2410894230A1', 0x5, 0);
    autologin.ptrs.select   = ashita.memory.find(0, 0, '89412C8B15????????897C2410894230A1', 0x11, 0);
    autologin.ptrs.selectidx= ashita.memory.find(0, 0, 'A1????????8B5108406689424C8B4908668B414C50E8', 0x01, 0);
    autologin.ptrs.yesno    = ashita.memory.find(0, 0, '895E1C895E14896E1889??????????EB??89??????????68', 0x47, 0);
    autologin.ptrs.main_sys = ashita.memory.find(0, 0, '8B0D????????8D04808B8481????????C3', 0, 0);
    
    -- Obtain the needed function pointers..
    local ptr = ashita.memory.find(0, 0, '8B0D????????85C974??8B44240450E8????????C383C8FFC3', 0, 0);
    config.get = ffi.cast('get_config_value_t', ptr);
    config.set = ffi.cast('set_config_value_t', ashita.memory.find(0, 0, '85C974??8B4424088B5424045052E8????????C383C8FFC3', -6, 0));
    config.info = ffi.cast('get_config_entry_t', ashita.memory.find(0, 0, '8B490485C974108B4424048D14808D04508D0481C2040033C0C20400', 0, 0));
    config.offline = ffi.cast('set_auto_offline_t', ashita.memory.find(0, 0, '568B74240885F674??B889888888F7EE', 0, 0));

    -- Obtain the 'this' pointer for the configuration data..
    config.this = ffi.cast('uint32_t**', ptr + 2)[0][0];

    -- Ensure all pointers are valid..
    assert(config.get ~= nil, chat.header('config'):append(chat.error('Error: Failed to locate required \'get\' function pointer.')));
    assert(config.set ~= nil, chat.header('config'):append(chat.error('Error: Failed to locate required \'set\' function pointer.')));
    assert(config.info ~= nil, chat.header('config'):append(chat.error('Error: Failed to locate required \'info\' function pointer.')));
    assert(config.this ~= 0, chat.header('config'):append(chat.error('Error: Failed to locate required \'this\' object pointer.')));
    assert(config.offline ~= 0, chat.header('config'):append(chat.error('Error: Failed to locate required \'SetAutoOffline\' function pointer.')));
    
    for _,arg in ipairs(e:args()) do
        if string.lower(arg) == 'norun' then
            executed = true;
        end
    end
end);

ashita.events.register('d3d_present', 'singleton_login', function()
    if (addon.instance.state == 1) and (not executed) then
        executed = true;
        if (not autologin.ptrs:all(function (v) return v ~= nil; end)) then
            error(chat.header(addon.name):append(chat.error('Error: Failed to locate required menu object pointer(s).')));
            return;
        end
        if (AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0) == 0) then
            autologin.enabled = true;
            do_login();
        else
            TryInit()
        end
        (function() ashita.events.unregister('d3d_present', 'singleton_login') end):oncef(1);
    end
end);

--[[
* event: unload
* desc : Event called when the addon is being unloaded.
--]]
ashita.events.register('unload', 'unload_cb', function ()
    autologin.enabled = false;
end);

ashita.events.register('command', 'command_cb', function (e)
    if (e.command == "/fixpos") then
        TryPosition();
        e.blocked = true;
    end
end);

local activatedIds = {};
local pendingRun;
local function ConfigureCharacter(fullConfig)
    while (true) do
        local playerIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
        if (playerIndex ~= 0) then
            local flags = AshitaCore:GetMemoryManager():GetEntity():GetRenderFlags0(playerIndex);
            if (bit.band(flags, 0x200) == 0x200) and (bit.band(flags, 0x4000) == 0) then
                break;
            end
        end
        coroutine.sleep(1);
    end
    if fullConfig then
        for _,setting in ipairs(CONFIG.FFXI_CONFIG) do
            SetConfig(setting.Id, setting.Value);
        end
        print(chat.header('AutoInit') .. chat.message("Flushed settings."));
    else
        SetConfig(65, 0);
        --print(chat.header('AutoInit') .. chat.message("Flushed autodisconnect."));
    end
    pendingRun = nil;
end

ashita.events.register('packet_in', 'autoconfig_packet_in', function(e)
    if (e.id == 0x00A) and (pendingRun == nil) then
        local id = struct.unpack('L', e.data, 0x04 + 1);
        local fullConfig = (activatedIds[id] == nil);
        ashita.tasks.oncef(1, ConfigureCharacter:bind1(fullConfig));
        activatedIds[id] = true;
        pendingRun = true;
    end
end);

do
    local playerId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
    if (playerId > 0) then
        activatedIds[playerId] = true;
        ashita.tasks.oncef(1, ConfigureCharacter:bind1(true));
        pendingRun = true;
    end
end