--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local function exec(command: string)
	stdio.write(stdio.style("dim"))
	stdio.write("$ ")
	stdio.write(command)
	stdio.write(stdio.style("reset"))
	stdio.write("\n")

	local result = process.spawn(command, {}, {
		stdio = "forward",
		shell = true,
	})

	stdio.write("\n")

	if not result.ok then
		stdio.write(stdio.style("bold"))
		stdio.write(stdio.color("red"))
		stdio.write("\n")
		stdio.write(`Process exited with code: {result.code}`)
		stdio.write("\n")

		process.exit(result.code)
	end
end

local function deepClone<T>(value: T): T
	if typeof(value) == "table" then
		local clone = {} :: any
		for i, v in pairs(value) do
			clone[i] = deepClone(v)
		end
		return clone
	else
		return value
	end
end

local function createDarkluaConfig()
	local baseConfig = serde.decode("json", fs.readFile("base.darklua.json"))

	local robloxConfig = deepClone(baseConfig)
	table.insert(robloxConfig.rules, 1, {
		rule = "inject_global_value",
		identifier = "TARGET",
		value = "roblox",
	})
	table.insert(robloxConfig.rules, 1, {
		rule = "convert_require",
		current = "path",
		target = "roblox",
	})

	fs.writeFile("build/src/roblox.darklua.json", serde.encode("json", robloxConfig))

	local luneConfig = deepClone(baseConfig)
	table.insert(luneConfig.rules, 1, {
		rule = "inject_global_value",
		identifier = "TARGET",
		value = "lune",
	})

	fs.writeFile("build/src/lune.darklua.json", serde.encode("json", luneConfig))

	local baseBundleConfig = deepClone(baseConfig)
	baseBundleConfig.bundle = {
		require_mode = "path",
		modules_identifier = "__MODULES",
		excludes = { "@lune/**" },
	}

	local robloxBundleConfig = deepClone(baseBundleConfig)
	table.insert(robloxBundleConfig.rules, 1, {
		rule = "inject_global_value",
		identifier = "TARGET",
		value = "roblox",
	})

	fs.writeFile("build/src/bundle_roblox.darklua.json", serde.encode("json", robloxBundleConfig))

	local luneBundleConfig = deepClone(baseBundleConfig)
	table.insert(robloxBundleConfig.rules, 1, {
		rule = "inject_global_value",
		identifier = "TARGET",
		value = "lune",
	})

	fs.writeFile("build/src/bundle_lune.darklua.json", serde.encode("json", luneBundleConfig))
end

local function copyPackageSrc(src: string, dest: string)
	for _, file in fs.readDir(src) do
		if file:match("test%.luau$") or file == "config.toml" then
			continue
		end

		if fs.isDir(`{src}/{file}`) then
			fs.writeDir(`{dest}/{file}`)
			copyPackageSrc(`{src}/{file}`, `{dest}/{file}`)
		else
			fs.copy(`{src}/{file}`, `{dest}/{file}`)
		end
	end
end

local function prepareBuild()
	if fs.isDir("build") then
		fs.removeDir("build")
	end

	fs.writeDir("build/src/pkg")
	fs.writeDir("build/pkg")
	createDarkluaConfig()

	for _, dir in fs.readDir("packages") do
		fs.writeDir(`build/src/pkg/{dir}`)
		copyPackageSrc(`packages/{dir}`, `build/src/pkg/{dir}`)
	end
end

local function buildPackage(packageName: string)
	local packagePath = `packages/{packageName}`
	local packageBuildSrc = `build/src/pkg/{packageName}`
	local packageBuildOut = `build/pkg/{packageName}`

	stdio.write(stdio.style("bold"))
	stdio.write(stdio.color("blue"))
	stdio.write("=> ")
	stdio.write(stdio.style("reset"))
	stdio.write(stdio.style("bold"))
	stdio.write(packagePath)
	stdio.write("\n\n")
	stdio.write(stdio.style("reset"))

	fs.writeDir(packageBuildOut)

	local packageConfig = serde.decode("toml", fs.readFile(`{packagePath}/config.toml`))

	local wallyManifest = {
		package = {
			name = `lukadev-0/{packageConfig.name}`,
			version = packageConfig.version,
			description = packageConfig.description,
			license = "MIT",
			authors = { "LukaDev" },
			realm = "shared",
			registry = "https://github.com/UpliftGames/wally-index",
		},
		dependencies = {},
	}

	print("generating wally.toml")

	if packageConfig.dependencies ~= nil then
		for _, dependency in pairs(packageConfig.dependencies) do
			local dependencyPath = `packages/{dependency}`
			local dependencyConfig = serde.decode("toml", fs.readFile(`{dependencyPath}/config.toml`))
			local dependencyVersion = dependencyConfig.version

			wallyManifest.dependencies[dependency] = `lukadev-0/{dependency}@{dependencyVersion}`
		end
	end

	fs.writeFile(`{packageBuildOut}/wally.toml`, serde.encode("toml", wallyManifest))

	print("processing files\n")

	exec(`darklua process {packageBuildSrc} {packageBuildOut}/roblox --config build/src/roblox.darklua.json`)
	exec(`darklua process {packageBuildSrc} {packageBuildOut}/lune --config build/src/lune.darklua.json`)

	print("generating linker files")

	local initFile = ""
	initFile ..= "--!strict\n"
	initFile ..= 'local pkg = require("./lune")\n'

	if packageConfig.types then
		for _, type in packageConfig.types do
			initFile ..= `export type {type} = pkg.{type}\n`
		end
	end

	initFile ..= "return pkg\n"

	fs.writeFile(`{packageBuildOut}/init.luau`, initFile)

	local rojoProject = {
		name = packageConfig.name,
		tree = {
			["$path"] = "./roblox",
		},
	}

	fs.writeFile(`{packageBuildOut}/default.project.json`, serde.encode("json", rojoProject))

	print("copying LICENSE")
	fs.copy("LICENSE", `{packageBuildOut}/LICENSE`)

	print("")
	print(`package built to {stdio.style("bold")}{packageBuildOut}{stdio.style("reset")}`)
	print("")
end

local function buildBundle()
	stdio.write(stdio.style("bold"))
	stdio.write(stdio.color("blue"))
	stdio.write("=> ")
	stdio.write(stdio.style("reset"))
	stdio.write(stdio.style("bold"))
	stdio.write("generating bundle")
	stdio.write("\n\n")
	stdio.write(stdio.style("reset"))

	local function generateBundle(target: string)
		local entrypoint = ""
		entrypoint ..= "return {\n"

		for _, dir in fs.readDir("packages") do
			local packageConfig = serde.decode("toml", fs.readFile(`packages/{dir}/config.toml`))
			if packageConfig.bundle then
				entrypoint ..= `  {packageConfig.bundle} = require("../pkg/{dir}/{target}"),\n`
			end
		end

		entrypoint ..= "}\n"

		local bundleSrcPath = `build/src/util.{target}.luau`
		local bundleOutPath = `build/util.{target}.luau`

		fs.writeFile(bundleSrcPath, entrypoint)

		exec(`darklua process {bundleSrcPath} {bundleOutPath} --config build/src/bundle_{target}.darklua.json`)
		print(
			`bundled for {stdio.style("bold")}{target}{stdio.style("reset")} to {stdio.style("bold")}{bundleOutPath}{stdio.style(
				"reset"
			)}`
		)
		print("")
	end

	generateBundle("roblox")
	generateBundle("lune")
end

prepareBuild()

for _, dir in fs.readDir("packages") do
	buildPackage(dir)
end

buildBundle()
