# Nyx Store. On NixOS it installs apps from Flathub (flatpak --user) and nixpkgs
# (nix profile) into the user's own profile, so the pacman helper isn't installed.
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
    description = "Apps from Flathub and nixpkgs, installed for you without a password";
    homepage = "https://github.com/design-nexus/nyx-store";
    mainProgram = "nyx-store";
  };
}
