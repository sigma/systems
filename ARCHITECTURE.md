# Architecture Documentation

This Nix configuration provides a unified, cross-platform system management framework across macOS (nix-darwin), NixOS, and Linux systems with home-manager. The architecture is built around a central abstraction layer called "Nebula" that enables consistent configuration across heterogeneous environments.

## Overview

The system follows a modular, feature-driven architecture that separates:
- **Platform-specific modules** (darwin, nixos, home)
- **User and machine definitions** (nebula core)
- **Policy-based configuration** (feature flags and conditional imports)
- **Package management** (overlays and custom packages)

## Core Components

### Nebula Module (`modules/nebula/`)

The heart of the architecture, Nebula provides an abstraction layer that:

- **Defines type system** (`types.nix`): Core data structures for users, hosts, and profiles
- **Manages configurations** (`configurations.nix`): Generates platform-specific configurations
- **Provides helpers** (`helpers.nix`): Utility functions for user expansion and machine mapping
- **Orchestrates builds** (`default.nix`): Main module that ties everything together

#### Key abstractions:

```nix
# User abstraction with multiple profiles
user = {
  name = "Display Name";
  githubHandle = "username";
  login = "system-login";
  profiles = [{ name = "work"; emails = ["work@company.com"]; }];
};

# Host/machine abstraction with features
host = {
  name = "hostname";
  system = "aarch64-darwin";
  features = ["managed" "mac" "laptop" "work"];
  user = "personalUser";
};
```

### Platform Modules

#### Darwin Modules (`darwin-modules/`)
macOS-specific configurations organized by concern:
- **Interface** (`interface/`): Trackpad, hotkeys, services, UI settings
- **PAM** (`pam/`): TouchID, U2F, sudo authentication
- **Apps** (`apps/`): Application settings and preferences
- **Features** (`features/`): Optional functionality (music, k8s, IPFS)
- **Policy** (`policy/`): Feature-driven conditional configuration

#### NixOS Modules (`nixos-modules/`)
Linux system-level configuration:
- System configuration, hardware, user management
- Docker, VMware Fusion support (as a guest OS)
- NixOS-specific settings

#### Home Manager Modules (`home-modules/`)
User-space configuration shared across platforms:
- **Editors** (`editors/`): Editor configurations
- **Shells** (`shells/`): Shell environments (Fish, tmux, etc.)
- **Settings** (`settings/`): User application settings

### Configuration Generation

The Nebula module generates platform-specific configurations through a sophisticated mapping system:

```nix
# Feature-based generation
flake = {
  darwinConfigurations = gen "mac";    # Hosts with "mac" feature
  homeConfigurations = gen "linux";    # Hosts with "linux" feature
  nixosConfigurations = gen "nixos";   # Hosts with "nixos" feature
};
```

Each configuration type receives appropriate modules:
- **Darwin**: darwin modules + home-manager integration
- **NixOS**: nixos modules + home-manager integration
- **Linux**: pure home-manager configuration

## Feature System

### Feature Flags
Features enable conditional configuration through boolean flags:

**Built-in features:**
- `managed`: Include in generated configurations
- `linux/mac/nixos`: Platform identification
- `interactive`: Interactive system vs headless
- `laptop`: Mobile vs desktop form factor

**Custom features:**
Custom features can be defined to organize different facets of machine specialization.
For example:
- Work-related tools and policies
- Music production software
- Organization-specific policies

### Policy Application

The policy system (`darwin-modules/policy/`) demonstrates feature-driven architecture:

```nix
# policy/default.nix - Conditional imports based on features
imports =
  lib.optionals machine.features.subzero [ ./subzero.nix ]
  ++ lib.optionals machine.features.firefly [ ./firefly.nix ]
  ++ lib.optionals machine.features.work [ ./work.nix ];
```

Each policy module can:
- Override default settings (`mkForce`)
- Add organization-specific packages
- Configure Git/SCM for different contexts
- Set up workspace layouts and window rules

## Cross-Platform Portability

### Package Management
- **Overlays** (`overlays/`): Package customizations and additions
- **Package sets** (`pkg-config.nix`): Multiple nixpkgs versions (stable, unstable, master)
- **Local packages** (`overlays/pkg/local/`): Custom package definitions

### System Abstraction
The Nebula layer abstracts platform differences:
- **Unified user model**: Same user definition across platforms
- **Feature parity**: Common functionality regardless of underlying system
- **Conditional platform modules**: Platform-specific code isolated in respective directories

### Configuration Sharing
- **Home modules**: User-space config shared between Darwin and NixOS
- **Common tooling**: Same CLI tools, editors, shells across platforms
- **Consistent themes**: Catppuccin theme applied uniformly

## Machine-Specific Configuration

### Host Definitions (`modules/hosts.nix`)
Each machine is defined with:
- **System architecture**: `aarch64-darwin`, `x86_64-linux`, etc.
- **Feature set**: Determines which modules are loaded
- **Remote connections**: SSH configuration for related hosts
- **User assignment**: Which user profile to apply

### User Selection (`modules/users.nix`)
- **Multiple user profiles**: Personal vs work configurations
- **Dynamic selection**: User chosen based on machine features
- **Profile management**: Different email addresses and Git settings per context

### Policy Customization
Policies can be machine-specific through feature flags:
- **Work environments**: Additional security tools, organization-specific Git settings
- **Laptop optimizations**: Power management, different keybindings
- **Development setups**: Language-specific toolchains and environments

## Build System Integration

### Flake Structure
- **Inputs**: All external dependencies centrally managed
- **Outputs**: Platform configurations generated by Nebula
- **System support**: Multi-architecture through flake-parts

### Deployment
- **Darwin**: `darwin-rebuild switch --flake .`
- **Home Manager**: `home-manager switch --flake .#hostname`
- **NixOS**: Standard NixOS rebuild process

The architecture provides a scalable, maintainable approach to managing multiple systems while maintaining consistency and enabling platform-specific optimizations where needed.