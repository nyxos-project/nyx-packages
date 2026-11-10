# Home Assistant client, the automation daemon and its CLI.
{
  nyx,
  src,
  openssl,
  mpv-unwrapped,
  libGL,
  gtk4,
  wireplumber,
  libnotify,
  libsecret,
}:
nyx.buildApp {
  pname = "nyx-home";
  # Its action manifest (nyx home …, Glimpse, the Assistant): lib installActions.
  actions = [ "nyx-homed" ];
  inherit src;
  # reqwest uses native TLS here; libmpv and EGL for nyx-design's nyx-playback.
  buildInputs = [
    openssl
    mpv-unwrapped
    libGL
  ];
  # gtk-launch starts apps from automations; wpctl sets volume.
  runtimeInputs = [
    gtk4
    wireplumber
    libnotify
    libsecret
  ];
  userUnits = [ "data/nyx-homed.service" ];
  dbusServices = [ "data/io.github.design_nexus.nyx.Home.Automation.service" ];
  passthru.autostart."nyx-homed" = "graphical-session.target";
  meta = {
    description = "Native Home Assistant and desktop automation";
    homepage = "https://github.com/design-nexus/nyx-home";
    mainProgram = "nyx-home";
  };
}
