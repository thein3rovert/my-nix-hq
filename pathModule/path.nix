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
    };
  };
in
{
  # map.paths is a list of pathTypes like "{ pathTypes = {"pathtypes"}};"
  options = {
    map.paths = lib.mkOption {
      type = lib.types.listOf pathTypes;
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
            attributes = builtins.map attrForLocation path.locations;
          in
          ''path="${lib.concatStringsSep "|" attributes}"'';
      in
      builtins.map paramForPath config.map.paths;
  };
}
