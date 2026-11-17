# TDLib 1.8.70 for Nyx Pulse, which uses its typed input objects (1.8.67 and later) and
# its names (areaPosition); nixpkgs 26.05 has 1.8.63. TDLib has no tags for minor versions, so this is the commit that
# set the version. Drop this once nixpkgs ships 1.8.70 or later.
{
  tdlib,
  fetchFromGitHub,
}:
tdlib.overrideAttrs {
  version = "1.8.70";
  src = fetchFromGitHub {
    owner = "tdlib";
    repo = "td";
    rev = "23383aef218a3123f02b744bfa91bde21056a814";
    hash = "sha256-4wR09InBx8eP7zVzvx6UXI4MGWfA9/7/H+ftKLy/xm4=";
  };
  # Some TDLib sources take several GB each to compile.
  preBuild = ''
    export NIX_BUILD_CORES=1
  '';
}
