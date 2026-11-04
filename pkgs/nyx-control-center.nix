# Control Center: network, Bluetooth, sound, brightness, calendar and plugin tiles on a
# layer-shell panel. Without Omarchy it uses nyx-notifyd, hyprsunset, bluetoothctl and
# brightnessctl; Omarchy-only extras (DNS presets, speed test, scale, text size) hide.
{
  nyx,
  src,
  gtk4-layer-shell,
  pulseaudio,
  brightnessctl,
  hyprsunset,
  bluez,
}:
nyx.buildApp {
  pname = "nyx-control-center";
  inherit src;
  buildInputs = [ gtk4-layer-shell ];
  preCheck = nyx.privateBusPreCheck;
  # nmcli, systemctl and hyprctl come from the system; pactl drives sound, brightnessctl
  # the screen, hyprsunset night light and bluetoothctl pairing.
  runtimeInputs = [
    pulseaudio
    brightnessctl
    hyprsunset
    bluez
  ];
  userUnits = [ "apps/control-center/data/nyx-control-center.service" ];
  passthru.autostart."nyx-control-center" = "graphical-session.target";
  meta = {
    description = "Quick settings for network, Bluetooth, sound and displays";
    homepage = "https://github.com/design-nexus/nyx-control-center";
    mainProgram = "nyx-control-center";
  };
}
