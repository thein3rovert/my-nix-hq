# MY NIX CHEETSHEET

- `submodules`: Submodules is usually refers to as a nested attributes set. Main used to organise large codebases. They also help in the reusability of an option. 

```nix
  pathTypes = lib.types.submodule {
    options = {
      locations = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
    };
  };

```

In the case above if we want to reuse this pathType for other similar options.
```nix
   options = {
    map.paths = lib.mkOption {
      type = lib.types.listOf pathTypes;
    };
  };

```
We can also create an attributes set of a submodules, intresting!.
```nix
users = lib.mkOption {
      type = lib.types.attrOf (
        lib.types.submodule {
          type = pathTypes;
          default = { };
        }
      );
    };
```
