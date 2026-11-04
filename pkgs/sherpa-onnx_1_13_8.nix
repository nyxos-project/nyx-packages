# sherpa-onnx 1.13.8 for Nyx Assistant's streaming speech recognition: its Rust
# bindings are generated for that version's C API, and nixpkgs 26.05 has 1.12.38.
# nixpkgs' recipe without Python or the websocket server, with the bundled sources
# 1.13.8 pins. Drop this once nixpkgs ships 1.13.8 or later.
{
  lib,
  sherpa-onnx,
  fetchFromGitHub,
  fetchurl,
  eigen_5,
}:
let
  # Copied into the source tree, where CMake's FetchContent looks before downloading.
  cache = lib.mapAttrsToList (name: src: "cp ${fetchurl src} ./${name}") {
    "espeak-ng-ed530aa113046142eb5115cf2fc9157854d0ffe1.zip" = {
      url = "https://github.com/csukuangfj/espeak-ng/archive/ed530aa113046142eb5115cf2fc9157854d0ffe1.zip";
      hash = "sha256-5OJiy+NPf+IfkfG6M5fyco4fMOr7rnhT8rdTqe0T8N0=";
    };
    "kaldi-native-fbank-1.22.3.tar.gz" = {
      url = "https://github.com/csukuangfj/kaldi-native-fbank/archive/refs/tags/v1.22.3.tar.gz";
      hash = "sha256-kXbMZvx84e34XPNVsG4yDFfbYpffdCd/V1GDRoiTz2E=";
    };
    "simple-sentencepiece-0.7.tar.gz" = {
      url = "https://github.com/pkufool/simple-sentencepiece/archive/refs/tags/v0.7.tar.gz";
      hash = "sha256-F0ioIgYKNbqp9mCfhO/I61TcDnS57OPYI2e3EZ/cda8=";
    };
    "kaldifst-1.8.0.tar.gz" = {
      url = "https://github.com/k2-fsa/kaldifst/archive/refs/tags/v1.8.0.tar.gz";
      hash = "sha256-PyR7flokCQcSAvXivGIABg9mcowKNEPAOSOtJyPgQLM=";
    };
    "kaldi-decoder-0.3.0.tar.gz" = {
      url = "https://github.com/k2-fsa/kaldi-decoder/archive/refs/tags/v0.3.0.tar.gz";
      hash = "sha256-ufNM+0/TsTRBAO6tee9NN6oVliJ0ueMFbeNFAh92obA=";
    };
    "cargs-1.0.3.tar.gz" = {
      url = "https://github.com/likle/cargs/archive/refs/tags/v1.0.3.tar.gz";
      hash = "sha256-3bolvTXpxsdbxwbBJgAbjOjghNQO83BQ5qppY+g264s=";
    };
    "piper-phonemize-f3ff95afc03640bc1399e113e83361192a2fafb4.zip" = {
      url = "https://github.com/csukuangfj/piper-phonemize/archive/f3ff95afc03640bc1399e113e83361192a2fafb4.zip";
      hash = "sha256-2cyk4r3H1t2N/7lqRmgoPb0/d6nBlKPlMMHo66lAal0=";
    };
    "openfst-1.8.5-2026-07-09.tar.gz" = {
      url = "https://github.com/csukuangfj/openfst/archive/refs/tags/v1.8.5-2026-07-09.tar.gz";
      hash = "sha256-L/cSoylS/LAdNREhpryMz0/cayqgbOjfKzCV3t1RjA4=";
    };
    "hclust-cpp-2026-02-25.tar.gz" = {
      url = "https://github.com/csukuangfj/hclust-cpp/archive/refs/tags/2026-02-25.tar.gz";
      hash = "sha256-jxTgJMcJ1zr7QK5pyyLeS3Pbpny85A8uUYgT2oE5q1Y=";
    };
  };
in
(sherpa-onnx.override {
  pythonSupport = false;
  websocketSupport = false;
  eigen = eigen_5;
}).overrideAttrs
  {
    version = "1.13.8";
    src = fetchFromGitHub {
      owner = "k2-fsa";
      repo = "sherpa-onnx";
      tag = "v1.13.8";
      hash = "sha256-yAkjeRJXSiGW7Pr6cmHKUeYiWZyd88raEMdaJvYhQLM=";
    };
    preConfigure = lib.concatLines cache;
  }
