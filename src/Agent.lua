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
		model = model;
		root = model.HumanoidRootPart;
		humanoid = humanoid;
		mesh = mesh;
		cmd = nil;
	}, instance_MT)
end

local function to_2d(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function dist2d(p1, p2)
	local dx = p1.X - p2.X
	local dz = p1.Z - p2.Z
	return math.sqrt(dx * dx + dz * dz)
end

local function dot2d(v1, v2)
	return v1.X * v2.X + v1.Z * v2.Z
end

function Agent:reached(pos, udir, threshold)
	return dot2d(udir, self.root.Position - pos) > -threshold
end

function Agent:go(to)
	local my_ground = self.mesh:get_ground(self.root.Position, 2)
	if my_ground == nil then
		warn 'There is no ground under the agent.'
		return false
	end

	local to_ground = self.mesh:get_ground(to, 0.1)
	if to_ground == nil then
		warn 'There is no ground under the goal.'
		return false
	end

	local path = A.find_path(my_ground, to_ground, { agent = self })
	
	if #path == 0 then
		warn 'There is no path to the goal.'
		return false
	end

	local cmd = {}
	self.cmd = cmd

	local last_p = self.root.Position
	for i, record in ipairs(path) do
		if self.cmd ~= cmd then
			break
		end

		local to = record.point.v3
		if record.action then
			record.action:perform(self)
		else
			local udir = to_2d(to - last_p).Unit
			while self.cmd == cmd and not self:reached(to, udir, 0.3) do
				self.humanoid:Move(to_2d(to - self.root.Position))
				task.wait()
			end
		end
		last_p = to
	end

	if self.cmd == cmd then
		self.humanoid:Move(Vector3.zero)
		self.cmd = nil
	end

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

return setmetatable(Agent, class_MT)