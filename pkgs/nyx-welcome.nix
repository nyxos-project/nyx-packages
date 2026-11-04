# NyxOS's setup after installation: the theme, the software catalog's presets and
# sections, accounts, and one System Manager apply at the end. Opens at the first
# sign-in until it's been finished, and from the launcher any time.
{
  nyx,
  src,
}:
nyx.buildApp {
  pname = "nyx-welcome";
  inherit src;
  preCheck = nyx.privateBusPreCheck;
  userUnits = [ "apps/welcome/data/nyx-welcome.service" ];
  passthru.autostart."nyx-welcome" = "graphical-session.target";
  meta = {
    description = "NyxOS's setup after installation";
    homepage = "https://github.com/nyxos-project/nyx-welcome";
    mainProgram = "nyx-welcome";
  };
}
