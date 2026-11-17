# Local universal search: the launcher, its indexer and Settings, its Quickshell panel and
# backend. Search by meaning runs in Nyx AI Core (EmbeddingGemma 2); Glimpse has no
# inference of its own.
{
  nyx,
  src,
  gtk4-layer-shell,
  bubblewrap,
  curl,
  unzip,
  ffmpeg,
  poppler-utils,
  grim,
  git,
  xdg-utils,
  python3,
}:
nyx.buildApp {
  pname = "nyx-glimpse";
  inherit src;
  buildInputs = [ gtk4-layer-shell ];
  # Its index skips folders named build (config::forbidden) and the sandbox builds in
  # /build, so the tests make their folders in /tmp. They sandbox plugins with bwrap and
  # run a Python reader.
  preCheck = ''
    export TMPDIR=$(mktemp -d /tmp/glimpse-check.XXXXXX)
  '';
  nativeCheckInputs = [
    bubblewrap
    python3
  ];
  # The plugin sandbox mounts the system's /usr or /run/current-system and runs its
  # `true`; the build sandbox has neither. Glimpse's own CI runs these on a real system.
  checkFlags = map (t: "--skip=${t}") [
    "capture_plugin_sees_only_its_library"
    "custom_reader_and_source_revocation"
    "news_plugin_sees_only_its_library"
    "plugin_update_permission_change_disables_and_rolls_back"
    "sandbox_blocks_home_and_network"
    "plugins_install_disabled_and_execute_only_after_grant"
    "contextual_plugin_actions_run_only_inside_current_grants"
  ];
  # Its library, program and integration tests (tests/core.rs and the rest).
  cargoTestFlags = [
    "-p"
    "nyx-glimpse"
  ];
  # bwrap sandboxes plugins; curl and unzip fetch models and plugins; ffmpeg and
  # poppler-utils read media and PDFs for previews and the index.
  runtimeInputs = [
    bubblewrap
    curl
    unzip
    ffmpeg
    poppler-utils
    grim
    git
    xdg-utils
  ];
  # The Quickshell panel (drawn by Nyx Shell's nyx-shell-qs, panels and pinned panels
  # included) and the backend that serves it, started with the session: `nyx-glimpse
  # --toggle` goes there while it runs, to the GTK panel otherwise.
  userUnits = [ "apps/glimpse/data/nyx-glimpse-backend.service" ];
  # The unit `nyx-glimpse service enable` would otherwise write to ~/.config with this
  # package's path in it.
  postInstall = ''
    mkdir -p $out/share/nyx-settings/extensions/glimpse
    cat > $out/share/nyx-settings/extensions/glimpse/extension.toml <<EOF
    id = "glimpse"
    name = "Glimpse"
    category = "Desktop"
    version = "0.1.0"
    description = "Local search, sources, semantic models, plugins, and privacy."
    exec = "nyx-glimpse-settings"
    EOF
    mkdir -p $out/share/nyx-shell/components
    cp -r quickshell/Glimpse $out/share/nyx-shell/components/nyx-glimpse
    mkdir -p $out/lib/systemd/user
    cat > $out/lib/systemd/user/nyx-glimpsed.service <<EOF
    [Unit]
    Description=Glimpse local search index
    After=graphical-session.target
    PartOf=graphical-session.target

    [Service]
    ExecStart=$out/bin/nyx-glimpsed
    Restart=on-failure
    UMask=0077
    Nice=10

    [Install]
    WantedBy=default.target
    EOF
  '';
  passthru.autostart."nyx-glimpse-backend" = "graphical-session.target";
  meta = {
    description = "Local universal search for apps, files, settings and plugins";
    homepage = "https://github.com/design-nexus/nyx-glimpse";
    mainProgram = "nyx-glimpse";
  };
}
