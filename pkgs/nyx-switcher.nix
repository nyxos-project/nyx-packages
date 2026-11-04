# Window and app switching (Alt+Tab, Super+Tab) and the overview of every window by
# workspace. Its shortcuts are its own file, ~/.config/hypr/nyx-switcher.lua, which
# NyxOS's hyprland.lua loads.
{
  nyx,
  src,
  gtk4-layer-shell,
}:
nyx.buildApp {
  pname = "nyx-switcher";
  inherit src;
  buildInputs = [ gtk4-layer-shell ];
  preCheck = nyx.privateBusPreCheck;
  userUnits = [ "apps/switcher/data/nyx-switcher.service" ];
  passthru.autostart."nyx-switcher" = "graphical-session.target";
  meta = {
    description = "Window and app switcher and the overview of every window";
    homepage = "https://github.com/design-nexus/nyx-switcher";
    mainProgram = "nyx-switcher";
  };
}
