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
in
{
  options.nyx = {
    icons.enable = lib.mkEnableOption "the Nyx application icons";
    accounts.enable = lib.mkEnableOption "the Nyx Online Accounts service";
    fonts.enable = lib.mkEnableOption "Nyx Fonts";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.icons.enable {
      environment.systemPackages = [ nyxPkgs.nyx-icons ];
    })

    (lib.mkIf cfg.accounts.enable {
      environment.systemPackages = [ nyxPkgs.nyx-accounts ];
      services.dbus.packages = [ nyxPkgs.nyx-accounts ];
      # Account credentials live in the Secret Service.
      services.gnome.gnome-keyring.enable = lib.mkDefault true;
    })

    (lib.mkIf cfg.fonts.enable {
      environment.systemPackages = [ nyxPkgs.nyx-fonts ];
    })
  ];
}
