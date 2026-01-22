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

    hive = colmena.lib.makeHive {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
        specialArgs = {inherit inputs nixpkgs disko sops-nix;};
        nodeSpecialArgs = {
          homelab-0 = myLib.mkHiveSpecialArgs "homelab-0" {
            isMaster = true;
            labels = ["n8n-node=true"];
          };

          homelab-1 = myLib.mkHiveSpecialArgs "homelab-1" {
            master = "192.168.50.104";
          };

          homelab-2 = myLib.mkHiveSpecialArgs "homelab-2" {
            master = "192.168.50.104";
          };
        };
      };

      homelab-0 = myLib.mkHiveK3s "homelab-0" {
        host = "192.168.50.104";
        hostModule = ./hosts/k3s/configuration.nix;
        tags = ["homelab" "master"];
      };

      homelab-1 = myLib.mkHiveK3s "homelab-1" {
        host = "192.168.50.103";
        hostModule = ./hosts/k3s/configuration.nix;
        tags = ["homelab"];
      };

      homelab-2 = myLib.mkHiveK3s "homelab-2" {
        host = "192.168.50.159";
        hostModule = ./hosts/k3s/configuration.nix;
        tags = ["homelab"];
      };
    };
  in
    with myLib; {
      colmenaHive = hive;
      nixosConfigurations = hive.nodes;
    };
}
