self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nyx;
  nyxPkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
  iconTools = nyxPkgs.nyx-icon-tools;

  # nyx.<app>.enable installs nyx-<app>.
  apps = {
    fonts = "Nyx Fonts";
    notepad = "Nyx Notepad";
    calculator = "Nyx Calculator";
    archive = "Nyx Archive";
    pdf = "Nyx PDF";
    news = "Nyx News";
    office = "Nyx Office (Write, Sheets and Present)";
    git = "Nyx Git";
    music = "Nyx Music";
    lyra = "Nyx Lyra (YouTube Music)";
    media-player = "Nyx Media Player";
    theater = "Nyx Theater";
    photos = "Nyx Photos and the photo viewer";
    share = "Nyx Share (Share Sheet and service)";
    transfer = "Nyx Transfer and its background service";
    cloud = "the Nyx Cloud storage service";
    clipboard = "Nyx Clipboard history";
    home = "Nyx Home and its automation service";
    chat = "Nyx Chat";
    activity = "Nyx Activity";
    containers = "Nyx Containers";
    torrents = "Nyx Torrents";
    weather = "Nyx Weather";
    notes = "Nyx Notes";
    files = "Nyx Files";
    contacts = "Nyx Contacts";
    calendar = "Nyx Calendar and its sync service";
    reminders = "Nyx Reminders and its sync service";
    backup = "Nyx Backup and its background service";
    maps = "Nyx Maps";
    mail = "Nyx Mail and its sync service";
    capture = "Nyx Capture";
    passwords = "Nyx Passwords and its vault service";
    pulse = "Nyx Pulse";
    assistant = "Nyx Assistant, its HUD, Canvas and speech services";
    glimpse = "Nyx Glimpse, the launcher and local search";
    notification-center = "Nyx Notification Center and its notification service";
    dock = "Nyx Dock";
    control-center = "Nyx Control Center";
    desktop-widgets = "Nyx Desktop Widgets, plugin widgets on the desktop (drawn by Nyx Shell's nyx-shell-qs)";
    bar = "Nyx Bar and its plugins";
    settings = "Nyx Settings and its root helper";
    store = "Nyx Store, with the NyxOS catalog, nixpkgs and Flathub";
    switcher = "Nyx Switcher, its window and app switching and the overview";
    shell = "Nyx Shell Core (the shell's coordinator) and the Nyx.Shell Quickshell module";
    welcome = "Nyx Welcome, the setup after installation";
    agents = "Nyx Agents, its session manager and the AI Hub for Nyx Bar and the Control Center";
  };

  # Nyx AI Core with the worker for this machine's acceleration. The CUDA build is
  # unfree, so it comes from the system's nixpkgs (and its allowed-unfree list).
  aiLlama = {
    vulkan = nyxPkgs.llama-prism;
    cpu = nyxPkgs.llama-prism.override { vulkanSupport = false; };
    cuda = pkgs.callPackage ../../pkgs/llama-prism-cuda.nix { };
  };
  aiPackage =
    if cfg.ai.acceleration == "vulkan" then
      nyxPkgs.nyx-ai
    else
      nyxPkgs.nyx-ai.override { llama = aiLlama.${cfg.ai.acceleration}; };

  # An app's user units and D-Bus activation files, plus the units its repository
  # starts with the session (passthru.autostart: unit name -> target).
  enabledPackages =
    map (name: nyxPkgs."nyx-${name}") (lib.filter (name: cfg.${name}.enable) (lib.attrNames apps))
    ++ lib.optional cfg.accounts.enable nyxPkgs.nyx-accounts
    ++ lib.optional cfg.ai.enable aiPackage;

  # Nyx apps in someone's Nix profile (installed per user): their user units, with the
  # PATH and condition the module's `services` gives the system's, and the units they
  # start with the session (share/nyx/autostart.d). The system's copy of a unit wins.
  # `systemctl --user daemon-reload` (done after each profile change) runs it again.
  profileUnits = pkgs.writeShellScript "nyx-profile-units" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.getent
      ]
    }
    normal=$1
    home=''${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}
    [ -n "$home" ] || exit 0
    seen=" "
    for profile in "$home/.nix-profile" "''${XDG_STATE_HOME:-$home/.local/state}/nix/profile"; do
      [ -d "$profile/lib/systemd/user" ] || continue
      real=$(readlink -f "$profile")
      case "$seen" in *" $real "*) continue ;; esac
      seen="$seen$real "
      for unit in "$profile"/lib/systemd/user/*; do
        [ -e "$unit" ] || continue
        name=''${unit##*/}
        [ -e "/etc/systemd/user/$name" ] && continue
        [ -e "$normal/$name" ] || ln -s "$unit" "$normal/$name"
        case $name in
          *.service)
            mkdir -p "$normal/$name.d"
            printf '%s\n' '[Unit]' 'ConditionUser=!@system' '[Service]' \
              "Environment=\"PATH=/run/wrappers/bin:$profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin\"" \
              > "$normal/$name.d/nyx-profile.conf"
            ;;
        esac
      done
      # share/nyx/autostart is the single file packages had before autostart.d.
      for list in "$profile"/share/nyx/autostart.d/* "$profile/share/nyx/autostart"; do
        [ -f "$list" ] || continue
        while read -r unit target; do
          [ -n "$unit" ] && [ -n "$target" ] || continue
          case $unit in *.*) ;; *) unit=$unit.service ;; esac
          [ -e "$normal/$unit" ] || continue
          mkdir -p "$normal/$target.wants"
          ln -sfn "$normal/$unit" "$normal/$target.wants/$unit"
        done < "$list"
      done
    done
  '';

  services = package: {
    systemd.packages = [ package ];
    # A NixOS drop-in also sets PATH, to a minimal one by default; these services
    # start apps and system tools, so they get the setuid wrappers and the user's and
    # system's profiles, as a login shell has.
    systemd.user.services = lib.mapAttrs (_: target: {
      overrideStrategy = "asDropin";
      wantedBy = [ target ];
      # People's sessions only, not the greeter's or another system account's.
      unitConfig.ConditionUser = "!@system";
      path = [
        "/run/wrappers"
        "/etc/profiles/per-user/%u"
        "/run/current-system/sw"
      ];
    }) (package.passthru.autostart or { });
    services.dbus.packages = [ package ];
    # Its action manifests (share/nyx/actions) for `nyx APP …`, Glimpse and Nyx
    # Assistant, and the nyx command's part that reads them.
    environment.pathsToLink = [ "/share/nyx" ];
    environment.systemPackages = [ nyxPkgs.nyx-actions ];
  };
in
{
  imports = [ (import ./biometrics.nix self) ];

  options.nyx = lib.mapAttrs (_: description: { enable = lib.mkEnableOption description; }) apps // {
    icons = {
      enable = lib.mkEnableOption "the Nyx application icons";
      followTheme = lib.mkEnableOption ''
        recolouring Nyx icons for each user's Nyx theme (`nyx-icons`), whenever the
        theme changes or an app is installed
      '';
    };
    accounts.enable = lib.mkEnableOption "the Nyx Online Accounts service";
    voice.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.assistant.enable;
      defaultText = lib.literalExpression "config.nyx.assistant.enable";
      description = ''
        Nyx Voice: dictation, listening and speaking for Nyx apps, started on first use.
        On by default with the Assistant, which listens through its recognizer worker.
      '';
    };
    ai = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.chat.enable || cfg.assistant.enable;
        defaultText = lib.literalExpression "config.nyx.chat.enable || config.nyx.assistant.enable";
        description = ''
          Nyx AI Core: the shared local model runtime (PrismML's llama.cpp) that Nyx apps
          use, started on first use, with an OpenAI-compatible API for coding tools on
          127.0.0.1:8080. On by default with Chat and the Assistant, whose language
          models run there.
        '';
      };
      acceleration = lib.mkOption {
        type = lib.types.enum [
          "vulkan"
          "cuda"
          "cpu"
        ];
        default = "vulkan";
        description = ''
          How the worker runs models: Vulkan (any GPU, and the processor), CUDA
          (Prism's prebuilt build for NVIDIA's own driver; unfree, so the system must
          allow `nyx.ai.unfree`) or the processor alone.
        '';
      };
      unfree = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        readOnly = true;
        default = lib.optionals (cfg.ai.acceleration == "cuda") aiLlama.cuda.passthru.unfree;
        description = "Unfree packages the chosen acceleration needs.";
      };
    };
    system = {
      enable = lib.mkEnableOption ''
        the Nyx System Manager: validated, polkit-authorized changes to this system's
        NixOS configuration (settings, packages, services), updates and rollback
      '';
      flake = lib.mkOption {
        type = lib.types.str;
        default = "/etc/nyxos/flake";
        description = "The system's flake, which reads the overrides layer as its `nyxos-overrides` input.";
      };
      host = lib.mkOption {
        type = lib.types.str;
        description = "This machine's attribute in the flake's nixosConfigurations.";
      };
    };
    themes.enable = lib.mkEnableOption ''
      Nyx Theme Engine: nyx-themed (io.github.design_nexus.nyx.Theme on the session bus,
      which announces theme changes and carries each user's theme to Hyprland, Foot,
      GTK and the wallpaper), the nyx-theme command and the Nyx.Theme QML module
    '';
    connect.enable = lib.mkEnableOption ''
      Nyx Connect's backend: upstream Flux's fluxd (started with the graphical session)
      and flux-cli, with its port (12100, TCP and UDP) open and Avahi for discovery.
      Pair a phone running Flux for Android or iOS in Settings › Devices
    '';
    locker.enable = lib.mkEnableOption ''
      Nyx Locker, the lock screen on the Wayland session-lock protocol: the password,
      and the methods in `nyx.biometrics.surfaces.lock`, each its own PAM service at once
    '';
    prompt.enable = lib.mkEnableOption ''
      Nyx Administrator Prompt, the graphical session's polkit authentication agent (in
      place of any other agent)
    '';
    wallpapers = {
      enable = lib.mkEnableOption "the Nyx wallpapers, with the theme's default shown on every output";
      theme = lib.mkOption {
        type = lib.types.str;
        default = "nyx-dark";
        description = "The theme whose default wallpaper is shown (a table in wallpapers.toml).";
      };
    };
  };

  config = lib.mkMerge (
    lib.mapAttrsToList (
      name: _:
      lib.mkIf cfg.${name}.enable (
        lib.mkMerge [
          { environment.systemPackages = [ nyxPkgs."nyx-${name}" ]; }
          (services nyxPkgs."nyx-${name}")
        ]
      )
    ) apps
    ++ [
      # Services that trust callers by program (Clipboard, Accounts) read the folders
      # of installed Nyx apps from /etc/nyx/trusted-bin; each app has its own store
      # folder (nyx-peer). It's this list and the Nyx apps people installed for
      # themselves that NyxOS's cache built (the System Manager's TrustApps), put
      # together here and by the manager. nyx-actions (`nyx APP …`) is there too: Clipboard
      # and Passwords answer it only as a program they trust.
      (lib.mkIf (enabledPackages != [ ]) {
        environment.etc."nyx/trusted-bin.system".text = lib.concatMapStrings (p: "${p}/bin\n") (
          enabledPackages ++ [ nyxPkgs.nyx-actions ]
        );
        system.activationScripts.nyx-trusted-bin = {
          deps = [ "etc" ];
          text = ''
            mkdir -p /etc/nyx
            {
              cat /etc/nyx/trusted-bin.system
              if [ -r /var/lib/nyx-system/trusted-profile-bin ]; then
                while read -r _ dir; do
                  if [ -d "$dir" ]; then printf '%s\n' "$dir"; fi
                done < /var/lib/nyx-system/trusted-profile-bin
              fi
            } | ${pkgs.gawk}/bin/awk '!seen[$0]++' > /etc/nyx/trusted-bin.new
            chmod 0644 /etc/nyx/trusted-bin.new
            mv /etc/nyx/trusted-bin.new /etc/nyx/trusted-bin
          '';
        };
        # Apps' Glimpse plugins, at /run/current-system/sw/share/nyx-APP/glimpse.
        environment.pathsToLink = map (p: "/share/${p.pname}/glimpse") (
          lib.filter (p: p.passthru.glimpsePlugin or false) enabledPackages
        );
      })

      (lib.mkIf cfg.icons.enable {
        environment.systemPackages = [ nyxPkgs.nyx-icons ];
      })

      # Nyx Shell Core's NyxOS defaults: the distribution layer of the `shell` domain.
      (lib.mkIf cfg.shell.enable {
        environment.etc."nyxos/defaults/shell.toml".source =
          "${nyxPkgs.nyx-shell}/share/nyx-shell/shell.toml";
        # nyx-shell-qs finds the components (its OSD and window menu, the Control
        # Center's panel, Desktop Widgets) in the system profile.
        environment.pathsToLink = [ "/share/nyx-shell/components" ];
      })

      (lib.mkIf cfg.icons.followTheme {
        environment.systemPackages = [ iconTools ];

        systemd.user.services.nyx-icons = {
          description = "Recolour Nyx icons for the current theme";
          # Bursts (clicking through swatches, a switch adding several apps) must not
          # hit the start limit; the pause lets one sync cover the whole burst.
          unitConfig.StartLimitIntervalSec = 0;
          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
            ExecStart = "${lib.getExe iconTools} sync --quiet";
            # Apps in the person's own Nix profile too (installed per user).
            Environment = "XDG_DATA_DIRS=%h/.nix-profile/share:%h/.local/state/nix/profile/share:/etc/profiles/per-user/%u/share:/run/current-system/sw/share";
          };
        };

        systemd.user.paths.nyx-icons = {
          description = "Recolour Nyx icons when the Nyx theme changes or an app installs its icon";
          wantedBy = [ "default.target" ];
          unitConfig.ConditionUser = "!@system";
          # Folders, not theme.toml itself: apps replace it by rename, which a file
          # watch misses.
          pathConfig = {
            PathChanged = [
              "%h/.config/nyx"
              "%h/.config/nyx/themes"
              "%h/.local/share/icons/hicolor/scalable/apps"
              # The resolved theme every app reads, written after theme.toml changes.
              "%t/nyx/theme"
            ];
            Unit = "nyx-icons.service";
          };
        };

        # A watch on a missing folder stops systemd seeing changes beside it.
        systemd.user.tmpfiles.rules = [
          "d %h/.config/nyx/themes - - - -"
          "d %h/.local/share/icons/hicolor/scalable/apps - - - -"
          "d %t/nyx/theme - - - -"
        ];

        # Apps installed by a system switch put their icons in the system profile,
        # which the path unit can't watch. Runs at login and after every switch.
        system.userActivationScripts.nyx-icons = ''
          ${config.systemd.package}/bin/systemctl --user start --no-block nyx-icons.service || true
        '';
      })

      # The browsers find the Passwords bridge through these manifests.
      (lib.mkIf cfg.passwords.enable {
        programs.firefox.nativeMessagingHosts.packages = [ nyxPkgs.nyx-passwords ];
        environment.etc."chromium/native-messaging-hosts/io.github.design_nexus.nyx.passwords.json".source =
          "${nyxPkgs.nyx-passwords}/etc/chromium/native-messaging-hosts/io.github.design_nexus.nyx.passwords.json";
        services.gnome.gnome-keyring.enable = lib.mkDefault true;
      })

      # Nearby sharing (LocalSend's protocol): transfers on TCP 53317, discovery on UDP
      # 53317 multicast. Share asks before receiving from a device it doesn't trust.
      (lib.mkIf cfg.share.enable {
        networking.firewall = {
          allowedTCPPorts = [ 53317 ];
          allowedUDPPorts = [ 53317 ];
        };
      })

      # Maps finds "my location" through GeoClue.
      (lib.mkIf cfg.connect.enable (
        lib.mkMerge [
          (services nyxPkgs.flux)
          {
            environment.systemPackages = [ nyxPkgs.flux ];
            networking.firewall = {
              allowedTCPPorts = [ 12100 ];
              allowedUDPPorts = [ 12100 ];
            };
            # fluxd publishes and browses _flux._udp through Avahi's D-Bus API.
            services.avahi = {
              enable = lib.mkDefault true;
              publish = {
                enable = lib.mkDefault true;
                userServices = lib.mkDefault true;
              };
            };
          }
        ]
      ))

      (lib.mkIf cfg.maps.enable {
        services.geoclue2.enable = lib.mkDefault true;
      })

      # Pulse shares live locations through GeoClue and keeps its database key in the
      # Secret Service.
      (lib.mkIf cfg.pulse.enable {
        services.geoclue2.enable = lib.mkDefault true;
        services.gnome.gnome-keyring.enable = lib.mkDefault true;
      })

      # At login the Assistant's settings, abilities and browser, search and voice assets are
      # set up in the user's folders, as its install script does. The daemon starts once
      # the user enables it (`systemctl --user enable --now nyx-assistantd`); its language
      # model is Nyx AI Core's and its listening Nyx Voice's (`nyx-voice models fetch asr`).
      (lib.mkIf cfg.assistant.enable {
        systemd.user.services.nyx-assistant-setup = {
          description = "Set up Nyx Assistant's settings and abilities";
          wantedBy = [ "default.target" ];
          unitConfig.ConditionUser = "!@system";
          before = [ "nyx-assistantd.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${nyxPkgs.nyx-assistant}/libexec/nyx-assistant-setup";
          };
        };
        systemd.user.services.nyx-assistantd = {
          overrideStrategy = "asDropin";
          wants = [ "nyx-assistant-setup.service" ];
          after = [ "nyx-assistant-setup.service" ];
        };
      })

      # Glimpse searches by meaning through Nyx AI Core now; the link to its old helper in
      # ~/.local/share/nyx-glimpse/runtime goes. Its panel reaches nyx-shell-qs through
      # share/nyx-shell/components in the system profile (nyx.shell).
      (lib.mkIf cfg.glimpse.enable {
        systemd.user.tmpfiles.rules = [ "r %h/.local/share/nyx-glimpse/runtime - - - - -" ];
      })

      # nyx-notifyd answers as the session's notification server and the Notification
      # Center shows the pop-ups (Nyx mode); there is no Omarchy shell to hand them to.
      (lib.mkIf cfg.notification-center.enable {
        systemd.user.services.nyx-notifyd.environment.NYX_NOTIFYD_MODE = "nyx";
      })

      # Settings asks polkit through the System Manager and cups-pk-helper.
      (lib.mkIf cfg.settings.enable {
        security.polkit.enable = true;
      })

      # Settings adds and removes printers through cups-pk-helper, CUPS's polkit D-Bus service.
      (lib.mkIf (cfg.settings.enable && config.services.printing.enable) {
        services.dbus.packages = [ pkgs.cups-pk-helper ];
        environment.systemPackages = [ pkgs.cups-pk-helper ];
      })

      # Until the theme service picks wallpapers, the theme's default is shown.
      (lib.mkIf cfg.wallpapers.enable {
        environment.systemPackages = [ nyxPkgs.nyx-wallpapers ];
        environment.pathsToLink = [ "/share/backgrounds" ];
        systemd.user.services.nyx-wallpaper = {
          description = "Nyx wallpaper";
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          unitConfig.ConditionUser = "!@system";
          serviceConfig = {
            # The theme service's choice (the user's own, or the theme's default), else this.
            ExecStart = pkgs.writeShellScript "nyx-wallpaper" ''
              image=${nyxPkgs.nyx-wallpapers.defaults.${cfg.wallpapers.theme}}
              state=''${XDG_STATE_HOME:-$HOME/.local/state}/nyx/wallpaper
              if [ -r "$state" ]; then
                read -r chosen < "$state" || true
                [ -r "$chosen" ] && image=$chosen
              fi
              exec ${pkgs.swaybg}/bin/swaybg --mode fill --image "$image"
            '';
            Restart = "on-failure";
          };
        };
      })

      # The System Manager starts on its first call (D-Bus activation) and exits when idle.
      (lib.mkIf cfg.system.enable {
        environment.systemPackages = [ nyxPkgs.nyx-system ];
        services.dbus.packages = [ nyxPkgs.nyx-system ];
        security.polkit.enable = true;
        environment.etc."nyxos/system.toml".text = ''
          flake = "${cfg.system.flake}"
          host = "${cfg.system.host}"
        '';
        systemd.tmpfiles.rules = [ "d /etc/nyxos/overrides 0755 root root -" ];
        # The catalog, and the Nyx apps this system has, for Welcome, the Store and nyx-system.
        environment.pathsToLink = [ "/share/nyx" ];
        environment.etc."nyx/apps".text = lib.concatLines (
          lib.filter (name: cfg.${name}.enable) (lib.attrNames apps)
        );
        # Nyx apps people install for themselves: their session services, and trusted
        # like the system's once NyxOS's cache built them (checked at each sign-in and
        # after each profile change).
        systemd.user.generators.nyx-profile-units = profileUnits;
        systemd.user.services.nyx-trust-apps = {
          description = "Trust the Nyx apps in your Nix profile";
          wantedBy = [ "default.target" ];
          unitConfig = {
            ConditionUser = "!@system";
            ConditionPathExistsGlob = "%h/.nix-profile/share/applications/io.github.design_nexus.nyx.*";
          };
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/busctl --system call io.github.nyxos_project.System /io/github/nyxos_project/System io.github.nyxos_project.System1 TrustApps";
          };
        };
        systemd.services.nyx-system-manager = {
          description = "Nyx System Manager";
          # It runs the switch itself: stopping it mid-switch would cut the switch's
          # output and fail it halfway. A new version starts after it goes idle.
          restartIfChanged = false;
          path = [
            config.system.build.nixos-rebuild
            config.nix.package
            pkgs.git
            # chpasswd, for passwords (they never go into the configuration).
            pkgs.shadow
            # Snapshots before and after a change, where NyxOS has them on.
            pkgs.snapper
          ];
          serviceConfig = {
            Type = "dbus";
            BusName = "io.github.nyxos_project.System";
            ExecStart = "${nyxPkgs.nyx-system}/bin/nyx-system-manager";
            StateDirectory = "nyx-system";
          };
        };
        # The daily run: what each person's update settings say (updates.system, .apps,
        # .tools, .firmware: off, check, notify or auto). Their own apps and tools
        # (profile, Flatpaks, mise, uv) install themselves when set to auto, the default,
        # at updates.install-at if set; the system and firmware only ever notify, once per
        # set of updates. It waits out metered connections unless allowed
        # (updates.check-on-metered) and does nothing when checks are off (updates.check).
        systemd.user.services.nyx-update-check = {
          description = "Check for NyxOS updates and install your own";
          unitConfig.ConditionUser = "!@system";
          # nix, flatpak, mise, uv and fwupdmgr, as the system and the person have them.
          path = [
            "/etc/profiles/per-user/%u"
            "/run/current-system/sw"
          ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${nyxPkgs.nyx-system}/bin/nyx-system update auto";
            Nice = 10;
            IOSchedulingClass = "idle";
          };
        };
        systemd.user.timers.nyx-update-check = {
          description = "Check for NyxOS updates daily";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnStartupSec = "15min";
            OnUnitActiveSec = "1d";
            RandomizedDelaySec = "1h";
            Persistent = true;
          };
        };
      })

      (lib.mkIf cfg.locker.enable {
        environment.systemPackages = [ nyxPkgs.nyx-locker ];
        # The password on its own: the other methods are their own services.
        security.pam.services.nyx-lock-password = {
          fprintAuth = false;
          u2fAuth = false;
        };
        environment.etc."nyx-locker/config.toml".text = ''
          methods = [${
            lib.concatMapStringsSep ", " (m: ''"${m}"'') (
              lib.optionals cfg.biometrics.enable (cfg.biometrics.surfaces.lock or [ ])
            )
          }]
        '';
      })

      (lib.mkIf cfg.prompt.enable {
        security.polkit.enable = true;
        systemd.user.services.nyx-prompt = {
          description = "Nyx Administrator Prompt (polkit agent)";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${nyxPkgs.nyx-prompt}/bin/nyx-prompt";
            Restart = "on-failure";
            RestartSec = 2;
          };
        };
      })

      (lib.mkIf cfg.themes.enable {
        environment.systemPackages = [
          nyxPkgs.nyx-system
          nyxPkgs.nyx-theme
        ];
        # `import Nyx.Theme` in Quickshell components.
        environment.sessionVariables.QML_IMPORT_PATH = [ "/run/current-system/sw/share/nyx/qml" ];
        # io.github.design_nexus.nyx.Theme starts nyx-themed when a client calls it first.
        services.dbus.packages = [ nyxPkgs.nyx-system ];
        programs.dconf.enable = true;
        systemd.user.services.nyx-themed = {
          description = "Nyx theme service (io.github.design_nexus.nyx.Theme)";
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          unitConfig.ConditionUser = "!@system";
          path = [
            config.programs.hyprland.package
            pkgs.dconf
            config.systemd.package
            # Redraws Umbra in the theme's colours.
            nyxPkgs.umbra-icons
          ];
          serviceConfig = {
            Type = "dbus";
            BusName = "io.github.design_nexus.nyx.Theme";
            ExecStart = "${nyxPkgs.nyx-system}/bin/nyx-themed";
            Restart = "on-failure";
          };
        };
      })

      # Switcher writes its shortcuts (~/.config/hypr/nyx-switcher.lua) as it starts; they
      # take over Alt+Tab and Super+Tab.
      (lib.mkIf cfg.switcher.enable {
        systemd.user.services.nyx-switcher.serviceConfig.ExecStartPre =
          "${nyxPkgs.nyx-switcher}/bin/nyx-switcher --integrate --force";
      })

      # Store installs Flathub apps with the user's flatpak.
      (lib.mkIf cfg.store.enable {
        services.flatpak.enable = true;
        xdg.portal.enable = lib.mkDefault true;
      })

      # The socket starts nyx-voiced on the first request.
      (lib.mkIf cfg.voice.enable {
        environment.systemPackages = [ nyxPkgs.nyx-voice ];
        systemd.packages = [ nyxPkgs.nyx-voice ];
        systemd.user.sockets.nyx-voiced = {
          overrideStrategy = "asDropin";
          wantedBy = [ "sockets.target" ];
          unitConfig.ConditionUser = "!@system";
        };
      })

      # The socket starts nyx-aid on the first request, from an app or a coding tool.
      (lib.mkIf cfg.ai.enable {
        environment.systemPackages = [ aiPackage ];
        systemd.packages = [ aiPackage ];
        systemd.user.sockets.nyx-aid = {
          overrideStrategy = "asDropin";
          wantedBy = [ "sockets.target" ];
          unitConfig.ConditionUser = "!@system";
        };
        # nvidia-smi and the like, for reading GPU memory.
        systemd.user.services.nyx-aid = {
          overrideStrategy = "asDropin";
          path = [
            "/run/wrappers"
            "/etc/profiles/per-user/%u"
            "/run/current-system/sw"
          ];
        };
        hardware.graphics.enable = lib.mkDefault true;
      })

      # The socket starts nyx-agentd on the first request (the app, the CLI, the AI Hub).
      # Agents run under holders in their own sessions: restarting the manager keeps them.
      (lib.mkIf cfg.agents.enable {
        systemd.user.sockets.nyx-agentd = {
          overrideStrategy = "asDropin";
          wantedBy = [ "sockets.target" ];
          unitConfig.ConditionUser = "!@system";
        };
        systemd.user.services.nyx-agentd = {
          overrideStrategy = "asDropin";
          path = [
            "/run/wrappers"
            "/etc/profiles/per-user/%u"
            "/run/current-system/sw"
          ];
        };
      })

      (lib.mkIf cfg.accounts.enable {
        environment.systemPackages = [ nyxPkgs.nyx-accounts ];
        services.dbus.packages = [ nyxPkgs.nyx-accounts ];
        # Account credentials live in the Secret Service.
        services.gnome.gnome-keyring.enable = lib.mkDefault true;
      })
    ]
  );
}
