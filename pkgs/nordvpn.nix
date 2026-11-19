# NordVPN's own Linux app (unfree): the `nordvpn` command and the `nordvpnd` daemon from
# Nord's .deb, as on Arch, so NordLynx, server search, the fastest server and the rest
# work as Nord ships them. Built with the system's nixpkgs (modules/nixos/nordvpn.nix),
# where accepting its licence applies.
#
# The daemon looks for its helpers in /usr/lib/nordvpn and its data in /var/lib/nordvpn,
# and runs nft, ip, resolvectl, sysctl, nmcli and xsltproc, so it runs in an FHS
# environment that has them; the command only talks to the daemon's socket.
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  buildFHSEnv,
  sqlite,
  libnl,
  libcap_ng,
  libidn2,
  zlib,
  iproute2,
  nftables,
  iptables,
  procps,
  systemd,
  networkmanager,
  libxslt,
  wireguard-tools,
  kmod,
  cacert,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "nordvpn";
  version = "6.0.2";
  src = fetchurl {
    url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/nordvpn_${finalAttrs.version}_amd64.deb";
    sha256 = "1qa3m7gai54lpwjhcc27kjn2mg72dgfj2llbs074xmccr83pkpw1";
  };
  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];
  buildInputs = [
    sqlite
    libnl
    libcap_ng
    libidn2
    zlib
    stdenv.cc.cc.lib
  ];
  unpackPhase = "dpkg-deb -x $src .";
  # The libraries are found next to the programs that use them.
  appendRunpaths = [ "${placeholder "out"}/lib/nordvpn" ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/lib $out/share $out/var/lib/nordvpn
    cp usr/bin/nordvpn usr/sbin/nordvpnd $out/bin/
    cp -r usr/lib/nordvpn $out/lib/
    cp -r usr/share/applications usr/share/icons usr/share/man $out/share/
    install -Dm644 usr/share/bash-completion/completions/nordvpn -t $out/share/bash-completion/completions
    install -Dm644 usr/share/zsh/functions/Completion/Unix/_nordvpn_auto_complete $out/share/zsh/site-functions/_nordvpn
    # Countries, servers and the OpenVPN template, which the daemon copies to and reads
    # from /var/lib/nordvpn/data.
    cp -r var/lib/nordvpn/data $out/var/lib/nordvpn/
    substituteInPlace $out/share/applications/nordvpn.desktop --replace-fail "Exec=nordvpn" "Exec=$out/bin/nordvpn"
    runHook postInstall
  '';
  # The daemon, with /usr/lib/nordvpn and the programs it runs.
  passthru.daemon = buildFHSEnv {
    name = "nordvpnd";
    targetPkgs = _: [
      finalAttrs.finalPackage
      sqlite
      libnl
      libcap_ng
      iproute2
      nftables
      iptables
      procps
      systemd
      networkmanager
      libxslt
      wireguard-tools
      kmod
      cacert
    ];
    runScript = "${finalAttrs.finalPackage}/bin/nordvpnd";
  };
  meta = {
    description = "NordVPN's app: the nordvpn command and its daemon";
    homepage = "https://nordvpn.com/download/linux/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "nordvpn";
  };
})
