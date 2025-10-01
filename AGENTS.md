# AI Agent Guidelines for Nix Configuration Repository

This document provides guidelines for AI agents working with this Nix configuration repository. It outlines safe patterns, common gotchas, and best practices to follow when making modifications.

## Repository Structure Understanding

### Architecture Overview
- This is a **multi-platform Nix configuration** managing macOS (darwin), NixOS, and Linux systems
- The **Nebula module** (`modules/nebula/`) is the central orchestration layer
- **Feature flags** control conditional configuration across different machine types
- **Policy modules** apply organization/context-specific settings

See `ARCHITECTURE.md` for detailed architectural information.

## Safe Modification Patterns

### 1. Adding New Features

**Pattern: Feature-driven module creation**
```nix
# darwin-modules/features/new-feature.nix
{
  config,
  lib,
  pkgs,
  user,
  machine,
  ...
}:
with lib;
let
  cfg = config.features.new-feature;
in
{
  options.features.new-feature = {
    enable = mkEnableOption "new-feature";

    # Add specific options here
    someOption = mkOption {
      type = types.bool;
      default = true;
      description = "Description of the option";
    };
  };

  config = mkIf cfg.enable {
    # Feature configuration
    user = {
      # User-space configuration
    };
  };
}
```

**Then enable in `features/default.nix`:**
```nix
{
  features = {
    new-feature.enable = machine.features.some-flag;
  };
}
```

### 2. Adding Machine-Specific Configuration

**Pattern: Use conditional imports in policy modules**
```nix
# darwin-modules/policy/default.nix
imports =
  lib.optionals machine.features.new-context [
    ./new-context.nix
  ]
  ++ lib.optionals machine.features.existing-feature [
    ./existing-feature.nix
  ];
```

**Note on Homebrew packages in policies:**
Policy modules may include `homebrew.brews` or `homebrew.casks` when packages are:
- Not available in nixpkgs
- Require specific homebrew-based integration
- Need to interact with other homebrew-managed tools

This is standard practice in nix-darwin configurations. Document the rationale:
```nix
# Homebrew packages for policy compliance
# These packages are installed via Homebrew rather than nixpkgs because:
# - [specific reason for each package group]
homebrew.brews = [
  "tool1"
  "tool2"
];
```

### 3. Adding New Hosts

**Pattern: Add to `modules/hosts.nix`**
```nix
nebula.hosts = {
  new-host = {
    name = "hostname.domain";
    system = "aarch64-darwin";  # or x86_64-linux, aarch64-linux
    features = [
      "managed"      # Required for generated configurations
      "mac"          # or "linux", "nixos"
      "laptop"       # or omit for desktop
      "work"         # optional feature flags
    ];
    user = "workUser";  # optional, defaults based on features
  };
};
```

### 4. Home Manager Integration

**Pattern: Always use `user`**
```nix
user = {
  # User configuration here
  programs.some-program = {
    enable = true;
    settings = { };
  };

  home.packages = with pkgs; [
    some-package
  ];
};
```

### 5. Settings Module System

The `home-modules/settings/` directory uses **filesystem hierarchy to define option paths**:

#### Hierarchy Pattern
```
home-modules/settings/
├── programs/
│   ├── bat.nix          → programs.bat.*
│   ├── wezterm.nix      → programs.wezterm.*
│   ├── vscode.nix       → programs.vscode.*
│   └── code/
│       ├── nix.nix      → programs.code.nix.*
│       └── python.nix   → programs.code.python.*
└── targets/
    └── genericLinux.nix → targets.genericLinux.*
```

#### Auto-Loading Mechanism
The `settings/default.nix` uses a **loader function** to automatically discover and map files:

```nix
# Transforms filesystem structure to attribute paths
programs = loader "programs";  # programs/*.nix → programs.*
targets = loader "targets";    # targets/*.nix → targets.*
```

#### Settings File Pattern
Each settings file exports configuration directly:

```nix
# settings/programs/bat.nix
{ pkgs, ... }:
{
  enable = true;  # Becomes programs.bat.enable = true
  config = {
    style = "numbers,changes,header";
    # ... more config
  };
  extraPackages = with pkgs.bat-extras; [
    batdiff
    batman
  ];
}
```

**Nested settings example** (`settings/programs/code/nix.nix`):
```nix
# VSCode Nix language support
{
  pkgs,
  extSet,  # VSCode extensions
  ...
}:
{
  userSettings = {
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "${pkgs.nil}/bin/nil";
  };

  extensions = with extSet.vscode-marketplace; [
    jnoortheen.nix-ide
    mkhl.direnv
  ];
}
```

#### Feature-Conditional Settings
Settings can be conditionally enabled based on machine features:

```nix
# settings/targets/genericLinux.nix
{ machine, ... }:
{
  enable = machine.features.linux;  # Only enable on Linux systems
}
```

#### Adding New Settings

**Important: Settings files export configuration FOR the program named by the file.**

The file `settings/programs/bat.nix` contains the configuration for the `bat` program.
Setting `enable = true` in that file means "enable bat", not "enable this settings file".

**1. For top-level programs:**
Create `settings/programs/program-name.nix`:
```nix
{ pkgs, machine, ... }:
{
  # This enables the program itself (programs.program-name.enable = true)
  enable = true;  # or machine.features.some-condition for conditional enabling

  # Program-specific configuration
  settings = {
    # ...
  };
}
```

**2. For nested configuration:**
Create subdirectory: `settings/programs/parent-program/feature.nix`
```nix
# Becomes programs.parent-program.feature.*
{
  enable = true;
  config = {
    # ...
  };
}
```

**3. For platform-specific settings:**
Use feature conditionals within settings files:
```nix
{
  # Enable conditionally based on platform
  enable = machine.features.mac;

  # Or enable always with platform-specific configuration
  enable = true;
  extraConfig = lib.optionalString machine.features.mac ''
    # macOS-specific config
  '';
}

### 6. Platform-Specific Packages

**Pattern: Use `lib.optionals` with feature flags**
```nix
home.packages = with pkgs; [
  # Common packages
  git
  curl
] ++ lib.optionals machine.features.mac [
  # macOS-specific
  m-cli
] ++ lib.optionals machine.features.work [
  # Work-specific
  kubectl
  terraform
];
```

## Critical Patterns to Follow

### 1. Module Structure

**Required imports and patterns:**
```nix
{
  config,      # Always include
  lib,         # Always include
  pkgs,        # For packages
  user,        # For user context (when needed)
  machine,     # For machine context (when needed)
  ...
}:
with lib;    # Standard pattern for lib functions
let
  cfg = config.some.nested.option;  # Extract config early
in
{
  options = { /* ... */ };
  config = mkIf cfg.enable {  # Always conditional on enable
    /* ... */
  };
}
```

### 2. Feature Flag Usage

**Pattern: Check features before applying configuration**
```nix
# GOOD: Feature-conditional configuration
config = mkIf machine.features.work {
  user = {
    programs.git.extraConfig = {
      user.email = "work@company.com";
    };
  };
};

# AVOID: Unconditional configuration
config = {
  user.programs.git.extraConfig = {
    user.email = "work@company.com";  # Applied to ALL machines
  };
};
```

### 3. User Context

**Pattern: Use user profiles for email/identity management**
```nix
# Extract appropriate email from user profiles
let
  workEmail = builtins.head (
    builtins.filter (e: lib.hasSuffix "@company.com" e) user.allEmails
  );
in
{
  programs.git.userEmail = workEmail;
}
```

## Common Gotchas and Anti-Patterns

### ⚠️ 1. Direct machine.name Checks

**AVOID: Hard-coding machine names**
```nix
# BAD
config = lib.mkIf (machine.name == "specific-host") {
  # This breaks modularity
};
```

**PREFER: Feature-based conditions**
```nix
# GOOD
config = lib.mkIf machine.features.special-setup {
  # Reusable across machines with this feature
};
```

### ⚠️ 2. Missing Conditional Guards

**AVOID: Unconditional configuration**
```nix
# BAD - Applied to ALL machines
user = {
  programs.work-tool.enable = true;
};
```

**PREFER: Feature-gated configuration**
```nix
# GOOD
user = lib.mkIf machine.features.work {
  programs.work-tool.enable = true;
};
```

### ⚠️ 3. Hardcoded Values

**AVOID: Magic strings and values**
```nix
# BAD
programs.git.userEmail = "hardcoded@email.com";
```

**PREFER: User profile extraction**
```nix
# GOOD
programs.git.userEmail = user.email;  # From user profiles
```

### ⚠️ 4. Missing Platform Considerations

**AVOID: Platform-unaware package installation**
```nix
# BAD - Might not work on all platforms
home.packages = [ pkgs.darwin-specific-tool ];
```

**PREFER: Platform-conditional packages**
```nix
# GOOD
home.packages = lib.optionals machine.features.mac [
  pkgs.darwin-specific-tool
];
```

## Testing and Validation

### Build Testing
Before committing changes:
```bash
# Test specific configuration build
nix build .#darwinConfigurations.hostname.system
nix build .#homeConfigurations.hostname.activationPackage
nix build .#nixosConfigurations.hostname.system

# Test all configurations
nix flake check
```

### Deployment Testing
```bash
# Darwin systems
darwin-rebuild check --flake .#hostname

# Home Manager only
home-manager switch --flake .#hostname --dry-run
```

## Development Workflow

### 1. Understand Context First
- Check existing host definitions in `modules/hosts.nix`
- Identify relevant feature flags and their usage
- Look for similar existing modules for patterns

### 2. Follow Existing Patterns
- Examine similar modules in the same directory
- Use the same import patterns and function signatures
- Maintain consistent option naming and structure

### 3. Modular Design
- Create reusable features rather than machine-specific hacks
- Use the policy system for organization-specific overrides
- Keep platform-specific code in appropriate module directories

### 4. Test Incrementally
- Build individual configurations before committing
- Test on actual target systems when possible
- Use `nix repl` for testing Nix expressions

## File Organization

### Where to Add New Code

- **New features**: `darwin-modules/features/` or `home-modules/`
- **Organization policies**: `darwin-modules/policy/`
- **System settings**: `darwin-modules/` (top-level modules)
- **Custom packages**: `overlays/pkg/local/`
- **User programs**: `home-modules/`
- **Host definitions**: `modules/hosts.nix`
- **User definitions**: `modules/users.nix`

### Module Naming Conventions

- Use kebab-case for filenames: `my-feature.nix`
- Use camelCase for option names: `myFeature.enable`
- Group related functionality in directories with `default.nix`
- Include descriptive comments for complex logic

## Package Management

### Package Sets and Overlays

This repository uses a sophisticated package management system with multiple package sets and overlays:

#### Package Sets (`overlays/pkgsets.nix`)
The system provides different views of nixpkgs:

```nix
# Available package sets
pkgs.master.*     # Latest packages from nixpkgs-master
pkgs.stable.*     # Stable packages (darwin-stable or nixos-stable)
pkgs.*            # Default unstable packages
pkgs.determinate.* # Determinate Nix packages
pkgs.x86.*        # x86_64 packages (on Apple Silicon for Rosetta)
```

**Usage examples:**
```nix
home.packages = with pkgs; [
  # Default unstable
  git

  # Stable version for reliability
  stable.thefuck

  # Latest features
  master.buck2

  # Determinate Nix
  determinate.nix

  # x86 for Rosetta compatibility (on ARM Darwin)
  x86.some-x86-only-tool
];
```

#### Custom Package Definitions

**Pattern: Follow nixpkgs structure for custom packages**

Custom packages live in `overlays/pkg/local/` and should follow nixpkgs patterns:

```nix
# overlays/pkg/local/my-tool.nix
{
  buildGoModule,    # Or stdenv.mkDerivation, buildRustPackage, etc.
  fetchFromGitHub,
  lib,
  ...
}:
buildGoModule rec {
  pname = "my-tool";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "owner";
    repo = "repo";
    rev = "v${version}";
    hash = "sha256-...";  # Use nix-prefetch-url or similar
  };

  vendorHash = "sha256-...";  # For Go modules

  meta = with lib; {
    description = "Tool description";
    homepage = "https://example.com";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
```

**Complex package example** (see `overlays/pkg/local/jaeger.nix`):
- Multi-stage builds (UI + Go binary)
- Submodule handling
- Asset preprocessing and compression
- Composite source trees

#### Overlay System

**Overlay composition** (`overlays/default.nix`):
```nix
[
  # Package sets (stable, master, x86)
  (import ./pkgsets.nix { inherit inputs config; })

  # Community overlays
  inputs.emacs.overlay
  inputs.fenix.overlays.default

  # For packages from inputs that don't come with an overlay
  (final: prev: {
    jj-spr = inputs.jj-spr.packages.${final.stdenv.system}.default;
    custom-tool = inputs.custom-tool.packages.${final.stdenv.system}.default;
  })

  # Package customizations and overrides
  (import ./pkg)
]
```

**Auto-discovery pattern** (`overlays/pkg/default.nix`):
- Automatically imports all `.nix` files in the directory
- Composes overlays using `foldl'` and `extends`
- Excludes `default.nix` from auto-import

### Package Configuration

**Global nixpkgs config** (`pkg-config.nix`):
```nix
{
  config = {
    allowUnfree = true;  # Enable unfree packages globally
  };
  overlays = import ./overlays { inherit inputs config; };
}
```

### Adding New Packages

#### 1. For Simple Packages
Add to existing configurations:
```nix
home.packages = with pkgs; [
  new-package-from-nixpkgs
];
```

#### 2. For Custom Packages
Create `overlays/pkg/local/package-name.nix`:
```nix
{
  stdenv,
  fetchurl,
  lib,
  ...
}:
stdenv.mkDerivation rec {
  # Follow nixpkgs patterns
}
```

Then use in configurations:
```nix
home.packages = with pkgs; [
  package-name  # Auto-available via overlay
];
```

#### 3. For Package Overrides

**For nixpkgs package overrides**, create separate files in `overlays/pkg/`:
```nix
# overlays/pkg/package-fixes.nix
final: prev: {
  existing-package = prev.existing-package.overrideAttrs (oldAttrs: {
    # Modifications
  });
}
```

**For flake input packages**, use the two-step approach:

1. **First, add the base package in `overlays/default.nix`:**
```nix
# In the "packages from inputs" section
(final: prev: {
  flake-package = inputs.some-flake.packages.${final.stdenv.system}.default;
})
```

2. **Then, add overrides in `overlays/pkg/flake-package.nix`:**
```nix
# overlays/pkg/flake-package.nix
final: prev: {
  flake-package = prev.flake-package.overrideAttrs (oldAttrs: {
    # Package customizations here
    buildInputs = with final; [
      # additional dependencies
    ];
  });
}
```

**When to use each approach:**
- Use separate `overlays/pkg/*.nix` files for **all package modifications and overrides**
- Use the "packages from inputs" section in `overlays/default.nix` **only** for bringing flake packages into scope
- This separation keeps the concerns clean: `default.nix` handles package availability, `pkg/` handles customizations

### Package Version Management

**Pinning specific versions:**
```nix
# Use specific package set
home.packages = with pkgs; [
  stable.reliable-tool    # Stable version
  master.cutting-edge     # Latest features
];
```

**For critical tools, consider version pinning:**
```nix
# In custom package definition
version = "1.2.3";  # Explicit version
src = fetchFromGitHub {
  rev = "v${version}";  # Tied to specific release
};
```

## Security Considerations

### Secrets and Keys
- Never hardcode secrets in configurations
- Use SSH keys and certificates from secure sources
- Be cautious with Git email configurations (they're logged)
- Consider using external secret management for sensitive data

### Package Sources
- Prefer packages from nixpkgs over custom builds
- Be cautious with unfree packages (check `allowUnfree` setting)
- Use specific package versions for critical tools
- Review overlays for package modifications
- Validate package hashes when adding new sources

### Package Security
- Custom packages should include proper `meta.license` information
- Review source URLs and verify authenticity
- Consider using `nix-prefetch-url` for hash verification
- Test custom packages in isolated environments first

This repository follows the principle of "modular and reusable" code. Always consider whether your changes could benefit other machines or users in the configuration.