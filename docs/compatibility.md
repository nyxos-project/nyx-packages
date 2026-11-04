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
