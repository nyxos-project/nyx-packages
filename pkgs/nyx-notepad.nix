{ nyx, src }:
nyx.buildApp {
  pname = "nyx-notepad";
  inherit src;
  meta = {
    description = "Tabbed plain-text notepad";
    homepage = "https://github.com/design-nexus/nyx-notepad";
    mainProgram = "nyx-notepad";
  };
}
