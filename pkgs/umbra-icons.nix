# Umbra, the suite's icon theme, in its three looks (Umbra, Umbra Solid, Umbra Line),
# drawn in Nyx Dark's colours, and the umbra-icons command that redraws them in another
# theme's colours (into ~/.local/share/icons, which comes first).
{
  stdenvNoCC,
  lib,
  nyx,
  src,
  python3,
  gtk3,
  makeWrapper,
}:
stdenvNoCC.mkDerivation {
  pname = "umbra-icons";
  version = nyx.version "0.1.0" src;
  inherit src;

  nativeBuildInputs = [
    python3
    gtk3
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR XDG_DATA_HOME=$TMPDIR/data XDG_CONFIG_HOME=$TMPDIR/config XDG_STATE_HOME=$TMPDIR/state
    python3 bin/umbra-icons build --out themes --palette nyx-dark
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons $out/lib/umbra-icons
    cp -a themes/. $out/share/icons/
    cp -a umbra symbolic bin $out/lib/umbra-icons/
    makeWrapper ${python3}/bin/python3 $out/bin/umbra-icons \
      --add-flags $out/lib/umbra-icons/bin/umbra-icons \
      --prefix PATH : ${lib.makeBinPath [ gtk3 ]}
    runHook postInstall
  '';

  meta = {
    description = "Umbra, the Nyx icon theme, in Nyx Dark's colours";
    homepage = "https://github.com/design-nexus/umbra-icons";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "umbra-icons";
  };
}
