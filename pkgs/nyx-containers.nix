# Docker and Incus manager. The docker and incus CLIs, their daemons and pkexec come
# from the system configuration (virtualisation.docker, virtualisation.incus).
{
  nyx,
  src,
  vte-gtk4,
  gtksourceview5,
  spice-gtk,
  libsecret,
  openssh,
}:
nyx.buildApp {
  pname = "nyx-containers";
  # Its action manifest (nyx containers …, Glimpse, the Assistant): lib installActions.
  actions = [ "nyx-containers" ];
  inherit src;
  # spice-client-glib shows a VM's screen inside its tab.
  buildInputs = [
    vte-gtk4
    gtksourceview5
    spice-gtk
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
