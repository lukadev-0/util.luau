# Supported Runtimes

util.luau is designed to run on any Luau runtime, with out-of-the-box support
for Roblox and Lune.

However, some packages require the use of standard libraries that differ between
runtimes. For example, [`timer`](/reference/timer) requires access to functions
to schedule code to run at a later time, this functionality is provided by the
`task` global on Roblox, and the `@lune/task` builtin on Lune.

In order to support all of these runtimes, util.luau provides the
[`env`](/reference/env) package. This package provides information about the
current runtime, and provides standard libraries that can be overridden by the
user to support different runtimes.

## Runtime Detection

In order to use the correct library implementations for the current runtime,
`env` will automatically try to detect the current runtime, this is done using
the following rules:

- if `typeof(script) == "Instance"` is true, then the runtime is `roblox`
- if `_VERSION` starts with the string `"lune "`, case-insensitive, then the
  runtime is `lune`
- otherwise, the runtime is `unknown`

## Implementing libraries

If you need to use util.luau in a runtime that is not supported out-of-the-box,
you need to add custom library implementations to the `env` package. This can be
done by calling one of the
[implement functions on the `env` package](/reference/env#libraries).

For example, to implement the `task` library, you would call `env.implementTask`
with a table containing the implementation of the library:

```lua
local env = require(...)

env.implementTask({
  cancel: ...,
  defer: ...,
  delay: ...,
  spawn: ...,
  wait: ...,
})
```

It is important that this is done before any code that uses the library is run.
