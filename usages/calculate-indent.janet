(import ../jts/tree-sitter)
(import ../janet-gf/indent)
(import ../janet-gf/node)

# XXX: note sure how to get the ERROR code path
(comment

  (def lines
    @["(comment\n"
      "\n"
      "[:a\n"      # calculate indent for this line
      ")\n"      
      ")"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 2)

  (:type (node/context-node-at line-no 2 t))
  # => "ERROR"

  # XXX: this doesn't appear to be what we want to test
  (indent/calculate-indent line-no lines t)

  )

(comment

  (def lines
    @["(+ 1 1)\n"])  # indent this line

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 0)

  (:type (node/context-node-at line-no 0 t))
  # => "source"

  (indent/calculate-indent line-no lines t)
  # => 0

  )

(comment

  (def lines
    @["[:a\n"
      ":b]\n"])  # indent this line

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 1)

  (:type (node/context-node-at line-no 0 t))
  # => "sqr_tup_lit"

  (indent/calculate-indent line-no lines t)
  # => 1

  )

(comment

  (def lines
    @["{:a 1\n"
      ":b 2}\n"])  # indent this line

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 1)

  (:type (node/context-node-at line-no 0 t))
  # => "struct_lit"

  (indent/calculate-indent line-no lines t)
  # => 1

  )

(comment

  (def lines
    @["(comment\n"
      "\n"
      "  @[:a :b\n"
      ":c]\n"       # indent this line
      ")"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 3)

  (:type (node/context-node-at line-no 0 t))
  # => "sqr_arr_lit"

  (indent/calculate-indent line-no lines t)
  # => 4

  )

(comment

  (def lines
    @["@{:a 1\n"
      ":b 2}\n"])  # indent this line

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 1)

  (:type (node/context-node-at line-no 0 t))
  # => "tbl_lit"

  (indent/calculate-indent line-no lines t)
  # => 2

  )

(comment

  (def lines
    @["@{:a 1\n"
      "  :b (\n"
      ")}\n"])  # indent this line

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 2)

  (:type (node/context-node-at line-no 0 t))
  # => "par_tup_lit"

  # XXX: is this right?
  (indent/calculate-indent line-no lines t)
  # => 6

  )

(comment

  (def lines
    @["(comment\n"
      "\n"
      "  (def a\n"
      "1)\n"       # indent this line
      ")"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 3)

  (:type (node/context-node-at line-no 0 t))
  # => "par_tup_lit"
  
  (indent/calculate-indent line-no lines t)
  # => 4

  )
