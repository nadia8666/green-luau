local main = require("./main")
local util = require("./components/util")

local json = require("@std/json")
local io = require("@std/io")
local fs = require("@std/fs")

local args = { ... }

local mode, in_path, in_source, debug_mode

if table.find(args, "--build") then
	mode = "build"
end

if table.find(args, "--lint") then
	mode = "lint"
end

if table.find(args, "--check") then
	mode = "check"
end

local _in = table.find(args, "-i")
if _in then
	in_path = args[_in + 1]
end

local in_c = table.find(args, "-ic")
if in_c then
	in_source = args[in_c + 1]
end

local _debug = table.find(args, "-d")
if _debug then
	debug_mode = true
end

if (not in_path and not in_source) or not mode then
	return
end

util.debug_mode = debug_mode or false

if mode == "build" then
	local success, output, stage = main.run_full(in_source or fs.readFileToString(in_path))
	local value = {
		success = success,
		output = output,
		mode = stage,
	}

	io.write(json.serialize(value))

	return
elseif mode == "check" then
	local out = main.check(in_source or fs.readFileToString(in_path))

	io.write(json.serialize(out))

	return
elseif mode == "lint" then
	local success, output = main.lint(in_source or fs.readFileToString(in_path))
	local value = {
		success = success,
		output = output,
	}

	io.write(json.serialize(value))

	return
end

local err = "could not process files, invalid args?"
io.write({ success = false, output = err })
error(err)
