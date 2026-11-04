# The NyxOS boot splash: one Plymouth theme per Nyx theme, built from nyx-design's colours
# and the brand mark (nyx-brand). The source is nyx-plymouth's own recipe (nix/).
{
  stdenvNoCC,
  src,
  design,
  python3,
  librsvg,
}:
stdenvNoCC.mkDerivation {
  pname = "nyx-plymouth";
  version = "0.1.0";
  inherit src;
  nativeBuildInputs = [
    python3
    librsvg
  ];
  buildPhase = ''
    python3 tools/generate.py --design ${design} --out build/themes \
      --install-root $out/share/plymouth/themes
  '';
  installPhase = ''
    mkdir -p $out/share/plymouth/themes
    cp -r build/themes/* $out/share/plymouth/themes/
  '';
  meta.description = "The NyxOS boot splash, one Plymouth theme per Nyx theme";
}
