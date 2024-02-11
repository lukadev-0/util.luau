---
outline: [2, 3]
---

<script setup>
import { data } from "./package-versions.data.ts";
</script>

# env

[View Source](https://github.com/lukadev-0/util.luau/blob/main/packages/env/init.luau)

Allows you to access the current platform and standard libraries.

This allows you to write code that runs on any environment.

## Installation

Learn more about [installation](/introduction#installation).

::: code-group

```toml-vue [Wally]
env = "lukadev-0/env@{{ data.env }}"
```

```lua [Bundle]
local env = require(...)
local platform = env.platform
```

:::

## Libraries

Libraries are accessible through [`env.libs`](#env-libs-1).

### task

```lua
export type TaskLib = {
	cancel: (thread) -> (),
	defer: <T...>(functionOrThread: thread | (T...) -> (), T...) -> thread,
	delay: <T...>(duration: number, functionOrThread: thread | (T...) -> (), T...) -> thread,
	spawn: <T...>(functionOrThread: thread | (T...) -> (), T...) -> thread,
	wait: (duration: number) -> number,
}
```

## Platform Detection

If the `_G.UTIL_TARGET` global is set **before the `env` module is required**, it will be used as the platform.

Otherwise, the platform will be detected using the following rules:

- if `typeof(script) == "Instance"` is true, then the platform is `roblox`
- if `_VERSION` starts with `"lune "`, case-insensitive, then the platform is `lune`
- otherwise, the platform is `unknown`

## Implementing Libraries

Currently, `env` has built-in library implementations for Roblox and Lune.

If you need to run code on an unsupported platform, you can need to create custom
implementations of the libraries.

This is done using one of the following functions:

- `env.implementTask` for the `task` library.

**Example**

```lua
env.implementTask({
  cancel = ...,
  defer = ...,
  delay = ...,
  spawn = ...,
  wait = ...,
})
```

It is important that the implementation is added before any code that uses the library,
otherwise you will get an error on unsupported platforms.

## Types

### env.Platform

```lua
export type Platform = "roblox" | "lune" | "unknown"
```

### env.Libs

```lua
type Proxy<T> = typeof(setmetatable({}, { __index = ({} :: any) :: T }))

export type Libs = {
  task: Proxy<TaskLib>,
}
```

## Properties

### env.platform

```lua
env.platform: Platform
```

### env.libs

```lua
env.libs: Libs
```
