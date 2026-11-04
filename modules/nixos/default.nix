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
    bar = "Nyx Bar and its plugins";
    settings = "Nyx Settings and its root helper";
    store = "Nyx Store, with Flathub and nixpkgs";
  };

  # An app's user units and D-Bus activation files, plus the units its repository
  # starts with the session (passthru.autostart: unit name -> target).
  enabledPackages =
    map (name: nyxPkgs."nyx-${name}") (lib.filter (name: cfg.${name}.enable) (lib.attrNames apps))
    ++ lib.optional cfg.accounts.enable nyxPkgs.nyx-accounts;

  services = package: {
    systemd.packages = [ package ];
    # A NixOS drop-in also sets PATH, to a minimal one by default; these services
    # start apps and system tools, so they get the setuid wrappers and the user's and
    # system's profiles, as a login shell has.
    systemd.user.services = lib.mapAttrs (_: target: {
      overrideStrategy = "asDropin";
      wantedBy = [ target ];
      path = [
        "/run/wrappers"
        "/etc/profiles/per-user/%u"
        "/run/current-system/sw"
      ];
    }) (package.passthru.autostart or { });
    services.dbus.packages = [ package ];
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
        {
          environment.systemPackages = [ nyxPkgs."nyx-${name}" ];
        }
        // services nyxPkgs."nyx-${name}"
      )
    ) apps
    ++ [
      # Services that trust callers by program (Clipboard, Accounts) read the folders
      # of installed Nyx apps from here; each app has its own store folder (nyx-peer).
      (lib.mkIf (enabledPackages != [ ]) {
        environment.etc."nyx/trusted-bin".text = lib.concatMapStrings (p: "${p}/bin\n") enabledPackages;
        # Apps' Glimpse plugins, at /run/current-system/sw/share/nyx-APP/glimpse.
        environment.pathsToLink = map (p: "/share/${p.pname}/glimpse") (
          lib.filter (p: p.passthru.glimpsePlugin or false) enabledPackages
        );
      })

      (lib.mkIf cfg.icons.enable {
        environment.systemPackages = [ nyxPkgs.nyx-icons ];
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
          };
        };

        systemd.user.paths.nyx-icons = {
          description = "Recolour Nyx icons when the Nyx theme changes or an app installs its icon";
          wantedBy = [ "default.target" ];
          # Folders, not theme.toml itself: apps replace it by rename, which a file
          # watch misses.
          pathConfig = {
            PathChanged = [
              "%h/.config/nyx"
              "%h/.config/nyx/themes"
              "%h/.local/share/icons/hicolor/scalable/apps"
            ];
            Unit = "nyx-icons.service";
          };
        };

        # A watch on a missing folder stops systemd seeing changes beside it.
        systemd.user.tmpfiles.rules = [
          "d %h/.config/nyx/themes - - - -"
          "d %h/.local/share/icons/hicolor/scalable/apps - - - -"
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

      # Maps finds "my location" through GeoClue.
      (lib.mkIf cfg.maps.enable {
        services.geoclue2.enable = lib.mkDefault true;
      })

      # Pulse shares live locations through GeoClue and keeps its database key in the
      # Secret Service.
      (lib.mkIf cfg.pulse.enable {
        services.geoclue2.enable = lib.mkDefault true;
        services.gnome.gnome-keyring.enable = lib.mkDefault true;
      })

      # At login the Assistant's settings, abilities and browser and search assets are set
      # up in the user's folders, as its install script does. The daemon starts once the
      # user enables it (`systemctl --user enable --now nyx-assistantd`), after a model is
      # downloaded; the Canvas starts with it, as the install script arranges.
      (lib.mkIf cfg.assistant.enable {
        systemd.user.services.nyx-assistant-setup = {
          description = "Set up Nyx Assistant's settings and abilities";
          wantedBy = [ "default.target" ];
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
        systemd.user.services.nyx-assistant-visual = {
          overrideStrategy = "asDropin";
          wantedBy = [ "nyx-assistantd.service" ];
        };
      })

      # Glimpse runs its semantic search helper from ~/.local/share/nyx-glimpse/runtime,
      # which it would otherwise build there.
      (lib.mkIf cfg.glimpse.enable {
        systemd.user.tmpfiles.rules = [
          "d %h/.local/share/nyx-glimpse 0700 - - -"
          "L+ %h/.local/share/nyx-glimpse/runtime - - - - ${nyxPkgs.nyx-glimpse.runtime}"
        ];
      })

      # nyx-notifyd answers as the session's notification server and the Notification
      # Center shows the pop-ups (Nyx mode); there is no Omarchy shell to hand them to.
      (lib.mkIf cfg.notification-center.enable {
        systemd.user.services.nyx-notifyd.environment.NYX_NOTIFYD_MODE = "nyx";
      })

      # pkexec runs Settings' helper from the system profile, the path its action names.
      (lib.mkIf cfg.settings.enable {
        environment.pathsToLink = [ "/lib/nyx-settings" ];
        security.polkit.enable = true;
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
          serviceConfig = {
            ExecStart = "${pkgs.swaybg}/bin/swaybg --mode fill --image ${
              nyxPkgs.nyx-wallpapers.defaults.${cfg.wallpapers.theme}
            }";
            Restart = "on-failure";
          };
        };
      })

      # Store installs Flathub apps with the user's flatpak.
      (lib.mkIf cfg.store.enable {
        services.flatpak.enable = true;
        xdg.portal.enable = lib.mkDefault true;
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
