{
  description = "Nix packages for the Nyx applications, built for NyxOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Face sign-in for Nyx Biometrics, with their own packages and NixOS modules, at
    # their release tags.
    irlume = {
      url = "github:archledger/irlume/v0.15.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    gaze = {
      url = "github:GunduLabs/gaze/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Application sources. `nix flake update <name>` moves one to its latest commit;
    # flake.lock records the exact revision each release of nyx-packages builds.
    # The suite repository: the nyx CLI and its icon tools.
    nyx = {
      url = "github:design-nexus/nyx";
      flake = false;
    };
    nyx-core = {
      url = "github:design-nexus/nyx-core";
      flake = false;
    };
    nyx-design = {
      url = "github:design-nexus/nyx-design";
      flake = false;
    };
    # nyx-design with the brand marks, for the boot splash (apps stay on nyx-design).
    nyx-brand = {
      url = "github:design-nexus/nyx-design";
      flake = false;
    };
    nyx-plymouth = {
      url = "github:nyxos-project/nyx-plymouth";
      flake = false;
    };
    nyx-greeter = {
      url = "github:nyxos-project/nyx-greeter";
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
    nyx-notepad = {
      url = "github:design-nexus/nyx-notepad";
      flake = false;
    };
    nyx-calculator = {
      url = "github:design-nexus/nyx-calculator";
      flake = false;
    };
    nyx-archive = {
      url = "github:design-nexus/nyx-archive";
      flake = false;
    };
    nyx-pdf = {
      url = "github:design-nexus/nyx-pdf";
      flake = false;
    };
    nyx-news = {
      url = "github:design-nexus/nyx-news";
      flake = false;
    };
    nyx-office = {
      url = "github:design-nexus/nyx-office";
      flake = false;
    };
    nyx-git = {
      url = "github:design-nexus/nyx-git";
      flake = false;
    };
    nyx-music = {
      url = "github:design-nexus/nyx-music";
      flake = false;
    };
    nyx-media-player = {
      url = "github:design-nexus/nyx-media-player";
      flake = false;
    };
    nyx-theater = {
      url = "github:design-nexus/nyx-theater";
      flake = false;
    };
    nyx-photos = {
      url = "github:design-nexus/nyx-photos";
      flake = false;
    };
    nyx-share = {
      url = "github:design-nexus/nyx-share";
      flake = false;
    };
    nyx-transfer = {
      url = "github:design-nexus/nyx-transfer";
      flake = false;
    };
    nyx-cloud = {
      url = "github:design-nexus/nyx-cloud";
      flake = false;
    };
    nyx-clipboard = {
      url = "github:design-nexus/nyx-clipboard";
      flake = false;
    };
    nyx-home = {
      url = "github:design-nexus/nyx-home";
      flake = false;
    };
    nyx-chat = {
      url = "github:design-nexus/nyx-chat";
      flake = false;
    };
    nyx-activity = {
      url = "github:design-nexus/nyx-activity";
      flake = false;
    };
    nyx-containers = {
      url = "github:design-nexus/nyx-containers";
      flake = false;
    };
    nyx-torrents = {
      url = "github:design-nexus/nyx-torrents";
      flake = false;
    };
    nyx-weather = {
      url = "github:design-nexus/nyx-weather";
      flake = false;
    };
    nyx-notes = {
      url = "github:design-nexus/nyx-notes";
      flake = false;
    };
    nyx-files = {
      url = "github:design-nexus/nyx-files";
      flake = false;
    };
    nyx-contacts = {
      url = "github:design-nexus/nyx-contacts";
      flake = false;
    };
    nyx-calendar = {
      url = "github:design-nexus/nyx-calendar";
      flake = false;
    };
    nyx-reminders = {
      url = "github:design-nexus/nyx-reminders";
      flake = false;
    };
    nyx-backup = {
      url = "github:design-nexus/nyx-backup";
      flake = false;
    };
    nyx-maps = {
      url = "github:design-nexus/nyx-maps";
      flake = false;
    };
    nyx-mail = {
      url = "github:design-nexus/nyx-mail";
      flake = false;
    };
    nyx-capture = {
      url = "github:design-nexus/nyx-capture";
      flake = false;
    };
    nyx-passwords = {
      url = "github:design-nexus/nyx-passwords";
      flake = false;
    };
    nyx-pulse = {
      url = "github:design-nexus/nyx-pulse";
      flake = false;
    };
    nyx-assistant = {
      url = "github:design-nexus/nyx-assistant";
      flake = false;
    };
    nyx-glimpse = {
      url = "github:design-nexus/nyx-glimpse";
      flake = false;
    };
    nyx-notification-center = {
      url = "github:design-nexus/nyx-notification-center";
      flake = false;
    };
    nyx-dock = {
      url = "github:design-nexus/nyx-dock";
      flake = false;
    };
    nyx-control-center = {
      url = "github:design-nexus/nyx-control-center";
      flake = false;
    };
    nyx-bar = {
      url = "github:design-nexus/nyx-bar";
      flake = false;
    };
    nyx-biometrics = {
      url = "github:design-nexus/nyx-biometrics";
      flake = false;
    };
    nyx-settings = {
      url = "github:design-nexus/nyx-settings";
      flake = false;
    };
    nyx-store = {
      url = "github:design-nexus/nyx-store";
      flake = false;
    };
    nyx-wallpapers = {
      url = "github:nyxos-project/nyx-wallpapers";
      flake = false;
    };
    nyx-system = {
      url = "github:nyxos-project/nyx-system";
      flake = false;
    };
    nyx-switcher = {
      url = "github:design-nexus/nyx-switcher";
      flake = false;
    };
    nyx-welcome = {
      url = "github:nyxos-project/nyx-welcome";
      flake = false;
    };
    nyx-installer = {
      url = "github:nyxos-project/nyx-installer";
      flake = false;
    };
    umbra-icons = {
      url = "github:design-nexus/umbra-icons";
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
      # The NyxOS software catalog, for checks against a NixOS configuration.
      lib = nyx // {
        catalog = builtins.fromTOML (builtins.readFile "${inputs.nyx-system}/crates/nyx-catalog/catalog.toml");
      };

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
