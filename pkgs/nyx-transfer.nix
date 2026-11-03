{
  nyx,
  src,
  sqlite,
  rclone,
  openssh,
}:
nyx.buildApp {
  pname = "nyx-transfer";
  inherit src;
  # The workspace's default member is only the app; the daemon is a separate member.
  cargoBuildFlags = [ "--workspace" ];
  cargoTestFlags = [ "--workspace" ];
  # rusqlite links the system SQLite here, not a bundled copy.
  buildInputs = [ sqlite ];
  # The rclone tests start local rclone servers and scan their SSH host keys. They
  # give each server a fixed half second to start, which parallel tests can overrun.
  dontUseCargoParallelTests = true;
  # rclone serve sftp saves its generated host key under HOME, which the build
  # sandbox doesn't let it write.
  preCheck = ''
    export HOME=$(mktemp -d)
  '';
  nativeCheckInputs = [
    rclone
    openssh
  ];
  runtimeInputs = [
    rclone
    openssh
  ];
  userUnits = [ "data/nyx-transfer.service" ];
  dbusServices = [ "data/io.github.design_nexus.nyx.Transfer1.service" ];
  passthru.autostart."nyx-transfer" = "default.target";
  meta = {
    description = "Copy files between local, SFTP, FTP, FTPS and WebDAV locations";
    homepage = "https://github.com/design-nexus/nyx-transfer";
    mainProgram = "nyx-transfer";
  };
}
