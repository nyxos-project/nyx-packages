# Chat for local models. The llama.cpp backend stays off: the repository installs a
# prebuilt CUDA build of PrismML's llama.cpp fork into ~/.local/lib with its own user
# unit. The Ollama backend works with services.ollama.
{
  nyx,
  src,
  wl-clipboard,
  grim,
  slurp,
  pipewire,
  poppler-utils,
  xdg-utils,
}:
nyx.buildApp {
  pname = "nyx-chat";
  inherit src;
  # Screenshots and clipboard as attachments, voice input, PDF text.
  runtimeInputs = [
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
