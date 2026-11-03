{
  nyx,
  src,
  fontconfig,
  gnutar,
  xz,
}:
nyx.buildApp {
  pname = "nyx-fonts";
  inherit src;
  # fc-list and fc-cache for installed fonts; tar with xz to unpack Nerd Fonts.
  runtimeInputs = [
    fontconfig
    gnutar
    xz
  ];
  meta = {
    description = "Browse, preview and install Google Fonts and Nerd Fonts";
    homepage = "https://github.com/design-nexus/nyx-fonts";
    mainProgram = "nyx-fonts";
  };
}
