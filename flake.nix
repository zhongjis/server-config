{
  description = "Manage NixOS server remotely";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    disko,
    sops-nix,
    ...
  }: let
    mkColmenaConfig = {
      user ? "nixos",
      host,
      buildOnTarget ? false,
      tags ? [],
      system ? "x86_64-linux",
      extraModules ? [],
      hostModule,
    }: {
      deployment = {
        targetHost = host;
        targetPort = 22;
        targetUser = user;
        buildOnTarget = buildOnTarget;
        tags = tags;
      };
      nixpkgs.system = system;
      imports =
        [
          disko.nixosModules.disko
          hostModule
        ]
        ++ extraModules;
    };
  in {
    nixosConfigurations.demo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hosts/k3s/configuration.nix
      ];
    };
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };

      defaults = {pkgs, ...}: {
        environment.systemPackages = [
          pkgs.curl
        ];
      };
      demo = mkColmenaConfig {
        host = "192.168.50.203";
        user = "root";
        tags = ["homelab"];
        hostModule = ./hosts/k3s/configuration.nix;
      };
    };
  };
}
