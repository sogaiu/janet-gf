(import ./support/path)
(import ./support/patch)

(declare-project
  :name "gf"
  :url "https://gitlab.com/sogaiu/janet-gf"
  :repo "git+https://gitlab.com/sogaiu/janet-gf.git")

# to make a standalone thing with no external dependencies via jpm,
# git submodules plus patching is used

(declare-native
  :name "_tree-sitter"
  :cflags [;default-cflags
           "-Ijanet-tree-sitter/tree-sitter/lib/include"
           "-Ijanet-tree-sitter/tree-sitter/lib/src"
           # XXX: for debugging
           #"-O0" "-g3"
          ]
  :source ["jts/tree_sitter.c"
           "janet-tree-sitter/tree-sitter/lib/src/lib.c"
           "tree-sitter-janet-simple/src/parser.c"
           "tree-sitter-janet-simple/src/scanner.c"])

# patching
(rule "jts/tree_sitter.c" []
      (os/mkdir "jts")
      (copy "janet-tree-sitter/janet-tree-sitter/tree_sitter.c"
            "jts")
      (patch/patch "jts/tree_sitter.c"
                   "support/cfun_ts_init.c"))

# using a custom version instead of the one in janet-tree-sitter
(rule "jts/tree-sitter.janet" []
      (os/mkdir "jts")
      # using another one anyway so no point in copying
      #(copy "janet-tree-sitter/janet-tree-sitter/tree-sitter.janet"
      #      "jts")
      (copy "support/tree-sitter.janet"
            "jts"))

(rule "jts/path.janet" []
      (os/mkdir "jts")
      (copy "janet-tree-sitter/janet-tree-sitter/path.janet"
            "jts"))

## gf.janet -- rather manual...

(def names
  (case (os/which)
    :windows
    (map |(string "_tree-sitter" $)
         [".meta.janet"
          ".dll"
          ".exp"
          ".lib"
          ".static.lib"])
    # *nix
    (map |(string "_tree-sitter" $)
         [".meta.janet"
          ".a"
          ".so"])))

(each name names
  (def jts-path (path/join "jts" name))
  (def build-path (path/join "build" name))
  (rule jts-path []
        (os/mkdir "jts") # meh
        (copy build-path "jts"))
  (add-dep jts-path
           build-path))

# XXX: didn't work without this
(rule "gf.janet" [])

(add-dep "gf.janet" "jts/_tree-sitter.meta.janet")
(add-dep "gf.janet" "jts/_tree-sitter.a")
(add-dep "gf.janet" "jts/_tree-sitter.so")
(add-dep "gf.janet" "jts/tree-sitter.janet")
(add-dep "gf.janet" "jts/path.janet")

(declare-executable
  :name "gf"
  :entry "gf.janet")

(phony "clean-jts" []
      (rm "jts"))

(add-dep "clean" "clean-jts")
