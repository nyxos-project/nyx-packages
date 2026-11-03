# Docker and Incus manager. The docker and incus CLIs, their daemons and pkexec come
# from the system configuration (virtualisation.docker, virtualisation.incus).
{
  nyx,
  src,
  vte-gtk4,
  gtksourceview5,
  libsecret,
  openssh,
}:
nyx.buildApp {
  pname = "nyx-containers";
  inherit src;
  buildInputs = [
    vte-gtk4
    gtksourceview5
  ];
  # secret-tool keeps registry credentials; ssh-keyscan checks remote Incus hosts.
  runtimeInputs = [
    libsecret
    openssh
  ];
  meta = {
    description = "Native Incus and Docker manager";
    homepage = "https://github.com/design-nexus/nyx-containers";
    mainProgram = "nyx-containers";
  };
}
