# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import prologue
import blogpkg/[types, postdb, server]
import std/os

import blogpkg/controller/[
  posts,
  tags
]

when isMainModule:
  case paramStr(1)
  of "run":
    launchServer() do (app: Prologue):
      Posts().setRoutes(app)
      Tags().setRoutes(app)
  of "new":
    let postId = paramStr(2)
    newPost(postId)
  of "compile":
    compilePosts()
  else:
    echo "Unknown command: ", paramStr(1)
    quit(-1)
