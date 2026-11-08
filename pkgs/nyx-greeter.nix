# Nyx Greeter: the NyxOS login screen, a greetd greeter in GTK 4 running in a bare
# Hyprland session (share/nyx-greeter/hyprland.lua, with nyx-greeter on its PATH). The
# mark comes from nyx-brand.
{
  nyx,
  src,
  design,
  gtk4-layer-shell,
  librsvg,
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
  nativeBuildInputs = [ librsvg ];
  runtimeInputs = [ hyprland ];
  postInstall = ''
    install -Dm644 data/hyprland.lua $out/share/nyx-greeter/hyprland.lua
    substituteInPlace $out/share/nyx-greeter/hyprland.lua \
      --replace-fail "sh -c 'nyx-greeter;" "sh -c '$out/bin/nyx-greeter;"
    rsvg-convert -w 192 -h 192 ${design}/brand/nyx-mark-silver.svg \
      -o $out/share/nyx-greeter/mark.png
  '';
  meta = {
    description = "Nyx Greeter: the NyxOS login screen, for greetd";
    homepage = "https://github.com/nyxos-project/nyx-greeter";
    mainProgram = "nyx-greeter";
  };
}
