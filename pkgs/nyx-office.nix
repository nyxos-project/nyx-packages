{
  nyx,
  src,
  runtimeShell,
  gtksourceview5,
  libspelling,
  qpdf,
}:
nyx.buildApp {
  pname = "nyx-office";
  inherit src;
  buildInputs = [
    gtksourceview5
    libspelling
  ];
  runtimeInputs = [ qpdf ];

  # The desktop entries launch nyx-write, nyx-sheets and nyx-present.
  postInstall = ''
    for app in write sheets present; do
      cat > $out/bin/nyx-$app <<EOF
    #!${runtimeShell}
    exec $out/bin/nyx-office --app $app "\$@"
    EOF
      chmod +x $out/bin/nyx-$app
    done
  '';

  meta = {
    description = "Write, Sheets and Present: documents, spreadsheets and slides";
    homepage = "https://github.com/design-nexus/nyx-office";
    mainProgram = "nyx-office";
  };
}
