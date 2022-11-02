import ../types, root, tagview
import karax/[karaxdsl, vdom]

type
  PostView* = ref object of View
    post: Post

proc newPostView*(post: Post): PostView =
  new result
  result.post = post

method renderHtml*(self: PostView, ctx: BlogContext): VNode =
  let articleBody = readFile self.post.viewPath()
  ctx.renderPage(self.post.title):
    main:
      article:
        header:
          h1: text self.post.title
          small: text self.post.subtitle
          p:
            for tag in self.post.tags:
              let tagView = newTagView(tag)
              tagView.renderHtml(ctx)
        verbatim(articleBody)
