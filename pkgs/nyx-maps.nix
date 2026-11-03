{ nyx, src }:
nyx.buildApp {
  pname = "nyx-maps";
  inherit src;
  buildInputs = [ nyx.libshumate_1_7 ];
  # Asks GeoClue (or the network) for a live location; the build sandbox has neither.
  checkFlags = [ "--skip=location::geoclue::tests::test_request_current_location" ];
  meta = {
    description = "Lightweight native desktop maps";
    homepage = "https://github.com/design-nexus/nyx-maps";
    mainProgram = "nyx-maps";
  };
}
