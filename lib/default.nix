# Shared build support for Nyx Rust workspaces.
{
  lib,
  rust-bin,
  makeRustPlatform,
  pkg-config,
  wrapGAppsHook4,
  gtk4,
  runtimeShell,
  coreutils,
  dbus,
  glib,
  json-glib,
  libxml2,
  callPackage,
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

  # Newer libraries than nixpkgs 26.05 has, for the apps that need them.
  libical_4 = callPackage ../pkgs/libical_4.nix { };
  libshumate_1_7 = callPackage ../pkgs/libshumate_1_7.nix { };
  tdlib_1_8_67 = callPackage ../pkgs/tdlib_1_8_67.nix { };
  ntgcalls = callPackage ../pkgs/ntgcalls.nix { };
  sherpa-onnx_1_13_8 = callPackage ../pkgs/sherpa-onnx_1_13_8.nix { };
  pacman_7_1 = callPackage ../pkgs/pacman_7_1.nix { };

  # Libraries behind nyx-pim, which Contacts, Calendar and Reminders use.
  pimInputs = [
    glib
    json-glib
    libxml2
    libical_4
  ];

  # nyx-core's Evolution Data Server crates need EDS 3.62 (Arch); nixpkgs 26.05 has
  # 3.60, built against libical 3. Only the EDS migration uses them. See
  # docs/compatibility.md.
  blockedCoreCrates = [
    "nyx-eds"
    "nyx-pim-migrate"
    "nyx-edataserver-sys"
    "nyx-ecal-sys"
    "nyx-camel-sys"
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
  # Git dependencies are fetched by hash (lib/git-hashes.json, from scripts/git-hashes),
  # never while evaluating: a store that has them builds without the network.
  cargoLock =
    src:
    let
      lockFile = "${src}/Cargo.lock";
      hashes = lib.importJSON ./git-hashes.json;
      git =
        lib.filter (p: lib.hasPrefix "git+" (p.source or ""))
          (builtins.fromTOML (builtins.readFile lockFile)).package;
    in
    {
      inherit lockFile;
      outputHashes = lib.listToAttrs (
        map (p: {
          name = "${p.name}-${p.version}";
          value =
            hashes.${p.source} or (throw "nyx-packages: no hash for ${p.source}; run scripts/git-hashes");
        }) git
      );
    };

  # The repositories' systemd user units and D-Bus activation files, pointed at the
  # package: they start programs from ~/.local/bin, @BINDIR@, @BIN@ or /usr/bin, and
  # activate through systemd with Exec=/usr/bin/false.
  installServices =
    { userUnits, dbusServices }:
    lib.optionalString (userUnits != [ ] || dbusServices != [ ]) ''
      for unit in ${lib.escapeShellArgs userUnits}; do
        install -Dm644 "$unit" -t $out/lib/systemd/user
      done
      for service in ${lib.escapeShellArgs dbusServices}; do
        install -Dm644 "$service" -t $out/share/dbus-1/services
      done
      for file in $out/lib/systemd/user/* $out/share/dbus-1/services/*; do
        [ -e "$file" ] || continue
        substituteInPlace "$file" \
          --replace-quiet '%h/.local/bin/' "$out/bin/" \
          --replace-quiet '@BINDIR@' "$out/bin" \
          --replace-quiet '@BIN@' "$out/bin" \
          --replace-quiet 'Exec=/usr/bin/false' 'Exec=${coreutils}/bin/false' \
          --replace-quiet 'Exec=/usr/bin/' "Exec=$out/bin/"
        if grep -qE '%h/\.local|/usr/' "$file"; then
          echo "$file still points outside the package" >&2
          exit 1
        fi
      done
    '';

  # A Rust workspace from a source input. Releases build in the "release" profile
  # the repositories ship (thin LTO, stripped). `userUnits` and `dbusServices` are
  # repository paths of service files to install (see installServices).
  buildWorkspace =
    {
      pname,
      src,
      baseVersion ? "0.1.0",
      userUnits ? [ ],
      dbusServices ? [ ],
      postInstall ? "",
      ...
    }@args:
    let
      # What starts with the session (unit name -> target), kept in the package too, for
      # an app in someone's Nix profile (the module's nyx-profile-units generator).
      autostart = (args.passthru or { }).autostart or { };
      autostartFile = lib.optionalString (autostart != { }) ''
        mkdir -p $out/share/nyx
        printf '%s\n' ${
          lib.escapeShellArgs (lib.mapAttrsToList (unit: target: "${unit} ${target}") autostart)
        } > $out/share/nyx/autostart
      '';
    in
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
        "userUnits"
        "dbusServices"
      ]
      // {
        postInstall = postInstall + installServices { inherit userUnits dbusServices; } + autostartFile;
      }
    );

  # A GTK application. Installs the repository's io.github.design_nexus.nyx.* desktop
  # entries and scalable icons, and puts `runtimeInputs` on the programs' PATH.
  # `glimpsePlugin` installs the repository's Glimpse plugin (a plugin.toml whose exec is
  # "./BINARY") with its binary in share/PNAME/glimpse, where the install script puts it.
  buildApp =
    {
      runtimeInputs ? [ ],
      glimpsePlugin ? false,
      nativeBuildInputs ? [ ],
      buildInputs ? [ ],
      preFixup ? "",
      postInstall ? "",
      ...
    }@args:
    buildWorkspace (
      removeAttrs args [
        "runtimeInputs"
        "glimpsePlugin"
      ]
      // {
        nativeBuildInputs = [
          pkg-config
          wrapGAppsHook4
        ]
        ++ nativeBuildInputs;
        buildInputs = [ gtk4 ] ++ buildInputs;
        passthru = (args.passthru or { }) // lib.optionalAttrs glimpsePlugin { inherit glimpsePlugin; };
        preFixup =
          lib.optionalString (runtimeInputs != [ ]) ''
            gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath runtimeInputs})
          ''
          + preFixup;
        # One install per file: some repositories carry the same icon in two places.
        postInstall = ''
          find . -path ./target -prune -o -name 'io.github.design_nexus.nyx.*.desktop' \
            -exec install -Dm644 -t $out/share/applications {} \;
          find . -path ./target -prune -o -name 'io.github.design_nexus.nyx.*.svg' \
            -exec install -Dm644 -t $out/share/icons/hicolor/scalable/apps {} \;
        ''
        + lib.optionalString glimpsePlugin ''
          manifest=$(find . -path ./target -prune -o -path '*glimpse/plugin.toml' -print | head -n 1)
          exe=$(sed -n 's|^exec = \["\./\([^"]*\)".*|\1|p' "$manifest")
          install -Dm644 "$manifest" $out/share/${args.pname}/glimpse/plugin.toml
          install -Dm755 $out/bin/$exe -t $out/share/${args.pname}/glimpse
        ''
        + postInstall;
      }
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
