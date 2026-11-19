{ config, lib, pkgs, ... }:
let
  biometrics = config.nyx.biometrics;
  bio = config.nyx.packages.nyx-biometrics;
  shell = config.nyx.packages.nyx-shell;
  methods = biometrics.surfaces.sudo or [ ];
  sudoFace = lib.elem "face" methods;
  polkitFace = config.nyx.prompt.enable && lib.elem "face" (biometrics.surfaces.polkit or [ ]);
  pam = config.security.pam.services.sudo.rules;
  firstAuth = lib.min pam.auth.unix.order (pam.auth.unix-early.order or pam.auth.unix.order);
  # Insert the two notifications around face while keeping each method in its configured order.
  methodRules = lib.listToAttrs (lib.concatLists (lib.imap0 (index: method:
    let
      face = method == "face";
      start = firstAuth - 100 + 4 * index;
    in [
      (lib.nameValuePair "nyx-gate-${method}" {
        order = lib.mkForce start;
        control = lib.mkIf face (lib.mkForce "[success=3 default=ignore]");
      })
      (lib.nameValuePair "nyx-${method}" {
        order = lib.mkForce (start + (if face then 2 else 1));
      })
    ] ++ lib.optionals face [
      (lib.nameValuePair "nyx-face-overlay-start" (notification (start + 1) [ "start" "face" ]))
      (lib.nameValuePair "nyx-face-overlay-failed" (notification (start + 3) [ "failed" "face" ]))
    ]
  ) methods));
  notification = order: args: {
    inherit order;
    control = "optional";
    modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
    args = [ "quiet" "${bio}/lib/nyx-biometrics/nyx-auth-notify" ] ++ args;
  };
  overlay = pkgs.runCommand "nyx-auth-overlay" { } ''
    component="$out/share/nyx-shell/components/nyx-auth-overlay"
    mkdir -p "$component"
    install -m 0644 ${bio.src}/shell/common/AuthOverlay.qml "$component/"
    substitute ${bio.src}/shell/design-nexus.auth-prompt/Service.qml "$component/Main.qml" \
      --replace-fail 'import qs.Commons as Commons' 'import Nyx.Shell' \
      --replace-fail 'import qs.Commons' "" \
      --replace-fail 'import qs.Ui' "" \
      --replace-fail 'ShellIpc {' 'IpcHandler {' \
      --replace-fail 'Commons.Color.lock.borderActive' 'Theme.accent' \
      --replace-fail 'Commons.Color.lock.background' 'Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.8)' \
      --replace-fail 'Commons.Color.lock.textError' 'Theme.danger' \
      --replace-fail 'Commons.Color.lock.text' 'Theme.text' \
      --replace-fail 'Commons.Color.lock.placeholder' 'Theme.dimText'
    substituteInPlace "$component/Main.qml" \
      --replace-fail 'if (event === "start")' 'if (event === "clear" && root.service === service) {
        root.settle("idle", 0)
      } else if (event === "start")' \
      --replace-fail 'root.phase === "scanning")' 'root.phase === "scanning" && root.service === service)' \
      --replace-fail 'readonly property bool edge: root.overlayStyle === "edge"' 'readonly property bool edge: root.service !== "polkit" && root.overlayStyle === "edge"' \
      --replace-fail 'style: root.overlayStyle' 'style: root.service === "polkit" ? "halo" : root.overlayStyle' \
      --replace-fail 'root.overlayStyle === "minimal" ?' 'style === "minimal" ?' \
      --replace-fail 'root.overlayStyle === "halo" ?' 'style === "halo" ?' \
      --replace-fail 'y: edge ? 0 : Math.round(parent.height * 0.18)' 'y: edge ? 0 : root.service === "polkit" ? (parent.height - height) / 2 : Math.round(parent.height * 0.18)' \
      --replace-fail '"Terminal sign-in · face"' '(root.service === "polkit" ? "Administrator approval · face" : "Terminal sign-in · face")'
  '';
in
lib.mkIf (biometrics.enable && (sudoFace || polkitFace) && config.nyx.shell.enable) {
  environment.systemPackages = [ overlay ];
  environment.etc."nyx/auth-overlay/quickshell".source = "${pkgs.quickshell}/bin/qs";
  environment.etc."nyx/auth-overlay/shell.qml".source = "${shell}/share/nyx-shell/qml/shell.qml";

  environment.etc."nyx/auth-overlay/polkit-face" = lib.mkIf polkitFace { text = "face\n"; };

  security.pam.services.sudo.rules = lib.mkIf sudoFace {
    auth = methodRules;
    session.nyx-face-overlay-done = notification (pam.session.unix.order + 1) [ "done" "any" ];
  };
}
