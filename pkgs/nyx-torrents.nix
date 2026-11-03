{
  nyx,
  src,
  libtorrent-rasterbar,
  boost,
  openssl,
  python3,
  curl,
  xdg-utils,
  libnotify,
}:
nyx.buildApp {
  pname = "nyx-torrents";
  inherit src;
  # The engine is a C++ shim over libtorrent, built by build.rs through cxx;
  # libtorrent's headers include OpenSSL's.
  buildInputs = [
    libtorrent-rasterbar
    boost
    openssl
  ];
  # Search plugins are qBittorrent-style Python scripts.
  runtimeInputs = [
    python3
    curl
    xdg-utils
    libnotify
  ];
  meta = {
    description = "BitTorrent client on libtorrent, with magnets, search plugins and VPN binding";
    homepage = "https://github.com/design-nexus/nyx-torrents";
    mainProgram = "nyx-torrents";
  };
}
