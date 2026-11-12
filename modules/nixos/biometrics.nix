# Nyx Biometrics on NixOS. The broker, key service and nyx-authctl come from the
# package; the PAM stacks the root helper writes into /etc/pam.d on Arch are built here
# from `nyx.biometrics.surfaces` instead, as the same lines: for each method, in the
# order given, the Nyx gate (`pam_exec nyx-auth-gate`, which exits 0 to skip the next
# line for remote sessions, inactive seats and a closed lid) and then the method as
# `sufficient`, all ahead of the password, which always stays.
self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nyx.biometrics;
  bio = self.packages.${pkgs.stdenv.hostPlatform.system}.nyx-biometrics;
  gate = "${bio}/lib/nyx-biometrics/nyx-auth-gate";

  # Nyx surfaces and the PAM services that enforce them.
  services = {
    login = [
      "greetd"
      "login"
    ];
    sudo = [ "sudo" ];
    polkit = [ "polkit-1" ];
    # Nyx Locker runs each method as its own service at once (lockServices).
    lock = [ ];
  };

  # The lock screen's per-method services: the gate and the method, nothing else. The
  # method's own result is the service's, so Nyx Locker can tell a finger it didn't
  # recognise (auth_err) from no reader (authinfo_unavail). A method the gate skips
  # lands on `false`, which pam_exec reports as system_err (unavailable), instead of
  # NixOS's closing pam_deny (auth_err, "not recognised").
  lockService = {
    face = "nyx-lock-face";
    fingerprint = "nyx-lock-fingerprint";
    security-key = "nyx-lock-key";
  };
  lockServices = lib.listToAttrs (
    map (name: {
      name = lockService.${name};
      value = {
        unixAuth = false;
        fprintAuth = false;
        u2fAuth = false;
        rules.auth = {
          nyx-gate = {
            order = 100;
            control = "[success=1 default=ignore]";
            modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
            args = [
              "quiet"
              gate
              (method "lock" name).kind
            ];
          };
          "nyx-${name}" = {
            order = 101;
            control = "[success=done ignore=ignore default=die]";
            inherit (method "lock" name) modulePath args;
          };
          "nyx-${name}-skipped" = {
            order = 102;
            control = "requisite";
            modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
            args = [
              "quiet"
              "${pkgs.coreutils}/bin/false"
            ];
          };
        };
      };
    }) (cfg.surfaces.lock or [ ])
  );

  faceModule =
    if cfg.face == "irlume" then
      "${config.services.irlume.package}/lib/security/pam_irlume.so"
    else
      "${config.services.gaze.package}/lib/security/pam_gaze.so";

  # The method's PAM line on a surface, as nyx-auth-pam generates it on Arch.
  method =
    surface: name:
    {
      face = {
        kind = "built-in";
        modulePath = faceModule;
        # At login Irlume waits for an empty answer before it scans.
        args = lib.optional (surface == "login" && cfg.face == "irlume") "ondemand";
      };
      fingerprint = {
        kind = "built-in";
        modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
        args = [
          "max-tries=2"
          "timeout=30"
        ];
      };
      security-key = {
        kind = "local";
        modulePath = "${pkgs.pam_u2f}/lib/security/pam_u2f.so";
        args = [
          "cue"
          "authfile=/etc/nyx-biometrics/u2f_keys"
        ]
        ++ lib.optional (cfg.securityKey.check == "verified") "pinverification=1";
      };
    }
    .${name};

  surfaceOf =
    service: lib.findFirst (s: lib.elem service services.${s}) null (lib.attrNames cfg.surfaces);

  # Gate and method rules for one PAM service, just ahead of pam_unix, and of the early
  # optional pam_unix NixOS adds to hand the password to the keyring, which would
  # otherwise ask for the password first.
  rulesFor =
    pamConfig: surface:
    let
      auth = pamConfig.rules.auth;
      first = lib.min auth.unix.order (auth.unix-early.order or auth.unix.order);
      start = first - 100;
    in
    lib.listToAttrs (
      lib.concatLists (
        lib.imap0 (
          i: name:
          let
            m = method surface name;
          in
          [
            {
              name = "nyx-gate-${name}";
              value = {
                order = start + 2 * i;
                control = "[success=1 default=ignore]";
                modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
                args = [
                  "quiet"
                  gate
                  m.kind
                ];
              };
            }
            {
              name = "nyx-${name}";
              value = {
                order = start + 2 * i + 1;
                control = "sufficient";
                inherit (m) modulePath args;
              };
            }
          ]
        ) cfg.surfaces.${surface}
      )
    );

  usedMethods = lib.unique (lib.concatLists (lib.attrValues cfg.surfaces));
in
{
  imports = [
    self.inputs.irlume.nixosModules.irlume
    self.inputs.gaze.nixosModules.gaze
  ];

  options.nyx.biometrics = {
    enable = lib.mkEnableOption ''
      Nyx Biometrics: the sign-in broker Nyx apps confirm the person with, the TPM key
      service for Nyx Passwords, nyx-authctl, and the root helper for security keys
    '';
    face = lib.mkOption {
      type = lib.types.enum [
        "none"
        "irlume"
        "gaze"
      ];
      default = "none";
      description = ''
        Face sign-in: Irlume for infrared (Windows Hello) cameras, Gaze for ordinary
        webcams. A webcam match only shows someone is present (a photo can pass), so
        Gaze works only on the lock screen, and only with `allowWebcamFace`.
      '';
    };
    allowWebcamFace = lib.mkEnableOption ''
      Gaze (an ordinary webcam) on the lock screen. A photo of you can unlock it; Gaze
      never signs in, runs sudo or approves administrator prompts
    '';
    fingerprint.enable = lib.mkEnableOption "fingerprint sign-in through fprintd";
    securityKey = {
      enable = lib.mkEnableOption "security-key sign-in through pam_u2f (keys registered with nyx-authctl keys add)";
      check = lib.mkOption {
        type = lib.types.enum [
          "touch"
          "verified"
        ];
        default = "touch";
        description = "`verified` also needs the key's PIN or its own fingerprint sensor.";
      };
    };
    surfaces = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.listOf (
          lib.types.enum [
            "face"
            "fingerprint"
            "security-key"
          ]
        )
      );
      default = { };
      example = {
        sudo = [
          "face"
          "fingerprint"
        ];
        polkit = [ "fingerprint" ];
      };
      description = ''
        Methods tried before the password, in order, on each surface: `login` (the
        greeter and the console), `sudo` and `polkit` (administrator prompts); and
        `lock`, the methods Nyx Locker runs beside the password. The password always
        works.
      '';
    };
  };

  # The Nyx rules, ahead of pam_unix, on the services of the surfaces that use them.
  options.security.pam.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }:
        let
          surface = surfaceOf name;
        in
        {
          # The Nyx rules take the place of NixOS's own fingerprint and key lines, which
          # fprintd would otherwise add to every service.
          config = lib.mkMerge [
            (lib.mkIf cfg.enable { fprintAuth = lib.mkDefault false; })
            (lib.mkIf (cfg.enable && surface != null) {
              rules.auth = rulesFor config surface;
              u2fAuth = false;
            })
          ];
        }
      )
    );
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (s: lib.hasAttr s services) (lib.attrNames cfg.surfaces);
        message = "nyx.biometrics.surfaces: the surfaces are ${lib.concatStringsSep ", " (lib.attrNames services)}.";
      }
      {
        assertion = lib.elem "face" usedMethods -> cfg.face != "none";
        message = "nyx.biometrics: a surface uses face sign-in; set nyx.biometrics.face.";
      }
      {
        assertion =
          cfg.face == "gaze"
          -> !lib.any (s: lib.elem "face" (cfg.surfaces.${s} or [ ])) [
            "login"
            "sudo"
            "polkit"
          ];
        message = "nyx.biometrics: Gaze (an ordinary webcam) can't sign in, run sudo or approve administrator prompts, because a photo can pass. Use Irlume with an infrared camera, or keep face for the lock screen only.";
      }
      {
        assertion = cfg.face == "gaze" && lib.elem "face" (cfg.surfaces.lock or [ ]) -> cfg.allowWebcamFace;
        message = "nyx.biometrics: Gaze on the lock screen lets a photo of you unlock it. Set nyx.biometrics.allowWebcamFace = true to use it anyway.";
      }
      {
        assertion = lib.elem "fingerprint" usedMethods -> cfg.fingerprint.enable;
        message = "nyx.biometrics: a surface uses fingerprint sign-in; set nyx.biometrics.fingerprint.enable.";
      }
      {
        assertion = lib.elem "security-key" usedMethods -> cfg.securityKey.enable;
        message = "nyx.biometrics: a surface uses security keys; set nyx.biometrics.securityKey.enable.";
      }
    ];

    environment.systemPackages = [
      bio
    ]
    ++ lib.optionals cfg.securityKey.enable [
      pkgs.pam_u2f
      pkgs.libfido2
    ];
    # The broker and the key service know Nyx Passwords and Assistant by these folders,
    # and apps know the broker by its own. The activation script in default.nix writes
    # /etc/nyx/trusted-bin from this list.
    environment.etc."nyx/trusted-bin.system".text = lib.mkAfter "${bio}/bin\n";
    services.dbus.packages = [ bio ];
    systemd.packages = [ bio ];
    systemd.sockets.nyx-auth-keyd.wantedBy = [ "sockets.target" ];
    security.polkit.enable = true;
    security.tpm2.enable = lib.mkDefault true;
    environment.pathsToLink = [ "/lib/nyx-biometrics" ];

    services.fprintd.enable = lib.mkIf cfg.fingerprint.enable true;
    security.pam.services = lockServices;
    services.irlume = {
      enable = cfg.face == "irlume";
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.irlume;
    };
    services.gaze = {
      enable = cfg.face == "gaze";
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.gaze;
      pam.defaultServices = [ ];
    };
  };
}
