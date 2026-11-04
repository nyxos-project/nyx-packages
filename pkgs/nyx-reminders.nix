# Task lists, their sync service and the Glimpse plugin.
{
  nyx,
  src,
  tzdata,
}:
nyx.buildApp {
  pname = "nyx-reminders";
  inherit src;
  glimpsePlugin = true;
  buildInputs = nyx.pimInputs;
  # libical reads time zones from TZDIR; the build sandbox has no /etc/zoneinfo.
  preCheck = ''
    export TZDIR=${tzdata}/share/zoneinfo
  '';
  userUnits = [ "apps/remindersd/data/nyx-remindersd.service" ];
  passthru.autostart."nyx-remindersd" = "graphical-session.target";
  meta = {
    description = "Today, scheduled and flagged lists from every account";
    homepage = "https://github.com/design-nexus/nyx-reminders";
    mainProgram = "nyx-reminders";
  };
}
