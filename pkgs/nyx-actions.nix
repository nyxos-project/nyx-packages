# nyx-actions from nyx-core: the part of the `nyx` command that runs Nyx apps' actions
# (`nyx apps`, `nyx APP …`, help, completion), on the same action manifests Glimpse and
# Nyx Assistant read (share/nyx/actions). nyxos's `nyx` routes app words to it.
{
  nyx,
  src,
}:
nyx.buildWorkspace {
  pname = "nyx-actions";
  inherit src;
  cargoBuildFlags = [
    "-p"
    "nyx-actions"
    "--features"
    "cli"
  ];
  # The library's tests; the registry tests run a private D-Bus daemon.
  cargoTestFlags = [
    "-p"
    "nyx-actions"
    "--features"
    "cli"
    "--lib"
  ];
  meta = {
    description = "Nyx apps' actions for the nyx command";
    homepage = "https://github.com/design-nexus/nyx-core";
    mainProgram = "nyx-actions";
  };
}
