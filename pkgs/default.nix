{
  pkgs,
  nyx,
  inputs,
}:
{
  nyx-icons = pkgs.callPackage ./nyx-icons.nix {
    inherit nyx;
    src = inputs.nyx-design;
  };

  nyx-accounts = pkgs.callPackage ./nyx-accounts.nix {
    inherit nyx;
    src = inputs.nyx-accounts;
  };

  nyx-fonts = pkgs.callPackage ./nyx-fonts.nix {
    inherit nyx;
    src = inputs.nyx-fonts;
  };
}
