---
outline: [2, 3]
---

<script setup>
import { data } from "./package-versions.data.ts";
</script>

# env

[View Source](https://github.com/lukadev-0/util.luau/blob/main/packages/env/init.luau)

Runtime detection and runtime-agnostic standard libraries.

See [supported runtimes](/docs/supported-runtimes) for more information.

## Installation

Learn more about [installation](/docs/getting-started#installation).

```toml-vue [Wally]
env = "lukadev-0/env@{{ data.env }}"
```

## Types

### env.Libs

```lua
type Proxy<T> = typeof(setmetatable({}, { __index = ({} :: any) :: T }))

export type Libs = {
  task: Proxy<TaskLib>,
}
```

## Properties

### env.runtime

```lua
env.runtime: string
```

### env.libs

```lua
env.libs: Libs
```

## Libraries

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

```lua
env.libs.task: Proxy<TaskLib> -- see `env.Libs`
```

```lua
function env.implementTask(lib: TaskLib): ()
```
