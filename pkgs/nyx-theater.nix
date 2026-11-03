{
  nyx,
  src,
  mpv-unwrapped,
  libGL,
  libsecret,
}:
nyx.buildApp {
  pname = "nyx-theater";
  inherit src;
  # libmpv and EGL for nyx-design's nyx-playback.
  buildInputs = [
    mpv-unwrapped
    libGL
  ];
  # secret-tool keeps Plex and Jellyfin tokens.
  runtimeInputs = [ libsecret ];
  meta = {
    description = "Browse and play Plex and Jellyfin movies and shows in one window";
    homepage = "https://github.com/design-nexus/nyx-theater";
    mainProgram = "nyx-theater";
  };
}
