{
  pkgs,
  nyx,
  inputs,
}:
let
  # Packages named after their source input: pkgs/<name>.nix built from inputs.<name>.
  fromSource =
    names:
    pkgs.lib.genAttrs names (
      name:
      pkgs.callPackage ./${name}.nix {
        inherit nyx;
        src = inputs.${name};
      }
    );
in
fromSource [
  "nyx-accounts"
  "nyx-fonts"
  "nyx-notepad"
  "nyx-calculator"
  "nyx-archive"
  "nyx-pdf"
  "nyx-news"
  "nyx-office"
  "nyx-git"
  "nyx-music"
  "nyx-media-player"
  "nyx-theater"
  "nyx-photos"
  "nyx-share"
  "nyx-transfer"
  "nyx-cloud"
  "nyx-clipboard"
  "nyx-home"
  "nyx-chat"
  "nyx-activity"
  "nyx-containers"
  "nyx-torrents"
  "nyx-weather"
  "nyx-notes"
  "nyx-files"
  "nyx-contacts"
  "nyx-calendar"
  "nyx-reminders"
  "nyx-backup"
  "nyx-maps"
  "nyx-mail"
  "nyx-capture"
  "nyx-passwords"
  "nyx-pulse"
  "nyx-assistant"
  "nyx-glimpse"
  "nyx-notification-center"
  "nyx-dock"
  "nyx-control-center"
  "nyx-bar"
  "nyx-biometrics"
  "nyx-settings"
  "nyx-store"
  "nyx-system"
  "nyx-switcher"
  "nyx-welcome"
]
// {
  nyx-wallpapers = pkgs.callPackage ./nyx-wallpapers.nix { src = inputs.nyx-wallpapers; };

  hyprland = pkgs.callPackage ./hyprland.nix { };

  nyx-icons = pkgs.callPackage ./nyx-icons.nix {
    inherit nyx;
    src = inputs.nyx-design;
  };

  inherit (nyx)
    libical_4
    libshumate_1_7
    tdlib_1_8_67
    ntgcalls
    sherpa-onnx_1_13_8
    pacman_7_1
    ;

  # Face sign-in for Nyx Biometrics, from their own flakes.
  irlume = inputs.irlume.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # Gaze's recipe with the Nyx Rust toolchain: its locked crates need Rust 1.96, and
  # nixpkgs 26.05 has 1.95.
  gaze = pkgs.callPackage "${inputs.gaze}/packaging/nix/gaze.nix" { inherit (nyx) rustPlatform; };

  nyx-icon-tools = pkgs.callPackage ./nyx-icon-tools.nix {
    inherit nyx;
    src = inputs.nyx;
    design = inputs.nyx-design;
  };
}
