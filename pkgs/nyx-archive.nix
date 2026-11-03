{
  nyx,
  src,
  _7zz,
}:
nyx.buildApp {
  pname = "nyx-archive";
  inherit src;
  runtimeInputs = [ _7zz ];
  meta = {
    description = "Browse, extract and compress 7z, zip, tar, rar and other archives";
    homepage = "https://github.com/design-nexus/nyx-archive";
    mainProgram = "nyx-archive";
  };
}
