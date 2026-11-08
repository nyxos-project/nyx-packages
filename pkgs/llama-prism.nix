# PrismML's llama.cpp (the release Nyx AI Core pins, docs/PRISM.md in nyx-ai), built
# from source as Nyx AI Core's worker: llama-server and its libraries in
# lib/nyx-ai/llama.cpp, with every CPU variant and, by default, the Vulkan backend.
# llama-prism-cuda.nix is Prism's prebuilt CUDA release for NVIDIA's own driver.
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  shaderc,
  spirv-headers,
  vulkan-headers,
  vulkan-loader,
  vulkanSupport ? true,
}:
let
  tag = "prism-b12128-d7b2896";
in
stdenv.mkDerivation {
  pname = "llama-prism" + lib.optionalString (!vulkanSupport) "-cpu";
  version = "b12128";
  src = fetchFromGitHub {
    owner = "PrismML-Eng";
    repo = "llama.cpp";
    rev = "d7b28968306207fd176e7ff10796ccb6be607865";
    hash = "sha256-uG0p3hztns+OVLXEvnKnVdU/9b2g02hWs58dWVVtVaQ=";
  };
  nativeBuildInputs = [
    cmake
    ninja
  ]
  ++ lib.optionals vulkanSupport [
    shaderc
    spirv-headers
  ];
  buildInputs = lib.optionals vulkanSupport [
    vulkan-headers
    vulkan-loader
  ];
  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
    (lib.cmakeBool "GGML_BACKEND_DL" true)
    (lib.cmakeBool "GGML_NATIVE" false)
    (lib.cmakeBool "GGML_CPU_ALL_VARIANTS" true)
    (lib.cmakeBool "GGML_VULKAN" vulkanSupport)
    (lib.cmakeBool "GGML_CUDA" false)
    (lib.cmakeBool "LLAMA_BUILD_SERVER" true)
    (lib.cmakeBool "LLAMA_BUILD_TOOLS" true)
    (lib.cmakeBool "LLAMA_BUILD_EXAMPLES" false)
    (lib.cmakeBool "LLAMA_BUILD_TESTS" false)
    (lib.cmakeBool "LLAMA_BUILD_UI" false)
    # Nyx AI Core downloads models itself; the worker runs offline.
    (lib.cmakeBool "LLAMA_OPENSSL" false)
    (lib.cmakeFeature "LLAMA_BUILD_NUMBER" "12128")
    (lib.cmakeFeature "CMAKE_INSTALL_RPATH" "$ORIGIN")
    (lib.cmakeBool "CMAKE_BUILD_WITH_INSTALL_RPATH" true)
  ];
  # The server, its libraries and the backends it loads at run time, beside each other
  # as Nyx AI Core expects (it reads the release tag from .release).
  installPhase = ''
    runHook preInstall
    dir=$out/lib/nyx-ai/llama.cpp
    mkdir -p $dir
    install -m755 bin/llama-server $dir/llama-server
    find . -name '*.so*' \( -type f -o -type l \) -exec cp -P {} $dir/ \;
    echo ${tag} > $dir/.release
    install -Dm644 ../LICENSE $out/share/licenses/llama-prism/LICENSE
    runHook postInstall
  '';
  passthru = { inherit tag; };
  meta = {
    description = "PrismML's llama.cpp fork (ternary Bonsai types), the server Nyx AI Core runs";
    homepage = "https://github.com/PrismML-Eng/llama.cpp";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
