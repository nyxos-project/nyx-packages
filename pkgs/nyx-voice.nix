# Nyx Voice: nyx-voiced (dictation, listening and speaking for the desktop), the
# nyx-voice command and the speech recognizer worker, with the user socket that starts
# the daemon on first use. Speech models download on request (`nyx-voice models fetch
# asr`), Kokoro's voices on first speech.
{
  lib,
  nyx,
  src,
  makeWrapper,
  onnxruntime,
  pipewire,
  wtype,
  wl-clipboard,
  playerctl,
  pulseaudio,
  curl,
  gnutar,
  bzip2,
}:
nyx.buildWorkspace {
  pname = "nyx-voice";
  inherit src;
  cargoBuildFlags = [
    "-p"
    "nyx-voiced"
    "-p"
    "nyx-voice"
    "-p"
    "nyx-voice-asr"
  ];
  # The workspace's tests; the recognizer's end-to-end test is ignored (real speech).
  cargoTestFlags = [ "--workspace" ];
  nativeBuildInputs = [
    makeWrapper
    nyx.rustPlatform.bindgenHook
  ];
  buildInputs = [
    onnxruntime
    nyx.sherpa-onnx_1_13_8
    pipewire
  ];
  # ort and sherpa-onnx link nixpkgs' ONNX Runtime and the sherpa-onnx build instead of
  # downloading their own, as the Assistant's package does.
  env = {
    ORT_LIB_LOCATION = "${lib.getLib onnxruntime}/lib";
    ORT_PREFER_DYNAMIC_LINK = "1";
    SHERPA_ONNX_LIB_DIR = "${nyx.sherpa-onnx_1_13_8}/lib";
  };
  postPatch = ''
    substituteInPlace apps/nyx-voice-asr/Cargo.toml --replace-fail \
      'sherpa-onnx = "=1.13.8"' \
      'sherpa-onnx = { version = "=1.13.8", default-features = false, features = ["shared"] }'
  '';
  userUnits = [
    "data/nyx-voiced.service"
    "data/nyx-voiced.socket"
  ];
  # Dictation types with wtype (or copies with wl-copy), pauses media with playerctl and
  # lists devices with pactl; models download with curl and tar.
  postInstall = ''
    wrapProgram $out/bin/nyx-voiced --prefix PATH : ${
      lib.makeBinPath [
        wtype
        wl-clipboard
        playerctl
        pulseaudio
      ]
    }
    wrapProgram $out/bin/nyx-voice --prefix PATH : ${
      lib.makeBinPath [
        curl
        gnutar
        bzip2
      ]
    }
  '';
  meta = {
    description = "Nyx Voice: local dictation, listening and speaking for the Nyx desktop";
    homepage = "https://github.com/design-nexus/nyx-voice";
    mainProgram = "nyx-voice";
  };
}
