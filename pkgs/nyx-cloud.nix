# Headless cloud-storage service: rclone mounts for accounts from Nyx Online Accounts.
# fusermount3 must stay the setuid wrapper in /run/wrappers/bin, so only rclone goes
# on the service's PATH.
{
  lib,
  nyx,
  src,
  pkg-config,
  makeWrapper,
  glib,
  rclone,
}:
nyx.buildWorkspace {
  pname = "nyx-cloud";
  inherit src;
  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];
  buildInputs = [ glib ];
  nativeCheckInputs = [ rclone ];
  postFixup = ''
    wrapProgram $out/bin/nyx-cloudd --prefix PATH : ${lib.makeBinPath [ rclone ]}
  '';
  userUnits = [ "data/nyx-cloud.service" ];
  dbusServices = [ "data/io.github.design_nexus.nyx.Cloud1.service" ];
  passthru.autostart."nyx-cloud" = "default.target";
  meta = {
    description = "Shared rclone storage service for the Nyx desktop";
    homepage = "https://github.com/design-nexus/nyx-cloud";
    mainProgram = "nyx-cloudd";
  };
}
