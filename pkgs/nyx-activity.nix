# System monitor. systemctl, systemd-analyze, pkexec and nvidia-smi come from the
# system; pkexec must stay the setuid wrapper.
{
  nyx,
  src,
  hwdata,
  xdg-utils,
  xdg-terminal-exec,
}:
nyx.buildApp {
  pname = "nyx-activity";
  inherit src;
  runtimeInputs = [
    xdg-utils
    xdg-terminal-exec
  ];
  # GPU names come from hwdata's pci.ids, found under XDG_DATA_DIRS.
  preFixup = ''
    gappsWrapperArgs+=(--prefix XDG_DATA_DIRS : ${hwdata}/share)
  '';
  meta = {
    description = "System monitor with live graphs, process control and login startup";
    homepage = "https://github.com/design-nexus/nyx-activity";
    mainProgram = "nyx-activity";
  };
}
