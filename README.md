# tree-sitter-tsg

A [tree-sitter] grammar for TSG, tree-sitter's native grammar DSL.

TSG support is currently developed on the [`deliver_native_dsl`](https://github.com/WillLillis/tree-sitter/tree/deliver_native_dsl)
branch.

## Neovim

Use `tsg` consistently as the filetype and parser name. After generating the
parser, install it and link this repository's queries:

```sh
tree-sitter build -o ~/.local/share/nvim/site/parser/tsg.so
ln -sfn "$PWD/queries" ~/.local/share/nvim/site/queries/tsg
```

Register the extension with `vim.filetype.add({ extension = { tsg = "tsg" } })`.
For a local nvim-treesitter parser entry, use `tsg` as the table key and this
repository as `install_info.path`.

[tree-sitter]: https://tree-sitter.github.io/
