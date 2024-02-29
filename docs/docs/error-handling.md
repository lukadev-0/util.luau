# Error Handling

The [`result`](/reference/result) utility can be used for more robust error
handling.

Errors are represented as values instead of being thrown using `error()`, this
makes it clear that a function can fail, so you don't forget to handle a
potential error which may lead to unexpected behavior or crashes.

## Creating results

A result can be in two states: `Ok` or `Err`. The `Ok` state represents a
successful value, and the `Err` state represents an error value.

To create an `Ok` result, we can use `Result.Ok`:

```lua
local res = Result.Ok(5)
```

To create an `Err` result, we can use `Result.Err`:

```lua
local res = Result.Err("something went wrong")
```

You can return a result from a function to indicate that the function can fail:

```lua
function divide(a: number, b: number): Result.Result<number, string>
  if b == 0 then
    return Result.Err("cannot divide by zero")
  end

  return Result.Ok(a / b)
end
```

If you need to wrap a function that throws errors with a result, you can use
`Result.try`:

```lua
local res = Result.try(function()
  error("something went wrong")
end)
```

Any errors thrown within the function will be caught and returned as an `Err`,
otherwise the return value will be wrapped in an `Ok`.

## Accessing the inner value

There are multiple ways to access the inner value of a result.

The easiest way is to use `Result.unwrap`:

```lua
local res = Result.Ok(5)
print(Result.unwrap(res)) -- 5

local res = Result.Err("something went wrong")
print(Result.unwrap(res)) -- throws "something went wrong"
```

If the result is an `Err`, `Result.unwrap` will throw an error.

Most of the time, we want to handle the error case without crashing the program.
There are other methods to access the inner value of a result without throwing
an error.

You can use `Result.unwrapOr` to get the `Ok` value or a default value in case
of an `Err`:

```lua
local res = Result.Ok(5)
print(Result.unwrapOr(res, 0)) -- 5

local res = Result.Err("something went wrong")
print(Result.unwrapOr(res, 0)) -- 0
```

The default value is eagerly evaluated, so it's always evaluated, even if the
result is an `Ok`.

You can use `Result.unwrapOrElse` to get the `Ok` value or compute a default
value in case of an `Err`:

```lua
local res = Result.Ok(5)
print(Result.unwrapOrElse(res, function()
  return 0
end)) -- 5
```

However, there are some cases where you don't want to throw an error or use a
default value, but instead want to perform different actions based on whether
the result is `Ok` or `Err`. You can use the `match` method for this:

```lua
local res = Result.Ok(5)

Result.match(res, {
  Ok = function(value)
    print("success:", value)
  end,
  Err = function(err)
    print("error:", err)
  end
})
```

You can also use the `unpack` method, which returns two values: the `Ok` value
or nil, and the `Err` value or nil:

```lua
local res = Result.Ok(5)
local ok, err = Result.unpack(res)
print(ok, err) -- 5 nil
```

This is useful to propagate the error in the function, for example, using the
`divide` function from before:

```lua
local function doCalculation(x: number): Result<number, string>
  local res = divide(x, x * x)

  local ok, err = res:unpack()
  if err then
    return Result.Err(err)
  end

  return ok
end
```

This function will return the result of `divide` if it's `Ok`, otherwise it will
return the error. This is the recommended way to propagate errors.

## Transforming results

You can use the `map` method to transform the inner value of a result:

```lua
local res = Result.Ok(5)
local doubled = res:map(function(value)
  return value * 2
end)
```

This will double the value inside the `Ok` result, or preserve the `Err` value.

You can also map the error instead using the `mapErr` method:

```lua
local some = Result.Err(5)

local doubled = some:mapErr(function(value)
  return value * 2
end)
```

You can also use the `andThen` method to transform the inner value of a result
and return a new result:

```lua
local res = Result.Ok(5)
local doubled = res:andThen(function(value)
  if value % 2 == 0 then
    return Result.Ok(value * 2)
  else
    return Result.Err("value is not even")
  end
end)
```

This will double the value inside the `Ok` result if it's even, or return the
`Err` value if it's odd. If the result is an `Err`, the `andThen` method will
preserve the `Err` value.

You can also use the `match` method from earlier by returning a value from the
callbacks:

```lua
local res = Result.Ok(5)
local doubled = Result.match(res, {
  Ok = function(value)
    return value * 2
  end,
  Err = function(err)
    return 0
  end
})
```

## Learn more

There are more methods available on the `Result` type, this was just a small
tour of what you can do with results. If you want to learn more, see the
[reference](/reference/result) for more information.
