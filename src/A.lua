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

local GOAL = e.Point.GOAL
local ACTION = e.Point.ACTION
local Queue = e.Queue

local A = {}

local function new(parent, pt, val, len, action)
	return {
		value = val;
		point = pt;
		parent = parent;
		closed = false;
		length = len;
		action = action;
	}
end

function A.find_path(s_ground, g_ground, opts)
	assert(s_ground.surface, 'The start point has no nav mesh below it')
	assert(g_ground.surface, 'The goal point has no nav mesh below it')

	-- Find the positions on the surfaces below the start and goal
	local pos_s = s_ground.surface:project_down(s_ground.point)
	local pos_g = g_ground.surface:project_down(g_ground.point)
	local p_goal = e.Point.new(pos_g, GOAL)
	local goal_record = new(nil, p_goal, math.huge, math.huge)

	-- If points lay on the same surface
	if s_ground.surface == g_ground.surface then
		return {goal_record}
	end

	-- If points have line of sight
	if s_ground.mesh == g_ground.mesh
		and s_ground.surface:line_of_sight(pos_s, pos_g)
	then
		return {goal_record}
	end

	-- Initial state
	local fringe = Queue()
	local records = { [p_goal] = goal_record }
	local record, cur_p

	fringe:insert(goal_record)

	local function consider(child_p, value, action)
		local child = records[child_p]
		if not child then
			child = new(record, child_p, value, record.length + 1, action)
			records[child_p] = child
			fringe:insert(child)
			return
		elseif not child.closed and value < child.value then
			child.value = value
			child.parent = record
			child.length = record.length + 1
			child.action = action
			fringe:decrease(child)
		end
	end

	-- Begin searching points connected to the start
	local s_adj = s_ground.mesh:get_visible(s_ground.point, s_ground.surface)
	for p, cost in next, s_adj do
		record = new(nil, p, cost, 1)
		records[p] = record
		fringe:insert(record)
	end

	-- Consider the goal when we reach these
	local finish = g_ground.mesh:get_visible(g_ground.point, g_ground.surface)

	while #fringe > 0 do
		record = fringe:pop()

		-- Check if we've reached the goal
		if record == goal_record then
			break
		end

		record.closed = true
		local cur_p = record.point
		local cur_v = record.value

		-- Special case for points connected to goal
		if finish[cur_p] then
			consider(p_goal, cur_v + finish[cur_p])
		end

		-- Go through all visible neighbors
		for to, cost in next, cur_p.sight do
			consider(to, cur_v + cost)
		end

		-- Handle actions associated with this point
		if cur_p.ptype == ACTION then
			for s, c_conn in next, cur_p.surfaces do
				local actions = c_conn:consider(
					opts.agent, cur_p, cur_v, cur_v)
				for i, action in ipairs(actions) do
					consider(action.to, cur_v + action.cost, action)
				end
			end
		end
	end

	-- No path to goal
	if goal_record.length == math.huge then
		return {}
	end

	local cur = goal_record
	local path = {}
	for i = cur.length, 1, -1 do
		table.insert(path, i, cur)
		cur = cur.parent
	end
	return path
end

return A