# Online accounts service (session D-Bus, activated on demand) and its CLI.
{
  nyx,
  src,
  pkg-config,
  glib,
  openssl,
  python3,
}:
let
  busName = "io.github.design_nexus.nyx.Accounts.Preview";
in
nyx.buildWorkspace {
  pname = "nyx-accounts";
  inherit src;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ glib ];
  # The DAV fixture tests mint certificates and serve them from a local Python server.
  nativeCheckInputs = [
    openssl
    python3
  ];

  preCheck = nyx.privateBusPreCheck;

  postInstall = ''
    mkdir -p $out/share/dbus-1/services
    cat > $out/share/dbus-1/services/${busName}.service <<EOF
    [D-BUS Service]
    Name=${busName}
    Exec=$out/bin/nyx-accountsd
    EOF
  '';

  passthru = { inherit busName; };

  meta = {
    description = "Nyx Online Accounts service";
    homepage = "https://github.com/design-nexus/nyx-accounts";
    mainProgram = "nyx-accountsctl";
  };
}
