import ../types
import ../view/[postview, postcardview, root]
import karax/[vdom]
import prologue
import std/[sequtils, options, strutils, algorithm, strformat]

type
  Posts* = ref object of Controller

iterator about(ctx: BlogContext): string =
  yield fmt"""{ctx.blogName()} is the personal blog of {ctx.blogAuthor()}.
  Subject matter will range from software engineering, to basketball, to personal matters."""

proc showPost(ctx: Context) {.async.} =
  let
    ctx = BlogContext(ctx)
    post = ctx.postManifest().filterIt(it.id == ctx.getPathParams("id"))

  if post.len == 0:
    resp error404()
  else:
    let view = newPostView(post[0])
    resp htmlResponse($view.renderHtml(ctx))

proc allPosts(ctx: Context) {.async.} =
  let
    ctx = BlogContext(ctx)
    postsPerPage = ctx.maxPostsPerPage()
    page = max(0, ctx.getQueryParamsOption("p").map(parseInt).get(0))
    start = postsPerPage * page
    allPosts = ctx.postManifest().sortedByIt(it.seqnum).reversed()
    posts = allPosts[min(high(allPosts), start)..<min(len(allPosts), start + postsPerPage)]

    header = buildHtml(h2): text "All Posts"

    postsView = newPostCardView(posts, header)

    outView = ctx.renderPage(fmt"Posts | {ctx.blogName()}"):
      main:
        postsView.renderHtml(ctx)
        footer(class="flex-row"):
          if start > 0:
            a(class="button", href="/post?p=" & $(page - 1)): em: verbatim "&larr; Previous"
          else:
            a(class="button disabled"): em: verbatim "&larr; Previous"
          
          if start + posts.len() < allPosts.len():
            a(class="button", href="/post?p=" & $(page + 1)): em: verbatim "Next &rarr;"
          else:
            a(class="button disabled"): em: verbatim "Next &rarr;"

  resp htmlResponse($outView)
      

proc homepage(ctx: Context) {.async.} =
  let
    ctx = BlogContext(ctx)
    latestPostsCount = ctx.latestPostsCount()
    # start = max(0, ctx.getQueryParamsOption("p").map(parseInt).get(0))
    posts = ctx.postManifest().sortedByIt(it.seqnum).reversed()

    latestPosts = posts[0..min(high(posts), latestPostsCount)]
    header = buildHtml(header):
      h2: text "Latest Posts"
    latestPostsView = newPostCardView(latestPosts, header)

    outView = ctx.renderPage(fmt"Home | {ctx.blogName()}"):
      main:
        latestPostsView.renderHtml(ctx)
        hr()
        section:
          header:
            h2: text fmt"About {ctx.blogName()}"
          for paragraph in about(ctx):
            p: text paragraph

  resp htmlResponse($outView)

method setRoutes*(self: Posts, server: Prologue) =
  server.addRoute("/post/{id}", showPost, HttpGet)
  server.addRoute("/post", allPosts, HttpGet)
  server.addRoute("/", homepage, HttpGet)
