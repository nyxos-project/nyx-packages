# The Share Sheet, its D-Bus service (activated on demand) and the CLI. Share
# extensions run in bubblewrap, which binds the Nix store and the system profile on
# NixOS.
{
  nyx,
  src,
  wl-clipboard,
  libsecret,
  zbar,
  bubblewrap,
}:
nyx.buildApp {
  pname = "nyx-share";
  inherit src;
  # wl-copy copies shared items; zbarimg reads QR codes; bwrap is the extensions' sandbox.
  runtimeInputs = [
    wl-clipboard
    libsecret
    zbar
    bubblewrap
  ];
  userUnits = [ "data/systemd/nyx-share.service" ];
  dbusServices = [ "data/dbus/io.github.design_nexus.nyx.Share1.service" ];
  meta = {
    description = "Share Sheet, D-Bus service and CLI for sharing files and links";
    homepage = "https://github.com/design-nexus/nyx-share";
    mainProgram = "nyx-share";
  };
}
