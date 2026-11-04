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
  };

  # An app's user units and D-Bus activation files, plus the units its repository
  # starts with the session (passthru.autostart: unit name -> target).
  enabledPackages =
    map (name: nyxPkgs."nyx-${name}") (lib.filter (name: cfg.${name}.enable) (lib.attrNames apps))
    ++ lib.optional cfg.accounts.enable nyxPkgs.nyx-accounts;

  services = package: {
    systemd.packages = [ package ];
    systemd.user.services = lib.mapAttrs (_: target: {
      overrideStrategy = "asDropin";
      wantedBy = [ target ];
    }) (package.passthru.autostart or { });
    services.dbus.packages = [ package ];
  };
in
{
  options.nyx = lib.mapAttrs (_: description: { enable = lib.mkEnableOption description; }) apps // {
    icons = {
      enable = lib.mkEnableOption "the Nyx application icons";
      followTheme = lib.mkEnableOption ''
        recolouring Nyx icons for each user's Nyx theme (`nyx-icons`), whenever the
        theme changes or an app is installed
      '';
    };
    accounts.enable = lib.mkEnableOption "the Nyx Online Accounts service";
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

      (lib.mkIf cfg.accounts.enable {
        environment.systemPackages = [ nyxPkgs.nyx-accounts ];
        services.dbus.packages = [ nyxPkgs.nyx-accounts ];
        # Account credentials live in the Secret Service.
        services.gnome.gnome-keyring.enable = lib.mkDefault true;
      })
    ]
  );
}
