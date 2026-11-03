# nyx-packages

Nix packages for the Nyx applications, built for [NyxOS](https://github.com/nyxos-project/nyxos).
The applications stay in their own repositories under
[design-nexus](https://github.com/design-nexus); this flake pins a revision of each,
builds it reproducibly and runs its tests.

## What's here

| Output | Source | Contents |
| --- | --- | --- |
| `packages.nyx-icons` | nyx-design | Nyx application icons (hicolor, scalable) |
| `packages.nyx-icon-tools` | nyx, nyx-design | `nyx-icons`: recolours Nyx icons for the Nyx theme |
| `packages.nyx-accounts` | nyx-accounts | `nyx-accountsd` session service (D-Bus activated) and `nyx-accountsctl` |
| `packages.nyx-fonts` | nyx-fonts | Nyx Fonts |
| `packages.nyx-notepad` | nyx-notepad | Nyx Notepad |
| `packages.nyx-calculator` | nyx-calculator | Nyx Calculator |
| `packages.nyx-archive` | nyx-archive | Nyx Archive, with 7-Zip |
| `packages.nyx-pdf` | nyx-pdf | Nyx PDF |
| `packages.nyx-news` | nyx-news | Nyx News and its Glimpse plugin |
| `packages.nyx-office` | nyx-office | Write, Sheets and Present (`nyx-write`, `nyx-sheets`, `nyx-present`) |
| `packages.nyx-git` | nyx-git | Nyx Git |
| `packages.nyx-music` | nyx-music | Nyx Music, with the GStreamer plugin sets |
| `packages.nyx-media-player` | nyx-media-player | Nyx Media Player (libmpv) |
| `packages.nyx-theater` | nyx-theater | Nyx Theater (libmpv) |
| `packages.nyx-photos` | nyx-photos | Nyx Photos and `nyx-viewer`; "Set as background" is hidden until NyxOS has a wallpaper command |
| `packages.nyx-share` | nyx-share | Share Sheet, CLI and D-Bus service; extensions unavailable (their sandbox expects `/usr`) |
| `packages.nyx-transfer` | nyx-transfer | Nyx Transfer and its background service |
| `packages.nyx-cloud` | nyx-cloud | Cloud storage service (rclone) |
| `packages.nyx-clipboard` | nyx-clipboard | Clipboard daemon, popup and Settings extension |
| `packages.nyx-home` | nyx-home | Nyx Home, its automation service and CLI |
| `packages.nyx-chat` | nyx-chat | Nyx Chat; no llama.cpp server (Chat installs PrismML's build itself) |
| `checks.nyx-core` | nyx-core | `cargo test --workspace` for the shared libraries |
| `checks.nyx-design` | nyx-design | `cargo test --workspace` for the design system |
| `nixosModules.default` | | `nyx.<app>.enable` for each app above, `nyx.accounts.enable`, and `nyx.icons.followTheme` (the tool plus its user units) |
| `overlays.default` | | `pkgs.nyx.<package>` |
| `lib` | | Toolchain and build helpers for Nyx Rust workspaces |

Every package is also a check, so `nix flake check` builds and tests everything.

nyx-core and nyx-design are libraries that the applications pull in as Cargo Git
dependencies at revisions pinned in their own `Cargo.lock`. They ship nothing on
their own; the checks make sure the pinned revisions build and pass their tests on
NixOS.

## Using it

```nix
{
  inputs.nyx-packages = {
    url = "github:nyxos-project/nyx-packages";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # in a NixOS configuration
  imports = [ inputs.nyx-packages.nixosModules.default ];
  nyx.fonts.enable = true;
}
```

```sh
nix build github:nyxos-project/nyx-packages#nyx-fonts
nix flake check github:nyxos-project/nyx-packages
```

## Builds

- Rust 1.99.1 from rust-overlay, matching `build-environment.json` in the Nyx
  repositories; nixpkgs 26.05 for everything else.
- Each package builds the release profile its repository ships (thin LTO, stripped)
  and runs its tests in the debug profile.
- Nyx crates fetched as Git dependencies come from the revisions in each
  `Cargo.lock`, fetched at evaluation time (`allowBuiltinFetchGit`).
- Tests that need a session bus get a private one (`lib.privateBusPreCheck`).
- `lib.buildApp` is the common GTK application recipe: it wraps the programs for
  GTK, puts `runtimeInputs` on their `PATH`, and installs the repository's
  `io.github.design_nexus.nyx.*` desktop entries and icons.
- `userUnits` and `dbusServices` install a repository's systemd user units and D-Bus
  activation files with store paths. The module registers them, and starts the units
  a package lists in `passthru.autostart`, as the repository's `[Install]` does.
- `/etc/nyx/trusted-bin` lists the `bin` folder of every enabled package. Services
  that trust callers by program (Clipboard, Accounts) read it through nyx-core's
  `nyx-peer`, since each app has its own store folder.

## Versions and channels

`flake.lock` is the version record: it pins nixpkgs, the Rust toolchain and the commit
of every Nyx source. To move one application forward:

```sh
nix flake update nyx-fonts
nix flake check
```

- `main` is the testing channel: sources move forward as they're updated.
- `stable` is promoted from `main` once a set of revisions has been tested in NyxOS.

CI builds and tests both branches and pushes the results to the Cachix binary cache.

## Compatibility

Applications are added only after the audit in
[nyxos/docs/audit](https://github.com/nyxos-project/nyxos/tree/main/docs/audit).
Known blockers are in [docs/compatibility.md](docs/compatibility.md).
