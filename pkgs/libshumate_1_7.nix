# libshumate 1.7, as Arch ships it, for Nyx Maps (its Rust bindings ask for the 1.7
# API). nixpkgs 26.05 has 1.6. Drop this once nixpkgs ships 1.7.
{
  libshumate,
  fetchurl,
}:
libshumate.overrideAttrs {
  version = "1.7.0";
  src = fetchurl {
    url = "mirror://gnome/sources/libshumate/1.7/libshumate-1.7.0.tar.xz";
    hash = "sha256-OJbMS2p7+DFBwn3yPOSM3WhGdgO8a3ZJYDB83LvvgOU=";
  };
}
