# The shared libraries have no programs to ship; these run their test suites against
# the pinned sources so every app built on them starts from a tested revision.
{
  pkgs,
  nyx,
  inputs,
  packages,
}:
{
  # The CUDA worker NVIDIA systems use (unfree, so no package here builds it): it builds
  # against nixpkgs' CUDA, every library it needs resolves, and it starts far enough to
  # print its version (libcuda comes from the driver, which a build has none of).
  llama-prism-cuda =
    let
      unfree = import inputs.nixpkgs {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
      cuda = unfree.callPackage ../pkgs/llama-prism-cuda.nix { };
    in
    pkgs.runCommand "llama-prism-cuda-starts" { } ''
      for exe in ${cuda}/lib/nyx-ai/llama.cpp/*; do
        if ${pkgs.binutils}/bin/readelf -h "$exe" >/dev/null 2>&1; then
          missing=$(${pkgs.glibc.bin}/bin/ldd "$exe" | grep 'not found' | grep -v libcuda.so || true)
          [ -z "$missing" ] || { echo "$exe: $missing" >&2; exit 1; }
        fi
      done
      ${cuda}/lib/nyx-ai/llama.cpp/llama-server --version 2>&1 | tee $out
      grep -q "version" $out
    '';

  # Files' tests the package build skips (pkgs/nyx-files-skipped-tests.txt: they need
  # bubblewrap, FUSE, a session bus or a Wayland display, which the build sandbox lacks),
  # run in a NixOS VM that has them, as a signed-in user. Fails when one fails.
  nyx-files-tests =
    let
      skipped = pkgs.lib.filter (l: l != "" && !pkgs.lib.hasPrefix "#" l) (
        pkgs.lib.splitString "\n" (builtins.readFile ../pkgs/nyx-files-skipped-tests.txt)
      );
      # The package's test program, built as the package is (the same inputs and flags).
      tests = packages.nyx-files.overrideAttrs (old: {
        pname = "nyx-files-test-program";
        doCheck = false;
        buildPhase = ''
          runHook preBuild
          cargo test --release --offline --no-run -p nyx-files --message-format=json \
            | ${pkgs.jq}/bin/jq -r 'select(.profile.test == true) | .executable // empty' > test-programs
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          n=0
          while read -r exe; do
            install -Dm755 "$exe" $out/bin/nyx-files-tests-$n
            n=$((n + 1))
          done < test-programs
          runHook postInstall
        '';
        postInstall = "";
        postFixup = "";
        preFixup = "";
      });
    in
    pkgs.testers.runNixOSTest {
      name = "nyx-files-tests";
      nodes.machine = {
        users.users.alice = {
          isNormalUser = true;
          uid = 1000;
        };
        environment.systemPackages = [
          pkgs.bubblewrap
          pkgs.fuse3
          pkgs.weston
          pkgs.xdg-utils
          pkgs.git
          pkgs.squashfsTools
          pkgs.ffmpeg
          pkgs.python3
          pkgs.dbus
        ];
        programs.fuse.userAllowOther = true;
        virtualisation.memorySize = 4096;
        system.stateVersion = "26.05";
      };
      testScript =
        let
          run = pkgs.writeShellScript "nyx-files-tests" ''
            export HOME=/home/alice XDG_RUNTIME_DIR=/run/user/1000
            weston --backend=headless --socket=wayland-test --idle-time=0 &
            sleep 3
            export WAYLAND_DISPLAY=wayland-test GSK_RENDERER=cairo
            # Also to the journal, which the test VM echoes to the build log as it runs:
            # one thread prints each test's name before running it, so a hang names itself.
            exec > >(tee >(systemd-cat -t nyx-files-tests)) 2>&1
            for t in ${tests}/bin/nyx-files-tests-*; do
              timeout -k 10 2400 "$t" --test-threads=1 --exact ${pkgs.lib.escapeShellArgs skipped} || exit 1
            done
          '';
        in
        ''
          machine.wait_for_unit("multi-user.target")
          machine.succeed("mkdir -p /run/user/1000 && chown alice /run/user/1000 && chmod 700 /run/user/1000")
          status, out = machine.execute("su - alice -c 'dbus-run-session -- ${run}' 2>&1", timeout=2700)
          print(out)
          assert status == 0, f"Files' tests failed ({status})"
          # Every listed test ran (a renamed one would otherwise pass unnoticed).
          for name in ${builtins.toJSON skipped}:
              assert f"test {name} ..." in out, f"{name} didn't run"
        '';
    };

  # The compositor patch series' tests: Hyprland's gtests and its whole hyprtester suite
  # (the series adds gestures, virtual_monitors and fullscreenSpaces to it), in a NixOS
  # VM, on Hyprland built with the full series. Fails when either fails.
  hyprland-tests =
    let
      hyprland = packages.hyprland-with-tests;
    in
    pkgs.testers.runNixOSTest {
      name = "nyx-hyprland-tests";
      nodes.machine = {
        environment.systemPackages = with pkgs; [
          foot # the virtual-monitor tests (patch 0008) open foot
          jq
          kitty
          wl-clipboard
          xeyes
        ];
        services.speechd.enable = false;
        environment.variables = {
          XDG_RUNTIME_DIR = "/tmp";
          XDG_CACHE_HOME = "/tmp";
          KITTY_CONFIG_DIRECTORY = "/etc/kitty";
        };
        environment.etc."kitty/kitty.conf".text = ''
          confirm_os_window_close 0
          remember_window_size no
          initial_window_width  640
          initial_window_height 400
        '';
        programs.hyprland = {
          enable = true;
          package = hyprland;
        };
        environment.etc."test.lua".source = "${hyprland}/share/hypr/test.lua";
        xdg.portal.enable = pkgs.lib.mkForce false;
        services.getty.autologinUser = "alice";
        users.users.alice.isNormalUser = true;
        system.stateVersion = "26.05";
        virtualisation = {
          cores = 4;
          memorySize = 8192;
          resolution = {
            x = 1920;
            y = 1080;
          };
          qemu.options = [ "-vga none -device virtio-gpu-pci" ];
        };
      };
      testScript = ''
        machine.wait_for_unit("multi-user.target")
        status, out = machine.execute("su - alice -c 'hyprland_gtests 2>&1'")
        print(out)
        assert status == 0, f"hyprland_gtests failed ({status})"
        status, out = machine.execute(
            "su - alice -c 'hyprtester -b ${hyprland}/bin/Hyprland -c /etc/test.lua -p ${hyprland}/lib/hyprtestplugin.so 2>&1'"
        )
        print(out)
        assert status == 0, f"hyprtester failed ({status})"
      '';
    };

  # Fails once nixpkgs ships a version at least the one a package here is built at, so
  # the override is dropped (lib/overrides.nix, docs/compatibility.md).
  overrides =
    let
      caught = builtins.filter (o: builtins.compareVersions (o.nixpkgs pkgs) o.ours >= 0) (
        import ../lib/overrides.nix
      );
      lines = map (o: "${o.name}: nixpkgs has ${o.nixpkgs pkgs}, ours is ${o.ours}") caught;
    in
    pkgs.runCommand "nyx-overrides-ahead-of-nixpkgs" { } (
      if caught == [ ] then
        "touch $out"
      else
        ''
          echo "nixpkgs has caught up; drop these overrides:" >&2
          ${pkgs.lib.concatMapStrings (l: "echo ${pkgs.lib.escapeShellArg "  ${l}"} >&2\n") lines}
          exit 1
        ''
    );

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
    # The theme installer's tests make git repositories.
    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.git
    ];
    buildInputs = with pkgs; [
      gtk4
      mpv-unwrapped
      libGL
      # nyx-plugin-view draws plugin icons with librsvg.
      librsvg
    ];
  };
}
