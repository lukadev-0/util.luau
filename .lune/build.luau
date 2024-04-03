--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local IS_CI = process.env.CI == "true"

local WALLY_SCOPE = "lukadev-0"

type Context = {
	rootDir: string,
	pkgDir: string,
	outDir: string,
	outPkgDir: string,
	outRbxmDir: string,
	outWorkDir: string,
	outWorkPkgDir: string,

	packages: { [string]: Package },

	darkluaConfig: {
		base: string,
		default: string,
		roblox: string,
	},
}

type Package = {
	path: string,
	config: PackageConfig,
}

type PackageConfig = {
	name: string,
	description: string,
	version: string,

	types: { string }?,
	dependencies: { string }?,
}

type ProgressReporter = {
	report: (message: string) -> (),
	log: (message: string) -> (),
	finish: () -> (),
	fail: (message: string) -> (),
}

local function noop() end

local function getPackages(dir: string): { [string]: Package }
	local packages = {}
	for _, entry in fs.readDir(dir) do
		if fs.isDir(`{dir}/{entry}`) then
			local configFile = fs.readFile(`{dir}/{entry}/config.toml`)
			local config = serde.decode("toml", configFile) :: PackageConfig

			packages[config.name] = {
				path = `{dir}/{entry}`,
				config = config,
			}
		end
	end
	return packages
end

local function createBuild(rootDir: string): Context
	local ctx = {}

	ctx.rootDir = rootDir
	ctx.pkgDir = `{rootDir}/packages`
	ctx.outDir = `{rootDir}/build`
	ctx.outPkgDir = `{ctx.outDir}/pkg`
	ctx.outRbxmDir = `{ctx.outDir}/rbxm`
	ctx.outWorkDir = `{ctx.outDir}/work`
	ctx.outWorkPkgDir = `{ctx.outWorkDir}/pkg`

	ctx.packages = getPackages(ctx.pkgDir)

	ctx.darkluaConfig = {}
	ctx.darkluaConfig.base = `{rootDir}/base.darklua.json`
	ctx.darkluaConfig.default = `{ctx.outWorkDir}/default.darklua.json`
	ctx.darkluaConfig.roblox = `{ctx.outWorkDir}/roblox.darklua.json`

	return ctx
end

local function prepareBuild(ctx: Context): ()
	if fs.isDir(ctx.outDir) then
		fs.removeDir(ctx.outDir)
	end

	fs.writeDir(ctx.outDir)
	fs.writeDir(ctx.outPkgDir)
	fs.writeDir(ctx.outRbxmDir)
	fs.writeDir(ctx.outWorkDir)
	fs.writeDir(ctx.outWorkPkgDir)

	local baseDarkluaConfigFile = fs.readFile(ctx.darkluaConfig.base)
	local baseDarkluaConfig = serde.decode("json", baseDarkluaConfigFile)

	local defaultDarkluaConfig = table.clone(baseDarkluaConfig)
	fs.writeFile(ctx.darkluaConfig.default, serde.encode("json", defaultDarkluaConfig, true))

	local robloxDarkluaConfig = table.clone(baseDarkluaConfig)
	robloxDarkluaConfig.rules = table.clone(baseDarkluaConfig.rules) :: { any }

	table.insert(robloxDarkluaConfig.rules, {
		rule = "convert_require",
		current = {
			name = "path",
		},
		target = {
			name = "roblox",

			-- Luau only supports requires with property-style indexing,
			-- this is important for typechecking.
			indexing_style = "property",
		},
	})

	table.insert(robloxDarkluaConfig.rules, 1, {
		rule = "inject_global_value",
		identifier = "UTIL_TARGET",
		value = "roblox",
	})

	fs.writeFile(ctx.darkluaConfig.roblox, serde.encode("json", robloxDarkluaConfig, true))
end

local function copyPackageSource(src: string, dest: string): ()
	fs.writeDir(dest)
	for _, entry in fs.readDir(src) do
		if fs.isDir(`{src}/{entry}`) then
			fs.writeDir(`{dest}/{entry}`)
			copyPackageSource(`{src}/{entry}`, `{dest}/{entry}`)
		else
			if entry:match("%.luau$") and not entry:match("%.test.luau$") then
				local contents = fs.readFile(`{src}/{entry}`)
				fs.writeFile(`{dest}/{entry}`, "--!strict\n" .. contents)
			end
		end
	end
end

local function spawnCommand(progress: ProgressReporter, command: string): ()
	local result = process.spawn(command, {}, {
		shell = true,
	})

	if result.ok then
		if result.stderr ~= "" then
			progress.log((result.stderr:gsub("%s$", "")))
		end
	else
		progress.fail(`command failed with {result.code}`)
		stdio.write("\n")
		stdio.write(stdio.style("bold"))
		stdio.write(command)
		stdio.write("\n\n")
		stdio.write(stdio.style("reset"))
		stdio.write(stdio.style("bold"))
		stdio.write("stdout\n")
		stdio.write(stdio.style("reset"))
		stdio.write(result.stdout)
		stdio.write("\n")
		stdio.write(stdio.style("bold"))
		stdio.write("stderr\n")
		stdio.write(stdio.style("reset"))
		stdio.write(result.stderr)

		stdio.write("\x1B[?25h")
		process.exit(1)
	end
end

local function createLinkingFile(targetPackage: PackageConfig, targetPath: string): string
	local s = ""
	s ..= "--!strict\n"
	s ..= `local pkg = require("{targetPath}")\n`
	if targetPackage.types ~= nil then
		for _, type in targetPackage.types do
			s ..= `export type {type} = pkg.{type}\n`
		end
	end
	s ..= "return pkg\n"

	return s
end

local function buildPackage(ctx: Context, progress: ProgressReporter, package: Package): ()
	progress.report("copying source files")

	local workPkgDir = `{ctx.outWorkPkgDir}/{package.config.name}`
	copyPackageSource(package.path, workPkgDir)

	local outDir = `{ctx.outPkgDir}/{package.config.name}`
	fs.writeDir(outDir)

	progress.report("processing files for default")
	spawnCommand(
		progress,
		`darklua process -c {ctx.darkluaConfig.default} {workPkgDir} {outDir}/default/{package.config.name}`
	)

	progress.report("processing files for roblox")
	spawnCommand(
		progress,
		`darklua process -c {ctx.darkluaConfig.roblox} {workPkgDir} {outDir}/roblox/{package.config.name}`
	)

	if package.config.dependencies then
		progress.report("creating dependency linking files for default")
		for _, dependencyName in package.config.dependencies do
			local dependency = ctx.packages[dependencyName]
			if dependency == nil then
				progress.fail(`dependency {dependencyName} not found`)
				process.exit(1)
			end

			fs.writeFile(
				`{outDir}/default/{dependencyName}.luau`,
				createLinkingFile(dependency.config, `../../{dependencyName}`)
			)
		end
	end

	progress.report("creating main linking file for default")
	do
		fs.writeFile(`{outDir}/init.luau`, createLinkingFile(package.config, `./default/{package.config.name}`))
	end

	progress.report("creating default.project.json for roblox")
	do
		local projectJson = {
			name = package.config.name,
			tree = {
				["$path"] = `./roblox/{package.config.name}`,
			},
		}

		fs.writeFile(`{outDir}/default.project.json`, serde.encode("json", projectJson, true))
	end

	progress.report("creating wally.toml")
	do
		local wallyToml = {
			package = {
				name = `{WALLY_SCOPE}/{package.config.name}`,
				version = package.config.version,
				description = package.config.description,
				license = "MIT",
				authors = { "LukaDev" },
				realm = "shared",
				registry = "https://github.com/UpliftGames/wally-index",
			},
			dependencies = {},
		}

		if package.config.dependencies then
			for _, dependencyName in package.config.dependencies do
				local dependency = ctx.packages[dependencyName]
				if dependency == nil then
					progress.fail(`dependency {dependencyName} not found`)
					process.exit(1)
				end

				wallyToml.dependencies[dependencyName] = `{WALLY_SCOPE}/{dependencyName}@{dependency.config.version}`
			end
		end

		fs.writeFile(`{outDir}/wally.toml`, serde.encode("toml", wallyToml, true))
	end

	progress.report("copying LICENSE")
	fs.copy(`{ctx.rootDir}/LICENSE`, `{outDir}/LICENSE`)

	progress.finish()
end

local function buildRbxms(ctx: Context, progress: ProgressReporter): ()
	local folder = roblox.Instance.new("Folder")
	folder.Name = "util"

	for _, package in ctx.packages do
		progress.report(`building RBXM for {package.config.name}`)

		local rbxmPath = `{ctx.outRbxmDir}/{package.config.name}.rbxm`

		spawnCommand(progress, `rojo build {ctx.outPkgDir}/{package.config.name}/default.project.json -o {rbxmPath}`)

		local instances = roblox.deserializeModel(fs.readFile(rbxmPath))
		for _, instance in instances do
			instance.Parent = folder
		end
	end

	progress.report("creating bundle RBXM")
	fs.writeFile(`{ctx.outDir}/util.rbxm`, roblox.serializeModel({ folder }))

	progress.finish()
end

local function createProgressReporter(name: string): ProgressReporter
	if IS_CI then
		return {
			report = noop,
			log = print,
			finish = function()
				print(`finished {name}`)
			end,
			fail = function(message)
				print(`failed {name}: {message}`)
			end,
		}
	else
		stdio.write(stdio.style("bold"))
		stdio.write(stdio.color("yellow"))
		stdio.write("building")
		stdio.write(stdio.style("reset"))
		stdio.write(" ")
		stdio.write(name)
		stdio.write(stdio.style("reset"))

		local offset = 11 + #name

		local lastMessage = ""

		return {
			report = function(message)
				lastMessage = message

				stdio.write(`\x1B[{offset}G`)
				stdio.write("\x1B[0K")
				stdio.write(stdio.style("dim"))
				stdio.write(message)
				stdio.write(stdio.style("reset"))
			end,
			log = function(message)
				stdio.write("\x1B[1G")
				stdio.write("\x1B[0K")
				print(message)
				stdio.write(stdio.style("bold"))
				stdio.write(stdio.color("yellow"))
				stdio.write("building")
				stdio.write(stdio.style("reset"))
				stdio.write(" ")
				stdio.write(name)
				stdio.write(" ")
				stdio.write(stdio.style("dim"))
				stdio.write(lastMessage)
				stdio.write(stdio.style("reset"))
			end,
			finish = function()
				stdio.write("\x1B[1G")
				stdio.write(stdio.style("bold"))
				stdio.write(stdio.color("blue"))
				stdio.write("finished")
				stdio.write(stdio.style("reset"))
				stdio.write(" ")
				stdio.write(name)
				stdio.write("\x1B[0K")
				stdio.write("\n")
			end,
			fail = function(message)
				stdio.write("\x1B[1G")
				stdio.write("\x1B[0K")
				stdio.write(stdio.style("bold"))
				stdio.write(stdio.color("red"))
				stdio.write("  failed")
				stdio.write(stdio.style("reset"))
				stdio.write(" ")
				stdio.write(name)
				stdio.write(" ")
				stdio.write(stdio.style("dim"))
				stdio.write(message)
				stdio.write("\x1B[0K")
				stdio.write("\x1B[?25h")
				stdio.write("\n")
			end,
		}
	end
end

local function build(rootDir: string): ()
	if not IS_CI then
		stdio.write("\x1B[?25l")
	end

	local ctx = createBuild(rootDir)

	local pkgCount = 0
	for _ in ctx.packages do
		pkgCount += 1
	end

	stdio.write("building ")
	stdio.write(stdio.style("bold"))
	stdio.write(`{pkgCount}`)
	stdio.write(stdio.style("reset"))
	stdio.write(" packages")
	stdio.write("\n\n")

	prepareBuild(ctx)

	for _, package in ctx.packages do
		local progress = createProgressReporter(package.config.name)
		buildPackage(ctx, progress, package)
	end

	stdio.write("\n")

	local rbxmProgress = createProgressReporter("rbxm")
	buildRbxms(ctx, rbxmProgress)

	stdio.write("\n")

	print("build finished")

	stdio.write("\x1B[?25h")
end

build(process.cwd)
