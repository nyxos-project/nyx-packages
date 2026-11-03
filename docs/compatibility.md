# Compatibility with nixpkgs 26.05

## nyx-core PIM stack needs libical 4 and EDS 3.62

`nyx-core`'s Evolution Data Server bindings (`crates/eds/*`) were generated on Arch
against libical 4.0.6 and evolution-data-server 3.62.1. nixpkgs 26.05, and
nixos-unstable as of 2026-11-02, ship libical 3.0.20 and evolution-data-server 3.60.2.

Affected crates, excluded from `checks.nyx-core`:

- `nyx-pim` and `nyx-eds` request `nyx-icalglib-sys` feature `v4`, which needs
  `libical-glib >= 4`. `nyx-eds` also requests EDS features `v3_62` and `v3_62_1`.
- `nyx-icalglib-sys`: the ABI test fails on struct layout and constants; libical 3 and
  4 aren't binary compatible.
- `nyx-edataserver-sys`: the ABI test fails on the EDS version constants (62 vs 60).
- `nyx-pim-migrate` depends on `nyx-eds`, so it isn't packaged yet.

Tried: requesting the newest API levels nixpkgs provides (`v3_0_17`, `v3_60`, `v3_58`).
Everything compiles except `nyx-eds`, which calls two libical 4-only functions,
`i_cal_component_clone` and `i_cal_duration_as_seconds` (4 call sites). Their libical 3
equivalents are `i_cal_component_new_clone` and `i_cal_duration_as_int`.

Everything else in nyx-core passes on NixOS: `nyx-core`, `nyx-desktop`, `nyx-accounts`,
`nyx-sync`, `nyx-when`, and the `camel`, `ecal`, `json-glib` and `libxml2` bindings.

Applications that depend on the PIM stack (Calendar, Contacts, Reminders, Mail and
Settings' account pages) are blocked until one of these lands:

1. Upstream in nyx-core: make the libical and EDS feature levels selectable, and gate
   the four calls on the libical version. Keeps Arch on libical 4 and lets NyxOS build
   against libical 3. Smallest change.
2. A NyxOS overlay with libical 4 and EDS 3.62. Rebuilds EDS and everything linked to
   it, and has to be maintained until nixpkgs moves.
3. Wait for nixpkgs to move to libical 4.
