# The shared libraries have no programs to ship; these run their test suites against
# the pinned sources so every app built on them starts from a tested revision.
{
  pkgs,
  nyx,
  inputs,
}:
{
  nyx-core = nyx.testWorkspace {
    pname = "nyx-core-tests";
    src = inputs.nyx-core;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = nyx.pimInputs ++ [ pkgs.gtk4 ];
    cargoTestFlags = [
      "--workspace"
      "--no-fail-fast"
    ]
    ++ map (crate: "--exclude=${crate}") nyx.blockedCoreCrates;
    # libical reads time zones from TZDIR; the build sandbox has no /etc/zoneinfo.
    preCheck = nyx.privateBusPreCheck + ''
      export TZDIR=${pkgs.tzdata}/share/zoneinfo
    '';
  };

  nyx-design = nyx.testWorkspace {
    pname = "nyx-design-tests";
    src = inputs.nyx-design;
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = with pkgs; [
      gtk4
      mpv-unwrapped
      libGL
    ];
  };
}
