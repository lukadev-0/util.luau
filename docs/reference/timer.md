---
outline: [2, 3]
---

<script setup>
import { data } from "./package-versions.data.ts";
</script>

# timer

`timer` allows you to schedule code to run at a future time or at an interval.

## Installation

Learn more about [installation](/docs/getting-started#installation).

::: code-group

```toml-vue [Wally]
timer = "lukadev-0/timer@{{ data.timer }}"
```

```lua [Bundle]
local util = require(...)
util.timer.delay(...)
```

:::

## Functions

### timer.delay

```lua
function timer.delay(duration: number): Future<number>
```

Returns a future that resolves after the given duration in seconds, returning
the amount of time it took to resolve.

This is equivalent to the following code:

```lua
local fut = Future.spawn(task.wait, duration)
```

### timer.interval

```lua
function timer.interval(duration: number, callback: function): () -> ()
```

Calls the given callback every `duration` seconds.

This will correct for drift, it repeatedly calls `task.wait` and calculates
the amount of time until the next call.

Returns a function that will stop the interval when called.
