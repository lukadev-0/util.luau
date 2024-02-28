---
outline: [2, 3]
---

<script setup>
import { data } from "./package-versions.data.ts";
</script>

# option

[View Source](https://github.com/lukadev-0/util.luau/blob/main/packages/option/init.luau)

The `option` package provides the `Option<T>` type, which is a type that
represents a value that may or may not exist, akin to `T | nil`.

This is useful to avoid `nil`-related bugs, which can cause bugs that are hard
to track down.

This utility is inspired by the
[`Option` type in Rust](https://doc.rust-lang.org/std/option/enum.Option.html).

## Installation

Learn more about [installation](/docs/getting-started#installation).

::: code-group

```toml-vue [Wally]
option = "lukadev-0/option@{{ data.option }}"
```

```lua [Bundle]
local util = require(...)
local foo = util.Option.Some(5)
```

:::

## Immutability

The `Option` type is immutable, meaning that once an `Option` is created, it
cannot be modified.

However, the value inside the `Option` may be mutable, so it is important to be
aware of this when working with `Option` values.

## Typechecking

The `Option` type aims to be as type-safe as possible, however due to Luau
limitations or bugs, some areas may not typecheck as expected.

### Callbacks

When calling a function through `:` syntax that takes a callback, the type of
the parameters aren't inferred.

```lua
local opt = Option.Some(5)
local mapped = opt:map(function(value)
  -- ┌────────────────────────── ^^^^^
  -- └ this is typed as `a` instead of `number`
  return value * 2
end)
```

This can be worked around by calling the function using `.` syntax:

```lua
local opt = Option.Some(5)

local mapped = Option.map(opt, function(value)
  -- ┌───────────────────────────────── ^^^^^
  -- └ correctly typed as `number`
  return value * 2
end)

-- the following is equivalent
local mapped = opt.map(opt, function(value)
  return value * 2
end)
```

## Static Properties

### Option.None

```lua
Option.None: Option<any>
```

The option that does not contain a value.

#### Example

```lua
local none = Option.None
assert(none:isNone())
```

## Static Functions

### Option.Some

```lua
function Option.Some<T>(value: T): Option<T>
```

Creates a new `Some` with the given value. A `Some` may contain any value,
including `nil`.

#### Example

```lua
local some = Option.Some(5)
assert(some:isSome())
```

### Option.from

```lua
function Option.from<T>(value: T | nil): Option<T>
```

Creates a new `Option` from the given value. If the value is `nil`, it returns
`None`, otherwise it returns `Some`.

#### Example

```lua
local some = Option.from(5)
assert(some == Option.Some(5))

local none = Option.from(nil)
assert(none == Option.None)
```

### Option.is

```lua
function Option.is(value: any): boolean
```

Returns `true` if the given value is an `Option`, otherwise it returns `false`.

#### Example

```lua
local some = Option.Some(5)
assert(Option.is(some))
assert(Option.is(5) == false)
```

## Instance Functions

### Option:isSome

```lua
function Option:isSome(): boolean
```

Returns `true` if the `Option` is a `Some`, otherwise it returns `false`.

#### Example

```lua
local some = Option.Some(5)
assert(some:isSome())
```

### Option:isSomeAnd

```lua
function Option:isSomeAnd(f: (T) -> boolean): boolean
```

Returns `true` if the `Option` is a `Some` and the value satisfies the given
predicate, otherwise it returns `false`.

#### Example

```lua
local some = Option.Some(5)
assert(some:isSomeAnd(function(value)
  return value > 0
end))
```

### Option:isNone

```lua
function Option:isNone(): boolean
```

Returns `true` if the `Option` is a `None`, otherwise it returns `false`.

#### Example

```lua
local none = Option.None
assert(none:isNone())
```

### Option:expect

```lua
function Option:expect(message: string): T
```

Returns the value of the option if it is a `Some`, otherwise it throws an error
with the given message.

::: warning THROWS

This function may throw an error.

:::

#### Example

```lua
local some = Option.Some(5)
assert(some:expect("expected a value") == 5)

local none = Option.None
none:expect("expected a value") -- throws "expected a value"
```

### Option:unwrap

```lua
function Option:unwrap(): T
```

Returns the value of the option if it is a `Some`, otherwise it throws an error.

::: warning THROWS

This function may throw an error.

:::

#### Example

```lua
local some = Option.Some(5)
assert(some:unwrap() == 5)

local none = Option.None
none:unwrap() -- throws "called `Option.unwrap()` on a `None` value"
```

### Option:unwrapOr

```lua
function Option:unwrapOr(default: T): T
```

Returns the value of the option if it is a `Some`, otherwise it returns the
given default.

#### Example

```lua
local some = Option.Some(5)
assert(some:unwrapOr(10) == 5)

local none = Option.None
assert(none:unwrapOr(10) == 10)
```

### Option:unwrapOrElse

```lua
function Option:unwrapOrElse(f: () -> T): T
```

Returns the value of the option if it is a `Some`, otherwise it returns the
result of the given function.

#### Example

```lua
local some = Option.Some(5)
assert(some:unwrapOrElse(function()
  return 10
end) == 5)
```

### Option:map

```lua
function Option:map<U>(f: (T) -> U): Option<U>
```

Returns the result of the given function wrapped in an `Option` if the option is
`Some`, otherwise returns `None`.

#### Example

```lua
local some = Option.Some(5)
local double = some:map(function(value)
  return value * 2
end)

assert(double == Option.Some(10))
```

### Option:mapOr

```lua
function Option:mapOr<U>(default: U, f: (T) -> U): U
```

Returns the result of the given function if the option is `Some`, otherwise
returns the given default value.

#### Example

```lua
local some = Option.Some(5)
assert(some:mapOr(15, function(value)
  return value * 2
end) == 10)

local none = Option.None
assert(none:mapOr(15, function(value)
  return value * 2
end) == 15)
```

### Option:mapOrElse

```lua
function Option:mapOrElse<U>(default: () -> U, f: (T) -> U): U
```

Returns the result of the given function if the option is `Some`, otherwise
returns the result of calling the default function.

#### Example

```lua
local none = Option.None
assert(none:mapOrElse(function()
  return 15
end, function(value)
  return value * 2
end) == 10)
```

### Option:andOpt

```lua
function Option:andOpt<U>(other: Option<U>): Option<U>
```

Returns `None` if the option is `None`, otherwise returns the other option.

#### Example

```lua
local some = Option.Some(5)
local other = Option.Some(10)
assert(some:andOpt(other) == other)

local none = Option.None
assert(none:andOpt(other) == none)
```

### Option:andThen

```lua
function Option:andThen<U>(f: (T) -> Option<U>): Option<U>
```

Returns `None` if the option is `None`, otherwise returns the result of the
given function.

#### Examples

```lua
local some = Option.Some(5)
local double = some:andThen(function(value)
  return Option.Some(value * 2)
end)

assert(double == Option.Some(10))
```

### Option:filter

```lua
function Option:filter(f: (T) -> boolean): Option<T>
```

Returns `None` if the option is `None`, otherwise calls the function with the
value:

- if the function returns `true`, returns the original option
- if the function returns `false`, returns `None`

#### Examples

```lua
local some = Option.Some(5)
local filtered = some:filter(function(value)
  return value > 0
end)

assert(filtered == some)
```

### Option:orOpt

```lua
function Option:orOpt(other: Option<T>): Option<T>
```

Returns the option if it is `Some`, otherwise returns the other option.

#### Example

```lua
local some = Option.Some(5)

assert(some:orOpt(Option.Some(10)) == some)
assert(some:orOpt(Option.None) == some)

local none = Option.None
assert(none:orOpt(Option.Some(10)) == Option.Some(10))
assert(none:orOpt(Option.None) == none)
```

### Option:orElse

```lua
function Option:orElse(f: () -> Option<T>): Option<T>
```

Returns the option if it is `Some`, otherwise returns the result of calling the
given function.

#### Example

```lua
local some = Option.Some(5)
assert(some:orElse(function()
  return Option.Some(10)
end) == some)
```

### Option:xor

```lua
function Option:xor(other: Option<T>): Option<T>
```

Returns `None` if both options are `Some` or `None`, otherwise returns the
option.

#### Example

```lua
local some = Option.Some(5)
local other = Option.Some(10)

assert(some:xor(other) == Option.None)
```

### Options:match

```lua
function Option:match<U>(f: {
  Some: (T) -> U,
  None: () -> U
}): U
```

Takes a table containing a `Some` and `None` function. If the option is a
`Some`, calls the `Some` function with the value of the option, otherwise calls
the `None` function. The result of the function call is returned.

#### Example

```lua
local some = Option.Some(5)

local result = some:match({
  Some = function(value)
    return value * 2
  end,
  None = function()
    return 20
  end
})

assert(result == 10)
```

## Metamethods

### Option:\_\_tostring

```lua
function Option:__tostring(): string
```

Called when `tostring()` is called on the `Option`.

Converts the `Option` to a string.

#### Example

```lua
local some = Option.Some(5)
assert(tostring(some) == "Option::Some(5)")

local none = Option.None
assert(tostring(none) == "Option::None")
```

### Option:\_\_eq

```lua
function Option:__eq(other: Option<T>): boolean
```

Called when the `==` operator is used on the `Option`.

Returns `true` if both options are `Some` and their values are equal, or if both
options are `None`, otherwise returns `false`.

#### Example

```lua
local some = Option.Some(5)
local other = Option.Some(5)

assert(some == other)
```
