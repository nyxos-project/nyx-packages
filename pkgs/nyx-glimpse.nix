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
}:
nyx.buildApp {
  pname = "nyx-glimpse";
  inherit src;
  buildInputs = [ gtk4-layer-shell ];
  # Its index skips folders named build (config::forbidden), and the sandbox builds in
  # /build, so these tests find no files there; they pass outside it.
  checkFlags = [
    "--skip=aicore::tests::offers_a_read_only_file_search"
    "--skip=backend::tests::fast_results_need_no_ai_and_no_display"
    "--skip=semantic::tests::old_indexes_stay_and_a_new_model_rebuilds_beside_them"
  ];
  # The library and program tests; tests/core.rs still includes a file from the old
  # monorepo's Settings.
  cargoTestFlags = [
    "-p"
    "nyx-glimpse"
    "--lib"
    "--bins"
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
