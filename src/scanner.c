#include "tree_sitter/alloc.h"
#include "tree_sitter/parser.h"

#include <stdint.h>

// External tokens for raw string literals (`r"..."`, `r#"..."#`, ...). The raw
// string is split into three tokens so the inner text is its own node: a
// `raw_string_content` that highlight/injection queries can target directly
// (the closing delimiter width varies with the hash count, so a query-side
// offset can't isolate the content). Mirrors tree-sitter-rust's scanner.
//
// Order MUST match the `externals:` list in grammar.tsg.
enum TokenType {
    RAW_STRING_START,
    RAW_STRING_CONTENT,
    RAW_STRING_END,
    ERROR_SENTINEL,
};

// The only state is the number of `#`s in the currently-open raw string, so the
// matching close (`"` + that many `#`s) can be found. One byte, serialized.
typedef struct {
    uint8_t opening_hash_count;
} Scanner;

static inline void advance(TSLexer *lexer) { lexer->advance(lexer, false); }
static inline void skip(TSLexer *lexer) { lexer->advance(lexer, true); }

// Opening delimiter: `r`, `r#`, `r##`, ... followed by `"`. Records the hash
// count. Returns false (rolling back the advances) for anything that is not a
// raw-string opener - the `r#name` raw identifier, or a bare `r`-leading
// identifier/keyword - so the main lexer handles it instead.
static bool scan_raw_string_start(Scanner *scanner, TSLexer *lexer) {
    advance(lexer); // 'r'
    uint8_t hash_count = 0;
    while (lexer->lookahead == '#') {
        advance(lexer);
        hash_count++;
    }
    if (lexer->lookahead != '"') {
        return false;
    }
    advance(lexer); // opening '"'
    scanner->opening_hash_count = hash_count;
    lexer->result_symbol = RAW_STRING_START;
    return true;
}

// Inner text up to (but not including) the closing `"` + `#`*. `mark_end` is set
// just before the closing quote so the END token starts there. A `"` followed
// by too few `#`s is ordinary content. May be zero-width (e.g. `r""`).
static bool scan_raw_string_content(Scanner *scanner, TSLexer *lexer) {
    for (;;) {
        if (lexer->eof(lexer)) {
            return false;
        }
        if (lexer->lookahead == '"') {
            lexer->mark_end(lexer);
            advance(lexer);
            unsigned hash_count = 0;
            while (hash_count < scanner->opening_hash_count && lexer->lookahead == '#') {
                advance(lexer);
                hash_count++;
            }
            if (hash_count == scanner->opening_hash_count) {
                lexer->result_symbol = RAW_STRING_CONTENT;
                return true;
            }
        } else {
            advance(lexer);
        }
    }
}

// Closing delimiter: `"` followed by the recorded number of `#`s.
static bool scan_raw_string_end(Scanner *scanner, TSLexer *lexer) {
    advance(lexer); // closing '"'
    for (unsigned i = 0; i < scanner->opening_hash_count; i++) {
        advance(lexer);
    }
    lexer->result_symbol = RAW_STRING_END;
    return true;
}

void *tree_sitter_tsg_external_scanner_create(void) {
    return ts_calloc(1, sizeof(Scanner));
}

void tree_sitter_tsg_external_scanner_destroy(void *payload) { ts_free(payload); }

unsigned tree_sitter_tsg_external_scanner_serialize(void *payload, char *buffer) {
    Scanner *scanner = (Scanner *)payload;
    buffer[0] = (char)scanner->opening_hash_count;
    return 1;
}

void tree_sitter_tsg_external_scanner_deserialize(void *payload, const char *buffer, unsigned length) {
    Scanner *scanner = (Scanner *)payload;
    scanner->opening_hash_count = 0;
    if (length == 1) {
        scanner->opening_hash_count = (uint8_t)buffer[0];
    }
}

bool tree_sitter_tsg_external_scanner_scan(void *payload, TSLexer *lexer, const bool *valid_symbols) {
    if (valid_symbols[ERROR_SENTINEL]) {
        return false;
    }

    Scanner *scanner = (Scanner *)payload;

    // Inside a raw string (between the delimiters): content, then end. No
    // whitespace skipping here - whitespace is part of the content.
    if (valid_symbols[RAW_STRING_CONTENT]) {
        return scan_raw_string_content(scanner, lexer);
    }
    if (valid_symbols[RAW_STRING_END] && lexer->lookahead == '"') {
        return scan_raw_string_end(scanner, lexer);
    }

    // A raw string may start at this (fresh) position. Skip leading whitespace,
    // then require an `r`.
    if (valid_symbols[RAW_STRING_START]) {
        while (lexer->lookahead == ' ' || lexer->lookahead == '\t' ||
               lexer->lookahead == '\n' || lexer->lookahead == '\r') {
            skip(lexer);
        }
        if (lexer->lookahead == 'r') {
            return scan_raw_string_start(scanner, lexer);
        }
    }

    return false;
}
