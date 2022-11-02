import types, mdex
import markdown
import std/[tables, os, strutils, times, json, xmltree, strtabs, sequtils]
from std/sugar import collect
from std/uri import parseUri, `/`

const PostsDir = "./posts"
const PostsOutputDir = "./public/posts"
const PostsUri = parseUri("/public/posts")
const PostsManifest = "./public/posts/manifest.json"
const BodyMdFilename = "body.md"
const DefaultBodyMd = """%%title Article Title
%%subtitle Article subtitle
%%tags foo bar baz

Hello, world!
"""

proc `%`(dt: DateTime): JsonNode =
  newJString dt.format("yyyy-MM-dd'T'HH:mm:sszzz")

proc parsePostDir(path: string): (int, string) =
  assert path[4] == '-'

  result[0] = parseInt(path[0..3])
  result[1] = path[5..^1]

proc compilePosts* =
  assert dirExists(PostsDir)
  assert dirExists(PostsOutputDir)

  var manifest: OrderedTable[string,Post]

  for postDir in PostsDir.walkDir(relative = true):
    if postDir.kind != pcDir: continue
    let
      (seqnum, id) = parsePostDir(postDir.path)
      postPath = PostsDir / postDir.path
      bodyMdPath = postPath / BodyMdFilename
      resourceDir = PostsOutputDir / id
      outputPath = PostsOutputDir / id & ".html"
      modifiedTime = getLastModificationTime(bodyMdPath)
      article = newArticle(bodyMdPath)
      doRecompile =
        if fileExists(outputPath):
          modifiedTime > getLastModificationTime(outputPath)
        else:
          true

    if id in manifest:
      raise ValueError.newException("Duplicate sequence number: " & $seqnum)

    manifest[id] = Post(
      seqnum: seqnum,
      id: id,
      title: article.metadata["title"],
      subtitle: article.metadata["subtitle"],
      tags: article.metadata["tags"].split(' ').mapIt(Tag(id: it.toLower().replace('_', '-'))),
      updated: modifiedTime.inZone local()
    )

    if doRecompile:
      echo "Recompiling: ", bodyMdPath
      let config = ArticleConfig(
        localRoot: PostsUri / id
      )

      article.genHtml(config)

      createDir resourceDir
      writeFile(outputPath, $article.htmlTree)

      for file in postPath.walkDir():
        let fileName = extractFilename(file.path)
        if fileName != BodyMdFilename:
          copyFile file.path, resourceDir / fileName

  manifest.sort do (left, right: (string, Post)) -> int:
    left[1].seqnum.cmp(right[1].seqnum)

  let
    manifestList = collect:
      for _, v in manifest:
        v

    manifestJson = %manifestList

  writeFile(PostsManifest, $manifestJson)

proc newPost*(id: string) =
  assert dirExists(PostsDir)
  var newSeqNum = 0
  for postDir in PostsDir.walkDir(relative = true):
    if postDir.kind != pcDir: continue
    let
      (seqnum, postId) = parsePostDir(postDir.path)
    if id == postId:
      echo "A post with id '", id, "' already exists."
      quit(-1)
    newSeqNum = max(seqnum + 1, newSeqNum)

  let
    dirName = align($newSeqNum, 4, padding = '0') & '-' & id
    postDir = PostsDir / dirName
    bodyMdPath = postDir / BodyMdFilename

  createDir postDir
  writeFile bodyMdPath, DefaultBodyMd

  echo "Created new post at ", bodyMdPath
