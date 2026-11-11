# The dock: pinned and running apps, folders and the trash. NyxOS runs its Quickshell
# interface, as the laptop does: nyx-dock-backend starts with the session and the dock
# goes to share/nyx-shell/components, drawn by Nyx Shell's nyx-shell-qs. The GTK dock
# stays installed; its unit isn't started. The swipe plugin isn't built (it builds
# against the running Hyprland), so the dock hides once a workspace swipe ends.
{
  nyx,
  src,
  gtk4-layer-shell,
}:
nyx.buildApp {
  pname = "nyx-dock";
  inherit src;
  cargoBuildFlags = [
    "-p"
    "nyx-dock"
    "-p"
    "nyx-dock-backend"
  ];
  buildInputs = [ gtk4-layer-shell ];
  preCheck = nyx.privateBusPreCheck;
  userUnits = [
    "apps/dock/data/nyx-dock.service"
    "apps/dock-backend/data/nyx-dock-backend.service"
  ];
  passthru.autostart."nyx-dock-backend" = "graphical-session.target";
  postInstall = ''
    mkdir -p $out/share/nyx-shell/components
    cp -r qml/Dock $out/share/nyx-shell/components/nyx-dock
  '';
  meta = {
    description = "Dock for pinned and running apps, folders and the trash";
    homepage = "https://github.com/design-nexus/nyx-dock";
    mainProgram = "nyx-dock";
  };
}
