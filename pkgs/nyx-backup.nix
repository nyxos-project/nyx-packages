# Encrypted Restic backups: the app, its background service and CLI, and the offline
# recovery tool. The recovery kit builder relies on mkinitcpio, so only the tool's
# restore side applies on NixOS. mount, findmnt and lsblk come from the system (mount
# must stay the setuid wrapper).
{
  nyx,
  src,
  restic,
  rclone,
  libsecret,
  git,
  gh,
  util-linux,
}:
nyx.buildApp {
  pname = "nyx-backup";
  inherit src;
  # The app isn't a default workspace member.
  cargoBuildFlags = [ "--workspace" ];
  cargoTestFlags = [
    "--workspace"
    "--no-fail-fast"
  ];
  # The mount checks call findmnt. Two tests read the host itself, which the build
  # sandbox doesn't have: its mount table (/proc a separate mount from /) and
  # /etc/os-release.
  nativeCheckInputs = [ util-linux ];
  checkFlags = [
    "--skip=fixture_tests::destination_traversal_and_nested_mount_are_refused"
    "--skip=tests::ordinary_file_is_never_disk"
  ];
  # git and gh for settings sync to GitHub.
  runtimeInputs = [
    restic
    rclone
    libsecret
    git
    gh
  ];
  userUnits = [ "data/nyx-backup.service" ];
  dbusServices = [ "data/io.github.design_nexus.nyx.Backup1.service" ];
  passthru.autostart."nyx-backup" = "default.target";
  meta = {
    description = "Encrypted Restic backups for selected user data";
    homepage = "https://github.com/design-nexus/nyx-backup";
    mainProgram = "nyx-backup";
  };
}
