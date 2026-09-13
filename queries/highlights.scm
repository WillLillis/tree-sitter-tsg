; Highlights for TSG, the tree-sitter native DSL (.tsg files).
;
; Ordered broad -> specific: later patterns override earlier ones for the same
; node (Neovim's tree-sitter highlighter applies captures in order).

; ----- base: a bare identifier is a rule reference --------------------------
(identifier) @variable
(for_reference) @variable

; ----- literals -------------------------------------------------------------
(string_literal) @string
(raw_string_literal) @string
(integer_literal) @number
(comment) @comment @spell

; ----- types ----------------------------------------------------------------
; Every type position is a primitive_type or generic_type, so these two cover
; parameter/return/let/for-binding annotations wherever they appear.
(primitive_type) @type.builtin
(generic_type name: _ @type.builtin)

; ----- definitions ----------------------------------------------------------
(rule_definition name: (identifier) @type.definition)
(expect_declaration name: (identifier) @type.definition)
(macro_definition name: (identifier) @function)
(rule_set_definition name: (identifier) @function)
(let_binding name: (identifier) @variable)

; ----- parameters / bindings ------------------------------------------------
(parameter name: (identifier) @variable.parameter)
(for_binding name: (identifier) @variable.parameter)

; ----- calls ----------------------------------------------------------------
; user-defined macro calls
(call_expression
  function: (identifier) @function.call
  (#not-any-of? @function.call
    "seq" "choice" "repeat" "repeat1" "optional" "blank" "eof"
    "field" "alias" "token" "token_immediate"
    "prec" "prec_left" "prec_right" "prec_dynamic"
    "reserved" "concat" "regexp" "append" "grammar_config"
    "inherit" "import"))

; builtin combinators
(call_expression
  function: (identifier) @function.builtin
  (#any-of? @function.builtin
    "seq" "choice" "repeat" "repeat1" "optional" "blank" "eof"
    "field" "alias" "token" "token_immediate"
    "prec" "prec_left" "prec_right" "prec_dynamic"
    "reserved" "concat" "regexp" "append" "grammar_config"))

; module imports
(call_expression
  function: (identifier) @keyword.import
  (#any-of? @keyword.import "inherit" "import"))
(call_expression
  function: (identifier) @_imp
  arguments: (argument_list [(string_literal) (raw_string_literal)] @string.special.path)
  (#any-of? @_imp "inherit" "import"))

; qualified calls:  module::macro(args)
(qualified_call_expression
  object: (identifier) @module)
(qualified_call_expression
  function: (identifier) @function.call)

; top-level qualified rule-set calls: @module::make_rules(args)
(rule_set_invocation
  module: (identifier) @module
  function: (identifier) @function.call)

; the first argument of field(...) names a field in the target grammar
(call_expression
  function: (identifier) @_f
  arguments: (argument_list . (identifier) @property)
  (#eq? @_f "field"))

; ----- member access --------------------------------------------------------
(field_access_expression field: (identifier) @property)
(qualified_access_expression object: (identifier) @module)
(qualified_access_expression member: (identifier) @property)

; ----- grammar config & object keys -----------------------------------------
(grammar_field key: (identifier) @property)
(object_field key: (identifier) @property)

; ----- cfg attributes -------------------------------------------------------
(cfg_attribute) @attribute
(cfg_attribute name: (identifier) @constant)

; ----- keywords -------------------------------------------------------------
[
  "grammar"
  "rule"
  "override"
  "let"
  "macro"
  "rules"
  "expect"
] @keyword

[
  "for"
  "in"
] @keyword.repeat

; ----- operators & punctuation ----------------------------------------------
[
  "="
  "+"
  "-"
] @operator

"@" @punctuation.special

[
  ":"
  "::"
  "."
  ","
] @punctuation.delimiter

[
  "("
  ")"
  "{"
  "}"
  "["
  "]"
  "<"
  ">"
] @punctuation.bracket
