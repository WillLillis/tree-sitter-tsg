; Tags for the tree-sitter native DSL (.tsg files).

(rule_definition
  name: (identifier) @name) @definition.type

(expect_declaration
  name: (identifier) @name) @definition.type

(macro_definition
  name: (identifier) @name) @definition.function

(rule_set_definition
  name: (identifier) @name) @definition.function

(let_binding
  name: (identifier) @name) @definition.var

; module::member  ->  a reference to another grammar's symbol
(qualified_access_expression
  member: (identifier) @name) @reference.call

(qualified_call_expression
  function: (identifier) @name) @reference.call

(rule_set_invocation
  function: (identifier) @name) @reference.call
