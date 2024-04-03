# Supported Runtimes

util.luau is designed to run on any Luau runtime, with out-of-the-box support
for Roblox and Lune.

However, some packages require the use of standard libraries that differ between
runtimes. For example, [`timer`](/reference/timer) requires access to functions
to schedule code to run at a later time, this functionality is provided by the
`task` global on Roblox, and the `@lune/task` builtin on Lune.

In order to support all of these runtimes, util.luau provides the
[`std`](/reference/std) package. This package provides common interfaces for
standard libraries, and default implementations for supported runtimes.

Currently, the following runtimes are supported out-of-the-box:

- [Roblox](https://create.roblox.com/docs/reference/engine)
- [Lune](https://lune-org.github.io/docs)

## Runtime Detection

In order to use the correct library implementations for the current runtime,
`std` will automatically try to detect the current runtime, this is done using
the following rules:

- if `_G.UTIL_TARGET` is set to `roblox`, then the Roblox implementations are
  used. This global is injected for Roblox builds meaning that runtime detection
  is skipped.
- if `typeof(script) == "Instance"` is true, then the Roblox implementations are
  used
- if `_VERSION` starts with the string `"lune "`, case-insensitive, then the
  Lune implementations are used.
- otherwise, the runtime is unknown, and no libraries are implemented.

## Defining Runtimes

If you need to use util.luau in a runtime that is not supported out-of-the-box,
You need to define the runtime yourself and implement the standard libraries.

This is done using the [`std.defineRuntime`](/reference/std#std-defineruntime)
function.

```lua
local std = require(...)

local myRuntime = std.defineRuntime({
  name = "my-runtime",
  libs = {
    task = {
      cancel = ...,
      defer = ...,
      delay = ...,
      spawn = ...,
      wait = ...,
    },
  },
})
```

Not every function needs to be implemented, however an error will be thrown if
you try to use a function that is not implemented.

## Using Runtimes

Once you've defined a runtime, you can use it by calling
[`std.setRuntime`](/reference/std#std-setruntime).

```lua
std.setRuntime(myRuntime)
```

:::warning

It is important to call this function **_before_** any code that uses the
standard libraries, otherwise you will get errors.

:::

## Using the Standard Libraries

If you'd like to use the standard libraries, you can do so by requiring the
[`std`](/reference/std) module and accessing the libraries.

```lua
local std = require(...)

std.task.spawn(...)
```

You may also alias the standard libraries to a shorter name if you prefer.

```lua
local task = std.task
```

However, do not alias functions directly, as this will break the runtime
setting functionality if the runtime is set after your module code is ran.

```lua
-- do not do this
local spawn = std.task.spawn
```

:::info

It is recommended to use one of the other utilities that wrap the standard
libraries, such as [`threadpool`](/reference/threadpool) or
[`timer`](/reference/timer), as these provide a more ergonomic API.

:::
