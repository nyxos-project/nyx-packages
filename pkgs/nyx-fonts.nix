{
  lib,
  nyx,
  src,
  pkg-config,
  wrapGAppsHook4,
  gtk4,
  fontconfig,
  gnutar,
  xz,
}:
nyx.buildWorkspace {
  pname = "nyx-fonts";
  inherit src;
  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
  ];
  buildInputs = [ gtk4 ];

  # fc-list and fc-cache for installed fonts; tar with xz to unpack Nerd Fonts.
  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${
      lib.makeBinPath [
        fontconfig
        gnutar
        xz
      ]
    })
  '';

  postInstall = ''
    install -Dm644 apps/fonts/data/io.github.design_nexus.nyx.Fonts.desktop -t $out/share/applications
    install -Dm644 crates/nyx-icons/apps/io.github.design_nexus.nyx.Fonts.svg \
      -t $out/share/icons/hicolor/scalable/apps
  '';

  meta = {
    description = "Browse, preview and install Google Fonts and Nerd Fonts";
    homepage = "https://github.com/design-nexus/nyx-fonts";
    mainProgram = "nyx-fonts";
  };
}
