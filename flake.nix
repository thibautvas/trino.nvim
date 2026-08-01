{
  description = "trino.nvim";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          trino-nvim = pkgs.vimUtils.buildVimPlugin {
            name = "trino.nvim";
            src = ./.;
          };

          luaRcContent = ''
            vim.g.mapleader = " "
            vim.o.wrap = false
            vim.o.number = true
            vim.o.cursorline = true
            vim.keymap.set("n", "-", function()
              local dir = vim.api.nvim_buf_get_name(0) ~= "" and "%:h" or "."
              vim.cmd("e " .. dir)
            end)
          '';

          fromLua = config: ''
            lua << EOF
            ${config}
            EOF
          '';

          plugins = [
            {
              plugin = trino-nvim;
              config = fromLua ''
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

                vim.keymap.set("v", "<leader>ef", require("trino").run_visual)
              '';
            }
          ];

          wrapperArgs =
            let
              extraPkgs = [
                (pkgs.python3.withPackages (ps: [
                  (ps.trino-python-client.overridePythonAttrs (oldAttrs: {
                    pname = "trino";
                  }))
                ]))
              ];
            in
            [
              "--prefix"
              "PATH"
              ":"
              (pkgs.lib.makeBinPath extraPkgs)
            ];

        in
        {
          default = trino-nvim;
          nvim = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
            inherit luaRcContent plugins wrapperArgs;
          };
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          dockerTrino = pkgs.writeShellApplication {
            name = "run-trino";
            runtimeInputs = [ pkgs.docker ];
            text = "docker run -d --name trino -p 8080:8080 trinodb/trino";
          };

        in
        {
          default = {
            type = "app";
            program = "${self.packages.${system}.nvim}/bin/nvim";
          };
          dockerTrino = {
            type = "app";
            program = "${dockerTrino}/bin/${dockerTrino.name}";
          };
        }
      );
    };
}
