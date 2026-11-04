# Nyx Locker: the NyxOS lock screen, on the Wayland session-lock protocol, with every
# way in (password, fingerprint, face, security key) as its own PAM service at once.
# From the nyx-greeter repository, which it shares its sign-in pieces with.
{
  nyx,
  src,
  gtk4-layer-shell,
  linux-pam,
}:
nyx.buildApp {
  pname = "nyx-locker";
  inherit src;
  cargoBuildFlags = [
    "-p"
    "nyx-locker"
  ];
  cargoTestFlags = [
    "-p"
    "nyx-locker"
    "-p"
    "nyx-lock-core"
    "-p"
    "nyx-signin-ui"
  ];
  buildInputs = [
    gtk4-layer-shell
    linux-pam
  ];
  meta = {
    description = "Nyx Locker: the NyxOS lock screen";
    homepage = "https://github.com/nyxos-project/nyx-greeter";
    mainProgram = "nyx-locker";
  };
}
