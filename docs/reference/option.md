---
outline: [2, 3]
---

# option

[View Source](https://github.com/lukadev-0/util.luau/blob/main/packages/option/init.luau)

The `option` package provides the `Option<T>` type, which is a type that represents
a value that may or may not exist, akin to `T | nil`.

This is useful to avoid `nil`-related bugs, which can cause bugs that are hard to
track down.

This utility is inspired by the
[`Option` type in Rust](https://doc.rust-lang.org/std/option/enum.Option.html).

## Installation

Learn more about [installation](/introduction#installation).

::: code-group

```toml [Wally]
option = "lukadev-0/option@1.0.0"
```

```lua [Bundle]
local util = require(...)
local foo = util.Option.Some(5)
```

:::

## Immutability

The `Option` type is immutable, meaning that once an `Option` is created, it cannot be
modified.

However, the value inside the `Option` may be mutable, so it is important to be aware
of this when working with `Option` values.

## Static Properties

### Option.None

```lua
Option.None: Option<never>
```

The option that does not contain a value.

## Static Functions

### Option.Some

```lua
function Option.Some<T>(value: T): Option<T>
```

Creates a new `Some` with the given value. A `Some` may contain any value, including `nil`.

### Option.from

```lua
function Option.from<T>(value: T | nil): Option<T>
```

Creates a new `Option` from the given value. If the value is `nil`, it returns `None`,
otherwise it returns `Some`.

### Option.is

```lua
function Option.is(value: any): boolean
```

Returns `true` if the given value is an `Option`, otherwise it returns `false`.

## Instance Functions

### Option:isSome

```lua
function Option:isSome(): boolean
```

Returns `true` if the `Option` is a `Some`, otherwise it returns `false`.

### Option:isSomeAnd

```lua
function Option:isSomeAnd(f: (T) -> boolean): boolean
```

Returns `true` if the `Option` is a `Some` and the value satisfies the given
predicate, otherwise it returns `false`.

### Option:isNone

```lua
function Option:isNone(): boolean
```

Returns `true` if the `Option` is a `None`, otherwise it returns `false`.

### Option:expect

```lua
function Option:expect(message: string): T
```

Returns the value of the option if it is a `Some`, otherwise it throws an error with
the given message.

::: warning THROWS
This function may throw an error.
:::

### Option:unwrap

```lua
function Option:unwrap(): T
```

Returns the value of the option if it is a `Some`, otherwise it throws the following error:

```
called `Option.unwrap()` on a `None` value
```

::: warning THROWS
This function may throw an error.
:::

### Option:unwrapOr

```lua
function Option:unwrapOr(default: T): T
```

Returns the value of the option if it is a `Some`, otherwise it returns the given default.

### Option:unwrapOrElse

```lua
function Option:unwrapOrElse(f: () -> T): T
```

Returns the value of the option if it is a `Some`, otherwise it returns the result of
the given function.

### Option:map

```lua
function Option:map<U>(f: (T) -> U): Option<U>
```

Returns the result of the given function wrapped in an `Option` if the option is
`Some`, otherwise returns `None`.

### Option:mapOr

```lua
function Option:mapOr<U>(default: U, f: (T) -> U): U
```

Returns the result of the given function if the option is `Some`, otherwise returns
the given default value.

### Option:mapOrElse

```lua
function Option:mapOrElse<U>(default: () -> U, f: (T) -> U): U
```

Returns the result of the given function if the option is `Some`, otherwise returns
the result of calling the default function.

### Option:andOpt

```lua
function Option:andOpt<U>(other: Option<U>): Option<U>
```

Returns `None` if the option is `None`, otherwise returns the other option.

### Option:andThen

```lua
function Option:andThen<U>(f: (T) -> Option<U>): Option<U>
```

Returns `None` if the option is `None`, otherwise returns the result of the given
function.

### Option:filter

```lua
function Option:filter(f: (T) -> boolean): Option<T>
```

Returns `None` if the option is `None`, otherwise calls the function with the value:

- if the function returns `true`, returns the original option
- if the function returns `false`, returns `None`

### Option:orOpt

```lua
function Option:orOpt(other: Option<T>): Option<T>
```

Returns the option if it is `Some`, otherwise returns the other option.

### Option:orElse

```lua
function Option:orElse(f: () -> Option<T>): Option<T>
```

Returns the option if it is `Some`, otherwise returns the result of calling the given
function.

### Option:xor

```lua
function Option:xor(other: Option<T>): Option<T>
```

Returns `None` if both options are `Some` or `None`, otherwise returns the option.

### Options:match

```lua
function Option:match<U>(f: {
  Some: (T) -> U,
  None: () -> U
}): U
```

Takes a table containing a `Some` and `None` function. If the option is a `Some`,
calls the `Some` function with the value of the option, otherwise calls the `None`
function. The result of the function call is returned.

## Metamethods

### Option:\_\_tostring

```lua
function Option:__tostring(): string
```

Called when `tostring()` is called on the `Option`.

Converts the `Option` to a string.

### Option:\_\_eq

```lua
function Option:__eq(other: Option<T>): boolean
```

Called when the `==` operator is used on the `Option`.

Returns `true` if both options are `Some` and their values are equal, or if both
options are `None`, otherwise returns `false`.
