# Nyx Agents: nyx-agentd (the session manager) and its user socket, the nyx-agents app
# and command, its Glimpse plugin and Settings page, and the AI Hub plugin for Nyx Bar
# and the Control Center. The plugin goes to share/nyx/plugins/nyx.ai-hub, where both
# hosts find it as a packaged (trusted) plugin through XDG_DATA_DIRS: it talks to
# nyx-agentd and Nyx AI Core over their sockets, which a sandboxed plugin can't.
{
  nyx,
  src,
  libghostty-vt,
  rustPlatform,
  sqlite,
  wayland,
  git,
  sway,
  wl-clipboard,
  xdg-utils,
  xdg-terminal-exec,
}:
nyx.buildApp {
  pname = "nyx-agents";
  inherit src;
  cargoBuildFlags = [
    "-p"
    "nyx-agentd"
    "-p"
    "nyx-agents"
    "-p"
    "agents-glimpse"
    "-p"
    "nyx-ai-hub-plugin"
  ];
  # The terminal, session records, usage scanners and the plugin's views and manifest.
  cargoTestFlags = [
    "-p"
    "nyx-term"
    "-p"
    "nyx-agents-proto"
    "-p"
    "nyx-agents-core"
    "-p"
    "nyx-ai-hub-plugin"
  ];
  # ghostty-vt-sys links the library built here instead of its vendored tarballs, and
  # generates its bindings with bindgen.
  env.NYX_GHOSTTY_VT_PREFIX = "${libghostty-vt}";
  nativeBuildInputs = [ rustPlatform.bindgenHook ];
  buildInputs = [
    sqlite
    wayland
  ];
  # git for branches and worktrees, sway for agent workspaces (headless), and what the
  # AI Hub runs: wl-copy, xdg-open, and the user's terminal for "resume in a terminal".
  runtimeInputs = [
    git
    sway
    wl-clipboard
    xdg-utils
    xdg-terminal-exec
  ];
  glimpsePlugin = true;
  userUnits = [
    "data/nyx-agentd.socket"
    "data/nyx-agentd.service"
  ];
  postInstall = ''
    install -Dm644 data/settings/extension.toml -t $out/share/nyx-settings/extensions/agents
    dest=$out/share/nyx/plugins/nyx.ai-hub
    install -Dm644 apps/ai-hub-plugin/plugin.toml apps/ai-hub-plugin/style.css -t "$dest"
    install -Dm644 apps/ai-hub-plugin/icons/*.svg -t "$dest/icons"
    install -Dm644 apps/ai-hub-plugin/icons/hicolor/scalable/apps/nyx-ai-hub-symbolic.svg \
      -t $out/share/icons/hicolor/scalable/apps
    mv $out/bin/nyx-ai-hub-plugin "$dest/"
    rm -f $out/bin/nyx-term-lab
  '';
  meta = {
    description = "Coding agents in native terminals, their session manager, and the AI Hub";
    homepage = "https://github.com/design-nexus/nyx-agents";
    mainProgram = "nyx-agents";
  };
}
