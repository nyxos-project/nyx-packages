{ nyx, src }:
nyx.buildApp {
  pname = "nyx-calculator";
  inherit src;
  meta = {
    description = "Calculator with standard, scientific, programmer, graphing and scratchpad modes";
    homepage = "https://github.com/design-nexus/nyx-calculator";
    mainProgram = "nyx-calculator";
  };
}
