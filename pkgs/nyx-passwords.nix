# Vaultwarden client: the app, its vault service, the assistant and settings
# extensions, and the browser bridge with its native-messaging manifests. The
# polkit-confirmed sign-in and the TPM key broker come with Nyx Biometrics
# (nyx.biometrics); without it the vault works with its master password.
{
  nyx,
  src,
  cmake,
  cacert,
  libsecret,
}:
nyx.buildApp {
  pname = "nyx-passwords";
  # Its action manifest (nyx passwords …, Glimpse, the Assistant): lib installActions.
  actions = [ "nyx-passwords" ];
  inherit src;
  # aws-lc-sys builds its C library with CMake.
  nativeBuildInputs = [ cmake ];
  dontUseCmakeConfigure = true;
  runtimeInputs = [ libsecret ];
  # reqwest's platform verifier won't build a client without a CA bundle, even for the
  # tests' plain-HTTP stand-in servers.
  nativeCheckInputs = [ cacert ];
  preCheck = nyx.privateBusPreCheck;

  userUnits = [ "apps/passwords/data/nyx-passwords.service" ];
  passthru.autostart."nyx-passwords" = "graphical-session.target";

  # The browsers start the bridge from these manifests: Firefox reads
  # lib/mozilla/native-messaging-hosts, Chromium /etc/chromium/native-messaging-hosts.
  postInstall = ''
    host=io.github.design_nexus.nyx.passwords
    for target in firefox:lib/mozilla/native-messaging-hosts chromium:etc/chromium/native-messaging-hosts; do
      mkdir -p $out/''${target#*:}
      sed "s|@BRIDGE@|$out/bin/nyx-passwords-bridge|" apps/passwords/browser/hosts/''${target%%:*}.json \
        > $out/''${target#*:}/$host.json
    done
  '';

  meta = {
    description = "Password manager for a self-hosted Vaultwarden server";
    homepage = "https://github.com/design-nexus/nyx-passwords";
    mainProgram = "nyx-passwords";
  };
}
