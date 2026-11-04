# Telegram client and its Glimpse plugin. TDLib 1.8.67 and NTgCalls load at runtime;
# Mini Apps and hardware passkeys run in a separate GTK 3 and WebKitGTK 4.1 Python.
{
  lib,
  stdenv,
  nyx,
  src,
  python3,
  gobject-introspection,
  wrapGAppsHook3,
  gtk3,
  webkitgtk_4_1,
  glib-networking,
  libfido2,
  mpv-unwrapped,
  libGL,
  tlottie,
  gst_all_1,
  pipewire,
  ffmpeg,
  pulseaudio,
  libcanberra-gtk3,
  libsecret,
  coreutils,
  gtk4,
  makeFontsConf,
}:
let
  # The helpers load libfido2 with ctypes, so it goes on the library path.
  helperPython = stdenv.mkDerivation {
    name = "nyx-pulse-python";
    dontUnpack = true;
    nativeBuildInputs = [
      gobject-introspection
      wrapGAppsHook3
    ];
    buildInputs = [
      gtk3
      webkitgtk_4_1
      glib-networking
    ];
    dontWrapGApps = true;
    installPhase = "mkdir -p $out/bin";
    preFixup = ''
      makeWrapper ${python3.withPackages (ps: [ ps.pygobject3 ])}/bin/python3 $out/bin/python3 \
        "''${gappsWrapperArgs[@]}" --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libfido2 ]}
    '';
  };
in
nyx.buildApp {
  pname = "nyx-pulse";
  inherit src;
  # bindgen generates the NTgCalls bindings.
  nativeBuildInputs = [ nyx.rustPlatform.bindgenHook ];
  # libmpv and EGL for nyx-design's nyx-playback; GStreamer and its PipeWire source
  # capture the screen for video calls.
  buildInputs = [
    mpv-unwrapped
    libGL
    tlottie
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    pipewire
  ];
  env.PULSE_PYTHON = "${helperPython}/bin/python3";
  # The call engine's tests load NTgCalls from where build.rs expects it.
  postPatch = ''
    mkdir -p target/native/ntgcalls/lib
    ln -s ${nyx.ntgcalls}/lib/libntgcalls.so target/native/ntgcalls/lib/
  '';
  # The chat view test renders on a Broadway display; the sticker test makes a clip
  # with ffmpeg.
  nativeCheckInputs = [ ffmpeg ];
  # Connects two call peers over WebRTC, which won't use the sandbox's loopback-only
  # network. It passes outside the sandbox.
  checkFlags = [ "--skip=engine::transport_regression::local_signaling_loopback" ];
  preCheck = nyx.privateBusPreCheck + ''
    export TDLIB_PATH=${nyx.tdlib_1_8_67}/lib/libtdjson.so
    export XDG_RUNTIME_DIR=$TMPDIR GDK_BACKEND=broadway BROADWAY_DISPLAY=:5
    export FONTCONFIG_FILE=${makeFontsConf { fontDirectories = [ ]; }}
    ${gtk4}/bin/gtk4-broadwayd :5 &
    for _ in $(seq 50); do
      ls "$XDG_RUNTIME_DIR"/broadway*.socket >/dev/null 2>&1 && break
      sleep 0.1
    done
  '';
  # pactl lists microphones; canberra-gtk-play plays message and call sounds;
  # secret-tool keeps the database key.
  runtimeInputs = [
    ffmpeg
    gst_all_1.gstreamer
    pulseaudio
    libcanberra-gtk3
    libsecret
    coreutils
  ];
  preFixup = ''
    gappsWrapperArgs+=(--set-default TDLIB_PATH ${nyx.tdlib_1_8_67}/lib/libtdjson.so)
  '';
  # Pulse looks for NTgCalls next to its binary, in ../share/nyx/lib.
  postInstall = ''
    mkdir -p $out/share/nyx/lib
    ln -s ${nyx.ntgcalls}/lib/libntgcalls.so $out/share/nyx/lib/
  '';
  meta = {
    description = "Native Telegram client with calls, stories, Mini Apps and business tools";
    homepage = "https://github.com/design-nexus/nyx-pulse";
    mainProgram = "nyx-pulse";
  };
}
