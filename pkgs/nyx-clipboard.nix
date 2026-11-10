# Clipboard history: the daemon, the layer-shell popup and its settings window.
{
  nyx,
  src,
  gtk4-layer-shell,
  wayland,
  wtype,
}:
nyx.buildApp {
  pname = "nyx-clipboard";
  # Its action manifest (nyx clipboard …, Glimpse, the Assistant): lib installActions.
  actions = [ "nyx-clipboardd" ];
  inherit src;
  buildInputs = [
    gtk4-layer-shell
    wayland
  ];
  # wtype pastes the chosen entry into the focused window.
  runtimeInputs = [ wtype ];
  userUnits = [
    "data/systemd/nyx-clipboardd.service"
    "data/systemd/nyx-clipboard.service"
  ];
  dbusServices = [ "data/dbus/io.github.design_nexus.nyx.Clipboard1.service" ];
  passthru.autostart = {
    "nyx-clipboardd" = "graphical-session.target";
    "nyx-clipboard" = "graphical-session.target";
  };
  meta = {
    description = "Clipboard history with a keyboard popup and verification codes";
    homepage = "https://github.com/design-nexus/nyx-clipboard";
    mainProgram = "nyx-clipboard";
  };
}
