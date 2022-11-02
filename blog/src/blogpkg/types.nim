import prologue
import std/json
from std/sugar import collect
from std/times import DateTime, parse
from std/os import fileExists
from karax/vdom import VNode

type
  Model* = ref object of RootObj
  View* = ref object of RootObj
  Controller* = ref object of RootObj

  Post* = ref object of Model
    seqnum*: int
    id*: string
    title*: string
    subtitle*: string
    tags*: seq[Tag]
    updated*: DateTime

  Tag* = ref object of Model
    id*: string

  BlogContext* = ref object of Context
    manifest: seq[Post]

method renderHtml*(self: View, ctx: BlogContext): VNode {.base.} =
  raise ValueError.newException("View.renderHtml method not defined")

method toJson*(self: Model): string {.base.} =
  raise ValueError.newException("Model.toJson method not defined")

method fromJson*(self: Model, data: JsonNode) {.base.} =
  raise ValueError.newException("Model.fromJson method not defined")

method setRoutes*(self: Controller, server: Prologue) {.base.} =
  raise ValueError.newException("Controller.setRoutes method not defined")


method fromJson*(self: Post, data: JsonNode) =
  self.seqnum = getInt data["seqnum"]
  self.id = getStr data["id"]
  self.title = getStr data["title"]
  self.subtitle = getStr data["subtitle"]
  self.tags = collect:
    for item in data["tags"]:
      Tag(id: getStr(item["id"]))
  self.updated = parse(getStr data["updated"], "yyyy-MM-dd'T'HH:mm:sszzz")

proc viewPath*(self: Post): string =
  "./public/posts/" & self.id & ".html"

proc exists*(self: Post): bool =
  fileExists self.viewPath

method extend*(ctx: BlogContext) {.gcsafe.} =
  ctx.manifest = @[]

proc postManifest*(ctx: BlogContext): seq[Post] =
  if ctx.manifest.len == 0:
    let jn = ctx.getSettings("postManifest")
    for postData in jn.items:
      var post = Post()
      post.fromJson(postData)
      ctx.manifest.add post
  result = ctx.manifest

proc `==`*(x, y: Tag): bool = x.id == y.id

iterator allTags*(ctx: BlogContext): Tag =
  let jn = ctx.getSettings("allTags")
  for tag in jn.items:
    yield Tag(id: getStr(tag))

proc blogAuthor*(ctx: BlogContext): string =
  ctx.getSettings("blogAuthor").getStr()

proc blogName*(ctx: BlogContext): string =
  ctx.getSettings("blogName").getStr()

proc maxPostsPerPage*(ctx: BlogContext): int =
  ctx.getSettings("maxPostsPerPage").getInt()

proc latestPostsCount*(ctx: BlogContext): int =
  ctx.getSettings("latestPostsCount").getInt()

iterator socialLinks*(ctx: BlogContext): tuple[text, href: string] =
  let socials = ctx.getSettings("socials")

  for k, v in socials.pairs:
    yield (text: k, href: v.getStr())
