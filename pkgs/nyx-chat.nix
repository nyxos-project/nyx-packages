# Chat for local models. This computer's models run in Nyx AI Core (nyx.ai, on by
# default with Chat); the Ollama backend works with services.ollama.
{
  nyx,
  src,
  wl-clipboard,
  grim,
  slurp,
  pipewire,
  poppler-utils,
  xdg-utils,
  libsecret,
}:
nyx.buildApp {
  pname = "nyx-chat";
  inherit src;
  # Screenshots and clipboard as attachments, voice input, PDF text; secret-tool keeps
  # the search keys.
  runtimeInputs = [
    libsecret
    wl-clipboard
    grim
    slurp
    pipewire
    poppler-utils
    xdg-utils
  ];
  meta = {
    description = "Desktop chat for local models, with tools and a model marketplace";
    homepage = "https://github.com/design-nexus/nyx-chat";
    mainProgram = "nyx-chat";
  };
}
