# Compatibility with nixpkgs 26.05

## One nyx-core revision per app

`cargo vendor`, and so Nix's vendoring, can't hold two packages with the same name and
version from different Git revisions. An app whose own nyx-core pin differs from its
nyx-design's ends up with two `nyx-core 0.1.0` packages and can't be packaged. Since
nyx-design `d2398b3`, all its crates depend on nyx-core `394ddf8`; an app pins that same
nyx-core revision next to it. Backup, Contacts, Calendar and Reminders do.

## nyx-pim needs libical 4

nyx-core's `nyx-pim`, which Contacts, Calendar and Reminders use, is written for libical
4 (Arch ships 4.0.7). nixpkgs 26.05, and nixos-unstable as of 2026-11-03, ship 3.0.20.
They differ in more than names: libical 3 doesn't add the `TZID` parameter when a time
with a zone is set, and doesn't resolve built-in zones for events without a
`VTIMEZONE`, both of which nyx-pim relies on (two of its time zone tests fail on 3.0).

nyx-packages builds libical 4.0.7 (`packages.libical_4`) for the Nyx PIM apps only;
everything else keeps nixpkgs' libical. Drop it once nixpkgs ships libical 4. Its
`regression` suite is left out of the build's tests: it expects `/usr/share/zoneinfo`
or `/etc/zoneinfo`, which the build sandbox lacks and NixOS has.

## nyx-core's Evolution Data Server crates need EDS 3.62

`nyx-eds`, its `-sys` crates and `nyx-pim-migrate` are generated against
evolution-data-server 3.62 (Arch); nixpkgs has 3.60, built against libical 3. They exist
to migrate existing EDS data, which a fresh NyxOS install doesn't have, so they are
neither packaged nor tested here.

## nyx-torrents needs libtorrent 2.1 for creating torrents

nixpkgs packages libtorrent-rasterbar 2.0 only. nyx-torrents' C++ shim builds a new
torrent with libtorrent 2.1's `list_files` and the `create_torrent` constructor that
takes its result; with 2.0 it uses `add_files` into a `file_storage` instead
(`LIBTORRENT_VERSION_NUM` decides).

## nyx-pulse needs TDLib 1.8.67 and NTgCalls 3.0.5

Pulse uses TDLib 1.8.67's typed input objects, which keep media metadata out of
`InputFile`; nixpkgs 26.05 has 1.8.63. nyx-packages builds 1.8.67 from the commit that
set that version (`packages.tdlib_1_8_67`), one compile job at a time because some of its
sources take several GB each. Drop it once nixpkgs ships 1.8.67 or later.

NTgCalls, the call engine, is the 3.0.5 release build Pulse pins upstream
(`packages.ntgcalls`). Building it means building WebRTC; the release links only glibc,
zlib and libstdc++. Its local WebRTC loopback test is skipped in the build sandbox, which
has only a loopback interface; it passes outside the sandbox.

## nyx-assistant needs sherpa-onnx 1.13.8, linked shared

The Assistant's streaming speech worker uses sherpa-onnx 1.13.8, whose Rust bindings
match that version's C API; nixpkgs 26.05 has 1.12.38. nyx-packages builds 1.13.8 from
source (`packages.sherpa-onnx_1_13_8`, nixpkgs' recipe without Python or the websocket
server, with the bundled sources 1.13.8 pins). The crate links sherpa-onnx statically by
default, which needs a static ONNX Runtime that nixpkgs doesn't build, so the package
switches it to its `shared` feature and links nixpkgs' ONNX Runtime.

Other differences from the Arch install:

- Browser automation drives nixpkgs' Chromium through `ASSISTANT_BROWSER_EXECUTABLE`
  instead of the Chromium build Playwright downloads.
- voxtype comes from nixpkgs with ONNX Runtime, which gives it the Parakeet engine.
- The daemon isn't started with the session: as with the install script, it is
  enabled once a model is downloaded (`systemctl --user enable --now nyx-assistantd`).
  `nyx-assistant-setup` prepares settings, abilities and the browser and search assets
  at login.
- The admin tools' root helper installs packages with pacman, so it isn't installed.
- `config::tests::scans_local_models_finds_ggufs` is skipped: it expects LM Studio models
  on the build machine.

## The desktop shell

- Glimpse's semantic search helper (`glimpse-embed`) is built here against the
  llama.cpp revision Glimpse pins (b11461) and linked to
  `~/.local/share/nyx-glimpse/runtime`, where `nyx-glimpse models setup` would build it.
  Glimpse's own shortcut setting edits `hyprland.lua` with Omarchy's helpers; on NyxOS
  Super+Space comes from the NyxOS Hyprland config instead. Its `tests/core.rs` still
  includes a file from the old monorepo's Settings and isn't run.
- nyx-notifyd runs in Nyx mode (`NYX_NOTIFYD_MODE=nyx`): with no Omarchy shell, it is
  the session's notification server and the Notification Center shows the pop-ups.
- Control Center tiles that run Omarchy's scripts (Bluetooth pairing, per-monitor
  brightness and scaling, night light, idle, DNS, captive portal, screenshots, the
  Omarchy menu) have nothing to run on NyxOS yet.
- Apps with a Glimpse plugin install it in `share/nyx-APP/glimpse`, as their install
  scripts do, linked at `/run/current-system/sw/share/nyx-APP/glimpse`; add one with
  `nyx-glimpse plugins install-local`.

## Nyx Biometrics: PAM from the NixOS configuration

On Arch, `nyx-auth-helper` writes the sign-in stacks into `/etc/pam.d` (with a snapshot
and a two-minute rollback). NixOS builds `/etc/pam.d` from its configuration, so the
module does the same from `nyx.biometrics.surfaces`: per method, in order, the Nyx gate
(`pam_exec nyx-auth-gate built-in|local`, which skips the next line for remote sessions,
sessions not on an active local seat, and, for face and fingerprint, a closed lid), then
the method as `sufficient`, ahead of `pam_unix`. Surfaces are `login` (greetd and the
console), `sudo` and `polkit` (`polkit-1`). On NixOS, `nyx-authctl pam apply`,
`helper install` and the helper's PAM and login-screen verbs say so and change nothing.

- Irlume and Gaze come from their own flakes and NixOS modules (the daemons, models,
  udev and polkit); their own PAM lines stay off and the Nyx rules take their place.
  Gaze is built with the Nyx Rust toolchain, as its locked crates need Rust 1.96.
- The broker, the key service and the apps' broker check (`nyx-auth-proto`) know Nyx
  programs by `/etc/nyx/trusted-bin` and Nix's `.NAME-wrapped`; system programs
  (`pkexec`, `pkcheck`, `systemd-creds`, fprintd's tools) are found in `/run/wrappers/bin`
  and `/run/current-system/sw` when `/usr` doesn't have them.
- The root helper is at `/run/current-system/sw/lib/nyx-biometrics/nyx-auth-helper`,
  the path its polkit actions name. It registers security keys in
  `/etc/nyx-biometrics/u2f_keys`, which `pam_u2f` reads.
- Not on NyxOS yet: the Quickshell sign-in overlays and the SDDM theme (NyxOS has
  neither Omarchy's shell nor SDDM), and the lock-screen surface (no lock screen yet).
- At login the Nyx rules come before the early `pam_unix` NixOS adds for the keyring, so
  a face or key is tried before the password is asked for. A face or key sign-in gives
  the keyring no password, so it stays locked until something unlocks it.
