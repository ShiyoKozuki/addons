--[[
    TEO DOES NOT CARE PUBLIC LICENSE
        Version 1, July 18 2016
    Copyright (C) 2016 TeoTwawki <https://github.com/TeoTwawki>
        Everyone is permitted to copy and distribute verbatim or modified copies
        of this license document, and changing it is allowed as long as the name is
        changed and you do not pretend it nor the associated code to be your original work.
    TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
    1. You may not represent the code this license applies to as your original work.
       This condition DOES NOT apply to any changes you make.
    2. Nothing! Do whatever you want!
       TEO DOES NOT CARE!
]]--

addon.author    = 'TeoTwawki'
addon.name      = 'getinfo'
addon.version   = '1.1'
addon.desc      = 'Prints out info about the current cursor target'
addon.link      = 'https://github.com/TeoTwawki/Teo-Ashita-addons'

require "common"

ashita.events.register('command', 'command_cb', function (e)
    --[[
    arg1 = command name
    arg2 = subcommand for extended data output
    arg3 = optional entity ID
    ]]
    local args = e.command:args()
    local target = AshitaCore:GetMemoryManager():GetTarget():GetServerId(0)
    local index  = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0)
    local entity = GetEntity(index)

    if #args >= 1 and (args[1]:ieq('/getinfo') or args[1]:ieq('/gi')) then
        if #args == 3 and tonumber(args[3]) then
            if tonumber(args[3]) then
                entity = GetEntity(bit.band(tonumber(args[3]), 0x0FFF))
            end

            if args[3] and not entity then
                print(string.format("Error: entity %s not found", args[3]))
                return
            end
        end

        if #args >= 2 and args[2]:any('?', 'help') or not entity then
            print("Usage:\n/getinfo optionalsubCommand optionalEntityID")
            print("Subcommands:\nflags\nlook")
            return
        end

        print(string.format("Name: %s  ID: %d (0x%08X)  Index: %d (0x%04X)", entity.Name, target, target, index, index))
        print(string.format("Speed: %f  Animation Speed  %d", entity.MovementSpeed * 10, entity.AnimationSpeed * 10))
        print(string.format("PosX: %f  PosY: %f  PosZ: %f", entity.Movement.LocalPosition.X, entity.Movement.LocalPosition.Y, entity.Movement.LocalPosition.Z))

        if #args >= 2 then
            if args[2]:any('flags') or (#args == 3 and args[3]:any('flags')) then
                print(string.format("Flags0: 0x%08X", entity.Render.Flags0)) -- Main Render Flags
                print(string.format("Flags1: 0x%08X", entity.Render.Flags1)) -- Name Flags (Party, Away, Anon)
                print(string.format("Flags2: 0x%08X", entity.Render.Flags2)) -- Name Flags (Bazaar, GM Icon, etc.)
                print(string.format("Flags3: 0x%08X", entity.Render.Flags3)) -- Entity Flags (Shadow)
                print(string.format("Flags4: 0x%08X", entity.Render.Flags4)) -- Name Flags (Name Visibility)
                print(string.format("Flags5: 0x%08X", entity.Render.Flags5)) -- Geomancer Indi's
                print(string.format("Flags6: 0x%08X", entity.Render.Flags6)) -- Unknown
                print(string.format("Flags7: 0x%08X", entity.Render.Flags7)) -- Overhead Flags (Hi-word: Jump Emote, Model Visibility etc.) (Low-word: Job Mastery Stars, Party Seek Mastery Star, etc. [Low-Byte:] Timer of some sort.)
                print(string.format("Flags8: 0x%08X", entity.Render.Flags8)) -- Overhead Flags (Job mastery party.)
            end

            if args[2]:any('look') or (#args == 3 and args[3]:any('look')) then
                local b01 = string.format("%02X", entity.Race)
                local b02 = string.format("%02X", entity.Look.Hair)
                local b03 = string.format("%04X", entity.Look.Head)
                local b04 = string.format("%04X", entity.Look.Body)
                local b05 = string.format("%04X", entity.Look.Hands)
                local b06 = string.format("%04X", entity.Look.Legs)
                local b07 = string.format("%04X", entity.Look.Feet)
                local b08 = string.format("%04X", entity.Look.Main)
                local b09 = string.format("%04X", entity.Look.Sub)
                local b10 = string.format("%04X", entity.Look.Ranged)
                local b11 = "00" -- unknown, maybe ammo byte?
                local fullMask = b01..b02..b03..b04..b05..b06..b07..b08..b09..b10..b11
                print(string.format("Race ID: 0x%s", b01))
                print(string.format("Hair model: 0x%s", b02))
                print(string.format("Head model: 0x%s", b03))
                print(string.format("Body model: 0x%s", b04))
                print(string.format("Hand model: 0x%s", b05))
                print(string.format("Legs model: 0x%s", b06))
                print(string.format("Feet model: 0x%s", b07))
                print(string.format("Mainhand model: 0x%s", b08))
                print(string.format("Offhand model ID: 0x%s", b09))
                print(string.format("Ranged model ID: 0x%s", b10))
                print("Full model Mask (minus index byte): "..fullMask)
            end
        end
    end

    return
end)