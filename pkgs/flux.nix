# Flux's daemon and CLI, the backend of Nyx Connect, from upstream at the release tag
# flake.lock pins (see nyx/docs/desktop/CONNECT.md). Not built: the Qt window, the
# omarchy-shell plugin and the sudo approval helper; Nyx Settings and the Control
# Center show the devices on NyxOS.
{
  lib,
  buildGoModule,
  go_1_27,
  makeWrapper,
  coreutils,
  wl-clipboard,
  xdg-utils,
  src,
}:
let
  version = "0.19.1";
in
(buildGoModule.override { go = go_1_27; }) {
  pname = "flux";
  inherit version src;
  vendorHash = "sha256-ziP/NS+YCcakzYOcszxqCV5dWKD4upCUVB8Rf6YFf+Y=";
  # Without Omarchy: the theme it sends the phone is nyx-themed's
  # ($XDG_RUNTIME_DIR/nyx/theme/system.json), and Do Not Disturb sync talks to nyx-notifyd.
  patches = [ ./flux-nyxos.patch ];
  # NyxOS's defaults for a new config.toml: a paired phone doesn't browse the home folder
  # or get the clipboard until Settings › Devices turns them on, and fluxd updates with
  # the system, not from GitHub.
  postPatch = ''
    substituteInPlace internal/config/config.go --replace-fail \
      'c := &Config{AutoClipboard: true, Notifications: true, ShareHome: true, PauseMediaOnCall: true, SyncDnd: true, Herdr: true, CheckUpdates: true}' \
      'c := &Config{AutoClipboard: false, Notifications: true, ShareHome: false, PauseMediaOnCall: true, SyncDnd: true, Herdr: true, CheckUpdates: false}'
  '';
  subPackages = [
    "cmd/fluxd"
    "cmd/flux"
  ];
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];
  nativeBuildInputs = [ makeWrapper ];
  # Both test Arch's install: the pacman/AUR update script and the polkit helper's setuid
  # bit. NyxOS updates fluxd with the system and doesn't install the helper.
  checkFlags = [ "-skip=^(TestRootInstall|TestPolkitNeedsSetuidHelper)$" ];

  postInstall = ''
    # Upstream calls it flux-cli: fluxcd owns `flux`.
    mv $out/bin/flux $out/bin/flux-cli
    # fluxd copies and pastes with wl-clipboard and opens shared links with xdg-open.
    # It restarts itself when the file in argv[0] isn't the one running (an update);
    # the wrapper's own path never is, so it gets the real program's.
    wrapProgram $out/bin/fluxd --argv0 "$out/bin/.fluxd-wrapped" --prefix PATH : ${
      lib.makeBinPath [
        wl-clipboard
        xdg-utils
      ]
    }
    install -Dm644 dist/fluxd.service $out/lib/systemd/user/fluxd.service
    substituteInPlace $out/lib/systemd/user/fluxd.service \
      --replace-fail "@BINDIR@/fluxd" "$out/bin/fluxd" \
      --replace-fail "/bin/kill" "${coreutils}/bin/kill"
  '';

  passthru.autostart."fluxd" = "graphical-session.target";

  meta = {
    description = "Flux, the phone link: fluxd and flux-cli";
    homepage = "https://github.com/bjarneo/flux";
    license = lib.licenses.mit;
    mainProgram = "flux-cli";
    platforms = lib.platforms.linux;
  };
}
