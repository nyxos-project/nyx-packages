# Also ships nyx-notes-glimpse, the Glimpse search plugin.
{
  nyx,
  src,
  gtksourceview5,
}:
nyx.buildApp {
  pname = "nyx-notes";
  inherit src;
  glimpsePlugin = true;
  buildInputs = [ gtksourceview5 ];
  meta = {
    description = "Markdown writing and knowledge workspace";
    homepage = "https://github.com/design-nexus/nyx-notes";
    mainProgram = "nyx-notes";
  };
}
