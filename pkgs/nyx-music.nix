{
  nyx,
  src,
  gst_all_1,
  libnotify,
  xdg-utils,
}:
nyx.buildApp {
  pname = "nyx-music";
  inherit src;
  # Playback goes through playbin, so the plugin sets decide which formats play;
  # wrapGAppsHook4 puts them on GST_PLUGIN_SYSTEM_PATH_1_0.
  buildInputs = with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ];
  runtimeInputs = [
    libnotify
    xdg-utils
  ];
  meta = {
    description = "Music player with a local library and a live spectrum";
    homepage = "https://github.com/design-nexus/nyx-music";
    mainProgram = "nyx-music";
  };
}
