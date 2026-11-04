# Nyx Store. On NixOS it installs the NyxOS catalog's software and nixpkgs for everyone
# through the Nyx System Manager, and Flathub apps for the user, so the pacman helper
# isn't installed.
{
  nyx,
  src,
}:
nyx.buildApp {
  pname = "nyx-store";
  inherit src;
  # The alpm crate links libalpm (16) whether or not pacman is used.
  buildInputs = [ nyx.pacman_7_1 ];
  postInstall = ''
    rm $out/bin/nyx-store-helper
  '';
  meta = {
    description = "Apps from the NyxOS catalog, nixpkgs and Flathub";
    homepage = "https://github.com/design-nexus/nyx-store";
    mainProgram = "nyx-store";
  };
}
