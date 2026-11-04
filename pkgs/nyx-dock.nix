# The dock: pinned and running apps, folders and the trash, on a layer-shell panel.
{
  nyx,
  src,
  gtk4-layer-shell,
}:
nyx.buildApp {
  pname = "nyx-dock";
  inherit src;
  buildInputs = [ gtk4-layer-shell ];
  preCheck = nyx.privateBusPreCheck;
  userUnits = [ "apps/dock/data/nyx-dock.service" ];
  passthru.autostart."nyx-dock" = "graphical-session.target";
  meta = {
    description = "Dock for pinned and running apps, folders and the trash";
    homepage = "https://github.com/design-nexus/nyx-dock";
    mainProgram = "nyx-dock";
  };
}
