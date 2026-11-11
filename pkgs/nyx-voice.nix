# Nyx Voice: nyx-voiced (dictation, listening and speaking for Nyx apps), the nyx-voice
# command, the streaming speech recognizer worker the Assistant listens with
# (nyx-voice-asr), and the user socket that starts the service on first use. Models
# download at runtime (`nyx-voice models fetch asr`).
{
  lib,
  nyx,
  src,
  pkg-config,
  makeWrapper,
  onnxruntime,
  pipewire,
  wtype,
  wl-clipboard,
  playerctl,
  pulseaudio,
  curl,
  gnutar,
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
  # The workspace's tests; the recognizer's end-to-end test needs a model and is ignored.
  cargoTestFlags = [ "--workspace" ];
  nativeBuildInputs = [
    pkg-config
    makeWrapper
    nyx.rustPlatform.bindgenHook
  ];
  buildInputs = [
    onnxruntime
    nyx.sherpa-onnx_1_13_8
    pipewire
  ];
  # ort and sherpa-onnx link nixpkgs' ONNX Runtime and the sherpa-onnx build instead of
  # downloading their own. nixpkgs has no static ONNX Runtime, so sherpa-onnx links shared.
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
  # wtype and wl-copy type and paste dictation, playerctl pauses media while it listens,
  # pactl and pw-link find and duck audio devices, curl and tar fetch models.
  postInstall = ''
    for program in nyx-voiced nyx-voice; do
      wrapProgram $out/bin/$program --prefix PATH : ${
        lib.makeBinPath [
          wtype
          wl-clipboard
          playerctl
          pulseaudio
          pipewire
          curl
          gnutar
        ]
      }
    done
  '';
  meta = {
    description = "Nyx Voice: dictation, listening and speaking for Nyx apps";
    homepage = "https://github.com/design-nexus/nyx-voice";
    mainProgram = "nyx-voice";
  };
}
