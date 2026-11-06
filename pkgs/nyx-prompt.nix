# Nyx Administrator Prompt: NyxOS's polkit authentication agent, one card in the Nyx
# theme that checks the password through polkit's helper socket. From the nyx-greeter
# repository, which it shares its sign-in pieces with.
{
  nyx,
  src,
  gtk4-layer-shell,
}:
nyx.buildApp {
  pname = "nyx-prompt";
  inherit src;
  cargoBuildFlags = [
    "-p"
    "nyx-prompt"
  ];
  cargoTestFlags = [
    "-p"
    "nyx-prompt"
  ];
  buildInputs = [ gtk4-layer-shell ];
  meta = {
    description = "Nyx Administrator Prompt: NyxOS's polkit authentication agent";
    homepage = "https://github.com/nyxos-project/nyx-greeter";
    mainProgram = "nyx-prompt";
  };
}
