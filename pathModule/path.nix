{ lib, config, ... }:
let
  # --- Path file is use to define a list of path
  # on the map from location to destination ---

  # ppathTypes is a submodules that takes in a list of
  # provided locations
  pathTypes = lib.types.submodule {
    options = {
      locations = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
      style = lib.mkOption {
        type = pathStyleType;
        default = { };
      };
    };
  };

  pathStyleType = lib.types.submodule {
    options = {
      weights = lib.mkOption {
        type = lib.types.ints.between 1 20;
        default = 5;
      };
      color = lib.mkOption {
        type = pathColorType;
        default = "red"; # change location line(path) color
      };
    };
  };

  pathColorType = lib.types.either (lib.types.strMatching "0x[0-9A-F]{6}([0-9A-F]{2})?") (
    lib.types.enum [
      "black"
      "brown"
      "green"
      "purple"
      "yellow"
      "blue"
      "gray"
      "orange"
      "red"
      "white"
    ]
  );
in
{
  # map.paths is a list of pathTypes like "{ pathTypes = {"pathtypes"}};"
  options = {
    map.paths = lib.mkOption {
      type = lib.types.listOf pathTypes;
    };
    users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            pathStyle = lib.mkOption {
              type = pathStyleType;
              default = { };
            };
          };
        }
      );
    };
  };

  config = {
    map.paths =
      builtins.map
        (user: {
          locations = [
            user.departure.location
            user.arrival.location
          ];
          style = user.pathStyle;
        })
        (
          # lib.filter takes a "f" and a list and return the values of the list if true
          lib.filter (user: user.departure.location != null && user.arrival.location != null) (
            lib.attrValues config.users
          )
        );
    requestParams =
      let
        attrForLocation = loc: "$(${config.scripts.geocode}/bin/geocode ${lib.escapeShellArg loc})";

        paramForPath =
          path:
          let
            # map the location attibutes to the path locations
            attributes = [
              "weight:${toString path.style.weights}"
              "color:${path.style.color}"
            ] ++ builtins.map attrForLocation path.locations;
          in
          ''path="${lib.concatStringsSep "|" attributes}"'';
      in
      builtins.map paramForPath config.map.paths;
  };
}
