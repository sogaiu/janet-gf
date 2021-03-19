(import ../jts/tree-sitter)
(import ../janet-gf/indent)
(import ../janet-gf/node)

(comment

  (def lines 
    @["(comment\n"
      "\n"
      "  (do\n"
      "    (def a 1)\n"
      "a)\n"            # calculate indentation for this line
      ")"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 4)

  (indent/calc-indent-for-special (node/context-node-at line-no 0 t)
                                  line-no)
  # => 4

  )

(comment

  (def lines
    @["(comment\n"
      "\n"
      "  (print :a\n"
      ":b)\n"         # calculate indentation for this line
      ")"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 3)

  (def ctx-node (node/context-node-at line-no 0 t))

  (:type ctx-node)
  # => "par_tup_lit"

  (indent/calc-indent-for-funcall ctx-node line-no)
  # => 9

  )

(comment

  (def p
    (tree-sitter/init "janet_simple"))

  (let [lines @["(def a\n"
                " 1)"]
        t (:parse p nil lines)]
    (indent/indent-line! 1 lines p t)
    lines)
  # => @["(def a\n" "  1)"]

  (let [lines @["(def a\n"
                "  1)"]
        t (:parse p nil lines)]
    (indent/indent-line! 1 lines p t)
    lines)
  # => @["(def a\n" "  1)"]

  (let [lines @["(+ a\n"
                "1)"]
        t (:parse p nil lines)]
    (indent/indent-line! 1 lines p t)
    lines)
  # => @["(+ a\n" "   1)"]

  (let [lines @["(when-let [x 1]\n"
                "x)"]
        t (:parse p nil lines)]
    (indent/indent-line! 1 lines p t)
    lines)
  # => @["(when-let [x 1]\n" "  x)"]

  )
