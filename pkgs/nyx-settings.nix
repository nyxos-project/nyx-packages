# Nyx Settings, built for NyxOS: its sidebar, and every system change through the Nyx
# System Manager (and printers through cups-pk-helper), so its root helper, Omarchy's
# way, isn't installed.
{
  nyx,
  src,
  pulseaudio,
  brightnessctl,
  bluez,
  git,
}:
nyx.buildApp {
  pname = "nyx-settings";
  # Its action manifest (nyx settings …, nyx devices …, Glimpse, the Assistant): lib installActions.
  actions = [ "nyx-settings" ];
  inherit src;
  buildInputs = nyx.pimInputs;
  buildFeatures = [ "nyxos" ];
  # The tests the repository's CI runs.
  cargoTestFlags = [
    "-p"
    "nyx-settings"
    "--bin"
    "nyx-settings"
  ];
  # nmcli, systemctl and hyprctl come from the system.
  runtimeInputs = [
    pulseaudio
    brightnessctl
    bluez
    git
  ];
  postInstall = ''
    rm $out/bin/nyx-settings-helper
  '';
  meta = {
    description = "System settings for the desktop, devices, accounts and sign-in";
    homepage = "https://github.com/design-nexus/nyx-settings";
    mainProgram = "nyx-settings";
  };
}
