--!nonstrict

local task = require("@std/task")
local fs = require("@std/fs")

local main = require("./main")
local util = require("./components/util")

local watchers: { [string]: typeof(fs.watch("")) } = {}

-- functions
function file_changed(path: string)
	if path:sub(#path - 4) ~= ".glua" then
		return
	end

	local name: string = path:split("/")
	name = name[#name]

	local new_contents = main.process(fs.readFileToString(path))
	if new_contents then
		local start = path:find("src")
		local out_path = path:gsub(".glua", ".luau")
		out_path = `{out_path:sub(0, start - 2)}/out/{out_path:sub(start + 4)}`

		if not fs.exists(out_path:sub(-#name)) then
			fs.createDirectory(out_path:sub(-#name), { makeParents = true })
		end

		local file = fs.open(out_path, "w+")
		if file then
			fs.write(file, new_contents)
		end

        print(`successfully transpiled {name}`)
    end
end

function watch_directory(path: string)
	task.spawn(function()
		local watcher = fs.watch(path)

		watchers[path] = watcher

		file_changed(path)
	end)
end

-- setup filesystem
do
	local iterator = fs.walk("./program/src", { recursive = true })
	local walker = iterator()
	while walker do
		local path = tostring(walker)

		local splits = path:split("\\")
		for index, path_component in splits do
			watch_directory(util.table.concat_up_to(splits, index, "/"))
		end

		walker = iterator()
	end
end

-- watch !(extremely performant)
while true do
	for path, watcher in watchers do
		local event = watcher:next()

		if event ~= nil then
			task.spawn(file_changed, path)
		end
	end
	task.wait()
end
