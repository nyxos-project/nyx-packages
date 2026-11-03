# Its Omarchy bar widget isn't installed; hyprctl comes from the system.
{ nyx, src }:
nyx.buildApp {
  pname = "nyx-weather";
  inherit src;
  meta = {
    description = "Forecasts, hourly graphs, radar, air quality and severe-weather alerts";
    homepage = "https://github.com/design-nexus/nyx-weather";
    mainProgram = "nyx-weather";
  };
}
