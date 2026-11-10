# Hyprland with the Nyx patch series from nyx-hyprland (patches/<version>/, the same
# series the Arch hyprland-nyx package applies): gestures:workspace_swipe_wrap and
# experimental virtual monitors (hl.virtual_monitor, off unless
# experimental:virtual_monitors is set).
{
  lib,
  hyprland,
  patchSeries,
}:
hyprland.overrideAttrs (old: {
  patches =
    (old.patches or [ ])
    ++ map (name: "${patchSeries}/${name}") (
      lib.sort lib.lessThan (lib.filter (lib.hasSuffix ".patch") (lib.attrNames (builtins.readDir patchSeries)))
    );
})
