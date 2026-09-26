{
  description = "trino.nvim";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      perSystem =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          trino-nvim = pkgs.vimUtils.buildVimPlugin {
            name = "trino.nvim";
            src = ./.;
            runtimeDeps = [
              (pkgs.python3.withPackages (ps: [
                (ps.trino-python-client.overridePythonAttrs (oldAttrs: {
                  pname = "trino";
                }))
              ]))
            ];
          };

          wrappedNvim = pkgs.callPackage ./nix/nvim.nix {
            inherit trino-nvim;
          };

          dockerTrino = pkgs.callPackage ./nix/docker.nix { };

        in
        {
          packages = {
            default = trino-nvim;
            nvim = wrappedNvim;
          };
          apps = {
            nvim = {
              type = "app";
              program = "${wrappedNvim}/bin/nvim";
            };
            dockerTrino = {
              type = "app";
              program = "${dockerTrino}/bin/${dockerTrino.name}";
            };
          };
        };

    in
    {
      packages = forAllSystems (system: (perSystem system).packages);
      apps = forAllSystems (system: (perSystem system).apps);
    };
}
