# Hyprland with the Nyx patch series from nyx-hyprland (patches/<version>/, the same
# series the Arch hyprland-nyx package applies; its README lists every patch):
# gestures:workspace_swipe_wrap, experimental virtual monitors (hl.virtual_monitor, off
# unless experimental:virtual_monitors is set), misc:fullscreen_own_workspace, and top
# layers sliding with the workspace.
{
  lib,
  hyprland,
  patchSeries,
  # Hyprland's build with its tests (hyprland-with-tests): the whole series goes in,
  # hyprtester's own changes too, for checks.hyprland-tests.
  withTests ? false,
  runCommand,
  patchutils,
  fetchurl,
  wayland-protocols,
}:
let
  # Only the series folder, so commits elsewhere in nyx-hyprland (its plugins) don't
  # rebuild Hyprland.
  dir = builtins.path {
    path = patchSeries;
    name = "hyprland-nyx-patches";
  };
  # Listed from the input itself: Nix 2.35 can't read the copy above without building
  # (CI's nix flake check --no-build).
  names = lib.sort lib.lessThan (
    lib.filter (lib.hasSuffix ".patch") (lib.attrNames (builtins.readDir patchSeries))
  );
  # Hyprland's flake source leaves out hyprtester (unless built with its tests), so the
  # series goes in without its test changes, as one patch (a patch that only touched
  # hyprtester would be empty).
  series = runCommand "nyx-hyprland-series.patch" { nativeBuildInputs = [ patchutils ]; } ''
    for p in ${lib.concatMapStringsSep " " (n: "${dir}/${n}") names}; do
      ${if withTests then ''cat "$p"'' else "filterdiff -p1 -x 'hyprtester/*' \"$p\""}
    done > $out
  '';
  # Hyprland 0.57.2 needs wayland-protocols 1.49; nixpkgs has 1.48.
  wayland-protocols' = wayland-protocols.overrideAttrs (_: rec {
    version = "1.49";
    src = fetchurl {
      url = "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/${version}/downloads/wayland-protocols-${version}.tar.xz";
      hash = "sha256-7EyPdJQtbf96zotM5HZPDvn/YYqTXZdOp37e4q0kCxQ=";
    };
  });
in
(hyprland.override { wayland-protocols = wayland-protocols'; }).overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ series ];
  # No fuzz: a series that doesn't apply exactly fails, as nyx-hyprland's update.sh does.
  patchFlags = [
    "-p1"
    "-F0"
  ];
  # Hyprland reads its tag from VERSION in its filtered source, which Nix 2.35 can't
  # read without building (CI's nix flake check --no-build). The version says the same.
  env = old.env // {
    GIT_TAG = "v${lib.head (lib.splitString "+" old.version)}";
  };
})
