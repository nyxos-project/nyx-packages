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

  # nyx.<app>.enable installs nyx-<app>.
  apps = {
    icons = "the Nyx application icons";
    fonts = "Nyx Fonts";
    notepad = "Nyx Notepad";
    calculator = "Nyx Calculator";
    archive = "Nyx Archive";
    pdf = "Nyx PDF";
    news = "Nyx News";
    office = "Nyx Office (Write, Sheets and Present)";
  };
in
{
  options.nyx =
    lib.mapAttrs (_: description: { enable = lib.mkEnableOption description; }) apps
    // {
      accounts.enable = lib.mkEnableOption "the Nyx Online Accounts service";
    };

  config = lib.mkMerge (
    lib.mapAttrsToList (
      name: _:
      lib.mkIf cfg.${name}.enable {
        environment.systemPackages = [ nyxPkgs."nyx-${name}" ];
      }
    ) apps
    ++ [
      (lib.mkIf cfg.accounts.enable {
        environment.systemPackages = [ nyxPkgs.nyx-accounts ];
        services.dbus.packages = [ nyxPkgs.nyx-accounts ];
        # Account credentials live in the Secret Service.
        services.gnome.gnome-keyring.enable = lib.mkDefault true;
      })
    ]
  );
}
