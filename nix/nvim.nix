{
  trino-nvim,
  neovim-unwrapped,
  wrapNeovimUnstable,
}:

let
  luaRcContent = ''
    vim.g.mapleader = " "
    vim.o.wrap = false
    vim.o.number = true
    vim.o.cursorline = true
  '';

  plugins = [
    {
      plugin = trino-nvim;
      type = "lua";
      config = ''
        require("trino").setup()
        vim.keymap.set("n", "<leader>ee", require("trino").run_input, { desc = "Trino run input" })
        vim.keymap.set("x", "<leader>ef", require("trino").run_visual, { desc = "Trino run visual" })
      '';
    }
  ];

in
wrapNeovimUnstable neovim-unwrapped {
  inherit luaRcContent plugins;
}
