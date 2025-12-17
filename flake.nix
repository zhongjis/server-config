{
  description = "Manage NixOS server remotely";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    colmena,
    disko,
    sops-nix,
    ...
  } @ inputs: let
    myLib = import ./lib/defaults.nix {inherit inputs nixpkgs colmena disko sops-nix;};
  in
    with myLib; {
      nixosConfigurations = {
        homelab-0 = mkK3sNode "homelab-0" {
          hostModule = ./hosts/k3s/configuration.nix;
          isMaster = true;
        };
        homelab-1 = mkK3sNode "homelab-1" {
          hostModule = ./hosts/k3s/configuration.nix;
          masterAddr = "192.168.50.104";
        };
      };

      colmenaHive = colmena.lib.makeHive {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };
          specialArgs = {inherit inputs;};
        };

        homelab-0 = mkHive "homelab-0" {
          host = "192.168.50.104";
          hostModule = ./hosts/k3s/configuration.nix;
          isMaster = true;
        };

        homelab-1 = mkHive "homelab-1" {
          host = "192.168.50.103";
          hostModule = ./hosts/k3s/configuration.nix;
          masterAddr = "192.168.50.104";
        };
      };
    };
}
