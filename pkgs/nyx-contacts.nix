{ nyx, src }:
nyx.buildApp {
  pname = "nyx-contacts";
  inherit src;
  buildInputs = nyx.pimInputs;
  meta = {
    description = "Address book with lists, birthdays, duplicates and online account books";
    homepage = "https://github.com/design-nexus/nyx-contacts";
    mainProgram = "nyx-contacts";
  };
}
