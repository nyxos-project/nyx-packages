# Nyx Greeter: the NyxOS login screen, a greetd greeter in GTK 4 running in a bare
# Hyprland session (share/nyx-greeter/hyprland.lua, with nyx-greeter on its PATH).
{
  nyx,
  src,
  gtk4-layer-shell,
  hyprland,
}:
nyx.buildApp {
  pname = "nyx-greeter";
  inherit src;
  cargoBuildFlags = [
    "-p"
    "nyx-greeter"
  ];
  # The greeter's own tests (the locker in the same repository has its own package).
  cargoTestFlags = [
    "-p"
    "nyx-greeter"
    "-p"
    "nyx-greeter-core"
    "-p"
    "nyx-greetd"
  ];
  buildInputs = [ gtk4-layer-shell ];
  runtimeInputs = [ hyprland ];
  postInstall = ''
    install -Dm644 data/hyprland.lua $out/share/nyx-greeter/hyprland.lua
    substituteInPlace $out/share/nyx-greeter/hyprland.lua \
      --replace-fail "sh -c 'nyx-greeter;" "sh -c '$out/bin/nyx-greeter;"
  '';
  meta = {
    description = "Nyx Greeter: the NyxOS login screen, for greetd";
    homepage = "https://github.com/nyxos-project/nyx-greeter";
    mainProgram = "nyx-greeter";
  };
}
