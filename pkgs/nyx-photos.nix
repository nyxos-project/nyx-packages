# Also ships nyx-viewer, the single-image viewer. "Set as background" goes through
# the Nyx Theme Engine (SetWallpaper) on NyxOS.
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
