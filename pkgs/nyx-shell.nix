# Nyx Shell Core (the shell's coordinator: desktop state, overlay policy, focus, actions,
# components, settings, theme events), nyx-shellctl, the Nyx.Shell Quickshell module and
# the nyx-shell-qs runtime, which draws the Quickshell components (handoff 03): the OSD
# from here, and those other packages put in share/nyx-shell/components (the Control
# Center, Desktop Widgets). Both start with the session.
{
  nyx,
  src,
  quickshell,
  qt6,
}:
nyx.buildApp {
  pname = "nyx-shell";
  inherit src;
  postPatch = ''
    # Nyx.Theme, Nyx.Ui and Nyx.PluginView come from the nyx-theme package, through the
    # system profile (the unit's own path replaces the session's). Glimpse's previews play
    # audio and video with QtMultimedia, which nixpkgs' Quickshell doesn't carry.
    substituteInPlace data/nyx-shell-qs.service \
      --replace-fail 'Environment=QML_IMPORT_PATH=%h/.local/share/nyx-shell/qml' \
        "Environment=QML_IMPORT_PATH=$out/share/nyx-shell/qml:/run/current-system/sw/share/nyx/qml:${qt6.qtmultimedia}/${qt6.qtbase.qtQmlPrefix}
    Environment=QT_PLUGIN_PATH=${qt6.qtmultimedia}/${qt6.qtbase.qtPluginPrefix}" \
      --replace-fail '/usr/bin/qs' '${quickshell}/bin/qs' \
      --replace-fail '%h/.local/share/nyx-shell/qml' "$out/share/nyx-shell/qml"
    # NixOS runs Quickshell from its store folder; trust that executable as the UI runtime.
    substituteInPlace data/shell.toml --replace-fail \
      'ui_runtimes = ["/usr/bin/quickshell"]' \
      'ui_runtimes = ["${quickshell}/bin/quickshell", "${quickshell}/bin/.quickshell-wrapped"]'
  '';
  userUnits = [
    "data/nyx-shell-core.service"
    "data/nyx-shell-qs.service"
  ];
  passthru.autostart = {
    "nyx-shell-core" = "graphical-session.target";
    "nyx-shell-qs" = "graphical-session.target";
  };
  postInstall = ''
    mkdir -p $out/share/nyx-shell/components
    cp -r qml $out/share/nyx-shell/
    cp -r qml/components/nyx-osd $out/share/nyx-shell/components/
    cp -r qml/components/nyx-window-menu $out/share/nyx-shell/components/
    install -Dm644 data/shell.toml $out/share/nyx-shell/shell.toml
  '';
  meta = {
    description = "Nyx Shell Core and the Nyx.Shell Quickshell module";
    homepage = "https://github.com/nyxos-project/nyx-shell";
    mainProgram = "nyx-shell-core";
  };
}
