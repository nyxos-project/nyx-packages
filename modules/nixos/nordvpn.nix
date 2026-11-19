# NordVPN's own app on NixOS: the daemon with its socket and kill-switch units as Nord's
# .deb has them, the `nordvpn` group whose members may talk to it, and its data folder.
# The package is unfree, so it's built with the system's nixpkgs, where accepting its
# licence (nyxos.unfree, from the catalog) applies.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nyx.nordvpn;
  nordvpn = pkgs.callPackage ../../pkgs/nordvpn.nix { };
in
{
  # Who may use it is the nordvpn group's members (the System Manager's group changes).
  options.nyx.nordvpn.enable = lib.mkEnableOption "NordVPN's app and daemon (unfree)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ nordvpn ];
    users.groups.nordvpn = { };

    # Its servers answer on another interface than the one a reply leaves by.
    networking.firewall.checkReversePath = lib.mkDefault "loose";

    systemd.tmpfiles.rules = [
      "d /run/nordvpn 0770 root nordvpn -"
      "d /var/lib/nordvpn 0750 root nordvpn -"
      # Countries, servers and the OpenVPN template, refreshed by the daemon later.
      "C /var/lib/nordvpn/data 0750 root nordvpn - ${nordvpn}/var/lib/nordvpn/data"
    ];

    systemd.sockets.nordvpnd = {
      description = "NordVPN Daemon Socket";
      wantedBy = [ "sockets.target" ];
      bindsTo = [ "nordvpnd.service" ];
      # Members of nordvpn only. The nordvpn command also checks the session's groups,
      # so someone just added uses it after logging in again (Settings says so).
      socketConfig = {
        ListenStream = "/run/nordvpn/nordvpnd.sock";
        SocketGroup = "nordvpn";
        SocketMode = "0660";
        DirectoryMode = "0750";
        RemoveOnStop = true;
      };
    };

    systemd.services.nordvpnd-killswitch = {
      description = "NordVPN daemon in kill-switch mode";
      before = [
        "network-pre.target"
        "nordvpnd.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${nordvpn.daemon}/bin/nordvpnd --killswitch-mode";
      };
    };

    systemd.services.nordvpnd = {
      description = "NordVPN Daemon";
      requires = [ "nordvpnd.socket" ];
      wants = [
        "nordvpnd-killswitch.service"
        "network-online.target"
      ];
      after = [
        "nordvpnd-killswitch.service"
        "network-online.target"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${nordvpn.daemon}/bin/nordvpnd";
        NonBlocking = true;
        KillMode = "process";
        Restart = "always";
        RestartSec = 5;
        RestartKillSignal = "SIGUSR1";
        RuntimeDirectory = "nordvpn";
        RuntimeDirectoryMode = "0750";
        RuntimeDirectoryPreserve = true;
        Group = "nordvpn";
      };
    };
  };
}
