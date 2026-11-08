# Nyx Theme Engine 2.0 from nyx-design: the `nyx-theme` command (choosing, installing,
# updating and checking themes; the snapshot the shell reads) and the Nyx.Theme QML
# module for Quickshell components. The engine itself is built into every app.
{
  nyx,
  src,
  git,
}:
nyx.buildWorkspace {
  pname = "nyx-theme";
  baseVersion = "0.2.0";
  inherit src;
  cargoBuildFlags = [
    "-p"
    "nyx-theme-cli"
  ];
  # The GTK-free engine and the command; the GTK adapter is tested by the apps.
  cargoTestFlags = [
    "-p"
    "nyx-theme-core"
    "-p"
    "nyx-theme-cli"
  ];
  # The installer's tests clone local repositories.
  nativeCheckInputs = [ git ];
  postInstall = ''
    mkdir -p $out/share/nyx/qml
    cp -r qml/Nyx $out/share/nyx/qml/
    install -Dm644 crates/nyx-theme-core/themes/catppuccin-mocha/LICENSE $out/share/licenses/nyx-theme/catppuccin-LICENSE
    install -Dm644 -t $out/share/doc/nyx-theme docs/theme-engine/*.md
  '';
  meta = {
    description = "Nyx Theme Engine: the nyx-theme command and the Nyx.Theme QML module";
    homepage = "https://github.com/design-nexus/nyx-design";
    mainProgram = "nyx-theme";
  };
}
