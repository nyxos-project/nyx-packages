# Also ships nyx-news-glimpse, the Glimpse search plugin.
{ nyx, src }:
nyx.buildApp {
  pname = "nyx-news";
  inherit src;
  glimpsePlugin = true;
  meta = {
    description = "Local news reader for RSS, Atom and JSON feeds";
    homepage = "https://github.com/design-nexus/nyx-news";
    mainProgram = "nyx-news";
  };
}
