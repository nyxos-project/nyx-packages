# NyxOS's window decorations (nyx-hyprland's plugins/nyx-decor): headerbars for apps
# without window controls, and floating geometry kept across tiling. Built against
# hyprland-nyx, as a Hyprland plugin only loads into the build it was made for.
{
  lib,
  stdenv,
  pkg-config,
  hyprland,
  src,
}:
(hyprland.stdenv or stdenv).mkDerivation {
  pname = "nyx-decor";
  version = "0.1.0";
  src = "${src}/plugins/nyx-decor";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ hyprland ] ++ hyprland.buildInputs;
  makeFlags = [ "PREFIX=${placeholder "out"}" ];
  meta = {
    description = "NyxOS window decorations for Hyprland";
    homepage = "https://github.com/nyxos-project/nyx-hyprland";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
