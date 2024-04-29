-- see .lune/test.luau

export type TupleFunctions = {
	map: (...any) -> ...any,
	other: () -> ...any,
	assertEq: (...any) -> (),
	assertEqMapped: (...any) -> (),
	assertEqOther: (...any) -> (),
	assertEqOtherMapped: (...any) -> (),
}

-- selene: allow(unused_variable)
return function(f: (tuple: TupleFunctions, ...any) -> ())
	return nil :: any
end
