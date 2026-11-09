# Nyx Shell Core (the shell's coordinator: desktop state, overlay policy, focus, actions,
# components, settings, theme events), nyx-shellctl, the Nyx.Shell Quickshell module and
# the nyx-shell-qs runtime. Only the core starts with the session; nyx-shell-qs waits
# until components move into it (handoff 03).
{
  nyx,
  src,
  quickshell,
}:
nyx.buildApp {
  pname = "nyx-shell";
  inherit src;
  postPatch = ''
    substituteInPlace data/nyx-shell-qs.service \
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
  passthru.autostart."nyx-shell-core" = "graphical-session.target";
  postInstall = ''
    mkdir -p $out/share/nyx-shell
    cp -r qml $out/share/nyx-shell/
    install -Dm644 data/shell.toml $out/share/nyx-shell/shell.toml
  '';
  meta = {
    description = "Nyx Shell Core and the Nyx.Shell Quickshell module";
    homepage = "https://github.com/nyxos-project/nyx-shell";
    mainProgram = "nyx-shell-core";
  };
}
