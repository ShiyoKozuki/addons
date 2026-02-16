
gLogManager = {};

LogStyle = {
    LogFailure = 0, --Red to game
    Error = 1, --Red to game and log
    Message = 2, --Blue to game and log
    Debug = 3 --To log only
};

local Player = {
    Loaded = false
};
local LogPath;
local LogDirectory = 'LogManager';

local playerIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
if playerIndex ~= 0 then
    local entity = AshitaCore:GetMemoryManager():GetEntity();
    local flags = entity:GetRenderFlags0(playerIndex);
    if (bit.band(flags, 0x200) == 0x200) and (bit.band(flags, 0x4000) == 0) then
        Player.Name = entity:GetName(playerIndex);
        Player.Id = entity:GetServerId(playerIndex);
        Player.Zone = 'Unknown';
        Player.Loaded = true;
        local zone =  AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
        if (zone > 0) then
            Player.ZoneId = zone;
            local zoneName = AshitaCore:GetResourceManager():GetString('zones.names', zone);
            if (type(zoneName) == 'string') and (string.len(zoneName) > 1) then
                Player.Zone =  zoneName;
            end
        end
    end
end

local function GetFileHeader(module)
    local time = os.date('*t');
    return ('[%02d:%02d:%02d] [%s] '):format(time.hour, time.min, time.sec, module);
end

local function GetChatHeader(module)
    return ('\30\81[\30\06%s\30\81]\30\01 '):format(module);
end

function gLogManager:Log(style, module, text)
    if (style ~= LogStyle.Debug) then
        local color = ('\30%c'):format(68);
        if style == LogStyle.Message then
            color = ('\30%c'):format(106);
        end

        local highlighted = color .. string.gsub(text, '$H', '\30\02');
        highlighted = string.gsub(highlighted, '$R', color);
        print(GetChatHeader(module) .. highlighted);
    end

    if style ~= LogStyle.LogFailure then
        local stripped = string.gsub(text, '$H', '');
        stripped = string.gsub(stripped, '$R', '');
        local file = io.open(LogPath, 'a');
        if not file then
            gLogManager:Log(LogStyle.LogFailure, 'LogManager', 'Failed to create or open file: $H' .. LogPath);
            return;
        end
        file:write(GetFileHeader(module) .. stripped .. '\n');
        file:close();
    end
end

local function CreateDirectories(path)
    local backSlash = string.byte('\\');
    for c = 1,#path,1 do
        if (path:byte(c) == backSlash) then
            local directory = string.sub(path,1,c);            
            if (ashita.fs.create_directory(directory) == false) then
                gLogManager:Log(LogStyle.LogFailure, 'LogManager', 'Failed to create directory: $H' .. directory);
                return;
            end
        end
    end
end

local function UpdateLogFile()
    local time = os.date('*t');
    if Player.Loaded then
        local filename = ('%04d%02d%02d_%02d%02d%02d_%s.log'):format(time.year, time.month, time.day, time.hour, time.min, time.sec, Player.Zone);
        LogPath = string.format('%slogs\\%s\\%s_%u\\%s', AshitaCore:GetInstallPath(), LogDirectory, Player.Name, Player.Id, filename);
    else
        local filename = ('%04d%02d%02d_%02d%02d%02d.log'):format(time.year, time.month, time.day, time.hour, time.min, time.sec);
        LogPath = string.format('%slogs\\%s\\Unknown\\%s', AshitaCore:GetInstallPath(), LogDirectory, filename);
    end
    CreateDirectories(LogPath);
end

function gLogManager:SetDirectory(directory)
    if (directory ~= LogDirectory) then
        LogDirectory = directory;
        UpdateLogFile()
    end
end

UpdateLogFile();


ashita.events.register('packet_in', 'LogManager_HandleIncomingPacket', function (e)
    if (e.id == 0x00A) then
        local id = struct.unpack('L', e.data, 0x04 + 1);
        local name = struct.unpack('c16', e.data, 0x84 + 1);
        local zoneId = struct.unpack('H', e.data, 0x30 + 1);
        local i,j = string.find(name, '\0');
        if (i ~= nil) then
            name = string.sub(name, 1, i - 1);
        end

        if (name ~= Player.Name) or (id ~= Player.Id) or (zoneId ~= Player.ZoneId) then
            Player.Name = name;
            Player.Id = id;
            Player.Loaded = true;
            Player.Zone = 'Unknown';
            Player.ZoneId = zoneId;
            if (zoneId > 0) then
                local zoneName = AshitaCore:GetResourceManager():GetString('zones.names', zoneId);
                if (type(zoneName) == 'string') and (string.len(zoneName) > 1) then
                    Player.Zone =  zoneName;
                end
            end
            UpdateLogFile();
        end
    end
end);