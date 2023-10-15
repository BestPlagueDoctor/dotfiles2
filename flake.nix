{
  description = "Nix-based config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05-small";

    deploy-rs.url = "github:serokell/deploy-rs";
    home-manager.url = "github:nix-community/home-manager";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nur.url = "github:nix-community/nur";
    ssbm.url = "github:djanatyn/ssbm-nix";

    nix-misc = {
      url = "github:armeenm/nix-misc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:t184256/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: let
    config = {
      allowUnfree = true;
      contentAddressedByDefault = false;
    };

    overlays = [
      (import ./overlay { inherit inputs; })
      inputs.emacs-overlay.overlays.default
    ];

    forAllSystems = f: nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ] (system: f system (
      import nixpkgs { inherit system config overlays; }
    ));

    root = ./.;
    user = {
      login = "sam";
      name = "Sam Knight";
      email = "sknight5@illinois.edu";
    };

    hmModules = [
#      inputs.ssbm.homeManagerModule
      { _module.args = {inherit inputs root user; }; }
    ];


    modules = hmModules ++ [
      inputs.ssbm.nixosModule
      inputs.home-manager.nixosModules.home-manager
      inputs.hyprland.nixosModules.default
      inputs.nur.nixosModules.nur
      inputs.sops-nix.nixosModules.sops
      inputs.lanzaboote.nixosModules.lanzaboote
      { nixpkgs = { inherit config overlays; }; }
      ./modules
    ];

  in {
    nixosConfigurations = {
      lithium = nixpkgs.lib.nixosSystem {
        modules = modules ++ [
          ./hosts/lithium
          ./home
        ];
      };

      magi = nixpkgs.lib.nixosSystem {
        modules = modules ++ [
          ./hosts/magi
          ./home
        ];
      };

      navi = nixpkgs.lib.nixosSystem {
        modules = modules ++ [
          ./hosts/navi
          ./home
        ];
      };
    };

    deploy = {
      nodes = {
        lithium = {
          hostname = "lithium";
          profiles.system = {
            user = "root";
            sudo = "doas -u";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.lithium;
          };
        };
      };
    };

    devShells = forAllSystems (system: pkgs: with pkgs; {
      default = mkShell {
        packages = [
          inputs.deploy-rs.packages.${system}.default
          nil
          nixUnstable
          nvd
          openssl
          sops
        ];

        shellHook = ''
          export PATH=$PWD/util:$PATH
        '';
      };
    });

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
  };
} 
