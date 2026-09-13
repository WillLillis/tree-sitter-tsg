; Inject the Rust-regex grammar into regexp(...) patterns, so character classes,
; quantifiers, groups, escapes, and anchors are highlighted instead of one flat
; string. Requires a `regex` parser (nvim-treesitter ships one: :TSInstall regex).
;
; Only the first argument (the pattern) is injected - the optional second
; argument is the flags string, not a regex.

; regexp(r"...") / regexp(r#"..."#): the scanner exposes the inner text as a
; raw_string_content node, so inject it directly (works for any `#` count).
(call_expression
  function: (identifier) @_fn
  arguments: (argument_list
    . (raw_string_literal (raw_string_content) @injection.content))
  (#eq? @_fn "regexp")
  (#set! injection.language "regex"))

; regexp("..."): a plain string is one token, so trim the surrounding quotes
; with an offset. (Raw strings are preferred for patterns precisely because a
; plain string's own \-escapes would double up; plain patterns are rare and
; usually escape-free.)
(call_expression
  function: (identifier) @_fn
  arguments: (argument_list . (string_literal) @injection.content)
  (#eq? @_fn "regexp")
  (#set! injection.language "regex")
  (#offset! @injection.content 0 1 0 -1))

; comments support spell-checking / prose highlighting.
((comment) @injection.content
  (#set! injection.language "comment"))
