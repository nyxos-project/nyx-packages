# YouTube Music through its own web player in WebKitGTK 6, with a native window.
{
  nyx,
  src,
  webkitgtk_6_0,
  glib-networking,
  gst_all_1,
}:
nyx.buildApp {
  pname = "nyx-lyra";
  # Its action manifest (nyx lyra …, Glimpse, the Assistant): lib installActions.
  actions = [ "nyx-lyra" ];
  inherit src;
  # The probe is a development tool.
  cargoBuildFlags = [
    "-p"
    "nyx-lyra"
  ];
  # glib-networking gives WebKit TLS. WebKit plays YouTube Music's AAC and Opus streams
  # through GStreamer; wrapGAppsHook4 puts the plugin sets on GST_PLUGIN_SYSTEM_PATH_1_0,
  # which the web process inherits.
  buildInputs = [
    webkitgtk_6_0
    glib-networking
  ]
  ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-libav
  ]);
  meta = {
    description = "YouTube Music for NyxOS, through YouTube Music's own web player";
    homepage = "https://github.com/design-nexus/nyx-lyra";
    mainProgram = "nyx-lyra";
  };
}
