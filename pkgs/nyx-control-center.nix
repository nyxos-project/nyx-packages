# Control Center: network, Bluetooth, sound, brightness, calendar and plugin tiles on a
# layer-shell panel. Without Omarchy it uses nyx-notifyd, hyprsunset, bluetoothctl and
# brightnessctl; Omarchy-only extras (DNS presets, speed test, scale, text size) hide.
# NyxOS runs its Quickshell interface (handoff 03): nyx-control-center-backend starts
# with the session and the panel goes to share/nyx-shell/components, drawn by Nyx
# Shell's nyx-shell-qs (whose OSD reads the backend's sound and brightness). The GTK
# panel stays installed; its unit isn't started.
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
  cargoBuildFlags = [
    "-p"
    "nyx-control-center"
    "-p"
    "nyx-control-center-backend"
  ];
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
  userUnits = [
    "apps/control-center/data/nyx-control-center.service"
    "apps/control-center-backend/data/nyx-control-center-backend.service"
  ];
  passthru.autostart."nyx-control-center-backend" = "graphical-session.target";
  postInstall = ''
    mkdir -p $out/share/nyx-shell/components
    cp -r qml/ControlCenter $out/share/nyx-shell/components/nyx-control-center
  '';
  meta = {
    description = "Quick settings for network, Bluetooth, sound and displays";
    homepage = "https://github.com/design-nexus/nyx-control-center";
    mainProgram = "nyx-control-center";
  };
}
