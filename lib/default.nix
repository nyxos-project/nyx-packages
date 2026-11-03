# Shared build support for Nyx Rust workspaces.
{
  lib,
  rust-bin,
  makeRustPlatform,
  runtimeShell,
  dbus,
  glib,
  evolution-data-server,
  libical,
  json-glib,
  libxml2,
  inputs,
}:
let
  # Matches build-environment.json in the Nyx repositories.
  rustToolchain = rust-bin.stable."1.99.1".minimal;
in
rec {
  inherit rustToolchain;

  rustPlatform = makeRustPlatform {
    cargo = rustToolchain;
    rustc = rustToolchain;
  };

  # Libraries behind nyx-core's Evolution Data Server bindings.
  edsInputs = [
    glib
    evolution-data-server
    libical
    json-glib
    libxml2
  ];

  # nyx-core's PIM stack is generated against libical-glib 4 and EDS 3.62 (Arch);
  # nixpkgs 26.05 has libical 3.0.20 and EDS 3.60.2. See docs/compatibility.md.
  blockedCoreCrates = [
    "nyx-pim"
    "nyx-eds"
    "nyx-pim-migrate"
    "nyx-icalglib-sys"
    "nyx-edataserver-sys"
  ];

  # Tests that talk to the session bus get a private one. The sandbox has neither
  # /etc/machine-id (so GLib can't autolaunch a bus) nor /etc/dbus-1/session.conf (the
  # default config of plain `dbus-run-session`, which some tests spawn themselves).
  privateBusPreCheck = ''
    mkdir -p "$TMPDIR/bin"
    cat > "$TMPDIR/bin/dbus-run-session" <<EOF
    #!${runtimeShell}
    exec ${dbus}/bin/dbus-run-session --dbus-daemon=${dbus}/bin/dbus-daemon \
      --config-file=${dbus}/share/dbus-1/session.conf "\$@"
    EOF
    chmod +x "$TMPDIR/bin/dbus-run-session"
    export PATH="$TMPDIR/bin:${dbus}/bin:$PATH"
    export DBUS_SESSION_BUS_ADDRESS=$(${dbus}/bin/dbus-daemon --fork --print-address \
      --config-file=${dbus}/share/dbus-1/session.conf)
  '';

  # "0.1.0-unstable-2026-11-02" from a source input's commit date.
  version =
    base: src:
    let
      d = src.lastModifiedDate;
    in
    "${base}-unstable-${builtins.substring 0 4 d}-${builtins.substring 4 2 d}-${builtins.substring 6 2 d}";

  # Nyx crates come from Git at revisions pinned in each Cargo.lock. Those revisions
  # are fixed, so fetching them at evaluation time is reproducible without hashes.
  cargoLock = src: {
    lockFile = "${src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  # A Rust workspace from a source input. Releases build in the "release" profile
  # the repositories ship (thin LTO, stripped).
  buildWorkspace =
    {
      pname,
      src,
      baseVersion ? "0.1.0",
      ...
    }@args:
    rustPlatform.buildRustPackage (
      {
        version = version baseVersion src;
        cargoLock = cargoLock src;
        checkType = "debug";
        meta = {
          license = lib.licenses.mit;
          platforms = [ "x86_64-linux" ];
        }
        // (args.meta or { });
      }
      // removeAttrs args [
        "baseVersion"
        "meta"
      ]
    );

  # `cargo test --workspace`, as the repositories' own CI runs it.
  testWorkspace =
    args:
    buildWorkspace (
      {
        dontCargoBuild = true;
        dontCargoInstall = true;
        cargoTestFlags = [ "--workspace" ];
        installPhase = "touch $out";
      }
      // args
    );
}
