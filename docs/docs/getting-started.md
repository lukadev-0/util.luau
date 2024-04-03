# Getting Started

util.luau is a collection of useful utilities for Luau, designed to work on any
Luau runtime.

## Installation

### With Wally

The recommended way to install util.luau is with [Wally](https://wally.run), a
package manager for Roblox. Each utility is published as a separate package, the
package name will be specified in the documentation for each utility.

If you're using [Lune](https://lune-org.github.io/lune), you can use
[this fork of Wally](https://github.com/VirtualButFake/wally) by
[VirtualButFake](https://github.com/VirtualButFake).

#### Accessing types

You may find that you cannot access the types of the packages you install with
Wally. This is because Wally generates linker scripts for the dependencies,
which don't re-export the types. To fix this, you need to use the
[wally-package-types](https://github.com/JohnnyMorganz/wally-package-types) tool
after running `wally install`.

If you're using the fork of Wally for Lune, you can use
[lune-wally-package-types](https://github.com/VirtualButFake/lune-wally-package-types).

### Roblox Models

You can also install `util.luau` through `.rbxm` files, which are available in
the [releases](https://github.com/lukadev-0/util.luau/releases), each package
has its own `.rbxm` file, and a `util.rbxm` is also available which contains
every package.

## Learning

The **Guide** is a great place to start to learn about some common utilities and
how to use them.

If you'd like to see the full list of utilities and their APIs, check out the
[reference](/reference/).
