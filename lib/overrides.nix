# Packages built at a version ahead of nixpkgs, each for a reason in docs/compatibility.md.
# `checks.overrides` fails once nixpkgs has caught up with one (at least `ours`), so the
# override is dropped instead of quietly missing nixpkgs' security fixes. `review` is when
# to look again even if nothing failed.
[
  {
    name = "libical";
    ours = "4.0.7";
    nixpkgs = pkgs: pkgs.libical.version;
    for = "nyx-pim (Contacts, Calendar, Reminders): libical 4's time zone behaviour";
    review = "2027-02-17";
  }
  {
    name = "libshumate";
    ours = "1.7.0";
    nixpkgs = pkgs: pkgs.libshumate.version;
    for = "Maps: libshumate 1.7's API";
    review = "2027-02-17";
  }
  {
    name = "tdlib";
    ours = "1.8.67";
    nixpkgs = pkgs: pkgs.tdlib.version;
    for = "Pulse: TDLib 1.8.67's typed input objects (network-facing: keep current)";
    review = "2026-12-17";
  }
  {
    name = "sherpa-onnx";
    ours = "1.13.8";
    nixpkgs = pkgs: pkgs.sherpa-onnx.version;
    for = "Nyx Voice and the Assistant: the Rust bindings match 1.13.8's C API";
    review = "2027-02-17";
  }
  {
    name = "pacman (libalpm)";
    ours = "7.1.0";
    nixpkgs = pkgs: pkgs.pacman.version;
    for = "Store and the Assistant link libalpm 16 through the alpm crate";
    review = "2027-02-17";
  }
  {
    name = "zig";
    ours = "0.17.0";
    nixpkgs = pkgs: pkgs.zig.version;
    for = "libghostty-vt 1.0 (Nyx Agents)";
    review = "2027-02-17";
  }
  {
    name = "wayland-protocols";
    ours = "1.49";
    nixpkgs = pkgs: pkgs.wayland-protocols.version;
    for = "Hyprland 0.57.2";
    review = "2027-02-17";
  }
  {
    name = "Rust";
    ours = "1.99.1";
    nixpkgs = pkgs: pkgs.rustc.version;
    for = "every Nyx app (build-environment.json), from rust-overlay";
    review = "2027-02-17";
  }
  {
    name = "Go";
    ours = "1.27";
    nixpkgs = pkgs: pkgs.go.version;
    for = "flux (Nyx Connect's backend)";
    review = "2027-02-17";
  }
]
