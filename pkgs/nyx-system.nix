# NyxOS's system services: the System Manager (a root D-Bus service started on demand),
# its nyx-system command, nyx-themed (the user's theme service, which owns
# io.github.design_nexus.nyx.Theme on the session bus) and the software catalog.
{
  nyx,
  src,
  pkg-config,
  coreutils,
  libxcrypt,
}:
nyx.buildWorkspace {
  pname = "nyx-system";
  inherit src;
  nativeBuildInputs = [ pkg-config ];
  # nyx-recovery checks an administrator's password with crypt(3).
  buildInputs = [ libxcrypt ];
  postInstall = ''
    install -Dm644 data/io.github.nyxos_project.system.policy -t $out/share/polkit-1/actions
    install -Dm644 data/io.github.nyxos_project.System.conf -t $out/share/dbus-1/system.d
    install -Dm644 crates/nyx-catalog/catalog.toml -t $out/share/nyx
    mkdir -p $out/share/dbus-1/system-services $out/share/dbus-1/services
    cat > $out/share/dbus-1/system-services/io.github.nyxos_project.System.service <<EOF
    [D-BUS Service]
    Name=io.github.nyxos_project.System
    Exec=${coreutils}/bin/false
    User=root
    SystemdService=nyx-system-manager.service
    EOF
    cat > $out/share/dbus-1/services/io.github.design_nexus.nyx.Theme.service <<EOF
    [D-BUS Service]
    Name=io.github.design_nexus.nyx.Theme
    Exec=${coreutils}/bin/false
    SystemdService=nyx-themed.service
    EOF
  '';
  meta = {
    description = "NyxOS's System Manager, configuration layers and theme service";
    homepage = "https://github.com/nyxos-project/nyx-system";
    mainProgram = "nyx-system";
  };
}
