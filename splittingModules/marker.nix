{ lib, config, ... }:
let
  # Here we are assigning values to option define in
  # another module
  # We create a submodules that includes
  # a markerType with a location option
  markerType = lib.types.submodule {
    # Each of the marker will have a location of
    # type string
    options = {
      location = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
  };
in
{
  # Create a list of markers of type markerType
  options = {
    map.markers = lib.mkOption {
      type = lib.types.listOf markerType;
    };
  };

  # Making use of the marker in this case we only
  # using one marker with location of type str.
  config = {
    map.markers = [
      { location = "new york"; }
    ];

    # Here we buiding a request param for the
    # geolocation api.
    # It runs the geocode script with marker location
    # as input
    requestParams =
      let
        paramForMarker = builtins.map (
          marker: "$(${config.scripts.geocode}/bin/geocode ${lib.escapeShellArg marker.location})"
        ) config.map.markers;
      in
      # This join the marker command string with | betweem them.
      [ "markers=\"${lib.concatStringsSep "|" paramForMarker}\"" ];
  };
}
