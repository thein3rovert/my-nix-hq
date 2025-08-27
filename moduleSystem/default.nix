{
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ../splittingModules/marker.nix
  ];

  # Using the mkOption function to declare script
  options = {
    scripts.output = lib.mkOption {
      type = lib.types.package;
    };

    # New mkOption to make request to external Api
    # In this case the scripts.output options depends
    # on other options make it possbilbe to build more
    # useful abstraction
    requestParams = lib.mkOption {
      type = lib.types.listOf lib.types.str;
    };

    # New mkOption for conditonal rendering.
    # Setting a default null values for optional request
    # This is dependent on the request param list
    map = {
      zoom = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = 5;
        # Set a default vaule if not specified
        # This makes it not optional
        #default = 10;
      };
      center = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "nigeria";
      };
    };

    # New mkOption for making the geocode package accessible
    # Depends on the map.center
    scripts.geocode = lib.mkOption {
      type = lib.types.package;
    };
  };
  /*
    - config argument hold the result of the module system
    - config attribute expose that particular module's option the module system for evaluation
  */
  config = {
    scripts.geocode = pkgs.writeShellApplication {
      name = "geocode";
      runtimeInputs = with pkgs; [
        curl
        jq
      ];
      text = ''exec ${./geocode.sh} "$@"'';
    };

    scripts.output = pkgs.writeShellApplication {
      name = "map";
      runtimeInputs = with pkgs; [ feh ];
      text = ''
        ${./map.sh} ${lib.concatStringsSep " " config.requestParams} | feh -
      '';
    };

    requestParams = [
      "size=640x640"
      "scale=2"
      (lib.mkIf (config.map.zoom != null) "zoom=${toString config.map.zoom}")
      (lib.mkIf (
        config.map.center != null
      ) "center=\"$(${config.scripts.geocode}/bin/geocode ${lib.escapeShellArg config.map.center})\"")
    ];

    users = {
      samad = {
        departure = {
          location = "Kano";
          style = {
            size = "tiny";
          };
        };
      };
      marek = {
        departure.location = "Nigeria";
        departure.style.size = "tiny";
      };
    };
  };

}
