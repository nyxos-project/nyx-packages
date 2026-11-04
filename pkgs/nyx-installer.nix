# NyxOS's installer, for the live USB: nyx-install (disks, plans, the install itself)
# with the tools it runs.
{
  nyx,
  src,
  lib,
  makeWrapper,
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
nyx.buildWorkspace {
  pname = "nyx-installer";
  inherit src;
  nativeBuildInputs = [ makeWrapper ];
  postFixup = ''
    wrapProgram $out/bin/nyx-install --prefix PATH : ${
      lib.makeBinPath [
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
      ]
    }
  '';
  meta = {
    description = "NyxOS's installer";
    homepage = "https://github.com/nyxos-project/nyx-installer";
    mainProgram = "nyx-install";
  };
}
