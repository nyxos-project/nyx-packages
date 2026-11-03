# The Share Sheet, its D-Bus service (activated on demand) and the CLI.
# Share extensions stay unavailable: their bubblewrap sandbox binds /usr and sets
# PATH=/usr/bin, which hold nothing on NixOS, so bwrap isn't put on PATH.
{
  nyx,
  src,
  wl-clipboard,
  libsecret,
  zbar,
}:
nyx.buildApp {
  pname = "nyx-share";
  inherit src;
  # wl-copy copies shared items; zbarimg reads QR codes.
  runtimeInputs = [
    wl-clipboard
    libsecret
    zbar
  ];
  userUnits = [ "data/systemd/nyx-share.service" ];
  dbusServices = [ "data/dbus/io.github.design_nexus.nyx.Share1.service" ];
  meta = {
    description = "Share Sheet, D-Bus service and CLI for sharing files and links";
    homepage = "https://github.com/design-nexus/nyx-share";
    mainProgram = "nyx-share";
  };
}
