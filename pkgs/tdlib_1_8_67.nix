# TDLib 1.8.67 for Nyx Pulse, which uses that version's typed input objects; nixpkgs
# 26.05 has 1.8.63. TDLib has no tags for minor versions, so this is the commit that
# set the version. Drop this once nixpkgs ships 1.8.67 or later.
{
  tdlib,
  fetchFromGitHub,
}:
tdlib.overrideAttrs {
  version = "1.8.67";
  src = fetchFromGitHub {
    owner = "tdlib";
    repo = "td";
    rev = "bc9c263e2bfee06aaab41e82db51a103376030bc";
    hash = "sha256-1MreABa9ydLAmyVhzD7QZlZ4uYYkBjM3lsh8yRBvPn0=";
  };
  # Some TDLib sources take several GB each to compile.
  preBuild = ''
    export NIX_BUILD_CORES=1
  '';
}
