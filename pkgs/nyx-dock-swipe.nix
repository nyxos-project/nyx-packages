# Nyx Dock's Hyprland plugin (nyx-dock's hyprland-plugin): it reports how far a
# workspace swipe has gone, so the dock follows the swipe instead of hiding once it ends.
# Built against hyprland-nyx, as a Hyprland plugin only loads into the build it was made
# for; the NixOS module points nyx-dock-backend at it (NYX_DOCK_SWIPE_PLUGIN).
{
  lib,
  stdenv,
  pkg-config,
  hyprland,
  src,
}:
(hyprland.stdenv or stdenv).mkDerivation {
  pname = "nyx-dock-swipe";
  version = "0.1.0";
  src = "${src}/hyprland-plugin";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ hyprland ] ++ hyprland.buildInputs;
  # The repository's own build of it is for an install.sh checkout, not this one.
  preBuild = "rm -f nyx-dock-swipe.so";
  installPhase = ''
    runHook preInstall
    install -Dm755 nyx-dock-swipe.so -t $out/lib
    runHook postInstall
  '';
  meta = {
    description = "Nyx Dock's Hyprland plugin: the dock follows workspace swipes";
    homepage = "https://github.com/design-nexus/nyx-dock";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
