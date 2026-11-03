# Application icons from nyx-design, as a hicolor icon set.
{
  stdenvNoCC,
  lib,
  nyx,
  src,
}:
stdenvNoCC.mkDerivation {
  pname = "nyx-icons";
  version = nyx.version "0.1.0" src;
  inherit src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 crates/nyx-icons/apps/*.svg -t $out/share/icons/hicolor/scalable/apps
    runHook postInstall
  '';

  meta = {
    description = "Nyx application icons";
    homepage = "https://github.com/design-nexus/nyx-design";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
