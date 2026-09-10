--[[
* Addons - Copyright (c) 2025 Ashita Development Team
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

---@meta

---@class AddonManager
AddonManager = {};

---Returns the current number of loaded addons.
---@param self AddonManager
---@return number
---@nodiscard
function AddonManager:Count() end

---Returns the name of the addon at the given index.
---@param self AddonManager
---@param index number
---@return string|nil
---@nodiscard
function AddonManager:Get(index) end

---Returns if the given addon is loaded.
---@param self AddonManager
---@return boolean
---@nodiscard
function AddonManager:IsLoaded(name) end

---Returns the addons current state.
---@param self AddonManager
---@param name string
---@return number
function AddonManager:GetState(name) end

---Returns the addons author.
---@param self AddonManager
---@param name string
---@return string|nil
function AddonManager:GetAuthor(name) end

---Returns the addons description.
---@param self AddonManager
---@param name string
---@return string|nil
function AddonManager:GetDescription(name) end

---Returns the addons file name.
---@param self AddonManager
---@param name string
---@return string|nil
function AddonManager:GetFileName(name) end

---Returns the addons link.
---@param self AddonManager
---@param name string
---@return string|nil
function AddonManager:GetLink(name) end

---Returns the addons version.
---@param self AddonManager
---@param name string
---@return string|nil
function AddonManager:GetVersion(name) end

---Returns the addons current memory usage.
---@param self AddonManager
---@param name string
---@return string|nil
function AddonManager:GetMemoryUsage(name) end