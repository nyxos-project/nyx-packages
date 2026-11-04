# Control Center: network, Bluetooth, sound, brightness, calendar and plugin tiles on a
# layer-shell panel. Tiles that run Omarchy's scripts (night light, idle, monitor
# scaling, DNS, Bluetooth pairing, screenshots) have nothing to run on NyxOS yet.
{
  nyx,
  src,
  gtk4-layer-shell,
  pulseaudio,
  brightnessctl,
}:
nyx.buildApp {
  pname = "nyx-control-center";
  inherit src;
  buildInputs = [ gtk4-layer-shell ];
  preCheck = nyx.privateBusPreCheck;
  # nmcli, systemctl and hyprctl come from the system; pactl drives sound and
  # brightnessctl the screen where Omarchy's brightness script isn't there.
  runtimeInputs = [
    pulseaudio
    brightnessctl
  ];
  userUnits = [ "apps/control-center/data/nyx-control-center.service" ];
  passthru.autostart."nyx-control-center" = "graphical-session.target";
  meta = {
    description = "Quick settings for network, Bluetooth, sound and displays";
    homepage = "https://github.com/design-nexus/nyx-control-center";
    mainProgram = "nyx-control-center";
  };
}
