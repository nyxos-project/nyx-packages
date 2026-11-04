# The Nyx themes' wallpapers in share/backgrounds/nyx, with wallpapers.toml, which says
# which belong to which theme and which one a new install shows.
{
  lib,
  stdenvNoCC,
  src,
}:
let
  sets = lib.importTOML "${src}/wallpapers.toml";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nyx-wallpapers";
  version = "0-unstable-${lib.substring 0 8 src.lastModifiedDate}";
  inherit src;
  installPhase = ''
    mkdir -p $out/share/backgrounds/nyx
    cp -r wallpapers.toml nyx-* $out/share/backgrounds/nyx/
  '';
  # The default wallpaper of each theme.
  passthru.defaults = lib.mapAttrs (
    _: theme: "${finalAttrs.finalPackage}/share/backgrounds/nyx/${theme.default}"
  ) sets;
  meta = {
    description = "Wallpapers for the Nyx themes";
    homepage = "https://github.com/nyxos-project/nyx-wallpapers";
    platforms = lib.platforms.all;
  };
})
