# pacman 7.1 for Nyx Store, whose alpm crate needs libalpm 16; nixpkgs 26.05 has
# pacman 7.0 (libalpm 15). Store only links the library on NixOS. Drop this once
# nixpkgs ships 7.1.
{
  pacman,
  fetchFromGitLab,
}:
pacman.overrideAttrs {
  version = "7.1.0";
  src = fetchFromGitLab {
    domain = "gitlab.archlinux.org";
    owner = "pacman";
    repo = "pacman";
    rev = "v7.1.0";
    hash = "sha256-bGg2ZrIsEYJYZCLsIh4FZROhpyLSBO0Lar1mSoz66wI=";
  };
  # 7.1 also makes an empty /etc/makepkg.d at install, outside the package.
  prePatch = ''
    substituteInPlace meson.build --replace-fail "install_emptydir(join_paths(SYSCONFDIR, 'makepkg.d/'))" ""
  '';
}
