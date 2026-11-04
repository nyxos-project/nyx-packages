# NTgCalls 3.0.5, the WebRTC call engine Nyx Pulse loads at runtime. This is the
# upstream release build Pulse pins: building it means building WebRTC, and it only
# links glibc, zlib and libstdc++.
{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  zlib,
}:
stdenv.mkDerivation {
  pname = "ntgcalls";
  version = "3.0.5";
  src = fetchurl {
    url = "https://github.com/pytgcalls/ntgcalls/releases/download/v3.0.5/ntgcalls.linux-x86_64-shared_libs.zip";
    hash = "sha256-pkMNlo2ytcJzeE7eC4wy8SpVuokVHT0hfJOWOX6hvrM=";
  };
  sourceRoot = ".";
  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];
  buildInputs = [
    zlib
    stdenv.cc.cc.lib
  ];
  installPhase = ''
    install -Dm755 lib/libntgcalls.so -t $out/lib
    install -Dm644 include/ntgcalls.h -t $out/include
    install -Dm644 LICENSE THIRD_PARTY_NOTICES.md -t $out/share/licenses/ntgcalls
  '';
  meta = {
    description = "WebRTC call engine for Telegram clients";
    homepage = "https://github.com/pytgcalls/ntgcalls";
    license = lib.licenses.lgpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}
