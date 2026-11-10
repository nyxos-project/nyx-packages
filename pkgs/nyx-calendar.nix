# The calendar, its sync service and the Glimpse plugin.
{
  nyx,
  src,
  tzdata,
}:
nyx.buildApp {
  pname = "nyx-calendar";
  # Its action manifest (nyx calendar …, Glimpse, the Assistant): lib installActions.
  actions = [ "nyx-calendar" ];
  inherit src;
  glimpsePlugin = true;
  buildInputs = nyx.pimInputs;
  # libical reads time zones from TZDIR; the build sandbox has no /etc/zoneinfo.
  preCheck = ''
    export TZDIR=${tzdata}/share/zoneinfo
  '';
  userUnits = [ "apps/calendard/data/nyx-calendard.service" ];
  passthru.autostart."nyx-calendard" = "graphical-session.target";
  meta = {
    description = "Calendar with events, invitations, reminders and offline access";
    homepage = "https://github.com/design-nexus/nyx-calendar";
    mainProgram = "nyx-calendar";
  };
}
