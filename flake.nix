{
  description = "Nix flake for Claude Code — AI coding assistant in your terminal (auto-updated daily)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          claude-code = pkgs.callPackage ./package.nix { };
          default = self.packages.${system}.claude-code;
        }
      );

      overlays.default = final: prev: {
        claude-code = self.packages.${final.stdenv.hostPlatform.system}.default;
      };

      homeManagerModules.default = { pkgs, ... }: {
        home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      };
    };
}
