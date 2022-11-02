# This is just an example to get you started. Users of your hybrid library will
# import this file by writing ``import blogpkg/submodule``. Feel free to rename or
# remove this file altogether. You may create additional modules alongside
# this file as required.

import prologue
import prologue/middlewares/staticfile
import types
import std/[json, jsonutils, streams, sequtils, algorithm]
from std/sugar import collect

proc launchServer*(loadRoutes: proc(app: Prologue)) =
  const
    manifestFilename = "./public/posts/manifest.json"
    settingsFilename = "config.debug.json"
  let
    manifestJson = parseJson(openFileStream(manifestFilename), manifestFilename)
    allTags = collect:
      for postData in manifestJson:
        var post = Post()
        post.fromJson(postData)
        for tag in post.tags:
          tag
    tagsJson = allTags.deduplicate().mapIt(it.id).sorted().toJson()
  var
    settingsJson = parseJson(openFileStream(settingsFilename), settingsFilename)
  settingsJson["postManifest"] = manifestJson
  settingsJson["allTags"] = tagsJson
  let
    settings = loadSettings(settingsJson)
  # settings.
  var app = newApp(settings)
  app.use staticFileMiddleware("public")
  loadRoutes(app)
  app.run(BlogContext)
