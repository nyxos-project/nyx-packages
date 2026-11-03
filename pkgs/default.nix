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
]
// {
  nyx-icons = pkgs.callPackage ./nyx-icons.nix {
    inherit nyx;
    src = inputs.nyx-design;
  };

  inherit (nyx) libical_4;

  nyx-icon-tools = pkgs.callPackage ./nyx-icon-tools.nix {
    inherit nyx;
    src = inputs.nyx;
    design = inputs.nyx-design;
  };
}
