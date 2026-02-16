--[[
* Addons - Copyright (c) 2021 Ashita Development Team
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

addon.name      = 'sneakvis';
addon.author    = 'Thorny';
addon.version   = '1.0';
addon.desc      = 'Cancels sneak and invisible when someone casts them on you while they are already active.';
addon.link      = 'https://ashitaxi.com/';

require('common');

local function GetBuffActive(matchBuff)
  local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();    
  for _, buff in pairs(buffs) do
    if buff == matchBuff then
      return true;
    end
  end
  return false;
end

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if (e.id == 0x028) then
		local actionType = ashita.bits.unpack_be( e.data:totable(), 10, 2, 4);
		if (actionType == 8) then
			local myId = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
			local actorId = struct.unpack('L', e.data, 0x05 + 1);
			local bitOffset = 150;
			while ((bitOffset + 40) < (e.size * 8)) do
				local targetId = ashita.bits.unpack_be( e.data:totable(), 0, bitOffset, 32);
				bitOffset = bitOffset + 63;
				local actionId = ashita.bits.unpack_be( e.data:totable(), 0, bitOffset, 17);
				bitOffset = bitOffset + 58;
				if ashita.bits.unpack_be( e.data:totable(), 0, bitOffset, 1) == 1 then
					bitOffset = bitOffset + 38;
				else
					bitOffset = bitOffset + 1;
				end
				
				if ashita.bits.unpack_be( e.data:totable(), 0, bitOffset, 1) == 1 then
					bitOffset = bitOffset + 35;
				else
					bitOffset = bitOffset + 1;
				end
				
				if (targetId == myId) then
					if (actionId == 136) and (actorId ~= myId) and GetBuffActive(69) then
						local packet = { 0x00, 0x00, 0x00, 0x00, 0x45, 0x00, 0x00, 0x00 };
						AshitaCore:GetPacketManager():AddOutgoingPacket(0xF1, packet);
					elseif (actionId == 137) and GetBuffActive(71) then
						local packet = { 0x00, 0x00, 0x00, 0x00, 0x47, 0x00, 0x00, 0x00 };
						AshitaCore:GetPacketManager():AddOutgoingPacket(0xF1, packet);
					elseif (actionId == 54) and GetBuffActive(37) then
						local packet = { 0x00, 0x00, 0x00, 0x00, 0x25, 0x00, 0x00, 0x00 };
						AshitaCore:GetPacketManager():AddOutgoingPacket(0xF1, packet);
					end
				end
			end
		end
	end
end);