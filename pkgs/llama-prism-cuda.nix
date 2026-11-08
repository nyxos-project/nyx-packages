# PrismML's prebuilt CUDA release of the llama.cpp Nyx AI Core pins, for NVIDIA's own
# driver: no compile, with CUDA's runtime and cuBLAS from nixpkgs (it was built with
# CUDA 12.8; nixpkgs' 12.9 runtime runs it) and libcuda from the driver. Unfree, so a
# system lists `unfree` (passthru) in its allowed packages.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  addDriverRunpath,
  cudaPackages,
}:
let
  tag = "prism-b12128-d7b2896";
in
stdenv.mkDerivation {
  pname = "llama-prism-cuda";
  version = "b12128";
  src = fetchurl {
    url = "https://github.com/PrismML-Eng/llama.cpp/releases/download/${tag}/llama-${tag}-bin-linux-cuda-12.8-x64.tar.gz";
    hash = "sha256-2ACoBylec3QtTf99OqOjQ41hR4gsm2Ce+LrLozO+rQE=";
  };
  sourceRoot = "llama-${tag}";
  nativeBuildInputs = [
    autoPatchelfHook
    addDriverRunpath
  ];
  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    (lib.getLib cudaPackages.cuda_cudart)
    (lib.getLib cudaPackages.libcublas)
  ];
  # The driver's library, found at run time through the driver runpath.
  autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    dir=$out/lib/nyx-ai/llama.cpp
    mkdir -p $dir
    install -m755 llama-server $dir/llama-server
    cp -P *.so* $dir/
    echo ${tag} > $dir/.release
    runHook postInstall
  '';
  postFixup = ''
    addDriverRunpath $out/lib/nyx-ai/llama.cpp/libggml-cuda.so
  '';
  passthru = {
    inherit tag;
    # What a system must allow for this package (nixpkgs.config.allowUnfreePredicate).
    unfree = [
      "llama-prism-cuda"
      "cuda_cudart"
      "libcublas"
      "cuda_cccl"
      "cuda_nvcc"
    ];
  };
  meta = {
    description = "PrismML's llama.cpp fork, prebuilt for NVIDIA CUDA, the server Nyx AI Core runs";
    homepage = "https://github.com/PrismML-Eng/llama.cpp";
    # MIT itself, but it links NVIDIA's CUDA runtime and cuBLAS.
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}
