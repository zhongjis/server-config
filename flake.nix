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
    myLib = import ./lib/defaults.nix {inherit inputs nixpkgs disko sops-nix;};
  in
    with myLib; {
      nixosConfigurations = {
        homelab-0 = mkK3sNode "homelab-0" {
          hostModule = ./hosts/k3s/configuration.nix;
          isMaster = true;
        };
        homelab-1 = mkK3sNode "homelab-1" {
          hostModule = ./hosts/k3s/configuration.nix;
          masterAddr = "192.168.50.201";
        };
        homelab-2 = mkK3sNode "homelab-2" {
          hostModule = ./hosts/k3s/configuration.nix;
          masterAddr = "192.168.50.201";
        };
      };
    };
}
