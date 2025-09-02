--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local IS_CI = process.env.CI == "true"

local WALLY_SCOPE = "lukadev-0"

local function pesdeify(str: string): string
	return str:gsub("-", "_")
end

local packageMetadata = {
	license = "MIT",
	authors = { "LukaDev <luka@lukadev.me> (https://lukadev.me/)" },
	realm = "shared",
	repository = "https://github.com/lukadev-0/util.luau",
}

type Context = {
	rootDir: string,
	pkgDir: string,
	outDir: string,
	outWorkDir: string,
	outWorkPkgDir: string,

	outWallyDir: string,
	outPesdeDir: string,
	outRbxmDir: string,

	pesdeWorkspaceMembers: { string },
	rbxms: { string },

	packages: { [string]: Package },

	darkluaConfig: {
		base: string,
		default: string,
		lune: string,
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
	targets: { string },
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
	ctx.outWorkDir = `{ctx.outDir}/work`
	ctx.outWorkPkgDir = `{ctx.outWorkDir}/pkg`

	ctx.outWallyDir = `{ctx.outDir}/wally`
	ctx.outPesdeDir = `{ctx.outDir}/pesde`
	ctx.outRbxmDir = `{ctx.outDir}/rbxm`

	ctx.pesdeWorkspaceMembers = {}
	ctx.rbxms = {}

	ctx.packages = getPackages(ctx.pkgDir)

	ctx.darkluaConfig = {}
	ctx.darkluaConfig.base = `{rootDir}/base.darklua.json`
	ctx.darkluaConfig.default = `{ctx.outWorkDir}/default.darklua.json`
	ctx.darkluaConfig.lune = `{ctx.outWorkDir}/lune.darklua.json`
	ctx.darkluaConfig.roblox = `{ctx.outWorkDir}/roblox.darklua.json`

	return ctx
end

local function prepareBuild(ctx: Context): ()
	if fs.isDir(ctx.outDir) then
		fs.removeDir(ctx.outDir)
	end

	fs.writeDir(ctx.outDir)
	fs.writeDir(ctx.outWorkDir)
	fs.writeDir(ctx.outWorkPkgDir)

	fs.writeDir(ctx.outWallyDir)
	fs.writeDir(ctx.outPesdeDir)
	fs.writeDir(ctx.outRbxmDir)

	local baseDarkluaConfigFile = fs.readFile(ctx.darkluaConfig.base)
	local baseDarkluaConfig = serde.decode("json", baseDarkluaConfigFile)

	local defaultDarkluaConfig = table.clone(baseDarkluaConfig)
	fs.writeFile(ctx.darkluaConfig.default, serde.encode("json", defaultDarkluaConfig, true))

	local luneDarkluaConfig = table.clone(baseDarkluaConfig)
	luneDarkluaConfig.rules = table.clone(baseDarkluaConfig.rules) :: { any }

	table.insert(luneDarkluaConfig.rules, 1, {
		rule = "inject_global_value",
		identifier = "UTIL_TARGET",
		value = "lune",
	})

	fs.writeFile(ctx.darkluaConfig.lune, serde.encode("json", luneDarkluaConfig, true))

	local robloxDarkluaConfig = table.clone(baseDarkluaConfig)
	robloxDarkluaConfig.rules = table.clone(baseDarkluaConfig.rules) :: { any }

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
	local result = process.exec(command, {}, {
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

local function createReadme(package: Package): string
	local s = ""
	s ..= `# {package.config.name}\n\n`
	s ..= `{package.config.description}\n\n`
	s ..= `Learn more in the [documentation](https://lukadev-0.github.io/util.luau/reference/{package.config.name}).\n`
	s ..= `This package is part of [util.luau](https://lukadev-0.github.io/util.luau).\n`

	return s
end

local function buildPackageBase(
	ctx: Context,
	progress: ProgressReporter,
	package: Package,
	outDir: string,
	processedDir: string,
	dependenciesDir: string
): ()
	fs.writeDir(outDir)

	fs.writeFile(`{outDir}/README.md`, createReadme(package))
	fs.copy(`{ctx.rootDir}/LICENSE`, `{outDir}/LICENSE`)

	progress.report("copying package source")
	fs.copy(processedDir, `{outDir}/{package.config.name}`)

	if package.config.dependencies then
		progress.report("creating dependency linking files")
		for _, dependencyName in package.config.dependencies do
			local dependency = ctx.packages[dependencyName]
			if dependency == nil then
				progress.fail(`dependency '{dependencyName}' not found`)
				process.exit(1)
			end

			local linkerDir = `{outDir}/{dependencyName}`
			fs.writeDir(linkerDir)
			fs.writeFile(
				`{linkerDir}/lib.luau`,
				createLinkingFile(dependency.config, `../{dependenciesDir}/{dependencyName}`)
			)
		end
	end
end

local function buildPackageWally(
	ctx: Context,
	progress: ProgressReporter,
	package: Package,
	processedPkgs: { [string]: string }
): ()
	local outDir = `{ctx.outWallyDir}/{package.config.name}`

	buildPackageBase(ctx, progress, package, outDir, processedPkgs.roblox, "..")

	progress.report("creating root linker file")
	fs.writeFile(`{outDir}/init.luau`, createLinkingFile(package.config, `@self/{package.config.name}/lib`))

	progress.report("creating wally.toml")
	local wallyToml = {
		package = {
			name = `{WALLY_SCOPE}/{package.config.name}`,
			version = package.config.version,
			description = package.config.description,
			license = packageMetadata.license,
			authors = packageMetadata.authors,
			realm = packageMetadata.realm,
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

local function buildPackagePesde(
	ctx: Context,
	progress: ProgressReporter,
	package: Package,
	processedPkgs: { [string]: string }
): ()
	local baseOutDir = `{ctx.outPesdeDir}/{package.config.name}`

	local basePesdeToml = {
		name = pesdeify(`{WALLY_SCOPE}/{package.config.name}`),
		version = package.config.version,
		description = package.config.description,
		license = packageMetadata.license,
		authors = packageMetadata.authors,
		repository = packageMetadata.repository,
		indices = {
			default = "https://github.com/daimond113/pesde-index",
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

			basePesdeToml.dependencies[dependencyName] = {
				workspace = pesdeify(`{WALLY_SCOPE}/{dependencyName}`),
			}
		end
	end

	fs.writeDir(baseOutDir)

	for target, processedDir in processedPkgs do
		progress.report(`building pesde package for {target}`)

		local environment = target
		if target == "default" then
			environment = "luau"
		end

		local outDir = `{baseOutDir}/{target}`
		buildPackageBase(ctx, progress, package, outDir, processedDir, `{environment}_packages`)

		local pesdeToml = table.clone(basePesdeToml)
		pesdeToml.target = {
			environment = environment,
			lib = `{package.config.name}/lib.luau`,
		}

		pesdeToml.includes = {}
		for _, file in fs.readDir(outDir) do
			if fs.isDir(`{outDir}/{file}`) then
				table.insert(pesdeToml.includes, `{file}/**/*`)
			else
				table.insert(pesdeToml.includes, file)
			end
		end

		table.insert(pesdeToml.includes, "pesde.toml")

		if environment == "roblox" then
			local buildFiles: { string } = { package.config.name }

			if package.config.dependencies then
				for _, dependencyName in package.config.dependencies do
					table.insert(buildFiles, dependencyName)
				end
			end

			pesdeToml.target.build_files = buildFiles
		end

		fs.writeFile(`{outDir}/pesde.toml`, serde.encode("toml", pesdeToml, true))

		table.insert(ctx.pesdeWorkspaceMembers, `{package.config.name}/{target}`)
	end
end

local function buildPackageRbxm(
	ctx: Context,
	progress: ProgressReporter,
	package: Package,
	processedPkgs: { [string]: string }
): ()
	local baseWorkDir = `{ctx.outWorkPkgDir}/{package.config.name}`
	local workDir = `{baseWorkDir}/rbxm`

	fs.copy(processedPkgs.roblox, workDir)
	fs.writeFile(`{workDir}/init.luau`, createLinkingFile(package.config, `@self/lib`))

	local projectJson = {
		name = package.config.name,
		tree = {
			["$path"] = workDir,
		},
	}

	local projectPath = `{baseWorkDir}/rbxm.project.json`
	fs.writeFile(projectPath, serde.encode("json", projectJson, true))

	local rbxmPath = `{ctx.outRbxmDir}/{package.config.name}.rbxm`
	spawnCommand(progress, `rojo build {projectPath} -o {rbxmPath}`)

	table.insert(ctx.rbxms, rbxmPath)
end

local function buildPackage(ctx: Context, progress: ProgressReporter, package: Package): ()
	progress.report("copying source files")

	local workPkgDir = `{ctx.outWorkPkgDir}/{package.config.name}`
	local workPkgSrc = `{workPkgDir}/src`
	copyPackageSource(package.path, workPkgSrc)

	local processedPkgs: { [string]: string } = {}
	for target, configPath in ctx.darkluaConfig do
		if target == "base" then
			continue
		end

		progress.report(`processing files for {target}`)

		local processedDir = `{workPkgDir}/{target}`
		spawnCommand(progress, `darklua process -c {configPath} {workPkgSrc} {processedDir}`)
		processedPkgs[target :: string] = processedDir
	end

	progress.report("building Wally package")
	buildPackageWally(ctx, progress, package, processedPkgs)

	progress.report("building pesde package")
	buildPackagePesde(ctx, progress, package, processedPkgs)

	progress.report("building rbxm")
	buildPackageRbxm(ctx, progress, package, processedPkgs)

	progress.finish()
end

local function buildBundleRbxm(ctx: Context, progress: ProgressReporter): ()
	local folder = roblox.Instance.new("Folder")
	folder.Name = "util"

	for _, rbxm in ctx.rbxms do
		for _, instance in roblox.deserializeModel(fs.readFile(rbxm)) do
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

	local pesdeWorkspace = {
		name = "lukadev_0/util_root",
		version = "0.0.0",
		private = true,
		workspace_members = ctx.pesdeWorkspaceMembers,
		target = {
			environment = "luau",
		},
	}

	fs.writeFile(`{ctx.outPesdeDir}/pesde.toml`, serde.encode("toml", pesdeWorkspace, true))

	stdio.write("\n")

	local rbxmProgress = createProgressReporter("rbxm")
	buildBundleRbxm(ctx, rbxmProgress)

	stdio.write("\n")

	print("build finished")

	stdio.write("\x1B[?25h")
end

build(process.cwd:gsub("/*$", ""))
