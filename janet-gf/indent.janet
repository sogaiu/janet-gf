(import ../jts/tree-sitter)
(import ./node)

(defn indent-line?
  [line-no tree]
  (def node
    (node/node-at line-no 0 tree))
  (def node-type
    (:type node))
  (if (and (not= "str_lit" node-type)
           (not= "long_str_lit" node-type))
    true
    (let [[start-row _] (:start-point node)]
      (= line-no start-row))))

(comment

  (def lines
    @["(def a\n"
      "``\n"
      "hello there\n"
      "``"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (indent-line? 1 t)
  # => true

  (indent-line? 2 t)
  # => false

  (indent-line? 3 t)
  # => false

  )

(defn indent-special?
  [node lines]
  (def head-node (:named-child node 0))
  (unless (= (:type head-node) "sym_lit")
    (break false))
  (def [start-row start-col] (:start-point head-node))
  # XXX: not checking that end-row == start-row, but if sym_lit, must be?
  (def [_ end-col] (:end-point head-node))
  (def line (get lines start-row))
  (def head-text (string/slice line start-col end-col))
  # XXX: some things here may be redundant, but make things
  #      slightly faster?
  (def names
    ["case" "comment" "cond" "coro"
     "def" "def-" "default" "defer" "defglobal"
     "defmacro" "defmacro-" "defn" "defn-" "do"
     "each" "eachk" "eachp" "eachy" "edefer"
     "fn" "for" "forever" "forv"
     "generate"
     "if" "if-let" "if-not" "if-with"
     "label" "let" "loop"
     "match"
     "prompt"
     "repeat"
     "seq" "short-fn"
     "try"
     "unless"
     "var" "var-" "varfn" "varglobal"
     "when" "when-let" "when-with" "while"
     "with" "with-dyns" "with-syms" "with-vars"])
  (def names-set
    (zipcoll names
             (array/new-filled (length names) true)))
  # XXX: predicate should return true or false?
  (if (or (get names-set head-text)
          (peg/match ~(choice "def"
                              "if-"
                              "when-"
                              "with-")
                     head-text))
    true
    false))

(comment

  (def lines
    @["(def a 1)\n"
      "(when-let [x 1] x)\n"
      "(and true false)"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def rn
    (:root-node t))

  (indent-special? (:named-child rn 0) lines)
  # => true

  (indent-special? (:named-child rn 1) lines)
  # => true

  (indent-special? (:named-child rn 2) lines)
  # => false

  )

(defn calc-indent-for-special
  [node line-no]
  (let [cnt (node/count-prev-child-nodes node line-no)
        delim-col (node/open-delim-col node)]
    (if (= 0 cnt)
      (inc delim-col)
      (+ delim-col 2))))

(comment

  (def lines 
    @["(comment\n"
      "\n"
      "  (def a\n"
      "x)\n"       # indent this line
      ")"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 3)

  (calc-indent-for-special (node/context-node-at line-no 0 t)
                           line-no)
  # => 4

  )

(defn calc-indent-for-funcall
  [node line-no]
  (let [cnt (node/count-prev-child-nodes node line-no)
        delim-col (node/open-delim-col node)]
    (cond
      (= 0 cnt)
      (inc delim-col)
      #
      (= 1 cnt)
      (+ delim-col 2)
      #
      (let [[_ start-col]
            (:start-point (:named-child node 1))]
        start-col))))

(comment

  (def lines
    @["(comment\n"
      "\n"
      "  (+ a\n"
      "x)\n"       # indent this line
      ")"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 3)

  (calc-indent-for-funcall (node/context-node-at line-no 0 t)
                           line-no)
  # => 5

  )

(def non-ws-peg
  ~(sequence (to (not (set " \t")))
             (position)))

(comment

  (first
    (peg/match non-ws-peg "     hello"))
  # => 5

  (first
    (peg/match non-ws-peg "smile"))
  # => 0

  )

(defn calculate-indent
  [line-no lines tree]
  (unless (indent-line? line-no tree)
    (break false))
  (def line (get lines line-no))
  (def first-non-ws
    (first
      (peg/match non-ws-peg line)))
  (def ctx-node
    (node/context-node-at line-no 0 tree))
  (unless ctx-node
    (eprintf "failed to find context node at line: %d" line-no)
    (break nil))
  (def ctx-type
    (:type ctx-node))
  (cond
    (= "ERROR" ctx-type)
    (do
      (eprintf "parsing failed related to: %s" line)
      nil)
    #
    (= "source" ctx-type)
    0
    #
    ({"sqr_tup_lit" true
      "struct_lit" true} ctx-type)
    (inc (node/open-delim-col ctx-node))
    #
    ({"par_arr_lit" true
      "sqr_arr_lit" true
      "tbl_lit" true} ctx-type)
    (inc (inc (node/open-delim-col ctx-node))) # leading @ adds one column more
    #
    (= "par_tup_lit" ctx-type)
    (do
      (if (zero? (:named-child-count ctx-node))
        (inc (node/open-delim-col ctx-node))
        (if (indent-special? ctx-node lines)
          (calc-indent-for-special ctx-node line-no)
          (calc-indent-for-funcall ctx-node line-no))))
    #
    (do
      (eprintf "unexpected node type: %s" ctx-type)
      nil)))

(comment

  (def lines
    @["(comment\n"
      "\n"
      "  (+ a\n"
      "x)\n"       # indent this line
      ")"])

  (def t
    (:parse (tree-sitter/init "janet_simple")
            nil lines))

  (def line-no 3)

  (:type (node/context-node-at line-no 0 t))
  # => "par_tup_lit"
  
  (calculate-indent line-no lines t)
  # => 5

  )

(defn line-col-to-offset
  [lines line col]
  (var offset 0)
  (for i 0 line
    (+= offset
        (length (in lines i))))
  (+ offset col))

(comment

  (def lines
    @["hello\n"
      "these\n"
      "are\n"
      "some\n"
      "lines"])

  (line-col-to-offset lines 0 0)
  # => 0

  (line-col-to-offset lines 1 0)
  # => 6

  (line-col-to-offset lines 3 3)
  # => 19

  )

(defn indent-line!
  [line-no lines parser tree]
  (def old-line (get lines line-no))
  # to indent or not to indent, that is the question
  (def n-cols
    (calculate-indent line-no lines tree))
  (cond
    (false? n-cols)
    (break tree)
    #
    (nil? n-cols)
    (break nil))
  #
  (def first-non-ws
    (first
      (peg/match non-ws-peg old-line)))
  (when (= n-cols first-non-ws)
    (break tree))
  # prepare to edit the lines and the tree
  (def start-row line-no)
  (def start-col 0)
  (def start-byte (line-col-to-offset lines start-row start-col))
  #
  (def old-end-row line-no)
  # XXX: either region seems to work for our use-case
  (def old-end-col (length old-line))
  #(def old-end-col 0)
  (def old-end-byte (line-col-to-offset lines old-end-row old-end-col))
  # edit the lines
  (def new-line
    (string (string/repeat " " n-cols)
            (string/slice old-line first-non-ws)))
  (array/remove lines line-no)
  (array/insert lines line-no new-line)
  #
  (def new-end-row line-no)
  # XXX: either region seems to work for our use-case
  (def new-end-col (length new-line))
  #(def new-end-col n-cols)
  (def new-end-byte (line-col-to-offset lines new-end-row new-end-col))
  # now edit the tree
  (:edit tree
         start-byte old-end-byte new-end-byte
         start-row start-col
         old-end-row old-end-col
         new-end-row new-end-col)
  (def new-tree
    (:parse parser tree lines))
  (unless (not (:has-error (:root-node new-tree)))
    (eprintf "parsed tree has error when working on line: %d" line-no)
    nil)
  new-tree)

(comment

  (let [lines @["(def a\n"
                "1)"]
        p (tree-sitter/init "janet_simple")
        t (:parse p nil lines)]
    (indent-line! 1 lines p t)
    lines)
  # => @["(def a\n" "  1)"]

  )
