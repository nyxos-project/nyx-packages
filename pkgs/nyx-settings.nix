# Nyx Settings, built for NyxOS: its sidebar, and system pages through the Nyx System
# Manager. Its root helper still makes account, firewall, mount, printer and power
# changes until those move to the System Manager.
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
  # polkit lets pkexec run the helper only from the path its action names; the system
  # profile has it there (Settings looks for it there when /usr/local has none).
  postPatch = ''
    substituteInPlace apps/settings/data/io.github.design_nexus.nyx.settings.policy \
      --replace-fail /usr/local/lib/nyx-settings/nyx-settings-helper /run/current-system/sw/lib/nyx-settings/nyx-settings-helper
  '';
  # nmcli, systemctl and hyprctl come from the system.
  runtimeInputs = [
    pulseaudio
    brightnessctl
    bluez
    git
  ];
  postInstall = ''
    install -Dm755 $out/bin/nyx-settings-helper -t $out/lib/nyx-settings
    rm $out/bin/nyx-settings-helper
    install -Dm644 apps/settings/data/io.github.design_nexus.nyx.settings.policy -t $out/share/polkit-1/actions
  '';
  meta = {
    description = "System settings for the desktop, devices, accounts and sign-in";
    homepage = "https://github.com/design-nexus/nyx-settings";
    mainProgram = "nyx-settings";
  };
}
