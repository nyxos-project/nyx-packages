# NyxOS's installer, for the live USB: Nyx Installer (the window) and nyx-install (the
# same without one), with the tools they run.
{
  nyx,
  src,
  util-linux,
  gptfdisk,
  dosfstools,
  btrfs-progs,
  cryptsetup,
  parted,
  systemd,
  nixos-install-tools,
  nix,
  coreutils,
}:
nyx.buildApp {
  pname = "nyx-installer";
  inherit src;
  runtimeInputs = [
    util-linux
    gptfdisk
    dosfstools
    btrfs-progs
    cryptsetup
    parted
    systemd
    nixos-install-tools
    nix
    coreutils
  ];
  meta = {
    description = "NyxOS's installer";
    homepage = "https://github.com/nyxos-project/nyx-installer";
    mainProgram = "nyx-installer";
  };
}
