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
