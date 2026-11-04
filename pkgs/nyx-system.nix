# NyxOS's system services: the System Manager (a root D-Bus service started on demand),
# its nyx-system command, nyx-themed (the user's theme service) and the software catalog.
{
  nyx,
  src,
  pkg-config,
  gtk4,
  coreutils,
}:
nyx.buildWorkspace {
  pname = "nyx-system";
  inherit src;
  nativeBuildInputs = [ pkg-config ];
  # nyx-themed resolves themes with nyx-design's nyx-theme, which links GTK.
  buildInputs = [ gtk4 ];
  postInstall = ''
    install -Dm644 data/io.github.nyxos_project.system.policy -t $out/share/polkit-1/actions
    install -Dm644 data/io.github.nyxos_project.System.conf -t $out/share/dbus-1/system.d
    install -Dm644 crates/nyx-catalog/catalog.toml -t $out/share/nyx
    mkdir -p $out/share/dbus-1/system-services
    cat > $out/share/dbus-1/system-services/io.github.nyxos_project.System.service <<EOF
    [D-BUS Service]
    Name=io.github.nyxos_project.System
    Exec=${coreutils}/bin/false
    User=root
    SystemdService=nyx-system-manager.service
    EOF
  '';
  meta = {
    description = "NyxOS's System Manager, configuration layers and theme service";
    homepage = "https://github.com/nyxos-project/nyx-system";
    mainProgram = "nyx-system";
  };
}
