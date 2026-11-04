# Nyx Biometrics: the sign-in broker (nyx-authd), the TPM key service (nyx-auth-keyd),
# nyx-authctl, the root helper for security-key registration, and the PAM gate. On
# NixOS the PAM stacks themselves come from the NixOS module (nyx.biometrics), so the
# helper's PAM and login-screen verbs aren't used.
{
  nyx,
  src,
  pam,
}:
let
  lib = "lib/nyx-biometrics";
in
nyx.buildWorkspace {
  pname = "nyx-biometrics";
  inherit src;
  # The helper and the gate run PAM conversations (pam_authenticate) themselves.
  buildInputs = [ pam ];
  preCheck = nyx.privateBusPreCheck;
  # polkit lets pkexec run the helper only from the path its actions name; the system
  # profile has it there (nyx-authctl looks for it there when /usr/local has none).
  postPatch = ''
    substituteInPlace crates/nyx-auth-helper/data/io.github.design_nexus.nyx.auth.policy \
      --replace-fail /usr/local/lib/nyx-biometrics/nyx-auth-helper /run/current-system/sw/${lib}/nyx-auth-helper
  '';
  postInstall = ''
    mkdir -p $out/${lib}
    for name in nyx-auth-helper nyx-auth-gate nyx-auth-notify nyx-auth-keyd; do
      mv $out/bin/$name $out/${lib}/
    done
    rm -f $out/bin/pam-try
    install -Dm644 -t $out/share/polkit-1/actions \
      crates/nyx-auth-helper/data/io.github.design_nexus.nyx.auth.policy \
      crates/nyx-auth-keyd/data/io.github.design_nexus.nyx.auth.unlock.policy
    install -Dm644 -t $out/lib/systemd/system \
      crates/nyx-auth-keyd/data/nyx-auth-keyd.socket crates/nyx-auth-keyd/data/nyx-auth-keyd@.service
    substituteInPlace $out/lib/systemd/system/nyx-auth-keyd@.service \
      --replace-fail /usr/lib/nyx-biometrics/nyx-auth-keyd $out/${lib}/nyx-auth-keyd
    # The broker starts when a Nyx app first asks.
    mkdir -p $out/share/dbus-1/services
    cat > $out/share/dbus-1/services/io.github.design_nexus.nyx.Auth.service <<EOF
    [D-BUS Service]
    Name=io.github.design_nexus.nyx.Auth
    Exec=$out/bin/nyx-authd
    EOF
  '';
  meta = {
    description = "Face, fingerprint and security-key sign-in with one policy, and the Nyx sign-in broker";
    homepage = "https://github.com/design-nexus/nyx-biometrics";
    mainProgram = "nyx-authctl";
  };
}
