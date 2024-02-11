# Roblox

util.luau is designed to work on Roblox too, this is done by processing the
code with [darklua](https://darklua.com/) which will convert the path requires
into Roblox style requires.

## Wally

When syncing the code using [Rojo](https://rojo.space/), it will correctly use
the Roblox version of the code, this is done by adding a `default.project.json`
to the package and pointing it to the generated `roblox` directory.
