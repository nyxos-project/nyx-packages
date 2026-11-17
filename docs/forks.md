# Forks and patch series

What NyxOS carries that upstream doesn't, why, and how each gets back to upstream or
stays maintainable. `scripts/upstream-watch` (weekly, `.github/workflows/upstream-watch.yml`)
opens an issue when upstream releases past a pin in `lib/upstreams.json`.

| What | Ours | Upstream status | Plan |
| --- | --- | --- | --- |
| llama.cpp | PrismML's fork, `prism-b12128` (Vulkan source build; CUDA as their prebuilt release) | PrismML's Bonsai quantization types aren't in ggml-org/llama.cpp | Ask PrismML to upstream the Bonsai types; until then follow each Prism release (watched), checking llama.cpp's server security fixes reached it, since AI Core exposes the server on 127.0.0.1 |
| Hyprland | 0.57.2 with nyx-hyprland's 13 patches (`patches/0.57.2`): workspace swipe wrap-around, virtual monitors (regions, workspaces, IPC, fullscreen), fullscreen on its own workspace, top layers sliding with the workspace | Not proposed upstream | Send the parts that stand alone upstream first (workspace swipe wrap-around, fullscreen on its own workspace), then virtual monitors as a series; rebase for each Hyprland release (watched); the series' own hyprtester and gtest suites run in `checks` (HYPR-004) |
| flux | v0.19.1 with `flux-nyxos.patch` (three files) | NyxOS hooks not upstream; upstream is 18 commits past the tag | Offer the hooks upstream as options (service paths, socket location); move to the next release once it carries them (watched) |
| irlume | archledger/irlume (flake input) | One maintainer | Mirror under the organization with review before each bump; watched |
| gaze | GunduLabs/gaze (flake input) | Upstream | Follow releases (watched) |
| pam_sm_rust, rust-tss-esapi | archledger forks (Cargo Git dependencies of nyx-biometrics) | Small fixes not upstream | Propose the fixes upstream; until merged, mirror the forks under the organization so a change needs review |
| nixpkgs patches | nyxos `patches/nixpkgs/0001-system-name-from-distro-id`, `0002-switch-says-nyxos` | Not upstream | Replace 0002 (the switch's own wording) with a wrapper message outside nixpkgs, so a nixpkgs bump can't fail on it and switch-to-configuration-ng isn't rebuilt locally; propose 0001 upstream (the system name from `distroId` is generally useful) |
| Packages ahead of nixpkgs | libical, libshumate, TDLib, sherpa-onnx, pacman, Zig, wayland-protocols, Rust, Go | nixpkgs behind | [compatibility.md](compatibility.md): `checks.overrides` fails once nixpkgs catches up |
