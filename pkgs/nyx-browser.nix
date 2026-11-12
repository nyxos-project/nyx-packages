# Browser: the Zen 1.24.2b source fork with Nyx's chrome, from the CI/release tarball
# (browser binary plus nyx-browser-bridge). Not built from source here; the engine is
# too large. Pin version and hash when UPDATING.md says to move the release.
{
  lib,
  stdenv,
  fetchurl,
  wrapGAppsHook3,
  autoPatchelfHook,
  patchelfUnstable,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  writeText,
  alsa-lib,
  curl,
  dbus-glib,
  ffmpeg_8,
  gtk3,
  libGL,
  libXtst,
  libva,
  pciutils,
  pipewire,
  adwaita-icon-theme,
}:
let
  version = "1.24.2b-1";
  zen = "1.24.2b";
  pname = "nyx-browser";
  appId = "io.github.design_nexus.nyx.Browser";
  hostId = "io.github.design_nexus.nyx.browser";
  libName = "nyx-browser-${version}";

  # Disable the in-app update UI that Zen would show; packaging owns updates.
  policiesJson = writeText "policies.json" (
    builtins.toJSON {
      policies = {
        DisableAppUpdate = true;
        AppAutoUpdate = false;
      };
    }
  );
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/design-nexus/nyx-browser/releases/download/v${version}/nyx-browser-${version}.linux-x86_64.tar.xz";
    hash = "sha256-IB7D32S/hyCBZLm5xtProBw+gfWnRnczynVG1/p85/0=";
  };

  nativeBuildInputs = [
    wrapGAppsHook3
    autoPatchelfHook
    patchelfUnstable
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    gtk3
    adwaita-icon-theme
    alsa-lib
    dbus-glib
    libXtst
    ffmpeg_8
  ];

  runtimeDependencies = [
    curl
    libva.out
    pciutils
    libGL
  ];

  appendRunpaths = [
    "${libGL}/lib"
    "${pipewire}/lib"
  ];

  # Firefox relocates by hand from a fixed offset.
  patchelfFlags = [ "--no-clobber-old-sections" ];

  # The release tarball's top folder is `nyx-browser/`.
  sourceRoot = "nyx-browser";

  desktopItems = [
    (makeDesktopItem {
      name = appId;
      desktopName = "Browser";
      genericName = "Web Browser";
      comment = "Browse the web, with vertical or horizontal tabs";
      exec = "nyx-browser %U";
      icon = appId;
      startupNotify = true;
      startupWMClass = appId;
      terminal = false;
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeTypes = [
        "text/html"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      actions = {
        new-window = {
          name = "New Window";
          exec = "nyx-browser --new-window";
        };
        new-private-window = {
          name = "New Private Window";
          exec = "nyx-browser --private-window";
        };
      };
    })
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/${libName}"
    cp -a . "$out/lib/${libName}"

    mkdir -p "$out/bin"
    # The binary looks next to itself for omni.ja and libs.
    makeWrapper "$out/lib/${libName}/nyx-browser" "$out/bin/nyx-browser" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ ffmpeg_8 ]}" \
      --set MOZ_SYSTEM_DIR "$out/lib/mozilla/native-messaging-hosts" \
      --add-flags "--name=${appId}" \
      --add-flags "--class=${appId}"

    ln -s "$out/lib/${libName}/nyx-browser-bridge" "$out/bin/nyx-browser-bridge"

    mkdir -p "$out/lib/${libName}/distribution"
    ln -sf ${policiesJson} "$out/lib/${libName}/distribution/policies.json"

    # Native messaging: only the Nyx integration extension may talk to the bridge.
    mkdir -p "$out/lib/mozilla/native-messaging-hosts"
    cat >"$out/lib/mozilla/native-messaging-hosts/${hostId}.json" <<EOF
{
  "name": "${hostId}",
  "description": "Browser",
  "path": "$out/lib/${libName}/nyx-browser-bridge",
  "type": "stdio",
  "allowed_extensions": ["nyx-integration@design-nexus.github.io"]
}
EOF

    # Nyx actions (nyx browser …) and D-Bus activation of the bridge's actions server.
    mkdir -p "$out/share/nyx/actions" "$out/share/dbus-1/services"
    "$out/lib/${libName}/nyx-browser-bridge" actions --describe >"$out/share/nyx/actions/${appId}.json"
    cat >"$out/share/dbus-1/services/${appId}.service" <<EOF
[D-BUS Service]
Name=${appId}
Exec=$out/lib/${libName}/nyx-browser-bridge actions
EOF

    # Icon from the brand, with a PNG fallback from the chrome defaults.
    mkdir -p "$out/share/icons/hicolor/scalable/apps" "$out/share/icons/hicolor/128x128/apps"
    if [ -f browser/chrome/icons/default/default128.png ]; then
      install -m644 browser/chrome/icons/default/default128.png \
        "$out/share/icons/hicolor/128x128/apps/${appId}.png"
    fi
    for size in 16 32 48 64 128; do
      if [ -f browser/chrome/icons/default/default$size.png ]; then
        mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
        install -m644 browser/chrome/icons/default/default$size.png \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/${appId}.png"
      fi
    done

    runHook postInstall
  '';

  passthru = {
    inherit zen appId hostId;
    binaryName = "nyx-browser";
    updateScript = null;
  };

  meta = {
    description = "Nyx Browser: Zen's engine with Nyx's chrome, theme and integrations";
    homepage = "https://github.com/design-nexus/nyx-browser";
    downloadPage = "https://github.com/design-nexus/nyx-browser/releases";
    changelog = "https://github.com/design-nexus/nyx-browser/releases/tag/v${version}";
    license = lib.licenses.mpl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "nyx-browser";
  };
}
