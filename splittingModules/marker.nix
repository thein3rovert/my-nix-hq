{ lib, config, ... }:
let
  # Here we are assigning values to option define in
  # another module
  # EXAMPLE: users.<name>.departure.location
  # TODO: Need a way to set the user

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

  # We want multiple uses to define a list of markers

  # Here we have a submodules of our
  # userType and their deprarture markerType
  # which will be of type location(str)
  userType = lib.types.submodule {
    options = {
      # Location == departure
      departure = lib.mkOption {
        type = markerType;
        default = { };
      };
    };
  };
in
{
  # Create a list of markers of type markerType
  options = {
    # Define our userType
    # - we need a attribute set of users of type
    # user type with departure(location)
    users = lib.mkOption {
      type = lib.types.attrsOf userType;
    };

    map.markers = lib.mkOption {
      type = lib.types.listOf markerType;
    };
  };

  # Making use of the marker in this case we only
  # using one marker with location of type str.
  config = {
    #   map.markers = [
    #     { location = "new york"; }
    #   ];

    # Check if location is not null
    # Take all depacture(location from users)
    map.markers = lib.filter (marker: marker.location != null) (
      lib.concatMap (user: [
        user.departure
      ]) (lib.attrValues config.users)
    );

    # In case we do not pass in a value for center or zoom
    # then default is center
    map.center = lib.mkIf (lib.length config.map.markers >= 1) null;

    map.zoom = lib.mkIf (lib.length config.map.markers >= 2) null;

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
