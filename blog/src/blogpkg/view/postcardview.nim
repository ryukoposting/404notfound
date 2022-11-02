import ../types, root, tagview
import karax/[karaxdsl, vdom]

type
  PostCardView* = ref object of View
    posts: seq[Post]
    heading: VNode

proc newPostCardView*(posts: seq[Post], heading: VNode = nil): PostCardView =
  new result
  result.posts = posts
  result.heading = heading

method renderHtml*(self: PostCardView, ctx: BlogContext): VNode =
  buildHtml(section):
    if not self.heading.isNil:
      self.heading
    tdiv(class="card-grid"):
      for post in self.posts:
        a(href="/post/" & post.id, class="unstyled-text"):
          aside(class="flex-card"):
            h3: text post.title
            p: small: text post.subtitle
            tdiv(class="flex-card-bottom flex-card-right"):
              for tag in post.tags:
                let tagView = newTagView(tag, button=false)
                tagView.renderHtml(ctx)
