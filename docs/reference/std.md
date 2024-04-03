---
outline: [2, 3]
---

<script setup>
import { data } from "./package-versions.data.ts";
</script>

# std

[View Source](https://github.com/lukadev-0/util.luau/blob/main/packages/std/init.luau)

Runtime agnostic access to standard libraries.

See [supported runtimes](/docs/supported-runtimes) for more information.

## Installation

Learn more about [installation](/docs/getting-started#installation).

```toml-vue [Wally]
std = "lukadev-0/std@{{ data.std }}"
```

## Libraries

### std.task

```lua
export type TaskLib = {
	cancel: (thread) -> (),
	defer: <T...>(functionOrThread: thread | (T...) -> (), T...) -> thread,
	delay: <T...>(duration: number, functionOrThread: thread | (T...) -> (), T...) -> thread,
	spawn: <T...>(functionOrThread: thread | (T...) -> (), T...) -> thread,
	wait: (duration: number) -> number,
}
```

## Types

### std.Runtime

```lua
export type Runtime = {
	name: string,
	libs: {
		task: libs.TaskLib,
	},
}
```

### std.RuntimeDefinition

```lua
export type RuntimeDefinition = {
	name: string,
	libs: {
		task: {
			cancel: ((thread) -> ())?,
			defer: (<T...>(functionOrThread: thread | (T...) -> (), T...) -> thread)?,
			delay: (<T...>(duration: number, functionOrThread: thread | (T...) -> (), T...) -> thread)?,
			spawn: (<T...>(functionOrThread: thread | (T...) -> (), T...) -> thread)?,
			wait: ((duration: number) -> number)?,
		}?,
	},
}
```

## Properties

### std.runtime

The current runtime, `nil` if running in an unsupported runtime and no runtime has been set.

```lua
std.runtime: Runtime?
```

## Functions

### std.setRuntime

Sets the current runtime.

```lua
function std.setRuntime(runtime: Runtime): ()
```

### std.defineRuntime

Defines a runtime.

```lua
function std.defineRuntime(definition: RuntimeDefinition): Runtime
```
