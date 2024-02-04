--[=[
  @class Option

  Represents an optional value: `Some` and contains a value, or `None`
  and does not contain a value.

  Options can be used as an alternative to `nil` to represent the
  absence of a value. They help you avoid bugs by requiring you to
  handle the case where a value might be missing.
]=]
local Option = {}
Option.__index = Option

export type Option<T> = typeof(setmetatable(
	{} :: {
		_s: true,
		_v: T,
	},
	Option
)) | typeof(setmetatable({} :: { _s: false }, Option))

function Option._new<T>(value: T): Option<T>
	return setmetatable({
		_v = value,
	}, Option) :: any
end

--[=[
  The `Option` that does not contain a value.
]=]
Option.None = table.freeze(setmetatable({ _s = false :: false, _v = nil }, Option)) :: Option<never>

--[=[
  Creates a new `Some` with the given value. A `Some` may contain
	a `nil` value.
]=]
function Option.Some<T>(value: T): Option<T>
	local self = setmetatable({ _s = true :: true, _v = value }, Option)
	return table.freeze(self)
end

--[=[
  Converts the given value to an `Option`, returning `None` if the
  value is `nil`.
]=]
function Option.from<T>(value: T | nil): Option<T>
	if value == nil then
		return Option.None
	else
		return Option.Some(value)
	end
end

--[=[
	Returns `true` if the given value is an `Option`.
]=]
function Option.is(value: any): boolean
	return typeof(value) == "table" and getmetatable(value) == Option
end

--[=[
  Returns `true` if the option is a `Some` value.
]=]
function Option.isSome<T>(self: Option<T>): boolean
	return self._s
end

--[=[
	Returns `true` if the option is a `Some` value and the value
	satisfies the given predicate.
]=]
function Option.isSomeAnd<T>(self: Option<T>, f: (T) -> boolean): boolean
	return self._s and f(self._v)
end

--[=[
  Returns `true` if the option is a `None` value.
]=]
function Option.isNone<T>(self: Option<T>): boolean
	return not self._s
end

--[=[
  Returns the value of the option if it is `Some`, otherwise throws
  an error with the given message.
]=]
function Option.expect<T>(self: Option<T>, message: string): T
	if not self._s then
		error(message, 2)
	end
	return self._v
end

--[=[
  Returns the value of the option if it is `Some`, otherwise throws
  an error.
]=]
function Option.unwrap<T>(self: Option<T>): T
	if not self._s then
		error("called `Option.unwrap()` on a `None` value", 2)
	end
	return self._v
end

--[=[
  Returns the value of the option if it is `Some`, otherwise returns
  the given default value.
]=]
function Option.unwrapOr<T>(self: Option<T>, default: T): T
	if not self._s then
		return default
	end
	return self._v
end

--[=[
  Returns the value of the option if it is `Some`, otherwise returns
  the result of calling the given function.
]=]
function Option.unwrapOrElse<T>(self: Option<T>, f: () -> T): T
	if not self._s then
		return f()
	end
	return self._v
end

--[=[
  Returns the result of the given function wrapped in an `Option` if
  the option is `Some`, otherwise returns `None`.
]=]
function Option.map<T, U>(self: Option<T>, f: (T) -> U): Option<U>
	if not self._s then
		return Option.None
	end
	return Option.Some(f(self._v))
end

--[=[
  Returns the result of the given function if the option is `Some`,
  otherwise returns the given default value.
]=]
function Option.mapOr<T, U>(self: Option<T>, default: U, f: (T) -> U): U
	if not self._s then
		return default
	end
	return f(self._v)
end

--[=[
  Returns the result of the given function if the option is `Some`,
  otherwise returns the result of calling the default function.
]=]
function Option.mapOrElse<T, U>(self: Option<T>, default: () -> U, f: (T) -> U): U
	if not self._s then
		return default()
	end
	return f(self._v)
end

--[=[
  Returns `None` if the option is `None`, otherwise returns the other option.
]=]
function Option.andOpt<T, U>(self: Option<T>, other: Option<U>): Option<U>
	if self:isNone() then
		return Option.None
	end
	return other
end

--[=[
  Returns `None` if the option is `None`, otherwise calls the given
  function with the value of the option and returns the result.
]=]
function Option.andThen<T, U>(self: Option<T>, f: (T) -> Option<U>): Option<U>
	if not self._s then
		return Option.None
	end
	return f(self._v)
end

--[=[
  Returns `None` if the option is `None`, otherwise calls the given
  function with the value:
   - if the function returns `true`, returns the original option
   - if the function returns `false`, returns `None`
]=]
function Option.filter<T>(self: Option<T>, f: (T) -> boolean): Option<T>
	if not self._s then
		return Option.None
	end
	if f(self._v) then
		return self
	end
	return Option.None
end

--[=[
  Returns the option if it is `Some`, otherwise returns
  the other option.
]=]
function Option.orOpt<T>(self: Option<T>, other: Option<T>): Option<T>
	if self._s then
		return self
	end
	return other
end

--[=[
  Returns the option if it is `Some`, otherwise returns
  the result of calling the given function.
]=]
function Option.orElse<T>(self: Option<T>, f: () -> Option<T>): Option<T>
	if self._s then
		return self
	end
	return f()
end

--[=[
  Returns `Some` if exactly one of the options is `Some`, otherwise
  returns `None`.
]=]
function Option.xor<T>(self: Option<T>, other: Option<T>): Option<T>
	if not self._s then
		return other
	end
	if not other._s then
		return self
	end
	return Option.None
end

--[=[
	Takes a table containing a `Some` and `None` function. If the option
	is a `Some`, calls the `Some` function with the value of the option,
	otherwise calls the `None` function. The result of the function call
	is returned.
]=]
function Option.match<T, U>(
	self: Option<T>,
	f: {
		Some: (T) -> U,
		None: () -> U,
	}
): U
	if self._s then
		return f.Some(self._v)
	end
	return f.None()
end

--[=[
	Converts the given option to a string.
]=]
function Option.__tostring<T>(self: Option<T>): string
	if self._s then
		return `Option::Some({self._v})`
	else
		return "Option::None"
	end
end

--[=[
	Returns `true` if the given value is an `Option` and contains the
	same value as this option, `false` otherwise.
]=]
function Option.__eq<T>(self: Option<T>, other: Option<T>): boolean
	if Option.is(other) then
		if self._s and other._s then
			return self._v == other._v
		end
		return self._s == other._s
	end
	return false
end

return Option
