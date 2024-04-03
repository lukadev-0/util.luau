---
outline: [2, 3]
---

<script setup>
import { data } from "./package-versions.data.ts";
</script>

# result

[View Source](https://github.com/lukadev-0/util.luau/blob/main/packages/result/init.luau)

The `result` package provides the `Result<T, E>` type, which is a type that
represents a value that may or may not exist, which can be used as an
alternative to throwing errors through `error()`.

Results force you to explicitly handle errors, so you don't have to worry about
unhandled errors that may break your code.

This utility is inspired by the
[`Result` type in Rust](https://doc.rust-lang.org/std/result/enum.Result.html).

## Installation

Learn more about [installation](/docs/getting-started#installation).

```toml-vue [Wally]
result = "lukadev-0/result@{{ data.result }}"
```

## Immutability

The `Result` type is immutable, meaning that once an `Result` is created, it
cannot be modified.

However, the value inside the `Result` may be mutable, so it is important to be
aware of this when working with `Result` values.

## Typechecking

The `Result` type aims to be as type-safe as possible, however due to Luau
limitations or bugs, some areas may not typecheck as expected.

### Callbacks

When calling a function through `:` syntax that takes a callback, the type of
the parameters aren't inferred.

```lua
local res = Result.Ok(5)
local mapped = res:map(function(value)
  -- ┌───────────────────────── ^^^^^
  -- └ this is typed as `a` instead of `number`
  return value * 2
end)
```

This can be worked around by calling the function using `.` syntax:

```lua
local res = Result.Ok(5)

local mapped = Result.map(res, function(value)
  -- ┌───────────────────────────────── ^^^^^
  -- └ correctly typed as `number`
  return value * 2
end)

-- the following is equivalent
local mapped = res.map(res, function(value)
  return value * 2
end)
```

## Static Functions

### Result.Ok

```lua
function Result.Ok<T>(value: T): Result<T, any>
```

Creates a new `Ok` with the given value.

#### Example

```lua
local result = Result.Ok(5)
assert(result:isOk())
```

### Result.Err

```lua
function Result.Err<E>(error: E): Result<any, E>
```

Creates a new `Err` with the given error.

#### Example

```lua
local result = Result.Err("An error occurred")
assert(result:isErr())
```

### Result.try

```lua
function Result.try<T, U...>(f: (U...) -> T, ...: U...): Result<T, unknown>
```

Calls the given function and returns a `Result` with the result of the function.
If the function throws an error, it will be caught and returned as an `Err`.

This is like `pcall()`, but it returns a `Result`.

#### Example

```lua
local ok = Result.try(function()
  return 5
end)

assert(ok == Result.Ok(5))

local err = Result.try(function()
  error("An error occurred")
end)

assert(err == Result.Err("An error occurred"))
```

### Result.is

```lua
function Result.is(value: any): boolean
```

Returns true if the given value is a `Result`.

#### Example

```lua
assert(Result.is(Result.Ok(5)))
assert(Result.is(Result.Err("An error occurred")))
assert(not Result.is(5)
```

## Instance Functions

### Result:isOk

```lua
function Result:isOk(): boolean
```

Returns true if the `Result` is an `Ok`.

#### Example

```lua
local result = Result.Ok(5)
assert(result:isOk())
```

### Result:isOkAnd

```lua
function Result:isOkAnd(f: (T) -> boolean): boolean
```

Returns true if the result is `Ok` and the value matches the given predicate.

#### Example

```lua
local result = Result.Ok(5)
assert(result:isOkAnd(function(value)
  return value == 5
end))
```

### Result:isErr

```lua
function Result:isErr(): boolean
```

Returns true if the `Result` is an `Err`.

#### Example

```lua
local result = Result.Err("An error occurred")
assert(result:isErr())
```

### Result:isErrAnd

```lua
function Result:isErrAnd(f: (E) -> boolean): boolean
```

Returns true if the result is `Err` and the error matches the given predicate.

#### Example

```lua
local result = Result.Err("An error occurred")
assert(result:isErrAnd(function(error)
  return error == "An error occurred"
end))
```

### Result:map

```lua
function Result:map<U>(f: (T) -> U): Result<U, E>
```

Calls the given function with the contained `Ok` value and returns a `Result`
with the result of the function. Leaving an `Err` value untouched.

#### Example

```lua
local result = Result.Ok(5)
local mapped = result:map(function(value)
  return value * 2
end)

assert(mapped == Result.Ok(10))
```

### Result:mapOr

```lua
function Result:mapOr<U>(default: U, f: (T) -> U): U
```

Calls the given function with the contained `Ok` value and returns the result,
otherwise returns the given default value.

#### Example

```lua
local ok = Result.Ok(5):mapOr(0, function(value)
  return value * 2
end)

assert(ok == 10)

local err = Result.Err("An error occurred"):mapOr(0, function(value)
  return value * 2
end)

assert(err == 0)
```

### Result:mapOrElse

```lua
function Result:mapOrElse<U, V>(default: (E) -> U, f: (T) -> V): U | V
```

Calls the given function with the contained `Ok` value and returns the result,
otherwise calls the given function with the contained `Err` value.

#### Example

```lua
local ok = Result.Ok(5):mapOrElse(
  function(error)
    return error
  end,
  function(value)
    return value * 2
  end
)

assert(ok == 10)

local err = Result.Err("An error occurred"):mapOrElse(
  function(error)
    return error
  end,
  function(value)
    return value * 2
  end
)

assert(err == "An error occurred")
```

### Result:mapErr

```lua
function Result:mapErr<F>(f: (E) -> F): Result<T, F>
```

Calls the given function with the contained `Err` value and returns a `Result`
with the result of the function. Leaving an `Ok` value untouched.

#### Example

```lua
local result = Result.Err("An error occurred")
local mapped = result:mapErr(function(error)
  return error:upper()
end)

assert(mapped == Result.Err("AN ERROR OCCURRED"))
```

### Result:expect

```lua
function Result:expect(message: string): T
```

Unwraps the `Ok` value, returning it. If the value is an `Err`, it will throw an
error with the given message.

::: warning THROWS

This function may throw an error.

:::

#### Example

```lua
local result = Result.Ok(5)
assert(result:expect("expected a value") == 5)
```

### Result:unwrap

```lua
function Result:unwrap(): T
```

Unwraps the `Ok` value, returning it. If the value is an `Err`, it will throw an
error.

::: warning THROWS

This function may throw an error.

:::

#### Example

```lua
local ok = Result.Ok(5)
assert(ok:unwrap() == 5)

local err = Result.Err("An error occurred")
err:unwrap() -- throws "An error occurred"
```

### Result:expectErr

```lua
function Result:expectErr(message: string): E
```

Unwraps the `Err` value, returning it. If the value is an `Ok`, it will throw an
error with the given message.

::: warning THROWS

This function may throw an error.

:::

#### Example

```lua
local result = Result.Err("An error occurred")
assert(result:expectErr("expected an error") == "An error occurred")
```

### Result:unwrapErr

```lua
function Result:unwrapErr(): E
```

Unwraps the `Err` value, returning it. If the value is an `Ok`, it will throw an
error.

::: warning THROWS

This function may throw an error.

:::

#### Example

```lua
local err = Result.Err("An error occurred")
assert(err:unwrapErr() == "An error occurred")

local ok = Result.Ok(5)
ok:unwrapErr() -- throws 5
```

### Result:andRes

```lua
function Result:andRes<U>(res: Result<U, E>): Result<U, E>
```

Returns `res` if the result is `Ok`, otherwise returns the `Err`.

#### Example

```lua
local ok = Result.Ok(5)
local res = Result.Ok(10)
assert(ok:andRes(res) == res)

local err = Result.Err("An error occurred")
assert(err:andRes(res) == err)
```

### Result:andThen

```lua
function Result:andThen<U>(f: (T) -> Result<U, E>): Result<U, E>
```

Calls the given function with the contained `Ok` value and returns the result,
otherwise returns the `Err`.

#### Example

```lua
local result = Result.Ok(5)
local mapped = result:andThen(function(value)
  return Result.Ok(value * 2)
end)

assert(mapped == Result.Ok(10))
```

### Result:orRes

```lua
function Result:orRes<F>(res: Result<T, F>): Result<T, F>
```

Returns the `res` if the result is `Err`, otherwise returns the `Ok`.

#### Example

```lua
local ok = Result.Ok(5)
local res = Result.Err("An error occurred")
assert(ok:orRes(res) == ok)

local err = Result.Err("An error occurred")
assert(err:orRes(res) == res)
```

### Result:orElse

```lua
function Result:orElse<F>(f: (E) -> Result<T, F>): Result<T, F>
```

Calls the given function with the contained `Err` value and returns the result,
otherwise returns the `Ok`.

#### Example

```lua
local result = Result.Err("An error occurred")
local mapped = result:orElse(function(error)
  return Result.Err(error:upper())
end)
```

### Result:unwrapOr

```lua
function Result:unwrapOr(default: T): T
```

Unwraps the `Ok` value, returning it. If the value is an `Err`, it will return
the given default value.

#### Example

```lua
local ok = Result.Ok(5)
assert(ok:unwrapOr(0) == 5)

local err = Result.Err("An error occurred")
assert(err:unwrapOr(0) == 0)
```

### Result:unwrapOrElse

```lua
function Result:unwrapOrElse(f: (E) -> T): T
```

Unwraps the `Ok` value, returning it. If the value is an `Err`, it will call the
given function with the error and return the result.

#### Example

```lua
local ok = Result.Ok(5)
assert(ok:unwrapOrElse(function(error)
  return error:upper()
end) == 5)

local err = Result.Err("An error occurred")
assert(err:unwrapOrElse(function(error)
  return error:upper()
end) == "AN ERROR OCCURRED")
```

### Result:match

```lua
function Result:match<U>(ok: (T) -> U, err: (E) -> U): U
```

Calls the given function with the contained `Ok` value and returns the result,
otherwise calls the given function with the contained `Err` value.

#### Example

```lua
local result = Result.Ok(5)

local value = result:match(
  function(value)
    return value * 2
  end,
  function(error)
    return error:upper()
  end
)

assert(value == 10)
```

### Result:unpack

```lua
function Result:unpack(): (T, E)
```

If the result is `Ok`, returns a tuple with the value and `nil`, otherwise
returns a tuple with `nil` and the error.

:::warning TYPE-SAFETY

Due to Luau limitations, this function may not be type-safe.

You may access the `Ok` value even if the result is `Err`, it is important to
check the `Err` value before using the `Ok` value.

:::

#### Example

This is useful to propagate errors in a function.

```lua
local function doSomething(): Result<number, string>
  if math.random() > 0.5 then
    return Result.Ok(5)
  else
    return Result.Err("An error occurred")
  end
end

local function doSomethingElse(): Result<number, string>
  local result, err = doSomething():unpack()

  -- We propagate the error if there is one
  if err then
    return Result.Err(err)
  end

  return Result.Ok(result * 2)
end
```

## Metamethods

### Result:\_\_tostring

```lua
function Result:__tostring(): string
```

Called when `tostring()` is called on the `Result`.

Converts the `Result` to a string.

#### Example

```lua
local ok = Result.Ok(5)
assert(tostring(ok) == "Result::Ok(5)")

local err = Result.Err("An error occurred")
assert(tostring(err) == "Result::Err(An error occurred)")
```

### Result:\_\_eq

```lua
function Result:__eq(other: Result<T, E>): boolean
```

Called when the `==` operator is used on the `Result`.

Returns `true` if both results are `Ok` and their values are equal, or if both
results are `Err` and their errors are equal.

#### Example

```lua
local ok1 = Result.Ok(5)
local ok2 = Result.Ok(5)
assert(ok1 == ok2)
```
