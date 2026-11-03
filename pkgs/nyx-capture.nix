# Screenshots, recording, webcam and OCR, and the Glimpse plugin. Scrolling capture
# stays hidden: it runs Omarchy's omasnap.
{
  lib,
  nyx,
  src,
  onnxruntime,
  gtk4-layer-shell,
  openssl,
  grim,
  slurp,
  ffmpeg,
  wf-recorder,
  tesseract,
  v4l-utils,
  mpv,
  wl-clipboard,
  pulseaudio,
  xdg-utils,
}:
nyx.buildApp {
  pname = "nyx-capture";
  inherit src;
  buildInputs = [
    onnxruntime
    gtk4-layer-shell
    openssl
  ];
  # ort links nixpkgs' ONNX Runtime instead of downloading a build of its own.
  env = {
    ORT_LIB_LOCATION = "${lib.getLib onnxruntime}/lib";
    ORT_PREFER_DYNAMIC_LINK = "1";
  };
  # pactl lists audio sources for recording; v4l2-ctl the webcams.
  runtimeInputs = [
    grim
    slurp
    ffmpeg
    wf-recorder
    tesseract
    v4l-utils
    mpv
    wl-clipboard
    pulseaudio
    xdg-utils
  ];
  meta = {
    description = "Screenshots, annotation, OCR and screen recording with a searchable history";
    homepage = "https://github.com/design-nexus/nyx-capture";
    mainProgram = "nyx-capture";
  };
}
