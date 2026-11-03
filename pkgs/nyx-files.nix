# File manager (a Strata fork, GPL-3.0-or-later) and its RAR helper, with the
# org.freedesktop.FileManager1 D-Bus service.
{
  lib,
  nyx,
  src,
  glib,
  gtksourceview5,
  poppler,
  gst_all_1,
  bubblewrap,
  xdg-utils,
  coreutils,
  bash,
  ffmpeg,
  ffmpegthumbnailer,
  libraw,
  squashfsTools,
  git,
  fontconfig,
  python3,
}:
nyx.buildApp {
  pname = "nyx-files";
  inherit src;
  # glib-compile-resources for the GResource bundle build.rs makes.
  nativeBuildInputs = [ glib ];
  buildInputs = [
    gtksourceview5
    poppler
  ]
  ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-libav
  ]);

  env = {
    STRATA_BUILD_COMMIT = src.rev;
    # Files resolves sandbox and MIME helpers only from trusted folders; a package
    # embeds its own at build time.
    STRATA_TRUSTED_COMMAND_PATH = lib.makeBinPath [
      bubblewrap
      xdg-utils
      coreutils
      bash
    ];
  };

  # Thumbnails and previews; libraw's raw-identify and simple_dcraw read RAW photos
  # (nixpkgs marks dcraw insecure).
  runtimeInputs = [
    ffmpeg
    ffmpegthumbnailer
    libraw
    squashfsTools
    git
    fontconfig
  ];

  # The tests run the same helpers, and Python for scripted actions.
  nativeCheckInputs = [
    ffmpeg
    ffmpegthumbnailer
    libraw
    squashfsTools
    git
    fontconfig
    python3
  ];
  preCheck = ''
    export HOME=$(mktemp -d)
  '';
  checkFlags = map (test: "--skip=${test}") (
    lib.filter (line: line != "" && !lib.hasPrefix "#" line) (
      lib.splitString "\n" (builtins.readFile ./nyx-files-skipped-tests.txt)
    )
  );

  dbusServices = [ "data/io.github.design_nexus.nyx.Files.FileManager1.service" ];

  meta = {
    description = "File manager for the Nyx desktop";
    homepage = "https://github.com/design-nexus/nyx-files";
    license = lib.licenses.gpl3Plus;
    mainProgram = "nyx-files";
  };
}
