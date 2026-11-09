# Local universal search: the launcher, its indexer and Settings, and the search backend
# for the Quickshell interface (with Nyx Shell Core). Semantic search runs in Nyx AI
# Core (EmbeddingGemma 2); Glimpse has no llama.cpp of its own.
{
  lib,
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
  wl-clipboard,
}:
nyx.buildApp {
  pname = "nyx-glimpse";
  inherit src;
  buildInputs = [ gtk4-layer-shell ];
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
    wl-clipboard
  ];
  # The search backend for the Quickshell interface (started with the session when Nyx
  # Shell Core runs it; see nyx.glimpse in the module).
  userUnits = [ "apps/glimpse/data/nyx-glimpse-backend.service" ];
  # The unit `nyx-glimpse service enable` would otherwise write to ~/.config with this
  # package's path in it; the Quickshell component goes where nyx-shell-qs finds it.
  postInstall = ''
    mkdir -p $out/share/nyx-shell/components
    cp -r quickshell/Glimpse $out/share/nyx-shell/components/Glimpse
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
  meta = {
    description = "Local universal search for apps, files, settings and plugins";
    homepage = "https://github.com/design-nexus/nyx-glimpse";
    mainProgram = "nyx-glimpse";
  };
}
