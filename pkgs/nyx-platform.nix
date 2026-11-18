# nyx-platform from nyx-core: the desktop jobs Omarchy's omarchy-* scripts do (the Wi-Fi
# band, connection details, speed test, captive-portal sign-in, DNS provider, restarting
# Wi-Fi and Bluetooth, Taildrop), for NyxOS, with the scripts' arguments and output.
# The Nyx apps run `nyx-platform JOB` where there's no omarchy-JOB. It runs nmcli, ip,
# ping (a setuid wrapper), curl and tailscale from the system's PATH.
{
  nyx,
  src,
}:
nyx.buildWorkspace {
  pname = "nyx-platform";
  inherit src;
  cargoBuildFlags = [
    "-p"
    "nyx-platform"
    "--features"
    "cli"
  ];
  cargoTestFlags = [
    "-p"
    "nyx-platform"
    "--features"
    "cli"
  ];
  meta = {
    description = "Desktop jobs the same way on NyxOS and Omarchy";
    homepage = "https://github.com/design-nexus/nyx-core";
    mainProgram = "nyx-platform";
  };
}
