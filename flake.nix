{
  description = "Nix packages for the Nyx applications, built for NyxOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Application sources. `nix flake update <name>` moves one to its latest commit;
    # flake.lock records the exact revision each release of nyx-packages builds.
    nyx-core = {
      url = "github:design-nexus/nyx-core";
      flake = false;
    };
    nyx-design = {
      url = "github:design-nexus/nyx-design";
      flake = false;
    };
    nyx-accounts = {
      url = "github:design-nexus/nyx-accounts";
      flake = false;
    };
    nyx-fonts = {
      url = "github:design-nexus/nyx-fonts";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
      };
      nyx = pkgs.callPackage ./lib { inherit inputs; };
      packages = import ./pkgs { inherit pkgs nyx inputs; };
    in
    {
      lib = nyx;

      packages.${system} = packages // {
        default = pkgs.symlinkJoin {
          name = "nyx-packages";
          paths = builtins.attrValues packages;
        };
      };

      checks.${system} =
        packages
        // import ./checks {
          inherit pkgs nyx inputs;
        };

      overlays.default = final: _prev: {
        nyx = self.packages.${final.stdenv.hostPlatform.system};
      };

      nixosModules.default = import ./modules/nixos self;

      formatter.${system} = pkgs.nixfmt;
    };
}
