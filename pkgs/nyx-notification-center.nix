# The Notification Center panel and pop-ups, and nyx-notifyd, which keeps every
# notification in Nyx's history. On NyxOS there is no Omarchy shell to show pop-ups, so
# the NixOS module runs nyx-notifyd in Nyx mode as the session's notification server.
{
  nyx,
  src,
  coreutils,
  dbus,
  runtimeShell,
  gtk4-layer-shell,
}:
nyx.buildApp {
  pname = "nyx-notification-center";
  inherit src;
  buildInputs = [ gtk4-layer-shell ];
  # nyx-notifyd's compatibility tests start `dbus-daemon --session` themselves.
  preCheck = nyx.privateBusPreCheck + ''
    cat > "$TMPDIR/bin/dbus-daemon" <<EOF
    #!${runtimeShell}
    args=()
    for arg in "\$@"; do
      [ "\$arg" = --session ] && arg=--config-file=${dbus}/share/dbus-1/session.conf
      args+=("\$arg")
    done
    exec ${dbus}/bin/dbus-daemon "\''${args[@]}"
    EOF
    chmod +x "$TMPDIR/bin/dbus-daemon"
  '';
  postPatch = ''
    substituteInPlace apps/notification-center/data/io.github.design_nexus.nyx.Notifications.service \
      --replace-fail 'Exec=/bin/false' 'Exec=${coreutils}/bin/false'
  '';
  userUnits = [
    "apps/notification-center/data/nyx-notification-center.service"
    "apps/notification-center/data/nyx-notifyd.service"
  ];
  dbusServices = [ "apps/notification-center/data/io.github.design_nexus.nyx.Notifications.service" ];
  # What `nyx-notification-center --use-nyx-popups` writes to ~/.local/share: a
  # notification sent while nyx-notifyd is down starts it.
  postInstall = ''
    mkdir -p $out/share/dbus-1/services
    cat > $out/share/dbus-1/services/org.freedesktop.Notifications.service <<EOF
    [D-BUS Service]
    Name=org.freedesktop.Notifications
    Exec=${coreutils}/bin/false
    SystemdService=nyx-notifyd.service
    EOF
  '';
  passthru.autostart = {
    "nyx-notifyd" = "graphical-session.target";
    "nyx-notification-center" = "graphical-session.target";
  };
  meta = {
    description = "Notification history, pop-ups and Do Not Disturb";
    homepage = "https://github.com/design-nexus/nyx-notification-center";
    mainProgram = "nyx-notification-center";
  };
}
