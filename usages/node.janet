(import ../jts/tree-sitter)
(import ../janet-gf/node)

(comment

  (def src
    "(defn my-fn [x] (+ x 1))")

  (def t
    (:parse-string (tree-sitter/init "janet_simple")
                   src))

  (:text (node/node-at 0 0 t) src)
  # => "("

  (:text (node/node-at 0 1 t) src)
  # => "defn"

  (:text (node/node-at 0 5 t) src)
  # => src

  (:text (node/node-at 0 6 t) src)
  # => "my-fn"

  (:text (node/node-at 0 12 t) src)
  # => "["

  (:text (node/node-at 0 13 t) src)
  # => "x"

  (:text (node/node-at 0 14 t) src)
  # => "]"

  (:text (node/node-at 0 16 t) src)
  # => "("

  (:text (node/node-at 0 17 t) src)
  # => "+"

  (:text (node/node-at 0 18 t) src)
  # => "(+ x 1)"

  (:text (node/node-at 0 (dec (length src)) t) src)
  # => ")"

  (:text (node/node-at 0 (length src) t) src)
  # => src

  )
