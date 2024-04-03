# Typechecking

util.luau tries to be as type-safe as possible, so you can catch bugs sooner and
get better autocomplete. However due to limitations in Luau, some areas don't
typecheck as well as others.

## Callbacks in Methods

When calling a method that takes a callback, such as
[`Option:map`](/reference/option#option-map) using `:` syntax, the parameters of
the callback are not inferred, and instead show up as `a`.

```lua
local opt = Option.Some(4)

local mapped = opt:map(function(value)
  -- ┌────────────────────────── ^^^^^
  -- └ this is typed as `a` instead of `number`
  return value * 2
end)
```

To work around this, you can explicitly type the parameter:

```lua
local opt = Option.Some(4)

local mapped = opt:map(function(value: number)
  return value * 2
end)
```

`value` now has the correct type of `number`. If the type of `value` is
incorrect, Luau will throw a type error as it does know the correct type of the
function, however it fails to infer it.

```lua
local opt = Option.Some(4)

-- TypeError: Type
--   '(string) -> number'
-- could not be converted into
--   '(number) -> number'
local mapped = opt:map(function(value: string)
  return value * 2
end)
```

There is an open issue regarding this,
[#1011](https://github.com/luau-lang/luau/issues/1011).

Another workaround is to use the `.` syntax instead of `:` syntax:

```lua
local opt = Option.Some(4)

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

## Type packs

Due to the fact that unions with type packs in them are not supported, types
like `Option` or `Future` only take a single type parameter. This means that
they can't store tuples.
