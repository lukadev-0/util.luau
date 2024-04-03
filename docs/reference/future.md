---
outline: [2, 3]
---

<script setup>
import { data } from "./package-versions.data.ts";
</script>

# future

[View Source](https://github.com/lukadev-0/util.luau/blob/main/packages/future/init.luau)

A future represents a value that does not exist yet, but will exist at some
point in the future.

Futures allow you to more easily compose asynchronous operations.

This utility is inspired by the
[`Future` type in Rust](https://doc.rust-lang.org/std/future/trait.Future.html).

## Installation

Learn more about [installation](/docs/getting-started#installation).

```toml-vue [Wally]
future = "lukadev-0/future@{{ data.future }}"
```

## Static Functions

### Future.new

```lua
function Future.new<T>(value: T) -> Future<T>
```

Creates a finished future with the given value.

#### Example

```lua
local fut = Future.new(5)
assert(fut:now() == Option.Some(5))
```

### Future.never

```lua
function Future.never() -> Future<any>
```

Creates a pending future that will never finish.

#### Example

```lua
local fut = Future.never()
assert(fut:now() == Option.None)
```

### Future.spawn

```lua
function Future.spawn<T, U...>(f: () -> T, ...: U...) -> Future<T>
```

Creates a future and spawns the function in a new thread. The future will
resolve with the result of the function.

Throwing inside of the function will lead to undefined behavior.

#### Example

```lua
local function httpGet(url)
  -- does an HTTP request to url
end

local fut = Future.spawn(httpGet, "https://google.com/")
local res = fut:await()
```

### Future.pending

```lua
function Future.pending<T>() -> (Future<T>, (T) -> ())
```

Returns a future and a function that, when called, will resolve the future with
the given value.

#### Example

```lua
local fut: Future.Future<number>, resolve = Future.pending()

resolve(5)
assert(fut:now() == Option.Some(5))
```

### Future.fn

```lua
function Future.fn<T, V...>(f: (V...) -> T) -> (V...) -> Future<T>
```

Returns a function that, when called, creates a future and spawns the given
function in a new thread. The future will resolve with the result of the
function.

This allows you to convert a yielding function into a function that returns a
Future.

#### Example

```lua
local function httpGet(url)
  -- does an HTTP request to url
end

local httpGetFut = Future.fn(httpGet)
local fut = httpGetFut("https://google.com/")
local res = fut:await()
```

### Future.all

```lua
function Future.all<T>(futures: { Future<T> }) -> Future<{ T }>
```

Returns a future that resolves once all the given futures have resolved. It
resolves with a table of the resolved values.

This turns `{ Future<T> }` into `Future<{ T }>`.

#### Example

```lua
local fut1 = Future.new(5)
local fut2 = Future.new(10)
local fut3 = Future.new(15)

local allFut = Future.all({ fut1, fut2, fut3 })

local res = allFut:now():unwrap()
assert(res[1] == 5)
assert(res[2] == 10)
assert(res[3] == 15)
```

### Future.race

```lua
function Future.race<T>(futures: { Future<T> }) -> Future<T>
```

Returns a future that resolves once the first of the given futures has resolved.
It resolves with the value of the first resolved future. The results of the
other futures are discarded.

This turns `{ Future<T> }` into `Future<T>`.

#### Example

```lua
local fut1 = Future.new(5)
local fut2 = Future.new(10)
local fut3 = Future.new(15)

local raceFut = Future.race({ fut1, fut2, fut3 })

local res = raceFut:now():unwrap()
assert(res == 5)
```

## Instance Functions

### Future:isFinished

```lua
function Future:isFinished() -> boolean
```

Returns `true` if the future is finished, otherwise it returns `false`.

#### Example

```lua
local fut = Future.new(5)
assert(fut:isFinished())
```

### Future:isPending

```lua
function Future:isPending() -> boolean
```

Returns `true` if the future is pending, otherwise it returns `false`.

#### Example

```lua
local fut = Future.never()
assert(fut:isPending())
```

### Future:now

```lua
function Future:now() -> Option<T>
```

Returns the value of the future if it is finished, otherwise it returns `None`.

This turns `Future<T>` into `Option<T>`.

#### Example

```lua
local fut = Future.new(5)
assert(fut:now() == Option.Some(5))
```

### Future:await

```lua
function Future:await() -> T
```

Waits for the future to finish and returns the value. If the future is already
finished, it returns the value immediately.

#### Example

```lua
local fut = Future.new(5)
assert(fut:await() == 5)
```

### Future:after

```lua
function Future:after(f: (T) -> ()) -> ()
```

Calls the given function with the value of the future once it is finished. If
the future is already finished, the function is called immediately.

#### Example

```lua
local fut = Future.new(5)
fut:after(function(value)
  print(value)
end)
```
