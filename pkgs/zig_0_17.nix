# Zig 0.17, which libghostty-vt 1.0 needs (nixpkgs 26.05 stops at 0.16). The official
# x86_64-linux release is a static binary; it finds its standard library beside its
# real path, so both stay together in share/zig.
{
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation rec {
  pname = "zig";
  version = "0.17.0";
  src = fetchurl {
    url = "https://ziglang.org/download/${version}/zig-x86_64-linux-${version}.tar.xz";
    sha256 = "1cbe9df9f27e6b78d14ccbca43b6703a404ef79ef1c463de901d7f088d4e2026";
  };
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;
  installPhase = ''
    mkdir -p $out/share/zig $out/bin
    cp -r zig lib $out/share/zig/
    ln -s $out/share/zig/zig $out/bin/zig
  '';
  meta = {
    description = "The Zig compiler, release ${version}";
    homepage = "https://ziglang.org";
    platforms = [ "x86_64-linux" ];
    mainProgram = "zig";
  };
}
