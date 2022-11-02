import markdown
import std/[strtabs, uri, pegs, streams, htmlparser, xmltree, strutils]

type
  Article* = ref object
    metadata*: StringTableRef
    mdText: string
    filename: string
    htmlTree*: XmlNode

  ArticleConfig* = object
    localRoot*: Uri

proc parseMetadata(line: string): tuple[match: bool, key, value: string] =
  let metadataPeg {.global.} = peg"attr <- ^ '%%' {\ident+} ' ' {.*}"
  var caps = ["", ""]
  if line.match(metadataPeg, caps):
    result = (match: true, key: caps[0], value: caps[1])

proc isLocal(uri: Uri): bool =
  uri.hostname == "" and uri.scheme == "" and uri.path.startsWith "./"

proc `[]`(n: XmlNode, i: BackwardsIndex): auto = n[n.len - int(i)]

proc transformHtmlTree(html: XmlNode, config: ArticleConfig, parent: XmlNode = nil) =
  if html.kind != xnElement: return

  proc getExplicitId(text: string): string =
    let customIdPeg {.global.} = peg"h <- '{#' { (\ident / '-')+ } '}' $"
    var caps = [""]
    discard text.find(customIdPeg, caps)
    result = caps[0]

  func textToHeaderId(text: string): string =
    for c in text:
      if c.isAlphaNumeric():
        result &= c.toLowerAscii()
      elif c == ' ':
        result &= '-'

  let
    srcUri = parseUri html.attr("src")
    hrefUri = parseUri html.attr("href")
    isHeading = html.tag in ["h1", "h2", "h3", "h4", "h5", "h6"]

  if srcUri.isLocal():
    html.attrs["src"] = $(config.localRoot / srcUri.path[2..^1])
  if hrefUri.isLocal():
    html.attrs["href"] = $(config.localRoot / hrefUri.path[2..^1])
  if isHeading:
    let
      explicitId = getExplicitId(html.innerText)
      id =
        if explicitId != "":
          explicitId
        else:
          textToHeaderId(html.innerText)
    
    if html.attrs.isNil:
      html.attrs = toXmlAttributes ("id", id)
    else:
      html.attrs["id"] = id

    if explicitId != "":
      assert html[^1].kind == xnText
      html[^1].text = html[^1].text[0..^(4 + len(explicitId))]

  for child in html.items:
    transformHtmlTree(child, config)

proc newArticle*(filename: string): Article =
  new result
  result.filename = filename
  result.metadata = newStringTable(modeStyleInsensitive)

  var
    mdStream = newStringStream()

  for line in lines(filename):
    let (isMetadata, key, value) = parseMetadata(line)
    if isMetadata:
      result.metadata[key] = value
    else:
      mdStream.writeLine line

  # gross, inefficient, and terrible. generate a raw HTML string from markdown,
  # then parse the resulting HTML.
  mdStream.setPosition(0)
  result.mdText = mdStream.readAll()

proc genHtml*(self: Article, config: ArticleConfig) =
  var
    htmlStream = newStringStream()
    htmlErrors: seq[string]
  let
    mdConfig = initCommonmarkConfig()

  htmlStream.writeLine markdown(self.mdText, mdConfig)
  htmlStream.setPosition(0)

  let
    htmlTree = parseHtml(htmlStream, self.filename, htmlErrors)
  if htmlErrors.len > 0:
    for err in htmlErrors:
      echo "HTML Error: ", err
      quit(-1)

  htmlTree.tag = "div"
  transformHtmlTree(htmlTree, config)
  self.htmlTree = htmlTree
