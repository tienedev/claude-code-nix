# claude-code-nix

Nix flake for [Claude Code](https://www.anthropic.com/claude-code) — AI coding assistant in your terminal.

Packages the official native binary. Auto-updated daily via GitHub Actions.

## Usage

### Flake input

```nix
{
  inputs.claude-code.url = "github:tienedev/claude-code-nix";

  outputs = { self, nixpkgs, claude-code, ... }: {
    # Option 1: overlay
    nixpkgs.overlays = [ claude-code.overlays.default ];
    # then use pkgs.claude-code

    # Option 2: direct package
    environment.systemPackages = [
      claude-code.packages.${system}.default
    ];

    # Option 3: home-manager module
    imports = [ claude-code.homeManagerModules.default ];
  };
}
```

### Run directly

```bash
nix run github:tienedev/claude-code-nix
```

## Supported platforms

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`
