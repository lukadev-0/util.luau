# Optional Values

The [`option`](/reference/option) utility can be used to represent values that
may or may not exist, akin to using `nil` to represent values that do not exist.

However, using `nil` to represent non-existing values can be error-prone, and
be harder to work with. The `option` utility provides a simpler and safer way to
work with optional values.

## Creating options

An option can be in two states: `Some` or `None`. The `Some` state represents a
value that exists, and the `None` state represents a value that does not exist.

To create a `Some` option, we can use `Option.Some`:

```lua
local opt = Option.Some(5)
```

To create a `None` option, we can use `Option.None`:

```lua
local opt = Option.None
```

## Accessing the inner value

There are multiple ways to access the inner value of an option.

The easiest way is to use the `unwrap` method, which will return the inner value
if it exist, or throw an error if it does not:

```lua
local some = Option.Some(5)
print(some:unwrap()) -- 5

local none = Option.None
none:unwrap() -- throws "called `Option.unwrap()` on a `None` value"
```

If you need to pass a custom error message, you can use the `expect` method:

```lua
local some = Option.Some(5)
print(some:expect("expected a value")) -- 5
```

Sometimes, you want to get the inner value but use a default value if it does not
exist. You can use the `unwrapOr` method for this:

```lua
local some = Option.Some(5)
print(some:unwrapOr(10)) -- 5

local none = Option.None
print(none:unwrapOr(10)) -- 10
```

The value passed to `unwrapOr` is eagerly evaluated, so it will be evaluated even
if the option is `Some`. If you need to lazily evaluate the default value, you can
use the `unwrapOrElse` method:

```lua
local some = Option.Some(5)
print(some:unwrapOrElse(function()
  return 10
end)) -- 5
```

However, there are some cases where you don't want to throw an error or use a
default value, but instead want to perform different actions based on whether
the option is `Some` or `None`. You can use the `match` method for this:

```lua
local some = Option.Some(5)

some:match({
  Some = function(value)
    print("got a value:", value)
  end,
  None = function()
    print("got no value")
  end,
})
```

Options require you to think about the case where the value does not exist, which
can help you write more robust code.

## Transforming options

You can transform the inner value of an option using the `map` method:

```lua
local some = Option.Some(5)

local doubled = some:map(function(value)
  return value * 2
end)
```

The value will be doubled if the option is `Some`, and the `None` state will be
preserved if the option is `None`.

You can also use the `andThen` method to transform the inner value of an option
and return a new option:

```lua
local some = Option.Some(5)

local doubled = some:andThen(function(value)
  if value % 2 == 0 then
    return Option.Some(value * 2)
  else
    return Option.None
  end
end)
```

The value will be doubled if the option is `Some` and the value is even, and the
`None` state will be preserved if the option is `None` or the value is odd.

You can also use the `match` method from earlier by returning a value from the
callbacks:

```lua
local some = Option.Some(5)

local result = some:match({
  Some = function(value)
    return value * 2
  end,
  None = function()
    return 0
  end,
})

print(result) -- 10
```

You can also filter the inner value of an option using the `filter` method:

```lua
local some = Option.Some(5)

local even = some:filter(function(value)
  return value % 2 == 0
end)
```

The value will be preserved if the option is `Some` and the value is even, and the
`None` state will be returned if the option is `None` or the value is odd.

::: tip TYPECHECKING

Luau fails to infer function parameters when passing functions to methods when calling
them using `:` syntax. [Learn more](/reference/option#typechecking).

:::

## Learn More

There are more methods available on the `Option` type, see the
[reference](/reference/option) for more information.