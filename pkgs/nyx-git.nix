{
  nyx,
  src,
  gtksourceview5,
  git,
  git-lfs,
  openssh,
  libsecret,
  xdg-utils,
  xdg-terminal-exec,
}:
nyx.buildApp {
  pname = "nyx-git";
  inherit src;
  buildInputs = [ gtksourceview5 ];
  nativeCheckInputs = [
    git
    git-lfs
  ];
  # secret-tool keeps hosting tokens; xdg-terminal-exec opens a terminal in a repository.
  runtimeInputs = [
    git
    git-lfs
    openssh
    libsecret
    xdg-utils
    xdg-terminal-exec
  ];
  meta = {
    description = "Visual Git client with a commit graph, worktrees and conflict resolution";
    homepage = "https://github.com/design-nexus/nyx-git";
    mainProgram = "nyx-git";
  };
}
