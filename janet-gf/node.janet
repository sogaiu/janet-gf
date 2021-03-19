(import ../jts/tree-sitter)

(defn node-at
  [line col tree]
  (def root-node (:root-node tree))
  (unless root-node
    (break nil))
  (def ret
    (:descendant-for-point-range root-node
                                 line col line col))
  ret)

(comment

  (def src
    "(defn my-fn [x] (+ x 1))")

  (def t
    (:parse-string (tree-sitter/init "janet_simple")
                   src))

  (:text (node-at 0 0 t) src)
  # => "("

  (:text (node-at 0 1 t) src)
  # => "defn"

  )

(defn context-node-at
  [line col tree]
  (when-let [node (node-at line col tree)
             node-type (:type node)]
    (cond
      ({"par_tup_lit" true "par_arr_lit" true
        "sqr_tup_lit" true "sqr_arr_lit" true
        "struct_lit" true "tbl_lit" true
        "source" true} node-type)
      node
      #
      ({"(" true "@(" true
        "[" true "@[" true
        "{" true "@{" true} node-type)
      (:parent (:parent node))
      #
      (let [parent-node (:parent node)
            parent-type (:type parent-node)]
        ({"quasi_quote_form" true "quote_form" true
          "short_fn_form" true "splice_form" true
          "unquote_form" true} parent-type))
      (:parent (:parent node))
      #
      node-type
      (:parent node))))

(comment

  (def src
    "(defn my-fn [x] (+ x 1))")

  (def t
    (:parse-string (tree-sitter/init "janet_simple")
                   src))

  (:text (context-node-at 0 0 t) src)
  # => src

  (:text (context-node-at 0 13 t) src)
  # => "[x]"
  
  (:text (context-node-at 0 17 t) src)
  # => "(+ x 1)"

  )

(defn count-prev-child-nodes
  [node line-no]
  (var idx 0)
  (var cur-node (:named-child node idx))
  (var done false)
  (while (and cur-node
              (not done))
    (def [cur-node-row _] (:start-point cur-node))
    (when (>= cur-node-row line-no)
      (set done true)
      (break))
    (++ idx)
    (set cur-node (:next-sibling cur-node)))
  (if done
    idx # equivalent to counting in this case
    nil))

(comment

  (def lines
    @["[:a\n"
      " :b\n"
      " :c\n"
      " :x\n"
      " :y]"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def sqtn
    (:child (:root-node t) 0))

  # XXX: does this seem right?
  (count-prev-child-nodes sqtn 0)
  # => 0

  (count-prev-child-nodes sqtn 2)
  # => 2

  (count-prev-child-nodes sqtn 3)
  # => 3

  )

(defn open-delim-col
  [node]
  (let [[_ col] (:start-point node)]
    col))

(comment

  (def lines
    @["[:a [:b]]"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def rn
    (:root-node t))

  (open-delim-col rn)
  # => 0

  (open-delim-col (:child (:child rn 0) 2))
  # => 4

  )
