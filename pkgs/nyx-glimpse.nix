# Local universal search: the launcher, its indexer and Settings, and the semantic
# search helper. The helper is what `nyx-glimpse models setup` builds in the home folder
# on Arch; here it is built against the same pinned llama.cpp, and the models still
# download at runtime.
{
  lib,
  stdenv,
  nyx,
  src,
  fetchFromGitHub,
  cmake,
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
let
  # llama.cpp b11461 with the options apps/glimpse/scripts/setup-runtime.sh uses.
  llama = stdenv.mkDerivation {
    pname = "glimpse-llama-cpp";
    version = "b11461";
    src = fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      rev = "4d756bc72bf00a4aacf410ae15a2d315f3db400d";
      hash = "sha256-RLPfPr+5yjQsWDpOSD1tGGNNThxYgTV6Bm3mh/pOC2E=";
    };
    nativeBuildInputs = [ cmake ];
    cmakeFlags = [
      "-DBUILD_SHARED_LIBS=ON"
      "-DGGML_BACKEND_DL=ON"
      "-DGGML_NATIVE=OFF"
      "-DGGML_CPU_ALL_VARIANTS=ON"
      "-DGGML_CUDA=OFF"
      "-DGGML_VULKAN=OFF"
      "-DLLAMA_BUILD_MTMD=ON"
      "-DLLAMA_BUILD_COMMON=OFF"
      "-DLLAMA_BUILD_TOOLS=OFF"
      "-DLLAMA_BUILD_APP=OFF"
      "-DLLAMA_BUILD_UI=OFF"
      "-DLLAMA_OPENSSL=OFF"
      "-DLLAMA_BUILD_SERVER=OFF"
      "-DLLAMA_BUILD_EXAMPLES=OFF"
      "-DLLAMA_BUILD_TESTS=OFF"
      "-DCMAKE_INSTALL_RPATH=$ORIGIN"
      "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"
    ];
    installPhase = ''
      mkdir -p $out/include $out/lib
      cp ../include/llama.h ../ggml/include/*.h ../tools/mtmd/mtmd.h ../tools/mtmd/mtmd-helper.h $out/include/
      find . -name '*.so*' \( -type f -o -type l \) -exec cp -P {} $out/lib/ \;
      install -Dm644 ../LICENSE $out/share/licenses/llama.cpp/LICENSE
    '';
  };

  # runtime/bin/glimpse-embed with the llama.cpp libraries and CPU backends in
  # runtime/lib, the layout Glimpse looks for.
  runtime = nyx.rustPlatform.buildRustPackage {
    pname = "glimpse-embed";
    version = nyx.version "0.1.0" src;
    src = "${src}/apps/glimpse/inference";
    cargoLock.lockFile = "${src}/apps/glimpse/inference/Cargo.lock";
    env.GLIMPSE_LLAMA_DIR = "${llama}";
    postInstall = ''
      mkdir -p $out/lib
      cp -P ${llama}/lib/*.so* $out/lib/
      cp ${llama}/share/licenses/llama.cpp/LICENSE $out/LLAMA_LICENSE
      echo 4d756bc72bf00a4aacf410ae15a2d315f3db400d > $out/LLAMA_REVISION
    '';
  };
in
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
  passthru = {
    inherit llama runtime;
    autostart."nyx-glimpse-backend" = "graphical-session.target";
  };
  meta = {
    description = "Local universal search for apps, files, settings and plugins";
    homepage = "https://github.com/design-nexus/nyx-glimpse";
    mainProgram = "nyx-glimpse";
  };
}
