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

local ACTION = e.Point.ACTION
local A = e.A

local Agent = {}
local instance_MT = {}
local props = {}
local class_MT = {}

function class_MT:__call(model, mesh)
	local humanoid = model:FindFirstChildOfClass 'Humanoid'
	assert(humanoid,
		'NPC model does not have a Humanoid')
	assert(model:FindFirstChild 'HumanoidRootPart',
		'NPC model does not have a HumanoidRootPart')
	local pos = model.HumanoidRootPart.Position
	return setmetatable({
		humanoid = humanoid;
		position = pos;
		ground = mesh:get_ground(pos);
	}, instance_MT)
end

function Agent:go(to)
	local to_ground = self.ground.mesh:get_ground(to)
	local path = A.find_path(self.ground, to_ground, { agent = self })
	
	if #path == 0 then
		return false
	end

	for i, record in ipairs(path) do
		if record.action then
			record.action:perform(self)
		else
			self.humanoid:MoveTo(record.point.v3)
			self.humanoid.MoveToFinished:Wait()
		end
	end
	self.ground = to_ground

	return true
end

function instance_MT:__index(key)
	local v = Agent[key]
	if v ~= nil then
		return v
	end

	v = props[key]
	if v ~= nil then
		return v(self)
	end
end

function props:speed()
	return self.humanoid.WalkSpeed
end

return setmetatable(Agent, class_MT)