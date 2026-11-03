{
  nyx,
  src,
  poppler,
}:
nyx.buildApp {
  pname = "nyx-pdf";
  inherit src;
  buildInputs = [ poppler ];
  meta = {
    description = "PDF viewer that remembers your page and lets you annotate, fill, sign and rearrange";
    homepage = "https://github.com/design-nexus/nyx-pdf";
    mainProgram = "nyx-pdf";
  };
}
