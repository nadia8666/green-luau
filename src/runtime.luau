local main = require("./main")

local json = require("@std/json")
local io = require("@std/io")
local fs = require("@std/fs")

local args = { ... }

local mode, ain

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
	ain = args[_in + 1]
end

if not ain or not mode then
	return
end

if mode == "build" then
	local success, output, stage = main.run_full(fs.readFileToString(ain))
	local value = {
		success = success,
		output = output,
		mode = stage,
	}

	io.write(json.serialize(value))

	return
elseif mode == "check" then
	local out = main.check(fs.readFileToString(ain))

	io.write(json.serialize(out))

	return
elseif mode == "lint" then
	local success, output = main.lint(fs.readFileToString(ain))
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
