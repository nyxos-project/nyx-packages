# Local voice assistant: the daemon and CLI, TUI, speech and plugin workers, the Canvas,
# the Quickshell HUD, the bundled abilities, browser automation (Playwright with nixpkgs'
# Chromium) and the DuckDuckGo search server. Inference runs on the CPU; models download
# at runtime. The admin tools' root helper drives pacman, so NyxOS doesn't install it.
{
  lib,
  nyx,
  src,
  buildNpmPackage,
  importNpmLock,
  fetchFromGitHub,
  writeShellScript,
  cmake,
  onnxruntime,
  gtk4-layer-shell,
  pipewire,
  wayland,
  fontconfig,
  freetype,
  poppler,
  mpv-unwrapped,
  libGL,
  nodejs,
  chromium,
  quickshell,
  coreutils,
  python3,
  pulseaudio,
  wireplumber,
  libnotify,
  git,
  wtype,
  procps,
  curl,
  bubblewrap,
  xdg-dbus-proxy,
  unzip,
  util-linux,
  tesseract,
  gnutar,
  grim,
  glib,
  bluez,
  ripgrep,
  jq,
  voxtype,
}:
let
  app = "${src}/apps/assistant";
  version = nyx.version "0.1.0" src;

  # The browser worker and its pinned Playwright, without Playwright's own browsers.
  browser = buildNpmPackage {
    pname = "nyx-assistant-browser";
    inherit version;
    src = "${app}/browser";
    npmDeps = importNpmLock { npmRoot = "${app}/browser"; };
    npmConfigHook = importNpmLock.npmConfigHook;
    npmFlags = [ "--ignore-scripts" ];
    dontNpmBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r worker.mjs package.json node_modules $out/
    '';
  };

  # AstroCorp's DuckDuckGo MCP server at the revision the Assistant pins, with its
  # bounds patch and lock file. GPL-3.0-only; talks to the Assistant over stdio.
  search = buildNpmPackage {
    pname = "nyx-assistant-search";
    version = "0-unstable-2026-10-20";
    src = fetchFromGitHub {
      owner = "AstroCorp";
      repo = "MCP-DuckDuckGo";
      rev = "0cd5c5b9e8a4994736f18ef816c601dddf5a8324";
      hash = "sha256-Aixr+Y6H3H3SKWF+Opt3j4tSeRHP1Q8KN0D2b5cVwjg=";
    };
    patches = [ "${app}/search/astro-bounds.patch" ];
    postPatch = ''
      install -m 0644 ${app}/search/astro-package-lock.json package-lock.json
    '';
    npmDepsHash = "sha256-2/Nj9EQGbM67Wl9xUWqIFYO73g0hpr0E2G6kZOO4yeE=";
    npmFlags = [ "--ignore-scripts" ];
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      node ${app}/search/verify.mjs .
      runHook postCheck
    '';
    installPhase = ''
      npm prune --omit=dev --ignore-scripts
      mkdir -p $out
      cp -r dist node_modules package.json LICENSE $out/
    '';
    meta.license = lib.licenses.gpl3Only;
  };

  # What the Assistant's install script puts in ~/.config and ~/.local/share: default
  # settings, the bundled abilities, and the browser and search assets.
  setup = writeShellScript "nyx-assistant-setup" ''
    set -eu
    out=@out@
    config=''${XDG_CONFIG_HOME:-$HOME/.config}/nyx-assistant
    data=''${XDG_DATA_HOME:-$HOME/.local/share}/nyx-assistant
    ${coreutils}/bin/mkdir -p "$config" "$data/search"
    for name in config apps commands voxtype-parakeet; do
      [ -e "$config/$name.toml" ] || ${coreutils}/bin/install -m 0644 "$out/share/nyx-assistant/config/$name.toml" "$config/$name.toml"
    done
    for link in browser search/duckduckgo; do
      if [ -L "$data/$link" ] || [ ! -e "$data/$link" ]; then
        ${coreutils}/bin/ln -sfn "$out/share/nyx-assistant/$link" "$data/$link"
      fi
    done
    "$out/bin/nyx-assistant" migrate
    "$out/bin/nyx-assistant" persona >/dev/null
    "$out/bin/nyx-assistant" plugins migrate "$out/share/nyx-assistant"
  '';
in
nyx.buildApp {
  pname = "nyx-assistant";
  inherit src;
  cargoRoot = "apps/assistant";
  buildAndTestSubdir = "apps/assistant";
  cargoLock = {
    lockFile = "${app}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };
  cargoBuildFlags =
    lib.concatMap
      (p: [
        "-p"
        p
      ])
      [
        "nyx-assistantd"
        "assistant-tui"
        "assistant-plugin-worker"
        "assistant-asr"
        "assistant-visual"
      ];
  # The tests the repository's CI runs.
  cargoTestFlags = [
    "-p"
    "assistant-core"
    "-p"
    "assistant-policy"
    "--lib"
  ];
  # Expects LM Studio models on the machine running the tests.
  checkFlags = [ "--skip=config::tests::scans_local_models_finds_ggufs" ];

  # llama.cpp builds with CMake inside its crate; bindgen makes the llama.cpp, sherpa-onnx
  # and PipeWire bindings.
  nativeBuildInputs = [
    cmake
    nyx.rustPlatform.bindgenHook
  ];
  dontUseCmakeConfigure = true;
  buildInputs = [
    onnxruntime
    nyx.sherpa-onnx_1_13_8
    gtk4-layer-shell
    nyx.libshumate_1_7
    pipewire
    wayland
    fontconfig
    freetype
    poppler
    # libmpv and EGL for nyx-design's nyx-playback in the Canvas.
    mpv-unwrapped
    libGL
  ];
  # ort and sherpa-onnx link nixpkgs' ONNX Runtime and the sherpa-onnx build instead of
  # downloading their own. nixpkgs has no static ONNX Runtime, so sherpa-onnx links shared.
  env = {
    ORT_LIB_LOCATION = "${lib.getLib onnxruntime}/lib";
    ORT_PREFER_DYNAMIC_LINK = "1";
    SHERPA_ONNX_LIB_DIR = "${nyx.sherpa-onnx_1_13_8}/lib";
  };
  postPatch = ''
    substituteInPlace apps/assistant/crates/assistant-asr/Cargo.toml --replace-fail \
      'sherpa-onnx = "=1.13.8"' \
      'sherpa-onnx = { version = "=1.13.8", default-features = false, features = ["shared"] }'
    for unit in apps/assistant/systemd/*.service; do
      substituteInPlace "$unit" \
        --replace-quiet '/usr/bin/qs' '${quickshell}/bin/qs' \
        --replace-quiet '%h/.local/share/nyx-assistant/quickshell' "$out/share/nyx-assistant/quickshell" \
        --replace-quiet 'PATH=%h/.local/bin:/usr/local/bin:/usr/bin' "PATH=$out/bin:/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin" \
        --replace-quiet '/usr/bin/mkdir' '${coreutils}/bin/mkdir' \
        --replace-quiet '/bin/kill' '${coreutils}/bin/kill'
    done
  '';
  userUnits = map (unit: "apps/assistant/systemd/${unit}.service") [
    "nyx-assistantd"
    "nyx-assistant-hud"
    "nyx-assistant-visual"
    "nyx-assistant-stt"
    "nyx-assistant-failed"
    "nyx-assistant-stt-failed"
  ];
  # Not started with the session: like the install script, the daemon waits until it is
  # enabled, as it needs a downloaded model.
  passthru = { inherit browser search; };

  # voxtype with ONNX Runtime has the Parakeet engine the speech service uses.
  # pactl, wpctl and pw-link for audio; wtype types dictation; bwrap and xdg-dbus-proxy
  # sandbox plugins and generated commands; tesseract and grim read the screen; voxtype
  # is F9 dictation and the fallback speech recognizer.
  runtimeInputs = [
    python3
    pulseaudio
    wireplumber
    pipewire
    libnotify
    git
    wtype
    procps
    curl
    bubblewrap
    xdg-dbus-proxy
    unzip
    util-linux
    tesseract
    gnutar
    grim
    glib
    bluez
    ripgrep
    jq
    (voxtype.override { onnxSupport = true; })
    quickshell
  ];
  preFixup = ''
    gappsWrapperArgs+=(--set-default ASSISTANT_BROWSER_EXECUTABLE ${lib.getExe chromium})
  '';
  postInstall = ''
    share=$out/share/nyx-assistant
    mkdir -p $share/search
    cp -r ${app}/abilities ${app}/plugin-sdk ${app}/quickshell ${app}/config $share/
    chmod -R u+w $share
    substituteInPlace $share/quickshell/shell.qml \
      --replace-fail '(Quickshell.env("HOME") || "") + "/.local/bin/nyx-assistant"' "\"$out/bin/nyx-assistant\""
    ln -s ${browser} $share/browser
    ln -s ${search} $share/search/duckduckgo
    ln -s ${lib.getExe nodejs} $out/bin/nyx-assistant-node
    install -Dm755 ${setup} $out/libexec/nyx-assistant-setup
    substituteInPlace $out/libexec/nyx-assistant-setup --replace-fail @out@ $out
  '';

  meta = {
    description = "Local voice assistant with desktop control, plugins and a Quickshell HUD";
    homepage = "https://github.com/design-nexus/nyx-assistant";
    mainProgram = "nyx-assistant";
  };
}
