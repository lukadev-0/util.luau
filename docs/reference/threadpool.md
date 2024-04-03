---
outline: [2, 3]
---

<script setup>
import { data } from "./package-versions.data.ts";
</script>

# threadpool

`threadpool` provides a `spawn` function that allows you to run a function in a
separate thread like `task.spawn`, however, it will pool and reuse threads.

This uses a global pool of free threads, when `spawn` is called, it'll take a
thread from the pool and run the function in it, if there isn't a thread
available it'll create a new one. Once the function has finished running, the
thread will be returned to the pool.

This can make spawning threads significantly faster than using `task.spawn`.

## Installation

Learn more about [installation](/docs/getting-started#installation).

```toml-vue [Wally]
threadpool = "lukadev-0/threadpool@{{ data.threadpool }}"
```

## Functions

### threadpool.spawn

```lua
function threadpool.spawn<T...>(f: (T...) -> (), ...: T...): ()
```

Executes the given function in a separate thread, with thread pooling.
