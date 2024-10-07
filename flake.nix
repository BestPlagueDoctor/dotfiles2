{
  description = "Nix-based config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11-small";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    ssbm.url = "github:djanatyn/ssbm-nix";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-misc = {
      url = "github:armeenm/nix-misc";
      inputs.nixpkgs.follows = "nixpkgs";
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

    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mpd-mpris = {
      url = "github:natsukagami/mpd-mpris";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: let
    config = {
      allowUnfree = true;
      contentAddressedByDefault = false;
    };

    overlays = [ inputs.emacs-overlay.overlays.default ];

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
      email = "ksam1337@gmail.com";
    };

    baseModules = [
#      inputs.ssbm.homeManagerModule
      { _module.args = {inherit inputs root user; }; }
      { nixpkgs = { inherit config overlays; }; }
    ];

    hmModules = baseModules ++ [
      inputs.mpd-mpris.homeManagerModules.default
    ];

    modules = hmModules ++ [
      inputs.ssbm.nixosModule
      inputs.home-manager.nixosModules.home-manager
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.ragenix.nixosModules.default
      ./modules
    ];

  in {
    nixosConfigurations = {
      lithium = nixpkgs.lib.nixosSystem {
        modules = modules ++ [
          ./hosts/lithium
        ];
      };

      magi = nixpkgs.lib.nixosSystem {
        modules = modules ++ [
          ./hosts/magi
        ];
      };

      navi = nixpkgs.lib.nixosSystem {
        modules = modules ++ [
          ./hosts/navi
        ];
      };

      wsl = nixpkgs.lib.nixosSystem {
        modules = modules ++ [
          inputs.nixos-wsl.nixosModules.default
          ./hosts/wsl
        ];
      };
    };

    homeConfigurations = forAllSystems (system: pkgs: with pkgs; {
      default = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = hmModules ++ [ ./home ];
      };
    });

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

      nodes = {
        navi = {
          hostname = "navi";
          profiles.system = {
            user = "root";
            sudo = "doas -u";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.navi;
          };
        };
      };

      nodes = {
        magi = {
          hostname = "magi";
          profiles.system = {
            user = "root";
            sudo = "doas -u";
            path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.magi;
          };
        };
      };
    };

    devShells = forAllSystems (system: pkgs: with pkgs; {
      default = mkShell {
        packages = [
          inputs.deploy-rs.packages.${system}.default
          nix-output-monitor
          nvd
          openssl
        ];

        shellHook = ''
          export PATH=$PWD/util:$PATH
        '';
      };
    });

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
  };
} 
