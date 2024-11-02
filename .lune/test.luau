--!strict
--[[
  Runs tests defined in *.test.luau files.

  Runs all tests under `packages` by default, optionally pass a list
  of directories to run tests from.

  Examples:
    lune test
    lune test packages/result
	
	Test files are files ending with `.test.luau`. They are able to access
	modules under `@testing/*`.

	The following modules are available:
		- `@testing/describe` - Creates a test block
		- `@testing/test` - Creates a test
		- `@testing/assertEq` - Asserts that two values are equal

	See `packages/result/init.test.luau` for an example.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

_G.UTIL_TARGET = "lune"

local function findTestFiles(dir: string): { string }
	local files = {}
	for _, name in fs.readDir(dir) do
		if fs.isDir(`{dir}/{name}`) and name ~= "dist" then
			for _, file in findTestFiles(`{dir}/{name}`) do
				table.insert(files, file)
			end
		elseif name:match("%.test%.luau$") then
			table.insert(files, `{dir}/{name}`)
		end
	end
	return files
end

local testFilePaths = {}
if #process.args > 0 then
	for _, dir in process.args do
		for _, file in findTestFiles(dir) do
			if not table.find(testFilePaths, file) then
				table.insert(testFilePaths, file)
			end
		end
	end
else
	for _, file in findTestFiles("packages") do
		table.insert(testFilePaths, file)
	end
end

type TestBlock = {
	type: "describe",
	name: string,
	children: { TestBlock },
} | {
	type: "test",
	name: string,
	fn: () -> (),
}

local function createTestLib(blocks: { TestBlock })
	local currentBlock: TestBlock? = nil
	local testLib = {}

	function testLib.describe(name: string, fn: () -> ())
		local block: TestBlock = {
			type = "describe",
			name = name,
			children = {},
		}

		if currentBlock and currentBlock.type == "describe" then
			table.insert(currentBlock.children, block)
		else
			table.insert(blocks, block)
		end

		local prevBlock = currentBlock
		currentBlock = block
		fn()
		currentBlock = prevBlock
	end

	function testLib.test(name: string, fn: () -> ())
		local block: TestBlock = {
			type = "test",
			name = name,
			fn = fn,
		}

		if currentBlock and currentBlock.type == "describe" then
			table.insert(currentBlock.children, block)
		else
			table.insert(blocks, block)
		end
	end

	function testLib.assertEq<T>(value: T, expected: T): boolean
		local eq = value == expected
		if not eq then
			error(`Equality Failed\n  Expected: {expected}\n  Received: {value}`, 2)
		end
		return true
	end

	local randomTuple = require("./test-lib/randomTuple")
	local possibleTypes = { "number", "string", "boolean" }
	local alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"

	local function createRandomTuple(types: { string }): { any }
		local t: { any } = {}
		for i, type in types do
			if type == "number" then
				t[i] = math.random(0, 999)
			elseif type == "string" then
				local s = ""
				for _ = 1, math.random(5, 10) do
					local randomChar = math.random(#alphabet)
					s ..= alphabet:sub(randomChar, randomChar)
				end
				t[i] = s
			elseif type == "boolean" then
				t[i] = math.random() > 0.5
			else
				error(`Unknown type: {type}`, 2)
			end
		end
		return t
	end

	local function createAssertEqTuple(name: string, tuple: { any }): (...any) -> ()
		local s = ""

		s ..= "local "
		for i = 1, #tuple do
			s ..= `v{i}`
			if i < #tuple then
				s ..= ", "
			end
		end
		s ..= " = ...\n"

		s ..= "if\n"
		s ..= `  select("#", ...) ~= {#tuple} or\n`

		local tupleStr = ""
		for i, v in tuple do
			local valueStr = if typeof(v) == "string" then `"{v}"` else `{v}`
			s ..= `  v{i} ~= {valueStr}`
			tupleStr ..= valueStr

			if i < #tuple then
				s ..= " or\n"
				tupleStr ..= "\t"
			end
		end
		s ..= "\nthen\n"
		s ..= '  local s = ""\n'
		s ..= '  for i = 1, select("#", ...) do'
		s ..= "    local v = select(i, ...)\n"
		s ..= '    s ..= if typeof(v) == "string" then `"{v}"` else `{v}`\n'
		s ..= '    if i < select("#", ...) then\n'
		s ..= '      s ..= "\\t"\n'
		s ..= "    end\n"
		s ..= "  end\n"
		s ..= `  error(\`Equality Failed\\n  Expected: \\t{tupleStr}\\n  Received: \\t\{s}\`, 2)\n`
		s ..= "end"

		return luau.load(s, { debugName = name })
	end

	local function createMapTuple(name: string, types: { string }): (...any) -> ...any
		local s = ""

		s ..= "local "
		for i = 1, #types do
			s ..= `v{i}`
			if i < #types then
				s ..= ", "
			end
		end
		s ..= " = ...\n"

		s ..= "return "
		for i, type in types do
			if type == "string" then
				if math.random() > 0.5 then
					s ..= `v{i}:upper()`
				else
					s ..= `v{i}:reverse()`
				end
			elseif type == "number" then
				if math.random() > 0.5 then
					s ..= `v{i} + {math.random(5)}`
				else
					s ..= `v{i} - {math.random(5)}`
				end
			elseif type == "boolean" then
				s ..= `not v{i}`
			else
				error(`Unknown type: {type}`, 2)
			end

			if i < #types then
				s ..= ", "
			end
		end

		return luau.load(s, { debugName = name })
	end

	function testLib.randomTuple(f: (randomTuple.TupleFunctions, ...any) -> ())
		local types = {}
		for i = 1, math.random(10) do
			types[i] = possibleTypes[math.random(#possibleTypes)]
		end

		local originalTuple = createRandomTuple(types)
		local otherTuple = createRandomTuple(types)

		local map = createMapTuple("map", types)

		local tupleFunctions = {
			map = map,
			other = function()
				return unpack(otherTuple)
			end,
			assertEq = createAssertEqTuple("assertEq", originalTuple),
			assertEqMapped = createAssertEqTuple("assertEqMapped", { map(unpack(originalTuple)) }),
			assertEqOther = createAssertEqTuple("assertEqOther", otherTuple),
			assertEqOtherMapped = createAssertEqTuple("assertEqOtherMapped", { map(unpack(otherTuple)) }),
		}

		f(tupleFunctions, unpack(originalTuple))
	end

	return testLib
end

local function createTestEnv(file: string, testLib)
	local testEnv = {}
	function testEnv.require(path)
		if path:match("^@testing/") then
			local name = path:sub(10)
			local mod = testLib[name]
			if not mod then
				error(`Unkwown require: {path}`, 2)
			end
			return mod
		end
		if path:match("^@lune/") then
			return require(path) :: any
		end
		return require(`../{file}/../{path}`) :: any
	end
	return testEnv
end

local function getTestBlocks(
	file: string
): { success: true, blocks: { TestBlock } } | { success: false, err: string, traceback: string }
	local blocks: { TestBlock } = {}
	local testLib = createTestLib(blocks)
	local testEnv = createTestEnv(file, testLib)

	local code = fs.readFile(file)
	local bytecode = luau.compile(code)
	local fn = luau.load(bytecode, {
		debugName = file,
		environment = testEnv,
	})

	local success, result = xpcall(fn, function(err)
		return { err = err, traceback = debug.traceback(nil, 3) }
	end)

	if success then
		return { success = true, blocks = blocks }
	else
		return { success = false, err = result.err, traceback = result.traceback }
	end
end

local function printErr(err: string, traceback: string)
	stdio.ewrite(stdio.color("red"))
	stdio.ewrite(stdio.style("bold"))
	stdio.ewrite(err .. "\n\n")
	stdio.ewrite(stdio.style("reset"))
	stdio.ewrite(stdio.style("dim"))
	stdio.ewrite("[Stack Begin]\n")
	stdio.ewrite(stdio.style("reset"))
	stdio.ewrite(traceback)
	stdio.ewrite(stdio.style("dim"))
	stdio.ewrite("[Stack End]\n\n")
	stdio.ewrite(stdio.style("reset"))
end

local files: { { path: string, blocks: { TestBlock } } } = {}
for _, path in testFilePaths do
	local result = getTestBlocks(path)

	if not result.success then
		printErr(result.err, result.traceback)
		stdio.ewrite("\27[1;41m FAIL \27[0m\n")
		stdio.ewrite("An error occurred whilst initializing tests\n")

		return process.exit(1)
	end

	table.insert(files, { path = path, blocks = result.blocks })
end

local function countTests(blocks: { TestBlock }): number
	local count = 0
	for _, block in blocks do
		if block.type == "test" then
			count += 1
		elseif block.type == "describe" then
			count += countTests(block.children)
		end
	end
	return count
end

local totalTestCount = 0
local passedTestCount = 0
local failedTestCount = 0

for _, file in files do
	totalTestCount += countTests(file.blocks)
end

print(`Running {stdio.style("bold")}{totalTestCount}{stdio.style("reset")} tests\n`)

local function runBlock(block: TestBlock, level)
	if block.type == "describe" then
		stdio.write(string.rep("  ", level))
		stdio.write(stdio.style("dim"))
		stdio.write(block.name)
		stdio.write(stdio.style("reset"))
		stdio.write("\n")

		for _, child in block.children do
			runBlock(child, level + 1)
		end
	else
		stdio.write(string.rep("  ", level))

		local success, result = xpcall(block.fn :: () -> ...any, function(err)
			return { err = err, traceback = debug.traceback(nil, 3) }
		end)

		if success then
			stdio.write(stdio.color("green"))
			stdio.write("PASS ")
			stdio.write(stdio.style("reset"))
			stdio.write(block.name)
			stdio.write("\n")
			passedTestCount += 1
		else
			stdio.write(stdio.color("red"))
			stdio.write("FAIL ")
			stdio.write(stdio.style("reset"))
			stdio.write(block.name)
			stdio.write("\n\n")
			failedTestCount += 1

			printErr(result.err, result.traceback)
		end
	end
end

for _, file in files do
	print(`{stdio.style("bold")}{file.path}{stdio.style("reset")}`)
	for _, block in file.blocks do
		runBlock(block, 1)
	end
	print("")
end

if failedTestCount > 0 then
	stdio.ewrite("\27[1;41m FAIL \27[0m\n\n")
else
	stdio.ewrite("\27[1;42m PASS \27[0m\n\n")
end

stdio.write(`{stdio.style("bold")}{passedTestCount}{stdio.style("reset")} passed, `)
if failedTestCount > 0 then
	stdio.write(`{stdio.style("bold")}{stdio.color("red")}{failedTestCount}{stdio.style("reset")} failed, `)
else
	stdio.write(`{stdio.style("bold")}{failedTestCount}{stdio.style("reset")} failed, `)
end
stdio.write(`{stdio.style("bold")}{totalTestCount}{stdio.style("reset")} total.\n\n`)

if failedTestCount > 0 then
	process.exit(1)
end
