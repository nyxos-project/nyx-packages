{
  nyx,
  src,
  glib-networking,
}:
nyx.buildApp {
  pname = "nyx-maps";
  inherit src;
  # libshumate fetches tiles through libsoup, which needs glib-networking for HTTPS:
  # without it every tile fails and the map stays blank.
  buildInputs = [
    nyx.libshumate_1_7
    glib-networking
  ];
  # Asks GeoClue (or the network) for a live location; the build sandbox has neither.
  checkFlags = [ "--skip=location::geoclue::tests::test_request_current_location" ];
  meta = {
    description = "Lightweight native desktop maps";
    homepage = "https://github.com/design-nexus/nyx-maps";
    mainProgram = "nyx-maps";
  };
}
