import ../types, root
import karax/[karaxdsl, vdom]
from std/strutils import replace

type
  TagView* = ref object of View
    tag: Tag
    button: bool

proc newTagView*(tag: Tag, button = true): TagView =
  new result
  result.tag = tag
  result.button = button

method renderHtml*(self: TagView, ctx: BlogContext): VNode =
  let id = self.tag.id.replace("-", "&#8209;")
  if self.button:
    buildHtml(a(class="tag-button", href="/tag/" & self.tag.id, id="btag-" & self.tag.id)):
      text "#"
      verbatim id
  else:
    buildHtml(small(class="tag-nobutton")):
      text "#"
      verbatim id
