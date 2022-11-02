# Package

version       = "0.1.0"
author        = "Evan Perry Grove"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["blog"]


# Dependencies

requires "nim >= 1.6.8"
requires "prologue >= 0.6.2"
requires "karax >= 1.2.2"
requires "markdown >= 0.8.5"
