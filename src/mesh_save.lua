
-- Polaris-Nav, advanced pathfinding as a library and service
-- Copyright (C) 2021 Tyler R. Herman-Hoyer
-- tyler@hoyerz.com
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU Lesser General Public
-- License as published by the Free Software Foundation; either
-- version 3 of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- Lesser General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.



local e = require(script.Parent)


e:load 'mesh_format'
e:load 'save_data'

local F = e.format
local util = e.util

local Point = e.Point
local Surface = e.Surface
local Connection = e.Connection
local CConnection = e.CConnection
local Mesh = e.Mesh

local function a(to, str)
	to[#to + 1] = str
	if to.size then
		to.size = to.size + #str
	end
end

function Point.format:save(data, context)
	local sight = {}
	local id = self.id
	for point, cost in next, self.sight do
		if point.id <= id then
			sight[point] = cost
		end
	end
	return util.save(data, sight, F.PointSight, context)
end

function CConnection.format:save(data, context)
	local action = e[self.type]
	if self.save then
		a(data, util.s2b(self:save()))
	end
end



return true