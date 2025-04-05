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
  } @ inputs: let
    myLib = import ./lib/defaults.nix {inherit nixpkgs disko sops-nix;};
  in
    with myLib; {
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
          specialArgs = {
            inputs = inputs;
          };
        };

        defaults = {pkgs, ...}: {
          environment.systemPackages = [
            pkgs.curl
          ];
        };
        demo = mkColmenaConfig "demo" {
          host = "192.168.50.203";
          user = "root";
          tags = ["homelab"];
          hostModule = ./hosts/k3s/configuration.nix;
        };
      };
    };
}
