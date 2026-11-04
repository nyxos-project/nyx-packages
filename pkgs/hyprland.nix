# Hyprland with gestures:workspace_swipe_wrap, so Nyx Settings' Loop around wraps the
# smooth workspace swipe without placeholder workspaces. The patch is from
# nyx-hyprland (patches/, the 0.55.4 backport); drop this once a Hyprland release in
# nixpkgs has the option.
{ hyprland }:
hyprland.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./hyprland-workspace-swipe-wrap.patch ];
})
