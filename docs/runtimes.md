# Runtimes

util.luau is designed to be runtime agnostic, meaning it should run on any
Luau runtime.

However, some packages require access to libraries that differ between runtimes,
in order to bridge this gap, the [`env`](/reference/env) package is used.

The `env` package provides information about the environment, and provides
common library interfaces that can be implemented for different runtimes.

Currently, there are default implementations for Roblox and Lune. If you need to
run code on a different runtime, you can
[create custom implementations](/reference/env#implementing-libraries) of the
libraries.
