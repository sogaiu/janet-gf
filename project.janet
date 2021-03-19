(import ./support/path)
(import ./support/patch)

(declare-project
  :name "gf"
  :url "https://gitlab.com/sogaiu/janet-gf"
  :repo "git+https://gitlab.com/sogaiu/janet-gf.git")

# to make a standalone thing with no external dependencies via jpm,
# git submodules plus patching is used

(rule "prepare-jts" []
      (def wd (os/cwd))
      (defer (os/cd wd)
        # create and populate jts
        (os/mkdir "jts")
        (def jts-src-root
          "janet-tree-sitter/janet-tree-sitter")
        # copy the required parts of janet-tree-sitter
        (each item (os/dir jts-src-root)
          (copy (path/join jts-src-root item)
                "jts"))
        # patch the source
        (unless (patch/patch "jts/tree_sitter.c"
                             "support/cfun_ts_init.c")
          (eprintf "patching failed")
          (os/exit 1))))

(add-dep "build" "prepare-jts")

(declare-native
  :name "_tree-sitter"
  :cflags [;default-cflags
           "-Itree-sitter/lib/include"
           "-Itree-sitter/lib/src"
           "-std=c99" "-Wall" "-Wextra"
           # XXX: for debugging
           #"-O0" "-g3"
          ]
  :source ["jts/tree_sitter.c"
           "tree-sitter/lib/src/lib.c"
           "tree-sitter-janet-simple/src/parser.c"
           "tree-sitter-janet-simple/src/scanner.c"])

# XXX: building doesn't succeed without this sort of thing
(each name ["_tree-sitter.a"
            "_tree-sitter.meta.janet"
            "_tree-sitter.so"]
  (def jts-path (path/join "jts" name))
  (def build-path (path/join "build" name))
  (rule jts-path [build-path]
        (copy build-path
              jts-path))
  (add-dep "build" jts-path))

(declare-executable
  :name "gf"
  :entry "gf.janet")

(rule "clean-jts" []
      (rm "jts"))

(add-dep "clean" "clean-jts")
