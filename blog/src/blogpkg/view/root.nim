import ../types
import std/macros
import karax/[karaxdsl, vdom]
export karaxdsl, vdom

macro renderPage*(ctx: BlogContext, title: string, body: untyped): VNode =
  quote do:
    buildHtml(html):
      head:
        meta(charset="utf-8")
        meta(name="viewport", content="width=device-width, initial-scale=1.0, maximum-scale=1.0")
        title: text `title`
        #  <link href="https://fonts.googleapis.com/css2?family=Merriweather&display=swap" rel="stylesheet"> 
        link(rel="stylesheet", href="https://fonts.googleapis.com/css2?family=Merriweather&display=swap")
        link(rel="stylesheet", href="/public/blog.css")
      body:
        script: text "0"
        header(id="sticky-header"):
          nav:
            a(href="/"): h1: text ctx.blogName()
            ul:
              li: a(href="/"): h4: text "Home"
              li: a(href="/post"): h4: text "Posts"
              li: a(href="/tag"): h4: text "Tags"
          hr()
        `body`
        footer:
          hr()
          p:
            a(href="/"): text `ctx`.blogName()
            for social in `ctx`.socialLinks():
              text " | "
              a(href=social.href): text social.text
          p:
            verbatim "Copyright &copy; 2022 "
            text `ctx`.blogAuthor()
        
        script(src="/public/blog.js"):
          discard
