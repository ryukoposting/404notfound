import ../types
import ../view/[postview, postcardview, tagview, root]
import karax/[vdom]
import prologue
import std/[sequtils, options, strutils, strformat]
from std/sugar import collect

type
  Tags* = ref object of Controller

proc showTag(ctx: Context) {.async.} =
  let
    ctx = BlogContext(ctx)
    posts = ctx.postManifest()
    tag = ctx.getPathParams("id")
    matchingPosts = posts.filterIt(it.tags.anyIt(it.id == tag))

    tagText = "#" & tag
    header = buildHtml(header):
      h2: text fmt"Tag {tagText}"

    postsView = newPostCardView(matchingPosts, header)

    outView = ctx.renderPage(fmt"{tagText} | {ctx.blogName()}"):
      main:
        postsView.renderHtml(ctx)

  resp htmlResponse($outView)

proc searchTags(ctx: Context) {.async.} =
  let
    ctx = BlogContext(ctx)

    outView = ctx.renderPage(fmt"Tags | {ctx.blogName()}"):
      main:
        h1: text "Tags"
        input(`type`="text", id="searchinput-tags", placeholder="search-for-a-tag", pattern="^[a-zA-Z0-9-]*$")
        tdiv:
          for tag in ctx.allTags():
            let tv = newTagView(tag)
            tv.renderHtml(ctx)

  resp htmlResponse($outView)

method setRoutes*(self: Tags, server: Prologue) =
  server.addRoute("/tag", searchTags, HttpGet)
  server.addRoute("/tag/{id}", showTag, HttpGet)
