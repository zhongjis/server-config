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
        homelab-0 = mkNixOS "homelab-0" {
          hostModule = ./hosts/k3s/configuration.nix;
        };
        homelab-1 = mkNixOS "homelab-1" {
          hostModule = ./hosts/k3s/configuration.nix;
        };
        homelab-2 = mkNixOS "homelab-2" {
          hostModule = ./hosts/k3s/configuration.nix;
        };
      };
    };
}
