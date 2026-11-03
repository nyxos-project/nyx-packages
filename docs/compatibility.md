# Compatibility with nixpkgs 26.05

## nyx-backup locks two nyx-core revisions

nyx-backup depends on nyx-core at `1c309f2`, and the nyx-design revision it uses
(`2302785`) depends on nyx-core at `52cba5e`. Its Cargo.lock then has two
`nyx-core 0.1.0` packages from different Git revisions. Cargo builds that from the
network, but neither `cargo vendor` nor Nix's vendoring can hold two packages with the
same name and version, so it can't be packaged until nyx-backup and nyx-design agree
on one nyx-core revision.

## nyx-torrents needs libtorrent 2.1 for creating torrents

nixpkgs packages libtorrent-rasterbar 2.0 only. nyx-torrents' C++ shim builds a new
torrent with libtorrent 2.1's `list_files` and the `create_torrent` constructor that
takes its result; with 2.0 it uses `add_files` into a `file_storage` instead
(`LIBTORRENT_VERSION_NUM` decides).

## nyx-pim needs libical 4

nyx-core's bindings (`crates/eds/*`) were generated on Arch against libical 4.0.6 and
evolution-data-server 3.62.1. nixpkgs 26.05, and nixos-unstable as of 2026-11-02, ship
libical 3.0.20 and evolution-data-server 3.60.2.

The applications no longer use Evolution Data Server: Calendar, Contacts, Reminders
and Settings depend on `nyx-pim`, and only `nyx-eds` and the migration tool
`nyx-pim-migrate` still link EDS. What still blocks them on NixOS is libical:

- `nyx-pim` requests `nyx-icalglib-sys` feature `v4`, which needs
  `libical-glib >= 4`.
- Requesting `v3_0_17` instead, `nyx-pim` compiles. It uses only types present in both
  versions (`ICalComponent`, `ICalTime`, `ICalTimezone`, `ICalProperty` and their
  enums).
- `nyx-icalglib-sys`'s generated ABI test fails against libical 3 because its C side
  references libical 4-only names (vCard types, `I_CAL_PARTICIPANTTYPE_*`). That's
  the test, not a layout mismatch in the types nyx-pim uses, but the enum constants
  nyx-pim uses haven't been checked against libical 3 yet.

Excluded from `checks.nyx-core` until this is fixed: `nyx-pim`, `nyx-icalglib-sys`,
and the EDS-only crates `nyx-eds`, `nyx-edataserver-sys` and `nyx-pim-migrate` (the
EDS bindings report EDS 3.62 constants; nixpkgs has 3.60). `nyx-eds` also calls two
libical 4-only functions, `i_cal_component_clone` and `i_cal_duration_as_seconds`.

Everything else in nyx-core passes on NixOS: `nyx-core`, `nyx-desktop`, `nyx-accounts`,
`nyx-sync`, `nyx-when`, and the `camel`, `ecal`, `json-glib` and `libxml2` bindings.

Suggested upstream change in nyx-core:

1. Give `nyx-pim` a feature that selects the libical level (`libical4`, on by default
   for Arch), so NyxOS can build it at `v3_0_17`.
2. Check the `ICalPropertyKind`, `ICalPropertyStatus` and `ICalParameterPartstat`
   constants nyx-pim uses against libical 3 headers.
3. Keep `nyx-eds` and `nyx-pim-migrate` out of NyxOS: they exist to migrate existing
   EDS data, which a fresh NyxOS install doesn't have.
