
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





local api = {}



function api.load_mesh(folder)
	-- Read mesh from save
	api:load 'mesh_load'
	local mesh = api.Mesh.load_dir(folder)

	-- Save line information in points
	-- Allows line of sight queries
	api:load 'mesh_line_of_sight'
	mesh:cache_lines()

	-- Load surfaces into the octree
	-- Allows finding the ground
	mesh:load_surfaces()

	return mesh
end

local mesh_cache = setmetatable({}, {
	__mode = 'v'
})
function api.agent(model, mesh)
	local loaded = mesh_cache[mesh]
	if not loaded then
		loaded = api.load_mesh(mesh)
		mesh_cache[mesh] = loaded
	end
	return api.Agent(model, loaded)
end


function api:load(name)
	if rawget(api, name) ~= nil then
		return
	end

	-- By default, search for the module in the root
	local module = script:FindFirstChild(name)

		or script.actions:FindFirstChild(name)

	local value
	if module then
		value = require(module)


	end


	api[name] = value
	return value
end




function api.info(text)
	print(text)

end

function api.warn(text)
	warn(text)

end

function api.error(text)
	warn(text)

end

return setmetatable(api, {__index = api.load})