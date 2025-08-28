# MY NIX CHEETSHEET

# Submodules

What are Submodules?

### What are Submodules?

* **Submodules** in Nix are `types.submodule` or `types.submodules`.
* They allow **structured configuration**: instead of a raw `attrset`, you define typed `options` inside.
* Useful for **organizing large codebases** (e.g., `services`, `users`, `map.paths`).
* Allow **reusability**: you can define a submodule type once, then reuse it in different options.

---

### 1. Defining a Submodule

A simple `submodule` type:

```nix
pathTypes = lib.types.submodule {
  options = {
    locations = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "A list of filesystem paths.";
    };
  };
};
```

Now `pathTypes` can be reused as a type anywhere.

---

### 2. Reusing a Submodule

You can make options that accept a **list of submodules**:

```nix
options = {
  map.paths = lib.mkOption {
    type = lib.types.listOf pathTypes;
    default = [];
  };
};
```

---

### 3. Attrset of Submodules

Instead of a list, you can key submodules by name:

```nix
users = lib.mkOption {
  type = lib.types.attrsOf (lib.types.submodule {
    options = {
      home = lib.mkOption {
        type = lib.types.path;
        description = "User home directory.";
      };
    };
  });
};
```

Usage:

```nix
users = {
  alice.home = "/home/alice";
  bob.home   = "/home/bob";
};
```

---

### 4. Nested Submodules

Submodules can themselves contain submodules:

```nix
nestedType = lib.types.submodule {
  options = {
    child = lib.mkOption {
      type = lib.types.submodule {
        options = {
          location = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
      };
    };
  };
};
```

---

### 5. `submodule` vs `submodules`

* `lib.types.submodule { ... }` → a **single submodule**.
* `lib.types.submodules { ... }` → a **list of submodules**, with merging rules.
  (So your `<submodulename1>` and `<submodulename2>` examples should use `submodule`, unless you really want a list type.)

Example:

```nix
service.backends = lib.mkOption {
  type = lib.types.submodules {
    options = {
      host = lib.mkOption { type = lib.types.str; };
      port = lib.mkOption { type = lib.types.int; };
    };
  };
};
```

Usage:

```nix
service.backends = [
  { host = "localhost"; port = 8080; }
  { host = "example.com"; port = 80; }
];
```

---

### 6. Defaults and Extension

* You can define a **default** submodule value:

```nix
example = lib.mkOption {
  type = pathTypes;
  default = { locations = [ "/tmp" ]; };
};
```

* Submodules can **extend each other** by merging:

```nix
imports = [
  (lib.mkRenamedOptionModule [ "oldOption" ] [ "newOption" ])
];
```

