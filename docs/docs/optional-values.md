# Optional Values

The [`option`](/reference/option) utility can be used to represent values that
may or may not exist, akin to using `nil` to represent values that do not exist.

However, using `nil` to represent non-existing values can be error-prone, and be
harder to work with. The `option` utility provides a simpler and safer way to
work with optional values.

## Creating options

An option can be in two states: `Some` or `None`. The `Some` state represents a
value that exists, and the `None` state represents a value that does not exist.

To create a `Some` option, we can use `Option.Some`:

```lua
local opt = Option.Some(5)
```

An option can contain multiple values:

```lua
local opt = Option.Some(5, "hello", true)
```

To create a `None` option, we can use `Option.None`:

```lua
local opt = Option.None
```

## Accessing the inner values

There are multiple ways to access the inner values of an option.

The easiest way is to use the `unwrap` method, which will return the inner
values if it exist, or throw an error if it does not:

```lua
local some = Option.Some(5)
print(some:unwrap()) -- 5

local none = Option.None
none:unwrap() -- throws "called `Option.unwrap()` on a `None` value"
```

If you need to pass a custom error message, you can use the `expect` method:

```lua
local none = Option.None
print(none:expect("expected a value")) -- throws "expected a value"
```

Sometimes, you want to get the inner value but use a default value if it does
not exist. You can use the `unwrapOr` method for this:

```lua
local some = Option.Some(5)
print(some:unwrapOr(10)) -- 5

local none = Option.None
print(none:unwrapOr(10)) -- 10
```

The value passed to `unwrapOr` is eagerly evaluated, so it will be evaluated
even if the option is `Some`. If you need to lazily evaluate the default value,
you can use the `unwrapOrElse` method:

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

Options require you to think about the case where the value does not exist,
which can help you write more robust code.

## Transforming options

Aside from accessing the inner value, you can also apply transformations to
options and return new options.

You can transform the inner value of an option using the `map` method:

```lua
local some = Option.Some(5)

local doubled = some:map(function(value)
  return value * 2
end)
```

The `Some` value will be doubles, and the `None` will be preserved.

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

If the `Some` value is even, it will be doubled. Otherwise, `None` will be
returned. If the option is `None`, it will be preserved.

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

The value will be preserved if the option is `Some` and the value is even, and
the `None` state will be returned if the option is `None` or the value is odd.

::: tip TYPECHECKING

Luau fails to infer function parameters when passing functions to methods when
calling them using `:` syntax. [Learn more](/reference/option#typechecking).

:::

## Joining options

Sometimes you have multiple options and you want to combine them into a single
option.

For example, lets say you had two options, and you wanted to get the sum of
their values. You may achieve this using the `andThen` and `map` methods:

```lua
local optA = Option.Some(5)
local optB = Option.Some(10)

local sum = optA:andThen(function(a)
  return optB:map(function(b)
    return a + b
  end)
end)

print(sum) -- Option::Some(15)
```

However, this introduces multiple levels of nesting, which may be undesirable.

Instead, we can use the `join` method to turn both options into a single option,
which we can map over:

```lua
local optA = Option.Some(5)
local optB = Option.Some(10)

local sum = optA:join(optB):map(function(a, b)
  return a + b
end)
```

If either option is `None`, the result will be `None`.

## Learn more

There are more methods available on the `Option` type, this was just a small
tour of what you can do with options. If you want to learn more, see the
[reference](/reference/option) for more information.
