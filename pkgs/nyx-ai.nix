# Nyx AI Core: nyx-aid (the shared local model runtime), the nyx-ai command, and the
# user socket and service that start it on first use (the socket also holds the
# OpenAI-compatible API on 127.0.0.1:8080). Its worker is `llama`: Prism's llama.cpp
# with Vulkan by default; the NixOS module swaps in the CUDA build on NVIDIA's driver.
{
  nyx,
  src,
  makeWrapper,
  llama,
}:
nyx.buildWorkspace {
  pname = "nyx-ai";
  inherit src;
  cargoBuildFlags = [
    "-p"
    "nyx-aid"
    "-p"
    "nyx-ai"
  ];
  # The workspace's tests, including the daemon against its stand-in worker.
  cargoTestFlags = [ "--workspace" ];
  nativeBuildInputs = [ makeWrapper ];
  userUnits = [
    "data/nyx-aid.service"
    "data/nyx-aid.socket"
  ];
  postInstall = ''
    rm -f $out/bin/nyx-ai-stub-worker
    wrapProgram $out/bin/nyx-aid --set-default NYX_AI_LIB ${llama}/lib/nyx-ai/llama.cpp
  '';
  passthru = { inherit llama; };
  meta = {
    description = "Nyx AI Core: the shared local model runtime (llama.cpp) for Nyx apps and coding tools";
    homepage = "https://github.com/design-nexus/nyx-ai";
    mainProgram = "nyx-ai";
  };
}
