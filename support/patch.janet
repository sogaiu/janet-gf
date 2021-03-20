(def start-marker
  "//////// start cfun_ts_init ////////\n")

(def end-marker
  "//////// end cfun_ts_init ////////\n")

(def grammar
  ~{:main (sequence :before :target :after)
    :before (sequence (capture (to ,start-marker))
                      ,start-marker)
    :target (sequence (capture (to ,end-marker))
                      ,end-marker)
    :after (capture (thru -1))})

(comment

  (def input
    ``
    const JanetAbstractType jts_parser_type = {
        "tree-sitter/parser",
        jts_parser_gc,
        NULL,
        jts_parser_get,
        JANET_ATEND_GET
    };

    //////// start cfun_ts_init ////////

    static Janet cfun_ts_init(int32_t argc, Janet *argv) {
        janet_fixarity(argc, 2);

        const char *path = (const char *)janet_getstring(argv, 0);

        Clib lib = load_clib(path);
        if (!lib) {
            fprintf(stderr, error_clib());
            return janet_wrap_nil();
        }

        const char *fn_name = (const char *)janet_getstring(argv, 1);

        JTSLang jtsl;
        jtsl = (JTSLang) symbol_clib(lib, fn_name);
        if (!jtsl) {
            fprintf(stderr, "could not find the target grammar's initializer");
            return janet_wrap_nil();
        }

        TSParser *p = ts_parser_new();
        if (p == NULL) {
            fprintf(stderr, "ts_parser_new failed");
            return janet_wrap_nil();
        }

        Parser *parser =
            (Parser *)janet_abstract(&jts_parser_type, sizeof(Parser));
        parser->parser = p;

        bool success = ts_parser_set_language(p, jtsl());
        if (!success) {
            fprintf(stderr, "ts_parser_set_language failed");
            // XXX: abstract will take care of this?
            //free(p);
            return janet_wrap_nil();
        }

        return janet_wrap_abstract(parser);
    }

    //////// end cfun_ts_init ////////

    /**
     * Get the node's type as a null-terminated string.
     */
    static Janet cfun_node_type(int32_t argc, Janet *argv) {
        janet_fixarity(argc, 1);
        Node *node = (Node *)janet_getabstract(argv, 0, &jts_node_type);
        // XXX: error checking?
        const char *the_type = ts_node_type(node->node);
        return janet_cstringv(the_type);
    }
    ``)

  (length (peg/match grammar input))
  # => 3

  (def patch
    ``
    //////// start cfun_ts_init ////////

    TSLanguage *tree_sitter_janet_simple();

    static Janet cfun_ts_init(int32_t argc, Janet *argv) {
        // arguments are ignored
        janet_fixarity(argc, 2);

        TSParser *p = ts_parser_new();
        if (p == NULL) {
          return janet_wrap_nil();
        }

        Parser* parser =
          (Parser *)janet_abstract(&jts_parser_type, sizeof(Parser));
        parser->parser = p;

        // XXX: should check return value of tree_sitter_janet_simple?
        bool success = ts_parser_set_language(p, tree_sitter_janet_simple());
        if (!success) {
          // XXX: abstract will take care of this?
          //free(p);
          return janet_wrap_nil();
        }

        return janet_wrap_abstract(parser);
    }

    //////// end cfun_ts_init ////////
    ``)

  (def output
    ``
    const JanetAbstractType jts_parser_type = {
        "tree-sitter/parser",
        jts_parser_gc,
        NULL,
        jts_parser_get,
        JANET_ATEND_GET
    };

    //////// start cfun_ts_init ////////

    TSLanguage *tree_sitter_janet_simple();

    static Janet cfun_ts_init(int32_t argc, Janet *argv) {
        // arguments are ignored
        janet_fixarity(argc, 2);

        TSParser *p = ts_parser_new();
        if (p == NULL) {
          return janet_wrap_nil();
        }

        Parser* parser =
          (Parser *)janet_abstract(&jts_parser_type, sizeof(Parser));
        parser->parser = p;

        // XXX: should check return value of tree_sitter_janet_simple?
        bool success = ts_parser_set_language(p, tree_sitter_janet_simple());
        if (!success) {
          // XXX: abstract will take care of this?
          //free(p);
          return janet_wrap_nil();
        }

        return janet_wrap_abstract(parser);
    }

    //////// end cfun_ts_init ////////

    /**
     * Get the node's type as a null-terminated string.
     */
    static Janet cfun_node_type(int32_t argc, Janet *argv) {
        janet_fixarity(argc, 1);
        Node *node = (Node *)janet_getabstract(argv, 0, &jts_node_type);
        // XXX: error checking?
        const char *the_type = ts_node_type(node->node);
        return janet_cstringv(the_type);
    }
    ``)

  (def [before _ after]
    (peg/match grammar input))

  (length output)
  # => 1218

  (def patched
    (string before patch after))
  # => 1218

  (= output patched)
  # => true

  )

# XXX: could generalize markers, but leave until later
# this works when the script is run from the project directory
(defn patch
  [src-file-path patch-file-path]
  # ensure src-file-path is as expected
  (def src-stat (os/stat src-file-path))
  (unless (and src-stat
               (= :file (src-stat :mode)))
    (eprintf "expected an existing file for: %s" src-file-path)
    (break false))
  # ensure patch-file-path is as expected
  (def patch-stat (os/stat patch-file-path))
  (unless (and patch-stat
               (= :file (patch-stat :mode)))
    (eprintf "expected an existing file for: %s" patch-file-path)
    (break false))
  # read in source lines
  (def src (slurp src-file-path))
  # read in patch lines
  (def patch (slurp patch-file-path))
  (def [before _ after]
    (peg/match grammar src))
  # assemble final file
  (with [out-f (file/open src-file-path :w)]
    (file/write out-f before)
    (file/write out-f patch)
    (file/write out-f after))
  true)
