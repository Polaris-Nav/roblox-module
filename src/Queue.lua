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

local Queue = {}
local MT = {
	__index = Queue
}

setmetatable(Queue, {
	__call = function(self, t)
		return setmetatable(t or {}, MT)
	end,
})

function Queue:pop()
	local cur = 1
	local child = 2 * cur
	local min = self[1]
	local element = self[#self]
	
	self[#self] = nil
	if #self == 0 then
		return min
	end

	while child < #self do
		if self[child + 1].value < self[child].value then
			child = child + 1
		end
		if element.value <= self[child].value then
			self[cur] = element
			element.index = cur

			return min
		else
			self[cur] = self[child]
			self[cur].index = cur
			cur = child
			child = 2 * cur
		end
	end
	if child == #self and element.value > self[child].value then
		self[cur] = self[child]
		self[cur].index = cur
		cur = child
	end
	self[cur] = element
	element.index = cur
	
	return min
end

function Queue:insert(element)
	local cur = #self + 1
	local p = (cur - cur % 2) / 2
	while p > 0 do
		if element.value <= self[p].value then
			self[cur] = self[p]
			self[cur].index = cur
			cur = p
			p = (cur - cur % 2) / 2
		else
			self[cur] = element
			element.index = cur
			return
		end
	end
	self[cur] = element
	element.index = cur
end

function Queue:decrease(element)
	local cur = element.index
	local p = (cur - cur % 2) / 2
	while p > 0 do
		if element.value <= self[p].value then
			self[cur] = self[p]
			self[cur].index = cur
			cur = p
			p = (cur - cur % 2) / 2
		else
			self[cur] = element
			element.index = cur
			return
		end
	end
end

return Queue