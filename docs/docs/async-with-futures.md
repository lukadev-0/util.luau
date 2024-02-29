# Async with Futures

The [`future`](/reference/future) utility can be used to represent asynchronous
computations.

A future represents a value that does not exist yet, but will exist at some
point in the future.

They're useful to represent asynchronous computation such as network requests.

## Creating futures

A future can be in two states: `Pending` or `Finished`. The `Pending` state
represents a computation that is still running, and the `Finished` state
represents a computation that has finished.

When a future finishes, that is also known as "resolving".

To create a future that is already finished, we can use `Future.new`:

```lua
local fut = Future.new(5)
```

To create a future that is pending, and will never resolve, you can use
`Future.never`:

```lua
local fut = Future.never()
```

Though, we want our futures to do something, to do this, we can use `Future.spawn`
which will spawn a new thread and run the given function:

```lua
local function httpGet(url)
  -- some code to make a network request
end

local fut = Future.spawn(httpGet, "https://google.com/")
```

This future will resolve with the result of the `httpGet` function.

You may also pass an anonymous function to `Future.spawn`:

```lua
local fut = Future.spawn(function()
  return 5
end)
```

We can return futures from functions to represent asynchronous computations:

```lua
function httpGet(url: string): Future.Future<string>
  return Future.spawn(function()
    -- some code to make a network request
  end)
end
```

::: tip MEMORY USAGE

The above code will create a closure for each call to `httpGet`, which may
cause high memory usage. To avoid this, you can pass any values the function
needs as arguments:

```lua
function httpGet(url: string): Future.Future<string>
  return Future.spawn(function(url)
    -- some code to make a network request
  end, url)
end

-- you may also define the function separately if you prefer:

local function httpGet(url: string): Future.Future<string>
  local function inner(url: string): string
    -- some code to make a network request
  end

  return Future.spawn(inner, url)
end
```

This will allow Luau to [cache the function](https://luau-lang.org/performance#closure-caching)
and reuse it across calls, reducing memory usage.

:::

## Accessing the inner value

We now have futures that will resolve at some point, but how do we access the
inner value?

One way is the `now` method, which will return an [option](/docs/optional-values)
containing the current value, or `None` if the future is still pending:

```lua
local fut = Future.new(5)

local value = fut:now():unwrap()
print(value) -- 5
```

However, usually we want to wait for the future to resolve, and then do
something with the value. We can use the `await` method for this:

```lua
local fut = Future.spawn(httpGet, "https://google.com/")

local value = fut:await()
print(value) -- 5
```

This will yield the current thread until the future resolves, and then return
the value.

You may also use the `after` method to execute a callback when the future
resolves:

```lua
local fut = Future.spawn(httpGet, "https://google.com/")

fut:after(function(value)
  print(value) -- 5
end)
```

The callback is executed in a separate thread when the future resolves.

## Composing futures

The future utility provides a few methods to compose futures.

The `all` function can be used to wait for every future in an array to resolve:

```lua
local fut1 = Future.new(5)
local fut2 = Future.new(10)

local fut = Future.all({ fut1, fut2 })

local values = fut:await()
print(values[1]) -- 5
print(values[2]) -- 10
```

This will wait for all given futures to resolve, and resolves to an array of
the resolved values.

The `race` utility can be used to wait for the first future in an array to
resolve:

```lua
local fut1 = Future.new(5)
local fut2 = Future.new(10)

local fut = Future.race({ fut1, fut2 })

local value = fut:await()
print(value) -- 5
```

This will wait for the first future to resolve, and resolves to the value of
the first resolved future.

## Error handling

Futures do not support throwing errors, to handle errors, you can use futures
in combination with [results](/docs/error-handling).

For example, the following code will call a yielding function that may fail
and wraps it in a future and result:

```lua
local fut = Future.spawn(Result.try, httpGet, "https://google.com/")
```

You can then await the future and handle the result:

```lua
local res = fut:await()

res:match({
  Ok = function(value)
    print("Got a response:", value)
  end,
  Err = function(err)
    warn("Failed to do the request:", err)
  end
})
```

## Learn more

There are more methods available on the `Future` type, this was just a small
tour of what you can do with futures. If you want to learn more, see the
[reference](/reference/future) for more information.
