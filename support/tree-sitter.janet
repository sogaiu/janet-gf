(import ./_tree-sitter)

(defn init
  ``
  Return tree-sitter parser for grammar.
  `lang-name` identifies a specific grammar, e.g.
  `clojure` or `janet_simple`.

  ``
  [lang-name]
  (_tree-sitter/_init nil nil))

(comment

  (def src "(def a 1)")

  (when-let [p (try
                 (init "janet-simple")
                 ([err]
                   (eprint err)
                   nil))
             t (:parse-string p src)
             rn (:root-node t)]
    (:text rn src))
  # => src

  )
