# The Nyx themes' wallpapers in share/backgrounds/nyx, with wallpapers.toml, which says
# which belong to which theme and which ones a new install shows.
{
  lib,
  stdenvNoCC,
  src,
}:
let
  sets = lib.importTOML "${src}/wallpapers.toml";
  path = finalAttrs: file: "${finalAttrs.finalPackage}/share/backgrounds/nyx/${file}";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nyx-wallpapers";
  version = "0-unstable-${lib.substring 0 8 src.lastModifiedDate}";
  inherit src;
  # A folder for each theme in wallpapers.toml.
  installPhase = ''
    mkdir -p $out/share/backgrounds/nyx
    cp -r wallpapers.toml ${lib.escapeShellArgs (lib.attrNames sets)} $out/share/backgrounds/nyx/
  '';
  # Each theme's desktop wallpaper (`default`) and lock and login screens' (`lock`, else
  # the desktop's).
  passthru.defaults = lib.mapAttrs (_: theme: path finalAttrs theme.default) sets;
  passthru.locks = lib.mapAttrs (_: theme: path finalAttrs (theme.lock or theme.default)) sets;
  meta = {
    description = "Wallpapers for the Nyx themes";
    homepage = "https://github.com/nyxos-project/nyx-wallpapers";
    platforms = lib.platforms.all;
  };
})
