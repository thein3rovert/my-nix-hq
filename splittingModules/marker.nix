{ lib, config, ... }:
let
  # Here we are assigning values to option define in
  # another module
  # EXAMPLE: users.<name>.departure.location
  # TODO: Need a way to set the user

  # Extracts the first alphanumeric character (A-Z, 0-9) from the string, ignoring case and leading non-alphanumerics
  firstUpperAlnum =
    str: lib.mapNullable lib.head (builtins.match "[^A-Z0-9]*([A-Z0-9]).*" (lib.toUpper str));

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

      style.label = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching "[A-Z0-9]");
        default = null;
      };

      style.color = lib.mkOption {
        type = lib.types.nullOr markerColorType;
        default = "blue";
      };

      # Set marker size
      style.size = lib.mkOption {
        type = lib.types.enum [
          "tiny"
          "small"
          "medium"
          "large"
        ];
        default = [ "small" ];
      };
    };
  };

  # Color type options for the marker label, if the color provided is of #fffff or "colorName"
  markerColorType = lib.types.either (lib.types.strMatching "0x[0-9A-F]{6}") (
    lib.types.enum [
      "black"
      "brown"
      "green"
      "purple"
      "yellow"
      "blue"
      "grey"
      "orange"
      "red"
      "white"
    ]
  );

  # We want multiple uses to define a list of markers

  # Here we have a submodules of our
  # userType and their departure markerType
  # which will be of type location(str)
  userType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        # Location == departure
        departure = lib.mkOption {
          type = markerType;
          default = { }; # Allows us to set a default attrbute of type user in config
        };
      };
      config = {
        departure.style.label = lib.mkDefault (firstUpperAlnum name);
      };
    }
  );

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
    # Take all departure (location from users)
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
        paramForMarker =
          marker:
          let
            size =
              {
                tiny = "tiny";
                small = "small";
                medium = "mid";
                large = "null";
              }
              .${marker.style.size};
            color = "${marker.style.color}";

            # 'attributes' is a list of strings describing the marker.
            # If the marker has a label, we include it as "label:<label>"
            # Then we add a geocode command to convert the marker's location to coordinates
            attributes = lib.optional (marker.style.label != null) "label:${marker.style.label}" ++ [
              "size:${size}"
              "color:${color}"
              # "color:${marker.style.color}"
              "$(${config.scripts.geocode}/bin/geocode ${lib.escapeShellArg marker.location})"
            ];
          in
          # Join all the attributes for a marker with "|" and wrap in markers=""
          "markers=\"${lib.concatStringsSep "|" attributes}\"";
      in
      # Apply the 'paramForMarker' function to all markers in the config
      builtins.map paramForMarker config.map.markers;

    #   paramForMarker = builtins.map (
    #     marker: "$(${config.scripts.geocode}/bin/geocode ${lib.escapeShellArg marker.location})"
    #   ) config.map.markers;
    # in
    # # This join the marker command string with | betweem them.
    # [ "markers=\"${lib.concatStringsSep "|" paramForMarker}\"" ];
  };
}
