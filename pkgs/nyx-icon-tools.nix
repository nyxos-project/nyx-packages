# `nyx-icons`: recolours Nyx app icons (and opted-in third-party launchers) to follow
# the Nyx theme. The tool comes from the nyx suite repository; the renderer, glyphs and
# themes from the same nyx-design revision as nyx-icons, so Nyx Dark matches exactly.
{
  lib,
  stdenvNoCC,
  nyx,
  src,
  design,
  python3,
  makeWrapper,
  wrapGAppsHook3,
  gobject-introspection,
  gtk3,
  librsvg,
  desktop-file-utils,
}:
let
  python = python3.withPackages (ps: [ ps.pygobject3 ]);
in
stdenvNoCC.mkDerivation {
  pname = "nyx-icon-tools";
  version = nyx.version "0.1.0" src;
  inherit src;

  nativeBuildInputs = [
    makeWrapper
    wrapGAppsHook3
    gobject-introspection
    python
  ];
  # GTK 3 looks up third-party launcher icons; librsvg lets GdkPixbuf read SVG logos.
  buildInputs = [
    gtk3
    librsvg
  ];

  dontBuild = true;
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall
    tools=$out/libexec/nyx-icons
    install -Dm644 tools/icons.py tools/theme.py -t $tools
    install -Dm644 ${design}/crates/nyx-icons/{make_icons.py,app-glyphs.json,third-party-glyphs.json} \
      -t $tools/assets
    # As tools/package-icons.py bundles them: the shipped themes, for following a theme
    # without any app installed.
    python3 - ${design}/crates/nyx-theme-core/themes $tools/assets/themes.json <<'EOF'
    import json, pathlib, sys, tomllib
    themes = {p.stem: tomllib.loads(p.read_text()) for p in sorted(pathlib.Path(sys.argv[1]).glob('*.toml'))}
    # Without them every theme falls back to the same colours.
    assert 'nyx-dark' in themes, f"no shipped themes in {sys.argv[1]}"
    pathlib.Path(sys.argv[2]).write_text(json.dumps(themes, indent=1, sort_keys=True) + '\n')
    EOF
    runHook postInstall
  '';

  # gappsWrapperArgs is filled in preFixup.
  postFixup = ''
    makeWrapper ${python}/bin/python3 $out/bin/nyx-icons \
      --add-flags $out/libexec/nyx-icons/icons.py \
      "''${gappsWrapperArgs[@]}" \
      --set NYX_ICONS_MANAGED_UNITS 1 \
      --prefix PATH : ${
        lib.makeBinPath [
          gtk3
          desktop-file-utils
        ]
      }
  '';

  meta = {
    description = "Recolour Nyx launcher icons to follow the Nyx theme";
    homepage = "https://github.com/design-nexus/nyx";
    license = lib.licenses.mit;
    mainProgram = "nyx-icons";
    platforms = lib.platforms.linux;
  };
}
