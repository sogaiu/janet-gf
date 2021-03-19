(import ./jts/tree-sitter)
(import ./janet-gf/indent)

(defn main
  [& args]
  (def n-args (length args))
  (unless (> n-args 1)
    (eprintf "expected more arguments, got: %d" n-args)
    (os/exit 1))
  # treat last thing as file path
  (def file-path (get args (dec n-args)))
  (def stat (os/stat file-path))
  (unless (and stat
               (= :file (stat :mode)))
    (eprintf "expected a file for: %s" file-path)
    (os/exit 1))
  # where the source lines live
  (def lines @[])
  # read in the source
  # XXX: what effect that :b have?
  (with [in-f (file/open file-path :rb)]
    (var line (file/read in-f :line))
    (while line
      (array/push lines line)
      (set line (file/read in-f :line))))
  # prepare the parser
  (def p (tree-sitter/init "janet_simple"))
  (unless p
    (eprint "failed to initialize parser")
    (os/exit 1))
  # parse the source
  (def t (:parse p nil lines))
  (unless t
    (eprintf "failed to parse source in: %s" file-path)
    (os/exit 1))
  (def rn (:root-node t))
  (unless (not (:has-error rn))
    (eprint "dumping lines...")
    (each line lines
      (eprin (length line) ": " )
      (eprin line))
    (eprintf "parsed with an error in: %s" file-path)
    (eprintf "expr: %p" (:expr rn))
    (os/exit 1))
  (var line-no 0)
  (var curr-tree t)
  # indent one line at a time
  (while (< line-no (length lines))
    (set curr-tree
         (indent/indent-line! line-no lines p curr-tree))
    (unless curr-tree
      (eprintf "no tree to work with, line number: %d" line-no)
      (eprint)
      (eprintf "dumping in-progress lines...")
      (eprint)
      (each line lines
        (eprin line))
      (os/exit 1))
    (++ line-no))
  # print out results
  (each line lines
    (prin line)))
