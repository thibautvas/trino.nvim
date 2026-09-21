{
  lib,
  trino-nvim,
  python3,
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
        require("trino").setup({
          host = "localhost",
          port = 8080,
          catalog = "tpch",
          http_headers = { ["X-Trino-Original-User"] = "placeholder" },
          http_scheme = "http",
          auth = {
            type = "none",
            username = nil,
            password = nil,
          },
          verify = false,
        })

        vim.keymap.set("x", "<leader>ef", require("trino").run_visual)
      '';
    }
  ];

  extraPkgs = [
    (python3.withPackages (ps: [
      (ps.trino-python-client.overridePythonAttrs (oldAttrs: {
        pname = "trino";
      }))
    ]))
  ];

  wrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath extraPkgs)
  ];

in
wrapNeovimUnstable neovim-unwrapped {
  inherit luaRcContent plugins wrapperArgs;
}
