{
  description = "Manage NixOS server remotely";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

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
      colmenaHive = colmena.lib.makeHive {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
          };
          specialArgs = {inherit inputs nixpkgs disko sops-nix;};
          nodeSpecialArgs = {
            homelab-0 = mkNodeSpecialArgs "homelab-0" {
              isMaster = true;
            };

            homelab-1 = mkNodeSpecialArgs "homelab-1" {
              master = "192.168.50.104";
            };
          };
        };

        homelab-0 = mkHive "homelab-0" {
          host = "192.168.50.104";
          hostModule = ./hosts/k3s/configuration.nix;
          tags = ["homelab" "master"];
        };

        homelab-1 = mkHive "homelab-1" {
          host = "192.168.50.103";
          hostModule = ./hosts/k3s/configuration.nix;
          tags = ["homelab"];
        };
      };
    };
}
