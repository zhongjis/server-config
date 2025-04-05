{
  description = "Manage NixOS server remotely";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    disko,
    ...
  }: {
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
      demo = {pkgs, ...}: {
        deployment = {
          targetHost = "192.168.50.203";
          targetPort = 22;
          targetUser = "root";
          buildOnTarget = false;
          tags = ["homelab"];
        };
        nixpkgs.system = "x86_64-linux";
        imports = [
          disko.nixosModules.disko
          ./hosts/k3s/configuration.nix
        ];
        time.timeZone = "Australia/Melbourne";
      };
    };
  };
}
