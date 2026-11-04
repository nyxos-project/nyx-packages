# Mail, its sync service and the Glimpse plugin. Messages render in WebKitGTK 6.
{
  nyx,
  src,
  webkitgtk_6_0,
  glib-networking,
}:
nyx.buildApp {
  pname = "nyx-mail";
  inherit src;
  glimpsePlugin = true;
  # glib-networking gives WebKit TLS for remote content.
  buildInputs = [
    webkitgtk_6_0
    glib-networking
  ];
  userUnits = [ "apps/maild/data/nyx-maild.service" ];
  passthru.autostart."nyx-maild" = "graphical-session.target";
  meta = {
    description = "Desktop mail with a unified inbox, conversations, search and offline reading";
    homepage = "https://github.com/design-nexus/nyx-mail";
    mainProgram = "nyx-mail";
  };
}
