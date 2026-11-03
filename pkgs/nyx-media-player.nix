{
  nyx,
  src,
  mpv-unwrapped,
  libGL,
  ffmpeg,
  yt-dlp,
  libnotify,
  xdg-utils,
}:
nyx.buildApp {
  pname = "nyx-media-player";
  inherit src;
  # libmpv and EGL for nyx-design's nyx-playback.
  buildInputs = [
    mpv-unwrapped
    libGL
  ];
  # ffmpeg and ffprobe for scrub previews; yt-dlp for online links.
  runtimeInputs = [
    ffmpeg
    yt-dlp
    libnotify
    xdg-utils
  ];
  meta = {
    description = "Video player with a local movie and TV library, resume and mpv playback";
    homepage = "https://github.com/design-nexus/nyx-media-player";
    mainProgram = "nyx-media-player";
  };
}
