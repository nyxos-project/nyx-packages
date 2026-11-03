# libical 4, as Arch ships it, for the Nyx PIM apps (nyx-core's nyx-pim). nixpkgs has
# 3.0, whose libical-glib renames functions and doesn't add TZID parameters or resolve
# built-in zones the way nyx-pim relies on. Everything else keeps nixpkgs' libical.
# Drop this once nixpkgs ships libical 4.
{
  libical,
  fetchFromGitHub,
  tzdata,
}:
libical.overrideAttrs (old: {
  version = "4.0.7";
  src = fetchFromGitHub {
    owner = "libical";
    repo = "libical";
    rev = "v4.0.7";
    hash = "sha256-FrSFOP0VICdGIKBSAuVLFIqdctpTg/c8eMAkOU1odEM=";
  };
  # nixpkgs' patches backport TZDIR support to 3.0; 4 has it.
  patches = [ ];
  # libical 4 renamed its options. As Arch builds it, without documentation.
  cmakeFlags = [
    "-DLIBICAL_BUILD_TESTING=True"
    "-DLIBICAL_BUILD_DOCS=False"
    "-DLIBICAL_GLIB_BUILD_DOCS=False"
    "-DLIBICAL_BUILD_EXAMPLES=False"
    "-DLIBICAL_GOBJECT_INTROSPECTION=True"
    "-DLIBICAL_GLIB_VAPI=True"
    "-DLIBICAL_JAVA_BINDINGS=False"
    "-DCMAKE_DISABLE_FIND_PACKAGE_BerkeleyDB=True"
  ];
  # The regression suite unsets TZDIR and expects /usr/share/zoneinfo or /etc/zoneinfo,
  # which the build sandbox lacks (NixOS has /etc/zoneinfo). The other suites run.
  installCheckPhase = ''
    runHook preInstallCheck
    export TZDIR=${tzdata}/share/zoneinfo
    ctest --output-on-failure --exclude-regex '^regression$'
    runHook postInstallCheck
  '';
  meta = old.meta // {
    changelog = "https://github.com/libical/libical/raw/v4.0.7/ReleaseNotes.txt";
  };
})
