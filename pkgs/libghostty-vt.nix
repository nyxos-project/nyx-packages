# libghostty-vt 1.0: Ghostty's terminal emulation as a static library, which Nyx Agents'
# terminal views are built on. Built offline from the release's source and dependency
# tarballs (their SHA256SUMS are in nyx-agents/vendor/libghostty-vt), starting from an
# empty Zig cache, as Ghostty's packaging notes require for Zig 0.17.
{
  stdenv,
  fetchurl,
  zig,
}:
let
  version = "1.0.0";
  release = "https://release.files.ghostty.org/libghostty-vt/${version}";
in
stdenv.mkDerivation {
  pname = "libghostty-vt";
  inherit version;
  src = fetchurl {
    url = "${release}/libghostty-vt-${version}.tar.gz";
    sha256 = "4a6ef758be721923e1969e7b81b443dcc92d8dd3fb5a39600c03a8817a753676";
  };
  deps = fetchurl {
    url = "${release}/libghostty-vt-${version}-deps.tar.gz";
    sha256 = "4d5ea5e448e4c7ea8fb55ccbaa8668f2a97d44f438cee831e2b7ecd162d85c29";
  };
  nativeBuildInputs = [ zig ];
  sourceRoot = "libghostty-vt-${version}";
  postUnpack = ''
    tar -xzf $deps
  '';
  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-global-cache
    zig build --prefix $out --system ../libghostty-vt-${version}-deps \
      -Doptimize=ReleaseFast -Dcpu=baseline
    runHook postBuild
  '';
  dontInstall = true;
  meta = {
    description = "Ghostty's terminal emulation library (static), with its C headers";
    homepage = "https://ghostty.org";
    platforms = [ "x86_64-linux" ];
  };
}
