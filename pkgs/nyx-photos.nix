# Also ships nyx-viewer, the single-image viewer. "Set as background" stays hidden:
# it runs Omarchy's omarchy-theme-bg-set, which NyxOS doesn't have.
{
  nyx,
  src,
  ffmpeg,
  ffmpegthumbnailer,
  xdg-utils,
}:
nyx.buildApp {
  pname = "nyx-photos";
  inherit src;
  # Video thumbnails and durations.
  runtimeInputs = [
    ffmpeg
    ffmpegthumbnailer
    xdg-utils
  ];
  meta = {
    description = "Keyboard-first photo gallery with a timeline and EXIF details";
    homepage = "https://github.com/design-nexus/nyx-photos";
    mainProgram = "nyx-photos";
  };
}
